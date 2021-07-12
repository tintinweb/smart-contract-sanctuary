/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.5.10;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}


contract CADE{
    using SafeMath for uint256;

    address public owner;
    
    bool public transferLock;
    bool public contractStatus;
    uint256 public poolAmount;
    uint256 public withdrawLimit;
    bool public withdrawStatus;

    mapping (address =>  uint256) public deposits;
    mapping (address => bool) public userStatus;

    event Deposit(address useraddr, uint256 amount, uint256 time);
    event Withdraw(address useraddr, uint256 amount, uint256 time);

    constructor(uint256 _withdrawLimit, bool _withdrawStatus) public {
        owner = msg.sender;
        contractStatus = true;
        transferLock = true;
        withdrawLimit = _withdrawLimit;
        withdrawStatus = _withdrawStatus;
    }
    /*
     * modifiers
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    modifier contractActive() {
        require(contractStatus, "Contract is inactive");
        _;
    }
    
    modifier isUnlocked() {
        require(!transferLock, "Locked");
        _;
    }
    
    modifier withdrawActive() {
        require(withdrawStatus, "Withdraw status inactive");
        _;
    }
    
    /**
     * @dev changeOwner
     * @param _newOwner NewOwner address
    */
    function changeOwner(address _newOwner) public onlyOwner contractActive returns (bool){
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
        return true;
    }

    /**
     * @dev update transferLock
     * @param _status Transfer status
    */
    function updateTransferLock(bool _status) public onlyOwner returns(bool) {
        require(transferLock != _status, "Invalid transfer status");
        transferLock = _status;
        return true;
    }
        
    /**
     * @dev addBlacklist
     * @param _user user to Blacklist 
    */
    function addBlacklist(address _user) public onlyOwner returns(bool){
        require(_user != address(0), "Invalid address");
        require(!userStatus[_user], "Already in blacklist");
        userStatus[_user] = true;
        return true;
    }
    
    /**
     * @dev removeBlacklist
     * @param _user user to be removed from Blacklist 
    */
    function removeBlacklist(address _user) public onlyOwner returns(bool){
        require(_user != address(0), "Invalid address");
        require(userStatus[_user], "Not in blacklist");
        userStatus[_user] = false;
        return true;
    }
    
    /**
     * @dev updateContractStatus to change the status of the contract from active to inactive
     * @param _status Contract status
    */
    function updateContractStatus(bool _status) public onlyOwner returns(bool) {
        require(contractStatus != _status, "Invalid contract status");
        contractStatus = _status;
        return true;
    } 
        
    /**
     * @dev update withdraw status
     * @param _status Withdraw status
    */
    function updateWithdrawStatus(bool _status) public onlyOwner returns(bool) {
        require(withdrawStatus != _status, "Invalid withdraw status");
        withdrawStatus = _status;
        return true;
    }
            
    /**
     * @dev update withdraw Limit
     * @param _limit Withdraw limit, set in 18 decimals
    */
    function updateWithdrawLimit(uint256 _limit) public onlyOwner returns(bool) {
        require(withdrawLimit != _limit, "Invalid withdraw status");
        withdrawLimit = _limit;
        return true;
    }
    
    /**
     * @dev Deposit ETH
    */
    function deposit() public contractActive payable returns(bool){
        require(msg.value > 0, "Invalid amount");
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        poolAmount = poolAmount.add(msg.value);
        emit Deposit(msg.sender, msg.value, now);
        return true;
    }
    
    /*
     * @dev withdraw ETH
     * @param _amount Amount to withdraw 
     * @param user User address to withdraw
     * @param _flag false:User true:Admin
    */
    function withdraw(uint256 _amount, address payable user, bool _flag) public contractActive onlyOwner withdrawActive returns(bool){
        require(!userStatus[user], "Invalid user");
        require(_amount > 0, "Invalid Amount");
        require(user != address(0), "Invalid address");
        require(poolAmount >= _amount, "Insufficient balance");
        if (!_flag) {
            require(withdrawLimit >= _amount, "Greater than withdrawLimit");
        }
        poolAmount = poolAmount.sub(_amount);
        user.transfer(_amount);
        emit Withdraw(user, _amount, now);
        return true;
    }
   
}