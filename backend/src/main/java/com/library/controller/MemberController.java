package com.library.controller;

import com.library.dto.MemberDTO;
import com.library.service.MemberService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/members")
public class MemberController {

    private final MemberService service;

    public MemberController(MemberService service) { this.service = service; }

    @GetMapping
    public ResponseEntity<List<MemberDTO>> list(
            @RequestParam(required = false) Long memberId,
            @RequestParam(required = false) String name,
            @RequestParam(required = false) String memberType
    ) {
        return ResponseEntity.ok(service.findMembers(memberId, name, memberType));
    }
}
