/// Password Strength Validator with Fun Roasting Messages
/// Makes password feedback entertaining while being helpful

class PasswordValidator {
  /// Calculate password strength (0.0 to 1.0)
  static double getStrength(String password) {
    if (password.isEmpty) return 0.0;
    
    double strength = 0.0;
    
    // Length checks
    if (password.length >= 6) strength += 0.15;
    if (password.length >= 8) strength += 0.15;
    if (password.length >= 12) strength += 0.1;
    
    // Character type checks
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.15;
    
    return strength.clamp(0.0, 1.0);
  }

  /// Get strength level
  static PasswordStrength getStrengthLevel(String password) {
    final strength = getStrength(password);
    
    if (strength < 0.3) return PasswordStrength.weak;
    if (strength < 0.5) return PasswordStrength.fair;
    if (strength < 0.7) return PasswordStrength.good;
    if (strength < 0.9) return PasswordStrength.strong;
    return PasswordStrength.excellent;
  }

  /// Get roasting message based on password strength
  static String getRoastMessage(String password, String? userName) {
    if (password.isEmpty) {
      return "Come on, type something! I don't bite... much 😏";
    }

    final strength = getStrengthLevel(password);
    final name = userName?.split(' ').first ?? 'friend';

    switch (strength) {
      case PasswordStrength.weak:
        return _getWeakRoast(password, name);
      case PasswordStrength.fair:
        return _getFairRoast(password, name);
      case PasswordStrength.good:
        return _getGoodMessage(name);
      case PasswordStrength.strong:
        return _getStrongMessage(name);
      case PasswordStrength.excellent:
        return _getExcellentMessage(name);
    }
  }

  static String _getWeakRoast(String password, String name) {
    // Check for common weak patterns
    if (password.toLowerCase() == '123456' || password.toLowerCase() == 'password') {
      return "Really, $name? '${password}'? That's literally the FIRST thing hackers try! 🤦‍♂️";
    }
    if (password.toLowerCase() == password && password.length < 6) {
      return "Hey $name, my grandma could hack this password... and she still uses a flip phone! 📱";
    }
    if (RegExp(r'^[0-9]+$').hasMatch(password)) {
      return "Just numbers, $name? Even my calculator is disappointed 🧮";
    }
    if (password.length < 6) {
      return "That's it? $name, this password is shorter than my patience! Make it at least 6 characters 😤";
    }
    
    final roasts = [
      "Yikes $name! A toddler mashing a keyboard could do better 👶",
      "$name, this password is weaker than gas station coffee ☕",
      "Bruh... even '1234' is laughing at this password 😂",
      "My pet goldfish could guess this, $name. And he's not that smart 🐟",
    ];
    return roasts[password.length % roasts.length];
  }

  static String _getFairRoast(String password, String name) {
    final messages = [
      "Getting warmer, $name! But still not quite there... Add some spice! 🌶️",
      "Meh, $name. It's like a bicycle lock - stops casual thieves but not pros 🚲",
      "C'mon $name, you're almost there! Throw in a symbol or uppercase! 💪",
      "Not terrible, $name, but hackers are having their morning coffee waiting for this one ☕",
    ];
    return messages[password.length % messages.length];
  }

  static String _getGoodMessage(String name) {
    final messages = [
      "Now we're talking, $name! This is pretty solid 💪",
      "Nice one, $name! Hackers would need a few coffee breaks for this ☕",
      "Looking good, $name! Add one more symbol for extra bragging rights ⭐",
      "Decent work, $name! Your accounts are getting safer 🛡️",
    ];
    return messages[DateTime.now().second % messages.length];
  }

  static String _getStrongMessage(String name) {
    final messages = [
      "Ooh la la, $name! This password means business! 🔐",
      "Now THAT'S what I'm talking about, $name! Fort Knox level! 🏰",
      "Impressive, $name! Hackers just closed their laptops in defeat 💻❌",
      "You're a security pro, $name! This password is chef's kiss 👨‍🍳💋",
    ];
    return messages[DateTime.now().second % messages.length];
  }

  static String _getExcellentMessage(String name) {
    final messages = [
      "LEGENDARY, $name! 🏆 This password could guard the Crown Jewels!",
      "Holy security, Batman! $name, you've created a digital fortress! 🦇",
      "Wow $name, even the FBI would need a vacation after trying this one! 🕵️",
      "$name, this password is so strong it does push-ups! 💪💪💪",
      "Absolute unit of a password, $name! Hackers are crying into their hoodies 😭",
    ];
    return messages[DateTime.now().second % messages.length];
  }

  /// Check if password meets minimum requirements
  static bool isValid(String password) {
    return password.length >= 6;
  }

  /// Get requirements list
  static List<PasswordRequirement> getRequirements(String password) {
    return [
      PasswordRequirement(
        text: 'At least 6 characters',
        isMet: password.length >= 6,
      ),
      PasswordRequirement(
        text: 'Contains uppercase letter',
        isMet: password.contains(RegExp(r'[A-Z]')),
      ),
      PasswordRequirement(
        text: 'Contains lowercase letter',
        isMet: password.contains(RegExp(r'[a-z]')),
      ),
      PasswordRequirement(
        text: 'Contains number',
        isMet: password.contains(RegExp(r'[0-9]')),
      ),
      PasswordRequirement(
        text: 'Contains special character',
        isMet: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      ),
    ];
  }
}

enum PasswordStrength {
  weak,
  fair,
  good,
  strong,
  excellent,
}

class PasswordRequirement {
  final String text;
  final bool isMet;

  PasswordRequirement({required this.text, required this.isMet});
}

/// Extension to get color for strength
extension PasswordStrengthColor on PasswordStrength {
  String get colorHex {
    switch (this) {
      case PasswordStrength.weak:
        return '#EF4444'; // Red
      case PasswordStrength.fair:
        return '#F97316'; // Orange
      case PasswordStrength.good:
        return '#EAB308'; // Yellow
      case PasswordStrength.strong:
        return '#22C55E'; // Green
      case PasswordStrength.excellent:
        return '#10B981'; // Emerald
    }
  }

  String get label {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak 😬';
      case PasswordStrength.fair:
        return 'Fair 🤔';
      case PasswordStrength.good:
        return 'Good 👍';
      case PasswordStrength.strong:
        return 'Strong 💪';
      case PasswordStrength.excellent:
        return 'Excellent 🔥';
    }
  }
}
