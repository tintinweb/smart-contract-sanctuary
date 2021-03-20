/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

pragma solidity ^0.4.24;

// Safe Math

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


// Ownable


contract Ownable {
  address public _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  constructor() public {
    _owner = msg.sender;
  }


  function owner() public view returns(address) {
    return _owner;
  }


  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract GorCoin is ERC20Interface, Ownable {
  using SafeMath for uint256;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 public _rate;
    uint256 private _totalSupply;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Mint(uint256 amount);


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
      symbol = "GORC";
      name = "GOR COIN";
      decimals = 8;
      _rate = uint256(5000);

      _totalSupply = 100000000 * (10 ** uint256(decimals));
      uint256 _ownerSupply = 10000000 * (10 ** uint256(decimals));
      _balances[_owner] = _ownerSupply;
      _balances[address(this)] = _ownerSupply;
      _allowed[address(this)][_owner]=_totalSupply;
      emit Transfer(address(0), _owner, _ownerSupply);
    }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }

    // Method for batch distribution of airdrop tokens.
    function sendBatchCS(address[] _recipients, uint[] _values) external onlyOwner returns (bool) {
        require(_recipients.length == _values.length);
        uint senderBalance = _balances[msg.sender];
        for (uint i = 0; i < _values.length; i++) {
            uint value = _values[i];
            address to = _recipients[i];
            require(senderBalance >= value);
            senderBalance = senderBalance - value;
            _balances[to] += value;
            emit Transfer(msg.sender, to, value);
        }
        _balances[msg.sender] = senderBalance;
        return true;
    }


  function _withdrawETH() external onlyOwner returns (bool) {
    require (address(this).balance > 0);
    _owner.transfer(address(this).balance);
    return true;
  }


  function _withdrawGORC(uint256 amount) external onlyOwner returns (bool) {
    require (_balances[address(this)] > 0);
    uint256 value = amount * 10 ** uint256(decimals);
    require (_balances[address(this)] > value);
    _balances[address(this)] = _balances[address(this)].sub(value);
    _balances[_owner] = _balances[_owner].add(value);
    emit Transfer(address(this), _owner, value);
    return true;


  }


function _setRate(uint256 newrate) external onlyOwner {
    require (newrate > 0);
    _rate = newrate;
  }


  function () external payable {
    buyTokens(msg.sender);
  }


function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require (_balances[address(this)] > 0);
    uint256 tokens = msg.value * _rate;

    require(_balances[address(this)] >= tokens);

    sendTokens(address(this), beneficiary, tokens);

    emit TokensPurchased(msg.sender, beneficiary,  msg.value, tokens);
  }




  function sendTokens(address from, address to, uint256 value) internal returns (bool) {
    require(value <= _balances[from]);
    require(to != address(0));
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
    return true;
  }


function mint(uint256 _amount) public onlyOwner returns (bool) {
    uint256 value = _amount * 10 ** uint256(decimals);
    uint256 toContract = value / 2;
    uint256 toOwner = value - toContract;
  _totalSupply = _totalSupply.add(value);
    _balances[address(this)] = _balances[address(this)].add(toContract);
    _balances[_owner] = _balances[_owner].add(toOwner);
    _allowed[address(this)][_owner]=_totalSupply;
    emit Mint(_amount);
    return true;


  }
}