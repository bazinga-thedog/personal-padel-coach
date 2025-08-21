Pod::Spec.new do |spec|
    spec.name         = "boost"
    spec.version      = "1.84.0"
    spec.summary      = "Boost C++ Libraries"
    spec.homepage     = "https://www.boost.org/"
    spec.license      = { :type => "Boost Software License", :file => "LICENSE_1_0.txt" }
    spec.authors      = { "Boost Authors" => "boost.org" }
    spec.source       = {
      :git => "https://github.com/boostorg/boost.git",
      :tag => "boost-1.84.0"
    }
    spec.platform     = :ios, "12.0"
    spec.requires_arc = false
    spec.header_mappings_dir = "boost"
    spec.preserve_paths = "boost"
    spec.source_files = "boost/**/*.hpp"
  end