pragma solidity ^0.4.24;


// Math operations with safety checks that revert on error
library SafeMath {
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);
    uint256 c = _a / _b;

    return c;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract IAToken {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozen;

    constructor(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 tokenDecimals) public {
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 _value);
    event Freeze(address indexed _target, bool _frozen);
   
    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not 
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != 0);
        require(!frozen[msg.sender], "from address frozen");
        require(!frozen[_to], "to address frozen");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != 0);
        require(!frozen[_from], "from address frozen");
        require(!frozen[_to], "to address frozen");
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice Remove `_value` tokens from the system irreversibly
    /// @param _value the amount of money to burn
    function burn(uint256 _value) public returns (bool success) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    /// @notice Create `_amount` tokens and send it to `_target`
    /// @param _target Address to receive the tokens
    /// @param _amount the amount of tokens it will receive
    function mint(address _target, uint256 _amount) public {
        require(msg.sender == owner, "permission denied");
        require(_target != 0);
        balanceOf[_target] = balanceOf[_target].add(_amount);
        totalSupply = totalSupply.add(_amount);
        emit Transfer(0, msg.sender, _amount);
        emit Transfer(msg.sender, _target, _amount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param _target Address to be frozen
    /// @param _frozen either to freeze it or not
    function freeze(address _target, bool _frozen) public {
        require(msg.sender == owner, "permission denied");
        frozen[_target] = _frozen;
        emit Freeze(_target, _frozen);
    }

	// Can accept ether
	function() public payable {
    }

	// Transfer ether to owner
	function withdraw (uint256 amount) public {
		require(msg.sender == owner, "permission denied");
		owner.transfer(amount);
	}
}