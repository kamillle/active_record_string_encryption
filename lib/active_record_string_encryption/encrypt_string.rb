# frozen_string_literal: true

module ActiveRecordStringEncryption
  class EncryptString < ActiveRecord::Type::String
    class << self
      def key_len
        ActiveSupport::MessageEncryptor.key_len(ActiveRecordStringEncryption.configuration.cipher_alg)
      end
    end

    # ActiveRecord calls `serialize` to convert Ruby objects to a format that can be understood by database
    def serialize(value)
      # expects same behavior as ActiveRecord::Type::String other than encryption
      # https://github.com/rails/rails/blob/5-0-stable/activemodel/lib/active_model/type/immutable_string.rb
      v = super(value)
      encryptor.encrypt_and_sign(v) if v.present?
    end

    # ActiveRecord calls `deserialize` to convert values stored database to Ruby objects
    def deserialize(value)
      # expects same behavior as ActiveRecord::Type::String other than decryption
      # https://github.com/rails/rails/blob/5-0-stable/activemodel/lib/active_model/type/value.rb#L21-L23
      v = super(value)
      encryptor.decrypt_and_verify(v) if v.present?
    end

    private

    def encryptor
      # TODO: rotate
      ActiveSupport::MessageEncryptor.new(secret, cipher: ActiveRecordStringEncryption.configuration.cipher_alg)
    end

    def secret
      ActiveSupport::KeyGenerator.new(secret_key).generate_key(salt, self.class.key_len)
    end

    def secret_key
      ActiveRecordStringEncryption.configuration.secret_key
    end

    def salt
      ActiveRecordStringEncryption.configuration.salt
    end
  end
end
