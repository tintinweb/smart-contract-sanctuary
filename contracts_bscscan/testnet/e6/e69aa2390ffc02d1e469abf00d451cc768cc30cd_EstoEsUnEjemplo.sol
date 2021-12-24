// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./SafeMath.sol";

contract EstoEsUnEjemplo {
    using SafeMath for uint256;

    mapping (address => uint) balanceOf;

    function Deposit() external payable {
        balanceOf[msg.sender] = balanceOf[msg.sender].add(msg.value);
    }

    function Withdraw(uint256 withdraw_amount) external{
        require(withdraw_amount <= balanceOf[msg.sender]);
        balanceOf[msg.sender] -= withdraw_amount;

        (bool sent, bytes memory data) = payable(msg.sender).call{value: withdraw_amount*1000000000000000000}("");
        
        if(!sent) {
            balanceOf[msg.sender] += withdraw_amount;
        }
    }
}