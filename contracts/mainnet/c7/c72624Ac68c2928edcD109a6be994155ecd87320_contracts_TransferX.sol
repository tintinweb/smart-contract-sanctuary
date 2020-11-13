
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TransferX {
event Memo(address indexed from, address indexed to, uint256 value, string memo,address tok);
IERC20 public Token;
 function transferx(
        address payable[] memory to,
        uint256[] memory tokens,
        string[] memory memo
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
}