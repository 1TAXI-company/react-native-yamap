package ru.vvdev.yamap.populator.factory;

import java.util.Objects;

import ru.vvdev.yamap.populator.CrossingPopulator;
import ru.vvdev.yamap.populator.DirectionSignsPopulator;
import ru.vvdev.yamap.populator.DrivingRoutePopulator;
import ru.vvdev.yamap.populator.LaneSignsPopulator;
import ru.vvdev.yamap.populator.MetadataPopulator;
import ru.vvdev.yamap.populator.RestrictedInfoPopulator;
import ru.vvdev.yamap.populator.impl.CrossingPopulatorImpl;
import ru.vvdev.yamap.populator.impl.DirectionSignsPopulatorImpl;
import ru.vvdev.yamap.populator.impl.DrivingRoutePopulatorImpl;
import ru.vvdev.yamap.populator.impl.LaneSignsPopulatorImpl;
import ru.vvdev.yamap.populator.impl.MetadataPopulatorImpl;
import ru.vvdev.yamap.populator.impl.RestrictedInfoPopulatorImpl;

public class PopulatorFactory {
    private static PopulatorFactory instance;

    private DirectionSignsPopulator directionSignsPopulator;
    private LaneSignsPopulator laneSignsPopulator;

    private MetadataPopulator metadataPopulator;

    private DrivingRoutePopulator drivingRoutePopulator;

    private CrossingPopulator crossingPopulator;

    private RestrictedInfoPopulator restrictedInfoPopulator;

    private PopulatorFactory() {

    }

    public DirectionSignsPopulator createDirectinoSignPopulator() {
        return Objects.nonNull(directionSignsPopulator) ?
                directionSignsPopulator : new DirectionSignsPopulatorImpl();
    }

    public LaneSignsPopulator createLaneSignPopulator() {
        return Objects.nonNull(directionSignsPopulator) ?
                laneSignsPopulator : new LaneSignsPopulatorImpl();
    }

    public MetadataPopulator createMetadataPopulator() {
        return Objects.nonNull(metadataPopulator) ?
                metadataPopulator : new MetadataPopulatorImpl();
    }

    public DrivingRoutePopulator createDrivingRoutePopulator() {
        return Objects.nonNull(drivingRoutePopulator) ?
                drivingRoutePopulator : new DrivingRoutePopulatorImpl();
    }

    public CrossingPopulator createCrossingPopulator() {
        return Objects.nonNull(crossingPopulator) ?
                crossingPopulator : new CrossingPopulatorImpl();
    }

    public RestrictedInfoPopulator createRestrictedInfoPopulator() {
        return Objects.nonNull(restrictedInfoPopulator) ?
                restrictedInfoPopulator : new RestrictedInfoPopulatorImpl();
    }

    public static PopulatorFactory getInstance() {
        return Objects.nonNull(instance) ? instance : new PopulatorFactory();
    }
}
