#!/bin/bash

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
database_file="$script_dir/.number_guessing_game.db"

declare -A user_games_played
declare -A user_best_game

load_database() {
	touch "$database_file"

	while IFS='|' read -r stored_username games_played best_game; do
		[[ -z "${stored_username:-}" ]] && continue
		user_games_played["$stored_username"]="$games_played"
		user_best_game["$stored_username"]="$best_game"
	done < "$database_file"
}

save_database() {
	: > "$database_file"

	for stored_username in "${!user_games_played[@]}"; do
		printf '%s|%s|%s\n' \
			"$stored_username" \
			"${user_games_played[$stored_username]}" \
			"${user_best_game[$stored_username]}" >> "$database_file"
	done
}

load_database

printf 'Enter your username:\n'
read -r username

if [[ -n "${user_games_played[$username]+x}" ]]; then
	printf 'Welcome back, %s! You have played %s games, and your best game took %s guesses.\n' \
		"$username" \
		"${user_games_played[$username]}" \
		"${user_best_game[$username]}"
else
	printf 'Welcome, %s! It looks like this is your first time here.\n' "$username"
	user_games_played["$username"]=0
	user_best_game["$username"]=0
fi

secret_number=$(( RANDOM % 1000 + 1 ))
guess_count=0

printf 'Guess the secret number between 1 and 1000:\n'

while true; do
	read -r guess

	if [[ ! "$guess" =~ ^-?[0-9]+$ ]]; then
		printf 'That is not an integer, guess again:\n'
		continue
	fi

	((guess_count++))

	if (( guess < secret_number )); then
		printf "It's higher than that, guess again:\n"
	elif (( guess > secret_number )); then
		printf "It's lower than that, guess again:\n"
	else
		printf 'You guessed it in %s tries. The secret number was %s. Nice job!\n' "$guess_count" "$secret_number"
		break
	fi
done

current_games_played="${user_games_played[$username]}"
current_best_game="${user_best_game[$username]}"

user_games_played["$username"]=$(( current_games_played + 1 ))

if (( current_best_game == 0 || guess_count < current_best_game )); then
	user_best_game["$username"]=$guess_count
fi

save_database
