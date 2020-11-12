// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract ERC20Basic {
    uint public _totalSupply;
    string public name;
    string public symbol;
    uint public decimals;
    function totalSupply() public view  returns (uint){}
    function balanceOf(address who) public view returns (uint){}
    function transfer(address to, uint value) public {}
    function transferFrom(address _from, address _to, uint _value) public{}
    function allowance(address _owner, address _spender) public view returns (uint remaining) {}
    
    event Transfer(address indexed from, address indexed to, uint value);
}

contract TetherToken {

    string public name;
    string public symbol;
    uint public decimals;

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transfer(address _to, uint _value) public {  }
    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transferFrom(address _from, address _to, uint _value) public  {   }
    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function allowance(address _owner, address _spender) public view returns (uint remaining) {    }

}

contract PhoenixTiger {
    
    /*-----------Public Variables---------------
    -----------------------------------*/
    address public owner;
    uint public totalGpv;
    uint public lastuid;
    /*-----------Mapping---------------
    -----------------------------------*/
    mapping(address => bool) public nonEcoUser;
    mapping(address => User) public users;
    mapping(address => bool) public userExist;
    mapping(uint => uint) public totalCountryGpv;
    mapping(address => uint[]) private userPackages;
    mapping(address => bool) public orgpool;
    mapping(address=> bool) public millpool;
    mapping(address => bool) public globalpool;
    mapping(address=>address[]) public userDownlink;
    mapping(address => bool) public isRegistrar;
    mapping(address=> uint) public userLockTime;
    mapping(address =>bool) public isCountryEli;    
    mapping(uint => address) public useridmap;
    
    uint[12] public Packs;
    enum Status {CREATED, ACTIVE}
    struct User {
        uint userid;
        uint countrycode;
        uint pbalance;
        uint rbalance;
        uint rank;
        uint gHeight;
        uint gpv;
        uint[2] lastBuy;   //0- time ; 1- pack;
        uint[7] earnings;  // 0 - team earnings; 1 - family earnings; 2 - match earnings; 3 - country earnings, 4- organisation, 5 - global, 6 - millionaire
        bool isbonus;
        bool isKyc;
        address teamaddress;
        address familyaddress;
        Status status;
        uint traininglevel;
        mapping(uint=>TrainingLevel) trainingpackage;
    }
    struct TrainingLevel {
        uint package;
        bool purchased;

    }
    function getLastBuyPack(address) public view returns(uint[2] memory ){  }
    function getCountryUsersCount(uint) public view returns (uint){    }
    function getTrainingLevel(address useraddress, uint pack) public view returns (uint tlevel, uint upack) {    }
    function getAllPacksofUsers(address useraddress) public view returns(uint[] memory pck) {    }
    function getidfromaddress(address useraddress) public view returns(uint userID){    }
    function getAllLevelsofUsers(address useraddress,uint pack) public view returns(uint lvl) {    }
    function isUserExists(address user) public view returns (bool) {    }
    function checkPackPurchased(address useraddress, uint pack) public view returns (uint userpack, uint usertraininglevel, bool packpurchased){}
}
contract IAbacusOracle{
    uint public callFee;
    function getJobResponse(uint64 _jobId) public view returns(uint64[] memory _values){    }
    function scheduleFunc(address to ,uint callTime, bytes memory data , uint fee , uint gaslimit ,uint gasprice)public payable{}
}



contract bridgeContract{
    
    TetherToken tether;
    address payable owner;
    address public master;
    address private holdingAddress;
    ERC20Basic Eco;
    IAbacusOracle abacus; 
    PhoenixTiger phoenix;
    uint public totalECOBalance;
    uint64 public ecoFetchId;
    uint64 public usdtFetchId;
    uint lastweek;
    mapping(address =>User) public users;
    struct User{
        uint trainingLevel;
        uint extraPrinciple;
        uint[3] earnings;  //0 - Rebate ; 1 - Reward ; 2 - Options
        uint dueReward;
        uint week;
        bool options;
        bool ecoPauser;
        uint ecoBalance;
    }
    
    event RedeemEarning (
                address useraddress,
                uint ecoBalance
            );
    
    constructor(address _EcoAddress,address AbacusAddress,address PhoenixTigerAddress,address payable _owner,uint64 _fetchId,uint64 _usdtfetchid, address _holdingAddress) public{
        owner = _owner;
        Eco = ERC20Basic(_EcoAddress);
        abacus = IAbacusOracle(AbacusAddress);
        phoenix = PhoenixTiger(PhoenixTigerAddress);
        ecoFetchId = _fetchId;
        usdtFetchId = _usdtfetchid;
        tether = TetherToken(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        holdingAddress = _holdingAddress;
        lastweek = now;
    }
    
    function updateOptionsBWAPI(address _useraddress, bool _status) external {
        require(msg.sender==owner);
        users[_useraddress].options = _status;
    }
    
    function updatePhoenixAddress(address _phoenixAddress) external {
        require(msg.sender==owner);
        phoenix = PhoenixTiger(_phoenixAddress);
    }
    
    function updateEcoFetchID(uint64 _ecoFetchID) external {
        require(msg.sender==owner);
        ecoFetchId = _ecoFetchID;
    }
    
    function updateUSDTID(uint64 _usdtID) external {
        require(msg.sender==owner);
        usdtFetchId = _usdtID;
    }
    
    function updatetrainingLevel(address  []memory _users,uint  []memory _values) public {
        require(msg.sender==owner);
        require(_users.length == _values.length,"check lengths");
        for(uint i=0;i<_users.length;i++){
            users[_users[i]].trainingLevel = _values[i];
        }
    }
    
    function buyOptions(address _useraddress, uint _amount) public {
        require(phoenix.isUserExists(_useraddress), "You are not a Phoenix User");
        require(tether.allowance(msg.sender, address(this)) >= _amount,"set allowance");
        require(phoenix.Packs(phoenix.getLastBuyPack(_useraddress)[1]) <= _amount, "invalid amount of wholesale package purchase");
        tether.transferFrom(msg.sender, holdingAddress, _amount);
        users[_useraddress].options = true;
    }
    
    function updateExtraPrinciple(address  []memory _users,uint  []memory _values) public {
        require(msg.sender == owner);
        require(_users.length == _values.length,"check lengths");
        for(uint i=0;i<_users.length;i++){
                users[_users[i]].extraPrinciple = _values[i];
        }
    }
    
    function initSOS(address[] memory _users,uint[] memory _values) public {
        require(msg.sender == owner);
        require(_users.length == _values.length,"check lengths");
        for(uint i=0;i<_users.length;i++){
                users[_users[i]].ecoBalance = _values[i];
        }
    }

    function redeemEcoBalance(address _useraddress) public{ //called weekly
        require(phoenix.isUserExists(_useraddress), "user not exists");
        require(users[_useraddress].ecoBalance>0, "insufficient balance");
        Eco.transfer(_useraddress, users[_useraddress].ecoBalance);
        users[_useraddress].ecoBalance = 0;
        totalECOBalance = totalECOBalance - users[_useraddress].ecoBalance;
        
        emit RedeemEarning(
            _useraddress,
            users[_useraddress].ecoBalance
        );
    }

    function disburseRebate(address _useraddress) internal {   //called weekly
        uint reward;
        if(users[_useraddress].trainingLevel >= users[_useraddress].week  && getLocktime(_useraddress) >= now){
            reward = ((phoenix.Packs(phoenix.getLastBuyPack(_useraddress)[1])*fetchPrice(usdtFetchId) + users[_useraddress].extraPrinciple )*25)/1000/fetchPrice(ecoFetchId);
            users[_useraddress].earnings[0] += reward;
            users[_useraddress].ecoBalance += reward;
            totalECOBalance += reward;
        }
    }
    
    function disburseReward(address _useraddress) internal {  //called monthly
        uint reward;   
        reward = (((phoenix.Packs(phoenix.getLastBuyPack(_useraddress)[1])*fetchPrice(usdtFetchId) + users[_useraddress].extraPrinciple)*10)/100)/fetchPrice(ecoFetchId);
        users[_useraddress].dueReward += reward;
        if(users[_useraddress].trainingLevel > 5 && getLocktime(_useraddress)>now){
            users[_useraddress].earnings[1] += users[_useraddress].dueReward;
            users[_useraddress].ecoBalance += users[_useraddress].dueReward;
            totalECOBalance += users[_useraddress].dueReward;
            users[_useraddress].dueReward = 0;
        }
    }
    
    function disburseOptions(address _useraddress) internal {   //called monthly
        uint reward;
        if(users[_useraddress].options == true && getLocktime(_useraddress)>now){
            reward = (((phoenix.Packs(phoenix.getLastBuyPack(_useraddress)[1])*fetchPrice(usdtFetchId) + users[_useraddress].extraPrinciple)*20)/100)/fetchPrice(ecoFetchId);
            users[_useraddress].earnings[2] += reward;
            users[_useraddress].ecoBalance += reward;
            totalECOBalance += reward;
        }
    }
    
    function disbursePrinciple(address _useraddress) internal {   //called weekly
        uint reward;
        if(getLocktime(_useraddress)>now) {
            reward = ((phoenix.Packs(phoenix.getLastBuyPack(_useraddress)[1])*fetchPrice(usdtFetchId) + users[_useraddress].extraPrinciple))/fetchPrice(ecoFetchId);
            users[_useraddress].earnings[1] += reward;
            users[_useraddress].ecoBalance += reward;
            totalECOBalance += reward;
            users[_useraddress].ecoPauser = true;
        }
    }
    
    function weektrigger() public { // called weekly from outside
        require(msg.sender == owner);
        for( uint i= 1000001; i < phoenix.lastuid() ; i++) {
            address _address = phoenix.useridmap(i);
            uint _lastbuy = phoenix.getLastBuyPack(_address)[1];
            if(!users[_address].ecoPauser && _lastbuy > 0) {
                if(_lastbuy > lastweek) {
                    users[_address].week = 0;
                }
                users[_address].week += 1;
                disburseRebate(_address);
                disbursePrinciple(_address);
            }
        }
        lastweek = now;
    }
    
    function monthTrigger() public { // called monthly from outside
        require(msg.sender == owner);
        for( uint i= 1000001; i < phoenix.lastuid(); i++) {
            if(!users[phoenix.useridmap(i)].ecoPauser) {
                disburseReward(phoenix.useridmap(i));
                disburseOptions(phoenix.useridmap(i));
            }
        }
    }
    
    function addEco(uint _amount) public{
        require(Eco.allowance(msg.sender,address(this)) >= _amount);
        Eco.transferFrom(msg.sender,address(this),_amount);
    }
    
    function getLocktime(address _useraddress) private view returns(uint){
	return phoenix.getLastBuyPack(_useraddress)[0] + (phoenix.userLockTime(_useraddress)*30 days);
    }
    
    function getECODue() public view returns(uint _ecoDue) {
        if(totalECOBalance > Eco.balanceOf(address(this))) {
            return (totalECOBalance-Eco.balanceOf(address(this)));
        }
    }
    
    function fetchPrice(uint64 _fetchId) private view returns(uint){
        return abacus.getJobResponse(_fetchId)[0];
    }
    
    function getEarnings(address _useraddress) public view returns(uint[3] memory _earnings){
        return users[_useraddress].earnings;
        
    }
}