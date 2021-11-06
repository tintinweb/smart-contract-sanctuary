/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

// File contracts/types/Ownable.sol

pragma solidity 0.7.5;

contract Ownable {

    address public policy;

    constructor () {
        policy = msg.sender;
    }

    modifier onlyPolicy() {
        require( policy == msg.sender, "Ownable: caller is not the owner" );
        _;
    }
    
    function transferManagment(address _newOwner) external onlyPolicy() {
        require( _newOwner != address(0) );
        policy = _newOwner;
    }
}


// File contracts/OlympusProSubsidyRouter.sol

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IBond {
    function paySubsidy() external returns ( uint );
}

// Immutable contract routes between Olympus Pro bonds and subsidy controllers
// Allows for subsidies on bonds offered through bond contracts
contract OPSubsidyRouter is Ownable {

    mapping( address => address ) public bondForController; // maps bond contract managed by subsidy controller

    /**
     *  @notice subsidy controller fetches and resets payout counter
     *  @return uint
     */
    function getSubsidyInfo() external returns ( uint ) {
        require( bondForController[ msg.sender ] != address(0), "Address not mapped" );
        return IBond( bondForController[ msg.sender ] ).paySubsidy();
    }

    /**
     *  @notice add new subsidy controller for bond contract
     *  @param _bond address
     *  @param _subsidyController address
     */
    function addSubsidyController( address _bond, address _subsidyController ) external onlyPolicy() {
        require( _bond != address(0) );
        require( _subsidyController != address(0) );

        bondForController[ _subsidyController ] = _bond;
    }

    /**
     *  @notice remove subsidy controller for bond contract
     *  @param _subsidyController address
     */
    function removeSubsidyController( address _subsidyController ) external onlyPolicy() {
        bondForController[ _subsidyController ] = address(0);
    }
}