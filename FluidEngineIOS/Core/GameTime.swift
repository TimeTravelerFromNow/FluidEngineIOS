import MetalKit

final class GameTime {
    private static var _totalGameTime: Float = 0.0
    private static var _deltaTime: Float = 0.0
    private static var _timeScale: Float = 1.0
    public static func UpdateTime(_ deltaTime: Float) {
        self._deltaTime = deltaTime * GameTime.TimeScale
        self._totalGameTime += deltaTime * GameTime.TimeScale
    }
}

extension GameTime {
    public static var TotalGameTime: Float {
        return self._totalGameTime
    }
    
    public static var DeltaTime: Float {
        return self._deltaTime
    }
    public static var TimeScale: Float {
        return self._timeScale
    }
    public static func SetTimeScale(_ to: Float) {
        self._timeScale = to
    }
}
