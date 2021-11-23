// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IIndexPool.sol";
import "../interfaces/IZapUniswapV2.sol";
import "../lib/TransferHelper.sol";


contract BisharesZapUniswapRouterBurner {
  address public immutable weth;
  address public immutable zapper;

  constructor(address weth_, address zapper_) {
    address zero = address(0);
    require(zapper_ != zero, "BiShares: Zapper is zero address");
    require(weth_ != zero, "BiShares: WETH is zero address");
    weth = weth_;
    zapper = zapper_;
  }

  receive() external payable {
    require(msg.sender == weth, "BiShares: Received ether");
  }

  function burnForAllTokensAndSwapForTokens(
    address indexPool,
    uint256 poolAmountIn,
    address tokenOut,
    uint256 minAmountOut
  ) external returns (uint256 amountOutTotal) {
    amountOutTotal = _burnForAllTokensAndSwap(
      indexPool,
      tokenOut,
      poolAmountIn,
      minAmountOut
    );
    TransferHelper.safeTransfer(tokenOut, msg.sender, amountOutTotal);
  }

  function burnForAllTokensAndSwapForETH(
    address indexPool,
    uint256 poolAmountIn,
    uint256 minAmountOut
  ) external returns (uint256 amountOutTotal) {
    amountOutTotal = _burnForAllTokensAndSwap(
      indexPool,
      weth,
      poolAmountIn,
      minAmountOut
    );
    IWETH(weth).withdraw(amountOutTotal);
    TransferHelper.safeTransferETH(msg.sender, amountOutTotal);
  }

  function _burnForAllTokensAndSwap(
    address indexPool,
    address tokenOut,
    uint256 poolAmountIn,
    uint256 minAmountOut
  ) internal returns (uint256 amountOutTotal) {
    TransferHelper.safeTransferFrom(indexPool, msg.sender, address(this), poolAmountIn);
    address[] memory vaults = IIndexPool(indexPool).getCurrentTokens();
    address[] memory routers = IIndexPool(indexPool).routers();
    uint256[] memory minAmountsOut = new uint256[](vaults.length);
    for (uint256 i = 0; i < vaults.length; i++) minAmountsOut[i] = 1;
    IIndexPool(indexPool).exitPool(poolAmountIn, minAmountsOut);
    amountOutTotal = _swapTokens(vaults, routers, tokenOut);
    require(amountOutTotal >= minAmountOut, "BiShares: Insufficient output amount");
  }

  function _swapTokens(
    address[] memory vaults,
    address[] memory routers,
    address tokenOut
  ) private returns (uint amountOutTotal) {
    address this_ = address(this);
    for (uint256 i = 0; i < vaults.length; i++) {
      uint256 amount = IERC20(vaults[i]).balanceOf(this_);
      TransferHelper.safeApprove(vaults[i], zapper, amount);
      amountOutTotal += IZapUniswapV2(zapper).zapOut(
        routers[i],
        vaults[i],
        amount,
        tokenOut,
        1
      );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


interface IZapUniswapV2 {
    function zapIn(
        address router,
        address vault,
        uint256 valueAmount,
        uint256 vaultAmountOutMin
    ) external returns (uint256 vaultAmount);

    function zapOut(
        address router,
        address vault,
        uint256 withdrawAmount,
        address desiredToken,
        uint256 desiredTokenOutMin
    ) external returns (uint256 desiredTokenAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


interface IIndexPool {
  /**
   * @dev Token record data structure
   * @param bound is token bound to pool
   * @param ready has token been initialized
   * @param lastDenormUpdate timestamp of last denorm change
   * @param denorm denormalized weight
   * @param desiredDenorm desired denormalized weight (used for incremental changes)
   * @param index index of address in tokens array
   * @param balance token balance
   */
  struct Record {
    bool bound;
    bool ready;
    uint40 lastDenormUpdate;
    uint96 denorm;
    uint96 desiredDenorm;
    uint8 index;
    uint256 balance;
  }

  function configure(
    address controller,
    string memory name,
    string memory symbol,
    address[] memory uniswapV2Factories,
    address[] memory uniswapV2Routers,
    address uniswapV2Oracle
  ) external returns (bool);
  function initialize(
    address[] memory tokens,
    uint256[] memory balances,
    uint96[] memory denorms,
    address tokenProvider
  ) external returns (bool);
  function setMaxPoolTokens(uint256 maxPoolTokens) external returns (bool);
  function delegateCompLikeToken(address token, address delegatee) external returns (bool);
  function reweighTokens(
    address[] memory tokens,
    uint96[] memory desiredDenorms
  ) external returns (bool);
  function reindexTokens(
    address[] memory tokens,
    uint96[] memory desiredDenorms,
    uint256[] memory minimumBalances
  ) external returns (bool);
  function setMinimumBalance(address token, uint256 minimumBalance) external returns (bool);
  function joinPool(uint256 poolAmountOut, uint256[] memory maxAmountsIn) external returns (bool);
  function exitPool(uint256 poolAmountIn, uint256[] memory minAmountsOut) external returns (bool);

  function oracle() external view returns (address);
  function routers() external view returns (address[] memory);
  function factories() external view returns (address[] memory);
  function isPublicSwap() external view returns (bool);
  function getController() external view returns (address);
  function getMaxPoolTokens() external view returns (uint256);
  function isBound(address t) external view returns (bool);
  function getNumTokens() external view returns (uint256);
  function getCurrentTokens() external view returns (address[] memory);
  function getCurrentDesiredTokens() external view returns (address[] memory tokens);
  function getDenormalizedWeight(address token) external view returns (uint256);
  function getTokenRecord(address token) external view returns (Record memory record);
  function extrapolatePoolValueFromToken() external view returns (address, address, uint256);
  function getTotalDenormalizedWeight() external view returns (uint256);
  function getBalance(address token) external view returns (uint256);
  function getMinimumBalance(address token) external view returns (uint256);
  function getUsedBalance(address token) external view returns (uint256);
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