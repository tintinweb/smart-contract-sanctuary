pragma solidity ^0.4.23;

/*
 * ==========================================================================================
 * @title: Digitech.Network
 * @website: https://digitech.network
 * @telegram: https://t.me/DigitechNetwork
 * @twitter: https://twitter.com/DigitechNetwork
 * DEX Token will be used for paying transaction, collecting airdrop campains, 
 * order contract func, creating auction...
 * ==========================================================================================
 */

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address target) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address target, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed target, uint256 value);
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

  function ceil(uint256 m, uint256 n) internal pure returns (uint256) {
    uint256 a = add(m, n);
    uint256 b = sub(a, 1);
    return mul(div(b, n), n);
  }
}

contract ERC20implemented is IERC20 {

  uint8 public _decimal;
  string public _name;
  string public _symbol;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _decimal = decimals;
    _name = name;
    _symbol = symbol; 
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimal;
  }
}
contract DigitechNetwork is ERC20implemented {

  using SafeMath for uint256;
  mapping (address => uint256) public _DGCBalance;
  mapping (address => mapping (address => uint256)) public _allowed;
  string constant TOKEN_NAME = "Digitech.Network";
  string constant TOKEN_SYMBOL = "DGC";
  uint8  constant TOKEN_DECIMAL = 18;
  uint256 constant MAX_SUPPLY = 33333;
  uint256 constant MAX_REMAIN = 8888;
  uint256 constant BURN_RATE = 100; //1%
  uint256 _totalSupply = MAX_SUPPLY * 10 ** uint256(TOKEN_DECIMAL);
  address constant RWALLET = 0xF212A3A9a201B8Ced41AaF783942285E928988ae;

  constructor() public payable ERC20implemented(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMAL) {
    _mint(msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _DGCBalance[owner];
  }
    
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _DGCBalance[msg.sender]);
    require(to != address(0));

    uint256 _d = value.div(BURN_RATE); 
    uint256 a = _totalSupply - MAX_REMAIN * 10 ** uint256(TOKEN_DECIMAL);
    if (a <= 0) {
        _d = 0;
    }else if (a < _d){
        _d = a;
    }
    
    uint256 _transfer = value.sub(_d);
    _DGCBalance[msg.sender] = _DGCBalance[msg.sender].sub(value);
    _DGCBalance[to] = _DGCBalance[to].add(_transfer);
    _totalSupply = _totalSupply.sub(_d);

    emit Transfer(msg.sender, to, _transfer);
    emit Transfer(msg.sender, address(0), _d);

    return true;
  }
  function distribute(address to, uint256 value) public returns (bool) {
    require(value <= _DGCBalance[msg.sender]);
    require(to != address(0));
    require(msg.sender == RWALLET);

    _DGCBalance[msg.sender] = _DGCBalance[msg.sender].sub(value);
    _DGCBalance[to] = _DGCBalance[to].add(value);

    emit Transfer(msg.sender, to, value);

    return true;
  }
  function allowance(address owner, address target) public view returns (uint256) {
    return _allowed[owner][target];
  }

  function approve(address target, uint256 value) public returns (bool) {
    require(target != address(0));
    _allowed[msg.sender][target] = value;
    emit Approval(msg.sender, target, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _DGCBalance[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _DGCBalance[from] = _DGCBalance[from].sub(value);
    uint256 _d = value.div(BURN_RATE);
    uint256 a = _totalSupply - MAX_REMAIN * 10 ** uint256(TOKEN_DECIMAL);
    
    if (a <= 0) {
        _d = 0;
    }else if (a < _d){
        _d = a;
    }
    uint256 _transfer = value.sub(_d);

    _DGCBalance[to] = _DGCBalance[to].add(_transfer);
    _totalSupply = _totalSupply.sub(_d);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, _transfer);
    emit Transfer(from, address(0), _d);

    return true;
  }
  
  function increaseAllowance(address target, uint256 addedValue) public returns (bool) {
    require(target != address(0));
    _allowed[msg.sender][target] = (_allowed[msg.sender][target].add(addedValue));
    emit Approval(msg.sender, target, _allowed[msg.sender][target]);
    return true;
  }

  function decreaseAllowance(address target, uint256 val) public returns (bool) {
    require(target != address(0));
    _allowed[msg.sender][target] = (_allowed[msg.sender][target].sub(val));
    emit Approval(msg.sender, target, _allowed[msg.sender][target]);
    return true;
  }

  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _DGCBalance[account] = _DGCBalance[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) external {
    _sendBurn(msg.sender, amount);
  }

  function _sendBurn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _DGCBalance[account]);
    _totalSupply = _totalSupply.sub(amount);
    _DGCBalance[account] = _DGCBalance[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _sendBurn(account, amount);
  }
}

//OrderContract.sol
/**
 * @param _tokenin20, _tokenin721: ERC20, ERC721
 * @param _tokenout20, _tokenout721: ERC20, ERC721
 * @param _rate -> weiRate: 
 * @param _slippage (max slippage which use for processing transaction)
 * @param _useDGC: bool
 * output: bool? revert:succeed
 * 
*/