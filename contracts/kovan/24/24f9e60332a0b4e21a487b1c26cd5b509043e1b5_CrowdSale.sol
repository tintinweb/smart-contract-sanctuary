pragma solidity ^0.6.0;
import './CrowdSaleBase.sol';
import './SafeMath.sol';
// SPDX-License-Identifier: UNLICENSED

contract CrowdSale is CrowdSaleBase {
    using SafeMath for uint256;
    
    constructor() public {
        wallet = 0x96B560a99648d4897E3aAdF62347fEB978A1daBE;
        // This is the address where you currently have the tokens after mining
        
        token = IERC20(0x61336F58E8F6f911ac14FC8A3F91168636062b70);
        // This is the address of the smart contract of token on BSC.
        // You can get this from BSC when you deploy the token.
        
        startDate = 1623281438;
        // start date of ICO in EPOCH time stamp - Use https://www.epochconverter.com/ for getting the timestamps
        
        endDate = 1623454250;
        // end date of ICO in EPOCH time stamp - Use https://www.epochconverter.com/ for getting the timestamps
        
        minimumParticipationAmount = 38000000000000000 wei;
        // Example value here is 0.5 BNB. This is the minimum amount of BNB a contributor will have to put in.
        
        minimumToRaise = 1000000000000000 wei;
        // 30.000 BNB.
        // This the minimum amount to be raised for the ICO to marked as valid or complete. You can also put this as 0 or 1 wei.
        
        // chainLinkAddress = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        chainLinkAddress = 0x9326BFA02ADD2366b30bacB125260Af641031331;
        // Chainlink Address to get live rate of Eth
        
        
        cap = 18000000000000000000000 wei;
        // The amount you have to raise after which the ICO will close
        //80.000 BNB
    }
}