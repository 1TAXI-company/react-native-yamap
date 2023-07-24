package ru.vvdev.yamap.populator.impl;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.google.android.gms.common.util.CollectionUtils;
import com.yandex.mapkit.directions.driving.DrivingRoute;
import com.yandex.mapkit.directions.driving.FordCrossing;
import com.yandex.mapkit.directions.driving.PedestrianCrossing;
import com.yandex.mapkit.directions.driving.RailwayCrossing;

import java.util.List;
import java.util.Objects;

import ru.vvdev.yamap.populator.CrossingPopulator;
import ru.vvdev.yamap.utils.PopulatorUtils;

public class CrossingPopulatorImpl implements CrossingPopulator {

    @Override
    public void populateCrossings(final WritableMap jsonRoute, final DrivingRoute drivingRoute) {
        populateRailwayCrossing(jsonRoute, drivingRoute.getRailwayCrossings());
        populatePedestrianCrossing(jsonRoute, drivingRoute.getPedestrianCrossings());
        populateFordCrossing(jsonRoute, drivingRoute.getFordCrossings());
    }

    private void populateRailwayCrossing(final WritableMap jsonRoute,
                                         final List<RailwayCrossing> railwayCrossingList) {
        if (!CollectionUtils.isEmpty(railwayCrossingList)) {
            final WritableArray railwayCrossingsJson = Arguments.createArray();

            for (RailwayCrossing railwayCrossing : railwayCrossingList) {
                final WritableMap railwayCrossingJson = Arguments.createMap();
                PopulatorUtils.populatePositionJson(railwayCrossingJson,
                        railwayCrossing.getPosition());
                railwayCrossingJson.putString("type", Objects.nonNull(railwayCrossing.getType()) ?
                        railwayCrossing.getType().name() : "");
                railwayCrossingsJson.pushMap(railwayCrossingJson);
            }

            jsonRoute.putArray("railwayCrossing", railwayCrossingsJson);
        }
    }

    private void populatePedestrianCrossing(final WritableMap jsonRoute,
                                         final List<PedestrianCrossing> pedestrianCrossings) {
        if (!CollectionUtils.isEmpty(pedestrianCrossings)) {
            final WritableArray pedestrianCrossingsJson = Arguments.createArray();

            for (PedestrianCrossing pedestrianCrossing : pedestrianCrossings) {
                final WritableMap writableMap = Arguments.createMap();
                PopulatorUtils.populatePositionJson(writableMap,
                        pedestrianCrossing.getPosition());
                pedestrianCrossingsJson.pushMap(writableMap);
            }

            jsonRoute.putArray("pedestrianCrossing", pedestrianCrossingsJson);
        }
    }

    private void populateFordCrossing(final WritableMap jsonRoute,
                                            final List<FordCrossing> fordCrossings) {
        if (!CollectionUtils.isEmpty(fordCrossings)) {
            final WritableArray fordCrossingsJson = Arguments.createArray();

            for (FordCrossing fordCrossing : fordCrossings) {
                final WritableMap writableMap = Arguments.createMap();
                PopulatorUtils.populateSubPolylinePositionJson(writableMap,
                        fordCrossing.getPosition());
                fordCrossingsJson.pushMap(writableMap);
            }

            jsonRoute.putArray("fordCrossing", fordCrossingsJson);
        }
    }
}
