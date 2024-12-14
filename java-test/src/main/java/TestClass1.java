// FILE: series1/java-test/src/main/java/TestClass.java
public class TestClass1 {
    private int value;

    public TestClass1(int value) {
        if (value == 0) {
            throw new IllegalArgumentException("Value cannot be zero");
        } else {
            this.value = value;
        }
    }

    public void f(int value) {
        if (value == 1) {
            throw new IllegalArgumentException("Value cannot be one");
        } else {
            this.value = value;
        }
    }

    public int getValue() {
        return value;
    }

    public void setValue(int value) {
        this.value = value;
    }

    public boolean isCurrentValue(int value) {
        if (this.value == value) {
            return true;
        } else {
            return false;
        }
    }

    // complexity should be 2+1=3
    public String compare(int value) {
        if (this.value == value) {
            return "equal";
        } else if (this.value < value) {
            return "larger";
        } else {
            test1();
            return "smaller";
        }
    }

    public void test1() {
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