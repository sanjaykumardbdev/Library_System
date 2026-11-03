package com.library.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;

@RestControllerAdvice
public class ApiExceptionHandler {

    private static final Logger LOGGER = LoggerFactory.getLogger(ApiExceptionHandler.class);

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, String>> handleResponseStatus(ResponseStatusException exception) {
        return ResponseEntity.status(exception.getStatusCode())
                .body(Map.of("detail", exception.getReason() == null
                        ? "The request could not be completed."
                        : exception.getReason()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidation(MethodArgumentNotValidException exception) {
        String details = exception.getBindingResult().getFieldErrors().stream()
                .map(this::formatFieldError)
                .distinct()
                .collect(Collectors.joining(" "));
        return ResponseEntity.badRequest().body(Map.of(
                "detail", details.isBlank() ? "Please check the information you entered." : details));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleUnexpected(Exception exception) {
        LOGGER.error("Unexpected request failure", exception);
        Map<String, String> body = new LinkedHashMap<>();
        body.put("detail", "Something went wrong while processing your request. Please try again.");
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
    }

    private String formatFieldError(FieldError error) {
        return error.getDefaultMessage() == null
                ? error.getField() + " is invalid."
                : error.getField() + ": " + error.getDefaultMessage();
    }
}
