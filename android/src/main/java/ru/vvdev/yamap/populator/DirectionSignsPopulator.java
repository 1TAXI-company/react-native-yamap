package ru.vvdev.yamap.populator;

import com.facebook.react.bridge.WritableMap;
import com.yandex.mapkit.directions.driving.DirectionSign;

import java.util.List;

public interface DirectionSignsPopulator {
    void populateDirectionSigns(final WritableMap jsonRoute,
                                final List<DirectionSign> directionSignList);
}
