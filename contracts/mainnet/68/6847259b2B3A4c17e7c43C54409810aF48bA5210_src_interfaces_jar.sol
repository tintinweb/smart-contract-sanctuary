// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../lib/erc20.sol";

interface IJar is IERC20 {
    function token() external view returns (address);

    function claimInsurance() external; // NOTE: Only yDelegatedVault implements this

    function getRatio() external view returns (uint256);

    function deposit(uint256) external;

    function withdraw(uint256) external;

    function earn() external;

    function decimals() external view returns (uint8);
}
