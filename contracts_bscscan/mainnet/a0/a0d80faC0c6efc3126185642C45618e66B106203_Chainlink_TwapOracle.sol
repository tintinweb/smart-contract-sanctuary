/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

// SPDX-License-Identifier: MIT 
pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity >=0.6.10 <0.8.0;

interface ITwapOracle {
    function getTwap(uint256 timestamp) external view returns (uint256);
}


pragma solidity >=0.6.10 <0.8.0;



/// @title Time-weighted average price oracle
/// @notice This contract extends the Open Oracle standard by Compound, accepts price data
///         signed by two Reporters (a primary source and a secondary source) and computes
///         time-weighted average price (TWAP) in every 30-minute epoch.
/// @author Tranchess
contract TwapOracle is ITwapOracle, Ownable {
    uint256 private constant MESSAGE_INTERVAL = 1 minutes;
    uint256 private constant MESSAGE_BATCH_SIZE = 30; // not exceeding 32 for v's to fit in a word
    uint256 public constant EPOCH = MESSAGE_INTERVAL * MESSAGE_BATCH_SIZE;

    /// @dev Minimal number of messages in an epoch.
    uint256 private constant MIN_MESSAGE_COUNT = 15;
    uint256 private constant PUBLISHING_DELAY = 15 minutes;

    uint256 private constant SECONDARY_SOURCE_DELAY = EPOCH * 2;
    uint256 private constant OWNER_DELAY = EPOCH * 4;
    uint256 private constant PRICE_UNIT = 1e12;
    uint256 private constant PRICE_MASK = 0xffffffffffffffff;

    enum UpdateType {PRIMARY, SECONDARY, OWNER, CHAINLINK}

    event Update(uint256 timestamp, uint256 price, UpdateType updateType);

    address public immutable primarySource;
    address public immutable secondarySource;
    uint256 private immutable _startTimestamp;
    string public symbol;

    uint256 private _lastPrimaryMessageCount;
    uint256 private _lastSecondaryTimestamp;
    uint256 private _lastSecondaryMessageCount;

    /// @dev Mapping of epoch end timestamp => TWAP
    mapping(uint256 => uint256) internal _prices;

    /// @param primarySource_ Address of the primary data source
    /// @param secondarySource_ Address of the secondary data source
    /// @param symbol_ Asset symbol
    constructor(
        address primarySource_,
        address secondarySource_,
        string memory symbol_
    ) public {
        primarySource = primarySource_;
        secondarySource = secondarySource_;
        symbol = symbol_;
        _startTimestamp = block.timestamp;
    }

    /// @notice Return TWAP with 18 decimal places in the epoch ending at the specified timestamp.
    ///         Zero is returned if the epoch is not initialized yet or can still be updated
    ///         with more messages from the same source.
    /// @param timestamp End Timestamp in seconds of the epoch
    /// @return TWAP (18 decimal places) in the epoch, or zero if the epoch is not initialized yet
    ///         or can still be updated with more messages from the same source.
    function getTwap(uint256 timestamp) external view virtual override returns (uint256) {
        // Check whether the stored price can be updated in the future
        if (
            // Case 1: it can still be updated by more messages from the primary source
            timestamp > block.timestamp - PUBLISHING_DELAY ||
            // Case 2: it comes from the secondary source and can still be updated
            // by more messages from that source
            (timestamp <= block.timestamp - SECONDARY_SOURCE_DELAY &&
                timestamp > block.timestamp - SECONDARY_SOURCE_DELAY - PUBLISHING_DELAY &&
                timestamp == _lastSecondaryTimestamp)
        ) {
            return 0;
        } else {
            return _prices[timestamp];
        }
    }

    /// @notice Return minimum acceptable message count from the primary source
    ///         to update a given epoch.
    /// @param timestamp End timestamp in seconds of the epoch to update
    /// @return Minimum acceptable message count, or `MESSAGE_BATCH_SIZE + 1` if the epoch
    ///         cannot be updated now
    function minPrimaryMessageCountToUpdate(uint256 timestamp) external view returns (uint256) {
        if (_prices[timestamp] != 0) {
            if (timestamp > block.timestamp - PUBLISHING_DELAY) {
                return _lastPrimaryMessageCount + 1;
            } else {
                return MESSAGE_BATCH_SIZE + 1;
            }
        } else {
            return MIN_MESSAGE_COUNT;
        }
    }

    /// @notice Return minimum acceptable message count from the secondary source
    ///         to update a given epoch.
    /// @param timestamp End timestamp in seconds of the epoch to update
    /// @return Minimum acceptable message count, or `MESSAGE_BATCH_SIZE + 1` if the epoch
    ///         cannot be updated now
    function minSecondaryMessageCountToUpdate(uint256 timestamp) external view returns (uint256) {
        if (timestamp > block.timestamp - SECONDARY_SOURCE_DELAY || timestamp <= _startTimestamp) {
            return MESSAGE_BATCH_SIZE + 1;
        } else if (_prices[timestamp] != 0) {
            if (
                timestamp == _lastSecondaryTimestamp &&
                timestamp > block.timestamp - SECONDARY_SOURCE_DELAY - PUBLISHING_DELAY
            ) {
                return _lastSecondaryMessageCount + 1;
            } else {
                return MESSAGE_BATCH_SIZE + 1;
            }
        } else {
            return MIN_MESSAGE_COUNT;
        }
    }

    /// @notice Submit prices in a epoch that are signed by the primary source.
    /// @param timestamp End timestamp in seconds of the epoch
    /// @param priceList A list of prices (6 decimal places) in messages signed by the source,
    ///        with zero indicating a missing message
    /// @param rList A list of "r" values of signatures
    /// @param sList A list of "s" values of signatures
    /// @param packedV "v" values of signatures packed in a single word,
    ///        starting from the lowest byte
    function updateTwapFromPrimary(
        uint256 timestamp,
        uint256[MESSAGE_BATCH_SIZE] calldata priceList,
        bytes32[MESSAGE_BATCH_SIZE] calldata rList,
        bytes32[MESSAGE_BATCH_SIZE] calldata sList,
        uint256 packedV
    ) external {
        // Do not check (timestamp > _startTimestamp) for two reasons:
        // 1. the primary source is trusted;
        // 2. to save gas in most of the time.

        uint256 lastMessageCount = MIN_MESSAGE_COUNT - 1;
        if (_prices[timestamp] != 0) {
            require(
                timestamp > block.timestamp - PUBLISHING_DELAY,
                "Too late for the primary source to update an existing epoch"
            );
            lastMessageCount = _lastPrimaryMessageCount;
        }
        uint256 newMessageCount =
            _updateTwapFromSource(
                timestamp,
                lastMessageCount,
                priceList,
                rList,
                sList,
                packedV,
                primarySource,
                UpdateType.PRIMARY
            );
        if (timestamp > block.timestamp - PUBLISHING_DELAY) {
            _lastPrimaryMessageCount = newMessageCount;
        }
    }

    /// @notice Submit prices in a epoch that are signed by the secondary source.
    ///         This is allowed only after SECONDARY_SOURCE_DELAY has elapsed after the epoch.
    /// @param timestamp End timestamp in seconds of the epoch
    /// @param priceList A list of prices (6 decimal places) in messages signed by the source,
    ///        with zero indicating a missing message
    /// @param rList A list of "r" values of signatures
    /// @param sList A list of "s" values of signatures
    /// @param packedV "v" values of signatures packed in a single word,
    ///        starting from the lowest byte
    function updateTwapFromSecondary(
        uint256 timestamp,
        uint256[MESSAGE_BATCH_SIZE] calldata priceList,
        bytes32[MESSAGE_BATCH_SIZE] calldata rList,
        bytes32[MESSAGE_BATCH_SIZE] calldata sList,
        uint256 packedV
    ) external {
        require(
            timestamp <= block.timestamp - SECONDARY_SOURCE_DELAY,
            "Not ready for the secondary source"
        );
        require(
            timestamp > _startTimestamp,
            "The secondary source cannot update epoch before this contract is deployed"
        );
        uint256 lastMessageCount = MIN_MESSAGE_COUNT - 1;
        if (_prices[timestamp] != 0) {
            require(
                timestamp == _lastSecondaryTimestamp &&
                    timestamp > block.timestamp - SECONDARY_SOURCE_DELAY - PUBLISHING_DELAY,
                "Too late for the secondary source to update an existing epoch"
            );
            lastMessageCount = _lastSecondaryMessageCount;
        }
        uint256 newMessageCount =
            _updateTwapFromSource(
                timestamp,
                lastMessageCount,
                priceList,
                rList,
                sList,
                packedV,
                secondarySource,
                UpdateType.SECONDARY
            );
        if (timestamp > block.timestamp - SECONDARY_SOURCE_DELAY - PUBLISHING_DELAY) {
            _lastSecondaryTimestamp = timestamp;
            _lastSecondaryMessageCount = newMessageCount;
        }
    }

    /// @dev Verify signatures and update a epoch.
    /// @param timestamp End timestamp in seconds of the epoch
    /// @param lastMessageCount Message count in the last update to the epoch
    /// @param priceList A list of prices (6 decimal places) in messages signed by the source,
    ///        with zero indicating a missing message
    /// @param rList A list of "r" values of signatures
    /// @param sList A list of "s" values of signatures
    /// @param packedV "v" values of signatures packed in a single word,
    ///        starting from the lowest byte
    /// @param source Address of the data source that signs the messages
    /// @param updateType Type of this update, which will be included in an event
    /// @return messageCount Non-zero price count in `priceList`
    function _updateTwapFromSource(
        uint256 timestamp,
        uint256 lastMessageCount,
        uint256[MESSAGE_BATCH_SIZE] memory priceList,
        bytes32[MESSAGE_BATCH_SIZE] memory rList,
        bytes32[MESSAGE_BATCH_SIZE] memory sList,
        uint256 packedV,
        address source,
        UpdateType updateType
    ) private returns (uint256 messageCount) {
        require(timestamp % EPOCH == 0, "Unaligned timestamp");
        messageCount = 0;
        uint256 sum = 0;
        string memory _symbol = symbol; // gas saver
        uint256 t = timestamp - EPOCH;
        uint256 weight = 1;
        for (uint256 i = 0; i < MESSAGE_BATCH_SIZE; i++) {
            t += MESSAGE_INTERVAL;
            // Only prices fitting in 8 bytes (about 1.8e13 with 6 decimal places) are accepted,
            // which guarentees the following arithmetic operations never overflow.
            uint256 p = priceList[i] & PRICE_MASK;
            if (p == 0) {
                weight += 1;
                packedV >>= 8;
                continue;
            }
            // Build the original message and verify its signature. The computation is packed
            // in a single complex statement to save gas. Solidity generates unnecessary
            // initialization for each local variable, which wastes notable gas in this hot loop.
            require(
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            keccak256(
                                // Rebuild the message signed by the source
                                abi.encode("prices", t, _symbol, p)
                            )
                        )
                    ),
                    uint8(packedV), // the lowest byte of packedV
                    rList[i],
                    sList[i]
                ) == source,
                "Invalid signature"
            );
            sum += p * weight;
            weight = 1;
            messageCount += 1;
            packedV >>= 8;
        }
        require(messageCount > lastMessageCount, "More messages are required to update this epoch");
        if (weight > 1) {
            sum += (priceList[MESSAGE_BATCH_SIZE - weight] & PRICE_MASK) * (weight - 1);
        }
        uint256 average = (sum * PRICE_UNIT) / MESSAGE_BATCH_SIZE;
        _prices[t] = average;
        emit Update(t, average, updateType);
    }

    /// @notice Submit a TWAP with 18 decimal places by the owner.
    ///         This is allowed only when a epoch gets no update after OWNER_DELAY has elapsed.
    function updateTwapFromOwner(uint256 timestamp, uint256 price) external onlyOwner {
        require(timestamp % EPOCH == 0, "Unaligned timestamp");
        require(timestamp <= block.timestamp - OWNER_DELAY, "Not ready for owner");
        require(_prices[timestamp] == 0, "Owner cannot update an existing epoch");
        require(
            timestamp > _startTimestamp,
            "Owner cannot update epoch before this contract is deployed"
        );

        uint256 lastPrice = _prices[timestamp - EPOCH];
        require(lastPrice > 0, "Owner can only update a epoch following an updated epoch");
        require(
            price > lastPrice / 10 && price < lastPrice * 10,
            "Owner price deviates too much from the last price"
        );

        _prices[timestamp] = price;
        emit Update(timestamp, price, UpdateType.OWNER);
    }
}


pragma solidity >=0.6.10 <0.8.0;


interface IAggregatorV3Interface {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract Chainlink_TwapOracle is TwapOracle {
    IAggregatorV3Interface public _priceFeed;
    uint256 internal _decimals;

    /// @param primarySource_ Address of the primary data source
    /// @param secondarySource_ Address of the secondary data source
    /// @param symbol_ Asset symbol
    constructor(
        address primarySource_,
        address secondarySource_,
        address chainlinkSource_,
        string memory symbol_
    ) public TwapOracle(
        primarySource_,
        secondarySource_,
        symbol_
    ) {
        _priceFeed = IAggregatorV3Interface(chainlinkSource_);
        _decimals = uint256(_priceFeed.decimals());
    }

    function updateTwapFromChainlink() external {
        uint256 timestamp = block.timestamp - block.timestamp % EPOCH;
        updateTwapFromChainlink(timestamp);
    }

    function updateTwapFromChainlink(uint256 timestamp) public {
        require(msg.sender == primarySource ||
                msg.sender == secondarySource ||
                msg.sender == owner(), '!non of primary or secondary source');

        (
            uint80 roundID,
            int256 priceInt,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = _priceFeed.latestRoundData();

        uint256 price = uint256(priceInt) * (10 ** (18 - _decimals));
        _prices[timestamp] = price;
        emit Update(timestamp, price, UpdateType.CHAINLINK);
    }
}