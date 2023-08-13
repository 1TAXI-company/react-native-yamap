package ru.vvdev.yamap.view.dto;

import android.graphics.Color;

import com.yandex.mapkit.geometry.PolylinePosition;

import java.util.List;

public class ArrowDto {
    private List<PolylinePosition> positions;
    private float length;

    private int arrowOutlineColor = Color.WHITE;

    private float arrowOutlineWidth = 1.f;

    private int arrowColor = Color.WHITE;

    public List<PolylinePosition> getPositions() {
        return positions;
    }

    public void setPositions(List<PolylinePosition> positions) {
        this.positions = positions;
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
