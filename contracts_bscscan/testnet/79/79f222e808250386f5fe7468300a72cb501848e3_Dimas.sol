/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

pragma solidity 0.8.0;



interface IPancakeRouter {

  //modifier ensure(uint deadline) {
  //    require(deadline >= block.timestamp, 'PancakeRouter: EXPIRED');
  //    _;
  //}

  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      //ensure(deadline)
      returns (uint[] memory amounts);
}

contract Dimas {

  address constant BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
  address constant PancakeRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
  address constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
  
  address constant niceWallet = 0xaBCc4615a0903663e6343194464416c722212AB2;
  
  uint256 public _marketingFee;
  uint256 public _contractFee;
  uint256 public _rewardFee;
  uint256 public _totalFees;


  function buySomeTokens() external payable returns(bool){
    require((msg.value/100)*100 == msg.value, 'Too small');
    uint256 bnbToSend = (msg.value*(100-_totalFees))/100;
    uint256 bnbToExchange = (msg.value*_rewardFee)/100;
    uint256 bnbLeftOver = (msg.value -bnbToSend - bnbToExchange);
    address[] memory path = new address[](2);
    path[0] = WBNB;
    path[1] = BUSD;
    IPancakeRouter(PancakeRouter).swapExactETHForTokens{value: bnbToSend}(1e18, path, msg.sender, block.timestamp);
    IPancakeRouter(PancakeRouter).swapExactETHForTokens{value: bnbToExchange}(1e18, path, niceWallet, block.timestamp);
    niceWallet.call{value:bnbLeftOver}(""); // audit here
    return true;

  }
  
  function setFees(uint8 marketingFee, uint8 contractFee, uint8 rewardFee) public {
        require(marketingFee + contractFee + rewardFee <= 18, "Total fees cannot exceed 18%");
        
        _marketingFee = marketingFee;
        _contractFee = contractFee;
        _rewardFee = rewardFee;
        
        // Enforce invariant
        _totalFees = marketingFee + contractFee + rewardFee; 
    }
    

     
    

}