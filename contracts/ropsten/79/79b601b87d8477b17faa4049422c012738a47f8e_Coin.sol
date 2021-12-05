/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Coin{
    mapping(address => uint8) players;
    address payable immutable owner;

    event received(uint, address);
    event resultHistory(address, uint, string);

    constructor(){
        owner = payable(msg.sender);
    }

    receive()external payable {
        emit received(msg.value, payable(msg.sender));
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function throwCoin(uint8 _coin)public payable{
        require(_coin==1 || _coin==2);
        require(address(this).balance >= msg.value * 2);

        uint hashBlock = uint(blockhash(block.number - 1));
        uint hashAdr = uint(keccak256(abi.encode(msg.sender)));
        uint hashCoin = uint(keccak256(abi.encode(_coin)));

        uint8 result = uint8(
                            uint(
                                keccak256(abi.encode( hashCoin%1000 + hashAdr%1000 + hashBlock%1000))
                            ) %2 + 1);
        if(result == _coin){
            payable(msg.sender).transfer(msg.value*2);
            players[msg.sender] = 1;
            emit resultHistory(msg.sender, msg.value, "Won");
        }
        else{
            players[msg.sender] = 2;
            emit resultHistory(msg.sender, msg.value, "Lost");
        }
    }
    
    function getResult()public view returns(string memory){
        if(players[msg.sender] == 0) return "You didn't play";
        else if(players[msg.sender] == 1) return "You won";
        return "You lose";
    }

    function getBalance()public onlyOwner view returns(uint){
        return address(this).balance;
    }

    function getAll()public onlyOwner{
        owner.transfer(address(this).balance);
    }
}