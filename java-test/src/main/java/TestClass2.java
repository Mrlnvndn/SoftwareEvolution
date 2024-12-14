// FILE: series1/java-test/src/main/java/TestClass.java
public class TestClass2 {
    private int value;

    public TestClass2(int value) {
        if (value == 0) {
            throw new IllegalArgumentException("Value cannot be zero");
        } else {
            this.value = value;
        }
    }

    // altough it throws a different error, it should still be marked as code clone
    // together with f in testClass
    public void f(int value) {
        if (value == 0) {
            throw new ArithmeticException("Value cannot be zero");
        } else {
            this.value = value;
        }
    }

    public int getValue() {
        return value;
    }

    public void setValue2(int value) {
        this.value = value;
    }

    public String compare(int value) {
        if (this.value == value) {
            return "equal";
        } else if (this.value < value) {
            return "larger";
        } else {
            test2();
            return "smaller";
        }
    }

    public void test2() {
        double randomValue = Math.random();
        if (randomValue < 0.33) {
            System.out.println("This will be printed 30% of the time");
        } else if (randomValue < 0.66) {
            System.out.println("This will be printed 30% of the time");
        } else {
            System.out.println("This will be printed 30% of the time");
        }
    }
}