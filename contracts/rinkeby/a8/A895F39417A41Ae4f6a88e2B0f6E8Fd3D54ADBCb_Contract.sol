/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

contract Contract {

    mapping(address => uint) private balances;

    receive() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint _value, address payable _addr) public payable {
        require(balances[_addr] >= _value, "Insufisient funds.");
        (bool sent, bytes memory data) = _addr.call{value: _value}("");
        require(sent, "Could not send money.");
        balances[msg.sender] -= _value;
    }

    function myBalance() public view returns(uint balance) {
        return address(this).balance;
    }

}