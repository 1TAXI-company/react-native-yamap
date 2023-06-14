package ru.vvdev.yamap.populator;

import com.facebook.react.bridge.WritableMap;
import com.yandex.mapkit.directions.driving.LaneSign;

import java.util.List;

public interface LaneSignsPopulator {
    void populateLaneSigns(final WritableMap jsonRoute,
                                final List<LaneSign> laneSignList);
}
