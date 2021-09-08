// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {Ownable} from "./Ownable.sol";
import {SafeMath} from "./SafeMath.sol";
import {IBEP20} from "./IBEP20.sol";

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

    constructor(IBEP20 _token, uint256 _rate, uint256 _minimumBuyIn, uint256 _maximumBuyIn, uint256 _timespanInMonths) {
        token = _token;
        rate = _rate;
        minimumBuyIn = _minimumBuyIn;
        maximumBuyIn = _maximumBuyIn;
        lockTimespan = 30 days * _timespanInMonths;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender),
        "Address is not in the whitelist.");
        _;
    }

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

    modifier lockingPeriodEnded() {
        require(
            whitelistUnlockTime[msg.sender] <= block.timestamp,
            "Time has not passed yet."
        );
        _;
    }

    modifier addressNotZero() {
        require(
            msg.sender != address(0),
            "Sender is address zero."
        );
        _;
    }

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

    function addToWhitelistSingle(address _address)
        public
        onlyOwner
    {
        whitelist[_address] = true;
    }

    function addToWhitelistMultiple(address[] memory _addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function removeFromWhitelist(address _address)
        public
        onlyOwner
    {
        whitelist[_address] = false;
    }

    function changeRate(uint256 newRate)
        public
        onlyOwner
    {
        rate = newRate;
    }

    function changeMaximumBuyIn(uint256 newMaximumBuyIn)
        public
        onlyOwner
    {
        maximumBuyIn = newMaximumBuyIn;
    }

    function changeMinimumBuyIn(uint256 newMinimumBuyIn)
        public
        onlyOwner
    {
        minimumBuyIn = newMinimumBuyIn;
    }

    function changelockTimespan(uint256 newLockTimespan)
        public
        onlyOwner
    {
        lockTimespan = newLockTimespan;
    }

    function withdrawAnyContractTokens(IBEP20 tokenAddress, address recipient) 
        public
        onlyOwner
        addressNotZero
    {
        require(recipient != address(0), "Receiver is address zero");
        tokenAddress.approve(address(this), tokenAddress.balanceOf(address(this)));
        tokenAddress.transferFrom(address(this), recipient, tokenAddress.balanceOf(address(this)));
    } 

    function isWhitelisted(address _address)
        public
        view
        returns (bool)
    {
        return whitelist[_address];
    }

    function unclaimedTokensPerAddress(address _address)
        public
        view
        returns (uint256)
    {
        return boughtLeftoverAmount[_address];
    }

    function unlockTimePerAddress(address _address)
        public
        view
        returns (uint256)
    {
        return whitelistUnlockTime[_address];
    }

    function totalUnclaimedTokens()
        public
        view
        onlyOwner
        returns (uint256)
    {
        return unclaimedTokens;
    }

}