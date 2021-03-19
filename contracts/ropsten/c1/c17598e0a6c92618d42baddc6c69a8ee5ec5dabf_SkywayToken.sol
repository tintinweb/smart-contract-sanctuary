/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity 0.4.26;

contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Destructible is Ownable {

  constructor() public payable { }

  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
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

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {
  event Burn(address indexed burner, uint256 value);

  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    // require(_value <= balances[_who]);
    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(
    address _from, 
    address _to, 
    uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(
    address _spender, 
    uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(
    address _owner, 
    address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(
    address _spender, 
    uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(
    address _spender, 
    uint256 _subtractedValue) public returns (bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if(_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract ERC223Basic is ERC20Basic {
  function transfer(
    address _to, 
    uint256 _value, 
    bytes _data) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}

contract ERC223ReceivingContract {
  function tokenFallback(
    address _from, 
    uint256 _value, 
    bytes _data) public returns (bool);
}

contract Adminable is Ownable {
  address public admin;
  event AdminDesignated(address indexed previousAdmin, address indexed newAdmin);

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  modifier onlyOwnerOrAdmin() {
    require(msg.sender == owner || msg.sender == admin);
    _;
  }
}

contract Lockable is Adminable, ERC20Basic {
  using SafeMath for uint256;
  // EPOCH TIMESTAMP OF "Thursday, September 2, 2021"
  // @see https://www.unixtimestamp.com/index.php
  uint public globalUnlockTime = 1630593524;
  uint public constant decimals = 18;

  event UnLock(address indexed unlocked);
  event Lock(address indexed locked, uint until, uint256 value, uint count);
  event UpdateGlobalUnlockTime(uint256 epoch);

  struct LockMeta {
    uint256 value;
    uint until;
  }

  mapping(address => LockMeta[]) internal locksMeta;
  mapping(address => bool) locks;

  function lock(
    address _address, 
    uint _days, 
    uint256 _value) onlyOwnerOrAdmin public {
    require(_value > 0);
    require(_days > 0);
    require(_address != owner);
    require(_address != admin);

    uint untilTime = block.timestamp + _days * 1 days;
    locks[_address] = true;
    // check if we have locks
    locksMeta[_address].push(LockMeta(_value, untilTime));
    // fire lock event
    emit Lock(_address, untilTime, _value, locksMeta[_address].length);
  }

  function unlock(address _address) onlyOwnerOrAdmin public {
    locks[_address] = false;
    delete locksMeta[_address];
    emit UnLock(_address);
  }

  function lockedBalanceOf(address _owner, uint _time) public view returns (uint256) {
    LockMeta[] memory locked = locksMeta[_owner];
    uint length = locked.length;
    // if no locks or even not created (takes bdefault) return 0
    if(length == 0) {
      return 0;
    }
    // sum all available locks
    uint256 _result = 0;
    for(uint i = 0; i < length; i++) {
      if(_time <= locked[i].until) {
        _result = _result.add(locked[i].value);
      }
    }
    return _result;
  }

  function lockedNowBalanceOf(address _owner) public view returns (uint256) {
    return this.lockedBalanceOf(_owner, block.timestamp);
  }

  function unlockedBalanceOf(address _owner, uint _time) public view returns (uint256) {
    return this.balanceOf(_owner) - lockedBalanceOf(_owner, _time);
  }

  function unlockedNowBalanceOf(address _owner) public view returns (uint256) {
    return this.unlockedBalanceOf(_owner, block.timestamp);
  }

  function updateGlobalUnlockTime(uint256 _epoch) public onlyOwnerOrAdmin returns (bool) {
    require(_epoch >= 0);
    globalUnlockTime = _epoch;
    emit UpdateGlobalUnlockTime(_epoch);
    // Gives owner the ability to update lockup period for all wallets.
    // Owner can pass an epoch timecode into the function to:
    // 1. Extend lockup period,
    // 2. Unlock all wallets by passing '0' into the function
  }

  modifier onlyUnlocked(uint256 _value) {
    if(block.timestamp > globalUnlockTime) {
      _;
    } else {
      if(locks[msg.sender] == true) {
        require(this.unlockedNowBalanceOf(msg.sender) >= _value);
      }
      _;
    }
  }

  modifier onlyUnlockedOf(address _address, uint256 _value) {
    if(block.timestamp > globalUnlockTime) {
      _;
    } else {
      if(locks[_address] == true) {
        require(this.unlockedNowBalanceOf(_address) >= _value);
      } else {

      }
      _;
    }
  }
}

contract TrancheToken is Adminable {
  struct WhiteListed {
    uint id;
    string fullname;
    uint trancheId;
    string country;
    string physicalAddress;
  }

  mapping(address => WhiteListed) public whiteListed;
  uint investorCount;
  address[] public whiteListedAddresses;

  event AddedWhiteListed(address indexed wallet, string fullname, uint256 trancheId, string country, string physicalAddress);
  event RemovedWhiteListed(address indexed wallet, string fullname, uint256 trancheId, string country, string physicalAddress);

  constructor() public { }

  function getIdByAddress(address _address) public view returns(uint) {
    return _getIdByAddress(_address);
  }

  function _getIdByAddress(address _address) internal view returns(uint) {
    return whiteListed[_address].id;
  }

  function getTrancheIdByAddress(address _address) public view returns(uint) {
    return _getTrancheIdByAddress(_address);
  }

  function _getTrancheIdByAddress(address _address) internal view returns(uint) {
    return whiteListed[_address].trancheId;
  }

  function getFullnameByAddress(address _address) public view returns(string) {
    return _getFullnameByAddress(_address);
  }

  function _getFullnameByAddress(address _address) internal view returns(string) {
    return whiteListed[_address].fullname;
  }

  function getCountryByAddress(address _address) public view returns(string) {
    return _getCountryByAddress(_address);
  }

  function _getCountryByAddress(address _address) internal view returns(string) {
    return whiteListed[_address].country;
  }

  function getPhysicalAddressByAddress(address _address) public view returns(string) {
    return _getPhysicalAddressByAddress(_address);
  }

  function _getPhysicalAddressByAddress(address _address) internal view returns(string) {
    return whiteListed[_address].physicalAddress;
  }

  function addWhiteListed(
    address _address, 
    string _fullname, 
    uint _tranche, 
    string country,
    string physicalAddress) public onlyOwnerOrAdmin {
    bytes memory tempEmptyString = bytes(physicalAddress);

    /* physicalAddress optional */
    if(tempEmptyString.length == 0) {
      physicalAddress = '';
    }

    _addWhiteListed(_address, _fullname, _tranche, country, physicalAddress);
  }

  function _addWhiteListed(
    address _address, 
    string _fullname, 
    uint _tranche, 
    string country,
    string physicalAddress) internal {
    investorCount++;
    whiteListedAddresses.push(_address);
    whiteListed[_address] = WhiteListed(investorCount, _fullname, _tranche, country, physicalAddress);
    emit AddedWhiteListed(_address, _fullname, _tranche, country, physicalAddress);
  }

  function removeWhiteListed(address _address) public onlyOwnerOrAdmin {
    _removeWhiteListed(_address);
  }

  function _removeWhiteListed(address _address) internal {
    string memory gotFullname = _getFullnameByAddress(_address);
    uint gotTranche = _getTrancheIdByAddress(_address);
    string memory gotCountry = _getCountryByAddress(_address);
    string memory gotPhysicalAddress = _getPhysicalAddressByAddress(_address);
    delete whiteListed[_address];

    for(uint i; i < whiteListedAddresses.length; i++) {
      if(whiteListedAddresses[i] == _address) delete whiteListedAddresses[i];
    }
    emit RemovedWhiteListed(_address, gotFullname, gotTranche, gotCountry, gotPhysicalAddress);
  }

  function designateAdmin(address _address) public onlyOwner {
    require(_address != owner && _address != admin);
    emit AdminDesignated(admin, _address);
    addWhiteListed(_address, 'ADMIN', 1, '', '');
    admin = _address;
  }
}

contract StandardLockableToken is Lockable, /**/ERC223Basic, /*ERC20*/StandardToken, TrancheToken {
  function isContract(address _address) private constant returns (bool) {
    uint256 codeLength;
    assembly {
      codeLength := extcodesize(_address)
    }
    return codeLength > 0;
  }

  function transfer(
    address _to, 
    uint256 _value) onlyUnlocked(_value) public returns (bool) {
    bytes memory empty;
    return _transfer(_to, _value, empty);
  }

  function transfer(
    address _to, 
    uint256 _value, 
    bytes _data) onlyUnlocked(_value) public returns (bool) {
    return _transfer(_to, _value, _data);
  }

  function _transfer(
    address _to, 
    uint256 _value, 
    bytes _data) internal returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(_value > 0);
    // catch overflow loosing tokens
    // require(balances[_to] + _value > balances[_to]);

    // check ability to send within tranche
    uint tranche_from = _getTrancheIdByAddress(msg.sender);
    uint tranche_to = _getTrancheIdByAddress(_to);
    require(tranche_from > 0);
    require(tranche_to > 0);
    require(tranche_from == tranche_to);

    // safety update balances
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    // determine if the contract given
    if(isContract(_to)) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
      receiver.tokenFallback(msg.sender, _value, _data);
    }

    // emit ERC20 transfer event
    emit Transfer(msg.sender, _to, _value);
    // emit ERC223 transfer event
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  function transferFrom(
    address _from, 
    address _to, 
    uint256 _value) onlyUnlockedOf(_from, _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_value > 0);

    // check ability to send within tranche
    uint tranche_from = _getTrancheIdByAddress(_from);
    uint tranche_to = _getTrancheIdByAddress(_to);
    require(tranche_from > 0);
    require(tranche_to > 0);
    require(tranche_from == tranche_to);

    // make balances manipulations first
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    bytes memory empty;
    if(isContract(_to)) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
      receiver.tokenFallback(msg.sender, _value, empty);
    }

    // emit ERC20 transfer event
    emit Transfer(_from, _to, _value);
    // emit ERC223 transfer event
    emit Transfer(_from, _to, _value, empty);
    return true;
  }
}

contract StandardBurnableLockableToken is StandardLockableToken, BurnableToken {
  function burnFrom(
    address _from, 
    uint256 _value) onlyOwner onlyUnlockedOf(_from, _value) public {
    require(_value <= allowed[_from][msg.sender]);
    require(_value > 0);
    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
    bytes memory empty;
    // emit ERC223 transfer event also
    emit Transfer(msg.sender, address(0), _value, empty);
  }

  function burn(uint256 _value) onlyOwner onlyUnlocked(_value) public {
    require(_value > 0);
    _burn(msg.sender, _value);

    bytes memory empty;
    // emit ERC223 transfer event also
    emit Transfer(msg.sender, address(0), _value, empty);
  }

  function burnRemaining() onlyOwner public {
    _burn(msg.sender, balanceOf(msg.sender));

    bytes memory empty;
    // emit ERC223 transfer event also
    emit Transfer(msg.sender, address(0), balanceOf(msg.sender), empty);
  }
}

contract SkywayToken is StandardBurnableLockableToken, Destructible {
  string public constant name = "Skyway Token";
    uint public constant decimals = 18;
    string public constant symbol = "SWS";

  constructor() public {
    // set the owner
    owner = msg.sender;
    admin = 0xFB371E205f5f1F93F268c64d1C09E06735127756;
    uint256 INITIAL_SUPPLY = 2100000000 * (10**decimals);

    addWhiteListed(owner, "OWNER", 1, '', '');
    addWhiteListed(admin, "ADMIN", 1, '', '');

    // init totalSupply
    totalSupply_ = INITIAL_SUPPLY;
    bytes memory empty;

    // Owner = 100%
    uint256 ownerSupply = INITIAL_SUPPLY;
    balances[msg.sender] = ownerSupply;
    emit Transfer(address(0), msg.sender, ownerSupply);
    emit Transfer(address(0), msg.sender, ownerSupply, empty);
  }
}