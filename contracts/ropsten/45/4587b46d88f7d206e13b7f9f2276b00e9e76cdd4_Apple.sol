/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity 0.5.10;

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

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
uint256 c = add(a,m);
uint256 d = sub(c,1);
return mul(div(d,m),m);
  }
}


interface IERC20 {

function totalSupply() external view returns (uint256);

function balanceOf(address account) external view returns (uint256);

function transfer(address recipient, uint256 amount) external returns (bool);

function allowance(address owner, address spender) external view returns (uint256);

function approve(address spender, uint256 amount) external returns (bool);

function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

event Transfer(address indexed from, address indexed to, uint256 value);

event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Apple is IERC20 {
using SafeMath for uint256;

mapping (address => uint256) private _balances;

mapping (address => mapping (address => uint256)) private _allowances;

uint256 public _burnRate;
uint256 private _totalSupply = 5000000000;
string public constant name = "Apple";
string public constant symbol = "APP";
uint256 public constant decimals = 6 ;
uint256 public _taxFee = 2;
uint256 public _burnFee = 2;
uint256 public _liquidityFee = 2;
address public owner;

constructor () public {
         owner = msg.sender ;
         _balances[msg.sender] = _totalSupply;
    }

function totalSupply() public view returns (uint256) {
    return _totalSupply;
}


function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
}

function transfer(address recipient, uint256 amount) public returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
}


function allowance(address from, address spender) public view returns (uint256) {
    return _allowances[from][spender];
}


function approve(address spender, uint256 value) public returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
}

function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
    return true;
}

function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    
    
    uint256 Taxvalue = _getTValues(amount);
    uint256 tokensToTransfer = amount.sub(Taxvalue);
    
    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(tokensToTransfer);
     emit Transfer(sender, recipient, tokensToTransfer);
}


function _approve(address from, address spender, uint256 value) internal {
    require(from != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[from][spender] = value;
    emit Approval(from, spender, value);
}


function burnRate() public returns(uint256) {
    if (_totalSupply > 48000) {
        _burnRate = 2;
    } else if(_totalSupply <= 48000 && _totalSupply > 46000) {
        _burnRate = 4;
    } else if(_totalSupply <= 46000 && _totalSupply > 44000) {
        _burnRate = 6;
    } else if(_totalSupply <= 44000 && _totalSupply > 42000) {
        _burnRate = 8;
    } else if(_totalSupply <= 42000 && _totalSupply > 0) {
        _burnRate = 10;
    }
    
    return _burnRate;
}


function _tokenToBurn(uint256 value) public returns(uint256){ 
    uint256 _burnerRate = burnRate();
    uint256 roundValue = value.ceil(_burnerRate);
    uint256 _myTokensToBurn = roundValue.mul(_burnerRate).div(100);
    return _myTokensToBurn;
}
function _getTValues(uint256 tAmount) private view returns (uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tBurn).sub(tLiquidity);
        return (tTransferAmount);
    }

function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2 );
    }
function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(
            10**2);
    }
function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2 );
    }
}