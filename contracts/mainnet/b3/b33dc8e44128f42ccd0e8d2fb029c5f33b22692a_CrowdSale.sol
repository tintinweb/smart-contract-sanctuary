pragma solidity ^0.6.0;
import './CrowdSaleBase.sol';
import './SafeMath.sol';
// SPDX-License-Identifier: UNLICENSED

contract CrowdSale is CrowdSaleBase {
    using SafeMath for uint256;
    
    constructor() public {
        wallet = 0xA4A5564Fbb72a0C0026082C5E6863AE21FB79E31;
        // This is the Fundrasing address 
        
        token = IERC20(0x1E19D4e538B1583613347671965A2FA848271f8a);
        // This is the address of the smart contract of token on ethscan.
      
        
        startDate = 1623715331;
        // start date of ICO in EPOCH time stamp - Use https://www.epochconverter.com/ for getting the timestamps
        
        endDate = 1640953855;
        // end date of ICO in EPOCH time stamp - Use https://www.epochconverter.com/ for getting the timestamps
        
        minimumParticipationAmount = 20000000000000000 wei;
        // Example value here is 0.02 eth. This is the minimum amount of eth a contributor will have to put in.
        
        minimumToRaise = 1000000000000000 wei;
        // 0.001 eth.
        // This the minimum amount to be raised for the ICO to marked as valid or complete. You can also put this as 0 or 1 wei.
        
        chainLinkAddress = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
     
        // Chainlink Address to get live rate of Eth
        
        
        cap = 16467100000000000000000 wei;
        // The amount you have to raise after which the ICO will close
        //16467.10 Eth 
    }
}