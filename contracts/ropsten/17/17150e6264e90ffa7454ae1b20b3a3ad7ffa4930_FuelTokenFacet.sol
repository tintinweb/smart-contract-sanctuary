/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

pragma solidity ^0.8.1;

// SPDX-License-Identifier: MIT

contract FuelTokenFacet {

    /// @notice Get the name of token
    /// @return The name of token
    function name() external pure returns (string memory) {
        return "FuelMU";
    }

    /// @notice Get the symbol of token
    /// @return The symbol of token
    function symbol() external pure returns (string memory) {
        return "FuelMU";
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

    /// @notice Mint additional tokens to specific address
    /// @param to address of recipient, 
    /// @param amount amount of token to be minted 
    

    function mint(address to, uint256 amount) external {
    }

    /// @notice Burn tokens from specific address
    /// @param from address of account, 
    /// @param amount amount of token to be burned 
    

    function burn(address from, uint256 amount) external {
    }
}