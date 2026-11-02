package com.korai.dbstudy.database;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class DBConnectionTest03 {
    public static void main(String[] args) {


        try(Connection conn = DatabaseProvider.getInstance().getConnection()){
            String sql = """
                    select 
                    * 
                    from 
                    customers
                    """;
            PreparedStatement pstmt = conn.prepareStatement(sql);
            ResultSet rs = pstmt.executeQuery();
        }catch (SQLException e){
            e.printStackTrace();
            System.out.println("SQL서버 연결 실패");
        }


    }
}
