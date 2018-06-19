pragma solidity ^0.4.11;

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

contract Crowdsale {
  function buyTokens(address _recipient) payable;
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

contract Preallocation is Ownable {
    using SafeMath for uint;

    address public investor;
    uint public maxBalance;

    enum States { Pending, Success, Fail }
    States public state = States.Pending;

    event InvestorChanged(address from, address to);

    event FundsLoaded(uint value, address from);
    event FundsRefunded(uint balance);

    event InvestmentSucceeded(uint value);
    event InvestmentFailed();


    function Preallocation(address _investor, uint _maxBalance) {
        investor = _investor;
        maxBalance = _maxBalance;
    }

    function () payable {
        if (this.balance > maxBalance) {
          throw;
        }
        FundsLoaded(msg.value, msg.sender);
    }

    function withdraw() onlyOwner notState(States.Success) {
        uint bal = this.balance;
        if (!investor.send(bal)) {
            throw;
        }

        FundsRefunded(bal);
    }

    function setInvestor(address _investor) onlyOwner {
        InvestorChanged(investor, _investor);
        investor = _investor;
    }

    function buyTokens(Crowdsale crowdsale) onlyOwner {
        uint bal = Math.min256(this.balance, maxBalance);
        crowdsale.buyTokens.value(bal)(investor);

        state = States.Success;
        InvestmentSucceeded(bal);
    }

    function setFailed() onlyOwner {
      state = States.Fail;
      InvestmentFailed();
    }

    function stateIs(States _state) constant returns (bool) {
        return state == _state;
    }

    modifier onlyState(States _state) {
        require (state == _state);
        _;
    }

    modifier notState(States _state) {
        require (state != _state);
        _;
    }
}

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}