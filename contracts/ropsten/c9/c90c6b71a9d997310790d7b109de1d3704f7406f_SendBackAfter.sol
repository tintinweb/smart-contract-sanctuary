/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity ^0.8.4;

contract SendBackAfter {

    bool paused;
    
    address payable public owner;
    
    event StillLocked(address _who, uint _time);
    event LockedForMe(uint _timespanInBlocks);
    
    mapping(address => uint) private lockedUntil;
    
    struct Payment {
        uint amount;
        uint timestamps;
    }
    
    struct Balance {
        uint totalBalance;
        uint numPayments;
        mapping(uint => Payment) payments;
    }
    
    mapping(address => Balance) public balanceReceived;
    
    constructor() {
        owner = payable(msg.sender);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner of this smart contract!");
        _;
    }
    
    function isLocked() public {
        uint _timespan;
        _timespan = lockedUntil[msg.sender] - block.timestamp;
        emit LockedForMe(_timespan);
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function sendMoney() public payable {
        balanceReceived[msg.sender].totalBalance += msg.value;
        Payment memory payment = Payment(msg.value, block.timestamp);
        lockedUntil[msg.sender] = block.timestamp + 1 minutes;
        balanceReceived[msg.sender].payments[balanceReceived[msg.sender].numPayments] = payment;
        balanceReceived[msg.sender].numPayments++;
    }
    
    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }
    
    function withdrawSome(uint _amount) public {
        require(_amount <= balanceReceived[msg.sender].totalBalance, "You don't have enough funds!");
        if (lockedUntil[msg.sender] > block.timestamp) {
            emit StillLocked(msg.sender, lockedUntil[msg.sender]);
            return;
        } else {
            balanceReceived[msg.sender].totalBalance -= _amount;
            address payable _to = payable(msg.sender);
            _to.transfer(_amount);
        }
    }
    
    function killMe() public onlyOwner {
        selfdestruct(owner);
    }
    
    fallback() external payable {
        sendMoney();
    }
    
    
    
}