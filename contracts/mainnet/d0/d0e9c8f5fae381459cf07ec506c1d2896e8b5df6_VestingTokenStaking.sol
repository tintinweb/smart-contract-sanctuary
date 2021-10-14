/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

interface IVestingToken {
    function vestingBalance(address _userAddr) external view
        returns (
            uint256 timestamp,
            uint256 totalBalance,
            uint256 tgeAmount,
            uint256 unlockedAmount,
            uint256 lockedAmount);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function customTransfer(address to, uint256 totalAmount, uint256 tgeAmount, uint256 unlockedTickAmount) external;
}

contract VestingTokenStaking is Initializable {
    address public admin_;
    bool public isPaused_;

    IVestingToken public token_;
    uint256 public maxStakeLimit_;  // may be zero here
    uint256 public apy_;            // in basis points
    uint256 public startDate_;      // may be zero here
    uint256 public period_;         // seconds

    uint256 public totalBalance_;   // total balance of all users
    mapping (address => uint256) public balances_;
    
    string private constant ERR_ZERO_ADDRESS = "Zero address provided";
    string private constant ERR_ALREADY_DONE = "Already done";
    string private constant ERR_ADMIN_ONLY = "Available for admin only";
    string private constant ERR_ZERO_APY = "Zero APY is not allowed";
    string private constant ERR_PERIOD_TOO_SMALL = "Period too small";
    string private constant ERR_ALREADY_STARTED = "Already started";
    string private constant ERR_NOT_FINISHED = "Not finished yet";
    string private constant ERR_START_DATE_INVALID = "Start date invalid";
    string private constant ERR_MAX_STAKE_LIMIT_TOO_SMALL = "Stake limit too small";
    string private constant ERR_TRYING_TO_DEPOSIT_ZERO = "Trying to deposit zero amount";
    string private constant ERR_MAX_LIMIT_REACHED = "Max limit reached";
    string private constant ERR_NOTHING_TO_WITHDRAW = "Nothing to withdrawal";
    string private constant ERR_TRANSFER_FAILURE = "Tokens transfer fails";
    string private constant ERR_NOT_PAUSED = "Not paused";
    string private constant ERR_PAUSED = "Paused";

    event Pause();
    event Resume();

    event SetStartDate(uint256 oldValue, uint256 newValue);
    event SetMaxStakeLimit(uint256 oldValue, uint256 newValue);

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 totalAmount, uint256 tgeAmount, uint256 unlockedAmount, address indexed toAddress);

    // constructor and initializer
    
    constructor() initializer {}

    function initialize(
        address _admin,
        IVestingToken _token,
        uint256 _maxStakeLimit, // may be zero here
        uint256 _apy,           // % in basis points
        uint256 _startDate,     // may be zero here
        uint256 _period         // seconds
        ) external initializer {

        require(_admin != address(0), ERR_ZERO_ADDRESS);
        require(address(_token) != address(0), ERR_ZERO_ADDRESS);
        require(_apy != 0, ERR_ZERO_APY);
        require(_period >= 60, ERR_PERIOD_TOO_SMALL);

        admin_ = _admin;
        token_ = _token;
        period_ = _period;
        apy_ = _apy;
        
        if (_startDate != 0) _setStartDate(_startDate);

        if (_maxStakeLimit != 0) _setMaxStakeLimit(_maxStakeLimit);
    }
    
    // modifiers

    modifier onlyAdmin() {
        require(admin_ == msg.sender, ERR_ADMIN_ONLY);
        _;
    }

    // setters

    function setStartDate(uint256 _newStartDate) external onlyAdmin {
        _setStartDate(_newStartDate);
    }
    
    function _setStartDate(uint256 _newStartDate) private {
        require(startDate_ != _newStartDate, ERR_ALREADY_DONE);
        require(startDate_ == 0 || block.timestamp < startDate_, ERR_ALREADY_STARTED);
        require(block.timestamp < _newStartDate, ERR_START_DATE_INVALID);
        
        emit SetStartDate(startDate_, _newStartDate);
        
        startDate_ = _newStartDate;
    }
    
    function setMaxStakeLimit(uint256 _newMaxStakeLimit) external onlyAdmin {
        _setMaxStakeLimit(_newMaxStakeLimit);
    }
    
    function _setMaxStakeLimit(uint256 _newMaxStakeLimit) private {
        require(maxStakeLimit_ != _newMaxStakeLimit, ERR_ALREADY_DONE);
        require(_newMaxStakeLimit >= totalBalance_, ERR_MAX_STAKE_LIMIT_TOO_SMALL);
        
        emit SetMaxStakeLimit(maxStakeLimit_, _newMaxStakeLimit);
        
        if (_newMaxStakeLimit < maxStakeLimit_) {
            uint256 delta = maxStakeLimit_ - _newMaxStakeLimit;
            maxStakeLimit_ = _newMaxStakeLimit;
            require(token_.transfer(msg.sender, _earnedAmount(delta)), ERR_TRANSFER_FAILURE);
        } else {
            require(token_.transferFrom(msg.sender, address(this), _earnedAmount(_newMaxStakeLimit - maxStakeLimit_)), ERR_TRANSFER_FAILURE);
            maxStakeLimit_ = _newMaxStakeLimit;
        }
    }

    // staking

    function depositToken(uint256 _amount) whenNotPaused external {
        require(startDate_ == 0 || block.timestamp < startDate_, ERR_ALREADY_STARTED);
        require(totalBalance_ + _amount <= maxStakeLimit_, ERR_MAX_LIMIT_REACHED); 
        require(_amount != 0, ERR_TRYING_TO_DEPOSIT_ZERO);

        require(token_.transferFrom(msg.sender, address(this), _amount), ERR_TRANSFER_FAILURE);

        totalBalance_ += _amount;
        balances_[msg.sender] += _amount;
        
        emit Deposit(msg.sender, _amount);
    }
    
    function canWithdrawToken(address _user) external view returns (bool) {
        return !isPaused_
            && startDate_ != 0
            && block.timestamp >= startDate_ + period_
            && balances_[_user] != 0;
    }

    function withdrawToken() external {
        withdrawToken(msg.sender);
    }

    function withdrawToken(address _toAddress) whenNotPaused public {
        require(_toAddress != address(0), ERR_ZERO_ADDRESS);
        require(startDate_ != 0 && block.timestamp >= startDate_ + period_, ERR_NOT_FINISHED);
        require(balances_[msg.sender] != 0, ERR_NOTHING_TO_WITHDRAW);

        uint256 userTotalAmount = balances_[msg.sender];
        balances_[msg.sender] = 0;
        totalBalance_ -= userTotalAmount;
        
        userTotalAmount += _earnedAmount(userTotalAmount);
        
        (, uint256 stakingTotalAmount, uint256 stakingTgeAmount, uint256 stakingUnlockedAmount, ) = token_.vestingBalance(address(this));
        
        uint256 userTgeAmount = _min(userTotalAmount * stakingTgeAmount / stakingTotalAmount, stakingTgeAmount);
        uint256 userUnlockedAmount = _min(userTotalAmount * stakingUnlockedAmount / stakingTotalAmount, stakingUnlockedAmount);
        
        token_.customTransfer(_toAddress, userTotalAmount, userTgeAmount, userUnlockedAmount);
            
        emit Withdrawal(msg.sender, userTotalAmount, userTgeAmount, userUnlockedAmount, _toAddress);
    }

    function balance(address _wallet) external view returns (uint256 depositAmount, uint256 currentAmount, uint256 finalAmount) {
        require(_wallet != address(0), ERR_ZERO_ADDRESS);
        
        depositAmount = balances_[_wallet];
        
        if (depositAmount != 0) {
            finalAmount = depositAmount + _earnedAmount(depositAmount);
            
            if (startDate_ == 0 || block.timestamp <= startDate_) {
                currentAmount = depositAmount;
            } else if (block.timestamp >= startDate_ + period_) {
                currentAmount = finalAmount;
            } else {
                currentAmount = finalAmount * (block.timestamp - startDate_) / period_;
            }
        }
    }
    
    // pausable
    
    modifier whenPaused() {
        require(isPaused_, ERR_NOT_PAUSED);
        _;
    }
    
    modifier whenNotPaused() {
        require(!isPaused_, ERR_PAUSED);
        _;
    }

    function pause() onlyAdmin whenNotPaused external {
        isPaused_ = true;
        emit Pause();
    }
    
    function resume() onlyAdmin whenPaused external {
        isPaused_ = false;
        emit Resume();
    }
    
    // heplers
    
    function earnedAmount(
        uint256 _amount,
        uint256 _apy,
        uint256 _period) external pure returns (uint256) {

        return _amount * _apy * _period / (10_000 * 365 days);
    }
    
    function _earnedAmount(uint256 _amount) private view returns (uint256) {
        return _amount * apy_ * period_ / (10_000 * 365 days);
    }
    
    function _min(uint256 _a, uint256 _b) private pure returns (uint256) {
        return _a <= _b ? _a : _b;
    }
}