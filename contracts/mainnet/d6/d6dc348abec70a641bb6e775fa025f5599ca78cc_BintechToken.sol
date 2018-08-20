pragma solidity ^0.4.24;

contract ContractReceiver {
  struct TKN {
    address sender;
    uint value;
    bytes data;
    bytes4 sig;
  }

  function tokenFallback(address _from, uint _value, bytes _data) public pure {
    TKN memory tkn;
    tkn.sender = _from;
    tkn.value = _value;
    tkn.data = _data;
    uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
    tkn.sig = bytes4(u);
  }
}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
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

contract ERC223 {
  uint public totalSupply;

  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function decimals() public view returns (uint8 _decimals);
  function totalSupply() public view returns (uint256 _supply);
  function balanceOf(address who) public view returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint _value, bytes indexed _data);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract BintechToken is ERC223, Ownable {
  using SafeMath for uint256;

  string public name = "BintechToken";
  string public symbol = "BTT";
  uint8 public decimals = 8;
  uint256 public initialSupply = 2e8 * 1e8;
  uint256 public totalSupply;
  uint256 public distributeAmount = 0;
  bool public mintingFinished = false;
  
  mapping (address => uint) balances;
  mapping (address => bool) public frozenAccount;
  mapping (address => uint256) public unlockUnixTime;

  event FrozenFunds(address indexed target, bool frozen);
  event LockedFunds(address indexed target, uint256 locked);
  event Burn(address indexed burner, uint256 value);
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  constructor() public {
    totalSupply = initialSupply;
    balances[msg.sender] = totalSupply;
  }

  function name() public view returns (string _name) {
      return name;
  }

  function symbol() public view returns (string _symbol) {
      return symbol;
  }

  function decimals() public view returns (uint8 _decimals) {
      return decimals;
  }

  function totalSupply() public view returns (uint256 _totalSupply) {
      return totalSupply;
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

  modifier onlyPayloadSize(uint256 size){
    assert(msg.data.length >= size + 4);
    _;
  }

  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
    require(_value > 0
            && frozenAccount[msg.sender] == false
            && frozenAccount[_to] == false
            && now > unlockUnixTime[msg.sender]
            && now > unlockUnixTime[_to]);

    if(isContract(_to)) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
        balances[_to] = SafeMath.add(balanceOf(_to), _value);
        assert(_to.call.value(0)(bytes4(keccak256(abi.encodePacked(_custom_fallback))), msg.sender, _value, _data));
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }

  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
    require(_value > 0
            && frozenAccount[msg.sender] == false
            && frozenAccount[_to] == false
            && now > unlockUnixTime[msg.sender]
            && now > unlockUnixTime[_to]);

    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }

  function transfer(address _to, uint _value) public returns (bool success) {
    require(_value > 0
            && frozenAccount[msg.sender] == false
            && frozenAccount[_to] == false
            && now > unlockUnixTime[msg.sender]
            && now > unlockUnixTime[_to]);

    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
  }

  function isContract(address _addr) private view returns (bool is_contract) {
    uint length;
    assembly {
      length := extcodesize(_addr)
    }
    return (length>0);
  }

  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
    balances[_to] = SafeMath.add(balanceOf(_to), _value);
    emit Transfer(msg.sender, _to, _value, _data);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
    balances[_to] = SafeMath.add(balanceOf(_to), _value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    emit Transfer(msg.sender, _to, _value, _data);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function freezeAccounts(address[] targets, bool isFrozen) onlyOwner public {
    require(targets.length > 0);

    for (uint i = 0; i < targets.length; i++) {
      require(targets[i] != 0x0);
      frozenAccount[targets[i]] = isFrozen;
      emit FrozenFunds(targets[i], isFrozen);
    }
  }

  function lockupAccounts(address[] targets, uint[] unixTimes) onlyOwner public {
    require(targets.length > 0
            && targets.length == unixTimes.length);

    for(uint i = 0; i < targets.length; i++){
      require(unlockUnixTime[targets[i]] < unixTimes[i]);
      unlockUnixTime[targets[i]] = unixTimes[i];
      emit LockedFunds(targets[i], unixTimes[i]);
    }
  }

  function burn(address _from, uint256 _unitAmount) onlyOwner public {
    require(_unitAmount > 0
            && balanceOf(_from) >= _unitAmount);

    balances[_from] = SafeMath.sub(balances[_from], _unitAmount);
    totalSupply = SafeMath.sub(totalSupply, _unitAmount);
    emit Burn(_from, _unitAmount);
  }

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _unitAmount) onlyOwner canMint public returns (bool) {
    require(_unitAmount > 0);

    totalSupply = SafeMath.add(totalSupply, _unitAmount);
    balances[_to] = SafeMath.add(balances[_to], _unitAmount);
    emit Mint(_to, _unitAmount);
    emit Transfer(address(0), _to, _unitAmount);
    return true;
  }

  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

  function distributeTokens(address[] addresses, uint256 amount) public returns (bool) {
    require(amount > 0
            && addresses.length > 0
            && frozenAccount[msg.sender] == false
            && now > unlockUnixTime[msg.sender]);

    amount = SafeMath.mul(amount, 1e8);
    uint256 totalAmount = SafeMath.mul(amount, addresses.length);
    require(balances[msg.sender] >= totalAmount);

    for (uint i = 0; i < addresses.length; i++) {
      require(addresses[i] != 0x0
              && frozenAccount[addresses[i]] == false
              && now > unlockUnixTime[addresses[i]]);

      balances[addresses[i]] = SafeMath.add(balances[addresses[i]], amount);
      emit Transfer(msg.sender, addresses[i], amount);
    }
    balances[msg.sender] = SafeMath.sub(balances[msg.sender], totalAmount);
    return true;
  }
  
  function distributeTokens(address[] addresses, uint[] amounts) public returns (bool) {
    require(addresses.length > 0
            && addresses.length == amounts.length
            && frozenAccount[msg.sender] == false
            && now > unlockUnixTime[msg.sender]);

    uint256 totalAmount = 0;
        
    for(uint i = 0; i < addresses.length; i++){
      require(amounts[i] > 0
      && addresses[i] != 0x0
      && frozenAccount[addresses[i]] == false
      && now > unlockUnixTime[addresses[i]]);
      
      amounts[i] = amounts[i].mul(1e8);
      totalAmount = SafeMath.add(totalAmount, amounts[i]);
    }
    require(balances[msg.sender] >= totalAmount);
        
    for (i = 0; i < addresses.length; i++) {
      balances[addresses[i]] = SafeMath.add(balances[addresses[i]], amounts[i]);
      emit Transfer(msg.sender, addresses[i], amounts[i]);
    }
    balances[msg.sender] = balances[msg.sender].sub(totalAmount);
    return true;
  }

  function collectTokens(address[] addresses, uint[] amounts) onlyOwner public returns (bool) {
    require(addresses.length > 0
            && addresses.length == amounts.length);

    uint256 totalAmount = 0;

    for (uint i = 0; i < addresses.length; i++) {
      require(amounts[i] > 0
              && addresses[i] != 0x0
              && frozenAccount[addresses[i]] == false
              && now > unlockUnixTime[addresses[i]]);

      amounts[i] = SafeMath.mul(amounts[i], 1e8);
      require(balances[addresses[i]] >= amounts[i]);
      balances[addresses[i]] = SafeMath.sub(balances[addresses[i]], amounts[i]);
      totalAmount = SafeMath.add(totalAmount, amounts[i]);
      emit Transfer(addresses[i], msg.sender, amounts[i]);
    }
    balances[msg.sender] = SafeMath.add(balances[msg.sender], totalAmount);
    return true;
  }

  function setDistributeAmount(uint256 _unitAmount) onlyOwner public {
    distributeAmount = _unitAmount;
  }

  function autoDistribute() payable public {
    require(distributeAmount > 0
            && balanceOf(owner) >= distributeAmount
            && frozenAccount[msg.sender] == false
            && now > unlockUnixTime[msg.sender]);
    if (msg.value > 0) owner.transfer(msg.value);
    
    balances[owner] = SafeMath.sub(balances[owner], distributeAmount);
    balances[msg.sender] = SafeMath.add(balances[msg.sender], distributeAmount);
    emit Transfer(owner, msg.sender, distributeAmount);
  }

  function() payable public {
    autoDistribute();
  }
}