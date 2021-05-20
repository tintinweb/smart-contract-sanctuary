/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract navickis {
    mapping (address => uint256) private balances;
    uint8 members = 2;
    address payable gaston = 0xF9CBA4Cbf77178889C59c3f2831D8a081216504C;
    address payable nicolas = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

    function deposit() public payable {
        balances[gaston] += msg.value/members;
        balances[nicolas] += msg.value/members;
    }

    receive() external payable{
        deposit();
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function getMyBalance() public view returns(uint){
        return balances[msg.sender];
    }

    function withdraw(uint amount) public returns(bool success) {
        if(balances[msg.sender] < amount) {
            return false;
        } else {
            balances[msg.sender] -= amount;
            msg.sender.transfer(amount);
            return true;         
        }
    }
}