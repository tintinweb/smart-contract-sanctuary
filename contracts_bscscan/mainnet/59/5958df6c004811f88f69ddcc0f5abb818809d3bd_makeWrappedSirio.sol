pragma solidity ^0.8.0;

import "IERC20.sol";

contract makeWrappedSirio{
    
    IERC20 public sirio;
    IERC20 public wSirio;
    
    constructor (address _sirio,address _wSirio){
        sirio=IERC20(_sirio);
        wSirio=IERC20(_wSirio);
    }
    
    function wrap(uint256 amount) public{
        sirio.transferFrom(msg.sender,address(this),amount);
        wSirio.mint(msg.sender,amount);
    }
    
    function unwrap(uint256 amount) public{
        wSirio.transferFrom(msg.sender,address(this),amount);
        wSirio.burn(amount);
        sirio.transfer(msg.sender,amount);
    }
}