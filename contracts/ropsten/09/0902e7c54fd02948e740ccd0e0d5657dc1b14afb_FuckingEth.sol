pragma solidity 0.4.25;


contract FuckingEth {
  using SafeMath for uint;

  struct Investor {
    uint deposit;
    uint paymentTime;
    uint withdrawal;
    uint FuckStartup;
    bool isParticipant;
  }

  mapping (address => Investor) public investors;
  address public admin1Address;
  address public admin2Address;
  address public owner;
  uint public investmentsNumber;
  uint public investorsNumber;

  modifier onlyOwner() {
    require(msg.sender == owner, "access denied");
    _;
  }

  event OnRefLink(address indexed referral, uint referrarBonus, address indexed referrer,  uint referrerBonus, uint time);
  event OnNewInvestor(address indexed addr, uint time);
  event OnInvesment(address indexed addr, uint deposit, uint time);
  event OnFuckChanged(address indexed addr, bool isActive, uint time);
  event OnEarlyWithdrawal(address indexed addr, uint withdrawal, uint time);
  event OnDeleteInvestor(address indexed addr, uint time);
  event OnWithdraw(address indexed addr, uint withdrawal, uint time);
  event OnFuckBonus(address indexed addr, uint bonus, uint time);
  event OnNotEnoughBalance(uint time);

  constructor() public {
    owner = msg.sender;
    admin1Address = msg.sender;
    admin2Address = msg.sender;
     }

  function() external payable {
    if (msg.value == 0) {
      withdraw();
    } else if (msg.value == 0.01 ether) {
      Fuck();
    } else if (msg.value == 0.003 ether) {
      earlyWithdrawal();
    } else {
      deposit(bytes2address(msg.data));
    }
  }

  function disown() public onlyOwner {
    owner = address(0x0);
  }

  function setAdminsAddress(uint n, address addr) public onlyOwner {
    require(n >= 1 && n <= 2, "invalid number of admin`s address");
    if (n == 1) {
      admin1Address = addr;
    } else if (n == 2) {
      admin2Address = addr;
    } 
  }

  function investorDividends(address investorAddr) public view returns(uint dividends, uint FuckBonus) {
    return getDividends(investorAddr);
  }

  function withdraw() public {
    address investorAddr = msg.sender;
    (uint dividends, uint FuckBonus) = getDividends(investorAddr);
    require(dividends > 0, "cannot to pay zero dividends");
    require(address(this).balance > 0, "fund is empty");
    uint withdrawal = dividends + FuckBonus;

    // fund limit
    if (address(this).balance <= withdrawal) {
      emit OnNotEnoughBalance(now);
      withdrawal = address(this).balance;
    }

    Investor storage investor = investors[investorAddr];
    uint withdrawalLimit = investor.deposit * 199 / 100; // 199%
    uint totalWithdrawal = withdrawal + investor.withdrawal;

    // withdrawal limit - 199%
    if (totalWithdrawal >= withdrawalLimit) {
      withdrawal = withdrawalLimit.sub(investor.withdrawal);
      if (FuckBonus > 0 ) {
        emit OnFuckBonus(investorAddr, FuckBonus, now);
      }
      deleteInvestor(investorAddr);
    } else {
      // normal withdraw - dont use FuckBonus
      if (withdrawal > dividends) {
        withdrawal = dividends;
      }
      investor.withdrawal += withdrawal;
      investor.paymentTime = now;
      if (investor.FuckStartup > 0) {
        investor.FuckStartup = 0;
        emit OnFuckChanged(investorAddr, false, now);
      }
    }

    investorAddr.transfer(withdrawal);
    emit OnWithdraw(investorAddr, withdrawal, now);
  }

  function earlyWithdrawal() public {
    address investorAddr = msg.sender;
    Investor storage investor = investors[investorAddr];
    require(investor.deposit > 0, "sender must be an investor");

    uint earlyWithdrawalLimit = investor.deposit * 75 / 100; // 75%
    require(earlyWithdrawalLimit > investor.withdrawal, "early withdraw only before 75% deposit`s withdrawal");

    uint withdrawal = earlyWithdrawalLimit.sub(investor.withdrawal); 
    investorAddr.transfer(withdrawal);
    emit OnEarlyWithdrawal(investorAddr, withdrawal, now);

    deleteInvestor(investorAddr);
  }

  function Fuck() public {
    Investor storage investor = investors[msg.sender];
    require(investor.deposit > 0, "sender must be an investor");
    require(investor.FuckStartup == 0, "Fucking is already activated");
    investor.FuckStartup = now;
    emit OnFuckChanged(msg.sender, true, now);
  }

  function deposit(address referrerAddr) public payable {
    uint depositAmount = msg.value;
    address investorAddr = msg.sender;
    require(isNotContract(investorAddr), "invest from contracts is not supported");
    require(depositAmount > 0, "deposit amount cannot be zero");

    admin1Address.send(depositAmount * 60 / 1000); //   6%
    admin2Address.send(depositAmount * 20 / 1000); //   2%

    Investor storage investor = investors[investorAddr];
    bool senderIsNotPaticipant = !investor.isParticipant;
    bool referrerIsParticipant = investors[referrerAddr].isParticipant;

    // ref link
    if (senderIsNotPaticipant && referrerIsParticipant && referrerAddr != investorAddr) {
      uint referrerBonus = depositAmount * 4 / 100; // 4%
      uint referralBonus = depositAmount * 3 / 100; // 3%
      referrerAddr.transfer(referrerBonus);
      investorAddr.transfer(referralBonus);
      emit OnRefLink(investorAddr, referralBonus, referrerAddr, referrerBonus, now);
    }

    if (investor.deposit == 0) {
      investorsNumber++;
      investor.isParticipant = true;
      emit OnNewInvestor(investorAddr, now);
    }

    investor.deposit += depositAmount;
    investor.paymentTime = now;

    investmentsNumber++;
    emit OnInvesment(investorAddr, depositAmount, now);
  }

  function getDividends(address investorAddr) internal view returns(uint dividends, uint FuckBonus) {
    Investor storage investor = investors[investorAddr];
    if (investor.deposit == 0) {
      return (0, 0);
    }

    if (investor.FuckStartup > 0) {
      uint FuckDays = now.sub(investor.FuckStartup).div(24 hours);
      FuckBonus = FuckDays * investor.deposit * 500 / 100000; // 0.5%
    }

    uint depositDays = now.sub(investor.paymentTime).div(24 hours);
    dividends = depositDays * investor.deposit * 1 / 100; // 1%

    uint depositAmountBonus;
    if (1 ether <= investor.deposit && investor.deposit <= 10 ether) {
      depositAmountBonus = depositDays * investor.deposit * 5 / 10000; // 0.05%
    } else if (10 ether <= investor.deposit && investor.deposit <= 25 ether) {
      depositAmountBonus = depositDays * investor.deposit * 11 / 10000; // 0.11%
    } else if (25 ether <= investor.deposit)  {
      depositAmountBonus = depositDays * investor.deposit * 15 / 10000; // 0.15% 
    
   } dividends += depositAmountBonus;
  }

  function isNotContract(address addr) internal view returns (bool) {
    uint length;
    assembly { length := extcodesize(addr) }
    return length == 0;
  }

  function bytes2address(bytes memory source) internal pure returns(address addr) {
    assembly { addr := mload(add(source, 0x14)) }
    return addr;
  }

  function deleteInvestor(address investorAddr) private {
    delete investors[investorAddr].deposit;
    delete investors[investorAddr].paymentTime;
    delete investors[investorAddr].withdrawal;
    delete investors[investorAddr].FuckStartup;
    emit OnDeleteInvestor(investorAddr, now);
    investorsNumber--;
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }


  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }


  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
    * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}