// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >= 0.8.0;

import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC2612.sol";
import "@yield-protocol/utils-v2/contracts/token/AllTransferHelper.sol";
import "@yield-protocol/utils-v2/contracts/utils/RevertMsgExtractor.sol";
import "@yield-protocol/utils-v2/contracts/interfaces/IWETH9.sol";
import "@yield-protocol/yieldspace-interfaces/IPool.sol";
import "@yield-protocol/yieldspace-interfaces/IPoolFactory.sol";
import "@yield-protocol/yieldspace-interfaces/PoolDataTypes.sol";
import "dss-interfaces/src/dss/DaiAbstract.sol";


contract PoolRouter {
    using AllTransferHelper for IERC20;
    using AllTransferHelper for address payable;

    IPoolFactory public immutable factory;
    IWETH9 public immutable weth;

    constructor(IPoolFactory factory_, IWETH9 weth_) {
        factory = factory_;
        weth = weth_;
    }

    struct PoolAddresses {
        address base;
        address fyToken;
        address pool;
    }

    /// @dev Submit a series of calls for execution
    /// The `bases` and `fyTokens` parameters define the pools that will be target for operations
    /// Each trio of `target`, `operation` and `data` define one call:
    ///  - `target` is an index in the `bases` and `fyTokens` arrays, from which contract addresses the target will be determined.
    ///  - `operation` is a numerical identifier for the call to be executed, from the enum `Operation`
    ///  - `data` is an abi-encoded group of parameters, to be consumed by the function encoded in `operation`.
    function batch(
        PoolDataTypes.Operation[] calldata operations,
        bytes[] calldata data
    ) external payable {
        require(operations.length == data.length, "Mismatched operation data");
        PoolAddresses memory cache;

        for (uint256 i = 0; i < operations.length; i += 1) {
            PoolDataTypes.Operation operation = operations[i];
            
            if (operation == PoolDataTypes.Operation.ROUTE) {
                (address base, address fyToken, bytes memory poolcall) = abi.decode(data[i], (address, address, bytes));
                if (cache.base != base || cache.fyToken != fyToken) cache = PoolAddresses(base, fyToken, findPool(base, fyToken));
                _route(cache, poolcall);

            } else if (operation == PoolDataTypes.Operation.TRANSFER_TO_POOL) {
                (address base, address fyToken, address token, uint128 wad) = abi.decode(data[i], (address, address, address, uint128));
                if (cache.base != base || cache.fyToken != fyToken) cache = PoolAddresses(base, fyToken, findPool(base, fyToken));
                _transferToPool(cache, token, wad);

            } else if (operation == PoolDataTypes.Operation.FORWARD_PERMIT) {
                (address base, address fyToken, address token, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) = 
                    abi.decode(data[i], (address, address, address, address, uint256, uint256, uint8, bytes32, bytes32));
                if (cache.base != base || cache.fyToken != fyToken) cache = PoolAddresses(base, fyToken, findPool(base, fyToken));
                _forwardPermit(cache, token, spender, amount, deadline, v, r, s);

            } else if (operation == PoolDataTypes.Operation.FORWARD_DAI_PERMIT) {
                        (address base, address fyToken, address spender, uint256 nonce, uint256 deadline, bool allowed, uint8 v, bytes32 r, bytes32 s) = 
                    abi.decode(data[i], (address, address, address, uint256, uint256, bool, uint8, bytes32, bytes32));
                if (cache.base != base || cache.fyToken != fyToken) cache = PoolAddresses(base, fyToken, findPool(base, fyToken));
                _forwardDaiPermit(cache, spender, nonce, deadline, allowed, v, r, s);

            } else if (operation == PoolDataTypes.Operation.JOIN_ETHER) {
                (address base, address fyToken) = abi.decode(data[i], (address, address));
                if (cache.base != base || cache.fyToken != fyToken) cache = PoolAddresses(base, fyToken, findPool(base, fyToken));
                _joinEther(cache.pool);

            } else if (operation == PoolDataTypes.Operation.EXIT_ETHER) {
                (address to) = abi.decode(data[i], (address));
                _exitEther(to);

            } else {
                revert("Invalid operation");
            }
        }
    }

    /// @dev Return which pool contract matches the base and fyToken
    function findPool(address base, address fyToken)
        private view returns (address pool)
    {
        pool = factory.getPool(base, fyToken);
        require (pool != address(0), "Pool not found");
    }

    /// @dev Allow users to trigger a token transfer to a pool, to be used with multicall
    function transferToPool(address base, address fyToken, address token, uint128 wad)
        external payable
        returns (bool)
    {
        return _transferToPool(
            PoolAddresses(base, fyToken, findPool(base, fyToken)),
            token, wad
        );
    }

    /// @dev Allow users to trigger a token transfer to a pool, to be used with batch
    function _transferToPool(PoolAddresses memory addresses, address token, uint128 wad)
        private
        returns (bool)
    {
        require(token == addresses.base || token == addresses.fyToken || token == addresses.pool, "Mismatched token");
        IERC20(token).safeTransferFrom(msg.sender, address(addresses.pool), wad);
        return true;
    }

    /// @dev Allow users to route calls to a pool, to be used with batch
    function _route(PoolAddresses memory addresses, bytes memory data)
        private
        returns (bool success, bytes memory result)
    {
        (success, result) = addresses.pool.call(data);
        if (!success) revert(RevertMsgExtractor.getRevertMsg(result));
    }

    // ---- Permit management ----

    /// @dev Execute an ERC2612 permit for the selected asset or fyToken, to be used with batch
    function _forwardPermit(PoolAddresses memory addresses, address token, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        private
    {
        require(token == addresses.base || token == addresses.fyToken || token == addresses.pool, "Mismatched token");
        IERC2612(token).permit(msg.sender, spender, amount, deadline, v, r, s);
    }

    /// @dev Execute a Dai-style permit for the selected asset or fyToken, to be used with batch
    function _forwardDaiPermit(PoolAddresses memory addresses, address spender, uint256 nonce, uint256 deadline, bool allowed, uint8 v, bytes32 r, bytes32 s)
        private
    {
        // Only the base token would ever be Dai
        DaiAbstract(addresses.base).permit(msg.sender, spender, nonce, deadline, allowed, v, r, s);
    }

    // ---- Ether management ----

    /// @dev The WETH9 contract will send ether to the PoolRouter on `weth.withdraw` using this function.
    receive() external payable {
        require (msg.sender == address(weth), "Only Weth contract allowed");
    }

    /// @dev Accept Ether, wrap it and forward it to the to a pool
    function _joinEther(address pool)
        private
        returns (uint256 ethTransferred)
    {
        ethTransferred = address(this).balance;

        weth.deposit{ value: ethTransferred }();   // TODO: Test gas savings using WETH10 `depositTo`
        IERC20(weth).safeTransfer(pool, ethTransferred);
    }

    /// @dev Unwrap Wrapped Ether held by this Router, and send the Ether
    function _exitEther(address to)
        private
        returns (uint256 ethTransferred)
    {
        ethTransferred = weth.balanceOf(address(this));

        weth.withdraw(ethTransferred);   // TODO: Test gas savings using WETH10 `withdrawTo`
        payable(to).safeTransferETH(ethTransferred); /// TODO: Consider reentrancy and safe transfers
    }
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

// SPDX-License-Identifier: GPL-3.0-or-later
// Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
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
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Taken from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

import "./IERC20.sol";
import "../utils/RevertMsgExtractor.sol";


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library AllTransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert(RevertMsgExtractor.getRevertMsg(data));
    }

    /// @notice Transfers tokens from the targeted address to the given destination
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert(RevertMsgExtractor.getRevertMsg(data));
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address payable to, uint256 value) internal {
        (bool success, bytes memory data) = to.call{value: value}(new bytes(0));
        if (!success) revert(RevertMsgExtractor.getRevertMsg(data));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Taken from https://github.com/sushiswap/BoringSolidity/blob/441e51c0544cf2451e6116fe00515e71d7c42e2c/contracts/BoringBatchable.sol

pragma solidity >=0.6.0;


library RevertMsgExtractor {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function getRevertMsg(bytes memory returnData)
        internal pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            returnData := add(returnData, 0x04)
        }
        return abi.decode(returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import "../token/IERC20.sol";

pragma solidity ^0.8.0;


interface IWETH9 is IERC20 {
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    function deposit() external payable;
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC2612.sol";
import "@yield-protocol/vault-interfaces/IFYToken.sol";


interface IPool is IERC20, IERC2612 {
    function base() external view returns(IERC20);
    function fyToken() external view returns(IFYToken);
    function maturity() external view returns(uint32);
    function getBaseBalance() external view returns(uint112);
    function getFYTokenBalance() external view returns(uint112);
    function retrieveBase(address to) external returns(uint128 retrieved);
    function retrieveFYToken(address to) external returns(uint128 retrieved);
    function sellBase(address to, uint128 min) external returns(uint128);
    function buyBase(address to, uint128 baseOut, uint128 max) external returns(uint128);
    function sellFYToken(address to, uint128 min) external returns(uint128);
    function buyFYToken(address to, uint128 fyTokenOut, uint128 max) external returns(uint128);
    function sellBasePreview(uint128 baseIn) external view returns(uint128);
    function buyBasePreview(uint128 baseOut) external view returns(uint128);
    function sellFYTokenPreview(uint128 fyTokenIn) external view returns(uint128);
    function buyFYTokenPreview(uint128 fyTokenOut) external view returns(uint128);
    function mint(address to, bool calculateFromBase, uint256 minTokensMinted) external returns (uint256, uint256, uint256);
    function mintWithBase(address to, uint256 fyTokenToBuy, uint256 minTokensMinted) external returns (uint256, uint256, uint256);
    function burn(address to, uint256 minBaseOut, uint256 minFYTokenOut) external returns (uint256, uint256, uint256);
    function burnForBase(address to, uint256 minBaseOut) external returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;


interface IPoolFactory {
  event PoolCreated(address indexed base, address indexed fyToken, address pool);

  function POOL_BYTECODE_HASH() external pure returns (bytes32);
  function calculatePoolAddress(address base, address fyToken) external view returns (address);
  function getPool(address base, address fyToken) external view returns (address);
  function createPool(address base, address fyToken) external returns (address);
  function nextBase() external view returns (address);
  function nextFYToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;


library PoolDataTypes {
  enum TokenType { BASE, FYTOKEN, LP }

  enum Operation {
    ROUTE, // 0
    TRANSFER_TO_POOL, // 1
    FORWARD_PERMIT, // 2
    FORWARD_DAI_PERMIT, // 3
    JOIN_ETHER, // 4
    EXIT_ETHER // 5
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss/blob/master/src/dai.sol
interface DaiAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function version() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function nonces(address) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function approve(address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function permit(address, address, uint256, uint256, bool, uint8, bytes32, bytes32) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";


interface IFYToken is IERC20 {
    /// @dev Asset that is returned on redemption.
    function underlying() external view returns (address);

    /// @dev Unix time at which redemption of fyToken for underlying are possible
    function maturity() external view returns (uint256);
    
    /// @dev Record price data at maturity
    function mature() external;

    /// @dev Burn fyToken after maturity for an amount of underlying.
    function redeem(address to, uint256 amount) external returns (uint256);

    /// @dev Mint fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param to Wallet to mint the fyToken in.
    /// @param fyTokenAmount Amount of fyToken to mint.
    function mint(address to, uint256 fyTokenAmount) external;

    /// @dev Burn fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param from Wallet to burn the fyToken from.
    /// @param fyTokenAmount Amount of fyToken to burn.
    function burn(address from, uint256 fyTokenAmount) external;
}

