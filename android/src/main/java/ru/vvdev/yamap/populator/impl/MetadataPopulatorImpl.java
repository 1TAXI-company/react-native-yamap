package ru.vvdev.yamap.populator.impl;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.yandex.mapkit.directions.driving.DrivingRouteMetadata;
import com.yandex.mapkit.directions.driving.Flags;

import java.util.Objects;

import ru.vvdev.yamap.populator.MetadataPopulator;

public class MetadataPopulatorImpl implements MetadataPopulator {
    @Override
    public void populateMetadata(final WritableMap jsonRoute,
                                 final DrivingRouteMetadata metadata) {
        final WritableMap metadataMap = Arguments.createMap();

        final com.yandex.mapkit.directions.driving.Weight weight = metadata.getWeight();
        metadataMap.putString("time", weight.getTime().getText());
        metadataMap.putString("timeWithTraffic", weight.getTimeWithTraffic().getText());
        metadataMap.putDouble("distance", weight.getDistance().getValue());

        final Flags flags = metadata.getFlags();
        if (Objects.nonNull(flags)) {
            WritableMap flagsMap = Arguments.createMap();
            flagsMap.putBoolean("blocked", flags.getBlocked());
            flagsMap.putBoolean("buildOffline", flags.getBuiltOffline());
            flagsMap.putBoolean("deadJam", flags.getDeadJam());
            flagsMap.putBoolean("forParking", flags.getForParking());
            flagsMap.putBoolean("futureBlocked", flags.getFutureBlocked());
            flagsMap.putBoolean("hasCheckpoints", flags.getHasCheckpoints());
            flagsMap.putBoolean("hasFerries", flags.getHasFerries());
            flagsMap.putBoolean("hasFordCrossing", flags.getHasFordCrossing());
            flagsMap.putBoolean("hasInPoorConditionRoads", flags.getHasInPoorConditionRoads());
            flagsMap.putBoolean("hasRailwayCrossing", flags.getHasRailwayCrossing());
            flagsMap.putBoolean("hasRuggedRoads", flags.getHasRuggedRoads());
            flagsMap.putBoolean("hasTolls", flags.getHasTolls());
            flagsMap.putBoolean("hasUnpavedRoads", flags.getHasUnpavedRoads());
            flagsMap.putBoolean("scheduledDeparture", flags.getScheduledDeparture());
            flagsMap.putBoolean("requiresAccessPass", flags.getRequiresAccessPass());
            flagsMap.putBoolean("predicted", flags.getPredicted());
            flagsMap.putBoolean("hasVehicleRestrictions", flags.getHasVehicleRestrictions());

            metadataMap.putMap("flags", flagsMap);
        }

        jsonRoute.putMap("metadata", metadataMap);
    }
}
