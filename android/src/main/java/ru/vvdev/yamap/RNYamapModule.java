package ru.vvdev.yamap;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.yandex.mapkit.MapKitFactory;
import com.yandex.mapkit.geometry.PolylinePosition;
import com.yandex.mapkit.transport.TransportFactory;
import com.yandex.runtime.i18n.I18nManagerFactory;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

import javax.annotation.Nullable;

import static com.facebook.react.bridge.UiThreadUtil.runOnUiThread;

import android.view.View;

import androidx.annotation.NonNull;

import ru.vvdev.yamap.utils.DrivingRouteManager;
import ru.vvdev.yamap.view.YamapView;

public class RNYamapModule extends ReactContextBaseJavaModule {
    private static final String REACT_CLASS = "yamap";

    private static final float ERROR_DISTANCE = -1.f;

    private ReactApplicationContext getContext() {
        return reactContext;
    }

    private static ReactApplicationContext reactContext = null;

    private DrivingRouteManager routeManager = DrivingRouteManager.getInstance();

    RNYamapModule(ReactApplicationContext context) {
        super(context);
        reactContext = context;
    }

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    public Map<String, Object> getConstants() {
        return new HashMap<>();
    }

    @ReactMethod
    public void init(final String apiKey, final Promise promise) {
        runOnUiThread(new Thread(new Runnable() {
            @Override
            public void run() {
                Throwable apiKeyException = null;
                try {
                    // In case when android application reloads during development
                    // MapKitFactory is already initialized
                    // And setting api key leads to crash
                    try {
                        MapKitFactory.setApiKey(apiKey);
                    } catch (Throwable exception) {
                        apiKeyException = exception;
                    }

                    MapKitFactory.initialize(reactContext);
                    TransportFactory.initialize(reactContext);
                    MapKitFactory.getInstance().onStart();
                    promise.resolve(null);
                } catch (Exception exception) {
                    if (apiKeyException != null) {
                        promise.reject(apiKeyException);
                        return;
                    }
                    promise.reject(exception);
                }
            }
        }));
    }

    @ReactMethod
    public void setLocale(final String locale, final Callback successCb, final Callback errorCb) {
        runOnUiThread(new Thread(new Runnable() {
            @Override
            public void run() {
                I18nManagerFactory.setLocale(locale);
                successCb.invoke();
            }
        }));
    }

    @ReactMethod
    public void getLocale(final Callback successCb, final Callback errorCb) {
        runOnUiThread(new Thread(new Runnable() {
            @Override
            public void run() {
                String locale = I18nManagerFactory.getLocale();
                successCb.invoke(locale);
            }
        }));
    }

    @ReactMethod
    public void resetLocale(final Callback successCb, final Callback errorCb) {
        runOnUiThread(new Thread(new Runnable() {
            @Override
            public void run() {
                I18nManagerFactory.setLocale(null);
                successCb.invoke();
            }
        }));
    }

    @ReactMethod
    public void getDistance(
            ReadableMap map,
            Promise promise) {
        runOnUiThread(new Thread(() -> {
            final String routeId = map.getString("routeId");
            final ReadableMap position1Map = map.getMap("position1");
            final PolylinePosition position1 = Objects.nonNull(position1Map) ?
                    createPolylinePosition(position1Map) : null;
            final PolylinePosition position2 = createPolylinePosition(map.getMap("position2"));

            final float distance = routeManager.getDistance(routeId, position1, position2);

            if (distance != ERROR_DISTANCE) {
                promise.resolve(distance);
            } else {
                promise.reject("ERROR", "noRouteWithSuchId");
            }

        }));
    }

    @ReactMethod
    private void getRoutePositionInfo(final String routeId, final Promise promise) {
        runOnUiThread(new Thread(() -> {
            routeManager.getRoutePositionInfo(routeId, promise);
        }));

    }

    @ReactMethod
    private void isInRoute(final String routeId, final String checkableRouteId,
                           final Promise promise) {
        runOnUiThread(new Thread(() -> {
            routeManager.isInRoute(routeId, checkableRouteId, promise);
        }));
    }

    @ReactMethod
    private void getReachedPosition(final String routeId,
                                    final Promise promise) {
        runOnUiThread(new Thread(() -> {
            routeManager.getReachedPosition(routeId, promise);
        }));
    }


    private PolylinePosition createPolylinePosition(final ReadableMap map) {
        return new PolylinePosition(map.getInt("segmentIndex"), map.getDouble("segmentPosition"));
    }

    private static void emitDeviceEvent(String eventName, @Nullable WritableMap eventData) {
        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName, eventData);
    }
}
