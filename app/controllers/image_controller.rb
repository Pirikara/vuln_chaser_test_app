require 'mini_magick'
require 'image_processing/mini_magick'
require 'tempfile'
require 'base64'

class ImageController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def process_with_mini_magick
    image_data = params[:image_data]
    filename = params[:filename] || 'image.jpg'
    operation = params[:operation] || 'resize'
    
    if image_data.blank?
      render json: { error: 'No image data provided' }
      return
    end
    
    begin
      temp_file = Tempfile.new([filename, '.tmp'])
      temp_file.binmode
      temp_file.write(Base64.decode64(image_data))
      temp_file.close
      
      image = MiniMagick::Image.open(temp_file.path)
      
      case operation
      when 'resize'
        size = params[:size] || '100x100'
        image.resize(size)
      when 'convert'
        format = params[:format] || 'jpg'
        image.format(format)
      when 'custom'
        command = params[:command] || 'identify'
        result = image.run_command(command, temp_file.path)
      end
      
      processed_data = Base64.encode64(File.binread(image.path))
      
      render json: {
        message: 'Image processed with MiniMagick',
        processed_image: processed_data[0..100] + '...',
        original_filename: filename,
        operation: operation,
        size: File.size(image.path)
      }
    rescue => e
      render json: {
        error: e.message,
        library: 'mini_magick',
        vulnerable: true
      }
    ensure
      temp_file&.unlink
      image&.destroy!
    end
  end
  
  def process_with_image_processing
    image_data = params[:image_data]
    processor_options = params[:options] || {}
    
    if image_data.blank?
      render json: { error: 'No image data provided' }
      return
    end
    
    begin
      temp_file = Tempfile.new(['processing', '.jpg'])
      temp_file.binmode
      temp_file.write(Base64.decode64(image_data))
      temp_file.close
      
      processed = ImageProcessing::MiniMagick
        .source(temp_file.path)
        .apply(processor_options)
      
      if params[:save_options]
        processed = processed.call(save: params[:save_options])
      else
        processed = processed.call
      end
      
      processed_data = Base64.encode64(File.binread(processed.path))
      
      render json: {
        message: 'Image processed with ImageProcessing',
        processed_image: processed_data[0..100] + '...',
        options_used: processor_options,
        size: File.size(processed.path)
      }
    rescue => e
      render json: {
        error: e.message,
        library: 'image_processing',
        vulnerable: true
      }
    ensure
      temp_file&.unlink
      processed&.unlink
    end
  end
  
  
  def batch_process_images
    images = params[:images] || []
    batch_options = params[:batch_options] || {}
    
    if images.empty?
      render json: { error: 'No images provided' }
      return
    end
    
    results = []
    
    images.each_with_index do |image_data, index|
      begin
        temp_file = Tempfile.new(["batch_#{index}", '.jpg'])
        temp_file.binmode
        temp_file.write(Base64.decode64(image_data[:data]))
        temp_file.close
        
        method = image_data[:method] || batch_options[:default_method] || 'mini_magick'
        
        case method
        when 'mini_magick'
          image = MiniMagick::Image.open(temp_file.path)
          if batch_options[:command]
            system("#{batch_options[:command]} #{temp_file.path}")
          else
            image.resize(image_data[:size] || '50x50')
          end
          processed_path = image.path
          
        when 'rmagick'
          raise StandardError, "RMagick processing not available"
        end
        
        processed_data = Base64.encode64(File.binread(processed_path))
        
        results << {
          index: index,
          status: 'success',
          method: method,
          size: File.size(processed_path),
          data: processed_data[0..50] + '...'
        }
        
      rescue => e
        results << {
          index: index,
          status: 'error',
          error: e.message,
          method: method
        }
      ensure
        temp_file&.unlink
        File.unlink(processed_path) if defined?(processed_path) && File.exist?(processed_path)
        image&.destroy! if defined?(image) && image.respond_to?(:destroy!)
        images&.each(&:destroy!) if defined?(images)
      end
    end
    
    render json: {
      message: 'Batch processing completed',
      results: results,
      batch_options: batch_options,
      total_processed: results.count { |r| r[:status] == 'success' }
    }
  end
  
  def imagemagick_info
    begin
      mini_magick_version = MiniMagick.imagemagick_version
      rmagick_version = 'Not available (RMagick not installed)'
      
      imagemagick_features = MiniMagick::Tool::Identify.new do |identify|
        identify << '-list' << 'configure'
      end.call rescue 'Unable to get features'
      
      render json: {
        message: 'ImageMagick information',
        mini_magick_version: mini_magick_version,
        rmagick_version: rmagick_version,
        imagemagick_features: imagemagick_features[0..500] + '...',
        vulnerable_note: 'Version information can reveal known vulnerabilities'
      }
    rescue => e
      render json: {
        error: e.message,
        vulnerable_note: 'Error handling may leak system information'
      }
    end
  end
end
