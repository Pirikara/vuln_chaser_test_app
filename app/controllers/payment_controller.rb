class PaymentController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def process_transaction
    processor = PaymentProcessor.new(
      amount: params[:amount],
      currency: params[:currency],
      user_id: params[:user_id],
      transaction_id: params[:transaction_id] || SecureRandom.uuid,
      metadata: params[:metadata] || {}
    )
    
    result = processor.process_payment
    
    render json: {
      message: 'Transaction processed',
      result: result,
      timestamp: Time.current.iso8601
    }
  end
  
  def process_refund
    processor = PaymentProcessor.new(
      amount: params[:refund_amount],
      currency: params[:currency],
      user_id: params[:user_id],
      metadata: params[:metadata] || {}
    )
    
    result = processor.process_refund
    
    render json: {
      message: 'Refund processed',
      result: result,
      timestamp: Time.current.iso8601
    }
  end
  
  def validate_discount
    processor = PaymentProcessor.new
    
    result = processor.validate_discount_code(params[:code] || '')
    
    render json: {
      message: 'Discount code validated',
      result: result,
      timestamp: Time.current.iso8601
    }
  end
  
  def calculate_price
    processor = PaymentProcessor.new(
      amount: params[:base_price],
      metadata: params[:pricing_metadata] || {}
    )
    
    result = processor.calculate_dynamic_pricing
    
    render json: {
      message: 'Price calculated',
      result: result,
      timestamp: Time.current.iso8601
    }
  end
end