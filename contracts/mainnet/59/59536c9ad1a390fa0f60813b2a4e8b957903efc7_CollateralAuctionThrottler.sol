/**
 *Submitted for verification at Etherscan.io on 2021-04-07
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


abstract contract LiquidationEngineLike {
    function currentOnAuctionSystemCoins() virtual public view returns (uint256);
    function modifyParameters(bytes32, uint256) virtual external;
}
abstract contract SAFEEngineLike {
    function globalDebt() virtual public view returns (uint256);
    function globalUnbackedDebt() virtual public view returns (uint256);
    function coinBalance(address) virtual public view returns (uint256);
}

contract CollateralAuctionThrottler is IncreasingTreasuryReimbursement {
    // --- Variables ---
    // Minimum delay between consecutive updates
    uint256 public updateDelay;                     // [seconds]
    // Delay since the last update time after which backupLimitRecompute can be called
    uint256 public backupUpdateDelay;               // [seconds]
    // Percentage of global debt taken into account in order to set LiquidationEngine.onAuctionSystemCoinLimit
    uint256 public globalDebtPercentage;            // [hundred]
    // The minimum auction limit
    uint256 public minAuctionLimit;                 // [rad]
    // Last timestamp when the onAuctionSystemCoinLimit was updated
    uint256 public lastUpdateTime;                  // [unix timestamp]

    LiquidationEngineLike    public liquidationEngine;
    SAFEEngineLike           public safeEngine;

    // List of surplus holders
    address[]                public surplusHolders;

    constructor(
      address safeEngine_,
      address liquidationEngine_,
      address treasury_,
      uint256 updateDelay_,
      uint256 backupUpdateDelay_,
      uint256 baseUpdateCallerReward_,
      uint256 maxUpdateCallerReward_,
      uint256 perSecondCallerRewardIncrease_,
      uint256 globalDebtPercentage_,
      address[] memory surplusHolders_
    ) public IncreasingTreasuryReimbursement(treasury_, baseUpdateCallerReward_, maxUpdateCallerReward_, perSecondCallerRewardIncrease_) {
        require(safeEngine_ != address(0), "CollateralAuctionThrottler/null-safe-engine");
        require(liquidationEngine_ != address(0), "CollateralAuctionThrottler/null-liquidation-engine");
        require(updateDelay_ > 0, "CollateralAuctionThrottler/null-update-delay");
        require(backupUpdateDelay_ > updateDelay_, "CollateralAuctionThrottler/invalid-backup-update-delay");
        require(both(globalDebtPercentage_ > 0, globalDebtPercentage_ <= HUNDRED), "CollateralAuctionThrottler/invalid-global-debt-percentage");
        require(surplusHolders_.length <= HOLDERS_ARRAY_LIMIT, "CollateralAuctionThrottler/invalid-holder-array-length");

        safeEngine             = SAFEEngineLike(safeEngine_);
        liquidationEngine      = LiquidationEngineLike(liquidationEngine_);
        updateDelay            = updateDelay_;
        backupUpdateDelay      = backupUpdateDelay_;
        globalDebtPercentage   = globalDebtPercentage_;
        surplusHolders         = surplusHolders_;

        emit ModifyParameters(bytes32("updateDelay"), updateDelay);
        emit ModifyParameters(bytes32("globalDebtPercentage"), globalDebtPercentage);
        emit ModifyParameters(bytes32("backupUpdateDelay"), backupUpdateDelay);
    }

    // --- Math ---
    uint256 internal constant ONE                 = 1;
    uint256 internal constant HOLDERS_ARRAY_LIMIT = 10;
    uint256 internal constant HUNDRED             = 100;

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Administration ---
    /*
    * @notify Modify a uint256 parameter
    * @param parameter The name of the parameter to modify
    * @param data The new parameter value
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "baseUpdateCallerReward") {
          require(data <= maxUpdateCallerReward, "CollateralAuctionThrottler/invalid-min-reward");
          baseUpdateCallerReward = data;
        }
        else if (parameter == "maxUpdateCallerReward") {
          require(data >= baseUpdateCallerReward, "CollateralAuctionThrottler/invalid-max-reward");
          maxUpdateCallerReward = data;
        }
        else if (parameter == "perSecondCallerRewardIncrease") {
          require(data >= RAY, "CollateralAuctionThrottler/invalid-reward-increase");
          perSecondCallerRewardIncrease = data;
        }
        else if (parameter == "maxRewardIncreaseDelay") {
          require(data > 0, "CollateralAuctionThrottler/invalid-max-increase-delay");
          maxRewardIncreaseDelay = data;
        }
        else if (parameter == "updateDelay") {
          require(data > 0, "CollateralAuctionThrottler/null-update-delay");
          updateDelay = data;
        }
        else if (parameter == "backupUpdateDelay") {
          require(data > updateDelay, "CollateralAuctionThrottler/invalid-backup-update-delay");
          backupUpdateDelay = data;
        }
        else if (parameter == "globalDebtPercentage") {
          require(both(data > 0, data <= HUNDRED), "CollateralAuctionThrottler/invalid-global-debt-percentage");
          globalDebtPercentage = data;
        }
        else if (parameter == "minAuctionLimit") {
          minAuctionLimit = data;
        }
        else revert("CollateralAuctionThrottler/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /*
    * @notify Modify the address of a contract param
    * @param parameter The name of the parameter to change the address for
    * @param addr The new address
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "CollateralAuctionThrottler/null-addr");
        if (parameter == "treasury") {
          require(StabilityFeeTreasuryLike(addr).systemCoin() != address(0), "CollateralAuctionThrottler/treasury-coin-not-set");
      	  treasury = StabilityFeeTreasuryLike(addr);
        }
        else if (parameter == "liquidationEngine") {
          liquidationEngine = LiquidationEngineLike(addr);
        }
        else revert("CollateralAuctionThrottler/modify-unrecognized-param");
        emit ModifyParameters(parameter, addr);
    }

    // --- Recompute Logic ---
    /*
    * @notify Recompute and set the new onAuctionSystemCoinLimit
    * @param feeReceiver The address that will receive the reward for recomputing the onAuctionSystemCoinLimit
    */
    function recomputeOnAuctionSystemCoinLimit(address feeReceiver) public {
        // Check delay between calls
        require(either(subtract(now, lastUpdateTime) >= updateDelay, lastUpdateTime == 0), "CollateralAuctionThrottler/wait-more");
        // Get the caller's reward
        uint256 callerReward = getCallerReward(lastUpdateTime, updateDelay);
        // Store the timestamp of the update
        lastUpdateTime = now;
        // Compute total surplus
        uint256 totalSurplus;
        for (uint i = 0; i < surplusHolders.length; i++) {
          totalSurplus = addition(totalSurplus, safeEngine.coinBalance(surplusHolders[i]));
        }
        // Remove surplus from global debt
        uint256 rawGlobalDebt               = subtract(safeEngine.globalDebt(), totalSurplus);
        rawGlobalDebt                       = subtract(rawGlobalDebt, safeEngine.globalUnbackedDebt());
        // Calculate and set the onAuctionSystemCoinLimit
        uint256 newAuctionLimit             = multiply(rawGlobalDebt / HUNDRED, globalDebtPercentage);
        uint256 currentOnAuctionSystemCoins = liquidationEngine.currentOnAuctionSystemCoins();
        newAuctionLimit                     = (newAuctionLimit <= minAuctionLimit) ? minAuctionLimit : newAuctionLimit;
        newAuctionLimit                     = (newAuctionLimit == 0) ? uint(-1) : newAuctionLimit;
        newAuctionLimit                     = (newAuctionLimit < currentOnAuctionSystemCoins) ? currentOnAuctionSystemCoins : newAuctionLimit;
        liquidationEngine.modifyParameters("onAuctionSystemCoinLimit", newAuctionLimit);
        // Pay the caller for updating the rate
        rewardCaller(feeReceiver, callerReward);
    }
    /*
    * @notify Backup function for recomputing the onAuctionSystemCoinLimit in case of a severe delay since the last update
    */
    function backupRecomputeOnAuctionSystemCoinLimit() public {
        // Check delay between calls
        require(both(subtract(now, lastUpdateTime) >= backupUpdateDelay, lastUpdateTime > 0), "CollateralAuctionThrottler/wait-more");
        // Store the timestamp of the update
        lastUpdateTime = now;
        // Set the onAuctionSystemCoinLimit
        liquidationEngine.modifyParameters("onAuctionSystemCoinLimit", uint(-1));
    }
}