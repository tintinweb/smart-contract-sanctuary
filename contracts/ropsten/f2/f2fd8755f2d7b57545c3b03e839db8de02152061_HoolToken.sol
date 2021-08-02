/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

pragma solidity ^0.8.1;

// SPDX-License-Identifier: MIT

contract HoolToken {

    /// @notice Get the name of token
    /// @return The name of token
    function name() external pure returns (string memory) {
        return "HOOL";
    }

    /// @notice Get the symbol of token
    /// @return The symbol of token
    function symbol() external pure returns (string memory) {
        return "HOOL";
    }

    /// @notice Get the decimals of token
    /// @return The decimals of token
    function decimals() external pure returns  (uint8) {
        return 18;
    }

    /// @notice Get the totalSupply of token
    /// @return The totalSupply of token
    function totalSupply() external pure returns  (uint256) {
        return 1;
    }

    /// @notice Get the totalSupply of token
    /// @param account address of acount
    /// @return The balance of account
    function balanceOf(address account) external pure returns  (uint256) {
        return 1;
    }

    /// @notice Transfer an amount of token to recipient
    /// @param recipient address of acount
    /// @param amount amount to be transferred
    function transfer(address recipient, uint256 amount) external pure returns  (bool) {
        return true;
    }

    /// @notice Get the amount of token allow to spend
    /// @param owner address of owner, 
    /// @param spender address of spender, 
    /// @return The amount of token allow to spend
    function allowance(address owner, address spender) external pure returns  (uint256) {
        return 1;
    }

    /// @notice Approve
    /// @param spender address of spender, 
    /// @param amount amount approve 
    /// @return Allow spender to spend an amount
    function approve(address spender, uint256 amount) external pure returns  (bool) {
        return true;
    }

    /// @notice Transfer token from sender to recipient
    /// @param sender address of sender,
    /// @param recipient address of recipient, 
    /// @param amount amount of token to be trasferred 
    /// @return Allow sender to transfer an amount
    

    function transferFrom(address sender, address recipient, uint256 amount) external pure returns (bool) {
        return true;
    }

    /// @notice Mint additional tokens to specific address
    /// @param to address of recipient, 
    /// @param amount amount of token to be minted 
    

    function mint(address to, uint256 amount) external {
    }
    
}