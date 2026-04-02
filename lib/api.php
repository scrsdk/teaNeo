<?php
header("Content-Type: application/json; charset=UTF-8");
$conn = new mysqli("localhost", "q97902ug_app", "Molotov321", "q97902ug_app");

if ($conn->connect_error) die(json_encode(["status" => "error", "message" => "Connection failed"]));

$action = $_POST['action'] ?? '';

// 1. ОБНОВЛЕНИЕ СТАТУСА (ОНЛАЙН)
if ($action == 'update_status') {
    $username = $_POST['username'] ?? '';
    if ($username) {
        $stmt = $conn->prepare("UPDATE users SET last_seen = NOW() WHERE username = ?");
        $stmt->bind_param("s", $username);
        $stmt->execute();
        echo json_encode(["status" => "success"]);
    }
}

// 2. ПРОВЕРКА СУЩЕСТВОВАНИЯ ПОЛЬЗОВАТЕЛЯ
elseif ($action == 'check_user') {
    $phone = $_POST['phone'] ?? '';
    $stmt = $conn->prepare("SELECT username, verify FROM users WHERE phone=?");
    $stmt->bind_param("s", $phone);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($row = $result->fetch_assoc()) {
        echo json_encode(["status" => "success", "exists" => true, "username" => $row['username'], "verify" => $row['verify']]);
    } else {
        echo json_encode(["status" => "success", "exists" => false]);
    }
}

// 3. АВТОРИЗАЦИЯ ИЛИ РЕГИСТРАЦИЯ
elseif ($action == 'auth') {
    $phone = $_POST['phone'] ?? '';
    $password = $_POST['password'] ?? '';
    $username = $_POST['username'] ?? '';

    $stmt = $conn->prepare("SELECT * FROM users WHERE phone=?");
    $stmt->bind_param("s", $phone);
    $stmt->execute();
    $res = $stmt->get_result();

    if ($row = $res->fetch_assoc()) {
        if (password_verify($password, $row['password'])) {
            echo json_encode(["status" => "success", "user" => [
                "username" => $row['username'],
                "phone" => $row['phone'],
                "verify" => $row['verify'],
                "photo" => $row['photo'] ?? '',
                "bio" => $row['bio'] ?? ''
            ]]);
        } else {
            echo json_encode(["status" => "error", "message" => "Неверный пароль"]);
        }
    } else {
        $hash = password_hash($password, PASSWORD_DEFAULT);
        $stmt = $conn->prepare("INSERT INTO users (phone, username, password, last_seen) VALUES (?, ?, ?, NOW())");
        $stmt->bind_param("sss", $phone, $username, $hash);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success", "user" => ["username" => $username, "phone" => $phone, "verify" => 0]]);
        } else {
            echo json_encode(["status" => "error", "message" => "Ошибка регистрации"]);
        }
    }
}

// 4. ПОЛУЧИТЬ ЧАТЫ (С ОНЛАЙН СТАТУСОМ, НЕПРОЧИТАННЫМИ И СТАТУСОМ ПОСЛЕДНЕГО СООБЩЕНИЯ)
elseif ($action == 'get_chats') {
    $user = $_POST['username'] ?? '';
    $stmt = $conn->prepare("
        SELECT m.*, u.verify, u.photo, u.last_seen, (u.last_seen > (NOW() - INTERVAL 2 MINUTE)) as is_online,
        (SELECT COUNT(*) FROM messages WHERE sender = u.username AND receiver = ? AND is_read = 0) as unread_count
        FROM messages m
        JOIN users u ON (u.username = CASE WHEN m.sender = ? THEN m.receiver ELSE m.sender END)
        WHERE m.sender=? OR m.receiver=?
        ORDER BY m.id DESC
    ");
    $stmt->bind_param("ssss", $user, $user, $user, $user);
    $stmt->execute();
    $result = $stmt->get_result();
    $chats = [];
    $seen = [];

    while ($row = $result->fetch_assoc()) {
        $other = ($row['sender'] == $user) ? $row['receiver'] : $row['sender'];
        if ($other == $user || in_array($other, $seen)) continue;
        $seen[] = $other;

        $chats[] = [
            'username' => $other,
            'last_message' => $row['message'],
            'last_sender' => $row['sender'],
            'is_read' => (int)$row['is_read'],
            'time' => date('H:i', strtotime($row['created_at'])),
            'unread' => (int)$row['unread_count'],
            'verify' => $row['verify'],
            'photo' => $row['photo'],
            'is_online' => (int)$row['is_online']
        ];
    }
    echo json_encode(["status" => "success", "data" => $chats]);
}

// 5. ПОЛУЧИТЬ СТАТУС КОНКРЕТНОГО ПОЛЬЗОВАТЕЛЯ
elseif ($action == 'get_user_status') {
    $target = $_POST['target'] ?? '';
    $stmt = $conn->prepare("SELECT last_seen, (last_seen > (NOW() - INTERVAL 2 MINUTE)) as is_online FROM users WHERE username = ?");
    $stmt->bind_param("s", $target);
    $stmt->execute();
    $res = $stmt->get_result()->fetch_assoc();
    if ($res) {
        echo json_encode(["status" => "success", "is_online" => (int)$res['is_online'], "last_seen" => $res['last_seen']]);
    } else {
        echo json_encode(["status" => "error"]);
    }
}

// 6. ПОМЕТИТЬ СООБЩЕНИЯ КАК ПРОЧИТАННЫЕ
elseif ($action == 'read_messages') {
    $me = $_POST['my_username'] ?? '';
    $other = $_POST['other_username'] ?? '';
    $stmt = $conn->prepare("UPDATE messages SET is_read = 1 WHERE sender = ? AND receiver = ?");
    $stmt->bind_param("ss", $other, $me);
    if ($stmt->execute()) echo json_encode(["status" => "success"]);
}

// --- ОСТАЛЬНЫЕ МЕТОДЫ ---

elseif ($action == 'send_message') {
    $sender = $_POST['sender'] ?? '';
    $receiver = $_POST['receiver'] ?? '';
    $message = $_POST['message'] ?? '';
    $reply_to = $_POST['reply_to_id'] ?? null;
    $stmt = $conn->prepare("INSERT INTO messages (sender, receiver, message, reply_to_id) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("sssi", $sender, $receiver, $message, $reply_to);
    if ($stmt->execute()) echo json_encode(["status" => "success"]);
}
elseif ($action == 'get_messages') {
    $sender = $_POST['sender'] ?? '';
    $receiver = $_POST['receiver'] ?? '';
    $stmt = $conn->prepare("SELECT * FROM messages WHERE (sender=? AND receiver=?) OR (sender=? AND receiver=?) ORDER BY created_at ASC");
    $stmt->bind_param("ssss", $sender, $receiver, $receiver, $sender);
    $stmt->execute();
    $result = $stmt->get_result();
    $messages = [];
    while ($row = $result->fetch_assoc()) { $messages[] = $row; }
    echo json_encode(["status" => "success", "data" => $messages]);
}
elseif ($action == 'search') {
    $query = $_POST['query'] ?? '';
    $search = "%{$query}%";
    $stmt = $conn->prepare("SELECT username, phone, verify, photo FROM users WHERE username LIKE ? LIMIT 20");
    $stmt->bind_param("s", $search);
    $stmt->execute();
    $result = $stmt->get_result();
    $users = [];
    while ($row = $result->fetch_assoc()) { $users[] = $row; }
    echo json_encode(["status" => "success", "data" => $users]);
}
elseif ($action == 'add_contact') {
    $owner = $_POST['owner'] ?? '';
    $contact = $_POST['contact'] ?? '';
    $stmt = $conn->prepare("INSERT IGNORE INTO contacts (owner_username, contact_username) VALUES (?, ?)");
    $stmt->bind_param("ss", $owner, $contact);
    $stmt->execute();
    echo json_encode(["status" => "success"]);
}
elseif ($action == 'get_contacts') {
    $owner = $_POST['owner'] ?? '';
    $stmt = $conn->prepare("SELECT c.contact_username as username, u.phone, u.verify, u.photo, (u.last_seen > (NOW() - INTERVAL 2 MINUTE)) as is_online FROM contacts c JOIN users u ON c.contact_username = u.username WHERE c.owner_username = ? ORDER BY c.contact_username ASC");
    $stmt->bind_param("s", $owner);
    $stmt->execute();
    $res = $stmt->get_result();
    $contacts = [];
    while ($row = $res->fetch_assoc()) { $contacts[] = $row; }
    echo json_encode(["status" => "success", "data" => $contacts]);
}
elseif ($action == 'delete_chat') {
    $user1 = $_POST['user'] ?? '';
    $user2 = $_POST['target'] ?? '';
    $stmt = $conn->prepare("DELETE FROM messages WHERE (sender=? AND receiver=?) OR (sender=? AND receiver=?)");
    $stmt->bind_param("ssss", $user1, $user2, $user2, $user1);
    if ($stmt->execute()) echo json_encode(["status" => "success"]);
}
elseif ($action == 'edit_message') {
    $id = $_POST['id'] ?? 0;
    $new_text = $_POST['text'] ?? '';
    $stmt = $conn->prepare("UPDATE messages SET message=?, is_edited=1 WHERE id=?");
    $stmt->bind_param("si", $new_text, $id);
    if ($stmt->execute()) echo json_encode(["status" => "success"]);
}
elseif ($action == 'toggle_pin') {
    $id = $_POST['id'] ?? 0;
    $is_pinned = $_POST['is_pinned'] ?? 0;
    $stmt = $conn->prepare("UPDATE messages SET is_pinned=? WHERE id=?");
    $stmt->bind_param("ii", $is_pinned, $id);
    if ($stmt->execute()) echo json_encode(["status" => "success"]);
}
elseif ($action == 'update_profile') {
    $old_username = $_POST['old_username'] ?? '';
    $new_username = $_POST['new_username'] ?? '';
    $bio = $_POST['bio'] ?? '';
    $conn->begin_transaction();
    try {
        $stmt = $conn->prepare("UPDATE users SET username=?, bio=? WHERE username=?");
        $stmt->bind_param("sss", $new_username, $bio, $old_username);
        $stmt->execute();
        $conn->commit();
        echo json_encode(["status" => "success"]);
    } catch (Exception $e) { $conn->rollback(); echo json_encode(["status" => "error"]); }
}
elseif ($action == 'upload_photo') {
    $username = $_POST['username'] ?? '';
    if (isset($_FILES['photo'])) {
        $target_file = "uploads/" . md5($username . time()) . ".jpg";
        if (move_uploaded_file($_FILES["photo"]["tmp_name"], $target_file)) {
            $url = "http://q97902ug.beget.tech/" . $target_file;
            $stmt = $conn->prepare("UPDATE users SET photo=? WHERE username=?");
            $stmt->bind_param("ss", $url, $username);
            $stmt->execute();
            echo json_encode(["status" => "success", "url" => $url]);
        }
    }
}

$conn->close();
?>