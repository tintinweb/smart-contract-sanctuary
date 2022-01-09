/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// curse crud

contract Main {
    struct Curse {
        string name;
        uint amount;
        bool  valid;
    }

    mapping(address => Curse) private curses;

    function createCurse(string memory  _name) external returns(string memory){
        require(curses[msg.sender].valid == false);
        curses[msg.sender] = Curse(_name, 0, true);
        return "created";
    }

    function updateCurse(string memory _newName) external returns(string memory){
        require(curses[msg.sender].valid == true);
        curses[msg.sender].name = _newName;
        return "updated";
    }

    function showCurse() external view returns(Curse memory){
        return curses[msg.sender];
    }

    function updateBalance(bool _isAddAmount, uint _amount) internal returns(string memory, uint){
        if(_isAddAmount){
            curses[msg.sender].amount += _amount;
        }else{
            curses[msg.sender].amount -= _amount;
        }
        return ("balance updated success", curses[msg.sender].amount);
    }

    function addAmount(uint _amountQty) external returns(string memory, uint){
        require(curses[msg.sender].valid == true);
        return updateBalance(true, _amountQty);
    }

    function removeAmount(uint _amountQty) external returns(string memory, uint){
        require(curses[msg.sender].valid == true);
        return updateBalance(false, _amountQty);
    }

    function deleteCurses() external  returns(string memory){
        require(curses[msg.sender].valid == true);
        delete curses[msg.sender];
        return "curse deleted successfully";
    }
}