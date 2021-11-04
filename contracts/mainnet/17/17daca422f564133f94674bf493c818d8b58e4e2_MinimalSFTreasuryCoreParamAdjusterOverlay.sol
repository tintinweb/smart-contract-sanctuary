/**
 *Submitted for verification at Etherscan.io on 2021-11-04
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

abstract contract SFTreasuryCoreParamAdjusterLike {
    function modifyParameters(bytes32 parameter, uint256 val) external virtual;
    function modifyParameters(address targetContract, bytes4 targetFunction, bytes32 parameter, uint256 val) external virtual;
}

contract MinimalSFTreasuryCoreParamAdjusterOverlay is GebAuth {
    // latestExpectedCalls
    // minPullFundsThreshold
    // pullFundsMinThresholdMultiplier
    SFTreasuryCoreParamAdjusterLike public adjuster;

    constructor(address adjuster_) public GebAuth() {
        require(adjuster_ != address(0), "MinimalSFTreasuryCoreParamAdjusterOverlay/null-adjuster");
        adjuster = SFTreasuryCoreParamAdjusterLike(adjuster_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Core Logic ---
    /*
    * @notice Modify minPullFundsThreshold or pullFundsMinThresholdMultiplier
    * @param parameter Must be "minPullFundsThreshold" or "pullFundsMinThresholdMultiplier"
    * @param data The new value
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        require(
          either(parameter == "minPullFundsThreshold", parameter == "pullFundsMinThresholdMultiplier"),
          "MinimalSFTreasuryCoreParamAdjusterOverlay/invalid-parameter"
        );
        adjuster.modifyParameters(parameter, data);
    }

    /*
    * @notify Modify "latestExpectedCalls" for a FundedFunction
    * @param targetContract The contract where the funded function resides
    * @param targetFunction The signature of the funded function
    * @param parameter Must be "latestExpectedCalls"
    * @param val The new parameter value
    */
    function modifyParameters(address targetContract, bytes4 targetFunction, bytes32 parameter, uint256 val) external isAuthorized {
        require(parameter == "latestExpectedCalls", "MinimalSFTreasuryCoreParamAdjusterOverlay/invalid-parameter");
        adjuster.modifyParameters(targetContract, targetFunction, parameter, val);
    }
}