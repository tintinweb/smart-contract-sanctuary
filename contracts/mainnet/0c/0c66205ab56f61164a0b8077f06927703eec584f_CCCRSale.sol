pragma solidity ^0.4.16;

interface CCCRCoin {
    function transfer(address receiver, uint amount);
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
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
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract CCCRSale is Pausable {
    using SafeMath for uint256;

    address public investWallet = 0xbb2efFab932a4c2f77Fc1617C1a563738D71B0a7;
    CCCRCoin public tokenReward; 
    uint256 public tokenPrice = 856; // 1ETH (856$) / 1$
    uint256 zeroAmount = 10000000000; // 10 zero
    uint256 startline = 1510736400; // 15.11.17 12:00
    uint256 public minCap = 300000000000000;
    uint256 public totalRaised = 207008997355300;

    function CCCRSale(address _tokenReward) {
        tokenReward = CCCRCoin(_tokenReward);
    }

    function () whenNotPaused payable {
        buy(msg.sender, msg.value); 
    }

    function getRate() constant internal returns (uint256) {
        if      (block.timestamp < startline + 19 days) return tokenPrice.mul(138).div(100);
        else if (block.timestamp <= startline + 46 days) return tokenPrice.mul(123).div(100);
        else if (block.timestamp <= startline + 60 days) return tokenPrice.mul(115).div(100);
        else if (block.timestamp <= startline + 74 days) return tokenPrice.mul(109).div(100);
        return tokenPrice;
    }

    function buy(address buyer, uint256 _amount) whenNotPaused payable {
        require(buyer != address(0));
        require(msg.value != 0);

        uint256 amount = _amount.div(zeroAmount);
        uint256 tokens = amount.mul(getRate());
        tokenReward.transfer(buyer, tokens);

        investWallet.transfer(this.balance);
        totalRaised = totalRaised.add(tokens);

        if (totalRaised >= minCap) {
          paused = true;
        }
    }

    function updatePrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function transferTokens(uint256 _tokens) external onlyOwner {
        tokenReward.transfer(owner, _tokens); 
    }

    function airdrop(address[] _array1, uint256[] _array2) external onlyOwner {
       address[] memory arrayAddress = _array1;
       uint256[] memory arrayAmount = _array2;
       uint256 arrayLength = arrayAddress.length.sub(1);
       uint256 i = 0;
       
      while (i <= arrayLength) {
           tokenReward.transfer(arrayAddress[i], arrayAmount[i]);
           i = i.add(1);
      }  
    }

}