package com.korai.dbstudy.database;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseProvider {
    private static DatabaseProvider instance;

    private String url;
    private String username;
    private String password;

    public DatabaseProvider(String url, String username, String password) {
        this.url = url;
        this.password = password;
        this.username = username;
    }

    private DatabaseProvider() {
    }

    public static DatabaseProvider getInstance() {
        if (instance == null) {
            instance = new DatabaseProvider(DBConfig.URL, DBConfig.USERNAME, DBConfig.PASSWORD);
        }
        return instance;
    }

    public Connection getConnection() throws SQLException {
        return DriverManager.getConnection(url, username, password);
    }


}
