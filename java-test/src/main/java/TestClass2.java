// FILE: series1/java-test/src/main/java/TestClass.java
public class TestClass2 {
    private int value;

    public TestClass2(int value) {
        if (value == 0) {
            throw new IllegalArgumentException("Value cannot be zero");
        } else {
            this.value = value;
        }
        int randomValue = (int) (Math.random() * 50);
        String randomString = "Random value: " + randomValue;
        for (int i = 0; i < 5; i++) {
            System.out.println(randomString);
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
        int randomValue = (int) (Math.random() * 12);
        String randomString = "Random value: " + randomValue;
        for (int i = 0; i < 5; i++) {
            System.out.println(randomString);
        }
        // This variable initialization has been changed after copying
        double anotherRandomValue = Math.random();
        String anotherRandomString = "Another random value: " + anotherRandomValue;
        System.out.println(anotherRandomString);
    }

    public String compare(int value) {
        if (this.value == value) {
            return "equal";
        } else if (this.value < value) {
            return "larger";
        } else {
            TestClass1 tc1 = new TestClass1(3);
            tc1.test1();
            return "smaller";
        }
    }
}