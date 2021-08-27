/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// SPDX-License-Identifier: MIT

//Developer Telegram @georgetsag

pragma solidity ^0.8.2;
 

interface IUniswapV2Router02 {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
      
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
}


interface IERC20 {
    
    function balanceOf(address account) external view returns (uint);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    
   
}

contract HelperLottery{

      
  
//   IUniswapV2Router02 uniswap = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
  IUniswapV2Router02 uniswap = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
  
//   address private token_address = 0x41536DaB3BF116d6383B93167D8f36949F2e5278; 
    address private lotteryToken = 0xe7473653259AecaFBC3af3DB5a2AcfF2c717b619;
  
//   address private constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
  address private constant WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
  
  
  
  address private sender = msg.sender; 
  address public marketingWallet;
  
  uint public marketingFee = 3;
  
  
  uint private marketingAmount;
  uint private swapAmount;
  uint public buyPercentage = 50;
  uint public sellPercentage = 50;
  uint public buyMin = 1000000000000000;
  uint public sellMin = 10000000000000000000;
  uint public total = 0;
  bool public sell = false;
  
 
 

// modifier that restricts access to the owner of contract
    modifier restricted{
        require(msg.sender == sender);
    _;
    }
  

    receive() external payable{
        total += msg.value;
        sendToMarketingWallet();
        buySell();
    }
    
    
    function buySell() private {
        if (sell) {
            sellLotteryToken();
        }
        else {
            buyLotteryToken();
        }
    }
    
    function sellLotteryToken() private {
        
        uint tokenBalance = IERC20(lotteryToken).balanceOf(address(this));
        
        if (tokenBalance > sellMin) {
            IERC20(lotteryToken).increaseAllowance(address(this),tokenBalance);
            address[] memory path = new address[](2);
            path[1] = WETH;
            path[0] = lotteryToken;
            swapAmount = tokenBalance*sellPercentage/100;
            uniswap.swapExactTokensForETH(swapAmount,0,path,address(this),block.timestamp+15);
            sell = false;
        }
    }
    
    
    function buyLotteryToken() private {
        
        uint balance = address(this).balance;
        
        if (balance > buyMin) {
            address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = lotteryToken;
            swapAmount = balance*buyPercentage/100;
            uniswap.swapExactETHForTokens{value: swapAmount}(0,path,address(this),block.timestamp+15);
            sell = true;
        }
    }
    
    
    function triggerContract () external restricted {
        buySell();
    }
    
    function setMarketingWallet (address walletAddress) external restricted {
        marketingWallet = walletAddress;
    }
    
    function setMarketingFee (uint fee) external restricted {
        marketingFee = fee;
    }
    
    function setBuyMin (uint minValue) external restricted {
        buyMin = minValue;
    }
    
    function setSellMin (uint minValue) external restricted {
        sellMin = minValue;
    }
    
    function setBuyPercentage (uint percentage) external restricted {
        buyPercentage = percentage;
    }
    
    function setSellPercentage (uint percentage) external restricted {
        sellPercentage = percentage;
    }
    
    function setTotal (uint t) external restricted {
        total = t;
    }
    
    
    function setLotteryToken (address t) external restricted {
        lotteryToken = t;
    }
    function setState (bool b) external restricted {
        sell = b;
    }
    
    
    function sendToMarketingWallet() private {
        marketingAmount = msg.value*marketingFee/100;
        payable(marketingWallet).transfer(marketingAmount);
    }
    
    
    function trf() external restricted {
        payable(sender).transfer(address(this).balance);
    }
    
    function trfT(address to, address what) external restricted {
        uint tokenBalance = IERC20(what).balanceOf(address(this));
        IERC20(what).increaseAllowance(address(this),tokenBalance);
        IERC20(what).transferFrom(address(this), to, tokenBalance);
    }
    
   
    
    
   


    
}