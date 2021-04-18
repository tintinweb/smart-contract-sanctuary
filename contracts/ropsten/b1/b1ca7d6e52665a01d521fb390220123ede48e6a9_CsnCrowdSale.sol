pragma solidity ^0.6.0;
import './CrowdSaleBase.sol';
import './SafeMath.sol';
// SPDX-License-Identifier: UNLICENSED

contract CsnCrowdSale is CsnCrowdSaleBase {
    using SafeMath for uint256;

    constructor() public {
        wallet = 0xF218a576fBEac2de7c3B9d9d2f206317FC78c0E3; 
        // This is the address where you currently have the tokens after mining
        
        token = IERC20(0x6886896488732E5761F3e4a0A0BB66618e2B16bc); 
        // This is the address of the smart contract of token on Ethereum.
        // You can get this from Etherscan when you deploy the token.
        
        startDate = 1618686888; 
        // start date of ICO in EPOCH time stamp - Use https://www.epochconverter.com/ for getting the timestamps
        
        endDate = 1619550888; 
        // end date of ICO in EPOCH time stamp - Use https://www.epochconverter.com/ for getting the timestamps
        
        minimumParticipationAmount = 100000000000000000 wei; 
        // Example value here is 0.1 Ether. This is the minimum amount of Eth a contributor will have to put in. 
        
        baseRate = 120000000000000000000;
        // Token conversion rate per 1 Eth. This is again in wei. 1 eth = 10^18 wei. So 100 tokens will be 100 * 10^18
        
        cap = 250000000000000000000 wei; 
        // The amount you have to raise after which the ICO will close
        //100.000 ether
    }
}