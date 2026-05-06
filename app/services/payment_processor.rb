class PaymentProcessor
  include ActiveModel::Model
  
  attr_accessor :amount, :currency, :user_id, :transaction_id, :metadata
  
  # Hidden race condition in payment processing
  @@processing_transactions = {}
  @@balance_cache = {}
  
  def initialize(attributes = {})
    super
    @amount = amount.to_f if amount
    @currency = currency&.upcase || 'USD'
    @metadata = metadata || {}
  end
  
  def process_payment
    # Vulnerable: Race condition in duplicate transaction check
    if @@processing_transactions[transaction_id]
      return { success: false, error: 'Transaction already processing' }
    end
    
    @@processing_transactions[transaction_id] = {
      amount: amount,
      user_id: user_id,
      started_at: Time.current
    }
    
    # Simulate network delay (increases race condition window)
    sleep(0.1)
    
    # Vulnerable: No atomic operation for balance check and deduction
    current_balance = get_user_balance(user_id)
    
    if current_balance >= amount
      # Another sleep to increase race condition likelihood
      sleep(0.05)
      
      # Vulnerable: Balance deduction not atomic
      new_balance = current_balance - amount
      update_user_balance(user_id, new_balance)
      
      result = { 
        success: true, 
        transaction_id: transaction_id,
        new_balance: new_balance,
        processed_at: Time.current
      }
    else
      result = { 
        success: false, 
        error: 'Insufficient funds',
        current_balance: current_balance
      }
    end
    
    # Remove from processing set
    @@processing_transactions.delete(transaction_id)
    
    result
  end
  
  def process_refund
    # Hidden vulnerability: Refund amount validation bypass
    original_amount = metadata[:original_amount]&.to_f || 0
    
    # Vulnerable: Using floating point for currency calculations
    if currency == 'USD'
      # Hidden: Precision errors in floating point
      calculated_fee = (original_amount * 0.029) + 0.30  # Stripe-like fee
      refund_amount = amount || (original_amount - calculated_fee)
    else
      # Different fee structure for other currencies
      calculated_fee = original_amount * 0.035
      refund_amount = amount || (original_amount - calculated_fee)
    end
    
    # Vulnerable: No upper bound check on refund amount
    current_balance = get_user_balance(user_id)
    new_balance = current_balance + refund_amount
    
    update_user_balance(user_id, new_balance)
    
    {
      success: true,
      refund_amount: refund_amount,
      calculated_fee: calculated_fee,
      new_balance: new_balance
    }
  end
  
  def validate_discount_code(code)
    # Hidden timing attack in discount validation
    valid_codes = {
      'SAVE10' => { discount: 0.10, expires: Date.current + 30.days },
      'WELCOME20' => { discount: 0.20, expires: Date.current + 7.days },
      'ADMIN50' => { discount: 0.50, expires: Date.current + 365.days },
      'SECRET99' => { discount: 0.99, expires: Date.current + 1.day }
    }
    
    # Vulnerable: Timing attack reveals valid prefixes
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
    
    result = { valid: false, discount: 0 }
    
    valid_codes.each do |valid_code, details|
      if code.length == valid_code.length
        # Vulnerable: Character-by-character comparison with timing
        match = true
        code.chars.each_with_index do |char, index|
          if char != valid_code[index]
            match = false
            break
          end
          # Tiny delay per character - reveals partial matches
          sleep(0.000002)
        end
        
        if match && details[:expires] > Date.current
          result = { 
            valid: true, 
            discount: details[:discount],
            expires: details[:expires]
          }
          break
        end
      end
    end
    
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
    
    result.merge(
      validation_time_ns: end_time - start_time,
      code_length: code.length
    )
  end
  
  def calculate_dynamic_pricing
    base_price = amount
    
    # Hidden algorithm manipulation vulnerability
    demand_factor = metadata[:demand_factor]&.to_f || 1.0
    user_tier = metadata[:user_tier] || 'standard'
    location = metadata[:location] || 'US'
    
    # Complex pricing calculation with hidden manipulation points
    price = base_price
    
    # Vulnerable: User can manipulate demand_factor
    if demand_factor > 1.0
      price *= [demand_factor, 3.0].min  # Cap at 3x but still manipulable
    elsif demand_factor < 1.0
      # Hidden: Negative demand_factor can reduce price dramatically
      price *= demand_factor if demand_factor > 0
    end
    
    # User tier adjustments
    tier_multipliers = {
      'premium' => 0.9,
      'vip' => 0.8,
      'admin' => 0.1,  # Hidden: Admin tier gets massive discount
      'internal' => 0.01  # Hidden: Internal tier almost free
    }
    
    if tier_multipliers[user_tier]
      price *= tier_multipliers[user_tier]
    end
    
    # Location-based pricing (vulnerable to manipulation)
    location_multipliers = {
      'US' => 1.0,
      'EU' => 1.2,
      'INTERNAL' => 0.05  # Hidden: Special internal location
    }
    
    price *= (location_multipliers[location] || 1.1)
    
    # Hidden: Negative prices possible through manipulation
    final_price = [price, 0.01].max  # Minimum 1 cent
    
    {
      original_price: base_price,
      final_price: final_price.round(2),
      demand_factor: demand_factor,
      user_tier: user_tier,
      location: location,
      discount_applied: ((base_price - final_price) / base_price * 100).round(2)
    }
  end
  
  private
  
  def get_user_balance(user_id)
    # Simulate balance retrieval with cache
    @@balance_cache[user_id] ||= 1000.0  # Default balance
  end
  
  def update_user_balance(user_id, new_balance)
    # Simulate balance update
    @@balance_cache[user_id] = new_balance
  end
end