pragma solidity ^0.4.23;

/* Team Littafi
**/

 
/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint256 a, uint256 b) public pure returns (uint256) {
     if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert( c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) public pure returns (uint256) {
    //assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    //assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) public pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) public pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) public pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) public pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) external pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) external pure returns (uint256) {
    return a < b ? a : b;
  }

}


 contract LittafiOwned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner public{
        newOwner = _newOwner;
    }

    function acceptOnwership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner,newOwner);
        owner=newOwner;
        newOwner=address(0);
    }

}

 contract Littafi is LittafiOwned{

      using SafeMath for uint256;

      uint256   public littID=0;
      uint256   public littClientId=1;
      bool      public sentinel=true;
      uint256   public littafiAccount=0;
      uint256   public littAdmins;

      littafiContents[] public littafi;

      mapping(bytes32 => address) littClientAddress;

      mapping(bytes32 => string)  littIPFS;

      mapping(bytes32 => uint256) littHashID;

      mapping(bytes32 => uint256) littCapsule;

      mapping(address => littafiAdmin) admins;

      mapping(address => littafiSubscribtion) subscriber;

      mapping(address => bool) subscriberStatus;

      mapping(uint256 => address) poolAdmin;

      mapping(uint256 => address) setPoolAdmin;

      mapping(address => bool) isDelegateAdmin;

      mapping(uint256 => string)  poolName;

      mapping(address => bytes32[]) subscriberContentHashes;

      mapping(address => uint256)  subscriberContentCount;
      
      mapping(address => bool) transferred;

      struct littafiContents{
          uint256 id;
          bytes32 hash;
          string  ipfs;
          string timestamp;
          string  metadata;
          string  unique;
          uint256 clientPool;
          bool    access;
      }

      struct littafiAdmin{
          uint256 poolID;
          bool isAdmin;
          string poolName;
      }

      struct littafiSubscribtion{
          uint256 subID;
          uint256 clientPool;
      }

      modifier onlyLittafiAdmin(uint256 _poolID){
          require(admins[msg.sender].isAdmin == true && admins[msg.sender].poolID == _poolID && msg.sender != owner);
          _;
      }

      modifier onlyLittafiSubscribed(){
          require(msg.value > 0 && subscriber[msg.sender].subID > 0 && msg.sender != owner);
          _;
      }

      modifier onlyLittafiNonSubscribed(){
          require(msg.value > 0 && subscriber[msg.sender].subID == 0 && msg.sender != owner);
          _;
      }

      modifier onlyDelegate(){
          require(msg.sender == owner || isDelegateAdmin[msg.sender] == true);
          _;
      }

      modifier onlyLittafiContentOwner(bytes32 _hash){
          require(msg.sender == littClientAddress[_hash]);
          _;
      }

      event littContent(address indexed _address,bytes32 _hash, string _ipfs, string _timestamp, string _metadata, string unique, uint256 _poolID, bool _access, bool success);

      event littClientSubscribed(address indexed _address, string _timestamp,uint256 _fee,uint256 _poolID,bool success);

      event littafiAssignedID(address indexed _adminAddress, string _timestamp, uint256 _poolID, address indexed _address);

      event littafiAdminReassigned(address indexed _previousAdmin,address indexed _newAdmin,string _timestamp,uint256 _assignedID);

      event littafiDelegateAdmin(address indexed _admin, address indexed _delegate,bool _state,string _timestamp);

      event littContentAccessModified(address indexed _admin,bytes32 _hash, uint256 _poolID,bool _access);

      event littPoolModified(address indexed _address,string _poolName,uint256 _poolID);

      event littContentOwnershipTransferred(bytes32 _hash, address indexed _address, string _timestamp);

      constructor() public{
          LittafiOwned(msg.sender);
      }

      function subscribtionLittafi(uint256 _assignedID,string _timestamp, string _poolName) public payable onlyLittafiNonSubscribed(){

          if(_assignedID > 0 && setPoolAdmin[_assignedID] == msg.sender){
             subscriber[msg.sender].subID=littClientId;
             subscriber[msg.sender].clientPool=_assignedID;
             subscriberStatus[msg.sender]=true;
             admins[msg.sender].poolID=_assignedID;
             admins[msg.sender].isAdmin=true;
             admins[msg.sender].poolName=_poolName;
             poolAdmin[_assignedID]=msg.sender;
             poolName[_assignedID]=_poolName;
             littClientId++;
             littAdmins++;
             owner.transfer(msg.value);
             littafiAccount.add(msg.value);

             emit littClientSubscribed(msg.sender,_timestamp,msg.value,_assignedID,true);
             return;
          }else{
              subscriber[msg.sender].subID=littClientId;
              subscriber[msg.sender].clientPool=0;
              subscriberStatus[msg.sender]=true;
              littClientId++;
              owner.transfer(msg.value);

              emit littClientSubscribed(msg.sender,_timestamp,msg.value,0,true);
              return;
          }
      }

      function littafiContentCommit(bytes32 _hash,string _ipfs,string _timestamp,string _metadata,string _unique,bool _sentinel) public payable onlyLittafiSubscribed(){

             uint256 id=littHashID[_hash];
             if (littClientAddress[_hash] != address(0)){
                emit littContent(littClientAddress[_hash],_hash,littIPFS[_hash],littafi[id].timestamp,littafi[id].metadata,littafi[id].unique,littafi[id].clientPool,littafi[id].access,true);
                return;
             }else{

              if(admins[msg.sender].isAdmin == true) sentinel=_sentinel;

              littafiContents memory commit=littafiContents(littID,_hash,_ipfs,_timestamp,_metadata,_unique,subscriber[msg.sender].clientPool,sentinel);
              littafi.push(commit);

              subscriberContentCount[msg.sender]++;
              subscriberContentHashes[msg.sender].push(_hash);
              littClientAddress[_hash]=msg.sender;
              littIPFS[_hash]=_ipfs;
              littHashID[_hash]=littID;
              littID++;
              owner.transfer(msg.value);

              emit littContent(msg.sender,_hash,_ipfs,_timestamp,_metadata,_unique,subscriber[msg.sender].clientPool,sentinel,true);
              return;
             }

      }

      function littafiTimeCapsule(bytes32 _hash,string _ipfs,string _timestamp,string _metadata,string _unique,uint256 _capsuleRelease) public payable onlyLittafiSubscribed(){

             uint256 id=littHashID[_hash];
             if (littClientAddress[_hash] != address(0)){
                emit littContent(littClientAddress[_hash],_hash,littIPFS[_hash],littafi[id].timestamp,littafi[id].metadata,littafi[id].unique,littafi[id].clientPool,littafi[id].access,true);
                return;
             }else{

              littafiContents memory commit=littafiContents(littID,_hash,_ipfs,_timestamp,_metadata,_unique,subscriber[msg.sender].clientPool,sentinel);
              littafi.push(commit);

              subscriberContentCount[msg.sender]++;
              littCapsule[_hash]=_capsuleRelease;
              littClientAddress[_hash]=msg.sender;
              littIPFS[_hash]=_ipfs;
              littHashID[_hash]=littID;
              littID++;
              owner.transfer(msg.value);

              emit littContent(msg.sender,_hash,_ipfs,_timestamp,_metadata,_unique,subscriber[msg.sender].clientPool,sentinel,true);
              return;
             }

      }

      function transferContentOwnership(bytes32 _hash, address _address, string _timestamp) public {
          require(littClientAddress[_hash] == msg.sender);
          littClientAddress[_hash]=_address;
          emit littContentOwnershipTransferred(_hash,_address,_timestamp);
          return;
      }

      function getLittafiContent(bytes32 _hash,uint256 _poolID) public payable{
        if (littClientAddress[_hash] != address(0) && littafi[littHashID[_hash]].clientPool==_poolID){
            owner.transfer(msg.value);
            emit littContent(littClientAddress[_hash],_hash,littIPFS[_hash],littafi[littHashID[_hash]].timestamp,littafi[littHashID[_hash]].metadata,littafi[littHashID[_hash]].unique,littafi[littHashID[_hash]].clientPool,littafi[littHashID[_hash]].access,true);
            return;
        }
      }

      function setDelegateAdmin(address _address, string _timestamp, bool _state) public onlyOwner() returns(bool){
          require(admins[_address].isAdmin == false);
          isDelegateAdmin[_address]=_state;
          emit littafiDelegateAdmin(msg.sender,_address,_state,_timestamp);
          return true;
      }

      function setAssignedID(address _address,uint256 _assignedID, string _timestamp) public onlyDelegate(){
          require(setPoolAdmin[_assignedID] == address(0));
          setPoolAdmin[_assignedID]=_address;
          emit littafiAssignedID(msg.sender,_timestamp,_assignedID,_address);
          return;
      }

      function changeAssignedAdmin(address _newAdmin, uint256 _assignedID, string _timestamp) public onlyOwner(){
          address _previousAdmin=poolAdmin[_assignedID];

          admins[_previousAdmin].isAdmin=false;
          admins[_previousAdmin].poolID=0;
          subscriber[_previousAdmin].clientPool=0;

          if(!subscriberStatus[_newAdmin])
             subscriber[_newAdmin].subID=littID;
             subscriber[_newAdmin].clientPool=_assignedID;

          admins[_newAdmin].isAdmin=true;
          admins[_newAdmin].poolID=_assignedID;
          littID++;

          emit littafiAdminReassigned(_previousAdmin,_newAdmin,_timestamp,_assignedID);
          return;
      }

      function getPoolAdmin(uint256 _poolID) public view onlyDelegate() returns(address){
          return poolAdmin[_poolID];
      }

      function modifyContentAccess(bytes32 _hash, bool _access, uint256 _poolID)public onlyLittafiAdmin(_poolID){
         littafi[littHashID[_hash]].access=_access;
         emit littContentAccessModified(msg.sender,_hash,_poolID,_access);
         return;
      }

      function getClientCount() public view returns(uint256){
          return littClientId;
      }

      function getContentCount() public view returns(uint256){
          return littID;
      }

      function getLittAdminCount() public view onlyDelegate() returns(uint256){
          return littAdmins;
      }

      function setPoolName(string _poolName,uint256 _poolID) public onlyLittafiAdmin(_poolID){
          admins[msg.sender].poolName=_poolName;
          emit littPoolModified(msg.sender,_poolName,_poolID);
          return;
      }

      function getPoolName(uint256 _poolID) public view onlyLittafiAdmin(_poolID) returns(string){
          return admins[msg.sender].poolName;
      }

      function getPoolNameByID(uint256 _poolID) public view returns(string){
          return poolName[_poolID];
      }

      function getPoolID() public view returns(uint256){
          return subscriber[msg.sender].clientPool;
      }

      function getSubscriberType() public view returns(bool){
          return admins[msg.sender].isAdmin;
      }

      function getSubscriberStatus() public view returns(bool){
          return subscriberStatus[msg.sender];
      }

      function getSubscriberContentCount() public view returns(uint256){
          return subscriberContentCount[msg.sender];
      }

      function getSubscriberContentHashes() public view returns(bytes32[]){
          return subscriberContentHashes[msg.sender];
      }

      function getDelegate() public view returns(bool){
          return isDelegateAdmin[msg.sender];
      }

      function littContentExists(bytes32 _hash) public view returns(bool){
          return littClientAddress[_hash] == address(0) ? false : true;
      }

      function littPoolIDExists(uint256 _poolID) public view returns(bool){
          return poolAdmin[_poolID] == address(0) ? false : true;
      }

      function littIsCapsule(bytes32 _hash) public view returns(bool){
          return littCapsule[_hash] == 0 ? false : true;
      }

      function littCapsuleGet(bytes32 _hash) public view returns(uint256){
          return littIsCapsule(_hash) == true ? littCapsule[_hash] : 0;
      }
      
}