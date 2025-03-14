<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>Legacy Todo App (Pre-Containerization)</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            position: relative;
            min-height: 100vh;
        }
        .todo-item {
            border: 1px solid #ddd;
            margin: 10px 0;
            padding: 10px;
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
        }
        .completed {
            background-color: #e8f5e9;
        }
        button {
            padding: 5px 10px;
            margin: 0 5px;
        }
        input[type="text"] {
            padding: 5px;
            width: 300px;
        }
        .todo-content {
            flex-grow: 1;
            margin-right: 20px;
        }
        .todo-actions {
            display: flex;
            flex-direction: column;
            align-items: flex-end;
        }
        .todo-dates {
            font-size: 0.8em;
            color: #666;
            margin-top: 5px;
        }
        .todo-buttons {
            margin-bottom: 10px;
        }
        .sort-buttons, .filter-buttons {
            margin: 20px 0;
            padding: 10px;
            background-color: #f5f5f5;
            border-radius: 5px;
        }
        .sort-buttons button, .filter-buttons button {
            background-color: #fff;
            border: 1px solid #ddd;
            border-radius: 3px;
        }
        .sort-buttons button.active, .filter-buttons button.active {
            background-color: #e3f2fd;
            border-color: #2196f3;
        }
        .version-info {
            position: fixed;
            bottom: 10px;
            right: 10px;
            font-size: 0.8em;
            color: #666;
            text-align: right;
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
            background-color: #ff9800;
            color: white;
            padding: 5px 10px;
            border-radius: 4px;
            font-size: 12px;
            z-index: 1000;
        }
    </style>
</head>
<body>
    <div class="version-badge">Pre-Containerization Version</div>
    <div class="about-link">
        <a href="about.jsp">About</a>
    </div>
    
    <h1>Legacy Todo Application</h1>
    
    <div id="add-todo">
        <input type="text" id="todo-title" placeholder="Todo title">
        <input type="text" id="todo-description" placeholder="Description">
        <button onclick="addTodo()">Add Todo</button>
    </div>

    <div class="filter-buttons">
        <span>Filter: </span>
        <button id="filter-all" onclick="filterTodos('all')" class="active">All</button>
        <button id="filter-active" onclick="filterTodos('active')">Active</button>
        <button id="filter-completed" onclick="filterTodos('completed')">Completed</button>
    </div>

    <div class="sort-buttons">
        <span>Sort by creation date: </span>
        <button id="sort-newest" onclick="sortTodos('newest')" class="active">Newest First</button>
        <button id="sort-oldest" onclick="sortTodos('oldest')">Oldest First</button>
    </div>

    <div id="todo-list">
        <!-- Todos will be loaded here -->
    </div>

    <div class="version-info">
        Tomcat Version: <%= application.getServerInfo() %><br>
        Java Version: <%= System.getProperty("java.version") %>
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
            fetch('/legacy-todo/api/todos')
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

            fetch('/legacy-todo/api/todos', {
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
            fetch('/legacy-todo/api/todos/' + id, {
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
            fetch('/legacy-todo/api/todos/' + id, {
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