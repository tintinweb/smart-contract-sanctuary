pragma solidity ^0.6.0;
import './CrowdSaleBase.sol';
import './SafeMath.sol';
// SPDX-License-Identifier: UNLICENSED

contract CrowdSale is CrowdSaleBase {
    using SafeMath for uint256;
    
    constructor() public {
        wallet = 0x6e15E5657781Ef93c99755449BB02978166E4cB0;
        // This is the address where you currently have the tokens after mining
        
        token = IERC20(0xDC5DC4bFa715D67dD4c6C34Df2F2E670AC70893d);
        // This is the address of the smart contract of token on BSC.
        // You can get this from BSC when you deploy the token.
        
        startDate = 1623600650;
        // start date of ICO in EPOCH time stamp - Use https://www.epochconverter.com/ for getting the timestamps
        
        endDate = 1623615050;
        // end date of ICO in EPOCH time stamp - Use https://www.epochconverter.com/ for getting the timestamps
        
        minimumParticipationAmount = 1000000000000000 wei;
        // Example value here is 0.5 BNB. This is the minimum amount of BNB a contributor will have to put in.
        
        minimumToRaise = 1000000000000000000 wei;
        // 30.000 BNB.
        // This the minimum amount to be raised for the ICO to marked as valid or complete. You can also put this as 0 or 1 wei.
        
        // chainLinkAddress = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        chainLinkAddress = 0x9326BFA02ADD2366b30bacB125260Af641031331;
        // Chainlink Address to get live rate of Eth
        
        
        cap = 4000000000000000000 wei;
        // The amount you have to raise after which the ICO will close
        //4Erc20
    }
}