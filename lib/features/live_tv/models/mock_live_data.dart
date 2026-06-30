import 'live_tv_models.dart';

const mockChannels = [
  LiveChannel(id: 'ch1', name: 'Channel 1'),
  LiveChannel(id: 'ch2', name: 'Channel 2'),
];

final mockSchedule = {
  'ch1': [
    LiveProgram(
      id: '1',
      startTime: '9:30 AM',
      endTime: '9:40 AM',
      title: 'Kia Mau',
      description:
          'A fun sing-along performing arts series for children. (R)',
      season: '2',
      episode: '22',
      rating: 'G',
      duration: '10 Mins',
    ),
    LiveProgram(
      id: '2',
      startTime: '9:40 AM',
      endTime: '9:48 AM',
      title: 'Tamariki Haka',
      description:
          'Children from kura across the country showcase their haka skills. (R)',
      season: '3',
      episode: '6',
      rating: 'G',
      duration: '8 Mins',
    ),
    LiveProgram(
      id: '3',
      startTime: '9:48 AM',
      endTime: '10:17 AM',
      title: 'Te Nūtube Haka',
      description:
          'Join Te Haakura and Atareta on the adventure of creating their own kapa haka group. (R)',
      season: '1',
      episode: '6',
      rating: 'G',
      duration: '29 Mins',
    ),
    LiveProgram(
      id: '4',
      startTime: '10:17 AM',
      endTime: '10:31 AM',
      title: 'Haka Life Wharekura',
      description:
          'Follow reigning champions, Te Wharekura o Hoani Waititi Marae, as they compete. (R)',
      episode: '5',
      rating: 'G',
      duration: '14 Mins',
    ),
    LiveProgram(
      id: '5',
      startTime: '10:31 AM',
      endTime: '11:00 AM',
      title: 'Pukuhohe',
      description:
          'Game show testing the language skills of two teams. (R)',
      season: '3',
      episode: '14',
      rating: 'G',
      duration: '29 Mins',
    ),
  ],
  'ch2': [
    LiveProgram(
      id: '6',
      startTime: '9:00 AM',
      endTime: '10:00 AM',
      title: 'Morning Show',
      description: 'Start your day with the latest news and stories. (R)',
      season: '1',
      episode: '45',
      rating: 'G',
      duration: '60 Mins',
    ),
    LiveProgram(
      id: '7',
      startTime: '10:00 AM',
      endTime: '10:30 AM',
      title: 'Culture Today',
      description: 'Exploring cultural events and traditions. (R)',
      season: '2',
      episode: '12',
      rating: 'G',
      duration: '30 Mins',
    ),
    LiveProgram(
      id: '8',
      startTime: '10:30 AM',
      endTime: '11:00 AM',
      title: 'Music Hour',
      description: 'The best local and international music. (R)',
      episode: '8',
      rating: 'G',
      duration: '30 Mins',
    ),
  ],
};
