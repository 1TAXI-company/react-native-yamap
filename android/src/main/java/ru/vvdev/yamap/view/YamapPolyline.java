package ru.vvdev.yamap.view;

import android.content.Context;
import android.graphics.Color;
import android.view.ViewGroup;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.yandex.mapkit.geometry.Point;
import com.yandex.mapkit.geometry.Polyline;
import com.yandex.mapkit.geometry.PolylinePosition;
import com.yandex.mapkit.map.Arrow;
import com.yandex.mapkit.map.MapObject;
import com.yandex.mapkit.map.MapObjectTapListener;
import com.yandex.mapkit.map.PolylineMapObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import ru.vvdev.yamap.models.ReactMapObject;
import ru.vvdev.yamap.view.dto.ArrowDto;
import ru.vvdev.yamap.view.dto.GradientDto;

public class YamapPolyline extends ViewGroup implements MapObjectTapListener, ReactMapObject {
    public Polyline polyline;
    public ArrayList<Point> _points = new ArrayList<>();
    private PolylineMapObject mapObject;
    private int outlineColor = Color.BLACK;
    private int strokeColor = Color.BLACK;
    private int zIndex = 1;
    private float strokeWidth = 1.f;
    private int dashLength = 1;
    private int gapLength = 0;
    private float dashOffset = 0;
    private int outlineWidth = 0;

    private ArrowDto arrowDto;

    private GradientDto gradientDto;

    private float turnRadius = 10;

    public YamapPolyline(Context context) {
        super(context);
        polyline = new Polyline(new ArrayList<Point>());
    }

    @Override
    protected void onLayout(boolean changed, int l, int t, int r, int b) {
    }

    // PROPS
    public void setPolygonPoints(ArrayList<Point> points) {
        _points = points != null ? points : new ArrayList<Point>();
        polyline = new Polyline(_points);
        updatePolyline();
    }



    public void setZIndex(int _zIndex) {
        zIndex = _zIndex;
        updatePolyline();
    }

    public void setStrokeColor(int _color) {
        strokeColor = _color;
        updatePolyline();
    }

    public void setDashLength(int length) {
        dashLength = length;
        updatePolyline();
    }

    public void setDashOffset(float offset) {
        dashOffset = offset;
        updatePolyline();
    }

    public void setGapLength(int length) {
        gapLength = length;
        updatePolyline();
    }

    public void setOutlineWidth(int width) {
        outlineWidth = width;
        updatePolyline();
    }

    public void setOutlineColor(int color) {
        outlineColor = color;
        updatePolyline();
    }

    public void setStrokeWidth(float width) {
        strokeWidth = width;
        updatePolyline();
    }

    public void setArrowDto(ArrowDto arrowDto) {
        this.arrowDto = arrowDto;
        updatePolyline();
    }

    public void setGradient(GradientDto gradientDto) {
        this.gradientDto = gradientDto;
        updatePolyline();
    }

    public void setTurnRadius(float turnRadius) {
        this.turnRadius = turnRadius;
        updatePolyline();
    }

    private void updatePolyline() {
        if (mapObject != null) {
            mapObject.setGeometry(polyline);
            mapObject.setStrokeWidth(strokeWidth);
            mapObject.setZIndex(zIndex);
            mapObject.setDashLength(dashLength);
            mapObject.setGapLength(gapLength);
            mapObject.setDashOffset(dashOffset);
            mapObject.setOutlineColor(outlineColor);
            mapObject.setOutlineWidth(outlineWidth);
            mapObject.setTurnRadius(turnRadius);
            if (Objects.nonNull(arrowDto)) {
                for (PolylinePosition position : arrowDto.getPositions()) {
                    mapObject.addArrow(position, arrowDto.getLength(), arrowDto.getArrowColor());
                }

                if (Objects.nonNull(mapObject.arrows())) {
                    for (Arrow arrow : mapObject.arrows()) {
                        arrow.setOutlineWidth(arrowDto.getArrowOutlineWidth());
                        arrow.setOutlineColor(arrowDto.getArrowOutlineColor());
                    }
                }
            }
            if (Objects.nonNull(gradientDto)
                    && mapObject.getGeometry().getPoints().size() - 1 == gradientDto.getColors().size()) {
                final List<Integer> strokeColors = new ArrayList<>();
                for (int i = 0; i < gradientDto.getColors().size(); i++) {
                    strokeColors.add(i);
                    mapObject.setPaletteColor(i, gradientDto.getColors().get(i));
                }
                mapObject.setStrokeColors(strokeColors);
                mapObject.setGradientLength(gradientDto.getLength());
            } else {
                mapObject.setStrokeColor(strokeColor);
            }
        }
    }

    public void setMapObject(MapObject obj) {
        mapObject = (PolylineMapObject) obj;
        mapObject.addTapListener(this);
        updatePolyline();
    }

    public MapObject getMapObject() {
        return mapObject;
    }

    @Override
    public boolean onMapObjectTap(@NonNull MapObject mapObject, @NonNull Point point) {
        WritableMap e = Arguments.createMap();
        ((ReactContext) getContext()).getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onPress", e);

        return false;
    }
}
