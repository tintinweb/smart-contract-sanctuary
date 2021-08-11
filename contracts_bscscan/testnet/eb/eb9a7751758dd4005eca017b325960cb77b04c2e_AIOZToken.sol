// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Ownable.sol";
import './TokenTimelock.sol';

contract ERC20 is IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
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

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

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

contract AIOZToken is ERC20, Ownable {
    uint256 private _maxTotalSupply;
    
    constructor() ERC20("DragonSoul", "DRAS") {
        _maxTotalSupply = 1000000000e18;
        
        // init timelock factory
        TimelockFactory timelockFactory = new TimelockFactory();

        // ERC20
        // public sales
        mint(0x076592ad72b79bBaBDD05aDd7d367f44f2CFf658, 10333333e18); // for Paid Ignition
        // private sales
        mint(0xF8477220f8375968E38a3B79ECA4343822b53af2, 73000000e18*25/100);
        address privateSalesLock = timelockFactory.createTimelock(this, 0xF8477220f8375968E38a3B79ECA4343822b53af2, block.timestamp + 30 days, 73000000e18*25/100, 30 days);
        mint(privateSalesLock, 73000000e18*75/100);
        // team
        address teamLock = timelockFactory.createTimelock(this, 0x82E83054CC631C0Da85Ca67087E45ca31b93F29b, block.timestamp + 180 days, 250000000e18*8/100, 30 days);
        mint(teamLock, 250000000e18);
        // advisors
        address advisorsLock = timelockFactory.createTimelock(this, 0xBbf78c2Ee1794229e31af81c83F4d5125F08FE0F, block.timestamp + 90 days, 50000000e18*8/100, 30 days);
        mint(advisorsLock, 50000000e18);
        // marketing
        mint(0x9E2F8e278585CAfD3308E894d2E09ffEc520b1E9, 30000000e18*10/100);
        address marketingERC20Lock = timelockFactory.createTimelock(this, 0x9E2F8e278585CAfD3308E894d2E09ffEc520b1E9, block.timestamp + 30 days, 30000000e18*5/100, 30 days);
        mint(marketingERC20Lock, 30000000e18*90/100);
        // exchange liquidity provision
        mint(0x6c3D8872002B66C808aE462Db314B87962DCC7aF, 23333333e18);
        // BEP20
        // public sales
        mint(0xc9Fc843DBAA8ccCcf37E09b67DeEa5f963E3919E, 6666667e18); // for BSCPad
        // ecosystem growth
        address growthLock = timelockFactory.createTimelock(this, 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615, block.timestamp + 90 days, 0, 0);
        mint(growthLock, 530000000e18);

        // // marketing
        // mint(0x7e318e80EB8e401451334cAa2278E39Da7F6C49B, 20000000e18*10/100);
        // address marketingBEP20Lock = timelockFactory.createTimelock(this, 0x7e318e80EB8e401451334cAa2278E39Da7F6C49B, block.timestamp + 30 days, 20000000e18*5/100, 30 days);
        // mint(marketingBEP20Lock, 20000000e18*90/100);
        // // exchange liquidity provision
        // mint(0x0a515Ac284E3c741575A4fd71C27e377a19D5E6D, 6666667e18);
    }

    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        require(totalSupply() + amount <= _maxTotalSupply, "AIOZ Token: mint more than the max total supply");
        _mint(account, amount);
        return true;
    }

    function burn(uint256 amount) public onlyOwner returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
}