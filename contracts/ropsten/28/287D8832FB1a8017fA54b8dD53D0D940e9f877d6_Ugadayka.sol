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
    uint prize_fund = 0;
    uint min_bet = 0;
    uint max_bet = 0;
    address immutable owner;

    event roundWinningNumber(uint round, uint8 winning_number);
    event playerStatus(uint round, address addr, string nickname, uint bet, string status, uint sum);

    struct player {
        string nickname;
        string playerResult;
        address addr;
        uint8 bet;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwnerBeforeRound() {
        require(msg.sender == owner);
        require(players.length == 0);
        _;
    }

    constructor(uint _min_bet, uint _max_bet) {
        min_bet = _min_bet;
        max_bet = _max_bet;
        owner = msg.sender;
    }

    function make_bet(string memory nickname, uint8 bet) public payable {
        require(bet >= 1 && bet <= 10, "Invalid bet");
        require(min_bet <= msg.value && msg.value <= max_bet, "The amount of ETH you have bet is too large or too small");
        players.push(player(nickname, "Now playing", msg.sender, bet));
        prize_fund += msg.value;
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
            if (players[i].bet == winning_number) {
                players[i].playerResult = "Won in the round";
                winners.push(players[i]);
            } else {
                players[i].playerResult = "Lose in the round";
                emit playerStatus(round, players[i].addr, players[i].nickname, players[i].bet, "Lose in the round", 0);
            }
        }
        for (uint8 i = 0; i < winners.length; ++i) {
            payable(winners[i].addr).transfer(prize_fund / winners.length);
            emit playerStatus(round, players[i].addr, players[i].nickname, players[i].bet, "Won in the round", prize_fund / winners.length);
        }
        prize_fund = 0;
        delete players;
        round++;
    }

    receive() external payable {}

    function get_prize_fund() public view returns(uint) {
        return prize_fund;
    }

    function get_bet_boders() public view returns(uint, uint) {
        return (min_bet, max_bet);
    }

    function get_winners() public view returns(player[] memory) {
        return winners;
    }

    function get_balance() public onlyOwner view returns(uint) {
        return address(this).balance;
    }

    function set_bet_borders(uint _min_bet, uint _max_bet) public onlyOwnerBeforeRound {
        min_bet = _min_bet;
        max_bet = _max_bet;
    }

    function withdraw_all_balance() public onlyOwnerBeforeRound {
        payable(owner).transfer(address(this).balance);
    }

    function withdraw_balance_part(uint amount) public onlyOwnerBeforeRound {
        require(amount <= address(this).balance, "You ask more ETH than the contract balance");
        payable(owner).transfer(amount);
    }
}