pragma solidity ^0.4.20;

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
    uint32 u = uint32(_data[3]) + (uint32(_data[2]) &lt;&lt; 8) + (uint32(_data[1]) &lt;&lt; 16) + (uint32(_data[0]) &lt;&lt; 24);
    tkn.sig = bytes4(u);
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
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
    // assert(b &gt; 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b &lt;= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c &gt;= a);
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
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract LongLegs is ERC223, Ownable {
  using SafeMath for uint256;

  string public name = &quot;LongLegs&quot;;
  string public symbol = &quot;XLL&quot;;
  uint8 public decimals = 7;
  uint256 public initialSupply = 3e10 * 1e7;
  uint256 public totalSupply;
  uint256 public distributeAmount = 0;
  bool public mintingFinished = false;
  
  mapping (address =&gt; uint) balances;
  mapping (address =&gt; bool) public frozenAccount;
  mapping (address =&gt; uint256) public unlockUnixTime;

  event FrozenFunds(address indexed target, bool frozen);
  event LockedFunds(address indexed target, uint256 locked);
  event Burn(address indexed burner, uint256 value);
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  function LongLegs() public {
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
    assert(msg.data.length &gt;= size + 4);
    _;
  }

  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
    require(_value &gt; 0
            &amp;&amp; frozenAccount[msg.sender] == false
            &amp;&amp; frozenAccount[_to] == false
            &amp;&amp; now &gt; unlockUnixTime[msg.sender]
            &amp;&amp; now &gt; unlockUnixTime[_to]);

    if(isContract(_to)) {
        if (balanceOf(msg.sender) &lt; _value) revert();
        balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
        balances[_to] = SafeMath.add(balanceOf(_to), _value);
        assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
        Transfer(msg.sender, _to, _value, _data);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }


  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
    require(_value &gt; 0
            &amp;&amp; frozenAccount[msg.sender] == false
            &amp;&amp; frozenAccount[_to] == false
            &amp;&amp; now &gt; unlockUnixTime[msg.sender]
            &amp;&amp; now &gt; unlockUnixTime[_to]);

    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }

  function transfer(address _to, uint _value) public returns (bool success) {
    require(_value &gt; 0
            &amp;&amp; frozenAccount[msg.sender] == false
            &amp;&amp; frozenAccount[_to] == false
            &amp;&amp; now &gt; unlockUnixTime[msg.sender]
            &amp;&amp; now &gt; unlockUnixTime[_to]);

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
    return (length&gt;0);
  }

  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) &lt; _value) revert();
    balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
    balances[_to] = SafeMath.add(balanceOf(_to), _value);
    Transfer(msg.sender, _to, _value, _data);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) &lt; _value) revert();
    balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
    balances[_to] = SafeMath.add(balanceOf(_to), _value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value, _data);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function freezeAccounts(address[] targets, bool isFrozen) onlyOwner public {
    require(targets.length &gt; 0);

    for (uint i = 0; i &lt; targets.length; i++) {
      require(targets[i] != 0x0);
      frozenAccount[targets[i]] = isFrozen;
      FrozenFunds(targets[i], isFrozen);
    }
  }

  function lockupAccounts(address[] targets, uint[] unixTimes) onlyOwner public {
    require(targets.length &gt; 0
            &amp;&amp; targets.length == unixTimes.length);

    for(uint i = 0; i &lt; targets.length; i++){
      require(unlockUnixTime[targets[i]] &lt; unixTimes[i]);
      unlockUnixTime[targets[i]] = unixTimes[i];
      LockedFunds(targets[i], unixTimes[i]);
    }
  }

  function burn(address _from, uint256 _unitAmount) onlyOwner public {
    require(_unitAmount &gt; 0
            &amp;&amp; balanceOf(_from) &gt;= _unitAmount);

    balances[_from] = SafeMath.sub(balances[_from], _unitAmount);
    totalSupply = SafeMath.sub(totalSupply, _unitAmount);
    Burn(_from, _unitAmount);
  }

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _unitAmount) onlyOwner canMint public returns (bool) {
    require(_unitAmount &gt; 0);

    totalSupply = SafeMath.add(totalSupply, _unitAmount);
    balances[_to] = SafeMath.add(balances[_to], _unitAmount);
    Mint(_to, _unitAmount);
    Transfer(address(0), _to, _unitAmount);
    return true;
  }

  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

  function distributeTokens(address[] addresses, uint256 amount) public returns (bool) {
    require(amount &gt; 0
            &amp;&amp; addresses.length &gt; 0
            &amp;&amp; frozenAccount[msg.sender] == false
            &amp;&amp; now &gt; unlockUnixTime[msg.sender]);

    amount = SafeMath.mul(amount, 1e8);
    uint256 totalAmount = SafeMath.mul(amount, addresses.length);
    require(balances[msg.sender] &gt;= totalAmount);

    for (uint i = 0; i &lt; addresses.length; i++) {
      require(addresses[i] != 0x0
              &amp;&amp; frozenAccount[addresses[i]] == false
              &amp;&amp; now &gt; unlockUnixTime[addresses[i]]);

      balances[addresses[i]] = SafeMath.add(balances[addresses[i]], amount);
      Transfer(msg.sender, addresses[i], amount);
    }
    balances[msg.sender] = SafeMath.sub(balances[msg.sender], totalAmount);
    return true;
  }

  function collectTokens(address[] addresses, uint[] amounts) onlyOwner public returns (bool) {
    require(addresses.length &gt; 0
            &amp;&amp; addresses.length == amounts.length);

    uint256 totalAmount = 0;

    for (uint i = 0; i &lt; addresses.length; i++) {
      require(amounts[i] &gt; 0
              &amp;&amp; addresses[i] != 0x0
              &amp;&amp; frozenAccount[addresses[i]] == false
              &amp;&amp; now &gt; unlockUnixTime[addresses[i]]);

      amounts[i] = SafeMath.mul(amounts[i], 1e8);
      require(balances[addresses[i]] &gt;= amounts[i]);
      balances[addresses[i]] = SafeMath.sub(balances[addresses[i]], amounts[i]);
      totalAmount = SafeMath.add(totalAmount, amounts[i]);
      Transfer(addresses[i], msg.sender, amounts[i]);
    }
    balances[msg.sender] = SafeMath.add(balances[msg.sender], totalAmount);
    return true;
  }

  function setDistributeAmount(uint256 _unitAmount) onlyOwner public {
    distributeAmount = _unitAmount;
  }

  function autoDistribute() payable public {
    require(distributeAmount &gt; 0
            &amp;&amp; balanceOf(owner) &gt;= distributeAmount
            &amp;&amp; frozenAccount[msg.sender] == false
            &amp;&amp; now &gt; unlockUnixTime[msg.sender]);
    if (msg.value &gt; 0) owner.transfer(msg.value);
    
    balances[owner] = SafeMath.sub(balances[owner], distributeAmount);
    balances[msg.sender] = SafeMath.add(balances[msg.sender], distributeAmount);
    Transfer(owner, msg.sender, distributeAmount);
  }

  function() payable public {
    autoDistribute();
  }
}