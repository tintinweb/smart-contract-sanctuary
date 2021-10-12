/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @notice Storage for the Tangle Contract
/// @dev This is a Diamond Storage implementation described in EIP-2535.
library SLib {

    struct S {
        uint minHoldAmount;
    }
    event MinHoldAmountChange(uint minHoldAmount);

    function getS() internal pure returns (S storage s) {
        bytes32 storagePosition = keccak256("Tangle.PreTransformer");
        assembly {s.slot := storagePosition}
    }

}

/// @title PreTransformer, transforms a Tangle transfer value before going
/// through the transfer process
/// @author Brad Brown
/// @notice Transforms a Tangle transfer before going
/// through the transfer process
contract PreTransformer {

    mapping(bytes4 => address) private _0;
    address private owner;

    /// @notice Transforms a Tangle transfer value, ensures that a transfer
    /// cannot leave a holder's balance below the minHoldAmount
    /// @param spender The address the Tangle is being transferred from
    /// @param value The amount of Tangle being transferred
    /// @return The transformed transfer value
    function preTransform(address spender, uint value)
        external
        view
        returns (uint)
    {
        uint balance = getBalance(spender);
        require(value <= balance, "transfer value exceeds balance");
        uint minHoldAmount_ = SLib.getS().minHoldAmount;
        if (balance - value < minHoldAmount_)
            value = balance - minHoldAmount_;
        return value;
    }

    /// @notice Changes the minHoldAmount, emits an event recording the change
    /// @param minHoldAmount_ The new minHoldAmount
    function changeMinHoldAmount(uint minHoldAmount_) external {
        require(msg.sender == owner, "changeMinHoldAmount");
        SLib.S storage s = SLib.getS();
        s.minHoldAmount = minHoldAmount_;
        emit SLib.MinHoldAmountChange(minHoldAmount_);
    }

    function getBalance(address owner_) internal view returns (uint balance) {
        (bool success, bytes memory result) = address(this).staticcall(
            abi.encodeWithSignature(
                "balanceOf(address)",
                owner_
            )
        );
        require(success, "getBalance staticdelegate");
        balance = uint(bytes32(result));
    }
    
    /// @notice Gets the current minHoldAmount
    /// @return The current minHoldAmount
    function minHoldAmount() external view returns (uint) {
        return SLib.getS().minHoldAmount;
    }

}