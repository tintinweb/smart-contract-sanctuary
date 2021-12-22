/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @primitivefi/rmm-core/contracts/interfaces/engine/[email protected]
// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

/// @title  View functions of the Primitive Engine contract
/// @author Primitive
interface IPrimitiveEngineView {
    // ===== View =====

    /// @notice             Fetches the current invariant based on risky and stable token reserves of pool with `poolId`
    /// @param  poolId      Pool Identifier
    /// @return invariant   Signed fixed point 64.64 number, invariant of `poolId`
    function invariantOf(bytes32 poolId) external view returns (int128 invariant);

    // ===== Constants =====

    /// @return Precision units to scale to when doing token related calculations
    function PRECISION() external view returns (uint256);

    /// @return Amount of seconds after pool expiry which allows swaps, no swaps after buffer
    function BUFFER() external view returns (uint256);

    // ===== Immutables =====

    /// @return Amount of liquidity burned on `create()` calls
    function MIN_LIQUIDITY() external view returns (uint256);

    //// @return Factory address which deployed this engine contract
    function factory() external view returns (address);

    //// @return Risky token address
    function risky() external view returns (address);

    /// @return Stable token address
    function stable() external view returns (address);

    /// @return Multiplier to scale amounts to/from, equal to 10^(18 - riskyDecimals)
    function scaleFactorRisky() external view returns (uint256);

    /// @return Multiplier to scale amounts to/from, equal to 10^(18 - stableDecimals)
    function scaleFactorStable() external view returns (uint256);

    // ===== Pool State =====

    /// @notice                      Fetches the global reserve state for a pool with `poolId`
    /// @param  poolId               Pool Identifier
    /// @return reserveRisky         Risky token balance in the reserve
    /// @return reserveStable        Stable token balance in the reserve
    /// @return liquidity            Total supply of liquidity for the curve
    /// @return blockTimestamp       Timestamp when the cumulative reserve values were last updated
    /// @return cumulativeRisky      Cumulative sum of risky token reserves of the previous update
    /// @return cumulativeStable     Cumulative sum of stable token reserves of the previous update
    /// @return cumulativeLiquidity  Cumulative sum of total supply of liquidity of the previous update
    function reserves(bytes32 poolId)
        external
        view
        returns (
            uint128 reserveRisky,
            uint128 reserveStable,
            uint128 liquidity,
            uint32 blockTimestamp,
            uint256 cumulativeRisky,
            uint256 cumulativeStable,
            uint256 cumulativeLiquidity
        );

    /// @notice                 Fetches `Calibration` pool parameters
    /// @param  poolId          Pool Identifier
    /// @return strike          Strike price of the pool with stable token decimals
    /// @return sigma           Implied Volatility as an unsigned 32-bit integer constant w/ precision of 1e4, 10000 = 100%
    /// @return maturity        Timestamp of maturity in seconds
    /// @return lastTimestamp   Last timestamp used to calculate time until expiry, aka "tau"
    /// @return gamma           = 1 - fee %, as an unsigned 32-bit integer constant w/ precision of 1e4, 10000 = 100%
    function calibrations(bytes32 poolId)
        external
        view
        returns (
            uint128 strike,
            uint32 sigma,
            uint32 maturity,
            uint32 lastTimestamp,
            uint32 gamma
        );

    /// @notice             Fetches position liquidity an account address and poolId
    /// @param  poolId      Pool Identifier
    /// @return liquidity   Liquidity owned by `account` in `poolId`
    function liquidity(address account, bytes32 poolId) external view returns (uint256 liquidity);

    /// @notice                 Fetches the margin balances of `account`
    /// @param  account         Margin account to fetch
    /// @return balanceRisky    Balance of the risky token
    /// @return balanceStable   Balance of the stable token
    function margins(address account) external view returns (uint128 balanceRisky, uint128 balanceStable);
}


// File @primitivefi/rmm-core/contracts/interfaces/callback/[email protected]


pragma solidity >=0.5.0;

/// @title  Primitive Create Callback
/// @author Primitive
interface IPrimitiveCreateCallback {
    /// @notice              Triggered when creating a new pool for an Engine
    /// @param  delRisky     Amount of risky tokens required to initialize risky reserve
    /// @param  delStable    Amount of stable tokens required to initialize stable reserve
    /// @param  data         Calldata passed on create function call
    function createCallback(
        uint256 delRisky,
        uint256 delStable,
        bytes calldata data
    ) external;
}


// File @primitivefi/rmm-core/contracts/interfaces/callback/[email protected]


pragma solidity >=0.5.0;

/// @title  Primitive Liquidity Callback
/// @author Primitive
interface IPrimitiveLiquidityCallback {
    /// @notice              Triggered when providing liquidity to an Engine
    /// @param  delRisky     Amount of risky tokens required to provide to risky reserve
    /// @param  delStable    Amount of stable tokens required to provide to stable reserve
    /// @param  data         Calldata passed on allocate function call
    function allocateCallback(
        uint256 delRisky,
        uint256 delStable,
        bytes calldata data
    ) external;
}


// File contracts/interfaces/IPrimitiveManager.sol


pragma solidity >=0.8.6;


/// @title   Interface of PrimitiveManager contract
/// @author  Primitive
interface IPrimitiveManager is IPrimitiveCreateCallback, IPrimitiveLiquidityCallback {
    /// ERRORS ///

    /// @notice  Thrown when trying to add or remove zero liquidity
    error ZeroLiquidityError();

    /// @notice  Thrown when the received liquidity is lower than the expected
    error MinLiquidityOutError();

    /// @notice  Thrown when the received risky / stable amounts are lower than the expected
    error MinRemoveOutError();

    /// EVENTS ///

    /// @notice           Emitted when a new pool is created
    /// @param payer      Payer sending liquidity
    /// @param engine     Primitive Engine where the pool is created
    /// @param poolId     Id of the new pool
    /// @param strike     Strike of the new pool
    /// @param sigma      Sigma of the new pool
    /// @param maturity   Maturity of the new pool
    /// @param gamma      Gamma of the new pool
    event Create(
        address indexed payer,
        address indexed engine,
        bytes32 indexed poolId,
        uint128 strike,
        uint32 sigma,
        uint32 maturity,
        uint32 gamma
    );

    /// @notice              Emitted when liquidity is allocated
    /// @param payer         Payer sending liquidity
    /// @param engine        Primitive Engine receiving liquidity
    /// @param poolId        Id of the pool receiving liquidity
    /// @param delLiquidity  Amount of liquidity allocated
    /// @param delRisky      Amount of risky tokens allocated
    /// @param delStable     Amount of stable tokens allocated
    /// @param fromMargin    True if liquidity was paid from margin
    event Allocate(
        address indexed payer,
        address indexed engine,
        bytes32 indexed poolId,
        uint256 delLiquidity,
        uint256 delRisky,
        uint256 delStable,
        bool fromMargin
    );

    /// @notice              Emitted when liquidity is removed
    /// @param payer         Payer receiving liquidity
    /// @param engine        Engine where liquidity is removed from
    /// @param poolId        Id of the pool where liquidity is removed from
    /// @param delLiquidity  Amount of liquidity removed
    /// @param delRisky      Amount of risky tokens allocated
    /// @param delStable     Amount of stable tokens allocated
    event Remove(
        address indexed payer,
        address indexed engine,
        bytes32 indexed poolId,
        uint256 delLiquidity,
        uint256 delRisky,
        uint256 delStable
    );

    /// EFFECT FUNCTIONS ///

    /// @notice              Creates a new pool using the specified parameters
    /// @param risky         Address of the risky asset
    /// @param stable        Address of the stable asset
    /// @param strike        Strike price of the pool to calibrate to, with the same decimals as the stable token
    /// @param sigma         Volatility to calibrate to as an unsigned 256-bit integer w/ precision of 1e4, 10000 = 100%
    /// @param maturity      Maturity timestamp of the pool, in seconds
    /// @param gamma         Multiplied against swap in amounts to apply fee, equal to 1 - fee %, an unsigned 32-bit integer, w/ precision of 1e4, 10000 = 100%
    /// @param riskyPerLp    Risky reserve per liq. with risky decimals, = 1 - N(d1), d1 = (ln(S/K)+(r*sigma^2/2))/sigma*sqrt(tau)
    /// @param delLiquidity  Amount of liquidity to allocate to the curve, wei value with 18 decimals of precision
    /// @return poolId       Id of the new created pool (Keccak256 hash of the engine address, maturity, sigma and strike)
    /// @return delRisky     Amount of risky tokens allocated into the pool
    /// @return delStable    Amount of stable tokens allocated into the pool
    function create(
        address risky,
        address stable,
        uint128 strike,
        uint32 sigma,
        uint32 maturity,
        uint32 gamma,
        uint256 riskyPerLp,
        uint256 delLiquidity
    )
        external
        payable
        returns (
            bytes32 poolId,
            uint256 delRisky,
            uint256 delStable
        );

    /// @notice               Allocates liquidity into a pool
    /// @param poolId         Id of the pool
    /// @param risky          Address of the risky asset
    /// @param stable         Address of the stable asset
    /// @param delRisky       Amount of risky tokens to allocate
    /// @param delStable      Amount of stable tokens to allocate
    /// @param fromMargin     True if the funds of the sender should be used
    /// @return delLiquidity  Amount of liquidity allocated into the pool
    function allocate(
        bytes32 poolId,
        address risky,
        address stable,
        uint256 delRisky,
        uint256 delStable,
        bool fromMargin,
        uint256 minLiquidityOut
    ) external payable returns (uint256 delLiquidity);

    /// @notice              Removes liquidity from a pool
    /// @param engine        Address of the engine
    /// @param poolId        Id of the pool
    /// @param delLiquidity  Amount of liquidity to remove
    /// @return delRisky     Amount of risky tokens removed from the pool
    /// @return delStable    Amount of stable tokens removed from the pool
    function remove(
        address engine,
        bytes32 poolId,
        uint256 delLiquidity,
        uint256 minRiskyOut,
        uint256 minStableOut
    ) external returns (uint256 delRisky, uint256 delStable);
}


// File contracts/interfaces/IMulticall.sol

pragma solidity >=0.8.6;

/// @title   Interface of Multicall contract
/// @author  https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/IMulticall.sol
interface IMulticall {
    /// @notice          Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev             `msg.value` should not be trusted for any method callable from Multicall
    /// @param data      Encoded function data for each of the calls to make to this contract
    /// @return results  Results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}


// File contracts/base/Multicall.sol

pragma solidity 0.8.6;

/// @title   Multicall contract
/// @author  https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol
/// @notice  Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) external payable override returns (bytes[] memory results) {
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


// File contracts/interfaces/ICashManager.sol


pragma solidity >=0.8.6;

/// @title   Interface of CashManager contract
/// @author  Primitive
interface ICashManager {
    /// ERRORS ///

    /// @notice  Thrown when the sender is not WETH
    error OnlyWETHError();

    /// @notice                Thrown when the amount required is above balance
    /// @param balance         Actual ETH or token balance of the contract
    /// @param requiredAmount  ETH or token amount required by the user
    error BalanceTooLowError(uint256 balance, uint256 requiredAmount);

    /// EFFECT FUNCTIONS ///

    /// @notice       Wraps ETH into WETH and transfers to the msg.sender
    /// @param value  Amount of ETH to wrap
    function wrap(uint256 value) external payable;

    /// @notice           Unwraps WETH to ETH and transfers to a recipient
    /// @param amountMin  Minimum amount to unwrap
    /// @param recipient  Address of the recipient
    function unwrap(uint256 amountMin, address recipient) external payable;

    /// @notice           Transfers the tokens in the contract to a recipient
    /// @param token      Address of the token to sweep
    /// @param amountMin  Minimum amount to transfer
    /// @param recipient  Recipient of the tokens
    function sweepToken(
        address token,
        uint256 amountMin,
        address recipient
    ) external payable;

    /// @notice  Transfers the ETH balance of the contract to the caller
    function refundETH() external payable;
}


// File contracts/interfaces/IManagerBase.sol


pragma solidity >=0.8.6;

/// @title   Interface of ManagerBase contract
/// @author  Primitive
interface IManagerBase {
    /// ERRORS ///

    /// @notice Thrown when the sender is not a Primitive Engine contract
    error NotEngineError();

    /// @notice Thrown when the constructor parameters are wrong
    error WrongConstructorParametersError();

    /// VIEW FUNCTIONS ///

    /// @notice Returns the address of the factory
    function factory() external view returns (address);

    /// @notice Returns the address of WETH9
    function WETH9() external view returns (address);

    /// @notice Returns the address of the PositionRenderer
    function positionRenderer() external view returns (address);
}


// File contracts/base/Reentrancy.sol


pragma solidity 0.8.6;

/// @title   Reentrancy contract
/// @author  Primitive
/// @notice  Prevents reentrancy
contract Reentrancy {
    /// @notice  Thrown when a call to the contract is made during a locked state
    error LockedError();

    uint256 private _unlocked = 1;

    /// @notice  Locks the contract to prevent reentrancy
    modifier lock() {
        if (_unlocked != 1) revert LockedError();

        _unlocked = 0;
        _;
        _unlocked = 1;
    }
}


// File contracts/libraries/EngineAddress.sol


pragma solidity >=0.8.6;

/// @author  Primitive
/// @notice  Small library to compute the address of the engines
library EngineAddress {
    /// @notice Thrown when the target Engine is not deployed
    error EngineNotDeployedError();

    /// @notice Hash of the bytecode of the PrimitiveEngine
    bytes32 internal constant ENGINE_INIT_CODE_HASH =
        0x3187e25cd8f65ad9c44cb7d8c3f78847a93d5e150d0efbd41bca66a6efb16e10;

    /// @notice         Computes the address of an engine
    /// @param factory  Address of the factory
    /// @param risky    Address of the risky token
    /// @param stable   Address of the stable token
    /// @return engine  Computed address of the engine
    function computeAddress(
        address factory,
        address risky,
        address stable
    ) internal pure returns (address engine) {
        engine = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(hex"ff", factory, keccak256(abi.encode(risky, stable)), ENGINE_INIT_CODE_HASH)
                    )
                )
            )
        );
    }

    /// @notice        Checks if the target address is a contract, this function is used
    ///                to verify if a PrimitiveEngine was deployed before calling it
    /// @param target  Address of the contract to check
    /// @return        True if the target is a contract
    function isContract(address target) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(target)
        }
        return size > 0;
    }
}


// File contracts/base/ManagerBase.sol


pragma solidity 0.8.6;




/// @title   ManagerBase contract
/// @author  Primitive
/// @notice  Base contract of the Manager
abstract contract ManagerBase is IManagerBase, Reentrancy {
    /// @notice Data struct reused by callbacks
    struct CallbackData {
        address payer;
        address risky;
        address stable;
    }

    /// @inheritdoc IManagerBase
    address public immutable override factory;

    /// @inheritdoc IManagerBase
    address public immutable override WETH9;

    /// @inheritdoc IManagerBase
    address public immutable override positionRenderer;

    /// @param factory_  Address of a PrimitiveFactory
    /// @param WETH9_    Address of WETH9
    /// @param positionRenderer_    Address of the position renderer
    constructor(
        address factory_,
        address WETH9_,
        address positionRenderer_
    ) {
        if (factory_ == address(0) || WETH9_ == address(0) || positionRenderer_ == address(0))
            revert WrongConstructorParametersError();

        factory = factory_;
        WETH9 = WETH9_;
        positionRenderer = positionRenderer_;
    }
}


// File contracts/interfaces/external/IERC20.sol


pragma solidity >=0.8.6;

/// @title   ERC20 Interface
/// @author  Primitive
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/libraries/TransferHelper.sol


pragma solidity 0.8.6;

/// @author  https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
/// @notice  Utils functions to transfer tokens and ETH
library TransferHelper {
    /// ERRORS ///

    /// @notice Thrown when a transfer reverts
    error TransferError();

    /// @notice Thrown when an approval reverts
    error ApproveError();

    /// FUNCTIONS ///

    /// @notice       Transfers tokens from the targeted address to the given destination
    /// @param token  Contract address of the token to be transferred
    /// @param from   Originating address from which the tokens will be transferred
    /// @param to     Destination address of the transfer
    /// @param value  Amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );

        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert TransferError();
    }

    /// @notice       Transfers tokens from msg.sender to a recipient
    /// @param token  Contract address of the token which will be transferred
    /// @param to     Recipient of the transfer
    /// @param value  Value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert TransferError();
    }

    /// @notice       Approves the stipulated contract to spend the given allowance in the given token
    /// @param token  Contract address of the token to be approved
    /// @param to     Target of the approval
    /// @param value  Amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert ApproveError();
    }

    /// @notice       Transfers ETH to the recipient address
    /// @param to     Destination of the transfer
    /// @param value  Value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (success == false) revert TransferError();
    }
}


// File contracts/interfaces/external/IWETH9.sol


pragma solidity >=0.8.6;

/// @title   Interface for WETH9
/// @author  Primitive
interface IWETH9 is IERC20 {
    /// @notice Wraps ETH into WETH
    function deposit() external payable;

    /// @notice Unwraps WETH into ETH
    function withdraw(uint256) external;
}


// File contracts/base/CashManager.sol


pragma solidity 0.8.6;




/// @title   CashManager contract
/// @author  Primitive
/// @notice  Utils contract to manage ETH and token balances
abstract contract CashManager is ICashManager, ManagerBase {
    /// @notice Only WETH9 can send ETH to this contract
    receive() external payable {
        if (msg.sender != WETH9) revert OnlyWETHError();
    }

    /// @inheritdoc ICashManager
    function wrap(uint256 value) external payable override {
        if (address(this).balance < value) {
            revert BalanceTooLowError(address(this).balance, value);
        }

        IWETH9(WETH9).deposit{value: value}();
        IWETH9(WETH9).transfer(msg.sender, value);
    }

    /// @inheritdoc ICashManager
    function unwrap(uint256 amountMin, address recipient) external payable override {
        uint256 balance = IWETH9(WETH9).balanceOf(address(this));

        if (balance < amountMin) revert BalanceTooLowError(balance, amountMin);

        if (balance > 0) {
            IWETH9(WETH9).withdraw(balance);
            TransferHelper.safeTransferETH(recipient, balance);
        }
    }

    /// @inheritdoc ICashManager
    function sweepToken(
        address token,
        uint256 amountMin,
        address recipient
    ) external payable override {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance < amountMin) revert BalanceTooLowError(balance, amountMin);

        if (balance > 0) {
            TransferHelper.safeTransfer(token, recipient, balance);
        }
    }

    /// @inheritdoc ICashManager
    function refundETH() external payable override {
        if (address(this).balance > 0) TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

    /// @dev              Pays {value} of {token] to {recipient} from {payer} wallet
    /// @param token      Token to transfer as payment
    /// @param payer      Account that pays
    /// @param recipient  Account that receives payment
    /// @param value      Amount to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        if (token == WETH9 && address(this).balance >= value) {
            IWETH9(WETH9).deposit{value: value}();
            IWETH9(WETH9).transfer(recipient, value);
        } else if (payer == address(this)) {
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File contracts/interfaces/external/IERC20PermitAllowed.sol


pragma solidity >=0.8.6;

/// @title   Interface for permit
/// @author  https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/external/IERC20PermitAllowed.sol
/// @notice  Interface used by DAI/CHAI for permit
interface IERC20PermitAllowed {
    /// @notice         Approve the spender to spend some tokens via the holder signature
    /// @dev            This is the permit interface used by DAI and CHAI
    /// @param holder   Address of the token holder, the token owner
    /// @param spender  Address of the token spender
    /// @param nonce    Holder's nonce, increases at each call to permit
    /// @param expiry   Timestamp at which the permit is no longer valid
    /// @param allowed  Boolean that sets approval amount, true for type(uint256).max and false for 0
    /// @param v        Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r        Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s        Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


// File contracts/interfaces/ISelfPermit.sol


pragma solidity >=0.8.6;

/// @title   Interface of SelfPermit contract
/// @author  https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISelfPermit.sol
interface ISelfPermit {
    /// @notice          Permits this contract to spend a given token from `msg.sender`
    /// @dev             `owner` is always msg.sender and the `spender` is always address(this)
    /// @param token     Address of the token spent
    /// @param value     Amount that can be spent of token
    /// @param deadline  A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v         Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r         Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s         Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice          Permits this contract to spend a given token from `msg.sender`
    /// @dev             `owner` is always msg.sender and the `spender` is always address(this)
    ///                  Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit
    /// @param token     Address of the token spent
    /// @param value     Amount that can be spent of token
    /// @param deadline  A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v         Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r         Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s         Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice        Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev           `owner` is always msg.sender and the `spender` is always address(this)
    /// @param token   Address of the token spent
    /// @param nonce   Current nonce of the owner
    /// @param expiry  Timestamp at which the permit is no longer valid
    /// @param v       Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r       Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s       Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice        Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev           `owner` is always msg.sender and the `spender` is always address(this)
    ///                Can be used instead of #selfPermitAllowed to prevent calls from failing due to a frontrun of a call to #selfPermitAllowed
    /// @param token   Address of the token spent
    /// @param nonce   Current nonce of the owner
    /// @param expiry  Timestamp at which the permit is no longer valid
    /// @param v       Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r       Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s       Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}


// File contracts/base/SelfPermit.sol


pragma solidity 0.8.6;




/// @title   SelfPermit contract
/// @author  https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/SelfPermit.sol
/// @notice  Functionality to call permit on any EIP-2612-compliant token
/// @dev     These functions are expected to be embedded in multicalls to allow EOAs to approve a contract and call a function
///          that requires an approval in a single transaction
abstract contract SelfPermit is ISelfPermit {
    /// @inheritdoc ISelfPermit
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable override {
        IERC20Permit(token).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable override {
        if (IERC20(token).allowance(msg.sender, address(this)) < value) selfPermit(token, value, deadline, v, r, s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable override {
        IERC20PermitAllowed(token).permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable override {
        if (IERC20(token).allowance(msg.sender, address(this)) < type(uint256).max)
            selfPermitAllowed(token, nonce, expiry, v, r, s);
    }
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// File base64-sol/[email protected]



pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/token/ERC1155/extensions/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/utils/introspection/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File contracts/base/ERC1155.sol



pragma solidity ^0.8.0;






/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}


// File contracts/interfaces/IERC1155Permit.sol


pragma solidity >=0.8.6;

/// @title   Interface of ERC1155Permit contract
/// @author  Primitive
interface IERC1155Permit is IERC1155 {
    /// ERRORS ///

    /// @notice Thrown when the signature has expired
    error SigExpiredError();

    /// @notice Thrown when the signature is invalid
    error InvalidSigError();

    /// EFFECT FUNCTIONS ///

    /// @notice          Grants or revokes the approval for an operator to transfer any of the owner's
    ///                  tokens using their signature
    /// @param owner     Address of the owner
    /// @param operator  Address of the operator
    /// @param approved  True if the approval should be granted, false if revoked
    /// @param deadline  Expiry of the signature, as a timestamp
    /// @param v         Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r         Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s         Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address owner,
        address operator,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// VIEW FUNCTIONS ///

    /// @notice Returns the current nonce of an address
    /// @param owner Address to inspect
    /// @return Current nonce of an address
    function nonces(address owner) external view returns (uint256);

    /// @notice Returns the domain separator
    /// @return Hash of the domain separator
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File contracts/base/ERC1155Permit.sol


pragma solidity 0.8.6;



/// @title   ERC1155Permit contract
/// @author  Primitive
/// @notice  ERC1155 contract with permit extension allowing approvals to be made via signatures
contract ERC1155Permit is ERC1155, IERC1155Permit, EIP712 {
    /// @inheritdoc IERC1155Permit
    mapping(address => uint256) public override nonces;

    /// @dev Typehash of the permit function
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)");

    constructor() ERC1155("") EIP712("PrimitiveManager", "1") {}

    /// @inheritdoc IERC1155Permit
    function permit(
        address owner,
        address operator,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        if (block.timestamp > deadline) revert SigExpiredError();

        bytes32 structHash = keccak256(
            abi.encode(_PERMIT_TYPEHASH, owner, operator, approved, nonces[owner], deadline)
        );

        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);

        if (signer != owner) revert InvalidSigError();

        _setApprovalForAll(owner, operator, approved);
        nonces[owner] += 1;
    }

    /// @inheritdoc IERC1155Permit
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }
}


// File contracts/interfaces/IPositionRenderer.sol


pragma solidity >=0.8.6;

/// @title   Interface of PositionRenderer contract
/// @author  Primitive
interface IPositionRenderer {
    /// @notice         Returns a SVG representation of the token
    /// @param engine   Address of the engine
    /// @param tokenId  Id of the token (same as pool id)
    /// @return         SVG image as a string
    function render(address engine, uint256 tokenId) external view returns (string memory);
}


// File contracts/interfaces/external/IERC20WithMetadata.sol


pragma solidity >=0.8.6;

/// @title   ERC20 Interface with metadata
/// @author  Primitive
interface IERC20WithMetadata is IERC20 {
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);
}


// File contracts/base/PositionManager.sol


pragma solidity 0.8.6;







/// @title   PositionManager contract
/// @author  Primitive
/// @notice  Wraps the positions into ERC1155 tokens
abstract contract PositionManager is ManagerBase, ERC1155Permit {
    using Strings for uint256;

    /// @dev  Ties together pool ids with engine addresses, this is necessary because
    ///       there is no way to get the Primitive Engine address from a pool id
    mapping(uint256 => address) private cache;

    /// @dev  Empty variable to pass to the _mint function
    bytes private _empty;

    /// @notice         Returns the metadata of a token
    /// @param tokenId  Token id to look for (same as pool id)
    /// @return         Metadata of the token as a string
    function uri(uint256 tokenId) public view override returns (string memory) {
        return getMetadata(tokenId);
    }

    /// @notice         Allocates {amount} of {poolId} liquidity to {account} balance
    /// @param account  Recipient of the liquidity
    /// @param engine   Address of the Primitive Engine
    /// @param poolId   Id of the pool
    /// @param amount   Amount of liquidity to allocate
    function _allocate(
        address account,
        address engine,
        bytes32 poolId,
        uint256 amount
    ) internal {
        _mint(account, uint256(poolId), amount, _empty);

        if (cache[uint256(poolId)] == address(0)) cache[uint256(poolId)] = engine;
    }

    /// @notice         Removes {amount} of {poolId} liquidity from {account} balance
    /// @param account  Account to remove from
    /// @param poolId   Id of the pool
    /// @param amount   Amount of liquidity to remove
    function _remove(
        address account,
        bytes32 poolId,
        uint256 amount
    ) internal {
        _burn(account, uint256(poolId), amount);
    }

    /// @notice         Returns the metadata of a token
    /// @param tokenId  Id of the token (same as pool id)
    /// @return         JSON metadata of the token
    function getMetadata(uint256 tokenId) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                getName(tokenId),
                                '","image":"',
                                IPositionRenderer(positionRenderer).render(cache[tokenId], tokenId),
                                '","license":"MIT","creator":"primitive.eth",',
                                '"description":"Concentrated liquidity tokens of a two-token AMM",',
                                getProperties(tokenId)
                            )
                        )
                    )
                )
            );
    }

    function getName(uint256 tokenId) private view returns (string memory) {
        IPrimitiveEngineView engine = IPrimitiveEngineView(cache[tokenId]);
        address risky = engine.risky();
        address stable = engine.stable();

        return
            string(
                abi.encodePacked(
                    "Primitive RMM-01 LP ",
                    IERC20WithMetadata(risky).name(),
                    "-",
                    IERC20WithMetadata(stable).name()
                )
            );
    }

    /// @notice         Returns the properties of a token
    /// @param tokenId  Id of the token (same as pool id)
    /// @return         Properties of the token formatted as JSON
    function getProperties(uint256 tokenId) private view returns (string memory) {
        IPrimitiveEngineView engine = IPrimitiveEngineView(cache[tokenId]);
        int128 invariant = engine.invariantOf(bytes32(tokenId));

        return
            string(
                abi.encodePacked(
                    '"properties":{',
                    '"factory":"',
                    uint256(uint160(engine.factory())).toHexString(),
                    '","risky":',
                    getTokenMetadata(engine.risky()),
                    ',"stable":',
                    getTokenMetadata(engine.stable()),
                    ',"invariant":"',
                    invariant < 0 ? "-" : "",
                    uint256((uint128(invariant < 0 ? ~invariant + 1 : invariant))).toString(),
                    '",',
                    getCalibration(tokenId),
                    ",",
                    getReserve(tokenId),
                    "}}"
                )
            );
    }

    function getTokenMetadata(address token) private view returns (string memory) {
        string memory name = IERC20WithMetadata(token).name();
        string memory symbol = IERC20WithMetadata(token).symbol();
        uint8 decimals = IERC20WithMetadata(token).decimals();

        return
            string(
                abi.encodePacked(
                    '{"name":"',
                    name,
                    '","symbol":"',
                    symbol,
                    '","decimals":"',
                    uint256(decimals).toString(),
                    '","address":"',
                    uint256(uint160(token)).toHexString(),
                    '"}'
                )
            );
    }

    /// @notice         Returns the calibration of a pool as JSON
    /// @param tokenId  Id of the token (same as pool id)
    /// @return         Calibration of the pool formatted as JSON
    function getCalibration(uint256 tokenId) private view returns (string memory) {
        IPrimitiveEngineView engine = IPrimitiveEngineView(cache[tokenId]);

        (uint128 strike, uint64 sigma, uint32 maturity, uint32 lastTimestamp, uint32 gamma) = engine.calibrations(
            bytes32(tokenId)
        );

        return
            string(
                abi.encodePacked(
                    '"calibration":{',
                    '"strike":"',
                    uint256(strike).toString(),
                    '","sigma":"',
                    uint256(sigma).toString(),
                    '","maturity":"',
                    uint256(maturity).toString(),
                    '","lastTimestamp":"',
                    uint256(lastTimestamp).toString(),
                    '","gamma":"',
                    uint256(gamma).toString(),
                    '"}'
                )
            );
    }

    /// @notice         Returns the reserves of a pool as JSON
    /// @param tokenId  Id of the token (same as pool id)
    /// @return         Reserves of the pool formatted as JSON
    function getReserve(uint256 tokenId) private view returns (string memory) {
        IPrimitiveEngineView engine = IPrimitiveEngineView(cache[tokenId]);

        (
            uint128 reserveRisky,
            uint128 reserveStable,
            uint128 liquidity,
            uint32 blockTimestamp,
            uint256 cumulativeRisky,
            uint256 cumulativeStable,
            uint256 cumulativeLiquidity
        ) = engine.reserves(bytes32(tokenId));

        return
            string(
                abi.encodePacked(
                    '"reserve":{',
                    '"reserveRisky":"',
                    uint256(reserveRisky).toString(),
                    '","reserveStable":"',
                    uint256(reserveStable).toString(),
                    '","liquidity":"',
                    uint256(liquidity).toString(),
                    '","blockTimestamp":"',
                    uint256(blockTimestamp).toString(),
                    '","cumulativeRisky":"',
                    uint256(cumulativeRisky).toString(),
                    '","cumulativeStable":"',
                    uint256(cumulativeStable).toString(),
                    '","cumulativeLiquidity":"',
                    uint256(cumulativeLiquidity).toString(),
                    '"}'
                )
            );
    }
}


// File @primitivefi/rmm-core/contracts/interfaces/engine/[email protected]


pragma solidity >=0.5.0;

/// @title  Action functions for the Primitive Engine contract
/// @author Primitive
interface IPrimitiveEngineActions {
    // ===== Pool Updates =====

    /// @notice             Updates the time until expiry of the pool by setting its last timestamp value
    /// @param  poolId      Pool Identifier
    /// @return lastTimestamp Timestamp loaded into the state of the pool's Calibration.lastTimestamp
    function updateLastTimestamp(bytes32 poolId) external returns (uint32 lastTimestamp);

    /// @notice             Initializes a curve with parameters in the `settings` storage mapping in the Engine
    /// @param  strike      Strike price of the pool to calibrate to, with the same decimals as the stable token
    /// @param  sigma       Implied Volatility to calibrate to as an unsigned 32-bit integer w/ precision of 1e4, 10000 = 100%
    /// @param  maturity    Maturity timestamp of the pool, in seconds
    /// @param  gamma       Multiplied against swap in amounts to apply fee, equal to 1 - fee %, an unsigned 32-bit integer, w/ precision of 1e4, 10000 = 100%
    /// @param  riskyPerLp  Risky reserve per liq. with risky decimals, = 1 - N(d1), d1 = (ln(S/K)+(r*sigma^2/2))/sigma*sqrt(tau)
    /// @param  delLiquidity Amount of liquidity to allocate to the curve, wei value with 18 decimals of precision
    /// @param  data        Arbitrary data that is passed to the createCallback function
    /// @return poolId      Pool Identifier
    /// @return delRisky    Total amount of risky tokens provided to reserves
    /// @return delStable   Total amount of stable tokens provided to reserves
    function create(
        uint128 strike,
        uint32 sigma,
        uint32 maturity,
        uint32 gamma,
        uint256 riskyPerLp,
        uint256 delLiquidity,
        bytes calldata data
    )
        external
        returns (
            bytes32 poolId,
            uint256 delRisky,
            uint256 delStable
        );

    // ===== Margin ====

    /// @notice             Adds risky and/or stable tokens to a `recipient`'s internal balance account
    /// @param  recipient   Recipient margin account of the deposited tokens
    /// @param  delRisky    Amount of risky tokens to deposit
    /// @param  delStable   Amount of stable tokens to deposit
    /// @param  data        Arbitrary data that is passed to the depositCallback function
    function deposit(
        address recipient,
        uint256 delRisky,
        uint256 delStable,
        bytes calldata data
    ) external;

    /// @notice             Removes risky and/or stable tokens from a `msg.sender`'s internal balance account
    /// @param  recipient   Address that tokens are transferred to
    /// @param  delRisky    Amount of risky tokens to withdraw
    /// @param  delStable   Amount of stable tokens to withdraw
    function withdraw(
        address recipient,
        uint256 delRisky,
        uint256 delStable
    ) external;

    // ===== Liquidity =====

    /// @notice             Allocates risky and stable tokens to a specific curve with `poolId`
    /// @param  poolId      Pool Identifier
    /// @param  recipient   Address to give the allocated liquidity to
    /// @param  delRisky    Amount of risky tokens to add
    /// @param  delStable   Amount of stable tokens to add
    /// @param  fromMargin  Whether the `msg.sender` pays with their margin balance, or must send tokens
    /// @param  data        Arbitrary data that is passed to the allocateCallback function
    /// @return delLiquidity Amount of liquidity given to `recipient`
    function allocate(
        bytes32 poolId,
        address recipient,
        uint256 delRisky,
        uint256 delStable,
        bool fromMargin,
        bytes calldata data
    ) external returns (uint256 delLiquidity);

    /// @notice               Unallocates risky and stable tokens from a specific curve with `poolId`
    /// @param  poolId        Pool Identifier
    /// @param  delLiquidity  Amount of liquidity to remove
    /// @return delRisky      Amount of risky tokens received from removed liquidity
    /// @return delStable     Amount of stable tokens received from removed liquidity
    function remove(bytes32 poolId, uint256 delLiquidity) external returns (uint256 delRisky, uint256 delStable);

    // ===== Swaps =====

    /// @notice             Swaps between `risky` and `stable` tokens
    /// @param  recipient   Address that receives output token `deltaOut` amount
    /// @param  poolId      Pool Identifier
    /// @param  riskyForStable If true, swap risky to stable, else swap stable to risky
    /// @param  deltaIn     Amount of tokens to swap in
    /// @param  deltaOut    Amount of tokens to swap out
    /// @param  fromMargin  Whether the `msg.sender` uses their margin balance, or must send tokens
    /// @param  toMargin    Whether the `deltaOut` amount is transferred or deposited into margin
    /// @param  data        Arbitrary data that is passed to the swapCallback function
    function swap(
        address recipient,
        bytes32 poolId,
        bool riskyForStable,
        uint256 deltaIn,
        uint256 deltaOut,
        bool fromMargin,
        bool toMargin,
        bytes calldata data
    ) external;
}


// File @primitivefi/rmm-core/contracts/libraries/[email protected]

/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        unchecked {
            require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
            return int128(x << 64);
        }
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        unchecked {
            return int64(x >> 64);
        }
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        unchecked {
            require(x <= 0x7FFFFFFFFFFFFFFF);
            return int128(int256(x << 64));
        }
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        unchecked {
            require(x >= 0);
            return uint64(uint128(x >> 64));
        }
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128(int256 x) internal pure returns (int128) {
        unchecked {
            int256 result = x >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128(int128 x) internal pure returns (int256) {
        unchecked {
            return int256(x) << 64;
        }
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) + y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) - y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = (int256(x) * y) >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y signed 256-bit integer number
     * @return signed 256-bit integer number
     */
    function muli(int128 x, int256 y) internal pure returns (int256) {
        unchecked {
            if (x == MIN_64x64) {
                require(
                    y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
                        y <= 0x1000000000000000000000000000000000000000000000000
                );
                return -y << 63;
            } else {
                bool negativeResult = false;
                if (x < 0) {
                    x = -x;
                    negativeResult = true;
                }
                if (y < 0) {
                    y = -y; // We rely on overflow behavior here
                    negativeResult = !negativeResult;
                }
                uint256 absoluteResult = mulu(x, uint256(y));
                if (negativeResult) {
                    require(absoluteResult <= 0x8000000000000000000000000000000000000000000000000000000000000000);
                    return -int256(absoluteResult); // We rely on overflow behavior here
                } else {
                    require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                    return int256(absoluteResult);
                }
            }
        }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) return 0;

            require(x >= 0);

            uint256 lo = (uint256(int256(x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
            uint256 hi = uint256(int256(x)) * (y >> 128);

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            hi <<= 64;

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
            return hi + lo;
        }
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            int256 result = (int256(x) << 64) / y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
     * @param y signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divi(int256 x, int256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);

            bool negativeResult = false;
            if (x < 0) {
                x = -x; // We rely on overflow behavior here
                negativeResult = true;
            }
            if (y < 0) {
                y = -y; // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint128 absoluteResult = divuu(uint256(x), uint256(y));
            if (negativeResult) {
                require(absoluteResult <= 0x80000000000000000000000000000000);
                return -int128(absoluteResult); // We rely on overflow behavior here
            } else {
                require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int128(absoluteResult); // We rely on overflow behavior here
            }
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            uint128 result = divuu(x, y);
            require(result <= uint128(MAX_64x64));
            return int128(result);
        }
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return -x;
        }
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return x < 0 ? -x : x;
        }
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function inv(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != 0);
            int256 result = int256(0x100000000000000000000000000000000) / x;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function avg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            return int128((int256(x) + int256(y)) >> 1);
        }
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 m = int256(x) * int256(y);
            require(m >= 0);
            require(m < 0x4000000000000000000000000000000000000000000000000000000000000000);
            return int128(sqrtu(uint256(m)));
        }
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y uint256 value
     * @return signed 64.64-bit fixed point number
     */
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        unchecked {
            bool negative = x < 0 && y & 1 == 1;

            uint256 absX = uint128(x < 0 ? -x : x);
            uint256 absResult;
            absResult = 0x100000000000000000000000000000000;

            if (absX <= 0x10000000000000000) {
                absX <<= 63;
                while (y != 0) {
                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x2 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x4 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x8 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    y >>= 4;
                }

                absResult >>= 64;
            } else {
                uint256 absXShift = 63;
                if (absX < 0x1000000000000000000000000) {
                    absX <<= 32;
                    absXShift -= 32;
                }
                if (absX < 0x10000000000000000000000000000) {
                    absX <<= 16;
                    absXShift -= 16;
                }
                if (absX < 0x1000000000000000000000000000000) {
                    absX <<= 8;
                    absXShift -= 8;
                }
                if (absX < 0x10000000000000000000000000000000) {
                    absX <<= 4;
                    absXShift -= 4;
                }
                if (absX < 0x40000000000000000000000000000000) {
                    absX <<= 2;
                    absXShift -= 2;
                }
                if (absX < 0x80000000000000000000000000000000) {
                    absX <<= 1;
                    absXShift -= 1;
                }

                uint256 resultShift = 0;
                while (y != 0) {
                    require(absXShift < 64);

                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                        resultShift += absXShift;
                        if (absResult > 0x100000000000000000000000000000000) {
                            absResult >>= 1;
                            resultShift += 1;
                        }
                    }
                    absX = (absX * absX) >> 127;
                    absXShift <<= 1;
                    if (absX >= 0x100000000000000000000000000000000) {
                        absX >>= 1;
                        absXShift += 1;
                    }

                    y >>= 1;
                }

                require(resultShift < 64);
                absResult >>= 64 - resultShift;
            }
            int256 result = negative ? -int256(absResult) : int256(absResult);
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt(int128 x) internal pure returns (int128) {
        unchecked {
            require(x >= 0);
            return int128(sqrtu(uint256(int256(x)) << 64));
        }
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            int256 msb = 0;
            int256 xc = x;
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 result = (msb - 64) << 64;
            uint256 ux = uint256(int256(x)) << uint256(127 - msb);
            for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                ux *= ux;
                uint256 b = ux >> 255;
                ux >>= 127 + b;
                result += bit * int256(b);
            }

            return int128(result);
        }
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            return int128(int256((uint256(int256(log_2(x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128));
        }
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0) result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            if (x & 0x4000000000000000 > 0) result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
            if (x & 0x2000000000000000 > 0) result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
            if (x & 0x1000000000000000 > 0) result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
            if (x & 0x800000000000000 > 0) result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
            if (x & 0x400000000000000 > 0) result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
            if (x & 0x200000000000000 > 0) result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
            if (x & 0x100000000000000 > 0) result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
            if (x & 0x80000000000000 > 0) result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
            if (x & 0x40000000000000 > 0) result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
            if (x & 0x20000000000000 > 0) result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
            if (x & 0x10000000000000 > 0) result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
            if (x & 0x8000000000000 > 0) result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
            if (x & 0x4000000000000 > 0) result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
            if (x & 0x2000000000000 > 0) result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
            if (x & 0x1000000000000 > 0) result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
            if (x & 0x800000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
            if (x & 0x400000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
            if (x & 0x200000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            if (x & 0x100000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            if (x & 0x80000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
            if (x & 0x40000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
            if (x & 0x20000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
            if (x & 0x10000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
            if (x & 0x8000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
            if (x & 0x4000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
            if (x & 0x2000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
            if (x & 0x1000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
            if (x & 0x800000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
            if (x & 0x400000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
            if (x & 0x200000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
            if (x & 0x100000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            if (x & 0x80000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
            if (x & 0x40000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
            if (x & 0x20000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            if (x & 0x10000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
            if (x & 0x8000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
            if (x & 0x4000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
            if (x & 0x2000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            if (x & 0x1000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
            if (x & 0x800000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
            if (x & 0x400000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
            if (x & 0x200000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
            if (x & 0x100000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
            if (x & 0x80000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
            if (x & 0x40000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
            if (x & 0x20000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
            if (x & 0x10000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
            if (x & 0x8000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
            if (x & 0x4000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
            if (x & 0x2000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            if (x & 0x1000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            if (x & 0x800 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            if (x & 0x400 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            if (x & 0x200 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
            if (x & 0x100 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
            if (x & 0x80 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
            if (x & 0x40 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            if (x & 0x20 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
            if (x & 0x10 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            if (x & 0x8 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
            if (x & 0x4 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
            if (x & 0x2 > 0) result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
            if (x & 0x1 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

            result >>= uint256(int256(63 - (x >> 64)));
            require(result <= uint256(int256(MAX_64x64)));

            return int128(int256(result));
        }
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            return exp_2(int128((int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128));
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu(uint256 x, uint256 y) private pure returns (uint128) {
        unchecked {
            require(y != 0);

            uint256 result;

            if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) result = (x << 64) / y;
            else {
                uint256 msb = 192;
                uint256 xc = x >> 192;
                if (xc >= 0x100000000) {
                    xc >>= 32;
                    msb += 32;
                }
                if (xc >= 0x10000) {
                    xc >>= 16;
                    msb += 16;
                }
                if (xc >= 0x100) {
                    xc >>= 8;
                    msb += 8;
                }
                if (xc >= 0x10) {
                    xc >>= 4;
                    msb += 4;
                }
                if (xc >= 0x4) {
                    xc >>= 2;
                    msb += 2;
                }
                if (xc >= 0x2) msb += 1; // No need to shift xc anymore

                result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
                require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 hi = result * (y >> 128);
                uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 xh = x >> 192;
                uint256 xl = x << 64;

                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here
                lo = hi << 128;
                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here

                assert(xh == hi >> 128);

                result += xl / y;
            }

            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128(result);
        }
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 x) private pure returns (uint128) {
        unchecked {
            if (x == 0) return 0;
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
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return uint128(r < r1 ? r : r1);
            }
        }
    }
}


// File @primitivefi/rmm-core/contracts/libraries/[email protected]


pragma solidity ^0.8.4;
/// @title   Cumulative Normal Distribution Math Library
/// @author  Primitive
library CumulativeNormalDistribution {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    /// @notice Thrown on passing an arg that is out of the input range for these math functions
    error InverseOutOfBounds(int128 value);

    int128 public constant ONE_INT = 0x10000000000000000;
    int128 public constant TWO_INT = 0x20000000000000000;
    int128 public constant CDF0 = 0x53dd02a4f5ee2e46;
    int128 public constant CDF1 = 0x413c831bb169f874;
    int128 public constant CDF2 = -0x48d4c730f051a5fe;
    int128 public constant CDF3 = 0x16a09e667f3bcc908;
    int128 public constant CDF4 = -0x17401c57014c38f14;
    int128 public constant CDF5 = 0x10fb844255a12d72e;

    /// @notice Uses Abramowitz and Stegun approximation:
    ///         https://en.wikipedia.org/wiki/Abramowitz_and_Stegun
    /// @dev    Maximum error: 3.15x10-3
    /// @return Standard Normal Cumulative Distribution Function of `x`
    function getCDF(int128 x) internal pure returns (int128) {
        int128 z = x.div(CDF3);
        int128 t = ONE_INT.div(ONE_INT.add(CDF0.mul(z.abs())));
        int128 erf = getErrorFunction(z, t);
        if (z < 0) {
            erf = erf.neg();
        }
        int128 result = (HALF_INT).mul(ONE_INT.add(erf));
        return result;
    }

    /// @notice Uses Abramowitz and Stegun approximation:
    ///         https://en.wikipedia.org/wiki/Error_function
    /// @dev    Maximum error: 1.5×10−7
    /// @return Error Function for approximating the Standard Normal CDF
    function getErrorFunction(int128 z, int128 t) internal pure returns (int128) {
        int128 step1 = t.mul(CDF3.add(t.mul(CDF4.add(t.mul(CDF5)))));
        int128 step2 = CDF1.add(t.mul(CDF2.add(step1)));
        int128 result = ONE_INT.sub(t.mul(step2.mul((z.mul(z).neg()).exp())));
        return result;
    }

    int128 public constant HALF_INT = 0x8000000000000000;
    int128 public constant INVERSE0 = 0x26A8F3C1F21B336E;
    int128 public constant INVERSE1 = -0x87C57E5DA70D3C90;
    int128 public constant INVERSE2 = 0x15D71F5721242C787;
    int128 public constant INVERSE3 = 0x21D0A04B0E9B94F1;
    int128 public constant INVERSE4 = -0xC2BF5D74C724E53F;

    int128 public constant LOW_TAIL = 0x666666666666666; // 0.025
    int128 public constant HIGH_TAIL = 0xF999999999999999; // 0.975

    /// @notice  Returns the inverse CDF, or quantile function of `p`.
    /// @dev     Source: https://arxiv.org/pdf/1002.0567.pdf
    ///          Maximum error of central region is 1.16x10−4
    /// @return  fcentral(p) = q * (a2 + (a1r + a0) / (r^2 + b1r +b0))
    function getInverseCDF(int128 p) internal pure returns (int128) {
        if (p >= ONE_INT || p <= 0) revert InverseOutOfBounds(p);
        // Short circuit for the central region, central region inclusive of tails
        if (p <= HIGH_TAIL && p >= LOW_TAIL) {
            return central(p);
        } else if (p < LOW_TAIL) {
            return tail(p);
        } else {
            int128 negativeTail = -tail(ONE_INT.sub(p));
            return negativeTail;
        }
    }

    /// @dev    Maximum error: 1.16x10−4
    /// @return Inverse CDF around the central area of 0.025 <= p <= 0.975
    function central(int128 p) internal pure returns (int128) {
        int128 q = p.sub(HALF_INT);
        int128 r = q.mul(q);
        int128 result = q.mul(
            INVERSE2.add((INVERSE1.mul(r).add(INVERSE0)).div((r.mul(r).add(INVERSE4.mul(r)).add(INVERSE3))))
        );
        return result;
    }

    int128 public constant C0 = 0x10E56D75CE8BCE9FAE;
    int128 public constant C1 = -0x2CB2447D36D513DAE;
    int128 public constant C2 = -0x8BB4226952BD69EDF;
    int128 public constant C3 = -0x1000BF627FA188411;
    int128 public constant C0_D = 0x10AEAC93F55267A9A5;
    int128 public constant C1_D = 0x41ED34A2561490236;
    int128 public constant C2_D = 0x7A1E70F720ECA43;
    int128 public constant D0 = 0x72C7D592D021FB1DB;
    int128 public constant D1 = 0x8C27B4617F5F800EA;

    /// @dev    Maximum error: 2.458x10-5
    /// @return Inverse CDF of the tail, defined for p < 0.0465, used with p < 0.025
    function tail(int128 p) internal pure returns (int128) {
        int128 r = ONE_INT.div(p.mul(p)).ln().sqrt();
        int128 step0 = C3.mul(r).add(C2_D);
        int128 numerator = C1_D.mul(r).add(C0_D);
        int128 denominator = r.mul(r).add(D1.mul(r)).add(D0);
        int128 result = step0.add(numerator.div(denominator));
        return result;
    }
}


// File @primitivefi/rmm-core/contracts/libraries/[email protected]


pragma solidity ^0.8.0;
/// @title   Units library
/// @author  Primitive
/// @notice  Utility functions for unit conversions
library Units {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    uint256 internal constant YEAR = 31556952; // 365.24219 ephemeris day = 1 year, in seconds
    uint256 internal constant PRECISION = 1e18; // precision to scale to
    uint256 internal constant PERCENTAGE = 1e4; // precision of percentages

    // ===== Unit Conversion =====

    /// @notice             Scales a wei value to a precision of 1e18 using the scaling factor
    /// @param   value      Unsigned 256-bit wei amount to convert with native decimals
    /// @param   factor     Scaling factor to multiply by, i.e. 10^(18 - value.decimals())
    /// @return  y          Unsigned 256-bit wei amount scaled to a precision of 1e18
    function scaleUp(uint256 value, uint256 factor) internal pure returns (uint256 y) {
        y = value * factor;
    }

    /// @notice             Scales a wei value from a precision of 1e18 to 10^(18 - precision)
    /// @param   value      Unsigned 256-bit wei amount with 18 decimals
    /// @param   factor     Scaling factor to divide by, i.e. 10^(18 - value.decimals())
    /// @return  y          Unsigned 256-bit wei amount scaled to 10^(18 - factor)
    function scaleDown(uint256 value, uint256 factor) internal pure returns (uint256 y) {
        y = value / factor;
    }

    /// @notice             Converts unsigned 256-bit wei value into a fixed point 64.64 number
    /// @param   value      Unsigned 256-bit wei amount, in native precision
    /// @param   factor     Scaling factor for `value`, used to calculate decimals of `value`
    /// @return  y          Signed 64.64 fixed point number scaled from native precision
    function scaleToX64(uint256 value, uint256 factor) internal pure returns (int128 y) {
        uint256 scaleFactor = PRECISION / factor;
        y = value.divu(scaleFactor);
    }

    /// @notice             Converts signed fixed point 64.64 number into unsigned 256-bit wei value
    /// @param   value      Signed fixed point 64.64 number to convert from precision of 10^18
    /// @param   factor     Scaling factor for `value`, used to calculate decimals of `value`
    /// @return  y          Unsigned 256-bit wei amount scaled to native precision of 10^(18 - factor)
    function scalefromX64(int128 value, uint256 factor) internal pure returns (uint256 y) {
        uint256 scaleFactor = PRECISION / factor;
        y = value.mulu(scaleFactor);
    }

    /// @notice         Converts denormalized percentage integer to a fixed point 64.64 number
    /// @dev            Convert unsigned 256-bit integer number into signed 64.64 fixed point number
    /// @param denorm   Unsigned percentage integer with precision of 1e4
    /// @return         Signed 64.64 fixed point percentage with precision of 1e4
    function percentage(uint256 denorm) internal pure returns (int128) {
        return denorm.divu(PERCENTAGE);
    }

    /// @notice         Converts signed 64.64 fixed point percentage to a denormalized percetage integer
    /// @param denorm   Signed 64.64 fixed point percentage
    /// @return         Unsigned percentage denormalized with precision of 1e4
    function percentage(int128 denorm) internal pure returns (uint256) {
        return denorm.mulu(PERCENTAGE);
    }

    /// @notice         Converts unsigned seconds integer into years as a signed 64.64 fixed point number
    /// @dev            Convert unsigned 256-bit integer number into signed 64.64 fixed point number
    /// @param s        Unsigned 256-bit integer amount of seconds to convert into year units
    /// @return         Fixed point 64.64 number of years equal to `seconds`
    function toYears(uint256 s) internal pure returns (int128) {
        return s.divu(YEAR);
    }
}


// File @primitivefi/rmm-core/contracts/libraries/[email protected]


pragma solidity ^0.8.4;
/// @title   Replication Math
/// @author  Primitive
/// @notice  Alex Evans, Guillermo Angeris, and Tarun Chitra. Replicating Market Makers.
///          https://stanford.edu/~guillean/papers/rmms.pdf
library ReplicationMath {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    using CumulativeNormalDistribution for int128;
    using Units for int128;
    using Units for uint256;

    int128 internal constant ONE_INT = 0x10000000000000000;

    /// @notice         Normalizes volatility with respect to square root of time until expiry
    /// @param   sigma  Unsigned 256-bit percentage as an integer with precision of 1e4, 10000 = 100%
    /// @param   tau    Time until expiry in seconds as an unsigned 256-bit integer
    /// @return  vol    Signed fixed point 64.64 number equal to sigma * sqrt(tau)
    function getProportionalVolatility(uint256 sigma, uint256 tau) internal pure returns (int128 vol) {
        int128 sqrtTauX64 = tau.toYears().sqrt();
        int128 sigmaX64 = sigma.percentage();
        vol = sigmaX64.mul(sqrtTauX64);
    }

    /// @notice                 Uses riskyPerLiquidity and invariant to calculate stablePerLiquidity
    /// @dev                    Converts unsigned 256-bit values to fixed point 64.64 numbers w/ decimals of precision
    /// @param   invariantLastX64   Signed 64.64 fixed point number. Calculated w/ same `tau` as the parameter `tau`
    /// @param   scaleFactorRisky   Unsigned 256-bit integer scaling factor for `risky`, 10^(18 - risky.decimals())
    /// @param   scaleFactorStable  Unsigned 256-bit integer scaling factor for `stable`, 10^(18 - stable.decimals())
    /// @param   riskyPerLiquidity  Unsigned 256-bit integer of Pool's risky reserves *per liquidity*, 0 <= x <= 1
    /// @param   strike         Unsigned 256-bit integer value with precision equal to 10^(18 - scaleFactorStable)
    /// @param   sigma          Volatility of the Pool as an unsigned 256-bit integer w/ precision of 1e4, 10000 = 100%
    /// @param   tau            Time until expiry in seconds as an unsigned 256-bit integer
    /// @return  stablePerLiquidity = K*CDF(CDF^-1(1 - riskyPerLiquidity) - sigma*sqrt(tau)) + invariantLastX64 as uint
    function getStableGivenRisky(
        int128 invariantLastX64,
        uint256 scaleFactorRisky,
        uint256 scaleFactorStable,
        uint256 riskyPerLiquidity,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) internal pure returns (uint256 stablePerLiquidity) {
        int128 strikeX64 = strike.scaleToX64(scaleFactorStable);
        int128 volX64 = getProportionalVolatility(sigma, tau);
        int128 riskyX64 = riskyPerLiquidity.scaleToX64(scaleFactorRisky); // mul by 2^64, div by precision
        int128 phi = ONE_INT.sub(riskyX64).getInverseCDF();
        int128 input = phi.sub(volX64);
        int128 stableX64 = strikeX64.mul(input.getCDF()).add(invariantLastX64);
        stablePerLiquidity = stableX64.scalefromX64(scaleFactorStable);
    }

    /// @notice                 Uses stablePerLiquidity and invariant to calculate riskyPerLiquidity
    /// @dev                    Converts unsigned 256-bit values to fixed point 64.64 numbers w/ decimals of precision
    /// @param   invariantLastX64   Signed 64.64 fixed point number. Calculated w/ same `tau` as the parameter `tau`
    /// @param   scaleFactorRisky   Unsigned 256-bit integer scaling factor for `risky`, 10^(18 - risky.decimals())
    /// @param   scaleFactorStable  Unsigned 256-bit integer scaling factor for `stable`, 10^(18 - stable.decimals())
    /// @param   stablePerLiquidity Unsigned 256-bit integer of Pool's stable reserves *per liquidity*, 0 <= x <= strike
    /// @param   strike         Unsigned 256-bit integer value with precision equal to 10^(18 - scaleFactorStable)
    /// @param   sigma          Volatility of the Pool as an unsigned 256-bit integer w/ precision of 1e4, 10000 = 100%
    /// @param   tau            Time until expiry in seconds as an unsigned 256-bit integer
    /// @return  riskyPerLiquidity = 1 - CDF(CDF^-1((stablePerLiquidity - invariantLastX64)/K) + sigma*sqrt(tau))
    function getRiskyGivenStable(
        int128 invariantLastX64,
        uint256 scaleFactorRisky,
        uint256 scaleFactorStable,
        uint256 stablePerLiquidity,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) internal pure returns (uint256 riskyPerLiquidity) {
        int128 strikeX64 = strike.scaleToX64(scaleFactorStable);
        int128 volX64 = getProportionalVolatility(sigma, tau);
        int128 stableX64 = stablePerLiquidity.scaleToX64(scaleFactorStable);
        int128 phi = stableX64.sub(invariantLastX64).div(strikeX64).getInverseCDF();
        int128 input = phi.add(volX64);
        int128 riskyX64 = ONE_INT.sub(input.getCDF());
        riskyPerLiquidity = riskyX64.scalefromX64(scaleFactorRisky);
    }

    /// @notice                 Calculates the invariant of a curve
    /// @dev                    Per unit of replication, aka per unit of liquidity
    /// @param   scaleFactorRisky   Unsigned 256-bit integer scaling factor for `risky`, 10^(18 - risky.decimals())
    /// @param   scaleFactorStable  Unsigned 256-bit integer scaling factor for `stable`, 10^(18 - stable.decimals())
    /// @param   riskyPerLiquidity  Unsigned 256-bit integer of Pool's risky reserves *per liquidity*, 0 <= x <= 1
    /// @param   stablePerLiquidity Unsigned 256-bit integer of Pool's stable reserves *per liquidity*, 0 <= x <= strike
    /// @return  invariantX64       = stablePerLiquidity - K * CDF(CDF^-1(1 - riskyPerLiquidity) - sigma * sqrt(tau))
    function calcInvariant(
        uint256 scaleFactorRisky,
        uint256 scaleFactorStable,
        uint256 riskyPerLiquidity,
        uint256 stablePerLiquidity,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) internal pure returns (int128 invariantX64) {
        uint256 output = getStableGivenRisky(
            0,
            scaleFactorRisky,
            scaleFactorStable,
            riskyPerLiquidity,
            strike,
            sigma,
            tau
        );
        int128 outputX64 = output.scaleToX64(scaleFactorStable);
        int128 stableX64 = stablePerLiquidity.scaleToX64(scaleFactorStable);
        invariantX64 = stableX64.sub(outputX64);
    }
}


// File @primitivefi/rmm-core/contracts/interfaces/callback/[email protected]


pragma solidity >=0.5.0;

/// @title  Primitive Swap Callback
/// @author Primitive
interface IPrimitiveSwapCallback {
    /// @notice              Triggered when swapping tokens in an Engine
    /// @param  delRisky     Amount of risky tokens required to pay the swap with
    /// @param  delStable    Amount of stable tokens required to pay the swap with
    /// @param  data         Calldata passed on swap function call
    function swapCallback(
        uint256 delRisky,
        uint256 delStable,
        bytes calldata data
    ) external;
}


// File contracts/interfaces/ISwapManager.sol


pragma solidity >=0.8.6;

/// @title   Interface of SwapManager contract
/// @author  Primitive
interface ISwapManager is IPrimitiveSwapCallback {
    /// @notice                Parameters for the swap function
    /// @param recipient       Address of the recipient
    /// @param risky           Address of the risky token
    /// @param stable          Address of the stable token
    /// @param poolId          Id of the pool
    /// @param riskyForStable  True if swapping risky for stable
    /// @param deltaIn         Exact amount to send
    /// @param deltaOut        Exact amount to receive
    /// @param fromMargin      True if the sent amount should be taken from the margin
    /// @param toMargin        True if the received amount should be sent to the margin
    /// @param deadline        Transaction will revert above this deadline
    struct SwapParams {
        address recipient;
        address risky;
        address stable;
        bytes32 poolId;
        bool riskyForStable;
        uint256 deltaIn;
        uint256 deltaOut;
        bool fromMargin;
        bool toMargin;
        uint256 deadline;
    }

    /// ERRORS ///

    /// @notice Thrown when the deadline is reached
    error DeadlineReachedError();

    /// EVENTS ///

    /// @notice                Emitted when a swap occurs
    /// @param payer           Address of the payer
    /// @param recipient       Address of the recipient
    /// @param engine          Address of the engine
    /// @param poolId          Id of the pool
    /// @param riskyForStable  True if swapping risky for stable
    /// @param deltaIn         Sent amount
    /// @param deltaOut        Received amount
    /// @param fromMargin      True if the sent amount is taken from the margin
    /// @param toMargin        True if the received amount is sent to the margin
    event Swap(
        address indexed payer,
        address recipient,
        address indexed engine,
        bytes32 indexed poolId,
        bool riskyForStable,
        uint256 deltaIn,
        uint256 deltaOut,
        bool fromMargin,
        bool toMargin
    );

    /// EFFECTS FUNCTIONS ///

    /// @notice        Swaps an exact amount of risky OR stable tokens for some risky OR stable tokens
    /// @dev           Funds are swapped from a specific pool located into a specific engine
    /// @param params  A struct of type SwapParameters
    function swap(SwapParams memory params) external payable;
}


// File @primitivefi/rmm-core/contracts/interfaces/callback/[email protected]


pragma solidity >=0.5.0;

/// @title  Primitive Deposit Callback
/// @author Primitive
interface IPrimitiveDepositCallback {
    /// @notice              Triggered when depositing tokens to an Engine
    /// @param  delRisky     Amount of risky tokens required to deposit to risky margin balance
    /// @param  delStable    Amount of stable tokens required to deposit to stable margin balance
    /// @param  data         Calldata passed on deposit function call
    function depositCallback(
        uint256 delRisky,
        uint256 delStable,
        bytes calldata data
    ) external;
}


// File contracts/interfaces/IMarginManager.sol


pragma solidity >=0.8.6;

/// @title   Interface of MarginManager contract
/// @author  Primitive
interface IMarginManager is IPrimitiveDepositCallback {
    /// ERRORS ///

    /// @notice Thrown when trying to deposit or withdraw 0 risky and stable
    error ZeroDelError();

    /// EVENTS ///

    /// @notice           Emitted when funds are deposited
    /// @param payer      Address depositing the funds
    /// @param recipient  Address receiving the funds in their margin
    /// @param engine     Engine receiving the funds
    /// @param risky      Address of the risky token
    /// @param stable     Address of the stable token
    /// @param delRisky   Amount of deposited risky
    /// @param delStable  Amount of deposited stable
    event Deposit(
        address indexed payer,
        address indexed recipient,
        address indexed engine,
        address risky,
        address stable,
        uint256 delRisky,
        uint256 delStable
    );

    /// @notice           Emitted when funds are withdrawn
    /// @param payer      Address withdrawing the funds
    /// @param recipient  Address receiving the funds in their wallet
    /// @param engine     Engine where the funds are withdrawn from
    /// @param risky      Address of the risky token
    /// @param stable     Address of the stable token
    /// @param delRisky   Amount of withdrawn risky
    /// @param delStable  Amount of withdrawn stable
    event Withdraw(
        address indexed payer,
        address indexed recipient,
        address indexed engine,
        address risky,
        address stable,
        uint256 delRisky,
        uint256 delStable
    );

    /// EFFECT FUNCTIONS ///

    /// @notice           Deposits funds into the margin of a Primitive Engine
    /// @dev              Since the PrimitiveManager contract keeps track of the margins, it
    ///                   will deposit the funds into the Primitive Engine using its own address
    /// @param recipient  Address receiving the funds in their margin
    /// @param risky      Address of the risky token
    /// @param stable     Address of the stable token
    /// @param delRisky   Amount of risky token to deposit
    /// @param delStable  Amount of stable token to deposit
    function deposit(
        address recipient,
        address risky,
        address stable,
        uint256 delRisky,
        uint256 delStable
    ) external payable;

    /// @notice           Withdraws funds from the margin of a Primitive Engine
    /// @param recipient  Address receiving the funds in their wallet
    /// @param engine     Primitive Engine to withdraw from
    /// @param delRisky   Amount of risky token to withdraw
    /// @param delStable  Amount of stable token to withdraw
    function withdraw(
        address recipient,
        address engine,
        uint256 delRisky,
        uint256 delStable
    ) external;

    /// VIEW FUNCTIONS ///

    /// @notice                Returns the margin of an account for a specific Primitive Engine
    /// @param account         Address of the account
    /// @param engine          Address of the engine
    /// @return balanceRisky   Balance of risky in the margin of the user
    /// @return balanceStable  Balance of stable in the margin of the user
    function margins(address account, address engine)
        external
        view
        returns (uint128 balanceRisky, uint128 balanceStable);
}


// File @primitivefi/rmm-core/contracts/libraries/[email protected]


pragma solidity >=0.5.0;

/// @notice Safely cast between uint256 and uint128
library SafeCast {
    /// @notice reverts if x > type(uint128).max
    function toUint128(uint256 x) internal pure returns (uint128 z) {
        require((z = uint128(x)) == x);
    }
}


// File contracts/libraries/Margin.sol


pragma solidity >=0.8.6;

/// @author  Primitive
/// @notice  Utils functions to manage margins
/// @dev     Uses a data struct with two uint128s to optimize for one storage slot
library Margin {
    using SafeCast for uint256;

    struct Data {
        uint128 balanceRisky; // Balance of the risky token, aka underlying asset
        uint128 balanceStable; // Balance of the stable token, aka "quote" asset
    }

    /// @notice             Adds to risky and stable token balances
    /// @param  margin      Margin data of an account in storage to manipulate
    /// @param  delRisky    Amount of risky tokens to add to margin
    /// @param  delStable   Amount of stable tokens to add to margin
    function deposit(
        Data storage margin,
        uint256 delRisky,
        uint256 delStable
    ) internal {
        if (delRisky > 0) margin.balanceRisky += delRisky.toUint128();
        if (delStable > 0) margin.balanceStable += delStable.toUint128();
    }

    /// @notice             Removes risky and stable token balance from an internal margin account
    /// @param  margin      Margin data of an account in storage to manipulate
    /// @param  delRisky    Amount of risky tokens to subtract from margin
    /// @param  delStable   Amount of stable tokens to subtract from margin
    function withdraw(
        Data storage margin,
        uint256 delRisky,
        uint256 delStable
    ) internal {
        if (delRisky > 0) margin.balanceRisky -= delRisky.toUint128();
        if (delStable > 0) margin.balanceStable -= delStable.toUint128();
    }
}


// File contracts/base/MarginManager.sol


pragma solidity 0.8.6;






/// @title   MarginManager contract
/// @author  Primitive
/// @notice  Manages the margins
abstract contract MarginManager is IMarginManager, CashManager {
    using TransferHelper for IERC20;
    using Margin for Margin.Data;

    /// @inheritdoc IMarginManager
    mapping(address => mapping(address => Margin.Data)) public override margins;

    /// EFFECT FUNCTIONS ///

    /// @inheritdoc IMarginManager
    function deposit(
        address recipient,
        address risky,
        address stable,
        uint256 delRisky,
        uint256 delStable
    ) external payable override lock {
        if (delRisky == 0 && delStable == 0) revert ZeroDelError();

        address engine = EngineAddress.computeAddress(factory, risky, stable);
        if (EngineAddress.isContract(engine) == false) revert EngineAddress.EngineNotDeployedError();

        IPrimitiveEngineActions(engine).deposit(
            address(this),
            delRisky,
            delStable,
            abi.encode(CallbackData({payer: msg.sender, risky: risky, stable: stable}))
        );

        margins[recipient][engine].deposit(delRisky, delStable);

        emit Deposit(msg.sender, recipient, engine, risky, stable, delRisky, delStable);
    }

    /// @inheritdoc IMarginManager
    function withdraw(
        address recipient,
        address engine,
        uint256 delRisky,
        uint256 delStable
    ) external override lock {
        if (delRisky == 0 && delStable == 0) revert ZeroDelError();

        // Reverts the call early if margins are insufficient
        margins[msg.sender][engine].withdraw(delRisky, delStable);

        // Setting address(0) as the recipient will result in the tokens
        // being sent into the contract itself, useful to unwrap WETH for example
        IPrimitiveEngineActions(engine).withdraw(
            recipient == address(0) ? address(this) : recipient,
            delRisky,
            delStable
        );

        emit Withdraw(
            msg.sender,
            recipient == address(0) ? msg.sender : recipient,
            engine,
            IPrimitiveEngineView(engine).risky(),
            IPrimitiveEngineView(engine).stable(),
            delRisky,
            delStable
        );
    }

    /// CALLBACK IMPLEMENTATIONS ///

    /// @inheritdoc IPrimitiveDepositCallback
    function depositCallback(
        uint256 delRisky,
        uint256 delStable,
        bytes calldata data
    ) external override {
        CallbackData memory decoded = abi.decode(data, (CallbackData));

        address engine = EngineAddress.computeAddress(factory, decoded.risky, decoded.stable);
        if (msg.sender != engine) revert NotEngineError();

        if (delStable > 0) pay(decoded.stable, decoded.payer, msg.sender, delStable);
        if (delRisky > 0) pay(decoded.risky, decoded.payer, msg.sender, delRisky);
    }
}


// File contracts/base/SwapManager.sol


pragma solidity 0.8.6;






/// @title   SwapManager contract
/// @author  Primitive
/// @dev     Manages the swaps
abstract contract SwapManager is ISwapManager, CashManager, MarginManager {
    using TransferHelper for IERC20;
    using Margin for Margin.Data;

    /// @notice Reverts the transaction is the deadline is reached
    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) revert DeadlineReachedError();
        _;
    }

    /// EFFECT FUNCTIONS ///

    /// @inheritdoc ISwapManager
    function swap(SwapParams memory params) external payable override lock checkDeadline(params.deadline) {
        CallbackData memory callbackData = CallbackData({
            payer: msg.sender,
            risky: params.risky,
            stable: params.stable
        });

        address engine = EngineAddress.computeAddress(factory, params.risky, params.stable);
        if (EngineAddress.isContract(engine) == false) revert EngineAddress.EngineNotDeployedError();

        IPrimitiveEngineActions(engine).swap(
            params.toMargin ? address(this) : params.recipient,
            params.poolId,
            params.riskyForStable,
            params.deltaIn,
            params.deltaOut,
            params.fromMargin,
            params.toMargin,
            abi.encode(callbackData)
        );

        if (params.fromMargin) {
            margins[msg.sender][engine].withdraw(
                params.riskyForStable ? params.deltaIn : 0,
                params.riskyForStable ? 0 : params.deltaIn
            );
        }

        if (params.toMargin) {
            margins[params.recipient][engine].deposit(
                params.riskyForStable ? 0 : params.deltaOut,
                params.riskyForStable ? params.deltaOut : 0
            );
        }

        emit Swap(
            msg.sender,
            params.recipient,
            engine,
            params.poolId,
            params.riskyForStable,
            params.deltaIn,
            params.deltaOut,
            params.fromMargin,
            params.toMargin
        );
    }

    /// CALLBACK IMPLEMENTATIONS ///

    /// @inheritdoc IPrimitiveSwapCallback
    function swapCallback(
        uint256 delRisky,
        uint256 delStable,
        bytes calldata data
    ) external override {
        CallbackData memory decoded = abi.decode(data, (CallbackData));

        address engine = EngineAddress.computeAddress(factory, decoded.risky, decoded.stable);
        if (msg.sender != engine) revert NotEngineError();

        if (delRisky > 0) pay(decoded.risky, decoded.payer, msg.sender, delRisky);
        if (delStable > 0) pay(decoded.stable, decoded.payer, msg.sender, delStable);
    }
}


// File contracts/PrimitiveManager.sol


pragma solidity 0.8.6;








/// @title   PrimitiveManager contract
/// @author  Primitive
/// @notice  Interacts with Primitive Engine contracts
contract PrimitiveManager is IPrimitiveManager, Multicall, CashManager, SelfPermit, PositionManager, SwapManager {
    using TransferHelper for IERC20;
    using Margin for Margin.Data;

    /// EFFECT FUNCTIONS ///

    /// @param factory_           Address of a PrimitiveFactory
    /// @param WETH9_             Address of WETH9
    /// @param positionRenderer_  Address of PositionRenderer
    constructor(
        address factory_,
        address WETH9_,
        address positionRenderer_
    ) ManagerBase(factory_, WETH9_, positionRenderer_) {}

    /// @inheritdoc IPrimitiveManager
    function create(
        address risky,
        address stable,
        uint128 strike,
        uint32 sigma,
        uint32 maturity,
        uint32 gamma,
        uint256 riskyPerLp,
        uint256 delLiquidity
    )
        external
        payable
        override
        lock
        returns (
            bytes32 poolId,
            uint256 delRisky,
            uint256 delStable
        )
    {
        address engine = EngineAddress.computeAddress(factory, risky, stable);
        if (EngineAddress.isContract(engine) == false) revert EngineAddress.EngineNotDeployedError();

        if (delLiquidity == 0) revert ZeroLiquidityError();

        CallbackData memory callbackData = CallbackData({risky: risky, stable: stable, payer: msg.sender});

        (poolId, delRisky, delStable) = IPrimitiveEngineActions(engine).create(
            strike,
            sigma,
            maturity,
            gamma,
            riskyPerLp,
            delLiquidity,
            abi.encode(callbackData)
        );

        // Mints {delLiquidity - MIN_LIQUIDITY} of liquidity tokens
        uint256 MIN_LIQUIDITY = IPrimitiveEngineView(engine).MIN_LIQUIDITY();
        _allocate(msg.sender, engine, poolId, delLiquidity - MIN_LIQUIDITY);

        emit Create(msg.sender, engine, poolId, strike, sigma, maturity, gamma);
    }

    address private _engine;

    /// @inheritdoc IPrimitiveManager
    function allocate(
        bytes32 poolId,
        address risky,
        address stable,
        uint256 delRisky,
        uint256 delStable,
        bool fromMargin,
        uint256 minLiquidityOut
    ) external payable override lock returns (uint256 delLiquidity) {
        _engine = EngineAddress.computeAddress(factory, risky, stable);
        if (EngineAddress.isContract(_engine) == false) revert EngineAddress.EngineNotDeployedError();

        if (delRisky == 0 && delStable == 0) revert ZeroLiquidityError();

        (delLiquidity) = IPrimitiveEngineActions(_engine).allocate(
            poolId,
            address(this),
            delRisky,
            delStable,
            fromMargin,
            abi.encode(CallbackData({risky: risky, stable: stable, payer: msg.sender}))
        );

        if (delLiquidity < minLiquidityOut) revert MinLiquidityOutError();

        if (fromMargin) margins[msg.sender][_engine].withdraw(delRisky, delStable);

        // Mints {delLiquidity} of liquidity tokens
        _allocate(msg.sender, _engine, poolId, delLiquidity);

        emit Allocate(msg.sender, _engine, poolId, delLiquidity, delRisky, delStable, fromMargin);

        _engine = address(0);
    }

    /// @inheritdoc IPrimitiveManager
    function remove(
        address engine,
        bytes32 poolId,
        uint256 delLiquidity,
        uint256 minRiskyOut,
        uint256 minStableOut
    ) external override lock returns (uint256 delRisky, uint256 delStable) {
        if (delLiquidity == 0) revert ZeroLiquidityError();

        (delRisky, delStable) = IPrimitiveEngineActions(engine).remove(poolId, delLiquidity);
        if (delRisky < minRiskyOut || delStable < minStableOut) revert MinRemoveOutError();

        _remove(msg.sender, poolId, delLiquidity);

        Margin.Data storage mar = margins[msg.sender][engine];
        mar.deposit(delRisky, delStable);

        emit Remove(msg.sender, engine, poolId, delLiquidity, delRisky, delStable);
    }

    /// CALLBACK IMPLEMENTATIONS ///

    /// @inheritdoc IPrimitiveCreateCallback
    function createCallback(
        uint256 delRisky,
        uint256 delStable,
        bytes calldata data
    ) external override {
        CallbackData memory decoded = abi.decode(data, (CallbackData));

        address engine = EngineAddress.computeAddress(factory, decoded.risky, decoded.stable);
        if (msg.sender != engine) revert NotEngineError();

        if (delRisky > 0) pay(decoded.risky, decoded.payer, msg.sender, delRisky);
        if (delStable > 0) pay(decoded.stable, decoded.payer, msg.sender, delStable);
    }

    /// @inheritdoc IPrimitiveLiquidityCallback
    function allocateCallback(
        uint256 delRisky,
        uint256 delStable,
        bytes calldata data
    ) external override {
        CallbackData memory decoded = abi.decode(data, (CallbackData));

        address engine = EngineAddress.computeAddress(factory, decoded.risky, decoded.stable);
        if (msg.sender != engine) revert NotEngineError();

        if (delRisky > 0) pay(decoded.risky, decoded.payer, msg.sender, delRisky);
        if (delStable > 0) pay(decoded.stable, decoded.payer, msg.sender, delStable);
    }
}