class ExampleTask {
  ExampleTask({
    required this.id,
    required this.title,
    required this.priority,
    required this.createdAt,
  });

  final int id;
  final String title;
  final int priority;
  final DateTime createdAt;
}

final List<ExampleTask> kExampleTasks = [
  ExampleTask(
    id: 1,
    title: 'Prepare quarterly report',
    priority: 1,
    createdAt: DateTime(2024, 1, 10),
  ),
  ExampleTask(
    id: 2,
    title: 'Fix login bug',
    priority: 2,
    createdAt: DateTime(2024, 1, 14),
  ),
  ExampleTask(
    id: 3,
    title: 'Refactor data layer',
    priority: 3,
    createdAt: DateTime(2024, 2, 1),
  ),
  ExampleTask(
    id: 4,
    title: 'Design new dashboard',
    priority: 2,
    createdAt: DateTime(2024, 2, 5),
  ),
  ExampleTask(
    id: 5,
    title: 'Write API documentation',
    priority: 1,
    createdAt: DateTime(2024, 2, 20),
  ),
  ExampleTask(
    id: 6,
    title: 'Prepare release notes',
    priority: 2,
    createdAt: DateTime(2024, 3, 1),
  ),
  ExampleTask(
    id: 7,
    title: 'Review pull requests',
    priority: 3,
    createdAt: DateTime(2024, 3, 3),
  ),
  ExampleTask(
    id: 8,
    title: 'Optimize database indexes',
    priority: 2,
    createdAt: DateTime(2024, 3, 5),
  ),
  ExampleTask(
    id: 9,
    title: 'Customer onboarding call',
    priority: 1,
    createdAt: DateTime(2024, 3, 8),
  ),
  ExampleTask(
    id: 10,
    title: 'Security audit follow-up',
    priority: 3,
    createdAt: DateTime(2024, 3, 12),
  ),
  ExampleTask(
    id: 11,
    title: 'Build analytics dashboard',
    priority: 2,
    createdAt: DateTime(2024, 3, 15),
  ),
  ExampleTask(
    id: 12,
    title: 'Migrate legacy reports',
    priority: 2,
    createdAt: DateTime(2024, 3, 20),
  ),
  ExampleTask(
    id: 13,
    title: 'Team retrospective meeting',
    priority: 1,
    createdAt: DateTime(2024, 3, 22),
  ),
  ExampleTask(
    id: 14,
    title: 'Prototype new feature A',
    priority: 3,
    createdAt: DateTime(2024, 3, 25),
  ),
  ExampleTask(
    id: 15,
    title: 'Prototype new feature B',
    priority: 2,
    createdAt: DateTime(2024, 3, 28),
  ),
  ExampleTask(
    id: 16,
    title: 'Write unit tests',
    priority: 1,
    createdAt: DateTime(2024, 4, 2),
  ),
  ExampleTask(
    id: 17,
    title: 'Upgrade dependencies',
    priority: 2,
    createdAt: DateTime(2024, 4, 4),
  ),
  ExampleTask(
    id: 18,
    title: 'Benchmark performance',
    priority: 3,
    createdAt: DateTime(2024, 4, 6),
  ),
  ExampleTask(
    id: 19,
    title: 'Fix flaky tests',
    priority: 2,
    createdAt: DateTime(2024, 4, 8),
  ),
  ExampleTask(
    id: 20,
    title: 'Improve error messages',
    priority: 1,
    createdAt: DateTime(2024, 4, 10),
  ),
  ExampleTask(
    id: 21,
    title: 'Add feature flags',
    priority: 2,
    createdAt: DateTime(2024, 4, 12),
  ),
  ExampleTask(
    id: 22,
    title: 'Refine onboarding flow',
    priority: 1,
    createdAt: DateTime(2024, 4, 15),
  ),
  ExampleTask(
    id: 23,
    title: 'Conduct user interviews',
    priority: 3,
    createdAt: DateTime(2024, 4, 18),
  ),
  ExampleTask(
    id: 24,
    title: 'Polish UI for launch',
    priority: 2,
    createdAt: DateTime(2024, 4, 20),
  ),
  ExampleTask(
    id: 25,
    title: 'Launch post-mortem review',
    priority: 1,
    createdAt: DateTime(2024, 4, 25),
  ),
];
