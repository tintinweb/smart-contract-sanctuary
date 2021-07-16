//SourceUnit: contract.sol

// Our website: https://trx.wtf

pragma solidity 0.4.25;

contract trxwtf {

  using SafeMath for uint;

  uint public RELEASE_TIME;
  uint RATE_PER_DECADE = 278;
  uint8 PAYOUTS_FOR_STEP = 6;

  uint ADMIN_PERCENT = 10;
  uint REF_PERCENT = 10;

  address owner;

  uint public iterator = 0;
  uint public totalInvested = 0;

  struct Invest {
    uint id;
    uint lastPayout;
    uint invested;
    uint balance;
    uint withdrawn;
    uint refReward;
  }
  mapping(address => Invest) public investors;

  address[] public investorAddresses;

  constructor() public {
    RELEASE_TIME = now;
    owner = msg.sender;
    investorAddresses.push(owner);
    investors[owner].invested = 1;
    investors[owner].lastPayout = now;
    investors[owner].id = 0;
  }

  function totalInvestors() public view returns (uint) {
      return investorAddresses.length;
  }

  function minInvest() public view returns(uint) {
    uint balance = address(msg.sender).balance;
    if (balance < 20000000) return 0;
    return balance.sub(20000000);
  }

  function earned(address investorAddress) public view returns(uint) {
    uint balance = investors[investorAddress].balance;

    uint userInvested = investors[investorAddress].invested;
    uint userRate = userInvested.mul(RATE_PER_DECADE).div(1000000);
    uint decadesPassed = now.sub(investors[investorAddress].lastPayout).div(600);
    uint currentEarn = userRate.mul(decadesPassed).add(balance);

    uint refReward = investors[investorAddress].refReward;
    uint maxAvailable = userInvested.mul(130).div(100).add(refReward);
    if (investors[investorAddress].withdrawn.add(currentEarn) > maxAvailable) {
      currentEarn = maxAvailable.sub(investors[investorAddress].withdrawn);
    }

    return currentEarn;
  }

  function deposit(uint ref) external payable {
    require(msg.value >= 10000000);
    require(msg.value >= minInvest(), 'You have to invest all your money');

    msg.sender.transfer(msg.value.div(10));
    uint id = totalInvestors();
    address refAddress = investorAddresses[ref];
    if (refAddress == msg.sender) {
      refAddress = owner;
    }
    investors[refAddress].balance = msg.value.mul(REF_PERCENT).div(100).add(investors[refAddress].balance);
    investors[refAddress].refReward = msg.value.mul(REF_PERCENT).div(100).add(investors[refAddress].refReward);
    investors[owner].balance = msg.value.mul(ADMIN_PERCENT).div(100).add(investors[owner].balance);
    investors[owner].refReward = msg.value.mul(ADMIN_PERCENT).div(100).add(investors[owner].refReward);
    
    if (now > RELEASE_TIME.add(259200)) {
      for (uint i = 0; i < PAYOUTS_FOR_STEP; i++) {
        uint investorID = iterator * PAYOUTS_FOR_STEP + i;
        if (investorID >= id) break;
        address receiver = investorAddresses[investorID];
        uint payoutValue = earned(receiver);
        if (address(this).balance < payoutValue) {
          payoutValue = address(this).balance;
        }
        if (payoutValue == 0) continue;
        investors[receiver].lastPayout = now;
        investors[receiver].balance = 0;
        investors[receiver].withdrawn = investors[receiver].withdrawn.add(payoutValue);
        receiver.transfer(payoutValue);
      }
      iterator = iterator.add(1);
      if (iterator.add(1).mul(PAYOUTS_FOR_STEP) > id) {
        iterator = 0;
      }
    }

    if (investors[msg.sender].invested > 0) {
      investors[msg.sender].balance = earned(msg.sender);
      investors[msg.sender].invested = investors[msg.sender].invested.add(msg.value);
      investors[msg.sender].withdrawn = investors[msg.sender].withdrawn.add(msg.value.div(10));
    } else {
      investorAddresses.push(msg.sender);
      investors[msg.sender].invested = msg.value;
      investors[msg.sender].lastPayout = now;
      investors[msg.sender].balance = 0;
      investors[msg.sender].withdrawn = msg.value.div(10);
      investors[msg.sender].id = id;
    }
    totalInvested += msg.value;
  }
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }
}