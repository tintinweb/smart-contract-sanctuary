/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.7 <0.9.0;

contract CoinGame {
    // Ну почему оно не поддерживается
    // string[] constant outcomeStrings = [
    //     "You didn't play",
    //     "You won",
    //     "You lost" // прошедшее время, раз уж `You won` в прошедшем
    // ];

    address owner;

    mapping(address => uint8) players;

    event received(address _address, uint _value);
    event gameResult(address _address, uint _value, string _result);

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit received(msg.sender, msg.value);
    }

    function bet(uint _guessedOutcome) public payable {
        require(_guessedOutcome == 1 || _guessedOutcome == 2);
        require(address(this).balance >= msg.value * 2);
        // Зачем считать все хеши по отдельности, а потом находить остатки, складывать, если можно
        // просто...
        uint hash = uint(keccak256(abi.encode(blockhash(block.number - 1),
                                              msg.sender, _guessedOutcome)));
        players[msg.sender] = (hash % 2 + 1 == _guessedOutcome) ? 1: 2;
        if (players[msg.sender] == 1) {
            payable(msg.sender).transfer(msg.value * 2);
            emit gameResult(msg.sender, msg.value, "Won");
        } else if (players[msg.sender] == 2) {
            emit gameResult(msg.sender, msg.value, "Lost");
        }
    }

    function get() public view returns(string memory) {
        if (players[msg.sender] == 1) {
            return "You won";
        } else if (players[msg.sender] == 2) {
            return "You lost";
        }
        return "You didn't play";
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getBalance() public view onlyOwner returns(uint) {
        return address(this).balance;
    }

    function withdrawAll() public payable onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}