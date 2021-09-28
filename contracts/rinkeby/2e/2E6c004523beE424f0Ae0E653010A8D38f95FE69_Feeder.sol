/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// File: Feeder.sol

contract Feeder {
    mapping(address => uint256) public MyAdress;

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function GetMoney(uint256 _amount, address payable _to) public payable {
        // require(msg.value == 1 ether);
        msg.value == _amount;
        _to.transfer(_amount);
    }

    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}