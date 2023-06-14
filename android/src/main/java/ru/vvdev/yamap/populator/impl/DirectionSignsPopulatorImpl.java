package ru.vvdev.yamap.populator.impl;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.google.android.gms.common.util.CollectionUtils;
import com.yandex.mapkit.directions.driving.DirectionSign;
import com.yandex.mapkit.directions.driving.DirectionSignDirection;
import com.yandex.mapkit.directions.driving.DirectionSignExit;
import com.yandex.mapkit.directions.driving.DirectionSignIcon;
import com.yandex.mapkit.directions.driving.DirectionSignItem;
import com.yandex.mapkit.directions.driving.DirectionSignRoad;
import com.yandex.mapkit.directions.driving.DirectionSignStyle;
import com.yandex.mapkit.directions.driving.Lane;
import com.yandex.mapkit.directions.driving.LaneDirection;
import com.yandex.mapkit.geometry.PolylinePosition;

import java.util.List;
import java.util.Objects;

import ru.vvdev.yamap.populator.DirectionSignsPopulator;

public class DirectionSignsPopulatorImpl implements DirectionSignsPopulator {
    @Override
    public void populateDirectionSigns(WritableMap jsonRoute, List<DirectionSign> directionSignList) {
        if (!CollectionUtils.isEmpty(directionSignList)) {
            final WritableArray directionSignsJson = Arguments.createArray();
            for (int i = 0; i < directionSignList.size(); i++) {
                final DirectionSign directionSign = directionSignList.get(i);
                final WritableMap directionSignJson = Arguments.createMap();
                populateDirection(directionSign.getDirection(), directionSignJson);
                populateDirectionSignPosition(directionSign.getPosition(), directionSignJson);
                populateItems(directionSign.getItems(), directionSignJson);
            }

            jsonRoute.putArray("laneSigns", directionSignsJson);
        }
    }

    private void populateDirection(final DirectionSignDirection direction,
                                   final WritableMap json) {
        if (Objects.nonNull(direction)) {
            json.putString("direction", direction.name());
        }
    }

    private void populateDirectionSignPosition(final PolylinePosition position,
                                               final WritableMap json) {
        if (Objects.nonNull(position)) {
            final WritableMap positionJson = Arguments.createMap();
            positionJson.putInt("segmentIndex", position.getSegmentIndex());
            positionJson.putDouble("segmentPosition", position.getSegmentPosition());

            json.putMap("position", positionJson);
        }
    }

    private void populateItems(final List<DirectionSignItem> items, final WritableMap json) {
        if (!CollectionUtils.isEmpty(items)) {
            final WritableArray lanesJson = Arguments.createArray();
            for (int i = 0; i < items.size(); i++) {
                final WritableMap itemJson = Arguments.createMap();

                final DirectionSignItem item = items.get(i);

                populateExit(item.getExit(), itemJson);
                populateIcon(item.getIcon(), itemJson);
                populateRoad(item.getRoad(), itemJson);
            }
            json.putArray("lanes", lanesJson);
        }
    }

    private void populateExit(final DirectionSignExit exit, final WritableMap json) {
        if (Objects.nonNull(exit)) {
            WritableMap exitJson = Arguments.createMap();
            exitJson.putString("name", exit.getName());
            populateStyle(exit.getStyle(), exitJson);

            json.putMap("exit", exitJson);
        }
    }

    private void populateIcon(final DirectionSignIcon icon, final WritableMap json) {
        if (Objects.nonNull(icon)) {
            WritableMap iconJson = Arguments.createMap();

            iconJson.putString("image", icon.getImage().name());
            populateStyle(icon.getStyle(), iconJson);

            json.putMap("icon", iconJson);
        }
    }

    private void populateRoad(final DirectionSignRoad road, final WritableMap json) {
        if (Objects.nonNull(road)) {
            WritableMap roadJson = Arguments.createMap();

            roadJson.putString("name", road.getName());
            populateStyle(road.getStyle(), roadJson);

            json.putMap("road", roadJson);
        }
    }

    private void populateStyle(final DirectionSignStyle style, final WritableMap json) {
        if (Objects.nonNull(style)) {
            WritableMap styleJson = Arguments.createMap();
            styleJson.putInt("bgColor", style.getBgColor());
            styleJson.putInt("textColor", style.getTextColor());

            json.putMap("style", styleJson);
        }
    }
}
