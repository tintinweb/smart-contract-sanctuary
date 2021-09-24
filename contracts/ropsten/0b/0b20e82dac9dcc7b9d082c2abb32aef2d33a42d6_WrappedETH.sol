/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract WrappedETH{

    string public name="wrapped ETH";
    string public symbol="WETH";
    uint8 public decimals=18;

    mapping(address=>uint) balanceOf;
    
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);

        emit Withdrawal(msg.sender, wad);
    }
}