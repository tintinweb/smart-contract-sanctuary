pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "Ownable.sol";

contract AtmosphereArcDCMS is Ownable{

    
    struct attachment{
        string ref;
        address author;
        bool approvedByPM;
        bool approvedByPS;
        uint status;
    }
    //status
    //0 unchecked
    //1 approved by PM
    //2 approved
    //3 refused
    struct project{
        string projectRef;
        address projectSupervisor;
        address projectManager;
        mapping (address => bool) expertsOfDomain;
        mapping (address => bool) customers;
        mapping(uint=>attachment) attachments;
        bool isFinished;
    }
    
    mapping(string=>project) projects;
    mapping(address=>string []) myProjects;
    mapping(string=>uint256) projAttachments;
    

    function addProject (address [] memory expertsOfDomain,address projectManager,string memory id, address [] memory _customers) external{
        require(projects[id].projectSupervisor==0x0000000000000000000000000000000000000000,"project already exists");
        project storage p;
        p.projectRef=id;
        p.projectSupervisor=msg.sender;
        myProjects[msg.sender].push(id);
        p.projectManager=projectManager;
        myProjects[projectManager].push(id);
        for(uint i=0;i<expertsOfDomain.length;i++){
            p.expertsOfDomain[expertsOfDomain[i]]=true;
            myProjects[expertsOfDomain[i]].push(id);
        }
        for(uint i=0;i<_customers.length;i++){
            p.customers[_customers[i]]=true;
            myProjects[_customers[i]].push(id);
        }
        projects[id]=p;
    }
    
    function addExpert(address ex,string memory projectId) external{
        require (msg.sender==projects[projectId].projectManager || msg.sender==projects[projectId].projectSupervisor,"your are not the PM/PS");
        require (projects[projectId].expertsOfDomain[ex]==false,"expert is already in the project");
        projects[projectId].expertsOfDomain[ex]=true;
        myProjects[ex].push(projectId);
    }
    
    function addCustomer(address cu,string memory projectId) external{
        require (msg.sender==projects[projectId].projectManager || msg.sender==projects[projectId].projectSupervisor,"your are not the PM/PS");
        require (projects[projectId].customers[cu]==false,"customer is already in the project");
        projects[projectId].customers[cu]=true;
        myProjects[cu].push(projectId);
    }
    
    function insertAttachment(string memory ref,uint taskId,string memory projectId) external{
        require(msg.sender==projects[projectId].projectManager || msg.sender==projects[projectId].projectSupervisor || projects[projectId].expertsOfDomain[msg.sender] || projects[projectId].customers[msg.sender] , "you are not in the project");
        attachment memory att=projects[projectId].attachments[taskId];
        require(msg.sender==att.author || att.author==0x0000000000000000000000000000000000000000,"forbidden");
        if(att.author==0x0000000000000000000000000000000000000000)
            projAttachments[projectId]++;
        att.ref=ref;
        att.author=msg.sender;
        att.approvedByPS=false;
        att.approvedByPM=false;
        att.status=0;
        projects[projectId].attachments[taskId]=att;
    }
    
    function getAttachment(uint taskId,string memory projectId) view external returns(string memory, address, bool, bool, uint){
        attachment memory att=projects[projectId].attachments[taskId];
        return(att.ref,att.author,att.approvedByPM,att.approvedByPS,att.status);
    }
    
    function getAttachments(string memory projectId) view external returns(uint256){
        return projAttachments[projectId];
    }
    
    function approve(uint taskId, string memory projectId) external{
        require (msg.sender==projects[projectId].projectManager || msg.sender==projects[projectId].projectSupervisor,"your are not the PM/PS");
        require (projects[projectId].attachments[taskId].author!=0x0000000000000000000000000000000000000000,"task id does not exist");
        if(msg.sender==projects[projectId].projectManager){
            require(!projects[projectId].attachments[taskId].approvedByPM,"you have already approved this");
            projects[projectId].attachments[taskId].approvedByPM=true;
            projects[projectId].attachments[taskId].status=1;
        }else{
            require(projects[projectId].attachments[taskId].approvedByPM,"PM have to approve this first");
            require(!projects[projectId].attachments[taskId].approvedByPS,"you have already approved this");
            projects[projectId].attachments[taskId].approvedByPS=true;
            projects[projectId].attachments[taskId].status=2;
        }
    }
    
    function disapprove(uint taskId,string memory ref,string memory projectId) external{
        require (msg.sender==projects[projectId].projectManager || msg.sender==projects[projectId].projectSupervisor,"your are not the PM/PS");
        require (projects[projectId].attachments[taskId].author!=0x0000000000000000000000000000000000000000,"task id does not exist");
        projects[projectId].attachments[taskId].approvedByPM=false;
        projects[projectId].attachments[taskId].status=3;
        projects[projectId].attachments[taskId].ref=ref;
    }
    
    function getMyProjects() external view returns(string [] memory){
        return myProjects[msg.sender];
    }
    
    function endProject(string memory projectId) external {
        require(msg.sender==projects[projectId].projectSupervisor,"you are not the supervisor");
        projects[projectId].isFinished=true;
    }
    
    function getProjectStatus(string memory projectId) view external returns(address,address,bool){
        project memory p=projects[projectId];
        return(p.projectSupervisor,p.projectManager,p.isFinished);
    }
    
}