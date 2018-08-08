library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BlocVehicle is ERC20 {

      using SafeMath for uint;
      string public constant name = "BlocVehicle";
      string public constant symbol = "VCL";
      uint256 public constant decimals = 18;
      uint256 _totalSupply = 1000000000 * (10 ** decimals);

      mapping(address => uint256) balances;
      mapping(address => mapping (address => uint256)) allowed;
      mapping(address => bool) public frozenAccount;

      event FrozenFunds(address target, bool frozen);


      address public owner;

      modifier onlyOwner() {
        require(msg.sender == owner);
        _;
      }

      function changeOwner(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        owner = _newOwner;
      }

      function burnTokens(address burnedAddress, uint256 amount) onlyOwner public {
        require(burnedAddress != address(0));
        require(amount > 0);
        require(amount <= balances[burnedAddress]);
        balances[burnedAddress] = balances[burnedAddress].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
      }

      function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
      }

      function isFrozenAccount(address _addr) public constant returns (bool) {
        return frozenAccount[_addr];
      }

      constructor() public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
      }

      function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(balances[_to].add(_value)  >= balances[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);

        uint previousBalances = balances[_from].add(balances[_to]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
        assert(balances[_from].add(balances[_to]) == previousBalances);
      }

      function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
      }

      function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
      }

      function totalSupply() public constant returns (uint256 supply) {
        supply = _totalSupply;
      }

      function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
      }

      function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
      }

      function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
          allowed[msg.sender][_spender] = 0;
        } else {
          allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
      }

      function approve(address _spender, uint256 _value) public returns (bool success) {
          allowed[msg.sender][_spender] = _value;
          emit Approval(msg.sender, _spender, _value);
          return true;
      }

      function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
      }
}