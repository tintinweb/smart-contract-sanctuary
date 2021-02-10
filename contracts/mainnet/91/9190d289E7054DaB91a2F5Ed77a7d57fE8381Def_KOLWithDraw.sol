/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

pragma solidity ^0.4.23;
/*
 *             ╔═╗┌─┐┌─┐┬┌─┐┬┌─┐┬   ┌─────────────────────────┐ ╦ ╦┌─┐┌┐ ╔═╗┬┌┬┐┌─┐
 *             ║ ║├┤ ├┤ ││  │├─┤│   │ KOL Community Foundation│ │ ║║║├┤ ├┴┐╚═╗│ │ ├┤
 *             ╚═╝└  └  ┴└─┘┴┴ ┴┴─┘ └─┬─────────────────────┬─┘ ╚╩╝└─┘└─┘╚═╝┴ ┴ └─┘
 *   ┌────────────────────────────────┘                     └──────────────────────────────┐
 *   │    ┌─────────────────────────────────────────────────────────────────────────────┐  │
 *   └────┤ Dev:Jack Koe ├─────────────┤ Special for: KOL  ├───────────────┤ 20200513   ├──┘
 *        └─────────────────────────────────────────────────────────────────────────────┘
 */

 library SafeMath {
   function mul(uint a, uint b) internal pure  returns (uint) {
     uint c = a * b;
     require(a == 0 || c / a == b);
     return c;
   }
   function div(uint a, uint b) internal pure returns (uint) {
     require(b > 0);
     uint c = a / b;
     require(a == b * c + a % b);
     return c;
   }
   function sub(uint a, uint b) internal pure returns (uint) {
     require(b <= a);
     return a - b;
   }
   function add(uint a, uint b) internal pure returns (uint) {
     uint c = a + b;
     require(c >= a);
     return c;
   }
   function max64(uint64 a, uint64 b) internal  pure returns (uint64) {
     return a >= b ? a : b;
   }
   function min64(uint64 a, uint64 b) internal  pure returns (uint64) {
     return a < b ? a : b;
   }
   function max256(uint256 a, uint256 b) internal  pure returns (uint256) {
     return a >= b ? a : b;
   }
   function min256(uint256 a, uint256 b) internal  pure returns (uint256) {
     return a < b ? a : b;
   }
 }

 /**
  * title KOL Promotion Withdraw contract
  * dev visit: https://github.com/jackoelv/KOL/
 */

 contract ERC20Basic {
   uint public totalSupply;
   function balanceOf(address who) public constant returns (uint);
   function transfer(address to, uint value) public;
   event Transfer(address indexed from, address indexed to, uint value);
 }

 contract ERC20 is ERC20Basic {
   function allowance(address owner, address spender) public constant returns (uint);
   function transferFrom(address from, address to, uint value) public;
   function approve(address spender, uint value) public;
   event Approval(address indexed owner, address indexed spender, uint value);
 }

 /**
  * title KOL Promotion Withdraw contract
  * dev visit: https://github.com/jackoelv/KOL/
 */

 contract BasicToken is ERC20Basic {

   using SafeMath for uint;

   mapping(address => uint) balances;

   function transfer(address _to, uint _value) public{
     balances[msg.sender] = balances[msg.sender].sub(_value);
     balances[_to] = balances[_to].add(_value);
     emit Transfer(msg.sender, _to, _value);
   }

   function balanceOf(address _owner) public constant returns (uint balance) {
     return balances[_owner];
   }
 }

 /**
  * title KOL Promotion Withdraw contract
  * dev visit: https://github.com/jackoelv/KOL/
 */

 contract StandardToken is BasicToken, ERC20 {
   mapping (address => mapping (address => uint)) allowed;
   uint256 public userSupplyed;

   function transferFrom(address _from, address _to, uint _value) public {
     balances[_to] = balances[_to].add(_value);
     balances[_from] = balances[_from].sub(_value);
     allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
     emit Transfer(_from, _to, _value);
   }

   function approve(address _spender, uint _value) public{
     require((_value == 0) || (allowed[msg.sender][_spender] == 0)) ;
     allowed[msg.sender][_spender] = _value;
     emit Approval(msg.sender, _spender, _value);
   }

   function allowance(address _owner, address _spender) public constant returns (uint remaining) {
     return allowed[_owner][_spender];
   }
 }
 contract KOL is StandardToken {
   function queryNode(address _addr) public view returns(bool);
   function querySuperNode(address _addr) public view returns(bool);
 }
 contract KOLP is StandardToken {

   address public draw;
   bool public going;
   struct lock{
     uint256 begin;
     uint256 amount;
     uint256 end;
     bool withDrawed;
   }
   struct teamRate{
     uint8 rate;
     uint256 changeTime;

   }
   struct inviteBonus{
     uint256 begin;
     uint256 dayBonus;
     uint256 hisTotalBonus;
   }
   struct withDraws{
     uint256 time;
     uint256 amount;
   }
   struct dayTeamBonus{
     uint256 theDayLastSecond;
     uint256 theDayTeamBonus;
     uint256 totalTeamBonus;
     uint8 theDayRate;
   }
   struct dayInviteBonus{
     uint256 theDayLastSecond;
     uint256 theDayInviteBonus;
     uint256 totalInviteBonus;
   }
   mapping (address => dayTeamBonus[]) public LockTeamBonus;
   mapping (address => dayInviteBonus[]) public LockInviteBonus;


   mapping (address => address[]) public InviteList;
   mapping (address => address[]) public ChildAddrs;
   mapping (address => lock[]) public LockHistory;
   mapping (address => uint256) public LockBalance;

   mapping (address => uint256) public InviteHistoryBonus;
   mapping (address => uint256) public InviteCurrentDayBonus;

   mapping (uint256 => uint256) public ClosePrice;
   mapping (address => uint256) public TotalUsers;
   mapping (address => uint256) public TotalLockingAmount;
   mapping (uint256 => address) public InviteCode;
   mapping (address => uint256) public RInviteCode;

   mapping (address => uint8) public isLevelN;
   mapping (uint8 => uint8) public levelRate;
   mapping (address => bool) public USDTOrCoin;

   //GAS优化
   modifier onlyContract {
       require(msg.sender == draw);
       _;
   }
   function qsLevel(address _addr) onlyContract public ;
   /* function queryAndSetLevelN(address _addr) public; */
   function queryLockBalance(address _addr,uint256 _queryTime) public view returns(uint256);
   function getYestodayLastSecond(uint256 _queryTime) public view returns(uint256);
   function clearLock(address _addr) onlyContract public ;
   function pushInvite(address _addr,
                       uint256 _theDayLastSecond,
                       uint256 _theDayInviteBonus,
                       uint256 _totalInviteBonus) onlyContract public ;
   function setLastInvite(address _addr,
                       uint256 _theDayInviteBonus,
                       uint256 _totalInviteBonus) onlyContract public ;
   function pushTeam(address _addr,
                       uint256 _theDayLastSecond,
                       uint256 _theDayTeamBonus,
                       uint256 _totalTeamBonus,
                       uint8 _theDayRate) onlyContract public ;
   function setLastTeam(address _addr,
                       uint256 _theDayTeamBonus,
                       uint256 _totalTeamBonus,
                       uint8 _theDayRate) onlyContract public ;

   function subTotalUsers(address _addr) onlyContract public ;
   function subTotalLockingAmount(address _addr,uint256 _amount) onlyContract public ;
   function subTotalBalance(uint256 _amount) onlyContract public ;
   function setInviteTeam(address _addr) onlyContract public ;
   function getLockLen(address _addr) public view returns(uint256);
   function getFathersLength(address _addr) public view returns(uint256);
   function getLockTeamBonusLen(address _addr) public view returns(uint256);
   function getLockInviteBonusLen(address _addr) public view returns(uint256);

}

 /**
  * title KOL Promotion Withdraw contract
  * dev visit: https://github.com/jackoelv/KOL/
 */

 contract Ownable {
     address public owner;

     constructor() public{
         owner = msg.sender;
     }

     modifier onlyOwner {
         require(msg.sender == owner);
         _;
     }
     function transferOwnership(address newOwner) onlyOwner public{
         if (newOwner != address(0)) {
             owner = newOwner;
         }
     }
 }
 /**
  * title KOL Promotion Withdraw contract
  * dev visit: https://github.com/jackoelv/KOL/
 */
contract KOLWithDraw is Ownable{
  using SafeMath for uint256;
  string public name = "KOL Withdraw";
  KOL public kol;
  KOLP public kolp;

  uint256 public every = 1 days;
  uint256 public minBonus = 30 * (10 ** 18);
  uint256 public leftBonus = 0;
  address public reciever;
  uint256 public etherFee = 0.005 ether;
  uint8 public fee = 5;


  struct dayTeamBonus{
    uint256 theDayLastSecond;
    uint256 theDayTeamBonus;
    uint256 totalTeamBonus;
    uint8 theDayRate;
  }
  struct dayInviteBonus{
    uint256 theDayLastSecond;
    uint256 theDayInviteBonus;
    uint256 totalInviteBonus;
  }

  mapping (address => uint256) public TotalWithDraws;

  mapping (address => uint256) public DrawTime;
  event WithDrawed(address _user,uint256 _amount);

  constructor(address _kolAddress,address _kolpAddress,address _reciever) public {
    kol = KOL(_kolAddress);
    kolp = KOLP(_kolpAddress);
    reciever = _reciever;
  }

  function querySelfBonus(address _addr) public view returns(uint256){
    uint256 len = kolp.getLockLen(_addr);
    uint256 selfBonus;
    if(len >0){
      uint256 begin;
      uint256 end;
      uint256 amount;
      bool withDrawed;
      for (uint i=0; i<len; i++){
        (begin,amount,end,withDrawed) = kolp.LockHistory(_addr,i);
        if (!withDrawed){
          if (DrawTime[_addr] > begin) begin = DrawTime[_addr];
          uint256 lastingDays = (kolp.getYestodayLastSecond(now) - kolp.getYestodayLastSecond(begin)) / every;
          if (kolp.USDTOrCoin(_addr)){
            begin = kolp.getYestodayLastSecond(begin) + every;
            for (uint j=0;j<lastingDays;j++){
              uint256 theTime = begin + j*every;
              selfBonus += amount * 3 / 1000 * kolp.ClosePrice(begin) / kolp.ClosePrice(theTime);
            }
          }else{
            selfBonus += lastingDays * amount * 3 / 1000;
          }
        }
      }
    }
    return (selfBonus);

  }

  function queryInviteBonus(address _addr) public view returns(uint256){
    uint256 last = kolp.getLockInviteBonusLen(_addr);
    if(last>0){
      uint256 yestodayLastSecond = kolp.getYestodayLastSecond(now);
      uint256 lastingDays;
      uint256 newDayInviteTotalBonus;
      dayInviteBonus memory theDayIB = dayInviteBonus(0,0,0);
      while(last>=1){
        (theDayIB.theDayLastSecond,theDayIB.theDayInviteBonus,theDayIB.totalInviteBonus) = kolp.LockInviteBonus(_addr,last-1);
        last--;
        if (theDayIB.theDayLastSecond <= yestodayLastSecond){
          lastingDays = (yestodayLastSecond - theDayIB.theDayLastSecond) / every;
          newDayInviteTotalBonus = (lastingDays * theDayIB.theDayInviteBonus) + theDayIB.totalInviteBonus;
          return (newDayInviteTotalBonus);
        }
      }
      return 0;
    }else
      return 0;
  }
  function queryTeamBonus(address _addr) public view returns(uint256){
    uint256 last = kolp.getLockTeamBonusLen(_addr);
    if(last>0){
      uint256 yestodayLastSecond = kolp.getYestodayLastSecond(now);
      uint256 lastingDays;
      uint256 newDayTeamTotalBonus;
      dayTeamBonus memory theDayTB =dayTeamBonus(0,0,0,0);
      while(last>=1){
        (theDayTB.theDayLastSecond,theDayTB.theDayTeamBonus,theDayTB.totalTeamBonus,theDayTB.theDayRate) = kolp.LockTeamBonus(_addr,last-1);
        last--;
        if (theDayTB.theDayLastSecond <= yestodayLastSecond){
          lastingDays = (yestodayLastSecond - theDayTB.theDayLastSecond) / every;
          newDayTeamTotalBonus = (lastingDays * theDayTB.theDayTeamBonus * theDayTB.theDayRate / 100 ) + theDayTB.totalTeamBonus;
          return (newDayTeamTotalBonus);
        }
      }
      return 0;
    }else
      return 0;

  }
  function afterWithdraw(address _addr,uint256 _amount) private {
    address father;
    uint256 fathersLen = kolp.getFathersLength(_addr);
    for (uint i = 0; i<fathersLen; i++){
      father = kolp.InviteList(_addr,i);
      kolp.subTotalUsers(father);
      kolp.subTotalLockingAmount(father,_amount);
      kolp.qsLevel(father);
      kolp.setInviteTeam(_addr);
    }

  }
  function withdraw(bool _onlyBonus) payable public{
    //true: bonus;false:balance & bonus;
    require(msg.value >= etherFee);
    uint256 bonus = querySelfBonus(msg.sender);
    DrawTime[msg.sender] = now;
    uint256 last = kolp.getLockInviteBonusLen(msg.sender);
    uint256 yestodayLastSecond = kolp.getYestodayLastSecond(now);
    uint256 lastingDays;

    if(last>0){
      dayInviteBonus memory theDayIB = dayInviteBonus(0,0,0);
      uint256 realLast = last;
      while(realLast>=1){
        (theDayIB.theDayLastSecond,theDayIB.theDayInviteBonus,theDayIB.totalInviteBonus) = kolp.LockInviteBonus(msg.sender,realLast-1);
        realLast--;
        if (theDayIB.theDayLastSecond <= yestodayLastSecond){
          lastingDays = (yestodayLastSecond - theDayIB.theDayLastSecond) / every;
          bonus += (lastingDays * theDayIB.theDayInviteBonus) + theDayIB.totalInviteBonus;
          if(theDayIB.theDayLastSecond < yestodayLastSecond){
            kolp.pushInvite(msg.sender,yestodayLastSecond,theDayIB.theDayInviteBonus,0);
          }else if(theDayIB.theDayLastSecond == yestodayLastSecond){
            kolp.setLastInvite(msg.sender,theDayIB.theDayInviteBonus,0);
          }
        }
      }
    }

    last = kolp.getLockTeamBonusLen(msg.sender);

    if(last>0){
      dayTeamBonus memory theDayTB =dayTeamBonus(0,0,0,0);
      while(last>=1){
        (theDayTB.theDayLastSecond,theDayTB.theDayTeamBonus,theDayTB.totalTeamBonus,theDayTB.theDayRate) = kolp.LockTeamBonus(msg.sender,last-1);
        last--;
        if (theDayTB.theDayLastSecond <= yestodayLastSecond){
          lastingDays = (yestodayLastSecond - theDayTB.theDayLastSecond) / every;
          bonus += (lastingDays * theDayTB.theDayTeamBonus * theDayTB.theDayRate / 100 ) + theDayTB.totalTeamBonus;
          if(theDayTB.theDayLastSecond < yestodayLastSecond){
            kolp.pushTeam(msg.sender,yestodayLastSecond,theDayTB.theDayTeamBonus,0,theDayTB.theDayRate);
          }else if(theDayTB.theDayLastSecond == yestodayLastSecond){
            kolp.setLastTeam(msg.sender,theDayTB.theDayTeamBonus,0,theDayTB.theDayRate);
          }
        }
      }

    }
    uint256 realBonus = bonus;
    if (leftBonus == 0){
      _onlyBonus = false;
      realBonus =0;
    }else if(bonus >= leftBonus){
      realBonus = leftBonus;
    }
    uint256 subLeft = realBonus;
    /* leftBonus = leftBonus.sub(realBonus); */
    uint256 tax = realBonus*fee/100;
    realBonus = realBonus.sub(tax);

    if (!_onlyBonus){
      uint256 balance = kolp.LockBalance(msg.sender);
      if (bonus < minBonus){
        realBonus = balance;
        tax = 0;
        subLeft = 0;
      }else{
        realBonus += balance;
      }
      kolp.subTotalBalance(balance);
      kolp.clearLock(msg.sender);
      afterWithdraw(msg.sender,balance);

    }else{
      require(bonus >= minBonus);
    }
    if (realBonus > 0) {
      kol.transfer(msg.sender,realBonus);
      TotalWithDraws[msg.sender] += realBonus;
      emit WithDrawed(msg.sender,realBonus);
    }
    if (tax > 0) kol.transfer(reciever,tax);
    leftBonus = leftBonus.sub(subLeft);

  }
  function calcuAllBonus(bool _onlyBonus) public view returns(uint256){
    //true: Only Bonus;false: balance & bonus;
    uint256 bonus = querySelfBonus(msg.sender);
    bonus += queryInviteBonus(msg.sender);
    bonus += queryTeamBonus(msg.sender);
    if (leftBonus == 0){
      bonus =0;
    }else if(bonus >= leftBonus){
      bonus = leftBonus;
    }
    bonus = bonus * (100-fee) /100;

    if (!_onlyBonus){
      uint256 balance = kolp.LockBalance(msg.sender);
      bonus += balance;
    }
    return bonus;
  }
  function addBonus(uint256 _amount) onlyOwner public{
    leftBonus = leftBonus.add(_amount);
  }
  function setFee(uint8 _fee) onlyOwner public{
    fee = _fee;
  }
  function setKOLP(address _paddr) onlyOwner public{
    kolp = KOLP(_paddr);
  }
  function draw() onlyOwner public{
    reciever.send(address(this).balance);
  }
  function setetherFee(uint256 _fee) onlyOwner public{
    etherFee = _fee;
  }
  function setReciever(address _reciever) onlyOwner public{
    reciever = _reciever;
  }
}