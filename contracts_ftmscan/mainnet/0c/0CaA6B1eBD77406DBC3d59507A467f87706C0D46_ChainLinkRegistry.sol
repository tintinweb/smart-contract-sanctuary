/**
 *Submitted for verification at FtmScan.com on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

interface ChainlinkOracle is IERC20 {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function latestAnswer() external view returns (int256);
    function latestRound() external view returns (uint256);
    function lastestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
    function latestTimestamp() external view returns (uint256);
    function version() external view returns (uint256);
}

contract ChainLinkRegistry is Ownable {
    mapping(address => address) public feeds;

    event UpdateFeed(address indexed token, address indexed oldFeed, address indexed newFeed);

    /**
     * @dev Adds a new chainlink feed to the registry for the given token
     *
     * Requirements:
     *
     * - Must be contract owner
     */
    function addFeed(address token, address feed) public onlyOwner {
        require(IERC20(token).decimals() != 0, "token does not appear to be a valid ERC20");
        require(ChainlinkOracle(feed).version() != 0, "feed does not appear to be a chainlink feed");
        address old = feeds[token];
        feeds[token] = feed;
        emit UpdateFeed(token, old, feed);
    }

   /**
    * @notice represents the number of decimals the aggregator responses represent.
    */
    function decimals(address token) public view returns (uint8) {
        require(feeds[token] != address(0), "feed does not exist for token");
        return ChainlinkOracle(feeds[token]).decimals();
    }

   /**
    * @notice returns the description of the aggregator the proxy points to.
    */
    function description(address token) public view returns (string memory) {
        require(feeds[token] != address(0), "feed does not exist for token");
        return ChainlinkOracle(feeds[token]).description();
    }

   /**
    * @notice Reads the current answer from aggregator delegated to.
    *
    * @dev #[deprecated] Use latestRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended latestRoundData
    * instead which includes better verification information.
    */
    function latestAnswer(address token) public view returns (int256) {
        require(feeds[token] != address(0), "feed does not exist for token");
        return ChainlinkOracle(feeds[token]).latestAnswer();
    }

   /**
    * @notice get the latest completed round where the answer was updated
    * @dev overridden function to add the checkAccess() modifier
    *
    * @dev #[deprecated] Use latestRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended latestRoundData
    * instead which includes better verification information.
    */
    function latestRound(address token) public view returns (uint256) {
        require(feeds[token] != address(0), "feed does not exist for token");
        return ChainlinkOracle(feeds[token]).latestRound();
    }

   /**
    * @notice get data about the latest round. Consumers are encouraged to check
    * that they're receiving fresh data by inspecting the updatedAt and
    * answeredInRound return values.
    * Note that different underlying implementations of AggregatorV3Interface
    * have slightly different semantics for some of the return values. Consumers
    * should determine what implementations they expect to receive
    * data from and validate that they can properly handle return data from all
    * of them.
    * @return roundId is the round ID from the aggregator for which the data was
    * retrieved combined with a phase to ensure that round IDs get larger as
    * time moves forward.
    * @return answer is the answer for the given round
    * @return startedAt is the timestamp when the round was started.
    * (Only some AggregatorV3Interface implementations return meaningful values)
    * @return updatedAt is the timestamp when the round last was updated (i.e.
    * answer was last computed)
    * @return answeredInRound is the round ID of the round in which the answer
    * was computed.
    * (Only some AggregatorV3Interface implementations return meaningful values)
    * @dev Note that answer and updatedAt may change between queries.
    */
    function lastestRoundData(address token) public view returns (uint80, int256, uint256, uint256, uint80) {
        require(feeds[token] != address(0), "feed does not exist for token");
        return ChainlinkOracle(feeds[token]).lastestRoundData();
    }

   /**
    * @notice Reads the last updated height from aggregator delegated to.
    *
    * @dev #[deprecated] Use latestRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended latestRoundData
    * instead which includes better verification information.
    */
    function latestTimestamp(address token) public view returns (uint256) {
        require(feeds[token] != address(0), "feed does not exist for token");
        return ChainlinkOracle(feeds[token]).latestTimestamp();
    }

    /**
     * @dev Removes the chainlink feed for the given token from the registry
     *
     * Requirements:
     *
     * - Must be contract owner
     */
    function removeFeed(address token) public onlyOwner {
        require(IERC20(token).decimals() != 0, "token does not appear to be a valid ERC20");
        require(feeds[token] != address(0), "feed is not currently set");
        address old = feeds[token];
        delete feeds[token];
        emit UpdateFeed(token, old, address(0));
    }
}