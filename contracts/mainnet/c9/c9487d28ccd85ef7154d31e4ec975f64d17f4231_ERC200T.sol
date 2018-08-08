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

contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;
  modifier whenNotPaused() {
    require(!paused);
    _;
  }
  modifier whenPaused() {
    require(paused);
    _;
  }
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC200Interface {
  string public name;
  string public symbol;
  uint8 public  decimals;
  uint public totalSupply;
  address public owner;

  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
  function approve(address _spender, uint256 _value)  public returns (bool success);
  function allowance(address _owner, address _spender)  public  view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC200T is ERC200Interface, Pausable{
  using SafeMath for uint256;
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) internal allowed;
  mapping(address => uint) pendingReturns;

  constructor() public {
      totalSupply = 21000000000000;
      name = "KKKMToken";
      symbol = "KKKM";
      decimals = 3;
      owner=msg.sender;
      balanceOf[msg.sender] = totalSupply;
  }

  function balanceOf(address _owner)  public  view returns (uint256 balance) {
      return balanceOf[_owner];
  }

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
    require(_to != address(0));
    require(_value <= balanceOf[msg.sender]);
    require(balanceOf[_to] + _value >= balanceOf[_to]);


    balanceOf[msg.sender] =balanceOf[msg.sender].sub(_value);
    balanceOf[_to] =balanceOf[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }



  function transferFrom(address _from, address _to, uint256 _value)  public  whenNotPaused returns (bool success) {
    require(_to != address(0));
    require(_value <= balanceOf[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(balanceOf[_to] + _value >= balanceOf[_to]);

    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;

    allowed[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
  }

  function allowance(address _owner, address _spender) public view onlyOwner returns (uint256 remaining) {
      return allowed[_owner][_spender];
  }
  function () public payable {
    pendingReturns[msg.sender] += msg.value;
  }
  function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!msg.sender.send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }
}