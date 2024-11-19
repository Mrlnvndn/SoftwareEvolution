// FILE: series1/java-test/src/main/java/TestClass.java
public class TestClass {
    private int value;

    public TestClass(int value) {

        if (value == 0) {
            throw new IllegalArgumentException("Value cannot be zero");
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
            test22();
            return "smaller";
        }
    }

    public void test22() {
        if (true) {

        } else if (false) {

        } else {

        }
    }
}