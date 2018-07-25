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

interface token {
    function transfer(address receiver, uint256 value) external returns(bool);
    function balanceOf(address holder) external constant returns (uint256 balance);
}

// Usage
// 1. create a Vault contract
// 2. transfer tokens to the Vault contract
// 3. call allocateToken()
// 4. Investor can claim() after the duration

contract Vault {

    enum State{Unknown, Loading, Holding, Distributing, Distributed}
    // Loading: Investor data is being loaded and contract not yet locked
    // Holding: Holding tokens for the investor
    // Distributing: Freeze time is over, the investor can claim their tokens
    // Distributed: The investor has already claimed

    using SafeMath for uint256;

    string public name;
    address public owner;
    address public tokenHolder;
    address public investor;
    uint256 public balance;
    uint256 public durationInDays;
    uint256 public freezeEndsAt;
    token public tokenContract;
    bool public claimed;

    event Allocated(address indexed _investor, uint256 value);
    event Distributed(address indexed _investor, uint256 value);
    event Withdrawed(address indexed _owner, uint256 value);

    constructor(string _name, address _tokenContract, address _investor, uint256 _durationInDays, uint256 _amountTokenNoDecimals) public {
        require(_durationInDays > 0);
        require(_amountTokenNoDecimals > 0);
        owner           = msg.sender;
        name            = _name;
        tokenHolder     = this;
        investor        = _investor;
        balance         = _amountTokenNoDecimals.mul(1 ether);
        durationInDays  = _durationInDays;
        freezeEndsAt    = 0;
        tokenContract   = token(_tokenContract);
        claimed         = false;
    }

    function allocateToken(address _investor, uint256 _durationInDays, uint256 _amountTokenNoDecimals) public {
        require(msg.sender == owner);
        require(freezeEndsAt == 0);
        require(investor == _investor);
        require(durationInDays == _durationInDays);
        require(balance == _amountTokenNoDecimals.mul(1 ether));
        require(balance == tokenContract.balanceOf(tokenHolder));
        freezeEndsAt = durationInDays.mul(1 days).add(now);
        emit Allocated(investor, balance);
    }

    function devAllocateTokenInMinutes(address _investor, uint256 _durationInMinutes, uint256 _amountTokenNoDecimals) public {
        require(msg.sender == owner);
        require(freezeEndsAt == 0);
        require(investor == _investor);
        require(durationInDays == _durationInMinutes);
        require(balance == _amountTokenNoDecimals.mul(1 ether));
        require(balance == tokenContract.balanceOf(tokenHolder));
        freezeEndsAt = durationInDays.mul(1 minutes).add(now);
        emit Allocated(investor, balance);
    }
    
    function withdrawToken() public {
        require(msg.sender == owner);
        require(freezeEndsAt == 0);
        uint256 amount = tokenContract.balanceOf(tokenHolder);
        require(amount > 0);
        tokenContract.transfer(owner, amount);
        emit Withdrawed(owner, amount);
    }

    function claim() public {
        require(msg.sender == investor);
        require(claimed == false);
        require(freezeEndsAt != 0);
        require(now > freezeEndsAt);
        tokenContract.transfer(investor, balance);
        claimed = true;
        emit Distributed(investor, balance);
    }

    function getState() public constant returns(State) {
        if(freezeEndsAt == 0) {
            return State.Loading;
        } else if(claimed == true) {
            return State.Distributed;
        } else if(now <= freezeEndsAt) {
            return State.Holding;
        } else {
            return State.Distributing;
        }
    }
}