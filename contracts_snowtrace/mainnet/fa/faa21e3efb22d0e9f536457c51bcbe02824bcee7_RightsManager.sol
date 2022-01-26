/**
 *Submitted for verification at snowtrace.io on 2022-01-26
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @author Kassandra (and Balancer Labs)
 *
 * @title Manage Configurable Rights for the smart pool
 *
 *      canPauseSwapping - can setPublicSwap back to false after turning it on
 *                         by default, it is off on initialization and can only be turned on
 *      canChangeSwapFee - can setSwapFee after initialization (by default, it is fixed at create time)
 *      canChangeWeights - can bind new token weights (allowed by default in base pool)
 *      canAddRemoveTokens - can bind/unbind tokens (allowed by default in base pool)
 *      canWhitelistLPs - can limit liquidity providers to a given set of addresses
 *      canChangeCap - can change the KSP cap (max # of pool tokens)
 */
library RightsManager {
    // possible permissions
    enum Permissions {
        PAUSE_SWAPPING,
        CHANGE_SWAP_FEE,
        CHANGE_WEIGHTS,
        ADD_REMOVE_TOKENS,
        WHITELIST_LPS,
        CHANGE_CAP
    }

    // for holding all possible permissions in a compact way
    struct Rights {
        bool canPauseSwapping;
        bool canChangeSwapFee;
        bool canChangeWeights;
        bool canAddRemoveTokens;
        bool canWhitelistLPs;
        bool canChangeCap;
    }

    // Default state variables (can only be constants in a library)
    bool public constant DEFAULT_CAN_PAUSE_SWAPPING = false;
    bool public constant DEFAULT_CAN_CHANGE_SWAP_FEE = true;
    bool public constant DEFAULT_CAN_CHANGE_WEIGHTS = true;
    bool public constant DEFAULT_CAN_ADD_REMOVE_TOKENS = false;
    bool public constant DEFAULT_CAN_WHITELIST_LPS = false;
    bool public constant DEFAULT_CAN_CHANGE_CAP = false;

    /**
     * @notice create a struct from an array (or return defaults)
     *
     * @dev If you pass an empty array, it will construct it using the defaults
     *
     * @param a - Boolean array input
     *
     * @return Rights struct
     */
    function constructRights(bool[] calldata a) external pure returns (Rights memory) {
        if (a.length == 0) {
            return Rights(
                DEFAULT_CAN_PAUSE_SWAPPING,
                DEFAULT_CAN_CHANGE_SWAP_FEE,
                DEFAULT_CAN_CHANGE_WEIGHTS,
                DEFAULT_CAN_ADD_REMOVE_TOKENS,
                DEFAULT_CAN_WHITELIST_LPS,
                DEFAULT_CAN_CHANGE_CAP
            );
        }
        return Rights(a[0], a[1], a[2], a[3], a[4], a[5]);
    }

    /**
     * @notice Convert rights struct to an array (e.g., for events, GUI)
     *
     * @dev Avoids multiple calls to hasPermission
     *
     * @param rights - The Rights struct to convert
     *
     * @return Boolean array containing the Rights settings
     */
    function convertRights(Rights calldata rights) external pure returns (bool[] memory) {
        bool[] memory result = new bool[](6);

        result[0] = rights.canPauseSwapping;
        result[1] = rights.canChangeSwapFee;
        result[2] = rights.canChangeWeights;
        result[3] = rights.canAddRemoveTokens;
        result[4] = rights.canWhitelistLPs;
        result[5] = rights.canChangeCap;

        return result;
    }

    /**
     * @notice Externally check permissions using the Enum
     *
     * @param self - Rights struct containing the permissions
     *
     * @param permission - The permission to check
     *
     * @return Boolean true if it has the permission
     */
    function hasPermission(Rights calldata self, Permissions permission) external pure returns (bool) {
        // assembly allows us to heavily optmise this by reading padding the location instead of using expensive ifs
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, add(self, mul(permission, 32)), 32)
            return(0, 32)
        }
    }
}