pragma solidity 0.4.21;

// Wolf Crypto presale pooling contract
// written by @iamdefinitelyahuman

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface ERC20 {
  function balanceOf(address _owner) external returns (uint256 balance);
  function transfer(address _to, uint256 _value) external returns (bool success);
}

interface WhiteList {
   function checkMemberLevel (address addr) external view returns (uint);
}

library PresaleLib {
	
  using SafeMath for uint;
  
  WhiteList constant whitelistContract = WhiteList(0x8D95B038cA80A986425FA240C3C17Fb2B6e9bc63);
  uint constant contributionMin = 100000000000000000;
  uint constant maxGasPrice = 50000000000;
  
  struct Contributor {
    uint16 claimedTokensIndex;
    uint balance;
  }
  
  struct Data {
    address owner;
    address receiver;
    address[] withdrawToken;
    bool poolSubmitted;
    bool locked;
    uint addressSetTime;
    uint fee;
    uint contractCap;
    uint finalBalance;
    uint[] withdrawAmount;
    uint[] capAmounts;
    uint32[] capTimes;
    mapping (address => uint) tokenBalances;
    mapping (address => uint) individualCaps;
    mapping (address => Contributor) contributorMap;
  }
  
  event ContributorBalanceChanged (address contributor, uint totalBalance);
  event ReceiverAddressSet ( address addr);
  event PoolSubmitted (address receiver, uint amount);
  event WithdrawalAvailable (address token);
  event WithdrawalClaimed (address receiver, address token, uint amount);
  
  modifier onlyOwner (Data storage self) {
    require (msg.sender == self.owner);
    _;
  }
  
  modifier noReentrancy(Data storage self) {
    require(!self.locked);
    self.locked = true;
    _;
    self.locked = false;
  }
  
  function _toPct (uint numerator, uint denominator ) internal pure returns (uint) {
    return numerator.mul(10 ** 20).div(denominator);
  }
  
  function _applyPct (uint numerator, uint pct) internal pure returns (uint) {
    return numerator.mul(pct).div(10 ** 20);
  }
  
  function newPool (Data storage self, uint _fee, address _receiver, uint _contractCap, uint _individualCap) public {
    require (_fee < 1000);
    self.owner = msg.sender;
    self.receiver = _receiver;
    self.contractCap = _contractCap;
    self.capTimes.push(0);
    self.capAmounts.push(_individualCap);
    self.fee = _toPct(_fee,1000);
  }
	
  function deposit (Data storage self) public {
	  assert (!self.poolSubmitted);
    require (tx.gasprice <= maxGasPrice);
    Contributor storage c = self.contributorMap[msg.sender];
    uint cap = _getCap(self, msg.sender);
    require (cap >= c.balance.add(msg.value));
    if (self.contractCap < address(this).balance) {
      require (address(this).balance.sub(msg.value) < self.contractCap);
      uint excess = address(this).balance.sub(self.contractCap);
      c.balance = c.balance.add(msg.value.sub(excess));
      msg.sender.transfer(excess);
    } else {
      c.balance = c.balance.add(msg.value);
    }
    require (c.balance >= contributionMin);
    emit ContributorBalanceChanged(msg.sender, c.balance);
  }
  
  function receiveRefund (Data storage self) public {
    assert (self.poolSubmitted);
    require (msg.sender == self.receiver || msg.sender == self.owner);
    require (msg.value >= 1 ether);
    self.withdrawToken.push(0x00);
    self.withdrawAmount.push(msg.value);
    emit WithdrawalAvailable(0x00);
  }
  
  function withdraw (Data storage self) public {
    assert (msg.value == 0);
    Contributor storage c = self.contributorMap[msg.sender];
    require (c.balance > 0);
    if (!self.poolSubmitted) {
      uint balance = c.balance;
      c.balance = 0;
      msg.sender.transfer(balance);
      emit ContributorBalanceChanged(msg.sender, 0);
      return;
    }
    require (c.claimedTokensIndex < self.withdrawToken.length);
    uint pct = _toPct(c.balance,self.finalBalance);
    uint amount;
    address token;
    for (uint16 i = c.claimedTokensIndex; i < self.withdrawToken.length; i++) {
      amount = _applyPct(self.withdrawAmount[i],pct);
      token = self.withdrawToken[i];
      c.claimedTokensIndex++;
      if (amount > 0) {  
        if (token == 0x00) {
          msg.sender.transfer(amount);
        } else {
          require (ERC20(token).transfer(msg.sender, amount));
          self.tokenBalances[token] = self.tokenBalances[token].sub(amount);  
        }
        emit WithdrawalClaimed(msg.sender, token, amount);
      }
    }
  }
  
  function setIndividualCaps (Data storage self, address[] addr, uint[] cap) public onlyOwner(self) {
    require (addr.length == cap.length);
    for (uint8 i = 0; i < addr.length; i++) {
      self.individualCaps[addr[i]] = cap[i];
    }  
  }
  
  function setCaps (Data storage self, uint32[] times, uint[] caps) public onlyOwner(self) {
    require (caps.length > 0);
    require (caps.length == times.length);
    self.capTimes = [0];
    self.capAmounts = [self.capAmounts[0]];
    for (uint8 i = 0; i < caps.length; i++) {
      require (times[i] > self.capTimes[self.capTimes.length.sub(1)]);
      self.capTimes.push(times[i]);
      self.capAmounts.push(caps[i]);
    }
  }
  
  function setContractCap (Data storage self, uint amount) public onlyOwner(self) {
    require (amount >= address(this).balance);
    self.contractCap = amount;
  }
  
  function _getCap (Data storage self, address addr) internal view returns (uint) {
    if (self.individualCaps[addr] > 0) return self.individualCaps[addr];
    if (whitelistContract.checkMemberLevel(msg.sender) == 0) return 0;
    return getCapAtTime(self,now);
  }
  
  function getCapAtTime (Data storage self, uint time) public view returns (uint) {
    if (time == 0) time = now;
    for (uint i = 1; i < self.capTimes.length; i++) {
      if (self.capTimes[i] > time) return self.capAmounts[i-1];
    }
    return self.capAmounts[self.capAmounts.length-1];
  }
  
  function getPoolInfo (Data storage self) view public returns (uint balance, uint remaining, uint cap) {
    if (!self.poolSubmitted) return (address(this).balance, self.contractCap.sub(address(this).balance), self.contractCap);
    return (address(this).balance, 0, self.contractCap);
  }
  
  function getContributorInfo (Data storage self, address addr) view public returns (uint balance, uint remaining, uint cap) {
    cap = _getCap(self, addr);
    Contributor storage c = self.contributorMap[addr];
    if (self.poolSubmitted || cap <= c.balance) return (c.balance, 0, cap);
    if (cap.sub(c.balance) > self.contractCap.sub(address(this).balance)) return (c.balance, self.contractCap.sub(address(this).balance), cap);
    return (c.balance, cap.sub(c.balance), cap);
  }
  
  function checkWithdrawalAvailable (Data storage self, address addr) view public returns (bool) {
    return self.contributorMap[addr].claimedTokensIndex < self.withdrawToken.length;
  }
  
  function setReceiverAddress (Data storage self, address _receiver) public onlyOwner(self) {
    require (!self.poolSubmitted);
    self.receiver = _receiver;
    self.addressSetTime = now;
    emit ReceiverAddressSet(_receiver);
  }
  
  function submitPool (Data storage self, uint amountInWei) public onlyOwner(self) noReentrancy(self) {
    require (!self.poolSubmitted);
    require (now > self.addressSetTime.add(86400));
    if (amountInWei == 0) amountInWei = address(this).balance;
    self.finalBalance = address(this).balance;
    self.poolSubmitted = true;
    require (self.receiver.call.value(amountInWei).gas(gasleft().sub(5000))());
    if (address(this).balance > 0) {
      self.withdrawToken.push(0x00);
      self.withdrawAmount.push(address(this).balance);
      emit WithdrawalAvailable(0x00);
    }
    emit PoolSubmitted(self.receiver, amountInWei);
  }
  
  function enableWithdrawals (Data storage self, address tokenAddress, address feeAddress) public onlyOwner(self) noReentrancy(self) {
    require (self.poolSubmitted);
    if (feeAddress == 0x00) feeAddress = self.owner;
    ERC20 token = ERC20(tokenAddress);
    uint amount = token.balanceOf(this).sub(self.tokenBalances[tokenAddress]);
    require (amount > 0);
    if (self.fee > 0) {
      require (token.transfer(feeAddress, _applyPct(amount,self.fee)));
      amount = token.balanceOf(this).sub(self.tokenBalances[tokenAddress]);
    }
    self.tokenBalances[tokenAddress] = token.balanceOf(this);
    self.withdrawToken.push(tokenAddress);
    self.withdrawAmount.push(amount);
    emit WithdrawalAvailable(tokenAddress);
  }

}
contract PresalePool {
	
	using PresaleLib for PresaleLib.Data;
	PresaleLib.Data data;
  
  event ERC223Received (address token, uint value, bytes data);
	
	function PresalePool (uint fee, address receiver, uint contractCap, uint individualCap) public {
    data.newPool(fee, receiver, contractCap, individualCap);
	}
	
	function () public payable {
    if (msg.value > 0) {
      if (!data.poolSubmitted) {
        data.deposit();
      } else {
        data.receiveRefund();
      }
    } else {
      data.withdraw();
    }
	}
  
  function setIndividualCaps (address[] addr, uint[] cap) public {
    data.setIndividualCaps(addr, cap); 
  }
  
  function setCaps (uint32[] times, uint[] caps) public {
    data.setCaps(times,caps);
  }
  
  function setContractCap (uint amount) public {
    data.setContractCap(amount);
  }
  
  function getPoolInfo () view public returns (uint balance, uint remaining, uint cap) {
    return data.getPoolInfo();
  }
  
  function getContributorInfo (address addr) view public returns (uint balance, uint remaining, uint cap) {
    return data.getContributorInfo(addr);
  }
  
  function getCapAtTime (uint32 time) view public returns (uint) {
    return data.getCapAtTime(time);
  }
  
  function checkWithdrawalAvailable (address addr) view public returns (bool) {
    return data.checkWithdrawalAvailable(addr);
  }
  
  function setReceiverAddress (address receiver) public {
    data.setReceiverAddress(receiver);
  }
  
  function submitPool (uint amountInWei) public {
    data.submitPool(amountInWei);
  }
  
  function enableWithdrawals (address tokenAddress, address feeAddress) public {
    data.enableWithdrawals(tokenAddress, feeAddress);
  }
  
  function tokenFallback (address from, uint value, bytes calldata) public {
    emit ERC223Received(from, value, calldata);
  }
	
}