pragma solidity ^0.4.25;

contract ONGContract {
    
    address private owner;
    address private oracle;
    int256 period;
    int256 epoch;
    int256 totalAvailableTokens;
    
    struct Project {
        string Name;
        address Owner;
        int256 Tokens;
        bool Disabled;
    }
    
    struct Member {
        string Name;
        int256 Tokens;
        int256 Epoch;
        bool Disabled;
    }
    
    mapping(int256 => Project) projects;
    mapping(address => Member) members;
    
    constructor () public {
        owner = msg.sender;
        period = 0;
        epoch = 0;
        oracle = address(0x14723a09acff6d2a60dcdf7aa4aff308fddc160c);
    }
    
    function AssignOwnerToProject(int256 id, address projectOwner) public {
        require(msg.sender == owner || projects[id].Owner == msg.sender);
        
        projects[id].Owner = projectOwner;
    }
    
    function ProjectOwner_DisableProject(int256 id) public {
        require(projects[id].Owner == msg.sender);
        projects[id].Disabled = true;
    }
    
    function ProjectOwner_EnableProject(int256 id) public {
        require(projects[id].Owner == msg.sender);
        projects[id].Disabled = false;
    }
    
    function AddTokensToMember (address member, int256 tokens) public {
        require(msg.sender == owner && !members[member].Disabled && period == 1);
        
        if(members[member].Epoch != epoch) {
            members[member].Tokens = 0;
            members[member].Epoch = epoch;
        }
        
        members[member].Tokens += tokens;
        totalAvailableTokens  += tokens;
    }
    
    function ReasignTokens(int256 id, int256 tokens) public {
        require(msg.sender == owner && !projects[id].Disabled && 
        totalAvailableTokens >= tokens && period == 3);
        
        totalAvailableTokens -= tokens;
        projects[id].Tokens += tokens;
    }
    
    function DisableMember(address member) public {
        require(msg.sender == owner);
        members[member].Disabled = true;
    }
    
    function EnableMember(address member) public {
        require(msg.sender == owner);
        members[member].Disabled = false;
    }
    
    function Member_GetMyTokens () public returns(int256) {
        require(!members[msg.sender].Disabled && period == 2);
        
        if(members[msg.sender].Epoch != epoch) {
            members[msg.sender].Tokens = 0;
            members[msg.sender].Epoch = epoch;
        }
        
        return members[msg.sender].Tokens;
    }
    
    function Member_AssignTokensToProject (int256 id, int256 tokens) public {
        require(!members[msg.sender].Disabled && !projects[id].Disabled &&
        members[msg.sender].Tokens >= tokens && period == 2);
        
        if(members[msg.sender].Epoch != epoch) {
            members[msg.sender].Tokens = 0;
            members[msg.sender].Epoch = epoch;
        }
        
        members[msg.sender].Tokens -= tokens;
        totalAvailableTokens  -= tokens;
        projects[id].Tokens += tokens;
    }
    
    function Oracle_ChangePeriod () public {
        require(msg.sender == oracle);
        
        if(period < 3) {
            period++;
        } else {
            epoch++;
            period = 1;
        }
        
    }
}