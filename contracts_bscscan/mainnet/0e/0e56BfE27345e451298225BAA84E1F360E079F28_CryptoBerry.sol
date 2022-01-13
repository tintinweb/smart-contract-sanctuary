/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

//This is promo version of CryptoBerry getting live in 13 jan , UTC 16:30 (next 30 mins)
//main contract is deployed on address 0xd2977a2a148df7f2c881c6eAb8E61fa2E859F5B0
//BSC: https://bscscan.com/token/0xd2977a2a148df7f2c881c6eAb8E61fa2E859F5B0
/**
*
We have anitbot feature in above MAIN contract because of which trade will automatically start on 13 January'2022, UTC time 16:30
FIRST EVER TOKEN IN HISTORY to have Dynamic tax and Greylisting
Buy Tax 10%(half to marketing and half to liquidity)
DYNAMIC TAX: sell tax varies from 10% to 5% (more you HOLD then less tax you pay)
GREYLISTING: After your latest buy or sell, tokens cannot be sold within 24 hours(in main contract) and ONLY 5 minutes in lite contarct. 
2% Max wallet.
Locked Liquidity
1 Trillion supply
0% transfer Tax while transfer to any normal account 
Buy CryptoBerry the Next future gem.
Follow CryptoBerry
BSC: https://bscscan.com/token/0xd2977a2a148df7f2c881c6eAb8E61fa2E859F5B0
Web: https://thecryptoberry.com/
twitter: https://twitter.com/MyCryptoBerry
Telegram: https://t.me/cryptoberrycommunity
Facebook: https://www.facebook.com/cryptoberrycommunity
Instagram: https://www.instagram.com/mycryptoberry/
*
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CryptoBerry {

    uint256 number;

    function store(uint256 num) public {
        number = num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}