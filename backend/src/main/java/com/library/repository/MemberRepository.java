package com.library.repository;

import com.library.dto.MemberDTO;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import java.sql.ResultSet;
import java.util.Collections;
import java.util.List;
import java.util.Map;

@Component
public class MemberRepository {

    private final JdbcTemplate jdbcTemplate;
    private SimpleJdbcCall jdbcCall;

    @Value("${members.procedure.schema:}")
    private String procedureSchema;

    public MemberRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @PostConstruct
    public void init() {
        SimpleJdbcCall call = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName("sp_get_members");
        if (procedureSchema != null && !procedureSchema.isBlank()) {
            call = call.withSchemaName(procedureSchema);
        }
        this.jdbcCall = call.returningResultSet("o_cursor", (ResultSet rs, int rowNum) -> {
                    MemberDTO m = new MemberDTO();
                    m.setMemberId(rs.getLong("member_id"));
                    m.setFullName(rs.getString("full_name"));
                    m.setMemberType(rs.getString("member_type"));
                    m.setEmail(rs.getString("email"));
                    m.setPhone(rs.getString("phone"));
                    m.setJoinDate(rs.getDate("join_date"));
                    m.setStatus(rs.getString("status"));
                    return m;
                });
    }

    @SuppressWarnings("unchecked")
    public List<MemberDTO> findMembers(Long memberId, String name, String memberType) {
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("p_member_id", memberId)
                .addValue("p_name", name)
                .addValue("p_member_type", memberType);

        Map<String, Object> out = jdbcCall.execute(params);
        Object o = out.get("o_cursor");
        if (o instanceof List) {
            return (List<MemberDTO>) o;
        }
        return Collections.emptyList();
    }
}
