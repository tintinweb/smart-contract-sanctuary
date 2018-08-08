pragma solidity ^0.4.13;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract BBDToken {
    function totalSupply() constant returns (uint256);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool);

    function creationRateOnTime() constant returns (uint256);
    function creationMinCap() constant returns (uint256);
    function transferToExchange(address _from, uint256 _value) returns (bool);
    function buy(address _beneficiary) payable;
}

/**
    Exchange for BlockChain Board Of Derivatives Token.
 */
contract BBDExchange is Ownable {
    using SafeMath for uint256;

    uint256 public constant startTime = 1506844800; //Sunday, 1 October 2017 08:00:00 GMT
    uint256 public constant endTime = 1509523200;  // Wednesday, 1 November 2017 08:00:00 GMT

    BBDToken private bbdToken;

    // Events
    event LogSell(address indexed _seller, uint256 _value, uint256 _amount);
    event LogBuy(address indexed _purchaser, uint256 _value, uint256 _amount);

    // Check if min cap was archived.
    modifier onlyWhenICOReachedCreationMinCap() {
        require(bbdToken.totalSupply() >= bbdToken.creationMinCap());
        _;
    }

    function() payable {}

    function Exchange(address bbdTokenAddress) {
        bbdToken = BBDToken(bbdTokenAddress);
    }

    // Current exchange rate for BBD
    function exchangeRate() constant returns (uint256){
        return bbdToken.creationRateOnTime().mul(100).div(93); // 93% of price on current contract sale
    }

    // Number of BBD tokens on exchange
    function exchangeBBDBalance() constant returns (uint256){
        return bbdToken.balanceOf(this);
    }

    // Max number of BBD tokens on exchange to sell
    function maxSell() constant returns (uint256 valueBbd) {
        valueBbd = this.balance.mul(exchangeRate());
    }

    // Max value of wei for buy on exchange
    function maxBuy() constant returns (uint256 valueInEthWei) {
        valueInEthWei = exchangeBBDBalance().div(exchangeRate());
    }

    // Check if sell is possible
    function checkSell(uint256 _valueBbd) constant returns (bool isPossible, uint256 valueInEthWei) {
        valueInEthWei = _valueBbd.div(exchangeRate());
        isPossible = this.balance >= valueInEthWei ? true : false;
    }

    // Check if buy is possible
    function checkBuy(uint256 _valueInEthWei) constant returns (bool isPossible, uint256 valueBbd) {
        valueBbd = _valueInEthWei.mul(exchangeRate());
        isPossible = exchangeBBDBalance() >= valueBbd ? true : false;
    }

    // Sell BBD
    function sell(uint256 _valueBbd) onlyWhenICOReachedCreationMinCap external {
        require(_valueBbd > 0);
        require(now >= startTime);
        require(now <= endTime);
        require(_valueBbd <= bbdToken.balanceOf(msg.sender));

        uint256 checkedEth = _valueBbd.div(exchangeRate());
        require(checkedEth <= this.balance);

        //Transfer BBD to exchange and ETH to user 
        require(bbdToken.transferToExchange(msg.sender, _valueBbd));
        msg.sender.transfer(checkedEth);

        LogSell(msg.sender, checkedEth, _valueBbd);
    }

    // Buy BBD
    function buy() onlyWhenICOReachedCreationMinCap payable external {
        require(msg.value != 0);
        require(now >= startTime);
        require(now <= endTime);

        uint256 checkedBBDTokens = msg.value.mul(exchangeRate());
        require(checkedBBDTokens <= exchangeBBDBalance());

        //Transfer BBD to user. 
        require(bbdToken.transfer(msg.sender, checkedBBDTokens));

        LogBuy(msg.sender, msg.value, checkedBBDTokens);
    }

    // Close Exchange
    function close() onlyOwner {
        require(now >= endTime);

        //Transfer BBD and ETH to owner
        require(bbdToken.transfer(owner, exchangeBBDBalance()));
        owner.transfer(this.balance);
    }
}