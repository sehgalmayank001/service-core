module ServiceCore
  class Error < StandardError; end

  # Raised when a value object access (Response#[], Response#[]=) targets
  # a key that is not one of the four allowed response keys.
  class InvalidKey < Error; end

  # Raised by `field` when a declared name would shadow a method that
  # the gem itself defines on every service.
  class ReservedFieldName < Error; end
end
