/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0

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






interface IUniswapV2Router is IUniswapV2Router01 {
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



contract ConvertPortal {
  address public cotToken;
  IUniswapV2Router public router;
  address public weth;
  address constant private ETH_TOKEN_ADDRESS = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

  /**
  * @dev contructor
  *
  * @param _cotToken               address of CoTrader erc20 contract
  * @param _router                 address of Uniswap v2
  */
  constructor(
    address _cotToken,
    address _router
    )
    public
  {
    cotToken = _cotToken;
    router = IUniswapV2Router(_router);
    weth = router.WETH();
  }

  // check if token can be converted to COT in Uniswap v2
  function isConvertibleToCOT(address _token, uint256 _amount)
   public
   view
  returns(uint256 cotAmount)
  {
    address fromToken = _token == address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee)
    ? weth
    : _token;

    address[] memory path = new address[](2);
    path[0] = fromToken;
    path[1] = cotToken;

    try router.getAmountsOut(_amount, path) returns(uint256[] memory res){
      cotAmount = res[1];
    }catch{
      cotAmount = 0;
    }
  }

  // check if token can be converted to ETH in Uniswap v2
  function isConvertibleToETH(address _token, uint256 _amount)
   public
   view
  returns(uint256 ethAmount)
  {
    address[] memory path = new address[](2);
    path[0] = _token;
    path[1] = weth;
    try router.getAmountsOut(_amount, path) returns(uint256[] memory res){
      ethAmount = res[1];
    }catch{
      ethAmount = 0;
    }
  }

  // Convert ETH to COT directly
  function convertETHToCOT(uint256 _amount)
   public
   payable
   returns (uint256 cotAmount)
  {
    require(msg.value == _amount, "wrong ETH amount");
    address[] memory path = new address[](2);
    path[0] = weth;
    path[1] = cotToken;
    uint256 deadline = now + 20 minutes;

    uint256[] memory amounts = router.swapExactETHForTokens.value(_amount)(
      1,
      path,
      msg.sender,
      deadline
    );

    // send eth remains
    uint256 remains = address(this).balance;
    if(remains > 0)
      payable(msg.sender).transfer(remains);

    cotAmount = amounts[1];
  }

  // convert Token to COT directly
  function convertTokenToCOT(address _token, uint256 _amount)
   external
   returns (uint256 cotAmount)
  {
    _transferFromSenderAndApproveTo(IERC20(_token), _amount, address(router));
    address[] memory path = new address[](2);
    path[0] = _token;
    path[1] = cotToken;
    uint256 deadline = now + 20 minutes;

    uint256[] memory amounts = router.swapExactTokensForTokens(
      _amount,
      1,
      path,
      msg.sender,
      deadline
    );

    // send token remains
    uint256 remains = IERC20(_token).balanceOf(address(this));
    if(remains > 0)
      IERC20(_token).transfer(msg.sender, remains);

    cotAmount = amounts[1];
  }

  // convert Token to COT via ETH
  function convertTokenToCOTViaETHHelp(address _token, uint256 _amount)
   external
   returns (uint256 cotAmount)
  {
    _transferFromSenderAndApproveTo(IERC20(_token), _amount, address(router));
    address[] memory path = new address[](3);
    path[0] = _token;
    path[1] = weth;
    path[2] = cotToken;
    uint256 deadline = now + 20 minutes;

    uint256[] memory amounts = router.swapExactTokensForTokens(
      _amount,
      1,
      path,
      msg.sender,
      deadline
    );

    // send token remains
    uint256 remains = IERC20(_token).balanceOf(address(this));
    if(remains > 0)
      IERC20(_token).transfer(msg.sender, remains);

    cotAmount = amounts[2];
  }

 /**
  * @dev Transfers tokens to this contract and approves them to another address
  *
  * @param _source          Token to transfer and approve
  * @param _sourceAmount    The amount to transfer and approve (in _source token)
  * @param _to              Address to approve to
  */
  function _transferFromSenderAndApproveTo(IERC20 _source, uint256 _sourceAmount, address _to) private {
    require(_source.transferFrom(msg.sender, address(this), _sourceAmount));

    _source.approve(_to, _sourceAmount);
  }

  // fallback payable function to receive ether from other contract addresses
  fallback() external payable {}
}