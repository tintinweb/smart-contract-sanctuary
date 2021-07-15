/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

abstract contract Pausable is Context {
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract Whitelist is Ownable {
    mapping (address => bool) private _whitelists;

    function isWhitelist(address addr) public view returns (bool) {
        return _whitelists[addr];
    }

    function addWhitelist(address addr) public onlyOwner returns (bool) {
        require(!_whitelists[addr], "Whitelist: The address is whitelist");
        _whitelists[addr] = true;
        return true;
    }

    function removeWhitelist(address addr) public onlyOwner returns (bool) {
        require(_whitelists[addr], "Whitelist: The address is not whitelist");
        delete _whitelists[addr];
        return true;
    }
}

abstract contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances; // 'private' change to 'internal'

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

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

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

contract TTN is Context, ERC20, Ownable, Pausable, Whitelist {
    address private _lpAddr = address(0); // liquidity pool address
    address private _referPool = 0x1111111111111111111111111111111111111111;

    uint256 private _maxTime = 360 days;
    uint256 private _referrerReward = 100; // (x/10)%, 10%

    mapping (address => uint256) private _activeTimes;
    mapping (address => address) private _referrers;

    event Burn(address indexed burner, uint256 value);
    event BindReferrer(address indexed referrer, address indexed referee);
    event PayReferReward(address indexed referee, address indexed referrer, uint256 value);

    constructor() ERC20("TTN", "TTN") {
        _mint(_msgSender(), 95 * 10**9 * 10**18); // 95 billions
        // _mint(_referPool, 5 * 10**9 * 10**18); // 5 billions
        _mint(_referPool, 20000 * 10**18); // tmp 20000
        addWhitelist(_msgSender());
        _pause();
    }

    function lpAddr() public view returns (address) {
        return _lpAddr;
    }

    function maxTime() public view returns (uint256) {
        return _maxTime;
    }

    function referrerReward() public view returns (uint256) {
        return _referrerReward;
    }

    function activeTimeOf(address addr) public view returns (uint256) {
        return _activeTimes[addr];
    }

    function referrerOf(address addr) public view returns (address) {
        return _referrers[addr];
    }

    function setLpAddr(address addr) public onlyOwner returns (bool) {
        require(addr != address(0), "TIM: set lpAddr to the zero address");
        _lpAddr = addr;
        return true;
    }

    function setMaxTime(uint256 value) public onlyOwner returns (bool) {
        require(value != 0, "TIM: set maxTime to zero");
        _maxTime = value;
        return true;
    }

    function setReferrerReward(uint256 value) public onlyOwner returns (bool) {
        require(value <= 1000, "TIM: set referrerReward greater than 1000");
        _referrerReward = value;
        return true;
    }

    // Test function: need to be deleted before formal deployment
    function setActiveTime(address account, uint256 time) public onlyOwner returns (bool) {
        _activeTimes[account] = time;
        return true;
    }

    function pause() public onlyOwner returns (bool) {
        _pause();
        return true;
    }

    function unpause() public onlyOwner returns (bool) {
        _unpause();
        return true;
    }

    function withdraw(address cntr, address payable recipient, uint256 amount) public onlyOwner returns (bool) {
        if (cntr == address(0)) {
            uint256 balance = address(this).balance;
            require(balance >= amount, "TIM: withdraw amount exceeds balance");
            recipient.transfer(amount);
        } else {
            IERC20 token = IERC20(cntr);
            uint256 balance = token.balanceOf(address(this));
            require(balance >= amount, "TIM: withdraw amount exceeds balance");
            token.transfer(recipient, amount);
        }
        return true;
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
        emit Burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
        emit Burn(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount != 0, "TIM: transfer amount is zero");

        _beforeTokenTransfer(sender, recipient, amount);

        if (recipient != _lpAddr) {
            // When a non-LP address receives tokens, it needs to reset its activeTime
            if (_activeTimes[recipient] == 0) {
                _activeTimes[recipient] = block.timestamp;
            } else {
                uint256 holdTime = (block.timestamp - _activeTimes[recipient]) * _balances[recipient] / (_balances[recipient] + amount);
                _activeTimes[recipient] = block.timestamp - holdTime;
            }

            // When the recipient has no referrer, bind the sender as the referrer of the recipient
            if (_referrers[recipient] == address(0)) {
                _referrers[recipient] = sender;
                emit BindReferrer(sender, recipient);
            }

            // Send referrer's rewards
            address referrer = _referrers[recipient];
            if (sender == _lpAddr && referrer != address(0) && referrer != _lpAddr) {
                uint256 referAmount = amount * _referrerReward / 1000;
                if (referAmount > 0 && _balances[_referPool] >= referAmount) {
                    uint256 referrerBalance = _balances[referrer];

                    uint256 holdTime = (block.timestamp - _activeTimes[referrer]) * referrerBalance / (referrerBalance + referAmount);
                    _activeTimes[referrer] = block.timestamp - holdTime;

                    _balances[_referPool] -= referAmount;
                    _balances[referrer] += referAmount;
                    emit Transfer(_referPool, referrer, referAmount);
                    emit PayReferReward(recipient, referrer, referAmount);
                }
            }
        } else {
            // When selling tokens, the contract needs to determine whether it needs to be burned based on the holding time
            // Please DO NOT add liquidity to TIM, otherwise it will cause your tokens to be burned
            if (!isWhitelist(sender)) {
                uint256 holdTime = block.timestamp - _activeTimes[sender];
                if (holdTime < _maxTime) {
                    uint256 burnAmount = amount * _maxTime / holdTime - amount;
                    if (burnAmount > 0) {
                        require((amount + burnAmount) <= _balances[sender], "TIM: total amount exceeds balance");
                        _burn(sender, burnAmount);
                        emit Burn(sender, burnAmount);
                    }
                }
            }
        }

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);

        if (!isWhitelist(from)) {
            require(!paused(), "ERC20Pausable: token transfer while paused");
        }
    }
}