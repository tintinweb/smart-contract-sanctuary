pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Token
{
    function balanceOf(address src) constant external returns (uint256);
    function transfer(address where, uint amount) external returns (bool);
}

contract Crowdsale is Ownable
{
    using SafeMath for uint256;
    ERC20Token token;

    address public ownerWallet;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public rate;
    uint256 public totalEtherRaised = 0;
    uint256 public minDepositAmount = 0;

    uint256 public softCapEther = 100 ether;
    uint256 public hardCapEther = 270 ether;

    function Crowdsale () {
        rate = 0.001 ether;
        ownerWallet = msg.sender;
        startTime = now;
        endTime = startTime + 30 days;
        token = ERC20Token(0x0);
    }

    function () external payable {
        buy(msg.sender);
    }
    
    function getSettings () view public returns(uint256 _startTime, 
        uint256 _endTime, 
        uint256 _rate, 
        uint256 _totalEtherRaised,
        uint256 _minDepositAmount,
        uint256 _tokensLeft ) {

        _startTime = startTime;
        _endTime = endTime;
        _rate = rate;
        _totalEtherRaised = totalEtherRaised;
        _minDepositAmount = minDepositAmount;
        _tokensLeft = tokensLeft();
    }
    
    function tokensLeft() view public returns (uint256)
    {
        return token.balanceOf(address(this));
    }

    function changeDepositAmount (uint256 _minDepositAmount) onlyOwner public {
        minDepositAmount = _minDepositAmount;
    }

    function changeRate(uint256 _rate) onlyOwner public 
    {        
        require (rate > 0);
        rate = _rate;    
    }
    
    function getTokenAmount(uint256 weiAmount) public view returns(uint256) {
        return weiAmount.mul(rate);
    }

    function checkCorrectPurchase() internal {
        require(startTime < now && now < endTime);
        require(msg.value > minDepositAmount);
        require(totalEtherRaised + msg.value < hardCapEther);
    }

    function buy(address userAddress) public payable {
        require(userAddress != address(0));
        checkCorrectPurchase();

        // calculate token amount to be created
        uint256 tokens = getTokenAmount(msg.value);

        // update state
        totalEtherRaised = totalEtherRaised.add(msg.value);

        // token.transfer(userAddress, tokens); todo

        ownerWallet.transfer(msg.value);
    }    
}