package com.korai.dbstudy.database;

import com.korai.dbstudy.entity.Menu;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class DBConnectionTest {
    public static void main(String[] args) {
        String protocol = "jdbc:mysql";
        String host = "localhost";
        String port = "3306";
        String username = "root";
        String password = "1q2w3e4r!";
        String databaseName = "hanip_delivery02";


        //jdbc:mysql://localhost:3306/hanip_delivery02
        String url = String.format("%s://%s:%s/%s", protocol, host, port, databaseName);

        List<Menu> menus = new ArrayList<>();

        //커넥션 소멸시켜줘야 함, 그래야 다른 연결도 가능함 (객체소멸)/ try with resourse / close를 자돟ㅇ으로 해줌
        //DB랑 연결하는 것임
        try (Connection connection = DriverManager.getConnection(url, username, password);) {
            PreparedStatement pstmt = connection.prepareStatement("""
                            select 
                            *
                            from 
                            menus
                    """);
            ResultSet rs = pstmt.executeQuery();
            //쿼리문을 rs에 담은거고, 거기서 계솧ㄱ next하는겅미, 다음 행을 계속 가져오는거라고 봏 수 있찌
            while (rs.next()) {

                Menu menu = new Menu(
                        //여기에 적는것들 mysql에서 실제 쓰는 컬럼명을 사용해야 함
                        rs.getInt("menu_id"),
                        rs.getInt("restaurant_id"),
                        rs.getString("name"),
                        rs.getInt("price"),
                        rs.getString("description"),
                        rs.getBoolean("is_signature"),
                        rs.getBoolean("is_sold_out")
                );

                menus.add(menu);

//                System.out.println(rs.getInt("menu_id"));
//                System.out.println(rs.getInt("restaurant_id"));
//                System.out.println(rs.getString("name"));
//                System.out.println(rs.getInt("price"));
//                System.out.println(rs.getString("description"));
//                System.out.println(rs.getBoolean("is_signature"));
//                System.out.println(rs.getBoolean("is_sold_out"));

            }

        } catch (SQLException e) {
            System.out.println("데이터베이스 연결실패");
            e.printStackTrace();    //오류 원인 찍어주는 것
        }

        menus.forEach(System.out::println);
    }
}
