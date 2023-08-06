package ru.vvdev.yamap.view.dto;

import android.graphics.Color;

import com.yandex.mapkit.geometry.PolylinePosition;

public class ArrowDto {
    private PolylinePosition position;
    private float length;

    private int arrowOutlineColor = Color.WHITE;

    private float arrowOutlineWidth = 1.f;

    private int arrowColor = Color.WHITE;

    public PolylinePosition getPosition() {
        return position;
    }

    public void setPosition(PolylinePosition position) {
        this.position = position;
    }

    public float getLength() {
        return length;
    }

    public void setLength(float length) {
        this.length = length;
    }

    public int getArrowOutlineColor() {
        return arrowOutlineColor;
    }

    public void setArrowOutlineColor(int arrowOutlineColor) {
        this.arrowOutlineColor = arrowOutlineColor;
    }

    public float getArrowOutlineWidth() {
        return arrowOutlineWidth;
    }

    public void setArrowOutlineWidth(float arrowOutlineWidth) {
        this.arrowOutlineWidth = arrowOutlineWidth;
    }

    public int getArrowColor() {
        return arrowColor;
    }

    public void setArrowColor(int arrowColor) {
        this.arrowColor = arrowColor;
    }
}
