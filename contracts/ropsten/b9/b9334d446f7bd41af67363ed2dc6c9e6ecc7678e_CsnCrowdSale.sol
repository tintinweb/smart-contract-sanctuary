pragma solidity ^0.6.0;
import './CrowdSaleBase.sol';
import './SafeMath.sol';
// SPDX-License-Identifier: UNLICENSED

contract CsnCrowdSale is CsnCrowdSaleBase {
    using SafeMath for uint256;

    constructor() public {
        wallet = 0xbCd3E2F199dE9cD8A3Fa154D3Ad4393E1d066397; 
        // This is the address where you currently have the tokens after mining
        
        token = IERC20(0x867C305CBa1c7e20dcC216694d770A7fbA616118); 
        // This is the address of the smart contract of token on Ethereum.
        // You can get this from Etherscan when you deploy the token.
        
        startDate = 1618686888; 
        // start date of ICO in EPOCH time stamp - Use https://www.epochconverter.com/ for getting the timestamps
        
        endDate = 1619550888; 
        // end date of ICO in EPOCH time stamp - Use https://www.epochconverter.com/ for getting the timestamps
        
        minimumParticipationAmount = 100000000000000000 wei; 
        // Example value here is 0.1 Ether. This is the minimum amount of Eth a contributor will have to put in. 
        
        minimumToRaise = 4000000000000000000000; 
        // 4.000 Ether.
        // This the minimum amount to be raised for the ICO to marked as valid or complete. You can also put this as 0 or 1 wei.
        
        baseRate = 120000000000000000000;
        // Token conversion rate per 1 Eth. This is again in wei. 1 eth = 10^18 wei. So 100 tokens will be 100 * 10^18
        
        cap = 100000000000000000000000 wei; 
        // The amount you have to raise after which the ICO will close
        //100.000 ether
    }
}