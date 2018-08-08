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
  address public manager;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
    manager = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
  
  modifier onlyManager() {
    require(msg.sender == manager || msg.sender == owner);
    _;
  }

  function transferManagment(address newManager) public onlyOwner {
    require(newManager != address(0));
    manager = newManager;
  }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {

  bool public paused = false;
  bool public finished = false;
  
  modifier whenSaleNotFinish() {
    require(!finished);
    _;
  }

  modifier whenSaleFinish() {
    require(finished);
    _;
  }

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
  }
}

contract CCCRSale is Pausable {
    using SafeMath for uint256;

    address public investWallet = 0xbb2efFab932a4c2f77Fc1617C1a563738D71B0a7;
    CCCRCoin public tokenReward; 
    uint256 public tokenPrice = 723; // 1ETH / 1$
    uint256 zeroAmount = 10000000000; // 10 zero
    uint256 startline = 1510736400; // 15.11.17 12:00
    uint256 public minCap = 300000000000000;
    uint256 public totalRaised = 207038943697300;
    uint256 public etherOne = 1000000000000000000;
    uint256 public minimumTokens = 10;

    function CCCRSale(address _tokenReward) {
        tokenReward = CCCRCoin(_tokenReward);
    }

    function bytesToAddress(bytes source) internal pure returns(address) {
        uint result;
        uint mul = 1;
        for(uint i = 20; i > 0; i--) {
            result += uint8(source[i-1])*mul;
            mul = mul*256;
        }
        return address(result);
    }

    function () whenNotPaused whenSaleNotFinish payable {

      require(msg.value >= etherOne.div(tokenPrice).mul(minimumTokens));
        
      uint256 amountWei = msg.value;        
      uint256 amount = amountWei.div(zeroAmount);
      uint256 tokens = amount.mul(getRate());
      
      if(msg.data.length == 20) {
          address referer = bytesToAddress(bytes(msg.data));
          require(referer != msg.sender);
          referer.transfer(amountWei.div(100).mul(20));
      }
      
      tokenReward.transfer(msg.sender, tokens);
      investWallet.transfer(this.balance);
      totalRaised = totalRaised.add(tokens);

      if (totalRaised >= minCap) {
          finished = true;
      }
    }

    function getRate() constant internal returns (uint256) {
        if      (block.timestamp < startline + 19 days) return tokenPrice.mul(138).div(100);
        else if (block.timestamp <= startline + 46 days) return tokenPrice.mul(123).div(100);
        else if (block.timestamp <= startline + 60 days) return tokenPrice.mul(115).div(100);
        else if (block.timestamp <= startline + 74 days) return tokenPrice.mul(109).div(100);
        return tokenPrice;
    }

    function updatePrice(uint256 _tokenPrice) external onlyManager {
        tokenPrice = _tokenPrice;
    }

    function transferTokens(uint256 _tokens) external onlyManager {
        tokenReward.transfer(msg.sender, _tokens); 
    }

    function newMinimumTokens(uint256 _minimumTokens) external onlyManager {
        minimumTokens = _minimumTokens; 
    }

    function getWei(uint256 _etherAmount) external onlyManager {
        uint256 etherAmount = _etherAmount.mul(etherOne);
        investWallet.transfer(etherAmount); 
    }

    function airdrop(address[] _array1, uint256[] _array2) external whenSaleNotFinish onlyManager {
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