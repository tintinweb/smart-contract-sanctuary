pragma solidity ^0.4.18;

contract TxdToken {
  string public standard = &#39;ERC20&#39;;
  string public name;
  string public symbol;
  uint8 public decimals;
  	
  address public controller_addr;

  uint256 public totalSupply;
  
  uint256 public peradd;

  uint256 public usedSupply;

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  event Addused(uint256 _value);

  constructor() public {
    controller_addr = msg.sender;
    
    uint256 _val = 10 ** 10;
    balanceOf[controller_addr] = _val; 
    usedSupply = _val;
    totalSupply = 10 ** 13 * 6;
    name = "Txd Bit";
    symbol = "TXD";
    
    peradd = _val;
    
    decimals = 4;
  }

  function addused(uint256 _value) public {
    if (controller_addr != msg.sender) revert();
    if (peradd < _value) revert();
    uint256 _temp_val = usedSupply + _value;
    if (_temp_val > totalSupply) revert();
    balanceOf[controller_addr] += _value;
    usedSupply = _temp_val;
    emit Addused( _value);
  }

  function transfer(address _to, uint256 _value) public {
    if (_to == 0x0) revert();
    if (balanceOf[msg.sender] < _value) revert();
    if (balanceOf[_to] + _value < balanceOf[_to]) revert();

    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    success = true;
  }    

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    if (_to == 0x0) revert();
    if (balanceOf[_from] < _value) revert();
    if (balanceOf[_to] + _value < balanceOf[_to]) revert();
    if (_value > allowance[_from][msg.sender]) revert();

    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    allowance[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    success = true;
  }
}