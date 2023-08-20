package ru.vvdev.yamap.populator.impl;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.google.android.gms.common.util.CollectionUtils;
import com.yandex.mapkit.RequestPoint;
import com.yandex.mapkit.annotations.AnnotationLanguage;
import com.yandex.mapkit.directions.driving.AnnotationSchemeID;
import com.yandex.mapkit.directions.driving.Checkpoint;
import com.yandex.mapkit.directions.driving.DrivingRoute;
import com.yandex.mapkit.directions.driving.Ferry;
import com.yandex.mapkit.directions.driving.JamSegment;
import com.yandex.mapkit.directions.driving.RuggedRoad;
import com.yandex.mapkit.directions.driving.SpeedBump;
import com.yandex.mapkit.directions.driving.StandingSegment;
import com.yandex.mapkit.directions.driving.TollRoad;
import com.yandex.mapkit.directions.driving.TrafficLight;
import com.yandex.mapkit.geometry.Point;
import com.yandex.mapkit.geometry.Polyline;
import com.yandex.mapkit.geometry.PolylinePosition;

import java.util.List;
import java.util.Objects;

import ru.vvdev.yamap.populator.CrossingPopulator;
import ru.vvdev.yamap.populator.DirectionSignsPopulator;
import ru.vvdev.yamap.populator.DrivingRoutePopulator;
import ru.vvdev.yamap.populator.LaneSignsPopulator;
import ru.vvdev.yamap.populator.MetadataPopulator;
import ru.vvdev.yamap.populator.RestrictedInfoPopulator;
import ru.vvdev.yamap.populator.SectionPopulator;
import ru.vvdev.yamap.populator.factory.PopulatorFactory;
import ru.vvdev.yamap.utils.PopulatorUtils;

public class DrivingRoutePopulatorImpl implements DrivingRoutePopulator {

    private MetadataPopulator metadataPopulator = PopulatorFactory.getInstance()
            .createMetadataPopulator();

    private LaneSignsPopulator laneSignsPopulator = PopulatorFactory.getInstance()
            .createLaneSignPopulator();

    private DirectionSignsPopulator directionSignsPopulator = PopulatorFactory.getInstance()
            .createDirectinoSignPopulator();

    private CrossingPopulator crossingPopulator = PopulatorFactory.getInstance()
            .createCrossingPopulator();

    private RestrictedInfoPopulator restrictedInfoPopulator = PopulatorFactory.getInstance()
            .createRestrictedInfoPopulator();

    private SectionPopulator sectionPopulator = PopulatorFactory.getInstance()
            .createSectionPopulator();

    @Override
    public void populateMandatoryData(final WritableMap jsonRoute,
                                      final DrivingRoute drivingRoute) {
        metadataPopulator.populateMetadata(jsonRoute, drivingRoute.getMetadata());
        populateGeometries(jsonRoute, drivingRoute.getGeometry());
        populateJams(jsonRoute, drivingRoute);
    }

    @Override
    public void populateNavigationData(final WritableMap jsonRoute,
                                       final DrivingRoute drivingRoute,
                                       final int routeIndex) {
        populateSpeedLimits(jsonRoute, drivingRoute.getSpeedLimits());
        populateSpeedBumps(jsonRoute, drivingRoute.getSpeedBumps());
        populateCheckpoints(jsonRoute, drivingRoute.getCheckpoints());
        populateRuggedRoads(jsonRoute, drivingRoute.getRuggedRoads());
        populateTollRoads(jsonRoute, drivingRoute.getTollRoads());
        populateFerries(jsonRoute, drivingRoute.getFerries());
        populateTrafficLights(jsonRoute, drivingRoute.getTrafficLights());
        populateStandingSegments(jsonRoute, drivingRoute.getStandingSegments());
        populateAnnotationLanguage(jsonRoute, drivingRoute.getAnnotationLanguage());
        populateAnnotationScheme(jsonRoute, drivingRoute.getAnnotationSchemes());
        populateRequestPoints(jsonRoute, drivingRoute.getRequestPoints());
        populateWayPoints(jsonRoute, drivingRoute.getWayPoints());
        laneSignsPopulator.populateLaneSigns(jsonRoute, drivingRoute.getLaneSigns());
        directionSignsPopulator.populateDirectionSigns(jsonRoute, drivingRoute.getDirectionSigns());
        crossingPopulator.populateCrossings(jsonRoute, drivingRoute);
        restrictedInfoPopulator.populateCrossings(jsonRoute, drivingRoute);
        sectionPopulator.populateSections(jsonRoute, drivingRoute, routeIndex);
    }

    private void populateJams(WritableMap writableMap, DrivingRoute drivingRoute) {
        List<JamSegment> jamSegments = drivingRoute.getJamSegments();
        final WritableArray jams = Arguments.createArray();

        if (!CollectionUtils.isEmpty(jamSegments)) {
            for (int i = 0; i < jamSegments.size(); i++) {
                jams.pushString(jamSegments.get(i).getJamType().name());
            }
        }

        writableMap.putArray("jams", jams);
    }

    private void populateRequestPoints(final WritableMap jsonRoute,
                                       final List<RequestPoint> requestPoints) {
        if (!CollectionUtils.isEmpty(requestPoints)) {
            final WritableArray requestPointsJson = Arguments.createArray();

            for (int i = 0; i < requestPoints.size(); i++) {
                final RequestPoint requestPoint =  requestPoints.get(i);
                final WritableMap requestPointJson = Arguments.createMap();
                requestPointJson.putMap("point",
                        PopulatorUtils.createPointJson(requestPoint.getPoint()));
                if (Objects.nonNull(requestPoint.getPointContext())) {
                    requestPointJson.putString("pointContext", requestPoint.getPointContext());
                }
                requestPointJson.putString("type", requestPoint.getType().name());

                requestPointsJson.pushMap(requestPointJson);
            }

            jsonRoute.putArray("requestPoints", requestPointsJson);
        }
    }

    private void populateWayPoints(final WritableMap jsonRoute,
                                       final List<PolylinePosition> wayPoints) {
        if (!CollectionUtils.isEmpty(wayPoints)) {
            final WritableArray writableArray = Arguments.createArray();

            for (int i = 0; i < wayPoints.size(); i++) {
                final WritableMap wayPointsJson = Arguments.createMap();
                PopulatorUtils.populatePositionJson(wayPointsJson, wayPoints.get(i));

                writableArray.pushMap(wayPointsJson);
            }

            jsonRoute.putArray("wayPoints", writableArray);
        }
    }


    private void populateAnnotationLanguage(final WritableMap jsonRoute,
                                            final AnnotationLanguage annotationLanguage) {
        if (Objects.nonNull(annotationLanguage)) {
            jsonRoute.putString("annotationLanguage", annotationLanguage.name());
        }
    }

    private void populateAnnotationScheme(final WritableMap jsonRoute,
                                            final List<AnnotationSchemeID> annotationSchemeIDs) {
        if (!CollectionUtils.isEmpty(annotationSchemeIDs)) {
            final WritableArray annotationSchemeIDsJson = Arguments.createArray();
            for (AnnotationSchemeID annotationSchemeID : annotationSchemeIDs) {
                annotationSchemeIDsJson.pushString(annotationSchemeID.name());
            }

            jsonRoute.putArray("annotationSchemeIDs", annotationSchemeIDsJson);
        }
    }

    private void populateSpeedBumps(final WritableMap jsonRoute, final List<SpeedBump> speedBumps) {
        if (!CollectionUtils.isEmpty(speedBumps)) {
            final WritableArray speedBumpsJson = Arguments.createArray();
            for (SpeedBump speedBump : speedBumps) {
                final WritableMap writableMap = Arguments.createMap();
                PopulatorUtils.populatePositionJson(writableMap,
                        speedBump.getPosition());
                speedBumpsJson.pushMap(writableMap);
            }
            jsonRoute.putArray("speedBumps", speedBumpsJson);
        }
    }

    private void populateCheckpoints(final WritableMap jsonRoute,
                                     final List<Checkpoint> checkpoints) {
        if (!CollectionUtils.isEmpty(checkpoints)) {
            final WritableArray checkpointJson = Arguments.createArray();
            for (Checkpoint checkpoint : checkpoints) {
                final WritableMap writableMap = Arguments.createMap();
                PopulatorUtils.populatePositionJson(writableMap,
                        checkpoint.getPosition());
                checkpointJson.pushMap(writableMap);
            }
            jsonRoute.putArray("checkpoints", checkpointJson);
        }
    }

    private void populateTrafficLights(final WritableMap jsonRoute,
                                       final List<TrafficLight> trafficLights) {
        if (!CollectionUtils.isEmpty(trafficLights)) {
            final WritableArray trafficLightsJson = Arguments.createArray();
            for (TrafficLight trafficLight : trafficLights) {
                final WritableMap writableMap = Arguments.createMap();
                PopulatorUtils.populatePositionJson(writableMap,
                        trafficLight.getPosition());
                trafficLightsJson.pushMap(writableMap);
            }
            jsonRoute.putArray("trafficLights", trafficLightsJson);
        }
    }

    private void populateStandingSegments(final WritableMap jsonRoute,
                                          final List<StandingSegment> standingSegments) {
        if (!CollectionUtils.isEmpty(standingSegments)) {
            final WritableArray standingSegmentsJson = Arguments.createArray();
            for (StandingSegment standingSegment : standingSegments) {
                final WritableMap writableMap = Arguments.createMap();
                PopulatorUtils.populateSubPolylinePositionJson(writableMap,
                        standingSegment.getPosition());
                standingSegmentsJson.pushMap(writableMap);
            }
            jsonRoute.putArray("standingSegments", standingSegmentsJson);
        }
    }

    private void populateSpeedLimits(final WritableMap jsonRoute, final List<Float> speedLimits) {
        if (!CollectionUtils.isEmpty(speedLimits)) {
            final WritableArray speedLimitsJson = Arguments.createArray();
            for (int i = 0; i < speedLimits.size(); i++) {
                speedLimitsJson.pushDouble(Objects.nonNull(speedLimits.get(i)) ?
                        speedLimits.get(i) : -1);
            }
            jsonRoute.putArray("speedLimits", speedLimitsJson);
        }
    }

    private void populateGeometries(final WritableMap jsonRoute, final Polyline geometry) {
        if (Objects.nonNull(geometry) && !CollectionUtils.isEmpty(geometry.getPoints())) {
            final WritableArray pointsJson = Arguments.createArray();

            final List<Point> points = geometry.getPoints();
            for (int i = 0; i < points.size(); i++) {
                pointsJson.pushMap(PopulatorUtils.createPointJson(points.get(i)));
            }

            jsonRoute.putArray("geometry", pointsJson);
        }
    }

    private void populateRuggedRoads(final WritableMap jsonRoute, final List<RuggedRoad> ruggedRoads) {
        if (!CollectionUtils.isEmpty(ruggedRoads)) {
            final WritableArray ruggedRoadsJson = Arguments.createArray();

            for (RuggedRoad ruggedRoad : ruggedRoads) {
                final WritableMap ruggedRoadJson = Arguments.createMap();
                PopulatorUtils.populateSubPolylinePositionJson(ruggedRoadJson,
                        ruggedRoad.getPosition());
                ruggedRoadJson.putBoolean("inPoorCondition", ruggedRoad.getInPoorCondition());
                ruggedRoadJson.putBoolean("unpaved", ruggedRoad.getUnpaved());

                ruggedRoadsJson.pushMap(ruggedRoadJson);
            }

            jsonRoute.putArray("ruggedRoads", ruggedRoadsJson);
        }
    }

    private void populateTollRoads(final WritableMap jsonRoute, final List<TollRoad> tollRoads) {
        if (!CollectionUtils.isEmpty(tollRoads)) {
            final WritableArray tollRoadsJson = Arguments.createArray();

            for (TollRoad tollRoad : tollRoads) {
                final WritableMap tollRoadJson = Arguments.createMap();
                PopulatorUtils.populateSubPolylinePositionJson(tollRoadJson,
                        tollRoad.getPosition());
                tollRoadsJson.pushMap(tollRoadJson);
            }

            jsonRoute.putArray("tollRoads", tollRoadsJson);
        }
    }

    private void populateFerries(final WritableMap jsonRoute, final List<Ferry> ferries) {
        if (!CollectionUtils.isEmpty(ferries)) {
            final WritableArray ferriesJson = Arguments.createArray();

            for (Ferry ferry : ferries) {
                final WritableMap ferryJson = Arguments.createMap();
                PopulatorUtils.populateSubPolylinePositionJson(ferryJson,
                        ferry.getPosition());
                ferriesJson.pushMap(ferryJson);
            }

            jsonRoute.putArray("ferries", ferriesJson);
        }
    }
}
