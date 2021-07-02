/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

pragma solidity ^0.6.7;

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
    function modifyParameters(bytes32, uint256) virtual external;
}
abstract contract OracleRelayerLike {
    function redemptionPrice() virtual external returns (uint256);
}

contract AuctionedSurplusSetter is IncreasingTreasuryReimbursement {
    // --- Variables ---
    // Minimum amount of surplus to sell in one auction
    uint256 public minAuctionedSurplus;                   // [rad]
    // Target value for the amount of surplus to sell
    uint256 public targetValue;                           // [ray]
    // The min delay between two adjustments of the surplus amount
    uint256 public updateDelay;                           // [seconds]
    // Last timestamp when the surplus amount was updated
    uint256 public lastUpdateTime;                        // [unix timestamp]

    // Accounting engine contract
    AccountingEngineLike public accountingEngine;
    // The oracle relayer contract
    OracleRelayerLike    public oracleRelayer;

    // --- Events ---
    event RecomputeSurplusAmountAuctioned(uint256 surplusToSell);

    constructor(
      address treasury_,
      address oracleRelayer_,
      address accountingEngine_,
      uint256 minAuctionedSurplus_,
      uint256 targetValue_,
      uint256 updateDelay_,
      uint256 baseUpdateCallerReward_,
      uint256 maxUpdateCallerReward_,
      uint256 perSecondCallerRewardIncrease_
    ) public IncreasingTreasuryReimbursement(treasury_, baseUpdateCallerReward_, maxUpdateCallerReward_, perSecondCallerRewardIncrease_) {
        require(both(oracleRelayer_ != address(0), accountingEngine_ != address(0)), "AuctionedSurplusSetter/invalid-core-contracts");
        require(minAuctionedSurplus_ > 0, "AuctionedSurplusSetter/invalid-min-auctioned-surplus");
        require(targetValue_ > 0, "AuctionedSurplusSetter/invalid-target-value");
        require(updateDelay_ > 0, "AuctionedSurplusSetter/null-update-delay");

        minAuctionedSurplus      = minAuctionedSurplus_;
        updateDelay              = updateDelay_;
        targetValue              = targetValue_;

        oracleRelayer            = OracleRelayerLike(oracleRelayer_);
        accountingEngine         = AccountingEngineLike(accountingEngine_);

        emit ModifyParameters("minAuctionedSurplus", minAuctionedSurplus);
        emit ModifyParameters("targetValue", targetValue);
        emit ModifyParameters("updateDelay", updateDelay);
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
        if (parameter == "minAuctionedSurplus") {
          require(val > 0, "AuctionedSurplusSetter/null-min-auctioned-amount");
          minAuctionedSurplus = val;
        }
        else if (parameter == "targetValue") {
          require(val > 0, "AuctionedSurplusSetter/null-target-value");
          targetValue = val;
        }
        else if (parameter == "baseUpdateCallerReward") {
          require(val <= maxUpdateCallerReward, "AuctionedSurplusSetter/invalid-min-reward");
          baseUpdateCallerReward = val;
        }
        else if (parameter == "maxUpdateCallerReward") {
          require(val >= baseUpdateCallerReward, "AuctionedSurplusSetter/invalid-max-reward");
          maxUpdateCallerReward = val;
        }
        else if (parameter == "perSecondCallerRewardIncrease") {
          require(val >= RAY, "AuctionedSurplusSetter/invalid-reward-increase");
          perSecondCallerRewardIncrease = val;
        }
        else if (parameter == "maxRewardIncreaseDelay") {
          require(val > 0, "AuctionedSurplusSetter/invalid-max-increase-delay");
          maxRewardIncreaseDelay = val;
        }
        else if (parameter == "updateDelay") {
          require(val > 0, "AuctionedSurplusSetter/null-update-delay");
          updateDelay = val;
        }
        else revert("AuctionedSurplusSetter/modify-unrecognized-param");
        emit ModifyParameters(parameter, val);
    }
    /*
    * @notify Modify an address param
    * @param parameter The name of the parameter to change
    * @param addr The new address for the parameter
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "AuctionedSurplusSetter/null-address");
        if (parameter == "treasury") treasury = StabilityFeeTreasuryLike(addr);
        else revert("AuctionedSurplusSetter/modify-unrecognized-param");
        emit ModifyParameters(parameter, addr);
    }

    // --- Core Logic ---
    /*
    * @notify Recompute and set the new amount of surplus that's sold in one surplus auction
    */
    function recomputeSurplusAmountAuctioned(address feeReceiver) public {
        // Check delay between calls
        require(either(subtract(now, lastUpdateTime) >= updateDelay, lastUpdateTime == 0), "AuctionedSurplusSetter/wait-more");
        // Get the caller's reward
        uint256 callerReward = getCallerReward(lastUpdateTime, updateDelay);
        // Store the timestamp of the update
        lastUpdateTime = now;

        // Calculate the new amount to sell
        uint256 surplusToSell = multiply(rdivide(targetValue, oracleRelayer.redemptionPrice()), WAD);
        surplusToSell         = (surplusToSell < minAuctionedSurplus) ? minAuctionedSurplus : surplusToSell;

        // Set the new amount
        accountingEngine.modifyParameters("surplusAuctionAmountToSell", surplusToSell);

        // Emit an event
        emit RecomputeSurplusAmountAuctioned(surplusToSell);

        // Pay the caller for updating the rate
        rewardCaller(feeReceiver, callerReward);
    }
}