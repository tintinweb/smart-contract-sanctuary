/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Coin  {
    mapping (address => uint8) players;
    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    event gotEth(address sender_address, uint amount);
    event playerPlayed(address player_address, uint amount, string status);

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function makeBet(uint8 bet) public payable {
        require(bet == 1 || bet == 2, "Invalid bet");
        require(address(this).balance >= msg.value * 2, "The amount of ETH you have bet is too large");
        uint hashBlock = uint(blockhash(block.number - 1));
        uint hashAddr = uint(keccak256(abi.encode(msg.sender)));
        uint hashCoin = uint(keccak256(abi.encode(bet)));
        uint8 result = uint8(uint(keccak256(abi.encode(hashBlock % 1000 + hashAddr % 1000 + hashCoin % 1000))) % 2 + 1);
        if (bet == result) {
            payable(msg.sender).transfer(msg.value * 2);
            players[msg.sender] = 1;
            emit playerPlayed(msg.sender, msg.value * 2, "Won");
        } else {
            players[msg.sender] = 2;
            emit playerPlayed(msg.sender, msg.value, "Lose");
        }
    }

    receive() external payable {
        emit gotEth(msg.sender, msg.value);
    }

    function getBalance() public ownerOnly view returns(uint) {
        require(msg.sender == owner, "You're not the owner");
        return address(this).balance;
    }

    function withdrawBalance() public ownerOnly {
        payable(owner).transfer(address(this).balance);
    }

    function checkResult() public view returns(string memory) {
        if (players[msg.sender] == 0) {
            return "You didn't play";
        }
        if (players[msg.sender] == 1) {
            return "You won";
        }
        if (players[msg.sender] == 2) {
            return "You lose";
        }
    }
}