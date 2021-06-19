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

abstract contract OracleLike {
    function getResultWithValidity() virtual external view returns (uint256, bool);
}
abstract contract AccountingEngineLike {
    function modifyParameters(bytes32, uint256) virtual external;
}

contract DebtAuctionInitialParameterSetter is IncreasingTreasuryReimbursement {
    // --- Variables ---
    // Delay between updates after which the reward starts to increase
    uint256 public updateDelay;
    // Last timestamp when the median was updated
    uint256 public lastUpdateTime;                                              // [unix timestamp]
    // Min amount of protocol tokens that should be offered in the auction
    uint256 public minProtocolTokenAmountOffered;                               // [wad]
    // Premium subtracted from the new amount of protocol tokens to be offered
    uint256 public protocolTokenPremium;                                        // [thousand]
    // Value of the initial debt bid
    uint256 public bidTargetValue;                                              // [wad]

    // The protocol token oracle
    OracleLike           public protocolTokenOrcl;
    // The system coin oracle
    OracleLike           public systemCoinOrcl;
    // The accounting engine contract
    AccountingEngineLike public accountingEngine;

    // --- Events ---
    event SetDebtAuctionInitialParameters(uint256 debtAuctionBidSize, uint256 initialDebtAuctionMintedTokens);

    constructor(
      address protocolTokenOrcl_,
      address systemCoinOrcl_,
      address accountingEngine_,
      address treasury_,
      uint256 updateDelay_,
      uint256 baseUpdateCallerReward_,
      uint256 maxUpdateCallerReward_,
      uint256 perSecondCallerRewardIncrease_,
      uint256 minProtocolTokenAmountOffered_,
      uint256 protocolTokenPremium_,
      uint256 bidTargetValue_
    ) public IncreasingTreasuryReimbursement(treasury_, baseUpdateCallerReward_, maxUpdateCallerReward_, perSecondCallerRewardIncrease_) {
        require(minProtocolTokenAmountOffered_ > 0, "DebtAuctionInitialParameterSetter/null-min-prot-amt");
        require(protocolTokenPremium_ < THOUSAND, "DebtAuctionInitialParameterSetter/invalid-prot-token-premium");
        require(both(both(protocolTokenOrcl_ != address(0), systemCoinOrcl_ != address(0)), accountingEngine_ != address(0)), "DebtAuctionInitialParameterSetter/invalid-contract-address");
        require(updateDelay_ > 0, "DebtAuctionInitialParameterSetter/null-update-delay");
        require(bidTargetValue_ > 0, "DebtAuctionInitialParameterSetter/invalid-bid-target-value");

        protocolTokenOrcl              = OracleLike(protocolTokenOrcl_);
        systemCoinOrcl                 = OracleLike(systemCoinOrcl_);
        accountingEngine               = AccountingEngineLike(accountingEngine_);

        minProtocolTokenAmountOffered  = minProtocolTokenAmountOffered_;
        protocolTokenPremium           = protocolTokenPremium_;
        updateDelay                    = updateDelay_;
        bidTargetValue                 = bidTargetValue_;

        emit ModifyParameters(bytes32("protocolTokenOrcl"), protocolTokenOrcl_);
        emit ModifyParameters(bytes32("systemCoinOrcl"), systemCoinOrcl_);
        emit ModifyParameters(bytes32("accountingEngine"), accountingEngine_);
        emit ModifyParameters(bytes32("bidTargetValue"), bidTargetValue);
        emit ModifyParameters(bytes32("minProtocolTokenAmountOffered"), minProtocolTokenAmountOffered);
        emit ModifyParameters(bytes32("protocolTokenPremium"), protocolTokenPremium);
        emit ModifyParameters(bytes32("updateDelay"), updateDelay);
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
      assembly{ z := and(x, y)}
    }

    // --- Math ---
    uint internal constant THOUSAND = 10 ** 3;
    function divide(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "divide-null-y");
        z = x / y;
        require(z <= x);
    }

    // --- Administration ---
    /*
    * @notice Modify the address of a contract integrated with this setter
    * @param parameter Name of the contract to set a new address for
    * @param addr The new address
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "DebtAuctionInitialParameterSetter/null-addr");
        if (parameter == "protocolTokenOrcl") protocolTokenOrcl = OracleLike(addr);
        else if (parameter == "systemCoinOrcl") systemCoinOrcl = OracleLike(addr);
        else if (parameter == "accountingEngine") accountingEngine = AccountingEngineLike(addr);
        else if (parameter == "treasury") {
          require(StabilityFeeTreasuryLike(addr).systemCoin() != address(0), "DebtAuctionInitialParameterSetter/treasury-coin-not-set");
      	  treasury = StabilityFeeTreasuryLike(addr);
        }
        else revert("DebtAuctionInitialParameterSetter/modify-unrecognized-param");
        emit ModifyParameters(parameter, addr);
    }
    /*
    * @notice Modify a uint256 parameter
    * @param parameter Name of the parameter
    * @param addr The new parameter value
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        if (parameter == "minProtocolTokenAmountOffered") {
          require(val > 0, "DebtAuctionInitialParameterSetter/null-min-prot-amt");
          minProtocolTokenAmountOffered = val;
        }
        else if (parameter == "protocolTokenPremium") {
          require(val < THOUSAND, "DebtAuctionInitialParameterSetter/invalid-prot-token-premium");
          protocolTokenPremium = val;
        }
        else if (parameter == "baseUpdateCallerReward") {
            require(val <= maxUpdateCallerReward, "DebtAuctionInitialParameterSetter/invalid-base-caller-reward");
            baseUpdateCallerReward = val;
        }
        else if (parameter == "maxUpdateCallerReward") {
          require(val >= baseUpdateCallerReward, "DebtAuctionInitialParameterSetter/invalid-max-reward");
          maxUpdateCallerReward = val;
        }
        else if (parameter == "perSecondCallerRewardIncrease") {
          require(val >= RAY, "DebtAuctionInitialParameterSetter/invalid-reward-increase");
          perSecondCallerRewardIncrease = val;
        }
        else if (parameter == "maxRewardIncreaseDelay") {
          require(val > 0, "DebtAuctionInitialParameterSetter/invalid-max-increase-delay");
          maxRewardIncreaseDelay = val;
        }
        else if (parameter == "updateDelay") {
          require(val > 0, "DebtAuctionInitialParameterSetter/null-update-delay");
          updateDelay = val;
        }
        else if (parameter == "bidTargetValue") {
          require(val > 0, "DebtAuctionInitialParameterSetter/invalid-bid-target-value");
          bidTargetValue = val;
        }
        else if (parameter == "lastUpdateTime") {
          require(val > now, "DebtAuctionInitialParameterSetter/");
          lastUpdateTime = val;
        }
        else revert("DebtAuctionInitialParameterSetter/modify-unrecognized-param");
        emit ModifyParameters(parameter, val);
    }

    // --- Setter ---
    /*
    * @notify View function that returns the new, initial debt auction bid
    * @returns debtAuctionBidSize The new, initial debt auction bid
    */
    function getNewDebtBid() external view returns (uint256 debtAuctionBidSize) {
        // Get token price
        (uint256 systemCoinPrice, bool validSysCoinPrice)   = systemCoinOrcl.getResultWithValidity();
        require(both(systemCoinPrice > 0, validSysCoinPrice), "DebtAuctionInitialParameterSetter/invalid-price");

        // Compute the bid size
        debtAuctionBidSize = divide(multiply(multiply(bidTargetValue, WAD), RAY), systemCoinPrice);
        if (debtAuctionBidSize < RAY) {
          debtAuctionBidSize = RAY;
        }
    }
    /*
    * @notify View function that returns the initial amount of protocol tokens which should be offered in a debt auction
    * @returns debtAuctionMintedTokens The initial amount of protocol tokens that should be offered in a debt auction
    */
    function getRawProtocolTokenAmount() external view returns (uint256 debtAuctionMintedTokens) {
        // Get token price
        (uint256 protocolTknPrice, bool validProtocolPrice) = protocolTokenOrcl.getResultWithValidity();
        require(both(validProtocolPrice, protocolTknPrice > 0), "DebtAuctionInitialParameterSetter/invalid-price");

        // Compute the amont of protocol tokens without the premium
        debtAuctionMintedTokens = divide(multiply(bidTargetValue, WAD), protocolTknPrice);

        // Take into account the minimum amount of protocol tokens to offer
        if (debtAuctionMintedTokens < minProtocolTokenAmountOffered) {
          debtAuctionMintedTokens = minProtocolTokenAmountOffered;
        }
    }
    /*
    * @notify View function that returns the initial amount of protocol tokens with a premium added on top
    * @returns debtAuctionMintedTokens The initial amount of protocol tokens with a premium added on top
    */
    function getPremiumAdjustedProtocolTokenAmount() external view returns (uint256 debtAuctionMintedTokens) {
        // Get token price
        (uint256 protocolTknPrice, bool validProtocolPrice) = protocolTokenOrcl.getResultWithValidity();
        require(both(validProtocolPrice, protocolTknPrice > 0), "DebtAuctionInitialParameterSetter/invalid-price");

        // Compute the amont of protocol tokens without the premium and apply it
        debtAuctionMintedTokens = divide(multiply(divide(multiply(bidTargetValue, WAD), protocolTknPrice), protocolTokenPremium), THOUSAND);

        // Take into account the minimum amount of protocol tokens to offer
        if (debtAuctionMintedTokens < minProtocolTokenAmountOffered) {
          debtAuctionMintedTokens = minProtocolTokenAmountOffered;
        }
    }
    /*
    * @notify Set the new debtAuctionBidSize and initialDebtAuctionMintedTokens inside the AccountingEngine
    * @param feeReceiver The address that will receive the reward for setting new params
    */
    function setDebtAuctionInitialParameters(address feeReceiver) external {
        // Check delay between calls
        require(either(subtract(now, lastUpdateTime) >= updateDelay, lastUpdateTime == 0), "DebtAuctionInitialParameterSetter/wait-more");
        // Get the caller's reward
        uint256 callerReward = getCallerReward(lastUpdateTime, updateDelay);
        // Store the timestamp of the update
        lastUpdateTime = now;

        // Get token prices
        (uint256 protocolTknPrice, bool validProtocolPrice) = protocolTokenOrcl.getResultWithValidity();
        (uint256 systemCoinPrice, bool validSysCoinPrice)   = systemCoinOrcl.getResultWithValidity();
        require(both(validProtocolPrice, validSysCoinPrice), "DebtAuctionInitialParameterSetter/invalid-prices");
        require(both(protocolTknPrice > 0, systemCoinPrice > 0), "DebtAuctionInitialParameterSetter/null-prices");

        // Compute the scaled bid target value
        uint256 scaledBidTargetValue = multiply(bidTargetValue, WAD);

        // Compute the amont of protocol tokens without the premium
        uint256 initialDebtAuctionMintedTokens = divide(scaledBidTargetValue, protocolTknPrice);

        // Apply the premium
        initialDebtAuctionMintedTokens = divide(multiply(initialDebtAuctionMintedTokens, protocolTokenPremium), THOUSAND);

        // Take into account the minimum amount of protocol tokens to offer
        if (initialDebtAuctionMintedTokens < minProtocolTokenAmountOffered) {
          initialDebtAuctionMintedTokens = minProtocolTokenAmountOffered;
        }

        // Compute the debtAuctionBidSize as a RAD taking into account the minimum amount to bid
        uint256 debtAuctionBidSize = divide(multiply(scaledBidTargetValue, RAY), systemCoinPrice);
        if (debtAuctionBidSize < RAY) {
          debtAuctionBidSize = RAY;
        }

        // Set the debt bid and the associated protocol token amount in the accounting engine
        accountingEngine.modifyParameters("debtAuctionBidSize", debtAuctionBidSize);
        accountingEngine.modifyParameters("initialDebtAuctionMintedTokens", initialDebtAuctionMintedTokens);

        // Emit an event
        emit SetDebtAuctionInitialParameters(debtAuctionBidSize, initialDebtAuctionMintedTokens);

        // Pay the caller for updating the rate
        rewardCaller(feeReceiver, callerReward);
    }
    /*
    * @notice Manually set initial debt auction parameters
    * @param debtAuctionBidSize The initial debt auction bid size
    * @param initialDebtAuctionMintedTokens The initial amount of protocol tokens to mint in exchange for debtAuctionBidSize system coins
    */
    function manualSetDebtAuctionParameters(uint256 debtAuctionBidSize, uint256 initialDebtAuctionMintedTokens)
      external isAuthorized {
        accountingEngine.modifyParameters("debtAuctionBidSize", debtAuctionBidSize);
        accountingEngine.modifyParameters("initialDebtAuctionMintedTokens", initialDebtAuctionMintedTokens);
        emit SetDebtAuctionInitialParameters(debtAuctionBidSize, initialDebtAuctionMintedTokens);
    }
}