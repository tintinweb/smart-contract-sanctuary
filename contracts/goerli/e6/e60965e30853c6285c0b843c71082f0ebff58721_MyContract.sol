/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract{

//private 
string _name;
uint _balance; 

constructor(string memory name,uint balances){
    require(balances>=500,"balance greater and Equal 500");
    _name = name;
    _balance = balances;
}

//view ทำงานกับตัวแปร หรือ แอทริบิว
//pure ทำงานกับค่าคงที่
function getBalance() public view returns(uint balance){
    return _balance;
}

function deposite(uint amount) public {
    _balance+=amount;
}

}