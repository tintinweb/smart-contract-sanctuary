// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {Ownable} from "./Ownable.sol";
import {SafeMath} from "./SafeMath.sol";
import {IERC20} from "./IERC20.sol";

/**
 * The contract is provided a list of accounts that are allowed to buy tokens at a smaller rate.
 * By applying several conditions, buyers are transferred half of the tokens at the time of purchase
 * and another half after the set locking period.
 */
 
contract WhitelistBuy is Ownable {
    
    using SafeMath for uint256;

    IERC20 public token;

    uint256 rate;  
    uint256 maximumBuyIn;
    uint256 lockTimespan;

    mapping(address => bool) whitelist;
    mapping(address => uint256) maximumBuyInList;
    mapping(address => uint256) whitelistedTimeFrame;
    mapping(address => uint256) boughtLeftoverAmount;

    /**
    * Required parameters: 
    * _token: BEP20 standard token address;
    * _rate: Rate of token price to currency;
    * _maximumBuyIn: total amount of currency allowed to spend on tokens;
    * _timespanInMonths: period of token locking.
    */
    constructor(IERC20 _token, uint256 _rate, uint256 _maximumBuyIn, uint256 _timespanInMonths) {
        token = _token;
        rate = _rate;
        maximumBuyIn = _maximumBuyIn * (10 ** 18);  
        lockTimespan = 30 days * _timespanInMonths ;
    }

    /**
    * Check whether the address is whitelisted.
    */
    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }
    

    /**
    * Check whether the currency amount does not exceed the set value of maximum buy in
    * and the overall amount of currency spent by the user does not exceed the set amount.
    */
    modifier doesNotExceedMaximumBuyIn() { 
        require(
            msg.value <= maximumBuyIn,
            "Amount must be less than the set maximum"
        );
        require(
            (maximumBuyInList[msg.sender].add(msg.value)) <= maximumBuyIn,
            "Amount must be less than the set maximum"
        );
        _;
    }
    
    /**
    * Checks whether locking period has ended.
    */
    modifier lockingPeriodEnded() {
        require(
            whitelistedTimeFrame[msg.sender] <= block.timestamp,
            "Time has not passed yet"
        );
        _;
    }

    /**
    * Lets user purchase tokens if address is whitelisted 
    * and the amount of currency does not exceed the maximum allowed.
    * 
    * Function saves the total amount of currency spent by the address 
    * and adds the set amount of days to the lock period.
    * 
    * Half of purchased tokens are transferred to the buyer 
    * and another half is locked until the locking period is over.
    */
    function buy() 
        public 
        payable 
        onlyWhitelisted 
        doesNotExceedMaximumBuyIn
    {
        maximumBuyInList[msg.sender] = maximumBuyInList[msg.sender].add(
            msg.value
        );
        whitelistedTimeFrame[msg.sender] = block.timestamp.add(lockTimespan);
        uint256 amountToSpendCurr = msg.value;
        require(msg.sender != address(0), "Sender is address zero");
        require(amountToSpendCurr > 0, "You need to send some BNB");
        uint256 totalAmountOfTokens = amountToSpendCurr.mul(rate);
        require(
            totalAmountOfTokens <= token.balanceOf(address(this)),
            "Not enough tokens in the contract"
        );
        token.approve(address(this), totalAmountOfTokens);
        uint256 halfOfTotalTokens = totalAmountOfTokens.div(2);
        boughtLeftoverAmount[msg.sender] = boughtLeftoverAmount[msg.sender].add(halfOfTotalTokens);
        token.transferFrom(address(this), msg.sender, halfOfTotalTokens);
    }

    /**
    * Transfers the remaining HALF of tokens to the whitelisted address if the locking period has ended.
    */
    function claimRemainingTokens()
        public
        onlyWhitelisted
        lockingPeriodEnded        
    {   
        require(msg.sender != address(0), "Sender is address zero");
        require(
            whitelistedTimeFrame[msg.sender] > 0,
            "Timeframe was not set"
        );
        require(
            boughtLeftoverAmount[msg.sender] > 0,
            "All funds already claimed"
        );
        token.approve(address(this), boughtLeftoverAmount[msg.sender]);
        token.transferFrom(address(this), msg.sender, boughtLeftoverAmount[msg.sender]);
        boughtLeftoverAmount[msg.sender] = 0;
    }

    /**
    * Adds the address to the whitelist.
    */
    function addToWhitelistSingle(address _address) 
        public 
        onlyOwner 
    {
        whitelist[_address] = true;
    }

    /**
    * Adds multiple addresses to the whitelist.
    */
    function addToWhitelistMultiple(address[] memory _addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }


    /**
    * Removes the address from the whitelist.
    */
    function removeFromWhitelist(address _address) 
        public 
        onlyOwner 
    {
        whitelist[_address] = false;
    }


    /**
    * Changes the rate of token purchase with currency.
    */
    function changeRate(uint256 newRate) 
        public 
        onlyOwner 
    {
        rate = newRate;
    }

    /**
    * Changes the maximum buy in amount of currency.
    */
    function changeMaximumBuyIn(uint256 newMaximumBuyIn) 
        public 
        onlyOwner 
    {
        maximumBuyIn = newMaximumBuyIn;
    }

    /**
    * Shows whether address is whitelisted.
    */
    function isWhitelisted(address _address) 
        public 
        view 
        returns (bool) 
    {
        return whitelist[_address];
    }
}