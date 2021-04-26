/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

pragma solidity ^0.7.0;  


interface DexInterface {
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
    
    DexInterface public uniswap;
    DexInterface public sushiswap; 
    DexInterface public tacoswap; 
    address public owner;   
     
    constructor(address _uniswap,address _sushiswap, address _tacoswap, address _owner){
        uniswap = DexInterface(_uniswap); 
        sushiswap = DexInterface(_sushiswap);  
        tacoswap = DexInterface(_tacoswap);  
        owner = _owner; 
    }   
    
    modifier isOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }    
    
    fallback() external payable { }  
    receive() external payable {  }  




    // Swap ETH for tokens on uniswap
    function swapExactTokensForETHUni( address token, uint amountIn, uint amountOutMin )external isOwner{  
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = sushiswap.WETH();
        IERC20(token).approve(address(uniswap), amountIn);
        uint deadline = block.timestamp + 1200;
        uniswap.swapExactTokensForETH( amountIn, amountOutMin, path, address(this), deadline ); 
    }  
    
    
    // Swap ETH for tokens on sushiswap
    function swapExactTokensForETHSUSHI( address token, uint amountIn, uint amountOutMin )external isOwner{  
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = sushiswap.WETH();
        IERC20(token).approve(address(sushiswap), amountIn);
        uint deadline = block.timestamp + 1200;
        sushiswap.swapExactTokensForETH( amountIn, amountOutMin, path, address(this), deadline ); 
    }  
   


    // Swap ETH for tokens on tacoswap
    function swapExactTokensForETHTaco( address token, uint amountIn, uint amountOutMin )external isOwner{  
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = sushiswap.WETH();
        IERC20(token).approve(address(tacoswap), amountIn);
        uint deadline = block.timestamp + 1200;
        tacoswap.swapExactTokensForETH( amountIn, amountOutMin, path, address(this), deadline ); 
    }  
   


    function swapExactETHForTokensUniToSushi ( uint amountOutUni, uint amountOutSushi, address tokenIn, address tokenOut, uint _value ) external isOwner {   
        uint uniDeadline = block.timestamp + 1200;
        
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



    function swapExactETHForTokensUniToTaco ( uint amountOutUni, uint amountOutTaco, address tokenIn, address tokenOut, uint _value ) external isOwner {   
        uint uniDeadline = block.timestamp + 1200;
        
        address[] memory pathUni = new address[](2);
        pathUni[0] = tokenIn;
        pathUni[1] = tokenOut;
        uint[] memory amountBack = uniswap.swapExactETHForTokens{value: _value}( amountOutUni, pathUni, address(this), uniDeadline ); 
        
        
        uint tacoDeadline = block.timestamp + 1200;
        address[] memory pathTaco = new address[](2);
        pathTaco[0] = tokenOut;
        pathTaco[1] = tokenIn;
        IERC20(tokenOut).approve(address(tacoswap), amountBack[1]); 
        tacoswap.swapExactTokensForETH( amountBack[1], amountOutTaco, pathTaco, address(this), tacoDeadline); 
    }




    function swapExactETHForTokensTacoToUni ( uint amountOutTaco, uint amountOutUni, address tokenIn, address tokenOut, uint _value ) external isOwner {   
        uint tacoDeadline = block.timestamp + 1200;
        
        address[] memory pathTaco = new address[](2);
        pathTaco[0] = tokenIn;
        pathTaco[1] = tokenOut;
        uint[] memory amountBack = tacoswap.swapExactETHForTokens{value: _value}( amountOutTaco, pathTaco, address(this), tacoDeadline ); 
        
        
        uint uniDeadline = block.timestamp + 1200;
        address[] memory pathUni = new address[](2);
        pathUni[0] = tokenOut;
        pathUni[1] = tokenIn;
        IERC20(tokenOut).approve(address(uniswap), amountBack[1]); 
        uniswap.swapExactTokensForETH( amountBack[1], amountOutUni, pathUni, address(this), uniDeadline); 
    }





    function swapExactETHForTokensSushiToTaco ( uint amountOutSushi, uint amountOutTaco, address tokenIn, address tokenOut, uint _value ) external isOwner {   
        uint sushiDeadline = block.timestamp + 1200;
        
        address[] memory pathSushi = new address[](2);
        pathSushi[0] = tokenIn;
        pathSushi[1] = tokenOut;
        uint[] memory amountBack = sushiswap.swapExactETHForTokens{value: _value}( amountOutSushi, pathSushi, address(this), sushiDeadline ); 
        
        
        uint tacoDeadline = block.timestamp + 1200;
        address[] memory pathTaco = new address[](2);
        pathTaco[0] = tokenOut;
        pathTaco[1] = tokenIn;
        IERC20(tokenOut).approve(address(tacoswap), amountBack[1]); 
        tacoswap.swapExactTokensForETH( amountBack[1], amountOutTaco, pathTaco, address(this), tacoDeadline); 
    }


    function swapExactETHForTokensTacoToSushi ( uint amountOutTaco, uint amountOutSushi, address tokenIn, address tokenOut, uint _value ) external isOwner {   
        uint tacoDeadline = block.timestamp + 1200;
        
        address[] memory pathTaco = new address[](2);
        pathTaco[0] = tokenIn;
        pathTaco[1] = tokenOut;
        uint[] memory amountBack = tacoswap.swapExactETHForTokens{value: _value}( amountOutTaco, pathTaco, address(this), tacoDeadline ); 
        
        
        uint sushiDeadline = block.timestamp + 1200;
        address[] memory pathSushi = new address[](2);
        pathSushi[0] = tokenOut;
        pathSushi[1] = tokenIn;
        IERC20(tokenOut).approve(address(sushiswap), amountBack[1]); 
        sushiswap.swapExactTokensForETH( amountBack[1], amountOutSushi, pathSushi, address(this), sushiDeadline); 
    }


    // Transfer contract ownership
    function transferOwnership (address _owner) external isOwner{
        owner = _owner;
    }


    // Reset DEX contract address
    function resetDEXAddress  (address _uniswap, address _sushiswap, address _tacoswap ) external  isOwner {
        uniswap = DexInterface(_uniswap); 
        sushiswap = DexInterface(_sushiswap);  
        tacoswap = DexInterface(_tacoswap);  
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