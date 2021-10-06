// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../interfaces/IPoolFactory.sol";
import "../utils/TridentOwnable.sol";

/// @notice Trident pool deployer contract with template factory whitelist.
/// @author Mudit Gupta.
contract MasterDeployer is TridentOwnable {
    event DeployPool(address indexed factory, address indexed pool, bytes deployData);
    event AddToWhitelist(address indexed factory);
    event RemoveFromWhitelist(address indexed factory);
    event BarFeeUpdated(uint256 indexed barFee);
    event MigratorUpdated(address indexed migrator);

    uint256 public barFee;
    address public migrator;

    address public immutable barFeeTo;
    address public immutable bento;

    uint256 internal constant MAX_FEE = 10000; // @dev 100%.

    mapping(address => bool) public pools;
    mapping(address => bool) public whitelistedFactories;

    constructor(
        uint256 _barFee,
        address _barFeeTo,
        address _bento
    ) {
        require(_barFee <= MAX_FEE, "INVALID_BAR_FEE");
        require(_barFeeTo != address(0), "ZERO_ADDRESS");
        require(_bento != address(0), "ZERO_ADDRESS");

        barFee = _barFee;
        barFeeTo = _barFeeTo;
        bento = _bento;
    }

    function deployPool(address _factory, bytes calldata _deployData) external returns (address pool) {
        require(whitelistedFactories[_factory], "FACTORY_NOT_WHITELISTED");
        pool = IPoolFactory(_factory).deployPool(_deployData);
        pools[pool] = true;
        emit DeployPool(_factory, pool, _deployData);
    }

    function addToWhitelist(address _factory) external onlyOwner {
        whitelistedFactories[_factory] = true;
        emit AddToWhitelist(_factory);
    }

    function removeFromWhitelist(address _factory) external onlyOwner {
        whitelistedFactories[_factory] = false;
        emit RemoveFromWhitelist(_factory);
    }

    function setBarFee(uint256 _barFee) external onlyOwner {
        require(_barFee <= MAX_FEE, "INVALID_BAR_FEE");
        barFee = _barFee;
        emit BarFeeUpdated(_barFee);
    }

    function setMigrator(address _migrator) external onlyOwner {
        migrator = _migrator;
        emit MigratorUpdated(_migrator);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident pool deployment interface.
interface IPoolFactory {
    function deployPool(bytes calldata _deployData) external returns (address pool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident access control contract.
/// @author Adapted from https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringOwnable.sol, License-Identifier: MIT.
contract TridentOwnable {
    address public owner;
    address public pendingOwner;

    event TransferOwner(address indexed sender, address indexed recipient);
    event TransferOwnerClaim(address indexed sender, address indexed recipient);

    /// @notice Initialize and grant deployer account (`msg.sender`) `owner` access role.
    constructor() {
        owner = msg.sender;
        emit TransferOwner(address(0), msg.sender);
    }

    /// @notice Access control modifier that requires modified function to be called by `owner` account.
    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    /// @notice `pendingOwner` can claim `owner` account.
    function claimOwner() external {
        require(msg.sender == pendingOwner, "NOT_PENDING_OWNER");
        emit TransferOwner(owner, msg.sender);
        owner = msg.sender;
        pendingOwner = address(0);
    }

    /// @notice Transfer `owner` account.
    /// @param recipient Account granted `owner` access control.
    /// @param direct If 'true', ownership is directly transferred.
    function transferOwner(address recipient, bool direct) external onlyOwner {
        require(recipient != address(0), "ZERO_ADDRESS");
        if (direct) {
            owner = recipient;
            emit TransferOwner(msg.sender, recipient);
        } else {
            pendingOwner = recipient;
            emit TransferOwnerClaim(msg.sender, recipient);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../pool/ConstantProductPool.sol";
import "../pool/ConstantProductPoolFactory.sol";
import "../deployer/MasterDeployer.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IBentoBoxMinimal.sol";

interface IERC20 {
    function totalSupply() external returns (uint256);
}

contract Migrator {
    address public chef;
    ConstantProductPoolFactory public factory;
    IBentoBoxMinimal public bentoBox;
    uint256 public desiredLiquidity = type(uint256).max;

    constructor(
        address _chef,
        IBentoBoxMinimal _bentoBox,
        ConstantProductPoolFactory _factory
    ) {
        chef = _chef;
        bentoBox = _bentoBox;
        factory = _factory;
    }

    function migrate(ConstantProductPool orig) public returns (IPool) {
        require(msg.sender == chef, "!chef");

        address token0 = orig.token0();
        address token1 = orig.token1();

        bytes memory deployData = abi.encode(token0, token1, 10, false);

        IPool pair = IPool(factory.configAddress(keccak256(deployData)));

        if (address(pair) == (address(0))) {
            pair = IPool(factory.deployPool(deployData));
        }

        require(IERC20(address(pair)).totalSupply() == 0, "pair must have no existing supply");

        uint256 lp = orig.balanceOf(msg.sender);

        if (lp == 0) return pair;

        orig.transferFrom(msg.sender, address(orig), lp);

        desiredLiquidity = lp;

        orig.burn(abi.encode(address(pair), false));

        pair.mint(abi.encode(msg.sender));

        desiredLiquidity = type(uint256).max;

        return pair;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../interfaces/IBentoBoxMinimal.sol";
import "../interfaces/IMasterDeployer.sol";
import "../workInProgress/IMigrator.sol";
import "../interfaces/IPool.sol";
import "../interfaces/ITridentCallee.sol";
import "../libraries/TridentMath.sol";
import "./TridentERC20.sol";

/// @notice Trident exchange pool template with constant product formula for swapping between an ERC-20 token pair.
/// @dev The reserves are stored as bento shares.
///      The curve is applied to shares as well. This pool does not care about the underlying amounts.
contract ConstantProductPool is IPool, TridentERC20 {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient);
    event Sync(uint256 reserve0, uint256 reserve1);

    uint256 internal constant MINIMUM_LIQUIDITY = 1000;

    uint8 internal constant PRECISION = 112;
    uint256 internal constant MAX_FEE = 10000; // @dev 100%.
    uint256 internal constant MAX_FEE_SQUARE = 100000000;
    uint256 public immutable swapFee;
    uint256 internal immutable MAX_FEE_MINUS_SWAP_FEE;

    address public immutable barFeeTo;
    IBentoBoxMinimal public immutable bento;
    IMasterDeployer public immutable masterDeployer;
    address public immutable token0;
    address public immutable token1;

    uint256 public barFee;
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast;

    uint112 internal reserve0;
    uint112 internal reserve1;
    uint32 internal blockTimestampLast;

    bytes32 public constant override poolIdentifier = "Trident:ConstantProduct";

    uint256 internal unlocked;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 2;
        _;
        unlocked = 1;
    }

    constructor(bytes memory _deployData, address _masterDeployer) {
        (address _token0, address _token1, uint256 _swapFee, bool _twapSupport) = abi.decode(_deployData, (address, address, uint256, bool));

        // @dev Factory ensures that the tokens are sorted.
        require(_token0 != address(0), "ZERO_ADDRESS");
        require(_token0 != _token1, "IDENTICAL_ADDRESSES");
        require(_token0 != address(this), "INVALID_TOKEN");
        require(_token1 != address(this), "INVALID_TOKEN");
        require(_swapFee <= MAX_FEE, "INVALID_SWAP_FEE");

        token0 = _token0;
        token1 = _token1;
        swapFee = _swapFee;
        // @dev This is safe from underflow - `swapFee` cannot exceed `MAX_FEE` per previous check.
        unchecked {
            MAX_FEE_MINUS_SWAP_FEE = MAX_FEE - _swapFee;
        }
        barFee = IMasterDeployer(_masterDeployer).barFee();
        barFeeTo = IMasterDeployer(_masterDeployer).barFeeTo();
        bento = IBentoBoxMinimal(IMasterDeployer(_masterDeployer).bento());
        masterDeployer = IMasterDeployer(_masterDeployer);
        unlocked = 1;
        if (_twapSupport) blockTimestampLast = 1;
    }

    /// @dev Mints LP tokens - should be called via the router after transferring `bento` tokens.
    /// The router must ensure that sufficient LP tokens are minted by using the return value.
    function mint(bytes calldata data) public override lock returns (uint256 liquidity) {
        address recipient = abi.decode(data, (address));
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = _getReserves();
        (uint256 balance0, uint256 balance1) = _balance();

        uint256 computed = TridentMath.sqrt(balance0 * balance1);
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
        (uint256 fee0, uint256 fee1) = _nonOptimalMintFee(amount0, amount1, _reserve0, _reserve1);
        _reserve0 += uint112(fee0);
        _reserve1 += uint112(fee1);

        (uint256 _totalSupply, uint256 k) = _mintFee(_reserve0, _reserve1);

        if (_totalSupply == 0) {
            require(amount0 > 0 && amount1 > 0, "INVALID_AMOUNTS");
            liquidity = computed - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            uint256 kIncrease;
            unchecked {
                kIncrease = computed - k;
            }
            liquidity = (kIncrease * _totalSupply) / k;
        }
        require(liquidity != 0, "INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(recipient, liquidity);
        _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
        kLast = computed;
        emit Mint(msg.sender, amount0, amount1, recipient);
    }

    /// @dev Burns LP tokens sent to this contract. The router must ensure that the user gets sufficient output tokens.
    function burn(bytes calldata data) public override lock returns (IPool.TokenAmount[] memory withdrawnAmounts) {
        (address recipient, bool unwrapBento) = abi.decode(data, (address, bool));
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = _getReserves();
        (uint256 balance0, uint256 balance1) = _balance();
        uint256 liquidity = balanceOf[address(this)];

        (uint256 _totalSupply, ) = _mintFee(_reserve0, _reserve1);

        uint256 amount0 = (liquidity * balance0) / _totalSupply;
        uint256 amount1 = (liquidity * balance1) / _totalSupply;

        _burn(address(this), liquidity);
        _transfer(token0, amount0, recipient, unwrapBento);
        _transfer(token1, amount1, recipient, unwrapBento);
        // @dev This is safe from underflow - amounts are lesser figures derived from balances.
        unchecked {
            balance0 -= amount0;
            balance1 -= amount1;
        }
        _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
        kLast = TridentMath.sqrt(balance0 * balance1);

        withdrawnAmounts = new TokenAmount[](2);
        withdrawnAmounts[0] = TokenAmount({token: address(token0), amount: amount0});
        withdrawnAmounts[1] = TokenAmount({token: address(token1), amount: amount1});
        emit Burn(msg.sender, amount0, amount1, recipient);
    }

    /// @dev Burns LP tokens sent to this contract and swaps one of the output tokens for another
    /// - i.e., the user gets a single token out by burning LP tokens.
    function burnSingle(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenOut, address recipient, bool unwrapBento) = abi.decode(data, (address, address, bool));
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = _getReserves();
        (uint256 balance0, uint256 balance1) = _balance();
        uint256 liquidity = balanceOf[address(this)];

        (uint256 _totalSupply, ) = _mintFee(_reserve0, _reserve1);

        uint256 amount0 = (liquidity * balance0) / _totalSupply;
        uint256 amount1 = (liquidity * balance1) / _totalSupply;

        _burn(address(this), liquidity);
        kLast = TridentMath.sqrt((uint256(_reserve0) - amount0) * (uint256(_reserve1) - amount1));

        // Swap one token for another
        unchecked {
            if (tokenOut == token1) {
                // @dev Swap `token0` for `token1`
                // - calculate `amountOut` as if the user first withdrew balanced liquidity and then swapped `token0` for `token1`.
                amount1 += _getAmountOut(amount0, _reserve0 - amount0, _reserve1 - amount1);
                _transfer(token1, amount1, recipient, unwrapBento);
                balance1 -= amount1;
                amountOut = amount1;
                amount0 = 0;
            } else {
                // @dev Swap `token1` for `token0`.
                require(tokenOut == token0, "INVALID_OUTPUT_TOKEN");
                amount0 += _getAmountOut(amount1, _reserve1 - amount1, _reserve0 - amount0);
                _transfer(token0, amount0, recipient, unwrapBento);
                balance0 -= amount0;
                amountOut = amount0;
                amount1 = 0;
            }
        }
        _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
        emit Burn(msg.sender, amount0, amount1, recipient);
    }

    /// @dev Swaps one token for another. The router must prefund this contract and ensure there isn't too much slippage.
    function swap(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenIn, address recipient, bool unwrapBento) = abi.decode(data, (address, address, bool));
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = _getReserves();
        require(_reserve0 > 0, "POOL_UNINITIALIZED");
        (uint256 balance0, uint256 balance1) = _balance();
        uint256 amountIn;
        address tokenOut;
        unchecked {
            if (tokenIn == token0) {
                tokenOut = token1;
                amountIn = balance0 - _reserve0;
                amountOut = _getAmountOut(amountIn, _reserve0, _reserve1);
                balance1 -= amountOut;
            } else {
                require(tokenIn == token1, "INVALID_INPUT_TOKEN");
                tokenOut = token0;
                amountIn = balance1 - reserve1;
                amountOut = _getAmountOut(amountIn, _reserve1, _reserve0);
                balance0 -= amountOut;
            }
        }
        _transfer(tokenOut, amountOut, recipient, unwrapBento);
        _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
        emit Swap(recipient, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @dev Swaps one token for another. The router must support swap callbacks and ensure there isn't too much slippage.
    function flashSwap(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenIn, address recipient, bool unwrapBento, uint256 amountIn, bytes memory context) = abi.decode(
            data,
            (address, address, bool, uint256, bytes)
        );
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = _getReserves();
        require(_reserve0 > 0, "POOL_UNINITIALIZED");
        unchecked {
            if (tokenIn == token0) {
                amountOut = _getAmountOut(amountIn, _reserve0, _reserve1);
                _transfer(token1, amountOut, recipient, unwrapBento);
                ITridentCallee(msg.sender).tridentSwapCallback(context);
                (uint256 balance0, uint256 balance1) = _balance();
                require(balance0 - _reserve0 >= amountIn, "INSUFFICIENT_AMOUNT_IN");
                _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
                emit Swap(recipient, tokenIn, token1, amountIn, amountOut);
            } else {
                require(tokenIn == token1, "INVALID_INPUT_TOKEN");
                amountOut = _getAmountOut(amountIn, _reserve1, _reserve0);
                _transfer(token0, amountOut, recipient, unwrapBento);
                ITridentCallee(msg.sender).tridentSwapCallback(context);
                (uint256 balance0, uint256 balance1) = _balance();
                require(balance1 - _reserve1 >= amountIn, "INSUFFICIENT_AMOUNT_IN");
                _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
                emit Swap(recipient, tokenIn, token0, amountIn, amountOut);
            }
        }
    }

    /// @dev Updates `barFee` for Trident protocol.
    function updateBarFee() public {
        barFee = IMasterDeployer(masterDeployer).barFee();
    }

    function _getReserves()
        internal
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _balance() internal view returns (uint256 balance0, uint256 balance1) {
        balance0 = bento.balanceOf(token0, address(this));
        balance1 = bento.balanceOf(token1, address(this));
    }

    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1,
        uint32 _blockTimestampLast
    ) internal {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "OVERFLOW");
        if (_blockTimestampLast == 0) {
            // @dev TWAP support is disabled for gas efficiency.
            reserve0 = uint112(balance0);
            reserve1 = uint112(balance1);
        } else {
            uint32 blockTimestamp = uint32(block.timestamp % 2**32);
            if (blockTimestamp != _blockTimestampLast && _reserve0 != 0 && _reserve1 != 0) {
                unchecked {
                    uint32 timeElapsed = blockTimestamp - _blockTimestampLast;
                    uint256 price0 = (uint256(_reserve1) << PRECISION) / _reserve0;
                    price0CumulativeLast += price0 * timeElapsed;
                    uint256 price1 = (uint256(_reserve0) << PRECISION) / _reserve1;
                    price1CumulativeLast += price1 * timeElapsed;
                }
            }
            reserve0 = uint112(balance0);
            reserve1 = uint112(balance1);
            blockTimestampLast = blockTimestamp;
        }
        emit Sync(balance0, balance1);
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1) internal returns (uint256 _totalSupply, uint256 computed) {
        _totalSupply = totalSupply;
        uint256 _kLast = kLast;
        if (_kLast != 0) {
            computed = TridentMath.sqrt(uint256(_reserve0) * _reserve1);
            if (computed > _kLast) {
                // @dev `barFee` % of increase in liquidity.
                // It's going to be slightly less than `barFee` % in reality due to the math.
                uint256 liquidity = (_totalSupply * (computed - _kLast) * barFee) / computed / MAX_FEE;
                if (liquidity != 0) {
                    _mint(barFeeTo, liquidity);
                    _totalSupply += liquidity;
                }
            }
        }
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveAmountIn,
        uint256 reserveAmountOut
    ) internal view returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * MAX_FEE_MINUS_SWAP_FEE;
        amountOut = (amountInWithFee * reserveAmountOut) / (reserveAmountIn * MAX_FEE + amountInWithFee);
    }

    function _transfer(
        address token,
        uint256 shares,
        address to,
        bool unwrapBento
    ) internal {
        if (unwrapBento) {
            bento.withdraw(token, address(this), to, 0, shares);
        } else {
            bento.transfer(token, address(this), to, shares);
        }
    }

    /// @dev This fee is charged to cover for `swapFee` when users add unbalanced liquidity.
    function _nonOptimalMintFee(
        uint256 _amount0,
        uint256 _amount1,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal view returns (uint256 token0Fee, uint256 token1Fee) {
        if (_reserve0 == 0 || _reserve1 == 0) return (0, 0);
        uint256 amount1Optimal = (_amount0 * _reserve1) / _reserve0;
        if (amount1Optimal <= _amount1) {
            token1Fee = (swapFee * (_amount1 - amount1Optimal)) / (2 * MAX_FEE);
        } else {
            uint256 amount0Optimal = (_amount1 * _reserve0) / _reserve1;
            token0Fee = (swapFee * (_amount0 - amount0Optimal)) / (2 * MAX_FEE);
        }
    }

    function getAssets() public view override returns (address[] memory assets) {
        assets = new address[](2);
        assets[0] = token0;
        assets[1] = token1;
    }

    function getAmountOut(bytes calldata data) public view override returns (uint256 finalAmountOut) {
        (address tokenIn, uint256 amountIn) = abi.decode(data, (address, uint256));
        (uint112 _reserve0, uint112 _reserve1, ) = _getReserves();
        if (tokenIn == token0) {
            finalAmountOut = _getAmountOut(amountIn, _reserve0, _reserve1);
        } else {
            finalAmountOut = _getAmountOut(amountIn, _reserve1, _reserve0);
        }
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        return _getReserves();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./ConstantProductPool.sol";
import "./PoolDeployer.sol";

/// @notice Contract for deploying Trident exchange Constant Product Pool with configurations.
/// @author Mudit Gupta.
contract ConstantProductPoolFactory is PoolDeployer {
    constructor(address _masterDeployer) PoolDeployer(_masterDeployer) {}

    function deployPool(bytes memory _deployData) external returns (address pool) {
        (address tokenA, address tokenB, uint256 swapFee, bool twapSupport) = abi.decode(_deployData, (address, address, uint256, bool));

        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }

        // @dev Strips any extra data.
        _deployData = abi.encode(tokenA, tokenB, swapFee, twapSupport);

        address[] memory tokens = new address[](2);
        tokens[0] = tokenA;
        tokens[1] = tokenB;

        // @dev Salt is not actually needed since `_deployData` is part of creationCode and already contains the salt.
        bytes32 salt = keccak256(_deployData);
        pool = address(new ConstantProductPool{salt: salt}(_deployData, masterDeployer));
        _registerPool(pool, tokens, salt);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @notice Trident pool interface.
interface IPool {
    /// @notice Executes a swap from one token to another.
    /// @dev The input tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that were sent to the user.
    function swap(bytes calldata data) external returns (uint256 finalAmountOut);

    /// @notice Executes a swap from one token to another with a callback.
    /// @dev This function allows borrowing the output tokens and sending the input tokens in the callback.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that were sent to the user.
    function flashSwap(bytes calldata data) external returns (uint256 finalAmountOut);

    /// @notice Mints liquidity tokens.
    /// @param data ABI-encoded params that the pool requires.
    /// @return liquidity The amount of liquidity tokens that were minted for the user.
    function mint(bytes calldata data) external returns (uint256 liquidity);

    /// @notice Burns liquidity tokens.
    /// @dev The input LP tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return withdrawnAmounts The amount of various output tokens that were sent to the user.
    function burn(bytes calldata data) external returns (TokenAmount[] memory withdrawnAmounts);

    /// @notice Burns liquidity tokens for a single output token.
    /// @dev The input LP tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return amountOut The amount of output tokens that were sent to the user.
    function burnSingle(bytes calldata data) external returns (uint256 amountOut);

    /// @return A unique identifier for the pool type.
    function poolIdentifier() external pure returns (bytes32);

    /// @return An array of tokens supported by the pool.
    function getAssets() external view returns (address[] memory);

    /// @notice Simulates a trade and returns the expected output.
    /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that will be sent to the user if the trade is executed.
    function getAmountOut(bytes calldata data) external view returns (uint256 finalAmountOut);

    /// @dev This event must be emitted on all swaps.
    event Swap(address indexed recipient, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    /// @dev This struct frames output tokens for burns.
    struct TokenAmount {
        address token;
        uint256 amount;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;
import "../libraries/RebaseLibrary.sol";

/// @notice Minimal BentoBox vault interface.
/// @dev `token` is aliased as `address` from `IERC20` for simplicity.
interface IBentoBoxMinimal {
    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address, address) external view returns (uint256);

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param token The ERC-20 token.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    /// @dev Helper function to represent shares back into the `token` amount.
    /// @param token The ERC-20 token.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        address token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    /// @notice Registers this contract so that users can approve it for BentoBox.
    function registerProtocol() external;

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param token_ The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount represented in shares.
    function deposit(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param token_ The ERC-20 token to withdraw.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    /// @notice Transfer shares from a user account to another one.
    /// @param token The ERC-20 token to transfer.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param share The amount of `token` in shares.
    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;

    /// @dev Reads the Rebase `totals`from storage for a given token
    function totals(address token) external view returns (Rebase memory total);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident pool deployer interface.
interface IMasterDeployer {
    function barFee() external view returns (uint256);

    function barFeeTo() external view returns (address);

    function bento() external view returns (address);

    function migrator() external view returns (address);

    function deployPool(address factory, bytes calldata deployData) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

interface IMigrator {
    // Return the desired amount of liquidity token that the migrator wants.
    function desiredLiquidity() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident pool callback interface.
interface ITridentCallee {
    function tridentSwapCallback(bytes calldata data) external;

    function tridentMintCallback(bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident sqrt helper library.
library TridentMath {
    /// @notice Calculate sqrt (x) rounding down, where `x` is unsigned 256-bit integer number.
    /// @dev Adapted from https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol, 
    /// © 2019 ABDK Consulting, License-Identifier: BSD-4-Clause.
    /// @param x Unsigned 256-bit integer number.
    /// @return result Sqrt result.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x == 0) result = 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) {
                    xx >>= 128;
                    r <<= 64;
                }
                if (xx >= 0x10000000000000000) {
                    xx >>= 64;
                    r <<= 32;
                }
                if (xx >= 0x100000000) {
                    xx >>= 32;
                    r <<= 16;
                }
                if (xx >= 0x10000) {
                    xx >>= 16;
                    r <<= 8;
                }
                if (xx >= 0x100) {
                    xx >>= 8;
                    r <<= 4;
                }
                if (xx >= 0x10) {
                    xx >>= 4;
                    r <<= 2;
                }
                if (xx >= 0x8) {
                    r <<= 1;
                }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // @dev Seven iterations should be enough.
                uint256 r1 = x / r;
                result = r < r1 ? r : r1;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident pool ERC-20 with EIP-2612 extension.
/// @author Adapted from RariCapital, https://github.com/Rari-Capital/solmate/blob/main/src/erc20/ERC20.sol,
/// License-Identifier: AGPL-3.0-only.
abstract contract TridentERC20 {
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    string public constant name = "Sushi LP Token";
    string public constant symbol = "SLP";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    /// @notice owner -> balance mapping.
    mapping(address => uint256) public balanceOf;
    /// @notice owner -> spender -> allowance mapping.
    mapping(address => mapping(address => uint256)) public allowance;

    /// @notice Chain Id at this contract's deployment.
    uint256 internal immutable DOMAIN_SEPARATOR_CHAIN_ID;
    /// @notice EIP-712 typehash for this contract's domain at deployment.
    bytes32 internal immutable _DOMAIN_SEPARATOR;
    /// @notice EIP-712 typehash for this contract's {permit} struct.
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /// @notice owner -> nonce mapping used in {permit}.
    mapping(address => uint256) public nonces;

    constructor() {
        DOMAIN_SEPARATOR_CHAIN_ID = block.chainid;
        _DOMAIN_SEPARATOR = _calculateDomainSeparator();
    }

    function _calculateDomainSeparator() internal view returns (bytes32 domainSeperator) {
        domainSeperator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /// @notice EIP-712 typehash for this contract's domain.
    function DOMAIN_SEPARATOR() public view returns (bytes32 domainSeperator) {
        domainSeperator = block.chainid == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator();
    }

    /// @notice Approves `amount` from `msg.sender` to be spent by `spender`.
    /// @param spender Address of the party that can pull tokens from `msg.sender`'s account.
    /// @param amount The maximum collective `amount` that `spender` can pull.
    /// @return (bool) Returns 'true' if succeeded.
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `msg.sender` to `recipient`.
    /// @param recipient The address to move tokens to.
    /// @param amount The token `amount` to move.
    /// @return (bool) Returns 'true' if succeeded.
    function transfer(address recipient, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        // @dev This is safe from overflow - the sum of all user
        // balances can't exceed 'type(uint256).max'.
        unchecked {
            balanceOf[recipient] += amount;
        }
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `sender` to `recipient`. Caller needs approval from `from`.
    /// @param sender Address to pull tokens `from`.
    /// @param recipient The address to move tokens to.
    /// @param amount The token `amount` to move.
    /// @return (bool) Returns 'true' if succeeded.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        if (allowance[sender][msg.sender] != type(uint256).max) {
            allowance[sender][msg.sender] -= amount;
        }
        balanceOf[sender] -= amount;
        // @dev This is safe from overflow - the sum of all user
        // balances can't exceed 'type(uint256).max'.
        unchecked {
            balanceOf[recipient] += amount;
        }
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /// @notice Triggers an approval from `owner` to `spender`.
    /// @param owner The address to approve from.
    /// @param spender The address to be approved.
    /// @param amount The number of tokens that are approved (2^256-1 means infinite).
    /// @param deadline The time at which to expire the signature.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline)))
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_PERMIT_SIGNATURE");
        allowance[recoveredAddress][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address recipient, uint256 amount) internal {
        totalSupply += amount;
        // @dev This is safe from overflow - the sum of all user
        // balances can't exceed 'type(uint256).max'.
        unchecked {
            balanceOf[recipient] += amount;
        }
        emit Transfer(address(0), recipient, amount);
    }

    function _burn(address sender, uint256 amount) internal {
        balanceOf[sender] -= amount;
        // @dev This is safe from underflow - users won't ever
        // have a balance larger than `totalSupply`.
        unchecked {
            totalSupply -= amount;
        }
        emit Transfer(sender, address(0), amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(Rebase memory total, uint256 elastic) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(Rebase memory total, uint256 base) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident pool deployer for whitelisted template factories.
/// @author Mudit Gupta.
abstract contract PoolDeployer {
    address public immutable masterDeployer;

    mapping(address => mapping(address => address[])) public pools;
    mapping(bytes32 => address) public configAddress;

    modifier onlyMaster() {
        require(msg.sender == masterDeployer, "UNAUTHORIZED_DEPLOYER");
        _;
    }

    constructor(address _masterDeployer) {
        require(_masterDeployer != address(0), "ZERO_ADDRESS");
        masterDeployer = _masterDeployer;
    }

    function _registerPool(
        address pool,
        address[] memory tokens,
        bytes32 salt
    ) internal onlyMaster {
        // @dev Store the address of the deployed contract.
        configAddress[salt] = pool;
        // @dev Attacker used underflow, it was not very effective. poolimon!
        // null token array would cause deployment to fail via out of bounds memory axis/gas limit.
        unchecked {
            for (uint256 i; i < tokens.length - 1; i++) {
                require(tokens[i] < tokens[i + 1], "INVALID_TOKEN_ORDER");
                for (uint256 j = i + 1; j < tokens.length; j++) {
                    pools[tokens[i]][tokens[j]].push(pool);
                    pools[tokens[j]][tokens[i]].push(pool);
                }
            }
        }
    }

    function poolsCount(address token0, address token1) external view returns (uint256 count) {
        count = pools[token0][token1].length;
    }

    function getPools(
        address token0,
        address token1,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (address[] memory pairPools) {
        pairPools = new address[](endIndex - startIndex);
        for (uint256 i = 0; startIndex < endIndex; i++) {
            pairPools[i] = pools[token0][token1][startIndex];
            startIndex++;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./interfaces/IBentoBoxMinimal.sol";
import "./interfaces/IPool.sol";
import "./interfaces/ITridentRouter.sol";
import "./utils/TridentHelper.sol";
import "./deployer/MasterDeployer.sol";

//

/// @notice Router contract that helps in swapping across Trident pools.
contract TridentRouter is ITridentRouter, TridentHelper {
    /// @notice BentoBox token vault.
    IBentoBoxMinimal public immutable bento;
    MasterDeployer public immutable masterDeployer;

    /// @dev Used to ensure that `tridentSwapCallback` is called only by the authorized address.
    /// These are set when someone calls a flash swap and reset afterwards.
    address internal cachedMsgSender;
    address internal cachedPool;

    mapping(address => bool) internal whitelistedPools;

    constructor(
        IBentoBoxMinimal _bento,
        MasterDeployer _masterDeployer,
        address _wETH
    ) TridentHelper(_wETH) {
        _bento.registerProtocol();
        bento = _bento;
        masterDeployer = _masterDeployer;
    }

    receive() external payable {
        require(msg.sender == wETH);
    }

    /// @notice Swaps token A to token B directly. Swaps are done on `bento` tokens.
    /// @param params This includes the address of token A, pool, amount of token A to swap,
    /// minimum amount of token B after the swap and data required by the pool for the swap.
    /// @dev Ensure that the pool is trusted before calling this function. The pool can steal users' tokens.
    function exactInputSingle(ExactInputSingleParams calldata params) public payable returns (uint256 amountOut) {
        // @dev Prefund the pool with token A.
        bento.transfer(params.tokenIn, msg.sender, params.pool, params.amountIn);
        // @dev Trigger the swap in the pool.
        amountOut = IPool(params.pool).swap(params.data);
        // @dev Ensure that the slippage wasn't too much. This assumes that the pool is honest.
        require(amountOut >= params.amountOutMinimum, "TOO_LITTLE_RECEIVED");
    }

    /// @notice Swaps token A to token B indirectly by using multiple hops.
    /// @param params This includes the addresses of the tokens, pools, amount of token A to swap,
    /// minimum amount of token B after the swap and data required by the pools for the swaps.
    /// @dev Ensure that the pools are trusted before calling this function. The pools can steal users' tokens.
    function exactInput(ExactInputParams calldata params) public payable returns (uint256 amountOut) {
        // @dev Pay the first pool directly.
        bento.transfer(params.tokenIn, msg.sender, params.path[0].pool, params.amountIn);
        // @dev Call every pool in the path.
        // Pool `N` should transfer its output tokens to pool `N+1` directly.
        // The last pool should transfer its output tokens to the user.
        // If the user wants to unwrap `wETH`, the final destination should be this contract and
        // a batch call should be made to `unwrapWETH`.
        for (uint256 i; i < params.path.length; i++) {
            // We don't necessarily need this check but saving users from themselves.
            isWhiteListed(params.path[i].pool);
            amountOut = IPool(params.path[i].pool).swap(params.path[i].data);
        }
        // @dev Ensure that the slippage wasn't too much. This assumes that the pool is honest.
        require(amountOut >= params.amountOutMinimum, "TOO_LITTLE_RECEIVED");
    }

    /// @notice Swaps token A to token B by using callbacks.
    /// @param path Addresses of the pools and data required by the pools for the swaps.
    /// @param amountOutMinimum Minimum amount of token B after the swap.
    /// @dev Ensure that the pools are trusted before calling this function. The pools can steal users' tokens.
    /// This function will unlikely be used in production but it shows how to use callbacks. One use case will be arbitrage.
    function exactInputLazy(uint256 amountOutMinimum, Path[] calldata path) public payable returns (uint256 amountOut) {
        // @dev Call every pool in the path.
        // Pool `N` should transfer its output tokens to pool `N+1` directly.
        // The last pool should transfer its output tokens to the user.
        for (uint256 i; i < path.length; i++) {
            isWhiteListed(path[i].pool);
            // @dev The cached `msg.sender` is used as the funder when the callback happens.
            cachedMsgSender = msg.sender;
            // @dev The cached pool must be the address that calls the callback.
            cachedPool = path[i].pool;
            amountOut = IPool(path[i].pool).flashSwap(path[i].data);
        }
        // @dev Resets the `cachedPool` to get a refund.
        // `1` is used as the default value to avoid the storage slot being released.
        cachedMsgSender = address(1);
        cachedPool = address(1);
        require(amountOut >= amountOutMinimum, "TOO_LITTLE_RECEIVED");
    }

    /// @notice Swaps token A to token B directly. It's the same as `exactInputSingle` except
    /// it takes raw ERC-20 tokens from the users and deposits them into `bento`.
    /// @param params This includes the address of token A, pool, amount of token A to swap,
    /// minimum amount of token B after the swap and data required by the pool for the swap.
    /// @dev Ensure that the pool is trusted before calling this function. The pool can steal users' tokens.
    function exactInputSingleWithNativeToken(ExactInputSingleParams calldata params) public payable returns (uint256 amountOut) {
        // @dev Deposits the native ERC-20 token from the user into the pool's `bento`.
        _depositToBentoBox(params.tokenIn, params.pool, params.amountIn);
        // @dev Trigger the swap in the pool.
        amountOut = IPool(params.pool).swap(params.data);
        // @dev Ensure that the slippage wasn't too much. This assumes that the pool is honest.
        require(amountOut >= params.amountOutMinimum, "TOO_LITTLE_RECEIVED");
    }

    /// @notice Swaps token A to token B indirectly by using multiple hops. It's the same as `exactInput` except
    /// it takes raw ERC-20 tokens from the users and deposits them into `bento`.
    /// @param params This includes the addresses of the tokens, pools, amount of token A to swap,
    /// minimum amount of token B after the swap and data required by the pools for the swaps.
    /// @dev Ensure that the pools are trusted before calling this function. The pools can steal users' tokens.
    function exactInputWithNativeToken(ExactInputParams calldata params) public payable returns (uint256 amountOut) {
        // @dev Deposits the native ERC-20 token from the user into the pool's `bento`.
        _depositToBentoBox(params.tokenIn, params.path[0].pool, params.amountIn);
        // @dev Call every pool in the path.
        // Pool `N` should transfer its output tokens to pool `N+1` directly.
        // The last pool should transfer its output tokens to the user.
        for (uint256 i; i < params.path.length; i++) {
            isWhiteListed(params.path[i].pool);
            amountOut = IPool(params.path[i].pool).swap(params.path[i].data);
        }
        // @dev Ensure that the slippage wasn't too much. This assumes that the pool is honest.
        require(amountOut >= params.amountOutMinimum, "TOO_LITTLE_RECEIVED");
    }

    /// @notice Swaps multiple input tokens to multiple output tokens using multiple paths, in different percentages.
    /// For example, you can swap 50 DAI + 100 USDC into 60% ETH and 40% BTC.
    /// @param params This includes everything needed for the swap. Look at the `ComplexPathParams` struct for more details.
    /// @dev This function is not optimized for single swaps and should only be used in complex cases where
    /// the amounts are large enough that minimizing slippage by using multiple paths is worth the extra gas.
    function complexPath(ComplexPathParams calldata params) public payable {
        // @dev Deposit all initial tokens to respective pools and initiate the swaps.
        // Input tokens come from the user - output goes to following pools.
        for (uint256 i; i < params.initialPath.length; i++) {
            if (params.initialPath[i].native) {
                _depositToBentoBox(params.initialPath[i].tokenIn, params.initialPath[i].pool, params.initialPath[i].amount);
            } else {
                bento.transfer(params.initialPath[i].tokenIn, msg.sender, params.initialPath[i].pool, params.initialPath[i].amount);
            }
            isWhiteListed(params.initialPath[i].pool);
            IPool(params.initialPath[i].pool).swap(params.initialPath[i].data);
        }
        // @dev Do all the middle swaps. Input comes from previous pools - output goes to following pools.
        for (uint256 i; i < params.percentagePath.length; i++) {
            uint256 balanceShares = bento.balanceOf(params.percentagePath[i].tokenIn, address(this));
            uint256 transferShares = (balanceShares * params.percentagePath[i].balancePercentage) / uint256(10)**8;
            bento.transfer(params.percentagePath[i].tokenIn, address(this), params.percentagePath[i].pool, transferShares);
            isWhiteListed(params.percentagePath[i].pool);
            IPool(params.percentagePath[i].pool).swap(params.percentagePath[i].data);
        }
        // @dev Do all the final swaps. Input comes from previous pools - output goes to the user.
        for (uint256 i; i < params.output.length; i++) {
            uint256 balanceShares = bento.balanceOf(params.output[i].token, address(this));
            require(balanceShares >= params.output[i].minAmount, "TOO_LITTLE_RECEIVED");
            if (params.output[i].unwrapBento) {
                bento.withdraw(params.output[i].token, address(this), params.output[i].to, 0, balanceShares);
            } else {
                bento.transfer(params.output[i].token, address(this), params.output[i].to, balanceShares);
            }
        }
    }

    /// @notice Add liquidity to a pool.
    /// @param tokenInput Token address and amount to add as liquidity.
    /// @param pool Pool address to add liquidity to.
    /// @param minLiquidity Minimum output liquidity - caps slippage.
    /// @param data Data required by the pool to add liquidity.
    function addLiquidity(
        TokenInput[] memory tokenInput,
        address pool,
        uint256 minLiquidity,
        bytes calldata data
    ) public payable returns (uint256 liquidity) {
        isWhiteListed(pool);
        // @dev Send all input tokens to the pool.
        for (uint256 i; i < tokenInput.length; i++) {
            if (tokenInput[i].native) {
                _depositToBentoBox(tokenInput[i].token, pool, tokenInput[i].amount);
            } else {
                bento.transfer(tokenInput[i].token, msg.sender, pool, tokenInput[i].amount);
            }
        }
        liquidity = IPool(pool).mint(data);
        require(liquidity >= minLiquidity, "NOT_ENOUGH_LIQUIDITY_MINTED");
    }

    /// @notice Add liquidity to a pool using callbacks - same as `addLiquidity`, but now with callbacks.
    /// @dev The input tokens are sent to the pool during the callback.
    function addLiquidityLazy(
        address pool,
        uint256 minLiquidity,
        bytes calldata data
    ) public payable returns (uint256 liquidity) {
        isWhiteListed(pool);
        cachedMsgSender = msg.sender;
        cachedPool = pool;
        // @dev The pool must ensure that there's not too much slippage.
        liquidity = IPool(pool).mint(data);
        cachedMsgSender = address(1);
        cachedPool = address(1);
        require(liquidity >= minLiquidity, "NOT_ENOUGH_LIQUIDITY_MINTED");
    }

    /// @notice Burn liquidity tokens to get back `bento` tokens.
    /// @param pool Pool address.
    /// @param liquidity Amount of liquidity tokens to burn.
    /// @param data Data required by the pool to burn liquidity.
    /// @param minWithdrawals Minimum amount of `bento` tokens to be returned.
    function burnLiquidity(
        address pool,
        uint256 liquidity,
        bytes calldata data,
        IPool.TokenAmount[] memory minWithdrawals
    ) public {
        isWhiteListed(pool);
        safeTransferFrom(pool, msg.sender, pool, liquidity);
        IPool.TokenAmount[] memory withdrawnLiquidity = IPool(pool).burn(data);
        for (uint256 i; i < minWithdrawals.length; i++) {
            uint256 j;
            for (; j < withdrawnLiquidity.length; j++) {
                if (withdrawnLiquidity[j].token == minWithdrawals[i].token) {
                    require(withdrawnLiquidity[j].amount >= minWithdrawals[i].amount, "TOO_LITTLE_RECEIVED");
                    break;
                }
            }
            // @dev A token that is present in `minWithdrawals` is missing from `withdrawnLiquidity`.
            require(j < withdrawnLiquidity.length, "INCORRECT_TOKEN_WITHDRAWN");
        }
    }

    /// @notice Burn liquidity tokens to get back `bento` tokens.
    /// @dev The tokens are swapped automatically and the output is in a single token.
    /// @param pool Pool address.
    /// @param liquidity Amount of liquidity tokens to burn.
    /// @param data Data required by the pool to burn liquidity.
    /// @param minWithdrawal Minimum amount of tokens to be returned.
    function burnLiquiditySingle(
        address pool,
        uint256 liquidity,
        bytes calldata data,
        uint256 minWithdrawal
    ) public {
        isWhiteListed(pool);
        // @dev Use 'liquidity = 0' for prefunding.
        safeTransferFrom(pool, msg.sender, pool, liquidity);
        uint256 withdrawn = IPool(pool).burnSingle(data);
        require(withdrawn >= minWithdrawal, "TOO_LITTLE_RECEIVED");
    }

    /// @notice Used by the pool 'flashSwap' functionality to take input tokens from the user.
    function tridentSwapCallback(bytes calldata data) external {
        require(msg.sender == cachedPool, "UNAUTHORIZED_CALLBACK");
        TokenInput memory tokenInput = abi.decode(data, (TokenInput));
        // @dev Transfer the requested tokens to the pool.
        if (tokenInput.native) {
            _depositFromUserToBentoBox(tokenInput.token, cachedMsgSender, msg.sender, tokenInput.amount);
        } else {
            bento.transfer(tokenInput.token, cachedMsgSender, msg.sender, tokenInput.amount);
        }
        // @dev Resets the `msg.sender`'s authorization.
        cachedMsgSender = address(1);
    }

    /// @notice Can be used by the pool 'mint' functionality to take tokens from the user.
    function tridentMintCallback(bytes calldata data) external {
        require(msg.sender == cachedPool, "UNAUTHORIZED_CALLBACK");
        TokenInput[] memory tokenInput = abi.decode(data, (TokenInput[]));
        // @dev Transfer the requested tokens to the pool.
        for (uint256 i; i < tokenInput.length; i++) {
            if (tokenInput[i].native) {
                _depositFromUserToBentoBox(tokenInput[i].token, cachedMsgSender, msg.sender, tokenInput[i].amount);
            } else {
                bento.transfer(tokenInput[i].token, cachedMsgSender, msg.sender, tokenInput[i].amount);
            }
        }
        // @dev Resets the `msg.sender`'s authorization.
        cachedMsgSender = address(1);
    }

    /// @notice Recover mistakenly sent `bento` tokens.
    function sweepBentoBoxToken(
        address token,
        uint256 amount,
        address recipient
    ) external {
        bento.transfer(token, address(this), recipient, amount);
    }

    /// @notice Recover mistakenly sent ERC-20 tokens.
    function sweepNativeToken(
        address token,
        uint256 amount,
        address recipient
    ) external {
        safeTransfer(token, recipient, amount);
    }

    /// @notice Recover mistakenly sent ETH.
    function refundETH() external payable {
        if (address(this).balance != 0) safeTransferETH(msg.sender, address(this).balance);
    }

    /// @notice Unwrap this contract's `wETH` into ETH
    function unwrapWETH(uint256 amountMinimum, address recipient) external {
        uint256 balanceWETH = balanceOfThis(wETH);
        require(balanceWETH >= amountMinimum, "INSUFFICIENT_WETH");
        if (balanceWETH != 0) {
            withdrawFromWETH(balanceWETH);
            safeTransferETH(recipient, balanceWETH);
        }
    }

    function deployPool(address _factory, bytes calldata _deployData) external returns (address) {
        return masterDeployer.deployPool(_factory, _deployData);
    }

    function _depositToBentoBox(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        if (token == wETH && address(this).balance != 0) {
            uint256 underlyingAmount = bento.toAmount(wETH, amount, true);
            if (address(this).balance >= underlyingAmount) {
                // @dev Deposit ETH into `recipient` `bento` account.
                bento.deposit{value: underlyingAmount}(address(0), address(this), recipient, 0, amount);
                return;
            }
        }
        // @dev Deposit ERC-20 token into `recipient` `bento` account.
        bento.deposit(token, msg.sender, recipient, 0, amount);
    }

    function _depositFromUserToBentoBox(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (token == wETH && address(this).balance != 0) {
            uint256 underlyingAmount = bento.toAmount(wETH, amount, true);
            if (address(this).balance >= underlyingAmount) {
                // @dev Deposit ETH into `recipient` `bento` account.
                bento.deposit{value: underlyingAmount}(address(0), address(this), recipient, 0, amount);
                return;
            }
        }
        // @dev Deposit ERC-20 token into `recipient` `bento` account.
        bento.deposit(token, sender, recipient, 0, amount);
    }

    function isWhiteListed(address pool) internal {
        if (!whitelistedPools[pool]) {
            require(masterDeployer.pools(pool), "INVALID POOL");
            whitelistedPools[pool] = true;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident pool router interface.
interface ITridentRouter {
    struct Path {
        address pool;
        bytes data;
    }

    struct ExactInputSingleParams {
        uint256 amountIn;
        uint256 amountOutMinimum;
        address pool;
        address tokenIn;
        bytes data;
    }

    struct ExactInputParams {
        address tokenIn;
        uint256 amountIn;
        uint256 amountOutMinimum;
        Path[] path;
    }

    struct TokenInput {
        address token;
        bool native;
        uint256 amount;
    }

    struct InitialPath {
        address tokenIn;
        address pool;
        bool native;
        uint256 amount;
        bytes data;
    }

    struct PercentagePath {
        address tokenIn;
        address pool;
        uint64 balancePercentage; // @dev Multiplied by 10^6. 100% = 100_000_000
        bytes data;
    }

    struct Output {
        address token;
        address to;
        bool unwrapBento;
        uint256 minAmount;
    }

    struct ComplexPathParams {
        InitialPath[] initialPath;
        PercentagePath[] percentagePath;
        Output[] output;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../TridentRouter.sol";

/// @notice Trident router helper contract.
contract TridentHelper {
    /// @notice ERC-20 token for wrapped ETH (v9).
    address internal immutable wETH;

    constructor(address _wETH) {
        wETH = _wETH;
    }

    /// @notice Provides batch function calls for this contract and returns the data from all of them if they all succeed.
    /// Adapted from https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/base/Multicall.sol, License-Identifier: GPL-2.0-or-later.
    /// @dev The `msg.value` should not be trusted for any method callable from this function.
    /// @param data ABI-encoded params for each of the calls to make to this contract.
    /// @return results The results from each of the calls passed in via `data`.
    function batch(bytes[] calldata data) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        // We only allow one exactInputSingle call to be made in a single batch call.
        // This is not really needed but we want to save users from signing malicious payloads.
        // We also don't want nested batch calls.
        bool swapCalled;
        for (uint256 i = 0; i < data.length; i++) {
            bytes4 selector = getSelector(data[i]);
            if (selector == TridentRouter.exactInputSingle.selector || selector == TridentRouter.exactInputSingleWithNativeToken.selector) {
                require(!swapCalled, "Swap called twice");
                swapCalled = true;
            } else {
                require(selector != this.batch.selector, "Nested Batch");
            }

            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            if (!success) {
                // @dev Next 5 lines from https://ethereum.stackexchange.com/a/83577.
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
            results[i] = result;
        }
    }

    /// @notice Provides gas-optimized balance check on this contract to avoid redundant extcodesize check in addition to returndatasize check.
    /// @param token Address of ERC-20 token.
    /// @return balance Token amount held by this contract.
    function balanceOfThis(address token) internal view returns (uint256 balance) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(0x70a08231, address(this))); // @dev balanceOf(address).
        require(success && data.length >= 32, "BALANCE_OF_FAILED");
        balance = abi.decode(data, (uint256));
    }

    /// @notice Provides EIP-2612 signed approval for this contract to spend user tokens.
    /// @param token Address of ERC-20 token.
    /// @param amount Token amount to grant spending right over.
    /// @param deadline Termination for signed approval (UTC timestamp in seconds).
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function permitThis(
        address token,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        (bool success, ) = token.call(abi.encodeWithSelector(0xd505accf, msg.sender, address(this), amount, deadline, v, r, s)); // @dev permit(address,address,uint256,uint256,uint8,bytes32,bytes32).
        require(success, "PERMIT_FAILED");
    }

    /// @notice Provides DAI-derived signed approval for this contract to spend user tokens.
    /// @param token Address of ERC-20 token.
    /// @param nonce Token owner's nonce - increases at each call to {permit}.
    /// @param expiry Termination for signed approval - UTC timestamp in seconds.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function permitThisAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        (bool success, ) = token.call(abi.encodeWithSelector(0x8fcbaf0c, msg.sender, address(this), nonce, expiry, true, v, r, s)); // @dev permit(address,address,uint256,uint256,bool,uint8,bytes32,bytes32).
        require(success, "PERMIT_FAILED");
    }

    /// @notice Provides 'safe' ERC-20 {transfer} for tokens that don't consistently return true/false.
    /// @param token Address of ERC-20 token.
    /// @param recipient Account to send tokens to.
    /// @param amount Token amount to send.
    function safeTransfer(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, recipient, amount)); // @dev transfer(address,uint256).
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    /// @notice Provides 'safe' ERC-20 {transferFrom} for tokens that don't consistently return true/false.
    /// @param token Address of ERC-20 token.
    /// @param sender Account to send tokens from.
    /// @param recipient Account to send tokens to.
    /// @param amount Token amount to send.
    function safeTransferFrom(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, sender, recipient, amount)); // @dev transferFrom(address,address,uint256).
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    /// @notice Provides low-level `wETH` {withdraw}.
    /// @param amount Token amount to unwrap into ETH.
    function withdrawFromWETH(uint256 amount) internal {
        (bool success, ) = wETH.call(abi.encodeWithSelector(0x2e1a7d4d, amount)); // @dev withdraw(uint256).
        require(success, "WITHDRAW_FROM_WETH_FAILED");
    }

    /// @notice Provides 'safe' ETH transfer.
    /// @param recipient Account to send ETH to.
    /// @param amount ETH amount to send.
    function safeTransferETH(address recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH_TRANSFER_FAILED");
    }

    /**
     * @notice function to extract the selector of a bytes calldata
     * @param _data the calldata bytes
     */
    function getSelector(bytes memory _data) internal pure returns (bytes4 sig) {
        assembly {
            sig := mload(add(_data, 32))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../interfaces/IBentoBoxMinimal.sol";
import "../interfaces/IMasterDeployer.sol";
import "../interfaces/IPool.sol";
import "../interfaces/ITridentCallee.sol";
import "./TridentERC20.sol";

/// @notice Trident exchange pool template with constant mean formula for swapping among an array of ERC-20 tokens.
/// @dev The reserves are stored as bento shares.
///      The curve is applied to shares as well. This pool does not care about the underlying amounts.
contract IndexPool is IPool, TridentERC20 {
    event Mint(address indexed sender, address tokenIn, uint256 amountIn, address indexed recipient);
    event Burn(address indexed sender, address tokenOut, uint256 amountOut, address indexed recipient);

    uint256 public immutable swapFee;

    address public immutable barFeeTo;
    IBentoBoxMinimal public immutable bento;
    IMasterDeployer public immutable masterDeployer;

    uint256 internal constant BASE = 10**18;
    uint256 internal constant MIN_TOKENS = 2;
    uint256 internal constant MAX_TOKENS = 8;
    uint256 internal constant MIN_FEE = BASE / 10**6;
    uint256 internal constant MAX_FEE = BASE / 10;
    uint256 internal constant MIN_WEIGHT = BASE;
    uint256 internal constant MAX_WEIGHT = BASE * 50;
    uint256 internal constant MAX_TOTAL_WEIGHT = BASE * 50;
    uint256 internal constant MIN_BALANCE = BASE / 10**12;
    uint256 internal constant INIT_POOL_SUPPLY = BASE * 100;
    uint256 internal constant MIN_POW_BASE = 1;
    uint256 internal constant MAX_POW_BASE = (2 * BASE) - 1;
    uint256 internal constant POW_PRECISION = BASE / 10**10;
    uint256 internal constant MAX_IN_RATIO = BASE / 2;
    uint256 internal constant MAX_OUT_RATIO = (BASE / 3) + 1;

    uint136 internal totalWeight;
    address[] internal tokens;

    uint256 public barFee;

    bytes32 public constant override poolIdentifier = "Trident:Index";

    uint256 internal unlocked;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 2;
        _;
        unlocked = 1;
    }

    mapping(address => Record) public records;
    struct Record {
        uint120 reserve;
        uint136 weight;
    }

    constructor(bytes memory _deployData, address _masterDeployer) {
        (address[] memory _tokens, uint136[] memory _weights, uint256 _swapFee) = abi.decode(_deployData, (address[], uint136[], uint256));
        // @dev Factory ensures that the tokens are sorted.
        require(_tokens.length == _weights.length, "INVALID_ARRAYS");
        require(MIN_FEE <= _swapFee && _swapFee <= MAX_FEE, "INVALID_SWAP_FEE");
        require(MIN_TOKENS <= _tokens.length && _tokens.length <= MAX_TOKENS, "INVALID_TOKENS_LENGTH");

        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_tokens[i] != address(0), "ZERO_ADDRESS");
            require(MIN_WEIGHT <= _weights[i] && _weights[i] <= MAX_WEIGHT, "INVALID_WEIGHT");
            records[_tokens[i]] = Record({reserve: 0, weight: _weights[i]});
            tokens.push(_tokens[i]);
            totalWeight += _weights[i];
        }

        require(totalWeight <= MAX_TOTAL_WEIGHT, "MAX_TOTAL_WEIGHT");
        // @dev This burns initial LP supply.
        _mint(address(0), INIT_POOL_SUPPLY);

        swapFee = _swapFee;
        barFee = IMasterDeployer(_masterDeployer).barFee();
        barFeeTo = IMasterDeployer(_masterDeployer).barFeeTo();
        bento = IBentoBoxMinimal(IMasterDeployer(_masterDeployer).bento());
        masterDeployer = IMasterDeployer(_masterDeployer);
        unlocked = 1;
    }

    /// @dev Mints LP tokens - should be called via the router after transferring `bento` tokens.
    /// The router must ensure that sufficient LP tokens are minted by using the return value.
    function mint(bytes calldata data) public override lock returns (uint256 liquidity) {
        (address recipient, uint256 toMint) = abi.decode(data, (address, uint256));

        uint120 ratio = uint120(_div(toMint, totalSupply));

        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenIn = tokens[i];
            uint120 reserve = records[tokenIn].reserve;
            // @dev If token balance is '0', initialize with `ratio`.
            uint120 amountIn = reserve != 0 ? uint120(_mul(ratio, reserve)) : ratio;
            require(amountIn >= MIN_BALANCE, "MIN_BALANCE");
            // @dev Check Trident router has sent `amountIn` for skim into pool.
            unchecked {
                // @dev This is safe from overflow - only logged amounts handled.
                require(_balance(tokenIn) >= amountIn + reserve, "NOT_RECEIVED");
                records[tokenIn].reserve += amountIn;
            }
            emit Mint(msg.sender, tokenIn, amountIn, recipient);
        }
        _mint(recipient, toMint);
        liquidity = toMint;
    }

    /// @dev Burns LP tokens sent to this contract. The router must ensure that the user gets sufficient output tokens.
    function burn(bytes calldata data) public override lock returns (IPool.TokenAmount[] memory withdrawnAmounts) {
        (address recipient, bool unwrapBento, uint256 toBurn) = abi.decode(data, (address, bool, uint256));

        uint256 ratio = _div(toBurn, totalSupply);

        withdrawnAmounts = new TokenAmount[](tokens.length);

        _burn(address(this), toBurn);

        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenOut = tokens[i];
            uint256 balance = records[tokenOut].reserve;
            uint120 amountOut = uint120(_mul(ratio, balance));
            require(amountOut != 0, "ZERO_OUT");
            // @dev This is safe from underflow - only logged amounts handled.
            unchecked {
                records[tokenOut].reserve -= amountOut;
            }
            _transfer(tokenOut, amountOut, recipient, unwrapBento);
            withdrawnAmounts[i] = TokenAmount({token: tokenOut, amount: amountOut});
            emit Burn(msg.sender, tokenOut, amountOut, recipient);
        }
    }

    /// @dev Burns LP tokens sent to this contract and swaps one of the output tokens for another
    /// - i.e., the user gets a single token out by burning LP tokens.
    function burnSingle(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenOut, address recipient, bool unwrapBento, uint256 toBurn) = abi.decode(data, (address, address, bool, uint256));

        Record storage outRecord = records[tokenOut];

        amountOut = _computeSingleOutGivenPoolIn(outRecord.reserve, outRecord.weight, totalSupply, totalWeight, toBurn, swapFee);

        require(amountOut <= _mul(outRecord.reserve, MAX_OUT_RATIO), "MAX_OUT_RATIO");
        // @dev This is safe from underflow - only logged amounts handled.
        unchecked {
            outRecord.reserve -= uint120(amountOut);
        }
        _burn(address(this), toBurn);
        _transfer(tokenOut, amountOut, recipient, unwrapBento);
        emit Burn(msg.sender, tokenOut, amountOut, recipient);
    }

    /// @dev Swaps one token for another. The router must prefund this contract and ensure there isn't too much slippage.
    function swap(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenIn, address tokenOut, address recipient, bool unwrapBento, uint256 amountIn) = abi.decode(
            data,
            (address, address, address, bool, uint256)
        );

        Record storage inRecord = records[tokenIn];
        Record storage outRecord = records[tokenOut];

        require(amountIn <= _mul(inRecord.reserve, MAX_IN_RATIO), "MAX_IN_RATIO");

        amountOut = _getAmountOut(amountIn, inRecord.reserve, inRecord.weight, outRecord.reserve, outRecord.weight);
        // @dev Check Trident router has sent `amountIn` for skim into pool.
        unchecked {
            // @dev This is safe from under/overflow - only logged amounts handled.
            require(_balance(tokenIn) >= amountIn + inRecord.reserve, "NOT_RECEIVED");
            inRecord.reserve += uint120(amountIn);
            outRecord.reserve -= uint120(amountOut);
        }
        _transfer(tokenOut, amountOut, recipient, unwrapBento);
        emit Swap(recipient, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @dev Swaps one token for another. The router must support swap callbacks and ensure there isn't too much slippage.
    function flashSwap(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenIn, address tokenOut, address recipient, bool unwrapBento, uint256 amountIn, bytes memory context) = abi.decode(
            data,
            (address, address, address, bool, uint256, bytes)
        );

        Record storage inRecord = records[tokenIn];
        Record storage outRecord = records[tokenOut];

        require(amountIn <= _mul(inRecord.reserve, MAX_IN_RATIO), "MAX_IN_RATIO");

        amountOut = _getAmountOut(amountIn, inRecord.reserve, inRecord.weight, outRecord.reserve, outRecord.weight);

        ITridentCallee(msg.sender).tridentSwapCallback(context);
        // @dev Check Trident router has sent `amountIn` for skim into pool.
        unchecked {
            // @dev This is safe from under/overflow - only logged amounts handled.
            require(_balance(tokenIn) >= amountIn + inRecord.reserve, "NOT_RECEIVED");
            inRecord.reserve += uint120(amountIn);
            outRecord.reserve -= uint120(amountOut);
        }
        _transfer(tokenOut, amountOut, recipient, unwrapBento);
        emit Swap(recipient, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @dev Updates `barFee` for Trident protocol.
    function updateBarFee() public {
        barFee = IMasterDeployer(masterDeployer).barFee();
    }

    function _balance(address token) internal view returns (uint256 balance) {
        balance = bento.balanceOf(token, address(this));
    }

    function _getAmountOut(
        uint256 tokenInAmount,
        uint256 tokenInBalance,
        uint256 tokenInWeight,
        uint256 tokenOutBalance,
        uint256 tokenOutWeight
    ) internal view returns (uint256 amountOut) {
        uint256 weightRatio = _div(tokenInWeight, tokenOutWeight);
        // @dev This is safe from under/overflow - only logged amounts handled.
        unchecked {
            uint256 adjustedIn = _mul(tokenInAmount, (BASE - swapFee));
            uint256 a = _div(tokenInBalance, tokenInBalance + adjustedIn);
            uint256 b = _compute(a, weightRatio);
            uint256 c = BASE - b;
            amountOut = _mul(tokenOutBalance, c);
        }
    }

    function _compute(uint256 base, uint256 exp) internal pure returns (uint256 output) {
        require(MIN_POW_BASE <= base && base <= MAX_POW_BASE, "INVALID_BASE");

        uint256 whole = (exp / BASE) * BASE;
        uint256 remain = exp - whole;
        uint256 wholePow = _pow(base, whole / BASE);

        if (remain == 0) output = wholePow;

        uint256 partialResult = _powApprox(base, remain, POW_PRECISION);
        output = _mul(wholePow, partialResult);
    }

    function _computeSingleOutGivenPoolIn(
        uint256 tokenOutBalance,
        uint256 tokenOutWeight,
        uint256 _totalSupply,
        uint256 _totalWeight,
        uint256 toBurn,
        uint256 _swapFee
    ) internal pure returns (uint256 amountOut) {
        uint256 normalizedWeight = _div(tokenOutWeight, _totalWeight);
        uint256 newPoolSupply = _totalSupply - toBurn;
        uint256 poolRatio = _div(newPoolSupply, _totalSupply);
        uint256 tokenOutRatio = _pow(poolRatio, _div(BASE, normalizedWeight));
        uint256 newBalanceOut = _mul(tokenOutRatio, tokenOutBalance);
        uint256 tokenAmountOutBeforeSwapFee = tokenOutBalance - newBalanceOut;
        uint256 zaz = (BASE - normalizedWeight) * _swapFee;
        amountOut = _mul(tokenAmountOutBeforeSwapFee, (BASE - zaz));
    }

    function _pow(uint256 a, uint256 n) internal pure returns (uint256 output) {
        output = n % 2 != 0 ? a : BASE;
        for (n /= 2; n != 0; n /= 2) a = a * a;
        if (n % 2 != 0) output = output * a;
    }

    function _powApprox(
        uint256 base,
        uint256 exp,
        uint256 precision
    ) internal pure returns (uint256 sum) {
        uint256 a = exp;
        (uint256 x, bool xneg) = _subFlag(base, BASE);
        uint256 term = BASE;
        sum = term;
        bool negative;

        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * BASE;
            (uint256 c, bool cneg) = _subFlag(a, (bigK - BASE));
            term = _mul(term, _mul(c, x));
            term = _div(term, bigK);
            if (term == 0) break;
            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = sum - term;
            } else {
                sum = sum + term;
            }
        }
    }

    function _subFlag(uint256 a, uint256 b) internal pure returns (uint256 difference, bool flag) {
        // @dev This is safe from underflow - if/else flow performs checks.
        unchecked {
            if (a >= b) {
                (difference, flag) = (a - b, false);
            } else {
                (difference, flag) = (b - a, true);
            }
        }
    }

    function _mul(uint256 a, uint256 b) internal pure returns (uint256 c2) {
        uint256 c0 = a * b;
        uint256 c1 = c0 + (BASE / 2);
        c2 = c1 / BASE;
    }

    function _div(uint256 a, uint256 b) internal pure returns (uint256 c2) {
        uint256 c0 = a * BASE;
        uint256 c1 = c0 + (b / 2);
        c2 = c1 / b;
    }

    function _transfer(
        address token,
        uint256 shares,
        address to,
        bool unwrapBento
    ) internal {
        if (unwrapBento) {
            bento.withdraw(token, address(this), to, 0, shares);
        } else {
            bento.transfer(token, address(this), to, shares);
        }
    }

    function getAssets() public view override returns (address[] memory assets) {
        assets = tokens;
    }

    function getAmountOut(bytes calldata data) public view override returns (uint256 amountOut) {
        (uint256 tokenInAmount, uint256 tokenInBalance, uint256 tokenInWeight, uint256 tokenOutBalance, uint256 tokenOutWeight) = abi.decode(
            data,
            (uint256, uint256, uint256, uint256, uint256)
        );
        amountOut = _getAmountOut(tokenInAmount, tokenInBalance, tokenInWeight, tokenOutBalance, tokenOutWeight);
    }

    function getReservesAndWeights() public view returns (uint256[] memory reserves, uint136[] memory weights) {
        uint256 length = tokens.length;
        reserves = new uint256[](length);
        weights = new uint136[](length);
        // @dev This is safe from overflow - `tokens` `length` is bound to '8'.
        unchecked {
            for (uint256 i = 0; i < length; i++) {
                reserves[i] = records[tokens[i]].reserve;
                weights[i] = records[tokens[i]].weight;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./IndexPool.sol";
import "./PoolDeployer.sol";

/// @notice Contract for deploying Trident exchange Index Pool with configurations.
/// @author Mudit Gupta
contract IndexPoolFactory is PoolDeployer {
    constructor(address _masterDeployer) PoolDeployer(_masterDeployer) {}

    function deployPool(bytes memory _deployData) external returns (address pool) {
        (address[] memory tokens, uint136[] memory weights, uint256 swapFee) = abi.decode(_deployData, (address[], uint136[], uint256));

        // @dev Strips any extra data.
        _deployData = abi.encode(tokens, weights, swapFee);

        // @dev Salt is not actually needed since `_deployData` is part of creationCode and already contains the salt.
        bytes32 salt = keccak256(_deployData);
        pool = address(new IndexPool{salt: salt}(_deployData, masterDeployer));
        _registerPool(pool, tokens, salt);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./HybridPool.sol";
import "./PoolDeployer.sol";

/// @notice Contract for deploying Trident exchange Hybrid Pool with configurations.
/// @author Mudit Gupta.
contract HybridPoolFactory is PoolDeployer {
    constructor(address _masterDeployer) PoolDeployer(_masterDeployer) {}

    function deployPool(bytes memory _deployData) external returns (address pool) {
        (address tokenA, address tokenB, uint256 swapFee, uint256 a) = abi.decode(_deployData, (address, address, uint256, uint256));

        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }

        // @dev Strips any extra data.
        _deployData = abi.encode(tokenA, tokenB, swapFee, a);
        address[] memory tokens = new address[](2);
        tokens[0] = tokenA;
        tokens[1] = tokenB;

        // @dev Salt is not actually needed since `_deployData` is part of creationCode and already contains the salt.
        bytes32 salt = keccak256(_deployData);
        pool = address(new HybridPool{salt: salt}(_deployData, masterDeployer));
        _registerPool(pool, tokens, salt);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../interfaces/IBentoBoxMinimal.sol";
import "../interfaces/IMasterDeployer.sol";
import "../interfaces/IPool.sol";
import "../interfaces/ITridentCallee.sol";
import "../libraries/MathUtils.sol";
import "./TridentERC20.sol";
import "../libraries/RebaseLibrary.sol";

/// @notice Trident exchange pool template with hybrid like-kind formula for swapping between an ERC-20 token pair.
/// @dev The reserves are stored as bento shares. However, the stableswap invariant is applied to the underlying amounts.
///      The API uses the underlying amounts.
contract HybridPool is IPool, TridentERC20 {
    using MathUtils for uint256;
    using RebaseLibrary for Rebase;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient);
    event Sync(uint256 reserve0, uint256 reserve1);

    uint256 internal constant MINIMUM_LIQUIDITY = 10**3;
    uint8 internal constant PRECISION = 112;

    /// @dev Constant value used as max loop limit.
    uint256 private constant MAX_LOOP_LIMIT = 256;
    uint256 internal constant MAX_FEE = 10000; // @dev 100%.
    uint256 public immutable swapFee;

    IBentoBoxMinimal public immutable bento;
    IMasterDeployer public immutable masterDeployer;
    address public immutable barFeeTo;
    address public immutable token0;
    address public immutable token1;
    uint256 public immutable A;
    uint256 internal immutable N_A; // @dev 2 * A.
    uint256 internal constant A_PRECISION = 100;

    /// @dev Multipliers for each pooled token's precision to get to POOL_PRECISION_DECIMALS.
    /// For example, TBTC has 18 decimals, so the multiplier should be 1. WBTC
    /// has 8, so the multiplier should be 10 ** 18 / 10 ** 8 => 10 ** 10.
    uint256 public immutable token0PrecisionMultiplier;
    uint256 public immutable token1PrecisionMultiplier;

    uint256 public barFee;

    uint128 internal reserve0;
    uint128 internal reserve1;
    uint256 internal dLast;

    bytes32 public constant override poolIdentifier = "Trident:HybridPool";

    uint256 internal unlocked;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 2;
        _;
        unlocked = 1;
    }

    constructor(bytes memory _deployData, address _masterDeployer) {
        (address _token0, address _token1, uint256 _swapFee, uint256 a) = abi.decode(_deployData, (address, address, uint256, uint256));

        // @dev Factory ensures that the tokens are sorted.
        require(_token0 != address(0), "ZERO_ADDRESS");
        require(_token0 != _token1, "IDENTICAL_ADDRESSES");
        require(_swapFee <= MAX_FEE, "INVALID_SWAP_FEE");
        require(a != 0, "ZERO_A");

        token0 = _token0;
        token1 = _token1;
        swapFee = _swapFee;
        barFee = IMasterDeployer(_masterDeployer).barFee();
        barFeeTo = IMasterDeployer(_masterDeployer).barFeeTo();
        bento = IBentoBoxMinimal(IMasterDeployer(_masterDeployer).bento());
        masterDeployer = IMasterDeployer(_masterDeployer);
        A = a;
        N_A = 2 * a;
        token0PrecisionMultiplier = uint256(10)**(decimals - TridentERC20(_token0).decimals());
        token1PrecisionMultiplier = uint256(10)**(decimals - TridentERC20(_token1).decimals());
        unlocked = 1;
    }

    /// @dev Mints LP tokens - should be called via the router after transferring `bento` tokens.
    /// The router must ensure that sufficient LP tokens are minted by using the return value.
    function mint(bytes calldata data) public override lock returns (uint256 liquidity) {
        address recipient = abi.decode(data, (address));
        (uint256 _reserve0, uint256 _reserve1) = _getReserves();
        (uint256 balance0, uint256 balance1) = _balance();

        uint256 newLiq = _computeLiquidity(balance0, balance1);
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
        (uint256 fee0, uint256 fee1) = _nonOptimalMintFee(amount0, amount1, _reserve0, _reserve1);
        _reserve0 += uint112(fee0);
        _reserve1 += uint112(fee1);

        (uint256 _totalSupply, uint256 oldLiq) = _mintFee(_reserve0, _reserve1);

        if (_totalSupply == 0) {
            require(amount0 > 0 && amount1 > 0, "INVALID_AMOUNTS");
            liquidity = newLiq - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = ((newLiq - oldLiq) * _totalSupply) / oldLiq;
        }
        require(liquidity != 0, "INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(recipient, liquidity);
        _updateReserves();

        dLast = newLiq;
        emit Mint(msg.sender, amount0, amount1, recipient);
    }

    /// @dev Burns LP tokens sent to this contract. The router must ensure that the user gets sufficient output tokens.
    function burn(bytes calldata data) public override lock returns (IPool.TokenAmount[] memory withdrawnAmounts) {
        (address recipient, bool unwrapBento) = abi.decode(data, (address, bool));
        (uint256 balance0, uint256 balance1) = _balance();
        uint256 liquidity = balanceOf[address(this)];

        (uint256 _totalSupply, ) = _mintFee(balance0, balance1);

        uint256 amount0 = (liquidity * balance0) / _totalSupply;
        uint256 amount1 = (liquidity * balance1) / _totalSupply;

        _burn(address(this), liquidity);
        _transfer(token0, amount0, recipient, unwrapBento);
        _transfer(token1, amount1, recipient, unwrapBento);

        _updateReserves();

        withdrawnAmounts = new TokenAmount[](2);
        withdrawnAmounts[0] = TokenAmount({token: token0, amount: amount0});
        withdrawnAmounts[1] = TokenAmount({token: token1, amount: amount1});

        dLast = _computeLiquidity(balance0 - amount0, balance1 - amount1);

        emit Burn(msg.sender, amount0, amount1, recipient);
    }

    /// @dev Burns LP tokens sent to this contract and swaps one of the output tokens for another
    /// - i.e., the user gets a single token out by burning LP tokens.
    function burnSingle(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenOut, address recipient, bool unwrapBento) = abi.decode(data, (address, address, bool));
        (uint256 balance0, uint256 balance1) = _balance();
        uint256 liquidity = balanceOf[address(this)];

        (uint256 _totalSupply, ) = _mintFee(balance0, balance1);

        uint256 amount0 = (liquidity * balance0) / _totalSupply;
        uint256 amount1 = (liquidity * balance1) / _totalSupply;

        _burn(address(this), liquidity);
        dLast = _computeLiquidity(balance0 - amount0, balance1 - amount1);

        // Swap tokens
        if (tokenOut == token1) {
            // @dev Swap `token0` for `token1`.
            // @dev Calculate `amountOut` as if the user first withdrew balanced liquidity and then swapped `token0` for `token1`.
            amount1 += _getAmountOut(amount0, balance0 - amount0, balance1 - amount1, true);
            _transfer(token1, amount1, recipient, unwrapBento);
            amountOut = amount1;
            amount0 = 0;
        } else {
            // @dev Swap `token1` for `token0`.
            require(tokenOut == token0, "INVALID_OUTPUT_TOKEN");
            amount0 += _getAmountOut(amount1, balance0 - amount0, balance1 - amount1, false);
            _transfer(token0, amount0, recipient, unwrapBento);
            amountOut = amount0;
            amount1 = 0;
        }
        _updateReserves();
        emit Burn(msg.sender, amount0, amount1, recipient);
    }

    /// @dev Swaps one token for another. The router must prefund this contract and ensure there isn't too much slippage.
    function swap(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenIn, address recipient, bool unwrapBento) = abi.decode(data, (address, address, bool));
        (uint256 _reserve0, uint256 _reserve1, uint256 balance0, uint256 balance1) = _getReservesAndBalances();
        uint256 amountIn;
        address tokenOut;

        if (tokenIn == token0) {
            tokenOut = token1;
            unchecked {
                amountIn = balance0 - _reserve0;
            }
            amountOut = _getAmountOut(amountIn, _reserve0, _reserve1, true);
        } else {
            require(tokenIn == token1, "INVALID_INPUT_TOKEN");
            tokenOut = token0;
            unchecked {
                amountIn = balance1 - _reserve1;
            }
            amountOut = _getAmountOut(amountIn, _reserve0, _reserve1, false);
        }
        _transfer(tokenOut, amountOut, recipient, unwrapBento);
        _updateReserves();
        emit Swap(recipient, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @dev Swaps one token for another with payload. The router must support swap callbacks and ensure there isn't too much slippage.
    function flashSwap(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenIn, address recipient, bool unwrapBento, uint256 amountIn, bytes memory context) = abi.decode(
            data,
            (address, address, bool, uint256, bytes)
        );
        (uint256 _reserve0, uint256 _reserve1) = _getReserves();
        address tokenOut;

        if (tokenIn == token0) {
            tokenOut = token1;
            amountIn = bento.toAmount(token0, amountIn, false);
            amountOut = _getAmountOut(amountIn, _reserve0, _reserve1, true);
            _processSwap(token1, recipient, amountOut, context, unwrapBento);
            uint256 balance0 = bento.toAmount(token0, bento.balanceOf(token0, address(this)), false);
            require(balance0 - _reserve0 >= amountIn, "INSUFFICIENT_AMOUNT_IN");
        } else {
            require(tokenIn == token1, "INVALID_INPUT_TOKEN");
            tokenOut = token0;
            amountIn = bento.toAmount(token1, amountIn, false);
            amountOut = _getAmountOut(amountIn, _reserve0, _reserve1, false);
            _processSwap(token0, recipient, amountOut, context, unwrapBento);
            uint256 balance1 = bento.toAmount(token1, bento.balanceOf(token1, address(this)), false);
            require(balance1 - _reserve1 >= amountIn, "INSUFFICIENT_AMOUNT_IN");
        }
        _updateReserves();
        emit Swap(recipient, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @dev Updates `barFee` for Trident protocol.
    function updateBarFee() public {
        barFee = masterDeployer.barFee();
    }

    function _processSwap(
        address tokenOut,
        address to,
        uint256 amountOut,
        bytes memory data,
        bool unwrapBento
    ) internal {
        _transfer(tokenOut, amountOut, to, unwrapBento);
        if (data.length != 0) ITridentCallee(msg.sender).tridentSwapCallback(data);
    }

    function _getReserves() internal view returns (uint256 _reserve0, uint256 _reserve1) {
        (_reserve0, _reserve1) = (reserve0, reserve1);
        _reserve0 = bento.toAmount(token0, _reserve0, false);
        _reserve1 = bento.toAmount(token1, _reserve1, false);
    }

    function _getReservesAndBalances()
        internal
        view
        returns (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 balance0,
            uint256 balance1
        )
    {
        (_reserve0, _reserve1) = (reserve0, reserve1);
        balance0 = bento.balanceOf(token0, address(this));
        balance1 = bento.balanceOf(token1, address(this));
        Rebase memory total0 = bento.totals(token0);
        Rebase memory total1 = bento.totals(token1);

        _reserve0 = total0.toElastic(_reserve0);
        _reserve1 = total1.toElastic(_reserve1);
        balance0 = total0.toElastic(balance0);
        balance1 = total1.toElastic(balance1);
    }

    function _updateReserves() internal {
        (uint256 _reserve0, uint256 _reserve1) = _balance();
        require(_reserve0 < type(uint128).max && _reserve1 < type(uint128).max, "OVERFLOW");
        reserve0 = uint128(_reserve0);
        reserve1 = uint128(_reserve1);
        emit Sync(_reserve0, _reserve1);
    }

    function _balance() internal view returns (uint256 balance0, uint256 balance1) {
        balance0 = bento.toAmount(token0, bento.balanceOf(token0, address(this)), false);
        balance1 = bento.toAmount(token1, bento.balanceOf(token1, address(this)), false);
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 _reserve0,
        uint256 _reserve1,
        bool token0In
    ) internal view returns (uint256 dy) {
        unchecked {
            uint256 adjustedReserve0 = _reserve0 * token0PrecisionMultiplier;
            uint256 adjustedReserve1 = _reserve1 * token1PrecisionMultiplier;
            uint256 feeDeductedAmountIn = amountIn - (amountIn * swapFee) / MAX_FEE;
            uint256 d = _computeLiquidityFromAdjustedBalances(adjustedReserve0, adjustedReserve1);

            if (token0In) {
                uint256 x = adjustedReserve0 + (feeDeductedAmountIn * token0PrecisionMultiplier);
                uint256 y = _getY(x, d);
                dy = adjustedReserve1 - y - 1;
                dy /= token1PrecisionMultiplier;
            } else {
                uint256 x = adjustedReserve1 + (feeDeductedAmountIn * token1PrecisionMultiplier);
                uint256 y = _getY(x, d);
                dy = adjustedReserve0 - y - 1;
                dy /= token0PrecisionMultiplier;
            }
        }
    }

    function _transfer(
        address token,
        uint256 amount,
        address to,
        bool unwrapBento
    ) internal {
        if (unwrapBento) {
            bento.withdraw(token, address(this), to, amount, 0);
        } else {
            bento.transfer(token, address(this), to, bento.toShare(token, amount, false));
        }
    }

    /// @notice Get D, the StableSwap invariant, based on a set of balances and a particular A.
    /// See the StableSwap paper for details.
    /// @dev Originally https://github.com/saddle-finance/saddle-contract/blob/0b76f7fb519e34b878aa1d58cffc8d8dc0572c12/contracts/SwapUtils.sol#L319.
    /// @return liquidity The invariant, at the precision of the pool.
    function _computeLiquidity(uint256 _reserve0, uint256 _reserve1) internal view returns (uint256 liquidity) {
        unchecked {
            uint256 adjustedReserve0 = _reserve0 * token0PrecisionMultiplier;
            uint256 adjustedReserve1 = _reserve1 * token1PrecisionMultiplier;
            liquidity = _computeLiquidityFromAdjustedBalances(adjustedReserve0, adjustedReserve1);
        }
    }

    function _computeLiquidityFromAdjustedBalances(uint256 xp0, uint256 xp1) internal view returns (uint256 computed) {
        uint256 s = xp0 + xp1;

        if (s == 0) {
            computed = 0;
        }
        uint256 prevD;
        uint256 D = s;
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            uint256 dP = (((D * D) / xp0) * D) / xp1 / 4;
            prevD = D;
            D = (((N_A * s) / A_PRECISION + 2 * dP) * D) / ((N_A / A_PRECISION - 1) * D + 3 * dP);
            if (D.within1(prevD)) {
                break;
            }
        }
        computed = D;
    }

    /// @notice Calculate the new balances of the tokens given the indexes of the token
    /// that is swapped from (FROM) and the token that is swapped to (TO).
    /// This function is used as a helper function to calculate how much TO token
    /// the user should receive on swap.
    /// @dev Originally https://github.com/saddle-finance/saddle-contract/blob/0b76f7fb519e34b878aa1d58cffc8d8dc0572c12/contracts/SwapUtils.sol#L432.
    /// @param x The new total amount of FROM token.
    /// @return y The amount of TO token that should remain in the pool.
    function _getY(uint256 x, uint256 D) internal view returns (uint256 y) {
        uint256 c = (D * D) / (x * 2);
        c = (c * D) / ((N_A * 2) / A_PRECISION);
        uint256 b = x + ((D * A_PRECISION) / N_A);
        uint256 yPrev;
        y = D;
        // @dev Iterative approximation.
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = (y * y + c) / (y * 2 + b - D);
            if (y.within1(yPrev)) {
                break;
            }
        }
    }

    function _mintFee(uint256 _reserve0, uint256 _reserve1) internal returns (uint256 _totalSupply, uint256 d) {
        _totalSupply = totalSupply;
        uint256 _dLast = dLast;
        if (_dLast != 0) {
            d = _computeLiquidity(_reserve0, _reserve1);
            if (d > _dLast) {
                // @dev `barFee` % of increase in liquidity.
                // It's going to be slightly less than `barFee` % in reality due to the math.
                uint256 liquidity = (_totalSupply * (d - _dLast) * barFee) / d / MAX_FEE;
                if (liquidity != 0) {
                    _mint(barFeeTo, liquidity);
                    _totalSupply += liquidity;
                }
            }
        }
    }

    /// @dev This fee is charged to cover for `swapFee` when users add unbalanced liquidity.
    function _nonOptimalMintFee(
        uint256 _amount0,
        uint256 _amount1,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal view returns (uint256 token0Fee, uint256 token1Fee) {
        if (_reserve0 == 0 || _reserve1 == 0) return (0, 0);
        uint256 amount1Optimal = (_amount0 * _reserve1) / _reserve0;

        if (amount1Optimal <= _amount1) {
            token1Fee = (swapFee * (_amount1 - amount1Optimal)) / (2 * MAX_FEE);
        } else {
            uint256 amount0Optimal = (_amount1 * _reserve0) / _reserve1;
            token0Fee = (swapFee * (_amount0 - amount0Optimal)) / (2 * MAX_FEE);
        }
    }

    function getAssets() public view override returns (address[] memory assets) {
        assets = new address[](2);
        assets[0] = token0;
        assets[1] = token1;
    }

    function getAmountOut(bytes calldata data) public view override returns (uint256 finalAmountOut) {
        (address tokenIn, uint256 amountIn) = abi.decode(data, (address, uint256));
        (uint256 _reserve0, uint256 _reserve1) = _getReserves();
        amountIn = bento.toAmount(tokenIn, amountIn, false);

        if (tokenIn == token0) {
            finalAmountOut = bento.toShare(token1, _getAmountOut(amountIn, _reserve0, _reserve1, true), false);
        } else {
            finalAmountOut = bento.toShare(token0, _getAmountOut(amountIn, _reserve0, _reserve1, false), false);
        }
    }

    function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1) {
        (_reserve0, _reserve1) = _getReserves();
    }

    function getVirtualPrice() public view returns (uint256 virtualPrice) {
        (uint256 _reserve0, uint256 _reserve1) = _getReserves();
        uint256 d = _computeLiquidity(_reserve0, _reserve1);
        virtualPrice = (d * (uint256(10)**decimals)) / totalSupply;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice A library that contains functions for calculating differences between two uint256.
/// @author Adapted from https://github.com/saddle-finance/saddle-contract/blob/master/contracts/MathUtils.sol.
library MathUtils {
    /// @notice Compares a and b and returns 'true' if the difference between a and b
    /// is less than 1 or equal to each other.
    /// @param a uint256 to compare with.
    /// @param b uint256 to compare with.
    function within1(uint256 a, uint256 b) internal pure returns (bool) {
        unchecked {
            if (a > b) {
                return a - b <= 1;
            }
            return b - a <= 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../../interfaces/IBentoBoxMinimal.sol";
import "../../interfaces/IMasterDeployer.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/ITridentCallee.sol";
import "../../libraries/TridentMath.sol";
import "./TridentFranchisedERC20.sol";

/// @notice Trident exchange franchised pool template with constant product formula for swapping between an ERC-20 token pair.
/// @dev The reserves are stored as bento shares.
///      The curve is applied to shares as well. This pool does not care about the underlying amounts.
contract FranchisedConstantProductPool is IPool, TridentFranchisedERC20 {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient);
    event Sync(uint256 reserve0, uint256 reserve1);

    uint256 internal constant MINIMUM_LIQUIDITY = 1000;

    uint8 internal constant PRECISION = 112;
    uint256 internal constant MAX_FEE = 10000; // @dev 100%.
    uint256 internal constant MAX_FEE_SQUARE = 100000000;
    uint256 internal constant E18 = uint256(10)**18;
    uint256 public immutable swapFee;
    uint256 internal immutable MAX_FEE_MINUS_SWAP_FEE;

    address public immutable barFeeTo;
    address public immutable bento;
    address public immutable masterDeployer;
    address public immutable token0;
    address public immutable token1;

    uint256 public barFee;
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast;

    uint112 internal reserve0;
    uint112 internal reserve1;
    uint32 internal blockTimestampLast;

    bytes32 public constant override poolIdentifier = "Trident:FranchisedCP";

    uint256 internal unlocked;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 2;
        _;
        unlocked = 1;
    }

    constructor(bytes memory _deployData, address _masterDeployer) {
        (address _token0, address _token1, uint256 _swapFee, bool _twapSupport, address _whiteListManager, address _operator, bool _level2) = abi.decode(
            _deployData,
            (address, address, uint256, bool, address, address, bool)
        );

        // @dev Factory ensures that the tokens are sorted.
        require(_token0 != address(0), "ZERO_ADDRESS");
        require(_token0 != _token1, "IDENTICAL_ADDRESSES");
        require(_token0 != address(this), "INVALID_TOKEN");
        require(_token1 != address(this), "INVALID_TOKEN");
        require(_swapFee <= MAX_FEE, "INVALID_SWAP_FEE");

        TridentFranchisedERC20.initialize(_whiteListManager, _operator, _level2);

        (, bytes memory _barFee) = _masterDeployer.staticcall(abi.encodeWithSelector(IMasterDeployer.barFee.selector));
        (, bytes memory _barFeeTo) = _masterDeployer.staticcall(abi.encodeWithSelector(IMasterDeployer.barFeeTo.selector));
        (, bytes memory _bento) = _masterDeployer.staticcall(abi.encodeWithSelector(IMasterDeployer.bento.selector));

        token0 = _token0;
        token1 = _token1;
        swapFee = _swapFee;
        // @dev This is safe from underflow - `swapFee` cannot exceed `MAX_FEE` per previous check.
        unchecked {
            MAX_FEE_MINUS_SWAP_FEE = MAX_FEE - _swapFee;
        }
        barFee = abi.decode(_barFee, (uint256));
        barFeeTo = abi.decode(_barFeeTo, (address));
        bento = abi.decode(_bento, (address));
        masterDeployer = _masterDeployer;
        unlocked = 1;
        if (_twapSupport) blockTimestampLast = 1;
    }

    /// @dev Mints LP tokens - should be called via the router after transferring `bento` tokens.
    /// The router must ensure that sufficient LP tokens are minted by using the return value.
    function mint(bytes calldata data) public override lock returns (uint256 liquidity) {
        address recipient = abi.decode(data, (address));
        _checkWhiteList(recipient);
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = _getReserves();
        (uint256 balance0, uint256 balance1) = _balance();
        uint256 _totalSupply = totalSupply;

        unchecked {
            _totalSupply += _mintFee(_reserve0, _reserve1, _totalSupply);
        }

        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
        (uint256 fee0, uint256 fee1) = _nonOptimalMintFee(amount0, amount1, _reserve0, _reserve1);
        uint256 computed = TridentMath.sqrt((balance0 - fee0) * (balance1 - fee1));

        if (_totalSupply == 0) {
            _mint(address(0), MINIMUM_LIQUIDITY);
            liquidity = computed - MINIMUM_LIQUIDITY;
        } else {
            uint256 k = TridentMath.sqrt(uint256(_reserve0) * _reserve1);
            liquidity = ((computed - k) * _totalSupply) / k;
        }
        require(liquidity != 0, "INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(recipient, liquidity);
        _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
        kLast = TridentMath.sqrt(balance0 * balance1);
        emit Mint(msg.sender, amount0, amount1, recipient);
    }

    /// @dev Burns LP tokens sent to this contract. The router must ensure that the user gets sufficient output tokens.
    function burn(bytes calldata data) public override lock returns (IPool.TokenAmount[] memory withdrawnAmounts) {
        (address recipient, bool unwrapBento) = abi.decode(data, (address, bool));
        _checkWhiteList(recipient);
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = _getReserves();
        (uint256 balance0, uint256 balance1) = _balance();
        uint256 _totalSupply = totalSupply;
        uint256 liquidity = balanceOf[address(this)];

        unchecked {
            _totalSupply += _mintFee(_reserve0, _reserve1, _totalSupply);
        }

        uint256 amount0 = (liquidity * balance0) / _totalSupply;
        uint256 amount1 = (liquidity * balance1) / _totalSupply;

        _burn(address(this), liquidity);
        _transfer(token0, amount0, recipient, unwrapBento);
        _transfer(token1, amount1, recipient, unwrapBento);
        // @dev This is safe from underflow - amounts are lesser figures derived from balances.
        unchecked {
            balance0 -= amount0;
            balance1 -= amount1;
        }
        _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
        kLast = TridentMath.sqrt(balance0 * balance1);

        withdrawnAmounts = new TokenAmount[](2);
        withdrawnAmounts[0] = TokenAmount({token: address(token0), amount: amount0});
        withdrawnAmounts[1] = TokenAmount({token: address(token1), amount: amount1});
        emit Burn(msg.sender, amount0, amount1, recipient);
    }

    /// @dev Burns LP tokens sent to this contract and swaps one of the output tokens for another
    /// - i.e., the user gets a single token out by burning LP tokens.
    function burnSingle(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenOut, address recipient, bool unwrapBento) = abi.decode(data, (address, address, bool));
        _checkWhiteList(recipient);
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = _getReserves();
        (uint256 balance0, uint256 balance1) = _balance();
        uint256 _totalSupply = totalSupply;
        uint256 liquidity = balanceOf[address(this)];

        unchecked {
            _totalSupply += _mintFee(_reserve0, _reserve1, _totalSupply);
        }

        uint256 amount0 = (liquidity * balance0) / _totalSupply;
        uint256 amount1 = (liquidity * balance1) / _totalSupply;

        _burn(address(this), liquidity);
        unchecked {
            if (tokenOut == token1) {
                // @dev Swap `token0` for `token1`
                // - calculate `amountOut` as if the user first withdrew balanced liquidity and then swapped `token0` for `token1`.
                amount1 += _getAmountOut(amount0, _reserve0 - amount0, _reserve1 - amount1);
                _transfer(token1, amount1, recipient, unwrapBento);
                balance1 -= amount1;
                amountOut = amount1;
                amount0 = 0;
            } else {
                // @dev Swap `token1` for `token0`.
                require(tokenOut == token0, "INVALID_OUTPUT_TOKEN");
                amount0 += _getAmountOut(amount1, _reserve1 - amount1, _reserve0 - amount0);
                _transfer(token0, amount0, recipient, unwrapBento);
                balance0 -= amount0;
                amountOut = amount0;
                amount1 = 0;
            }
        }
        _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
        kLast = TridentMath.sqrt(balance0 * balance1);
        emit Burn(msg.sender, amount0, amount1, recipient);
    }

    /// @dev Swaps one token for another. The router must prefund this contract and ensure there isn't too much slippage.
    function swap(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenIn, address recipient, bool unwrapBento) = abi.decode(data, (address, address, bool));
        if (level2) _checkWhiteList(recipient);
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = _getReserves();
        (uint256 balance0, uint256 balance1) = _balance();
        uint256 amountIn;
        address tokenOut;
        unchecked {
            if (tokenIn == token0) {
                tokenOut = token1;
                amountIn = balance0 - _reserve0;
                amountOut = _getAmountOut(amountIn, _reserve0, _reserve1);
                balance1 -= amountOut;
            } else {
                require(tokenIn == token1, "INVALID_INPUT_TOKEN");
                tokenOut = token0;
                amountIn = balance1 - reserve1;
                amountOut = _getAmountOut(amountIn, _reserve1, _reserve0);
                balance0 -= amountOut;
            }
        }
        _transfer(tokenOut, amountOut, recipient, unwrapBento);
        _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
        emit Swap(recipient, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @dev Swaps one token for another. The router must support swap callbacks and ensure there isn't too much slippage.
    function flashSwap(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenIn, address recipient, bool unwrapBento, uint256 amountIn, bytes memory context) = abi.decode(
            data,
            (address, address, bool, uint256, bytes)
        );
        if (level2) _checkWhiteList(recipient);
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = _getReserves();
        unchecked {
            if (tokenIn == token0) {
                amountOut = _getAmountOut(amountIn, _reserve0, _reserve1);
                _transfer(token1, amountOut, recipient, unwrapBento);
                ITridentCallee(msg.sender).tridentSwapCallback(context);
                (uint256 balance0, uint256 balance1) = _balance();
                require(balance0 - _reserve0 >= amountIn, "INSUFFICIENT_AMOUNT_IN");
                _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
                emit Swap(recipient, tokenIn, token1, amountIn, amountOut);
            } else {
                require(tokenIn == token1, "INVALID_INPUT_TOKEN");
                amountOut = _getAmountOut(amountIn, _reserve1, _reserve0);
                _transfer(token0, amountOut, recipient, unwrapBento);
                ITridentCallee(msg.sender).tridentSwapCallback(context);
                (uint256 balance0, uint256 balance1) = _balance();
                require(balance1 - _reserve1 >= amountIn, "INSUFFICIENT_AMOUNT_IN");
                _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
                emit Swap(recipient, tokenIn, token0, amountIn, amountOut);
            }
        }
    }

    /// @dev Updates `barFee` for Trident protocol.
    function updateBarFee() public {
        (, bytes memory _barFee) = masterDeployer.staticcall(abi.encodeWithSelector(IMasterDeployer.barFee.selector));
        barFee = abi.decode(_barFee, (uint256));
    }

    function _getReserves()
        internal
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _balance() internal view returns (uint256 balance0, uint256 balance1) {
        // @dev balanceOf(address,address).
        (, bytes memory _balance0) = bento.staticcall(abi.encodeWithSelector(0xf7888aec, token0, address(this)));
        balance0 = abi.decode(_balance0, (uint256));
        // @dev balanceOf(address,address).
        (, bytes memory _balance1) = bento.staticcall(abi.encodeWithSelector(0xf7888aec, token1, address(this)));
        balance1 = abi.decode(_balance1, (uint256));
    }

    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1,
        uint32 _blockTimestampLast
    ) internal {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "OVERFLOW");
        if (blockTimestampLast == 0) {
            // @dev TWAP support is disabled for gas efficiency.
            reserve0 = uint112(balance0);
            reserve1 = uint112(balance1);
        } else {
            uint32 blockTimestamp = uint32(block.timestamp % 2**32);
            if (blockTimestamp != _blockTimestampLast && _reserve0 != 0 && _reserve1 != 0) {
                unchecked {
                    uint32 timeElapsed = blockTimestamp - _blockTimestampLast;
                    uint256 price0 = (uint256(_reserve1) << PRECISION) / _reserve0;
                    price0CumulativeLast += price0 * timeElapsed;
                    uint256 price1 = (uint256(_reserve0) << PRECISION) / _reserve1;
                    price1CumulativeLast += price1 * timeElapsed;
                }
            }
            reserve0 = uint112(balance0);
            reserve1 = uint112(balance1);
            blockTimestampLast = blockTimestamp;
        }
        emit Sync(balance0, balance1);
    }

    function _mintFee(
        uint112 _reserve0,
        uint112 _reserve1,
        uint256 _totalSupply
    ) internal returns (uint256 liquidity) {
        uint256 _kLast = kLast;
        if (_kLast != 0) {
            uint256 computed = TridentMath.sqrt(uint256(_reserve0) * _reserve1);
            if (computed > _kLast) {
                // @dev `barFee` % of increase in liquidity.
                // It's going to be slightly less than `barFee` % in reality due to the math.
                liquidity = (_totalSupply * (computed - _kLast) * barFee) / computed / MAX_FEE;
                if (liquidity != 0) {
                    _mint(barFeeTo, liquidity);
                }
            }
        }
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveAmountIn,
        uint256 reserveAmountOut
    ) internal view returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * MAX_FEE_MINUS_SWAP_FEE;
        amountOut = (amountInWithFee * reserveAmountOut) / (reserveAmountIn * MAX_FEE + amountInWithFee);
    }

    function _transfer(
        address token,
        uint256 shares,
        address to,
        bool unwrapBento
    ) internal {
        if (unwrapBento) {
            (bool success, ) = bento.call(abi.encodeWithSelector(IBentoBoxMinimal.withdraw.selector, token, address(this), to, 0, shares));
            require(success, "WITHDRAW_FAILED");
        } else {
            (bool success, ) = bento.call(abi.encodeWithSelector(IBentoBoxMinimal.transfer.selector, token, address(this), to, shares));
            require(success, "TRANSFER_FAILED");
        }
    }

    /// @dev This fee is charged to cover for `swapFee` when users add unbalanced liquidity.
    function _nonOptimalMintFee(
        uint256 _amount0,
        uint256 _amount1,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal view returns (uint256 token0Fee, uint256 token1Fee) {
        if (_reserve0 == 0 || _reserve1 == 0) return (0, 0);
        uint256 amount1Optimal = (_amount0 * _reserve1) / _reserve0;
        if (amount1Optimal <= _amount1) {
            token1Fee = (swapFee * (_amount1 - amount1Optimal)) / (2 * MAX_FEE);
        } else {
            uint256 amount0Optimal = (_amount1 * _reserve0) / _reserve1;
            token0Fee = (swapFee * (_amount0 - amount0Optimal)) / (2 * MAX_FEE);
        }
    }

    function getAssets() public view override returns (address[] memory assets) {
        assets = new address[](2);
        assets[0] = token0;
        assets[1] = token1;
    }

    function getAmountOut(bytes calldata data) public view override returns (uint256 finalAmountOut) {
        (address tokenIn, uint256 amountIn) = abi.decode(data, (address, uint256));
        (uint112 _reserve0, uint112 _reserve1, ) = _getReserves();
        if (tokenIn == token0) {
            finalAmountOut = _getAmountOut(amountIn, _reserve0, _reserve1);
        } else {
            finalAmountOut = _getAmountOut(amountIn, _reserve1, _reserve0);
        }
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        return _getReserves();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../../interfaces/IWhiteListManager.sol";

/// @notice Trident franchised pool ERC-20 with EIP-2612 extension.
/// @author Adapted from RariCapital, https://github.com/Rari-Capital/solmate/blob/main/src/erc20/ERC20.sol,
/// License-Identifier: AGPL-3.0-only.
abstract contract TridentFranchisedERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);

    string public constant name = "Sushi Franchised LP Token";
    string public constant symbol = "SLP";
    uint8 public constant decimals = 18;

    address public whiteListManager;
    address public operator;
    bool public level2;

    uint256 public totalSupply;
    /// @notice owner -> balance mapping.
    mapping(address => uint256) public balanceOf;
    /// @notice owner -> spender -> allowance mapping.
    mapping(address => mapping(address => uint256)) public allowance;

    /// @notice The EIP-712 typehash for this contract's {permit} struct.
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /// @notice The EIP-712 typehash for this contract's domain.
    bytes32 public immutable DOMAIN_SEPARATOR;
    /// @notice owner -> nonce mapping used in {permit}.
    mapping(address => uint256) public nonces;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /// @dev Initializes whitelist settings from pool.
    function initialize(
        address _whiteListManager,
        address _operator,
        bool _level2
    ) internal {
        whiteListManager = _whiteListManager;
        operator = _operator;
        if (_level2) level2 = true;
    }

    /// @notice Approves `amount` from `msg.sender` to be spent by `spender`.
    /// @param spender Address of the party that can pull tokens from `msg.sender`'s account.
    /// @param amount The maximum collective `amount` that `spender` can pull.
    /// @return (bool) Returns 'true' if succeeded.
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `msg.sender` to `recipient`.
    /// @param recipient The address to move tokens to.
    /// @param amount The token `amount` to move.
    /// @return (bool) Returns 'true' if succeeded.
    function transfer(address recipient, uint256 amount) external returns (bool) {
        if (level2) _checkWhiteList(recipient);
        balanceOf[msg.sender] -= amount;
        // @dev This is safe from overflow - the sum of all user
        // balances can't exceed 'type(uint256).max'.
        unchecked {
            balanceOf[recipient] += amount;
        }
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `sender` to `recipient`. Caller needs approval from `from`.
    /// @param sender Address to pull tokens `from`.
    /// @param recipient The address to move tokens to.
    /// @param amount The token `amount` to move.
    /// @return (bool) Returns 'true' if succeeded.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        if (level2) _checkWhiteList(recipient);
        if (allowance[sender][msg.sender] != type(uint256).max) {
            allowance[sender][msg.sender] -= amount;
        }
        balanceOf[sender] -= amount;
        // @dev This is safe from overflow - the sum of all user
        // balances can't exceed 'type(uint256).max'.
        unchecked {
            balanceOf[recipient] += amount;
        }
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /// @notice Triggers an approval from `owner` to `spender`.
    /// @param owner The address to approve from.
    /// @param spender The address to be approved.
    /// @param amount The number of tokens that are approved (2^256-1 means infinite).
    /// @param deadline The time at which to expire the signature.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline)))
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_PERMIT_SIGNATURE");
        allowance[recoveredAddress][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address recipient, uint256 amount) internal {
        totalSupply += amount;
        // @dev This is safe from overflow - the sum of all user
        // balances can't exceed 'type(uint256).max'.
        unchecked {
            balanceOf[recipient] += amount;
        }
        emit Transfer(address(0), recipient, amount);
    }

    function _burn(address sender, uint256 amount) internal {
        balanceOf[sender] -= amount;
        // @dev This is safe from underflow - users won't ever
        // have a balance larger than `totalSupply`.
        unchecked {
            totalSupply -= amount;
        }
        emit Transfer(sender, address(0), amount);
    }

    /// @dev Checks `whiteListManager` for pool `operator` and given user `account`.
    function _checkWhiteList(address account) internal view {
        (, bytes memory _whitelisted) = whiteListManager.staticcall(abi.encodeWithSelector(IWhiteListManager.whitelistedAccounts.selector, operator, account));
        bool whitelisted = abi.decode(_whitelisted, (bool));
        require(whitelisted, "NOT_WHITELISTED");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident franchised pool whitelist manager interface.
interface IWhiteListManager {
    function whitelistedAccounts(address operator, address account) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../../interfaces/IBentoBoxMinimal.sol";
import "../../interfaces/IMasterDeployer.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/ITridentCallee.sol";
import "./TridentFranchisedERC20.sol";

/// @notice Trident exchange franchised pool template with constant mean formula for swapping among an array of ERC-20 tokens.
/// @dev The reserves are stored as bento shares.
///      The curve is applied to shares as well. This pool does not care about the underlying amounts.
contract FranchisedIndexPool is IPool, TridentFranchisedERC20 {
    event Mint(address indexed sender, address tokenIn, uint256 amountIn, address indexed recipient);
    event Burn(address indexed sender, address tokenOut, uint256 amountOut, address indexed recipient);

    uint256 public immutable swapFee;

    address public immutable barFeeTo;
    address public immutable bento;
    address public immutable masterDeployer;

    uint256 internal constant BASE = 10**18;
    uint256 internal constant MIN_TOKENS = 2;
    uint256 internal constant MAX_TOKENS = 8;
    uint256 internal constant MIN_FEE = BASE / 10**6;
    uint256 internal constant MAX_FEE = BASE / 10;
    uint256 internal constant MIN_WEIGHT = BASE;
    uint256 internal constant MAX_WEIGHT = BASE * 50;
    uint256 internal constant MAX_TOTAL_WEIGHT = BASE * 50;
    uint256 internal constant MIN_BALANCE = BASE / 10**12;
    uint256 internal constant INIT_POOL_SUPPLY = BASE * 100;
    uint256 internal constant MIN_POW_BASE = 1;
    uint256 internal constant MAX_POW_BASE = (2 * BASE) - 1;
    uint256 internal constant POW_PRECISION = BASE / 10**10;
    uint256 internal constant MAX_IN_RATIO = BASE / 2;
    uint256 internal constant MAX_OUT_RATIO = (BASE / 3) + 1;

    uint136 internal totalWeight;
    address[] internal tokens;

    uint256 public barFee;

    bytes32 public constant override poolIdentifier = "Trident:FranchisedIndex";

    uint256 internal unlocked;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 2;
        _;
        unlocked = 1;
    }

    mapping(address => Record) public records;
    struct Record {
        uint120 reserve;
        uint136 weight;
    }

    constructor(bytes memory _deployData, address _masterDeployer) {
        (address[] memory _tokens, uint136[] memory _weights, uint256 _swapFee, address _whiteListManager, address _operator, bool _level2) = abi.decode(
            _deployData,
            (address[], uint136[], uint256, address, address, bool)
        );
        // @dev Factory ensures that the tokens are sorted.
        require(_tokens.length == _weights.length, "INVALID_ARRAYS");
        require(MIN_FEE <= _swapFee && _swapFee <= MAX_FEE, "INVALID_SWAP_FEE");
        require(MIN_TOKENS <= _tokens.length && _tokens.length <= MAX_TOKENS, "INVALID_TOKENS_LENGTH");

        TridentFranchisedERC20.initialize(_whiteListManager, _operator, _level2);

        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_tokens[i] != address(0), "ZERO_ADDRESS");
            require(MIN_WEIGHT <= _weights[i] && _weights[i] <= MAX_WEIGHT, "INVALID_WEIGHT");
            records[_tokens[i]] = Record({reserve: 0, weight: _weights[i]});
            tokens.push(_tokens[i]);
            totalWeight += _weights[i];
        }

        require(totalWeight <= MAX_TOTAL_WEIGHT, "MAX_TOTAL_WEIGHT");
        // @dev This burns initial LP supply.
        _mint(address(0), INIT_POOL_SUPPLY);

        (, bytes memory _barFee) = _masterDeployer.staticcall(abi.encodeWithSelector(IMasterDeployer.barFee.selector));
        (, bytes memory _barFeeTo) = _masterDeployer.staticcall(abi.encodeWithSelector(IMasterDeployer.barFeeTo.selector));
        (, bytes memory _bento) = _masterDeployer.staticcall(abi.encodeWithSelector(IMasterDeployer.bento.selector));

        swapFee = _swapFee;
        barFee = abi.decode(_barFee, (uint256));
        barFeeTo = abi.decode(_barFeeTo, (address));
        bento = abi.decode(_bento, (address));
        masterDeployer = _masterDeployer;
        unlocked = 1;
    }

    /// @dev Mints LP tokens - should be called via the router after transferring `bento` tokens.
    /// The router must ensure that sufficient LP tokens are minted by using the return value.
    function mint(bytes calldata data) public override lock returns (uint256 liquidity) {
        (address recipient, uint256 toMint) = abi.decode(data, (address, uint256));
        _checkWhiteList(recipient);
        uint120 ratio = uint120(_div(toMint, totalSupply));

        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenIn = tokens[i];
            uint120 reserve = records[tokenIn].reserve;
            // @dev If token balance is '0', initialize with `ratio`.
            uint120 amountIn = reserve != 0 ? uint120(_mul(ratio, reserve)) : ratio;
            require(amountIn >= MIN_BALANCE, "MIN_BALANCE");
            // @dev Check Trident router has sent `amountIn` for skim into pool.
            unchecked {
                // @dev This is safe from overflow - only logged amounts handled.
                require(_balance(tokenIn) >= amountIn + reserve, "NOT_RECEIVED");
                records[tokenIn].reserve += amountIn;
            }
            emit Mint(msg.sender, tokenIn, amountIn, recipient);
        }
        _mint(recipient, toMint);
        liquidity = toMint;
    }

    /// @dev Burns LP tokens sent to this contract. The router must ensure that the user gets sufficient output tokens.
    function burn(bytes calldata data) public override lock returns (IPool.TokenAmount[] memory withdrawnAmounts) {
        (address recipient, bool unwrapBento, uint256 toBurn) = abi.decode(data, (address, bool, uint256));
        _checkWhiteList(recipient);
        uint256 ratio = _div(toBurn, totalSupply);

        withdrawnAmounts = new TokenAmount[](tokens.length);

        _burn(address(this), toBurn);

        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenOut = tokens[i];
            uint256 balance = records[tokenOut].reserve;
            uint120 amountOut = uint120(_mul(ratio, balance));
            require(amountOut != 0, "ZERO_OUT");
            // @dev This is safe from underflow - only logged amounts handled.
            unchecked {
                records[tokenOut].reserve -= amountOut;
            }
            _transfer(tokenOut, amountOut, recipient, unwrapBento);
            withdrawnAmounts[i] = TokenAmount({token: tokenOut, amount: amountOut});
            emit Burn(msg.sender, tokenOut, amountOut, recipient);
        }
    }

    /// @dev Burns LP tokens sent to this contract and swaps one of the output tokens for another
    /// - i.e., the user gets a single token out by burning LP tokens.
    function burnSingle(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenOut, address recipient, bool unwrapBento, uint256 toBurn) = abi.decode(data, (address, address, bool, uint256));
        _checkWhiteList(recipient);
        Record storage outRecord = records[tokenOut];

        amountOut = _computeSingleOutGivenPoolIn(outRecord.reserve, outRecord.weight, totalSupply, totalWeight, toBurn, swapFee);

        require(amountOut <= _mul(outRecord.reserve, MAX_OUT_RATIO), "MAX_OUT_RATIO");
        // @dev This is safe from underflow - only logged amounts handled.
        unchecked {
            outRecord.reserve -= uint120(amountOut);
        }
        _burn(address(this), toBurn);
        _transfer(tokenOut, amountOut, recipient, unwrapBento);
        emit Burn(msg.sender, tokenOut, amountOut, recipient);
    }

    /// @dev Swaps one token for another. The router must prefund this contract and ensure there isn't too much slippage.
    function swap(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenIn, address tokenOut, address recipient, bool unwrapBento, uint256 amountIn) = abi.decode(
            data,
            (address, address, address, bool, uint256)
        );
        if (level2) _checkWhiteList(recipient);
        Record storage inRecord = records[tokenIn];
        Record storage outRecord = records[tokenOut];

        require(amountIn <= _mul(inRecord.reserve, MAX_IN_RATIO), "MAX_IN_RATIO");

        amountOut = _getAmountOut(amountIn, inRecord.reserve, inRecord.weight, outRecord.reserve, outRecord.weight);
        // @dev Check Trident router has sent `amountIn` for skim into pool.
        unchecked {
            // @dev This is safe from under/overflow - only logged amounts handled.
            require(_balance(tokenIn) >= amountIn + inRecord.reserve, "NOT_RECEIVED");
            inRecord.reserve += uint120(amountIn);
            outRecord.reserve -= uint120(amountOut);
        }
        _transfer(tokenOut, amountOut, recipient, unwrapBento);
        emit Swap(recipient, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @dev Swaps one token for another. The router must support swap callbacks and ensure there isn't too much slippage.
    function flashSwap(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenIn, address tokenOut, address recipient, bool unwrapBento, uint256 amountIn, bytes memory context) = abi.decode(
            data,
            (address, address, address, bool, uint256, bytes)
        );
        if (level2) _checkWhiteList(recipient);
        Record storage inRecord = records[tokenIn];
        Record storage outRecord = records[tokenOut];

        require(amountIn <= _mul(inRecord.reserve, MAX_IN_RATIO), "MAX_IN_RATIO");

        amountOut = _getAmountOut(amountIn, inRecord.reserve, inRecord.weight, outRecord.reserve, outRecord.weight);

        ITridentCallee(msg.sender).tridentSwapCallback(context);
        // @dev Check Trident router has sent `amountIn` for skim into pool.
        unchecked {
            // @dev This is safe from under/overflow - only logged amounts handled.
            require(_balance(tokenIn) >= amountIn + inRecord.reserve, "NOT_RECEIVED");
            inRecord.reserve += uint120(amountIn);
            outRecord.reserve -= uint120(amountOut);
        }
        _transfer(tokenOut, amountOut, recipient, unwrapBento);
        emit Swap(recipient, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @dev Updates `barFee` for Trident protocol.
    function updateBarFee() public {
        (, bytes memory _barFee) = masterDeployer.staticcall(abi.encodeWithSelector(IMasterDeployer.barFee.selector));
        barFee = abi.decode(_barFee, (uint256));
    }

    function _balance(address token) internal view returns (uint256 balance) {
        (, bytes memory data) = bento.staticcall(abi.encodeWithSelector(IBentoBoxMinimal.balanceOf.selector, token, address(this)));
        balance = abi.decode(data, (uint256));
    }

    function _getAmountOut(
        uint256 tokenInAmount,
        uint256 tokenInBalance,
        uint256 tokenInWeight,
        uint256 tokenOutBalance,
        uint256 tokenOutWeight
    ) internal view returns (uint256 amountOut) {
        uint256 weightRatio = _div(tokenInWeight, tokenOutWeight);
        // @dev This is safe from under/overflow - only logged amounts handled.
        unchecked {
            uint256 adjustedIn = _mul(tokenInAmount, (BASE - swapFee));
            uint256 a = _div(tokenInBalance, tokenInBalance + adjustedIn);
            uint256 b = _compute(a, weightRatio);
            uint256 c = BASE - b;
            amountOut = _mul(tokenOutBalance, c);
        }
    }

    function _compute(uint256 base, uint256 exp) internal pure returns (uint256 output) {
        require(MIN_POW_BASE <= base && base <= MAX_POW_BASE, "INVALID_BASE");

        uint256 whole = (exp / BASE) * BASE;
        uint256 remain = exp - whole;
        uint256 wholePow = _pow(base, whole / BASE);

        if (remain == 0) output = wholePow;

        uint256 partialResult = _powApprox(base, remain, POW_PRECISION);
        output = _mul(wholePow, partialResult);
    }

    function _computeSingleOutGivenPoolIn(
        uint256 tokenOutBalance,
        uint256 tokenOutWeight,
        uint256 _totalSupply,
        uint256 _totalWeight,
        uint256 toBurn,
        uint256 _swapFee
    ) internal pure returns (uint256 amountOut) {
        uint256 normalizedWeight = _div(tokenOutWeight, _totalWeight);
        uint256 newPoolSupply = _totalSupply - toBurn;
        uint256 poolRatio = _div(newPoolSupply, _totalSupply);
        uint256 tokenOutRatio = _pow(poolRatio, _div(BASE, normalizedWeight));
        uint256 newBalanceOut = _mul(tokenOutRatio, tokenOutBalance);
        uint256 tokenAmountOutBeforeSwapFee = tokenOutBalance - newBalanceOut;
        uint256 zaz = (BASE - normalizedWeight) * _swapFee;
        amountOut = _mul(tokenAmountOutBeforeSwapFee, (BASE - zaz));
    }

    function _pow(uint256 a, uint256 n) internal pure returns (uint256 output) {
        output = n % 2 != 0 ? a : BASE;
        for (n /= 2; n != 0; n /= 2) a = a * a;
        if (n % 2 != 0) output = output * a;
    }

    function _powApprox(
        uint256 base,
        uint256 exp,
        uint256 precision
    ) internal pure returns (uint256 sum) {
        uint256 a = exp;
        (uint256 x, bool xneg) = _subFlag(base, BASE);
        uint256 term = BASE;
        sum = term;
        bool negative;

        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * BASE;
            (uint256 c, bool cneg) = _subFlag(a, (bigK - BASE));
            term = _mul(term, _mul(c, x));
            term = _div(term, bigK);
            if (term == 0) break;
            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = sum - term;
            } else {
                sum = sum + term;
            }
        }
    }

    function _subFlag(uint256 a, uint256 b) internal pure returns (uint256 difference, bool flag) {
        // @dev This is safe from underflow - if/else flow performs checks.
        unchecked {
            if (a >= b) {
                (difference, flag) = (a - b, false);
            } else {
                (difference, flag) = (b - a, true);
            }
        }
    }

    function _mul(uint256 a, uint256 b) internal pure returns (uint256 c2) {
        uint256 c0 = a * b;
        uint256 c1 = c0 + (BASE / 2);
        c2 = c1 / BASE;
    }

    function _div(uint256 a, uint256 b) internal pure returns (uint256 c2) {
        uint256 c0 = a * BASE;
        uint256 c1 = c0 + (b / 2);
        c2 = c1 / b;
    }

    function _transfer(
        address token,
        uint256 shares,
        address to,
        bool unwrapBento
    ) internal {
        if (unwrapBento) {
            (bool success, ) = bento.call(abi.encodeWithSelector(IBentoBoxMinimal.withdraw.selector, token, address(this), to, 0, shares));
            require(success, "WITHDRAW_FAILED");
        } else {
            (bool success, ) = bento.call(abi.encodeWithSelector(IBentoBoxMinimal.transfer.selector, token, address(this), to, shares));
            require(success, "TRANSFER_FAILED");
        }
    }

    function getAssets() public view override returns (address[] memory assets) {
        assets = tokens;
    }

    function getAmountOut(bytes calldata data) public view override returns (uint256 amountOut) {
        (uint256 tokenInAmount, uint256 tokenInBalance, uint256 tokenInWeight, uint256 tokenOutBalance, uint256 tokenOutWeight) = abi.decode(
            data,
            (uint256, uint256, uint256, uint256, uint256)
        );
        amountOut = _getAmountOut(tokenInAmount, tokenInBalance, tokenInWeight, tokenOutBalance, tokenOutWeight);
    }

    function getReservesAndWeights() public view returns (uint256[] memory reserves, uint136[] memory weights) {
        uint256 length = tokens.length;
        reserves = new uint256[](length);
        weights = new uint136[](length);
        // @dev This is safe from overflow - `tokens` `length` is bound to '8'.
        unchecked {
            for (uint256 i = 0; i < length; i++) {
                reserves[i] = records[tokens[i]].reserve;
                weights[i] = records[tokens[i]].weight;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../../interfaces/IBentoBoxMinimal.sol";
import "../../interfaces/IMasterDeployer.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/ITridentCallee.sol";
import "../../libraries/MathUtils.sol";
import "./TridentFranchisedERC20.sol";

/// @notice Trident exchange franchised pool template with hybrid like-kind formula for swapping between an ERC-20 token pair.
/// @dev The reserves are stored as bento shares. However, the stableswap invariant is applied to the underlying amounts.
///      The API uses the underlying amounts.
contract FranchisedHybridPool is IPool, TridentFranchisedERC20 {
    using MathUtils for uint256;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient);
    event Sync(uint256 reserve0, uint256 reserve1);

    uint256 internal constant MINIMUM_LIQUIDITY = 10**3;
    uint8 internal constant PRECISION = 112;

    /// @dev Constant value used as max loop limit.
    uint256 internal constant MAX_LOOP_LIMIT = 256;
    uint256 internal constant MAX_FEE = 10000; // @dev 100%.
    uint256 public immutable swapFee;

    address public immutable barFeeTo;
    address public immutable bento;
    address public immutable masterDeployer;
    address public immutable token0;
    address public immutable token1;
    uint256 public immutable A;
    uint256 internal immutable N_A; // @dev 2 * A.
    uint256 internal constant A_PRECISION = 100;

    /// @dev Multipliers for each pooled token's precision to get to POOL_PRECISION_DECIMALS.
    /// For example, TBTC has 18 decimals, so the multiplier should be 1. WBTC
    /// has 8, so the multiplier should be 10 ** 18 / 10 ** 8 => 10 ** 10.
    uint256 public immutable token0PrecisionMultiplier;
    uint256 public immutable token1PrecisionMultiplier;

    uint256 public barFee;

    uint128 internal reserve0;
    uint128 internal reserve1;

    bytes32 public constant override poolIdentifier = "Trident:FranchisedHybrid";

    uint256 internal unlocked;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 2;
        _;
        unlocked = 1;
    }

    constructor(bytes memory _deployData, address _masterDeployer) {
        (address _token0, address _token1, uint256 _swapFee, uint256 a, address _whiteListManager, address _operator, bool _level2) = abi.decode(
            _deployData,
            (address, address, uint256, uint256, address, address, bool)
        );

        // @dev Factory ensures that the tokens are sorted.
        require(_token0 != address(0), "ZERO_ADDRESS");
        require(_token0 != _token1, "IDENTICAL_ADDRESSES");
        require(_swapFee <= MAX_FEE, "INVALID_SWAP_FEE");
        require(a != 0, "ZERO_A");

        TridentFranchisedERC20.initialize(_whiteListManager, _operator, _level2);

        (, bytes memory _barFee) = _masterDeployer.staticcall(abi.encodeWithSelector(IMasterDeployer.barFee.selector));
        (, bytes memory _barFeeTo) = _masterDeployer.staticcall(abi.encodeWithSelector(IMasterDeployer.barFeeTo.selector));
        (, bytes memory _bento) = _masterDeployer.staticcall(abi.encodeWithSelector(IMasterDeployer.bento.selector));
        (, bytes memory _decimals0) = _token0.staticcall(abi.encodeWithSelector(0x313ce567)); // @dev 'decimals()'.
        (, bytes memory _decimals1) = _token1.staticcall(abi.encodeWithSelector(0x313ce567)); // @dev 'decimals()'.

        token0 = _token0;
        token1 = _token1;
        swapFee = _swapFee;
        barFee = abi.decode(_barFee, (uint256));
        barFeeTo = abi.decode(_barFeeTo, (address));
        bento = abi.decode(_bento, (address));
        masterDeployer = _masterDeployer;
        A = a;
        N_A = 2 * a;
        token0PrecisionMultiplier = 10**(decimals - abi.decode(_decimals0, (uint8)));
        token1PrecisionMultiplier = 10**(decimals - abi.decode(_decimals1, (uint8)));
        unlocked = 1;
    }

    /// @dev Mints LP tokens - should be called via the router after transferring `bento` tokens.
    /// The router must ensure that sufficient LP tokens are minted by using the return value.
    function mint(bytes calldata data) public override lock returns (uint256 liquidity) {
        address recipient = abi.decode(data, (address));
        _checkWhiteList(recipient);
        (uint256 _reserve0, uint256 _reserve1) = _getReserves();
        (uint256 balance0, uint256 balance1) = _balance();
        uint256 _totalSupply = totalSupply;

        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
        (uint256 fee0, uint256 fee1) = _nonOptimalMintFee(amount0, amount1, _reserve0, _reserve1);
        uint256 newLiq = _computeLiquidity(balance0 - fee0, balance1 - fee1);

        if (_totalSupply == 0) {
            liquidity = newLiq - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            uint256 oldLiq = _computeLiquidity(_reserve0, _reserve1);
            liquidity = ((newLiq - oldLiq) * _totalSupply) / oldLiq;
        }
        require(liquidity != 0, "INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(recipient, liquidity);
        _updateReserves();
        emit Mint(msg.sender, amount0, amount1, recipient);
    }

    /// @dev Burns LP tokens sent to this contract. The router must ensure that the user gets sufficient output tokens.
    function burn(bytes calldata data) public override lock returns (IPool.TokenAmount[] memory withdrawnAmounts) {
        (address recipient, bool unwrapBento) = abi.decode(data, (address, bool));
        _checkWhiteList(recipient);
        (uint256 balance0, uint256 balance1) = _balance();
        uint256 _totalSupply = totalSupply;
        uint256 liquidity = balanceOf[address(this)];

        uint256 amount0 = (liquidity * balance0) / _totalSupply;
        uint256 amount1 = (liquidity * balance1) / _totalSupply;

        _burn(address(this), liquidity);
        _transfer(token0, amount0, recipient, unwrapBento);
        _transfer(token1, amount1, recipient, unwrapBento);

        balance0 -= _toShare(token0, amount0);
        balance1 -= _toShare(token1, amount1);

        _updateReserves();

        withdrawnAmounts = new TokenAmount[](2);
        withdrawnAmounts[0] = TokenAmount({token: token0, amount: amount0});
        withdrawnAmounts[1] = TokenAmount({token: token1, amount: amount1});

        emit Burn(msg.sender, amount0, amount1, recipient);
    }

    /// @dev Burns LP tokens sent to this contract and swaps one of the output tokens for another
    /// - i.e., the user gets a single token out by burning LP tokens.
    function burnSingle(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenOut, address recipient, bool unwrapBento) = abi.decode(data, (address, address, bool));
        _checkWhiteList(recipient);
        (uint256 _reserve0, uint256 _reserve1) = _getReserves();
        (uint256 balance0, uint256 balance1) = _balance();
        uint256 _totalSupply = totalSupply;
        uint256 liquidity = balanceOf[address(this)];

        uint256 amount0 = (liquidity * balance0) / _totalSupply;
        uint256 amount1 = (liquidity * balance1) / _totalSupply;

        _burn(address(this), liquidity);

        if (tokenOut == token1) {
            // @dev Swap `token0` for `token1`.
            // @dev Calculate `amountOut` as if the user first withdrew balanced liquidity and then swapped `token0` for `token1`.
            uint256 fee = _handleFee(token0, amount0);
            amount1 += _getAmountOut(amount0 - fee, _reserve0 - amount0, _reserve1 - amount1, true);
            _transfer(token1, amount1, recipient, unwrapBento);
            balance0 -= _toShare(token0, amount0);
            amountOut = amount1;
            amount0 = 0;
        } else {
            // @dev Swap `token1` for `token0`.
            require(tokenOut == token0, "INVALID_OUTPUT_TOKEN");
            uint256 fee = _handleFee(token1, amount1);
            amount0 += _getAmountOut(amount1 - fee, _reserve0 - amount0, _reserve1 - amount1, false);
            _transfer(token0, amount0, recipient, unwrapBento);
            balance1 -= _toShare(token1, amount1);
            amountOut = amount0;
            amount1 = 0;
        }
        _updateReserves();
        emit Burn(msg.sender, amount0, amount1, recipient);
    }

    /// @dev Swaps one token for another. The router must prefund this contract and ensure there isn't too much slippage.
    function swap(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenIn, address recipient, bool unwrapBento) = abi.decode(data, (address, address, bool));
        if (level2) _checkWhiteList(recipient);
        (uint256 _reserve0, uint256 _reserve1) = _getReserves();
        (uint256 balance0, uint256 balance1) = _balance();
        uint256 amountIn;
        address tokenOut;

        if (tokenIn == token0) {
            tokenOut = token1;
            amountIn = balance0 - _reserve0;
            uint256 fee = _handleFee(tokenIn, amountIn);
            amountOut = _getAmountOut(amountIn - fee, _reserve0, _reserve1, true);
        } else {
            require(tokenIn == token1, "INVALID_INPUT_TOKEN");
            tokenOut = token0;
            amountIn = balance1 - _reserve1;
            uint256 fee = _handleFee(tokenIn, amountIn);
            amountOut = _getAmountOut(amountIn - fee, _reserve0, _reserve1, false);
        }
        _transfer(tokenOut, amountOut, recipient, unwrapBento);
        _updateReserves();
        emit Swap(recipient, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @dev Swaps one token for another with payload. The router must support swap callbacks and ensure there isn't too much slippage.
    function flashSwap(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenIn, address recipient, bool unwrapBento, uint256 amountIn, bytes memory context) = abi.decode(
            data,
            (address, address, bool, uint256, bytes)
        );
        if (level2) _checkWhiteList(recipient);
        (uint256 _reserve0, uint256 _reserve1) = _getReserves();
        address tokenOut;
        uint256 fee;

        if (tokenIn == token0) {
            tokenOut = token1;
            amountIn = _toAmount(token0, amountIn);
            fee = (amountIn * swapFee) / MAX_FEE;
            amountOut = _getAmountOut(amountIn - fee, _reserve0, _reserve1, true);
            _processSwap(token1, recipient, amountOut, context, unwrapBento);
            uint256 balance0 = _toAmount(token0, __balance(token0));
            require(balance0 - _reserve0 >= amountIn, "INSUFFICIENT_AMOUNT_IN");
        } else {
            require(tokenIn == token1, "INVALID_INPUT_TOKEN");
            tokenOut = token0;
            amountIn = _toAmount(token1, amountIn);
            fee = (amountIn * swapFee) / MAX_FEE;
            amountOut = _getAmountOut(amountIn - fee, _reserve0, _reserve1, false);
            _processSwap(token0, recipient, amountOut, context, unwrapBento);
            uint256 balance1 = _toAmount(token1, __balance(token1));
            require(balance1 - _reserve1 >= amountIn, "INSUFFICIENT_AMOUNT_IN");
        }
        _transfer(tokenIn, fee, barFeeTo, false);
        _updateReserves();
        emit Swap(recipient, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @dev Updates `barFee` for Trident protocol.
    function updateBarFee() public {
        (, bytes memory _barFee) = masterDeployer.staticcall(abi.encodeWithSelector(IMasterDeployer.barFee.selector));
        barFee = abi.decode(_barFee, (uint256));
    }

    function _processSwap(
        address tokenOut,
        address to,
        uint256 amountOut,
        bytes memory data,
        bool unwrapBento
    ) internal {
        _transfer(tokenOut, amountOut, to, unwrapBento);
        if (data.length != 0) ITridentCallee(msg.sender).tridentSwapCallback(data);
    }

    function _getReserves() internal view returns (uint256 _reserve0, uint256 _reserve1) {
        (_reserve0, _reserve1) = (reserve0, reserve1);
        _reserve0 = _toAmount(token0, _reserve0);
        _reserve1 = _toAmount(token1, _reserve1);
    }

    function _updateReserves() internal {
        (uint256 _reserve0, uint256 _reserve1) = _balance();
        require(_reserve0 < type(uint128).max && _reserve1 < type(uint128).max, "OVERFLOW");
        reserve0 = uint128(_reserve0);
        reserve1 = uint128(_reserve1);
        emit Sync(_reserve0, _reserve1);
    }

    function _balance() internal view returns (uint256 balance0, uint256 balance1) {
        balance0 = _toAmount(token0, __balance(token0));
        balance1 = _toAmount(token1, __balance(token1));
    }

    function __balance(address token) internal view returns (uint256 balance) {
        // @dev balanceOf(address,address).
        (, bytes memory ___balance) = bento.staticcall(abi.encodeWithSelector(IBentoBoxMinimal.balanceOf.selector, token, address(this)));
        balance = abi.decode(___balance, (uint256));
    }

    function _toAmount(address token, uint256 input) internal view returns (uint256 output) {
        // @dev toAmount(address,uint256,bool).
        (, bytes memory _output) = bento.staticcall(abi.encodeWithSelector(IBentoBoxMinimal.toAmount.selector, token, input, false));
        output = abi.decode(_output, (uint256));
    }

    function _toShare(address token, uint256 input) internal view returns (uint256 output) {
        // @dev toShare(address,uint256,bool).
        (, bytes memory _output) = bento.staticcall(abi.encodeWithSelector(IBentoBoxMinimal.toShare.selector, token, input, false));
        output = abi.decode(_output, (uint256));
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 _reserve0,
        uint256 _reserve1,
        bool token0In
    ) internal view returns (uint256 dy) {
        uint256 xpIn;
        uint256 xpOut;

        if (token0In) {
            xpIn = _reserve0 * token0PrecisionMultiplier;
            xpOut = _reserve1 * token1PrecisionMultiplier;
            amountIn *= token0PrecisionMultiplier;
        } else {
            xpIn = _reserve1 * token1PrecisionMultiplier;
            xpOut = _reserve0 * token0PrecisionMultiplier;
            amountIn *= token1PrecisionMultiplier;
        }
        uint256 d = _computeLiquidityFromAdjustedBalances(xpIn, xpOut);
        uint256 x = xpIn + amountIn;
        uint256 y = _getY(x, d);
        dy = xpOut - y - 1;
        dy /= (token0In ? token1PrecisionMultiplier : token0PrecisionMultiplier);
    }

    function _transfer(
        address token,
        uint256 amount,
        address to,
        bool unwrapBento
    ) internal {
        if (unwrapBento) {
            // @dev withdraw(address,address,address,uint256,uint256).
            (bool success, ) = bento.call(abi.encodeWithSelector(IBentoBoxMinimal.withdraw.selector, token, address(this), to, amount, 0));
            require(success, "WITHDRAW_FAILED");
        } else {
            // @dev transfer(address,address,address,uint256).
            (bool success, ) = bento.call(abi.encodeWithSelector(IBentoBoxMinimal.transfer.selector, token, address(this), to, _toShare(token, amount)));
            require(success, "TRANSFER_FAILED");
        }
    }

    /// @notice Get D, the StableSwap invariant, based on a set of balances and a particular A.
    /// See the StableSwap paper for details.
    /// @dev Originally https://github.com/saddle-finance/saddle-contract/blob/0b76f7fb519e34b878aa1d58cffc8d8dc0572c12/contracts/SwapUtils.sol#L319.
    /// @return liquidity The invariant, at the precision of the pool.
    function _computeLiquidity(uint256 _reserve0, uint256 _reserve1) internal view returns (uint256 liquidity) {
        uint256 xp0 = _reserve0 * token0PrecisionMultiplier;
        uint256 xp1 = _reserve1 * token1PrecisionMultiplier;
        liquidity = _computeLiquidityFromAdjustedBalances(xp0, xp1);
    }

    function _computeLiquidityFromAdjustedBalances(uint256 xp0, uint256 xp1) internal view returns (uint256 computed) {
        uint256 s = xp0 + xp1;

        if (s == 0) {
            computed = 0;
        }
        uint256 prevD;
        uint256 D = s;
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            uint256 dP = (((D * D) / xp0) * D) / xp1 / 4;
            prevD = D;
            D = (((N_A * s) / A_PRECISION + 2 * dP) * D) / ((N_A / A_PRECISION - 1) * D + 3 * dP);
            if (D.within1(prevD)) {
                break;
            }
        }
        computed = D;
    }

    /// @notice Calculate the new balances of the tokens given the indexes of the token
    /// that is swapped from (FROM) and the token that is swapped to (TO).
    /// This function is used as a helper function to calculate how much TO token
    /// the user should receive on swap.
    /// @dev Originally https://github.com/saddle-finance/saddle-contract/blob/0b76f7fb519e34b878aa1d58cffc8d8dc0572c12/contracts/SwapUtils.sol#L432.
    /// @param x The new total amount of FROM token.
    /// @return y The amount of TO token that should remain in the pool.
    function _getY(uint256 x, uint256 D) internal view returns (uint256 y) {
        uint256 c = (D * D) / (x * 2);
        c = (c * D) / ((N_A * 2) / A_PRECISION);
        uint256 b = x + ((D * A_PRECISION) / N_A);
        uint256 yPrev;
        y = D;
        // @dev Iterative approximation.
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = (y * y + c) / (y * 2 + b - D);
            if (y.within1(yPrev)) {
                break;
            }
        }
    }

    /// @notice Calculate the price of a token in the pool given
    /// precision-adjusted balances and a particular D and precision-adjusted
    /// array of balances.
    /// @dev This is accomplished via solving the quadratic equation iteratively.
    /// See the StableSwap paper and Curve.fi implementation for further details.
    /// x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
    /// x_1**2 + b*x_1 = c
    /// x_1 = (x_1**2 + c) / (2*x_1 + b)
    /// @dev Originally https://github.com/saddle-finance/saddle-contract/blob/0b76f7fb519e34b878aa1d58cffc8d8dc0572c12/contracts/SwapUtils.sol#L276.
    /// @return y The price of the token, in the same precision as in xp.
    function _getYD(
        uint256 s, // @dev xpOut.
        uint256 d
    ) internal view returns (uint256 y) {
        uint256 c = (d * d) / (s * 2);
        c = (c * d) / ((N_A * 2) / A_PRECISION);

        uint256 b = s + ((d * A_PRECISION) / N_A);
        uint256 yPrev;
        y = d;

        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = (y * y + c) / (y * 2 + b - d);
            if (y.within1(yPrev)) {
                break;
            }
        }
    }

    function _handleFee(address tokenIn, uint256 amountIn) internal returns (uint256 fee) {
        fee = (amountIn * swapFee) / MAX_FEE;
        uint256 _barFee = (fee * barFee) / MAX_FEE;
        _transfer(tokenIn, _barFee, barFeeTo, false);
    }

    /// @dev This fee is charged to cover for `swapFee` when users add unbalanced liquidity.
    function _nonOptimalMintFee(
        uint256 _amount0,
        uint256 _amount1,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal view returns (uint256 token0Fee, uint256 token1Fee) {
        if (_reserve0 == 0 || _reserve1 == 0) return (0, 0);
        uint256 amount1Optimal = (_amount0 * _reserve1) / _reserve0;

        if (amount1Optimal <= _amount1) {
            token1Fee = (swapFee * (_amount1 - amount1Optimal)) / (2 * MAX_FEE);
        } else {
            uint256 amount0Optimal = (_amount1 * _reserve0) / _reserve1;
            token0Fee = (swapFee * (_amount0 - amount0Optimal)) / (2 * MAX_FEE);
        }
    }

    function getAssets() public view override returns (address[] memory assets) {
        assets = new address[](2);
        assets[0] = token0;
        assets[1] = token1;
    }

    function getAmountOut(bytes calldata data) public view override returns (uint256 finalAmountOut) {
        (address tokenIn, uint256 amountIn) = abi.decode(data, (address, uint256));
        (uint256 _reserve0, uint256 _reserve1) = _getReserves();
        amountIn = _toAmount(tokenIn, amountIn);
        amountIn -= (amountIn * swapFee) / MAX_FEE;

        if (tokenIn == token0) {
            finalAmountOut = _getAmountOut(amountIn, _reserve0, _reserve1, true);
        } else {
            finalAmountOut = _getAmountOut(amountIn, _reserve0, _reserve1, false);
        }
    }

    function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1) {
        (_reserve0, _reserve1) = _getReserves();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

import "../libraries/TridentMath.sol";

contract TridentMathConsumerMock {
    function sqrt(uint256 x) public pure returns (uint256) {
        return TridentMath.sqrt(x);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

import "../interfaces/IPoolFactory.sol";

import "./PoolTemplate.sol";

/**
 * @author Mudit Gupta
 */
contract PoolFactory is IPoolFactory {
    // Consider deploying via an upgradable proxy to allow upgrading pools in the future

    function deployPool(bytes memory _deployData) external override returns (address) {
        return address(new PoolTemplate(_deployData));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

/**
 * @author Mudit Gupta
 */
contract PoolTemplate {
    uint256 public immutable configValue;
    address public immutable anotherConfigValue;

    constructor(bytes memory _data) {
        (configValue, anotherConfigValue) = abi.decode(_data, (uint256, address));
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 99999
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  }
}