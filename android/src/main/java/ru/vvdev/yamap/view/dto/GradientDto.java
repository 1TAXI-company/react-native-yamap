package ru.vvdev.yamap.view.dto;


import java.util.List;

public class GradientDto {
    private List<Integer> colors;

    private List<Double> weights;

    private float length;

    public List<Integer> getColors() {
        return colors;
    }

    public void setColors(List<Integer> colors) {
        this.colors = colors;
    }

    public List<Double> getWeights() {
        return weights;
    }

    public void setWeights(List<Double> weights) {
        this.weights = weights;
    }

    public float getLength() {
        return length;
    }

    public void setLength(float length) {
        this.length = length;
    }
}
