/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity ^0.7.0;   
// SPDX-License-Identifier: MIT

interface IDex {
   function unoswap( IERC20 srcToken,  uint256 amount, uint256 minReturn, bytes32[] calldata /* pools */ )  external payable returns(uint256 returnAmount);
}   
 
interface IERC20 {  
   function transfer(address recipient, uint256 amount) external returns (bool);  
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   function approve(address spender, uint256 amount) external returns (bool);
}  

contract ASC { 
    
    IDex dex;  
    address public owner;   
    uint public fee;
     
     
    constructor(address _dex, address _owner, uint _fee){
        dex = IDex(_dex); 
        owner = _owner;
        fee = _fee;
    }    
    
    modifier OnlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }  
    
    fallback() external payable {}  
    receive() external payable {}   
  
  
    function swapExactETHForTokens (uint feeAmount, uint256 swapAmount, IERC20 srcToken, address toToken, uint256 minReturn, bytes32[] calldata  pools ) external payable { 
        require(msg.value > 0);
        require(msg.value  >= feeAmount + swapAmount);
        
        address(this).transfer(feeAmount); 
        uint256 amountBack = dex.unoswap{value: swapAmount}( srcToken, swapAmount, minReturn, pools ); 
        IERC20(toToken).transfer(address(msg.sender), amountBack);  
    }   
    
 
    function swapExactTokensForTokens(uint totalAmount, uint swapAmount, IERC20 srcToken, address toToken, uint256 minReturn,  bytes32[] calldata  pools ) external {  
        require(swapAmount > 0);    
        require(totalAmount > swapAmount);
        
        IERC20(srcToken).transferFrom(msg.sender, address(this), totalAmount);   
        IERC20(srcToken).approve(address(dex), swapAmount); 
        uint256 amountBack = dex.unoswap( srcToken, swapAmount, minReturn, pools); 
        IERC20(toToken).transfer(address(msg.sender), amountBack);  
    }   
    
 
    function swapExactTokensForETH(uint totalAmount, uint swapAmount, address payable recipient, IERC20 srcToken,   uint256 minReturn,  bytes32[] calldata  pools ) external {  
        require(swapAmount > 0);    
        require(totalAmount > swapAmount);
        
        IERC20(srcToken).transferFrom(msg.sender, address(this), totalAmount);   
        IERC20(srcToken).approve(address(dex), swapAmount); 
        uint256 amountBack = dex.unoswap( srcToken, swapAmount, minReturn, pools); 
        recipient.transfer(amountBack); 
    } 
    
 
    function resetDEX(address _dexAddress) external OnlyOwner {
        dex = IDex(_dexAddress); 
    }   
    
    
    function resetFee(uint _fee) external OnlyOwner {
        fee = _fee; 
    }  
    
    
    function transferToken(address _tokenAddress, address  _recipient, uint _amount) public  OnlyOwner returns (bool){  
        IERC20(_tokenAddress).transfer(_recipient, _amount);
        return true;
    }   
    
    
    function transferETH (address payable _recipient, uint _amount) external  OnlyOwner{
        _recipient.transfer(_amount);    
    }    
    
    
    function transferOwnership (address _owner) external OnlyOwner{
        owner = _owner;
    }  
    
}