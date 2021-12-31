/**
 *Submitted for verification at BscScan.com on 2021-12-31
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.6.11;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity ^0.6.11;

contract ApproveMultiple {
    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    function approveTokensMax(IERC20[] calldata tokens, address spender) public {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).approve(spender, MAX_INT);
        }     
	}
}