/**
 * 
 * 
  _______      ___       __          ___       ______ .___________. _______ .______       __   __    __  .___  ___. 
 /  _____|    /   \     |  |        /   \     /      ||           ||   ____||   _  \     |  | |  |  |  | |   \/   | 
|  |  __     /  ^  \    |  |       /  ^  \   |  ,----'`---|  |----`|  |__   |  |_)  |    |  | |  |  |  | |  \  /  | 
|  | |_ |   /  /_\  \   |  |      /  /_\  \  |  |         |  |     |   __|  |      /     |  | |  |  |  | |  |\/|  | 
|  |__| |  /  _____  \  |  `----./  _____  \ |  `----.    |  |     |  |____ |  |\  \----.|  | |  `--'  | |  |  |  | 
 \______| /__/     \__\ |_______/__/     \__\ \______|    |__|     |_______|| _| `._____||__|  \______/  |__|  |__|                                                                                                                

____ _  _ ____ ___  _ ____ _  _ ____    ____ ____    ___ _  _ ____    ____ ____ _    ____ ____ ___ ____ ____ _ _  _ _  _ 
| __ |  | |__| |  \ | |__| |\ | [__     |  | |___     |  |__| |___    | __ |__| |    |__| |     |  |___ |__/ | |  | |\/| 
|__] |__| |  | |__/ | |  | | \| ___]    |__| |        |  |  | |___    |__] |  | |___ |  | |___  |  |___ |  \ | |__| |  | 
                                                                                                                         
____ ____ ___ ____ ___     ____ _  _ ___     ____ ___ ____ ____ _  _ ____ _  _                                           
[__  |___  |  |___ |__]    |__| |\ | |  \    [__   |  |__| |__/ |\/| |__| |\ |                                           
___] |___  |  |___ |       |  | | \| |__/    ___]  |  |  | |  \ |  | |  | | \|   

Reality Benders

(3)(6)(9)
MarsOne
Rocket Labs
Elon Musk
Richard Brandson
Space Force
International Space Station
Beyond
 * 
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */


pragma solidity ^0.4.8;

import "./IncreasingPriceCrowdsale.sol";
import "./GalacticCrowdsale.sol";
import "./Ownable.sol";
import "./ERC20.sol";

contract GalacticSale is IncreasingPriceCrowdsale, Ownable {

  address  private ownerwallet;
  constructor (
    uint256 _openingTime,
    uint256 _closingTime,
    address  _wallet,
    address _token,
    uint256 _initialRate,
    uint256 _finalRate
  )
    public
    GalacticCrowdsale(_initialRate, _wallet, _token)
    TimedCrowdsale(_openingTime, _closingTime)
    IncreasingPriceCrowdsale(_initialRate, _finalRate)
  {
      ownerwallet=_wallet;
  }
  
  function closeSale() onlyOwner public{
      if(!hasClosed()) revert();
      uint256 contractTokenBalance = tokensRemaining();
     
      if(contractTokenBalance>0){
        ERC20(token).transfer(ownerwallet,contractTokenBalance);  
        emit Transfer(address(0),address(ownerwallet),contractTokenBalance);
      }
  }

}