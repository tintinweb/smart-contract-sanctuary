/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

pragma solidity >=0.8.0;

contract ORG{
    uint256 totalProjects;
    uint256 totalOrganisations;
    
    struct Organisations{
        uint256 id;
        string name;
        uint256 startDate;
        bool isActive;
    }
    
    struct Projects{
        uint256 pid;
        uint256 organisationId;
        string title;
        string desc;
        uint256 startDate;
        uint256 timeline;
        string status;
    }
    
    mapping (uint256=>Organisations) public organisationInfo;
    mapping (uint256=>Projects) public projectInfo;
    mapping (address=>uint256) public ownerToOrg;
    mapping (uint256=>address) public orgToOwner;
    mapping (uint256=>address[]) public teamMembers;
    
    function createOrganisation(
        string memory _name
        ) public{
            require(ownerToOrg[msg.sender]==0, " owner already exist");
            totalOrganisations++;
            organisationInfo[totalOrganisations] = Organisations({id:totalOrganisations,name:_name,startDate:block.timestamp, isActive:true});
            ownerToOrg[msg.sender] = totalOrganisations;
            
        }
        
    function createProject(string memory _title,
    uint256 _organisationId,
        string memory _desc,
        uint256 _timeline) public{
        totalProjects++;
        projectInfo[totalProjects] = Projects({pid:totalProjects,organisationId:_organisationId,title:_title,desc:_desc,timeline:_timeline,startDate:block.timestamp,status:"pending"});
    }
    
    function addTeamMembers(address _newMember, uint256 _organisationId) public{
        require(msg.sender == orgToOwner[_organisationId], "you can't add members");
        teamMembers[_organisationId].push(_newMember);
    }
}