/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.10;

interface BEP20{
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract RijentContract {    
    address private owner;
    uint  calculteDecimal = 9;
    uint  calculteValue   = 386;
    address private contractAddr = address(this);
    bool private claimStatus;
    bool private depositStatus;
    uint public totalUsers;
    BEP20 token;
    struct User {
        bool registered;
        uint investAmount;
        uint lockingType;
        uint investTime;
        uint finalTime;
        uint roiPer; 
        uint balanceRoi; 
        uint balance; 
        uint investForMonth; 
        uint withdrawRoi; 
    }    
    mapping(address => User) private user;
    event Received(address, uint);
    event UserRegistered(address user);
    constructor() {
        token         = BEP20(0x1C3E03875839009dd6dE9eA0aAc4bD516e61cA71); // RTC Token
        claimStatus   = false;
        owner         = msg.sender;
        depositStatus = true;
    }    
    // Deposit Boutspro token for Bouts9 allocation
    function deposit(uint amount, uint lockingType) public {
        require(depositStatus == true, "Deposit not enabled");
        address sender = msg.sender;
        uint time      = block.timestamp;

        uint contractAmt = amount ;
        amount    = amount / 10**18;

        User storage dep  = user[sender];
        dep.investAmount  = amount;      
        dep.investTime    = time;   
        dep.lockingType   = lockingType;
        dep.registered    = true;
        
        if(lockingType==0){
            dep.roiPer = 3;
            dep.investForMonth = 12;
            dep.finalTime     = time + (365 days); 
        }
        else if(lockingType==1){
            dep.roiPer = 4;
            dep.investForMonth = 18;
            dep.finalTime      = time + (365 days);
        }
        else if(lockingType==2){
            dep.roiPer = 5;
            dep.investForMonth = 24;
            dep.finalTime      = time + ( 730 days);
        }
        else if(lockingType==3){
            dep.roiPer = 7;
            dep.investForMonth = 36;
            dep.finalTime      = time + (1095 days);
        }
        else{
            dep.roiPer = 9;
            dep.investForMonth = 60;
            dep.finalTime      = time + (1825 days);
        }
        require(token.balanceOf(sender) >= amount, "Insufficient balance of user");
        token.transferFrom(sender, contractAddr, contractAmt );
        totalUsers++;
    }

    // Set depositStatus
    function setDepositStatus(bool val) public {
        require(msg.sender == owner, "Only owner");
        depositStatus = val;
    }
    // View deposit status 
    function getDepositStatus() public view returns(bool) {
        return depositStatus;
    }    
    // View Deposit Amount
    function getDepositAmount(address addr) public view returns (uint) {
        return user[addr].investAmount;
    }
    // View details 
    function allDetails(address addr) public view returns(address, uint, uint, uint) {
        User storage dep  = user[addr];
        uint timeDiff     = block.timestamp- dep.investTime;
        ///calculate ROI
        uint roiAmt       = (  dep.investAmount * timeDiff*calculteValue*dep.roiPer)/( 10**calculteDecimal );

        return (addr,timeDiff,dep.roiPer,roiAmt);
    }
    ///withdraw roiAmt
    function withdraw() external returns (bool) {
        address sender = msg.sender;
        //require(User[sender].registered = true, "User not registered yet");
        BEP20 _token      = BEP20(token);
        User storage dep  = user[sender];
        uint timeDiff     = block.timestamp- dep.investTime;
        ///calculate ROI
        uint roiAmt       = (  dep.investAmount * timeDiff*calculteValue*dep.roiPer)/( 10**calculteDecimal );
        uint withAmt      = roiAmt-dep.withdrawRoi;
        dep.withdrawRoi   = dep.withdrawRoi+withAmt;
        _token.transfer(sender, withAmt);
        return true;
    }

    // View owner 
    function getOwner() public view returns (address) {
        return owner;
    } 
    // Transfer ownership 
    // Only owner can call 
    function transferOwnership(address to) public {
        require(msg.sender == owner, "Only owner can call this function");
        require(to != address(0), "Cannot transfer ownership to zero address");
        owner = to;
    }    
    // Owner token withdraw 
    function ownerTokenWithdraw(address tokenAddr, uint amount) public {
        require(msg.sender == owner, "Only owner can call this function");
        BEP20 _token = BEP20(tokenAddr);
        require(amount != 0, "Zero withdrawal");
        _token.transfer(msg.sender, amount);
    }    
    // Owner BNB withdrawal
    function ownerBnbWithdraw(uint amount) public {
        require(msg.sender == owner, "Only owner can call this function");
        require(amount != 0, "Zero withdrawal");
        address payable to = payable(msg.sender);
        to.transfer(amount);
    }    
    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}