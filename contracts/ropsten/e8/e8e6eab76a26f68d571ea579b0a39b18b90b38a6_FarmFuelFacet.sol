/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract FarmFuelFacet {


    /// @notice Construct the FarmFuel for the corresponding FuelToken
    /// @param _StakedTokenAddr The address of StackedToken (HOOL or LP Token)
    /// @param _FuelTokenAddr The address of FuelToken
    constructor(
        address _StakedTokenAddr,
        address _FuelTokenAddr
    ) {
    }

    /// @notice Locks the user's HoolToken/LP within the contract
    /// @param amount Quantity of HoolToken/LP the user wishes to lock in the contract
    function stake(uint256 amount) public {
    }

    /// @notice Retrieves funds locked in contract and sends them back to user
    /// @param amount The quantity of HoolToken the user wishes to receive
    function unstake(uint256 amount) public {
    }

    /// @dev Kept visibility public for testing
    /// @param user The user
    function calculateYieldTime(address user) public view returns(uint256){
        return 1;
    }

    /// @notice Calculates the user's yield in amount of FuelToken
    /// @param user The address of the user
    function calculateYieldTotal(address user) public view returns(uint256) {
        return 1;
    } 

    /// @notice Transfers accrued FuelToken yield to the user
    function withdrawYield() public {
    } 
}