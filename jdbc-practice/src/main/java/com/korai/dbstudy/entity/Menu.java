package com.korai.dbstudy.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Menu {
    private int menuId;
    private int restaurantId;
    private String name;
    private int price;
    private String description;
    private boolean isSignature;
    private boolean isSoldOut;

    public Menu(Map<String, Object> map) {
        this.menuId = (int) map.get("menu_id");
        this.restaurantId = (int) map.get("restaurant_id");
        this.name = (String) map.get("name");
        this.price = (int) map.get("price");
        this.description = (String) map.get("description");
        this.isSignature = (boolean) map.get("is_signature");
        this.isSoldOut = (boolean) map.get("is_sold_out");
    }

    public Menu(Object menuId, Object restaurantId, Object name, Object price, Object description, Object isSignature, Object isSoldOut) {
        this.menuId = (int) menuId;
        this.restaurantId = (int) restaurantId;
        this.name = (String) name;
        this.price = (int) price;
        this.description = (String) description;
        this.isSignature = (boolean) isSignature;
        this.isSoldOut = (boolean) isSoldOut;
    }
}