package ru.vvdev.yamap.populator;

import com.facebook.react.bridge.WritableMap;
import com.yandex.mapkit.directions.driving.DrivingRoute;
import com.yandex.mapkit.directions.driving.LaneSign;

import java.util.List;

public interface CrossingPopulator {
    void populateCrossings(final WritableMap jsonRoute,
                                final DrivingRoute drivingRoute);
}
