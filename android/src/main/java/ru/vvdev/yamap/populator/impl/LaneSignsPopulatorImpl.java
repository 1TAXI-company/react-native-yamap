package ru.vvdev.yamap.populator.impl;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.google.android.gms.common.util.CollectionUtils;
import com.yandex.mapkit.directions.driving.Lane;
import com.yandex.mapkit.directions.driving.LaneDirection;
import com.yandex.mapkit.directions.driving.LaneSign;
import com.yandex.mapkit.geometry.PolylinePosition;

import java.util.List;
import java.util.Objects;

import ru.vvdev.yamap.populator.LaneSignsPopulator;
import ru.vvdev.yamap.utils.PopulatorUtils;

public class LaneSignsPopulatorImpl implements LaneSignsPopulator {
    @Override
    public void populateLaneSigns(final WritableMap jsonRoute, final List<LaneSign> laneSigns) {
        if (!CollectionUtils.isEmpty(laneSigns)) {
            final WritableArray laneSignsJson = Arguments.createArray();
            for (int i = 0; i < laneSigns.size(); i++) {
                final WritableMap laneSignJson = Arguments.createMap();
                PopulatorUtils.populatePositionJson(laneSignJson, laneSigns.get(i).getPosition());
                populateLanes(laneSigns.get(i).getLanes(), laneSignJson);

                laneSignsJson.pushMap(laneSignJson);
            }

            jsonRoute.putArray("laneSigns", laneSignsJson);
        }
    }

    private void populateLanes(final List<Lane> lanes, final WritableMap laneSignJson) {
        if (!CollectionUtils.isEmpty(lanes)) {
            final WritableArray lanesJson = Arguments.createArray();
            for (int i = 0; i < lanes.size(); i++) {
                final WritableMap laneJson = Arguments.createMap();

                laneJson.putString("laneKind", lanes.get(i).getLaneKind().name());
                populateLaneDirections(lanes.get(i).getDirections(), laneJson);

                final LaneDirection highlightedDirection = lanes.get(i)
                        .getHighlightedDirection();
                if (Objects.nonNull(highlightedDirection)) {
                    laneJson.putString("highlightedDirection", highlightedDirection.name());
                }
                lanesJson.pushMap(laneJson);
            }
            laneSignJson.putArray("lanes", lanesJson);
        }
    }

    private void populateLaneDirections(final List<LaneDirection> laneDirections,
                                        final WritableMap laneJson) {
        if (!CollectionUtils.isEmpty(laneDirections)) {
            final WritableArray laneDirectionsJson = Arguments.createArray();
            for (int k = 0; k < laneDirections.size(); k++) {
                laneDirectionsJson.pushString(laneDirections.get(k).name());
            }
            laneJson.putArray("laneDirections", laneDirectionsJson);
        }
    }
}
