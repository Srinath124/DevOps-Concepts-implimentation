package com.example.taskmanager.controller;

import com.example.taskmanager.repository.TaskRepository;
import java.util.Map;
import org.springframework.dao.DataAccessException;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** A small UI-facing status check. The repository query verifies database connectivity. */
@RestController
@RequestMapping("/api/system")
public class SystemStatusController {
    private final TaskRepository repository;

    public SystemStatusController(TaskRepository repository) { this.repository = repository; }

    @GetMapping("/status")
    public Map<String, String> status() {
        try {
            repository.count();
            return Map.of("api", "ONLINE", "database", "ONLINE");
        } catch (DataAccessException exception) {
            return Map.of("api", "ONLINE", "database", "OFFLINE");
        }
    }
}
