#!/usr/bin/env ruby

require "sinatra"
require "csv"
require "json"

ONE_MINUTE_IN_MS = 1000 * 60

post "/delineation" do
  csv = CSV.new(params[:data][:tempfile])

  premature_p_waves = 0
  premature_qrs_complexes = 0
  minimum_onset = nil
  maximum_onset = nil
  qrs_complexes = 0

  csv.each do |line|
    type, onset, offset, *tags = line

    onset = onset.to_i
    offset = offset.to_i

    if type == "P" && tags.include?("premature")
      premature_p_waves += 1
    end

    if type == "QRS" && tags.include?("premature")
      premature_qrs_complexes += 1
    end

    if type == "QRS"
      qrs_complexes += 1
    end

    if minimum_onset.nil? || onset < minimum_onset
      minimum_onset = onset
    end

    if maximum_onset.nil? || onset > maximum_onset
      maximum_onset = onset
    end
  end

  heart_rate = qrs_complexes / ((maximum_onset - minimum_onset) / ONE_MINUTE_IN_MS)

  JSON.pretty_generate({
    premature_p_waves: premature_p_waves,
    premature_qrs_complexes: premature_qrs_complexes,
    heart_rate: heart_rate,
  })
end
