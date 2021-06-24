pragma solidity ^0.4.26;

import "./liqnetCoin.sol";

/**
 * @title exchangeRate
 * @dev base for crowdsale to apply rate changing
 */
contract exchangeRate is Ownable {
    
    using SafeMath for uint256;

    address public trader;
    uint public rate;
    //decimal by default = 18 or 1 ether
    
    event rateChanged(uint newRate, uint time);
    
    modifier isTrader() {
       require(msg.sender == owner || msg.sender == trader);
       _;
    }
    
    /**
    * @dev set new Trader address
    * @param newAddr - new trader address.
    */
    function setTrader(address newAddr) public isTrader {
        trader = newAddr;
    }
    
    /**
     * @dev set new rate in ether format
     * @param newRate - new exchange rate of ETH to Coin. for 2510.69 is 2510690000000000000000
     */
    function setRate(uint newRate) public isTrader {
        rate = newRate;
        emit rateChanged(newRate, now);
    }
    
    /**
     * @dev set only integer part of rate.
     * @param newRate - only interger for 2510.69 is 2511
     */
    function setRateInt(uint newRate) public isTrader {
        rate = newRate.mul(1 ether);
    }
    
    /**
     * @dev set new rate with 2 decimals.
     * @param newRate - new rate. for 2510.6912 is 251069
     */
    function setRate2Decimals(uint newRate) public isTrader {
        rate = newRate.mul(1 ether).div(100);
    }
    
    /**
     * @dev convert ETH to Coins
     * @param value - amount of ETH
     * @return amount of Coins
     */
    function convert(uint value) public constant returns (uint usd) {
        return rate.mul(value).div(1 ether);
    }
}

contract crowdsaleBase is ERC223Receiver, exchangeRate {
    
    using SafeMath for uint256;
    
    address multisig;
    
    uint public hardcap;
    uint public currentETH = 0;
    uint public currentLEN = 0;
    
    uint start = 1623024000;//07 jun 2012
    
    uint period = 90;
    
    modifier salesIsOn() {
        require(now > start && now < start + period * 1 days);
        _;
    }
    
    modifier isUnderHardcap() {
        require(currentLEN < hardcap);
        _;
    }
    
    /**
     * @dev calculation of bonus tokens
     * @param tokens - base amount of tokens
     * @return amount of bonus Tokens
     */
    function calcBonusTokens(uint tokens) internal constant returns (uint bonusTokens) {
        bonusTokens = 0;
        /*if (now < start + (24 hours)) {
            bonusTokens = tokens.div(5);
        } else */
        if (now < start + (30 days)) {
            bonusTokens = tokens.div(100).mul(15);
        } else if (now < start + (60 days)) {
            bonusTokens = tokens.div(1000).mul(75);
        }
        return bonusTokens;
    }
    
    /**
     * @dev calculation oftokens
     */
    function createTokensBase(uint _amount) internal isUnderHardcap salesIsOn returns (uint tokens) {
        tokens = convert(_amount);
        tokens = tokens.add(calcBonusTokens(tokens));
        
        currentLEN = currentLEN.add(tokens);
        currentETH = currentETH.add(_amount);
        
        return tokens;
    }
}

/**
 * @title Crowdsale LEN tokens. This contract is saleAgent for LEN_ERC20 compatible.
 */
contract LiqnetCrowdsale is crowdsaleBase {
    
    using SafeMath for uint256;
    
    LiqnetCoin token = LiqnetCoin(0xf569E6bDfAC9ca4AD2814C7Af393B27B4A03bE0B);// paste real address & setSaleAgent for iteraction.
    
    constructor () public {
        hardcap = 3500000 * (1 ether);
        rate = 2241060000000000000000;//2241.06
        multisig = 0x806b5968FD6E67caC021f6354443434d99AEcA20;//address to transfer all income Ethers
        start = 1623628800;//test //1624320000;//22 jun 2021
        period = 90;
    }
    
    function createTokens() public isUnderHardcap salesIsOn payable {
        uint tokens = createTokensBase(msg.value);
        multisig.transfer(msg.value);//comment this to hold eth in contract address.
        
        //Mintable
        token.mint(msg.sender, tokens);//send tokens to investor. 1eth=1token
    }
    
    function() external payable {
        createTokens();
    }
}