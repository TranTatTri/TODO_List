//Họ và tên: Trần Tất Trí
//MSSV: 20126030
//20VP
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'Noti.dart';
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  var initializationSettingsAndroid = AndroidInitializationSettings('mipmap/ic_launcher');
  var initializationSettingsIOS = DarwinInitializationSettings();
  var initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<TodoItem> _todos = [];
  List<TodoItem> _filteredTodos = [];
  FilterType _filterType = FilterType.All;
  String _searchText ='';

  //Save state của từng nút
  bool _allSelected = true;
  bool _todaySelected = false;
  bool _upcomingSelected = false;

  @override
  void initState(){
    super.initState();
    Noti.initialize(flutterLocalNotificationsPlugin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: Row(
          children: [
            IconButton(
              onPressed: () {
              },
              icon: const Icon(Icons.search),
            ),
            Expanded(
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search',
                  border: InputBorder.none,
                  //fillColor: Color
                ),
              ),
            ),
          ],
        ),
      ),
      body: _searchText.isNotEmpty ? _buildSuggestions() : _buildTodoList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTodoDialog();
        },
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),

      bottomNavigationBar: BottomAppBar(
        height: 92,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    _filterTasks(FilterType.All);
                    setState(() {
                      _allSelected = true;
                      _todaySelected = false;
                      _upcomingSelected = false;
                    });
                  },
                  icon: Icon(Icons.list, color: _allSelected ? Colors.deepPurple : null),
                ),
                Text('All'),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    _filterTasks(FilterType.Today);
                    setState(() {
                      _allSelected = false;
                      _todaySelected = true;  
                      _upcomingSelected = false;
                    });
                  },
                  icon: Icon(Icons.today, color: _todaySelected ? Colors.deepPurple : null),
                ),
                Text('Today'),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    _filterTasks(FilterType.Upcoming);
                    setState(() {
                      _allSelected = false;
                      _todaySelected = false;
                      _upcomingSelected = true;
                    });
                  },
                  icon: Icon(Icons.upcoming, color: _upcomingSelected ? Colors.deepPurple : null),
                ),
                Text('Upcoming'),
              ],
            ),
          ]
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    final List<Suggestion> suggestions = _findSuggestions(_searchText);
    if (suggestions.isEmpty) {
      return Center(
        child: Text('Not found information'),
      );
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          title: Text(suggestion.todo),
          subtitle: Text(_formatDate(suggestion.dateTime)),
          trailing: IconButton(
            onPressed: () {
              _showDeleteConfirmationDialog(index); // Hiển thị hộp thoại xác nhận xóa khi bấm vào icon thùng rác
            },
            icon: Icon(Icons.delete),
          ),
          onTap: () {
            // Chuyển hướng đến trang chứa task tương ứng
          },
        );
      },
    );
  }

  List<Suggestion> _findSuggestions(String searchText) {
    // Tìm kiếm các task có tên gần giống với chuỗi tìm kiếm và trả về danh sách gợi ý
    final List<TodoItem> filteredTasks = _todos.where((todo) => todo.todo.toLowerCase().contains(searchText.toLowerCase())).toList();
    final List<Suggestion> suggestions = filteredTasks.map((todo) => Suggestion(todo: todo.todo, dateTime: todo.dateTime)).toList();
    return suggestions;
  }

  // Kiểm tra xem một task đã hoàn thành chưa dựa trên thời gian
  bool _isTaskCompleted(DateTime taskDateTime) {
    final currentTime = DateTime.now();
    // Kiểm tra xem thời gian hiện tại đã qua thời gian của task chưa
    if (currentTime.isAfter(taskDateTime)) {
      return true; // Đánh dấu là đã hoàn thành nếu thời gian hiện tại đã qua thời gian của task
    }
    return false;
  }

  Widget _buildTodoList(){
    return ListView.builder(
        itemCount: _filteredTodos.length,
        itemBuilder: (context, index) {
          final TodoItem todo = _filteredTodos[index];
          final bool isCompleted = _isTaskCompleted(todo.dateTime);
          return ListTile(
            title: Text(
              '${todo.todo}${isCompleted ? " - Đã hoàn thành" : ""}',
              style: TextStyle(
                fontStyle: isCompleted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            subtitle: Text(_formatDate(_filteredTodos[index].dateTime)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCompleted)
                  IconButton(
                    onPressed: () {
                      _showEditTodoDialog(index);
                    },
                    icon: const Icon(Icons.edit),
                  ),
                IconButton(
                  onPressed: () {
                    _showDeleteConfirmationDialog(index);
                  },
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
          );
        },
      );
  }
  void _showAddTodoDialog() {
    String newTodo = '';
    DateTime? selectedDate;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  newTodo = value;
                },
                decoration: InputDecoration(labelText: 'Add Task'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                    onPressed: () async {
                      selectedDate = await _selectDate(context);
                      if (selectedDate != null) {
                        _addTodoToList(newTodo, selectedDate!);
                        // Kiểm tra xem nếu còn 10 phút trước khi đến hạn
                        DateTime tenMinutesBeforeDueTime = selectedDate!.subtract(Duration(minutes: 10));
                        if (DateTime.now().isBefore(tenMinutesBeforeDueTime)) {
                          Noti.showTenMinutesNotification(
                            title: 'Task Due Soon',
                            body: 'Your task "$newTodo" is due in 10 minutes!',
                            fln: flutterLocalNotificationsPlugin,
                          );
                        }
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text('Add Task'),
                  ),
            ],
          ),
        );
      },
    );
  }
  //Chọn thời gian cho TAsk đang đăng ký
  Future<DateTime?> _selectDate(BuildContext context) async {
  // Lựa chọn ngày
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(2100),
  );

  if (pickedDate != null) {
    // Lựa chọn giờ
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      // Kết hợp ngày và giờ đã chọn thành DateTime mới
      return DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    }
  }
  return null;
}

  void _addTodoToList(String todo, DateTime date) {
    setState(() {
      final newTodo = TodoItem(todo: todo, dateTime: date);
      _todos.add(newTodo);
      _filteredTodos = _todos;
      /*
      // Kiểm tra nếu thời gian task còn lại ít hơn hoặc bằng 10 phút, hiển thị thông báo
      if (date.difference(DateTime.now()).inMinutes <= 10) {
        Noti.showTenMinutesNotification(
          id: _todos.length, // Đặt ID của thông báo
          title: 'Còn 10 phút',
          body: 'Task $todo còn 10 phút nữa là hết hạn',
          fln: flutterLocalNotificationsPlugin,
        );
      }*/
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  void _showEditTodoDialog(int index) {
    String editedTodo = _filteredTodos[index].todo;
    DateTime editedDateTime = _filteredTodos[index].dateTime;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) {
                      editedTodo = value;
                    },
                    decoration: InputDecoration(labelText: 'Edit Task'),
                    controller: TextEditingController(text: _filteredTodos[index].todo),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final DateTime? newDateTime = await _selectDate(editedDateTime as BuildContext);
                      if (newDateTime != null) {
                        setState(() {
                          editedDateTime = newDateTime;
                        });
                      }
                    },
                    child: Text('Change Date and Time'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _editTodoInList(index, editedTodo, editedDateTime);
                      Navigator.of(context).pop();
                    },
                    child: Text('Save Changes'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  //Chỉnh sửa và xóa Task đã đăng ký
  void _editTodoInList(int index, String editedTodo, DateTime editedDateTime) {
    setState(() {
      _filteredTodos[index] = TodoItem(todo: editedTodo, dateTime: _filteredTodos[index].dateTime);
    });
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteTodoFromList(index);
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTodoFromList(int index) {
    setState(() {
      _filteredTodos.removeAt(index);
    });
  }

  void _filterTasks(FilterType filterType) {
    setState(() {
      _filterType = filterType;
      if (filterType == FilterType.All) {
        _filteredTodos = _todos;
      } else if (filterType == FilterType.Today) {
        _filteredTodos = _todos.where((todo) => todo.dateTime.day == DateTime.now().day).toList();
      } else if (filterType == FilterType.Upcoming) {
        _filteredTodos = _todos.where((todo) => todo.dateTime.isAfter(DateTime.now())).toList();
      }
    });
  }
}
//Thời gian của cái Task
class TodoItem {
    final String todo;
    final DateTime dateTime;
    bool isCompleted;
    TodoItem({required this.todo, required this.dateTime, this.isCompleted = false});
}

enum FilterType {
  All,
  Today,
  Upcoming,
}
//Gợi ý khi tìm kiếm
class Suggestion {
  final String todo;
  final DateTime dateTime;

  Suggestion({required this.todo, required this.dateTime});
}