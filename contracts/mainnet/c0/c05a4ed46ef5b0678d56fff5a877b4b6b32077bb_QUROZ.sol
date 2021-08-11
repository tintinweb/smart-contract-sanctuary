/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract Freezable is Context {
    event Freeze(address indexed holder);
    event Unfreeze(address indexed holder);

    mapping(address => bool) private _frozenAccount;

    modifier whenNotFrozen(address holder) {
        require(!_frozenAccount[holder]);
        _;
    }

    function isFrozen(address holder) public view virtual returns (bool frozen) {
        return _frozenAccount[holder];
    }

    function _freezeAccount(address holder) internal virtual returns (bool success) {
        require(!isFrozen(holder));
        _frozenAccount[holder] = true;
        emit Freeze(holder);
        success = true;
    }

    function _unfreezeAccount(address holder) internal virtual returns (bool success) {
        require(isFrozen(holder));
        _frozenAccount[holder] = false;
        emit Unfreeze(holder);
        success = true;
    }
}

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
    }
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
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract ERC20Burnable is Context, ERC20, Ownable {
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
    unchecked {
        _approve(account, _msgSender(), currentAllowance - amount);
    }
        _burn(account, amount);
    }
}

abstract contract ERC20Lockable is ERC20, Ownable {
    struct LockInfo {
        uint256 _releaseTime;
        uint256 _amount;
    }

    mapping(address => LockInfo[]) internal _locks;
    mapping(address => uint256) internal _totalLocked;

    event Lock(address indexed from, uint256 amount, uint256 releaseTime);
    event Unlock(address indexed from, uint256 amount);

    modifier checkLock(address from, uint256 amount) {
        uint256 length = _locks[from].length;
        if (length > 0) {
            autoUnlock(from);
        }
        require(_balances[from] >= _totalLocked[from] + amount, "checkLock : balance exceed");
        _;
    }

    function _lock(address from, uint256 amount, uint256 releaseTime) internal returns (bool success)
    {
        require(
            _balances[from] >= amount + _totalLocked[from],
            "lock : locked total should be smaller than balance"
        );
        _totalLocked[from] = _totalLocked[from] + amount;
        _locks[from].push(LockInfo(releaseTime, amount));
        emit Lock(from, amount, releaseTime);
        success = true;
    }

    function _unlock(address from, uint256 index) internal returns (bool success) {
        LockInfo storage info = _locks[from][index];
        _totalLocked[from] = _totalLocked[from] - info._amount;
        emit Unlock(from, info._amount);
        _locks[from][index] = _locks[from][_locks[from].length - 1];
        _locks[from].pop();
        success = true;
    }

    function lock(address recipient, uint256 amount, uint256 releaseTime) public onlyOwner returns (bool success) {
        require(_balances[recipient] >= amount, "There is not enough balance of holder.");
        _lock(recipient, amount, releaseTime);

        success = true;
    }

    function autoUnlock(address from) public returns (bool success) {
        for (uint256 i = 0; i < _locks[from].length; i++) {
            if (_locks[from][i]._releaseTime < block.timestamp) {
                _unlock(from, i);
            }
        }
        success = true;
    }

    function unlock(address from, uint256 idx) public onlyOwner returns (bool success) {
        require(_locks[from].length > idx, "There is not lock info.");
        _unlock(from, idx);
        success = true;
    }

    function releaseLock(address from) external onlyOwner returns (bool success){
        require(_locks[from].length > 0, "There is not lock info.");
        //        uint256 i = _locks[from].length - 1;
        //        _unlock(from, i);
        for (uint256 i = _locks[from].length; i > 0; i--) {
            _unlock(from, i - 1);
        }
        success = true;
    }

    function transferWithLock(address recipient, uint256 amount, uint256 releaseTime) external onlyOwner returns (bool success)
    {
        require(recipient != address(0));
        _transfer(msg.sender, recipient, amount);
        _lock(recipient, amount, releaseTime);
        success = true;
    }

    function lockInfo(address locked, uint256 index) public view returns (uint256 releaseTime, uint256 amount)
    {
        LockInfo memory info = _locks[locked][index];
        releaseTime = info._releaseTime;
        amount = info._amount;
    }

    function totalLocked(address locked) public view returns (uint256 amount, uint256 length){
        amount = _totalLocked[locked];
        length = _locks[locked].length;
    }
}

contract QUROZ is ERC20, Pausable, Freezable, ERC20Burnable, ERC20Lockable {

    constructor() ERC20("Qfora", "QUROZ") {
        _mint(msg.sender, 1200000000 * (10 ** decimals()));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function freezeAccount(address holder) public onlyOwner {
        _freezeAccount(holder);
    }

    function unfreezeAccount(address holder) public onlyOwner {
        _unfreezeAccount(holder);
    }

    function transfer(address to, uint256 amount) public checkLock(msg.sender, amount) override returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public checkLock(from, amount) override returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    function balanceOf(address holder) public view override returns (uint256 balance) {
        uint256 totalBalance = super.balanceOf(holder);
        uint256 avaliableBalance = 0;
        (uint256 lockedBalance, uint256 lockedLength) = totalLocked(holder);
        require(totalBalance >= lockedBalance);

        if (lockedLength > 0) {
            for (uint i = 0; i < lockedLength; i++) {
                (uint256 releaseTime, uint256 amount) = lockInfo(holder, i);
                if (releaseTime <= block.timestamp) {
                    avaliableBalance += amount;
                }
            }
        }

        balance = totalBalance - lockedBalance + avaliableBalance;
    }

    function balanceOfTotal(address holder) public view returns (uint256 balance) {
        balance = super.balanceOf(holder);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused whenNotFrozen(from) override {
        super._beforeTokenTransfer(from, to, amount);
    }
}