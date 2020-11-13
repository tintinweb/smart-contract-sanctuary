/* SPDX-License-Identifier: MIT */
pragma solidity ^0.7.0;

import "./Erc20Storage.sol";

/**
 * @title Erc20Interface
 * @author Paul Razvan Berg
 * @notice Interface of the Erc20 standard
 * @dev Forked from OpenZeppelin
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/token/ERC20/IERC20.sol
 */
abstract contract Erc20Interface is Erc20Storage {
    /**
     * CONSTANT FUNCTIONS
     */
    function allowance(address owner, address spender) external view virtual returns (uint256);

    function balanceOf(address account) external view virtual returns (uint256);

    /**
     * NON-CONSTANT FUNCTIONS
     */
    function approve(address spender, uint256 amount) external virtual returns (bool);

    function transfer(address recipient, uint256 amount) external virtual returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual returns (bool);

    /**
     * EVENTS
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Burn(address indexed account, uint256 burnAmount);

    event Mint(address indexed account, uint256 mintAmount);

    event Transfer(address indexed from, address indexed to, uint256 value);
}
