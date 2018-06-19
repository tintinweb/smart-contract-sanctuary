pragma solidity 0.4.24;
contract SafeMath {
  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}
contract owned {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}
contract HermesBlockTechToken is SafeMath,owned {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply; 
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Freeze(address indexed from, bool frozen);
    constructor(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }
    function _transfer(address _from, address _to, uint256 _value) internal {
      require(_to != 0x0);
      require(_value > 0);
      require(balanceOf[_from] >= _value);
      require(balanceOf[_to] + _value > balanceOf[_to]);
      require(!frozenAccount[_from]);
      require(!frozenAccount[_to]);
      uint previousBalances = SafeMath.safeAdd(balanceOf[_from] , balanceOf[_to]);
      balanceOf[_from] = SafeMath.safeSub( balanceOf[_from] , _value);
      balanceOf[_to] =SafeMath.safeAdd(balanceOf[_to] , _value);
      emit Transfer(_from, _to, _value);
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      require(_to != 0x0);
      require(_value > 0);
      require(balanceOf[_from] >= _value);
      require(balanceOf[_to] + _value > balanceOf[_to]);
      require(!frozenAccount[_from]);
      require(!frozenAccount[_to]);
      require(_value <= allowance[_from][msg.sender]); 
      uint previousBalances = SafeMath.safeAdd(balanceOf[_from] , balanceOf[_to]);
      allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender] , _value);
      balanceOf[_from] = SafeMath.safeSub( balanceOf[_from] , _value);
      balanceOf[_to] =SafeMath.safeAdd(balanceOf[_to] , _value);
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
      emit Transfer(_from, _to, _value);
      return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != 0x0);
        require(_value > 0);
        require(balanceOf[_spender] >= _value);
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_spender]);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    function freezeMethod(address target, bool frozen) onlyOwner public returns (bool success){
        require(target != 0x0);
        frozenAccount[target] = frozen;
        emit Freeze(target, frozen);
        return true;
    }
}