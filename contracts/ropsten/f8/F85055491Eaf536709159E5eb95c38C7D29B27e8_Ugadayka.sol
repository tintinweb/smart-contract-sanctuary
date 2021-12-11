/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Ugadayka  {
    player[] players;
    player[] winners;
    uint entropy = 0;
    uint round = 0;

    event roundWinningNumber(uint round, uint8 winning_number);
    event playerStatus(uint round, address addr, string nickname, uint bet, string status);

    struct player {
        string nickname;
        address addr;
        uint8 bet;
    }

    function make_bet(string memory nickname, uint8 bet) public {
        require(bet >= 1 && bet <= 10, "Invalid bet");
        players.push(player(nickname, msg.sender, bet));
        uint hashBlock = uint(blockhash(block.number - 1));
        uint hashName = uint(keccak256(bytes(nickname)));
        uint hashNumber = uint(keccak256(abi.encode(bet)));
        entropy += hashBlock % 1000 + hashName % 1000 + hashNumber % 1000;
        if (players.length == 5) {
            game();
        }
    }

    function game() private {
        delete winners;
        uint8 winning_number = uint8(entropy % 10 + 1);
        emit roundWinningNumber(round, winning_number);
        for (uint8 i = 0; i < 5; ++i) {
            string memory result =  "Lost in the round";
            if (players[i].bet == winning_number) {
                winners.push(players[i]);
                result = "Won in the round";
            }
            emit playerStatus(round, players[i].addr, players[i].nickname, players[i].bet, result);
        }
        delete players;
        round++;
    }

    function get_winners() public view returns(player[] memory) {
        return winners;
    }
}