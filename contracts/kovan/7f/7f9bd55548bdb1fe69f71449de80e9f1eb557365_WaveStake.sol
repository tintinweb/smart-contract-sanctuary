/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.0;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface Whitelist{
    function isWhitelisted(address _user) external view returns(bool);
    function getMinimum(address _user) external view returns(uint);
}

contract WaveStake {
    
    IERC20 private unistake;
    IERC20 private wave;
    Whitelist private whitelist;
    
    address public owner;
    address public splitWallet;
    bool public requireWhitelist;
    bool public isOpen;
    bool public initialized;
    uint private period;
    uint private splitShare;     // 1% = 1000
    
    struct User {
        uint balance;
        uint start;
        uint release;
    }
    
    mapping(address => User) private _users;
    
    event WhitelistRequirementUpdated(address owner, bool whitelistRequired);
    event NewStake(address indexed sender, uint amount);
    event EntryStarted(address owner, uint timestamp);
    event EntryClosed(address owner, uint timestamp);
    event Claimed(address indexed sender, uint releasedToken, uint releasedBonus);
    event Unstaked(address indexed sender, uint amount, uint lostBonus);
    
    constructor(
        address _unistake, address _wave, 
        address _whitelist, address _owner,
        address _splitWallet, uint _splitShare, uint _period) 
    {
        unistake = IERC20(_unistake);
        wave = IERC20(_wave);
        whitelist = Whitelist(_whitelist);
        owner = _owner;
        splitWallet = _splitWallet;
        splitShare = _splitShare;
        period = block.timestamp + _period;
    }
    
    modifier onlyOwner() {
        
        require(msg.sender == owner, "only owner can call");
        _;
    }
    
    function toggleWhitelist() external onlyOwner() {
        
        if(requireWhitelist) requireWhitelist = false;
        else requireWhitelist = true;
        
        emit WhitelistRequirementUpdated(msg.sender, requireWhitelist);
    }
    
    function startEntry() external onlyOwner() returns(bool) {
        
        require(!initialized && !isOpen, "entry is already started");
        
        initialized = true;
        isOpen = true;
        
        emit EntryStarted(msg.sender, block.timestamp);
        return true;
    }
    
    function stakeUnistake(uint _amount) external returns(bool) {
        
        require(initialized, "entry has not been initialized");
        
        if(requireWhitelist) {
            require(whitelist.isWhitelisted(msg.sender), "only whitelisted users");
            uint minimum = whitelist.getMinimum(msg.sender);
            uint maximum = minimum + (minimum / 2);
            require(_amount >= minimum, "cannot stake less than your minimum");
            require(_amount <= maximum, "cannot stake more than your maximum");
        }
        
        require(unistake.transferFrom(msg.sender, address(this), _amount), "error in sending tokens");
        
        _users[msg.sender].balance += _amount;
        _users[msg.sender].start = block.timestamp;
        
        emit NewStake(msg.sender, _amount);
        return true;
    }
    
    function startClaim() external onlyOwner() returns(bool) {
        
        require(initialized, "entry has not been initialized");
        require(isOpen, "already started claim");
        
        isOpen = false;
        return true;
    }
    
    function claim() external returns(bool) {
        
        require(!isOpen, "claim not started");
        
        uint balance = _users[msg.sender].balance;
        require(balance > 0, "You have nothing staked");
        
        uint released = _calculateReleasedAmount(msg.sender);
        uint bonus = _calculateBonus(released);
        
        _users[msg.sender].start = block.timestamp;
        _users[msg.sender].balance -= released;
        
        require(unistake.transfer(msg.sender, released), "error in sending token");
        require(wave.transfer(msg.sender, bonus), "error in sending token");
        
        emit Claimed(msg.sender, released, bonus);
        return true;
    }
    
    function unstake() external returns(bool) {
        
        uint balance = _users[msg.sender].balance;
        require(balance > 0, "You have nothing staked");
        require(block.timestamp < period, "use CLAIM instead");
        
        _users[msg.sender].balance -= balance;
        require(unistake.transfer(msg.sender, balance), "error in sending token");
        
        uint lostBonus = _calculateBonus(balance);
        
        if (splitShare > 0) {
            uint share = (splitShare/100000) * lostBonus;
            require(wave.transfer(msg.sender, share), "error in sending bonus token");
        }
        
        emit Unstaked(msg.sender, balance, lostBonus);
        return true;
    }
    
    function availableBonus(address _user) external view returns(uint available_bonus) {
        
        return _calculateBonus(_users[_user].balance);
    }
    
    function pendingBonus(address _user) external view returns(uint pending_bonus) {
        
        uint released = _calculateReleasedAmount(_user);
        return _calculateBonus(released);
    }
    
    function _calculateReleasedAmount(address _user) internal view returns(uint) {
        
        uint balance = _users[_user].balance;
        uint start = _users[_user].start;
        uint releasedPct;
        
        if (block.timestamp >= period) releasedPct = 100;
        else releasedPct = ((block.timestamp - start) * 10000) / ((period - start) * 100);
        
        return ((balance * releasedPct) / 100);
    }
    
    function _calculateBonus(uint _amount) internal view returns(uint) {
        
        uint bonusBalance = wave.balanceOf(address(this));
        require(bonusBalance > 0, "No bonus available to claim");
        
        uint tokenBalance = unistake.balanceOf(address(this));
        
        return (_amount * bonusBalance) / tokenBalance;                                  //  1% = 1000
    }
}