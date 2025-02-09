class UnsafeDeserializationInteractor
  include Interactor

  def call
    unsafe_data = Base64.decode64(context.data)
    context.object = Marshal.load(unsafe_data) # 安全でないデシリアライゼーション
  rescue => e
    context.fail!(error: "Deserialization failed: #{e.message}")
  end
end