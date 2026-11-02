package com.korai.dbstudy.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Customer {
    private int customerId;
    private String name;
    private String phones;
    private String email;
    private String birthDate;
    private String district;
    private String address;
    private String grade;
    private String marketingAgreed;
    private String joinedAt;

    public Customer(Map<String, Object> map) {
        this.customerId = (int) map.get("customer_id");
        this.name = (String) map.get("name");
        this.phones = (String) map.get("phone");
        this.email = (String) map.get("email");
        this.birthDate = String.valueOf(map.get("birth_date"));
        this.district = (String) map.get("district");
        this.address = (String) map.get("address");
        this.grade = (String) map.get("grade");
        this.marketingAgreed = String.valueOf(map.get("marketing_agreed"));
        this.joinedAt = String.valueOf(map.get("joined_at"));
    }
}
