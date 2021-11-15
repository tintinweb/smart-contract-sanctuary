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
pragma solidity ^0.8.0;
import "@yield-protocol/utils/contracts/token/IERC20.sol";


interface IFYToken is IERC20 {
    /// @dev Asset that is returned on redemption. Also called underlying.
    function asset() external view returns (address);

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.1;

import "@yield-protocol/utils/contracts/token/IERC20.sol";
import "@yield-protocol/utils/contracts/token/IERC2612.sol";
import "@yield-protocol/vault-interfaces/IFYToken.sol";

interface IPool is IERC20, IERC2612 {
    function baseToken() external view returns(IERC20);
    function fyToken() external view returns(IFYToken);
    function maturity() external view returns(uint32);
    function getBaseTokenReserves() external view returns(uint112);
    function getFYTokenReserves() external view returns(uint112);
    function sellBaseToken(address to) external returns(uint128);
    function buyBaseToken(address to, uint128 baseTokenOut) external returns(uint128);
    function sellFYToken(address to) external returns(uint128);
    function buyFYToken(address to, uint128 fyTokenOut) external returns(uint128);
    function sellBaseTokenPreview(uint128 baseTokenIn) external view returns(uint128);
    function buyBaseTokenPreview(uint128 baseTokenOut) external view returns(uint128);
    function sellFYTokenPreview(uint128 fyTokenIn) external view returns(uint128);
    function buyFYTokenPreview(uint128 fyTokenOut) external view returns(uint128);
    function mint(address to, uint256 tokenOffered) external returns (uint256);
    function burn(address to, uint256 tokensBurned) external returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.1;

interface IPoolFactory {
  event PoolCreated(address indexed baseToken, address indexed fyToken, address pool);

  function POOL_BYTECODE_HASH() external pure returns (bytes32);
  function calculatePoolAddress(address token, address fyToken) external view returns (address);
  function getPool(address token, address fyToken) external view returns (address);
  function createPool(address token, address fyToken) external returns (address);
  function nextToken() external view returns (address);
  function nextFYToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@yield-protocol/utils/contracts/token/IERC20.sol";
import "@yield-protocol/yieldspace-interfaces/IPool.sol";
import "@yield-protocol/yieldspace-interfaces/IPoolFactory.sol";
import "@yield-protocol/vault-interfaces/IFYToken.sol";
import "./interfaces/IPermit.sol";

contract PoolCreator {
  IPoolFactory public immutable poolFactory;

  constructor(address _poolFactory) {
    poolFactory = IPoolFactory(_poolFactory);
  }

  function createPool(address fyToken, uint256 initialLiquidity) external {
    address underlying = IFYToken(fyToken).asset();
    address pool = poolFactory.createPool(underlying, fyToken);

    IERC20(underlying).transferFrom(msg.sender, address(this), initialLiquidity);
    IERC20(underlying).approve(pool, initialLiquidity);

    IPool(pool).mint(msg.sender, initialLiquidity);
  }

  function createPoolWithPermit(address fyToken, uint256 initialLiquidity, uint deadline, uint256 nonce, uint8 v, bytes32 r, bytes32 s) external {
    address underlying = IFYToken(fyToken).asset();

    // First try ERC-2612 permit, fall back to Dai permit
    try IPermit(underlying).permit(msg.sender, address(this), initialLiquidity, deadline, v, r, s) {
    } catch {
      // Dai
      IPermit(underlying).permit(msg.sender, address(this), nonce, deadline, true /* allowed */, v, r, s);
    }

    poolFactory.createPool(underlying, fyToken);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IPermit {
  // ERC-2612 permit
  function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

  // Dai Permit
  function permit(address holder, address spender, uint256 nonce, uint256 expiry,
                  bool allowed, uint8 v, bytes32 r, bytes32 s) external;
}

