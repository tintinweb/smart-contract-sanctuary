/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Coin{
    mapping (address => uint8) players;
    address immutable owner;

    constructor(){
        owner = msg.sender;
    }

    event Receive(address adr, uint sum);
    event GameInfo(address adr, uint sum, string state);

    function Bid(uint8 side) public payable {
        require(side == 1 || side == 2);
        require(payable(address(this)).balance >= 2 * msg.value);
        uint hashBlock = uint(blockhash(block.number - 1));
        uint hashAdr = uint(keccak256(abi.encode(msg.sender)));
        uint hashCoin = uint(keccak256(abi.encode(side)));
        uint hash = uint(keccak256(abi.encode(hashBlock % 1000 + hashAdr % 1000 + hashCoin % 1000)));
        uint result = hash % 2 + 1;
        if (result == side){
            payable(msg.sender).transfer(2 * msg.value);
            players[msg.sender] = 1;
            emit GameInfo(msg.sender, msg.value, "Won");
        }
        else {
            players[msg.sender] = 2;
            emit GameInfo(msg.sender, msg.value, "Lose");
        }
    }

    function Result() public view returns (string memory){
        if (players[msg.sender] == 0){
            return "You didn't play";
        }
        else if (players[msg.sender] == 1){
            return "You won";
        }
        return "You lose";
    }

    function getBalance() public view returns (uint){
        require(msg.sender == owner);
        return payable(address(this)).balance;
    }

    function transferBalance() public payable{
        require(msg.sender == owner);
        payable(owner).transfer(payable(address(this)).balance);
    }

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }
}