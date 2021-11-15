// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./abstract/Ownable.sol";
import "./external/uniswap/IUniswapV2Pair.sol";
import "./external/chainlink/AggregatorV2V3Interface.sol";

contract Oracle is Ownable {
    IUniswapV2Pair private lp; // SNP/USDC
    AggregatorV2V3Interface private priceFeed; // USDC/USD

    constructor(address _lp, address _priceFeed) {
        lp = IUniswapV2Pair(_lp);
        priceFeed = AggregatorV2V3Interface(_priceFeed);
    }

    function decimals() public view returns (uint8) {
        return priceFeed.decimals();
    }

    /**
     * Returns the latest price
     */
    function getUSDCPrice() public view returns (uint256) {
        int256 price = priceFeed.latestAnswer();

        return uint256(price);
    }

    function getSNPPrice() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = lp.getReserves();

        return (((uint256(reserve1) * 1 ether) / uint256(reserve0)) * getUSDCPrice()) / 1 ether;
    }

    function getUsdValueFromSNP(uint256 amount) public view returns (uint256) {
        return (amount * getSNPPrice()) / 10**(18 + decimals() - 2);
    }

    function getLPPrice() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = lp.getReserves();

        uint256 snpValue = uint256(reserve0) * getSNPPrice();
        uint256 ethValue = uint256(reserve1) * getUSDCPrice();

        return (snpValue + ethValue) / lp.totalSupply();
    }

    function getUsdValueFromLp(uint256 amount) public view returns (uint256) {
        return (amount * getLPPrice()) / 10**(18 + decimals() - 2);
    }

    function setupLp(address _lp) external onlyOwner {
        lp = IUniswapV2Pair(_lp);
    }

    function setupPriceFeed(address _priceFeed) external onlyOwner {
        priceFeed = AggregatorV2V3Interface(_priceFeed);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

abstract contract OwnableData {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    function transferOwnership(address newOwner, bool direct) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0), "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

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

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

