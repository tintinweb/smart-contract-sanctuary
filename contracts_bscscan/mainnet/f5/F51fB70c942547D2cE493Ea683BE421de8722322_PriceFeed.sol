// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./abstract/Ownable.sol";
import "./external/uniswap/IUniswapV2Pair.sol";
import "./external/chainlink/AggregatorV2V3Interface.sol";

import "./interfaces/IERC20.sol";

contract PriceFeed is Ownable {
    IUniswapV2Pair private lp;
    AggregatorV2V3Interface private priceFeed;
    bool private tokenOrder;

    constructor(address _lp, address _priceFeed) {
        lp = IUniswapV2Pair(_lp);
        priceFeed = AggregatorV2V3Interface(_priceFeed);
        tokenOrder = false;
    }

    function decimals() public view returns (uint8) {
        return priceFeed.decimals();
    }

    function feedTokenPrice() public view returns (uint256) {
        int256 price = priceFeed.latestAnswer();

        return uint256(price);
    }

    function getMultipliers() internal view returns (uint8 multiplier0, uint8 multiplier1) {
        uint8 decimals0 = IERC20(lp.token0()).decimals();
        uint8 decimals1 = IERC20(lp.token1()).decimals();

        if (decimals0 > decimals1) {
            multiplier1 = decimals0 - decimals1;
        } else if (decimals0 < decimals1) {
            multiplier0 = decimals1 - decimals0;
        }
    }

    function tokenPrice() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = lp.getReserves();
        (uint112 reserveA, uint112 reserveB) = tokenOrder ? (reserve0, reserve1) : (reserve1, reserve0);
        (uint8 multiplier0, uint8 multiplier1) = getMultipliers();
        (uint8 multiplierA, uint8 multiplierB) = tokenOrder ? (multiplier0, multiplier1) : (multiplier1, multiplier0);

        return
            ((((uint256(reserveB) * 10**uint256(multiplierB) * 1 ether) / (uint256(reserveA) * 10**uint256(multiplierA))) * feedTokenPrice())) /
            1 ether;
    }

    function usdValueForToken(uint256 amount) public view returns (uint256) {
        return (amount * tokenPrice()) / 10**18;
    }

    function lpPrice() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = lp.getReserves();
        (uint112 reserveA, uint112 reserveB) = tokenOrder ? (reserve0, reserve1) : (reserve1, reserve0);

        uint256 snpValue = uint256(reserveA) * tokenPrice();
        uint256 usdcValue = uint256(reserveB) * feedTokenPrice();

        return (snpValue + usdcValue) / lp.totalSupply();
    }

    function usdValueForLp(uint256 amount) public view returns (uint256) {
        return (amount * lpPrice()) / 10**18;
    }

    function setupLp(address _lp) external onlyOwner {
        lp = IUniswapV2Pair(_lp);
    }

    function setupPriceFeed(address _priceFeed) external onlyOwner {
        priceFeed = AggregatorV2V3Interface(_priceFeed);
    }

    function setupTokenOrder(bool order) external onlyOwner {
        tokenOrder = order;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

abstract contract OwnableData {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev `owner` defaults to msg.sender on construction.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
     *      Can only be invoked by the current `owner`.
     * @param _newOwner Address of the new owner.
     * @param _direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
     */
    function transferOwnership(address _newOwner, bool _direct) external onlyOwner {
        if (_direct) {
            require(_newOwner != address(0), "zero address");

            emit OwnershipTransferred(owner, _newOwner);
            owner = _newOwner;
            pendingOwner = address(0);
        } else {
            pendingOwner = _newOwner;
        }
    }

    /**
     * @dev Needs to be called by `pendingOwner` to claim ownership.
     */
    function claimOwnership() external {
        address _pendingOwner = pendingOwner;
        require(msg.sender == _pendingOwner, "caller != pending owner");

        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /**
     * @dev Throws if called by any account other than the Owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: GPL-3.0

/* solhint-disable func-name-mixedcase */
pragma solidity 0.8.6;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    // EIP 2612
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function transferWithPermit(address target, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
}

