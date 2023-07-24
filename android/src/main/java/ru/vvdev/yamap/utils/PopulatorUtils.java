package ru.vvdev.yamap.utils;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.yandex.mapkit.geometry.Point;
import com.yandex.mapkit.geometry.PolylinePosition;
import com.yandex.mapkit.geometry.Subpolyline;

import java.util.Objects;

public class PopulatorUtils {
    public static WritableMap createPointJson(final Point point) {
        WritableMap pointJson = Arguments.createMap();
        pointJson.putDouble("lat", point.getLatitude());
        pointJson.putDouble("lon", point.getLongitude());
        return pointJson;
    }

    public static void populatePositionJson(final WritableMap writableMap,
                                                   final PolylinePosition position) {
        populatePositionJson(writableMap, position, "position");
    }

    public static void populatePositionJson(final WritableMap writableMap,
                                            final PolylinePosition position,
                                            final String name) {
        if (Objects.nonNull(position)) {
            WritableMap positionJson = Arguments.createMap();
            positionJson.putDouble("segmentPosition", position.getSegmentPosition());
            positionJson.putDouble("segmentIndex", position.getSegmentIndex());
            writableMap.putMap(name, positionJson);
        }
    }

    public static void populateSubPolylinePositionJson(final WritableMap writableMap,
                                            final Subpolyline position) {
        if (Objects.nonNull(position)) {
            WritableMap positionJson = Arguments.createMap();
            populatePositionJson(positionJson, position.getBegin(), "begin");
            populatePositionJson(positionJson, position.getEnd(), "end");
            writableMap.putMap("position", positionJson);
        }
    }

    public static Float getFloatValue(final Float value) {
        return Objects.nonNull(value) ? value : -1;
    }

    public static double getDoubleValue(final Double value) {
        return Objects.nonNull(value) ? value : -1;
    }

    public static Integer getIntegerValue(final Integer value) {
        return Objects.nonNull(value) ? value : -1;
    }

    public static Boolean getBooleanValue(final Boolean value) {
        return Objects.nonNull(value) ? value : false;
    }


}
