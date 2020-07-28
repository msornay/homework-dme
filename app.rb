#!/usr/bin/env ruby

require "sinatra"
require "csv"
require "json"

post "/delineation" do
  csv = CSV.new(params[:data][:tempfile])

  premature_p_waves = 0
  premature_qrs_complexes = 0

  csv.each do |line|
    type, onset, offset, *tags = line

    if type == "P" && tags.include?("premature")
      premature_p_waves += 1
    end

    if type == "QRS" && tags.include?("premature")
      premature_qrs_complexes += 1
    end
  end

  JSON.pretty_generate({
    premature_p_waves: premature_p_waves,
    premature_qrs_complexes: premature_qrs_complexes,
  })
end
