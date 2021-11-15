// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

// Needed to handle structures externally
pragma experimental ABIEncoderV2;

/**
 * @author Balancer Labs
 * @title Manage Configurable Rights for the smart pool
 *      canPauseSwapping - can setPublicSwap back to false after turning it on
 *                         by default, it is off on initialization and can only be turned on
 *      canChangeSwapFee - can setSwapFee after initialization (by default, it is fixed at create time)
 *      canChangeWeights - can bind new token weights (allowed by default in base pool)
 *      canAddRemoveTokens - can bind/unbind tokens (allowed by default in base pool)
 *      canWhitelistLPs - can limit liquidity providers to a given set of addresses
 *      canChangeCap - can change the BSP cap (max # of pool tokens)
 */
library RightsManager {

    // Type declarations

    enum Permissions { PAUSE_SWAPPING,
                       CHANGE_SWAP_FEE,
                       CHANGE_WEIGHTS,
                       ADD_REMOVE_TOKENS,
                       WHITELIST_LPS,
                       CHANGE_CAP,
                       CHANGE_PROTOCOL_FEE }

    struct Rights {
        bool canPauseSwapping;
        bool canChangeSwapFee;
        bool canChangeWeights;
        bool canAddRemoveTokens;
        bool canWhitelistLPs;
        bool canChangeCap;
        bool canChangeProtocolFee;
    }

    // State variables (can only be constants in a library)
    bool public constant DEFAULT_CAN_PAUSE_SWAPPING = false;
    bool public constant DEFAULT_CAN_CHANGE_SWAP_FEE = true;
    bool public constant DEFAULT_CAN_CHANGE_WEIGHTS = true;
    bool public constant DEFAULT_CAN_ADD_REMOVE_TOKENS = false;
    bool public constant DEFAULT_CAN_WHITELIST_LPS = false;
    bool public constant DEFAULT_CAN_CHANGE_CAP = false;
    bool public constant DEFAULT_CAN_CHANGE_PROTOCOL_FEE = true;
    // Functions

    /**
     * @notice create a struct from an array (or return defaults)
     * @dev If you pass an empty array, it will construct it using the defaults
     * @param a - array input
     * @return Rights struct
     */ 
    function constructRights(bool[] calldata a) external pure returns (Rights memory) {
        if (a.length == 0) {
            return Rights(DEFAULT_CAN_PAUSE_SWAPPING,
                          DEFAULT_CAN_CHANGE_SWAP_FEE,
                          DEFAULT_CAN_CHANGE_WEIGHTS,
                          DEFAULT_CAN_ADD_REMOVE_TOKENS,
                          DEFAULT_CAN_WHITELIST_LPS,
                          DEFAULT_CAN_CHANGE_CAP,
                          DEFAULT_CAN_CHANGE_PROTOCOL_FEE);
        }
        else {
            return Rights(a[0], a[1], a[2], a[3], a[4], a[5], a[6]);
        }
    }

    /**
     * @notice Convert rights struct to an array (e.g., for events, GUI)
     * @dev avoids multiple calls to hasPermission
     * @param rights - the rights struct to convert
     * @return boolean array containing the rights settings
     */
    function convertRights(Rights calldata rights) external pure returns (bool[] memory) {
        bool[] memory result = new bool[](7);

        result[0] = rights.canPauseSwapping;
        result[1] = rights.canChangeSwapFee;
        result[2] = rights.canChangeWeights;
        result[3] = rights.canAddRemoveTokens;
        result[4] = rights.canWhitelistLPs;
        result[5] = rights.canChangeCap;
        result[6] = rights.canChangeProtocolFee;

        return result;
    }

    // Though it is actually simple, the number of branches triggers code-complexity
    /* solhint-disable code-complexity */

    /**
     * @notice Externally check permissions using the Enum
     * @param self - Rights struct containing the permissions
     * @param permission - The permission to check
     * @return Boolean true if it has the permission
     */
    function hasPermission(Rights calldata self, Permissions permission) external pure returns (bool) {
        if (Permissions.PAUSE_SWAPPING == permission) {
            return self.canPauseSwapping;
        }
        else if (Permissions.CHANGE_SWAP_FEE == permission) {
            return self.canChangeSwapFee;
        }
        else if (Permissions.CHANGE_WEIGHTS == permission) {
            return self.canChangeWeights;
        }
        else if (Permissions.ADD_REMOVE_TOKENS == permission) {
            return self.canAddRemoveTokens;
        }
        else if (Permissions.WHITELIST_LPS == permission) {
            return self.canWhitelistLPs;
        }
        else if (Permissions.CHANGE_CAP == permission) {
            return self.canChangeCap;
        }
        else if (Permissions.CHANGE_PROTOCOL_FEE == permission) {
            return self.canChangeProtocolFee;
        }
    }

    /* solhint-enable code-complexity */
}

