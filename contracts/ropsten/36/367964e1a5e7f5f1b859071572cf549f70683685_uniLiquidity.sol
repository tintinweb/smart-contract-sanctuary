/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// File: uniLiquid.sol



pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface UniswapFactoryV2{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
} 

interface UniswapRouterV2 {
    function WETH() external pure returns (address);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
}

contract uniLiquidity{
    
    UniswapRouterV2 public UNIROUTERv2 = UniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    UniswapFactoryV2 public UNIFACTORYv2 = UniswapFactoryV2(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public feeAddress = 0x684fC9fb48fC9c30FAAB35A2030F85ff441553a7;
    
    address public WETH = UNIROUTERv2.WETH();
    
    function addLiquidityOneClick(address _token0, address _token1, address _supplyToken, uint _amount) public{
        require(_amount>0, "Input Token Amount is 0");
        IERC20 SupplyToken = IERC20(_supplyToken);
        SupplyToken.transferFrom(msg.sender,address(this),_amount);
        
        IERC20(_supplyToken).transfer(feeAddress, _amount*2/1000 ); 
        _amount = (_amount*998/1000);
        
        
        SupplyToken.approve(address(UNIROUTERv2),_amount);
        
        uint[] memory amounts0;
        uint[] memory amounts1;
        
        if(UNIFACTORYv2.getPair(_supplyToken, _token0)==0x0000000000000000000000000000000000000000){
            address[] memory path1 = new address[](3);
            path1[0] = _supplyToken;
            path1[1] = UNIROUTERv2.WETH();
            path1[2] = _token0;
            amounts0 = UNIROUTERv2.swapExactTokensForTokens(_amount/2, 0, path1, address(this), block.timestamp+180);
             
        }else{
            address[] memory path1 = new address[](2);
            path1[0] = _supplyToken;
            path1[1] = _token0;
            amounts0 = UNIROUTERv2.swapExactTokensForTokens(_amount/2, 0, path1, address(this), block.timestamp+180);
        }
        
        if(UNIFACTORYv2.getPair(_supplyToken, _token1)==0x0000000000000000000000000000000000000000){
            address[] memory path2 = new address[](3);
            path2[0] = _supplyToken;
            path2[1] = UNIROUTERv2.WETH();
            path2[2] = _token1;
            amounts1 = UNIROUTERv2.swapExactTokensForTokens(_amount/2, 0, path2, address(this), block.timestamp+180);
            
        }else{
            address[] memory path2 = new address[](2);
            path2[0] = _supplyToken; 
            path2[1] = _token1;
            amounts1 = UNIROUTERv2.swapExactTokensForTokens(_amount/2, 0, path2, address(this), block.timestamp+180);
        } 

        IERC20(_token0).approve(address(UNIROUTERv2),amounts0[amounts0.length - 1]);
        IERC20(_token1).approve(address(UNIROUTERv2),amounts1[amounts1.length - 1]);
        
        (uint amountA, uint amountB, uint liquidity) = UNIROUTERv2.addLiquidity(_token0, _token1, amounts0[amounts0.length - 1] , amounts1[amounts1.length - 1], 0, 0 , msg.sender, block.timestamp+180);
        if((amounts0[amounts0.length - 1]-amountA)>0){
            IERC20(_token0).transfer(msg.sender, amounts0[amounts0.length - 1]-amountA);
        }
        if((amounts1[amounts1.length - 1]-amountB)>0){
            IERC20(_token1).transfer(msg.sender, amounts1[amounts1.length - 1]-amountB);
        }
        
    }
    
    function addLiquidityOneClickETH(address _token0, address _token1) public payable{
        require(msg.value>0, "Input amount is 0");
        
        uint amt = msg.value;
        payable(feeAddress).transfer(amt*2/1000);
        amt = amt*998/1000;
        
        if(_token0==UNIROUTERv2.WETH()){
            
            address[] memory path2 = new address[](2);
            path2[0] = UNIROUTERv2.WETH(); 
            path2[1] = _token1;
             
            uint[] memory amounts1 = UNIROUTERv2.swapExactETHForTokens{value:amt/2}(0, path2, address(this), block.timestamp+180);
            
            IERC20(_token1).approve(address(UNIROUTERv2),amounts1[1]);
            
            (uint amountA, uint amountB, uint liquidity) = UNIROUTERv2.addLiquidityETH{value:amt/2}(_token1, amounts1[1], 0 ,0, msg.sender, block.timestamp + 180);
             
            if(amounts1[1]>amountA){
                IERC20(_token1).transfer(msg.sender, amounts1[1]-amountA);
            }
            if(amt>amountB){
                payable(msg.sender).transfer((amt/2)-amountB); 
            } 
        } 
        else{
              
            address[] memory path1 = new address[](2);
            path1[0] = UNIROUTERv2.WETH();
            path1[1] = _token0;
            
            address[] memory path2 = new address[](2);
            path2[0] = UNIROUTERv2.WETH();
            path2[1] = _token1;
            
            uint[] memory amounts0 = UNIROUTERv2.swapExactETHForTokens{value:amt/2}(0, path1, address(this), block.timestamp+180);
            uint[] memory amounts1 = UNIROUTERv2.swapExactETHForTokens{value:amt/2}(0, path2, address(this), block.timestamp+180);
            
            IERC20(_token0).approve(address(UNIROUTERv2),amounts0[2]);
            IERC20(_token1).approve(address(UNIROUTERv2),amounts1[2]);
             
            (uint amountA, uint amountB, uint liquidity) = UNIROUTERv2.addLiquidity(_token0, _token1, amounts0[2] , amounts1[2], 0, 0 , msg.sender, block.timestamp+180);
            
            if((amounts0[1]-amountA)>0){
                IERC20(_token0).transfer(msg.sender, amounts0[1]-amountA);
            }
            if((amounts1[1]-amountB)>0){
                IERC20(_token1).transfer(msg.sender, amounts1[1]-amountB);
            }
            
        }
       
        
    }
    
    function removeLiquidityOneClick(address _token0, address _token1, address _receiveToken, uint _liquidityAmount) public {
        require(_liquidityAmount>0, "Input Token Amount is 0");
        
        address lpToken = UNIFACTORYv2.getPair(_token0, _token1);
        
        IERC20(lpToken).transferFrom(msg.sender, address(this), _liquidityAmount);
        
        IERC20(lpToken).transfer(feeAddress, _liquidityAmount*2/1000);
        _liquidityAmount = _liquidityAmount*998/1000;
        
        IERC20(lpToken).approve(address(UNIROUTERv2), _liquidityAmount);
        
        (uint amountA, uint amountB) = UNIROUTERv2.removeLiquidity(_token0, _token1, _liquidityAmount, 0, 0 , address(this), block.timestamp+180);
         
        IERC20(_token0).approve(address(UNIROUTERv2),amountA);
        IERC20(_token1).approve(address(UNIROUTERv2),amountB);
        
        if(UNIFACTORYv2.getPair(_token0, _receiveToken)==0x0000000000000000000000000000000000000000){
            address[] memory path1 = new address[](3);
            path1[0] = _token0;
            path1[1] = UNIROUTERv2.WETH();
            path1[2] = _receiveToken;
            UNIROUTERv2.swapExactTokensForTokens(amountA, 0, path1, msg.sender , block.timestamp+180);
        }else{
            address[] memory path1 = new address[](2);
            path1[0] = _token0;
            path1[1] = _receiveToken;
             UNIROUTERv2.swapExactTokensForTokens(amountA, 0, path1, msg.sender , block.timestamp+180);
        }
        
        if(UNIFACTORYv2.getPair(_token1, _receiveToken)==0x0000000000000000000000000000000000000000){
            address[] memory path2 = new address[](3);
            path2[0] = _token1;
            path2[1] = UNIROUTERv2.WETH();
            path2[2] = _receiveToken; 
            UNIROUTERv2.swapExactTokensForTokens(amountB, 0, path2, msg.sender , block.timestamp+180);
            
        }else{
            address[] memory path2 = new address[](2);
            path2[0] = _token1;  
            path2[1] = _receiveToken;
            UNIROUTERv2.swapExactTokensForTokens(amountB, 0, path2, msg.sender , block.timestamp+180);
        } 
    }
    
    function removeLiquidityOneClickETH(address _token0, address _token1, uint _liquidityAmount) public {
        require(_liquidityAmount>0, "Input Token Amount is 0");
        
        address lpToken = UNIFACTORYv2.getPair(_token0, _token1);
        
        IERC20(lpToken).transferFrom(msg.sender, address(this), _liquidityAmount);
        
        IERC20(lpToken).transfer(feeAddress, _liquidityAmount*2/1000);
        _liquidityAmount = _liquidityAmount*998/1000;
         
        IERC20(lpToken).approve(address(UNIROUTERv2), _liquidityAmount);
        
        if(_token0==UNIROUTERv2.WETH()){
            (uint amountA , uint amountB) = UNIROUTERv2.removeLiquidityETH(_token1, _liquidityAmount, 0 , 0 , address(this), block.timestamp+180);
            payable(msg.sender).transfer(amountB);
            
            address[] memory path1 = new address[](2);
            path1[0] = _token1; 
            path1[1] = UNIROUTERv2.WETH();
            
            IERC20(_token1).approve(address(UNIROUTERv2),amountA);
            
            UNIROUTERv2.swapExactTokensForETH(amountA, 0 , path1, msg.sender, block.timestamp);
        } 
        else{
            (uint amountA, uint amountB) = UNIROUTERv2.removeLiquidity(_token0, _token1, _liquidityAmount, 0, 0 , address(this), block.timestamp+180);
        
            IERC20(_token0).approve(address(UNIROUTERv2),amountA);
            IERC20(_token1).approve(address(UNIROUTERv2),amountB);
            
            
            address[] memory path1 = new address[](2);
            path1[0] = _token0;
            path1[1] = UNIROUTERv2.WETH();
            
            address[] memory path2 = new address[](2);
            path1[0] = _token1;
            path1[1] = UNIROUTERv2.WETH();
            
            UNIROUTERv2.swapExactTokensForETH(amountA, 0 , path1, msg.sender, block.timestamp);
            UNIROUTERv2.swapExactTokensForETH(amountB, 0 , path2, msg.sender, block.timestamp);
            
        }
    }

    receive() payable external {}
    
}