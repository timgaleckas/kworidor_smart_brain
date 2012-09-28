module SmartBrainPlayer
  class << self
    def take_turn(board, player_state)
      opponent_states = board.player_states - [player_state]

      graph = board.graph
      opponent_current_score, my_current_score = opponent_states.map do |opponent_state|
        scores(graph,player_state,opponent_state)
      end.min
      scores_of_moves = board.valid_moves.map do |move|
        speculative_graph = board.with_speculative_move(move){|b| b.graph }
        opponent_score, my_score = opponent_states.map do |opponent_state|
          player_state.with_speculative_move(move) do |speculative_player_state|
            scores(speculative_graph,speculative_player_state,opponent_state)
          end
        end.min
        opponent_change = opponent_score - opponent_current_score
        my_change = my_score - my_current_score
        opponent_change = opponent_change*2 if opponent_score < 5 && board.get_xyd(move).size == 3 #prefer tile placement when opponent close to winning
        [opponent_change-my_change,move]
      end
      scores_of_moves.max[1]
    end

    def score(graph,player_state,opponent_state)
      opponent_score, my_score = scores(graph,player_state,opponent_state)
      opponent_score - my_score
    end

    def scores(graph,player_state,opponent_state)
      my_moves_to_win = likely_path_for(player_state,graph).size
      [likely_path_for(opponent_state,graph).size, my_moves_to_win]
    end

    def likely_path_for(player,graph)
      player.positions.map do |position|
        shortest_paths = shortest_paths(position,graph)
        player.goal_positions.map{|gp|shortest_paths[gp]}.compact.min { |a, b| a.size <=> b.size }
      end.min { |a, b| a.size <=> b.size }
    end

    def shortest_paths(source,graph)
      shortest_paths = {}
      shortest_paths[source]=[]
      i = graph.bfs_iterator(source)
      i.set_examine_edge_event_handler do |from,to|
        old_shortest_path = shortest_paths[to]
        unless old_shortest_path && old_shortest_path.size < shortest_paths[from].size+1
          shortest_paths[to] = shortest_paths[from] + [to]
        end
      end
      i.to_a
      shortest_paths
    end
  end
end
register_ai(SmartBrainPlayer)
