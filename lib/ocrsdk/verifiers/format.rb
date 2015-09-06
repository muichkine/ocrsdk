module OCRSDK::Verifiers::Format
  # http://ocrsdk.com/documentation/specifications/image-formats/
  INPUT_FORMATS = [:bmp, :dcx, :pcx, :png, :jp2, :jpc, :jpg, :jpeg, :jfif, :pdf, 
    :tif, :tiff, :gif, :djvu, :djv, :jb2].freeze

  # http://ocrsdk.com/documentation/apireference/processImage/
  OUTPUT_FORMATS = [:txt, :rtf, :docx, :xlsx, :pptx, :pdf_searchable, :pdfa,
    :pdf_text_and_images, :xml, :xml_for_corrected_image, :alto].freeze

  def formats_to_s(formats)
    formats.map{ |f| self.format_to_s f }.join(',')
  end

  def format_to_s(format)
    format.to_s.camelize(:lower)
  end

  def supported_input_format?(format)
    format = format.downcase.to_sym  if format.kind_of? String

    INPUT_FORMATS.include? format
  end

  def supported_output_format?(format)
    format = format.underscore.to_sym  if format.kind_of? String

    OUTPUT_FORMATS.include? format
  end

end
