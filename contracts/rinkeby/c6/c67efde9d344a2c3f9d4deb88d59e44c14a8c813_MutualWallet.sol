/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract MutualWallet {
    uint256 public TotalCurrentMembers;
    uint256 public TotalExistMembers;
    address payable[] members;
    mapping(address => uint256) Value_Of;
    mapping(address => uint256) index;
    uint256 idx = 0;

    function Deposite() payable public {
        require(msg.value > 0, "Value must be greater than zero!");

        if(checkMemberExist(msg.sender)){
            if(Value_Of[msg.sender] == 0){
                TotalCurrentMembers += 1;
            }
            Value_Of[msg.sender] += msg.value;
        }else{
            Value_Of[msg.sender] += msg.value;
            members.push(msg.sender);
            index[msg.sender] = idx;
            idx++;
            TotalExistMembers = members.length;
            TotalCurrentMembers = members.length;
        }
    }

    function checkMemberExist(address _add) internal returns(bool) {
         for(uint256 i = 0; i < members.length; i++){
                if(members[i] == _add){
                    return true;
                }
            }
        return false;   
    }

    function CheckYourFund(address _address) public view returns(uint256){
        return Value_Of[_address];
    }

    function Withdraw(uint256 _amount) public {
        uint256 amount = _amount*1000000000000000000;
        require(Value_Of[msg.sender] > 0, "Your fund is 0");
        require(Value_Of[msg.sender] >= amount,"You can not withdraw greater than your fund!");
    
        members[index[msg.sender]].transfer(amount);
        Value_Of[msg.sender] -= amount;
        if(Value_Of[msg.sender] == 0){
            TotalCurrentMembers -= 1;
        }
    }

    function ContractBalance() public view returns(uint256){
        return address(this).balance;
    }
}