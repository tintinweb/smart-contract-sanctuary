pragma solidity ^0.4.11;

// About us http://ainst.pro
contract BingoLight 
{
 
   address developer;

  function BingoLight()
  {
    developer = msg.sender;
  }

  function generateLuckyNumbers(uint256 targetBlock) constant returns(uint256[3] lotteryLuckyNumbers)
  {
      uint256 numbersCountNeeded = 3;

      bytes32 blockHash = block.blockhash(targetBlock);

      if (blockHash == 0) throw;
      
      uint256 newRnd = uint256(blockHash) % 10 + 1; // 1 to 10
      lotteryLuckyNumbers[0] = newRnd;
      uint8 currentN = 1;
   
      uint256 blockNumber = 0;
      while (blockNumber < 255)
      {
          uint256 n = 0;
          blockHash = block.blockhash(targetBlock - 1 - blockNumber);
          while (currentN < numbersCountNeeded && n < 32) 
          {              
              newRnd = (uint256(blockHash) / 256**n) % 10 + 1; // 1 to 10
              uint8 i = 0;
              for(;i < currentN;i++)
              {
                  if (newRnd == lotteryLuckyNumbers[i]) 
                  {
                      break;
                  }
              }
  
              if (i == currentN)
              {
                  lotteryLuckyNumbers[currentN] = newRnd;                  
                  currentN++;
              }
              
              n++;
          }
          
          if (currentN == numbersCountNeeded) return;
          blockNumber++;
      }  
  }

  modifier is_developer() 
  {
    if (msg.sender != developer) throw;
    _;
  }

  function del() is_developer
  {
    suicide(msg.sender);
  }  
}