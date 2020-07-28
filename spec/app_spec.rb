require File.expand_path("../spec_helper.rb", __FILE__)

require "active_support/all"

def data_file(name)
  Rack::Test::UploadedFile.new(File.expand_path("../data/#{name}", __FILE__))
end

describe "Cardiologs" do
  it "returns correct data for minimal data file" do
    post "/delineation", data: data_file("minimal.csv"), starts_at: "2020-07-28"

    expect(last_response).to be_ok

    json_body = JSON.parse(last_response.body)

    expect(json_body.deep_symbolize_keys).to eq({
      premature_p_waves: 2,
      premature_qrs_complexes: 3,
      mean_heart_rate: 49,
      minimum_heart_rate: {
        rate: 49,
        starts_at: "2020-07-28 00:00:02 +0200"
      },
      maximum_heart_rate: {
        rate: 49,
        starts_at: "2020-07-28 00:00:02 +0200"
      }
    })
  end

  it "returns correct data for full data file" do
    post "/delineation", data: data_file("records.csv"), starts_at: "2020-07-28"

    expect(last_response).to be_ok

    json_body = JSON.parse(last_response.body)

    expect(json_body.deep_symbolize_keys).to eq({
      premature_p_waves: 315,
      premature_qrs_complexes: 149,
      mean_heart_rate: 65,
      minimum_heart_rate: {
        rate: 17,
        starts_at: "2020-07-28 00:30:36 +0200"
      },
      maximum_heart_rate: {
        rate: 600,
        starts_at: "2020-07-28 10:27:57 +0200"
      }
    })
  end
end
