package ru.vvdev.yamap.view.dto;


import java.util.List;

public class GradientDto {
    private List<Integer> colors;

    private float length;

    public List<Integer> getColors() {
        return colors;
    }

    public void setColors(List<Integer> colors) {
        this.colors = colors;
    }

    public float getLength() {
        return length;
    }

    public void setLength(float length) {
        this.length = length;
    }
}
