/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

//"SPDX-License-Identifier: UNLICENSED"

pragma solidity 0.8.5;

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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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

interface IUniswapV2Router01 {
    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (uint[] memory amounts);
    
    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
        ) external returns (uint[] memory amounts);
}

contract DeSpaceRouter {
    
    IUniswapV2Router01 private _iUni;
    
    event EthToTokenSwap(
        address indexed user, 
        uint ethSpent, 
        uint tokenReceived);
    event TokenToEthSwap(
        address indexed user, 
        uint tokenSpent, 
        uint ethReceived);
    event TokenToTokenSwap(
        address indexed user,
        address tokenA,
        address tokenB,
        uint tokenSpent, 
        uint tokenReceived);
    
    constructor(address _uniswapV2RouterAddress) {
        //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ropsten address
        _iUni = IUniswapV2Router01(_uniswapV2RouterAddress);
    }
    
    function swapETHForTokens(
        address _token,
        uint _amountOutMin
        ) external payable {
        require(msg.value > 0, 'Insufficient Balance');
        address[] memory path = new address[](2);
        path[0] = _iUni.WETH();
        path[1] = _token;

        uint[] memory amounts = _iUni.swapExactETHForTokens{
            value: msg.value }
            (_amountOutMin, path, msg.sender, block.timestamp);
        emit EthToTokenSwap(msg.sender, amounts[0], amounts[1]);
    }
    
    function swapTokensForETH(
        address _token, 
        uint _amountIn, 
        uint _amountOutMin
        ) external {
        require(
            IERC20(_token).allowance(
                msg.sender, address(this) 
            ) >= _amountIn, 
            "must approve contract"
        );
        require(
            IERC20(_token).approve(address(_iUni), _amountIn), 
            "approve failed"
        );
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = _iUni.WETH();
        
        uint[] memory amounts = _iUni.swapExactTokensForETH(
            _amountIn, _amountOutMin, path, msg.sender, block.timestamp);
        emit TokenToEthSwap(msg.sender, amounts[0], amounts[1]);
    }
    
    function swapTokensForTokens(
        address _tokenIn, 
        address _tokenOut,
        uint _amountIn, 
        uint _amountOutMin
        ) external {
        require(
            IERC20(_tokenIn).allowance(
                msg.sender, address(this) 
            ) >= _amountIn, 
            "must approve contract"
        );
        require(
            IERC20(_tokenIn).approve(address(_iUni), _amountIn), 
            "approve failed"
        );
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        
        uint[] memory amounts = _iUni.swapExactTokensForTokens(
            _amountIn, _amountOutMin, path, msg.sender, block.timestamp);
        emit TokenToTokenSwap(
            msg.sender, _tokenIn, _tokenOut, amounts[0], amounts[1]);
    }
}