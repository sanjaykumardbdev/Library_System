package com.library.service.impl;

import com.library.dto.MemberDTO;
import com.library.repository.MemberRepository;
import com.library.service.MemberService;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class MemberServiceImpl implements MemberService {

    private final MemberRepository repository;

    public MemberServiceImpl(MemberRepository repository) { this.repository = repository; }

    @Override
    public List<MemberDTO> findMembers(Long memberId, String name, String memberType) {
        return repository.findMembers(memberId, name, memberType);
    }
}
