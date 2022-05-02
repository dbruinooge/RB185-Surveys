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
