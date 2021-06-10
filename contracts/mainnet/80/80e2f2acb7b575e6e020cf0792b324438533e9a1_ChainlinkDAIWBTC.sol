/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^0.5.16;

contract ChainlinkLike {
    function latestAnswer() external view returns(int);
}

contract ChainlinkDAIWBTC {
    ChainlinkLike constant DAI_USD = ChainlinkLike(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
    ChainlinkLike constant USD_BTC = ChainlinkLike(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
    
    function latestAnswer() external view returns(int) {
        int daiusd = DAI_USD.latestAnswer();
        int usdbtc = USD_BTC.latestAnswer();
        
        return daiusd * 1e8 / usdbtc;
    }
}