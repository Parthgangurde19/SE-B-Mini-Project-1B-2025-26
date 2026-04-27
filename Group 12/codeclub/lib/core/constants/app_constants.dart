/// App-wide constants for CodeClub application
library;

/// Application name and branding constants
class AppConstants {
  AppConstants._();

  static const String appName = 'CodeClub';
  static const String appTagline = 'Find Your Perfect Hackathon Team';
  
  /// Allowed email domain for APSIT students
  static const String allowedEmailDomain = '@apsit.edu.in';
  
  /// Error messages
  static const String invalidEmailDomain = 
      'Only APSIT student emails (@apsit.edu.in) are allowed';
  static const String networkError = 
      'Please check your internet connection and try again';
  static const String unknownError = 
      'Something went wrong. Please try again later';
  
  /// Success messages
  static const String profileSaved = 'Profile saved successfully!';
  static const String registrationSuccess = 'Registration successful!';
}

/// Available student roles
class StudentRoles {
  StudentRoles._();

  static const List<String> roles = [
    'Developer',
    'Designer',
    'ML Engineer',
    'Team Leader',
  ];
}

/// Available branches at APSIT
class Branches {
  Branches._();

  static const List<String> branches = [
    'Computer Engineering',
    'Information Technology',
    'Electronics & Telecommunication',
    'Mechanical Engineering',
    'Civil Engineering',
    'Artificial Intelligence & Data Science',
    'Artificial Intelligence & Machine Learning',
  ];
}

/// Academic years
class AcademicYears {
  AcademicYears._();

  static const List<String> years = [
    'First Year',
    'Second Year',
    'Third Year',
    'Fourth Year',
  ];
}

/// Common skills for students
class CommonSkills {
  CommonSkills._();

  static const List<String> skills = [
    'Flutter',
    'React',
    'React Native',
    'Node.js',
    'Python',
    'Java',
    'Kotlin',
    'Swift',
    'C++',
    'JavaScript',
    'TypeScript',
    'Firebase',
    'MongoDB',
    'PostgreSQL',
    'MySQL',
    'AWS',
    'Docker',
    'Kubernetes',
    'Machine Learning',
    'Deep Learning',
    'TensorFlow',
    'PyTorch',
    'OpenCV',
    'NLP',
    'Data Science',
    'UI/UX Design',
    'Figma',
    'Adobe XD',
    'Graphic Design',
    'Video Editing',
    'Git',
    'Linux',
    'Blockchain',
    'Web3',
    'IoT',
    'Arduino',
    'Raspberry Pi',
  ];
}
