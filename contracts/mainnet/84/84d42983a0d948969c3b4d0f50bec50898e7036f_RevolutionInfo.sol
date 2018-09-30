pragma solidity ^0.4.23;



library Percent {
  // Solidity automatically throws when dividing by 0
  struct percent {
    uint num;
    uint den;
  }
  function mul(percent storage p, uint a) internal view returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function div(percent storage p, uint a) internal view returns (uint) {
    return a/p.num*p.den;
  }

  function sub(percent storage p, uint a) internal view returns (uint) {
    uint b = mul(p, a);
    if (b >= a) return 0; // solium-disable-line lbrace
    return a - b;
  }

  function add(percent storage p, uint a) internal view returns (uint) {
    return a + mul(p, a);
  }
}

contract InvestorsStorage {
  function investorFullInfo(address addr) public view returns(uint, uint, uint, uint);
  function investorBaseInfo(address addr) public view returns(uint, uint, uint);
  function investorShortInfo(address addr) public view returns(uint, uint);
  function keyFromIndex(uint i) public view returns (address);
  function size() public view returns (uint);
  function iterStart() public pure returns (uint);
}

contract Revolution {
  function dividendsPercent() public view returns(uint numerator, uint denominator);
  function latestPayout() public view returns(uint timestamp) ;
}

contract RevolutionInfo {
  using Percent for Percent.percent;
  address private owner;
  Revolution public revolution;
  InvestorsStorage public investorsStorage;
  Percent.percent public dividendsPercent;
  
  modifier onlyOwner() {
    require(msg.sender == owner, "access denied");
    _;
  }
  
  constructor() public {
    owner = msg.sender;
  }
  
  function info() public view returns(uint totalInvl, uint debt, uint dailyWithdraw) {
    uint i = investorsStorage.iterStart();
    uint size = investorsStorage.size();
    address addr;
    uint inv;
    uint time;
    uint ref;
    uint latestPayout = revolution.latestPayout();
    
    for (i; i < size; i++) {
      addr = investorsStorage.keyFromIndex(i);
      (inv, time, ref) = investorsStorage.investorBaseInfo(addr);
      if (time == 0) {
        time = latestPayout;
      }
      totalInvl += inv;
      debt += ((now - time) / 24 hours) * dividendsPercent.mul(inv) + ref;
    }
    dailyWithdraw = dividendsPercent.mul(totalInvl);
  }
  
  function setRevolution(address addr) public onlyOwner {
    revolution = Revolution(addr);
    (uint num, uint den) = revolution.dividendsPercent();
    dividendsPercent = Percent.percent(num, den);
  }
  
  function setInvestorsStorage(address addr) public onlyOwner{
    investorsStorage = InvestorsStorage(addr);
  }
}