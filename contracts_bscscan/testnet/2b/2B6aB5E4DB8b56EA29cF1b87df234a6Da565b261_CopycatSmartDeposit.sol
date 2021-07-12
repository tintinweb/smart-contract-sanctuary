pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICopycatLeader.sol";
import "./interfaces/IUniswapV2Router.sol";

contract CopycatSmartDeposit {
  event DepositUsingToken(
    address indexed leader,
    address indexed depositer,
    address indexed token,
    address router,
    uint256 tokenAmount,
    uint256 bnbOutputAmount,
    uint256 shareOutputAmount
  );
  function depositUsingToken(ICopycatLeader leader, uint256 tokenAmount, address router, uint256 shareMin, address[] calldata path) public returns (uint256) {
    uint256 bnbBefore = address(this).balance;

    IERC20(path[0]).approve(router, tokenAmount);
    
    IUniswapV2Router02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      address(this),
      block.timestamp
    );

    uint256 bnbOutputAmount = address(this).balance - bnbBefore;

    uint256 shareOutputAmount = leader.depositTo{value: bnbOutputAmount}(msg.sender, shareMin);

    emit DepositUsingToken(address(leader), msg.sender, path[0], router, tokenAmount, bnbOutputAmount, shareOutputAmount);
  }

  event WithdrawToToken(
    address indexed leader,
    address indexed withdrawer,
    address indexed token,
    address router,
    uint256 shareAmount,
    uint256 bnbOutputAmount,
    uint256 tokenOutputAmount
  );
  function withdrawToToken(ICopycatLeader leader, uint256 shareAmount, address router, uint256 tokenMin, address[] calldata path) public returns (uint256 tokenOutputAmount) {
    leader.transferFrom(msg.sender, address(this), shareAmount);
    
    uint256 bnbOutputAmount = leader.withdrawTo(address(this), shareAmount, 0);
    
    address token = path[path.length - 1];
    uint256 tokenBefore = IERC20(token).balanceOf(address(this));
    
    IUniswapV2Router02(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbOutputAmount}(
      tokenMin,
      path,
      address(this),
      block.timestamp
    );

    tokenOutputAmount = IERC20(token).balanceOf(address(this)) - tokenBefore;
    IERC20(token).transfer(msg.sender, tokenOutputAmount);

    emit WithdrawToToken(address(leader), msg.sender, token, router, shareAmount, bnbOutputAmount, tokenOutputAmount);
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

pragma solidity >=0.6.6;

import "./ICopycatAdapter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Copycat Leader with NFT renaming support
interface ICopycatLeader is IERC20 {
  function adapters(uint256 i) external view returns(ICopycatAdapter);

  function initialize(
    address _leaderAddr, 
    uint256 _depositCopycatFee,
    uint256 _withdrawCopycatFee,
    uint256 _level,
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _description,
    string memory _avatar
  ) external;

  // Setting fee is not allowed
  // function setDepositFeeRate(uint256 _depositFeeRate) external;
  // function setWithdrawFeeRate(uint256 _withdrawFeeRate) external;

  function getAdaptersLength() external view returns(uint256);

  // function getBnbInContract() external view returns(uint256);
  function getAdaptersBnb() external view returns(uint256[] memory);
  function getShareRatioSaveGas(uint256 totalBnb) external view returns(uint256);
  function getShareRatio() external view returns(uint256);
  function addAdapter(ICopycatAdapter adapter) external;

  function depositTo(address to, uint256 shareMin) external payable returns (uint256 totalShare);
  function deposit(uint256 shareMin) external payable returns (uint256 totalShare);
  //function depositUsingToken(uint256 tokenAmount, address router, uint256 shareMin, address[] calldata path) external returns (uint256);
  function withdraw(uint256 amount, uint256 bnbMin) external returns (uint256 outputAmount);
  function withdrawTo(address to, uint256 amount, uint256 bnbMin) external returns (uint256 outputAmount);
  //function withdrawToToken(uint256 shareAmount, address router, uint256 tokenMin, address[] calldata path) external returns (uint256 tokenOutputAmount);

  function toAdapter(uint256 adapterId, uint256 amountBnb, uint256 tokenMin) external returns(uint256);
  function toLeader(uint256 adapterId, uint256 percentage, uint256 bnbMin) external returns(uint256);

  function removeAdapter(uint256 adapterId) external;

  function disable() external;
  function upgrade(uint256 amount) external;
  function migrateTo(ICopycatLeader to) external;
  function migrationMintShare(uint256 amount) external;
}

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

pragma solidity >=0.6.6;

import "./ICopycatLeader.sol";

/**
  Adapter for CopycatLeader

  Example mode: swap / farm
*/
interface ICopycatAdapter {
  // Factory
  function factory() external returns(address);

  // Signature system for emergency use
  function contractSignature() external view returns(bytes32);

  // Initialize the adapter and bond it to leader
  function initializeLeader(ICopycatLeader _leaderContract) external;
  function getLeaderContract() external view returns(ICopycatLeader);
  function getLeaderAddress() external view returns(address);

  // Transfer BNB from leader to adapter and then convert BNB = msg.value to xxx
  function toAdapter(uint256 tokenMin) external payable returns(uint256);

  // Adapter sell xxx to BNB and transfer to leader (sell only ... percent (100% = 1e18)), returns BNB value
  function toLeader(uint256 percentage, uint256 bnbMin) external returns(uint256);

  // Sum of BNB value in all mode
  function getBnbValue() external view returns(uint256);

  function migrateTo(ICopycatLeader to) external;
}