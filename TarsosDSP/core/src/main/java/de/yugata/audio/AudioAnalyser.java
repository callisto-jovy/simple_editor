package de.yugata.audio;


import be.tarsos.dsp.AudioDispatcher;
import be.tarsos.dsp.beatroot.BeatRootOnsetEventHandler;
import be.tarsos.dsp.io.jvm.JVMAudioInputStream;
import be.tarsos.dsp.onsets.ComplexOnsetDetector;
import be.tarsos.dsp.onsets.OnsetHandler;

import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.UnsupportedAudioFileException;
import java.io.File;
import java.io.IOException;
import java.util.ArrayDeque;
import java.util.*;

public class AudioAnalyser {


    public static List<Double> analyseBeats(final String audioInput, final double peakThreshold, final double msThreshold) {
        final List<Double> timeBetweenBeats = new ArrayList<>();

        final double[] lastMs = {0};
        analyseBeats(audioInput, peakThreshold, msThreshold, (timeStamp, salience) -> {
            final double time = (timeStamp * 1000);
            final double msPassed = time - lastMs[0];

            timeBetweenBeats.add(msPassed);
            lastMs[0] = time;
        });
        return timeBetweenBeats;
    }


    public static List<Double> analyseStamps(final String audioInput, final double peakThreshold, final double msThreshold) {
        final List<Double> stamps = new ArrayList<>();

        final double[] lastMs = {0};
        analyseBeats(audioInput, peakThreshold, msThreshold, (timeStamp, salience) -> {
            final double time = (timeStamp * 1000);
            stamps.add(time);
            lastMs[0] = time;
        });

        return stamps;
    }

    public static void analyseBeats(final String audioInput, final double peakThreshold, final double msThreshold, final OnsetHandler tracker) {
        validatePath(audioInput);


        // This limits us to AIFF, AU and WAV files only, however, it eliminates the need for the ffmpeg grabber, which reduces code complexity.
        try (final AudioInputStream audioInputStream = AudioSystem.getAudioInputStream(new File(audioInput))) {
            final AudioFormat audioFormat = audioInputStream.getFormat();


            // Sample rate, the buffer's size and overlap between buffers
            final float sampleRate = audioFormat.getSampleRate(); //We get the sample rate from the file
            final int bufferSize = 2048, // Just hardcoded
                    bufferOverlap = 1024;

            // Don't continue from here, just abort.
            if (sampleRate == -1)
                throw new RuntimeException("Samplerate cannot be negative.");


            //
            final JVMAudioInputStream audioStream = new JVMAudioInputStream(audioInputStream);
            final AudioDispatcher dispatcher = new AudioDispatcher(audioStream, bufferSize, bufferOverlap);


            //TODO: Setting
            final ComplexOnsetDetector detector = new ComplexOnsetDetector(bufferSize, peakThreshold, msThreshold / 1000);
            final BeatRootOnsetEventHandler handler = new BeatRootOnsetEventHandler();
            detector.setHandler(handler);
            dispatcher.addAudioProcessor(detector);
            dispatcher.run();

            handler.trackBeats(tracker);

        } catch (UnsupportedAudioFileException | IOException e) {
            e.printStackTrace();
        }
    }

    /*
     * Checks whether the input exists & creates the output file
     */
    private static void validatePath(final String inputPath) {
        final File inputFile = new File(inputPath);

        // Check the input's validity
        if (!inputFile.exists()) {
            throw new IllegalArgumentException("The input file supplied does not exist. Aborting!");
        }
    }
}
