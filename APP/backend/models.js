class ApiResponse {
  constructor({success = false, error = null, validation = null, data = null} = {}) {
    this.success = success;
    this.error = error;
    this.validation = validation;
    this.data = data;
  }

  static successResponse(data) {
    return new ApiResponse({
      success: true, 
      data
    });
  }

  static errorResponse(message) {
    return new ApiResponse({
      success: false,
      error: message
    });
  }

  static validationResponse(errors) {
    return new ApiResponse({
      success: false,
      validation: errors
    });
  }
}

module.exports = ApiResponse;