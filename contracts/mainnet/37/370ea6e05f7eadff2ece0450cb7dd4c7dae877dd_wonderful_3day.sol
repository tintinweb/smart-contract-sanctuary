/**
 *Submitted for verification at Etherscan.io on 2020-12-25
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
    address public bidAddress;
    address payable public feeAddress;
    uint256 public fee = 10; // default 10
    uint256 public day = 1 days;
    uint256 public rechargeTime;
    uint256 public minAmount = 0.1 ether;
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
        uint256 depositTime;
    }
    mapping(address => UserInfo) public user;
    mapping(address => uint256) public balance;
    mapping(address => mapping(address => bool)) public userDireMap;
    
    constructor(address bid)public{
        manager = msg.sender;
        bidAddress = bid;
    }

    function deposit(address referrer) payable public {
        require(msg.value > 0 && isTime() == false && msg.value >= minAmount);
        uint256 fees = msg.value.div(fee);
        if(address(this).balance >= fees){
            feeAddress.transfer(fees);
        }
        UserInfo storage u = user[msg.sender];
		if (u.referrer == address(0)) {
		    if (referrer != msg.sender){
		        u.referrer = referrer;
		    }else{
		        u.referrer = bidAddress;
		    }
		    if (userDireMap[u.referrer][msg.sender] == false){
                user[u.referrer].directPush.push(msg.sender);
                userDireMap[u.referrer][msg.sender] = true;
            }
		}
		
		if (balance[msg.sender] == 0){
		    totalUsers = totalUsers.add(1);
		    u.depositTime = now;
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
        if (isTime() == true && ISEND == false){
            uint256 a = 0;
            if (rechargeAddress.length>10){
                a = rechargeAddress.length.sub(10);
            }
            uint256 total = (address(this).balance.mul(percentage)).div(uint256(1000));
            for (;a < rechargeAddress.length; a++){
                payable(rechargeAddress[a].rec_addr).transfer(total.div(10));
            }
            ISEND = true;
        }
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
        return ((getDirectTotal(addr).add(getInterest(addr))).add(getInterest(addr))).div(balance[addr]);
    }
    
    // 最大收益：(推广总量 + 当前利息) - 提出总量
    function getMaxIncome(address addr) view public isAddress(addr) returns(uint256){
        return (getDirectTotal(addr).add(getInterest(addr))).sub(user[addr].amountWithdrawn);
    }
    
    // 当前收益：直推总量 / 投入本金 是否大于等于3，小于3 当前收益为0 大于3  ：本金*3 - 已提取数
    function getIncome(address addr) view public isAddress(addr) returns(uint256){
        uint256 multiple = directPushMultiple(addr);
        if (multiple < 3){
            return 0;
        }
        return (balance[addr].mul(3).sub(user[addr].amountWithdrawn));
    }

    function additionalThrow(address addr) view public isAddress(addr) returns(uint256){
        uint256 multiple = directPushMultiple(addr);
        if (multiple < 3){
            return 0;
        }
        return ((getDirectTotal(addr).add(getInterest(addr))).sub(user[addr].amountWithdrawn).sub(getIncome(addr))).div(3);
    }
    
    function numberWithdrawn(address addr) view public isAddress(addr) returns(uint256) {
        return user[addr].amountWithdrawn;
    }

    function getDirectTotal(address addr) view public isAddress(addr) returns(uint256) {
        UserInfo memory u = user[addr];
        if (u.directPush.length == 0){return (0);}
        uint256 total;
        for (uint256 i= 0; i<u.directPush.length;i++){
            total = total.add(balance[u.directPush[i]]).add(getDirectTotal2(u.directPush[i]));
        }
        return (total);
    }
    
    function getDirectTotal2(address addr) view public isAddress(addr) returns(uint256) {
        UserInfo memory u = user[addr];
        if (u.directPush.length == 0){return (0);}
        uint256 total;
        for (uint256 i= 0; i<u.directPush.length;i++){
            total += balance[u.directPush[i]];
        }
        return (total);
    }
    
    function getIndirectTotal(address addr) view public isAddress(addr) returns(uint256){
        return getDirectTotal(addr).sub(getDirectTotal2(addr));
    }
    
    function getDirectLength(address addr) view public isAddress(addr) returns(uint256){
        return user[addr].directPush.length;
    }
    
    function getInterest(address addr)view public returns(uint256){
        // 取当前本金0.3%
        uint256 inter = balance[addr].mul(3).div(1000);
        uint256 d = (now.sub(user[addr].depositTime)).div(1 days);
        return inter.mul(d);
    }
    
    function ownerWitETH() public onlyOwner{
        require(ISEND == true);
        msg.sender.transfer(getPoolETH());
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