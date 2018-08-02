contract SafeMath {
  function mul(uint a, uint b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint a, uint b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>= a);
        return c;
    }
}
contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    uint public decimals;
    string public name;
}
contract ERC20Token is ERC20 {

  function transfer(address _to, uint256 _value) public returns (bool success) {
    if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      emit Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      emit Transfer(_from, _to, _value);
      return true;
    } else { return false; }
  }
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  uint256 public totalSupply;
}
contract Mooncases is SafeMath {
  address public admin; //the admin address
  mapping (address => uint) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)
  
  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);

  constructor () public {
    admin = msg.sender;
  }
  modifier onlyAdmin() {
      require(msg.sender == admin);
      _;
  }
  function changeAdmin(address admin_) public onlyAdmin {
    require(msg.sender == admin);
    admin = admin_;
  }
  function deposit() public payable {
    tokens[0] = add(tokens[0], msg.value);
    emit Deposit(0, msg.sender, msg.value, tokens[0]);
  }
  function withdraw(uint amount) public onlyAdmin {
    require(msg.sender != address(0) && msg.sender == admin);
    require(tokens[0] > amount);
    tokens[0] = sub(tokens[0], amount);
    require(msg.sender.call.value(amount)());
    emit Withdraw(0, msg.sender, amount, tokens[0]);
  }
  function depositToken(address token, uint amount) public {
    require(token!=0);
    require(ERC20(token).transferFrom(msg.sender, admin, amount));
    tokens[token] = add(tokens[token], amount);
    emit Deposit(token, msg.sender, amount, tokens[token]);
  }
  function withdrawToken(address token, uint amount) public {
    require(token != 0);
    require(tokens[token] > amount);
    tokens[token] = SafeMath.sub(tokens[token], amount);
    require (ERC20(token).transfer(msg.sender, amount));
    emit Withdraw(token, msg.sender, amount, tokens[token]);
  }
  function balanceOf(address token) public constant returns (uint) {
    return tokens[token];
  }

}