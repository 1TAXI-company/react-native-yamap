package ru.vvdev.yamap.populator.impl;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.google.android.gms.common.util.CollectionUtils;
import com.yandex.mapkit.directions.driving.DrivingRoute;
import com.yandex.mapkit.directions.driving.ManoeuvreVehicleRestriction;
import com.yandex.mapkit.directions.driving.RestrictedEntry;
import com.yandex.mapkit.directions.driving.RoadVehicleRestriction;
import com.yandex.mapkit.directions.driving.VehicleRestriction;

import java.util.List;
import java.util.Objects;

import ru.vvdev.yamap.populator.RestrictedInfoPopulator;
import ru.vvdev.yamap.utils.PopulatorUtils;

public class RestrictedInfoPopulatorImpl implements RestrictedInfoPopulator {

    @Override
    public void populateCrossings(final WritableMap jsonRoute, final DrivingRoute drivingRoute) {
        populateRestrictedEntries(jsonRoute, drivingRoute.getRestrictedEntries());
        populateRoadVehicleRestrictions(jsonRoute, drivingRoute.getRoadVehicleRestrictions());
        populateManoeuvreVehicleRestrictions(jsonRoute, drivingRoute.getManoeuvreVehicleRestrictions());
    }

    private void populateRestrictedEntries(final WritableMap jsonRoute,
                                           final List<RestrictedEntry> restrictedEntries) {
        if (!CollectionUtils.isEmpty(restrictedEntries)) {
            final WritableArray restrictedEntriesJson = Arguments.createArray();

            for (RestrictedEntry restrictedEntry : restrictedEntries) {
                final WritableMap writableMap = Arguments.createMap();
                PopulatorUtils.populatePositionJson(writableMap, restrictedEntry.getPosition());
                restrictedEntriesJson.pushMap(writableMap);
            }

            jsonRoute.putArray("restrictedEntries", restrictedEntriesJson);
        }
    }

    private void populateRoadVehicleRestrictions(final WritableMap jsonRoute,
                                                 final List<RoadVehicleRestriction> roadVehicleRestrictions) {
        if (!CollectionUtils.isEmpty(roadVehicleRestrictions)) {
            final WritableArray restrictedEntriesJson = Arguments.createArray();

            for (RoadVehicleRestriction roadVehicleRestriction : roadVehicleRestrictions) {
                final WritableMap writableMap = Arguments.createMap();
                PopulatorUtils.populateSubPolylinePositionJson(writableMap,
                        roadVehicleRestriction.getPosition());
                populateVehicleRestriction(writableMap,
                        roadVehicleRestriction.getVehicleRestriction());
                restrictedEntriesJson.pushMap(writableMap);
            }

            jsonRoute.putArray("roadVehicleRestrictions", restrictedEntriesJson);
        }
    }

    private void populateVehicleRestriction(final WritableMap writableMap,
                                            final VehicleRestriction vehicleRestriction) {
        if (Objects.nonNull(vehicleRestriction)) {
            writableMap.putDouble("axleWeightLimit",
                    PopulatorUtils.getFloatValue(vehicleRestriction.getAxleWeightLimit()));
            writableMap.putDouble("heightLimit",
                    PopulatorUtils.getFloatValue(vehicleRestriction.getHeightLimit()));
            writableMap.putDouble("lengthLimit",
                    PopulatorUtils.getFloatValue(vehicleRestriction.getLengthLimit()));
            writableMap.putDouble("maxWeightLimit",
                    PopulatorUtils.getFloatValue(vehicleRestriction.getMaxWeightLimit()));
            writableMap.putDouble("payloadLimit",
                    PopulatorUtils.getFloatValue(vehicleRestriction.getPayloadLimit()));
            writableMap.putDouble("weightLimit",
                    PopulatorUtils.getFloatValue(vehicleRestriction.getWeightLimit()));
            writableMap.putDouble("widthLimit",
                    PopulatorUtils.getFloatValue(vehicleRestriction.getWidthLimit()));
            writableMap.putBoolean("legal",
                    PopulatorUtils.getBooleanValue(vehicleRestriction.getLegal()));
            writableMap.putBoolean("trailerNotAllowed",
                    PopulatorUtils.getBooleanValue(vehicleRestriction.getTrailerNotAllowed()));
            writableMap.putInt("minEcoClass",
                    PopulatorUtils.getIntegerValue(vehicleRestriction.getMinEcoClass()));
        }
    }

    private void populateManoeuvreVehicleRestrictions(final WritableMap jsonRoute,
                                                      final List<ManoeuvreVehicleRestriction> manoeuvreVehicleRestrictions) {
        if (!CollectionUtils.isEmpty(manoeuvreVehicleRestrictions)) {
            final WritableArray manoeuvreVehicleRestrictionsJson = Arguments.createArray();

            for (ManoeuvreVehicleRestriction manoeuvreVehicleRestriction : manoeuvreVehicleRestrictions) {
                final WritableMap writableMap = Arguments.createMap();
                PopulatorUtils.populatePositionJson(writableMap,
                        manoeuvreVehicleRestriction.getPosition());
                populateVehicleRestriction(writableMap,
                        manoeuvreVehicleRestriction.getVehicleRestriction());
                manoeuvreVehicleRestrictionsJson.pushMap(writableMap);
            }

            jsonRoute.putArray("manoeuvreVehicleRestrictions", manoeuvreVehicleRestrictionsJson);
        }
    }
}
