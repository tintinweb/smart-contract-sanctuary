/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

pragma solidity ^0.8.0;

contract count {

    mapping(address => uint256) private balance;

    event updateCount(
        uint256 balance
    );

    function getCount() public view returns (uint256) {
        return balance[msg.sender];
    }

    function increaseCount() public {
        balance[msg.sender] += 1;
        emit updateCount(balance[msg.sender]);
    }

}