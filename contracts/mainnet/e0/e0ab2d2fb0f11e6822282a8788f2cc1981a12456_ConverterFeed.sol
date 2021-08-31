/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

pragma solidity 0.6.7;

abstract contract ConverterFeedLike {
    function getResultWithValidity() virtual external view returns (uint256,bool);
    function updateResult(address) virtual external;
}

contract ConverterFeed {
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
        require(authorizedAccounts[msg.sender] == 1, "ConverterFeed/account-not-authorized");
        _;
    }

    // --- General Vars ---
    // Base feed you want to convert into another currency. ie: (RAI/ETH)
    ConverterFeedLike public targetFeed;
    // Feed user for conversion. (i.e: Using the example above and ETH/USD willoutput RAI price in USD)
    ConverterFeedLike public denominationFeed;
    // This is the denominator for computing
    uint256           public converterFeedScalingFactor;
    // Manual flag that can be set by governance and indicates if a result is valid or not
    uint256           public validityFlag;

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
    event FailedUpdate(address feed, bytes out);

    constructor(
      address targetFeed_,
      address denominationFeed_,
      uint256 converterFeedScalingFactor_
    ) public {
        require(targetFeed_ != address(0), "ConverterFeed/null-target-feed");
        require(denominationFeed_ != address(0), "ConverterFeed/null-denomination-feed");
        require(converterFeedScalingFactor_ > 0, "ConverterFeed/null-scaling-factor");

        authorizedAccounts[msg.sender] = 1;

        targetFeed                    = ConverterFeedLike(targetFeed_);
        denominationFeed              = ConverterFeedLike(denominationFeed_);
        validityFlag                  = 1;
        converterFeedScalingFactor    = converterFeedScalingFactor_;

        // Emit events
        emit AddAuthorization(msg.sender);
        emit ModifyParameters(bytes32("validityFlag"), 1);
        emit ModifyParameters(bytes32("converterFeedScalingFactor"), converterFeedScalingFactor_);
        emit ModifyParameters(bytes32("targetFeed"), targetFeed_);
        emit ModifyParameters(bytes32("denominationFeed"), denominationFeed_);
    }

    // --- General Utils --
    function both(bool x, bool y) private pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Math ---
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Administration ---
    /**
    * @notice Modify uint256 parameters
    * @param parameter Name of the parameter to modify
    * @param data New parameter value
    **/
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "validityFlag") {
          require(either(data == 1, data == 0), "ConverterFeed/invalid-data");
          validityFlag = data;
        } else if (parameter == "scalingFactor") {
          require(data > 0, "ConverterFeed/invalid-data");
          converterFeedScalingFactor = data;
        }
        else revert("ConverterFeed/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
    * @notice Modify uint256 parameters
    * @param parameter Name of the parameter to modify
    * @param data New parameter value
    **/
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(data != address(0), "ConverterFeed/invalid-data");
        if (parameter == "targetFeed") {
          targetFeed = ConverterFeedLike(data);
        } else if (parameter == "denominationFeed") {
          denominationFeed = ConverterFeedLike(data);
        }
        else revert("ConverterFeed/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    /**
    * @notice Updates both feeds
    **/
    function updateResult(address feeReceiver) external {
        try targetFeed.updateResult(feeReceiver) {}
        catch (bytes memory out) {
          emit FailedUpdate(address(targetFeed), out);
        }
        try denominationFeed.updateResult(feeReceiver) {}
        catch (bytes memory out) {
          emit FailedUpdate(address(denominationFeed), out);
        }
    }

    // --- Getters ---
    /**
    * @notice Fetch the latest medianPrice (for maxWindow) or revert if is is null
    **/
    function read() external view returns (uint256) {
        (uint256 value, bool valid) = getResultWithValidity();
        require(valid, "ConverterFeed/invalid-price-feed");
        return value;
    }
    /**
    * @notice Fetch the latest medianPrice and whether it is null or not
    **/
    function getResultWithValidity() public view returns (uint256 value, bool valid) {
        (uint256 targetValue, bool targetValid) = targetFeed.getResultWithValidity();
        (uint256 denominationValue, bool denominationValid) = denominationFeed.getResultWithValidity();
        value = multiply(targetValue, denominationValue) / converterFeedScalingFactor;
        valid = both(
            both(targetValid, denominationValid),
            both(validityFlag == 1, value > 0)
        );
    }
}