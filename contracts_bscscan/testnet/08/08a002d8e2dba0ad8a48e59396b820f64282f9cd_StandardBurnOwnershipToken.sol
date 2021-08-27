/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

pragma solidity ^ 0.8.0;


interface IERC20 {
 
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

abstract contract Context {
 function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
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

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  
  constructor () {
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
 
contract StandardBurnOwnershipToken is Context, IERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  string public _name;
  string public _symbol;
  uint8 public _decimals;
  uint256 private _totalSupply;
  uint256 private burnFee;
  
 
  

  constructor(string memory tokenName, string memory tokenSymbol,uint256 initialSupply , uint256 _burnFee)  {
    _name = tokenName;
    _symbol = tokenSymbol;
    _decimals = 18;
    _totalSupply = initialSupply * 10 ** 18;
    burnFee = _burnFee;
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  
  function getOwner() external override view returns (address) {
    return owner();
  }

  function decimals() external override view returns (uint8) {
    return _decimals;
  }

  
  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  function name() external override view returns (string memory) {
    return _name;
  }

  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }


  function balanceOf(address account) external override view returns (uint256) {
    return _balances[account];
  }

 
  
 function transfer(address recipient, uint256 amount) external override returns (bool){
    require(amount <= _balances[msg.sender]);
    require(recipient != address(0));

    uint256 tokensToBurn = amount * burnFee / 100;
    uint256 tokensToTransfer = amount.sub(tokensToBurn);

    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, recipient, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    return true;
  }
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(recipient != address(0));
        require(amount <= _balances[sender]);
        require(amount <= _allowances[sender][msg.sender]);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
      emit   Transfer(sender, recipient, amount);
        return true;
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
       emit  Approval(msg.sender, spender, amount);
        return true;
    }
    
function allowance(address _owner, address spender) external override view returns (uint256) {
        return _allowances[_owner][spender];
    }

   

}