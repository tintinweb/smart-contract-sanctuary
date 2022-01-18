/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;
contract MyContract {
//variable
// default as private
/*
type access_modifier
*/
// bool _status =false;
// string public name="mainframe";
// int _amount=0;
// function deposite(unit amount) public{

// }

// function getbalance() public view returns(uint balance){
    //   return _balance
// }
// function getbalance() public pure returns(uint balance){
    //   return 50
// }


string _name;
uint _balance;

constructor(string memory name,uint balance){
    // require(balance>=500,"balance greater 500");
    _name=name;
    _balance=balance;
}

    function getBalance() public view returns(uint balance){
        return _balance;
    }
    // function getBalance() public pure returns(uint balance){
    //      return 500;
    // }
    // function deposite(uint amount) public {
    //     _balance +=amount;
    // }

}