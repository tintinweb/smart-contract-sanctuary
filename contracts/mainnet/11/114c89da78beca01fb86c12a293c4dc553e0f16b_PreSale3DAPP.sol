pragma solidity ^0.4.16;

interface Token3DAPP {
    function transfer(address receiver, uint amount);
}

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

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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

contract PreSale3DAPP is Pausable {
    using SafeMath for uint256;

    Token3DAPP public tokenReward; 
    uint256 public deadline;

    uint256 public tokenPrice = 10000; // 1 ETH = 10 000 Tokens
    uint256 public minimalETH = 200000000000000000; // minimal = 0.2 ETH

    function PreSale3DAPP(address _tokenReward) {
        tokenReward = Token3DAPP(_tokenReward); // our token address
        deadline = block.timestamp.add(2 weeks); 
    }

    function () whenNotPaused payable {
        buy(msg.sender);
    }

    function buy(address buyer) whenNotPaused payable {
        require(buyer != address(0));
        require(msg.value != 0);
        require(msg.value >= minimalETH);

        uint amount = msg.value;
        uint tokens = amount.mul(tokenPrice);
        tokenReward.transfer(buyer, tokens);
    }

    function transferFund() onlyOwner {
        owner.transfer(this.balance);
    }

    function updatePrice(uint256 _tokenPrice) onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function updateMinimal(uint256 _minimalETH) onlyOwner {
        minimalETH = _minimalETH;
    }

    function transferTokens(uint256 _tokens) onlyOwner {
        tokenReward.transfer(owner, _tokens); 
    }

    // airdrop
    function airdrop(address[] _array1, uint256[] _array2) onlyOwner {
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