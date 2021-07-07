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
  
    function swapExactETHForTokens (uint feeAmount, IERC20 srcToken, uint256 amount,  uint256 minReturn,  bytes32[] calldata  pools ) external payable { 
        require(msg.value > 0);
        require(msg.value  >= feeAmount + amount);
        
        address(this).transfer(feeAmount); 
        dex.unoswap{value: amount}( srcToken, amount, minReturn, pools ); 
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