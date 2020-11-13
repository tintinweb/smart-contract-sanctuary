// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract FounderPool {
    IERC20 public Token;
    uint256 public blocklock;
    address public bucket;

    constructor(
        IERC20 Tokent,
        address buckt
    ) public {
        Token = Tokent;
        bucket = buckt;
    }
    uint256 public balmin;
    function tap() public {
        require(blocklock <= now, "block");
          if (balmin < Token.balanceOf(address(this))/24) {
          balmin = Token.balanceOf(address(this))/24;
          }
          if (balmin >Token.balanceOf(address(this))){
               Token.transfer(bucket, Token.balanceOf(address(this)));
           } else{
Token.transfer(bucket, balmin);
          }
        blocklock = now + 14 days;
    }
}
