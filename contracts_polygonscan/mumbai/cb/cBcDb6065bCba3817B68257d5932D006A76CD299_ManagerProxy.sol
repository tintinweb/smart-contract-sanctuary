// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title ManagerProxy
contract ManagerProxy {
    // ============ Variables ============

    address public immutable _manager;

    // ============ Constructor function ============

    constructor(address manager) {
        _manager = manager;
    }

    // ============ External functions ============

    function endArtAuction(uint256 nftId) external returns (bool) {
        (bool success, bytes memory returnData) = _manager.call(abi.encodeWithSignature("endArtAuction", nftId));

        if (!success) {
            revert(_getRevertMsg(returnData));
        }

        return success;
    }

    // ========== Internal functions ==========

    /// @return revertMsg Revert message
    function _getRevertMsg(bytes memory revertData) internal pure returns (string memory revertMsg) {
        uint256 dataLen = revertData.length;

        if (dataLen < 68) {
            revertMsg = "Transaction reverted silently";
        } else {
            uint256 t;
            assembly {
                revertData := add(revertData, 4)
                t := mload(revertData) // Save the content of the length slot
                mstore(revertData, sub(dataLen, 4)) // Set proper length
            }
            revertMsg = abi.decode(revertData, (string));
            assembly {
                mstore(revertData, t) // Restore the content of the length slot
            }
        }
    }
}