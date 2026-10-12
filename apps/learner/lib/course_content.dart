// Course structure only. Teaching and activity content has been removed.
part 'extended_content.dart';
class Topic {
  const Topic(this.id, this.chapter, this.title, {this.goal = '', this.lesson = '', this.example = '', this.output = ''});
  final String id, title, goal, lesson, example, output;
  final int chapter;
  bool get ready => lesson.isNotEmpty;
}
const chapters = ['Functions and Variables', 'Conditionals', 'Loops', 'Exceptions', 'Libraries', 'Unit Tests', 'File I/O', 'Regular Expressions', 'Object-Oriented Programming', 'Et Cetera', 'Final Project and Course Assessment'];
const starterTopics = <Topic>[
  Topic('python-c0-t0', 0, 'Running and saving Python programs'),
  Topic('python-c0-t1', 0, 'print, strings, and comments'),
  Topic('python-c0-t2', 0, 'Variables and assignment'),
  Topic('python-c0-t3', 0, 'input and string methods'),
  Topic('python-c0-t4', 0, 'Numbers and conversion'),
  Topic('python-c0-t5', 0, 'Arithmetic and formatted output'),
  Topic('python-c0-t6', 0, 'Functions and parameters'),
  Topic('python-c0-t7', 0, 'Return values and program structure'),
];
// Retained chapter and topic structure.
const draftOutlines = <int, List<String>>{
  1: ['Comparisons and Boolean values', 'if, elif, and else', 'and, or, and not', 'Boundary values and decision tables', 'Nested conditions', 'Truthiness and match statements'],
  2: ['while loops and termination', 'for loops and range', 'Lists and iteration', 'Dictionaries and iteration', 'Counters and accumulators'],
  3: ['Understanding an exception traceback', 'Recovering from invalid numeric input', 'Raising and propagating errors'],
  4: ['Importing a standard library module', 'Choosing an API and reading its documentation', 'Isolating project dependencies'],
  5: ['Checking a function with assert', 'Testing boundaries and failure cases', 'Writing an independent test suite'],
  6: ['Opening, reading and closing a text file', 'Writing structured records', 'Validating loaded data'],
  7: ['Matching a simple text pattern', 'Searching and extracting a group', 'Testing a pattern against edge cases'],
  8: ['Defining a class and creating objects', 'Separating instance data from class data', 'Designing a small object interface'],
  9: ['Comprehensions and generators', 'Describing interfaces with type hints', 'Refactoring a program without changing its behaviour'],
  10: ['Planning a final project', 'Collecting evidence and tests', 'Final assessment and reflection'],
};
List<Topic> get courseTopics => [...starterTopics, ...extendedTopics];
Topic topicById(String id) => courseTopics.firstWhere((t) => t.id == id);

class Exercise {
  const Exercise({required this.id, required this.topic, required this.category, required this.type, required this.title, required this.prompt, this.options = const [], this.answer = '', this.accepted = const [], this.tests = const [], this.hints = const [], this.solution = '', this.required = true});
  final String id, topic, category, type, title, prompt, answer, solution;
  final List<String> options, accepted, hints;
  final List<Map<String, dynamic>> tests;
  final bool required;
  Map<String, dynamic> get marking => {'id': id, 'type': type, 'answer': answer, 'accepted': accepted, 'tests': tests};
}
const starterExercises = <Exercise>[];
List<Exercise> get exercises => [...starterExercises, ...extendedExercises];
List<Exercise> forTopic(String topic, String category) => exercises.where((e) => e.topic == topic && e.category == category).toList();
