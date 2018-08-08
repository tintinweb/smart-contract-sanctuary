pragma solidity ^0.4.13;

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

contract PreIco is Ownable {
    using SafeMath for uint;

    uint public decimals = 18;

    uint256 public initialSupply = 4000000 * 10 ** decimals;  // 4 milions XCC

    uint256 public remainingSupply = initialSupply;

    uint256 public tokenValue;  // value in wei

    address public updater;  // account in charge of updating the token value

    uint256 public startBlock;  // block number of contract deploy

    uint256 public endTime;  // seconds from 1970-01-01T00:00:00Z

    function PreIco(uint256 initialValue, address initialUpdater, uint256 end) {
        tokenValue = initialValue;
        updater = initialUpdater;
        startBlock = block.number;
        endTime = end;
    }

    event UpdateValue(uint256 newValue);

    function updateValue(uint256 newValue) {
        require(msg.sender == updater || msg.sender == owner);
        tokenValue = newValue;
        UpdateValue(newValue);
    }

    function updateUpdater(address newUpdater) onlyOwner {
        updater = newUpdater;
    }

    function updateEndTime(uint256 newEnd) onlyOwner {
        endTime = newEnd;
    }

    event Withdraw(address indexed to, uint value);

    function withdraw(address to, uint256 value) onlyOwner {
        to.transfer(value);
        Withdraw(to, value);
    }

    modifier beforeEndTime() {
        require(now < endTime);
        _;
    }

    event AssignToken(address indexed to, uint value);

    function () payable beforeEndTime {
        require(remainingSupply > 0);
        address sender = msg.sender;
        uint256 value = msg.value.mul(10 ** decimals).div(tokenValue);
        if (remainingSupply >= value) {
            AssignToken(sender, value);
            remainingSupply = remainingSupply.sub(value);
        } else {
            AssignToken(sender, remainingSupply);
            remainingSupply = 0;
        }
    }
}