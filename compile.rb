if ENV.key?('TVIP_COMMON_HOME')
  file_list File.join(ENV['TVIP_COMMON_HOME'], 'compile.rb')
elsif Dir.exist?(File.join(__dir__, 'tvip-common'))
  file_list 'tvip-common/compile.rb', from: :current
end

include_directory 'src'
source_file 'src/tvip_axi_pkg.sv'
