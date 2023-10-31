package ru.vvdev.yamap.utils;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.WritableMap;
import com.yandex.mapkit.directions.driving.DrivingRoute;
import com.yandex.mapkit.geometry.Point;
import com.yandex.mapkit.geometry.PolylinePosition;
import com.yandex.mapkit.geometry.geo.PolylineIndex;
import com.yandex.mapkit.geometry.geo.PolylineUtils;
import com.yandex.mapkit.navigation.RoutePosition;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class DrivingRouteManager {
    private static final int NUMBER_OF_STORED_ROUTES = 10;
    private static List<DrivingRoute> existingRoutes = new ArrayList<>();

    private static final DrivingRouteManager instance = new DrivingRouteManager();

    private DrivingRouteManager() {

    }

    public static String generateId() {
        return java.util.UUID.randomUUID().toString();
    }

    public void saveRoute(DrivingRoute route) {
        existingRoutes.add(route);
    }

    public DrivingRoute getRoute(String id) {
        for (DrivingRoute drivingRoute : existingRoutes) {
            if (drivingRoute.getRouteId().equals(id)) {
                return drivingRoute;
            }
        }
        return null;
    }

    public int getNumberOfRoutes() {
        return existingRoutes.size();
    }

    public void removeUnusedRoutes() {
        if (existingRoutes.size() > NUMBER_OF_STORED_ROUTES) {
            int elementsToRemove = existingRoutes.size() - NUMBER_OF_STORED_ROUTES;

            existingRoutes = existingRoutes.subList(elementsToRemove, existingRoutes.size());
        }
    }

    public static DrivingRouteManager getInstance() {
        return instance;
    }

    public float getDistance(final String routeId, final PolylinePosition position1,
                             final PolylinePosition position2) {
        final DrivingRoute route = getRoute(routeId);

        if (Objects.isNull(route) || Objects.isNull(position2)) {
            return -1.f;
        }

        if (Objects.isNull(position1)) {
            return PolylineUtils.distanceBetweenPolylinePositions(route.getGeometry(),
                    route.getPosition(), position2);
        } else {
            return PolylineUtils.distanceBetweenPolylinePositions(route.getGeometry(),
                    position1, position2);
        }
    }

    public RoutePosition getRoutePosition(final String routeId)  {
        final DrivingRoute drivingRoute = getRoute(routeId);
        return Objects.nonNull(drivingRoute) ? drivingRoute.getRoutePosition() : null;
    }

    public void getRoutePositionInfo(final String routeId, final Promise promise) {
        final RoutePosition routePosition = getRoutePosition(routeId);

        final WritableMap writableMap = Arguments.createMap();
        if (Objects.nonNull(routePosition)) {
            writableMap.putDouble("distanceToFinish",
                    PopulatorUtils.getDoubleValue(routePosition.distanceToFinish()));
            writableMap.putDouble("timeToFinish",
                    PopulatorUtils.getDoubleValue(routePosition.timeToFinish()));
            writableMap.putMap("point", PopulatorUtils.createPointJson(routePosition.getPoint()));
            writableMap.putDouble("heading", PopulatorUtils.getDoubleValue(routePosition.heading()));
            promise.resolve(writableMap);
        } else {
            promise.reject("ERROR", "noRouteWithSuchId");
        }
    }

    public void isInRoute(final String routeId, final String checkableRouteId, final Promise promise) {
        final RoutePosition routePosition = getRoutePosition(routeId);

        final WritableMap writableMap = Arguments.createMap();
        if (Objects.nonNull(routePosition)) {
            writableMap.putBoolean("onRoute", routePosition.onRoute(checkableRouteId));
            promise.resolve(writableMap);
        } else {
            promise.reject("ERROR", "noRouteWithSuchId");
        }
    }

    public void getReachedPosition(final String routeId, final Promise promise) {
        final DrivingRoute drivingRoute = getRoute(routeId);

        final WritableMap writableMap = Arguments.createMap();

        if (Objects.nonNull(drivingRoute)) {
            PopulatorUtils.populatePositionJson(writableMap, drivingRoute.getPosition());
            promise.resolve(writableMap);
        } else {
            promise.reject("ERROR", "noRouteWithSuchId");
        }
    }

    public void setReachedPosition(final String routeId, final PolylinePosition polylinePosition,
                                   final Promise promise) {
        final DrivingRoute drivingRoute = getRoute(routeId);

        if (Objects.nonNull(drivingRoute)) {
            drivingRoute.setPosition(polylinePosition);
            promise.resolve("success");
        } else {
            promise.reject("ERROR", "noRouteWithSuchId");
        }
    }

    public void getAdvancedPosition(final String routeId, final PolylinePosition polylinePosition,
                                   final double distance,
                                   final Promise promise) {
        final DrivingRoute drivingRoute = getRoute(routeId);

        final WritableMap writableMap = Arguments.createMap();
        if (Objects.nonNull(drivingRoute)) {

            PopulatorUtils.populatePositionJson(writableMap,
                    PolylineUtils.advancePolylinePosition(drivingRoute.getGeometry(),
                            polylinePosition, distance));
            promise.resolve(writableMap);
        } else {
            promise.reject("ERROR", "noRouteWithSuchId");
        }
    }


    public void getClosestPosition(final String routeId,
                                       final Point point,
                                       final String priority,
                                       final double maxLocationBias,
                                       final Promise promise) {
        final DrivingRoute drivingRoute = getRoute(routeId);

        if (Objects.nonNull(drivingRoute)) {
            PolylineIndex.Priority priorityEnum = "START_POINT".equals(priority) ?
                    PolylineIndex.Priority.CLOSEST_TO_START : PolylineIndex.Priority.CLOSEST_TO_RAW_POINT ;
            final PolylinePosition position = PolylineUtils
                    .createPolylineIndex(drivingRoute.getGeometry())
                    .closestPolylinePosition(point, priorityEnum,
                            maxLocationBias);

            final WritableMap writableMap = Arguments.createMap();

            if (Objects.nonNull(position)) {
                PopulatorUtils.populatePositionJson(writableMap, position);
            }

            promise.resolve(writableMap);
        } else {
            promise.reject("ERROR", "noRouteWithSuchId");
        }
    }

    public void getClosestPositionBetweenPoints(final String routeId,
                                               final Point point,
                                               final PolylinePosition positionFrom,
                                               final PolylinePosition positionTo,
                                               double maxLocationBias,
                                               final Promise promise) {
        final DrivingRoute drivingRoute = getRoute(routeId);

        if (Objects.nonNull(drivingRoute)) {
            final PolylinePosition position = PolylineUtils
                    .createPolylineIndex(drivingRoute.getGeometry())
                    .closestPolylinePosition(point, positionFrom, positionTo,
                            maxLocationBias);

            final WritableMap writableMap = Arguments.createMap();

            if (Objects.nonNull(position)) {
                PopulatorUtils.populatePositionJson(writableMap, position);
            }

            promise.resolve(writableMap);
        } else {
            promise.reject("ERROR", "noRouteWithSuchId");
        }
    }
}
