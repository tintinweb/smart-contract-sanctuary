// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "IERC20.sol";

contract sirioRedeem{
    IERC20 public sirio;
    IERC20 public dummy;

    event redeemed(address who, uint256 amount);
    
    constructor (address _sirio,address _dummy){
        sirio=IERC20(_sirio);
        dummy=IERC20(_dummy);
    }

    
    function redeem() external{
        uint256 balance=dummy.balanceOf(msg.sender);
        require(balance>0);
        dummy.transferFrom(msg.sender, address(this), balance);
        sirio.transfer(msg.sender,balance);
        emit redeemed(msg.sender,balance);
    }
    
}