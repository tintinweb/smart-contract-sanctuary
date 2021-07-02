/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

pragma solidity 0.6.7;


contract GebMath {
    uint256 public constant RAY = 10 ** 27;
    uint256 public constant WAD = 10 ** 18;

    function ray(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 9);
    }
    function rad(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 27);
    }
    function minimum(uint x, uint y) public pure returns (uint z) {
        z = (x <= y) ? x : y;
    }
    function addition(uint x, uint y) public pure returns (uint z) {
        z = x + y;
        require(z >= x, "uint-uint-add-overflow");
    }
    function subtract(uint x, uint y) public pure returns (uint z) {
        z = x - y;
        require(z <= x, "uint-uint-sub-underflow");
    }
    function multiply(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "uint-uint-mul-overflow");
    }
    function rmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / RAY;
    }
    function rdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, RAY) / y;
    }
    function wdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, WAD) / y;
    }
    function wmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / WAD;
    }
    function rpower(uint x, uint n, uint base) public pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}

abstract contract StabilityFeeTreasuryLike {
    function getAllowance(address) virtual external view returns (uint, uint);
    function systemCoin() virtual external view returns (address);
    function pullFunds(address, address, uint) virtual external;
}

contract IncreasingTreasuryReimbursement is GebMath {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "IncreasingTreasuryReimbursement/account-not-authorized");
        _;
    }

    // --- Variables ---
    // Starting reward for the fee receiver/keeper
    uint256 public baseUpdateCallerReward;          // [wad]
    // Max possible reward for the fee receiver/keeper
    uint256 public maxUpdateCallerReward;           // [wad]
    // Max delay taken into consideration when calculating the adjusted reward
    uint256 public maxRewardIncreaseDelay;          // [seconds]
    // Rate applied to baseUpdateCallerReward every extra second passed beyond a certain point (e.g next time when a specific function needs to be called)
    uint256 public perSecondCallerRewardIncrease;   // [ray]

    // SF treasury
    StabilityFeeTreasuryLike  public treasury;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(
      bytes32 parameter,
      address addr
    );
    event ModifyParameters(
      bytes32 parameter,
      uint256 val
    );
    event FailRewardCaller(bytes revertReason, address feeReceiver, uint256 amount);

    constructor(
      address treasury_,
      uint256 baseUpdateCallerReward_,
      uint256 maxUpdateCallerReward_,
      uint256 perSecondCallerRewardIncrease_
    ) public {
        if (address(treasury_) != address(0)) {
          require(StabilityFeeTreasuryLike(treasury_).systemCoin() != address(0), "IncreasingTreasuryReimbursement/treasury-coin-not-set");
        }
        require(maxUpdateCallerReward_ >= baseUpdateCallerReward_, "IncreasingTreasuryReimbursement/invalid-max-caller-reward");
        require(perSecondCallerRewardIncrease_ >= RAY, "IncreasingTreasuryReimbursement/invalid-per-second-reward-increase");
        authorizedAccounts[msg.sender] = 1;

        treasury                        = StabilityFeeTreasuryLike(treasury_);
        baseUpdateCallerReward          = baseUpdateCallerReward_;
        maxUpdateCallerReward           = maxUpdateCallerReward_;
        perSecondCallerRewardIncrease   = perSecondCallerRewardIncrease_;
        maxRewardIncreaseDelay          = uint(-1);

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("treasury", treasury_);
        emit ModifyParameters("baseUpdateCallerReward", baseUpdateCallerReward);
        emit ModifyParameters("maxUpdateCallerReward", maxUpdateCallerReward);
        emit ModifyParameters("perSecondCallerRewardIncrease", perSecondCallerRewardIncrease);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Treasury ---
    /**
    * @notice This returns the stability fee treasury allowance for this contract by taking the minimum between the per block and the total allowances
    **/
    function treasuryAllowance() public view returns (uint256) {
        (uint total, uint perBlock) = treasury.getAllowance(address(this));
        return minimum(total, perBlock);
    }
    /*
    * @notice Get the SF reward that can be sent to a function caller right now
    * @param timeOfLastUpdate The last time when the function that the treasury pays for has been updated
    * @param defaultDelayBetweenCalls Enforced delay between calls to the function for which the treasury reimburses callers
    */
    function getCallerReward(uint256 timeOfLastUpdate, uint256 defaultDelayBetweenCalls) public view returns (uint256) {
        // If the rewards are null or if the time of the last update is in the future or present, return 0
        bool nullRewards = (baseUpdateCallerReward == 0 && maxUpdateCallerReward == 0);
        if (either(timeOfLastUpdate >= now, nullRewards)) return 0;

        // If the time elapsed is smaller than defaultDelayBetweenCalls or if the base reward is zero, return 0
        uint256 timeElapsed = (timeOfLastUpdate == 0) ? defaultDelayBetweenCalls : subtract(now, timeOfLastUpdate);
        if (either(timeElapsed < defaultDelayBetweenCalls, baseUpdateCallerReward == 0)) {
            return 0;
        }

        // If too much time elapsed, return the max reward
        uint256 adjustedTime      = subtract(timeElapsed, defaultDelayBetweenCalls);
        uint256 maxPossibleReward = minimum(maxUpdateCallerReward, treasuryAllowance() / RAY);
        if (adjustedTime > maxRewardIncreaseDelay) {
            return maxPossibleReward;
        }

        // Calculate the reward
        uint256 calculatedReward = baseUpdateCallerReward;
        if (adjustedTime > 0) {
            calculatedReward = rmultiply(rpower(perSecondCallerRewardIncrease, adjustedTime, RAY), calculatedReward);
        }

        // If the reward is higher than max, set it to max
        if (calculatedReward > maxPossibleReward) {
            calculatedReward = maxPossibleReward;
        }
        return calculatedReward;
    }
    /**
    * @notice Send a stability fee reward to an address
    * @param proposedFeeReceiver The SF receiver
    * @param reward The system coin amount to send
    **/
    function rewardCaller(address proposedFeeReceiver, uint256 reward) internal {
        // If the receiver is the treasury itself or if the treasury is null or if the reward is zero, return
        if (address(treasury) == proposedFeeReceiver) return;
        if (either(address(treasury) == address(0), reward == 0)) return;

        // Determine the actual receiver and send funds
        address finalFeeReceiver = (proposedFeeReceiver == address(0)) ? msg.sender : proposedFeeReceiver;
        try treasury.pullFunds(finalFeeReceiver, treasury.systemCoin(), reward) {}
        catch(bytes memory revertReason) {
            emit FailRewardCaller(revertReason, finalFeeReceiver, reward);
        }
    }
}

abstract contract SAFEEngineLike {
    function modifyParameters(
        bytes32 collateralType,
        bytes32 parameter,
        uint256 data
    ) virtual external;
    function collateralTypes(bytes32) virtual public view returns (
        uint256 debtAmount,        // [wad]
        uint256 accumulatedRate,   // [ray]
        uint256 safetyPrice,       // [ray]
        uint256 debtCeiling        // [rad]
    );
}
abstract contract OracleRelayerLike {
    function redemptionPrice() virtual public returns (uint256);
}
abstract contract OracleLike {
    function read() virtual external view returns (uint256);
}

contract SingleDebtFloorAdjuster is IncreasingTreasuryReimbursement {
    // --- Auth ---
    // Mapping of addresses that are allowed to manually recompute the debt floor (without being rewarded for it)
    mapping (address => uint256) public manualSetters;
    /*
    * @notify Add a new manual setter
    * @param account The address of the new manual setter
    */
    function addManualSetter(address account) external isAuthorized {
        manualSetters[account] = 1;
        emit AddManualSetter(account);
    }
    /*
    * @notify Remove a manual setter
    * @param account The address of the manual setter to remove
    */
    function removeManualSetter(address account) external isAuthorized {
        manualSetters[account] = 0;
        emit RemoveManualSetter(account);
    }
    /*
    * @notice Modifier for checking that the msg.sender is a whitelisted manual setter
    */
    modifier isManualSetter {
        require(manualSetters[msg.sender] == 1, "SingleDebtFloorAdjuster/not-manual-setter");
        _;
    }

    // --- Variables ---
    // The collateral's name
    bytes32 public collateralName;
    // Gas amount needed to liquidate a Safe backed by the collateral type with the collateralName
    uint256 public gasAmountForLiquidation;
    // The max value for the debt floor
    uint256 public maxDebtFloor;                    // [rad]
    // The min amount of system coins that must be generated using this collateral type
    uint256 public minDebtFloor;                    // [rad]
    // When the debt floor was last updated
    uint256 public lastUpdateTime;                  // [timestamp]
    // Enforced gap between calls
    uint256 public updateDelay;                     // [seconds]
    // Last timestamp of a manual update
    uint256 public lastManualUpdateTime;            // [seconds]

    // The SAFEEngine contract
    SAFEEngineLike    public safeEngine;
    // The OracleRelayer contract
    OracleRelayerLike public oracleRelayer;
    // The gas price oracle
    OracleLike        public gasPriceOracle;
    // The ETH price oracle
    OracleLike        public ethPriceOracle;

    // --- Events ---
    event AddManualSetter(address account);
    event RemoveManualSetter(address account);
    event UpdateFloor(uint256 nextDebtFloor);

    constructor(
      address safeEngine_,
      address oracleRelayer_,
      address treasury_,
      address gasPriceOracle_,
      address ethPriceOracle_,
      bytes32 collateralName_,
      uint256 baseUpdateCallerReward_,
      uint256 maxUpdateCallerReward_,
      uint256 perSecondCallerRewardIncrease_,
      uint256 updateDelay_,
      uint256 gasAmountForLiquidation_,
      uint256 maxDebtFloor_,
      uint256 minDebtFloor_
    ) public IncreasingTreasuryReimbursement(treasury_, baseUpdateCallerReward_, maxUpdateCallerReward_, perSecondCallerRewardIncrease_) {
        require(safeEngine_ != address(0), "SingleDebtFloorAdjuster/invalid-safe-engine");
        require(oracleRelayer_ != address(0), "SingleDebtFloorAdjuster/invalid-oracle-relayer");
        require(gasPriceOracle_ != address(0), "SingleDebtFloorAdjuster/invalid-gas-price-oracle");
        require(ethPriceOracle_ != address(0), "SingleDebtFloorAdjuster/invalid-eth-price-oracle");
        require(updateDelay_ > 0, "SingleDebtFloorAdjuster/invalid-update-delay");
        require(both(gasAmountForLiquidation_ > 0, gasAmountForLiquidation_ < block.gaslimit), "SingleDebtFloorAdjuster/invalid-liq-gas-amount");
        require(minDebtFloor_ > 0, "SingleDebtFloorAdjuster/invalid-min-floor");
        require(both(maxDebtFloor_ > 0, maxDebtFloor_ > minDebtFloor_), "SingleDebtFloorAdjuster/invalid-max-floor");

        manualSetters[msg.sender] = 1;

        safeEngine              = SAFEEngineLike(safeEngine_);
        oracleRelayer           = OracleRelayerLike(oracleRelayer_);
        gasPriceOracle          = OracleLike(gasPriceOracle_);
        ethPriceOracle          = OracleLike(ethPriceOracle_);
        collateralName          = collateralName_;
        gasAmountForLiquidation = gasAmountForLiquidation_;
        updateDelay             = updateDelay_;
        maxDebtFloor            = maxDebtFloor_;
        minDebtFloor            = minDebtFloor_;
        lastManualUpdateTime    = now;

        oracleRelayer.redemptionPrice();

        emit AddManualSetter(msg.sender);
        emit ModifyParameters("oracleRelayer", oracleRelayer_);
        emit ModifyParameters("gasPriceOracle", gasPriceOracle_);
        emit ModifyParameters("ethPriceOracle", ethPriceOracle_);
        emit ModifyParameters("gasAmountForLiquidation", gasAmountForLiquidation);
        emit ModifyParameters("updateDelay", updateDelay);
        emit ModifyParameters("maxDebtFloor", maxDebtFloor);
        emit ModifyParameters("minDebtFloor", minDebtFloor);
    }
    
    
    
    // 0x6d6178526577617264496e63726561736544656c617900000000000000000000
    // 0x6c00000000000000000000000000000000000000000000000000000000000000
    
    
    
    

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Math ---
    function divide(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "SingleDebtFloorAdjuster/div-y-null");
        z = x / y;
        require(z <= x, "SingleDebtFloorAdjuster/div-invalid");
    }

    // --- Administration ---
    /*
    * @notify Update the address of a contract that this adjuster is connected to
    * @param parameter The name of the contract to update the address for
    * @param addr The new contract address
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "SingleDebtFloorAdjuster/null-address");
        if (parameter == "treasury") {
            treasury = StabilityFeeTreasuryLike(addr);
        }
        else if (parameter == "oracleRelayer") {
            oracleRelayer = OracleRelayerLike(addr);
            oracleRelayer.redemptionPrice();
        }
        else if (parameter == "gasPriceOracle") {
            gasPriceOracle = OracleLike(addr);
            gasPriceOracle.read();
        }
        else if (parameter == "ethPriceOracle") {
            ethPriceOracle = OracleLike(addr);
            ethPriceOracle.read();
        }
        else revert("SingleDebtFloorAdjuster/modify-unrecognized-params");
        emit ModifyParameters(parameter, addr);
    }
    /*
    * @notify Modify an uint256 param
    * @param parameter The name of the parameter to modify
    * @param val The new parameter value
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        if (parameter == "baseUpdateCallerReward") {
          require(val <= maxUpdateCallerReward, "SingleDebtFloorAdjuster/invalid-base-caller-reward");
          baseUpdateCallerReward = val;
        }
        else if (parameter == "maxUpdateCallerReward") {
          require(val >= baseUpdateCallerReward, "SingleDebtFloorAdjuster/invalid-max-caller-reward");
          maxUpdateCallerReward = val;
        }
        else if (parameter == "perSecondCallerRewardIncrease") {
          require(val >= RAY, "SingleDebtFloorAdjuster/invalid-caller-reward-increase");
          perSecondCallerRewardIncrease = val;
        }
        else if (parameter == "maxRewardIncreaseDelay") {
          require(val > 0, "SingleDebtFloorAdjuster/invalid-max-increase-delay");
          maxRewardIncreaseDelay = val;
        }
        else if (parameter == "updateDelay") {
          require(val >= 0, "SingleDebtFloorAdjuster/invalid-call-gap-length");
          updateDelay = val;
        }
        else if (parameter == "maxDebtFloor") {
          require(both(val > 0, val > minDebtFloor), "SingleDebtFloorAdjuster/invalid-max-floor");
          maxDebtFloor = val;
        }
        else if (parameter == "minDebtFloor") {
          require(both(val > 0, val < maxDebtFloor), "SingleDebtFloorAdjuster/invalid-min-floor");
          minDebtFloor = val;
        }
        else if (parameter == "lastUpdateTime") {
          require(val > now, "SingleDebtFloorAdjuster/invalid-update-time");
          lastUpdateTime = val;
        }
        else if (parameter == "gasAmountForLiquidation") {
          require(both(val > 0, val < block.gaslimit), "SingleDebtFloorAdjuster/invalid-liq-gas-amount");
          gasAmountForLiquidation = val;
        }
        else revert("SingleDebtFloorAdjuster/modify-unrecognized-param");
        emit ModifyParameters(
          parameter,
          val
        );
    }

    // --- Utils ---
    /*
    * @notify Internal function meant to modify the collateral's debt floor
    * @param nextDebtFloor The new floor to set
    */
    function setFloor(uint256 nextDebtFloor) internal {
        require(nextDebtFloor > 0, "SingleDebtFloorAdjuster/null-debt-floor");
        safeEngine.modifyParameters(collateralName, "debtFloor", nextDebtFloor);
        emit UpdateFloor(nextDebtFloor);
    }

    // --- Core Logic ---
    /*
    * @notify Automatically recompute and set a new debt floor for the collateral type with collateralName
    * @param feeReceiver The address that will receive the reward for calling this function
    */
    function recomputeCollateralDebtFloor(address feeReceiver) external {
        // Check that the update time is not in the future
        require(lastUpdateTime < now, "SingleDebtFloorAdjuster/update-time-in-the-future");
        // Check delay between calls
        require(either(subtract(now, lastUpdateTime) >= updateDelay, lastUpdateTime == 0), "SingleDebtFloorAdjuster/wait-more");

        // Get the caller's reward
        uint256 callerReward = getCallerReward(lastUpdateTime, updateDelay);
        // Update lastUpdateTime
        lastUpdateTime = now;

        // Get the next floor and set it
        uint256 nextCollateralFloor = getNextCollateralFloor();
        setFloor(nextCollateralFloor);

        // Pay the caller for updating the floor
        rewardCaller(feeReceiver, callerReward);
    }
    /*
    * @notice Manually recompute and set a new debt floor for the collateral type with collateralName
    */
    function manualRecomputeCollateralDebtFloor() external isManualSetter {
        require(now > lastManualUpdateTime, "SingleDebtFloorAdjuster/cannot-update-twice-same-block");
        uint256 nextCollateralFloor = getNextCollateralFloor();
        lastManualUpdateTime = now;
        setFloor(nextCollateralFloor);
    }

    // --- Getters ---
    /*
    * @notify View function meant to return the new and upcoming debt floor. It checks for min/max bounds for newly computed floors
    */
    function getNextCollateralFloor() public returns (uint256) {
        (, , , uint256 debtCeiling) = safeEngine.collateralTypes(collateralName);
        uint256 lowestPossibleFloor  = minimum(debtCeiling, minDebtFloor);
        uint256 highestPossibleFloor = minimum(debtCeiling, maxDebtFloor);

        // Read the gas and the ETH prices
        uint256 gasPrice = gasPriceOracle.read();
        uint256 ethPrice = ethPriceOracle.read();

        // Calculate the denominated value of the new debt floor
        uint256 debtFloorValue = divide(multiply(multiply(gasPrice, gasAmountForLiquidation), ethPrice), WAD);

        // Calculate the new debt floor in terms of system coins
        uint256 redemptionPrice     = oracleRelayer.redemptionPrice();
        uint256 systemCoinDebtFloor = multiply(divide(multiply(debtFloorValue, RAY), redemptionPrice), RAY);

        // Check boundaries
        if (systemCoinDebtFloor <= lowestPossibleFloor) return lowestPossibleFloor;
        else if (systemCoinDebtFloor >= highestPossibleFloor) return highestPossibleFloor;

        return systemCoinDebtFloor;
    }
}