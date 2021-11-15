// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author 1001.digital
/// @title A helper to distinguish external and contract addresses
library CheckAddress {

    /// Check whether an address is a smart contract.
    /// @param account the address to check
    /// @dev checks if the `extcodesize` of `address` is greater zero
    /// @return true for contracts
    function isContract(address account) external view returns (bool) {
        return getSize(account) > 0;
    }

    /// Check whether an address is an external wallet.
    /// @param account the address to check
    /// @dev checks if the `extcodesize` of `address` is zero
    /// @return true for external wallets
    function isExternal(address account) external view returns (bool) {
        return getSize(account) == 0;
    }

    /// Get the size of the code of an address
    /// @param account the address to check
    /// @dev gets the `extcodesize` of `address`
    /// @return the size of the address
    function getSize(address account) internal view returns (uint256) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size;
    }
}

