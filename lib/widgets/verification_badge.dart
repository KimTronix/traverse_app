import 'package:flutter/material.dart';
import '../services/verification_service.dart';
import '../utils/theme.dart';

class VerificationBadge extends StatelessWidget {
  final Map<String, dynamic> verificationStatus;
  final bool showText;
  final double iconSize;

  const VerificationBadge({
    super.key,
    required this.verificationStatus,
    this.showText = true,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (verificationStatus.isEmpty) {
      return _buildUnverifiedBadge();
    }

    final verificationLevel = VerificationService.getVerificationLevel(verificationStatus);
    final statusText = VerificationService.getVerificationStatusText(verificationStatus);

    return _buildVerifiedBadge(verificationLevel, statusText);
  }

  Widget _buildUnverifiedBadge() {
    if (!showText) {
      return Icon(
        Icons.verified_user_outlined,
        size: iconSize,
        color: Colors.grey[400],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: iconSize,
          color: Colors.grey[400],
        ),
        const SizedBox(width: 4),
        Text(
          'Unverified',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: iconSize * 0.75,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedBadge(int level, String statusText) {
    Color badgeColor;
    IconData badgeIcon;

    switch (level) {
      case 5: // Premium
        badgeColor = const Color(0xFFFFD700); // Gold
        badgeIcon = Icons.verified;
        break;
      case 4: // Business
        badgeColor = AppTheme.primaryBlue;
        badgeIcon = Icons.business_center;
        break;
      case 3: // Identity
        badgeColor = AppTheme.primaryGreen;
        badgeIcon = Icons.verified_user;
        break;
      case 2: // Phone
        badgeColor = AppTheme.primaryBlue;
        badgeIcon = Icons.phone_android;
        break;
      case 1: // Email
      default:
        badgeColor = AppTheme.primaryGreen;
        badgeIcon = Icons.verified;
        break;
    }

    if (!showText) {
      return Icon(
        badgeIcon,
        size: iconSize,
        color: badgeColor,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          badgeIcon,
          size: iconSize,
          color: badgeColor,
        ),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: TextStyle(
            color: badgeColor,
            fontSize: iconSize * 0.75,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class VerificationCard extends StatelessWidget {
  final Map<String, dynamic> verificationStatus;

  const VerificationCard({
    super.key,
    required this.verificationStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Verification Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildVerificationList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationList() {
    if (verificationStatus.isEmpty) {
      return _buildVerificationItem(
        'Email Verification',
        'Not verified',
        Icons.email_outlined,
        false,
      );
    }

    return Column(
      children: [
        _buildVerificationItem(
          'Email Verification',
          verificationStatus.containsKey('email') ? 'Verified' : 'Not verified',
          Icons.email,
          verificationStatus.containsKey('email'),
        ),
        if (verificationStatus.containsKey('phone'))
          _buildVerificationItem(
            'Phone Verification',
            'Verified',
            Icons.phone_android,
            true,
          ),
        if (verificationStatus.containsKey('identity'))
          _buildVerificationItem(
            'Identity Verification',
            'Verified',
            Icons.badge,
            true,
          ),
        if (verificationStatus.containsKey('business'))
          _buildVerificationItem(
            'Business Verification',
            'Verified',
            Icons.business_center,
            true,
          ),
        if (verificationStatus.containsKey('premium'))
          _buildVerificationItem(
            'Premium Verification',
            'Verified',
            Icons.stars,
            true,
          ),
      ],
    );
  }

  Widget _buildVerificationItem(
    String title,
    String status,
    IconData icon,
    bool isVerified,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: isVerified ? AppTheme.primaryGreen : Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: isVerified ? AppTheme.primaryGreen : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isVerified ? Icons.check_circle : Icons.circle_outlined,
            color: isVerified ? AppTheme.primaryGreen : Colors.grey[400],
            size: 20,
          ),
        ],
      ),
    );
  }
}

class VerificationPrompt extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;

  const VerificationPrompt({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryBlue,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}