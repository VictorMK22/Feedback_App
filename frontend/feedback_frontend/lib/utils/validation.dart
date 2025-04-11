class Validator {
  // Validate Username
  static String? validateUsername(String? username) {
    if (username == null || username.trim().isEmpty) {
      return 'Username cannot be empty';
    }
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(username)) {
      return 'Username can only contain letters and numbers';
    }
    return null; // Valid
  }

  // Validate Email
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email cannot be empty';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null; // Valid
  }

  // Validate Password
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password cannot be empty';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]+$').hasMatch(password)) {
      return 'Password must include letters and numbers';
    }
    return null; // Valid
  }

  // Validate Confirm Password
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Confirm password cannot be empty';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null; // Valid
  }

  // Validate Phone Number
  static String? validatePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return null; // Optional field
    }
    if (!RegExp(r'^\d{10,15}$').hasMatch(phoneNumber)) {
      return 'Enter a valid phone number (10-15 digits)';
    }
    return null; // Valid
  }

  // Validate Bio (Optional)
  static String? validateBio(String? bio) {
    if (bio != null && bio.length > 200) {
      return 'Bio cannot exceed 200 characters';
    }
    return null; // Valid
  }

  // Validate Feedback Text
  static String? validateFeedback(String? feedback) {
    if (feedback == null || feedback.trim().isEmpty) {
      return 'Feedback cannot be empty';
    }
    return null; // Valid
  }

  // Validate Star Rating
  static String? validateStarRating(double? rating) {
    if (rating == null || rating == 0) {
      return 'Please rate your experience';
    }
    return null; // Valid
  }
}