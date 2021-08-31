// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./CodeTest_1.sol";

contract ICO is CodeTest_1  {

    using SafeMath for uint256;
    // The token we are selling
    CodeTest_1 public token;
    //fund goes to

    
    address beneficiary;
    // the UNIX timestamp start date of the crowdsale
    uint256 public startsAt;
    // the UNIX timestamp end date of the crowdsale
    uint256 public endsAt;
    // the price of token
    uint256 public TokenPerBNB;
    
    string ipfs;
    
    // Has this crowdsale been finalized
    bool public finalized = false;
    // the number of tokens already sold through this contract
    uint256 public tokensSold = 0;
    // the number of ETH raised through this contract
    uint256 public weiRaised = 0;
    // How many distinct addresses have invested
    uint256 public investorCount = 0;
    // How much ETH each address has invested to this crowdsale
    uint256 public minPerAddress = 1;
    
    mapping (address => uint256) public investedAmountOf;
    // A new investment was made
    mapping (address => uint256) public listOfAdrress;
       
    event Invested(address investor, uint256 weiAmount, uint256 tokenAmount);
    
    // Crowdsale Start time has been changed
    event StartsAtChanged(uint256 startsAt);
    
    // Crowdsale end time has been changed
    event EndsAtChanged(uint256 endsAt);
    
    // Calculated new price
    event RateChanged(uint256 oldValue, uint256 newValue);
    
    constructor (address _beneficiary)  {
        beneficiary = _beneficiary;
    }
    
    function initialize(address _token) public {
         token = CodeTest_1(_token);
    }
    function investInternal(address receiver, string  memory metadata) private {
        require(!finalized);
        require(startsAt <= block.timestamp && endsAt > block.timestamp);
        if(investedAmountOf[receiver] == 0) {
            // A new investor
            investorCount++;
        }
        // Update investor
        uint256 tokensAmount = (msg.value).mul(TokenPerBNB).div(10**10);
        investedAmountOf[receiver] += msg.value;
        // Update totals
        tokensSold += tokensAmount;
        weiRaised += msg.value;
        // Emit an event that shows invested successfully
        emit Invested(receiver, msg.value, tokensAmount);
        
        require(listOfAdrress[receiver] > 2, "Strings: 31 nft is minted with one address");
        // minPerAddress++;
        listOfAdrress[receiver] += minPerAddress;
        
        // Transfer Token to owner's address
        token.transferFrom( address(this),receiver, tokensAmount);
        
        token.safemint(receiver, metadata);
        
        // Transfer Fund to owner's address
        payable(beneficiary).transfer(address(this).balance);
    }
    function invest() public payable {
        investInternal(msg.sender, ipfs);
    }
    function setStartsAt(uint256 time) onlyOwner public {
        require(!finalized);
        startsAt = time;
        emit StartsAtChanged(startsAt);
    }
    function setEndsAt(uint256 time) onlyOwner public {
        require(!finalized);
        endsAt = time;                                                                  
        emit EndsAtChanged(endsAt);
    }
    function setRate(uint256 value) onlyOwner public {
        require(!finalized);
        require(value > 0);
        emit RateChanged(TokenPerBNB, value);
        TokenPerBNB = value;
    }
    function finalize() public onlyOwner {
        // Finalized Pre crowdsele.
        finalized = true;
        uint256 tokensAmount = token.balanceOf(address(this));
        token.transferFrom(address(this),beneficiary, tokensAmount);
    }
}