/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable is Context {
    address public owner;
    address payable fund = 0x533b9cA1d7B563E86E87785c02574098Cd00F444;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }


    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title Token
 * @dev API interface for interacting with the WILD Token contract 
 */
interface Token {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address _owner) external returns (uint256 balance);
}

/**
 * @title LavevelICO
 * @dev LavevelICO contract is Ownable
 **/
contract KMLICO is Ownable {
  using SafeMath for uint256;
  Token token;

  uint256 public constant rate = 1000; // Number of tokens per 0.1 BNB
  uint256 public constant CAP = 2000; // Cap in BNB
  
  uint256 public raisedAmount = 0;
  uint256 public rewardPool = 0;
  uint256 public price = 0.1 ether;
  uint64 public ticketMax = 20000;
  uint256 public ticketsBought = 0;
  /**
   * BoughtTokens
   * @dev Log tokens bought onto the blockchain
   */
  event BoughtTokens(address indexed to, uint256 value);

function Start (Token _token)
        public
        payable
    {
        token = _token;
    }

  /**
   * @dev Fallback function if ether is sent to address insted of buyTokens function
   **/
   receive() external payable  {
    buyTokens();
  }
   fallback() external payable {
     buyTokens();
   }

  /**
   * buyTokens
   * @dev function that sells available tokens
   **/
  function buyTokens() payable public {
	require(ticketsBought < ticketMax);
    emit BoughtTokens(msg.sender, rate); // log event onto the blockchain
    raisedAmount = raisedAmount.add(msg.value); // Increment raised amount
	ticketsBought += 1;
    token.transfer(msg.sender, rate); // Send tokens to buyer
    fund.transfer(msg.value);// Send money to owner
  }
}