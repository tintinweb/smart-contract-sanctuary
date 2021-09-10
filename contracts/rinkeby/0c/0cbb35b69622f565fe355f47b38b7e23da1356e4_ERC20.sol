/**
 *Submitted for verification at Etherscan.io on 2020-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Address.sol";
import "./SafeMath.sol";
import "./IERC20Interface.sol";

contract ERC20 is IERC20 {
    using SafeMath for uint256;
    using Address for address;

    struct StakedToken {
        uint256 amount;
        uint256 expiredAt;
        uint256 rate;
        int256 claimed;
    }

    event Locked(address indexed account, uint256 amount, uint256 expiredAt);
    event Unlocked(address indexed account, uint256 index, uint256 amount, uint256 rate); // rate = 0 --> cancel, rate > 0 --> unlocked

    mapping (address => uint256) private _balances;
    mapping (address => StakedToken[]) private _stakedTokens;
    // address[] private _lockedAddress;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;
    address private _owner;
    uint256 private _lockDuration = 14 days;
    uint256 private _interestRate = 20; // %

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _owner = msg.sender;
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
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
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view {
        // super._beforeTokenTransfer(from, to, amount);

        //if (from == address(0)) { // When minting tokens
        //    require(totalSupply().add(amount) <= _cap, "ERC20Capped: cap exceeded");
        //    return;
        //}
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function setDuration(uint256 duration) public onlyOwner {
        if (duration > 0) {
            _lockDuration = duration;
        }
    }

    function setInterest(uint256 interest) public onlyOwner {
        if (_interestRate < 100 && _interestRate >= 0) {
            _interestRate = interest;
        }
    }

    function getLockDuration() public view returns (uint256) {
        return _lockDuration;
    }

    function currentInterestRate() public view returns (uint256) {
        return _interestRate;
    }
    
    function stakeTotal() public view returns (uint256) {
        return _stakedTokens[msg.sender].length;
    }
    
    function stake(uint256 index) public view returns (uint256, uint256, uint256, int256) {
        if (index < 0 || index >= _stakedTokens[msg.sender].length) {
            return (0, 0, 0, 0);
        }

        return (_stakedTokens[msg.sender][index].amount, _stakedTokens[msg.sender][index].expiredAt, _stakedTokens[msg.sender][index].rate, _stakedTokens[msg.sender][index].claimed);
    }
    
    function lock(uint256 amount) public {
        uint256 expiredAt = now.add(_lockDuration);

        require(amount > 0 && amount <= balanceOf(msg.sender), "Invalid amount");
        require(msg.sender != _owner, "Invalid address");

        _transfer(msg.sender, _owner, amount);
        _stakedTokens[msg.sender].push(StakedToken(amount, expiredAt, _interestRate, 0));
        emit Locked(msg.sender, amount, expiredAt);
    }
    
    function unlock(uint256 index) public {
        require(index >= 0 && index < _stakedTokens[msg.sender].length, "Index out of range");
        require(_stakedTokens[msg.sender][index].claimed == 0, "This stake is claimed");
        require(_stakedTokens[msg.sender][index].expiredAt <= now, "The unlocked date has not yet came");

        uint256 amount = _stakedTokens[msg.sender][index].amount;
        uint256 rate = _stakedTokens[msg.sender][index].rate;
        uint256 interest = amount.mul(rate).div(100);
        if (amount > 0) {
            _transfer(_owner, msg.sender, amount.add(interest));
        }
        _stakedTokens[msg.sender][index].claimed = 1;
        emit Unlocked(msg.sender, index, amount, rate);
    }
    
    function unlockAll() public {
        uint256 amount = 0;
        uint256 interest = 0;

        for (uint256 i = 0; i < _stakedTokens[msg.sender].length; i++) {
            if (_stakedTokens[msg.sender][i].claimed != 0 || _stakedTokens[msg.sender][i].expiredAt > now) {
                continue;
            }

            uint256 currentAmount = _stakedTokens[msg.sender][i].amount;
            uint256 rate = _stakedTokens[msg.sender][i].rate;
            amount = amount.add(currentAmount);
            interest = interest.add(currentAmount.mul(rate).div(100));
            
            _stakedTokens[msg.sender][i].claimed = 1;
            emit Unlocked(msg.sender, i, currentAmount, rate);
        }

        if (amount > 0) {
            _transfer(_owner, msg.sender, amount.add(interest));
        }
    }
    
    function cancel(uint256 index) public {
        if (index < 0 || index >= _stakedTokens[msg.sender].length) {
            return;
        }
        
        if (_stakedTokens[msg.sender][index].claimed != 0) {
            return;
        }
        
        uint256 amount = _stakedTokens[msg.sender][index].amount;
        if (amount > 0) {
            _transfer(_owner, msg.sender, amount);
        }
        _stakedTokens[msg.sender][index].claimed = -1;
        emit Unlocked(msg.sender, index, amount, 0);
    }
    
    function cancelAll() public {
        uint256 amount = 0;

        for (uint256 i = 0; i < _stakedTokens[msg.sender].length; i++) {
            if (_stakedTokens[msg.sender][i].claimed != 0) {
                continue;
            }

            amount = amount.add(_stakedTokens[msg.sender][i].amount);
            _stakedTokens[msg.sender][i].claimed = -1;
            emit Unlocked(msg.sender, i, amount, 0);
        }

        if (amount > 0) {
            _transfer(_owner, msg.sender, amount);
        }
    }
}