pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract INATokenAbstract is ERC20Basic{
  function unlockPublic() public;
  function unlockPrivate() public;
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract INACrowdsale is Ownable {
  using SafeMath for uint256;

  address public INAAddress;

  // The token being sold
  INATokenAbstract public INAToken;
  // start and end timestamps where public sale are allowed (both inclusive)
  uint256 public constant startTime = 1533315600;
  uint256 public constant mTime = 1533317400;
  uint256 public constant endTime = 1533319200;



  // address where funds are collected
  address public INAWallet;
  address public team1Address;
  address public team2Address;
  address public team3Address;
  address public team4Address;

  // how many token units a buyer gets per wei
  uint256 public rate1 = 1000000000;
  uint256 public rate2 = 500000000;

  // amount of raised money in wei
  uint256 public weiRaised;

  mapping (address => bool) public PublicBuyerList;

  constructor(address _token, address _INAWallet, address _team1Address, address _team2Address, address _team3Address, address _team4Address) public {
    INAAddress = _token;
    INAToken = INATokenAbstract(INAAddress);
    INAWallet = _INAWallet;
    team1Address = _team1Address;
    team2Address = _team2Address;
    team3Address = _team3Address;
    team4Address = _team4Address;
  }

  function addAddressToPublicBuyerList(address addr) public onlyOwner {
    // Allow a certain address to purchase INA Coin
    PublicBuyerList[addr] = true; 
  }

  function addMultipleAddressesToPublicBuyerList(address[] addrList) public onlyOwner {
    for (uint i = 0; i < addrList.length; i++) {
      // Allow a certain address to purchase INA Coin
      addAddressToPublicBuyerList(addrList[i]); 
    }
  }
  
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(PublicBuyerList[msg.sender]);
    require(validPurchase());
    require(beneficiary != address(0));
    require(msg.value != 0);

    // calculate token amount to be created
    uint256 INAAmounts = calculateObtainedINA(msg.value);
    
    // update state
    weiRaised = weiRaised.add(msg.value);

    require(INAToken.transfer(beneficiary, INAAmounts));
    emit TokenPurchase(msg.sender, beneficiary, msg.value, INAAmounts);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    INAWallet.transfer(msg.value);
  }

  function calculateObtainedINA(uint256 amountEtherInWei) public view returns (uint256) {
    if( now <= mTime) {
      return amountEtherInWei.mul(rate1);
    } else if ( now > mTime) {
      return amountEtherInWei.mul(rate2);
    }
  } 

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = (now >= startTime && now <= endTime);
    return withinPeriod;
  }

  function releaseINAToken() public {
    require (now > endTime);
    uint256 remainedINA = INAToken.balanceOf(this);
    uint256 teamlockedINA = remainedINA.div(4);
    uint256 lasttoken = remainedINA.sub(teamlockedINA.mul(3));
    require(INAToken.transfer(team1Address, teamlockedINA));
    require(INAToken.transfer(team2Address, teamlockedINA));
    require(INAToken.transfer(team3Address, teamlockedINA));
    require(INAToken.transfer(team4Address, lasttoken));   
    INAToken.unlockPublic();
  }

  function releaseINATokenToTeam() public {
    INAToken.unlockPrivate();
  }

  function changeINAWallet(address _INAWallet) public {
    require (msg.sender == INAWallet);
    INAWallet = _INAWallet;
  }

  // Forbid to transfer INA by this function
  function transferAnyERC20Token(address _tokenAddress, uint256 _value) public onlyOwner returns (bool) {
    require(_tokenAddress != INAAddress);
    return ERC20Basic(_tokenAddress).transfer(INAWallet, _value);
  }

}