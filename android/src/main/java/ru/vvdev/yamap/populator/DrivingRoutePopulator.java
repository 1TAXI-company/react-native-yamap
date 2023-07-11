package ru.vvdev.yamap.populator;

import com.facebook.react.bridge.WritableMap;
import com.yandex.mapkit.directions.driving.DrivingRoute;

public interface DrivingRoutePopulator {
    void populateMandatoryData(final WritableMap jsonRoute,
                               final DrivingRoute drivingRoute);

    void populateNavigationData(final WritableMap jsonRoute,
                              final DrivingRoute drivingRoute);
}
