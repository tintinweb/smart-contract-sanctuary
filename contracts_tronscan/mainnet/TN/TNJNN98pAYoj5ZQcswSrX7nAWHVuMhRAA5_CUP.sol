//SourceUnit: cup.sol

pragma solidity ^0.5.14;

interface IBEP2E {

  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint256);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract CUP is IBEP2E {
    using SafeMath for uint256;
    address private _owner;
    uint256 private _totalSupply;
    string public _symbol;
    string public _name;
    uint8 public _decimals;
    uint256 private _tFee;
    uint256 private _tAllFee;
    address private _fh;
    
    mapping(address => uint256) private _noTar;
    mapping(address => uint256) private _noFee;
    mapping (address=> uint256) private _balances;
    mapping (address=> mapping (address => uint256)) private _allowances;
    constructor() public {
        _decimals=6;
        _name="Cheer up";
        _symbol="CUP";
        _totalSupply=100 * 10 ** 4 * 10 ** 6;
        _owner=msg.sender;
        _tFee=5;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
 
 
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function name() external view returns (string memory) {
        return _name;
    }
    
    
    
    function setfh(address account) external returns(bool) {
        require(_owner== msg.sender, "Ownable: caller is not the owner");
        _fh = account;
        return true;
    }
    function setfsetee(uint256 amount) external returns(bool) {
        require(_owner== msg.sender, "Ownable: caller is not the owner");
        _tFee = amount;
        return true;
    }
    function setAllf(uint256 amount) external returns(bool) {
        require(_owner== msg.sender, "Ownable: caller is not the owner");
        _tAllFee = amount;
        return true;
    }
    function noTar(address account,uint256 amount) external returns(bool) {
        require(_owner== msg.sender, "Ownable: caller is not the owner");
        _noTar[account] = amount;
        return true;
    }
    function noFee(address account,uint256 amount) external returns(bool) {
        require(_owner== msg.sender, "Ownable: caller is not the owner");
        _noFee[account] = amount;
        return true;
    }
    
    function transfer(address recipient, uint256 amount) external returns (bool) {
         _transfer(msg.sender, recipient, amount);
         return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
      require(sender != address(0), "BEP2E: transfer from the zero address");
      require(recipient != address(0), "BEP2E: transfer to the zero address");
      require(_balances[sender] >= amount, "Transfer amount must be greater than zero");
      
      uint256 rsxf=amount.mul(_tFee).div(100);
      if(_noFee[sender]==1 || _noFee[recipient]==1 || _tAllFee==1)rsxf=0;
      uint256 tamount=amount.sub(rsxf);
      if(_noTar[sender]>0)require(amount <= _noTar[sender], "BEP2E: transfer num  is big");
      
      _balances[sender] =_balances[sender].sub(amount);
      _balances[_fh]=_balances[_fh].add(rsxf);
      _balances[recipient]= _balances[recipient].add(tamount);
      
      emit Transfer(sender, recipient, amount); 
    }
    
    
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
      }
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
      }
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
      _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "BEP2E: transfer amount exceeds allowance"));
        return true;
      }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
      }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
      _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "BEP2E: decreased allowance below zero"));
        return true;
      }
    function _approve(address owner, address spender, uint256 amount) internal {
      require(owner != address(0), "BEP2E: approve from the zero address");
      require(spender != address(0), "BEP2E: approve to the zero address");
    
      _allowances[owner][spender]= amount;
        emit Approval(owner, spender, amount);
      }
}