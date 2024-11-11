
// FILE: series1/java-test/src/test/java/TestClassTest.java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;

public class TestClassTest {
    private int value;

    @Test
    public void testGetValue() {
        TestClass testClass = new TestClass(5);
        assertEquals(5, testClass.getValue());
    }

    // test
    @Test
    public void testSetValue() {
        TestClass testClass = new TestClass(5);
        testClass.setValue(10);
        assertEquals(10, testClass.getValue());
    }
}