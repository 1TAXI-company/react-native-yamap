package ru.vvdev.yamap.populator;

import com.facebook.react.bridge.WritableMap;
import com.yandex.mapkit.directions.driving.DrivingRoute;

public interface SectionPopulator {
    void populateSections(final WritableMap jsonRoute,
                          final DrivingRoute drivingRoute,
                          final int routeIndex);
}
