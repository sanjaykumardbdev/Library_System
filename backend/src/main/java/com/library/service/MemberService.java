package com.library.service;

import com.library.dto.MemberDTO;
import java.util.List;

public interface MemberService {
    List<MemberDTO> findMembers(Long memberId, String name, String memberType);
}
