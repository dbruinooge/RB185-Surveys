require "pg"
require "pry"

class DatabasePersistence
  def initialize
    @db = PG.connect(dbname: "surveys")
  end

  def query(statement, *arguments)
    @db.exec_params(statement, arguments)
  end

  def username_exists?(username)
    sql = "SELECT username FROM users"
    result = query(sql)
    result.any? { |tuple| tuple["username"] == username }
  end

  def find_password(username)
    sql = <<~SQL
      SELECT password FROM users
      WHERE username = $1
    SQL
    result = query(sql, username)
    result.first["password"]
  end

  def find_all_surveys
    sql = <<~SQL
      SELECT * FROM surveys
    SQL
    result = query(sql)
    result.map do |tuple|
      {
        survey_id: tuple["survey_id"],
        title: tuple["title"],
        user_id: tuple["user_id"]
      }
    end
  end

  def find_survey(survey_id)
    sql = <<~SQL
     SELECT * FROM surveys
     WHERE surveys.survey_id = $1
    SQL
    result = query(sql,survey_id)
    tuple = result.first
    { survey_id: tuple["survey_id"],
      title: tuple["title"],
      created_on: tuple["created_on"] }
  end

  def find_survey_id(title)
    sql = <<~SQL
      SELECT survey_id FROM surveys
      WHERE title = $1
    SQL
    result = query(sql, title)
    return result.first unless result.first
    result.first["survey_id"]
  end

  def find_survey_items(survey_id)
    questions = find_questions_for_survey(survey_id)
    questions.map do |question|
      { question_id: question[:question_id],
        question: question[:question],
        choices: find_choices_for_question(question[:question_id]) }
    end
  end

  def find_questions_for_survey(survey_id)
    sql = <<~SQL
      SELECT * FROM questions
      JOIN surveys ON surveys.survey_id = questions.survey_id
      WHERE surveys.survey_id = $1
    SQL
    result = query(sql, survey_id)
    result.map do |tuple|
      {
        question_id: tuple["question_id"],
        question: tuple["question"]
      }
    end
  end

  def find_choices_for_question(question_id)
    sql = <<~SQL
      SELECT * FROM choices
      JOIN questions ON questions.question_id = choices.question_id
      WHERE questions.question_id = $1
    SQL
    result = query(sql, question_id)
    result.map do |tuple|
      { choice_id: tuple["choice_id"], choice: tuple["choice"] }
    end
  end

  def record_choices(params)
    params.each do |_,choice_id|
      sql = <<~SQL
        INSERT INTO responses (choice_id)
        VALUES ($1)
      SQL
      query(sql, choice_id)
    end
  end

  def add_survey_items(params)
    params = cleanup_survey_items(params)
    params = survey_items_to_hash(params)
    binding.pry
    params.each do |survey_item|
      survey_id = last_survey_id
      question = survey_item[:question]
      question_sql = <<~SQL
        INSERT INTO questions (question, survey_id) VALUES ($1, $2)
      SQL
      query(question_sql, question, survey_id)
      question_id = last_question_id
      survey_item[:choices].each do |choice|
        choice_sql = <<~SQL
          INSERT INTO choices (choice, question_id)
          VALUES ($1, $2)
        SQL
        query(choice_sql, choice, question_id)
      end
    end
  end

  def add_survey(title, username)
    user_id = find_user_id(username)
    sql = <<~SQL
      INSERT INTO surveys (title, user_id)
      VALUES ($1, $2)
    SQL
    query(sql, title, user_id)
  end

  def add_user(username, password)
    sql = <<~SQL
      INSERT INTO users (username, password)
      VALUES ($1, $2)
    SQL
    query(sql, username, password)
  end

  def find_user_id(username)
    sql = <<~SQL
      SELECT user_id FROM users
      WHERE username = $1
    SQL
    result = query(sql, username)
    return result.first unless result.first
    result.first["user_id"]
  end

  def cleanup_survey_items(params)
    # Remove elements with empty value
    params.delete_if { |_,v| v == "" }
    # Remove questions and associated choices if < 2 choices
    1.upto(6) do |i|
      count = params.count { |k,_| k.start_with?("q#{i}") }
      if count < 3 || !params.key?("q#{i}")
        params.delete_if { |k,_| k.start_with?("q#{i}") }
      end
    end
    params
  end

  def survey_items_to_hash(params)
    result = []
    1.upto(6) do |q|
      if params.key?("q#{q}")
        question = params["q#{q}"]
        choices = []
        1.upto(6) do |c|
          choices << params["q#{q}c#{c}"] if params.key?("q#{q}c#{c}")
        end
        result << { question: question, choices: choices }
      end
    end
    result
  end

  def last_question_id
    result = query("SELECT max(question_id) FROM questions")
    result.first["max"]
  end

  def last_survey_id
    result = query("SELECT max(survey_id) FROM surveys")
    result.first["max"]
  end

  def find_taken_record(user_id, survey_id)
    sql = <<~SQL
      SELECT * FROM users_taken_surveys
      WHERE user_id = $1 AND survey_id = $2
    SQL
    result = query(sql, user_id, survey_id)
    result.first
  end

  def record_user_took_survey(user_id, survey_id)
    sql = <<~SQL
      INSERT INTO users_taken_surveys (user_id, survey_id)
      VALUES ($1, $2)
    SQL
    query(sql, user_id, survey_id)
  end

  def find_number_of_questions(survey_id)
    sql = <<~SQL
      SELECT count(questions.survey_id) FROM questions
      JOIN surveys ON surveys.survey_id = questions.survey_id
      WHERE questions.survey_id = $1
    SQL
    result = query(sql, survey_id)
    result.first["count"]
  end
end