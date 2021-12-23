/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    
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


interface IBEP20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract Proxy {

  address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
  address private constant ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
  IPancakeRouter private constant ROUTER = IPancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
  
  address private _owner;
  bool private _active;

  constructor() {
    _owner = msg.sender;
    _active = true;
  }
  
  modifier ifActive() {
    require(isActive(), 'Contract not active');
    _;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, 'Caller is not the owner');
    _;
  }

  function isActive()  public view returns (bool) { return _active; }

  function setActive(bool b) external onlyOwner {
    _active = b;
  }

  /* SWAP */
  function swapBNBToTokens(address tokenOut, address receiver) external payable ifActive returns (uint256) {
    uint256 amount = msg.value;
    return _swapBNBToTokens(amount, tokenOut, receiver);
  }

  function swapBNBToTokens_Fee(address tokenOut, address receiver) external payable ifActive returns (uint256) {
    uint256 amount = msg.value;
    return _swapBNBToTokens_Fee(amount, tokenOut, receiver);
  }

  function swapTokensToBNB(address tokenIn, uint256 amount, address receiver) external ifActive returns (uint256) {
    return _swapTokensToBNB(tokenIn, amount, receiver);
  }

  function swapTokensToBNB_Fee(address tokenIn, uint256 amount, address receiver) external ifActive { 
    _swapTokensToBNB_Fee(tokenIn, amount, receiver);
  }

  function swapTokensToTokens(address tokenIn, uint256 amountIn, address tokenOut, address receiver) external ifActive returns (uint256) {
    return _swapTokensToTokens(tokenIn, amountIn, tokenOut, receiver); 
  }

  function swapTokensToTokens_Fee(address tokenIn, uint256 amountIn, address tokenOut, address receiver) external ifActive returns (uint256) {
    return _swapTokensToTokens_Fee(tokenIn, amountIn, tokenOut, receiver); 
  }


  /* SPLIT SWAP */
  function splitBNBToTokens(address tokenOut_A, address tokenOut_B, address receiver) external payable ifActive {
    uint256[] memory amountsArr = _splitAmount(msg.value);
    _swapBNBToTokens(amountsArr[0], tokenOut_A, receiver);
    _swapBNBToTokens(amountsArr[1], tokenOut_B, receiver);
  }

  function splitBNBToTokens_Fee(address tokenOut_A, address tokenOut_B, address receiver) external payable ifActive {
    uint256[] memory amountsArr = _splitAmount(msg.value);
    _swapBNBToTokens_Fee(amountsArr[0], tokenOut_A, receiver);
    _swapBNBToTokens_Fee(amountsArr[1], tokenOut_B, receiver);
  }

  function splitTokensToTokens(address tokenIn, uint256 amountIn, address tokenOut_A, address tokenOut_B, address receiver) external ifActive {
    uint256[] memory amountsArr = _splitAmount(amountIn);
    _swapTokensToTokens(tokenIn, amountsArr[0], tokenOut_A, receiver);
    _swapTokensToTokens(tokenIn, amountsArr[1], tokenOut_B, receiver); 
  }

  function splitTokensToTokens_Fee(address tokenIn, uint256 amountIn, address tokenOut_A, address tokenOut_B, address receiver) external ifActive {
    uint256[] memory amountsArr = _splitAmount(amountIn);
    _swapTokensToTokens_Fee(tokenIn, amountsArr[0], tokenOut_A, receiver);
    _swapTokensToTokens_Fee(tokenIn, amountsArr[1], tokenOut_B, receiver); 
  }

  function _splitAmount(uint256 amount) private pure returns (uint256[] memory){
    uint256[] memory arr = new uint256[](2);
    arr[0] = amount / 2;
    arr[1] = amount - arr[0];
    return arr;
  }


  /* private SWAP */
  function _swapBNBToTokens(uint256 amountIn, address tokenOut, address receiver) private returns (uint256) {
    address[] memory path = _tokensPath(WBNB, tokenOut);
    uint[] memory amounts = ROUTER.swapExactETHForTokens{value : amountIn}(0, path, receiver, block.timestamp);
    return amounts[amounts.length - 1];     
  }

  function _swapBNBToTokens_Fee(uint256 amountIn, address tokenOut, address receiver) private returns (uint256) {
    uint256 oldTokenOutBalance = IBEP20(tokenOut).balanceOf(receiver);
    address[] memory path = _tokensPath(WBNB, tokenOut);
    ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value : amountIn}(0, path, receiver, block.timestamp);
    uint256 newTokenOutBalance = IBEP20(tokenOut).balanceOf(receiver);
    return newTokenOutBalance - oldTokenOutBalance;
  }

  function _swapTokensToTokens(address tokenIn, uint256 amountIn, address tokenOut, address receiver) private returns (uint256) {
    IBEP20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
    if(IBEP20(tokenIn).allowance(msg.sender, address(this)) < amountIn ){
      IBEP20(tokenIn).approve(ROUTER_ADDRESS, type(uint256).max);
    }

    address[] memory path = _tokensPath(tokenIn, tokenOut);
    uint[] memory amounts = ROUTER.swapExactTokensForTokens(amountIn, 0, path, receiver, block.timestamp);
    return amounts[amounts.length - 1];
  }

  function _swapTokensToTokens_Fee(address tokenIn, uint256 amountIn, address tokenOut, address receiver) private returns (uint256) {
    IBEP20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
    if(IBEP20(tokenIn).allowance(msg.sender, address(this)) < amountIn ){
      IBEP20(tokenIn).approve(ROUTER_ADDRESS, type(uint256).max);
    }
    
    uint256 oldTokenOutBalance = IBEP20(tokenOut).balanceOf(receiver);
    address[] memory path = _tokensPath(tokenIn, tokenOut);
    ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, 0, path, receiver, block.timestamp);
    uint256 newTokenOutBalance = IBEP20(tokenOut).balanceOf(receiver);
    return newTokenOutBalance - oldTokenOutBalance;
  }

  function _swapTokensToBNB(address tokenIn, uint256 amount, address receiver) private returns (uint256) {
    IBEP20(tokenIn).transferFrom(msg.sender, address(this), amount);
    if(IBEP20(tokenIn).allowance(msg.sender, address(this)) < amount ){
      IBEP20(tokenIn).approve(ROUTER_ADDRESS, type(uint256).max);
    }

    address[] memory path;
    if (tokenIn == WBNB) {
      path = new address[](1);
      path[0] = WBNB;
    } else {
      path = new address[](2);
      path[0] = tokenIn;
      path[1] = WBNB;
    }
    uint[] memory amounts = ROUTER.swapExactTokensForETH(amount, 0, path, receiver, block.timestamp);
    return amounts[amounts.length - 1];
  }

  function _swapTokensToBNB_Fee(address tokenIn, uint256 amount, address receiver) private {
    IBEP20(tokenIn).transferFrom(msg.sender, address(this), amount);
    if(IBEP20(tokenIn).allowance(msg.sender, address(this)) < amount ){
      IBEP20(tokenIn).approve(ROUTER_ADDRESS, type(uint256).max);
    }

    address[] memory path;
    if (tokenIn == WBNB) {
      path = new address[](1);
      path[0] = WBNB;
    } else {
      path = new address[](2);
      path[0] = tokenIn;
      path[1] = WBNB;
    }
    ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, receiver, block.timestamp);
  }

  function _tokensPath(address tokenIn, address tokenOut) private pure returns (address[] memory) {
    address[] memory path;
    if (tokenIn == WBNB || tokenOut == WBNB) {
      path = new address[](2);
      path[0] = tokenIn;
      path[1] = tokenOut;
    } else {
      path = new address[](3);
      path[0] = tokenIn;
      path[1] = WBNB;
      path[2] = tokenOut;
    }
    return path;
  }

  receive() external payable {}

  /* ========== TO OWNER ========== */

  function transferBNB(uint256 amount) external onlyOwner {
    transferTo(_owner, amount);
  }

  function transferAllBNB() external onlyOwner {
    transferAllTo(_owner);
  }

  function transferTokens(address token, uint256 amount) external onlyOwner {
    transferTokensTo(_owner, token, amount);
  }

  function transferAllTokens(address token) external onlyOwner {
    transferAllTokensTo(_owner, token);
  }

  /* ========== TO ANY ADDRESS ========== */

  function transferTo(address recipient, uint256 amount) public onlyOwner {
    require(recipient != address(0), 'Recipient cannot be the zero address');
    require(amount != 0, 'Amount cannot be zero');
    payable(recipient).transfer(amount);
  }

  function transferAllTo(address recipient) public onlyOwner {
    require(recipient != address(0), 'Recipient cannot be the zero address');
    payable(recipient).transfer(address(this).balance);
  }

  function transferTokensTo(address recipient, address token, uint256 amount) public onlyOwner {
    require(recipient != address(0), 'Recipient cannot be the zero address');
    require(amount != 0, 'Amount cannot be zero');
    IBEP20(token).transfer(recipient, amount);
  }

  function transferAllTokensTo(address recipient, address token) public onlyOwner {
    require(recipient != address(0), 'Recipient cannot be the zero address');
    uint256 amount = IBEP20(token).balanceOf(address(this));
    IBEP20(token).transfer(recipient, amount);
  }

  function approveTokens(address token, address spender) public onlyOwner {
    IBEP20(token).approve(spender, type(uint256).max);
  }

  function approveTokensToRouter(address token) public onlyOwner {
    IBEP20(token).approve(ROUTER_ADDRESS, type(uint256).max);
  }
}