/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-07
*/

pragma solidity >=0.8.6;


contract HashFlip {

    struct Game {
        address player_1;
        address player_2;
        uint256 wager;
        uint256 creation_block;
        uint256 winner;
    }

    struct Player {
        uint256 high_score;
        uint256 current_score;
        uint256 profit;
        uint256 loss;
        uint256[] game_ids;
    }

    Game[] public games;

    mapping(address => Player) public players;

    function new_game() external payable {
        require(msg.value >= 0.05 ether, "send more");
        players[msg.sender].game_ids.push(games.length);
        games.push(Game(msg.sender, address(0), msg.value, block.number, 0));
    }

    function join_game(uint256 game_id) external payable {
        Game storage game = games[game_id];
        
        require(msg.value >= game.wager, "send wager");
        require(game.player_2 == address(0), "game already taken");
        require(msg.sender != game.player_1, "can't play with yourself");
        
        game.player_2 = msg.sender;
    }

    function call_winner(uint256 game_id) external {
        Game storage game = games[game_id];
        
        require(game.winner == 0, "game already ended");
        require(block.number >= game.creation_block + 1, "must wait a block for randomness");

        game.winner = (uint256(blockhash(game.creation_block + 1)) % 2) + 1;

        Player storage p1 = players[game.player_1];
        Player storage p2 = players[game.player_2];
        
        uint256 payout = game.wager * 2;

        if (game.winner == 1) {
            p1.current_score++;
            if (p1.current_score > p1.high_score) p1.high_score = p1.current_score;

            p2.current_score = 0;
            p2.loss += payout;

            p1.profit += payout;

            payable(game.player_1).transfer(payout);
        } else {
            p2.current_score++;
            
            if (p2.current_score > p2.high_score) p2.high_score = p2.current_score;

            p1.current_score = 0;
            p1.loss += payout;

            p2.profit += payout;

            payable(game.player_2).transfer(payout);
        }
    }
}