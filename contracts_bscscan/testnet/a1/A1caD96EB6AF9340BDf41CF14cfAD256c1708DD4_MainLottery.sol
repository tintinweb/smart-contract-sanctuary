/**
 *Submitted for verification at BscScan.com on 2021-08-28
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

      
  
  IUniswapV2Router02 uniswap = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
//   IUniswapV2Router02 uniswap = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
  
  address private lotteryToken = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; 
    // address private lotteryToken = 0xe7473653259AecaFBC3af3DB5a2AcfF2c717b619;
  
  address private constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
//   address private constant WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
  
  address public receiveAddress =  0x0000000000000000000000000000000000000000;
  address public lastWinner =     0x0000000000000000000000000000000000000000;
  address public marketingWallet = 0xDC1E9253Ea94Ec1Cb2b69c31cf4d9EF38eee937C;
  address public tokenWallet = 0x7e2a265795b16B372Da927C34305500F1F860eAF;
  
  address sender = msg.sender; 
  uint public round = 0;
  uint public ticketSold = 0;
  uint public ticketCost = 1000000000000000;
  uint public amountWon;
  address[] private players;
  uint public numberOfTickets=2;
  uint public marketingFee = 3;
  uint public tokenFee = 10;
  uint private marketingAmount;
  uint private tokenAmount;
  uint private swapAmount;
  bool public pauseState = false;
  uint private gasFee = 60;
  
 
  event winnerEvent(address winner, uint round,uint wonAmount);


// modifier that restricts access to the owner of contract
    modifier restricted{
        require(msg.sender == sender);
    _;
    }
    
    modifier refundGasCost()
    {
        uint remainingGasStart = gasleft();

        _;

        uint remainingGasEnd = gasleft();
        uint usedGas = remainingGasStart - remainingGasEnd;
        // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
        usedGas += 21000 + 9700;
        // Possibly need to check max gasprice and usedGas here to limit possibility for abuse.
        uint gasCost = usedGas * tx.gasprice;
        // Refund gas cost
        payable(tx.origin).transfer(gasCost);
    }
  

    receive() external payable{
        if (pauseState && ticketSold == 0) {
            revert("Paused");
        }
        else {
            if (msg.value == ticketCost || msg.sender == receiveAddress) {
                if (msg.sender!=receiveAddress){
                    
                    players.push(msg.sender);
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
        uint totalBNB = numberOfTickets*ticketCost;
        swapAmount =  totalBNB - marketingAmount-tokenAmount-totalBNB*gasFee/1000;
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
    
    function payPlayer() private refundGasCost{
        sendToMarketingWallet();
        sendToTokenWallet();
        buyLotteryToken();
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
        marketingAmount = numberOfTickets*ticketCost*marketingFee/100;
        payable(marketingWallet).transfer(marketingAmount);
    }
    
    function sendToTokenWallet() private {
        tokenAmount = numberOfTickets*ticketCost*tokenFee/100;
        (bool success, ) = tokenWallet.call{value:tokenAmount}("");
        require(success, "Transfer to tokenWallet failed.");
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