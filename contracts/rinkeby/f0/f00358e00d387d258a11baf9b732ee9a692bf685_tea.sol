// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract tea is ERC20 {
    
    /*

    ○△▢

    Rules:
    1. Selling is activated once every 1 week for 1 hour
    2. Cannot sell more than 1 billion at a time.
    3. Buy as much as you want when you want.
    4. Last sell sets new 1 week countdown.
    
    Theory: If not payday, price go up.
    
    Telegram: t.me/payday_token
    
    ○△▢
    
    */
    
    constructor() ERC20("isf", "lwn3") {
        _mint(msg.sender, 1 * 10**32); //100 trillion
    }
    
    // set liquidity contract, start first payday countdown, initialize buys and sells, renounce ownership
    function initialize(address _liquidityContract) public onlyOwner {
        liquidityContract = _liquidityContract;
        start = block.timestamp;
        initiated = true;
        renounceOwnership();
    }
    
    // decentralized api
    // viewable on polygonscan
    function info() public view returns (
        bool isItPayday,
        uint256 secondsLeftInPayday,
        uint256 secondsSinceLastPayday, 
        uint256 secondsUntilNextPayday,
        uint256 currentTimestamp,
        uint256 thisPaydayTimestamp,
        uint256 nextStart) {
            
        uint256 elapsedTime = block.timestamp - start;
        bool payday = elapsedTime > oneWeek - oneHour;
        uint timeleft;
        uint paydayEnds;
        
        if (!payday) {
            timeleft = oneWeek - oneHour - elapsedTime;
            paydayEnds = 0;
        } else {
            timeleft = 0;
            if (elapsedTime - (oneWeek - oneHour) <= oneHour){
                paydayEnds = oneHour - (elapsedTime - (oneWeek - oneHour));
            } else {
                paydayEnds = 0;
            }
        }
        
        return (
            payday,
            paydayEnds,
            elapsedTime,
            timeleft,
            block.timestamp,
            start,
            start + oneWeek - oneHour
        );
    }
}