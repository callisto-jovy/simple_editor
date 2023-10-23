extension RemapInt on double {

  /// Same as [remap], but using double arithmetic only.
  double remap(double fromLow, double fromHigh, double toLow, double toHigh) {
    return (this - fromLow) * (toHigh - toLow) / (fromHigh - fromLow) + toLow;
  }

  /// Same as [remapAndClamp], but using double arithmetic only.
  double remapAndClamp(double fromLow, double fromHigh, double toLow, double toHigh) {
    final remappedValue = remap(fromLow, fromHigh, toLow, toHigh);

    if (toLow > toHigh) {
      return remappedValue.clamp(toHigh, toLow);
    }

    return remappedValue.clamp(toLow, toHigh);
  }


}