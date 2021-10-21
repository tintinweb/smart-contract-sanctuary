// SPDX-License-Identifier: GPL-3.0
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/MatrixPoolInterface.sol";
import "./interfaces/MatrixPoolFactoryInterface.sol";

contract MatrixPoolActions {
  struct Args {
    uint256 minWeightPerSecond;
    uint256 maxWeightPerSecond;
    uint256 swapFee;
    uint256 communitySwapFee;
    uint256 communityJoinFee;
    uint256 communityExitFee;
    address communityFeeReceiver;
    bool finalize;
  }

  struct TokenConfig {
    address token;
    uint256 balance;
    uint256 targetDenorm;
    uint256 fromTimestamp;
    uint256 targetTimestamp;
  }

  function create(
    MatrixPoolFactoryInterface factory,
    string calldata name,
    string calldata symbol,
    Args calldata args,
    TokenConfig[] calldata tokens
  ) external returns (MatrixPoolInterface pool) {
    pool = factory.newPool(name, symbol, address(this), args.minWeightPerSecond, args.maxWeightPerSecond);
    pool.setSwapFee(args.swapFee);
    pool.setCommunityFeeAndReceiver(
      args.communitySwapFee,
      args.communityJoinFee,
      args.communityExitFee,
      args.communityFeeReceiver
    );

    for (uint256 i = 0; i < tokens.length; i++) {
      TokenConfig memory tokenConfig = tokens[i];
      IERC20 token = IERC20(tokenConfig.token);
      require(token.transferFrom(msg.sender, address(this), tokenConfig.balance), "ERR_TRANSFER_FAILED");
      if (token.allowance(address(this), address(pool)) > 0) {
        token.approve(address(pool), 0);
      }
      token.approve(address(pool), tokenConfig.balance);
      pool.bind(
        tokenConfig.token,
        tokenConfig.balance,
        tokenConfig.targetDenorm,
        tokenConfig.fromTimestamp,
        tokenConfig.targetTimestamp
      );
    }

    if (args.finalize) {
      pool.finalize();
      require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    }

    pool.setController(msg.sender);
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

pragma solidity 0.6.12;

import "./BPoolInterface.sol";

interface MatrixPoolInterface is BPoolInterface {
  function initialize(
    string calldata name,
    string calldata symbol,
    uint256 minWeightPerSecond,
    uint256 maxWeightPerSecond
  ) external;

  function bind(
    address,
    uint256,
    uint256,
    uint256,
    uint256
  ) external;

  function setDynamicWeight(
    address token,
    uint256 targetDenorm,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  ) external;

  function getDynamicWeightSettings(address token)
    external
    view
    returns (
      uint256 fromTimestamp,
      uint256 targetTimestamp,
      uint256 fromDenorm,
      uint256 targetDenorm
    );

  function getMinWeight() external view override returns (uint256);

  function getWeightPerSecondBounds() external view returns (uint256, uint256);

  function setWeightPerSecondBounds(uint256, uint256) external;

  function setWrapper(address, bool) external;

  function getWrapperMode() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./MatrixPoolInterface.sol";

interface MatrixPoolFactoryInterface {
  function newPool(
    string calldata _name,
    string calldata _symbol,
    address _controller,
    uint256 _minWeightPerSecond,
    uint256 _maxWeightPerSecond
  ) external returns (MatrixPoolInterface);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BMathInterface.sol";

interface BPoolInterface is IERC20, BMathInterface {
  function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

  function swapExactAmountIn(
    address,
    uint256,
    address,
    uint256,
    uint256
  ) external returns (uint256, uint256);

  function swapExactAmountOut(
    address,
    uint256,
    address,
    uint256,
    uint256
  ) external returns (uint256, uint256);

  function joinswapExternAmountIn(
    address,
    uint256,
    uint256
  ) external returns (uint256);

  function joinswapPoolAmountOut(
    address,
    uint256,
    uint256
  ) external returns (uint256);

  function exitswapPoolAmountIn(
    address,
    uint256,
    uint256
  ) external returns (uint256);

  function exitswapExternAmountOut(
    address,
    uint256,
    uint256
  ) external returns (uint256);

  function getDenormalizedWeight(address) external view returns (uint256);

  function getBalance(address) external view returns (uint256);

  function getSwapFee() external view returns (uint256);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getCommunityFee()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      address
    );

  function calcAmountWithCommunityFee(
    uint256,
    uint256,
    address
  ) external view returns (uint256, uint256);

  function getRestrictions() external view returns (address);

  function isSwapsDisabled() external view returns (bool);

  function isFinalized() external view returns (bool);

  function isBound(address t) external view returns (bool);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function getFinalTokens() external view returns (address[] memory tokens);

  function setSwapFee(uint256) external;

  function setCommunityFeeAndReceiver(
    uint256,
    uint256,
    uint256,
    address
  ) external;

  function setController(address) external;

  function setSwapsDisabled(bool) external;

  function finalize() external;

  function bind(
    address,
    uint256,
    uint256
  ) external;

  function rebind(
    address,
    uint256,
    uint256
  ) external;

  function unbind(address) external;

  function gulp(address) external;

  function callVoting(
    address voting,
    bytes4 signature,
    bytes calldata args,
    uint256 value
  ) external;

  function getMinWeight() external view returns (uint256);

  function getMaxBoundTokens() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface BMathInterface {
  function calcInGivenOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) external pure returns (uint256 tokenAmountIn);

  function calcSingleInGivenPoolOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountOut,
    uint256 swapFee
  ) external pure returns (uint256 tokenAmountIn);
}