/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract bet{
    uint public secretnumber;
    uint public num;
    address payable public house;
    address public winner;
    uint public total;
    bool ended=false;
    mapping(address => uint) public ttwin;
    
    event winperson(address player, uint amount);
    
    constructor(uint _secretnumber, address payable _house){
        house = _house;
        secretnumber = _secretnumber;
    }
    
    function set(uint x)public{
        num = x;
    }

    function betting() public payable{
        if(num != secretnumber){
        revert("you lose");
        }
        winner = msg.sender;
        total = msg.value*0;
        if(num == secretnumber){
        revert("you win");
        }
        winner = msg.sender;
        total = msg.value*10;
    } 
    
     function withdraw() public returns(bool){
        uint amount = total;
        if (amount > 0){
            ttwin[msg.sender]=0;
            if(!payable(winner).send(total)){
                ttwin[msg.sender]=total;
                return false;
            }
        }
        return true;
    }
}