/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

// SPDX-License-Identifier: unlicensed 

 pragma solidity ^0.6.0;


contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor()  public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

  
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

   
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    
    function ceil(uint a, uint m) internal pure returns (uint r) {
        return (a + m - 1) / m * m;
    }
}

contract VotingSystem is Owned {
    using SafeMath for uint256;
    struct USER{
        bytes32 Name;
        bytes32 Email;
        bytes32 Pass;
        uint256 PhoneNumber;
        string HomeAddress;
        uint256[] votedOn; // ElectionID
        uint256[] voteID; // VoteID
        bool Verified;
        bool isExist;
    }
    
    struct CANDIDATE{
        bytes32 Name;
        string Desription;
        uint256 ElectionID;
        string Image;
        uint256 CanditateValue;
        uint256 votes;
        bool isExist;
        
    }
    
    struct RESULT{
        uint256 ElectionID;
        uint256 Winner;
        uint256 TotalVotes;
        uint256 WinnerVotes;
    }
    
    struct ELECTION{
        uint256 ElectionID;
        bytes32 ElectionName;
        uint256 [] Candidates;
        uint256 ElectionStartTime;
        uint256 ElectionEndTime;
    }
    
    struct Vote{
        uint256 voteID;
        address userAddress;
        uint256 CanditateValue;
        bool verified;
    }
    
    mapping(address => USER) private users;
    mapping(uint256 => CANDIDATE) public candidates;
    mapping(uint256 => RESULT) public results;
    mapping(uint256 => ELECTION) public elections;
    mapping(uint256 => Vote) public votes;
       
   
    uint256[] electionlist;
    uint256[] candidatelist;
    uint256[] resultlist;
    uint256[] voterlist;
    address[] userlist;
      
       
    event USER_REGISTERD(address userAddress,bytes32 userName);
    event VOTE_CASTED(address userAddress,uint256 CANDIDATEID);
    event ElectionCreated(bytes32 ElectionName,uint256 starttime);
    event ResultComputed(uint256 Winner, uint256 ElectionID);
       
    constructor() public {
         owner = msg.sender;
         users[msg.sender].Name = "Admin";//"0x41646d696e"; //Admin
         users[msg.sender].Email =  "[email protected]";//"0x41646d696e4061646d696e2e636f6d";//[email protected]
         users[msg.sender].PhoneNumber= 1223456;
         users[msg.sender].HomeAddress="NULL";
         users[msg.sender].Verified = true;
         users[msg.sender].isExist =true;
         users[msg.sender].Pass = "admin123";//"0x61646d696e313233"; //admin123
         
    }
    function  RegisterUser(bytes32 names,bytes32 emails,uint256 contact,string memory addresses,bytes32 password) public{ 
        
        if(users[msg.sender].isExist)
        {
            revert('user already exsists');
        }
        else
        {
            users[msg.sender].Name = names;
            users[msg.sender].Email = emails;
            users[msg.sender].PhoneNumber = contact;
            users[msg.sender].HomeAddress= addresses;
            users[msg.sender].Pass = password;
            users[msg.sender].Verified = true;
            users[msg.sender].isExist =true;
            userlist.push(msg.sender);
    
            emit USER_REGISTERD(msg.sender, users[msg.sender].Name);
        }
     
    }
    
    function createCandidate(bytes32 CandidateName, string memory Desription, uint256 ElectionID, string memory Image) public onlyOwner(){
        
        
        if(block.timestamp < elections[ElectionID].ElectionStartTime)
        
        {
            
        
            
        uint256 _id = candidatelist.length;            
        candidates[_id].Name = CandidateName;
        candidates[_id].CanditateValue = _id; 
        candidates[_id].Desription = Desription;
        candidates[_id].Image = Image;
        candidates[_id].ElectionID = ElectionID;
        candidates[_id].votes = 0;
        candidates[_id].isExist = true;
        elections[ElectionID].Candidates.push(_id);
        candidatelist.push(_id);
           
        }else{
            revert('Election Has Already Started');
        } 
        
        
        
    }
 
    function editCandidate(bytes32 CandidateName, string memory Desription, uint256 ElectionID, uint256 _id) public onlyOwner(){
        
            if(candidates[_id].isExist)
            {
        
        if(block.timestamp > elections[ElectionID].ElectionEndTime ||  block.timestamp < elections[ElectionID].ElectionStartTime)
        {
            
            candidates[_id].Name = CandidateName;
            candidates[_id].Desription = Desription;
            candidates[_id].ElectionID = ElectionID;
            candidates[_id].votes = 0;
        
           
        }else{
            
            revert('Election Has Already Started');
            
        } 
        
            }else{
          
            revert('Sorry, Candidate Does not Exsist');
          
            }
        
    }

    function AcceptUser(uint256 voter) onlyOwner() public returns(bytes32 result){
    
    if( !(votes[voter].verified))
    {
        votes[voter].verified = true;
        uint256 candId = votes[voter].CanditateValue;
       // address votAdd = votes[voter].userAddress;
       // uint256 ElectionID = candidates[candId].ElectionID; 
        candidates[candId].votes = (candidates[candId].votes).add(1);
                //users[votAdd].votedOn.push(ElectionID);
               // users[votAdd].voteID.push(voter);
   
    }
   
   
    return "Vote Verified";
    
}

    function createElection(bytes32 ElectonNam, uint256[] memory candidatelists, uint256 starttime, uint256 endtime)public onlyOwner(){
        
        
            
        uint256 _id = electionlist.length;            
        elections[_id].ElectionName = ElectonNam;
        elections[_id].ElectionID = _id; 
        elections[_id].Candidates = candidatelists;
        elections[_id].ElectionStartTime = starttime;
        elections[_id].ElectionEndTime = endtime;
        electionlist.push(_id);
        emit ElectionCreated(ElectonNam,starttime);
        
            
        
    }
    
    function computeResult(uint256 ElectionID)  public onlyOwner(){
        if(block.timestamp > elections[ElectionID].ElectionEndTime)
        {
        
        uint256 maxVotes=0;
        uint256 maxID=0;
        uint256 tVotes=0;
        for(uint256 i=0; i<elections[ElectionID].Candidates.length;i++)
        {
            uint256 temp = elections[ElectionID].Candidates[i];
            tVotes = tVotes.add(candidates[temp].votes);
            if(i==0)
            {
                maxVotes = candidates[temp].votes;
                maxID = temp;
                
            }else{
                
                if(candidates[temp].votes > maxVotes){
                    maxVotes = candidates[temp].votes;
                    maxID =temp;
                }
            }
            
        }
        
            uint256 _id= resultlist.length;
             results[_id].ElectionID = ElectionID;
            results[_id].Winner = maxID;
            results[_id].TotalVotes = tVotes;
            results[_id].WinnerVotes = maxVotes;
            resultlist.push(_id);
            emit ResultComputed(maxID,ElectionID);
    
        }else{
            revert('Election hasnt been over yet');
        }    
    }
    
    function RegisterVoter(uint256 CandidateId, uint256 ElectionID) public{
        if((block.timestamp > elections[ElectionID].ElectionStartTime) && (block.timestamp < elections[ElectionID].ElectionEndTime))
        {
       
           if(users[msg.sender].Verified)
           {
                uint256 _id = voterlist.length;   
               if(users[msg.sender].votedOn.length >0)
               {
                
                for(uint i=0; i< users[msg.sender].votedOn.length; i++)
                {
                    if(users[msg.sender].votedOn[i] == ElectionID)
                    {
                        revert('Already Voted In this election');
                    }
                }
                
                
                votes[_id].voteID = _id;
                votes[_id].userAddress = msg.sender;
                votes[_id].CanditateValue = CandidateId;
                votes[_id].verified = false;
                voterlist.push(_id);
                users[msg.sender].votedOn.push(ElectionID);
                users[msg.sender].voteID.push(_id);
                
               }else{
                   
                
                votes[_id].voteID = _id;
                votes[_id].userAddress = msg.sender;
                votes[_id].CanditateValue = CandidateId;
                votes[_id].verified = false;
                voterlist.push(_id);   
                users[msg.sender].votedOn.push(ElectionID);
                users[msg.sender].voteID.push(_id);
               }
                    
           }else{
                revert('Please Verify yourself First');
           }
                

        }
            else{
                
                 revert('This Election is not currently Active');
        
            }

        
    }
        
    function Login(bytes32 pass, bytes32 email) public view returns(  bytes32 Name, bytes32 Email, bytes32 Pass, uint256 PhoneNumber, string memory HomeAddress, uint256[] memory votedOn, bool Verified, bool isExist){   
                require(users[msg.sender].isExist == true,"User Does Not Exsist");
                require(users[msg.sender].Pass == pass && users[msg.sender].Email == email,"Password or Email  Incorrect");
                return (users[msg.sender].Name, users[msg.sender].Email, users[msg.sender].Pass, users[msg.sender].PhoneNumber, users[msg.sender].HomeAddress, users[msg.sender].votedOn, users[msg.sender].Verified, users[msg.sender].isExist);
            }
  
    function getAll() public onlyOwner() view returns (address[] memory){
       return userlist;
    }
    
    function getUser(address user) public onlyOwner() view returns(  bytes32 Name, bytes32 Email, uint256 PhoneNumber, string memory HomeAddress,  bool Verified, bool isExist){   
                
                return (users[user].Name, users[user].Email,  users[user].PhoneNumber, users[user].HomeAddress,  users[user].Verified, users[user].isExist);
            }
    
    function getElectionList() public view returns(uint256[] memory){
        return electionlist;
    }
    
    function getCandidateList() public view returns(uint256[] memory){
        return candidatelist;
    }
    
    function getResultList() public view returns(uint256[] memory){
        return resultlist;
    }
    
    function getVoterslist() public view returns(uint256[] memory){
        return voterlist;
    }
    
    function getElectionCandidates(uint256 ElectionID) public view returns(uint256[] memory){
        
        return elections[ElectionID].Candidates;
    }
   
    function getUserVotedOn(address user) public view returns(uint256[] memory){
        return users[user].votedOn;
    }
    
    function voteDetailsUser(address user) public view returns(uint256[] memory){
        return users[user].voteID;
    }
     
    function updateInformation(bytes32 Name, bytes32 Email, uint256 PhoneNumber, string memory HomeAddress, bytes32 Pass) public {
        
        require(users[msg.sender].isExist == true, "User Must Exsist");
        users[msg.sender].Name = Name;
        users[msg.sender].PhoneNumber = PhoneNumber;
        users[msg.sender].HomeAddress = HomeAddress;
        users[msg.sender].Pass = Pass;
        users[msg.sender].Email = Email;
    }
    
    function changePass(bytes32 OldPass, bytes32 NewPass) onlyOwner public{
        require(OldPass == users[msg.sender].Pass,"Old Password doesnot matches");
        users[msg.sender].Pass = NewPass;
    }
    
    function fotgetPass( bytes32 Email, bytes32 NewPass) public{
        require(users[msg.sender].Email == Email,"Email Does not Match with your registed Account");
        users[msg.sender].Pass = NewPass;
    }
}