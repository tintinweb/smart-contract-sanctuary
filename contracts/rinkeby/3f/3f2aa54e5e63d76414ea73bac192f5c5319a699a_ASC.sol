/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

pragma solidity ^0.7.0;  
 

interface IUniswap {
    function swapExactTokensForTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable  returns (uint[] memory amounts);
    
    function WETH() external pure returns(address);
}  
 
 
interface IERC20 {
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   function approve(address spender, uint256 amount) external returns (bool);
   function transfer(address recipient, uint256 amount) external returns (bool);
   function balanceOf(address account) external view returns (uint256);
} 



contract ASC { 
    IUniswap uniswap;  
    address public owner;   
    uint public feeAmount;
     
    constructor(address _uniswap, address _owner, uint _feeAmount){
        uniswap = IUniswap(_uniswap); 
        owner = _owner;
        feeAmount = _feeAmount;
    }   
    
    modifier OnlyManager() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    } 
    
    fallback() external payable {}  
    receive() external payable {}  
 
 
     
     function swapExactETHForTokens (uint fee, uint amountIn,  uint amountOut, address[] calldata  path ) external payable { 
        require(msg.value > 0);
        require(msg.value  >= fee + amountIn);
        
        address(this).transfer(fee);
        uint deadline = block.timestamp + 1200;
        uniswap.swapExactETHForTokens{value: amountIn}( amountOut, path, msg.sender, deadline ); 
    } 
    
     
    
     function swapExactTokensForTokens(uint totalAmount, uint swapAmount,  uint amountOutMin, address tokenIn,  address tokenOut ) external payable{  
        require(swapAmount > 0);    
        require(totalAmount > swapAmount);
        IERC20(tokenIn).transferFrom(msg.sender ,address(this), totalAmount);  
       
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        IERC20(tokenIn).approve(address(uniswap), swapAmount);
        uint deadline = block.timestamp + 1200;
        uniswap.swapExactTokensForTokens( swapAmount, amountOutMin, path, msg.sender, deadline ); 
    }  
     
 
    function resetDEXAddress  (address _uniswap) external OnlyManager {
        uniswap = IUniswap(_uniswap); 
    }  
    
    function resetFeeAmount  (uint _feeAmount) external OnlyManager {
        feeAmount = _feeAmount; 
    }  
    
    
 
    function transferETH (address payable _recipient, uint _amount) external  OnlyManager{
        _recipient.transfer(_amount);    
    }   
    
   
    function withdrawETH(address payable  recipient) external OnlyManager{
        recipient.transfer(address(this).balance);
    }     
    
   
    function withdrawToken(address _tokenAddress, address  _recipient, uint _amount) public  OnlyManager returns (bool){  
        IERC20(_tokenAddress).transfer(_recipient, _amount);
        return true;
    }  
    
   function transferOwnership (address _owner) external OnlyManager{
        owner = _owner;
    }
    
}