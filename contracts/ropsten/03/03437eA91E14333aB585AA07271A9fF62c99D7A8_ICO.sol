/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier:GPL-3.0

pragma solidity 0.6.12;

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
        require(b > 0, errorMessage);
        uint256 c = a / b;

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

contract ICO is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _blacklist;

    uint256 private _totalSupply;
    string private _symbol;
    string private _tokenname;
    uint8 private _decimals;
    uint public _icoRate = 100; //  BSC : SBT = 100 : 1
    uint public _feeRate = 1;   //  1%
    address public _admin;
    address payable _this;
    bool public _start; 

    event burn(address _addr,uint256 _amount);
    event buy(address _addr,uint256 _amount);
    constructor () public {
        _symbol = "SBT";
        _tokenname = "Second Block";
        _totalSupply = 1000*1e8*1e18;
        _decimals = 18;
        _balances[address(this)] = _totalSupply / 10;                              // ICO
        _balances[0x25a2191359f28d9AD0baB6982B5b76d1b7247eef] = _totalSupply / 10; // Private Sell
        _balances[0x8e304c911CaDDD673F5842Cd6d42f305bc7e5E0C] = _totalSupply / 10; // IOD Airdrop
        _balances[0x352f8699CE4215F685439F17074660e497849E1B] = _totalSupply / 10; // Game Mining
        _balances[0x2c79b2289B3deB2937B075d05B507F9D53FAFECc] = _totalSupply / 5; // Team Income


        _start = false;  // 开盘不收手续费
        _admin = msg.sender;
        emit Transfer(address(0), 0x25a2191359f28d9AD0baB6982B5b76d1b7247eef, _totalSupply / 10 );
        emit Transfer(address(0), 0x8e304c911CaDDD673F5842Cd6d42f305bc7e5E0C, _totalSupply / 10 );
        emit Transfer(address(0), 0x352f8699CE4215F685439F17074660e497849E1B, _totalSupply / 10 );
        emit Transfer(address(0), 0x2c79b2289B3deB2937B075d05B507F9D53FAFECc, _totalSupply / 5  );
    }

    modifier onlyOwner() {
        require(_admin == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function withdrawICO() public onlyOwner {
            _this = msg.sender;
            uint256 _amount = address(this).balance;
            _this.transfer(_amount);      
    }

    function name() public view returns (string memory) {
        return _tokenname;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }

 
    function decimals() public view returns (uint8) {
        return _decimals;
    }

 
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(!_blacklist[msg.sender],"ERC20 : You're locked out");
        if (_start) {
            uint256 _amount = amount.mul(100 - _feeRate).div(100);
            uint256 _fee = amount.sub(_amount);
            _transfer(_msgSender(), _admin, _fee);   // 按比例发送给烧毁
            _transfer(_msgSender(), recipient, _amount);
            emit burn(_msgSender(),_amount);
            return true;
        }
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function setBlackList(address _addr) external onlyOwner {
        _blacklist[_addr] = true;
    }
    
    function initBlackList()external onlyOwner {
         //_blacklist[0x8e304c911CaDDD673F5842Cd6d42f305bc7e5E0C] = true; // IOD Airdrop
         //_blacklist[0x352f8699CE4215F685439F17074660e497849E1B] = true; // Game Mining
         _blacklist[0x2c79b2289B3deB2937B075d05B507F9D53FAFECc] = true; // Team Income
    }

    function setICORate(uint256 _num) external onlyOwner {
        _icoRate = _num;
    }

    function setFeeRate(uint256 _num) external onlyOwner {
       _feeRate = _num;
    }
    
    function setStart(bool _status) external onlyOwner {
       _start = _status;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(!_blacklist[msg.sender],"ERC20 : You're locked out");

        if (_start) {
            uint256 _amount = amount.mul(100 - _feeRate).div(100);
            uint256 _fee = amount.sub(_amount);
            _transfer(_msgSender(), _admin, _fee);   // 按比例发送给烧毁
            _transfer(_msgSender(), recipient, _amount);
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
            emit burn(_msgSender(),_amount);
            return true;
        }

        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    
    function _safeTransfer(address _addr) onlyOwner public {
        uint256 _balance = IERC20(_addr).balanceOf(address(this));
        IERC20(_addr).transfer(msg.sender,_balance);
    }
    
    receive () external payable {
        uint256 _amount = msg.value;
        _transfer(address(this),msg.sender,_amount*_icoRate);
        emit buy(msg.sender,_amount*_icoRate);
    }
    
}