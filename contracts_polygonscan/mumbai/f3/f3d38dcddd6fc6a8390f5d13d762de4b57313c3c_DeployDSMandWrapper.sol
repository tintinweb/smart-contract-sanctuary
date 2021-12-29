/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

// Verified using https://dapp.tools

// hevm: flattened sources of /nix/store/9562cr0d7ld8jb3ba5jdn2xyk9cx9kxs-h2o-governance-actions/dapp/h2o-governance-actions/src/DeployDSMandWrapper.sol

pragma solidity =0.6.7;

////// /nix/store/irf6p6ny7fdsxbc9i9p4bz4vzfbccq9b-geb-treasury-reimbursement/dapp/geb-treasury-reimbursement/src/math/GebMath.sol
/* pragma solidity 0.6.7; */

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

////// /nix/store/irf6p6ny7fdsxbc9i9p4bz4vzfbccq9b-geb-treasury-reimbursement/dapp/geb-treasury-reimbursement/src/reimbursement/NoSetupNoAuthIncreasingTreasuryReimbursement.sol
/* pragma solidity 0.6.7; */

/* import "../math/GebMath.sol"; */

abstract contract StabilityFeeTreasuryLike_13 {
    function getAllowance(address) virtual external view returns (uint, uint);
    function systemCoin() virtual external view returns (address);
    function pullFunds(address, address, uint) virtual external;
}

contract NoSetupNoAuthIncreasingTreasuryReimbursement is GebMath {
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
    StabilityFeeTreasuryLike_13  public treasury;

    // --- Events ---
    event ModifyParameters(
      bytes32 parameter,
      address addr
    );
    event ModifyParameters(
      bytes32 parameter,
      uint256 val
    );
    event FailRewardCaller(bytes revertReason, address feeReceiver, uint256 amount);

    constructor() public {
        maxRewardIncreaseDelay = uint(-1);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
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

////// /nix/store/n9q4i4x8k6az7jv4dl3rkjmdw2kjdr20-geb-fsm/dapp/geb-fsm/src/DSM.sol
/* pragma solidity 0.6.7; */

/* import "geb-treasury-reimbursement/reimbursement/NoSetupNoAuthIncreasingTreasuryReimbursement.sol"; */

abstract contract DSValueLike_1 {
    function getResultWithValidity() virtual external view returns (uint256, bool);
}
abstract contract FSMWrapperLike_1 {
    function renumerateCaller(address) virtual external;
}

contract DSM {
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
        require(authorizedAccounts[msg.sender] == 1, "DSM/account-not-authorized");
        _;
    }

    // --- Stop ---
    uint256 public stopped;
    modifier stoppable { require(stopped == 0, "DSM/is-stopped"); _; }

    // --- Variables ---
    address public priceSource;
    uint16  public updateDelay = ONE_HOUR;      // [seconds]
    uint64  public lastUpdateTime;              // [timestamp]
    uint256 public newPriceDeviation;           // [wad]

    uint16  constant ONE_HOUR = uint16(3600);   // [seconds]

    // --- Structs ---
    struct Feed {
        uint128 value;
        uint128 isValid;
    }

    Feed currentFeed;
    Feed nextFeed;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, uint256 val);
    event ModifyParameters(bytes32 parameter, address val);
    event Start();
    event Stop();
    event ChangePriceSource(address priceSource);
    event ChangeDeviation(uint deviation);
    event ChangeDelay(uint16 delay);
    event RestartValue();
    event UpdateResult(uint256 newMedian, uint256 lastUpdateTime);

    constructor (address priceSource_, uint256 deviation) public {
        require(deviation > 0 && deviation < WAD, "DSM/invalid-deviation");

        authorizedAccounts[msg.sender] = 1;

        priceSource       = priceSource_;
        newPriceDeviation = deviation;

        if (priceSource != address(0)) {
          // Read from the median
          (uint256 priceFeedValue, bool hasValidValue) = getPriceSourceUpdate();
          // If the price is valid, update state
          if (hasValidValue) {
            nextFeed = Feed(uint128(uint(priceFeedValue)), 1);
            currentFeed = nextFeed;
            lastUpdateTime = latestUpdateTime(currentTime());
            emit UpdateResult(uint(currentFeed.value), lastUpdateTime);
          }
        }

        emit AddAuthorization(msg.sender);
        emit ChangePriceSource(priceSource);
        emit ChangeDeviation(deviation);
    }

    // --- DSM Specific Math ---
    uint256 private constant WAD = 10 ** 18;

    function add(uint64 x, uint64 y) internal pure returns (uint64 z) {
        z = x + y;
        require(z >= x);
    }
    function sub(uint x, uint y) private pure returns (uint z) {
        z = x - y;
        require(z <= x, "uint-uint-sub-underflow");
    }
    function mul(uint x, uint y) private pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "uint-uint-mul-overflow");
    }
    function wmul(uint x, uint y) private pure returns (uint z) {
        z = mul(x, y) / WAD;
    }

    // --- Core Logic ---
    /*
    * @notify Stop the DSM
    */
    function stop() external isAuthorized {
        stopped = 1;
        emit Stop();
    }
    /*
    * @notify Start the DSM
    */
    function start() external isAuthorized {
        stopped = 0;
        emit Start();
    }

    /*
    * @notify Change the oracle from which the DSM reads
    * @param priceSource_ The address of the oracle from which the DSM reads
    */
    function changePriceSource(address priceSource_) external isAuthorized {
        priceSource = priceSource_;
        emit ChangePriceSource(priceSource);
    }

    /*
    * @notify Helper that returns the current block timestamp
    */
    function currentTime() internal view returns (uint) {
        return block.timestamp;
    }

    /*
    * @notify Return the latest update time
    * @param timestamp Custom reference timestamp to determine the latest update time from
    */
    function latestUpdateTime(uint timestamp) internal view returns (uint64) {
        require(updateDelay != 0, "DSM/update-delay-is-zero");
        return uint64(timestamp - (timestamp % updateDelay));
    }

    /*
    * @notify Change the deviation supported for the next price
    * @param deviation Allowed deviation for the next price compared to the current one
    */
    function changeNextPriceDeviation(uint deviation) external isAuthorized {
        require(deviation > 0 && deviation < WAD, "DSM/invalid-deviation");
        newPriceDeviation = deviation;
        emit ChangeDeviation(deviation);
    }

    /*
    * @notify Change the delay between updates
    * @param delay The new delay
    */
    function changeDelay(uint16 delay) external isAuthorized {
        require(delay > 0, "DSM/delay-is-zero");
        updateDelay = delay;
        emit ChangeDelay(updateDelay);
    }

    /*
    * @notify Restart/set to zero the feeds stored in the DSM
    */
    function restartValue() external isAuthorized {
        currentFeed = nextFeed = Feed(0, 0);
        stopped = 1;
        emit RestartValue();
    }

    /*
    * @notify View function that returns whether the delay between calls has been passed
    */
    function passedDelay() public view returns (bool ok) {
        return currentTime() >= uint(add(lastUpdateTime, uint64(updateDelay)));
    }

    /*
    * @notify Update the price feeds inside the DSM
    */
    function updateResult() virtual external stoppable {
        // Check if the delay passed
        require(passedDelay(), "DSM/not-passed");
        // Read the price from the median
        (uint256 priceFeedValue, bool hasValidValue) = getPriceSourceUpdate();
        // If the value is valid, update storage
        if (hasValidValue) {
            // Update state
            currentFeed.isValid = nextFeed.isValid;
            currentFeed.value   = getNextBoundedPrice();
            nextFeed            = Feed(uint128(priceFeedValue), 1);
            lastUpdateTime      = latestUpdateTime(currentTime());
            // Emit event
            emit UpdateResult(uint(currentFeed.value), lastUpdateTime);
        }
    }

    // --- Getters ---
    /*
    * @notify Internal helper that reads a price and its validity from the priceSource
    */
    function getPriceSourceUpdate() internal view returns (uint256, bool) {
        try DSValueLike_1(priceSource).getResultWithValidity() returns (uint256 priceFeedValue, bool hasValidValue) {
          return (priceFeedValue, hasValidValue);
        }
        catch(bytes memory) {
          return (0, false);
        }
    }

    /*
    * @notify View function that returns what the next bounded price would be (taking into account the deviation set in this contract)
    */
    function getNextBoundedPrice() public view returns (uint128 boundedPrice) {
        boundedPrice = nextFeed.value;
        if (currentFeed.value == 0) return boundedPrice;

        uint128 lowerBound = uint128(wmul(uint(currentFeed.value), newPriceDeviation));
        uint128 upperBound = uint128(wmul(uint(currentFeed.value), sub(mul(uint(2), WAD), newPriceDeviation)));

        if (nextFeed.value < lowerBound) {
          boundedPrice = lowerBound;
        } else if (nextFeed.value > upperBound) {
          boundedPrice = upperBound;
        }
    }

    /*
    * @notify Returns the lower bound for the upcoming price (taking into account the deviation var)
    */
    function getNextPriceLowerBound() public view returns (uint128) {
        return uint128(wmul(uint(currentFeed.value), newPriceDeviation));
    }

    /*
    * @notify Returns the upper bound for the upcoming price (taking into account the deviation var)
    */
    function getNextPriceUpperBound() public view returns (uint128) {
        return uint128(wmul(uint(currentFeed.value), sub(mul(uint(2), WAD), newPriceDeviation)));
    }

    /*
    * @notify Return the current feed value and its validity
    */
    function getResultWithValidity() external view returns (uint256, bool) {
        return (uint(currentFeed.value), currentFeed.isValid == 1);
    }
    /*
    * @notify Return the next feed's value and its validity
    */
    function getNextResultWithValidity() external view returns (uint256, bool) {
        return (nextFeed.value, nextFeed.isValid == 1);
    }
    /*
    * @notify Return the current feed's value only if it's valid, otherwise revert
    */
    function read() external view returns (uint256) {
        require(currentFeed.isValid == 1, "DSM/no-current-value");
        return currentFeed.value;
    }
}

contract SelfFundedDSM is DSM, NoSetupNoAuthIncreasingTreasuryReimbursement {
    constructor (address priceSource_, uint256 deviation) public DSM(priceSource_, deviation) {}

    // --- Administration ---
    /*
    * @notify Modify a uint256 parameter
    * @param parameter The parameter name
    * @param val The new value for the parameter
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        if (parameter == "baseUpdateCallerReward") {
          require(val < maxUpdateCallerReward, "SelfFundedDSM/invalid-base-caller-reward");
          baseUpdateCallerReward = val;
        }
        else if (parameter == "maxUpdateCallerReward") {
          require(val >= baseUpdateCallerReward, "SelfFundedDSM/invalid-max-reward");
          maxUpdateCallerReward = val;
        }
        else if (parameter == "perSecondCallerRewardIncrease") {
          require(val >= RAY, "SelfFundedDSM/invalid-reward-increase");
          perSecondCallerRewardIncrease = val;
        }
        else if (parameter == "maxRewardIncreaseDelay") {
          require(val > 0, "SelfFundedDSM/invalid-max-increase-delay");
          maxRewardIncreaseDelay = val;
        }
        else revert("SelfFundedDSM/modify-unrecognized-param");
        emit ModifyParameters(parameter, val);
    }
    /*
    * @notify Modify an address parameter
    * @param parameter The parameter name
    * @param val The new value for the parameter
    */
    function modifyParameters(bytes32 parameter, address val) external isAuthorized {
        if (parameter == "treasury") {
          require(val != address(0), "SelfFundedDSM/invalid-treasury");
          treasury = StabilityFeeTreasuryLike_13(val);
        }
        else revert("SelfFundedDSM/modify-unrecognized-param");
        emit ModifyParameters(parameter, val);
    }

    // --- Core Logic ---
    /*
    * @notify Update the price feeds inside the DSM
    */
    function updateResult() override external stoppable {
        // Check if the delay passed
        require(passedDelay(), "SelfFundedDSM/not-passed");
        // Read the price from the median
        (uint256 priceFeedValue, bool hasValidValue) = getPriceSourceUpdate();
        // If the value is valid, update storage
        if (hasValidValue) {
            // Get the caller's reward
            uint256 callerReward = getCallerReward(lastUpdateTime, updateDelay);
            // Update state
            currentFeed.isValid = nextFeed.isValid;
            currentFeed.value   = getNextBoundedPrice();
            nextFeed            = Feed(uint128(priceFeedValue), 1);
            lastUpdateTime      = latestUpdateTime(currentTime());
            // Emit event
            emit UpdateResult(uint(currentFeed.value), lastUpdateTime);
            // Pay the caller
            rewardCaller(msg.sender, callerReward);
        }
    }
}

contract ExternallyFundedDSM is DSM {
    // --- Variables ---
    // The wrapper for this DSM. It can relay treasury rewards
    FSMWrapperLike_1 public fsmWrapper;

    // --- Evemts ---
    event FailRenumerateCaller(address wrapper, address caller);

    constructor (address priceSource_, uint256 deviation) public DSM(priceSource_, deviation) {}

    // --- Administration ---
    /*
    * @notify Modify an address parameter
    * @param parameter The parameter name
    * @param val The new value for the parameter
    */
    function modifyParameters(bytes32 parameter, address val) external isAuthorized {
        if (parameter == "fsmWrapper") {
          require(val != address(0), "ExternallyFundedDSM/invalid-fsm-wrapper");
          fsmWrapper = FSMWrapperLike_1(val);
        }
        else revert("ExternallyFundedDSM/modify-unrecognized-param");
        emit ModifyParameters(parameter, val);
    }

    // --- Core Logic ---
    /*
    * @notify Update the price feeds inside the DSM
    */
    function updateResult() override external stoppable {
        // Check if the delay passed
        require(passedDelay(), "ExternallyFundedDSM/not-passed");
        // Check that the wrapper is set
        require(address(fsmWrapper) != address(0), "ExternallyFundedDSM/null-wrapper");
        // Read the price from the median
        (uint256 priceFeedValue, bool hasValidValue) = getPriceSourceUpdate();
        // If the value is valid, update storage
        if (hasValidValue) {
            // Update state
            currentFeed.isValid = nextFeed.isValid;
            currentFeed.value   = getNextBoundedPrice();
            nextFeed            = Feed(uint128(priceFeedValue), 1);
            lastUpdateTime      = latestUpdateTime(currentTime());
            // Emit event
            emit UpdateResult(uint(currentFeed.value), lastUpdateTime);
            // Pay the caller
            try fsmWrapper.renumerateCaller(msg.sender) {}
            catch(bytes memory revertReason) {
              emit FailRenumerateCaller(address(fsmWrapper), msg.sender);
            }
        }
    }
}

////// /nix/store/irf6p6ny7fdsxbc9i9p4bz4vzfbccq9b-geb-treasury-reimbursement/dapp/geb-treasury-reimbursement/src/reimbursement/NoSetupIncreasingTreasuryReimbursement.sol
/* pragma solidity 0.6.7; */

/* import "../math/GebMath.sol"; */

abstract contract StabilityFeeTreasuryLike_12 {
    function getAllowance(address) virtual external view returns (uint, uint);
    function systemCoin() virtual external view returns (address);
    function pullFunds(address, address, uint) virtual external;
}

contract NoSetupIncreasingTreasuryReimbursement is GebMath {
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
        require(authorizedAccounts[msg.sender] == 1, "NoSetupIncreasingTreasuryReimbursement/account-not-authorized");
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
    StabilityFeeTreasuryLike_12  public treasury;

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

    constructor() public {
        authorizedAccounts[msg.sender] = 1;
        maxRewardIncreaseDelay         = uint(-1);

        emit AddAuthorization(msg.sender);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
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

////// /nix/store/n9q4i4x8k6az7jv4dl3rkjmdw2kjdr20-geb-fsm/dapp/geb-fsm/src/FSMWrapper.sol
/* pragma solidity 0.6.7; */

/* import "geb-treasury-reimbursement/reimbursement/NoSetupIncreasingTreasuryReimbursement.sol"; */

abstract contract FSMLike {
    function stopped() virtual public view returns (uint256);
    function priceSource() virtual public view returns (address);
    function updateDelay() virtual public view returns (uint16);
    function lastUpdateTime() virtual public view returns (uint64);
    function newPriceDeviation() virtual public view returns (uint256);
    function passedDelay() virtual public view returns (bool);
    function getNextBoundedPrice() virtual public view returns (uint128);
    function getNextPriceLowerBound() virtual public view returns (uint128);
    function getNextPriceUpperBound() virtual public view returns (uint128);
    function getResultWithValidity() virtual external view returns (uint256, bool);
    function getNextResultWithValidity() virtual external view returns (uint256, bool);
    function read() virtual external view returns (uint256);
}

contract FSMWrapper is NoSetupIncreasingTreasuryReimbursement {
    // --- Vars ---
    // When the rate has last been relayed
    uint256 public lastReimburseTime;       // [timestamp]
    // Enforced gap between reimbursements
    uint256 public reimburseDelay;          // [seconds]

    FSMLike public fsm;

    constructor(address fsm_, uint256 reimburseDelay_) public NoSetupIncreasingTreasuryReimbursement() {
        require(fsm_ != address(0), "FSMWrapper/null-fsm");

        fsm            = FSMLike(fsm_);
        reimburseDelay = reimburseDelay_;

        emit ModifyParameters("reimburseDelay", reimburseDelay);
    }

    // --- Administration ---
    /*
    * @notice Change the addresses of contracts that this wrapper is connected to
    * @param parameter The contract whose address is changed
    * @param addr The new contract address
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "FSMWrapper/null-addr");
        if (parameter == "fsm") {
          fsm = FSMLike(addr);
        }
        else if (parameter == "treasury") {
          require(StabilityFeeTreasuryLike_12(addr).systemCoin() != address(0), "FSMWrapper/treasury-coin-not-set");
          treasury = StabilityFeeTreasuryLike_12(addr);
        }
        else revert("FSMWrapper/modify-unrecognized-param");
        emit ModifyParameters(
          parameter,
          addr
        );
    }
    /*
    * @notify Modify a uint256 parameter
    * @param parameter The parameter name
    * @param val The new parameter value
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        if (parameter == "baseUpdateCallerReward") {
          require(val <= maxUpdateCallerReward, "FSMWrapper/invalid-base-caller-reward");
          baseUpdateCallerReward = val;
        }
        else if (parameter == "maxUpdateCallerReward") {
          require(val >= baseUpdateCallerReward, "FSMWrapper/invalid-max-caller-reward");
          maxUpdateCallerReward = val;
        }
        else if (parameter == "perSecondCallerRewardIncrease") {
          require(val >= RAY, "FSMWrapper/invalid-caller-reward-increase");
          perSecondCallerRewardIncrease = val;
        }
        else if (parameter == "maxRewardIncreaseDelay") {
          require(val > 0, "FSMWrapper/invalid-max-increase-delay");
          maxRewardIncreaseDelay = val;
        }
        else if (parameter == "reimburseDelay") {
          reimburseDelay = val;
        }
        else revert("FSMWrapper/modify-unrecognized-param");
        emit ModifyParameters(
          parameter,
          val
        );
    }

    // --- Renumeration Logic ---
    /*
    * @notice Renumerate the caller that updates the connected FSM
    * @param feeReceiver The address that will receive the reward for the update
    */
    function renumerateCaller(address feeReceiver) external {
        // Perform checks
        require(address(fsm) == msg.sender, "FSMWrapper/invalid-caller");
        require(feeReceiver != address(0), "FSMWrapper/null-fee-receiver");
        // Check delay between calls
        require(either(subtract(now, lastReimburseTime) >= reimburseDelay, lastReimburseTime == 0), "FSMWrapper/wait-more");
        // Get the caller's reward
        uint256 callerReward = getCallerReward(lastReimburseTime, reimburseDelay);
        // Store the timestamp of the update
        lastReimburseTime = now;
        // Pay the caller for updating the FSM
        rewardCaller(feeReceiver, callerReward);
    }

    // --- Wrapped Functionality ---
    /*
    * @notify Return whether the FSM is stopped
    */
    function stopped() public view returns (uint256) {
        return fsm.stopped();
    }
    /*
    * @notify Return the FSM price source
    */
    function priceSource() public view returns (address) {
        return fsm.priceSource();
    }
    /*
    * @notify Return the FSM update delay
    */
    function updateDelay() public view returns (uint16) {
        return fsm.updateDelay();
    }
    /*
    * @notify Return the FSM last update time
    */
    function lastUpdateTime() public view returns (uint64) {
        return fsm.lastUpdateTime();
    }
    /*
    * @notify Return the FSM's next price deviation
    */
    function newPriceDeviation() public view returns (uint256) {
        return fsm.newPriceDeviation();
    }
    /*
    * @notify Return whether the update delay has been passed in the FSM
    */
    function passedDelay() public view returns (bool) {
        return fsm.passedDelay();
    }
    /*
    * @notify Return the next bounded price from the FSM
    */
    function getNextBoundedPrice() public view returns (uint128) {
        return fsm.getNextBoundedPrice();
    }
    /*
    * @notify Return the next lower bound price from the FSM
    */
    function getNextPriceLowerBound() public view returns (uint128) {
        return fsm.getNextPriceLowerBound();
    }
    /*
    * @notify Return the next upper bound price from the FSM
    */
    function getNextPriceUpperBound() public view returns (uint128) {
        return fsm.getNextPriceUpperBound();
    }
    /*
    * @notify Return the result with its validity from the FSM
    */
    function getResultWithValidity() external view returns (uint256, bool) {
        (uint256 price, bool valid) = fsm.getResultWithValidity();
        return (price, valid);
    }
    /*
    * @notify Return the next result with its validity from the FSM
    */
    function getNextResultWithValidity() external view returns (uint256, bool) {
        (uint256 price, bool valid) = fsm.getNextResultWithValidity();
        return (price, valid);
    }
    /*
    * @notify Return the result from the FSM if it's valid
    */
    function read() external view returns (uint256) {
        return fsm.read();
    }
}

////// /nix/store/9562cr0d7ld8jb3ba5jdn2xyk9cx9kxs-h2o-governance-actions/dapp/h2o-governance-actions/src/DeployDSMandWrapper.sol
/* pragma solidity 0.6.7; */

/* import {ExternallyFundedDSM} from "geb-fsm/DSM.sol"; */
/* import {FSMWrapper} from "geb-fsm/FSMWrapper.sol"; */

abstract contract LiquidationEngineLike_4 {
    function addAuthorization(address) external virtual;
}

abstract contract StabilityFeeTreasuryLike_3 {
    function setTotalAllowance(address, uint256) external virtual;
    function setPerBlockAllowance(address, uint256) external virtual;
}

abstract contract FsmGovernanceInterfaceLike_1 {
    function setFsm(bytes32, address) external virtual;
}

abstract contract OracleRelayerLike_3 {
    function modifyParameters(bytes32, bytes32, address) external virtual;
}

// @notice Proposal to deploy and setup new DSM and wrapper
// Missing steps:
// - Change orcl for the targeted collateral in the OracleRelayer
// - Change collateralFSM in the collateral's auction house
contract DeployDSMandWrapper {
    // --- Variables ---
    uint256 public constant RAY = 10**27;
    event DsmAndWrapperDeployed(address indexed dsm, address indexed wrapper);

    function execute(address _treasury, address ethMedianizer, address fsmGovernanceInterface, bytes32 collateralType, uint256 deviation) public returns (address) {
        // Define params
        StabilityFeeTreasuryLike_3 treasury     = StabilityFeeTreasuryLike_3(_treasury);
        uint256 reimburseDelay                = 3600;
        uint256 maxRewardIncreaseDelay        = 10800;
        uint256 baseUpdateCallerReward        = 0.0001 ether;
        uint256 maxUpdateCallerReward         = 0.0001 ether;
        uint256 perSecondCallerRewardIncrease = 1 * RAY;

        // deploy new DSM
        ExternallyFundedDSM dsm = new ExternallyFundedDSM(ethMedianizer, deviation);

        // deploy DSM Wrapper
        FSMWrapper dsmWrapper = new FSMWrapper(
            address(dsm),
            reimburseDelay
        );

        // set the wrapper on the DSM
        dsm.modifyParameters("fsmWrapper", address(dsmWrapper));

        FsmGovernanceInterfaceLike_1(fsmGovernanceInterface).setFsm(collateralType, address(dsmWrapper));

        // Setup treasury allowance
        treasury.setTotalAllowance(address(dsmWrapper), uint(-1));
        treasury.setPerBlockAllowance(address(dsmWrapper), 0.0001 ether * RAY);

        // Set the remaining params
        dsmWrapper.modifyParameters("treasury", address(treasury));
        dsmWrapper.modifyParameters("maxUpdateCallerReward", maxUpdateCallerReward);
        dsmWrapper.modifyParameters("baseUpdateCallerReward", baseUpdateCallerReward);
        dsmWrapper.modifyParameters("perSecondCallerRewardIncrease", perSecondCallerRewardIncrease);
        dsmWrapper.modifyParameters("maxRewardIncreaseDelay", maxRewardIncreaseDelay);

        emit DsmAndWrapperDeployed(address(dsm), address(dsmWrapper));
        return address(dsm);
    }
}