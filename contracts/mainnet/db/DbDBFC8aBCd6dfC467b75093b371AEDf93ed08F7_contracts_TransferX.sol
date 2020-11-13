
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TransferX {
event Memo(address indexed from, address indexed to, uint256 value, string memo,address tok);

address payable public Owner;
 constructor(address payable _owner) public {
        Owner = _owner;
    }
function withdraw(IERC20 Token) public{
    if (address(Token) == address(0)){
Owner.transfer(address(this).balance);
}
else {
require(Token.transfer(Owner, Token.balanceOf(address(this))));
}
}

 function transferx(
        address payable[] memory to,
        uint256[] memory tokens,
        string[] memory memo,
        IERC20 Token
    ) public payable returns (bool success) {
        require(to.length == tokens.length && tokens.length == memo.length);
        for (uint256 i = 0; i < to.length; i++) {
            if (address(Token) == address(0)){
to[i].transfer(tokens[i]);
emit Memo(msg.sender, to[i], tokens[i], memo[i], address(0));
}
else {
require(Token.transferFrom(msg.sender, to[i], tokens[i]));
            emit Memo(msg.sender, to[i], tokens[i], memo[i], address(Token));
}
        }
        return true;
    }

    
 function transferxFee(
        address payable[] memory to,
        uint256[] memory tokens,
        string[] memory memo,
        IERC20 Token, uint256 fee, address payable Payto
    ) public payable returns (bool success) {
        uint256 feePay;
        require(to.length == tokens.length && tokens.length == memo.length);
        require(fee <= 50);
        for (uint256 i = 0; i < to.length; i++) {
            if (address(Token) == address(0)){
to[i].transfer(tokens[i] * (1000-fee)/(1000));
feePay += tokens[i] * fee/1000;
emit Memo(msg.sender, to[i], tokens[i], memo[i], address(0));
}
else {
require(Token.transferFrom(msg.sender, to[i], tokens[i]*(1000-fee)/1000));
feePay += tokens[i]* fee/1000 ;
            emit Memo(msg.sender, to[i], tokens[i], memo[i], address(Token));
}
        }
        if (address(Token) == address(0)){
Payto.transfer(feePay);
}
else {
require(Token.transferFrom(msg.sender, Payto, feePay));
  }
        return true;
    }
}