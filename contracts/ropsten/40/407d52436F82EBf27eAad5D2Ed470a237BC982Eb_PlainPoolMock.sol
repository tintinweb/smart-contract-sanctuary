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

import "../../utils/Curve/IPlainPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// solhint-disable func-name-mixedcase
contract PlainPoolMock is IPlainPool {
  address public lpToken;

  address[3] public tokens;

  constructor(address _lpToken, address[3] memory _tokens) {
    lpToken = _lpToken;
    tokens = _tokens;
  }

  function calc_token_amount(uint256[3] memory amounts, bool) external pure override returns (uint256 minted) {
    for (uint8 i = 0; i < 3; i++) {
      minted += amounts[i];
    }
  }

  function add_liquidity(uint256[3] memory amounts, uint256) external override returns (uint256 minted) {
    for (uint8 i = 0; i < 3; i++) {
      IERC20 token = IERC20(tokens[i]);
      if (amounts[i] > 0) {
        require(token.allowance(msg.sender, address(this)) >= amounts[i], "PlainPoolMock::add_liquidity: token not allowance");
        token.transferFrom(msg.sender, address(this), amounts[i]);
      }
      minted += amounts[i];
    }
    IERC20(lpToken).transfer(msg.sender, minted);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IPlainPool {
  function calc_token_amount(uint256[3] memory amounts, bool isDeposit) external view returns (uint256);

  function add_liquidity(uint256[3] memory amounts, uint256 minMint) external returns (uint256);
}