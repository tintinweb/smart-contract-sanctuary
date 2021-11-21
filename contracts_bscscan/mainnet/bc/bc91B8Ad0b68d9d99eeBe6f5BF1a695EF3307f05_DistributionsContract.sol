/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

contract DistributionsContract {
    function dbnb(uint amount, address payable[] calldata dst) public lock payable {
        for (uint i; i < dst.length; i++) {
            dst[i].transfer(amount);
        }
    }

    function dbep20(uint amount, ERC20 token, address [] calldata dst) public lock {
        for (uint i; i < dst.length; i++) {
            token.transferFrom(msg.sender,dst[i],amount);
        }
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
}

interface ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}