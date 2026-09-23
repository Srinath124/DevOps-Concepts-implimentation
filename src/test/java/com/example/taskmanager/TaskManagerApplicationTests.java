package com.example.taskmanager;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
@SpringBootTest(properties = {"spring.datasource.url=jdbc:h2:mem:testdb", "spring.datasource.password=test-password", "spring.jpa.hibernate.ddl-auto=create-drop"})
class TaskManagerApplicationTests { @Test void contextLoads() { } }
