import 'dart:math' as math;

List<double> chopSamples(final List<double> rawSamples, final int totalSamples) {
  List<double> filteredData = [];
  // Change this value to number of audio samples you want.
  // Values between 256 and 1024 are good for showing [RectangleWaveform] and [SquigglyWaveform]
  // While the values above them are good for showing [PolygonWaveform]
  final double blockSize = rawSamples.length / totalSamples;

  for (int i = 0; i < totalSamples; i++) {
    final double blockStart = blockSize * i; // the location of the first sample in the block
    double sum = 0;
    for (int j = 0; j < blockSize; j++) {
      sum += rawSamples[(blockStart + j).toInt()]; // find the sum of all the samples in the block
    }
    // take the average of the block and add it to the filtered data
    filteredData.add((sum / blockSize)); // divide the sum by the block size to get the average
  }

  final maxNum = filteredData.reduce((a, b) => math.max(a.abs(), b.abs()));

  final double multiplier = math.pow(maxNum, -1).toDouble();

  final samples = filteredData.map<double>((e) => (e * multiplier)).toList();

  return samples;
}
