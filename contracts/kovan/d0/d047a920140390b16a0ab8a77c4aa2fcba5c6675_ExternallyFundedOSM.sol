/**
 *Submitted for verification at Etherscan.io on 2021-04-04
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
    StabilityFeeTreasuryLike  public treasury;

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

abstract contract DSValueLike {
    function getResultWithValidity() virtual external view returns (uint256, bool);
}
abstract contract FSMWrapperLike {
    function renumerateCaller(address) virtual external;
}

contract OSM {
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
        require(authorizedAccounts[msg.sender] == 1, "OSM/account-not-authorized");
        _;
    }

    // --- Stop ---
    uint256 public stopped;
    modifier stoppable { require(stopped == 0, "OSM/is-stopped"); _; }

    // --- Variables ---
    address public priceSource;
    uint16  constant ONE_HOUR = uint16(3600);
    uint16  public updateDelay = ONE_HOUR;
    uint64  public lastUpdateTime;

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
    event ChangeDelay(uint16 delay);
    event RestartValue();
    event UpdateResult(uint256 newMedian, uint256 lastUpdateTime);

    constructor (address priceSource_) public {
        authorizedAccounts[msg.sender] = 1;
        priceSource = priceSource_;
        if (priceSource != address(0)) {
          (uint256 priceFeedValue, bool hasValidValue) = getPriceSourceUpdate();
          if (hasValidValue) {
            nextFeed = Feed(uint128(uint(priceFeedValue)), 1);
            currentFeed = nextFeed;
            lastUpdateTime = latestUpdateTime(currentTime());
            emit UpdateResult(uint(currentFeed.value), lastUpdateTime);
          }
        }
        emit AddAuthorization(msg.sender);
        emit ChangePriceSource(priceSource);
    }

    // --- Math ---
    function addition(uint64 x, uint64 y) internal pure returns (uint64 z) {
        z = x + y;
        require(z >= x);
    }

    // --- Core Logic ---
    /*
    * @notify Stop the OSM
    */
    function stop() external isAuthorized {
        stopped = 1;
        emit Stop();
    }
    /*
    * @notify Start the OSM
    */
    function start() external isAuthorized {
        stopped = 0;
        emit Start();
    }

    /*
    * @notify Change the oracle from which the OSM reads
    * @param priceSource_ The address of the oracle from which the OSM reads
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
        require(updateDelay != 0, "OSM/update-delay-is-zero");
        return uint64(timestamp - (timestamp % updateDelay));
    }

    /*
    * @notify Change the delay between updates
    * @param delay The new delay
    */
    function changeDelay(uint16 delay) external isAuthorized {
        require(delay > 0, "OSM/delay-is-zero");
        updateDelay = delay;
        emit ChangeDelay(updateDelay);
    }

    /*
    * @notify Restart/set to zero the feeds stored in the OSM
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
        return currentTime() >= uint(addition(lastUpdateTime, uint64(updateDelay)));
    }

    /*
    * @notify Update the price feeds inside the OSM
    */
    function updateResult() virtual external stoppable {
        // Check if the delay passed
        require(passedDelay(), "OSM/not-passed");
        // Read the price from the median
        (uint256 priceFeedValue, bool hasValidValue) = getPriceSourceUpdate();
        // If the value is valid, update storage
        if (hasValidValue) {
            // Update state
            currentFeed    = nextFeed;
            nextFeed       = Feed(uint128(uint(priceFeedValue)), 1);
            lastUpdateTime = latestUpdateTime(currentTime());
            // Emit event
            emit UpdateResult(uint(currentFeed.value), lastUpdateTime);
        }
    }

    // --- Getters ---
    /*
    * @notify Internal helper that reads a price and its validity from the priceSource
    */
    function getPriceSourceUpdate() internal view returns (uint256, bool) {
        try DSValueLike(priceSource).getResultWithValidity() returns (uint256 priceFeedValue, bool hasValidValue) {
          return (priceFeedValue, hasValidValue);
        }
        catch(bytes memory) {
          return (0, false);
        }
    }
    /*
    * @notify Return the current feed value and its validity
    */
    function getResultWithValidity() external view returns (uint256,bool) {
        return (uint(currentFeed.value), currentFeed.isValid == 1);
    }
    /*
    * @notify Return the next feed's value and its validity
    */
    function getNextResultWithValidity() external view returns (uint256,bool) {
        return (nextFeed.value, nextFeed.isValid == 1);
    }
    /*
    * @notify Return the current feed's value only if it's valid, otherwise revert
    */
    function read() external view returns (uint256) {
        require(currentFeed.isValid == 1, "OSM/no-current-value");
        return currentFeed.value;
    }
}

contract ExternallyFundedOSM is OSM {
    // --- Variables ---
    FSMWrapperLike public fsmWrapper;

    // --- Evemts ---
    event FailRenumerateCaller(address wrapper, address caller);

    constructor (address priceSource_) public OSM(priceSource_) {}

    // --- Administration ---
    /*
    * @notify Modify an address parameter
    * @param parameter The parameter name
    * @param val The new value for the parameter
    */
    function modifyParameters(bytes32 parameter, address val) external isAuthorized {
        if (parameter == "fsmWrapper") {
          require(val != address(0), "ExternallyFundedOSM/invalid-fsm-wrapper");
          fsmWrapper = FSMWrapperLike(val);
        }
        else revert("ExternallyFundedOSM/modify-unrecognized-param");
        emit ModifyParameters(parameter, val);
    }

    /*
    * @notify Update the price feeds inside the OSM
    */
    function updateResult() override external stoppable {
        // Check if the delay passed
        require(passedDelay(), "ExternallyFundedOSM/not-passed");
        // Check that the wrapper is set
        require(address(fsmWrapper) != address(0), "ExternallyFundedOSM/null-wrapper");
        // Read the price from the median
        (uint256 priceFeedValue, bool hasValidValue) = getPriceSourceUpdate();
        // If the value is valid, update storage
        if (hasValidValue) {
            // Update state
            currentFeed    = nextFeed;
            nextFeed       = Feed(uint128(uint(priceFeedValue)), 1);
            lastUpdateTime = latestUpdateTime(currentTime());
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