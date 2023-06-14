package ru.vvdev.yamap.populator.factory;

import java.util.Objects;

import ru.vvdev.yamap.populator.DirectionSignsPopulator;
import ru.vvdev.yamap.populator.LaneSignsPopulator;
import ru.vvdev.yamap.populator.impl.DirectionSignsPopulatorImpl;
import ru.vvdev.yamap.populator.impl.LaneSignsPopulatorImpl;

public class PopulatorFactory {
    private static PopulatorFactory instance;

    private DirectionSignsPopulator directionSignsPopulator;
    private LaneSignsPopulator laneSignsPopulator;

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

    public static PopulatorFactory getInstance() {
        return Objects.nonNull(instance) ? instance : new PopulatorFactory();
    }
}
