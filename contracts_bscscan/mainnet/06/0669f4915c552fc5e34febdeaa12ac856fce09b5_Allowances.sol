/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @notice Allowance storage for Tangle
/// @dev This is a Diamond Storage implementation described in EIP-2535.
/// This is in a separate contract with a numbered ID because mappings cannot
/// be cleared. In the event the balances need to be reset, a new Allowances
/// contract can be created without needing to redeploy other contracts.
library SLib {

    struct S {
        mapping(address => mapping(address => uint)) allowances;
    }

    function getS() internal pure returns (S storage s) {
        bytes32 storagePosition = keccak256("Tangle.Allowances0");
        assembly {s.slot := storagePosition}
    }

}

/// @title Allowances for Tangle
/// @author Brad Brown
/// @notice Stores and provides information related to Tangle holders'
/// allowances
contract Allowances {

    /// @notice Returns the amount of a Tangle holder's Tangle a spender is
    /// allowed to spend
    /// @param _owner The Tangle token holder's address
    /// @param _spender The spender's address
    /// @return The amount that can be spent
    function allowance(address _owner, address _spender)
        external
        view
        returns
        (uint)
    {
        return SLib.getS().allowances[_owner][_spender];
    }

}