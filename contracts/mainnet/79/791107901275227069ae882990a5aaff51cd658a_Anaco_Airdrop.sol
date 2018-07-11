pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Interface{
    function transferFrom(address from, address to, uint256 value) public returns (bool);
}

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;
  
  constructor() public { 
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }
  //transfer owner to another address
  function transferOwnership(address _newOwner) onlyOwner public {
    if (_newOwner != address(0)) {
      owner = _newOwner;
    }
  }
}

contract Anaco_Airdrop is Ownable {
    
    // allows the use of the SafeMath library inside that contract, only for uint256 variables
    using SafeMath for uint256;
    
    // Token exchange rate (taking into account the 8 decimals from ANACO tokens)
    uint256 public tokensPerEth = 100000000 * 1e8;
    uint256 public closeTime = 1538351999; // September 30th, at 11PM 59:59 GMT is the end of the airdrop
    
    // ANAC Token interface
    ERC20Interface public anacoContract = ERC20Interface(0x356A50ECE1eD2782fE7031D81FD168f08e242a4E);
    address public fundsWallet;
    
    // modifiers
    modifier airdropOpen() {
       // if(now > closeTime) revert();
        _;
    }
    
    modifier airdropClosed() {
       // if(now < closeTime) revert(); 
        _;
    }
    
    constructor(address _fundsWallet) public {
        fundsWallet = _fundsWallet;
    }
    
    
    function () public {
        revert();           // do not accept fallback calls
    }
    
    
    function getTokens() payable public{
        require(msg.value >= 2 finney);             // needs to contribute at least 0.002 Ether
        
        uint256 amount = msg.value.mul(tokensPerEth).div(1 ether);
        
        if(msg.value >= 500 finney) {               // +50% bonus if you contribute more than 0.5 Ether
            amount = amount.add(amount.div(2));
        }
        
        anacoContract.transferFrom(fundsWallet, msg.sender, amount); // reverts by itself if fundsWallet doesn&#39;t allow enough funds to the contract
    }
    
    
    function withdraw() public onlyOwner {
        require(owner.send(address(this).balance));
    }
    
    
    function changeFundsWallet(address _newFundsWallet) public onlyOwner {
        fundsWallet = _newFundsWallet;
    }
    
}