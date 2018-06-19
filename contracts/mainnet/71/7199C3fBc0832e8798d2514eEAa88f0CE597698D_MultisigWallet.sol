pragma solidity ^0.4.11;

contract Multisig {
  event Deposit(address _from, uint value);
  event SingleTransact(address owner, uint value, address to, bytes data);
  event MultiTransact(address owner, bytes32 operation, uint value, address to, bytes data);
  event ConfirmationNeeded(bytes32 operation, address initiator, uint value, address to, bytes data);
  function changeOwner(address _from, address _to) external;
  function execute(address _to, uint _value, bytes _data) external returns (bytes32);
  function confirm(bytes32 _h) returns (bool);
}


contract Shareable {
  struct PendingState {
    uint yetNeeded;
    uint ownersDone;
    uint index;
  }
  uint public required;
  address[256] owners;
  mapping(address => uint) ownerIndex;
  mapping(bytes32 => PendingState) pendings;
  bytes32[] pendingsIndex;
  event Confirmation(address owner, bytes32 operation);
  event Revoke(address owner, bytes32 operation);
  modifier onlyOwner {
    if (!isOwner(msg.sender)) {
      throw;
    }
    _;
  }
  modifier onlymanyowners(bytes32 _operation) {
    if (confirmAndCheck(_operation)) {
      _;
    }
  }
  function Shareable(address[] _owners, uint _required) {
    owners[1] = msg.sender;
    ownerIndex[msg.sender] = 1;
    for (uint i = 0; i < _owners.length; ++i) {
      owners[2 + i] = _owners[i];
      ownerIndex[_owners[i]] = 2 + i;
    }
    required = _required;
    if (required > owners.length) {
      throw;
    }
  }
  function revoke(bytes32 _operation) external {
    uint index = ownerIndex[msg.sender];
    if (index == 0) {
      return;
    }
    uint ownerIndexBit = 2**index;
    var pending = pendings[_operation];
    if (pending.ownersDone & ownerIndexBit > 0) {
      pending.yetNeeded++;
      pending.ownersDone -= ownerIndexBit;
      Revoke(msg.sender, _operation);
    }
  }
  function getOwner(uint ownerIndex) external constant returns (address) {
    return address(owners[ownerIndex + 1]);
  }
  function isOwner(address _addr) constant returns (bool) {
    return ownerIndex[_addr] > 0;
  }
  function hasConfirmed(bytes32 _operation, address _owner) constant returns (bool) {
    var pending = pendings[_operation];
    uint index = ownerIndex[_owner];
    if (index == 0) {
      return false;
    }
    uint ownerIndexBit = 2**index;
    return !(pending.ownersDone & ownerIndexBit == 0);
  }
  function confirmAndCheck(bytes32 _operation) internal returns (bool) {
    uint index = ownerIndex[msg.sender];
    if (index == 0) {
      throw;
    }

    var pending = pendings[_operation];
    if (pending.yetNeeded == 0) {
      pending.yetNeeded = required;
      pending.ownersDone = 0;
      pending.index = pendingsIndex.length++;
      pendingsIndex[pending.index] = _operation;
    }
    uint ownerIndexBit = 2**index;
    if (pending.ownersDone & ownerIndexBit == 0) {
      Confirmation(msg.sender, _operation);
      if (pending.yetNeeded <= 1) {
        delete pendingsIndex[pendings[_operation].index];
        delete pendings[_operation];
        return true;
      } else {
        pending.yetNeeded--;
        pending.ownersDone |= ownerIndexBit;
      }
    }
    return false;
  }
  function clearPending() internal {
    uint length = pendingsIndex.length;
    for (uint i = 0; i < length; ++i) {
      if (pendingsIndex[i] != 0) {
        delete pendings[pendingsIndex[i]];
      }
    }
    delete pendingsIndex;
  }

}


contract DayLimit {

  uint public dailyLimit;
  uint public spentToday;
  uint public lastDay;
  function DayLimit(uint _limit) {
    dailyLimit = _limit;
    lastDay = today();
  }
  function _setDailyLimit(uint _newLimit) internal {
    dailyLimit = _newLimit;
  }
  function _resetSpentToday() internal {
    spentToday = 0;
  }
  function underLimit(uint _value) internal returns (bool) {
    if (today() > lastDay) {
      spentToday = 0;
      lastDay = today();
    }
    if (spentToday + _value >= spentToday && spentToday + _value <= dailyLimit) {
      spentToday += _value;
      return true;
    }
    return false;
  }
  function today() private constant returns (uint) {
    return now / 1 days;
  }
  modifier limitedDaily(uint _value) {
    if (!underLimit(_value)) {
      throw;
    }
    _;
  }
}



contract MultisigWalletZeppelin is Multisig, Shareable, DayLimit {

  struct Transaction {
    address to;
    uint value;
    bytes data;
  }
  function MultisigWalletZeppelin(address[] _owners, uint _required, uint _daylimit)       
    Shareable(_owners, _required)        
    DayLimit(_daylimit) { 
    }
  function destroy(address _to) onlymanyowners(keccak256(msg.data)) external {
    selfdestruct(_to);
  }
  function() payable {
    if (msg.value > 0)
      Deposit(msg.sender, msg.value);
  }
  function execute(address _to, uint _value, bytes _data) external onlyOwner returns (bytes32 _r) {
    if (underLimit(_value)) {
      SingleTransact(msg.sender, _value, _to, _data);
      if (!_to.call.value(_value)(_data)) {
        throw;
      }
      return 0;
    }
    _r = keccak256(msg.data, block.number);
    if (!confirm(_r) && txs[_r].to == 0) {
      txs[_r].to = _to;
      txs[_r].value = _value;
      txs[_r].data = _data;
      ConfirmationNeeded(_r, msg.sender, _value, _to, _data);
    }
  }
  function confirm(bytes32 _h) onlymanyowners(_h) returns (bool) {
    if (txs[_h].to != 0) {
      if (!txs[_h].to.call.value(txs[_h].value)(txs[_h].data)) {
        throw;
      }
      MultiTransact(msg.sender, _h, txs[_h].value, txs[_h].to, txs[_h].data);
      delete txs[_h];
      return true;
    }
  }
  function setDailyLimit(uint _newLimit) onlymanyowners(keccak256(msg.data)) external {
    _setDailyLimit(_newLimit);
  }
  function resetSpentToday() onlymanyowners(keccak256(msg.data)) external {
    _resetSpentToday();
  }
  function clearPending() internal {
    uint length = pendingsIndex.length;
    for (uint i = 0; i < length; ++i) {
      delete txs[pendingsIndex[i]];
    }
    super.clearPending();
  }
  mapping (bytes32 => Transaction) txs;
}


contract MultisigWallet is MultisigWalletZeppelin {
  uint public totalSpending;

  function MultisigWallet(address[] _owners, uint _required, uint _daylimit)
    MultisigWalletZeppelin(_owners, _required, _daylimit) payable { }

  function changeOwner(address _from, address _to) external { }

}