/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity 0.6.7;

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