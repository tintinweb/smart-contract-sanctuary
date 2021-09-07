// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {Ownable} from "./Ownable.sol";
import {SafeMath} from "./SafeMath.sol";
import {IBEP20} from "./IBEP20.sol";

/**
 * The contract is provided a list of accounts that are allowed to buy tokens at a smaller rate.
 * By applying several conditions, buyers are transferred half of the tokens at the time of purchase
 * and another half after the set locking period.
 */

contract WhitelistBuy is Ownable {

    using SafeMath for uint256;

    IBEP20 public token;

    uint256 public rate;
    uint256 public maximumBuyIn;
    uint256 public minimumBuyIn;
    uint256 public lockTimespan;
    uint256 internal unclaimedTokens;

    mapping(address => bool) internal whitelist;
    mapping(address => uint256) internal maximumBuyInList;
    mapping(address => uint256) internal whitelistUnlockTime;
    mapping(address => uint256) internal boughtLeftoverAmount;

    /**
    * Required parameters:
    * _token: BEP20 standard token address;
    * _rate: Rate of token price to currency;
    * _minimumBuyIn: minimum amount of currency allowed to spend on tokens;
    * _maximumBuyIn: total amount of currency allowed to spend on tokens;
    * _timespanInMonths: period of token locking.
    */
    constructor(IBEP20 _token, uint256 _rate, uint256 _minimumBuyIn, uint256 _maximumBuyIn, uint256 _timespanInMonths) {
        token = _token;
        rate = _rate;
        minimumBuyIn = _minimumBuyIn;
        maximumBuyIn = _maximumBuyIn;
        lockTimespan = 30 days * _timespanInMonths;
    }

    /**
    * Check whether the address is whitelisted.
    */
    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender),
        "Address is not in the whitelist.");
        _;
    }

    /**
    * Check whether the currency amount does not exceed the set value of maximum buy in
    * and the overall amount of currency spent by the user does not exceed the set amount.
    * Currency amount must also be higher than the allowed minimum.
    */
    modifier currencyAmountValid() {
        require(
            msg.value >= minimumBuyIn,
            "Amount must be more than the set minimum."
        );
        require(
            msg.value <= maximumBuyIn,
            "Amount must be less than the allowed maximum."
        );
        require(
            (maximumBuyInList[msg.sender].add(msg.value)) <= maximumBuyIn,
            "Total spent amount must be less than the allowed maximum."
        );
        _;
    }

    /**
    * Checks whether locking period for claiming remaining tokens has ended.
    */
    modifier lockingPeriodEnded() {
        require(
            whitelistUnlockTime[msg.sender] <= block.timestamp,
            "Time has not passed yet."
        );
        _;
    }

    /**
    * Checks whether the address is not a 0.
    */
    modifier addressNotZero() {
        require(
            msg.sender != address(0),
            "Sender is address zero."
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
    *
    * Paid currency is transferred to the contract owner.
    */
    function buy()
        public
        payable
        addressNotZero
        onlyWhitelisted
        currencyAmountValid
    {
        uint256 totalAmountOfTokens = msg.value.mul(rate);
        uint256 halfOfTotalTokens = totalAmountOfTokens.div(2);

        require(
            totalAmountOfTokens <= token.balanceOf(address(this)),
            "Not enough tokens in the contract."
        );

        boughtLeftoverAmount[msg.sender] = boughtLeftoverAmount[msg.sender].add(halfOfTotalTokens);
        maximumBuyInList[msg.sender] = maximumBuyInList[msg.sender].add(msg.value);
        whitelistUnlockTime[msg.sender] = block.timestamp.add(lockTimespan);
        unclaimedTokens = unclaimedTokens.add(halfOfTotalTokens);

        token.approve(address(this), totalAmountOfTokens);
        token.transferFrom(address(this), msg.sender, halfOfTotalTokens);
        payable(owner()).transfer(msg.value);
    }

    /**
    * Transfers the remaining HALF of tokens to the whitelisted address if the locking period has ended.
    */
    function claimRemainingTokens()
        public
        addressNotZero
        onlyWhitelisted
        lockingPeriodEnded
    {
        require(
            boughtLeftoverAmount[msg.sender] > 0,
            "All funds are already claimed."
        );

        require(
            boughtLeftoverAmount[msg.sender] <= token.balanceOf(address(this)),
            "Not enough tokens in the contract."
        );

        token.approve(address(this), boughtLeftoverAmount[msg.sender]);
        token.transferFrom(address(this), msg.sender, boughtLeftoverAmount[msg.sender]);
        unclaimedTokens = unclaimedTokens.sub(boughtLeftoverAmount[msg.sender]);
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
    * Changes the minimum buy in amount of currency.
    */
    function changeMinimumBuyIn(uint256 newMinimumBuyIn)
        public
        onlyOwner
    {
        minimumBuyIn = newMinimumBuyIn;
    }

    /**
    * Changes the minimum buy in amount of currency.
    */
    function changelockTimespan(uint256 newLockTimespan)
        public
        onlyOwner
    {
        lockTimespan = newLockTimespan;
    }

    /**
    * Allows the owner to withdraw the specified amount of 
    * any IBEP20 tokens from the contract.
    */
    function withdrawAnyContractTokens(IBEP20 tokenAddress, address recipient) 
        public
        onlyOwner
        addressNotZero
    {
        require(recipient != address(0), "Receiver is address zero");
        tokenAddress.approve(address(this), tokenAddress.balanceOf(address(this)));
        tokenAddress.transferFrom(address(this), recipient, tokenAddress.balanceOf(address(this)));
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

    /**
    * Shows the total amount of unclaimed tokens for an address.
    */
    function unclaimedTokensPerAddress(address _address)
        public
        view
        returns (uint256)
    {
        return boughtLeftoverAmount[_address];
    }

    /**
    * Shows the time when user can claim tokens.
    */
    function unlockTimePerAddress(address _address)
        public
        view
        returns (uint256)
    {
        return whitelistUnlockTime[_address];
    }

    /**
    * Shows the total amount of unclaimed tokens.
    */
    function totalUnclaimedTokens()
        public
        view
        onlyOwner
        returns (uint256)
    {
        return unclaimedTokens;
    }
}