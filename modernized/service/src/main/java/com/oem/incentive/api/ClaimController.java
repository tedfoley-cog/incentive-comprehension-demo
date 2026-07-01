package com.oem.incentive.api;

import com.oem.incentive.engine.ClaimProcessor;
import com.oem.incentive.model.ClaimRequest;
import com.oem.incentive.model.PayoutResponse;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/claims")
public class ClaimController {

    private final ClaimProcessor processor;

    public ClaimController(ClaimProcessor processor) {
        this.processor = processor;
    }

    @PostMapping("/process")
    public PayoutResponse process(@RequestBody ClaimRequest claim) {
        return processor.process(claim);
    }

    @DeleteMapping("/state")
    public ResponseEntity<Void> resetState() {
        processor.resetState();
        return ResponseEntity.noContent().build();
    }
}
