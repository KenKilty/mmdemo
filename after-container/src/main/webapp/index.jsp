<!DOCTYPE html>
<html>
<head>
    <title>Todo Application</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            margin-bottom: 20px;
        }
        .todo-form {
            margin-bottom: 20px;
        }
        .todo-form input[type="text"],
        .todo-form textarea {
            width: 100%;
            padding: 8px;
            margin-bottom: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        .todo-form textarea {
            height: 100px;
            resize: vertical;
        }
        .todo-form button {
            background-color: #4CAF50;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
        }
        .todo-form button:hover {
            background-color: #45a049;
        }
        .todo-item {
            background-color: #fff;
            padding: 15px;
            margin-bottom: 10px;
            border-radius: 4px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
        }
        .todo-item.completed {
            background-color: #f8f8f8;
            opacity: 0.8;
        }
        .todo-content {
            flex-grow: 1;
        }
        .todo-content h3 {
            margin: 0 0 10px 0;
            color: #333;
        }
        .todo-content p {
            margin: 0 0 10px 0;
            color: #666;
        }
        .todo-dates {
            font-size: 0.9em;
            color: #999;
        }
        .todo-actions {
            margin-left: 20px;
        }
        .todo-buttons button {
            padding: 5px 10px;
            margin-left: 5px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            background-color: #f0f0f0;
            color: #333;
        }
        .todo-buttons button:hover {
            background-color: #e0e0e0;
        }
        .filter-sort {
            margin-bottom: 20px;
            display: flex;
            gap: 10px;
        }
        .filter-sort button {
            padding: 5px 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            background-color: white;
            cursor: pointer;
        }
        .filter-sort button.active {
            background-color: #4CAF50;
            color: white;
            border-color: #4CAF50;
        }
        .version-info {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            color: #666;
            font-size: 0.9em;
        }
        .about-link {
            position: absolute;
            top: 20px;
            right: 20px;
        }
        .about-link a {
            color: #2196f3;
            text-decoration: none;
            font-weight: bold;
        }
        .about-link a:hover {
            text-decoration: underline;
        }
        .version-badge {
            position: fixed;
            top: 10px;
            left: 10px;
            background-color: #4CAF50;
            color: white;
            padding: 5px 10px;
            border-radius: 4px;
            font-size: 12px;
            z-index: 1000;
        }
    </style>
</head>
<body>
    <div class="version-badge">Containerized Version</div>
    <div class="about-link">
        <a href="about.jsp">About</a>
    </div>
    <div class="container">
        <h1>Todo Application</h1>

        <div class="todo-form">
            <input type="text" id="todo-title" placeholder="Enter todo title">
            <textarea id="todo-description" placeholder="Enter todo description"></textarea>
            <button onclick="addTodo()">Add Todo</button>
        </div>

        <div class="filter-sort">
            <div>
                <button id="filter-all" onclick="filterTodos('all')" class="active">All</button>
                <button id="filter-active" onclick="filterTodos('active')">Active</button>
                <button id="filter-completed" onclick="filterTodos('completed')">Completed</button>
            </div>
            <div>
                <button id="sort-newest" onclick="sortTodos('newest')" class="active">Newest First</button>
                <button id="sort-oldest" onclick="sortTodos('oldest')">Oldest First</button>
            </div>
        </div>

        <div id="todo-list">
            <!-- Todos will be loaded here -->
        </div>

        <div class="version-info">
            Tomcat Version: <%= application.getServerInfo() %><br>
            Java Version: <%= System.getProperty("java.version") %>
        </div>
    </div>

    <script>
        let currentTodos = [];
        let currentSort = 'newest';
        let currentFilter = 'all';

        function formatDate(dateString) {
            if (!dateString) return '';
            const date = new Date(dateString);
            return date.toLocaleString();
        }

        function filterTodos(filter) {
            currentFilter = filter;
            
            // Update button styles
            document.getElementById('filter-all').classList.toggle('active', filter === 'all');
            document.getElementById('filter-active').classList.toggle('active', filter === 'active');
            document.getElementById('filter-completed').classList.toggle('active', filter === 'completed');
            
            // Display filtered todos
            displayTodos(currentTodos);
        }

        function sortTodos(sortOrder) {
            currentSort = sortOrder;
            
            // Update button styles
            document.getElementById('sort-newest').classList.toggle('active', sortOrder === 'newest');
            document.getElementById('sort-oldest').classList.toggle('active', sortOrder === 'oldest');
            
            // Sort and display todos
            displayTodos(currentTodos);
        }

        function displayTodos(todos) {
            // Filter todos based on current filter
            let filteredTodos = todos;
            if (currentFilter === 'active') {
                filteredTodos = todos.filter(todo => !todo.completed);
            } else if (currentFilter === 'completed') {
                filteredTodos = todos.filter(todo => todo.completed);
            }

            // Sort todos based on current sort order
            const sortedTodos = [...filteredTodos].sort((a, b) => {
                const dateA = new Date(a.createdAt).getTime();
                const dateB = new Date(b.createdAt).getTime();
                return currentSort === 'newest' ? dateB - dateA : dateA - dateB;
            });

            const todoList = document.getElementById('todo-list');
            todoList.innerHTML = '';
            
            sortedTodos.forEach(todo => {
                const div = document.createElement('div');
                div.className = 'todo-item' + (todo.completed ? ' completed' : '');
                
                const titleText = escapeHtml(todo.title);
                const descriptionText = escapeHtml(todo.description || '');
                const completedText = todo.completed ? 'Undo' : 'Complete';
                const createdAtText = formatDate(todo.createdAt);
                const completedAtText = todo.completed ? formatDate(todo.completedAt) : '';
                
                div.innerHTML = 
                    '<div class="todo-content">' +
                        '<h3>' + titleText + '</h3>' +
                        '<p>' + descriptionText + '</p>' +
                        '<div class="todo-dates">' +
                            '<div>Created: ' + createdAtText + '</div>' +
                            (completedAtText ? '<div>Completed: ' + completedAtText + '</div>' : '') +
                        '</div>' +
                    '</div>' +
                    '<div class="todo-actions">' +
                        '<div class="todo-buttons">' +
                            '<button onclick="toggleTodo(' + todo.id + ', ' + !todo.completed + ', \'' + titleText.replace(/'/g, "\\'") + '\', \'' + descriptionText.replace(/'/g, "\\'") + '\')">' +
                                completedText +
                            '</button>' +
                            '<button onclick="deleteTodo(' + todo.id + ')">Delete</button>' +
                        '</div>' +
                    '</div>';
                
                todoList.appendChild(div);
            });
        }

        function loadTodos() {
            fetch('/todo/api/todos')
                .then(response => response.json())
                .then(todos => {
                    currentTodos = todos;
                    displayTodos(todos);
                })
                .catch(error => console.error('Error loading todos:', error));
        }

        function escapeHtml(unsafe) {
            if (!unsafe) return '';
            return unsafe
                .replace(/&/g, "&amp;")
                .replace(/</g, "&lt;")
                .replace(/>/g, "&gt;")
                .replace(/"/g, "&quot;")
                .replace(/'/g, "&#039;");
        }

        function addTodo() {
            const title = document.getElementById('todo-title').value.trim();
            const description = document.getElementById('todo-description').value.trim();
            
            if (!title) return;

            fetch('/todo/api/todos', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    title: title,
                    description: description,
                    completed: false
                })
            })
            .then(response => {
                if (response.ok) {
                    document.getElementById('todo-title').value = '';
                    document.getElementById('todo-description').value = '';
                    loadTodos();
                }
            })
            .catch(error => console.error('Error adding todo:', error));
        }

        function toggleTodo(id, completed, title, description) {
            fetch('/todo/api/todos/' + id, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    id: id,
                    title: title,
                    description: description,
                    completed: completed
                })
            })
            .then(response => {
                if (response.ok) {
                    loadTodos();
                }
            })
            .catch(error => console.error('Error updating todo:', error));
        }

        function deleteTodo(id) {
            fetch('/todo/api/todos/' + id, {
                method: 'DELETE'
            })
            .then(response => {
                if (response.ok) {
                    loadTodos();
                }
            })
            .catch(error => console.error('Error deleting todo:', error));
        }

        // Load todos when page loads
        loadTodos();
    </script>
</body>
</html> 