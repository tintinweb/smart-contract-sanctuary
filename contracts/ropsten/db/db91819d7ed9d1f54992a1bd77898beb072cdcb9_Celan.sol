/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-21
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-19
*/

pragma solidity 0.5.16;

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
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Celan{
    
    using SafeMath for uint256;
    
   
    
     struct UserStruct{
         bool isExist;
         uint id;
         uint currentLevel;
         uint referer;
         uint referalEarnings;
         address[] referals; 
        mapping(uint => bool)activeLevel;
     }
    
    address public owner;
    uint public poolBonus;
    uint public lastLevel = 10;
    uint public currentId = 2;
    
    address[] public poolMembers;
     bool public lockStatus;
    
    event Referalcommission(address indexed to,uint level,uint value);
    event Directrefercommission(address indexed _from,address indexed _to,uint value);
    event Poolperson(address indexed to,uint amount);
    event Registration(address indexed _from,address indexed to,uint level,uint value,uint time,address indexed directrefer);
    event Buylevel(address indexed _from,uint level,uint value,uint time);
    
    
    mapping(address => UserStruct)public users;
    mapping(uint => address)public userList;
    mapping(uint => uint)public levelPrice;
    mapping(address => uint)public loopCheck;
    mapping(uint => uint)public referalUpline;
    mapping(address => bool)public pollStatus;
   
    
     modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }
    
     modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    } 
    
    constructor(address Owneraddress)public{
        owner = Owneraddress;
        
        UserStruct memory userstruct;
        userstruct = UserStruct({
           isExist:true,
           id:1,
           currentLevel:10,
           referer:0,
           referalEarnings:0,
           referals:new address[](0)
           
        });
        users[owner] = userstruct;
        userList[1] = owner;
        
        for (uint i=1; i<=lastLevel; i++){
            users[owner].activeLevel[i] = true;
        }
        
         //Levels levelprice
        levelPrice[1] = 0.05 ether;
        
        for(uint i =2; i<= 10; i++){
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
        referalUpline[1] = 3;
        for(uint i=2; i<=10;i++){
            referalUpline[i] = referalUpline[i-1] + 1;
        }
       
        
        
    }
    
    function register(uint _referid,uint level)public isLock payable{
        require(users[msg.sender].isExist == false,"User already exist");
        require(msg.value == levelPrice[level],"invalid price");
        require(_referid <= currentId,"invalid id");
        require(level <= lastLevel,"invalid level");
        uint referLimit = 2;
        address directid;
        if(users[userList[_referid]].referals.length >= referLimit){
             directid = userList[_referid];
        }
        else directid = userList[_referid];
         if(users[userList[_referid]].referals.length >= referLimit)
         _referid = users[findFreeReferrer(userList[_referid])].id;
        UserStruct memory userstruct;
        userstruct = UserStruct({
           isExist:true,
           id:currentId,
           currentLevel:level,
           referer:_referid,
           referalEarnings:0,
           referals:new address[](0)
        });
        
        users[msg.sender] = userstruct;
        userList[currentId] = msg.sender;
        users[msg.sender].activeLevel[1] = true;
        users[userList[_referid]].referals.push(msg.sender);
        currentId++;
        uint poolpercentage = (msg.value .mul(10 ether)).div(100 ether);
        uint directbonus = (msg.value .mul(30 ether)).div(100 ether);
        poolBonus = poolBonus .add(poolpercentage);
        require(address(uint160(userList[_referid])).send(directbonus),"direct bonus failed");
        emit Directrefercommission(msg.sender,userList[_referid],directbonus);
        uint amount = msg.value .sub(poolpercentage .add(directbonus));
        _paylevel(userList[_referid],level,amount);
        emit Registration(msg.sender,userList[_referid],level,msg.value,block.timestamp,directid);
        
        
    }
    
   
            
    function buyLevel(uint _level)public isLock payable{
        require(users[msg.sender].isExist == true,"register first");
        require(msg.value == levelPrice[_level],"incorrect price");
        require(users[msg.sender].currentLevel + 1 == _level,"wrong level given");
        
        
        if(_level == 10 && msg.sender != owner){
        poolMembers.push(msg.sender);
        }
        
        users[msg.sender].activeLevel[_level] = true;
        users[msg.sender].currentLevel = _level;
        
        uint poolpercentage = (msg.value .mul(10 ether)).div(100 ether);
        uint directbonus = (msg.value .mul(30 ether)).div(100 ether);
        poolBonus = poolBonus .add(poolpercentage);
        uint amount = msg.value .sub(poolpercentage .add(directbonus));
        
        _directShare(msg.sender,userList[users[msg.sender].referer],_level,directbonus);
        
        loopCheck[msg.sender] = 0;
        _paylevel(userList[users[msg.sender].referer],_level,amount);
        
        emit Buylevel(msg.sender,_level,msg.value,block.timestamp);
        
    }    
        
        
        
    

    function _directShare(address user,address refer,uint level,uint amount)internal{
        if(users[refer].activeLevel[level] != true){
             address ref = userList[users[refer].referer];
        _directShare(user,ref,level,amount);
             
        }
        else{
       
        require(address(uint160(refer)).send(amount),"direct bonus failed");
              emit Directrefercommission(user,refer,amount);
        }
    }
    
    function _paylevel(address referer,uint level,uint amount)internal{
            
        if(referer == address(0))
        referer = owner;
        if(loopCheck[msg.sender] < referalUpline[level]){
        require(address(uint160(referer)).send(amount .div(referalUpline[level])),"transfer level  failed");
        users[referer].referalEarnings =  users[referer].referalEarnings .add(amount .div(referalUpline[level]));
        emit Referalcommission(referer,level,amount .div(referalUpline[level]));
        loopCheck[msg.sender] = loopCheck[msg.sender].add(1);
        address ref =  userList[users[referer].referer];
        _paylevel(ref,level,amount);
        }
    }
    
    function findFreeReferrer(address _user) public view returns(address) {
        uint referLimit = 2;
        if(users[_user].referals.length < referLimit) return _user;

        address[] memory referrals = new address[](126);
        referrals[0] = users[_user].referals[0];
        referrals[1] = users[_user].referals[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {
            if(users[referrals[i]].referals.length == referLimit) {
                if(i < 62) {
                    referrals[(i+1)*2] = users[referrals[i]].referals[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].referals[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }
    
    function()external payable{
        
    }
    
    function poolPercent()public onlyOwner{
        
        require(poolMembers.length != 0,"no members");
        uint _poolmember = poolMembers.length .mul(0.1 ether);
        require(poolBonus >= _poolmember,"not sufficient amount for all");
        
       
        if(poolMembers.length > 0){
            for(uint i =0;i<poolMembers.length;i++){
                require(pollStatus[poolMembers[i]] == false,"Already pool selected");
                 require(poolMembers[i] != address(0) ,"transaction failed");
                require(address(uint160(poolMembers[i])).send(poolBonus.div(poolMembers.length) ),"Transaction failed");
                pollStatus[poolMembers[i]] = true;
                emit Poolperson(poolMembers[i],poolBonus.div(poolMembers.length));
                
            }
            poolBonus = 0;
        }
    }
    
    function failSafe(address payable _toUser, uint _amount) public onlyOwner returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        
        (_toUser).transfer(_amount);
        return true;
    }
    
    function viewUsers(address user)public view returns(address[]memory){
        return users[user].referals;
    }
    
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }
}