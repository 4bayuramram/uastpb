import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async'; // Import dart:async untuk menggunakan Timer

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes App',
      theme: ThemeData(primarySwatch: Colors.lightGreen),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => NotesPage()));
              },
              child: Text('Get Started'),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.lightGreen,
              ),
              child: Text(
                'Navigation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            buildDrawerItem(context, Icons.notes, 'Notes', NotesPage()),
            buildDrawerItem(context, Icons.notifications, 'Reminder', ReminderPage()),
            buildDrawerItem(context, Icons.calendar_today, 'Calendar', CalendarPage()),
            buildDrawerItem(context, Icons.notifications, 'Reminder', ReminderPage()),
            buildDrawerItem(context, Icons.check_circle, 'To-Do List', ToDoListPage()),
          ],
        ),
      ),
    );
  }

  ListTile buildDrawerItem(BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, size: 28),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close the drawer
        // Navigate to the respective page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}

class Note {
  int? id; // Change to nullable to handle auto-increment ID
  String title;
  String text;

  Note({
    this.id,
    required this.title,
    required this.text,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'text': text,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      text: map['text'],
    );
  }
}

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String _title = '';
  String _text = '';
  List<Note> _notes = [];
  Database? _database;
  TextEditingController _titleController = TextEditingController();
  TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _loadNotes();
  }

  Future<void> _initializeDatabase() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'notes.db');

    // Open the database and create the table if it doesn't exist
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE notes (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, text TEXT)',
        );
      },
    );
  }

  Future<void> _loadNotes() async {
    if (_database == null) return;

    // Fetch all notes from the database
    List<Map<String, dynamic>> results = await _database!.query('notes');

    setState(() {
      _notes = results.map((note) => Note.fromMap(note)).toList();
    });
  }

  Future<void> _addNote() async {
    if (_database == null) return;

    // Insert new note to the database
    await _database!.insert(
      'notes',
      {'title': _titleController.text, 'text': _textController.text},
    );

    // Clear the input fields and reload the notes
    setState(() {
      _titleController.clear();
      _textController.clear();
      _loadNotes();
    });
  }

  Future<void> _deleteNote(int id) async {
    if (_database == null) return;

    // Delete note from the database
    await _database!.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Reload the notes
    setState(() {
      _loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _titleController,
                onChanged: (value) {
                  setState(() {
                    _title = value;
                  });
                },
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Masukkan judul',
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: _textController,
                onChanged: (value) {
                  setState(() {
                    _text = value;
                  });
                },
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: 'Masukkan teks',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addNote,
                child: Text('Add Note'),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    return Dismissible(
                      key: Key(_notes[index].id.toString()),
                      onDismissed: (direction) async {
                        // Remove the item from the database and the list
                        await _deleteNote(_notes[index].id!);
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20.0),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      child: ListTile(
                        title: Text(_notes[index].title),
                        subtitle: Text(_notes[index].text),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  DateTime _firstDay = DateTime.utc(2022, 1, 1);
  DateTime _lastDay = DateTime.utc(2022, 12, 31);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TableCalendar(
            //   firstDay: _firstDay,
            //   lastDay: _lastDay,
            //   focusedDay: _focusedDay,
            //   calendarFormat: _calendarFormat,
            //   selectedDayPredicate: (day) {
            //     return isSameDay(_selectedDay, day);
            //   },
            //   onDaySelected: (selectedDay, focusedDay) {
            //     setState(() {
            //       _selectedDay = selectedDay;
            //       _focusedDay = focusedDay;
            //     });
            //   },
            //   onPageChanged: (focusedDay) {
            //     _focusedDay = focusedDay;
            //   },
            // ),
            SizedBox(height: 20),
            Text('Selected Day: $_selectedDay'),
          ],
        ),
      ),
    );
  }
}

class ReminderPage extends StatefulWidget {
  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  String _reminderText = '';
  List<String> _reminders = [];
  List<DateTime> _reminderDates = [];
  TextEditingController _reminderController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
        _reminderController.text = _selectedDate.toLocal().toString().split(' ')[0];
      });
  }

  void _deleteReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
      _reminderDates.removeAt(index);
    });
  }

  void _addReminder() {
    String reminderText = _reminderController.text.trim();
    if (reminderText.isNotEmpty) {
      setState(() {
        _reminders.add(reminderText);
        _reminderDates.add(_selectedDate);
        _reminderController.clear();
        _selectedDate = DateTime.now();
      });
    }
  }

  void _startCountdown(int index) {
    // Calculate remaining days
    DateTime now = DateTime.now();
    Duration difference = _reminderDates[index].isAfter(now) ? _reminderDates[index].difference(now) : now.difference(_reminderDates[index]);
    int remainingDays = difference.inDays;

    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingDays > 0) {
          remainingDays -= 1;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _showReminderDetails(BuildContext context, String reminder) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reminder Details'),
          content: Text(reminder),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reminder'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    controller: _reminderController,
                    onChanged: (value) {
                      // You can add any logic you want when the user types in the text field
                    },
                    decoration: InputDecoration(
                      labelText: 'Add a new reminder',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text('Select Date'),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addReminder,
              child: Text('Add Reminder'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _reminders.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: Key(_reminders[index]),
                    onDismissed: (direction) {
                      _deleteReminder(index);
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20.0),
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    child: ListTile(
                      title: Text(_reminders[index]),
                      subtitle: Text('Reminder Date: ${_reminderDates[index].toString().substring(0, 10)}'),
                      onTap: () {
                        _startCountdown(index);
                        _showReminderDetails(context, _reminders[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ToDoListPage extends StatefulWidget {
  @override
  _ToDoListPageState createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> {
  List<String> _todoList = [];
  List<bool> _isCompletedList = [];
  TextEditingController _todoController = TextEditingController();

  void _addTodo() {
    String todoText = _todoController.text.trim();
    if (todoText.isNotEmpty) {
      setState(() {
        _todoList.add(todoText);
        _isCompletedList.add(false);
        _todoController.clear();
      });
    }
  }

  void _removeTodo(int index) {
    setState(() {
      _todoList.removeAt(index);
      _isCompletedList.removeAt(index);
    });
  }

  void _toggleCompletion(int index) {
    setState(() {
      _isCompletedList[index] = !_isCompletedList[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _todoController,
              onChanged: (value) {
                // You can add any logic you want when the user types in the text field
              },
              onSubmitted: (value) {
                _addTodo();
              },
              decoration: InputDecoration(
                labelText: 'Add a new task',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addTodo,
              child: Text('Add Task'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _todoList.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: Key(_todoList[index]),
                    onDismissed: (direction) {
                      _removeTodo(index);
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20.0),
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: _isCompletedList[index],
                      onChanged: (value) {
                        _toggleCompletion(index);
                      },
                      title: Text(_todoList[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
