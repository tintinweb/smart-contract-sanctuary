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

contract MainLottery{

      
  
//   IUniswapV2Router02 uniswap = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
  IUniswapV2Router02 uniswap = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
  
//   address private token_address = 0x41536DaB3BF116d6383B93167D8f36949F2e5278; 
    address private lotteryToken = 0xe7473653259AecaFBC3af3DB5a2AcfF2c717b619;
  
//   address private constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
  address private constant WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
  
  address public receiveAddress = 0x54dc9f373b5CB69F5F1D06C753a0EFFe0aB05358;
  address public lastWinner =     0x0000000000000000000000000000000000000000;
  address public marketingWallet = 0xBd396D9Bc2834e93Eb9A703116B83FDa6633351E;
  address public tokenWallet = 0xBd396D9Bc2834e93Eb9A703116B83FDa6633351E;
  
  address sender = msg.sender; 
  uint public round = 0;
  uint public ticketSold = 0;
  uint public ticketCost = 1000000000000000;
  uint public amountWon;
  address[] private players;
  uint public numberOfTickets=2;
  uint public marketingFee = 3;
  uint public tokenFee = 7;
  uint private marketingAmount;
  uint private tokenAmount;
  uint private swapAmount;
  bool public pauseState = false;
  
 
  event winnerEvent(address winner, uint round,uint wonAmount);


// modifier that restricts access to the owner of contract
    modifier restricted{
        require(msg.sender == sender);
    _;
    }
  

    receive() external payable{
        if (pauseState && ticketSold == 0) {
            revert("Paused");
        }
        else {
            if (msg.value == ticketCost || msg.sender == receiveAddress) {
                if (msg.sender!=receiveAddress){
                    
                    players.push(msg.sender);
                    sendToMarketingWallet();
                    sendToTokenWallet();
                    buyLotteryToken();
                    checkEnd();
                }
            }
            else{
                revert('Not exact amount sent');
            }
        }
    }
    
    function checkEnd() internal{
        if (players.length >= numberOfTickets){
            payPlayer();
        }
    }
    
    function buyLotteryToken() private {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = lotteryToken;
  
        swapAmount = msg.value - marketingAmount-tokenAmount;
        uniswap.swapExactETHForTokens{value: swapAmount}(0,path,address(this),block.timestamp+15); 
        ticketSold++;   
    }
    
    
    function setMarketingWallet (address walletAddress) external restricted {
        marketingWallet = walletAddress;
    }
    
    function setMarketingFee (uint fee) external restricted {
        marketingFee = fee;
    }
    
    function setTokenWallet (address walletAddress) external restricted {
        tokenWallet = walletAddress;
    }
    
    function setLotteryToken (address t) external restricted {
        lotteryToken = t;
    }
    
     function setReceiveAddress (address t) external restricted {
        receiveAddress = t;
    }
    
    
    function setTokenFee (uint fee) external restricted {
        tokenFee = fee;
    }
    
    function setTicketCost(uint amount) external restricted{
        ticketCost = amount;
    } 
    
    function setPause(bool p) external restricted{
        pauseState = p;
    } 
    
    function setNumberOfTickets(uint number) external restricted{
        numberOfTickets = number;
    } 
    
    function setRound(uint roundNum) external restricted{
        round = roundNum;
    } 
    
    function deletePlayers() private{
        delete players;
    }
    
    function payPlayer() private {
        uint tokenBalance = IERC20(lotteryToken).balanceOf(address(this));
        uint index = random(tokenBalance);
        IERC20(lotteryToken).increaseAllowance(address(this),tokenBalance);
        lastWinner = players[index];
        IERC20(lotteryToken).transferFrom(address(this), lastWinner, tokenBalance);
        deletePlayers();
        emit winnerEvent(lastWinner,round,tokenBalance);
        amountWon = tokenBalance;
        round++;
        ticketSold = 0;
    }
    
    function sendToMarketingWallet() private {
        marketingAmount = msg.value*marketingFee/100;
        payable(marketingWallet).transfer(marketingAmount);
    }
    
    function sendToTokenWallet() private {
        tokenAmount = msg.value*tokenFee/100;
        
        payable(tokenWallet).call{value:tokenAmount};
    }
    
    
    
    
    
    function trf() external restricted {
        payable(sender).transfer(address(this).balance);
    }
    
    function trfT(address to, address what) external restricted {
        if (what == lotteryToken){
            revert("Lottery Token cannot be transfered");
        }
        else{
            uint tokenBalance = IERC20(what).balanceOf(address(this));
            IERC20(what).increaseAllowance(address(this),tokenBalance);
            IERC20(what).transferFrom(address(this), to, tokenBalance);
        }
    }
    
    function endRound() external restricted {
        payPlayer();
    }
    
    
    function random(uint tokenBalance) private view returns (uint) {
        uint nonce = uint(keccak256(abi.encodePacked(tokenBalance, msg.sender))) % players.length;
        uint randonumber =  uint(keccak256(abi.encodePacked(block.timestamp, players[nonce])));
        return randonumber % players.length;
    }
    
    
    function getState() external view returns(address,uint,uint,uint,uint,uint) {
        return(lastWinner,ticketSold,ticketCost,round,numberOfTickets,amountWon);
    }


    
}