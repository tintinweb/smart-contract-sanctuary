/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

pragma solidity ^0.6.2;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.6.2;

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

pragma solidity ^0.6.2;

contract Ownable {
  address private _owner;

  constructor() public {
    _owner = msg.sender;
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function owner(
  ) public view returns (address) {
    return _owner;
  }

  function isOwner(
  ) public view returns (bool) {
    return msg.sender == _owner;
  }
}

pragma solidity ^0.6.2;

contract Pausable is Ownable {

    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    modifier whenNotPaused() 
    {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    constructor() internal {}

    function paused(
    ) public view returns (bool) 
    {
        return _paused;
    }

    function pause(
    ) public 
        onlyOwner 
        whenNotPaused 
    {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause(
    ) public 
        onlyOwner 
        whenPaused 
    {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


pragma solidity ^0.6.2;

contract EverShit is IERC20, Ownable, Pausable {

    using SafeMath for uint;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;

    event Mint(address indexed minter, address indexed account, uint256 amount);
    event Burn(address indexed burner, address indexed account, uint256 amount);

    constructor (
        string memory name, 
        string memory symbol, 
        uint8 decimals, 
        uint256 totalSupply
    ) public
    {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = totalSupply;
        _balances[msg.sender] = totalSupply;
    }

    function name(
    ) public view returns (string memory)
    {
        return _name;
    }

    function symbol(
    ) public view returns (string memory)
    {
        return _symbol;
    }

    function decimals(
    ) public view returns (uint8)
    {
        return _decimals;
    }

    function totalSupply(
    ) public view returns (uint256)
    {
        return _totalSupply;
    }

    function transfer(
        address _to, 
        uint256 _value
    ) public override
        whenNotPaused 
      returns (bool)
    {
        require(_to != address(0), 'ERC20: to address is not valid');
        require(_value <= _balances[msg.sender], 'ERC20: insufficient balance');
        
        _balances[msg.sender] = SafeMath.sub(_balances[msg.sender], _value);
        _balances[_to] = SafeMath.add(_balances[_to], _value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }

   function balanceOf(
       address _owner
    ) public override view returns (uint256 balance) 
    {
        return _balances[_owner];
    }

    function approve(
       address _spender, 
       uint256 _value
    ) public override
        whenNotPaused
      returns (bool) 
    {
        _allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
   }

   function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    ) public override
        whenNotPaused
      returns (bool) 
    {
        require(_from != address(0), 'ERC20: from address is not valid');
        require(_to != address(0), 'ERC20: to address is not valid');
        require(_value <= _balances[_from], 'ERC20: insufficient balance');
        require(_value <= _allowed[_from][msg.sender], 'ERC20: from not allowed');

        _balances[_from] = SafeMath.sub(_balances[_from], _value);
        _balances[_to] = SafeMath.add(_balances[_to], _value);
        _allowed[_from][msg.sender] = SafeMath.sub(_allowed[_from][msg.sender], _value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
   }

    function allowance(
        address _owner, 
        address _spender
    ) public override view 
        whenNotPaused
      returns (uint256) 
    {
        return _allowed[_owner][_spender];
    }

    function increaseApproval(
        address _spender, 
        uint _addedValue
    ) public
        whenNotPaused
      returns (bool)
    {
        _allowed[msg.sender][_spender] = SafeMath.add(_allowed[msg.sender][_spender], _addedValue);
        
        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
        
        return true;
    }

    function decreaseApproval(
        address _spender, 
        uint _subtractedValue
    ) public
        whenNotPaused
      returns (bool) 
    {
        uint oldValue = _allowed[msg.sender][_spender];
        
        if (_subtractedValue > oldValue) {
            _allowed[msg.sender][_spender] = 0;
        } else {
            _allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
        }
        
        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
        
        return true;
   }

    function mintTo(
        address _to,
        uint _amount
    ) public
        whenNotPaused
        onlyOwner
    {
        require(_to != address(0), 'ERC20: to address is not valid');
        require(_amount > 0, 'ERC20: amount is not valid');

        _totalSupply = _totalSupply.add(_amount);
        _balances[_to] = _balances[_to].add(_amount);

        emit Mint(msg.sender, _to, _amount);
    }

    function burnFrom(
        address _from,
        uint _amount
    ) public
        whenNotPaused
        onlyOwner
    {
        require(_from != address(0), 'ERC20: from address is not valid');
        require(_balances[_from] >= _amount, 'ERC20: insufficient balance');
        
        _balances[_from] = _balances[_from].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);

        emit Burn(msg.sender, _from, _amount);
    }

}

pragma solidity >=0.4.21 <0.7.0;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}