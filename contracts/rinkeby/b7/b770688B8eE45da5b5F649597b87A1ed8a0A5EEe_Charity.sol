/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

contract Charity{
    struct Cause{
     string name;
     uint goal;
     bool completed;
    }
    
    struct Organization{
        string name;
        mapping(uint => Cause) causeList;
        uint fundsCollected;
        uint causeCount;
    }
    
    struct User{
        string name;
        uint moneyDonated;
        string[] orgList;
    }
    
    address private _owner;
    mapping(uint => Organization) private _organizations;
    mapping(uint => User) private _users;
    uint256 private _orgCount;
    uint256 private _userCount;
    Cause[] tmpList;
    
    
    constructor(){
        _owner=msg.sender;
    }
    
    modifier ownerCheck {
        require (msg.sender==_owner,"This Contract is only accessible by its Owner.");
        _;
    }
    
    event Register(string name,uint id,string message,uint time);
    
    function getUserCount() public view ownerCheck returns (uint count) {
        return _userCount;
    }
    
    function getOrgCount() public view ownerCheck returns (uint count) {
        return _orgCount;
    }
    
    function regUser(uint id,string memory name) public ownerCheck{
        _userCount++;
        _users[id].name=name;
        _users[id].moneyDonated=0;
        
        emit Register(name,id,"User Registered Successfully",block.timestamp);
    }
    
    
    
    function regOrg(uint id,string memory name) public ownerCheck{
        _orgCount++;
        _organizations[id].name=name;
        _organizations[id].fundsCollected=0;
        
        emit Register(name,id,"Organization Registered Successfully",block.timestamp);
    }
    
    
    function regCause(uint orgId, uint causeId,uint goal,string memory name) public ownerCheck{
        _organizations[orgId].causeCount++;
        _organizations[orgId].causeList[causeId].name=name;
        _organizations[orgId].causeList[causeId].goal=goal;
        _organizations[orgId].causeList[causeId].completed=false;
    
        emit Register(name,causeId,"Cause Created Successfully",block.timestamp);
    }
    
    
    event Donate(string donor, string organization, string cause ,uint amount, uint time);
    
    function donate(uint amount,uint userId,uint orgId,uint causeId) public ownerCheck returns(string memory message)  {
        _users[userId].orgList.push(_organizations[orgId].name);
        _users[userId].moneyDonated+=amount;
        _organizations[orgId].fundsCollected+=amount;
        
        emit Donate(_users[userId].name,_organizations[orgId].name,_organizations[orgId].causeList[causeId].name,amount,block.timestamp);
        message="Money Donated Successfully.";
    }
    
    function getOrg(uint id) public view returns(string memory name,uint fundsCollected,uint causeCount){
        name=_organizations[id].name;
        causeCount=_organizations[id].causeCount;
        fundsCollected=_organizations[id].fundsCollected;
      }

    function getUser(uint id) public view returns(string memory username, uint fundsDonated){
        username= _users[id].name;
        fundsDonated=_users[id].moneyDonated;
    }
    }