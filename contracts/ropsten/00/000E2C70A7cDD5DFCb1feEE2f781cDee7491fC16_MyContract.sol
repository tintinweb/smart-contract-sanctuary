/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract MyContract
{
    address owner;
    mapping(address => uint8) players;

    event received(address, uint);
    event bets(address, uint, string);

    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    constructor()
    {
        owner = msg.sender;
    }

    receive() external payable
    {
        emit received(msg.sender, msg.value);
    }

    function bet(uint8 side) public payable
    {
        require((side == 1) || (side == 2));
        require(address(this).balance >= msg.value * 2);

        uint hashBlock = uint(blockhash(block.number - 1));
        uint hashAdr = uint(keccak256(abi.encode(msg.sender)));
        uint hashCoin = uint(keccak256(abi.encode(side)));

        uint8 result = uint8(uint(keccak256(abi.encode(hashBlock % 1000 + hashAdr % 1000 + hashCoin % 1000))) % 2 + 1);
        if (result == side)
        {
            payable(msg.sender).transfer(msg.value * 2);
            players[msg.sender] = 1;
            emit bets(msg.sender, msg.value * 2, "Won");
        }
        else
        {
            players[msg.sender] = 2;
            emit bets(msg.sender, msg.value * 2, "Lose");
        }
    }

    function viewStatus() public view returns(string memory)
    {
        if (players[msg.sender] == 0)
        {
            return "You didn't play";
        }
        else if (players[msg.sender] == 1)
        {
            return "You won";
        }
        else
        {
            return "You lose";
        }
    }

    function getBalance() public view onlyOwner returns(uint)
    {
        return address(this).balance;   
    }

    function sendProfit() public onlyOwner
    {
        payable(msg.sender).transfer(address(this).balance);
    }
}