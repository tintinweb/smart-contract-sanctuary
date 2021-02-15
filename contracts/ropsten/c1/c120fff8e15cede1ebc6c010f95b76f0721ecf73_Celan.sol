/**
 *Submitted for verification at Etherscan.io on 2021-02-15
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

contract Celan {
    
    using SafeMath for uint256;
    // Registered users details
    struct UserStruct{
        bool isExist;
        uint id;
        uint currentLevel;
        uint referer;
        uint referalEarnings;
        address[] referals; 
        mapping(uint => bool)activeLevel;
    }
    
    // owner address
    address public owner;
    // pool bonus percentage
    uint public poolBonus;
    // Total levels
    uint public lastLevel = 10;
    // users currentId
    uint public currentId = 2;
    // poolMembers list
    address[] public poolMembers;
    // contract purpose
    bool public lockStatus;
    
    event Referalcommission(address indexed to,uint level,uint value);
    event Directrefercommission(address indexed from,address indexed to,uint value);
    event Poolperson(address indexed to,uint amount);
    event Registration(address indexed from,address indexed to,uint level,uint value,uint time,address indexed directrefer);
    event Buylevel(address indexed from,uint level,uint value,uint time);
 
    mapping(address => UserStruct)public users; // mapping users details by address
    mapping(uint => address)public userList; // mapping users address by Id
    mapping(uint => uint)public levelPrice; // mapping price by levels
    mapping(address => uint)public loopCheck; // mapping counts for payment purpose
    mapping(uint => uint)public referalUpline; // mapping levels for upline 
    mapping(address => bool)public pollStatus; // mapping status by address
   
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }
    
    modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    } 
    
    modifier isContractcheck(address _user) {
       require(!isContract(_user),"Invalid address");
            _;
    }
    
    constructor(address _ownerAddress)public{
        owner = _ownerAddress;
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
        // upline counts
        referalUpline[1] = 3;
        for(uint i=2; i<=10;i++){
            referalUpline[i] = referalUpline[i-1] + 1;
        }
    }
     /**
    * @dev registration : User register with level 1 price 
    * 30% for directReferer, 10% for pool bonus, 60% for uplines.
    * @param _referid : user give referid for reference purpose
    * @param _level : initaially for registering level will be 1
    */ 
    
    function register(uint _referid,uint _level)public isLock isContractcheck(msg.sender)  payable{
        require(users[msg.sender].isExist == false,"User already exist");
        require(_level == 1,"wrong level given");
        require(msg.value == levelPrice[_level],"invalid price");
        require(_referid <= currentId,"invalid id");
        uint referLimit = 2;
        address directAddress;
        
        if(users[userList[_referid]].referals.length >= referLimit){
             directAddress = userList[_referid];
        }
        else{ 
            directAddress = userList[_referid];
        }
        
        if(users[userList[_referid]].referals.length >= referLimit){
             _referid = users[findFreeReferrer(userList[_referid])].id;
        }
        
        _userregister(msg.sender,_referid,_level,msg.value,directAddress);
    }
    
    function _userregister(address _user,uint _referid,uint _level,uint _amount,address _directAddress)internal{
         UserStruct memory userstruct;
        userstruct = UserStruct({
            isExist:true,
            id:currentId,
            currentLevel:_level,
            referer:_referid,
            referalEarnings:0,
            referals:new address[](0)
        });
        
        users[_user] = userstruct;
        userList[currentId] = _user;
        users[_user].activeLevel[1] = true;
        users[userList[_referid]].referals.push(_user);
        currentId++;
        
        uint poolpercentage = (_amount.mul(10 ether)).div(100 ether);
        uint directbonus = (_amount.mul(30 ether)).div(100 ether);
        poolBonus = poolBonus.add(poolpercentage);
        
        require(address(uint160(userList[_referid])).send(directbonus),"direct bonus failed");
        uint amount = _amount.sub(poolpercentage.add(directbonus));
        _paylevel(userList[_referid],_level,amount.div(referalUpline[_level]));
        emit Directrefercommission(_user,userList[_referid],directbonus);
        emit Registration(_user,userList[_referid],_level,_amount,block.timestamp,_directAddress);
    }
     /**
    * @dev buyLevel : User can buy next level.
    * @param _level : Giving level for buy another level user can move one by one no skipping levels
    */ 
    function buyLevel(uint _level)public isLock payable{
        require(users[msg.sender].isExist == true,"register first");
        require(msg.value == levelPrice[_level],"incorrect price");
        require(users[msg.sender].currentLevel + 1 == _level,"wrong level given");
        if(_level == 10 && msg.sender != owner){
           poolMembers.push(msg.sender);
        }
        
        users[msg.sender].activeLevel[_level] = true;
        users[msg.sender].currentLevel = _level;
        
        uint poolpercentage = (msg.value.mul(10 ether)).div(100 ether);
        uint directbonus = (msg.value.mul(30 ether)).div(100 ether);
        poolBonus = poolBonus.add(poolpercentage);
        uint amount = msg.value.sub(poolpercentage .add(directbonus));
        _directShare(msg.sender,userList[users[msg.sender].referer],_level,directbonus);
        loopCheck[msg.sender] = 0;
        
        _paylevel(userList[users[msg.sender].referer],_level,amount.div(referalUpline[_level]));
        emit Buylevel(msg.sender,_level,msg.value,block.timestamp);
    }    
   
    function _directShare(address _user,address _refer,uint _level,uint _amount)internal{
        if(users[_refer].activeLevel[_level] != true){
            address ref = userList[users[_refer].referer];
            _directShare(_user,ref,_level,_amount);
             
        }
        
        else{
            require(address(uint160(_refer)).send(_amount),"direct bonus failed");
            emit Directrefercommission(_user,_refer,_amount);
        }
    }
    
    function _paylevel(address _referer,uint _level,uint _amount)internal{
        if(_referer == address(0)){
           _referer = owner;
        }
        
        if(loopCheck[msg.sender] < referalUpline[_level]){
            users[_referer].referalEarnings =  users[_referer].referalEarnings.add(_amount);
            require(address(uint160(_referer)).send(_amount),"transfer level  failed");
            emit Referalcommission(_referer,_level,_amount);
            loopCheck[msg.sender] = loopCheck[msg.sender].add(1);
            address ref =  userList[users[_referer].referer];
            _paylevel(ref,_level,_amount);
        }
    }
       
     /**
    * @dev findFreeReferrer : Check the refer either having space or find new refer
    * @param _user:passing address for check his referal length
    */ 
    function findFreeReferrer(address _user) public view returns(address) {
        uint referLimit = 2;
        if(users[_user].referals.length < referLimit){
            return _user;
        } 
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
      /**
    * @dev poolPercent : Distribute the poolbonus to selected person call by onlyowner.
    * 
    */ 
    
    function poolPercent()public onlyOwner{
        require(poolMembers.length != 0,"no members");
        uint _poolmember = poolMembers.length.mul(0.1 ether);
        require(poolBonus >= _poolmember,"not sufficient amount for all");
        
        if(poolMembers.length > 0){
            for(uint i =0;i<poolMembers.length;i++){
                require(pollStatus[poolMembers[i]] == false,"Already pool selected");
                require(poolMembers[i] != address(0),"transaction failed");
                require(address(uint160(poolMembers[i])).send(poolBonus.div(poolMembers.length)),"Transaction failed");
                pollStatus[poolMembers[i]] = true;
                emit Poolperson(poolMembers[i],poolBonus.div(poolMembers.length));
            }
            poolBonus = 0;
        }
    }
    
     /**
    * @dev failSafe : For admin purpose
    */ 
    
    function failSafe(address payable _toUser, uint _amount) public onlyOwner returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }
    
    function viewUsers(address _user,uint _level)public view returns(address[]memory,bool){
        return (users[_user].referals,
        users[_user].activeLevel[_level]);
    }
    
     /**
    * @dev failSafe : For admin purpose
    */ 
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }
    
    function isContract(address _account) public view returns (bool) {
        uint32 size;
        assembly {
                size := extcodesize(_account)
        }
        if(size != 0)
            return true;
        return false;
   }
}