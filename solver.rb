#/usr/bin/env ruby

# Solves nonogram puzzles
# https://en.wikipedia.org/wiki/Nonogram
#
# Fill in what is known about the board, then the row and column counts, and
# then run the script.

EMPTY = "."
EXCLUDED = "×"
MARKED = "▉"

board = <<~END.lines.map { |line| line.chomp.chars }
  ...............
  ...............
  ...............
  ...............
  ...............
  ...............
  ...............
  ...............
  ...............
  ...............
  ...............
  ...............
  ...............
  ...............
  ...............
END

row_counts = [
  [4],
  [1, 3, 3],
  [3, 5, 2],
  [1, 6, 1],
  [8, 2],

  [8, 1],
  [8, 1],
  [1, 8, 2],
  [3, 6, 1],
  [1, 5, 2],

  [3, 3],
  [1, 4],
  [3, 1],
  [1, 1, 3],
  [3, 1],
]

column_counts = [
  [1, 1],
  [3, 3],
  [1, 1, 1],
  [4, 3],
  [8, 1],

  [10],
  [10, 1],
  [12, 2],
  [1, 8, 1, 1],
  [1, 6, 1],

  [2, 4, 2],
  [1, 1],
  [2, 2, 1],
  [3, 3, 3],
  [4, 1],
]

def clear_screen
  # Clear screen
  print "\e[2J"
  # Reset cursor to top-left
  print "\e[H"
end

# Generates all possible permutations of `counts` within `size` tiles.
# generate(10, [4,4])
# => [["▉", "▉", "▉", "▉", "×", "▉", "▉", "▉", "▉", "×"],
#     ["▉", "▉", "▉", "▉", "×", "×", "▉", "▉", "▉", "▉"],
#     ["×", "▉", "▉", "▉", "▉", "×", "▉", "▉", "▉", "▉"]]
def generate(size, counts, already=[])
  if counts.empty?
    capacity = size - already.size
    [already + [EXCLUDED] * capacity]
  else
    minimum = counts.reduce { |count, rest| count + 1 + rest }
    already += [EXCLUDED] if already.any?
    capacity = size - already.size
    (0..(capacity - minimum)).flat_map { |offset|
      generate(size, counts[1..-1], already + [EXCLUDED] * offset + [MARKED] * counts[0])
    }
  end
end

possible_rows = row_counts.map do |counts|
  generate(board.size, counts)
end

possible_columns = column_counts.map do |counts|
  generate(board.size, counts)
end

# Until the board is solved...
while board.any? { |row| row.any? { |column| column == EMPTY } }
  clear_screen
  puts "Progress:"
  puts board.map { |row| row.join }.join("\n")
  possible = possible_rows.map(&:size).reduce(&:*) * possible_columns.map(&:size).reduce(&:*)
  puts "possible solutions: #{possible}"
  sleep 1

  # Eliminate any possibilities which don't match the board
  possible_rows.each.with_index do |rows, y|
    rows.select! do |row|
      row.each.with_index.all? do |expected, x|
	actual = board[y][x]
	actual == EMPTY || actual == expected
      end
    end
  end

  # Elimitate rows without any possible columns
  possible_rows.each.with_index do |rows, y|
    rows.select! do |row|
      row.each.with_index.all? do |expected, x|
	possible_columns[x].any? { |column| column[y] == expected }
      end
    end
  end

  possible_rows.each.with_index do |rows, y|
    # If only one possibility exists for this row, fill it to the board
    if rows.size == 1
      rows[0].each.with_index do |calculated, x|
	board[y][x] = calculated
      end
    else
      # If a column is the same across all possible rows, fill it to the board
      (0...board.size).each do |x|
	if rows[1..-1].all? { |row| rows[0][x] == row[x] }
	  board[y][x] = rows[0][x]
	end
      end
    end
  end

  possible_columns.each.with_index do |columns, x|
    columns.select! do |column|
      column.each.with_index.all? do |expected, y|
	actual = board[y][x]
	actual == EMPTY || actual == expected
      end
    end
  end

  # Elimitate columns without any possible rows
  possible_columns.each.with_index do |columns, x|
    columns.select! do |column|
      column.each.with_index.all? do |expected, y|
	possible_rows[y].any? { |row| row[x] == expected }
      end
    end
  end

  possible_columns.each.with_index do |columns, x|
    # If only one possibility exists for this column, fill it to the board
    if columns.size == 1
      columns[0].each.with_index do |calculated, y|
	board[y][x] = calculated
      end
    else
      # If a row is the same across all possible columns, fill it to the board
      (0...board.size).each do |y|
	if columns[1..-1].all? { |column| columns[0][y] == column[y] }
	  board[y][x] = columns[0][y]
	end
      end
    end
  end
end

clear_screen
puts "Solution:"
puts board.map { |row| row.join }.join("\n")
