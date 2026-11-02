package com.korai.dbstudy.database;

import com.korai.dbstudy.entity.Customer;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class DBConnectionTest2 {
    public static void main(String[] args) {

        //초기세팅 : protocol, host, port, username, password, databaseName 정의하기
        String protocol = "jdbc:mysql";
        String host = "localhost";
        String port = "3306";
        String username = "root";
        String password = "1q2w3e4r!";
        String databaseName = "hanip_delivery02";

        //String Format으로 한 번에 위에 값들 전달
        String url = String.format("%s://%s:%s/%s", protocol, host, port, databaseName);

        //객체로 담아서 출력하기 위해서 리스트에 출력하고자하는 것 넣고 새로운 List만들기
        List<Customer> customers = new ArrayList<>();

        try (Connection connection = DriverManager.getConnection(url, username, password)) {
            PreparedStatement pstmt = connection.prepareStatement("""
                            select 
                                 *
                            from
                                customers
                    """);

            //위에서 준비한 SELECT 쿼리를 실제로 MySQL 서버에 전송해서 "실행"하라는 명령입니다. (Workbench에서 번개 모양 버튼 누르는 것과 같음)
            //ResultSet rs : SELECT를 실행하고 나면 DB가 결과 표(테이블 모양의 데이터들)를 돌려주는데, 그 결과 표 전체를 자바에서 받아 담아두는 객체입니다.
            //처음에 rs는 첫 번째 행(Row) 바로 위(빈 공간, Before First)를 가리키는 커서(화살표)를 가지고 있습니다.
            ResultSet rs = pstmt.executeQuery();

            //sql 내부에서도 select 하게되면 반복하게 되니, for문보다 다음이 없으면 false가 되기때문에 while문을 활용해 로직작성
            while (rs.next()){

                //customer라는 객체에 값 전달 준비, 이때 sql내부에서 사용하는 컬럼명으로 해야 오류 안남
                Customer customer = new Customer(
                        rs.getInt("customer_id"),
                        rs.getString("name"),
                        rs.getString("phone"),
                        rs.getString("email"),
                        rs.getString("birth_date"),
                        rs.getString("district"),
                        rs.getString("address"),
                        rs.getString("grade"),
                        rs.getString("marketing_agreed"),
                        rs.getString("joined_at")     // "joinedAt" -> "joined_at"
                );

                //customers 리스트에 담기
                customers.add(customer);

            }
        } catch (SQLException e) {
            System.out.println("SQL서버 접속 실패 ");
            e.printStackTrace();
        }

        customers.forEach(System.out::println);

    }
}