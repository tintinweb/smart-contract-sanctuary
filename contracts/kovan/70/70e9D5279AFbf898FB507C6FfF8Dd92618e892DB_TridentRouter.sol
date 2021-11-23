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

    uint256 public barFee;
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
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident pool deployment interface.
interface IPoolFactory {
    function deployPool(bytes calldata _deployData) external returns (address pool);

    function configAddress(bytes32 data) external returns (address pool);
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

pragma solidity 0.8.7;

import "../utils/TridentBatchable.sol";
import "../utils/TridentPermit.sol";
import "../interfaces/IBentoBoxMinimal.sol";
import "../interfaces/ITridentRouter.sol";
import "../interfaces/IMasterDeployer.sol";
import "../interfaces/IPoolFactory.sol";
import "../interfaces/IUniswapV2Minimal.sol";
import "../interfaces/IPool.sol";

/// @notice Liquidity migrator from UniV2 style pool to Trident Constant product pool.
contract TridentSushiRollCP is TridentBatchable, TridentPermit {
    error MinimumOutput();

    IBentoBoxMinimal internal immutable bentoBox;
    IPoolFactory internal immutable poolFactory;
    IMasterDeployer internal immutable masterDeployer;

    constructor(
        IBentoBoxMinimal _bentoBox,
        IPoolFactory _poolFactory,
        IMasterDeployer _masterDeployer
    ) {
        bentoBox = _bentoBox;
        poolFactory = _poolFactory;
        masterDeployer = _masterDeployer;
    }

    /** @notice Function to migrate existing Sushiswap or other Uniswap V2 style pools to Trident.
        @param pair Uniswap V2 style liquidity pool address.
        @param amount Liquidity amount (Lp token balance) to be migrated.
        @param swapFee Swap fee of the Trident CP pool we are migrating into.
        @param twapSupport Whether the Trident CP pool we are migrating into supports twap oracles.
        @param minReceived Slippage protection for minting liquidity on the Trident CP pool.
        @dev If the pool with the current conditions doesn't exist it will be deployed. */
    function migrate(
        IUniswapV2Minimal pair,
        uint256 amount,
        uint256 swapFee,
        bool twapSupport,
        uint256 minReceived
    ) external returns (uint256 liquidity) {
        address token0 = pair.token0();
        address token1 = pair.token1();

        bytes memory poolData = abi.encode(token0, token1, swapFee, twapSupport);
        address tridentPool = poolFactory.configAddress(keccak256(poolData));

        if (tridentPool == address(0)) {
            tridentPool = masterDeployer.deployPool(address(poolFactory), poolData);
        }

        pair.transferFrom(msg.sender, address(pair), amount);
        (uint256 amount0, uint256 amount1) = pair.burn(address(bentoBox));

        bentoBox.deposit(token0, address(bentoBox), tridentPool, amount0, 0);
        bentoBox.deposit(token1, address(bentoBox), tridentPool, amount1, 0);

        liquidity = IPool(tridentPool).mint(abi.encode(msg.sender));

        if (liquidity < minReceived) revert MinimumOutput();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Generic contract exposing the batch call functionality.
abstract contract TridentBatchable {
    /// @notice Provides batch function calls for this contract and returns the data from all of them if they all succeed.
    /// Adapted from https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/base/Multicall.sol, License-Identifier: GPL-2.0-or-later.
    /// @dev The `msg.value` should not be trusted for any method callable from this function.
    /// @param data ABI-encoded params for each of the calls to make to this contract.
    /// @return results The results from each of the calls passed in via `data`.
    function batch(bytes[] calldata data) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);

        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Generic contract exposing the permit functionality.
abstract contract TridentPermit {
    error PermitFailed();

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
        (bool success, ) = token.call(abi.encodeWithSelector(0xd505accf, msg.sender, address(this), amount, deadline, v, r, s)); // permit(address,address,uint256,uint256,uint8,bytes32,bytes32).
        if (!success) revert PermitFailed();
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
        (bool success, ) = token.call(abi.encodeWithSelector(0x8fcbaf0c, msg.sender, address(this), nonce, expiry, true, v, r, s)); // permit(address,address,uint256,uint256,bool,uint8,bytes32,bytes32).
        if (!success) revert PermitFailed();
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
    /// @param token The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount represented in shares.
    function deposit(
        address token,
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

    /// @dev Approves users' BentoBox assets to a "master" contract.
    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
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
        uint64 balancePercentage; // Multiplied by 10^6. 100% = 100_000_000
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

/// @notice Trident pool deployer interface.
interface IMasterDeployer {
    function barFee() external view returns (uint256);

    function barFeeTo() external view returns (address);

    function bento() external view returns (address);

    function migrator() external view returns (address);

    function pools(address pool) external view returns (bool);

    function deployPool(address factory, bytes calldata deployData) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./IERC20.sol";

/// @notice Minimal Uniswap V2 LP interface.
interface IUniswapV2Minimal is IERC20 {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);
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

    /// @notice Simulates a trade and returns the expected output.
    /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountIn The amount of input tokens that are required from the user if the trade is executed.
    function getAmountIn(bytes calldata data) external view returns (uint256 finalAmountIn);

    /// @dev This event must be emitted on all swaps.
    event Swap(address indexed recipient, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    /// @dev This struct frames output tokens for burns.
    struct TokenAmount {
        address token;
        uint256 amount;
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

/// @dev Use a library or custom safeTransfer{From} functions when dealing with unknown tokens!
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./interfaces/IPool.sol";
import "./interfaces/ITridentRouter.sol";
import "./utils/RouterHelper.sol";

/// @notice Router contract that helps in swapping across Trident pools.
contract TridentRouter is ITridentRouter, RouterHelper {
    /// @dev Used to ensure that `tridentSwapCallback` is called only by the authorized address.
    /// These are set when someone calls a flash swap and reset afterwards.
    address internal cachedMsgSender;
    address internal cachedPool;

    mapping(address => bool) internal whitelistedPools;

    constructor(
        IBentoBoxMinimal bento,
        IMasterDeployer masterDeployer,
        address wETH
    ) RouterHelper(bento, masterDeployer, wETH) {}

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

    /// @notice Deposit from the user's wallet into BentoBox.
    /// @dev Amount is the native token amount. We let BentoBox do the conversion into shares.
    function _depositToBentoBox(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        bento.deposit{value: token == USE_ETHEREUM ? amount : 0}(token, msg.sender, recipient, amount, 0);
    }

    /// @notice Same effect as _depositToBentoBox() but with a sender parameter.
    function _depositFromUserToBentoBox(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        bento.deposit{value: token == USE_ETHEREUM ? amount : 0}(token, sender, recipient, amount, 0);
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

import "../interfaces/IBentoBoxMinimal.sol";
import "../interfaces/IMasterDeployer.sol";
import "../TridentRouter.sol";
import "./TridentPermit.sol";

/// @notice Trident router helper contract.
contract RouterHelper is TridentPermit {
    /// @notice BentoBox token vault.
    IBentoBoxMinimal public immutable bento;
    /// @notice Trident AMM master deployer contract.
    IMasterDeployer public immutable masterDeployer;
    /// @notice ERC-20 token for wrapped ETH (v9).
    address internal immutable wETH;
    /// @notice The user should use 0x0 if they want to deposit ETH
    address constant USE_ETHEREUM = address(0);

    constructor(
        IBentoBoxMinimal _bento,
        IMasterDeployer _masterDeployer,
        address _wETH
    ) {
        bento = _bento;
        masterDeployer = _masterDeployer;
        wETH = _wETH;
        _bento.registerProtocol();
    }

    /// @notice Provides batch function calls for this contract and returns the data from all of them if they all succeed.
    /// Adapted from https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/base/Multicall.sol, License-Identifier: GPL-2.0-or-later.
    /// @dev The `msg.value` should not be trusted for any method callable from this function.
    /// @dev Uses a modified version of the batch function - preventing multiple calls of the single input swap functions
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
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577.
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
            results[i] = result;
        }
    }

    function deployPool(address factory, bytes calldata deployData) external payable returns (address) {
        return masterDeployer.deployPool(factory, deployData);
    }

    /// @notice Helper function to allow batching of BentoBox master contract approvals so the first trade can happen in one transaction.
    function approveMasterContract(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        bento.setMasterContractApproval(msg.sender, address(this), true, v, r, s);
    }

    /// @notice Provides gas-optimized balance check on this contract to avoid redundant extcodesize check in addition to returndatasize check.
    /// @param token Address of ERC-20 token.
    /// @return balance Token amount held by this contract.
    function balanceOfThis(address token) internal view returns (uint256 balance) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(0x70a08231, address(this))); // @dev balanceOf(address).
        require(success && data.length >= 32, "BALANCE_OF_FAILED");
        balance = abi.decode(data, (uint256));
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../utils/TridentBatchable.sol";
import "../utils/TridentPermit.sol";

/// @notice Interface for handling Balancer V1 LP.
interface IBalancerV1 {
    function getFinalTokens() external view returns (address[] memory);

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;
}

/// @notice Interface for handling Balancer V2 LP - `assets` aliased to address for code simplicity.
interface IBalancerV2 {
    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /// @notice Returns asset tokens from a Balancer V2 pool.
    function getPoolTokens(bytes32 poolId) external view returns (address[] memory);

    /// @notice Exits liquidity tokens from a Balancer V2 pool.
    function exitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest calldata request
    ) external;
}

/// @notice Minimal Uniswap V2 LP interface.
interface IUniswapV2Minimal {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);
}

/// @notice Interface for handling Uniswap V3 LP.
interface IUniswapV3 {
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    // @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}

/// @notice Minimal Trident pool router interface.
interface ITridentRouterMinimal {
    struct TokenInput {
        address token;
        bool native;
        uint256 amount;
    }

    /// @notice Add liquidity to a pool.
    /// @param tokenInput Token address and amount to add as liquidity.
    /// @param pool Pool address to add liquidity to.
    /// @param minLiquidity Minimum output liquidity - caps slippage.
    /// @param data Data required by the pool to add liquidity.
    function addLiquidity(
        TokenInput[] calldata tokenInput,
        address pool,
        uint256 minLiquidity,
        bytes calldata data
    ) external payable returns (uint256 liquidity);
}

/// @notice Liquidity migrator for Trident from popular pool types.
contract TridentSushiRoll {
    /* IBalancerV2 internal immutable balancerVault;
    IUniswapV3 internal immutable uniNonfungiblePositionManager;
    ITridentRouterMinimal internal immutable tridentRouter;

    constructor(
        IBalancerV2 _balancerVault,
        IUniswapV3 _uniNonfungiblePositionManager,
        ITridentRouterMinimal _tridentRouter
    ) {
        balancerVault = _balancerVault;
        uniNonfungiblePositionManager = _uniNonfungiblePositionManager;
        tridentRouter = _tridentRouter;
    }

    // **** BAL MIGRATOR **** //
    // --------------------- //

    function migrateFromBalancerV1toTrident(
        IBalancerV1 bPool,
        uint256 poolAmountIn,
        uint256[] calldata minAmountsOut,
        address tridentPool,
        uint256 minLiquidity,
        bytes calldata data
    ) external returns (uint256 liquidity) {
        address[] memory tokens = bPool.getFinalTokens();

        bPool.exitPool(poolAmountIn, minAmountsOut);

        ITridentRouterMinimal.TokenInput[] memory input = new ITridentRouterMinimal.TokenInput[](tokens.length);

        unchecked {
            for (uint256 i; i < tokens.length; i++) {
                input[i].token = tokens[i];
                input[i].native = true;
                input[i].amount = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).approve(address(tridentRouter), input[i].amount);
            }
        }

        liquidity = tridentRouter.addLiquidity(input, tridentPool, minLiquidity, data);
    }

    function migrateFromBalancerV2toTrident(
        bytes32 poolId,
        IBalancerV2.ExitPoolRequest calldata request,
        address tridentPool,
        uint256 minLiquidity,
        bytes calldata data
    ) external returns (uint256 liquidity) {
        address[] memory tokens = balancerVault.getPoolTokens(poolId);

        balancerVault.exitPool(poolId, msg.sender, address(this), request);

        ITridentRouterMinimal.TokenInput[] memory input = new ITridentRouterMinimal.TokenInput[](tokens.length);

        unchecked {
            for (uint256 i; i < tokens.length; i++) {
                input[i].token = tokens[i];
                input[i].native = true;
                input[i].amount = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).approve(address(tridentRouter), input[i].amount);
            }
        }

        liquidity = tridentRouter.addLiquidity(input, tridentPool, minLiquidity, data);
    }

    // **** UNI MIGRATOR **** //
    // --------------------- //

    function migrateFromUniswapV2toTrident(
        address pair,
        uint256 _liquidity,
        address pool,
        uint256 minLiquidity,
        bytes calldata data
    ) external returns (uint256 liquidity) {
        IERC20(pair).transferFrom(msg.sender, address(pair), _liquidity);

        IUniswapV2Minimal(pair).burn(address(this));

        ITridentRouterMinimal.TokenInput[] memory input = new ITridentRouterMinimal.TokenInput[](2);

        IERC20 token0 = IERC20(IUniswapV2Minimal(pair).token0());
        IERC20 token1 = IERC20(IUniswapV2Minimal(pair).token1());

        input[0].token = address(token0);
        input[0].native = true;
        input[0].amount = token0.balanceOf(address(this));

        input[1].token = address(token1);
        input[1].native = true;
        input[1].amount = token1.balanceOf(address(this));

        token0.approve(address(tridentRouter), input[0].amount);
        token1.approve(address(tridentRouter), input[1].amount);

        liquidity = ITridentRouterMinimal(tridentRouter).addLiquidity(input, pool, minLiquidity, data);
    }

    function migrateFromUniswapV3toTrident(
        IUniswapV3.DecreaseLiquidityParams calldata decreaseLiqParams,
        IUniswapV3.CollectParams calldata collectParams,
        address tridentPool,
        uint256 minLiquidity,
        bytes calldata data
    ) external returns (uint256 liquidity) {
        uniNonfungiblePositionManager.decreaseLiquidity(decreaseLiqParams);
        uniNonfungiblePositionManager.collect(collectParams);

        ITridentRouterMinimal.TokenInput[] memory input = new ITridentRouterMinimal.TokenInput[](2);

        (, , address token0, , , , , , , , , ) = uniNonfungiblePositionManager.positions(decreaseLiqParams.tokenId);
        (, , , address token1, , , , , , , , ) = uniNonfungiblePositionManager.positions(decreaseLiqParams.tokenId);

        input[0].token = token0;
        input[0].native = true;
        input[0].amount = IERC20(token0).balanceOf(address(this));

        input[1].token = token1;
        input[1].native = true;
        input[1].amount = IERC20(token1).balanceOf(address(this));

        liquidity = tridentRouter.addLiquidity(input, tridentPool, minLiquidity, data);
    } */
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../../interfaces/concentratedPool/IConcentratedLiquidityPoolManager.sol";
import "../../interfaces/concentratedPool/IPositionManager.sol";
import "../../interfaces/IMasterDeployer.sol";
import "../../interfaces/IBentoBoxMinimal.sol";
import "../../interfaces/ITridentRouter.sol";
import "../../libraries/concentratedPool/FullMath.sol";
import "../../libraries/concentratedPool/TickMath.sol";
import "../../libraries/concentratedPool/DyDxMath.sol";
import "../../utils/TridentBatchable.sol";
import "./TridentNFT.sol";

/// @notice Trident Concentrated Liquidity Pool periphery contract that combines non-fungible position management and staking.
contract ConcentratedLiquidityPoolManager is IPositionManager, IConcentratedLiquidityPoolManagerStruct, TridentNFT, TridentBatchable {
    event IncreaseLiquidity(address indexed pool, address indexed owner, uint256 indexed positionId, uint128 liquidity);
    event DecreaseLiquidity(address indexed pool, address indexed owner, uint256 indexed positionId, uint128 liquidity);

    IBentoBoxMinimal public immutable bento;
    IMasterDeployer public immutable masterDeployer;

    mapping(uint256 => Position) public positions;

    constructor(address _masterDeployer) {
        masterDeployer = IMasterDeployer(_masterDeployer);
        IBentoBoxMinimal _bento = IBentoBoxMinimal(IMasterDeployer(_masterDeployer).bento());
        _bento.registerProtocol();
        bento = _bento;
        _mint(address(0));
    }

    function positionMintCallback(
        address recipient,
        int24 lower,
        int24 upper,
        uint128 amount,
        uint256 feeGrowthInside0,
        uint256 feeGrowthInside1,
        uint256 _positionId
    ) external override returns (uint256 positionId) {
        require(IMasterDeployer(masterDeployer).pools(msg.sender), "NOT_POOL");

        if (_positionId == 0) {
            // We mint a new NFT.
            positions[totalSupply] = Position({
                pool: IConcentratedLiquidityPool(msg.sender),
                liquidity: amount,
                lower: lower,
                upper: upper,
                latestAddition: uint32(block.timestamp),
                feeGrowthInside0: feeGrowthInside0,
                feeGrowthInside1: feeGrowthInside1
            });
            positionId = totalSupply;
            _mint(recipient);
            emit IncreaseLiquidity(msg.sender, recipient, positionId, amount);
        } else if (amount > 0) {
            // We increase liquidity for an existing NFT.
            Position storage position = positions[_positionId];
            require(_positionId < totalSupply, "INVALID_POSITION");
            require(position.lower == lower && position.upper == upper, "RANGE_MIS_MATCH");
            require(position.feeGrowthInside0 == feeGrowthInside0 && position.feeGrowthInside1 == feeGrowthInside1, "UNCLAIMED");
            position.liquidity += amount;
            position.latestAddition = uint32(block.timestamp);
            emit IncreaseLiquidity(msg.sender, recipient, positionId, amount);
        }
    }

    function decreaseLiquidity(
        uint256 tokenId,
        uint128 amount,
        address recipient,
        bool unwrapBento
    ) external {
        require(msg.sender == ownerOf[tokenId], "NOT_ID_OWNER");
        Position storage position = positions[tokenId];

        IPool.TokenAmount[] memory withdrawAmounts;
        IPool.TokenAmount[] memory feeAmounts;
        uint256 oldLiquidity;

        if (amount < position.liquidity) {
            (withdrawAmounts, feeAmounts, oldLiquidity) = position.pool.decreaseLiquidity(
                position.lower,
                position.upper,
                amount,
                address(this),
                false
            );

            (position.feeGrowthInside0, position.feeGrowthInside1) = position.pool.rangeFeeGrowth(position.lower, position.upper);

            position.liquidity -= amount;
        } else {
            (withdrawAmounts, feeAmounts, oldLiquidity) = position.pool.decreaseLiquidity(
                position.lower,
                position.upper,
                position.liquidity,
                address(this),
                false
            );

            delete positions[tokenId];

            _burn(tokenId);
        }

        uint256 token0Amount = withdrawAmounts[0].amount + ((feeAmounts[0].amount * amount) / oldLiquidity);
        uint256 token1Amount = withdrawAmounts[1].amount + ((feeAmounts[1].amount * amount) / oldLiquidity);

        _transfer(withdrawAmounts[0].token, address(this), recipient, token0Amount, unwrapBento);
        _transfer(withdrawAmounts[1].token, address(this), recipient, token1Amount, unwrapBento);

        emit DecreaseLiquidity(address(position.pool), msg.sender, tokenId, amount);
    }

    function collect(
        uint256 tokenId,
        address recipient,
        bool unwrapBento
    ) public returns (uint256 token0amount, uint256 token1amount) {
        require(msg.sender == ownerOf[tokenId], "NOT_ID_OWNER");
        Position storage position = positions[tokenId];

        address[] memory tokens = position.pool.getAssets();
        address token0 = tokens[0];
        address token1 = tokens[1];

        (token0amount, token1amount, position.feeGrowthInside0, position.feeGrowthInside1) = positionFees(tokenId);

        uint256 balance0 = bento.balanceOf(token0, address(this));
        uint256 balance1 = bento.balanceOf(token1, address(this));

        if (balance0 < token0amount || balance1 < token1amount) {
            (uint256 amount0fees, uint256 amount1fees) = position.pool.collect(position.lower, position.upper, address(this), false);

            uint256 newBalance0 = amount0fees + balance0;
            uint256 newBalance1 = amount1fees + balance1;

            /// @dev Rounding errors due to frequent claiming of other users in the same position may cost us some wei units
            if (token0amount > newBalance0) token0amount = newBalance0;
            if (token1amount > newBalance1) token1amount = newBalance1;
        }

        _transfer(token0, address(this), recipient, token0amount, unwrapBento);
        _transfer(token1, address(this), recipient, token1amount, unwrapBento);
    }

    /// @notice Returns the claimable fees and the fee growth accumulators of a given position.
    function positionFees(uint256 tokenId)
        public
        view
        returns (
            uint256 token0amount,
            uint256 token1amount,
            uint256 feeGrowthInside0,
            uint256 feeGrowthInside1
        )
    {
        Position memory position = positions[tokenId];

        (feeGrowthInside0, feeGrowthInside1) = position.pool.rangeFeeGrowth(position.lower, position.upper);

        token0amount = FullMath.mulDiv(
            feeGrowthInside0 - position.feeGrowthInside0,
            position.liquidity,
            0x100000000000000000000000000000000
        );

        token1amount = FullMath.mulDiv(
            feeGrowthInside1 - position.feeGrowthInside1,
            position.liquidity,
            0x100000000000000000000000000000000
        );
    }

    function _transfer(
        address token,
        address from,
        address to,
        uint256 shares,
        bool unwrapBento
    ) internal {
        if (unwrapBento) {
            bento.withdraw(token, from, to, 0, shares);
        } else {
            bento.transfer(token, from, to, shares);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./IConcentratedLiquidityPool.sol";
import "./../ITridentNFT.sol";

/// @notice Trident concentrated liquidity manager contract Struct.
/// @dev Split out struct and function declarations due to solidity quirks.
interface IConcentratedLiquidityPoolManagerStruct {
    struct Position {
        IConcentratedLiquidityPool pool;
        uint128 liquidity;
        int24 lower;
        int24 upper;
        uint32 latestAddition;
        uint256 feeGrowthInside0; /// @dev Per unit of liquidity.
        uint256 feeGrowthInside1;
    }
}

/// @notice Trident concentrated liquidity manager contract interface.
interface IConcentratedLiquidityPoolManager is IConcentratedLiquidityPoolManagerStruct, ITridentNFT {
    function positions(uint256) external view returns (Position memory);

    function bento() external view returns (IBentoBoxMinimal);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident concentrated Liquidity pool mint callback receiver.
interface IPositionManager {
    function positionMintCallback(
        address recipient,
        int24 lower,
        int24 upper,
        uint128 amount,
        uint256 feeGrowthInside0,
        uint256 feeGrowthInside1,
        uint256 positionId
    ) external returns (uint256 _positionId);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/// @notice Math library that facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision.
/// @author Adapted from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/FullMath.sol.
/// @dev Handles "phantom overflow", i.e., allows multiplication and division where an intermediate value overflows 256 bits.
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision - throws if result overflows an uint256 or denominator == 0.
    /// @param a The multiplicand.
    /// @param b The multiplier.
    /// @param denominator The divisor.
    /// @return result The 256-bit result.
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b.
            // Compute the product mod 2**256 and mod 2**256 - 1,
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product.
            uint256 prod1; // Most significant 256 bits of the product.
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }
            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }
            // Make sure the result is less than 2**256 -
            // also prevents denominator == 0.
            require(denominator > prod1);
            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////
            // Make division exact by subtracting the remainder from [prod1 prod0] -
            // compute remainder using mulmod.
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number.
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }
            // Factor powers of two out of denominator -
            // compute largest power of two divisor of denominator
            // (always >= 1).
            uint256 twos = uint256(-int256(denominator)) & denominator;
            // Divide denominator by power of two.
            assembly {
                denominator := div(denominator, twos)
            }
            // Divide [prod1 prod0] by the factors of two.
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos -
            // if twos is zero, then it becomes one.
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;
            // Invert denominator mod 2**256 -
            // now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // for four bits. That is, denominator * inv = 1 mod 2**4.
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // Inverse mod 2**8.
            inv *= 2 - denominator * inv; // Inverse mod 2**16.
            inv *= 2 - denominator * inv; // Inverse mod 2**32.
            inv *= 2 - denominator * inv; // Inverse mod 2**64.
            inv *= 2 - denominator * inv; // Inverse mod 2**128.
            inv *= 2 - denominator * inv; // Inverse mod 2**256.
            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision - throws if result overflows an uint256 or denominator == 0.
    /// @param a The multiplicand.
    /// @param b The multiplier.
    /// @param denominator The divisor.
    /// @return result The 256-bit result.
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) != 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

/// @notice Math library for computing sqrt price for ticks of size 1.0001, i.e., sqrt(1.0001^tick) as fixed point Q64.96 numbers - supports
/// prices between 2**-128 and 2**128 - 1.
/// @author Adapted from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/TickMath.sol.
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128.
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128 - 1.
    int24 internal constant MAX_TICK = -MIN_TICK;
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick - equivalent to getSqrtRatioAtTick(MIN_TICK).
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick - equivalent to getSqrtRatioAtTick(MAX_TICK).
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    error TickOutOfBounds();
    error PriceOutOfBounds();

    /// @notice Calculates sqrt(1.0001^tick) * 2^96.
    /// @dev Throws if |tick| > max tick.
    /// @param tick The input tick for the above formula.
    /// @return sqrtPriceX96 Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick.
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        if (absTick > uint256(uint24(MAX_TICK))) revert TickOutOfBounds();
        unchecked {
            uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;
            // This divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // We then downcast because we know the result always fits within 160 bits due to our tick input constraint.
            // We round up in the division so getTickAtSqrtRatio of the output price is always consistent.
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio.
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96.
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio.
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // Second inequality must be < because the price can never reach the price at the max tick.
        if (sqrtPriceX96 < MIN_SQRT_RATIO || sqrtPriceX96 >= MAX_SQRT_RATIO) revert PriceOutOfBounds();
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }
        unchecked {
            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number.

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./FullMath.sol";
import "./UnsafeMath.sol";

/// @notice Math library that facilitates ranged liquidity calculations.
library DyDxMath {
    function getDy(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dy) {
        unchecked {
            if (roundUp) {
                dy = FullMath.mulDivRoundingUp(liquidity, priceUpper - priceLower, 0x1000000000000000000000000);
            } else {
                dy = FullMath.mulDiv(liquidity, priceUpper - priceLower, 0x1000000000000000000000000);
            }
        }
    }

    function getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dx) {
        unchecked {
            if (roundUp) {
                dx = UnsafeMath.divRoundingUp(FullMath.mulDivRoundingUp(liquidity << 96, priceUpper - priceLower, priceUpper), priceLower);
            } else {
                dx = FullMath.mulDiv(liquidity << 96, priceUpper - priceLower, priceUpper) / priceLower;
            }
        }
    }

    function getLiquidityForAmounts(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 dy,
        uint256 dx
    ) public pure returns (uint256 liquidity) {
        unchecked {
            if (priceUpper <= currentPrice) {
                liquidity = FullMath.mulDiv(dy, 0x1000000000000000000000000, priceUpper - priceLower);
            } else if (currentPrice <= priceLower) {
                liquidity = FullMath.mulDiv(
                    dx,
                    FullMath.mulDiv(priceLower, priceUpper, 0x1000000000000000000000000),
                    priceUpper - priceLower
                );
            } else {
                uint256 liquidity0 = FullMath.mulDiv(
                    dx,
                    FullMath.mulDiv(priceUpper, currentPrice, 0x1000000000000000000000000),
                    priceUpper - currentPrice
                );
                uint256 liquidity1 = FullMath.mulDiv(dy, 0x1000000000000000000000000, currentPrice - priceLower);
                liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
            }
        }
    }

    function getAmountsForLiquidity(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 liquidityAmount,
        bool roundUp
    ) internal pure returns (uint128 token0amount, uint128 token1amount) {
        if (priceUpper <= currentPrice) {
            // Only supply `token1` (`token1` is Y).
            token1amount = uint128(DyDxMath.getDy(liquidityAmount, priceLower, priceUpper, roundUp));
        } else if (currentPrice <= priceLower) {
            // Only supply `token0` (`token0` is X).
            token0amount = uint128(DyDxMath.getDx(liquidityAmount, priceLower, priceUpper, roundUp));
        } else {
            // Supply both tokens.
            token0amount = uint128(DyDxMath.getDx(liquidityAmount, currentPrice, priceUpper, roundUp));
            token1amount = uint128(DyDxMath.getDy(liquidityAmount, priceLower, currentPrice, roundUp));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident Concentrated Liquidity Pool ERC-721 implementation with ERC-20/EIP-2612-like extensions,
// as well as partially, MetaData and Enumerable extensions.
/// @author Adapted from RariCapital, https://github.com/Rari-Capital/solmate/blob/main/src/erc721/ERC721.sol,
// License-Identifier: AGPL-3.0-only, and Shoyu, https://github.com/sushiswap/shoyu/blob/master/contracts/base/BaseNFT721.sol,
// License-Identifier: MIT.
abstract contract TridentNFT {
    event Transfer(address indexed sender, address indexed recipient, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public constant name = "TridentNFT";
    string public constant symbol = "tNFT";
    /// @notice Tracks total liquidity range positions.
    uint256 public totalSupply;
    /// @notice 'owner' -> balance mapping.
    mapping(address => uint256) public balanceOf;
    /// @notice `tokenId` -> 'owner' mapping.
    mapping(uint256 => address) public ownerOf;
    /// @notice `tokenId` -> 'spender' mapping.
    mapping(uint256 => address) public getApproved;
    /// @notice 'owner' -> 'operator' status mapping.
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @notice EIP-712 typehash for this contract's {permit} struct for {approve}.
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    /// @notice EIP-712 typehash for this contract's {permitAll} struct for {setApprovalForAll}.
    bytes32 public constant PERMIT_ALL_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 nonce,uint256 deadline)");

    /// @notice Chain Id at this contract's deployment.
    uint256 internal immutable DOMAIN_SEPARATOR_CHAIN_ID;
    /// @notice EIP-712 typehash for this contract's domain at deployment.
    bytes32 internal immutable _DOMAIN_SEPARATOR;
    /// @notice 'tokenId' -> `nonce` mapping used in {permit} for {approve}.
    mapping(uint256 => uint256) public nonces;
    /// @notice 'owner' -> `tokenId` mapping used in {permitAll} for {setApprovalForAll}.
    mapping(address => uint256) public noncesForAll;

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

    /// @notice Provides ERC-165-compatible confirmation for ERC-721 interfaces supported by this contract.
    /// @param interfaceId XOR of all function selectors in the reference interface.
    /// @return supported Returns 'true' if `interfaceId` is flagged as implemented.
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    /// @notice Approves `tokenId` from `msg.sender` 'owner' or 'operator' to be spent by `spender`.
    /// @param spender Address of the party that can pull `tokenId` from 'owner''s account.
    /// @param tokenId The Id to approve for `spender`.
    function approve(address spender, uint256 tokenId) external {
        address owner = ownerOf[tokenId];
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_APPROVED");
        getApproved[tokenId] = spender;
        emit Approval(owner, spender, tokenId);
    }

    /// @notice Approves an 'operator' for `msg.sender` 'owner' that can spend or {approve} spends of 'owner''s `tokenId`s.
    /// @param operator Address of the party that can pull `tokenId`s from 'owner''s account or approve others to do same.
    /// @param approved The approval status of `operator`.
    function setApprovalForAll(address operator, bool approved) external {
        require(operator != address(0), "INVALID_OPERATOR");
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Transfers `tokenId` from 'owner' to `recipient`. Caller needs ownership.
    /// @param recipient The address to move `tokenId` to.
    /// @param tokenId The Id to move.
    function transfer(address recipient, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        _transfer(msg.sender, recipient, tokenId);
    }

    /// @notice Transfers `tokenId` from 'owner' to `recipient`. Caller needs ownership or approval from 'owner'.
    /// @param recipient The address to move `tokenId` to.
    /// @param tokenId The Id to move.
    function transferFrom(
        address,
        address recipient,
        uint256 tokenId
    ) public {
        address owner = ownerOf[tokenId];
        require(msg.sender == owner || msg.sender == getApproved[tokenId] || isApprovedForAll[owner][msg.sender], "NOT_APPROVED");
        _transfer(owner, recipient, tokenId);
    }

    /// @notice Transfers `tokenId` from 'owner' to `recipient` with no data. Caller needs ownership or approval from 'owner',
    /// and `recipient` must have compatible {onERC721Received} function.
    /// @param recipient The address to move `tokenId` to.
    /// @param tokenId The Id to move.
    function safeTransferFrom(
        address,
        address recipient,
        uint256 tokenId
    ) external {
        safeTransferFrom(address(0), recipient, tokenId, "");
    }

    /// @notice Transfers `tokenId` from 'owner' to `recipient` with data. Caller needs ownership or approval from 'owner',
    /// and `recipient` must have compatible {onERC721Received} function.
    /// @param recipient The address to move `tokenId` to.
    /// @param tokenId The Id to move.
    function safeTransferFrom(
        address,
        address recipient,
        uint256 tokenId,
        bytes memory data
    ) public {
        transferFrom(address(0), recipient, tokenId);
        if (recipient.code.length != 0) {
            /// @dev `onERC721Received(address,address,uint,bytes)`.
            (, bytes memory returned) = recipient.staticcall(abi.encodeWithSelector(0x150b7a02, msg.sender, address(0), tokenId, data));
            bytes4 selector = abi.decode(returned, (bytes4));
            require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
        }
    }

    /// @notice Triggers an approval from 'owner' to `spender` for a given `tokenId`.
    /// @param spender The address to be approved.
    /// @param tokenId The Id that is approved for `spender`.
    /// @param deadline The time at which to expire the signature.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");
        address owner = ownerOf[tokenId];
        /// @dev This is reasonably safe from overflow - incrementing `nonces` beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonces[tokenId]++, deadline))
                )
            );
            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0), "INVALID_PERMIT_SIGNATURE");
            require(recoveredAddress == owner || isApprovedForAll[owner][recoveredAddress], "INVALID_SIGNER");
        }
        getApproved[tokenId] = spender;
        emit Approval(owner, spender, tokenId);
    }

    /// @notice Triggers an approval from 'owner' to `operator` that can spend or {approve} spends of 'owner''s `tokenId`s.
    /// @param owner The address to be approved.
    /// @param operator Address of the party that can pull `tokenId`s from 'owner''s account or approve others to do same.
    /// @param deadline The time at which to expire the signature.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function permitAll(
        address owner,
        address operator,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");
        /// @dev This is reasonably safe from overflow - incrementing `nonces` beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_ALL_TYPEHASH, owner, operator, noncesForAll[owner]++, deadline))
                )
            );
            address recoveredAddress = ecrecover(digest, v, r, s);
            require(
                (recoveredAddress != address(0) && recoveredAddress == owner) || isApprovedForAll[owner][recoveredAddress],
                "INVALID_PERMIT_SIGNATURE"
            );
        }
        isApprovedForAll[owner][operator] = true;
        emit ApprovalForAll(owner, operator, true);
    }

    function _mint(address recipient) internal {
        /// @dev This is reasonably safe from overflow - incrementing beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits.
        unchecked {
            uint256 tokenId = totalSupply++;
            require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");
            balanceOf[recipient]++;
            ownerOf[tokenId] = recipient;
            emit Transfer(address(0), recipient, tokenId);
        }
    }

    function _burn(uint256 tokenId) internal {
        // @dev We tranfer the NFT to address(0) rather than burning to keep Total Supply static.
        address owner = ownerOf[tokenId];
        require(owner != address(0), "NOT_MINTED");
        _transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        /// @dev This is safe from under/overflow -
        // ownership is checked against decrement,
        // and sum of all user balances can't reasonably exceed type(uint256).max (see {_mint}).
        unchecked {
            balanceOf[from]--;
            balanceOf[to]++;
        }
        delete getApproved[tokenId];
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./../IPool.sol";
import "./../IBentoBoxMinimal.sol";
import "./../IMasterDeployer.sol";
import "../../libraries/concentratedPool/Ticks.sol";

/// @notice Trident Concentrated Liquidity Pool interface.
interface IConcentratedLiquidityPool is IPool {
    function price() external view returns (uint160);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function ticks(int24 _tick) external view returns (Ticks.Tick memory tick);

    function feeGrowthGlobal0() external view returns (uint256);

    function feeGrowthGlobal1() external view returns (uint256);

    function rangeFeeGrowth(int24 lowerTick, int24 upperTick) external view returns (uint256 feeGrowthInside0, uint256 feeGrowthInside1);

    function collect(
        int24,
        int24,
        address,
        bool
    ) external returns (uint256 amount0fees, uint256 amount1fees);

    function decreaseLiquidity(
        int24 lower,
        int24 upper,
        uint128 amount,
        address recipient,
        bool unwrapBento
    )
        external
        returns (
            TokenAmount[] memory withdrawnAmounts,
            TokenAmount[] memory feesWithdrawn,
            uint256 oldLiquidity
        );

    function getImmutables()
        external
        view
        returns (
            uint128 _MAX_TICK_LIQUIDITY,
            uint24 _tickSpacing,
            uint24 _swapFee,
            address _barFeeTo,
            IBentoBoxMinimal _bento,
            IMasterDeployer _masterDeployer,
            address _token0,
            address _token1
        );

    function getPriceAndNearestTicks() external view returns (uint160 _price, int24 _nearestTick);

    function getTokenProtocolFees() external view returns (uint128 _token0ProtocolFee, uint128 _token1ProtocolFee);

    function getReserves() external view returns (uint128 _reserve0, uint128 _reserve1);

    function getSecondsGrowthAndLastObservation() external view returns (uint160 _secondGrowthGlobal, uint32 _lastObservation);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident NFT interface.
interface ITridentNFT {
    function ownerOf(uint256) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import "./TickMath.sol";

/// @notice Tick management library for ranged liquidity.
library Ticks {
    struct Tick {
        int24 previousTick;
        int24 nextTick;
        uint128 liquidity;
        uint256 feeGrowthOutside0; // Per unit of liquidity.
        uint256 feeGrowthOutside1;
        uint160 secondsGrowthOutside;
    }

    function getMaxLiquidity(uint24 _tickSpacing) public pure returns (uint128) {
        return type(uint128).max / uint128(uint24(TickMath.MAX_TICK) / (2 * uint24(_tickSpacing)));
    }

    function cross(
        mapping(int24 => Tick) storage ticks,
        int24 nextTickToCross,
        uint160 secondsGrowthGlobal,
        uint256 currentLiquidity,
        uint256 feeGrowthGlobal,
        bool zeroForOne
    ) internal returns (uint256, int24) {
        ticks[nextTickToCross].secondsGrowthOutside = secondsGrowthGlobal - ticks[nextTickToCross].secondsGrowthOutside;
        if (zeroForOne) {
            // Moving forward through the linked list.
            if (nextTickToCross % 2 == 0) {
                currentLiquidity -= ticks[nextTickToCross].liquidity;
            } else {
                currentLiquidity += ticks[nextTickToCross].liquidity;
            }
            nextTickToCross = ticks[nextTickToCross].previousTick;
            ticks[nextTickToCross].feeGrowthOutside0 = feeGrowthGlobal - ticks[nextTickToCross].feeGrowthOutside0;
        } else {
            // Moving backwards through the linked list.
            if (nextTickToCross % 2 == 0) {
                currentLiquidity += ticks[nextTickToCross].liquidity;
            } else {
                currentLiquidity -= ticks[nextTickToCross].liquidity;
            }
            nextTickToCross = ticks[nextTickToCross].nextTick;
            ticks[nextTickToCross].feeGrowthOutside1 = feeGrowthGlobal - ticks[nextTickToCross].feeGrowthOutside1;
        }

        return (currentLiquidity, nextTickToCross);
    }

    function insert(
        mapping(int24 => Tick) storage ticks,
        uint256 feeGrowthGlobal0,
        uint256 feeGrowthGlobal1,
        uint160 secondsGrowthGlobal,
        int24 lowerOld,
        int24 lower,
        int24 upperOld,
        int24 upper,
        uint128 amount,
        int24 nearestTick,
        uint160 currentPrice
    ) public returns (int24) {
        require(lower < upper, "WRONG_ORDER");
        require(TickMath.MIN_TICK <= lower, "LOWER_RANGE");
        require(upper <= TickMath.MAX_TICK, "UPPER_RANGE");

        {
            // Stack overflow.
            uint128 currentLowerLiquidity = ticks[lower].liquidity;
            if (currentLowerLiquidity != 0 || lower == TickMath.MIN_TICK) {
                // We are adding liquidity to an existing tick.
                ticks[lower].liquidity = currentLowerLiquidity + amount;
            } else {
                // We are inserting a new tick.
                Ticks.Tick storage old = ticks[lowerOld];
                int24 oldNextTick = old.nextTick;

                require((old.liquidity != 0 || lowerOld == TickMath.MIN_TICK) && lowerOld < lower && lower < oldNextTick, "LOWER_ORDER");

                if (lower <= nearestTick) {
                    ticks[lower] = Ticks.Tick(lowerOld, oldNextTick, amount, feeGrowthGlobal0, feeGrowthGlobal1, secondsGrowthGlobal);
                } else {
                    ticks[lower] = Ticks.Tick(lowerOld, oldNextTick, amount, 0, 0, 0);
                }

                old.nextTick = lower;
                ticks[oldNextTick].previousTick = lower;
            }
        }

        uint128 currentUpperLiquidity = ticks[upper].liquidity;
        if (currentUpperLiquidity != 0 || upper == TickMath.MAX_TICK) {
            // We are adding liquidity to an existing tick.
            ticks[upper].liquidity = currentUpperLiquidity + amount;
        } else {
            // Inserting a new tick.
            Ticks.Tick storage old = ticks[upperOld];
            int24 oldNextTick = old.nextTick;

            require(old.liquidity != 0 && oldNextTick > upper && upperOld < upper, "UPPER_ORDER");

            if (upper <= nearestTick) {
                ticks[upper] = Ticks.Tick(upperOld, oldNextTick, amount, feeGrowthGlobal0, feeGrowthGlobal1, secondsGrowthGlobal);
            } else {
                ticks[upper] = Ticks.Tick(upperOld, oldNextTick, amount, 0, 0, 0);
            }
            old.nextTick = upper;
            ticks[oldNextTick].previousTick = upper;
        }

        int24 actualNearestTick = TickMath.getTickAtSqrtRatio(currentPrice);

        if (nearestTick < upper && upper <= actualNearestTick) {
            nearestTick = upper;
        } else if (nearestTick < lower && lower <= actualNearestTick) {
            nearestTick = lower;
        }

        return nearestTick;
    }

    function remove(
        mapping(int24 => Tick) storage ticks,
        int24 lower,
        int24 upper,
        uint128 amount,
        int24 nearestTick
    ) public returns (int24) {
        Ticks.Tick storage current = ticks[lower];

        if (lower != TickMath.MIN_TICK && current.liquidity == amount) {
            // Delete lower tick.
            Ticks.Tick storage previous = ticks[current.previousTick];
            Ticks.Tick storage next = ticks[current.nextTick];

            previous.nextTick = current.nextTick;
            next.previousTick = current.previousTick;

            if (nearestTick == lower) nearestTick = current.previousTick;

            delete ticks[lower];
        } else {
            unchecked {
                current.liquidity -= amount;
            }
        }

        current = ticks[upper];

        if (upper != TickMath.MAX_TICK && current.liquidity == amount) {
            // Delete upper tick.
            Ticks.Tick storage previous = ticks[current.previousTick];
            Ticks.Tick storage next = ticks[current.nextTick];

            previous.nextTick = current.nextTick;
            next.previousTick = current.previousTick;

            if (nearestTick == upper) nearestTick = current.previousTick;

            delete ticks[upper];
        } else {
            unchecked {
                current.liquidity -= amount;
            }
        }

        return nearestTick;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.5.0;

/// @notice Math library that contains methods that perform common math functions but do not do any overflow or underflow checks.
/// @author Adapted from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/UnsafeMath.sol.
library UnsafeMath {
    /// @notice Returns ceil(x / y).
    /// @dev Division by 0 has unspecified behavior, and must be checked externally.
    /// @param x The dividend.
    /// @param y The divisor.
    /// @return z The quotient, ceil(x / y).
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../../interfaces/IBentoBoxMinimal.sol";
import "../../interfaces/IMasterDeployer.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/concentratedPool/IPositionManager.sol";
import "../../interfaces/ITridentCallee.sol";
import "../../interfaces/ITridentRouter.sol";
import "../../libraries/concentratedPool/FullMath.sol";
import "../../libraries/concentratedPool/TickMath.sol";
import "../../libraries/concentratedPool/UnsafeMath.sol";
import "../../libraries/concentratedPool/DyDxMath.sol";
import "../../libraries/concentratedPool/SwapLib.sol";
import "../../libraries/concentratedPool/Ticks.sol";

/// @notice Trident exchange pool template implementing concentrated liquidity for swapping between an ERC-20 token pair.
/// @dev Amounts are considered to be in Bentobox shared
contract ConcentratedLiquidityPool is IPool {
    using Ticks for mapping(int24 => Ticks.Tick);

    event Mint(address indexed owner, uint256 amount0, uint256 amount1);
    event Burn(address indexed owner, uint256 amount0, uint256 amount1);
    event Collect(address indexed sender, uint256 amount0, uint256 amount1);
    event Sync(uint256 reserveShares0, uint256 reserveShares1);

    bytes32 public constant override poolIdentifier = "Trident:ConcentratedLiquidity";

    uint24 internal constant MAX_FEE = 100000; /// @dev Maximum `swapFee` is 10%.
    /// @dev References for tickSpacing:
    /// 100 tickSpacing -> 2% between ticks.
    uint24 internal immutable tickSpacing;
    uint24 internal immutable swapFee; /// @dev 1000 corresponds to 0.1% fee. Fee is measured in pips.
    uint128 internal immutable MAX_TICK_LIQUIDITY;

    address internal immutable barFeeTo;
    IBentoBoxMinimal internal immutable bento;
    IMasterDeployer internal immutable masterDeployer;

    address internal immutable token0;
    address internal immutable token1;

    uint128 public liquidity;

    uint160 internal secondsGrowthGlobal; /// @dev Multiplied by 2^128.
    uint32 internal lastObservation;

    uint256 public feeGrowthGlobal0; /// @dev All fee growth counters are multiplied by 2^128.
    uint256 public feeGrowthGlobal1;

    uint256 public barFee;

    uint128 internal token0ProtocolFee;
    uint128 internal token1ProtocolFee;

    uint128 internal reserve0; /// @dev `bento` share balance tracker.
    uint128 internal reserve1;

    uint160 internal price; /// @dev Sqrt of price aka. √(y/x), multiplied by 2^96.
    int24 internal nearestTick; /// @dev Tick that is just below the current price.

    uint256 internal unlocked;

    mapping(int24 => Ticks.Tick) public ticks;
    mapping(address => mapping(int24 => mapping(int24 => Position))) public positions;

    struct Position {
        uint128 liquidity;
        uint256 feeGrowthInside0Last;
        uint256 feeGrowthInside1Last;
    }

    struct SwapCache {
        uint256 feeAmount;
        uint256 totalFeeAmount;
        uint256 protocolFee;
        uint256 feeGrowthGlobal;
        uint256 currentPrice;
        uint256 currentLiquidity;
        uint256 input;
        int24 nextTickToCross;
    }

    struct MintParams {
        int24 lowerOld;
        int24 lower;
        int24 upperOld;
        int24 upper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        bool token0native;
        bool token1native;
        address positionOwner; // To mint an NFT the positionOwner should be set to the positionManager contract.
        address positionRecipient;
        uint256 positionId;
    }

    /// @dev Error list to optimize around pool requirements.
    error Locked();
    error ZeroAddress();
    error InvalidToken();
    error InvalidSwapFee();
    error LiquidityOverflow();
    error Token0Missing();
    error Token1Missing();
    error InvalidTick();
    error LowerEven();
    error UpperOdd();
    error MaxTickLiquidity();
    error Overflow();

    modifier lock() {
        if (unlocked == 2) revert Locked();
        unlocked = 2;
        _;
        unlocked = 1;
    }

    /// @dev Only set immutable variables here - state changes made here will not be used.
    constructor(bytes memory _deployData, IMasterDeployer _masterDeployer) {
        (address _token0, address _token1, uint24 _swapFee, uint160 _price, uint24 _tickSpacing) = abi.decode(
            _deployData,
            (address, address, uint24, uint160, uint24)
        );

        if (_token0 == address(0)) revert ZeroAddress();
        if (_token0 == address(this)) revert InvalidToken();
        if (_token1 == address(this)) revert InvalidToken();
        if (_swapFee > MAX_FEE) revert InvalidSwapFee();

        token0 = _token0;
        token1 = _token1;
        swapFee = _swapFee;
        price = _price;
        tickSpacing = _tickSpacing;
        // Prevents global liquidity overflow in the case all ticks are initialised.
        MAX_TICK_LIQUIDITY = Ticks.getMaxLiquidity(_tickSpacing);
        ticks[TickMath.MIN_TICK] = Ticks.Tick(TickMath.MIN_TICK, TickMath.MAX_TICK, uint128(0), 0, 0, 0);
        ticks[TickMath.MAX_TICK] = Ticks.Tick(TickMath.MIN_TICK, TickMath.MAX_TICK, uint128(0), 0, 0, 0);
        nearestTick = TickMath.MIN_TICK;
        bento = IBentoBoxMinimal(_masterDeployer.bento());
        barFeeTo = _masterDeployer.barFeeTo();
        barFee = _masterDeployer.barFee();
        masterDeployer = _masterDeployer;
        unlocked = 1;
    }

    /// @dev Mints LP tokens - should be called via the router after transferring `bento` tokens.
    /// The router must ensure that sufficient liquidity has been minted.
    function mint(bytes calldata data) public override lock returns (uint256 _liquidity) {
        MintParams memory mintParams = abi.decode(data, (MintParams));

        uint256 priceLower = uint256(TickMath.getSqrtRatioAtTick(mintParams.lower));
        uint256 priceUpper = uint256(TickMath.getSqrtRatioAtTick(mintParams.upper));
        uint256 currentPrice = uint256(price);

        _liquidity = DyDxMath.getLiquidityForAmounts(
            priceLower,
            priceUpper,
            currentPrice,
            mintParams.amount1Desired,
            mintParams.amount0Desired
        );

        unchecked {
            (uint256 amount0fees, uint256 amount1fees, ) = _updatePosition(
                mintParams.positionOwner,
                mintParams.lower,
                mintParams.upper,
                int128(uint128(_liquidity))
            );
            if (amount0fees > 0) {
                _transfer(token0, amount0fees, mintParams.positionOwner, false);
                reserve0 -= uint128(amount0fees);
            }
            if (amount1fees > 0) {
                _transfer(token1, amount1fees, mintParams.positionOwner, false);
                reserve1 -= uint128(amount1fees);
            }
        }

        unchecked {
            if (priceLower < currentPrice && currentPrice < priceUpper) liquidity += uint128(_liquidity);
        }

        _ensureTickSpacing(mintParams.lower, mintParams.upper);

        nearestTick = Ticks.insert(
            ticks,
            feeGrowthGlobal0,
            feeGrowthGlobal1,
            secondsGrowthGlobal,
            mintParams.lowerOld,
            mintParams.lower,
            mintParams.upperOld,
            mintParams.upper,
            uint128(_liquidity),
            nearestTick,
            uint160(currentPrice)
        );

        (uint128 amount0Actual, uint128 amount1Actual) = DyDxMath.getAmountsForLiquidity(
            priceLower,
            priceUpper,
            currentPrice,
            _liquidity,
            true
        );

        {
            ITridentRouter.TokenInput[] memory callbackData = new ITridentRouter.TokenInput[](2);
            callbackData[0] = ITridentRouter.TokenInput(token0, mintParams.token0native, amount0Actual);
            callbackData[1] = ITridentRouter.TokenInput(token1, mintParams.token1native, amount1Actual);
            ITridentCallee(msg.sender).tridentMintCallback(abi.encode(callbackData));
        }

        unchecked {
            if (amount0Actual != 0) {
                if (amount0Actual + reserve0 > _balance(token0)) revert Token0Missing();
                reserve0 += amount0Actual;
            }

            if (amount1Actual != 0) {
                if (amount1Actual + reserve1 > _balance(token1)) revert Token1Missing();
                reserve1 += amount1Actual;
            }
        }

        (uint256 feeGrowth0, uint256 feeGrowth1) = rangeFeeGrowth(mintParams.lower, mintParams.upper);

        if (mintParams.positionRecipient != address(0)) {
            IPositionManager(mintParams.positionOwner).positionMintCallback(
                mintParams.positionRecipient,
                mintParams.lower,
                mintParams.upper,
                uint128(_liquidity),
                feeGrowth0,
                feeGrowth1,
                mintParams.positionId
            );
        }

        emit Mint(mintParams.positionOwner, amount0Actual, amount1Actual);
    }

    /// @notice Burn function that cannpt conform to the IPool interface due to having three return values.
    /// @dev Burns LP tokens sent to this contract.
    function decreaseLiquidity(
        int24 lower,
        int24 upper,
        uint128 amount,
        address recipient,
        bool unwrapBento
    )
        public
        returns (
            IPool.TokenAmount[] memory withdrawnAmounts,
            IPool.TokenAmount[] memory feesWithdrawn,
            uint256 oldLiquidity
        )
    {
        uint256 amount0;
        uint256 amount1;

        {
            uint160 priceLower = TickMath.getSqrtRatioAtTick(lower);
            uint160 priceUpper = TickMath.getSqrtRatioAtTick(upper);
            uint160 currentPrice = price;

            unchecked {
                if (priceLower < currentPrice && currentPrice < priceUpper) liquidity -= amount;
            }

            (amount0, amount1) = DyDxMath.getAmountsForLiquidity(
                uint256(priceLower),
                uint256(priceUpper),
                uint256(currentPrice),
                uint256(amount),
                false
            );
        }

        {
            // Ensure no overflow happens when we cast to int128.
            if (amount > uint128(type(int128).max)) revert Overflow();

            uint256 amount0fees;
            uint256 amount1fees;
            (amount0fees, amount1fees, oldLiquidity) = _updatePosition(msg.sender, lower, upper, -int128(amount));

            withdrawnAmounts = new TokenAmount[](2);
            withdrawnAmounts[0] = TokenAmount({token: token0, amount: amount0});
            withdrawnAmounts[1] = TokenAmount({token: token1, amount: amount1});

            feesWithdrawn = new TokenAmount[](2);
            feesWithdrawn[0] = TokenAmount({token: token0, amount: amount0fees});
            feesWithdrawn[1] = TokenAmount({token: token1, amount: amount1fees});

            unchecked {
                amount0 += amount0fees;
                amount1 += amount1fees;
            }
        }

        unchecked {
            reserve0 -= uint128(amount0);
            reserve1 -= uint128(amount1);
        }

        _transferBothTokens(recipient, amount0, amount1, unwrapBento);

        nearestTick = Ticks.remove(ticks, lower, upper, amount, nearestTick);
        emit Burn(msg.sender, amount0, amount1);
    }

    function burn(bytes calldata) public pure override returns (IPool.TokenAmount[] memory) {
        revert();
    }

    function burnSingle(bytes calldata) public pure override returns (uint256) {
        revert();
    }

    function collect(
        int24 lower,
        int24 upper,
        address recipient,
        bool unwrapBento
    ) public lock returns (uint256 amount0fees, uint256 amount1fees) {
        (amount0fees, amount1fees, ) = _updatePosition(msg.sender, lower, upper, 0);

        _transferBothTokens(recipient, amount0fees, amount1fees, unwrapBento);

        reserve0 -= uint128(amount0fees);
        reserve1 -= uint128(amount1fees);

        emit Collect(msg.sender, amount0fees, amount1fees);
    }

    /// @dev Swaps one token for another. The router must prefund this contract and ensure there isn't too much slippage
    /// - price is √(y/x)
    /// - x is token0
    /// - zero for one -> price will move down.
    function swap(bytes memory data) public override lock returns (uint256 amountOut) {
        (bool zeroForOne, uint256 inAmount, address recipient, bool unwrapBento) = abi.decode(data, (bool, uint256, address, bool));

        SwapCache memory cache = SwapCache({
            feeAmount: 0,
            totalFeeAmount: 0,
            protocolFee: 0,
            feeGrowthGlobal: zeroForOne ? feeGrowthGlobal1 : feeGrowthGlobal0,
            currentPrice: uint256(price),
            currentLiquidity: uint256(liquidity),
            input: inAmount,
            nextTickToCross: zeroForOne ? nearestTick : ticks[nearestTick].nextTick
        });

        unchecked {
            uint256 timestamp = block.timestamp;
            uint256 diff = timestamp - uint256(lastObservation); // Underflow in 2106. Don't do staking rewards in the year 2106.
            if (diff > 0 && liquidity > 0) {
                lastObservation = uint32(timestamp);
                secondsGrowthGlobal += uint160((diff << 128) / liquidity);
            }
        }

        while (cache.input != 0) {
            uint256 nextTickPrice = uint256(TickMath.getSqrtRatioAtTick(cache.nextTickToCross));
            uint256 output = 0;
            bool cross = false;

            if (zeroForOne) {
                // Trading token 0 (x) for token 1 (y).
                // Price is decreasing.
                // Maximum input amount within current tick range: Δx = Δ(1/√𝑃) · L.
                uint256 maxDx = DyDxMath.getDx(cache.currentLiquidity, nextTickPrice, cache.currentPrice, false);

                if (cache.input <= maxDx) {
                    // We can swap within the current range.
                    uint256 liquidityPadded = cache.currentLiquidity << 96;
                    // Calculate new price after swap: √𝑃[new] =  L · √𝑃 / (L + Δx · √𝑃)
                    // This is derrived from Δ(1/√𝑃) = Δx/L
                    // where Δ(1/√𝑃) is 1/√𝑃[old] - 1/√𝑃[new] and we solve for √𝑃[new].
                    // In case of an owerflow we can use: √𝑃[new] = L / (L / √𝑃 + Δx).
                    // This is derrived by dividing the original fraction by √𝑃 on both sides.
                    uint256 newPrice = uint256(
                        FullMath.mulDivRoundingUp(liquidityPadded, cache.currentPrice, liquidityPadded + cache.currentPrice * cache.input)
                    );

                    if (!(nextTickPrice <= newPrice && newPrice < cache.currentPrice)) {
                        // Overflow. We use a modified version of the formula.
                        newPrice = uint160(UnsafeMath.divRoundingUp(liquidityPadded, liquidityPadded / cache.currentPrice + cache.input));
                    }
                    // Based on the price difference calculate the output of th swap: Δy = Δ√P · L.
                    output = DyDxMath.getDy(cache.currentLiquidity, newPrice, cache.currentPrice, false);
                    cache.currentPrice = newPrice;
                    cache.input = 0;
                } else {
                    // Execute swap step and cross the tick.
                    output = DyDxMath.getDy(cache.currentLiquidity, nextTickPrice, cache.currentPrice, false);
                    cache.currentPrice = nextTickPrice;
                    cross = true;
                    cache.input -= maxDx;
                }
            } else {
                // Price is increasing.
                // Maximum swap amount within the current tick range: Δy = Δ√P · L.
                uint256 maxDy = DyDxMath.getDy(cache.currentLiquidity, cache.currentPrice, nextTickPrice, false);

                if (cache.input <= maxDy) {
                    // We can swap within the current range.
                    // Calculate new price after swap: ΔP = Δy/L.
                    uint256 newPrice = cache.currentPrice +
                        FullMath.mulDiv(cache.input, 0x1000000000000000000000000, cache.currentLiquidity);
                    // Calculate output of swap
                    // - Δx = Δ(1/√P) · L.
                    output = DyDxMath.getDx(cache.currentLiquidity, cache.currentPrice, newPrice, false);
                    cache.currentPrice = newPrice;
                    cache.input = 0;
                } else {
                    // Swap & cross the tick.
                    output = DyDxMath.getDx(cache.currentLiquidity, cache.currentPrice, nextTickPrice, false);
                    cache.currentPrice = nextTickPrice;
                    cross = true;
                    cache.input -= maxDy;
                }
            }
            (cache.totalFeeAmount, amountOut, cache.protocolFee, cache.feeGrowthGlobal) = SwapLib.handleFees(
                output,
                swapFee,
                barFee,
                cache.currentLiquidity,
                cache.totalFeeAmount,
                amountOut,
                cache.protocolFee,
                cache.feeGrowthGlobal
            );
            if (cross) {
                (cache.currentLiquidity, cache.nextTickToCross) = Ticks.cross(
                    ticks,
                    cache.nextTickToCross,
                    secondsGrowthGlobal,
                    cache.currentLiquidity,
                    cache.feeGrowthGlobal,
                    zeroForOne
                );
                if (cache.currentLiquidity == 0) {
                    // We step into a zone that has liquidity - or we reach the end of the linked list.
                    cache.currentPrice = uint256(TickMath.getSqrtRatioAtTick(cache.nextTickToCross));
                    (cache.currentLiquidity, cache.nextTickToCross) = Ticks.cross(
                        ticks,
                        cache.nextTickToCross,
                        secondsGrowthGlobal,
                        cache.currentLiquidity,
                        cache.feeGrowthGlobal,
                        zeroForOne
                    );
                }
            }
        }

        price = uint160(cache.currentPrice);

        int24 newNearestTick = zeroForOne ? cache.nextTickToCross : ticks[cache.nextTickToCross].previousTick;

        if (nearestTick != newNearestTick) {
            nearestTick = newNearestTick;
            liquidity = uint128(cache.currentLiquidity);
        }

        _updateReserves(zeroForOne, uint128(inAmount), amountOut);

        _updateFees(zeroForOne, cache.feeGrowthGlobal, uint128(cache.protocolFee));

        if (zeroForOne) {
            _transfer(token1, amountOut, recipient, unwrapBento);
            emit Swap(recipient, token0, token1, inAmount, amountOut);
        } else {
            _transfer(token0, amountOut, recipient, unwrapBento);
            emit Swap(recipient, token1, token0, inAmount, amountOut);
        }
    }

    /// @dev Reserved for IPool.
    function flashSwap(bytes calldata) public pure override returns (uint256) {
        revert();
    }

    /// @dev Updates `barFee` for Trident protocol.
    function updateBarFee() public {
        barFee = IMasterDeployer(masterDeployer).barFee();
    }

    /// @dev Collects fees for Trident protocol.
    function collectProtocolFee() public lock returns (uint128 amount0, uint128 amount1) {
        if (token0ProtocolFee > 1) {
            amount0 = token0ProtocolFee - 1;
            token0ProtocolFee = 1;
            reserve0 -= amount0;
            _transfer(token0, amount0, barFeeTo, false);
        }
        if (token1ProtocolFee > 1) {
            amount1 = token1ProtocolFee - 1;
            token1ProtocolFee = 1;
            reserve1 -= amount1;
            _transfer(token1, amount1, barFeeTo, false);
        }
    }

    function _ensureTickSpacing(int24 lower, int24 upper) internal view {
        if (lower % int24(tickSpacing) != 0) revert InvalidTick();
        if ((lower / int24(tickSpacing)) % 2 != 0) revert LowerEven();
        if (upper % int24(tickSpacing) != 0) revert InvalidTick();
        if ((upper / int24(tickSpacing)) % 2 == 0) revert UpperOdd();
    }

    function _updateReserves(
        bool zeroForOne,
        uint128 inAmount,
        uint256 amountOut
    ) internal {
        if (zeroForOne) {
            uint256 balance0 = _balance(token0);
            uint128 newBalance = reserve0 + inAmount;
            if (uint256(newBalance) > balance0) revert Token0Missing();
            reserve0 = newBalance;
            reserve1 -= uint128(amountOut);
        } else {
            uint256 balance1 = _balance(token1);
            uint128 newBalance = reserve1 + inAmount;
            if (uint256(newBalance) > balance1) revert Token1Missing();
            reserve1 = newBalance;
            reserve0 -= uint128(amountOut);
        }
    }

    function _updateFees(
        bool zeroForOne,
        uint256 feeGrowthGlobal,
        uint128 protocolFee
    ) internal {
        if (zeroForOne) {
            feeGrowthGlobal1 = feeGrowthGlobal;
            token1ProtocolFee += protocolFee;
        } else {
            feeGrowthGlobal0 = feeGrowthGlobal;
            token0ProtocolFee += protocolFee;
        }
    }

    function _updatePosition(
        address owner,
        int24 lower,
        int24 upper,
        int128 amount
    )
        internal
        returns (
            uint256 amount0fees,
            uint256 amount1fees,
            uint256 oldLiquidity
        )
    {
        Position storage position = positions[owner][lower][upper];

        (uint256 growth0current, uint256 growth1current) = rangeFeeGrowth(lower, upper);
        amount0fees = FullMath.mulDiv(
            growth0current - position.feeGrowthInside0Last,
            position.liquidity,
            0x100000000000000000000000000000000
        );

        amount1fees = FullMath.mulDiv(
            growth1current - position.feeGrowthInside1Last,
            position.liquidity,
            0x100000000000000000000000000000000
        );

        oldLiquidity = position.liquidity;

        if (amount < 0) {
            position.liquidity -= uint128(-amount);
        }

        if (amount > 0) {
            position.liquidity += uint128(amount);
            if (position.liquidity > MAX_TICK_LIQUIDITY) revert LiquidityOverflow();
        }

        position.feeGrowthInside0Last = growth0current;
        position.feeGrowthInside1Last = growth1current;
    }

    function _balance(address token) internal view returns (uint256 balance) {
        balance = bento.balanceOf(token, address(this));
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

    function _transferBothTokens(
        address to,
        uint256 shares0,
        uint256 shares1,
        bool unwrapBento
    ) internal {
        if (unwrapBento) {
            bento.withdraw(token0, address(this), to, 0, shares0);
            bento.withdraw(token1, address(this), to, 0, shares1);
        } else {
            bento.transfer(token0, address(this), to, shares0);
            bento.transfer(token1, address(this), to, shares1);
        }
    }

    /// @dev Generic formula for fee growth inside a range: (globalGrowth - growthBelow - growthAbove)
    /// - available counters: global, outside u, outside v.

    ///                  u         ▼         v
    /// ----|----|-------|xxxxxxxxxxxxxxxxxxx|--------|--------- (global - feeGrowthOutside(u) - feeGrowthOutside(v))

    ///             ▼    u                   v
    /// ----|----|-------|xxxxxxxxxxxxxxxxxxx|--------|--------- (global - (global - feeGrowthOutside(u)) - feeGrowthOutside(v))

    ///                  u                   v    ▼
    /// ----|----|-------|xxxxxxxxxxxxxxxxxxx|--------|--------- (global - feeGrowthOutside(u) - (global - feeGrowthOutside(v)))

    /// @notice Calculates the fee growth inside a range (per unit of liquidity).
    /// @dev Multiply `rangeFeeGrowth` delta by the provided liquidity to get accrued fees for some period.
    function rangeFeeGrowth(int24 lowerTick, int24 upperTick) public view returns (uint256 feeGrowthInside0, uint256 feeGrowthInside1) {
        int24 currentTick = nearestTick;

        Ticks.Tick storage lower = ticks[lowerTick];
        Ticks.Tick storage upper = ticks[upperTick];

        // Calculate fee growth below & above.
        uint256 _feeGrowthGlobal0 = feeGrowthGlobal0;
        uint256 _feeGrowthGlobal1 = feeGrowthGlobal1;
        uint256 feeGrowthBelow0;
        uint256 feeGrowthBelow1;
        uint256 feeGrowthAbove0;
        uint256 feeGrowthAbove1;

        if (lowerTick <= currentTick) {
            feeGrowthBelow0 = lower.feeGrowthOutside0;
            feeGrowthBelow1 = lower.feeGrowthOutside1;
        } else {
            feeGrowthBelow0 = _feeGrowthGlobal0 - lower.feeGrowthOutside0;
            feeGrowthBelow1 = _feeGrowthGlobal1 - lower.feeGrowthOutside1;
        }

        if (currentTick < upperTick) {
            feeGrowthAbove0 = upper.feeGrowthOutside0;
            feeGrowthAbove1 = upper.feeGrowthOutside1;
        } else {
            feeGrowthAbove0 = _feeGrowthGlobal0 - upper.feeGrowthOutside0;
            feeGrowthAbove1 = _feeGrowthGlobal1 - upper.feeGrowthOutside1;
        }

        feeGrowthInside0 = _feeGrowthGlobal0 - feeGrowthBelow0 - feeGrowthAbove0;
        feeGrowthInside1 = _feeGrowthGlobal1 - feeGrowthBelow1 - feeGrowthAbove1;
    }

    function getAssets() public view override returns (address[] memory assets) {
        assets = new address[](2);
        assets[0] = token0;
        assets[1] = token1;
    }

    /// @dev Reserved for IPool.
    function getAmountOut(bytes calldata) public pure override returns (uint256) {
        revert();
    }

    /// @dev Reserved for IPool.
    function getAmountIn(bytes calldata) public pure override returns (uint256) {
        revert();
    }

    function getImmutables()
        public
        view
        returns (
            uint128 _MAX_TICK_LIQUIDITY,
            uint24 _tickSpacing,
            uint24 _swapFee,
            address _barFeeTo,
            IBentoBoxMinimal _bento,
            IMasterDeployer _masterDeployer,
            address _token0,
            address _token1
        )
    {
        _MAX_TICK_LIQUIDITY = MAX_TICK_LIQUIDITY;
        _tickSpacing = tickSpacing;
        _swapFee = swapFee; // 1000 corresponds to 0.1% fee.
        _barFeeTo = barFeeTo;
        _bento = bento;
        _masterDeployer = masterDeployer;
        _token0 = token0;
        _token1 = token1;
    }

    function getPriceAndNearestTicks() public view returns (uint160 _price, int24 _nearestTick) {
        _price = price;
        _nearestTick = nearestTick;
    }

    function getTokenProtocolFees() public view returns (uint128 _token0ProtocolFee, uint128 _token1ProtocolFee) {
        _token0ProtocolFee = token0ProtocolFee;
        _token1ProtocolFee = token1ProtocolFee;
    }

    function getReserves() public view returns (uint128 _reserve0, uint128 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function getSecondsGrowthAndLastObservation() public view returns (uint160 _secondsGrowthGlobal, uint32 _lastObservation) {
        _secondsGrowthGlobal = secondsGrowthGlobal;
        _lastObservation = lastObservation;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident pool callback interface.
interface ITridentCallee {
    function tridentSwapCallback(bytes calldata data) external;

    function tridentMintCallback(bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import "./FullMath.sol";

/// @notice Math library that facilitates fee handling for Trident Concentrated Liquidity Pools.
library SwapLib {
    function handleFees(
        uint256 output,
        uint24 swapFee,
        uint256 barFee,
        uint256 currentLiquidity,
        uint256 totalFeeAmount,
        uint256 amountOut,
        uint256 protocolFee,
        uint256 feeGrowthGlobal
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 feeAmount = FullMath.mulDivRoundingUp(output, swapFee, 1e6);

        totalFeeAmount += feeAmount;

        amountOut += output - feeAmount;

        // Calculate `protocolFee` and convert pips to bips.
        uint256 feeDelta = FullMath.mulDivRoundingUp(feeAmount, barFee, 1e4);

        protocolFee += feeDelta;

        // Updating `feeAmount` based on the protocolFee.
        feeAmount -= feeDelta;

        feeGrowthGlobal += FullMath.mulDiv(feeAmount, 0x100000000000000000000000000000000, currentLiquidity);

        return (totalFeeAmount, amountOut, protocolFee, feeGrowthGlobal);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./ConcentratedLiquidityPool.sol";
import "../PoolDeployer.sol";

/// @notice Contract for deploying Trident exchange Concentrated Liquidity Pool with configurations.
/// @author Mudit Gupta.
contract ConcentratedLiquidityPoolFactory is PoolDeployer {
    constructor(address _masterDeployer) PoolDeployer(_masterDeployer) {}

    function deployPool(bytes memory _deployData) external returns (address pool) {
        (address tokenA, address tokenB, uint24 swapFee, uint160 price, uint24 tickSpacing) = abi.decode(
            _deployData,
            (address, address, uint24, uint160, uint24)
        );
        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }
        // @dev Strips any extra data.
        _deployData = abi.encode(tokenA, tokenB, swapFee, price, tickSpacing);

        address[] memory tokens = new address[](2);
        tokens[0] = tokenA;
        tokens[1] = tokenB;

        // @dev Salt is not actually needed since `_deployData` is part of creationCode and already contains the salt.
        bytes32 salt = keccak256(_deployData);
        pool = address(new ConcentratedLiquidityPool{salt: salt}(_deployData, IMasterDeployer(masterDeployer)));
        _registerPool(pool, tokens, salt);
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

    error UnauthorisedDeployer();
    error ZeroAddress();
    error InvalidTokenOrder();

    modifier onlyMaster() {
        if (msg.sender != masterDeployer) revert UnauthorisedDeployer();
        _;
    }

    constructor(address _masterDeployer) {
        if (_masterDeployer == address(0)) revert ZeroAddress();
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
                if (tokens[i] >= tokens[i + 1]) revert InvalidTokenOrder();
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
        uint256 count
    ) external view returns (address[] memory pairPools) {
        pairPools = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            pairPools[i] = pools[token0][token1][startIndex + i];
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
        (uint256 tokenInAmount, uint256 tokenInBalance, uint256 tokenInWeight, uint256 tokenOutBalance, uint256 tokenOutWeight) = abi
            .decode(data, (uint256, uint256, uint256, uint256, uint256));
        amountOut = _getAmountOut(tokenInAmount, tokenInBalance, tokenInWeight, tokenOutBalance, tokenOutWeight);
    }

    function getAmountIn(bytes calldata) public pure override returns (uint256) {
        revert();
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
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
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
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline))
            )
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

    event Mint(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient, uint256 liquidity);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient, uint256 liquidity);
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
        uint256 liquidityForEvent = liquidity;
        emit Mint(msg.sender, amount0, amount1, recipient, liquidityForEvent);
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

        emit Burn(msg.sender, amount0, amount1, recipient, liquidity);
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
        emit Burn(msg.sender, amount0, amount1, recipient, liquidity);
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
            require(tokenIn == token1, "INVALID_INPUT_TOKEN");
            finalAmountOut = bento.toShare(token0, _getAmountOut(amountIn, _reserve0, _reserve1, false), false);
        }
    }

    function getAmountIn(bytes calldata) public pure override returns (uint256) {
        revert();
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
        (
            address[] memory _tokens,
            uint136[] memory _weights,
            uint256 _swapFee,
            address _whiteListManager,
            address _operator,
            bool _level2
        ) = abi.decode(_deployData, (address[], uint136[], uint256, address, address, bool));
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
        (uint256 tokenInAmount, uint256 tokenInBalance, uint256 tokenInWeight, uint256 tokenOutBalance, uint256 tokenOutWeight) = abi
            .decode(data, (uint256, uint256, uint256, uint256, uint256));
        amountOut = _getAmountOut(tokenInAmount, tokenInBalance, tokenInWeight, tokenOutBalance, tokenOutWeight);
    }

    function getAmountIn(bytes calldata) public pure override returns (uint256) {
        revert();
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
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
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
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline))
            )
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
        (, bytes memory _whitelisted) = whiteListManager.staticcall(
            abi.encodeWithSelector(IWhiteListManager.whitelistedAccounts.selector, operator, account)
        );
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
import "../../libraries/MathUtils.sol";
import "./TridentFranchisedERC20.sol";

/// @notice Trident exchange franchised pool template with hybrid like-kind formula for swapping between an ERC-20 token pair.
/// @dev The reserves are stored as bento shares. However, the stableswap invariant is applied to the underlying amounts.
///      The API uses the underlying amounts.
contract FranchisedHybridPool is IPool, TridentFranchisedERC20 {
    using MathUtils for uint256;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient, uint256 liquidity);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient, uint256 liquidity);
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
        (address _token0, address _token1, uint256 _swapFee, uint256 a, address _whiteListManager, address _operator, bool _level2) = abi
            .decode(_deployData, (address, address, uint256, uint256, address, address, bool));

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
        uint256 liquidityForEvent = liquidity;
        emit Mint(msg.sender, amount0, amount1, recipient, liquidityForEvent);
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

        emit Burn(msg.sender, amount0, amount1, recipient, liquidity);
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
        emit Burn(msg.sender, amount0, amount1, recipient, liquidity);
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
            (bool success, ) = bento.call(
                abi.encodeWithSelector(IBentoBoxMinimal.transfer.selector, token, address(this), to, _toShare(token, amount))
            );
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
            require(tokenIn == token1, "INVALID_INPUT_TOKEN");
            finalAmountOut = _getAmountOut(amountIn, _reserve0, _reserve1, false);
        }
    }

    function getAmountIn(bytes calldata) public pure override returns (uint256) {
        revert();
    }

    function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1) {
        (_reserve0, _reserve1) = _getReserves();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./FranchisedHybridPool.sol";
import "../PoolDeployer.sol";

/// @notice Contract for deploying Trident exchange Franchised Hybrid Product Pool with configurations.
/// @author Mudit Gupta.
contract FranchisedHybridPoolFactory is PoolDeployer {
    constructor(address _masterDeployer) PoolDeployer(_masterDeployer) {}

    function deployPool(bytes memory _deployData) external returns (address pool) {
        (address tokenA, address tokenB, uint256 swapFee, uint256 a, address whiteListManager, address operator, bool level2) = abi.decode(
            _deployData,
            (address, address, uint256, uint256, address, address, bool)
        );
        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }

        // @dev Strips any extra data.
        _deployData = abi.encode(tokenA, tokenB, swapFee, a, whiteListManager, operator, level2);
        address[] memory tokens = new address[](2);
        tokens[0] = tokenA;
        tokens[1] = tokenB;

        // @dev Salt is not actually needed since `_deployData` is part of creationCode and already contains the salt.
        bytes32 salt = keccak256(_deployData);
        pool = address(new FranchisedHybridPool{salt: salt}(_deployData, masterDeployer));
        _registerPool(pool, tokens, salt);
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
    event Mint(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient, uint256 liquidity);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient, uint256 liquidity);
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
        (
            address _token0,
            address _token1,
            uint256 _swapFee,
            bool _twapSupport,
            address _whiteListManager,
            address _operator,
            bool _level2
        ) = abi.decode(_deployData, (address, address, uint256, bool, address, address, bool));

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
        uint256 liquidityForEvent = liquidity;
        emit Mint(msg.sender, amount0, amount1, recipient, liquidityForEvent);
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
        emit Burn(msg.sender, amount0, amount1, recipient, liquidity);
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
        emit Burn(msg.sender, amount0, amount1, recipient, liquidity);
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
            uint32 blockTimestamp = uint32(block.timestamp);
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
            require(tokenIn == token1, "INVALID_INPUT_TOKEN");
            finalAmountOut = _getAmountOut(amountIn, _reserve1, _reserve0);
        }
    }

    function getAmountIn(bytes calldata) public pure override returns (uint256) {
        revert();
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

import "./FranchisedConstantProductPool.sol";
import "../PoolDeployer.sol";

/// @notice Contract for deploying Trident exchange Franchised Constant Product Pool with configurations.
/// @author Mudit Gupta.
contract FranchisedConstantProductPoolFactory is PoolDeployer {
    constructor(address _masterDeployer) PoolDeployer(_masterDeployer) {}

    function deployPool(bytes memory _deployData) external returns (address pool) {
        (address tokenA, address tokenB, uint256 swapFee, bool twapSupport, address whiteListManager, address operator, bool level2) = abi
            .decode(_deployData, (address, address, uint256, bool, address, address, bool));
        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }

        // @dev Strips any extra data.
        _deployData = abi.encode(tokenA, tokenB, swapFee, twapSupport, whiteListManager, operator, level2);

        address[] memory tokens = new address[](2);
        tokens[0] = tokenA;
        tokens[1] = tokenB;

        // @dev Salt is not actually needed since `_deployData` is part of creationCode and already contains the salt.
        bytes32 salt = keccak256(_deployData);
        pool = address(new FranchisedConstantProductPool{salt: salt}(_deployData, masterDeployer));
        _registerPool(pool, tokens, salt);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../interfaces/IBentoBoxMinimal.sol";
import "../interfaces/IMasterDeployer.sol";
import "../interfaces/IPool.sol";
import "../interfaces/ITridentCallee.sol";
import "../libraries/TridentMath.sol";
import "./TridentERC20.sol";

/// @notice Trident exchange pool template with constant product formula for swapping between an ERC-20 token pair.
/// @dev The reserves are stored as bento shares.
///      The curve is applied to shares as well. This pool does not care about the underlying amounts.
contract ConstantProductPool is IPool, TridentERC20 {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient, uint256 liquidity);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient, uint256 liquidity);
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
        (address _token0, address _token1, uint256 _swapFee, bool _twapSupport) = abi.decode(
            _deployData,
            (address, address, uint256, bool)
        );

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
        uint256 liquidityForEvent = liquidity;
        emit Mint(msg.sender, amount0, amount1, recipient, liquidityForEvent);
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
        emit Burn(msg.sender, amount0, amount1, recipient, liquidity);
    }

    /// @dev Burns LP tokens sent to this contract and swaps one of the output tokens for another
    /// - i.e., the user gets a single token out by burning LP tokens.
    function burnSingle(bytes calldata data) public override lock returns (uint256 amountOut) {
        (address tokenOut, address recipient, bool unwrapBento) = abi.decode(data, (address, address, bool));
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = _getReserves();
        uint256 liquidity = balanceOf[address(this)];

        (uint256 _totalSupply, ) = _mintFee(_reserve0, _reserve1);

        uint256 amount0 = (liquidity * _reserve0) / _totalSupply;
        uint256 amount1 = (liquidity * _reserve1) / _totalSupply;

        kLast = TridentMath.sqrt((_reserve0 - amount0) * (_reserve1 - amount1));

        _burn(address(this), liquidity);

        // Swap one token for another
        unchecked {
            if (tokenOut == token1) {
                // @dev Swap `token0` for `token1`
                // - calculate `amountOut` as if the user first withdrew balanced liquidity and then swapped `token0` for `token1`.
                amount1 += _getAmountOut(amount0, _reserve0 - amount0, _reserve1 - amount1);
                _transfer(token1, amount1, recipient, unwrapBento);
                amountOut = amount1;
                amount0 = 0;
            } else {
                // @dev Swap `token1` for `token0`.
                require(tokenOut == token0, "INVALID_OUTPUT_TOKEN");
                amount0 += _getAmountOut(amount1, _reserve1 - amount1, _reserve0 - amount0);
                _transfer(token0, amount0, recipient, unwrapBento);
                amountOut = amount0;
                amount1 = 0;
            }
        }

        (uint256 balance0, uint256 balance1) = _balance();
        _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);

        emit Burn(msg.sender, amount0, amount1, recipient, liquidity);
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
            uint32 blockTimestamp = uint32(block.timestamp);
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

    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveAmountIn,
        uint256 reserveAmountOut
    ) internal view returns (uint256 amountIn) {
        amountIn = (reserveAmountIn * amountOut * MAX_FEE) / ((reserveAmountOut - amountOut) * MAX_FEE_MINUS_SWAP_FEE) + 1;
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
            require(tokenIn == token1, "INVALID_INPUT_TOKEN");
            finalAmountOut = _getAmountOut(amountIn, _reserve1, _reserve0);
        }
    }

    function getAmountIn(bytes calldata data) public view override returns (uint256 finalAmountIn) {
        (address tokenOut, uint256 amountOut) = abi.decode(data, (address, uint256));
        (uint112 _reserve0, uint112 _reserve1, ) = _getReserves();
        if (tokenOut == token1) {
            finalAmountIn = _getAmountIn(amountOut, _reserve0, _reserve1);
        } else {
            require(tokenOut == token0, "INVALID_OUTPUT_TOKEN");
            finalAmountIn = _getAmountIn(amountOut, _reserve1, _reserve0);
        }
    }

    /// @dev returned values are in terms of BentoBox "shares".
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

    /// @dev returned values are the native ERC20 token amounts.
    function getNativeReserves()
        public
        view
        returns (
            uint256 _nativeReserve0,
            uint256 _nativeReserve1,
            uint32 _blockTimestampLast
        )
    {
        (uint112 _reserve0, uint112 _reserve1, uint32 __blockTimestampLast) = _getReserves();
        _nativeReserve0 = bento.toAmount(token0, _reserve0, false);
        _nativeReserve1 = bento.toAmount(token1, _reserve1, false);
        _blockTimestampLast = __blockTimestampLast;
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

pragma solidity >=0.8.0;

import "./IntermediaryToken.sol";
import "../interfaces/IMasterDeployer.sol";
import "../interfaces/IBentoBoxMinimal.sol";
import "../interfaces/IPoolFactory.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IConstantProductPool.sol";
import "../interfaces/IUniswapV2Minimal.sol";

/// @notice Trident pool migrator contract for legacy SushiSwap.
/** Sushiswap's master chef contracts which distribute rewards to LP token holders have the option to migrate liquidity.
    We can set this contract as the migrator on the master chef contracts to migrate LP positions from the legacy to the new Trident
    constant product pools. After the migrator is set anyone can call the migrate() function (once per pool) on the master chef contract.
    Used by MasterChef / MasterChefV2 / MiniChef. */
contract Migrator {
    event Migrate(address indexed oldPool, address indexed newPool, address indexed intermediaryToken);

    /// @dev Intermediary token to new LP token mapping.
    /// @dev Used to prevent subsequent calls to masterchef's migrate function with the same PID.
    mapping(address => address) public migrated;

    IBentoBoxMinimal public immutable bento;
    IMasterDeployer public immutable masterDeployer;
    IPoolFactory public immutable constantProductPoolFactory;
    address public immutable masterChef;

    constructor(
        IBentoBoxMinimal _bento,
        IMasterDeployer _masterDeployer,
        IPoolFactory _constantProductPoolFactory,
        address _masterChef
    ) {
        bento = _bento;
        masterDeployer = _masterDeployer;
        constantProductPoolFactory = _constantProductPoolFactory;
        masterChef = _masterChef;
    }

    /// @notice Method to migrate MasterChef's liquidity form the legacy SushiSwap AMM to the Trident constant product pool.
    /// @param oldPool Legacy SushiSwap pool.
    /// @dev Since MasterChef has a requierment to receive the same amount of "LP" tokens back after migration we use an
    /// intermediary token so we can mint the desired balance. Anfer unstaking users can call redeem() on the intermediary
    /// token to receive their share of the LP tokens of the new Trident constant product pool.
    function migrate(IUniswapV2Minimal oldPool) external returns (address) {
        require(msg.sender == address(masterChef), "ONLY_CHEF");
        require(migrated[address(oldPool)] == address(0), "ONLY_ONCE");

        address token0 = oldPool.token0();
        address token1 = oldPool.token1();

        bytes memory deployData = abi.encode(token0, token1, 30, false);

        IConstantProductPool pool = IConstantProductPool(constantProductPoolFactory.configAddress(keccak256(deployData)));

        // We deploy the pool if it doesn't exist yet.
        if (address(pool) == address(0)) {
            pool = IConstantProductPool(masterDeployer.deployPool(address(constantProductPoolFactory), deployData));
        }

        // We are migrating all of master chef's balance.
        uint256 lpBalance = oldPool.balanceOf(address(masterChef));

        if (lpBalance == 0) {
            return address(pool);
        }

        // Remove the liquidity and send assets to BentoBox.
        oldPool.transferFrom(address(masterChef), address(oldPool), lpBalance);
        (uint256 amount0, uint256 amount1) = oldPool.burn(address(bento));

        bento.deposit(token0, address(bento), address(pool), amount0, 0);
        bento.deposit(token1, address(bento), address(pool), amount1, 0);

        if (pool.totalSupply() != 0) {
            // We require the pools' prices to differ by no more than 0.5%.
            (uint256 _nativeReserve0, uint256 _nativeReserve1, ) = pool.getNativeReserves();
            uint256 oldPoolPrice = (1e18 * amount0) / amount1;
            uint256 newPoolPrice = (1e18 * _nativeReserve0) / _nativeReserve1;
            uint256 priceChange = (1e3 * oldPoolPrice) / newPoolPrice;
            require(priceChange < 1005 && priceChange >= 995, "PRICE_DIFFERENCE");
        }

        // We mint the intermediary token to Master Chef.
        address intermediaryToken = address(new IntermediaryToken(address(pool), masterChef, lpBalance));

        // The new Trident pool mints liquidity to the intermediary token.
        pool.mint(abi.encode(intermediaryToken));

        migrated[intermediaryToken] = address(pool);

        emit Migrate(address(oldPool), address(pool), intermediaryToken);

        return intermediaryToken;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../pool/TridentERC20.sol";
import "../interfaces/IERC20.sol";

/// @notice Intermediary token users who are staked in MasterChef will receive after migration.
/// Can be redeemed for the LP token of the new pool.
contract IntermediaryToken is TridentERC20 {
    /// @dev Liquidity token of the Trident constant product pool.
    IERC20 public immutable lpToken;

    constructor(
        address _lpToken,
        address _recipient,
        uint256 _amount
    ) {
        lpToken = IERC20(_lpToken);
        _mint(_recipient, _amount);
    }

    /// @dev Since we might be rewarding the intermediary token for some time we allow users to mint it.
    function deposit(uint256 amount) public returns (uint256 minted) {
        uint256 availableLpTokens = lpToken.balanceOf(address(this));
        if (availableLpTokens != 0) {
            minted = (totalSupply * amount) / availableLpTokens;
        } else {
            minted = amount;
        }
        _mint(msg.sender, minted);
        require(lpToken.transferFrom(msg.sender, address(this), amount), "TRANSFER_FROM_FAILED");
    }

    function redeem(uint256 amount) public returns (uint256 claimed) {
        uint256 availableLpTokens = lpToken.balanceOf(address(this));
        claimed = (availableLpTokens * amount) / totalSupply;
        _burn(msg.sender, amount);
        require(lpToken.transfer(msg.sender, claimed), "TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./IPool.sol";

interface IConstantProductPool is IPool, IERC20 {
    function getNativeReserves()
        external
        view
        returns (
            uint256 _nativeReserve0,
            uint256 _nativeReserve1,
            uint32
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../../interfaces/concentratedPool/IConcentratedLiquidityPool.sol";
import "../../libraries/concentratedPool/Ticks.sol";
import "../../interfaces/IBentoBoxMinimal.sol";
import {IConcentratedLiquidityPoolManager as IPoolManager} from "../../interfaces/concentratedPool/IConcentratedLiquidityPoolManager.sol";

/// @notice Trident Concentrated Liquidity Pool periphery contract that combines non-fungible position management and staking.
contract ConcentratedLiquidityPoolStaker {
    event AddIncentive(IConcentratedLiquidityPool indexed pool, uint256 indexed incentiveId, address indexed rewardToken);
    event Subscribe(uint256 indexed positionId, uint256 indexed incentiveId);
    event ClaimReward(uint256 indexed positionId, uint256 indexed incentiveId, address indexed recipient, uint96 amount);
    event ReclaimIncentive(IConcentratedLiquidityPool indexed pool, uint256 indexed incentiveId, uint256 amount);

    struct Incentive {
        address owner;
        address token;
        uint32 startTime;
        uint32 endTime;
        uint32 expiry;
        uint160 secondsClaimed; // @dev x128.
        uint96 rewardsUnclaimed;
    }

    struct Stake {
        uint160 secondsGrowthInsideLast; // @dev x128.
        uint32 timestamp;
    }

    IBentoBoxMinimal public immutable bento;
    IPoolManager public poolManager;

    mapping(IConcentratedLiquidityPool => uint256) public incentiveCount;
    mapping(IConcentratedLiquidityPool => mapping(uint256 => Incentive)) public incentives;
    /// @dev When subscribing to an incentive we take a snapshot of the position secondsGrowth accumulator.
    /// @dev positionId to incentiveId to position's secondsGrowth snapshot mapping.
    mapping(uint256 => mapping(uint256 => Stake)) public stakes;

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
        IBentoBoxMinimal _bento = IBentoBoxMinimal(_poolManager.bento());
        _bento.registerProtocol();
        bento = _bento;
    }

    function addIncentive(IConcentratedLiquidityPool pool, Incentive memory incentive) public {
        uint32 current = uint32(block.timestamp);
        require(current <= incentive.startTime, "ALREADY_STARTED");
        require(incentive.startTime < incentive.endTime, "START_PAST_END");
        require(incentive.endTime + 90 days < incentive.expiry, "END_PAST_BUFFER");
        require(incentive.rewardsUnclaimed != 0, "NO_REWARDS");
        incentive.secondsClaimed = 0;
        incentives[pool][incentiveCount[pool]++] = incentive;
        _transfer(incentive.token, msg.sender, address(this), incentive.rewardsUnclaimed, false);
        emit AddIncentive(pool, incentiveCount[pool], incentive.token);
    }

    /// @dev Withdraws any unclaimed incentive rewards.
    function reclaimIncentive(
        IConcentratedLiquidityPool pool,
        uint256 incentiveId,
        address receiver,
        uint96 amount,
        bool unwrapBento
    ) public {
        Incentive storage incentive = incentives[pool][incentiveId];
        require(incentive.owner == msg.sender, "NOT_OWNER");
        require(incentive.expiry < block.timestamp, "EXPIRED");
        require(incentive.rewardsUnclaimed >= amount, "ALREADY_CLAIMED");
        incentive.rewardsUnclaimed -= uint96(amount);
        _transfer(incentive.token, address(this), receiver, amount, unwrapBento);
        emit ReclaimIncentive(pool, incentiveId, amount);
    }

    /// @dev Subscribes a non-fungible position token to an incentive.
    function subscribe(uint256 positionId, uint256[] calldata incentiveId) external {
        require(poolManager.ownerOf(positionId) == msg.sender, "NOT_OWNER");
        IPoolManager.Position memory position = poolManager.positions(positionId);
        IConcentratedLiquidityPool pool = position.pool;
        require(position.liquidity != 0, "INACTIVE");
        Stake memory stakeData = Stake(uint160(rangeSecondsInside(pool, position.lower, position.upper)), uint32(block.timestamp));
        for (uint256 i; i < incentiveId.length; i++) {
            Incentive memory incentive = incentives[pool][incentiveId[i]];
            Stake storage stake = stakes[positionId][incentiveId[i]];
            require(stake.secondsGrowthInsideLast == 0, "SUBSCRIBED");
            require(block.timestamp >= incentive.startTime && block.timestamp < incentive.endTime, "INACTIVE_INCENTIVE");
            stakes[positionId][incentiveId[i]] = stakeData;
            emit Subscribe(positionId, incentiveId[i]);
        }
    }

    function claimRewards(
        uint256 positionId,
        uint256[] memory incentiveIds,
        address recipient,
        bool unwrapBento
    ) public {
        require(poolManager.ownerOf(positionId) == msg.sender, "NOT_OWNER");

        IPoolManager.Position memory position = poolManager.positions(positionId);
        IConcentratedLiquidityPool pool = position.pool;

        uint256 currentSecondsGrowth = rangeSecondsInside(pool, position.lower, position.upper);

        for (uint256 i = 0; i < incentiveIds.length; i++) {
            Incentive storage incentive = incentives[pool][incentiveIds[i]];
            Stake storage stake = stakes[positionId][incentiveIds[i]];

            require(stake.timestamp >= position.latestAddition, "MUST_RESUBSCRIBE");

            uint256 rewards;
            uint256 secondsInside;

            {
                uint256 secondsGrowth = currentSecondsGrowth - stake.secondsGrowthInsideLast;
                uint256 maxTime = block.timestamp < incentive.endTime ? incentive.endTime : block.timestamp;
                uint256 secondsUnclaimed = ((maxTime - incentive.startTime) << 128) - incentive.secondsClaimed;
                secondsInside = secondsGrowth * position.liquidity; // secondsGrowth is multiplied by 2**128
                rewards = (incentive.rewardsUnclaimed * secondsInside) / secondsUnclaimed; // 2**128 cancels out
            }

            stake.secondsGrowthInsideLast = uint160(currentSecondsGrowth);
            incentive.secondsClaimed += uint160(secondsInside);
            incentive.rewardsUnclaimed -= uint96(rewards);

            _transfer(incentive.token, address(this), recipient, rewards, unwrapBento);

            emit ClaimReward(positionId, incentiveIds[i], recipient, uint96(rewards));
        }
    }

    function getReward(uint256 positionId, uint256 incentiveId) public view returns (uint256 rewards, uint256 secondsInside) {
        IPoolManager.Position memory position = poolManager.positions(positionId);
        IConcentratedLiquidityPool pool = position.pool;
        Incentive memory incentive = incentives[pool][positionId];
        Stake memory stake = stakes[positionId][incentiveId];
        if (stake.timestamp > 0) {
            uint256 secondsGrowth = rangeSecondsInside(pool, position.lower, position.upper) - stake.secondsGrowthInsideLast;
            secondsInside = secondsGrowth * position.liquidity;
            uint256 maxTime = block.timestamp < incentive.endTime ? incentive.endTime : block.timestamp;
            uint256 secondsUnclaimed = ((maxTime - incentive.startTime) << 128) - incentive.secondsClaimed;
            rewards = (incentive.rewardsUnclaimed * secondsInside) / secondsUnclaimed;
        }
    }

    /// @dev Calculates the "seconds per liquidity" accumulator for a range.
    function rangeSecondsInside(
        IConcentratedLiquidityPool pool,
        int24 lowerTick,
        int24 upperTick
    ) public view returns (uint256 secondsInside) {
        (, int24 currentTick) = pool.getPriceAndNearestTicks();

        Ticks.Tick memory lower = pool.ticks(lowerTick);
        Ticks.Tick memory upper = pool.ticks(upperTick);

        (uint256 secondsGrowthGlobal, ) = pool.getSecondsGrowthAndLastObservation();
        uint256 secondsBelow;
        uint256 secondsAbove;

        if (lowerTick <= currentTick) {
            secondsBelow = lower.secondsGrowthOutside;
        } else {
            secondsBelow = secondsGrowthGlobal - lower.secondsGrowthOutside;
        }

        if (currentTick < upperTick) {
            secondsAbove = upper.secondsGrowthOutside;
        } else {
            secondsAbove = secondsGrowthGlobal - upper.secondsGrowthOutside;
        }

        secondsInside = secondsGrowthGlobal - secondsBelow - secondsAbove;
    }

    function _transfer(
        address token,
        address from,
        address to,
        uint256 shares,
        bool unwrapBento
    ) internal {
        if (unwrapBento) {
            bento.withdraw(token, from, to, 0, shares);
        } else {
            bento.transfer(token, from, to, shares);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../../interfaces/concentratedPool/IConcentratedLiquidityPool.sol";
import "../../libraries/concentratedPool/TickMath.sol";
import "../../libraries/concentratedPool/Ticks.sol";

/// @notice Trident Concentrated Liquidity Pool periphery contract to read state.
contract ConcentratedLiquidityPoolHelper {
    struct SimpleTick {
        int24 index;
        uint128 liquidity;
    }

    function getTickState(IConcentratedLiquidityPool pool, uint24 tickCount) external view returns (SimpleTick[] memory) {
        SimpleTick[] memory ticks = new SimpleTick[](tickCount); // todo save tickCount in the core contract

        Ticks.Tick memory tick;
        uint24 i;
        int24 current = TickMath.MIN_TICK;

        while (current != TickMath.MAX_TICK) {
            tick = pool.ticks(current);
            ticks[i++] = SimpleTick({index: current, liquidity: tick.liquidity});
            current = tick.nextTick;
        }

        tick = pool.ticks(current);
        ticks[i] = SimpleTick({index: TickMath.MAX_TICK, liquidity: tick.liquidity});

        return ticks;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../libraries/concentratedPool/TickMath.sol";

contract TickMathTest {
    function getSqrtRatioAtTick(int24 tick) external pure returns (uint160) {
        return TickMath.getSqrtRatioAtTick(tick);
    }

    function getTickAtSqrtRatio(uint160 sqrtPriceX96) external pure returns (int24) {
        return TickMath.getTickAtSqrtRatio(sqrtPriceX96);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply);
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        _burn(msg.sender, wad);
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

import "./ERC20Mock.sol";

contract WETH9 is ERC20Mock {
    constructor() ERC20Mock("WETH9", "WETH9", 0) {}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

import "../interfaces/IPoolFactory.sol";

import "./PoolTemplate.sol";

/**
 * @author Mudit Gupta
 */
abstract contract PoolFactory is IPoolFactory {
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