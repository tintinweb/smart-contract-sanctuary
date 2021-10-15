/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity 0.6.7;

abstract contract StabilityFeeTreasuryLike {
    function modifyParameters(bytes32, uint256) virtual external;
}
abstract contract OracleRelayerLike {
    function redemptionPrice() virtual public returns (uint256);
}

contract SFTreasuryCoreParamAdjuster {
    // --- Authorities ---
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
        require(authorizedAccounts[msg.sender] == 1, "SFTreasuryCoreParamAdjuster/account-not-authorized");
        _;
    }

    // --- Structs ---
    struct FundedFunction {
        // Amount of function calls for which a funded function should request payment
        uint256 latestExpectedCalls;
        // Max reward per call requested by a funded function
        uint256 latestMaxReward;      // [wad]
    }

    // --- Variables ---
    // Minimum delay between two consecutive recomputeTreasuryParameters calls
    uint256                  public updateDelay;                       // [seconds]
    // Last timestamp when setNewTreasuryParameters was called
    uint256                  public lastUpdateTime;                    // [unit timestamp]
    // The dynamically calculated max treasury capacity
    uint256                  public dynamicRawTreasuryCapacity;        // [wad]
    // Multiplier applied to dynamicRawTreasuryCapacity before setting the new treasury capacity in the SF treasury contract
    uint256                  public treasuryCapacityMultiplier;        // [hundred]
    // The smallest treasury capacity to set in the SF treasury
    uint256                  public minTreasuryCapacity;               // [rad]
    // Multiplier applied to dynamicRawTreasuryCapacity in order to determine the minimumFundsRequired value to set in the SF treasury
    uint256                  public minimumFundsMultiplier;            // [hundred]
    // The smallest value that can be set for the minimumFundsRequired var inside the SF treasury
    uint256                  public minMinimumFunds;                   // [rad]
    // Multiplier applied to dynamicRawTreasuryCapacity in order to determine the pullFundsMinThreshold value to set in the SF treasury
    uint256                  public pullFundsMinThresholdMultiplier;   // [hundred]
    // The smallest value that can be set for the pullFundsMinThreshold var inside the SF treasury
    uint256                  public minPullFundsThreshold;             // [rad]

    // Mapping of whitelisted reward adjusters that can call adjustMaxReward
    mapping(address => uint256) public rewardAdjusters;

    // Funded functions taken into account when computing the SF treasury params
    mapping(address => mapping(bytes4 => FundedFunction)) public whitelistedFundedFunctions;

    // The address of the treasury contract
    StabilityFeeTreasuryLike public treasury;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event AddRewardAdjuster(address adjuster);
    event RemoveRewardAdjuster(address adjuster);
    event ModifyParameters(bytes32 parameter, uint256 val);
    event ModifyParameters(bytes32 parameter, address addr);
    event ModifyParameters(address targetContract, bytes4 targetFunction, bytes32 parameter, uint256 val);
    event AddFundedFunction(address targetContract, bytes4 targetFunction, uint256 latestExpectedCalls);
    event RemoveFundedFunction(address targetContract, bytes4 targetFunction);
    event AdjustMaxReward(address targetContract, bytes4 targetFunction, uint256 newMaxReward, uint256 dynamicCapacity);
    event UpdateTreasuryParameters(uint256 newMinPullFundsThreshold, uint256 newMinimumFunds, uint256 newTreasuryCapacity);

    constructor(
      address treasury_,
      uint256 updateDelay_,
      uint256 lastUpdateTime_,
      uint256 treasuryCapacityMultiplier_,
      uint256 minTreasuryCapacity_,
      uint256 minimumFundsMultiplier_,
      uint256 minMinimumFunds_,
      uint256 pullFundsMinThresholdMultiplier_,
      uint256 minPullFundsThreshold_
    ) public {
        require(treasury_ != address(0), "SFTreasuryCoreParamAdjuster/null-treasury");

        require(updateDelay_ > 0, "SFTreasuryCoreParamAdjuster/null-update-delay");
        require(lastUpdateTime_ > now, "SFTreasuryCoreParamAdjuster/invalid-last-update-time");
        require(both(treasuryCapacityMultiplier_ >= HUNDRED, treasuryCapacityMultiplier_ <= THOUSAND), "SFTreasuryCoreParamAdjuster/invalid-capacity-mul");
        require(minTreasuryCapacity_ > 0, "SFTreasuryCoreParamAdjuster/invalid-min-capacity");
        require(both(minimumFundsMultiplier_ >= HUNDRED, minimumFundsMultiplier_ <= THOUSAND), "SFTreasuryCoreParamAdjuster/invalid-min-funds-mul");
        require(minMinimumFunds_ > 0, "SFTreasuryCoreParamAdjuster/null-min-minimum-funds");
        require(both(pullFundsMinThresholdMultiplier_ >= HUNDRED, pullFundsMinThresholdMultiplier_ <= THOUSAND), "SFTreasuryCoreParamAdjuster/invalid-pull-funds-threshold-mul");
        require(minPullFundsThreshold_ > 0, "SFTreasuryCoreParamAdjuster/null-min-pull-funds-threshold");

        authorizedAccounts[msg.sender]   = 1;

        treasury                         = StabilityFeeTreasuryLike(treasury_);

        updateDelay                      = updateDelay_;
        lastUpdateTime                   = lastUpdateTime_;
        treasuryCapacityMultiplier       = treasuryCapacityMultiplier_;
        minTreasuryCapacity              = minTreasuryCapacity_;
        minimumFundsMultiplier           = minimumFundsMultiplier_;
        minMinimumFunds                  = minMinimumFunds_;
        pullFundsMinThresholdMultiplier  = pullFundsMinThresholdMultiplier_;
        minPullFundsThreshold            = minPullFundsThreshold_;

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("treasury", treasury_);
        emit ModifyParameters("updateDelay", updateDelay);
        emit ModifyParameters("lastUpdateTime", lastUpdateTime);
        emit ModifyParameters("minTreasuryCapacity", minTreasuryCapacity);
        emit ModifyParameters("minMinimumFunds", minMinimumFunds);
        emit ModifyParameters("minPullFundsThreshold", minPullFundsThreshold);
        emit ModifyParameters("treasuryCapacityMultiplier", treasuryCapacityMultiplier);
        emit ModifyParameters("minimumFundsMultiplier", minimumFundsMultiplier);
        emit ModifyParameters("pullFundsMinThresholdMultiplier", pullFundsMinThresholdMultiplier);
    }

    // --- Math ---
    uint256 public constant RAY      = 10 ** 27;
    uint256 public constant WAD      = 10 ** 18;
    uint256 public constant HUNDRED  = 100;
    uint256 public constant THOUSAND = 1000;
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "SFTreasuryCoreParamAdjuster/add-uint-uint-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "SFTreasuryCoreParamAdjuster/sub-uint-uint-underflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "SFTreasuryCoreParamAdjuster/multiply-uint-uint-overflow");
    }
    function maximum(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x >= y) ? x : y;
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Administration ---
    /*
    * @notify Modify a uint256 parameter
    * @param parameter The parameter name
    * @param val The new parameter value
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        require(val > 0, "SFTreasuryCoreParamAdjuster/null-value");

        if (parameter == "updateDelay") {
            updateDelay = val;
        }
        else if (parameter == "dynamicRawTreasuryCapacity") {
            dynamicRawTreasuryCapacity = val;
        }
        else if (parameter == "treasuryCapacityMultiplier") {
            require(both(val >= HUNDRED, val <= THOUSAND), "SFTreasuryCoreParamAdjuster/invalid-capacity-mul");
            treasuryCapacityMultiplier = val;
        }
        else if (parameter == "minimumFundsMultiplier") {
            require(both(val >= HUNDRED, val <= THOUSAND), "SFTreasuryCoreParamAdjuster/invalid-min-funds-mul");
            minimumFundsMultiplier = val;
        }
        else if (parameter == "pullFundsMinThresholdMultiplier") {
            require(both(val >= HUNDRED, val <= THOUSAND), "SFTreasuryCoreParamAdjuster/invalid-pull-funds-threshold-mul");
            pullFundsMinThresholdMultiplier = val;
        }
        else if (parameter == "minTreasuryCapacity") {
            minTreasuryCapacity = val;
        }
        else if (parameter == "minMinimumFunds") {
            minMinimumFunds = val;
        }
        else if (parameter == "minPullFundsThreshold") {
            minPullFundsThreshold = val;
        }
        else revert("SFTreasuryCoreParamAdjuster/modify-unrecognized-param");
        emit ModifyParameters(parameter, val);
    }
    /*
    * @notify Modify the address of a contract integrated with this adjuster
    * @param parameter The parameter/contract name
    * @param addr The new address for the contract
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "SFTreasuryCoreParamAdjuster/null-address");

        if (parameter == "treasury") {
            treasury = StabilityFeeTreasuryLike(addr);
        }
        else revert("SFTreasuryCoreParamAdjuster/modify-unrecognized-param");
        emit ModifyParameters(parameter, addr);
    }
    /*
    * @notify Modify a parameter in a FundedFunction
    * @param targetContract The contract where the funded function resides
    * @param targetFunction The signature of the funded function
    * @param parameter The name of the parameter to change
    * @param val The new parameter value
    */
    function modifyParameters(address targetContract, bytes4 targetFunction, bytes32 parameter, uint256 val) external isAuthorized {
        FundedFunction storage fundedFunction = whitelistedFundedFunctions[targetContract][targetFunction];
        require(fundedFunction.latestExpectedCalls >= 1, "SFTreasuryCoreParamAdjuster/inexistent-funded-function");
        require(val >= 1, "SFTreasuryCoreParamAdjuster/invalid-value");

        if (parameter == "latestExpectedCalls") {
            dynamicRawTreasuryCapacity = subtract(dynamicRawTreasuryCapacity, multiply(fundedFunction.latestExpectedCalls, fundedFunction.latestMaxReward));
            fundedFunction.latestExpectedCalls = val;
            dynamicRawTreasuryCapacity = addition(dynamicRawTreasuryCapacity, multiply(val, fundedFunction.latestMaxReward));
        }
        else revert("SFTreasuryCoreParamAdjuster/modify-unrecognized-param");
        emit ModifyParameters(targetContract, targetFunction, parameter, val);
    }

    // --- Reward Adjusters Management ---
    /*
    * @notify Add a new reward adjuster
    * @param adjuster The address of the adjuster
    */
    function addRewardAdjuster(address adjuster) external isAuthorized {
        require(rewardAdjusters[adjuster] == 0, "SFTreasuryCoreParamAdjuster/adjuster-already-added");
        rewardAdjusters[adjuster] = 1;
        emit AddRewardAdjuster(adjuster);
    }
    /*
    * @notify Remove an existing reward adjuster
    * @param adjuster The address of the adjuster
    */
    function removeRewardAdjuster(address adjuster) external isAuthorized {
        require(rewardAdjusters[adjuster] == 1, "SFTreasuryCoreParamAdjuster/adjuster-not-added");
        rewardAdjusters[adjuster] = 0;
        emit RemoveRewardAdjuster(adjuster);
    }

    // --- Funded Function Management ---
    /*
    * @notify Add a new funded function
    * @param targetContract The contract where the funded function resides
    * @param targetFunction The signature of the funded function
    * @param latestExpectedCalls Amount of function calls for which a funded function should request payment
    */
    function addFundedFunction(address targetContract, bytes4 targetFunction, uint256 latestExpectedCalls) external isAuthorized {
        FundedFunction storage fundedFunction = whitelistedFundedFunctions[targetContract][targetFunction];
        require(fundedFunction.latestExpectedCalls == 0, "SFTreasuryCoreParamAdjuster/existent-funded-function");

        // Update the entry
        require(latestExpectedCalls >= 1, "SFTreasuryCoreParamAdjuster/invalid-expected-calls");
        fundedFunction.latestExpectedCalls = latestExpectedCalls;

        // Emit the event
        emit AddFundedFunction(targetContract, targetFunction, latestExpectedCalls);
    }
    /*
    * @notify Remove an already existent funded function
    * @param targetContract The contract where the funded function resides
    * @param targetFunction The signature of the funded function
    */
    function removeFundedFunction(address targetContract, bytes4 targetFunction) external isAuthorized {
        FundedFunction memory fundedFunction = whitelistedFundedFunctions[targetContract][targetFunction];
        require(fundedFunction.latestExpectedCalls >= 1, "SFTreasuryCoreParamAdjuster/inexistent-funded-function");

        // Update the dynamic capacity
        dynamicRawTreasuryCapacity = subtract(
          dynamicRawTreasuryCapacity,
          multiply(fundedFunction.latestExpectedCalls, fundedFunction.latestMaxReward)
        );

        // Delete the entry from the mapping
        delete(whitelistedFundedFunctions[targetContract][targetFunction]);

        // Emit the event
        emit RemoveFundedFunction(targetContract, targetFunction);
    }

    // --- Reward Adjuster Logic ---
    /*
    * @notify Adjust the latestMaxReward of a funded function
    * @param targetContract The contract where the funded function resides
    * @param targetFunction The signature of the funded function
    * @param newMaxReward The new latestMaxReward for the funded function
    */
    function adjustMaxReward(address targetContract, bytes4 targetFunction, uint256 newMaxReward) external {
        require(rewardAdjusters[msg.sender] == 1, "SFTreasuryCoreParamAdjuster/invalid-caller");
        require(newMaxReward >= 1, "SFTreasuryCoreParamAdjuster/invalid-value");

        // Check that the funded function exists
        FundedFunction storage fundedFunction = whitelistedFundedFunctions[targetContract][targetFunction];
        require(fundedFunction.latestExpectedCalls >= 1, "SFTreasuryCoreParamAdjuster/inexistent-funded-function");

        // Update the dynamic capacity and store the new latestMaxReward
        dynamicRawTreasuryCapacity = subtract(dynamicRawTreasuryCapacity, multiply(fundedFunction.latestExpectedCalls, fundedFunction.latestMaxReward));
        fundedFunction.latestMaxReward = newMaxReward;
        dynamicRawTreasuryCapacity = addition(dynamicRawTreasuryCapacity, multiply(fundedFunction.latestExpectedCalls, newMaxReward));

        emit AdjustMaxReward(targetContract, targetFunction, newMaxReward, dynamicRawTreasuryCapacity);
    }

    // --- Core Logic ---
    /*
    * @notify Calculate and set new treasury params according to the latest dynamicRawTreasuryCapacity
    */
    function setNewTreasuryParameters() external {
        require(subtract(now, lastUpdateTime) >= updateDelay, "SFTreasuryCoreParamAdjuster/wait-more");
        lastUpdateTime = now;

        // Calculate the amx treasury capacity
        uint256 newMaxTreasuryCapacity = multiply(treasuryCapacityMultiplier, dynamicRawTreasuryCapacity) / HUNDRED;
        newMaxTreasuryCapacity         = multiply(newMaxTreasuryCapacity, RAY);
        newMaxTreasuryCapacity         = (newMaxTreasuryCapacity < minTreasuryCapacity) ? minTreasuryCapacity : newMaxTreasuryCapacity;

        // Calculate the minimumFundsRequired and scale to RAD
        uint256 newMinTreasuryCapacity = multiply(minimumFundsMultiplier, newMaxTreasuryCapacity) / HUNDRED;
        newMinTreasuryCapacity         = (newMinTreasuryCapacity < minMinimumFunds) ? minMinimumFunds : newMinTreasuryCapacity;

        // Calculate the new pullFundsMinThreshold
        uint256 newPullFundsMinThreshold = multiply(pullFundsMinThresholdMultiplier, newMaxTreasuryCapacity) / HUNDRED;
        newPullFundsMinThreshold         = (newPullFundsMinThreshold < minPullFundsThreshold) ? minPullFundsThreshold : newPullFundsMinThreshold;

        // Set the params in the treasury contract
        treasury.modifyParameters("treasuryCapacity", newMaxTreasuryCapacity);
        treasury.modifyParameters("minimumFundsRequired", newMinTreasuryCapacity);
        treasury.modifyParameters("pullFundsMinThreshold", newPullFundsMinThreshold);

        // Emit event
        emit UpdateTreasuryParameters(newPullFundsMinThreshold, newMinTreasuryCapacity, newMaxTreasuryCapacity);
    }
}