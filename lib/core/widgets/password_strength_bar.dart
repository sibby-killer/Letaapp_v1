import 'package:flutter/material.dart';
import '../utils/password_validator.dart';

/// Password Strength Bar Widget with Fun Roasting Messages
class PasswordStrengthBar extends StatelessWidget {
  final String password;
  final String? userName;
  final bool showRequirements;

  const PasswordStrengthBar({
    super.key,
    required this.password,
    this.userName,
    this.showRequirements = false,
  });

  @override
  Widget build(BuildContext context) {
    final strength = PasswordValidator.getStrength(password);
    final strengthLevel = PasswordValidator.getStrengthLevel(password);
    final roastMessage = PasswordValidator.getRoastMessage(password, userName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength Bar
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: password.isEmpty ? 0 : strength,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getColor(strengthLevel)),
            minHeight: 8,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Strength Label and Roast Message
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getColor(strengthLevel).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                strengthLevel.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getColor(strengthLevel),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Roast Message
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getColor(strengthLevel).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getColor(strengthLevel).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Text(
                _getEmoji(strengthLevel),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  roastMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Requirements Checklist (optional)
        if (showRequirements) ...[
          const SizedBox(height: 12),
          ...PasswordValidator.getRequirements(password).map((req) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  req.isMet ? Icons.check_circle : Icons.circle_outlined,
                  size: 16,
                  color: req.isMet ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  req.text,
                  style: TextStyle(
                    fontSize: 12,
                    color: req.isMet ? Colors.green[700] : Colors.grey[600],
                    decoration: req.isMet ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }

  Color _getColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return const Color(0xFFEF4444);
      case PasswordStrength.fair:
        return const Color(0xFFF97316);
      case PasswordStrength.good:
        return const Color(0xFFEAB308);
      case PasswordStrength.strong:
        return const Color(0xFF22C55E);
      case PasswordStrength.excellent:
        return const Color(0xFF10B981);
    }
  }

  String _getEmoji(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return '😰';
      case PasswordStrength.fair:
        return '🤨';
      case PasswordStrength.good:
        return '😊';
      case PasswordStrength.strong:
        return '😎';
      case PasswordStrength.excellent:
        return '🤩';
    }
  }
}

/// Compact version for inline use
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = PasswordValidator.getStrength(password);
    final strengthLevel = PasswordValidator.getStrengthLevel(password);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: password.isEmpty ? 0 : strength,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getColor(strengthLevel)),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          strengthLevel.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _getColor(strengthLevel),
          ),
        ),
      ],
    );
  }

  Color _getColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return const Color(0xFFEF4444);
      case PasswordStrength.fair:
        return const Color(0xFFF97316);
      case PasswordStrength.good:
        return const Color(0xFFEAB308);
      case PasswordStrength.strong:
        return const Color(0xFF22C55E);
      case PasswordStrength.excellent:
        return const Color(0xFF10B981);
    }
  }
}
