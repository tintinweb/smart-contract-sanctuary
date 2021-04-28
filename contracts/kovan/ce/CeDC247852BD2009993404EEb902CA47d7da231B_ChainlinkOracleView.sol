pragma solidity >=0.5.16 <0.7.0;

import "./SafeMath.sol";

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/GSN/Context.sol
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
contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Source: https://github.com/smartcontractkit/chainlink/blob/develop/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract ChainlinkOracleView is Ownable {
    using SafeMath for uint256;

    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    address public ethUsdChainlinkAggregatorAddress;

    struct TokenConfig {
        address chainlinkAggregatorAddress;
        uint256 chainlinkPriceBase; // 0: Invalid, 1: USD, 2: ETH
        uint256 underlyingTokenDecimals;
    }

    mapping(address => TokenConfig) public tokenConfig;

    constructor(address ethUsdChainlinkAggregatorAddress_) public {
        ethUsdChainlinkAggregatorAddress = ethUsdChainlinkAggregatorAddress_;
    }

    /**
     * @notice Get the underlying price of a slToken
     * @dev Implements the PriceOracle interface for Compound v2.
     * @param slToken The slToken address for price retrieval
     * @return Price denominated in USD, with 18 decimals, for the given slToken address. Comptroller needs prices in the format: ${raw price} * 1e(36 - baseUnit)
     */
    function getUnderlyingPrice(address slToken) public view returns (uint256){
        TokenConfig memory config = tokenConfig[address(slToken)];

        (, int256 chainlinkPrice, , ,) = AggregatorV3Interface(config.chainlinkAggregatorAddress).latestRoundData();

        require(chainlinkPrice > 0, "Chainlink price feed invalid");

        uint256 underlyingPrice;

        if (config.chainlinkPriceBase == 1) {
            underlyingPrice = uint256(chainlinkPrice).mul(1e28).div(
                10 ** config.underlyingTokenDecimals
            );
        } else if (config.chainlinkPriceBase == 2) {
            (, int256 ethPriceInUsd, , ,) = AggregatorV3Interface(
                ethUsdChainlinkAggregatorAddress
            )
            .latestRoundData();

            require(ethPriceInUsd > 0, "ETH price invalid");

            underlyingPrice = uint256(chainlinkPrice)
            .mul(uint256(ethPriceInUsd))
            .mul(1e10)
            .div(10 ** config.underlyingTokenDecimals);
        } else {
            revert("Token config invalid");
        }

        require(underlyingPrice > 0, "Underlying price invalid");

        return underlyingPrice;
    }

    function setEthUsdChainlinkAggregatorAddress(address addr)
    external
    onlyOwner
    {
        ethUsdChainlinkAggregatorAddress = addr;
    }

    function setTokenConfigs(
        address[] calldata slTokenAddress,
        address[] calldata chainlinkAggregatorAddress,
        uint256[] calldata chainlinkPriceBase,
        uint256[] calldata underlyingTokenDecimals
    ) external onlyOwner {
        require(
            slTokenAddress.length == chainlinkAggregatorAddress.length &&
            slTokenAddress.length == chainlinkPriceBase.length &&
            slTokenAddress.length == underlyingTokenDecimals.length,
            "Arguments must have same length"
        );

        for (uint256 i = 0; i < slTokenAddress.length; i++) {
            tokenConfig[slTokenAddress[i]] = TokenConfig({
            chainlinkAggregatorAddress : chainlinkAggregatorAddress[i],
            chainlinkPriceBase : chainlinkPriceBase[i],
            underlyingTokenDecimals : underlyingTokenDecimals[i]
            });
            emit TokenConfigUpdated(
                slTokenAddress[i],
                chainlinkAggregatorAddress[i],
                chainlinkPriceBase[i],
                underlyingTokenDecimals[i]
            );
        }
    }

    event TokenConfigUpdated(
        address slTokenAddress,
        address chainlinkAggregatorAddress,
        uint256 chainlinkPriceBase,
        uint256 underlyingTokenDecimals
    );
}