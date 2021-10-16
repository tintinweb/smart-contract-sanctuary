/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity 0.6.7;

abstract contract StabilityFeeTreasuryLike {
    function getAllowance(address) virtual public view returns (uint256, uint256);
    function setPerBlockAllowance(address, uint256) virtual external;
}
abstract contract TreasuryFundableLike {
    function authorizedAccounts(address) virtual public view returns (uint256);
    function baseUpdateCallerReward() virtual public view returns (uint256);
    function maxUpdateCallerReward() virtual public view returns (uint256);
    function modifyParameters(bytes32, uint256) virtual external;
}
abstract contract TreasuryParamAdjusterLike {
    function adjustMaxReward(address receiver, bytes4 targetFunctionSignature, uint256 newMaxReward) virtual external;
}
abstract contract OracleLike {
    function read() virtual external view returns (uint256);
}
abstract contract OracleRelayerLike {
    function redemptionPrice() virtual public returns (uint256);
}

contract MinMaxRewardsAdjuster {
    // --- Auth ---
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
        require(authorizedAccounts[msg.sender] == 1, "MinMaxRewardsAdjuster/account-not-authorized");
        _;
    }

    // --- Structs ---
    struct FundingReceiver {
        // Last timestamp when the funding receiver data was updated
        uint256 lastUpdateTime;           // [unix timestamp]
        // Gas amount used to execute this funded function
        uint256 gasAmountForExecution;    // [gas amount]
        // Delay between two calls to recompute the fees for this funded function
        uint256 updateDelay;              // [seconds]
        // Multiplier applied to the computed base reward
        uint256 baseRewardMultiplier;     // [hundred]
        // Multiplied applied to the computed max reward
        uint256 maxRewardMultiplier;      // [hundred]
    }

    // --- Variables ---
    // Data about funding receivers
    mapping(address => mapping(bytes4 => FundingReceiver)) public fundingReceivers;

    // The gas price oracle
    OracleLike                public gasPriceOracle;
    // The ETH oracle
    OracleLike                public ethPriceOracle;
    // The contract that adjusts SF treasury parameters and needs to be updated with max rewards for each funding receiver
    TreasuryParamAdjusterLike public treasuryParamAdjuster;
    // The oracle relayer contract
    OracleRelayerLike         public oracleRelayer;
    // The SF treasury contract
    StabilityFeeTreasuryLike  public treasury;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, address addr);
    event ModifyParameters(address receiver, bytes4 targetFunction, bytes32 parameter, uint256 val);
    event AddFundingReceiver(
        address indexed receiver,
        bytes4  targetFunctionSignature,
        uint256 updateDelay,
        uint256 gasAmountForExecution,
        uint256 baseRewardMultiplier,
        uint256 maxRewardMultiplier
    );
    event RemoveFundingReceiver(address indexed receiver, bytes4 targetFunctionSignature);
    event RecomputedRewards(address receiver, uint256 newBaseReward, uint256 newMaxReward);

    constructor(
        address oracleRelayer_,
        address treasury_,
        address gasPriceOracle_,
        address ethPriceOracle_,
        address treasuryParamAdjuster_
    ) public {
        // Checks
        require(oracleRelayer_ != address(0), "MinMaxRewardsAdjuster/null-oracle-relayer");
        require(treasury_ != address(0), "MinMaxRewardsAdjuster/null-treasury");
        require(gasPriceOracle_ != address(0), "MinMaxRewardsAdjuster/null-gas-oracle");
        require(ethPriceOracle_ != address(0), "MinMaxRewardsAdjuster/null-eth-oracle");
        require(treasuryParamAdjuster_ != address(0), "MinMaxRewardsAdjuster/null-treasury-adjuster");

	      authorizedAccounts[msg.sender]   = 1;

        // Store
        oracleRelayer         = OracleRelayerLike(oracleRelayer_);
        treasury              = StabilityFeeTreasuryLike(treasury_);
        gasPriceOracle        = OracleLike(gasPriceOracle_);
        ethPriceOracle        = OracleLike(ethPriceOracle_);
        treasuryParamAdjuster = TreasuryParamAdjusterLike(treasuryParamAdjuster_);

        // Check that the oracle relayer has a redemption price stored
        oracleRelayer.redemptionPrice();

        // Emit events
        emit ModifyParameters("treasury", treasury_);
        emit ModifyParameters("oracleRelayer", oracleRelayer_);
        emit ModifyParameters("gasPriceOracle", gasPriceOracle_);
        emit ModifyParameters("ethPriceOracle", ethPriceOracle_);
        emit ModifyParameters("treasuryParamAdjuster", treasuryParamAdjuster_);
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Math ---
    uint256 public constant WAD            = 10**18;
    uint256 public constant RAY            = 10**27;
    uint256 public constant HUNDRED        = 100;
    uint256 public constant THOUSAND       = 1000;

    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "MinMaxRewardsAdjuster/add-uint-uint-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "MinMaxRewardsAdjuster/sub-uint-uint-underflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "MinMaxRewardsAdjuster/multiply-uint-uint-overflow");
    }
    function divide(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "MinMaxRewardsAdjuster/div-y-null");
        z = x / y;
        require(z <= x, "MinMaxRewardsAdjuster/div-invalid");
    }

    // --- Administration ---
    /*
    * @notify Update the address of a contract that this adjuster is connected to
    * @param parameter The name of the contract to update the address for
    * @param addr The new contract address
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "MinMaxRewardsAdjuster/null-address");
        if (parameter == "oracleRelayer") {
            oracleRelayer = OracleRelayerLike(addr);
            oracleRelayer.redemptionPrice();
        }
        else if (parameter == "treasury") {
            treasury = StabilityFeeTreasuryLike(addr);
        }
        else if (parameter == "gasPriceOracle") {
            gasPriceOracle = OracleLike(addr);
        }
        else if (parameter == "ethPriceOracle") {
            ethPriceOracle = OracleLike(addr);
        }
        else if (parameter == "treasuryParamAdjuster") {
            treasuryParamAdjuster = TreasuryParamAdjusterLike(addr);
        }
        else revert("MinMaxRewardsAdjuster/modify-unrecognized-params");
        emit ModifyParameters(parameter, addr);
    }
    /*
    * @notify Change a parameter for a funding receiver
    * @param receiver The address of the funding receiver
    * @param targetFunction The function whose callers receive funding for calling
    * @param parameter The name of the parameter to change
    * @param val The new parameter value
    */
    function modifyParameters(address receiver, bytes4 targetFunction, bytes32 parameter, uint256 val) external isAuthorized {
        require(val > 0, "MinMaxRewardsAdjuster/null-value");
        FundingReceiver storage fundingReceiver = fundingReceivers[receiver][targetFunction];
        require(fundingReceiver.lastUpdateTime > 0, "MinMaxRewardsAdjuster/non-existent-receiver");

        if (parameter == "gasAmountForExecution") {
            require(val < block.gaslimit, "MinMaxRewardsAdjuster/invalid-gas-amount-for-exec");
            fundingReceiver.gasAmountForExecution = val;
        }
        else if (parameter == "updateDelay") {
            fundingReceiver.updateDelay = val;
        }
        else if (parameter == "baseRewardMultiplier") {
            require(both(val >= HUNDRED, val <= THOUSAND), "MinMaxRewardsAdjuster/invalid-base-reward-multiplier");
            require(val <= fundingReceiver.maxRewardMultiplier, "MinMaxRewardsAdjuster/max-mul-smaller-than-min-mul");
            fundingReceiver.baseRewardMultiplier = val;
        }
        else if (parameter == "maxRewardMultiplier") {
            require(both(val >= HUNDRED, val <= THOUSAND), "MinMaxRewardsAdjuster/invalid-max-reward-multiplier");
            require(val >= fundingReceiver.baseRewardMultiplier, "MinMaxRewardsAdjuster/max-mul-smaller-than-min-mul");
            fundingReceiver.maxRewardMultiplier = val;
        }
        else revert("MinMaxRewardsAdjuster/modify-unrecognized-params");
        emit ModifyParameters(receiver, targetFunction, parameter, val);
    }

    /*
    * @notify Add a new funding receiver
    * @param receiver The funding receiver address
    * @param targetFunctionSignature The signature of the function whose callers get funding
    * @param updateDelay The update delay between two consecutive calls that update the base and max rewards for this receiver
    * @param gasAmountForExecution The gas amount spent calling the function with signature targetFunctionSignature
    * @param baseRewardMultiplier Multiplier applied to the computed base reward
    * @param maxRewardMultiplier Multiplied applied to the computed max reward
    */
    function addFundingReceiver(
        address receiver,
        bytes4  targetFunctionSignature,
        uint256 updateDelay,
        uint256 gasAmountForExecution,
        uint256 baseRewardMultiplier,
        uint256 maxRewardMultiplier
    ) external isAuthorized {
        // Checks
        require(receiver != address(0), "MinMaxRewardsAdjuster/null-receiver");
        require(updateDelay > 0, "MinMaxRewardsAdjuster/null-update-delay");
        require(both(baseRewardMultiplier >= HUNDRED, baseRewardMultiplier <= THOUSAND), "MinMaxRewardsAdjuster/invalid-base-reward-multiplier");
        require(both(maxRewardMultiplier >= HUNDRED, maxRewardMultiplier <= THOUSAND), "MinMaxRewardsAdjuster/invalid-max-reward-multiplier");
        require(maxRewardMultiplier >= baseRewardMultiplier, "MinMaxRewardsAdjuster/max-mul-smaller-than-min-mul");
        require(gasAmountForExecution > 0, "MinMaxRewardsAdjuster/null-gas-amount");
        require(gasAmountForExecution < block.gaslimit, "MinMaxRewardsAdjuster/large-gas-amount-for-exec");

        // Check that the receiver hasn't been already added
        FundingReceiver storage newReceiver = fundingReceivers[receiver][targetFunctionSignature];
        require(newReceiver.lastUpdateTime == 0, "MinMaxRewardsAdjuster/receiver-already-added");

        // Add the receiver's data
        newReceiver.lastUpdateTime        = now;
        newReceiver.updateDelay           = updateDelay;
        newReceiver.gasAmountForExecution = gasAmountForExecution;
        newReceiver.baseRewardMultiplier  = baseRewardMultiplier;
        newReceiver.maxRewardMultiplier   = maxRewardMultiplier;

        emit AddFundingReceiver(
          receiver,
          targetFunctionSignature,
          updateDelay,
          gasAmountForExecution,
          baseRewardMultiplier,
          maxRewardMultiplier
        );
    }
    /*
    * @notify Remove an already added funding receiver
    * @param receiver The funding receiver address
    * @param targetFunctionSignature The signature of the function whose callers get funding
    */
    function removeFundingReceiver(address receiver, bytes4 targetFunctionSignature) external isAuthorized {
        // Check that the receiver is still stored and then delete it
        require(fundingReceivers[receiver][targetFunctionSignature].lastUpdateTime > 0, "MinMaxRewardsAdjuster/non-existent-receiver");
        delete(fundingReceivers[receiver][targetFunctionSignature]);
        emit RemoveFundingReceiver(receiver, targetFunctionSignature);
    }

    // --- Core Logic ---
    /*
    * @notify Recompute the base and max rewards for a specific funding receiver with a specific function offering funding
    * @param receiver The funding receiver address
    * @param targetFunctionSignature The signature of the function whose callers get funding
    */
    function recomputeRewards(address receiver, bytes4 targetFunctionSignature) external {
        FundingReceiver storage targetReceiver = fundingReceivers[receiver][targetFunctionSignature];
        require(both(targetReceiver.lastUpdateTime > 0, addition(targetReceiver.lastUpdateTime, targetReceiver.updateDelay) <= now), "MinMaxRewardsAdjuster/wait-more");

        // Update last time
        targetReceiver.lastUpdateTime = now;

        // Read the gas and the ETH prices
        uint256 gasPrice = gasPriceOracle.read();
        uint256 ethPrice = ethPriceOracle.read();

        // Calculate the base fiat value
        uint256 baseRewardFiatValue = divide(multiply(multiply(gasPrice, targetReceiver.gasAmountForExecution), WAD), ethPrice);

        // Calculate the base reward expressed in system coins
        uint256 newBaseReward = divide(multiply(baseRewardFiatValue, RAY), oracleRelayer.redemptionPrice());
        newBaseReward         = divide(multiply(newBaseReward, targetReceiver.baseRewardMultiplier), HUNDRED);

        // Compute the new max reward and check both rewards
        uint256 newMaxReward = divide(multiply(newBaseReward, targetReceiver.maxRewardMultiplier), HUNDRED);
        require(both(newBaseReward > 0, newMaxReward > 0), "MinMaxRewardsAdjuster/null-new-rewards");

        // Notify the treasury param adjuster about the new max reward
        treasuryParamAdjuster.adjustMaxReward(receiver, targetFunctionSignature, newMaxReward);

        // Approve the max reward in the treasury
        treasury.setPerBlockAllowance(receiver, multiply(newMaxReward, RAY));

        // Set the new rewards inside the receiver contract
        TreasuryFundableLike(receiver).modifyParameters("maxUpdateCallerReward", newMaxReward);
        TreasuryFundableLike(receiver).modifyParameters("baseUpdateCallerReward", newBaseReward);

        emit RecomputedRewards(receiver, newBaseReward, newMaxReward);
    }
}