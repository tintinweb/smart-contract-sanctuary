// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./CodeTest_1.sol";

contract ICO is Ownable  {

    using SafeMath for uint256;
    // The token we are selling
    CodeTest_1 public token;
    //fund goes to
    
  
    
    address beneficiary;
    // the UNIX timestamp start date of the crowdsale
    uint256 private startsAt;
    // the UNIX timestamp end date of the crowdsale
    uint256 private endsAt;
    // the price of token
    uint256 private TokenPerBNB;
    bool private _pause_ico;
    

    // Has this crowdsale been finalized
    bool private finalized = false;
    // the number of tokens already sold through this contract
    uint256 private tokensSold = 0;
    // the number of ETH raised through this contract
    uint256 private weiRaised = 0;
    // How many distinct addresses have invested
    uint256 private investorCount = 0;
    // How much ETH each address has invested to this crowdsale
    uint256 private minPerAddress = 1;
    uint256 private token_id = 0;
    uint256 private token_id_presale = 0;
    
    mapping (address => uint256) private investedAmountOf;
    // A new investment was made
    mapping (address => uint256) private listOfAdrress_presale;
    
    mapping (address => bool) private listOfAdrress_whitelist;
       
    event Invested(address investor, uint256 weiAmount, uint256 tokenAmount);
    
    // Crowdsale Start time has been changed
    event StartsAtChanged(uint256 startsAt);
    
    // Crowdsale end time has been changed
    event EndsAtChanged(uint256 endsAt);
    
    // Calculated new price
    event RateChanged(uint256 oldValue, uint256 newValue);
    
    function initialize(address _beneficiary, address _token) public {
        beneficiary = _beneficiary;
        token = CodeTest_1(_token);
        _pause_ico = true;
    }
     function get_nft(address to) public payable {
        
        require(listOfAdrress_whitelist[to], "Strings: This user is not whitelisted");
        require(listOfAdrress_presale[to] < 6, "Strings: You cant't mint");
        require(TokenPerBNB >= msg.value,"Strings: Please Check Price");
        require(_pause_ico, "Strings: pause");
        token.buy_nft(to);
    }
    
    function investInternal(address receiver, string  memory metadata) private {
        require(!finalized, "Strings: finalized error");
     
        require(token_id < 222, "Strings: 222 nft is minted");
        token_id++;
        listOfAdrress_presale[receiver] += 1; 
        token.safemint(receiver, metadata);
        
        // Transfer Fund to owner's address
        // payable(owner()).transfer(address(this).balance);
    }
    
    function invest(string memory _ipfs) public payable {
        investInternal(msg.sender, _ipfs);
    }
    
    function white_list(address whitelisted) onlyOwner public {
        listOfAdrress_whitelist[whitelisted] = true;
    }
    
    function black_list(address whitelisted) onlyOwner public {
        listOfAdrress_whitelist[whitelisted] = false;
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
    
    function pause_ico() public onlyOwner {
        _pause_ico = true;
    }
    
    function unpause_ico() public onlyOwner {
        _pause_ico = false;
    }
    
    function finalize() public onlyOwner {
        // Finalized Pre crowdsele.
        finalized = true;
        uint256 tokensAmount = token.balanceOf(address(this));
        token.transferFrom(address(this),beneficiary, tokensAmount);
    }
    
    function getstartAt() public view virtual returns(uint256){
        return startsAt;
    }
}