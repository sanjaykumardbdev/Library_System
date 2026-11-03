package com.library.repository;

import com.library.dto.MemberDTO;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

@Component
public class MemberRepository {

    private final JdbcTemplate jdbcTemplate;

    public MemberRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<MemberDTO> findMembers(
            Long memberId, String name, String memberType, String status, Boolean hasAppUser) {
        StringBuilder sql = new StringBuilder(
                "SELECT m.member_id, m.full_name, m.member_type, m.email, m.phone, m.join_date, m.status, " +
                        "CASE WHEN EXISTS (SELECT 1 FROM app_users u WHERE u.member_id = m.member_id) " +
                        "THEN 1 ELSE 0 END AS has_app_user FROM members m WHERE 1 = 1");
        List<Object> args = new ArrayList<>();
        if (memberId != null) {
            sql.append(" AND m.member_id = ?");
            args.add(memberId);
        }
        if (name != null && !name.isBlank()) {
            sql.append(" AND LOWER(m.full_name) LIKE ?");
            args.add("%" + name.trim().toLowerCase() + "%");
        }
        if (memberType != null && !memberType.isBlank()) {
            sql.append(" AND UPPER(m.member_type) = ?");
            args.add(memberType.trim().toUpperCase());
        }
        if (status != null && !status.isBlank()) {
            sql.append(" AND UPPER(m.status) = ?");
            args.add(status.trim().toUpperCase());
        }
        if (Boolean.TRUE.equals(hasAppUser)) {
            sql.append(" AND EXISTS (SELECT 1 FROM app_users u WHERE u.member_id = m.member_id)");
        }
        sql.append(" ORDER BY m.member_id");
        return jdbcTemplate.query(sql.toString(), (ResultSet rs, int rowNum) -> {
            MemberDTO member = new MemberDTO();
            member.setMemberId(rs.getLong("member_id"));
            member.setFullName(rs.getString("full_name"));
            member.setMemberType(rs.getString("member_type"));
            member.setEmail(rs.getString("email"));
            member.setPhone(rs.getString("phone"));
            member.setJoinDate(rs.getDate("join_date"));
            member.setStatus(rs.getString("status"));
            member.setHasAppUser(rs.getInt("has_app_user") == 1);
            return member;
        }, args.toArray());
    }
}
