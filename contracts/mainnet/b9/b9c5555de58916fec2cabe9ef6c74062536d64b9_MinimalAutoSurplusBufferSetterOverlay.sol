/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity 0.6.7;

contract GebAuth {
    // --- Authorization ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "GebAuth/account-not-authorized");
        _;
    }

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);

    constructor () public {
        authorizedAccounts[msg.sender] = 1;
        emit AddAuthorization(msg.sender);
    }
}

abstract contract AutoSurplusBufferSetterLike {
    function modifyParameters(bytes32, uint256) virtual external;
}
contract MinimalAutoSurplusBufferSetterOverlay is GebAuth {
    AutoSurplusBufferSetterLike public autoSurplusBuffer;

    constructor(address autoSurplusBuffer_) public GebAuth() {
        require(autoSurplusBuffer_ != address(0), "MinimalAutoSurplusBufferSetterOverlay/null-address");
        autoSurplusBuffer = AutoSurplusBufferSetterLike(autoSurplusBuffer_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    /*
    * @notify Change the stopAdjustments value
    * @param parameter Must be "stopAdjustments"
    * @param data The new value for stopAdjustments
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "stopAdjustments") {
          autoSurplusBuffer.modifyParameters(parameter, data);
        }
        else revert("MinimalAutoSurplusBufferSetterOverlay/modify-forbidden-param");
    }
}