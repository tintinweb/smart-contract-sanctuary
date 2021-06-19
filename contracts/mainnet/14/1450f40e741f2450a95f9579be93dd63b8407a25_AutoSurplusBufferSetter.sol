/**
 *Submitted for verification at Etherscan.io on 2021-06-18
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

abstract contract AccountingEngineLike {
    function surplusBuffer() virtual public view returns (uint256);
    function modifyParameters(bytes32, uint256) virtual external;
}
abstract contract SAFEEngineLike {
    function globalDebt() virtual external view returns (uint256);
}

contract AutoSurplusBufferSetter is IncreasingTreasuryReimbursement {
    // --- Variables ---
    // Whether buffer adjustments are blocked or not
    uint256 public stopAdjustments;
    // Delay between updates after which the reward starts to increase
    uint256 public updateDelay;                                                                 // [seconds]
    // The minimum buffer that must be maintained
    uint256 public minimumBufferSize;                                                           // [rad]
    // The max buffer allowed
    uint256 public maximumBufferSize;                                                           // [rad]
    // Last read global debt
    uint256 public lastRecordedGlobalDebt;                                                      // [rad]
    // Minimum change compared to current globalDebt that allows a new modifyParameters() call
    uint256 public minimumGlobalDebtChange;                                                     // [thousand]
    // Percentage of global debt that should be covered by the buffer
    uint256 public coveredDebt;                                                                 // [thousand]
    // Last timestamp when the median was updated
    uint256 public lastUpdateTime;                                                              // [unix timestamp]

    // Safe engine contract
    SAFEEngineLike       public safeEngine;
    // Accounting engine contract
    AccountingEngineLike public accountingEngine;

    constructor(
      address treasury_,
      address safeEngine_,
      address accountingEngine_,
      uint256 minimumBufferSize_,
      uint256 minimumGlobalDebtChange_,
      uint256 coveredDebt_,
      uint256 updateDelay_,
      uint256 baseUpdateCallerReward_,
      uint256 maxUpdateCallerReward_,
      uint256 perSecondCallerRewardIncrease_
    ) public IncreasingTreasuryReimbursement(treasury_, baseUpdateCallerReward_, maxUpdateCallerReward_, perSecondCallerRewardIncrease_) {
        require(both(minimumGlobalDebtChange_ > 0, minimumGlobalDebtChange_ <= THOUSAND), "AutoSurplusBufferSetter/invalid-debt-change");
        require(both(coveredDebt_ > 0, coveredDebt_ <= THOUSAND), "AutoSurplusBufferSetter/invalid-covered-debt");
        require(updateDelay_ > 0, "AutoSurplusBufferSetter/null-update-delay");

        minimumBufferSize        = minimumBufferSize_;
        maximumBufferSize        = uint(-1);
        coveredDebt              = coveredDebt_;
        minimumGlobalDebtChange  = minimumGlobalDebtChange_;
        updateDelay              = updateDelay_;

        safeEngine               = SAFEEngineLike(safeEngine_);
        accountingEngine         = AccountingEngineLike(accountingEngine_);

        emit ModifyParameters(bytes32("minimumBufferSize"), minimumBufferSize);
        emit ModifyParameters(bytes32("maximumBufferSize"), maximumBufferSize);
        emit ModifyParameters(bytes32("coveredDebt"), coveredDebt);
        emit ModifyParameters(bytes32("minimumGlobalDebtChange"), minimumGlobalDebtChange);
        emit ModifyParameters(bytes32("accountingEngine"), address(accountingEngine));
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
      assembly{ z := and(x, y)}
    }

    // --- Administration ---
    /*
    * @notify Modify an uint256 parameter
    * @param parameter The name of the parameter to change
    * @param val The new parameter value
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        if (parameter == "minimumBufferSize") minimumBufferSize = val;
        else if (parameter == "maximumBufferSize") {
          require(val >= minimumBufferSize, "AutoSurplusBufferSetter/max-buffer-size-too-small");
          maximumBufferSize = val;
        }
        else if (parameter == "minimumGlobalDebtChange") {
          require(both(val > 0, val <= THOUSAND), "AutoSurplusBufferSetter/invalid-debt-change");
          minimumGlobalDebtChange = val;
        }
        else if (parameter == "coveredDebt") {
          require(both(val > 0, val <= THOUSAND), "AutoSurplusBufferSetter/invalid-covered-debt");
          coveredDebt = val;
        }
        else if (parameter == "baseUpdateCallerReward") {
          require(val <= maxUpdateCallerReward, "AutoSurplusBufferSetter/invalid-min-reward");
          baseUpdateCallerReward = val;
        }
        else if (parameter == "maxUpdateCallerReward") {
          require(val >= baseUpdateCallerReward, "AutoSurplusBufferSetter/invalid-max-reward");
          maxUpdateCallerReward = val;
        }
        else if (parameter == "perSecondCallerRewardIncrease") {
          require(val >= RAY, "AutoSurplusBufferSetter/invalid-reward-increase");
          perSecondCallerRewardIncrease = val;
        }
        else if (parameter == "maxRewardIncreaseDelay") {
          require(val > 0, "AutoSurplusBufferSetter/invalid-max-increase-delay");
          maxRewardIncreaseDelay = val;
        }
        else if (parameter == "updateDelay") {
          require(val > 0, "AutoSurplusBufferSetter/null-update-delay");
          updateDelay = val;
        }
        else if (parameter == "stopAdjustments") {
          require(val <= 1, "AutoSurplusBufferSetter/invalid-stop-adjust");
          stopAdjustments = val;
        }
        else revert("AutoSurplusBufferSetter/modify-unrecognized-param");
        emit ModifyParameters(parameter, val);
    }
    /*
    * @notify Modify an address param
    * @param parameter The name of the parameter to change
    * @param addr The new address for the parameter
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "AutoSurplusBufferSetter/null-address");
        if (parameter == "accountingEngine") accountingEngine = AccountingEngineLike(addr);
        else if (parameter == "treasury") treasury = StabilityFeeTreasuryLike(addr);
        else revert("AutoSurplusBufferSetter/modify-unrecognized-param");
        emit ModifyParameters(parameter, addr);
    }

    // --- Math ---
    uint internal constant RAD      = 10 ** 45;
    uint internal constant THOUSAND = 1000;

    // --- Utils ---
    /*
    * @notify Return the percentage debt change since the last recorded debt amount in the system
    * @param currentGlobalDebt The current globalDebt in the system
    */
    function percentageDebtChange(uint currentGlobalDebt) public view returns (uint256) {
        if (lastRecordedGlobalDebt == 0) return uint(-1);
        uint256 deltaDebt = (currentGlobalDebt >= lastRecordedGlobalDebt) ?
          subtract(currentGlobalDebt, lastRecordedGlobalDebt) : subtract(lastRecordedGlobalDebt, currentGlobalDebt);
        return multiply(deltaDebt, THOUSAND) / lastRecordedGlobalDebt;
    }
    /*
    * @notify Return the upcoming surplus buffer
    * @param currentGlobalDebt The current amount of debt in the system
    * @return newBuffer The new surplus buffer
    */
    function getNewBuffer(uint256 currentGlobalDebt) public view returns (uint newBuffer) {
        if (currentGlobalDebt >= uint(-1) / coveredDebt) return maximumBufferSize;
        newBuffer = multiply(coveredDebt, currentGlobalDebt) / THOUSAND;
        newBuffer = both(newBuffer > maximumBufferSize, maximumBufferSize > 0) ? maximumBufferSize : newBuffer;
        newBuffer = (newBuffer < minimumBufferSize) ? minimumBufferSize : newBuffer;
    }

    // --- Buffer Adjustment ---
    /*
    * @notify Calculate and set a new surplus buffer
    * @param feeReceiver The address that will receive the SF reward for calling this function
    */
    function adjustSurplusBuffer(address feeReceiver) external {
        // Check if adjustments are forbidden or not
        require(stopAdjustments == 0, "AutoSurplusBufferSetter/cannot-adjust");
        // Check delay between calls
        require(either(subtract(now, lastUpdateTime) >= updateDelay, lastUpdateTime == 0), "AutoSurplusBufferSetter/wait-more");
        // Get the caller's reward
        uint256 callerReward = getCallerReward(lastUpdateTime, updateDelay);
        // Store the timestamp of the update
        lastUpdateTime = now;

        // Get the current global debt
        uint currentGlobalDebt = safeEngine.globalDebt();
        // Check if we didn't already reach the max buffer
        if (both(currentGlobalDebt > lastRecordedGlobalDebt, maximumBufferSize > 0)) {
          require(accountingEngine.surplusBuffer() < maximumBufferSize, "AutoSurplusBufferSetter/max-buffer-reached");
        }
        // Check that global debt changed enough
        require(percentageDebtChange(currentGlobalDebt) >= subtract(THOUSAND, minimumGlobalDebtChange), "AutoSurplusBufferSetter/small-debt-change");
        // Compute the new buffer
        uint newBuffer         = getNewBuffer(currentGlobalDebt);

        lastRecordedGlobalDebt = currentGlobalDebt;
        accountingEngine.modifyParameters("surplusBuffer", newBuffer);

        // Pay the caller for updating the rate
        rewardCaller(feeReceiver, callerReward);
    }
}