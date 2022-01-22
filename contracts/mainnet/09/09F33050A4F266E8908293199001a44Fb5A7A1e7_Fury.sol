/**
 *Submitted for verification at Etherscan.io on 2022-01-22
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

    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Pausable is Ownable {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }
    
    function pause() external virtual onlyOwner {
        _pause();
    }
    
    function unpause() external virtual onlyOwner {
        _unpause();
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


interface ILosslessController {
    function beforeTransfer(address sender, address recipient, uint256 amount) external;

    function beforeTransferFrom(address msgSender, address sender, address recipient, uint256 amount) external;

    function beforeApprove(address sender, address spender, uint256 amount) external;

    function beforeIncreaseAllowance(address msgSender, address spender, uint256 addedValue) external;

    function beforeDecreaseAllowance(address msgSender, address spender, uint256 subtractedValue) external;
}

contract Fury is Pausable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    //120 000 000
    uint256 private _totalSupply = 120e6 ether;
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    address public recoveryAdmin;
    address private recoveryAdminCanditate;
    bytes32 private recoveryAdminKeyHash;
    address public admin;
    uint256 public timelockPeriod;
    uint256 public losslessTurnOffTimestamp;
    bool public isLosslessTurnOffProposed;
    bool public isLosslessOn = true;
    ILosslessController public lossless;

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event RecoveryAdminChangeProposed(address indexed candidate);
    event RecoveryAdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event LosslessTurnOffProposed(uint256 turnOffDate);
    event LosslessTurnedOff();
    event LosslessTurnedOn();

    constructor(address admin_, address recoveryAdmin_, uint256 timelockPeriod_, address lossless_) {
        admin = admin_;
        recoveryAdmin = recoveryAdmin_;
        timelockPeriod = timelockPeriod_;
        lossless = ILosslessController(lossless_);
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // --- LOSSLESS modifiers ---

    modifier lssAprove(address spender, uint256 amount) {
        if (isLosslessOn) {
            lossless.beforeApprove(_msgSender(), spender, amount);
        } 
        _;
    }

    modifier lssTransfer(address recipient, uint256 amount) {
        if (isLosslessOn) {
            lossless.beforeTransfer(_msgSender(), recipient, amount);
        } 
        _;
    }

    modifier lssTransferFrom(address sender, address recipient, uint256 amount) {
        if (isLosslessOn) {
            lossless.beforeTransferFrom(_msgSender(), sender, recipient, amount);
        }
        _;
    }

    modifier lssIncreaseAllowance(address spender, uint256 addedValue) {
        if (isLosslessOn) {
            lossless.beforeIncreaseAllowance(_msgSender(), spender, addedValue);
        }
        _;
    }

    modifier lssDecreaseAllowance(address spender, uint256 subtractedValue) {
        if (isLosslessOn) {
            lossless.beforeDecreaseAllowance(_msgSender(), spender, subtractedValue);
        }
        _;
    }

    modifier onlyRecoveryAdmin() {
        require(_msgSender() == recoveryAdmin, "LERC20: Must be recovery admin");
        _;
    }

    // --- LOSSLESS management ---

    function getAdmin() external view returns (address) {
        return admin;
    }

    function transferOutBlacklistedFunds(address[] calldata from) external {
        require(_msgSender() == address(lossless), "LERC20: Only lossless contract");
        for (uint i = 0; i < from.length; i++) {
            _transfer(from[i], address(lossless), balanceOf(from[i]));
        }
    }

    function setLosslessAdmin(address newAdmin) external onlyRecoveryAdmin {
        require(newAdmin != address(0), "LERC20: Cannot be zero address");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    function transferRecoveryAdminOwnership(address candidate, bytes32 keyHash) external onlyRecoveryAdmin {
        require(candidate != address(0), "LERC20: Cannot be zero address");
        recoveryAdminCanditate = candidate;
        recoveryAdminKeyHash = keyHash;
        emit RecoveryAdminChangeProposed(candidate);
    }

    function acceptRecoveryAdminOwnership(bytes memory key) external {
        require(_msgSender() == recoveryAdminCanditate, "LERC20: Must be canditate");
        require(keccak256(key) == recoveryAdminKeyHash, "LERC20: Invalid key");
        emit RecoveryAdminChanged(recoveryAdmin, recoveryAdminCanditate);
        recoveryAdmin = recoveryAdminCanditate;
    }

    function proposeLosslessTurnOff() external onlyRecoveryAdmin {
        losslessTurnOffTimestamp = block.timestamp + timelockPeriod;
        isLosslessTurnOffProposed = true;
        emit LosslessTurnOffProposed(losslessTurnOffTimestamp);
    }

    function executeLosslessTurnOff() external onlyRecoveryAdmin {
        require(isLosslessTurnOffProposed, "LERC20: TurnOff not proposed");
        require(losslessTurnOffTimestamp <= block.timestamp, "LERC20: Time lock in progress");
        isLosslessOn = false;
        isLosslessTurnOffProposed = false;
        emit LosslessTurnedOff();
    }

    function executeLosslessTurnOn() external onlyRecoveryAdmin {
        isLosslessTurnOffProposed = false;
        isLosslessOn = true;
        emit LosslessTurnedOn();
    }

    // --- ERC20 methods ---

    function name() external virtual returns (string memory) {
        return "Engines of Fury Token";
    }

    function symbol() external virtual returns (string memory) {
        return "FURY";
    }

    function decimals() external virtual returns (uint8) {
        return 18;
    }

    function totalSupply() external view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external virtual lssTransfer(recipient, amount) returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external virtual lssAprove(spender, amount) returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external virtual lssTransferFrom(sender, recipient, amount) returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual lssIncreaseAllowance(spender, addedValue) returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual lssDecreaseAllowance(spender, subtractedValue) returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
    function burn(uint256 amount) external virtual {
        _burn(_msgSender(), amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer();

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

  
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer();

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

    function _beforeTokenTransfer() internal virtual {
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}