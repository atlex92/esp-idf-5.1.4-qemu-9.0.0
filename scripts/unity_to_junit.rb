class UnityToJUnit
    PASS_RESULT = /^(?<file>.*):(?<line>[1-9]+):(?<name>.+):PASS$/
    FAIL_RESULT = /^(?<file>.*):(?<line>[1-9]+):(?<name>.+):FAIL:(?<reason>.+)$/
    SKIP_RESULT = /^(?<file>.*):(?<line>[1-9]+):(?<name>.+):IGNORE:(?<reason>.+)$/

    # Prints conversion to stdout
    #
    # @param input [String] name of input file (Unity output format)
    # @param output [String] name of output file (JUnit XML format)
    def self.parse(input, output)
        test_count = 0
        fail_count = 0
        skip_count = 0

        xml = ""
        result = File.read(input)

        result.each_line do |line|
            pass = PASS_RESULT.match(line)
            fail = FAIL_RESULT.match(line)
            skip = SKIP_RESULT.match(line)

            if pass || fail || skip
                test_count += 1
                test = pass || fail || skip

                xml << "<testcase classname=\"#{File.basename(test[:file])}\" name=\"#{test[:name]}\">"
                
                if fail
                    fail_count += 1
                    xml << "    <failure type=\"ASSERT FAILED\">\"#{fail[:reason]}\"</failure>"
                elsif skip
                    skip_count += 1
                    xml << "    <skipped type=\"TEST IGNORED\">\"#{skip[:reason]}\"</skipped>"
                end

                xml << "</testcase>"
            end
        end

        if test_count > 0
            xml_output = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
            xml_output << "<testsuite tests=\"#{test_count}\" failures=\"#{fail_count}\" skips=\"#{skip_count}\">\n"
            xml_output << xml
            xml_output << "</testsuite>"

            File.open(output, "w") do |file|
                file.write(xml_output)
            end

            puts xml_output
        else
            raise "file is not a unity output"
        end
    end
end

if ARGV.length < 1 || ARGV.length > 2
    puts "Usage: ruby script.rb input_file [output_file]"
    exit 1
end

input_file = ARGV[0]
output_file = ARGV[1] || "tests_report.xml"  # Default output file

UnityToJUnit.parse(input_file, output_file)
