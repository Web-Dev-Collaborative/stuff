file pkg("foreman-#{version}-mingw32.gem") => distribution_files do |t|
  Bundler.with_clean_env do
    sh "env PLATFORM=mingw32 gem build foreman.gemspec"
  end
  sh "mv foreman-#{version}-mingw32.gem #{t.name}"
end

task "mingw32:build" => pkg("foreman-#{version}-mingw32.gem")

task "mingw32:clean" do
  clean pkg("foreman-#{version}-mingw32.gem")
end

task "mingw32:release" => "mingw32:build" do |t|
  sh "gem push #{pkg("foreman-#{version}-mingw32.gem")} || echo 'error'"
end
