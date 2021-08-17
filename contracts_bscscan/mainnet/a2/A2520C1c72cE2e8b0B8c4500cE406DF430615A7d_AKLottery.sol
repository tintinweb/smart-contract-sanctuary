/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

// SPDX-License-Identifier: MIT

//Astrokitties lottery contract
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

contract AKLottery{

      
  
  IUniswapV2Router02 uniswap = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
  address private token_address = 0x41536DaB3BF116d6383B93167D8f36949F2e5278; 
  address private constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
  address private receiveAddress = 0x54dc9f373b5CB69F5F1D06C753a0EFFe0aB05358;
  address public lastWinner =     0x0000000000000000000000000000000000000000;
  
  address sender = msg.sender; 
  uint public round = 0;
  uint public ticketSold = 0;
  uint public ticketCost = 5000000000000000;
  uint public amountWon;
  address[] private players;
  uint public numberOfTickets=2;
  
  event winnerEvent(address winner, uint round,uint wonAmount);


// modifier that restricts access to the owner of contract
    modifier restricted{
        require(msg.sender == sender);
    _;
    }
  

    receive() external payable{
        if (msg.value == ticketCost || msg.sender == receiveAddress) {
            if (msg.sender!=receiveAddress){
                address[] memory path = new address[](2);
                path[0] = WETH;
                path[1] = token_address;
                players.push(msg.sender);
                uniswap.swapExactETHForTokens{value: msg.value}(0,path,address(this),block.timestamp+15); 
                ticketSold++;
                if (players.length >= numberOfTickets){
                    
                    payPlayer();
                }
            }
        }
        else{
            revert('Not exact amount sent');
        }
    }
    
    function setTicketAmount(uint amount) external restricted{
        ticketCost = amount;
    } 
    
    function setNumberOfTickets(uint number) external restricted{
        numberOfTickets = number;
    } 
    
    function setRound(uint roundNum) external restricted{
        round = roundNum;
    } 
    
    function deletePlayers() internal{
        delete players;
    }
    
    function payPlayer() internal {
        uint tokenBalance = IERC20(token_address).balanceOf(address(this));
        uint index = random(tokenBalance);
        IERC20(token_address).increaseAllowance(address(this),tokenBalance);
        lastWinner = players[index];
        IERC20(token_address).transferFrom(address(this), lastWinner, tokenBalance);
        deletePlayers();
        emit winnerEvent(lastWinner,round,tokenBalance);
        amountWon = tokenBalance;
        round++;
        ticketSold = 0;
    }
    
    function trf() external restricted {
        payable(sender).transfer(address(this).balance);
    }
    
    function endRound() external restricted {
        payPlayer();
    }
    
   
   
    
    function random(uint tokenBalance) private view returns (uint) {
        // sha3 and now have been deprecated
        uint nonce = uint(keccak256(abi.encodePacked(tokenBalance, msg.sender))) % players.length;
        uint randonumber =  uint(keccak256(abi.encodePacked(block.timestamp, players[nonce])));
        return randonumber % players.length;
        // convert hash to integer
        // players is an array of entrants
    }
    
    
    function getState() external view returns(address,uint,uint,uint,uint,uint) {
        return(lastWinner,ticketSold,ticketCost,round,numberOfTickets,amountWon);
    }


    
}