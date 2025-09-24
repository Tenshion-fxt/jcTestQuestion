-- 俱乐部表
CREATE TABLE Clubs (
    club_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    contact_phone VARCHAR(20),
    contact_email VARCHAR(100),
    founded_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_club_name (name)
);

-- 棋手表
CREATE TABLE Players (
    player_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE,
    nationality VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    fide_rating INT DEFAULT 0,
    current_rank INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 会员表（棋手与俱乐部的关联表）
CREATE TABLE Members (
    membership_id INT PRIMARY KEY AUTO_INCREMENT,
    player_id INT NOT NULL,
    club_id INT NOT NULL,
    membership_type ENUM('active', 'associate', 'honorary') DEFAULT 'active',
    join_date DATE NOT NULL,
    leave_date DATE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES Players(player_id) ON DELETE CASCADE,
    FOREIGN KEY (club_id) REFERENCES Clubs(club_id) ON DELETE CASCADE,
    UNIQUE KEY unique_active_membership (player_id, club_id, leave_date),
    INDEX idx_club_members (club_id, leave_date)
);

-- 锦标赛表
CREATE TABLE Tournaments (
    tournament_code VARCHAR(20) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    organizer_type ENUM('club', 'corporate', 'government', 'other') NOT NULL,
    organizer_club_id INT NULL,
    organizer_name VARCHAR(100), -- 用于非俱乐部主办方
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    location VARCHAR(100),
    tournament_type ENUM('round_robin', 'swiss', 'knockout', 'team') NOT NULL,
    status ENUM('upcoming', 'ongoing', 'completed', 'cancelled') DEFAULT 'upcoming',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organizer_club_id) REFERENCES Clubs(club_id) ON DELETE SET NULL,
    CHECK (end_date >= start_date)
);

-- 赞助方表（多对多关系）
CREATE TABLE Sponsors (
    sponsor_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    type ENUM('corporate', 'government', 'individual') NOT NULL,
    contact_info TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 锦标赛赞助关系表
CREATE TABLE Tournament_Sponsors (
    tournament_code VARCHAR(20) NOT NULL,
    sponsor_id INT NOT NULL,
    sponsorship_type ENUM('main', 'co-sponsor', 'partner') DEFAULT 'co-sponsor',
    contribution_amount DECIMAL(10,2) NULL,
    PRIMARY KEY (tournament_code, sponsor_id),
    FOREIGN KEY (tournament_code) REFERENCES Tournaments(tournament_code) ON DELETE CASCADE,
    FOREIGN KEY (sponsor_id) REFERENCES Sponsors(sponsor_id) ON DELETE CASCADE
);

-- 锦标赛参赛者表
CREATE TABLE Tournament_Players (
    tournament_code VARCHAR(20) NOT NULL,
    player_id INT NOT NULL,
    registration_date DATE NOT NULL,
    status ENUM('registered', 'withdrawn', 'disqualified') DEFAULT 'registered',
    seed_rank INT NULL,
    final_rank INT NULL,
    PRIMARY KEY (tournament_code, player_id),
    FOREIGN KEY (tournament_code) REFERENCES Tournaments(tournament_code) ON DELETE CASCADE,
    FOREIGN KEY (player_id) REFERENCES Players(player_id) ON DELETE CASCADE,
    INDEX idx_tournament_players (tournament_code, final_rank)
);

-- 比赛表
CREATE TABLE Matches (
    match_id INT PRIMARY KEY AUTO_INCREMENT,
    tournament_code VARCHAR(20) NOT NULL,
    round_number INT NOT NULL,
    white_player_id INT NOT NULL,
    black_player_id INT NOT NULL,
    match_date DATE NOT NULL,
    result ENUM('white_win', 'black_win', 'draw', 'unplayed') DEFAULT 'unplayed',
    white_rating_change INT DEFAULT 0,
    black_rating_change INT DEFAULT 0,
    moves TEXT, -- 存储棋步记录
    duration_minutes INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tournament_code) REFERENCES Tournaments(tournament_code) ON DELETE CASCADE,
    FOREIGN KEY (white_player_id) REFERENCES Players(player_id) ON DELETE CASCADE,
    FOREIGN KEY (black_player_id) REFERENCES Players(player_id) ON DELETE CASCADE,
    CHECK (white_player_id != black_player_id),
    UNIQUE KEY unique_tournament_match (tournament_code, round_number, white_player_id, black_player_id),
    INDEX idx_tournament_rounds (tournament_code, round_number)
);

-- 确保棋手在同一时间只能属于一个俱乐部
CREATE TRIGGER before_member_insert
BEFORE INSERT ON Members
FOR EACH ROW
BEGIN
    DECLARE active_memberships INT;
    
    SELECT COUNT(*) INTO active_memberships 
    FROM Members 
    WHERE player_id = NEW.player_id AND leave_date IS NULL;
    
    IF active_memberships > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Player can only have one active club membership at a time';
    END IF;
END;

-- 锦标赛日期验证
DELIMITER //
CREATE TRIGGER before_tournament_insert
BEFORE INSERT ON Tournaments
FOR EACH ROW
BEGIN
    IF NEW.end_date < NEW.start_date THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'End date cannot be before start date';
    END IF;
    
    -- 确保主办方信息完整
    IF NEW.organizer_type = 'club' AND NEW.organizer_club_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Club organizer must have a club ID';
    END IF;
END//
DELIMITER ;
