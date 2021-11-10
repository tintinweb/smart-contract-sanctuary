/**
 *Submitted for verification at polygonscan.com on 2021-11-10
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-08-10
*/

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20{
    function transferFrom(address _from, address _to, uint _value) external;
    function transfer(address _to, uint256 _value) external;
}

contract Invest{
    using SafeMath for uint256;
    
    event AddMember(address newMember, string group, uint256 amount);
    event ReceiveToken(address member, string group, uint256 amount);
    event DepositToken(address member, string group, uint256 amount);
    
    struct UnlockMod{
        uint256 first;
        uint256 periods;
        uint256 price;
        uint256 pool;
    }
    
    struct MemberInfo{
        bool isMember;
        bool isReceivefirst;
        uint256 deposit;
        uint256 limit;
        uint256 everyUnlock;
        uint256 received;
    }
    
    address public owner;
    string private ERR_LACK_OF_CREDIT = "Insufficient token surplus";
    mapping (string => UnlockMod) private UNLOCK_MODS;
    string[] public groups;
    uint256 public ISSUE_TIME;
    // uint256 public timeMod = 60 * 60 * 24 * 30;
    uint256 public timeMod = 60;
    address public dpcpAddress = 0xB51a8Bcdf0282c208806E5d5a2D66726166FCA68;
    address public usdtAddress = 0x50e27c4C68bfCaBeb29cCaB083E6185F4478350b;
    address public receivingAddress = 0x286ED650C550e1A0f9CcF50A2Bc5a4Ac4296AE2D;
    bool public isOpenReturn;
    
    mapping(address => mapping(string => MemberInfo)) public memberAsset;
    // mapping(address => string[]) public memberRoles;
    
    constructor(){
        owner = msg.sender;
        isOpenReturn = false;
        UNLOCK_MODS["liquidity"] = UnlockMod(15, 10, uint256(12 * 10 ** 16), 1000000 * 10**18);
        UNLOCK_MODS["first"] = UnlockMod(8, 18, uint256(10 * 10 ** 16), 1000000 * 10**18);
        UNLOCK_MODS["second"] = UnlockMod(10, 15, uint256(11 * 10 ** 16), 1600000 * 10**18); 
        UNLOCK_MODS["ido"] = UnlockMod(20, 10, uint256(30 * 10 ** 16), 600000 * 10**18);
        UNLOCK_MODS["dao"] = UnlockMod(10, 10, 0, 1200000 * 10**18);
        UNLOCK_MODS["develop"] = UnlockMod(10, 10, 0, 600000 * 10**18);
        UNLOCK_MODS["community"] = UnlockMod(10, 10, 0, 600000 * 10**18);
        UNLOCK_MODS["award"] = UnlockMod(10, 10, 0, 400000 * 10**18);
        
        groups.push("liquidity");
        groups.push("first");
        groups.push("second");
        groups.push("ido");
        groups.push("dao");
        groups.push("develop");
        groups.push("community");
        groups.push("award");
        
    } 
    
    function addMember(address _newMember, string memory _group, uint256 _limit)external existGroup(_group) onlyOwner{
        require(UNLOCK_MODS[_group].pool >= _limit, ERR_LACK_OF_CREDIT);
        require(!memberAsset[_newMember][_group].isMember, "The member already exists.");
        UNLOCK_MODS[_group].pool = UNLOCK_MODS[_group].pool.sub(_limit);
        memberAsset[_newMember][_group]= MemberInfo(true, false, 0, _limit, 0, 0);
        // memberRoles[_newMember].push(_group);
        
        emit AddMember(_newMember, _group, _limit);
    }
    
    function removedMember(address _member, string memory _group)external existGroup(_group) onlyOwner{
        require(memberAsset[_member][_group].isMember, "The address is not a member.");
        memberAsset[_member][_group].isMember = false;
    }
    
    function depositForMember(address _member, string memory _group, uint256 _amount)external existGroup(_group) onlyOwner{
        IERC20 usdt = IERC20(usdtAddress);
        uint256 usdtAmount = _amount.div(10).mul(10**6).div(10**18);
        require(memberAsset[_member][_group].isMember, "You are not a member of the group!");
        require(memberAsset[_member][_group].deposit.add(_amount) <= memberAsset[_member][_group].limit, ERR_LACK_OF_CREDIT);
        uint256 newDeposit = memberAsset[_member][_group].deposit.add(_amount);
        memberAsset[_member][_group].deposit = newDeposit;
        memberAsset[_member][_group].everyUnlock = (newDeposit.sub(newDeposit.mul(UNLOCK_MODS[_group].first).div(100)).div(UNLOCK_MODS[_group].periods));
        usdt.transfer(receivingAddress, usdtAmount);
        
        emit DepositToken(msg.sender, _group, _amount);
    }
    
    function depositToken(string memory _group, uint256 _amount)external existGroup(_group){
        IERC20 usdt = IERC20(usdtAddress);
        uint256 usdtAmount = _amount.div(10).mul(10**6).div(10**18);
        require(memberAsset[msg.sender][_group].isMember, "You are not a member of the group!");
        require(memberAsset[msg.sender][_group].deposit.add(_amount) <= memberAsset[msg.sender][_group].limit, ERR_LACK_OF_CREDIT);
        uint256 newDeposit = memberAsset[msg.sender][_group].deposit.add(_amount);
        memberAsset[msg.sender][_group].deposit = newDeposit;
        memberAsset[msg.sender][_group].everyUnlock = (newDeposit.sub(newDeposit.mul(UNLOCK_MODS[_group].first).div(100)).div(UNLOCK_MODS[_group].periods));
        usdt.transferFrom(msg.sender, receivingAddress, usdtAmount);
        
        emit DepositToken(msg.sender, _group, _amount);
    }
    
    function receiveToken(string memory _group) external existGroup(_group) checkIssue {
        IERC20 dpcp = IERC20(dpcpAddress);
        uint256 unlocks;
        if(isOpenReturn){
            unlocks = memberAsset[msg.sender][_group].deposit.sub(memberAsset[msg.sender][_group].received);
            require(memberAsset[msg.sender][_group].received.add(unlocks) <= memberAsset[msg.sender][_group].deposit, "The number of unlocks exceeds expectations.");
            memberAsset[msg.sender][_group].received = memberAsset[msg.sender][_group].deposit;
        }else{
            unlocks =countUnlockLiquidity(msg.sender, _group);
            require(memberAsset[msg.sender][_group].received.add(unlocks) <= memberAsset[msg.sender][_group].deposit, "The number of unlocks exceeds expectations.");
            memberAsset[msg.sender][_group].isReceivefirst = true;
            memberAsset[msg.sender][_group].received = memberAsset[msg.sender][_group].received.add(unlocks);
        }
        dpcp.transfer(msg.sender, unlocks);
        
        emit ReceiveToken(msg.sender, _group, unlocks);
    }
    
    function countUnlockLiquidity(address _addr, string memory _group)public view existGroup(_group) returns(uint256){
        uint256 amount;
        MemberInfo memory info = memberAsset[_addr][_group];
        if(block.timestamp <= ISSUE_TIME || ISSUE_TIME == 0){
            return 0;
        }
        if(info.isMember){
            if(!info.isReceivefirst){
                amount = amount.add(info.deposit.mul(UNLOCK_MODS[_group].first).div(100));
            }
            uint256 spendPeriods = (block.timestamp.sub(ISSUE_TIME)).div(timeMod);
            if(spendPeriods >= UNLOCK_MODS[_group].periods){
                amount = amount.add(info.deposit.sub(info.received));
            }else{
                amount = amount.add(spendPeriods.mul(info.everyUnlock));
            }
        }
        return amount;
    }
    
    function memberInfo(address _member, string memory _group) external view existGroup(_group) returns(uint256 deposit, uint256 received, uint256 limit){
        return (memberAsset[_member][_group].deposit,
                memberAsset[_member][_group].received,
                memberAsset[_member][_group].limit);
    }
    
    function roles(address _member)external view returns(string memory){
        string memory rolesLlistStr = "";
        uint256 count = 0;
        for(uint256 i = 0; i < groups.length; i++){
            if(memberAsset[_member][groups[i]].isMember){
                count = count+1;
                if (count == 1){
                    rolesLlistStr = groups[i];
                }else{
                    rolesLlistStr = string(abi.encodePacked(rolesLlistStr,",", groups[i]));
                }
            }
        }
        return rolesLlistStr;
    }
    
    //manager
    
    function setReceivingAddress(address _newReceivingAddress)external onlyOwner{
        receivingAddress = _newReceivingAddress;
    }
    
    function switchOpenReturn()external onlyOwner{
        isOpenReturn = !isOpenReturn;
    }

    function _toWei(uint256 _amount)internal pure returns(uint256){
        return _amount.mul(10 ** 18);
    }
    
    function issue()external onlyOwner{
        ISSUE_TIME = block.timestamp;
    }
    
    modifier existGroup(string memory _group) {
        bool exist = false;
        bytes32 a = keccak256(abi.encodePacked(_group));
        for(uint256 i = 0; i < groups.length; i++){
            bytes32 b = keccak256(abi.encodePacked(groups[i]));
            if(b == a){
                exist = true;
            }
        }
        require(exist, "The group is not exist!");
        _;
    }
    
    modifier checkIssue(){
        require(block.timestamp >= ISSUE_TIME && ISSUE_TIME != 0, "The token is not issued.");
        _;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner, "msg.sender is not owner");
        _;
    }
}