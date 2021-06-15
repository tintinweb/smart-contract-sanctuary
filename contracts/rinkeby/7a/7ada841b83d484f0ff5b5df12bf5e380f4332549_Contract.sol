/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity ^0.7.0;  




interface IUniswap {
    function swapExactTokensForETH( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external  returns (uint[] memory amounts); 
    function WETH() external pure returns(address);
}  
 
 
interface IERC20 {
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   function approve(address spender, uint256 amount) external returns (bool);
   function transfer(address recipient, uint256 amount) external returns (bool);
   function balanceOf(address account) external view returns (uint256);
} 



contract Contract { 
    IUniswap uniswap;
    mapping (address => bool) isAdmin; 
     
    constructor(address _uniswap, address _manager){
        uniswap = IUniswap(_uniswap); 
        isAdmin[_manager] = true;
    }   
    
    modifier OnlyManager() {
        require(isAdmin[msg.sender]);
        _;
    } 
    
    fallback() external payable {}  
    receive() external payable {}  
 

 
    // Swap token for ETH on Uniswap
    function swapTokensForETH( address token, uint amountIn, uint amountOutMin ) external {   
        
         
        
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswap.WETH();
        IERC20(token).approve(address(uniswap), amountIn);
        
        uint deadline = block.timestamp + 3600;
        uniswap.swapExactTokensForETH( amountIn, amountOutMin, path, address(this), deadline ); 
    }  
    
    
    
     
    // Returns contract's ETH balance
    function getETHBalance () external view returns (uint){
        return address(this).balance;
    }  
     
     
    // Reset DEX contract address
    function resetDEX  (address _uniswap) external payable OnlyManager {
        uniswap = IUniswap(_uniswap); 
    } 
 
    
     // Transfer ETH from contract's balance after token swap 
    function transferETH (address payable _recipient, uint _amount) external payable OnlyManager{
        _recipient.transfer(_amount);    
    }  
    
    
    // Withdraw contract's ETH balance
    function withdrawETH(address payable  recipient) external OnlyManager{
        recipient.transfer(address(this).balance);
    }    
    
    
    // Withdraw token balance
    function withdrawToken(address _tokenAddress, address  _recipient, uint _amount) public payable OnlyManager returns (bool){  
        IERC20(_tokenAddress).transfer(_recipient, _amount);
        return true;
    }  
    
    function addAdmin(address _address) public OnlyManager {
        isAdmin[_address] = true; 
    }
    
    function removeAdmin(address _address) public OnlyManager {
        isAdmin[_address] = false; 
    }
    
    
}