/**
 *Submitted for verification at polygonscan.com on 2021-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () {
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

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);    
    function sync() external;
}

/**
 * @title Controllers
 * @dev admin only access restriction, extends OpenZeppelin Ownable.
 */
contract Controllers is Ownable{

    // Contract controllers
    address private _admin;

    event NewAdmin(address indexed oldAdmin, address indexed newAdmin);

    constructor() {
        address msgSender = _msgSender();
        _admin = msgSender;
        emit NewAdmin(address(0), msgSender);
    }

    /**
     * @dev modifier for admin only functions.
     */
    modifier onlyAdmin() {
        require(admin() == _msgSender(), "Controllers: admin only!");
        _;
    }

    /**
     * @dev modifier for owner or admin only functions.
     */
    modifier onlyControllers() {
        require((owner() == _msgSender()) || (admin() == _msgSender()), "Controllers: controller only!");
        _;
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Assigns new admin.
     * @param _newAdmin address of new admin
     */
    function setAdmin(address _newAdmin) external onlyOwner {
        // Check for non 0 address
        require(_newAdmin != address(0), "Controllers: admin can not be zero address!");
        emit NewAdmin(_admin, _newAdmin);
        _admin = _newAdmin;
    }
}

/**
 * @title PolyRebaseOracle
 * @dev inspired by uniswap ExampleOracleSimple.sol
 * Features admin control, pair reinitialization, sync and irreversible locking.
 */
contract RC_PolyRebaseOracle is Controllers {
    using FixedPoint for *;

    bool public initialized;
    bool public locked;
    
    struct PairConfig {
        IUniswapV2Pair uniV2;
        address token0;
        address token1;
    }
    PairConfig private _pair;

    struct PriceConfig {
        uint256 pc0Last;
        uint256 pc1Last;
        uint32  timestampLast;
        FixedPoint.uq112x112 p0Ave;
        FixedPoint.uq112x112 p1Ave;
        uint32 period;
    }
    PriceConfig private _price;

    event Initialized(address indexed pair, uint32 period);
    event Locked(uint256 blocknum, uint256 timestamp);

    constructor() {
        initialized = false;
        locked = false;
    }

    function initialize(address pair, uint32 period) external onlyAdmin {
        require(!locked, "Oracle: locked!");
        _pair.uniV2 = IUniswapV2Pair(pair);
        _pair.token0 = _pair.uniV2.token0();
        _pair.token1 = _pair.uniV2.token1();
        _price.pc0Last = _pair.uniV2.price0CumulativeLast();
        _price.pc1Last = _pair.uniV2.price1CumulativeLast();
        _price.p0Ave = FixedPoint.uq112x112(0);
        _price.p1Ave = FixedPoint.uq112x112(0);
        _price.period = period;
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, _price.timestampLast) = _pair.uniV2.getReserves();
        require(
            reserve0 != 0 && reserve1 != 0,
            'Oracle: no reserves!'
        );
        initialized = true;

        emit Initialized(pair, period);
    }

    function update() external onlyAdmin {
        require(initialized, "Oracle: uninitialized!");
        (uint256 pc0, uint256 pc1, uint32 timestamp) =
            _currentCumulativePrices(address(_pair.uniV2));
        uint32 timeElapsed = timestamp - _price.timestampLast;

        require(timeElapsed >= _price.period, 'Oracle: below minimum period!');

        _price.p0Ave = FixedPoint.uq112x112(uint224((pc0 - _price.pc0Last) / timeElapsed));
        _price.p1Ave = FixedPoint.uq112x112(uint224((pc1 - _price.pc1Last) / timeElapsed));

        _price.pc0Last = pc0;
        _price.pc1Last = pc1;
        _price.timestampLast = timestamp;
    }

    function quote(address token, uint amountIn) external view returns (uint amountOut) {
        require(initialized, "Oracle: uninitialized!");
        if (token == _pair.token0) {
            amountOut = _price.p0Ave.mul(amountIn).decode144();
        } else {
            require(token == _pair.token1, 'Oracle: invalid token');
            amountOut = _price.p1Ave.mul(amountIn).decode144();
        }
    }

    function lock() external onlyAdmin {
        require(initialized, "Oracle: uninitialized!");
        locked = true;

        emit Locked(block.number, block.timestamp);
    }

    function sync() external onlyAdmin {
        require(initialized, "Oracle: uninitialized!");
        _pair.uniV2.sync();
    }

    function _currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    function _currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = _currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}