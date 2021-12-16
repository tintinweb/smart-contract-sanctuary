/**
 *Submitted for verification at Etherscan.io on 2021-12-15
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

abstract contract RewardsAdjusterLike {
    function modifyParameters(bytes32 parameter, address addr) external virtual;
    function modifyParameters(address receiver, bytes4 targetFunction, bytes32 parameter, uint256 val) external virtual;
}

contract MinimalRewardsAdjusterOverlay is GebAuth {
    RewardsAdjusterLike public adjuster;

    constructor(address adjuster_) public GebAuth() {
        require(adjuster_ != address(0), "MinimalRewardsAdjusterOverlay/null-adjuster");
        adjuster = RewardsAdjusterLike(adjuster_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Core Logic ---
    /*
    * @notice Modify the gasPriceOracle or ethPriceOracle address
    * @param parameter Must be "gasPriceOracle" or "ethPriceOracle"
    * @param data The new address
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(
          either(parameter == "gasPriceOracle", parameter == "ethPriceOracle"),
          "MinimalRewardsAdjusterOverlay/invalid-parameter"
        );
        adjuster.modifyParameters(parameter, data);
    }

    /*
     * @notice Modify "updateDelay" for a funded function
     * @param receiver The address of the funding receiver
     * @param targetFunction The function whose callers receive funding for calling
     * @param parameter Must be "updateDelay"
     * @param val The new parameter value
     */
    function modifyParameters(address receiver, bytes4 targetFunction, bytes32 parameter, uint256 val) external isAuthorized {
        require(parameter == "updateDelay", "MinimalRewardsAdjusterOverlay/invalid-parameter");
        adjuster.modifyParameters(receiver, targetFunction, parameter, val);
    }
}