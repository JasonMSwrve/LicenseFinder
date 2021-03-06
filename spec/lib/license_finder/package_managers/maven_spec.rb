require 'spec_helper'

module LicenseFinder
  describe Maven do
    subject { Maven.new(project_path: Pathname('/fake/path')) }

    it_behaves_like "a PackageManager"

    def license_xml(xml)
      <<-resp
        <?xml version="1.0" encoding="UTF-8" standalone="no"?>
        <licenseSummary>
          <dependencies>
            #{xml}
          </dependencies>
        </licenseSummary>
      resp
    end

    describe '.current_packages' do
      before do
        allow(subject).to receive('`').with('cd /fake/path && mvn license:download-licenses')
      end

      def stub_license_report(deps)
        fake_file = double(:license_report, read: license_xml(deps))
        allow(subject).to receive(:license_report).and_return(fake_file)
      end

      it 'lists all the current packages' do
        stub_license_report("
          <dependency>
            <artifactId>junit</artifactId>
            <version>4.11</version>
          </dependency>
          <dependency>
            <artifactId>hamcrest-core</artifactId>
            <version>1.3</version>
           </dependency>
        ")

        expect(subject.current_packages.map { |p| [p.name, p.version] }).to eq [
          ["junit", "4.11"],
          ["hamcrest-core", "1.3"]
        ]
      end

      it "handles multiple licenses" do
        stub_license_report("
          <dependency>
            <licenses>
              <license>
                <name>License 1</name>
              </license>
              <license>
                <name>License 2</name>
              </license>
            </licenses>
          </dependency>
        ")

        expect(subject.current_packages.first.licenses.map(&:name)).to eq ['License 1', 'License 2']
      end

      it "handles no licenses" do
        stub_license_report("
          <dependency>
          </dependency>
        ")

        expect(subject.current_packages.first.licenses.map(&:name)).to eq ['unknown']
      end
    end
  end
end
