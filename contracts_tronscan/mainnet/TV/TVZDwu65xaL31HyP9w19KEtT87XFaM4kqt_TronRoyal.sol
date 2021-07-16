//SourceUnit: TronRoyal.sol

pragma solidity ^0.5.4;

contract TronRoyal {

  using SafeMath for uint;

  struct User {
    uint32 level1;
    uint32 level2;
    uint32 level3;
    uint32 level4;
    uint32 level5;
    uint64 refLink;
    uint64 inviterLink;
    uint investment;
    uint timestamp;
    uint balance;
    uint totalRefReward;
    uint payout;
    address payable inviter;
  }

  uint[] public refReward;
  uint public ownersPart;

  address payable public owner;
  uint public totalUsers;
  uint public minDeposit;
  uint64 public lastRefLink;
  uint public rateDivider;
  mapping (address => User) public users;
  mapping (uint64 => address payable) public links;

  uint public totalInvested;

  constructor() public {
    links[1] = msg.sender;
    totalUsers = 0;
    totalInvested = 0;
    owner = msg.sender;
    minDeposit = 30 trx;
    refReward = [ 15, 4, 3, 2, 1];
    ownersPart = 5;
    lastRefLink = 15555;
    rateDivider = 345600;
  }

  modifier restricted() {
    require(msg.sender == owner);
    _;
  }

  function changeOwner(address payable newOwner) public restricted {
    owner = newOwner;
    links[1] = newOwner;
  }

  function setRefLink(uint64 refLink) public returns (uint64) {
    User storage user = users[msg.sender];
    if (user.refLink != 0) return 0;

    lastRefLink = lastRefLink + 1;
    user.refLink = lastRefLink;
    links[lastRefLink] = msg.sender;

    setInviter(msg.sender, refLink);
    return lastRefLink;
  }

  function setInviter(address payable addr, uint64 refLink) private {
    User storage user = users[addr];
    address payable inviter1 = links[refLink] == address(0x0) ||
     links[refLink] == msg.sender ? owner : links[refLink];
    user.inviter = inviter1;
    user.inviterLink = inviter1 == owner ? 1 : refLink;

    address payable inviter2 = users[inviter1].inviter;
    address payable inviter3 = users[inviter2].inviter;
    address payable inviter4 = users[inviter3].inviter;
    address payable inviter5 = users[inviter4].inviter;
    
    users[inviter1].level1++;
    users[inviter2].level2++;
    users[inviter3].level3++;
    users[inviter4].level4++;
    users[inviter5].level5++;
  }

  function checkout(address payable addr) private {
    User storage user = users[addr];

    uint secondsGone = now.sub(user.timestamp);
    if (secondsGone == 0 || user.timestamp == 0) return;

    uint profit = user.investment.mul(secondsGone).div(rateDivider);
    user.balance = user.balance.add(profit);
    user.timestamp = user.timestamp.add(secondsGone);
  }

  function refSpreader(address payable inviter1, uint amount) private {
    address payable inviter2 = users[inviter1].inviter;
    address payable inviter3 = users[inviter2].inviter;
    address payable inviter4 = users[inviter3].inviter;
    address payable inviter5 = users[inviter4].inviter;

    uint refSum = refReward[0] + refReward[1] + refReward[2] + refReward[3] + refReward[4];

    if (inviter1 != address(0x0)) {
      refSum = refSum.sub(refReward[0]);
      uint reward1 = amount.mul(refReward[0]).div(100);
      users[inviter1].totalRefReward = users[inviter1].totalRefReward.add(reward1);
      inviter1.transfer(reward1);
    }

    if (inviter2 != address(0x0)) {
      refSum = refSum.sub(refReward[1]);
      uint reward2 = amount.mul(refReward[1]).div(100);
      users[inviter2].totalRefReward = users[inviter2].totalRefReward.add(reward2);
      inviter2.transfer(reward2);
    }

    if (inviter3 != address(0x0)) {
      refSum = refSum.sub(refReward[2]);
      uint reward3 = amount.mul(refReward[2]).div(100);
      users[inviter3].totalRefReward = users[inviter3].totalRefReward.add(reward3);
      inviter3.transfer(reward3);
    }

    if (inviter4 != address(0x0)) {
      refSum = refSum.sub(refReward[3]);
      uint reward4 = amount.mul(refReward[3]).div(100);
      users[inviter4].totalRefReward = users[inviter4].totalRefReward.add(reward4);
      inviter4.transfer(reward4);
    }

    if (inviter5 != address(0x0)) {
      refSum = refSum.sub(refReward[4]);
      uint reward5 = amount.mul(refReward[4]).div(100);
      users[inviter5].totalRefReward = users[inviter5].totalRefReward.add(reward5);
      inviter5.transfer(reward5);
    }

    if (refSum == 0) return;
    owner.transfer(amount.mul(refSum).div(100));
  }

  function deposit(uint64 refLink) public payable {
    require(msg.value >= minDeposit);
    require(now > 1594224000);

    checkout(msg.sender);
    User storage user = users[msg.sender];
    if (user.refLink == 0) {
      setRefLink(refLink);
    }

    if (user.timestamp == 0) {
      totalUsers++;
      user.timestamp = now;
      if (user.inviter == address(0x0)) {
        setInviter(msg.sender, refLink);
      }
    }

    refSpreader(user.inviter, msg.value);

    totalInvested = totalInvested.add(msg.value);
    user.investment = user.investment.add(msg.value);
    owner.transfer(msg.value.mul(ownersPart).div(100));
  }

  function reinvest() public payable {
    require(now > 1594224000);
    checkout(msg.sender);
    User storage user = users[msg.sender];
    require(user.balance > 0);
    uint amount = user.balance;
    user.balance = 0;
    user.investment = user.investment.add(amount);

    refSpreader(user.inviter, amount);
    totalInvested = totalInvested.add(msg.value);
    owner.transfer(amount.mul(ownersPart).div(100));
  }

  // no separate withdraws like trondivs scam has :)))
  function withdraw() public payable {
    checkout(msg.sender);
    User storage user = users[msg.sender];
    require(user.balance > 0);

    uint amount = user.balance;
    user.payout = user.payout.add(amount);
    user.balance = 0;
    msg.sender.transfer(amount);
  }

  function () external payable { }  

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}