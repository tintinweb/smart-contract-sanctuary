/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity ^0.7.0;  


interface IUniswap {
    function swapExactTokensForETH( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external  returns (uint[] memory amounts); 
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable  returns (uint[] memory amounts);
    function swapExactTokensForTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts);
    function WETH() external pure returns(address);
}  

interface ISushiswap {
    function swapExactTokensForETH( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external  returns (uint[] memory amounts); 
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable  returns (uint[] memory amounts);
    function swapExactTokensForTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts);
    function WETH() external pure returns(address);
}  

 
 
interface IERC20 {
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   function approve(address spender, uint256 amount) external returns (bool);
   function transfer(address recipient, uint256 amount) external returns (bool);
   function balanceOf(address account) external view returns (uint256);
} 


contract ArbitrageBot { 
    
    IUniswap public uniswap;
    ISushiswap public sushiswap; 
    address public owner;   
     
    constructor(address _uniswap,address _sushiswap, address _owner){
        uniswap = IUniswap(_uniswap); 
        sushiswap = ISushiswap(_sushiswap);  
        owner = _owner; 
    }   
    
    modifier isOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }    
    
    fallback() external payable { }  
    receive() external payable {  }  


    // Swap ETH for tokens 
     function swapExactETHForTokensSUSHI ( uint amountOut, address[] calldata  path, uint _value ) external isOwner{   
        uint deadline = block.timestamp + 60 * 20;
        sushiswap.swapExactETHForTokens{value: _value}( amountOut, path, address(this), deadline ); 
    }  


    // Swap ETH for tokens 
     function swapExactETHForTokensUni ( uint amountOut, address[] calldata  path, uint _value ) external isOwner{   
        uint deadline = block.timestamp + 60 * 20;
        uniswap.swapExactETHForTokens{value: _value}( amountOut, path, address(this), deadline ); 
    }


    function swapExactETHForTokensUniToSushi ( uint amountOutUni, uint amountOutSushi, address tokenIn, address tokenOut, uint _value ) external isOwner {   
        uint uniDeadline = block.timestamp + 60 * 20;
        
        address[] memory pathUni = new address[](2);
        pathUni[0] = tokenIn;
        pathUni[1] = tokenOut;
        uint[] memory amountBack = uniswap.swapExactETHForTokens{value: _value}( amountOutUni, pathUni, address(this), uniDeadline ); 
        
        
        uint sushiDeadline = block.timestamp + 1200;
        address[] memory pathSushi = new address[](2);
        pathSushi[0] = tokenOut;
        pathSushi[1] = tokenIn;
        IERC20(tokenOut).approve(address(sushiswap), amountBack[1]); 
        sushiswap.swapExactTokensForETH( amountBack[1], amountOutSushi, pathSushi, address(this), sushiDeadline); 
    }
    

    function swapExactETHForTokensSushiToUni ( uint amountOutSushi, uint amountOutUni, address tokenIn, address tokenOut, uint _value ) external isOwner {   
        uint sushiDeadline = block.timestamp + 1200;
        
        address[] memory pathSushi = new address[](2);
        pathSushi[0] = tokenIn;
        pathSushi[1] = tokenOut;
        uint[] memory amountBack = sushiswap.swapExactETHForTokens{value: _value}( amountOutSushi, pathSushi, address(this), sushiDeadline ); 
        
        
        uint uniDeadline = block.timestamp + 1200;
        address[] memory pathUni = new address[](2);
        pathUni[0] = tokenOut;
        pathUni[1] = tokenIn;
        IERC20(tokenOut).approve(address(uniswap), amountBack[1]); 
        uniswap.swapExactTokensForETH( amountBack[1], amountOutUni, pathUni, address(this), uniDeadline); 
    }

















    // Transfer contract ownership
    function transferOwnership (address _owner) external isOwner{
        owner = _owner;
    }


    // Reset DEX contract address
    function resetDEXAddress  (address _uniswap,address _sushiswap ) external  isOwner {
        uniswap = IUniswap(_uniswap); 
        sushiswap = ISushiswap(_sushiswap);  
    } 
    
    
    // Returns contract's ETH balance
    function getETHBalance () external view returns (uint){
        return address(this).balance;
    }  
    
    
    // Returns contract's particular token balance
    function getTokenBalance(address _address) external view returns (uint) {
      return IERC20(_address).balanceOf(address(this));
    }  
     
     
     // Transfer ETH from contract's balance after token swap 
    function transferETH (address payable _recipient, uint _amount) external isOwner{
        require(_amount > 0 ); 
        _recipient.transfer(_amount);    
    }  
    
     // Withdraw contract's particular token balance
    function transferTokens (address _tokenAddress, address  _recipient, uint _amount) public  isOwner returns (bool){ 
        require(_amount > 0 ); 
        IERC20(_tokenAddress).transfer(_recipient, _amount);
        return true;
    }  
    
    // Withdraw contract's ETH balance
    function withdrawETHBalance(address payable  recipient) external isOwner{
        recipient.transfer(address(this).balance);
    }    
     
     
   
}