CREATE TABLE users (
  user_id serial PRIMARY KEY,
  username varchar(25) UNIQUE NOT NULL,
  password text NOT NULL
);

CREATE TABLE surveys (
  survey_id serial PRIMARY KEY,
  title varchar(25) UNIQUE NOT NULL,
  created_on timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  user_id integer NOT NULL REFERENCES users (user_id) ON DELETE CASCADE
);

CREATE TABLE questions (
  question_id serial PRIMARY KEY,
  question varchar(50) NOT NULL,
  survey_id integer NOT NULL REFERENCES surveys (survey_id) ON DELETE CASCADE
);

CREATE TABLE choices (
  choice_id serial PRIMARY KEY,
  choice varchar(50) NOT NULL,
  question_id integer NOT NULL REFERENCES questions (question_id) ON DELETE CASCADE
);

CREATE TABLE responses (
  response_id serial PRIMARY KEY,
  choice_id integer NOT NULL REFERENCES choices (choice_id) ON DELETE CASCADE
);

CREATE TABLE users_taken_surveys (
  user_id integer NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
  survey_id integer NOT NULL REFERENCES surveys (survey_id) ON DELETE CASCADE,
  taken_on timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (username, password) VALUES
  ('admin', 'password')
;

INSERT INTO surveys (title, user_id) VALUES
  ('Fun Survey', 1)
;

INSERT INTO questions (question, survey_id) VALUES
  ('What''s your favorite flavor of ice cream?', 1),
  ('What''s your favorite sport?', 1)
;

INSERT INTO choices (choice, question_id) VALUES
  ('Chocolate', 1),
  ('Vanilla', 1),
  ('Baseball', 2),
  ('Basketball', 2),
  ('Hocket', 2)
;
