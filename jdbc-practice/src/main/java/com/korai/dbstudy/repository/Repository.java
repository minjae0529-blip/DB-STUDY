package com.korai.dbstudy.repository;

import java.sql.*;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public interface Repository<T> {
    List<T> findAll();
    T findById(int id);

    default Map<String, Object> selectOne(Connection connection, String sql, List<Object> params) {
        return select(connection, sql, params).getFirst();
    }

    default List<Map<String, Object>> select(Connection connection, String sql, List<Object> params) {

        try (Connection conn = connection) {
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                if (params != null && !params.isEmpty()) {
                    for (int i = 0; i < params.size(); i++) {
                        int index = i + 1;
                        pstmt.setObject(index, params.get(i));
                    }
                }
                try (ResultSet rs = pstmt.executeQuery()) {
                    List<Map<String, Object>> table = new ArrayList<>();
                    ResultSetMetaData metaData = rs.getMetaData();
                    int columnCount = metaData.getColumnCount();
                    while (rs.next()) {
                        Map<String, Object> row = new LinkedHashMap<>();
                        for (int i = 0; i < columnCount; i++) {
                            int index = i + 1;
                            String columnName = metaData.getColumnLabel(index);
                            Object columnValue = rs.getObject(index);

                            row.put(columnName, columnValue);
                        }
                        table.add(row);
                    }
                    return table;
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
}