// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract ICOGameNFT is Ownable  {
     
    using SafeMath for uint256;
    // The token we are selling
    IBEP20 private token;

    // the UNIX timestamp start date of the crowdsale
    uint256 private startsAt;

    // the UNIX timestamp end date of the crowdsale
    uint256 private endsAt;

    // the price of token
    uint256 private tokenPrice;
    
    // the number of tokens already sold through this contract
    uint256 private tokensSold = 0;

    // the number of ETH raised through this contract
    uint256 private weiRaised = 0;

    // How many distinct addresses have invested
    uint256 private investorCount = 0;

    struct Invest {
        uint256 investAmount;
        uint256 tokenAmount;
    }

    // How much ETH each address has invested to this crowdsale
    mapping (address => Invest) private investedAmountOf;

    // A new investment was made
    event Invested(address investor, uint256 weiAmount, uint256 tokenAmount);
    
    // Crowdsale Start time has been changed
    event StartsAtChanged(uint256 startsAt);
    
    // Crowdsale end time has been changed
    event EndsAtChanged(uint256 endsAt);

    event Claimed(address receiver, uint256 amount, uint256 time);
    
    // Calculated new price
    event RateChanged(uint256 oldValue, uint256 newValue);
    

    function initialize(address _token) public onlyOwner{
        require(_token != address(0), "Invalid Address");
        token = IBEP20(_token);
    }

    function investInternal(address receiver) private {
        require(startsAt <= block.timestamp && endsAt > block.timestamp, "Sale not started yet");
        if(investedAmountOf[receiver].investAmount == 0) {
            // A new investor
            investorCount++;
        }
        // Update investor
        uint256 tokensAmount = (msg.value).mul(10**8).div(tokenPrice);
        investedAmountOf[receiver].investAmount += msg.value;
        // Update totals
        tokensSold += tokensAmount;
        weiRaised += msg.value;
        investedAmountOf[receiver].tokenAmount += tokensAmount;
        // Transfer Fund to owner's address
        payable(owner()).transfer(address(this).balance);

        // Emit an event that shows invested successfully
        emit Invested(receiver, msg.value, tokensAmount);
    }

    function claim (address receiver, uint256 amount) public {
        require(block.timestamp > endsAt, "Sale not end yet");
        require(investedAmountOf[receiver].tokenAmount >= amount, "Zero amount in your wallet");
        // Transfer Token to owner's address
        token.transfer(receiver, amount);

        investedAmountOf[receiver].tokenAmount -= amount;
        // Emit an event that shows claimed successfully
        emit Claimed(receiver, amount, block.timestamp);
    }

    function invest() public payable {
        investInternal(msg.sender);
    }

    function setStartsAt(uint256 time) onlyOwner public {
        startsAt = time;
        emit StartsAtChanged(startsAt);
    }
    
    function setEndsAt(uint256 time) onlyOwner public {     
        endsAt = time;
        emit EndsAtChanged(endsAt);
    }
    
    function setRate(uint256 value) onlyOwner public {
        require(value > 0, "Amount must be greater than 0");
        emit RateChanged(tokenPrice, value);
        tokenPrice = value;
    }

    function price() public view returns(uint256) {
        return tokenPrice;
    }

    function starts() public view returns(uint256){
        return startsAt;
    }

    function ends() public view returns(uint256){
        return endsAt;
    }

    function investDetails(address receiver) public view returns(uint256, uint256){
       Invest memory investInf = investedAmountOf[receiver];  
       return (investInf.tokenAmount, investInf.investAmount);
    }

}