#import "/common/java-kotlin-launch.typ": *

#set page(height:auto)

#show: single-file-sample(
  "/reinterpret_cast and java/reinterpret-cast-and-java.typ",
  add-imports: "import sun.misc.Unsafe;\nimport java.lang.reflect.*;",
  start-marker: "//Start\n",
  end-marker: "//End\n",
)

= #smallcaps[Is it possible to do a `reinterpret_cast` in Java?]

Well, at first glance someone could say "No, there is no such construction in Java". And they would be right. That's because the Object in Java is not just a collection of fields, it contains the information about the object itself --- the object _header_. In most JVMs, for 64-bit architectures the header size is 128 bits. Those are a *Mark Word* (information about the state of the object: GC notes, associated lock etc.) and a *Klass Word* (pointer to the information about the class of the object).

== #smallcaps[So, there is nothing we could do?]

Not exactly.

We'll need an instance of the class called `com.misc.Unsafe`. It's a singleton class, and the instance is returned by the method `getUnsafe`

```java
//Start
public static void main(String[] args) {
    Unsafe unsafe = Unsafe.getUnsafe();
}
//End
``` <class>

A shame. We aren't supposed to use it. _Normally_.

OK, let's bring the heavy artillery in.

```java
//Start
public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException {
    Field f = Unsafe.class.getDeclaredField("theUnsafe");
    f.setAccessible(true);
    Unsafe unsafe = (Unsafe) f.get(null);
    System.out.println(unsafe);
}
//End
``` <class>

Well, that works. Now let's declare two classes with one field each.

```java
//Start
static class A {
    long field = 566;
}

static class B {
    long field = 30;
}

public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException {
    Field f = Unsafe.class.getDeclaredField("theUnsafe");
    f.setAccessible(true);
    Unsafe unsafe = (Unsafe) f.get(null);

    A a = new A();
    System.out.println(unsafe.getLong(a, 0));
    System.out.println(unsafe.getLong(a, 8));
    System.out.println(unsafe.getLong(a, 16));
}
//End
``` <class>

Our expectations are satisfied. There are `mark` word, then `klass` word, then the `field`. Let's open the Hotspot JVM specifications. Last two bits equal to `01` indicate that the object is unlocked. In fact, let's play with it:

```java
static class A {
    long a = 566;
}

public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException {
    Field f = Unsafe.class.getDeclaredField("theUnsafe");
    f.setAccessible(true);
    Unsafe unsafe = (Unsafe) f.get(null);

    A a = new A();
//Start
    System.out.println(unsafe.getLong(a, 0));
    System.out.println(a);
    System.out.println(unsafe.getLong(a, 0));
    synchronized (a) {
        System.out.println(unsafe.getLong(a, 0));
    }
    System.out.println(unsafe.getLong(a, 0));
//End
}
```<class>

Wait, what have just happened? First of all, we asked to print `a`, it called `a.toString()`, which in turn called `a.hashCode()`. Hash code turned out to be `6d06d69c`,
and it was cached in the object header. `Mark` word is now `000000`#text(fill:blue,`6d06d69c`)`01`. The we called `synchronized` on it, the lock was created, then we unlocked it. 

The `klass` word, however, never changed. Now let's change it!

```java
static class A {
    long field = 566;
}

static class B {
    long field = 30;
}

public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException {
    Field f = Unsafe.class.getDeclaredField("theUnsafe");
    f.setAccessible(true);
    Unsafe unsafe = (Unsafe) f.get(null);
//Start
    Object a = new A();
    Object b = new B();
    System.out.println(a.getClass());
    unsafe.putLong(a, 8, unsafe.getLong(b, 8));
    System.out.println(a.getClass());
//End
}
``` <class>

OK, but what happens if we cast it to `B`? Nothing special. Now the `JVM` is completely sure that what lies behind `a` is actually `B`.

```java
static class A {
    long field = 566;
}

static class B {
    long field = 30;
}

public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException {
    Field f = Unsafe.class.getDeclaredField("theUnsafe");
    f.setAccessible(true);
    Unsafe unsafe = (Unsafe) f.get(null);
    Object a = new A();
    Object b = new B();
    unsafe.putLong(a, 8, unsafe.getLong(b, 8));
//Start
    B itsSoWrong = (B) a;
    System.out.println(itsSoWrong.field);
//End
}
``` <class>

But don't forget. Everything is Java is by reference. What if we had a reference of type `A` left?

```java
static class A {
    long field = 566;
}

static class B {
    long field = 30;
}

public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException {
    Field f = Unsafe.class.getDeclaredField("theUnsafe");
    f.setAccessible(true);
    Unsafe unsafe = (Unsafe) f.get(null);
//Start
    A a = new A();
    B b = new B();
    unsafe.putLong(a, 8, unsafe.getLong(b, 8));
    B itsSoWrong = (B) a;
    System.out.println(itsSoWrong.field);
//End
}
``` <class>

Oh wait, it's a compilation error. There is no way `a` can actually point to some `B`, right? _Right?_


```java
static class A {
    long field = 566;
}

static class B {
    long field = 30;
}

public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException {
    Field f = Unsafe.class.getDeclaredField("theUnsafe");
    f.setAccessible(true);
    Unsafe unsafe = (Unsafe) f.get(null);
//Start
    A a = new A();
    Object probablyA = a;
    B b = new B();
    unsafe.putLong(a, 8, unsafe.getLong(b, 8));
    B itsSoWrong = (B) probablyA;
    System.out.println(itsSoWrong.field);
    System.out.println(a.getClass());
    System.out.println(a.field);
//End
}
``` <class>

Surprisinlgy still seems to be fine. 

```java
static class A {
    long field = 566;
}

static class B {
    long field = 30;
}

public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException {
    Field f = Unsafe.class.getDeclaredField("theUnsafe");
    f.setAccessible(true);
    Unsafe unsafe = (Unsafe) f.get(null);
    A a = new A();
    Object probablyA = a;
    B b = new B();
    unsafe.putLong(a, 8, unsafe.getLong(b, 8));
    B itsSoWrong = (B) probablyA;
//Start
    A thatWasA = (A) (Object) a;
//End
}
``` <class>

Yeah, that broke. `a` is not `A` anymore. 


