// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

contract Inflatex is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _inCouncil;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    
    address private _primaryAddress;
    uint256 private _inflationRate; //inflation per cycle (= inflation per _periodsInCycle * _periodSeconds seconds)
    
    uint256 private _turnoverSum;
    mapping(uint32 => uint256) private _turnoverRetention;
    uint32 private _oldestDay;
    
    uint32 private _periodsInCycle; //days per months
    uint32 private _periodSeconds; //seconds per day

    constructor(address primaryAddress) {
        _name = "Inflatex";
        _symbol = "INFL";
        
        _turnoverSum = 0;
        _periodsInCycle = uint32(30); //30
        _periodSeconds = uint32(86400); //86400
        
        _primaryAddress = primaryAddress;
        _inCouncil[primaryAddress] = true;
        _mint(primaryAddress, 21000000 * (10**decimals()));
        _oldestDay = _currentDay() - 1;
        uint256 initialRetetion = 21000000 * (10**decimals());
        _turnoverRetention[_oldestDay] = initialRetetion; //initial turnover to avoid very high first rates
        _turnoverSum += initialRetetion;
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

    function addToCouncil(address member) public {
        require(_inCouncil[_msgSender()], "Cannot add to council");
        _inCouncil[member] = true;
    }
    
    function getInflationRate() public view virtual returns (uint256) {
        return _inflationRate;
    }

    function setInflationRate(uint256 inflationRate) public {
        require(_inCouncil[_msgSender()], "Cannot set inflation rate");
        _inflationRate = inflationRate; //note that inflationRate cannot be negative given it is a uint256
    }

    function getPeriodsInCycle() public view virtual returns (uint32) {
        return _periodsInCycle;
    }

    function setPeriodsInCycle(uint32 periodsInCycle) public {
        require(_inCouncil[_msgSender()], "Cannot set periods in cycle");
        _periodsInCycle = periodsInCycle;
    }

    function getPeriodSeconds() public view virtual returns (uint32) {
        return _periodSeconds;
    }

    function setPeriodSeconds(uint32 periodSeconds) public {
        require(_inCouncil[_msgSender()], "Cannot set period seconds");
        _periodSeconds = periodSeconds;
    }    

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(balanceOf(_msgSender()) >= amount, "ERC20: transfer amount exceeds balance");
        uint256 burn = _calculateInflationBurn(amount);
        uint256 remainingAmount = amount - burn;
        _burn(_msgSender(), burn);
        _transfer(_msgSender(), recipient, remainingAmount);
        _addToTurnover(amount);
        return true;
    }
    
    function _calculateInflationBurn(uint256 amount) internal virtual returns (uint256) {
        uint256 b = (amount * _inflationRate * _totalSupply) / ((10**decimals() + _inflationRate) * turnover(amount) + 1);
        if (b > amount * 1353 / 10000) {
            return amount * 1353 / 10000;
        }
        return b;
    }
    
    /**
     * how many tokens have been moved
     */
    function turnover(uint256 amount) public returns (uint256) {
        //calculate the turnover as if amount were added
        
        uint32 periodAgo = _currentDay() - _periodsInCycle;
        while (_oldestDay < periodAgo) {
            _turnoverSum -= _turnoverRetention[_oldestDay];
            delete _turnoverRetention[_oldestDay];
            _oldestDay++;
        }
        
        return _turnoverSum + amount;
    }
    
    function getTurnover() public view virtual returns (uint256) {
        return _turnoverSum;
    }

    function _addToTurnover(uint256 amount) internal virtual {
        //add the given amount to the turnover
        _turnoverRetention[_currentDay()] += amount;
        _turnoverSum += amount;
    }
    
    function _currentDay() internal virtual view returns (uint32) {
        return uint32(block.timestamp / _periodSeconds);
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

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        _afterTokenTransfer(account, address(0), amount);
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

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}