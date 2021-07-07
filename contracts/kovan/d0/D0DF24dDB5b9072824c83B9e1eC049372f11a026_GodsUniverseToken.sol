/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

contract GodsUniverseToken is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public superAccounts;
    mapping(address => address) public referrers;
    mapping(address => uint256) public airdrops;
    mapping(address => uint256) public airdropCounts;

    uint256 private _totalSupply = 10**15 * 10**6;
    string private _name = "Gods Universe Token";
    string private _symbol = "GODT";
    uint8 private _decimals = 6;

    address public managerAccount; //管理员账号地址
    address public fundAccount;    //基金会收款地址
    address public airdropAccount; //空投账号地址
    uint256 public airdropOnce;    //每个账号接收空投数量
    uint256 public airdropOnceReward;

    event SetReferrerAccount(address indexed selfAccount, address indexed referrerAccount);
    event SetSuperAccount(address indexed owner, address indexed superAccount);
    event DelSuperAccount(address indexed owner, address indexed superAccount);

    constructor() {
        superAccounts[_msgSender()] = true;
        _balances[_msgSender()] = _totalSupply;
        managerAccount = _msgSender();
        fundAccount = _msgSender();
        airdropAccount = _msgSender();

        emit Transfer(address(0), owner(), _totalSupply);
    }

    function setReferrerAccount(address _referrerAccount) public {
        require(referrers[_msgSender()] == address(0), "You already have a referrer.");
        referrers[_msgSender()] = _referrerAccount;

        emit SetReferrerAccount(_msgSender(), _referrerAccount);
    }

    function setSuperAccount(address _superAccount) public onlyOwner() {
        superAccounts[_superAccount] = true;
        
        emit SetSuperAccount(owner(), _superAccount);
    }
    
    function delSuperAccount(address _oldAddress) public onlyOwner() {
        require(superAccounts[_oldAddress], "It must be a super account.");
        delete superAccounts[_oldAddress];

        emit DelSuperAccount(owner(), _oldAddress);
    }

    function setManager(address _managerAccount) public {
        require(owner() == _msgSender() || managerAccount == _msgSender(), "You have no authority.");
        managerAccount = _managerAccount;
    }
    
    function setFundAccount(address _fundAccount) public {
        require(owner() == _msgSender() || fundAccount == _msgSender(), "You have no authority.");
        fundAccount = _fundAccount;
    }

    function setAirdropAccount(address _airdropAccount) public {
        require(owner() == _msgSender() || airdropAccount == _msgSender(), "You have no authority.");
        airdropAccount = _airdropAccount;
    }

    function setAirdropOnceAmount(uint256 _amount, uint256 _rewardAmount) public {
        require(owner() == _msgSender() || managerAccount == _msgSender(), "You have no authority.");
        airdropOnce = _amount;
        airdropOnceReward = _rewardAmount;
    }

    function addAirdropCount(address _account, uint256 _count) public {
        require(owner() == _msgSender() || managerAccount == _msgSender(), "You have no authority.");
        airdropCounts[_account] = airdropCounts[_account].add(_count);
    }

    function subAirdropCount(address _account, uint256 _count) public {
        require(owner() == _msgSender() || managerAccount == _msgSender(), "You have no authority.");
        airdropCounts[_account] = airdropCounts[_account].sub(_count);
    }
    
    function airdrop(address receiver) public {
        require(airdropCounts[_msgSender()] > 0 && referrers[receiver] == _msgSender(), "You need have airdrop authority and be receiver's referrer.");
        require(airdrops[receiver] == 0, "Receiver has been airdropped.");
        airdropCounts[_msgSender()] = airdropCounts[_msgSender()].sub(1);
        airdrops[receiver] = airdropOnce;
        _transfer(address(this), receiver, airdropOnce);
        _transfer(address(this), _msgSender(), airdropOnceReward);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (superAccounts[sender] || superAccounts[recipient]) {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        } else {
             _transferWithFee(sender, recipient, amount);
        }
    }

    function _transferWithFee(address from, address to, uint256 amount) internal virtual {
        _balances[from] = _balances[from].sub(amount);

        uint256 burnAmount = amount.mul(2).div(100);
        uint256 addAmount = amount.sub(burnAmount);
        _balances[address(0)] = _balances[address(0)].add(burnAmount);

        uint256 fundAmount = amount.mul(2).div(100);
        addAmount = addAmount.sub(fundAmount);
        _balances[fundAccount] = _balances[fundAccount].add(fundAmount);

        uint256 referrerAmount = amount.mul(2).div(100);
        addAmount = addAmount.sub(referrerAmount);
        address referrerAccount = referrers[from];
        if (referrerAccount == address(0)) {
            referrerAccount = fundAccount;
        }
        _balances[referrerAccount] = _balances[referrerAccount].add(referrerAmount);

        uint256 airdropAmount = amount.mul(2).div(100);
        addAmount = addAmount.sub(airdropAmount);
        _balances[airdropAccount] = _balances[airdropAccount].add(airdropAmount);

        _balances[to] = _balances[to].add(addAmount);

        emit Transfer(from, to, addAmount);
        emit Transfer(from, fundAccount, fundAmount);
        emit Transfer(from, referrerAccount, referrerAmount);
        emit Transfer(from, airdropAccount, airdropAmount);
        emit Transfer(from, address(0), burnAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}