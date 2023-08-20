package ru.vvdev.yamap.populator.impl;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.yandex.mapkit.directions.driving.ActionMetadata;
import com.yandex.mapkit.directions.driving.Annotation;
import com.yandex.mapkit.directions.driving.DrivingRoute;
import com.yandex.mapkit.directions.driving.DrivingSection;
import com.yandex.mapkit.directions.driving.DrivingSectionMetadata;
import com.yandex.mapkit.directions.driving.HDAnnotation;
import com.yandex.mapkit.directions.driving.Weight;
import com.yandex.mapkit.geometry.Point;
import com.yandex.mapkit.geometry.Polyline;
import com.yandex.mapkit.geometry.Subpolyline;
import com.yandex.mapkit.geometry.SubpolylineHelper;

import java.util.List;
import java.util.Objects;

import ru.vvdev.yamap.populator.SectionPopulator;
import ru.vvdev.yamap.utils.PopulatorUtils;

public class SectionPopulatorImpl implements SectionPopulator {
    private static final int NOT_EXIST_INDEX = -1;

    @Override
    public void populateSections(final WritableMap jsonRoute, final DrivingRoute drivingRoute,
                                 final int routeIndex) {
        WritableArray sections = Arguments.createArray();
        for (DrivingSection section : drivingRoute.getSections()) {
            WritableMap jsonSection = convertDrivingRouteSection(drivingRoute, section, routeIndex);
            sections.pushMap(jsonSection);
        }
        jsonRoute.putArray("sections", sections);
    }

    private WritableMap convertDrivingRouteSection(final DrivingRoute route,
                                                   final DrivingSection section,
                                                   int routeIndex) {
        WritableMap sectionMap = Arguments.createMap();

        sectionMap.putInt("routeIndex", routeIndex);

        populateMetadata(section.getMetadata(), sectionMap);

        Polyline subpolyline = SubpolylineHelper.subpolyline(route.getGeometry(), section.getGeometry());
        List<Point> linePoints = subpolyline.getPoints();
        WritableArray jsonPoints = Arguments.createArray();

        for (Point point : linePoints) {
            jsonPoints.pushMap(PopulatorUtils.createPointJson(point));
        }

        sectionMap.putArray("points", jsonPoints);

        final Subpolyline geometry = section.getGeometry();
        int beginSegmentIndex = NOT_EXIST_INDEX;
        int endSegmentIndex = NOT_EXIST_INDEX;

        if (Objects.nonNull(subpolyline) && Objects.nonNull(geometry.getBegin())
                && Objects.nonNull(subpolyline)) {
            beginSegmentIndex = geometry.getBegin().getSegmentIndex();
            endSegmentIndex = geometry.getEnd().getSegmentIndex();
        }
        sectionMap.putInt("beginPointIndex", beginSegmentIndex);
        sectionMap.putInt("endPointIndex", endSegmentIndex);

        return sectionMap;
    }

    private void populateMetadata(final DrivingSectionMetadata sectionMetadata,
                                  final WritableMap sectionMap) {
        final WritableMap metadataMap = Arguments.createMap();

        populateWeight(sectionMetadata.getWeight(), metadataMap);
        populateAnnotation(sectionMetadata.getAnnotation(), metadataMap);

        metadataMap.putInt("legIndex", sectionMetadata.getLegIndex());
        if (Objects.nonNull(sectionMetadata.getSchemeId())) {
            metadataMap.putString("schemeId", sectionMetadata.getSchemeId().name());
        }
        final WritableArray viaPoints = Arguments.createArray();
        for (Integer viaPointPosition : sectionMetadata.getViaPointPositions()) {
            viaPoints.pushInt(viaPointPosition);
        }
        metadataMap.putArray("viaPointPositions", viaPoints);

        sectionMap.putMap("metadata", metadataMap);
    }

    private void populateWeight(final Weight weight,
                                final WritableMap metadataMap) {
        final WritableMap weightMap = Arguments.createMap();
        weightMap.putString("time", weight.getTime().getText());
        weightMap.putString("timeWithTraffic", weight.getTimeWithTraffic().getText());
        weightMap.putDouble("distance", weight.getDistance().getValue());
        metadataMap.putMap("weight", weightMap);
    }

    private void populateAnnotation(final Annotation annotation,
                                    final WritableMap metadataMap) {
        final WritableMap annotationMap = Arguments.createMap();

        if (Objects.nonNull(annotation.getAction())) {
            annotationMap.putString("action", annotation.getAction().name());
        }

        if (Objects.nonNull(annotation.getToponym())) {
            annotationMap.putString("toponym", annotation.getToponym());
        }

        annotationMap.putString("description", annotation.getDescriptionText());

        if (Objects.nonNull(annotation.getToponymPhrase())) {
            annotationMap.putString("toponymPhrase", annotation.getToponymPhrase().getText());
        }

        populateActionMetadata(annotation.getActionMetadata(), annotationMap);
        populateHDAnnotation(annotation.getHdAnnotation(), annotationMap);

        metadataMap.putMap("annotation", annotationMap);
    }

    private void populateActionMetadata(final ActionMetadata actionMetadata,
                                        final WritableMap annotationMap) {
        final WritableMap actionMetadataMap = Arguments.createMap();

        if (Objects.nonNull(actionMetadata.getUturnMetadata())) {
            actionMetadataMap.putDouble("uTurnLength", actionMetadata.getUturnMetadata().getLength());
        }

        if (Objects.nonNull(actionMetadata.getLeaveRoundaboutMetadada())) {
            actionMetadataMap.putInt("leaveRoundaboutExitNumber",
                    actionMetadata.getLeaveRoundaboutMetadada().getExitNumber());
        }

        annotationMap.putMap("actionMetadata", actionMetadataMap);
    }

    private void populateHDAnnotation(final HDAnnotation hdAnnotation,
                                      final WritableMap annotationMap) {
        if (Objects.nonNull(hdAnnotation)) {
            final WritableMap hdAnnotationMap = Arguments.createMap();

            if (Objects.nonNull(hdAnnotation.getActionArea())) {
                final WritableArray actionAreaMap = Arguments.createArray();

                for (Point point : hdAnnotation.getActionArea().getPoints()) {
                    actionAreaMap.pushMap(PopulatorUtils.createPointJson(point));
                }

                hdAnnotationMap.putArray("actionAreaPoint", actionAreaMap);
            }

            if (Objects.nonNull(hdAnnotation.getTrajectory())) {
                final WritableArray trajectoryMap = Arguments.createArray();

                for (Point point : hdAnnotation.getTrajectory().getPoints()) {
                    trajectoryMap.pushMap(PopulatorUtils.createPointJson(point));
                }

                hdAnnotationMap.putArray("trajectory", trajectoryMap);
            }

            annotationMap.putMap("hdAnnotation", hdAnnotationMap);
        }
    }

}
