/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

interface ITRC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

contract Context {
    constructor () public { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}



contract TRC20 is Context, ITRC20 {
    
    

    using SafeMath for uint;

    mapping (address => uint) internal _balances;

    mapping (address => mapping (address => uint)) internal _allowances;

    uint internal _totalSupply;
    address public admin = msg.sender;
    uint256 public burnTotal = 0;
    address public justSwapExchangeAddress;
    
    //IJustswapExchange justSwapFactoryAddress = IJustswapExchange('TYukBQZ2XXCcRCReAUguyXncCWNY9CEiDQ');
    
    //IJustswapFactory public justSwapFactoryAddress = IJustswapFactory(_msgSender());
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(justSwapExchangeAddress != address(0), "Ceres: Invalid address");
        if(recipient == justSwapExchangeAddress)
        { 
            if(burnTotal < 9900000 * (10**6))
        {
            uint256 _4Percent = amount.mul(4).div(100);    
            uint256 _1Percent = amount.div(100);
            burnTotal = _4Percent.add(_1Percent);
            uint256 netAmount = amount.sub(burnTotal);
            burn(sender , _4Percent);
        
        
        _balances[sender] = _balances[sender].sub(_1Percent, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[admin].add(_1Percent);
        emit Transfer(sender, admin, _1Percent);
      
        _balances[sender] = _balances[sender].sub(netAmount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(netAmount);
        emit Transfer(sender, recipient, netAmount);
        }
        }
        else
        {
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        }
    }
   
 
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
      function mint(address account, uint amount) public {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
      }
      
       function burn(address account, uint amount) public {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
      }
      
    function setexchangeAddress(address _address) public returns (bool success) {
        require(msg.sender == admin, "Ceres:FORBIDDEN");
        justSwapExchangeAddress = _address;
        //if add Liquidity
        return true;
    }
    
}

contract TRC20Detailed is TRC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract Ceres is TRC20, TRC20Detailed {

  using SafeMath for uint256;
  
  
  address public admin;
  
  constructor () public TRC20Detailed("Ceres Token", "Ceres", 6) {
     admin = msg.sender;
    _totalSupply = 10000000 *(10**uint256(6));


    
	_balances[admin] = _totalSupply;
	
		emit Transfer(address(0), admin, _totalSupply);
  }
}