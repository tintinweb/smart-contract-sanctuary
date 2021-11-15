// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./interfaces/IDMMFactory.sol";
import "./DMMPool.sol";
import "./ManageUser.sol";

contract DMMFactory is IDMMFactory, ManageUser {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 internal constant BPS = 10000;

    address private feeTo;
    uint16 private governmentFeeBps;
    address public override feeToSetter;

    mapping(IERC20 => mapping(IERC20 => EnumerableSet.AddressSet)) internal tokenPools;
    mapping(IERC20 => mapping(IERC20 => address)) public override getUnamplifiedPool;
    address[] public override allPools;

    event PoolCreated(
        IERC20 indexed token0,
        IERC20 indexed token1,
        address pool,
        uint32 ampBps,
        uint256 totalPool
    );
    event SetFeeConfiguration(address feeTo, uint16 governmentFeeBps);
    event SetFeeToSetter(address feeToSetter);

    constructor(address _feeToSetter, address _manage) public ManageUser(_manage) {
        feeToSetter = _feeToSetter;
    }

    function createPool(
        IERC20 tokenA,
        IERC20 tokenB,
        uint32 ampBps
    ) external override _admin returns (address pool) {
        require(tokenA != tokenB, "DMM: IDENTICAL_ADDRESSES");
        (IERC20 token0, IERC20 token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(address(token0) != address(0), "DMM: ZERO_ADDRESS");
        require(ampBps >= BPS, "DMM: INVALID_BPS");
        // only exist 1 unamplified pool of a pool.
        require(
            ampBps != BPS || getUnamplifiedPool[token0][token1] == address(0),
            "DMM: UNAMPLIFIED_POOL_EXISTS"
        );
        pool = address(new DMMPool());
        DMMPool(pool).initialize(token0, token1, ampBps);
        // populate mapping in the reverse direction
        tokenPools[token0][token1].add(pool);
        tokenPools[token1][token0].add(pool);
        if (ampBps == BPS) {
            getUnamplifiedPool[token0][token1] = pool;
            getUnamplifiedPool[token1][token0] = pool;
        }
        allPools.push(pool);

        emit PoolCreated(token0, token1, pool, ampBps, allPools.length);
    }

    function setFeeConfiguration(address _feeTo, uint16 _governmentFeeBps) external override {
        require(msg.sender == feeToSetter, "DMM: FORBIDDEN");
        require(_governmentFeeBps > 0 && _governmentFeeBps < 2000, "DMM: INVALID FEE");
        feeTo = _feeTo;
        governmentFeeBps = _governmentFeeBps;

        emit SetFeeConfiguration(_feeTo, _governmentFeeBps);
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "DMM: FORBIDDEN");
        feeToSetter = _feeToSetter;

        emit SetFeeToSetter(_feeToSetter);
    }

    function getFeeConfiguration()
        external
        override
        view
        returns (address _feeTo, uint16 _governmentFeeBps)
    {
        _feeTo = feeTo;
        _governmentFeeBps = governmentFeeBps;
    }

    function allPoolsLength() external override view returns (uint256) {
        return allPools.length;
    }

    function getPools(IERC20 token0, IERC20 token1)
        external
        override
        view
        returns (address[] memory _tokenPools)
    {
        uint256 length = tokenPools[token0][token1].length();
        _tokenPools = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            _tokenPools[i] = tokenPools[token0][token1].at(i);
        }
    }

    function getPoolsLength(IERC20 token0, IERC20 token1) external view returns (uint256) {
        return tokenPools[token0][token1].length();
    }

    function getPoolAtIndex(
        IERC20 token0,
        IERC20 token1,
        uint256 index
    ) external view returns (address pool) {
        return tokenPools[token0][token1].at(index);
    }

    function isPool(
        IERC20 token0,
        IERC20 token1,
        address pool
    ) external override view returns (bool) {
        return tokenPools[token0][token1].contains(pool);
    }

    function changeRatio(
        address pool,
        uint32 newRatio
    ) public _admin {
        DMMPool(pool).changeRatioFee(newRatio);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDMMFactory {
    function createPool(
        IERC20 tokenA,
        IERC20 tokenB,
        uint32 ampBps
    ) external returns (address pool);

    function setFeeConfiguration(address feeTo, uint16 governmentFeeBps) external;

    function setFeeToSetter(address) external;

    function getFeeConfiguration() external view returns (address feeTo, uint16 governmentFeeBps);

    function feeToSetter() external view returns (address);

    function allPools(uint256) external view returns (address pool);

    function allPoolsLength() external view returns (uint256);

    function getUnamplifiedPool(IERC20 token0, IERC20 token1) external view returns (address);

    function getPools(IERC20 token0, IERC20 token1)
        external
        view
        returns (address[] memory _tokenPools);

    function isPool(
        IERC20 token0,
        IERC20 token1,
        address pool
    ) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./libraries/MathExt.sol";
import "./libraries/FeeFomula.sol";
import "./libraries/ERC20Permit.sol";

import "./interfaces/IDMMFactory.sol";
import "./interfaces/IDMMCallee.sol";
import "./interfaces/IDMMPool.sol";
import "./VolumeTrendRecorder.sol";

contract DMMPool is IDMMPool, ERC20Permit, ReentrancyGuard, VolumeTrendRecorder {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant MAX_UINT112 = 2**112 - 1;
    uint256 internal constant BPS = 10000;

    struct ReserveData {
        uint256 reserve0;
        uint256 reserve1;
        uint256 vReserve0;
        uint256 vReserve1; // only used when isAmpPool = true
    }

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    /// @dev To make etherscan auto-verify new pool, these variables are not immutable
    IDMMFactory public override factory;
    IERC20 public override token0;
    IERC20 public override token1;

    /// @dev uses single storage slot, accessible via getReservesData
    uint112 internal reserve0;
    uint112 internal reserve1;
    uint32 public override ampBps;
    uint32 public ratioFee = 2000;
    /// @dev addition param only when amplification factor > 1
    uint112 internal vReserve0;
    uint112 internal vReserve1;

    /// @dev vReserve0 * vReserve1, as of immediately after the most recent liquidity event
    uint256 public override kLast;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to,
        uint256 feeInPrecision
    );
    event Sync(uint256 vReserve0, uint256 vReserve1, uint256 reserve0, uint256 reserve1);

    constructor() public ERC20Permit("KyberDMM LP", "DMM-LP", "1") VolumeTrendRecorder(0) {
        factory = IDMMFactory(msg.sender);
    }

    // called once by the factory at time of deployment
    function initialize(
        IERC20 _token0,
        IERC20 _token1,
        uint32 _ampBps
    ) external {
        require(msg.sender == address(factory), "DMM: FORBIDDEN");
        token0 = _token0;
        token1 = _token1;
        ampBps = _ampBps;
    }

    /// @dev this low-level function should be called from a contract
    ///                 which performs important safety checks
    function mint(address to) external override nonReentrant returns (uint256 liquidity) {
        (bool isAmpPool, ReserveData memory data) = getReservesData();
        ReserveData memory _data;
        _data.reserve0 = token0.balanceOf(address(this));
        _data.reserve1 = token1.balanceOf(address(this));
        uint256 amount0 = _data.reserve0.sub(data.reserve0);
        uint256 amount1 = _data.reserve1.sub(data.reserve1);

        bool feeOn = _mintFee(isAmpPool, data);
        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            if (isAmpPool) {
                uint32 _ampBps = ampBps;
                _data.vReserve0 = _data.reserve0.mul(_ampBps) / BPS;
                _data.vReserve1 = _data.reserve1.mul(_ampBps) / BPS;
            }
            liquidity = MathExt.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(-1), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                amount0.mul(_totalSupply) / data.reserve0,
                amount1.mul(_totalSupply) / data.reserve1
            );
            if (isAmpPool) {
                uint256 b = liquidity.add(_totalSupply);
                _data.vReserve0 = Math.max(data.vReserve0.mul(b) / _totalSupply, _data.reserve0);
                _data.vReserve1 = Math.max(data.vReserve1.mul(b) / _totalSupply, _data.reserve1);
            }
        }
        require(liquidity > 0, "DMM: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(isAmpPool, _data);
        if (feeOn) kLast = getK(isAmpPool, _data);
        emit Mint(msg.sender, amount0, amount1);
    }

    /// @dev this low-level function should be called from a contract
    /// @dev which performs important safety checks
    /// @dev user must transfer LP token to this contract before call burn
    function burn(address to)
        external
        override
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        (bool isAmpPool, ReserveData memory data) = getReservesData(); // gas savings
        IERC20 _token0 = token0; // gas savings
        IERC20 _token1 = token1; // gas savings

        uint256 balance0 = _token0.balanceOf(address(this));
        uint256 balance1 = _token1.balanceOf(address(this));
        require(balance0 >= data.reserve0 && balance1 >= data.reserve1, "DMM: UNSYNC_RESERVES");
        uint256 liquidity = balanceOf(address(this));

        bool feeOn = _mintFee(isAmpPool, data);
        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "DMM: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _token0.safeTransfer(to, amount0);
        _token1.safeTransfer(to, amount1);
        ReserveData memory _data;
        _data.reserve0 = _token0.balanceOf(address(this));
        _data.reserve1 = _token1.balanceOf(address(this));
        if (isAmpPool) {
            uint256 b = Math.min(
                _data.reserve0.mul(_totalSupply) / data.reserve0,
                _data.reserve1.mul(_totalSupply) / data.reserve1
            );
            _data.vReserve0 = Math.max(data.vReserve0.mul(b) / _totalSupply, _data.reserve0);
            _data.vReserve1 = Math.max(data.vReserve1.mul(b) / _totalSupply, _data.reserve1);
        }
        _update(isAmpPool, _data);
        if (feeOn) kLast = getK(isAmpPool, _data); // data are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    /// @dev this low-level function should be called from a contract
    /// @dev which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata callbackData
    ) external override nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, "DMM: INSUFFICIENT_OUTPUT_AMOUNT");
        (bool isAmpPool, ReserveData memory data) = getReservesData(); // gas savings
        require(
            amount0Out < data.reserve0 && amount1Out < data.reserve1,
            "DMM: INSUFFICIENT_LIQUIDITY"
        );

        ReserveData memory newData;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            IERC20 _token0 = token0;
            IERC20 _token1 = token1;
            require(to != address(_token0) && to != address(_token1), "DMM: INVALID_TO");
            if (amount0Out > 0) _token0.safeTransfer(to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _token1.safeTransfer(to, amount1Out); // optimistically transfer tokens
            if (callbackData.length > 0)
                IDMMCallee(to).dmmSwapCall(msg.sender, amount0Out, amount1Out, callbackData);
            newData.reserve0 = _token0.balanceOf(address(this));
            newData.reserve1 = _token1.balanceOf(address(this));
            if (isAmpPool) {
                newData.vReserve0 = data.vReserve0.add(newData.reserve0).sub(data.reserve0);
                newData.vReserve1 = data.vReserve1.add(newData.reserve1).sub(data.reserve1);
            }
        }
        uint256 amount0In = newData.reserve0 > data.reserve0 - amount0Out
            ? newData.reserve0 - (data.reserve0 - amount0Out)
            : 0;
        uint256 amount1In = newData.reserve1 > data.reserve1 - amount1Out
            ? newData.reserve1 - (data.reserve1 - amount1Out)
            : 0;
        require(amount0In > 0 || amount1In > 0, "DMM: INSUFFICIENT_INPUT_AMOUNT");
        uint256 feeInPrecision = verifyBalanceAndUpdateEma(
            amount0In,
            amount1In,
            isAmpPool ? data.vReserve0 : data.reserve0,
            isAmpPool ? data.vReserve1 : data.reserve1,
            isAmpPool ? newData.vReserve0 : newData.reserve0,
            isAmpPool ? newData.vReserve1 : newData.reserve1
        );
        _update(isAmpPool, newData);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to, feeInPrecision);
        {
            IERC20 tokenFee;
            if (amount0In > 0) {
                tokenFee = token0;
            } else {
                tokenFee = token1;
            }
            sendFeeToFactory(feeInPrecision, tokenFee);
        }
    }

    /// @dev force balances to match reserves
    function skim(address to) external nonReentrant {
        token0.safeTransfer(to, token0.balanceOf(address(this)).sub(reserve0));
        token1.safeTransfer(to, token1.balanceOf(address(this)).sub(reserve1));
    }

    /// @dev force reserves to match balances
    function sync() external override nonReentrant {
        _sync();
    }

    function _sync() private {
        (bool isAmpPool, ReserveData memory data) = getReservesData();
        bool feeOn = _mintFee(isAmpPool, data);
        ReserveData memory newData;
        newData.reserve0 = IERC20(token0).balanceOf(address(this));
        newData.reserve1 = IERC20(token1).balanceOf(address(this));
        // update virtual reserves if this is amp pool
        if (isAmpPool) {
            uint256 _totalSupply = totalSupply();
            uint256 b = Math.min(
                newData.reserve0.mul(_totalSupply) / data.reserve0,
                newData.reserve1.mul(_totalSupply) / data.reserve1
            );
            newData.vReserve0 = Math.max(data.vReserve0.mul(b) / _totalSupply, newData.reserve0);
            newData.vReserve1 = Math.max(data.vReserve1.mul(b) / _totalSupply, newData.reserve1);
        }
        _update(isAmpPool, newData);
        if (feeOn) kLast = getK(isAmpPool, newData);
    }   

    /// @dev returns data to calculate amountIn, amountOut
    function getTradeInfo()
        external
        virtual
        override
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint112 _vReserve0,
            uint112 _vReserve1,
            uint256 feeInPrecision
        )
    {
        // gas saving to read reserve data
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        uint32 _ampBps = ampBps;
        _vReserve0 = vReserve0;
        _vReserve1 = vReserve1;
        if (_ampBps == BPS) {
            _vReserve0 = _reserve0;
            _vReserve1 = _reserve1;
        }
        uint256 rFactorInPrecision = getRFactor(block.number);
        feeInPrecision = FeeFomula.getFeeSwap(rFactorInPrecision, _ampBps);
    }

    /// @dev returns reserve data to calculate amount to add liquidity
    function getReserves() external override view returns (uint112 _reserve0, uint112 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function name() public override view returns (string memory) {
        return FeeFomula.name(address(token0), address(token1));
    }

    function symbol() public override view returns (string memory) {
        return FeeFomula.symbol(address(token0), address(token1));
    }

    function verifyBalanceAndUpdateEma(
        uint256 amount0In,
        uint256 amount1In,
        uint256 beforeReserve0,
        uint256 beforeReserve1,
        uint256 afterReserve0,
        uint256 afterReserve1
    ) internal virtual returns (uint256 feeInPrecision) {
        // volume = beforeReserve0 * amount1In / beforeReserve1 + amount0In (normalized into amount in token 0)
        uint256 volume = beforeReserve0.mul(amount1In).div(beforeReserve1).add(amount0In);
        uint256 rFactorInPrecision = recordNewUpdatedVolume(block.number, volume);
        feeInPrecision = FeeFomula.getFeeSwap(rFactorInPrecision, ampBps);
        // verify balance update matches with fomula
        uint256 balance0Adjusted = afterReserve0.mul(PRECISION);
        balance0Adjusted = balance0Adjusted.sub(amount0In.mul(feeInPrecision));
        balance0Adjusted = balance0Adjusted / PRECISION;
        uint256 balance1Adjusted = afterReserve1.mul(PRECISION);
        balance1Adjusted = balance1Adjusted.sub(amount1In.mul(feeInPrecision));
        balance1Adjusted = balance1Adjusted / PRECISION;
        require(
            balance0Adjusted.mul(balance1Adjusted) >= beforeReserve0.mul(beforeReserve1),
            "DMM: K"
        );
    }

    /// @dev update reserves
    function _update(bool isAmpPool, ReserveData memory data) internal {
        reserve0 = safeUint112(data.reserve0);
        reserve1 = safeUint112(data.reserve1);
        if (isAmpPool) {
            assert(data.vReserve0 >= data.reserve0 && data.vReserve1 >= data.reserve1); // never happen
            vReserve0 = safeUint112(data.vReserve0);
            vReserve1 = safeUint112(data.vReserve1);
        }
        emit Sync(data.vReserve0, data.vReserve1, data.reserve0, data.reserve1);
    }

    /// @dev if fee is on, mint liquidity equivalent to configured fee of the growth in sqrt(k)
    function _mintFee(bool isAmpPool, ReserveData memory data) internal returns (bool feeOn) {
        (address feeTo, uint16 governmentFeeBps) = factory.getFeeConfiguration();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = MathExt.sqrt(getK(isAmpPool, data));
                uint256 rootKLast = MathExt.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply().mul(rootK.sub(rootKLast)).mul(
                        governmentFeeBps
                    );
                    uint256 denominator = rootK.add(rootKLast).mul(5000);
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    /// @dev gas saving to read reserve data
    function getReservesData() internal view returns (bool isAmpPool, ReserveData memory data) {
        data.reserve0 = reserve0;
        data.reserve1 = reserve1;
        isAmpPool = ampBps != BPS;
        if (isAmpPool) {
            data.vReserve0 = vReserve0;
            data.vReserve1 = vReserve1;
        }
    }

    function getK(bool isAmpPool, ReserveData memory data) internal pure returns (uint256) {
        return isAmpPool ? data.vReserve0 * data.vReserve1 : data.reserve0 * data.reserve1;
    }

    function safeUint112(uint256 x) internal pure returns (uint112) {
        require(x <= MAX_UINT112, "DMM: OVERFLOW");
        return uint112(x);
    }

    function changeRatioFee(uint32 newRatio) public {
        require(msg.sender == address(factory), "DMM: FORBIDDEN");
        require(newRatio <= 10000 && newRatio >= 0, "RATIO FEE: NOT VALID");
        ratioFee = newRatio;
    }

    function getRatioFee() public view returns (uint32) {
        return ratioFee;
    }

    function feeForFactory(uint256 _feeInPrecision) private view returns (uint256) {
        uint256 feeForFactory = _feeInPrecision.mul(ratioFee).div(BPS);
        return feeForFactory;
    }

    function sendFeeToFactory(uint256 _feeInPrecision, IERC20 token) private {
        uint256 feeForFactory = feeForFactory(_feeInPrecision);
        address _to = address(factory);
        token.safeTransfer(_to, feeForFactory);
        _sync();
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

interface IManageAddress {
    function getRole(address user) external view returns (bytes32);
}

contract ManageUser {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant NORMAL = keccak256("NORMAL");
    IManageAddress public manage;

    constructor(address manageAddress) public {
        manage = IManageAddress(manageAddress);
    }

    function getRoleUser(address user) public view returns (bytes32) {
        return manage.getRole(user);
    }

    modifier _superAdmin() {
        require(getRoleUser(msg.sender) == SUPER_ADMIN_ROLE, "NO PERMISSION");
        _;
    }

    modifier _admin() {
        require(getRoleUser(msg.sender) == ADMIN_ROLE || getRoleUser(msg.sender) == SUPER_ADMIN_ROLE, "NO PERMISSION");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

library MathExt {
    using SafeMath for uint256;

    uint256 public constant PRECISION = (10**18);

    /// @dev Returns x*y in precision
    function mulInPrecision(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(y) / PRECISION;
    }

    /// @dev source: dsMath
    /// @param xInPrecision should be < PRECISION, so this can not overflow
    /// @return zInPrecision = (x/PRECISION) ^k * PRECISION
    function unsafePowInPrecision(uint256 xInPrecision, uint256 k)
        internal
        pure
        returns (uint256 zInPrecision)
    {
        require(xInPrecision <= PRECISION, "MathExt: x > PRECISION");
        zInPrecision = k % 2 != 0 ? xInPrecision : PRECISION;

        for (k /= 2; k != 0; k /= 2) {
            xInPrecision = (xInPrecision * xInPrecision) / PRECISION;

            if (k % 2 != 0) {
                zInPrecision = (zInPrecision * xInPrecision) / PRECISION;
            }
        }
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "./MathExt.sol";
import "../interfaces/IERC20Metadata.sol";

library FeeFomula {
    using SafeMath for uint256;
    using MathExt for uint256;

    uint256 private constant PRECISION = 10**18;
    uint256 private constant R0 = 1477405064814996100; // 1.4774050648149961

    uint256 private constant C0 = (60 * PRECISION) / 10000;

    uint256 private constant A = uint256(PRECISION * 20000) / 27;
    uint256 private constant B = uint256(PRECISION * 250) / 9;
    uint256 private constant C1 = uint256(PRECISION * 985) / 27;
    uint256 private constant U = (120 * PRECISION) / 100;

    uint256 private constant G = (836 * PRECISION) / 1000;
    uint256 private constant F = 5 * PRECISION;
    uint256 private constant L = (2 * PRECISION) / 10000;
    // C2 = 25 * PRECISION - (F * (PRECISION - G)**2) / ((PRECISION - G)**2 + L * PRECISION)
    uint256 private constant C2 = 20036905816356657810;

    /// @dev calculate fee from rFactorInPrecision, see section 3.2 in dmmSwap white paper
    /// @dev fee in [15, 60] bps
    /// @return fee percentage in Precision
    function getFee(uint256 rFactorInPrecision) internal pure returns (uint256) {
        if (rFactorInPrecision >= R0) {
            return C0;
        } else if (rFactorInPrecision >= PRECISION) {
            // C1 + A * (r-U)^3 + b * (r -U)
            if (rFactorInPrecision > U) {
                uint256 tmp = rFactorInPrecision - U;
                uint256 tmp3 = tmp.unsafePowInPrecision(3);
                return (C1.add(A.mulInPrecision(tmp3)).add(B.mulInPrecision(tmp))) / 10000;
            } else {
                uint256 tmp = U - rFactorInPrecision;
                uint256 tmp3 = tmp.unsafePowInPrecision(3);
                return C1.sub(A.mulInPrecision(tmp3)).sub(B.mulInPrecision(tmp)) / 10000;
            }
        } else {
            // [ C2 + sign(r - G) *  F * (r-G) ^2 / (L + (r-G) ^2) ] / 10000
            uint256 tmp = (
                rFactorInPrecision > G ? (rFactorInPrecision - G) : (G - rFactorInPrecision)
            );
            tmp = tmp.unsafePowInPrecision(2);
            uint256 tmp2 = F.mul(tmp).div(tmp.add(L));
            if (rFactorInPrecision > G) {
                return C2.add(tmp2) / 10000;
            } else {
                return C2.sub(tmp2) / 10000;
            }
        }
    }

    function getFinalFee(uint256 feeInPrecision, uint32 _ampBps) internal pure returns (uint256) {
        if (_ampBps <= 20000) {
            return feeInPrecision;
        } else if (_ampBps <= 50000) {
            return (feeInPrecision * 20) / 30;
        } else if (_ampBps <= 200000) {
            return (feeInPrecision * 10) / 30;
        } else {
            return (feeInPrecision * 4) / 30;
        }
    }

    function getFeeSwap(uint256 rFactorInPrecision, uint32 _ampBps) internal pure returns (uint256) {
        return getFinalFee(getFee(rFactorInPrecision), _ampBps);
    }

    function name(address token0, address token1) public view returns (string memory) {
        IERC20Metadata _token0 = IERC20Metadata(token0);
        IERC20Metadata _token1 = IERC20Metadata(token1);
        return string(abi.encodePacked("KyberDMM LP ", _token0.symbol(), "-", _token1.symbol()));
    }

    function symbol(address token0, address token1) public view returns (string memory) {
        IERC20Metadata _token0 = IERC20Metadata(token0);
        IERC20Metadata _token1 = IERC20Metadata(token1);
        return string(abi.encodePacked("DMM-LP ", _token0.symbol(), "-", _token1.symbol()));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IERC20Permit.sol";

/// @dev https://eips.ethereum.org/EIPS/eip-2612
contract ERC20Permit is ERC20, IERC20Permit {
    /// @dev To make etherscan auto-verify new pool, this variable is not immutable
    bytes32 public domainSeparator;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32
        public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) public nonces;

    constructor(
        string memory name,
        string memory symbol,
        string memory version
    ) public ERC20(name, symbol) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "ERC20Permit: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline)
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "ERC20Permit: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

interface IDMMCallee {
    function dmmSwapCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IDMMFactory.sol";

interface IDMMPool {
    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function sync() external;

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);

    function getTradeInfo()
        external
        view
        returns (
            uint112 _vReserve0,
            uint112 _vReserve1,
            uint112 reserve0,
            uint112 reserve1,
            uint256 feeInPrecision
        );

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function ampBps() external view returns (uint32);

    function factory() external view returns (IDMMFactory);

    function kLast() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "./libraries/MathExt.sol";

/// @dev contract to calculate volume trend. See secion 3.1 in the white paper
/// @dev EMA stands for Exponential moving average
/// @dev https://en.wikipedia.org/wiki/Moving_average
contract VolumeTrendRecorder {
    using MathExt for uint256;
    using SafeMath for uint256;

    uint256 private constant MAX_UINT128 = 2**128 - 1;
    uint256 internal constant PRECISION = 10**18;
    uint256 private constant SHORT_ALPHA = (2 * PRECISION) / 5401;
    uint256 private constant LONG_ALPHA = (2 * PRECISION) / 10801;

    uint128 internal shortEMA;
    uint128 internal longEMA;
    // total volume in current block
    uint128 internal currentBlockVolume;
    uint128 internal lastTradeBlock;

    event UpdateEMA(uint256 shortEMA, uint256 longEMA, uint128 lastBlockVolume, uint256 skipBlock);

    constructor(uint128 _emaInit) public {
        shortEMA = _emaInit;
        longEMA = _emaInit;
        lastTradeBlock = safeUint128(block.number);
    }

    function getVolumeTrendData()
        external
        view
        returns (
            uint128 _shortEMA,
            uint128 _longEMA,
            uint128 _currentBlockVolume,
            uint128 _lastTradeBlock
        )
    {
        _shortEMA = shortEMA;
        _longEMA = longEMA;
        _currentBlockVolume = currentBlockVolume;
        _lastTradeBlock = lastTradeBlock;
    }

    /// @dev records a new trade, update ema and returns current rFactor for this trade
    /// @return rFactor in Precision for this trade
    function recordNewUpdatedVolume(uint256 blockNumber, uint256 value)
        internal
        returns (uint256)
    {
        // this can not be underflow because block.number always increases
        uint256 skipBlock = blockNumber - lastTradeBlock;
        if (skipBlock == 0) {
            currentBlockVolume = safeUint128(
                uint256(currentBlockVolume).add(value),
                "volume exceeds valid range"
            );
            return calculateRFactor(uint256(shortEMA), uint256(longEMA));
        }
        uint128 _currentBlockVolume = currentBlockVolume;
        uint256 _shortEMA = newEMA(shortEMA, SHORT_ALPHA, currentBlockVolume);
        uint256 _longEMA = newEMA(longEMA, LONG_ALPHA, currentBlockVolume);
        // ema = ema * (1-aplha) ^(skipBlock -1)
        _shortEMA = _shortEMA.mulInPrecision(
            (PRECISION - SHORT_ALPHA).unsafePowInPrecision(skipBlock - 1)
        );
        _longEMA = _longEMA.mulInPrecision(
            (PRECISION - LONG_ALPHA).unsafePowInPrecision(skipBlock - 1)
        );
        shortEMA = safeUint128(_shortEMA);
        longEMA = safeUint128(_longEMA);
        currentBlockVolume = safeUint128(value);
        lastTradeBlock = safeUint128(blockNumber);

        emit UpdateEMA(_shortEMA, _longEMA, _currentBlockVolume, skipBlock);

        return calculateRFactor(_shortEMA, _longEMA);
    }

    /// @return rFactor in Precision for this trade
    function getRFactor(uint256 blockNumber) internal view returns (uint256) {
        // this can not be underflow because block.number always increases
        uint256 skipBlock = blockNumber - lastTradeBlock;
        if (skipBlock == 0) {
            return calculateRFactor(shortEMA, longEMA);
        }
        uint256 _shortEMA = newEMA(shortEMA, SHORT_ALPHA, currentBlockVolume);
        uint256 _longEMA = newEMA(longEMA, LONG_ALPHA, currentBlockVolume);
        _shortEMA = _shortEMA.mulInPrecision(
            (PRECISION - SHORT_ALPHA).unsafePowInPrecision(skipBlock - 1)
        );
        _longEMA = _longEMA.mulInPrecision(
            (PRECISION - LONG_ALPHA).unsafePowInPrecision(skipBlock - 1)
        );
        return calculateRFactor(_shortEMA, _longEMA);
    }

    function calculateRFactor(uint256 _shortEMA, uint256 _longEMA)
        internal
        pure
        returns (uint256)
    {
        if (_longEMA == 0) {
            return 0;
        }
        return (_shortEMA * MathExt.PRECISION) / _longEMA;
    }

    /// @dev return newEMA value
    /// @param ema previous ema value in wei
    /// @param alpha in Precicion (required < Precision)
    /// @param value current value to update ema
    /// @dev ema and value is uint128 and alpha < Percison
    /// @dev so this function can not overflow and returned ema is not overflow uint128
    function newEMA(
        uint128 ema,
        uint256 alpha,
        uint128 value
    ) internal pure returns (uint256) {
        assert(alpha < PRECISION);
        return ((PRECISION - alpha) * uint256(ema) + alpha * uint256(value)) / PRECISION;
    }

    function safeUint128(uint256 v) internal pure returns (uint128) {
        require(v <= MAX_UINT128, "overflow uint128");
        return uint128(v);
    }

    function safeUint128(uint256 v, string memory errorMessage) internal pure returns (uint128) {
        require(v <= MAX_UINT128, errorMessage);
        return uint128(v);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Permit is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IDMMFactory.sol";
import "../interfaces/IDMMRouter02Delegate.sol";
import "../interfaces/IERC20Permit.sol";
import "../interfaces/IDMMPool.sol";
import "../interfaces/IWETH.sol";
import "../libraries/DMMLibrary.sol";
import "../ManageUser.sol";

contract DMMRouter02DelegateCall is IDMMRouter02Delegate, ManageUser {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;
    using SafeMath for uint256;

    uint256 internal constant BPS = 10000;
    uint256 internal constant MIN_VRESERVE_RATIO = 0;
    uint256 internal constant MAX_VRESERVE_RATIO = 2**256 - 1;
    uint256 internal constant Q112 = 2**112;
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address public immutable factory;
    IWETH public immutable weth;
    address public manageUser;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "DMMRouter: EXPIRED");
        _;
    }

    constructor(address _factory, IWETH _weth, address _manage) public ManageUser(_manage) {
        factory = _factory;
        weth = _weth;
        manageUser = _manage;
    }

    receive() external payable {
        assert(msg.sender == address(weth)); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256[2] memory vReserveRatioBounds
    ) internal virtual view returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB, uint256 vReserveA, uint256 vReserveB, ) = DMMLibrary
            .getTradeInfo(pool, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = DMMLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "DMMRouter: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = DMMLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "DMMRouter: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
            uint256 currentRate = (vReserveB * Q112) / vReserveA;
            require(
                currentRate >= vReserveRatioBounds[0] && currentRate <= vReserveRatioBounds[1],
                "DMMRouter: OUT_OF_BOUNDS_VRESERVE"
            );
        }
    }

    function addLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256[2] memory vReserveRatioBounds,
        address to,
        uint256 deadline
    )
        public
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        verifyPoolAddress(tokenA, tokenB, pool);
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            pool,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            vReserveRatioBounds
        );
        // using tokenA.safeTransferFrom will get "Stack too deep"
        SafeERC20.safeTransferFrom(tokenA, msg.sender, pool, amountA);
        SafeERC20.safeTransferFrom(tokenB, msg.sender, pool, amountB);
        liquidity = IDMMPool(pool).mint(to);
    }

    function addLiquidityNewPool(
        IERC20 tokenA,
        IERC20 tokenB,
        uint32 ampBps,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        override
        _admin
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        address pool;
        if (ampBps == BPS) {
            pool = IDMMFactory(factory).getUnamplifiedPool(tokenA, tokenB);
        }
        if (pool == address(0)) {
            pool = IDMMFactory(factory).createPool(tokenA, tokenB, ampBps);
        }
        // if we add liquidity to an existing pool, this is an unamplifed pool
        // so there is no need for bounds of virtual reserve ratio
        uint256[2] memory vReserveRatioBounds = [MIN_VRESERVE_RATIO, MAX_VRESERVE_RATIO];
        (amountA, amountB, liquidity) = addLiquidity(
            tokenA,
            tokenB,
            pool,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            vReserveRatioBounds,
            to,
            deadline
        );
    }

    function addLiquidityETH(
        IERC20 token,
        address pool,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256[2] memory vReserveRatioBounds,
        address to,
        uint256 deadline
    )
        public
        override
        payable
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        verifyPoolAddress(token, weth, pool);
        (amountToken, amountETH) = _addLiquidity(
            token,
            weth,
            pool,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin,
            vReserveRatioBounds
        );
        token.safeTransferFrom(msg.sender, pool, amountToken);
        weth.deposit{value: amountETH}();
        weth.safeTransfer(pool, amountETH);
        liquidity = IDMMPool(pool).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
        }
    }

    function addLiquidityNewPoolETH(
        IERC20 token,
        uint32 ampBps,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        override
        payable
        _superAdmin
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        address pool;
        if (ampBps == BPS) {
            pool = IDMMFactory(factory).getUnamplifiedPool(token, weth);
        }
        if (pool == address(0)) {
            pool = IDMMFactory(factory).createPool(token, weth, ampBps);
        }
        // if we add liquidity to an existing pool, this is an unamplifed pool
        // so there is no need for bounds of virtual reserve ratio
        uint256[2] memory vReserveRatioBounds = [MIN_VRESERVE_RATIO, MAX_VRESERVE_RATIO];
        (amountToken, amountETH, liquidity) = addLiquidityETH(
            token,
            pool,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            vReserveRatioBounds,
            to,
            deadline
        );
    }

    // **** REMOVE LIQUIDITY ****

    function removeLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        verifyPoolAddress(tokenA, tokenB, pool);
        IERC20(pool).safeTransferFrom(msg.sender, pool, liquidity); // send liquidity to pool
        (uint256 amount0, uint256 amount1) = IDMMPool(pool).burn(to);
        (IERC20 token0, ) = DMMLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "DMMRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "DMMRouter: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityETH(
        IERC20 token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            weth,
            pool,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        token.safeTransfer(to, amountToken);
        IWETH(weth).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityWithPermit(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountA, uint256 amountB) {
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IERC20Permit(pool).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(
            tokenA,
            tokenB,
            pool,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }


    function removeLiquidityETHWithPermit(
        IERC20 token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256 amountToken, uint256 amountETH) {
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IERC20Permit(pool).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(
            token,
            pool,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        IERC20 token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public override ensure(deadline) returns (uint256 amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            weth,
            pool,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        token.safeTransfer(to, IERC20(token).balanceOf(address(this)));
        IWETH(weth).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        IERC20 token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256 amountETH) {
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IERC20Permit(pool).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            pool,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // **** LIBRARY FUNCTIONS ****


    function verifyPoolAddress(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool
    ) internal view {
        require(IDMMFactory(factory).isPool(tokenA, tokenB, pool), "DMMRouter: INVALID_POOL");
    }
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "./IDMMRouter01Delegate.sol";

interface IDMMRouter02Delegate is IDMMRouter01Delegate {

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        IERC20 token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        IERC20 token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IDMMPool.sol";

library DMMLibrary {
    using SafeMath for uint256;

    uint256 public constant PRECISION = 1e18;

    // returns sorted token addresses, used to handle return values from pools sorted in this order
    function sortTokens(IERC20 tokenA, IERC20 tokenB)
        internal
        pure
        returns (IERC20 token0, IERC20 token1)
    {
        require(tokenA != tokenB, "DMMLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(address(token0) != address(0), "DMMLibrary: ZERO_ADDRESS");
    }

    /// @dev fetch the reserves and fee for a pool, used for trading purposes
    function getTradeInfo(
        address pool,
        IERC20 tokenA,
        IERC20 tokenB
    )
        internal
        view
        returns (
            uint256 reserveA,
            uint256 reserveB,
            uint256 vReserveA,
            uint256 vReserveB,
            uint256 feeInPrecision
        )
    {
        (IERC20 token0, ) = sortTokens(tokenA, tokenB);
        uint256 reserve0;
        uint256 reserve1;
        uint256 vReserve0;
        uint256 vReserve1;
        (reserve0, reserve1, vReserve0, vReserve1, feeInPrecision) = IDMMPool(pool).getTradeInfo();
        (reserveA, reserveB, vReserveA, vReserveB) = tokenA == token0
            ? (reserve0, reserve1, vReserve0, vReserve1)
            : (reserve1, reserve0, vReserve1, vReserve0);
    }

    /// @dev fetches the reserves for a pool, used for liquidity adding
    function getReserves(
        address pool,
        IERC20 tokenA,
        IERC20 tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (IERC20 token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1) = IDMMPool(pool).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pool reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "DMMLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "DMMLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pool reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 vReserveIn,
        uint256 vReserveOut,
        uint256 feeInPrecision
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "DMMLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "DMMLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(PRECISION.sub(feeInPrecision)).div(PRECISION);
        uint256 numerator = amountInWithFee.mul(vReserveOut);
        uint256 denominator = vReserveIn.add(amountInWithFee);
        amountOut = numerator.div(denominator);
        require(reserveOut > amountOut, "DMMLibrary: INSUFFICIENT_LIQUIDITY");
    }

    // given an output amount of an asset and pool reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 vReserveIn,
        uint256 vReserveOut,
        uint256 feeInPrecision
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "DMMLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > amountOut, "DMMLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = vReserveIn.mul(amountOut);
        uint256 denominator = vReserveOut.sub(amountOut);
        amountIn = numerator.div(denominator).add(1);
        // amountIn = floor(amountIN *PRECISION / (PRECISION - feeInPrecision));
        numerator = amountIn.mul(PRECISION);
        denominator = PRECISION.sub(feeInPrecision);
        amountIn = numerator.add(denominator - 1).div(denominator);
    }

    // performs chained getAmountOut calculations on any number of pools
    function getAmountsOut(
        uint256 amountIn,
        address[] memory poolsPath,
        IERC20[] memory path
    ) internal view returns (uint256[] memory amounts) {
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (
                uint256 reserveIn,
                uint256 reserveOut,
                uint256 vReserveIn,
                uint256 vReserveOut,
                uint256 feeInPrecision
            ) = getTradeInfo(poolsPath[i], path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(
                amounts[i],
                reserveIn,
                reserveOut,
                vReserveIn,
                vReserveOut,
                feeInPrecision
            );
        }
    }

    // performs chained getAmountIn calculations on any number of pools
    function getAmountsIn(
        uint256 amountOut,
        address[] memory poolsPath,
        IERC20[] memory path
    ) internal view returns (uint256[] memory amounts) {
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (
                uint256 reserveIn,
                uint256 reserveOut,
                uint256 vReserveIn,
                uint256 vReserveOut,
                uint256 feeInPrecision
            ) = getTradeInfo(poolsPath[i - 1], path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(
                amounts[i],
                reserveIn,
                reserveOut,
                vReserveIn,
                vReserveOut,
                feeInPrecision
            );
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IWETH.sol";
import "./IDMMExchangeRouterDelegate.sol";
import "./IDMMLiquidityRouterDelegate.sol";

/// @dev full interface for router
interface IDMMRouter01Delegate is IDMMExchangeRouterDelegate, IDMMLiquidityRouterDelegate {
//    function factory() external pure returns (address);
//
//    function weth() external pure returns (IWETH);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev an simple interface for integration dApp to swap
interface IDMMExchangeRouterDelegate {
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev an simple interface for integration dApp to contribute liquidity
interface IDMMLiquidityRouterDelegate {

    /**
     * @param tokenA address of token in the pool
     * @param tokenB address of token in the pool
     * @param pool the address of the pool
     * @param amountADesired the amount of tokenA users want to add to the pool
     * @param amountBDesired the amount of tokenB users want to add to the pool
     * @param amountAMin bounds to the extents to which amountB/amountA can go up
     * @param amountBMin bounds to the extents to which amountB/amountA can go down
     * @param vReserveRatioBounds bounds to the extents to which vReserveB/vReserveA can go (precision: 2 ** 112)
     * @param to Recipient of the liquidity tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function addLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256[2] calldata vReserveRatioBounds,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityNewPool(
        IERC20 tokenA,
        IERC20 tokenB,
        uint32 ampBps,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityNewPoolETH(
        IERC20 token,
        uint32 ampBps,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    /**
     * @param token address of token in the pool
     * @param pool the address of the pool
     * @param amountTokenDesired the amount of token users want to add to the pool
     * @dev   msg.value equals to amountEthDesired
     * @param amountTokenMin bounds to the extents to which WETH/token can go up
     * @param amountETHMin bounds to the extents to which WETH/token can go down
     * @param vReserveRatioBounds bounds to the extents to which vReserveB/vReserveA can go (precision: 2 ** 112)
     * @param to Recipient of the liquidity tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function addLiquidityETH(
        IERC20 token,
        address pool,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256[2] calldata vReserveRatioBounds,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    /**
     * @param tokenA address of token in the pool
     * @param tokenB address of token in the pool
     * @param pool the address of the pool
     * @param liquidity the amount of lp token users want to burn
     * @param amountAMin the minimum token retuned after burning
     * @param amountBMin the minimum token retuned after burning
     * @param to Recipient of the returned tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function removeLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @param token address of token in the pool
     * @param pool the address of the pool
     * @param liquidity the amount of lp token users want to burn
     * @param amountTokenMin the minimum token retuned after burning
     * @param amountETHMin the minimum eth in wei retuned after burning
     * @param to Recipient of the returned tokens.
     * @param deadline Unix timestamp after which the transaction will revert
     */
    function removeLiquidityETH(
        IERC20 token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @param tokenA address of token in the pool
     * @param tokenB address of token in the pool
     * @param pool the address of the pool
     * @param liquidity the amount of lp token users want to burn
     * @param amountAMin the minimum token retuned after burning
     * @param amountBMin the minimum token retuned after burning
     * @param to Recipient of the returned tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param approveMax whether users permit the router spending max lp token or not.
     * @param r s v Signature of user to permit the router spending lp token
     */
    function removeLiquidityWithPermit(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @param token address of token in the pool
     * @param pool the address of the pool
     * @param liquidity the amount of lp token users want to burn
     * @param amountTokenMin the minimum token retuned after burning
     * @param amountETHMin the minimum eth in wei retuned after burning
     * @param to Recipient of the returned tokens.
     * @param deadline Unix timestamp after which the transaction will revert
     * @param approveMax whether users permit the router spending max lp token
     * @param r s v signatures of user to permit the router spending lp token.
     */
    function removeLiquidityETHWithPermit(
        IERC20 token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @param amountA amount of 1 side token added to the pool
     * @param reserveA current reserve of the pool
     * @param reserveB current reserve of the pool
     * @return amountB amount of the other token added to the pool
     */
//    function quote(
//        uint256 amountA,
//        uint256 reserveA,
//        uint256 reserveB
//    ) external pure returns (uint256 amountB);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/IDMMFactory.sol";
import "../interfaces/IDMMRouter02.sol";
import "../interfaces/IERC20Permit.sol";
import "../interfaces/IDMMPool.sol";
import "../interfaces/IWETH.sol";
import "../libraries/DMMLibrary.sol";
import "../ManageUser.sol";

contract DMMRouter02 is IDMMRouter02, ManageUser {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;
    using SafeMath for uint256;

    uint256 internal constant BPS = 10000;
    uint256 internal constant MIN_VRESERVE_RATIO = 0;
    uint256 internal constant MAX_VRESERVE_RATIO = 2**256 - 1;
    uint256 internal constant Q112 = 2**112;
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address public immutable override factory;
    IWETH public immutable override weth;
    address public manageUser;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "DMMRouter: EXPIRED");
        _;
    }

    constructor(address _factory, IWETH _weth, address _delegate, address _manage) public ManageUser(_manage){
        factory = _factory;
        weth = _weth;
        manageUser = _manage;
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_delegate);
    }

    receive() external payable {
        assert(msg.sender == address(weth)); // only accept ETH via fallback from the WETH contract
    }

    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }

    function _implementation() internal view returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        _delegate(_implementation());
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pool
    function _swap(
        uint256[] memory amounts,
        address[] memory poolsPath,
        IERC20[] memory path,
        address _to
    ) private {
        for (uint256 i; i < path.length - 1; i++) {
            (IERC20 input, IERC20 output) = (path[i], path[i + 1]);
            (IERC20 token0, ) = DMMLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2 ? poolsPath[i + 1] : _to;
            IDMMPool(poolsPath[i]).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory poolsPath,
        IERC20[] memory path,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256[] memory amounts) {
        verifyPoolsPathSwap(poolsPath, path);
        amounts = DMMLibrary.getAmountsOut(amountIn, poolsPath, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "DMMRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IERC20(path[0]).safeTransferFrom(msg.sender, poolsPath[0], amounts[0]);
        _swap(amounts, poolsPath, path, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory poolsPath,
        IERC20[] memory path,
        address to,
        uint256 deadline
    ) public override ensure(deadline) returns (uint256[] memory amounts) {
        verifyPoolsPathSwap(poolsPath, path);
        amounts = DMMLibrary.getAmountsIn(amountOut, poolsPath, path);
        require(amounts[0] <= amountInMax, "DMMRouter: EXCESSIVE_INPUT_AMOUNT");
        path[0].safeTransferFrom(msg.sender, poolsPath[0], amounts[0]);
        _swap(amounts, poolsPath, path, to);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external override payable ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == weth, "DMMRouter: INVALID_PATH");
        verifyPoolsPathSwap(poolsPath, path);
        amounts = DMMLibrary.getAmountsOut(msg.value, poolsPath, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "DMMRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWETH(weth).deposit{value: amounts[0]}();
        weth.safeTransfer(poolsPath[0], amounts[0]);
        _swap(amounts, poolsPath, path, to);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == weth, "DMMRouter: INVALID_PATH");
        verifyPoolsPathSwap(poolsPath, path);
        amounts = DMMLibrary.getAmountsIn(amountOut, poolsPath, path);
        require(amounts[0] <= amountInMax, "DMMRouter: EXCESSIVE_INPUT_AMOUNT");
        path[0].safeTransferFrom(msg.sender, poolsPath[0], amounts[0]);
        _swap(amounts, poolsPath, path, address(this));
        IWETH(weth).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == weth, "DMMRouter: INVALID_PATH");
        verifyPoolsPathSwap(poolsPath, path);
        amounts = DMMLibrary.getAmountsOut(amountIn, poolsPath, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "DMMRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        path[0].safeTransferFrom(msg.sender, poolsPath[0], amounts[0]);
        _swap(amounts, poolsPath, path, address(this));
        IWETH(weth).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external override payable ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == weth, "DMMRouter: INVALID_PATH");
        verifyPoolsPathSwap(poolsPath, path);
        amounts = DMMLibrary.getAmountsIn(amountOut, poolsPath, path);
        require(amounts[0] <= msg.value, "DMMRouter: EXCESSIVE_INPUT_AMOUNT");
        IWETH(weth).deposit{value: amounts[0]}();
        weth.safeTransfer(poolsPath[0], amounts[0]);
        _swap(amounts, poolsPath, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
        }
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pool
    function _swapSupportingFeeOnTransferTokens(
        address[] memory poolsPath,
        IERC20[] memory path,
        address _to
    ) internal {
        verifyPoolsPathSwap(poolsPath, path);
        for (uint256 i; i < path.length - 1; i++) {
            (IERC20 input, IERC20 output) = (path[i], path[i + 1]);
            (IERC20 token0, ) = DMMLibrary.sortTokens(input, output);
            IDMMPool pool = IDMMPool(poolsPath[i]);
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (
                    uint256 reserveIn,
                    uint256 reserveOut,
                    uint256 vReserveIn,
                    uint256 vReserveOut,
                    uint256 feeInPrecision
                ) = DMMLibrary.getTradeInfo(poolsPath[i], input, output);
                uint256 amountInput = IERC20(input).balanceOf(address(pool)).sub(reserveIn);
                amountOutput = DMMLibrary.getAmountOut(
                    amountInput,
                    reserveIn,
                    reserveOut,
                    vReserveIn,
                    vReserveOut,
                    feeInPrecision
                );
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? poolsPath[i + 1] : _to;
            pool.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory poolsPath,
        IERC20[] memory path,
        address to,
        uint256 deadline
    ) public override ensure(deadline) {
        path[0].safeTransferFrom(msg.sender, poolsPath[0], amountIn);
        uint256 balanceBefore = path[path.length - 1].balanceOf(to);
        _swapSupportingFeeOnTransferTokens(poolsPath, path, to);
        uint256 balanceAfter = path[path.length - 1].balanceOf(to);
        require(
            balanceAfter >= balanceBefore.add(amountOutMin),
            "DMMRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external override payable ensure(deadline) {
        require(path[0] == weth, "DMMRouter: INVALID_PATH");
        uint256 amountIn = msg.value;
        IWETH(weth).deposit{value: amountIn}();
        weth.safeTransfer(poolsPath[0], amountIn);
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(poolsPath, path, to);
        require(
            path[path.length - 1].balanceOf(to).sub(balanceBefore) >= amountOutMin,
            "DMMRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) {
        require(path[path.length - 1] == weth, "DMMRouter: INVALID_PATH");
        path[0].safeTransferFrom(msg.sender, poolsPath[0], amountIn);
        _swapSupportingFeeOnTransferTokens(poolsPath, path, address(this));
        uint256 amountOut = IWETH(weth).balanceOf(address(this));
        require(amountOut >= amountOutMin, "DMMRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(weth).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****

    /// @dev get the amount of tokenB for adding liquidity with given amount of token A and the amount of tokens in the pool
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external override pure returns (uint256 amountB) {
        return DMMLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata poolsPath,
        IERC20[] calldata path
    ) external override view returns (uint256[] memory amounts) {
        verifyPoolsPathSwap(poolsPath, path);
        return DMMLibrary.getAmountsOut(amountIn, poolsPath, path);
    }

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata poolsPath,
        IERC20[] calldata path
    ) external override view returns (uint256[] memory amounts) {
        verifyPoolsPathSwap(poolsPath, path);
        return DMMLibrary.getAmountsIn(amountOut, poolsPath, path);
    }

    function verifyPoolsPathSwap(address[] memory poolsPath, IERC20[] memory path) internal view {
        require(path.length >= 2, "DMMRouter: INVALID_PATH");
        require(poolsPath.length == path.length - 1, "DMMRouter: INVALID_POOLS_PATH");
        for (uint256 i = 0; i < poolsPath.length; i++) {
            verifyPoolAddress(path[i], path[i + 1], poolsPath[i]);
        }
    }

    function verifyPoolAddress(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool
    ) internal view {
        require(IDMMFactory(factory).isPool(tokenA, tokenB, pool), "DMMRouter: INVALID_POOL");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "./IDMMRouter01.sol";

interface IDMMRouter02 is IDMMRouter01 {

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IWETH.sol";
import "./IDMMExchangeRouter.sol";
import "./IDMMLiquidityRouter.sol";

/// @dev full interface for router
interface IDMMRouter01 is IDMMExchangeRouter, IDMMLiquidityRouter {
    function factory() external pure returns (address);

    function weth() external pure returns (IWETH);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev an simple interface for integration dApp to swap
interface IDMMExchangeRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata poolsPath,
        IERC20[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata poolsPath,
        IERC20[] calldata path
    ) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev an simple interface for integration dApp to contribute liquidity
interface IDMMLiquidityRouter {

    /**
     * @param amountA amount of 1 side token added to the pool
     * @param reserveA current reserve of the pool
     * @param reserveB current reserve of the pool
     * @return amountB amount of the other token added to the pool
     */
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "./IDMMRouter02.sol";
import "./IDMMRouter02Delegate.sol";

interface IDMMRouter02Total is IDMMRouter02, IDMMRouter02Delegate {
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "../interfaces/IDMMLiquidityRouter.sol";
import "../interfaces/IDMMRouter02Total.sol";
import "../interfaces/IERC20Permit.sol";

interface ILiquidityMigrator {
    struct PermitData {
        bool approveMax;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct PoolInfo {
        address poolAddress;
        uint32 poolAmp;
        uint256[2] dmmVReserveRatioBounds;
    }

    event RemoveLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        address indexed uniPair,
        uint256 liquidity,
        uint256 amountA,
        uint256 amountB
    );

    event Migrated(
        address indexed tokenA,
        address indexed tokenB,
        uint256 dmmAmountA,
        uint256 dmmAmountB,
        uint256 dmmLiquidity,
        PoolInfo info
    );

    /**
     * @dev Migrate tokens from a pair to a Kyber Dmm Pool
     *   Supporting both normal tokens and tokens with fee on transfer
     *   Support create new pool with received tokens from removing, or
     *       add tokens to a given pool address
     * @param uniPair pair for token that user wants to migrate from
     *   it should be compatible with UniswapPair's interface
     * @param tokenA first token of the pool
     * @param tokenB second token of the pool
     * @param liquidity amount of LP tokens to migrate
     * @param amountAMin min amount for tokenA when removing
     * @param amountBMin min amount for tokenB when removing
     * @param dmmAmountAMin min amount for tokenA when adding
     * @param dmmAmountBMin min amount for tokenB when adding
     * @param poolInfo info the the Kyber DMM Pool - (poolAddress, poolAmp)
     *   if poolAddress is 0x0 -> create new pool with amp factor of poolAmp
     *   otherwise add liquidity to poolAddress
     * @param deadline only allow transaction to be executed before the deadline
     */
    function migrateLpToDmmPool(
        address uniPair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 dmmAmountAMin,
        uint256 dmmAmountBMin,
        PoolInfo calldata poolInfo,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 addedLiquidity
        );

    /**
     * @dev Migrate tokens from a pair to a Kyber Dmm Pool with permit
     *   User doesn't have to make an approve allowance transaction, just need to sign the data
     *   Supporting both normal tokens and tokens with fee on transfer
     *   Support create new pool with received tokens from removing, or
     *       add tokens to a given pool address
     * @param uniPair pair for token that user wants to migrate from
     *   it should be compatible with UniswapPair's interface
     * @param tokenA first token of the pool
     * @param tokenB second token of the pool
     * @param liquidity amount of LP tokens to migrate
     * @param amountAMin min amount for tokenA when removing
     * @param amountBMin min amount for tokenB when removing
     * @param dmmAmountAMin min amount for tokenA when adding
     * @param dmmAmountBMin min amount for tokenB when adding
     * @param poolInfo info the the Kyber DMM Pool - (poolAddress, poolAmp)
     *   if poolAddress is 0x0 -> create new pool with amp factor of poolAmp
     *   otherwise add liquidity to poolAddress
     * @param deadline only allow transaction to be executed before the deadline
     * @param permitData data of approve allowance
     */
    function migrateLpToDmmPoolWithPermit(
        address uniPair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 dmmAmountAMin,
        uint256 dmmAmountBMin,
        PoolInfo calldata poolInfo,
        uint256 deadline,
        PermitData calldata permitData
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 addedLiquidity
        );
}

/**
 * @dev Liquidity Migrator contract to help migrating liquidity
 *       from other sources to Kyber DMM Pool
 */
contract LiquidityMigrator is ILiquidityMigrator, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public immutable dmmRouter;

    constructor(address _dmmRouter) public {
        require(_dmmRouter != address(0), "Migrator: INVALID_ROUTER");
        dmmRouter = _dmmRouter;
    }

    /**
     * @dev Use only for some special tokens
     */
    function manualApproveAllowance(
        IERC20[] calldata tokens,
        address[] calldata spenders,
        uint256 allowance
    ) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            for (uint256 j = 0; j < spenders.length; j++) {
                tokens[i].safeApprove(spenders[j], allowance);
            }
        }
    }

    /**
     * @dev Migrate tokens from a pair to a Kyber Dmm Pool
     *   Supporting both normal tokens and tokens with fee on transfer
     *   Support create new pool with received tokens from removing, or
     *       add tokens to a given pool address
     * @param uniPair pair for token that user wants to migrate from
     *   it should be compatible with UniswapPair's interface
     * @param tokenA first token of the pool
     * @param tokenB second token of the pool
     * @param liquidity amount of LP tokens to migrate
     * @param amountAMin min amount for tokenA when removing/adding
     * @param amountBMin min amount for tokenB when removing/adding
     * @param poolInfo info the the Kyber DMM Pool - (poolAddress, poolAmp)
     *   if poolAddress is 0x0 -> create new pool with amp factor of poolAmp
     *   otherwise add liquidity to poolAddress
     * @param deadline only allow transaction to be executed before the deadline
     * @param permitData data of approve allowance
     */
    function migrateLpToDmmPoolWithPermit(
        address uniPair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 dmmAmountAMin,
        uint256 dmmAmountBMin,
        PoolInfo calldata poolInfo,
        uint256 deadline,
        PermitData calldata permitData
    )
        external
        override
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 addedLiquidity
        )
    {
        IERC20Permit(uniPair).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(-1) : liquidity,
            deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );

        (amountA, amountB, addedLiquidity) = migrateLpToDmmPool(
            uniPair,
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            dmmAmountAMin,
            dmmAmountBMin,
            poolInfo,
            deadline
        );
    }

    /**
     * @dev Migrate tokens from a pair to a Kyber Dmm Pool with permit
     *   User doesn't have to make an approve allowance transaction, just need to sign the data
     *   Supporting both normal tokens and tokens with fee on transfer
     *   Support create new pool with received tokens from removing, or
     *       add tokens to a given pool address
     * @param uniPair pair for token that user wants to migrate from
     *   it should be compatible with UniswapPair's interface
     * @param tokenA first token of the pool
     * @param tokenB second token of the pool
     * @param liquidity amount of LP tokens to migrate
     * @param amountAMin min amount for tokenA when removing/adding
     * @param amountBMin min amount for tokenB when removing/adding
     * @param poolInfo info the the Kyber DMM Pool - (poolAddress, poolAmp)
     *   if poolAddress is 0x0 -> create new pool with amp factor of poolAmp
     *   otherwise add liquidity to poolAddress
     * @param deadline only allow transaction to be executed before the deadline
     */
    function migrateLpToDmmPool(
        address uniPair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 dmmAmountAMin,
        uint256 dmmAmountBMin,
        PoolInfo memory poolInfo,
        uint256 deadline
    )
        public
        override
        returns (
            uint256 dmmAmountA,
            uint256 dmmAmountB,
            uint256 dmmLiquidity
        )
    {
        // support for both normal token and token with fee on transfer
        {
            uint256 balanceTokenA = IERC20(tokenA).balanceOf(address(this));
            uint256 balanceTokenB = IERC20(tokenB).balanceOf(address(this));
            _removeUniLiquidity(
                uniPair,
                tokenA,
                tokenB,
                liquidity,
                amountAMin,
                amountBMin,
                deadline
            );
            dmmAmountA = IERC20(tokenA).balanceOf(address(this)).sub(balanceTokenA);
            dmmAmountB = IERC20(tokenB).balanceOf(address(this)).sub(balanceTokenB);
            require(dmmAmountA > 0 && dmmAmountB > 0, "Migrator: INVALID_AMOUNT");

            emit RemoveLiquidity(tokenA, tokenB, uniPair, liquidity, dmmAmountA, dmmAmountB);
        }

        (dmmAmountA, dmmAmountB, dmmLiquidity) = _addLiquidityToDmmPool(
            tokenA,
            tokenB,
            dmmAmountA,
            dmmAmountB,
            dmmAmountAMin,
            dmmAmountBMin,
            poolInfo,
            deadline
        );

        emit Migrated(tokenA, tokenB, dmmAmountA, dmmAmountB, dmmLiquidity, poolInfo);
    }

    /** @dev Allow the Owner to withdraw any funds that have been 'wrongly'
     *       transferred to the migrator contract
     */
    function withdrawFund(IERC20 token, uint256 amount) external onlyOwner {
        if (token == IERC20(0)) {
            (bool success, ) = owner().call{value: amount}("");
            require(success, "Migrator: TRANSFER_ETH_FAILED");
        } else {
            token.safeTransfer(owner(), amount);
        }
    }

    /**
     * @dev Add liquidity to Kyber dmm pool, support adding to new pool or an existing pool
     */
    function _addLiquidityToDmmPool(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        PoolInfo memory poolInfo,
        uint256 deadline
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        // safe approve only if needed
        _safeApproveAllowance(IERC20(tokenA), address(dmmRouter));
        _safeApproveAllowance(IERC20(tokenB), address(dmmRouter));
        if (poolInfo.poolAddress == address(0)) {
            // add to new pool
            (amountA, amountB, liquidity) = _addLiquidityNewPool(
                tokenA,
                tokenB,
                amountADesired,
                amountBDesired,
                amountAMin,
                amountBMin,
                poolInfo.poolAmp,
                deadline
            );
        } else {
            (amountA, amountB, liquidity) = _addLiquidityExistingPool(
                tokenA,
                tokenB,
                amountADesired,
                amountBDesired,
                amountAMin,
                amountBMin,
                poolInfo.poolAddress,
                poolInfo.dmmVReserveRatioBounds,
                deadline
            );
        }
    }

    /**
     * @dev Add liquidity to an existing pool, and return back tokens to users if any
     */
    function _addLiquidityExistingPool(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address dmmPool,
        uint256[2] memory vReserveRatioBounds,
        uint256 deadline
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB, liquidity) = IDMMRouter02Total(dmmRouter).addLiquidity(
            IERC20(tokenA),
            IERC20(tokenB),
            dmmPool,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            vReserveRatioBounds,
            msg.sender,
            deadline
        );
        // return back token if needed
        if (amountA < amountADesired) {
            IERC20(tokenA).safeTransfer(msg.sender, amountADesired - amountA);
        }
        if (amountB < amountBDesired) {
            IERC20(tokenB).safeTransfer(msg.sender, amountBDesired - amountB);
        }
    }

    /**
     * @dev Add liquidity to a new pool, and return back tokens to users if any
     */
    function _addLiquidityNewPool(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint32 amps,
        uint256 deadline
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB, liquidity) = IDMMRouter02Total(dmmRouter).addLiquidityNewPool(
            IERC20(tokenA),
            IERC20(tokenB),
            amps,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            msg.sender,
            deadline
        );
        // return back token if needed
        if (amountA < amountADesired) {
            IERC20(tokenA).safeTransfer(msg.sender, amountADesired - amountA);
        }
        if (amountB < amountBDesired) {
            IERC20(tokenB).safeTransfer(msg.sender, amountBDesired - amountB);
        }
    }

    /**
     * @dev Re-write remove liquidity function from Uniswap
     */
    function _removeUniLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    ) internal {
        require(deadline >= block.timestamp, "Migratior: EXPIRED");
        IERC20(pair).safeTransferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(address(this));
        (address token0, ) = _sortTokens(tokenA, tokenB);
        (uint256 amountA, uint256 amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        require(amountA >= amountAMin, "Migratior: UNI_INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "Migratior: UNI_INSUFFICIENT_B_AMOUNT");
    }

    /**
     * @dev only approve if the current allowance is 0
     */
    function _safeApproveAllowance(IERC20 token, address spender) internal {
        if (token.allowance(address(this), spender) == 0) {
            token.safeApprove(spender, uint256(-1));
        }
    }

    /**
     * @dev Copy logic of sort token from Uniswap lib
     */
    function _sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "Migrator: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Migrator: ZERO_ADDRESS");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../../interfaces/IDMMPool.sol";
import "./IKyberDao.sol";

contract DaoOperator {
    address public daoOperator;

    constructor(address _daoOperator) public {
        require(_daoOperator != address(0), "daoOperator is 0");
        daoOperator = _daoOperator;
    }

    modifier onlyDaoOperator() {
        require(msg.sender == daoOperator, "only daoOperator");
        _;
    }
}

contract FeeTo is DaoOperator, ReentrancyGuard {
    uint256 internal constant PRECISION = (10**18);

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IKyberDao public immutable kyberDao;

    mapping(uint256 => mapping(IERC20 => uint256)) public rewardsPerEpoch;
    mapping(uint256 => mapping(IERC20 => uint256)) public rewardsPaidPerEpoch;
    // hasClaimedReward[staker][epoch]: true/false if the staker has/hasn't claimed the reward for an epoch
    mapping(address => mapping(uint256 => mapping(IERC20 => bool))) public hasClaimedReward;
    mapping(IERC20 => uint256) public reserves; // total balance in the contract that is for reward and platform fee

    mapping(IERC20 => bool) public allowedToken;
    mapping(IERC20 => uint256) public lastFinalizedEpoch;

    event FeeDistributed(IERC20 indexed token, uint256 indexed epoch, uint256 rewardWei);
    event RewardPaid(
        address indexed staker,
        uint256 indexed epoch,
        IERC20 indexed token,
        uint256 amount
    );
    event SetAllowedToken(IERC20 token, bool isAllowed);

    constructor(IKyberDao _kyberDao, address _daoOperator) public DaoOperator(_daoOperator) {
        require(_kyberDao != IKyberDao(0), "_kyberDao 0");

        kyberDao = _kyberDao;
    }

    function setAllowedToken(IERC20 token, bool isAllowed) external onlyDaoOperator {
        allowedToken[token] = isAllowed;

        emit SetAllowedToken(token, isAllowed);
    }

    function finalize(IERC20 token, uint256 epoch) public {
        if (!allowedToken[token]) {
            return;
        }
        uint256 lastEpoch = kyberDao.getCurrentEpochNumber() - 1;
        // epoch mut be last epoch
        if (epoch != lastEpoch) {
            return;
        }
        // epoch must be not finalized
        if (lastEpoch <= lastFinalizedEpoch[token]) {
            return;
        }
        lastFinalizedEpoch[token] = lastEpoch;
        IDMMPool(address(token)).sync();

        uint256 amount = token.balanceOf(address(this)).sub(reserves[token]);
        if (amount == 0) {
            return;
        }
        rewardsPerEpoch[lastEpoch][token] = rewardsPerEpoch[lastEpoch][token].add(amount);
        reserves[token] = reserves[token].add(amount);
        emit FeeDistributed(token, lastEpoch, amount);
    }

    function burn(IERC20 token) external onlyDaoOperator {
        require(allowedToken[token], "token should be distributed");
        uint256 amount = token.balanceOf(address(this));
        if (amount <= 1) {
            return;
        }
        token.safeTransfer(address(token), amount - 1); // gas saving.
        IDMMPool(address(token)).burn(address(token));
    }

    /// @notice  WARNING When staker address is a contract,
    ///          it should be able to receive claimed reward in ETH whenever anyone calls this function.
    /// @dev not revert if already claimed or reward percentage is 0
    ///      allow writing a wrapper to claim for multiple epochs
    /// @param staker address.
    /// @param epoch for which epoch the staker is claiming the reward
    function claimStakerReward(
        address staker,
        IERC20 token,
        uint256 epoch
    ) external nonReentrant returns (uint256 amountWei) {
        if (hasClaimedReward[staker][epoch][token]) {
            // staker has already claimed reward for the epoch
            return 0;
        }

        // the relative part of the reward the staker is entitled to for the epoch.
        // units Precision: 10 ** 18 = 100%
        // if the epoch is current or in the future, kyberDao will return 0 as result
        uint256 percentageInPrecision = kyberDao.getPastEpochRewardPercentageInPrecision(
            staker,
            epoch
        );
        if (percentageInPrecision == 0) {
            return 0; // not revert, in case a wrapper wants to claim reward for multiple epochs
        }

        finalize(token, epoch);
        require(percentageInPrecision <= PRECISION, "percentage too high");

        // Amount of reward to be sent to staker
        uint256 rewardAllStaker = rewardsPerEpoch[epoch][token];
        amountWei = rewardAllStaker.mul(percentageInPrecision).div(PRECISION);
        {
            uint256 newRewardPaid = rewardsPaidPerEpoch[epoch][token].add(amountWei);
            assert(newRewardPaid <= rewardAllStaker); // redundant check, can't happen
            rewardsPaidPerEpoch[epoch][token] = newRewardPaid;
        }

        reserves[token] = reserves[token].sub(amountWei);
        hasClaimedReward[staker][epoch][token] = true; // SSTORE

        // send reward to staker
        token.safeTransfer(staker, amountWei);

        emit RewardPaid(staker, epoch, token, amountWei);
    }

    function getCurrentEpochNumber() internal view returns (uint256 epoch) {
        IKyberDao _kyberDao = kyberDao;
        if (_kyberDao == IKyberDao(0)) {
            return 0;
        } else {
            return _kyberDao.getCurrentEpochNumber();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

interface IEpochUtils {
    function epochPeriodInSeconds() external view returns (uint256);

    function firstEpochStartTimestamp() external view returns (uint256);

    function getCurrentEpochNumber() external view returns (uint256);

    function getEpochNumber(uint256 timestamp) external view returns (uint256);
}

interface IKyberDao is IEpochUtils {
    event Voted(
        address indexed staker,
        uint256 indexed epoch,
        uint256 indexed campaignID,
        uint256 option
    );

    function getLatestNetworkFeeDataWithCache()
        external
        returns (uint256 feeInBps, uint256 expiryTimestamp);

    function getLatestBRRDataWithCache()
        external
        returns (
            uint256 burnInBps,
            uint256 rewardInBps,
            uint256 rebateInBps,
            uint256 epoch,
            uint256 expiryTimestamp
        );

    function handleWithdrawal(address staker, uint256 penaltyAmount) external;

    function vote(uint256 campaignID, uint256 option) external;

    function getLatestNetworkFeeData()
        external
        view
        returns (uint256 feeInBps, uint256 expiryTimestamp);

    function shouldBurnRewardForEpoch(uint256 epoch) external view returns (bool);

    /**
     * @dev  return staker's reward percentage in precision for a past epoch only
     *       fee handler should call this function when a staker wants to claim reward
     *       return 0 if staker has no votes or stakes
     */
    function getPastEpochRewardPercentageInPrecision(address staker, uint256 epoch)
        external
        view
        returns (uint256);

    /**
     * @dev  return staker's reward percentage in precision for the current epoch
     *       reward percentage is not finalized until the current epoch is ended
     */
    function getCurrentEpochRewardPercentageInPrecision(address staker)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./IKyberDao.sol";

contract MockKyberDao is IKyberDao {
    uint256 public constant BPS = 10000; // Basic Price Steps. 1 step = 0.01%

    uint256 public rewardInBPS;
    uint256 public rebateInBPS;
    uint256 public epoch;
    uint256 public expiryTimestamp;
    uint256 public feeBps;
    uint256 public epochPeriod = 160;
    uint256 public startTimestamp;
    uint256 public rewardPercentageInPrecision;
    uint256 data;
    mapping(uint256 => bool) public shouldBurnRewardEpoch;

    constructor(
        uint256 _rewardInBPS,
        uint256 _rebateInBPS,
        uint256 _epoch,
        uint256 _expiryTimestamp
    ) public {
        rewardInBPS = _rewardInBPS;
        rebateInBPS = _rebateInBPS;
        epoch = _epoch;
        expiryTimestamp = _expiryTimestamp;
        startTimestamp = now;
    }

    function getLatestNetworkFeeDataWithCache() external override returns (uint256, uint256) {
        data++;
        return (feeBps, expiryTimestamp);
    }

    function getLatestBRRDataWithCache()
        external
        virtual
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (BPS - rewardInBPS - rebateInBPS, rewardInBPS, rebateInBPS, epoch, expiryTimestamp);
    }

    function setStakerPercentageInPrecision(uint256 percentage) external {
        rewardPercentageInPrecision = percentage;
    }

    function getPastEpochRewardPercentageInPrecision(address staker, uint256 forEpoch)
        external
        override
        view
        returns (uint256)
    {
        staker;
        // return 0 for current or future epochs
        if (forEpoch >= epoch) {
            return 0;
        }
        return rewardPercentageInPrecision;
    }

    function getCurrentEpochRewardPercentageInPrecision(address staker)
        external
        override
        view
        returns (uint256)
    {
        staker;
        return rewardPercentageInPrecision;
    }

    function handleWithdrawal(address staker, uint256 reduceAmount) external override {
        staker;
        reduceAmount;
    }

    function vote(uint256 campaignID, uint256 option) external override {
        // must implement so it can be deployed.
        campaignID;
        option;
    }

    function epochPeriodInSeconds() external override view returns (uint256) {
        return epochPeriod;
    }

    function firstEpochStartTimestamp() external override view returns (uint256) {
        return startTimestamp;
    }

    function getCurrentEpochNumber() external override view returns (uint256) {
        return epoch;
    }

    function getEpochNumber(uint256 timestamp) public override view returns (uint256) {
        if (timestamp < startTimestamp || epochPeriod == 0) {
            return 0;
        }
        // ((timestamp - startTimestamp) / epochPeriod) + 1;
        return ((timestamp - startTimestamp) / epochPeriod) + 1;
    }

    function getLatestNetworkFeeData() external override view returns (uint256, uint256) {
        return (feeBps, expiryTimestamp);
    }

    function shouldBurnRewardForEpoch(uint256 epochNum) external override view returns (bool) {
        if (shouldBurnRewardEpoch[epochNum]) return true;
        return false;
    }

    function advanceEpoch() public {
        epoch++;
        expiryTimestamp = now + epochPeriod;
    }

    function setShouldBurnRewardTrue(uint256 epochNum) public {
        shouldBurnRewardEpoch[epochNum] = true;
    }

    function setMockEpochAndExpiryTimestamp(uint256 _epoch, uint256 _expiryTimestamp) public {
        epoch = _epoch;
        expiryTimestamp = _expiryTimestamp;
    }

    function setMockBRR(uint256 _rewardInBPS, uint256 _rebateInBPS) public {
        rewardInBPS = _rewardInBPS;
        rebateInBPS = _rebateInBPS;
    }

    function setNetworkFeeBps(uint256 _feeBps) public {
        feeBps = _feeBps;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "../interfaces/IDMMCallee.sol";
import "../interfaces/IDMMFactory.sol";
import "../interfaces/IDMMPool.sol";
import "../interfaces/IWETH.sol";
import "../libraries/DMMLibrary.sol";

contract ExampleFlashSwap is IDMMCallee {
    using SafeERC20 for IERC20;

    address public immutable factory;
    IWETH public immutable weth;
    IUniswapV2Router02 public uniswapRounter02;

    constructor(IUniswapV2Router02 _uniswapRounter02, address _factory) public {
        uniswapRounter02 = _uniswapRounter02;
        weth = IWETH(_uniswapRounter02.WETH());
        factory = _factory;
    }

    receive() external payable {}

    // gets tokens/WETH via a dmm flash swap, swaps for the WETH/tokens on uniswapV2, repays dmm, and keeps the rest!
    function dmmSwapCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        IERC20[] memory path = new IERC20[](2);
        address[] memory path2 = new address[](2);
        address[] memory poolsPath = new address[](1);
        poolsPath[0] = msg.sender;

        uint256 amountToken;
        uint256 amountETH;
        {
            // scope for token{0,1}, avoids stack too deep errors
            IERC20 token0 = IDMMPool(msg.sender).token0();
            IERC20 token1 = IDMMPool(msg.sender).token1();
            assert(IDMMFactory(factory).isPool(token0, token1, msg.sender));
            assert(amount0 == 0 || amount1 == 0); // this strategy is unidirectional
            path[0] = amount0 == 0 ? token0 : token1;
            path[1] = amount0 == 0 ? token1 : token0;
            path2[0] = address(path[1]);
            path2[1] = address(path[0]);

            amountToken = token0 == IERC20(weth) ? amount1 : amount0;
            amountETH = token0 == IERC20(weth) ? amount0 : amount1;
        }
        assert(path[0] == IERC20(weth) || path[1] == IERC20(weth)); // this strategy only works with a V2 WETH pool

        if (amountToken > 0) {
            uint256 minETH = abi.decode(data, (uint256)); // slippage parameter for V1, passed in by caller
            uint256 amountRequired = DMMLibrary.getAmountsIn(amountToken, poolsPath, path)[0];
            path[1].safeApprove(address(uniswapRounter02), amountToken);
            uint256[] memory amounts = uniswapRounter02.swapExactTokensForTokens(
                amountToken,
                minETH,
                path2,
                address(this),
                uint256(-1)
            );
            uint256 amountReceived = amounts[amounts.length - 1];
            assert(amountReceived > amountRequired); // fail if we didn't get enough ETH back to repay our flash loan

            weth.transfer(msg.sender, amountRequired);
            weth.withdraw(amountReceived - amountRequired);
            (bool success, ) = sender.call{value: amountReceived - amountRequired}(new bytes(0));
            require(success, "transfer eth failed");
        } else {
            weth.withdraw(amountETH);
            uint256 amountRequired = DMMLibrary.getAmountsIn(amountETH, poolsPath, path)[0];
            uint256[] memory amounts = uniswapRounter02.swapETHForExactTokens{value: amountETH}(
                amountRequired,
                path2,
                address(this),
                uint256(-1)
            );

            path[0].safeTransfer(msg.sender, amountRequired);
            assert(amountETH > amounts[0]); // fail if we didn't get enough tokens back to repay our flash loan
            (bool success, ) = sender.call{value: amountETH - amounts[0]}(new bytes(0));
            require(success, "transfer eth failed");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IDMMFactory.sol";

contract DaoRegistry is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public immutable factory;
    mapping(IERC20 => mapping(IERC20 => EnumerableSet.AddressSet)) internal tokenPools;

    event AddPool(IERC20 token0, IERC20 token1, address pool, bool isAdd);

    constructor(address _factory) public Ownable() {
        factory = _factory;
    }

    function addPool(
        IERC20 token0,
        IERC20 token1,
        address pool,
        bool isAdd
    ) external onlyOwner {
        // populate mapping in the reverse direction
        if (isAdd) {
            require(IDMMFactory(factory).isPool(token0, token1, pool), "Registry: INVALID_POOL");

            tokenPools[token0][token1].add(pool);
            tokenPools[token1][token0].add(pool);
        } else {
            tokenPools[token0][token1].remove(pool);
            tokenPools[token1][token0].remove(pool);
        }

        emit AddPool(token0, token1, pool, isAdd);
    }

    function getPools(IERC20 token0, IERC20 token1)
        external
        view
        returns (address[] memory _tokenPools)
    {
        uint256 length = tokenPools[token0][token1].length();
        _tokenPools = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            _tokenPools[i] = tokenPools[token0][token1].at(i);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) public ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockFeeOnTransferERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) public ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override {
        uint256 burnAmount = (value * 13) / 10000;
        _burn(from, burnAmount);
        uint256 transferAmount = value.sub(burnAmount);

        super._transfer(from, to, transferAmount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "../libraries/MathExt.sol";

contract MockMathExt {
    using MathExt for uint256;

    function mulInPrecision(uint256 x, uint256 y) external pure returns (uint256) {
        return x.mulInPrecision(y);
    }

    function powInPrecision(uint256 x, uint256 k) external pure returns (uint256) {
        return x.unsafePowInPrecision(k);
    }

    function sqrt(uint256 x) external pure returns (uint256) {
        return x.sqrt();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "../VolumeTrendRecorder.sol";

contract MockVolumeTrendRecorder is VolumeTrendRecorder {
    constructor(uint128 _emaInit) public VolumeTrendRecorder(_emaInit) {}

    function mockRecordNewUpdatedVolume(uint256 value, uint256 blockNumber) external {
        recordNewUpdatedVolume(blockNumber, value);
    }

    function mockGetRFactor(uint256 blockNumber) external view returns (uint256) {
        return getRFactor(blockNumber);
    }

    function testGasCostGetRFactor(uint256 blockNumber) external view returns (uint256) {
        uint256 gas1 = gasleft();
        getRFactor(blockNumber);
        return gas1 - gasleft();
    }

    function mockGetInfo()
        external
        view
        returns (
            uint128 _shortEMA,
            uint128 _longEMA,
            uint128 _currentBlockVolume,
            uint128 _lastTradeBlock
        )
    {
        _shortEMA = shortEMA;
        _longEMA = longEMA;
        _currentBlockVolume = currentBlockVolume;
        _lastTradeBlock = lastTradeBlock;
    }

    function mockSafeUint128(uint256 a) external pure returns (uint128) {
        return safeUint128(a);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "../DMMPool.sol";

/// @dev this is a mock contract, so tester can set fee to random value
contract MockDMMPool is DMMPool {
    uint256 public simulationFee;

    constructor(
        address _factory,
        IERC20 _token0,
        IERC20 _token1,
        bool isAmpPool
    ) public DMMPool() {
        factory = IDMMFactory(_factory);
        token0 = _token0;
        token1 = _token1;
        ampBps = isAmpPool ? uint32(BPS + 1) : uint32(BPS);
    }

    function setFee(uint256 _fee) external {
        simulationFee = _fee;
    }

    function setReserves(
        uint112 _reserve0,
        uint112 _reserve1,
        uint112 _vReserve0,
        uint112 _vReserve1
    ) external {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        vReserve0 = _vReserve0;
        vReserve1 = _vReserve1;
    }

    function verifyBalanceAndUpdateEma(
        uint256 amount0In,
        uint256 amount1In,
        uint256 beforeReserve0,
        uint256 beforeReserve1,
        uint256 afterReserve0,
        uint256 afterReserve1
    ) internal override returns (uint256 feeInPrecision) {
        feeInPrecision = simulationFee;
        //verify balance update is match with fomula
        uint256 balance0Adjusted = afterReserve0.mul(PRECISION);
        balance0Adjusted = balance0Adjusted.sub(amount0In.mul(feeInPrecision));
        balance0Adjusted = balance0Adjusted / PRECISION;
        uint256 balance1Adjusted = afterReserve1.mul(PRECISION);
        balance1Adjusted = balance1Adjusted.sub(amount1In.mul(feeInPrecision));
        balance1Adjusted = balance1Adjusted / PRECISION;
        require(
            balance0Adjusted.mul(balance1Adjusted) >= beforeReserve0.mul(beforeReserve1),
            "DMM: K"
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "../libraries/ERC20Permit.sol";

contract MockERC20Permit is ERC20Permit {
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _version,
        uint256 _totalSupply
    ) public ERC20Permit(_name, _symbol, _version) {
        _mint(msg.sender, _totalSupply);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "../libraries/FeeFomula.sol";

contract MockFeeFomula {
    function getFee(uint256 rFactor) external pure returns (uint256) {
        return FeeFomula.getFee(rFactor);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDMMFactoryDelegate {

    function setFeeConfiguration(address feeTo, uint16 governmentFeeBps) external;

    function setFeeToSetter(address) external;

    function getFeeConfiguration() external view returns (address feeTo, uint16 governmentFeeBps);

    function feeToSetter() external view returns (address);

    function allPools(uint256) external view returns (address pool);

    function allPoolsLength() external view returns (uint256);

    function getUnamplifiedPool(IERC20 token0, IERC20 token1) external view returns (address);

    function getPools(IERC20 token0, IERC20 token1)
        external
        view
        returns (address[] memory _tokenPools);

    function isPool(
        IERC20 token0,
        IERC20 token1,
        address pool
    ) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "../libraries/DMMLibrary.sol";

contract MockDMMLibrary {
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 vReserveIn,
        uint256 vReserveOut,
        uint256 fee
    ) external pure returns (uint256 amountOut) {
        return
            DMMLibrary.getAmountOut(amountIn, reserveIn, reserveOut, vReserveIn, vReserveOut, fee);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 vReserveIn,
        uint256 vReserveOut,
        uint256 fee
    ) external pure returns (uint256 amountIn) {
        return
            DMMLibrary.getAmountIn(amountOut, reserveIn, reserveOut, vReserveIn, vReserveOut, fee);
    }

    function sortTokens(IERC20 tokenA, IERC20 tokenB)
        external
        pure
        returns (IERC20 token0, IERC20 token1)
    {
        return DMMLibrary.sortTokens(tokenA, tokenB);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "../ManageUser.sol";

contract TestManageUser is ManageUser {
    constructor(address _manage) public ManageUser(_manage) {
    }

    function testOnlySuperAdmin() public view _superAdmin returns (uint) {
        return 100;
    }

    function testAdmin() public view _admin returns (uint) {
        return 200;
    }

    function everyoneCanRead() public pure returns (uint) {
        return 300;
    }
}

