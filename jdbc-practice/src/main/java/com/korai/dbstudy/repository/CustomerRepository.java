package com.korai.dbstudy.repository;

import com.korai.dbstudy.database.DatabaseProvider;
import com.korai.dbstudy.entity.Customer;

import java.sql.SQLException;
import java.util.List;

public class CustomerRepository implements Repository<Customer> {
    public List<Customer> findAllByLikename(String value){
        String sql = """
                select * from customes where name like concat('%' ,'준' ,'%')
                """;

        return null;
    }


    @Override
    public List<Customer> findAll() {
        String sql = """
                select * from customers
                """;
        try {
            return select(DatabaseProvider.getInstance().getConnection(), sql, null).stream()
                    .map(Customer::new)
                    .toList(); // <-- 세미콜론 추가
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return List.of(); // <-- 예외 발생 시 반환값 추가
    }

    @Override
    public Customer findById(int id) {
        String sql = """
                select * from customers where customer_id = ?
                """;
        try {
            return new Customer(selectOne(DatabaseProvider.getInstance().getConnection(), sql, List.of(id)));
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }


}