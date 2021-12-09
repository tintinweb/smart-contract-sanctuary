// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;


contract RescueMe {
    address constant public owner = 0x5eeA118E75f247014c6D0E990f02a0c254EDC852;

    /// @dev To be used with delegatecall, remove all ether from the calling contract to owner
    function rescue()
        external payable
    {
        (bool success,) = owner.call{value: address(this).balance}(new bytes(0));
        if (!success) revert("Fail");
    }
}