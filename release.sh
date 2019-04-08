version=$(grep VERSION lib/version.rb| cut -d \" -f2)
git commit -am $version && git tag $version && git push --tags && git push && gem build term-slides.gemspec && gem push term-slides-$version.gem

