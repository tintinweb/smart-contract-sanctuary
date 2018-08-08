pragma solidity ^0.4.13;

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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC23ContractInterface {
  function tokenFallback(address _from, uint256 _value, bytes _data) external;
}

contract ERC23Contract is ERC23ContractInterface {

 /**
  * @dev Reject all ERC23 compatible tokens
  * param _from address that is transferring the tokens
  * param _value amount of specified token
  * param _data bytes data passed from the caller
  */
  function tokenFallback(address /*_from*/, uint256 /*_value*/, bytes /*_data*/) external {
    revert();
  }

}

contract EthMatch is Ownable, ERC23Contract {
  using SafeMath for uint256;

  uint256 public constant MASTERY_THRESHOLD = 10 finney; // new master allowed if balance falls below this (10 finney == .01 ETH)
  uint256 public constant PAYOUT_PCT = 95; // % to winner (rest to creator)

  uint256 public startTime; // start timestamp when matches may begin
  address public master; // current Matchmaster
  uint256 public gasReq; // require same gas every time in maker()

  event MatchmakerPrevails(address indexed matchmaster, address indexed matchmaker, uint256 sent, uint256 actual, uint256 winnings);
  event MatchmasterPrevails(address indexed matchmaster, address indexed matchmaker, uint256 sent, uint256 actual, uint256 winnings);
  event MatchmasterTakeover(address indexed matchmasterPrev, address indexed matchmasterNew, uint256 balanceNew);

  // can be funded at init if desired
  function EthMatch(uint256 _startTime) public payable {
    require(_startTime >= now);

    startTime = _startTime;
    master = msg.sender; // initial
    gasReq = 42000;
  }

  // ensure proper state
  modifier isValid(address _addr) {
    require(_addr != 0x0);
    require(!Lib.isContract(_addr)); // ban contracts
    require(now >= startTime);

   _;
  }

  // fallback function
  // make a match
  function () public payable {
    maker(msg.sender);
  }

  // make a match (and specify payout address)
  function maker(address _addr) isValid(_addr) public payable {
    require(msg.gas >= gasReq); // require same gas every time (overages auto-returned)

    uint256 weiPaid = msg.value;
    require(weiPaid > 0);

    uint256 balPrev = this.balance.sub(weiPaid);

    if (balPrev == weiPaid) {
      // maker wins
      uint256 winnings = weiPaid.add(balPrev.div(2));
      pay(_addr, winnings);
      MatchmakerPrevails(master, _addr, weiPaid, balPrev, winnings);
    } else {
      // master wins
      pay(master, weiPaid);
      MatchmasterPrevails(master, _addr, weiPaid, balPrev, weiPaid);
    }
  }

  // send proceeds
  function pay(address _addr, uint256 _amount) internal {
    if (_amount == 0) {
      return; // amount actually could be 0, e.g. initial funding or if balance is totally drained
    }

    uint256 payout = _amount.mul(PAYOUT_PCT).div(100);
    _addr.transfer(payout);

    uint256 remainder = _amount.sub(payout);
    owner.transfer(remainder);
  }

  // become the new master
  function mastery() public payable {
    mastery(msg.sender);
  }

  // become the new master (and specify payout address)
  function mastery(address _addr) isValid(_addr) public payable {
    uint256 weiPaid = msg.value;
    require(weiPaid >= MASTERY_THRESHOLD);

    uint256 balPrev = this.balance.sub(weiPaid);
    require(balPrev < MASTERY_THRESHOLD);

    pay(master, balPrev);

    MatchmasterTakeover(master, _addr, weiPaid); // called before new master set

    master = _addr; // must be set after event logged
  }

  // in case it ever needs to be updated for future Ethereum releases, etc
  function setGasReq(uint256 _gasReq) onlyOwner external {
    gasReq = _gasReq;
  }

  // initial funding
  function fund() onlyOwner external payable {
    require(now < startTime); // otherwise can just call mastery()

    // it is possible that funds can be forced in via selfdestruct, so
    // just ensure balance is enough, at least after receiving this call (msg.value)
    require(this.balance >= MASTERY_THRESHOLD);
  }

  // explicit balance getter
  function getBalance() external constant returns (uint256) {
    return this.balance;
  }

}

library Lib {
  // whether given address is a contract or not based on bytecode
  function isContract(address addr) internal constant returns (bool) {
    uint size;
    assembly {
      size := extcodesize(addr)
    }
    return (size > 1); // testing returned size "1" for non-contract accounts, so we&#39;re using that.
  }
}