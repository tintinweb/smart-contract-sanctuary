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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "../../utils/Curve/IGauge.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
contract GaugeMock is IGauge {
  address public override minter;

  address public override crv_token;

  address public override lp_token;

  uint256 public override totalSupply;

  mapping(address => uint256) public override balanceOf;

  constructor(
    address _minter,
    address _crvToken,
    address _lpToken
  ) {
    minter = _minter;
    crv_token = _crvToken;
    lp_token = _lpToken;
  }

  function deposit(uint256 amount, address recipient) public override {
    IERC20(lp_token).transferFrom(msg.sender, address(this), amount);
    balanceOf[recipient] += amount;
    totalSupply += amount;
  }

  function deposit(uint256 amount) external override {
    deposit(amount, msg.sender);
  }

  function withdraw(uint256 amount) external override {
    balanceOf[msg.sender] -= amount;
    totalSupply -= amount;
    IERC20(lp_token).transfer(msg.sender, amount);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IGauge {
  function minter() external view returns (address);

  function crv_token() external view returns (address);

  function lp_token() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function deposit(uint256 amount) external;

  function deposit(uint256 amount, address recipient) external;

  function withdraw(uint256 amount) external;
}