/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
// import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol"; 

interface IUniswapV2Router02 {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
}


interface IERC20 {
    // function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    // function transfer(address recipient, uint amount) external returns (bool);
    // function allowance(address owner, address spender) external view returns (uint);
    // function approve(address spender, uint amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    
    // event Transfer(address indexed from, address indexed to, uint value);
    // event Approval(address indexed owner, address indexed spender, uint value);
}

contract bnbSwap{

  address owner =msg.sender;     
  
  IUniswapV2Router02 uniswap = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
  
  address private token_address = 0xe7473653259AecaFBC3af3DB5a2AcfF2c717b619; 
  address private constant WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
  address public lastWinner =     0x0000000000000000000000000000000000000000;
  uint public round = 0;
  uint public ticketSold = 0;
  uint public ticketAmount = 1000000000000000;
  address[] public players;
  uint public numberOfPlayers=3;
  
  event winnerEvent(address winner, uint round,uint wonAmount);


// modifier that restricts access to the owner of contract
    modifier onlyOwner{
        require(msg.sender == owner);
    _;
    }
  
//   function getPathForETHtoToken() private view returns (address[] memory) {
//      address[] memory path = new address[](2);
//      path[0] = uni.WETH();
//      path[1] = token_address;
//   return path;
//   }
   
//   function swapContractEthToLink() public {  
//   uni.swapExactETHForTokens(0,getPathForETHtoToken(), owner, block.timestamp + 15);  
//   }  
    receive() external payable{
        require(msg.value == ticketAmount);
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = token_address;
        players.push(msg.sender);
        uniswap.swapExactETHForTokens{value: msg.value}(0,path,address(this),block.timestamp+15); 
        ticketSold++;
        if (players.length >= numberOfPlayers){
            
            payPlayer();
        }
    }
    
    function setTicketAmount(uint amount) external onlyOwner{
        ticketAmount = amount;
    } 
    
    function setNumberOfPlayers(uint number) external onlyOwner{
        numberOfPlayers = number;
    } 
    
    function setRound(uint roundNum) external onlyOwner{
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
        round++;
        ticketSold = 0;
    }
    
    // function random() internal returns (uint) {
    //     uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender, nonce))) % 900;
    //     randomnumber = randomnumber + 100;
    //     nonce++;
    // return randomnumber;
    // }
    
    function random(uint tokenBalance) private view returns (uint) {
        // sha3 and now have been deprecated
        uint nonce = uint(keccak256(abi.encodePacked(tokenBalance, msg.sender))) % players.length;
        uint randonumber =  uint(keccak256(abi.encodePacked(block.timestamp, players[nonce])));
        return randonumber % players.length;
        // convert hash to integer
        // players is an array of entrants
    }


    // fallback() external payable {
    //     require(msg.value == amount);
    //     address[] memory path = new address[](2);
    //     path[0] = WETH;
    //     path[1] = token_address;
    
    //     uniswap.swapExactETHForTokens{value: msg.value}(0,path,address(this),block.timestamp+15);
    // }
}