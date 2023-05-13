package ru.vvdev.yamap.suggest;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.yandex.mapkit.geometry.Point;

import java.util.List;
import java.util.Objects;

public final class YandexSuggestRNArgsHelper {
    public WritableArray createSuggestsMapFrom(List<MapSuggestItem> data) {
        final WritableArray result = Arguments.createArray();

        for (int i = 0; i < data.size(); i++) {
            result.pushMap(createSuggestMapFrom(data.get(i)));
        }

        return result;
    }

    private WritableMap createSuggestMapFrom(MapSuggestItem data) {
        final WritableMap result = Arguments.createMap();
        result.putString("title", data.getTitle());
        result.putString("subtitle", data.getSubtitle());
        result.putString("uri", data.getUri());

        final Point point = data.getCenter();
        if (Objects.nonNull(point)) {
            result.putDouble("lat", point.getLatitude());
            result.putDouble("lon", point.getLongitude());
        }

        return result;
    }
}
