/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: contracts/interfaces/chainlink/IAggregatorV3.sol

pragma solidity >=0.6 <0.7.0;


/**
 * @dev `AggregatorV3Interface` by Chainlink
 * @dev Source: https://docs.chain.link/docs/price-feeds-api-reference
 */
interface IAggregatorV3 {
    /*
     * @dev Get the number of decimals present in the response value
     */
    function decimals() external view returns (uint8);

    /*
     * @dev Get the description of the underlying aggregator that the proxy points to
     */
    function description() external view returns (string memory);

    /*
     * @dev Get the version representing the type of aggregator the proxy points to
     */
    function version() external view returns (uint256);

    /**
     * @dev Get data from a specific round
     * @notice It raises "No data present" if there is no data to report
     * @notice Consumers are encouraged to check they're receiving fresh data
     * by inspecting the updatedAt and answeredInRound return values.
     * @notice The round id is made up of the aggregator's round ID with the phase ID
     * in the two highest order bytes (it ensures round IDs get larger as time moves forward)
     * @param roundId The round ID
     * @return roundId The round ID
     * @return answer The price
     * @return startedAt Timestamp of when the round started
     * (Only some AggregatorV3Interface implementations return meaningful values)
     * @return updatedAt Timestamp of when the round was updated (computed)
     * @return answeredInRound The round ID of the round in which the answer was computed
     * (Only some AggregatorV3Interface implementations return meaningful values)
     */
    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    /**
     * @dev Get data from the last round
     * Should raise "No data present" if there is no data to report
     * @return roundId The round ID
     * @return answer The price
     * @return startedAt Timestamp of when the round started
     * @return updatedAt Timestamp of when the round was updated
     * @return answeredInRound The round ID of the round in which the answer was computed
     */
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

// File: contracts/mocks/MockPriceOracle.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6 <0.7.0;




interface IMockAggregatorV3 is IAggregatorV3 {

    /**
     * @return The address that may change updater
     */
    function getOwner() external view  returns (address);

    /**
     * @return The address that may update price data
     */
    function getUpdater() external view  returns (address);

    /**
     * @dev Change the updater
     * @param updater The address that may update price data
     */
    function changeUpdater(address updater) external;

    /**
     * @dev Set mock data
     * (Can only be called by the updater)
     * @param roundId The round ID
     * @param answer The price
     * @param updatedAt Timestamp of when the round was updated
     */
    function setRoundData(uint80 roundId, int256 answer, uint256 updatedAt) external;

    /**
     * @dev Initializes the contract
     * @notice It sets the caller address as the owner and the updater
     * @param version The version representing the type of aggregator the proxy points to
     * @param decimals The number of decimals present in the response value
     * @param description The description of the underlying aggregator that the proxy points to
     */
    function initialize(
        uint32 version,
        uint8 decimals,
        string memory description
    ) external;
}

/**
 * @dev Mock price feed oracle that simulates `AggregatorV3Interface` by Chainlink
 */
contract MockPriceOracle is Initializable, IMockAggregatorV3 {

    string private _description;
    uint32 private _version;
    uint8 private _decimals;

    address private _owner;
    address private _updater;
    uint80 internal _currentRound;

    // roundId => uint256(uint32 updatedAt; int128 answer)
    mapping(uint80 => uint256) internal _rounds;

    /// @inheritdoc IMockAggregatorV3
    function initialize(
        uint32 version,
        uint8 decimals,
        string memory description
    ) external override initializer
    {
        _owner = msg.sender;
        _updater = msg.sender;
        _version = version;
        _decimals = decimals;
        _description = description;
    }

    /// @inheritdoc IAggregatorV3
    function getRoundData(uint80 _roundId) public view virtual override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        roundId = _roundId;
        (answer, updatedAt) = unpackRound(_rounds[roundId]);
        answeredInRound = roundId;
        startedAt = updatedAt;
    }

    /// @inheritdoc IAggregatorV3
    function latestRoundData() public view virtual override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return getRoundData(_currentRound);
    }

    /// @inheritdoc IAggregatorV3
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /// @inheritdoc IAggregatorV3
    function version() external view override returns (uint256) {
        return _version;
    }

    /// @inheritdoc IAggregatorV3
    function description() external view override returns (string memory) {
        return _description;
    }

    /// @inheritdoc IMockAggregatorV3
    function getOwner() external view override returns (address) {
        return _owner;
    }

    /// @inheritdoc IMockAggregatorV3
    function getUpdater() external view override returns (address) {
        return _updater;
    }

    /// @inheritdoc IMockAggregatorV3
    function changeUpdater(address updater) external override {
        require(msg.sender == _owner, "MockPriceOracle: caller is not the owner");
        require(updater != address(0), "MockPriceOracle: invalid updater address");
        _updater = updater;
    }

    /// @inheritdoc IMockAggregatorV3
    function setRoundData(uint80 roundId, int256 answer, uint256 updatedAt) external
    override
    {
        require(msg.sender == _updater, "MockPriceOracle: caller is not the updater");
        require(
            (roundId != 0) && (roundId <= MAX_ROUND_ID),
            "MockPriceOracle: roundId out of range"
        );
        require((roundId >= _currentRound), "MockPriceOracle: roundId must be incremental");

        if (roundId != _currentRound) {
            _currentRound = roundId;
            _rounds[roundId] = packRound(answer, updatedAt);
        } else {
            (int256 oldAnswer, uint256 oldUpdatedAt) = unpackRound(_rounds[_currentRound]);
            require(oldAnswer == answer, "MockPriceOracle: mismatching answer");
            require(oldUpdatedAt == updatedAt, "MockPriceOracle: mismatching updatedAt");
        }
    }

    /*
     * private functions and constants
     */

    uint256 constant private OFFSET = 128;
    uint256 constant private MAX_ROUND_ID = 2**80 - 1;
    uint256 constant private MAX_UPDATED_AT = 2**32 - 1;
    uint256 constant private MAX_ANSWER = 2**128 - 1;

    // Pack `updatedAt` and `answer` into uint256 (uin64 _gap, uint32 updatedAt, int128 answer)
    function packRound(int256 answer, uint256 updatedAt) private pure returns (uint256) {
        require(
            updatedAt <= MAX_UPDATED_AT && updatedAt <= MAX_ANSWER,
            "MockPriceOracle: too big value(s)"
        );
        return (updatedAt << OFFSET) | uint256(answer);
    }

    // Unpack `updatedAt` and `answer` from uint256
    function unpackRound(uint256 round) private pure returns (int256 answer, uint256 updatedAt) {
        require(round > 0, "No data present");
        updatedAt = (uint256(round) >> OFFSET) & MAX_UPDATED_AT;
        answer = int256(round & MAX_ANSWER);
    }
}