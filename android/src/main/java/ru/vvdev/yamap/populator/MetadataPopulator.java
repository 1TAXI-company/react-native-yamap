package ru.vvdev.yamap.populator;

import com.facebook.react.bridge.WritableMap;
import com.yandex.mapkit.directions.driving.DrivingRouteMetadata;

public interface MetadataPopulator {
    void populateMetadata(final WritableMap jsonRoute,
                          final DrivingRouteMetadata metadata);
}
