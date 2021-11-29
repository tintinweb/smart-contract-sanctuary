// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// 3rd-party library imports
import { IUniswapV2Router02 } from "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 1st-party project imports
import { Constants } from "./Constants.sol";
import { SwapUser } from "./DataStructures.sol";

contract TokenSwapper {
  address private tusdTokenAddr;
  address private wbtcTokenAddr;

  constructor(address _tusdTokenAddr, address _wbtcTokenAddr) public {
    tusdTokenAddr = _tusdTokenAddr;
    wbtcTokenAddr = _wbtcTokenAddr;
  }

  /*
   * Generic function to approve and perform swap from starting to ending token
   */
  function _swapTokens(uint _inputAmt, address[] memory _tokenPath) internal returns (uint) {
    // First get approval to transfer from starting to ending token via the router
    require(
      IERC20(_tokenPath[0]).approve(Constants.SUSHIV2_ROUTER02_ADDRESS, _inputAmt),
      "APPROVE_SWAP_START_TOKEN_FAIL"
    );

    IUniswapV2Router02 swapRouter = IUniswapV2Router02(
      Constants.SUSHIV2_ROUTER02_ADDRESS
    );

    // Finally, perform the swap from starting to ending token via the token path specified
    uint[] memory swappedAmts = swapRouter.swapExactTokensForTokens(
      _inputAmt,       // amount in terms of starting token
      1,               // min amount expected in terms of ending token
      _tokenPath,      // path of swapping from starting to ending token
      address(this),   // address of where the starting & ending token assets are/will be held
      block.timestamp  // expiry time for transaction
    );

    return swappedAmts[swappedAmts.length - 1];
  }

  /*
   * Swapping TUSD -> BTC (WBTC)
   */
  function swapToWBTC(SwapUser memory _user) external returns (SwapUser memory) {
    require(_user.tusdBalance > 0, "USER_SWAP_TUSD_NOT_FOUND");

    // HACK: This form of array initialization is used to bypass a type cast error
    address[] memory path = new address[](2);
    path[0] = tusdTokenAddr;
    path[1] = wbtcTokenAddr;

    uint addedWbtcBalance = _swapTokens(_user.tusdBalance, path);

    _user.tusdBalance = 0;
    _user.wbtcBalance += addedWbtcBalance;

    return _user;
  }

  /*
   * Swapping BTC (WBTC) -> TUSD
   */
  function swapToTUSD(SwapUser memory _user) external returns (SwapUser memory) {
    require(_user.wbtcBalance > 0, "USER_SWAP_WBTC_NOT_FOUND");

    // HACK: This form of array initialization is used to bypass a type cast error
    address[] memory path = new address[](2);
    path[0] = wbtcTokenAddr;
    path[1] = tusdTokenAddr;

    uint addedTusdBalance = _swapTokens(_user.wbtcBalance, path);

    _user.tusdBalance += addedTusdBalance;
    _user.wbtcBalance = 0;

    return _user;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
pragma solidity ^0.6.12;

library Constants {
  address public constant SUSHIV2_FACTORY_ADDRESS = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
  address public constant SUSHIV2_ROUTER02_ADDRESS = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

  address public constant VRF_COORDINATOR_ADDRESS = 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9;
  bytes32 public constant VRF_KEY_HASH = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;

  address public constant KOVAN_LINK_TOKEN = 0xa36085F69e2889c224210F603D836748e7dC0088;

  uint public constant ONE_TENTH_LINK_PAYMENT = 0.1 * 1 ether;
  uint public constant ONE_LINK_PAYMENT = 1 ether;

  uint public constant TUSD_MULT_AMT = 10 ** 7;

  ////////////////////////
  // Oracle information //
  ////////////////////////

  address public constant BTC_USD_PRICE_FEED_ADDR = 0x6135b13325bfC4B00278B4abC5e20bbce2D6580e;

  address public constant PRICE_ORACLE_ADDR = 0xfF07C97631Ff3bAb5e5e5660Cdf47AdEd8D4d4Fd;
  bytes32 public constant PRICE_JOB_ID = "35e14dbd490f4e3b9fbe92b85b32d98a";

  address public constant HTTP_GET_ORACLE_ADDR = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
  bytes32 public constant HTTP_GET_JOB_ID = "d5270d1c311941d0b08bead21fea7747";
  string public constant TUSD_URL = "https://core-api.real-time-attest.trustexplorer.io/trusttoken/TrueUSD";

  address public constant SENTIMENT_ORACLE_ADDR = 0x56dd6586DB0D08c6Ce7B2f2805af28616E082455;
  bytes32 public constant SENTIMENT_JOB_ID = "e7beed14d06d477192ef30edc72557b1";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

struct SwapUser {
  // The 'exists' attribute is used purely for checking if a user exists. This works
  // since when you instantiate a new SwapUser, the default value is 'false'
  bool exists;

  uint tusdBalance;
  uint wbtcBalance;
  bool optInStatus;
}

struct PredictionResponse {
  uint btcPriceCurrent;
  uint btcPricePrediction;
  uint tusdAssetsAmt;
  uint tusdReservesAmt;
  int btcSentiment;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}