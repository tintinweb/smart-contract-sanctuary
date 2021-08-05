/**
 *Submitted for verification at Etherscan.io on 2020-12-02
*/

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;

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

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

contract wonderful_3day {
    using SafeMath for uint256;
    address public manager;
    address payable public feeAddress;
    uint256 public fee = 10; // default 10
    uint256 public day = 3 days;
    uint256 public rechargeTime;
    uint256 public minAmount = 0.5 ether;
    uint256 public percentage = 900;
    uint256 public totalUsers;
    bool public ISEND;
    
    struct RechargeInfo{
        address rec_addr;
        uint256 rec_value;
        uint256 rec_time;
    }
    RechargeInfo[] public rechargeAddress;
    struct UserInfo {
		address   referrer;   
        address[] directPush; 
        uint256 amountWithdrawn;
    }
    mapping(address => UserInfo) public user;
    mapping(address => uint256) public balance;
    mapping(address => mapping(address => bool)) public userDireMap;
    
    constructor()public{
        manager = msg.sender;
     }

    function deposit(address referrer) payable public {
        require(msg.value > 0 && isTime() == false && msg.value >= minAmount);
        uint256 fees = msg.value.div(fee);
        if(address(this).balance >= fees){
            feeAddress.transfer(fees);
        }
        UserInfo storage u = user[msg.sender];
		if (u.referrer == address(0) && referrer != msg.sender) {
            u.referrer = referrer;
            if (userDireMap[referrer][msg.sender] == false){
                user[referrer].directPush.push(msg.sender);
                userDireMap[referrer][msg.sender] = true;
            }
		}
		
		if (balance[msg.sender] == 0){
		    totalUsers = totalUsers.add(1);
		}
		
		balance[msg.sender] = balance[msg.sender].add(msg.value);
		rechargeAddress.push(RechargeInfo({rec_addr:msg.sender,rec_value:msg.value,rec_time:block.timestamp}));
		rechargeTime = block.timestamp;
    }
    
    function withdraw(uint256 value) public {
        require(value > 0);
        uint256 count = getIncome(msg.sender);
        require(count >= value,"Not enough quota");
        msg.sender.transfer(value);
        user[msg.sender].amountWithdrawn = user[msg.sender].amountWithdrawn.add(value);
    }
    
    function getPoolETH() view public returns(uint256){
        return address(this).balance;
    }
    
    function getRecTotal() view public returns(uint256){
        return rechargeAddress.length;
    }
    
    function getRec10() view public returns(RechargeInfo[] memory){
        uint256 l = rechargeAddress.length;
        uint256 a = 0;
        uint256 i = 0;
        if (rechargeAddress.length>10){
            l = 10;
            a = rechargeAddress.length.sub(10);
        }
        RechargeInfo[] memory data = new RechargeInfo[](l);
        for (;a < rechargeAddress.length; a++){
            data[i] = rechargeAddress[a];
            i = i+1;
        }
        return data;
    }
    
    function distribution72() public {
        if (isTime() == false){return;}
        uint256 a = 0;
        if (rechargeAddress.length>50){
            a = rechargeAddress.length.sub(50);
        }
        uint256 total = (address(this).balance.mul(percentage)).div(uint256(1000));
        for (;a < rechargeAddress.length; a++){
            payable(rechargeAddress[a].rec_addr).transfer(total.div(50));
        }
        ISEND = true;
        return;
    }
    
    function isTime()view public returns(bool) {
        if ((block.timestamp.sub(rechargeTime)) >= day && rechargeTime != 0){
            return true;
        }
        return false;
    }
    
    function directPushMultiple(address addr) view public isAddress(addr) returns(uint256) {
        if(balance[addr] == 0){
            return 0;
        }
        return getDirectTotal(addr).div(balance[addr]);
    }
    
    function getMaxIncome(address addr) view public isAddress(addr) returns(uint256){
        return getDirectTotal(addr).sub(user[addr].amountWithdrawn);
    }
    
    function getIncome(address addr) view public isAddress(addr) returns(uint256){
        uint256 multiple = directPushMultiple(addr);
        if (multiple < 3){
            return 0;
        }
        return (balance[addr].mul(3).sub(user[addr].amountWithdrawn));
    }
    
    function numberWithdrawn(address addr) view public isAddress(addr) returns(uint256) {
        return user[addr].amountWithdrawn;
    }

    function additionalThrow(address addr) view public isAddress(addr) returns(uint256){
        uint256 multiple = directPushMultiple(addr);
        if (multiple < 3){
            return 0;
        }
        return (getDirectTotal(addr).sub(user[addr].amountWithdrawn).sub(getIncome(addr))).div(3);
    }

    function getDirectTotal(address addr) view public isAddress(addr) returns(uint256) {
        UserInfo memory u = user[addr];
        if (u.directPush.length == 0){return (0);}
        uint256 total;
        for (uint256 i= 0; i<u.directPush.length;i++){
            total += balance[u.directPush[i]];
        }
        return (total);
    }
    
    function getDirectLength(address addr) view public isAddress(addr) returns(uint256){
        return user[addr].directPush.length;
    }
    
    function ownerWitETH(uint256 value) public onlyOwner{
        require(getPoolETH() >= value && ISEND == true);
        msg.sender.transfer(value);
    }
    
    function ownerTransfer(address newOwner) public onlyOwner isAddress(newOwner) {
        manager = newOwner;
    }
    
    function ownerSetFeeAddress(address payable feeAddr) public onlyOwner isAddress(feeAddr) {
        feeAddress = feeAddr;
    }
    
    function ownerSetFee(uint256 value) public onlyOwner{
        require(value > 0);
        fee = value;
    }
    
    function ownerSetMinAmount(uint256 min) public onlyOwner{
        require(min >= 0);
        minAmount = min;
    }
    
    modifier isAddress(address addr) {
        require(addr != address(0));
        _;
    }
    
    modifier onlyOwner {
        require(manager == msg.sender);
        _;
    }

}