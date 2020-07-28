#!/usr/bin/env ruby

require "sinatra"
require "csv"
require "json"

ONE_MINUTE_IN_MS = 1000 * 60
ONE_SECOND_IN_MS = 1000

post "/delineation" do
  if !params[:data] || !params[:data][:tempfile]
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
  minimum_onset = nil
  maximum_onset = nil
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
    minimum_onset = onset if minimum_onset.nil? || onset < minimum_onset
    maximum_onset = onset if maximum_onset.nil? || onset > maximum_onset

    if last_heart_beat_at.nil?
      last_heart_beat_at = onset
    else
      minutes = (onset - last_heart_beat_at).to_f / ONE_MINUTE_IN_MS
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
  end

  mean_heart_rate = (
    (qrs_complexes - 1) /
    ((maximum_onset - minimum_onset).to_f / ONE_MINUTE_IN_MS)
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
