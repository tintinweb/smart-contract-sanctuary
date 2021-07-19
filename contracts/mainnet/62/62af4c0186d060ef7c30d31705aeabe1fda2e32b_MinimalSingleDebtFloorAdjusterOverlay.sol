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

abstract contract SingleDebtFloorAdjusterLike {
    function modifyParameters(bytes32, uint256) virtual external;
}
contract MinimalSingleDebtFloorAdjusterOverlay is GebAuth {
    SingleDebtFloorAdjusterLike public adjuster;

    constructor(address adjuster_) public GebAuth() {
        require(adjuster_ != address(0), "MinimalSingleDebtFloorAdjusterOverlay/null-address");
        adjuster = SingleDebtFloorAdjusterLike(adjuster_);
    }

    /*
    * @notify Modify "lastUpdateTime"
    * @param parameter Must be "lastUpdateTime"
    * @param data The new value for lastUpdateTime
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "lastUpdateTime") {
          require(data >= block.timestamp, "MinimalSingleDebtFloorAdjusterOverlay/invalid-data");
          adjuster.modifyParameters(parameter, data);
        } else revert("MinimalSingleDebtFloorAdjusterOverlay/modify-forbidden-param");
    }
}