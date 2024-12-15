// FILE: series1/java-test/src/main/java/TestClass.java
public class TestClass1 {
    private int value;

    public TestClass1(int value) {
        if (value == 0) {
            throw new IllegalArgumentException("Value cannot be zero");
        } else {
            this.value = value;
        }
        int randomValue = (int) (Math.random() * 50);
        String randomString = "Random value: " + randomValue;
        for (int i = 0; i < 5; i++) {
            System.out.println(randomValue);
        }
        double anotherRandomValue = Math.random() * 5;
        String anotherRandomString = "Another random value: " + anotherRandomValue;
        System.out.println(anotherRandomString);
    }

    public void f(int value) {
        if (value == 0) {
            throw new IllegalArgumentException("Value cannot be zero");
        } else {
            this.value = value;
        }
        int randomValue = (int) (Math.random() * 35);
        String randomString = "Random value: " + randomValue;
        for (int i = 0; i < 5; i++) {
            System.out.println(randomString);
        }
        double differentRandomValue = Math.random() * 21;
        String differentRandomString = "Another random value: " + differentRandomValue;
        System.out.println(differentRandomString);
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
        if (randomValue < 0.1) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.2) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.3) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.4) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.5) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.6) {
            System.out.println("This will be printed 15% of the time");
        } else if (randomValue < 0.75) {
            System.out.println("This will be printed 5% of the time");
            // from here it is the same in all three test methods
        } else if (randomValue < 0.8) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.9) {
            System.out.println("This will be printed 10% of the time");
        } else {
            System.out.println("This will be printed 10% of the time");
        }
    }

    public void test2() {
        int x = 0;
        double randomValue = Math.random();
        if (randomValue < 0.1) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.2) {
            System.out.println("This will be printed 15% of the time");
        } else if (randomValue < 0.35) {
            System.out.println("This will be printed 5% of the time");
        } else if (randomValue < 0.4) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.5) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.6) {
            System.out.println("This will be printed 15% of the time");
        } else if (randomValue < 0.75) {
            System.out.println("This will be printed 5% of the time");
            // from here it is the same in all three test methods
        } else if (randomValue < 0.8) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.9) {
            System.out.println("This will be printed 10% of the time");
        } else {
            System.out.println("This will be printed 10% of the time");
        }
    }

    public void test3() {
        double randomValue = Math.random();
        if (randomValue < 0.1) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.2) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.3) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.4) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.5) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.6) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.7) {
            System.out.println("This will be printed 10% of the time");
            // from here it is the same in all three test methods
        } else if (randomValue < 0.8) {
            System.out.println("This will be printed 10% of the time");
        } else if (randomValue < 0.9) {
            System.out.println("This will be printed 10% of the time");
        } else {
            System.out.println("This will be printed 10% of the time");
        }
        int x = 0;
    }
}