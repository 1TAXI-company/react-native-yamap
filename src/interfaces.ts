export interface Point {
  lat: number;
  lon: number;
}

export interface BoundingBox {
  southWest: Point;
  northEast: Point;
}

export interface ScreenPoint {
  x: number;
  y: number;
}

export interface Arrow {
  length: number;
  positions: Position[];
  arrowOutlineColor: number;
  arrowOutlineWidth: number;
  arrowColor: number;
}

export interface GradientInfo {
  length?: number;
  colors: number[];
}

export interface HideSegment {
  begin: Position;
  end: Position;
}

export interface MapLoaded {
  renderObjectCount: number;
  curZoomModelsLoaded: number;
  curZoomPlacemarksLoaded: number;
  curZoomLabelsLoaded: number;
  curZoomGeometryLoaded: number;
  tileMemoryUsage: number;
  delayedGeometryLoaded: number;
  fullyAppeared: number;
  fullyLoaded: number;
}

export interface InitialRegion {
  lat: number;
  lon: number;
  zoom?: number;
  azimuth?: number;
  tilt?: number;
}

export type MasstransitVehicles = 'bus' | 'trolleybus' | 'tramway' | 'minibus' | 'suburban' | 'underground' | 'ferry' | 'cable' | 'funicular';

export type Vehicles = MasstransitVehicles | 'walk' | 'car';

export type MapType = 'none' | 'raster' | 'vector';

export interface DrivingInfo {
  time: string;
  timeWithTraffic: string;
  distance: number;
}

export interface MasstransitInfo {
  time: string;
  transferCount: number;
  walkingDistance: number;
}

export interface RouteInfo<T extends (DrivingInfo | MasstransitInfo)> {
  id: string;
  sections: {
    points: Point[];
    sectionInfo: T;
    routeInfo: T;
    routeIndex: number;
    stops: any[];
    type: string;
    transports?: any;
    sectionColor?: string;
  }[];
}

export interface RoutePositionInfo {
  id: string;
  distanceToFinish: number;
  timeToFinish: number;
  heading: number;
  point: Point;
}

export interface IsOnRoute {
  onRoute: boolean;
}

export interface Position {
  segmentIndex: number;
  segmentPosition: number
}

export interface DistanceInfo {
  routeId: string;
  position1?: Position;
  position2: Position;
}

export interface SetPositionDTO {
  routeId: string;
  position: Position;
}

export interface AdvancePositionDTO {
  routeId?: string;
  position: Position;
  distance: number;
}

export interface GetClosestPositionCommonDTO {
  routeId?: string;
  point: Point;
  maxLocationBias: number;
}

export interface GetClosestPositionDTO extends GetClosestPositionCommonDTO{
  priority: string;
}

export interface GetClosestPositionBetweenPointsDTO extends GetClosestPositionCommonDTO {
  positionFrom: Position;
  positionTo: Position;
}

export interface PolylinePosition {
  position: Position;
}

export interface RoutesFoundEvent<T extends (DrivingInfo | MasstransitInfo)> {
  nativeEvent: {
    status: 'success' | 'error';
    id: string;
    routes: RouteInfo<T>[];
  };
}

export interface CameraPosition {
  zoom: number;
  tilt: number;
  azimuth: number;
  point: Point;
  finished: boolean;
}

export type VisibleRegion = {
  bottomLeft: Point;
  bottomRight: Point;
  topLeft: Point;
  topRight: Point;
}

export enum Animation {
  SMOOTH,
  LINEAR
}

export type YandexLogoPosition = {
  horizontal?: 'left' | 'center' | 'right';
  vertical?: 'top' | 'bottom';
}

export type YandexLogoPadding = {
  horizontal?: number;
  vertical?: number;
}
