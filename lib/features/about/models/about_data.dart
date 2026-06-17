class AboutLink {
  final String label;
  final String url;

  const AboutLink({required this.label, required this.url});
}

class OrgInfo {
  final String name;
  final String description;
  final String? contactEmail;
  final String? contactPhone;
  final String? websiteUrl;
  final List<AboutLink> links;

  const OrgInfo({
    required this.name,
    required this.description,
    this.contactEmail,
    this.contactPhone,
    this.websiteUrl,
    this.links = const [],
  });

  bool get hasContact =>
      contactEmail != null || contactPhone != null || websiteUrl != null;

  static const OrgInfo defaultInfo = OrgInfo(
    name: 'AppAmbit',
    description:
        'AppAmbit is a powerful content management platform that enables '
        'organizations to create, manage, and deliver engaging content '
        'experiences across mobile apps.',
    contactEmail: 'hello@appambit.com',
    contactPhone: null,
    websiteUrl: 'https://appambit.com',
    links: [
      AboutLink(
        label: 'Documentation',
        url: 'https://docs.appambit.com',
      ),
      AboutLink(
        label: 'Privacy Policy',
        url: 'https://appambit.com/privacy-policy',
      ),
      AboutLink(
        label: 'Terms of Service',
        url: 'https://appambit.com/terms-of-service',
      ),
      AboutLink(
        label: 'Discord',
        url: 'https://discord.com/invite/nJyetYue2s',
      ),
      AboutLink(
        label: 'GitHub',
        url: 'https://github.com/AppAmbit',
      ),
    ],
  );
}
