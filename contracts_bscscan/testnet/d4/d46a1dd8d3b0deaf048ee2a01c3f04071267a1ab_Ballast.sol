// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./interfaces/IERC20PresetFixedSupply.sol";
import "./interfaces/IBEP20.sol";
import "./interfaces/IBallast.sol";
import "./helpers/Context.sol";

contract Ballast is Context, IBallast {
  uint private tokenTotalSupply;
  uint private tokenDecimals;
  IBEP20 private btcb;
  IERC20PresetFixedSupply private token;

  constructor (address _btcbAddress, address _tokenAddress, uint _tokenTotalSupply) {
    btcb = IBEP20(_btcbAddress);
    token = IERC20PresetFixedSupply(_tokenAddress);
    tokenTotalSupply = _tokenTotalSupply;
  }

  function getTokenTotalSupply() public view override returns (uint) {
    return tokenTotalSupply;
  }

  function getTokenAddress() public view override returns (address) {
    return address(token);
  }

  function getBTCbAddress() public view override returns (address) {
    return address(btcb);
  }

  function getBTCbBalance() public view override returns(uint) {
    return btcb.balanceOf(address(this));
  }

  function getBTCbBalanceFrom(address _from) public view override returns (uint) {
    return estimateBTCbConversion(token.balanceOf(_from));
  }

  function estimateBTCbConversion(uint _tokenAmount) public view override returns (uint) {
    require(_tokenAmount <= tokenTotalSupply, "Token amount must be less than token total balance");
    uint tokenProportion = _tokenAmount * btcb.balanceOf(address(this));
    return tokenProportion / tokenTotalSupply;
  }

  function liquidate (uint _amount) public override {
    require(token.isPaused() == false, "Token must be Unpaused");
    require(_amount > 0, "Amount must be higher than 0");
    uint allowance = token.allowance(_msgSender(), address(this));
    require(allowance >= _amount, "The ballast must be allowed to spend the `_amount` of tokens");
    token.transferFrom(_msgSender(), token.getTokenOwner(), _amount);
    uint btcbAmount = estimateBTCbConversion(_amount);
    btcb.transfer(_msgSender(), btcbAmount);

    emit Liquidate(_amount, _msgSender());
  }

  function deposit (uint _amount) public override {
    require(_amount > 0, "Amount must be higher than 0");
    uint allowance = btcb.allowance(_msgSender(), address(this));
    require(allowance >= _amount, "The btcb must be allowed to spend the `_amount` of btcb's");
    btcb.transferFrom(_msgSender(), address(this), _amount);

    emit Deposit(_amount);
  }
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
pragma solidity ^0.8.0;

interface IBallast {
    function getTokenTotalSupply() external view returns (uint);
    function getTokenAddress() external view returns (address);
    function getBTCbAddress() external view returns (address);
    function getBTCbBalance() external view returns(uint);
    function getBTCbBalanceFrom(address _from) external view returns (uint);
    function estimateBTCbConversion(uint _tokenAmount) external view returns (uint);
    function deposit (uint _amount) external;
    function liquidate (uint _amount) external;

    event Liquidate(uint _amount, address _from);
    event Withdraw(uint _amount);
    event Deposit(uint _amount);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

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

import "./IERC20Metadata.sol";

interface IERC20PresetFixedSupply is IERC20Metadata {
    function isPaused() external view returns (bool);
    function ableToPause() external view returns (bool);
    function getTokenOwner() external view returns (address);
    function getContractOwner() external view returns (address);
    function pause() external;
    function unPause() external;
    function notPausable() external;
}

