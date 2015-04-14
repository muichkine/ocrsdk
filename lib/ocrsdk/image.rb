class OCRSDK::Image < OCRSDK::AbstractEntity
  include OCRSDK::Verifiers::Language
  include OCRSDK::Verifiers::Format
  include OCRSDK::Verifiers::Profile

  def initialize(image_path)
    super()
    @image_path = image_path
  end

  def as_text(languages)
    xml_string = api_process_image @image_path, languages, :txt, :text_extraction

    OCRSDK::Promise.from_response xml_string
  end

  def as_text_sync(languages, wait_interval=OCRSDK.config.default_poll_time)
    as_text(languages).wait(wait_interval).result.force_encoding('utf-8')
  end

  def as_xml(languages, profile=:text_extraction)
    xml_string = api_process_image @image_path, languages, :xml, profile

    OCRSDK::Promise.from_response xml_string
  end

  def as_xml_sync(languages, wait_interval=OCRSDK.config.default_poll_time, profile=:text_extraction)
    as_xml(languages, profile).wait(wait_interval).result.force_encoding('utf-8')
  end

  def as_pdf(languages)
    xml_string = api_process_image @image_path, languages, :pdf_text_and_images, :document_conversion

    OCRSDK::Promise.from_response xml_string
  end

  def as_pdf_sync(languages, out_path=nil, wait_interval=OCRSDK.config.default_poll_time)
    result = as_pdf(languages).wait(wait_interval).result

    if out_path.nil?
      result
    else
      File.open(out_path, 'wb+') {|f| f.write result }
    end
  end

  def as_receipt(countries = [], extendedCharacterInfo = false)
    xml_string = api_process_receipt @image_path, countries, extendedCharacterInfo

    OCRSDK::Promise.from_response xml_string
  end

private

  # TODO handle 4xx and 5xx responses and errors, file not found error
  # http://ocrsdk.com/documentation/apireference/processImage/
  def api_process_image(image_path, languages, format=:txt, profile=:document_conversion)
    raise OCRSDK::UnsupportedInputFormat   unless supported_input_format? File.extname(image_path)[1..-1]
    raise OCRSDK::UnsupportedOutputFormat  unless supported_output_format? format
    raise OCRSDK::UnsupportedProfile       unless supported_profile? (profile)

    params = URI.encode_www_form(
        language: languages_to_s(languages).join(','),
        exportFormat: format_to_s(format),
        profile: profile_to_s(profile))

    self.api_process image_path, URI.join(@url, '/processImage', "?#{params}")
  end

  def api_process_receipt(image_path, countries = [], extendedCharacterInfo = false)
    raise OCRSDK::UnsupportedInputFormat   unless supported_input_format? File.extname(image_path)[1..-1]

    params = URI.encode_www_form(
        writeExtendedCharacterInfo: extendedCharacterInfo.to_s)

    self.api_process image_path, URI.join(@url, '/processReceipt', "?#{params}")
  end

  def api_process(image_path, uri)
    retryable tries: OCRSDK.config.number_or_retries, on: OCRSDK::NetworkError, sleep: OCRSDK.config.retry_wait_time do
      begin
        RestClient.post uri.to_s, upload: { file: File.new(image_path, 'rb') }
      rescue RestClient::ExceptionWithResponse
        raise OCRSDK::NetworkError
      end
    end
  end

end
