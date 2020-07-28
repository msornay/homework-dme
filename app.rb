#!/usr/bin/env ruby

require "sinatra"
require "csv"
require "json"

ONE_SECOND_IN_MS = 1000
ONE_MINUTE_IN_MS = ONE_SECOND_IN_MS * 60

post "/delineation" do
  unless params[:data] && params[:data][:tempfile]
    status :bad_request
    return { error: "data file must be present" }.to_json
  end

  unless params[:starts_at]
    status :bad_request
    return { error: "starts_at must be present" }.to_json
  end

  starts_at = Time.parse(params[:starts_at])

  csv = CSV.new(params[:data][:tempfile])

  premature_p_waves = 0
  premature_qrs_complexes = 0
  minimum_qrs_onset = nil
  maximum_qrs_onset = nil
  qrs_complexes = 0
  last_heart_beat_at = nil
  minimum_heart_rate = nil
  maximum_heart_rate = nil

  csv.each do |line|
    type, onset, _offset, *tags = line

    onset = onset.to_i

    premature_p_waves += 1 if type == "P" && tags.include?("premature")

    next unless type == "QRS"

    qrs_complexes += 1
    premature_qrs_complexes += 1 if tags.include?("premature")
    minimum_qrs_onset = onset if minimum_qrs_onset.nil? || onset < minimum_qrs_onset
    maximum_qrs_onset = onset if maximum_qrs_onset.nil? || onset > maximum_qrs_onset

    # when encountering the first qrs complex
    if last_heart_beat_at.nil?
      last_heart_beat_at = onset
      next
    end

    # minutes between the last heart beat and the current onset
    minutes = (onset - last_heart_beat_at).to_f / ONE_MINUTE_IN_MS
    # heart rate is in beats per minutes
    heart_rate = (1 / minutes).to_i
    last_heart_beat_at = onset

    if minimum_heart_rate.nil? || minimum_heart_rate[:rate] > heart_rate
      minimum_heart_rate = {
        rate: heart_rate,
        starts_at: starts_at + (onset / ONE_SECOND_IN_MS)
      }
    end

    if maximum_heart_rate.nil? || maximum_heart_rate[:rate] < heart_rate
      maximum_heart_rate = {
        rate: heart_rate,
        starts_at: starts_at + (onset / ONE_SECOND_IN_MS)
      }
    end
  end

  # number of heart beats encountered divided by the duration of the ECG
  mean_heart_rate = (
    (qrs_complexes - 1) /
    ((maximum_qrs_onset - minimum_qrs_onset).to_f / ONE_MINUTE_IN_MS)
  )

  JSON.pretty_generate(
    {
      premature_p_waves: premature_p_waves,
      premature_qrs_complexes: premature_qrs_complexes,
      mean_heart_rate: mean_heart_rate.to_i,
      minimum_heart_rate: minimum_heart_rate,
      maximum_heart_rate: maximum_heart_rate
    }
  )
end
