/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract owned
{
    address public owner;
    address internal newOwner;
  
    
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor()  {
        owner = msg.sender;
        
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }




    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error

}




contract DealCracker is owned{
    
    uint256 projectID;
    
    //projectMilestone
    
    	struct projectMilestone {
		uint256 phase;
		uint256 allocFund;
        bool isFinished;
        
    }
    
        // project details	
	struct projectInfo {
		string name;
		uint256 Totalfund;
        address payable developer;
        uint256 developerremainFund;
        uint256 developerReceivedFund;
        projectMilestone[] milestone;
        uint256 totalMileston;
        uint256 achievedMileston;
        bool isFinished;
    }
    
    mapping (uint256 => projectInfo) public projectinfos;

    
    
    constructor(){
        
        projectID=1;
        
        
    }
    
    
    fallback () payable external {
        
    }
    
    receive() payable external{
        
    }
    
    function getContractBalnce () public view returns(uint256){
        
        return address(this).balance;
    }
    event ProjectEvent(uint256 _id, address _to, uint256 _total);
    function addProject (string calldata _projectName, uint256 _totalFund, address payable _developer) public payable onlyOwner returns(bool){
    
        uint256 contractBalance = address(this).balance;
        require(_developer!=address(0),"invalid address");
        require(contractBalance>0,"contract have not sufficient balance");
        require(contractBalance>=_totalFund,"no fund for Project");
        projectinfos[projectID].name=_projectName;
        projectinfos[projectID].Totalfund=_totalFund;
        projectinfos[projectID].developer=_developer;
        projectinfos[projectID].developerremainFund=_totalFund;
        projectinfos[projectID].developerReceivedFund=0;
        projectinfos[projectID].isFinished=false;
        
        emit ProjectEvent(projectID,_developer,_totalFund);
    
        projectID++;
        
        return true;
    }
    
    event ProjectMilestoneEvent(uint256 _pid, uint256 _phase, uint256 _total);
   function addProjectMileStone(uint256 _pid,uint256 _phase,uint256 allocFund)public onlyOwner returns(bool){
       require(projectinfos[_pid].Totalfund>=allocFund,"invalid fund");
       
       projectinfos[_pid].milestone.push(projectMilestone(_phase,allocFund,false));// add new milestone in current project
       projectinfos[_pid].totalMileston=projectinfos[_pid].milestone.length; // total no of milestone a project contain.
       
       emit ProjectMilestoneEvent(_pid,_phase,allocFund);
       return true;
       
   }
   
   function getProjectMileston(uint256 _pid,uint256 _mid) external view returns(uint256 _phase,uint256 _fundalloc,bool _isFinish){
    //   allocFund
    // percent
       return (projectinfos[_pid].milestone[_mid].phase,projectinfos[_pid].milestone[_mid].allocFund,projectinfos[_pid].milestone[_mid].isFinished);
       
   }
   
   event AchievedMilestoneEvent(uint256 _pid, uint256 _mid, uint256 _total);
   function setMilestoneAchieve(uint256 _pid,uint256 _mid) external onlyOwner returns(bool) {
       
       require(projectinfos[_pid].isFinished==false,"project is Finished please use another project");
       require(projectinfos[_pid].milestone[_mid].isFinished==false,"milestone is achieved please use another milestone");
       projectinfos[_pid].milestone[_mid].isFinished=true;
       uint256 amount = projectinfos[_pid].milestone[_mid].allocFund;
       require(address(this).balance>=amount,"insufficient balance");
       require(projectinfos[_pid].developerremainFund>=amount,"invalid amount");
       projectinfos[_pid].achievedMileston=_mid+1;
       if( projectinfos[_pid].achievedMileston==projectinfos[_pid].milestone.length){
           
           projectinfos[_pid].isFinished=true;
       }
       projectinfos[_pid].developerReceivedFund+=amount;
       
       projectinfos[_pid].developerremainFund-=amount;
       projectinfos[_pid].developer.transfer(amount);
       emit AchievedMilestoneEvent(_pid,_mid,amount);
       return true;
      
   }
   
   event projectFundEvent(uint256 _pid,  uint256 _total);
   function addProjectFund(uint256 _pid) public payable onlyOwner returns(bool){
       
       require(msg.value>0,"insufficient value");
       projectinfos[_pid].Totalfund+=msg.value;
       projectinfos[_pid].developerremainFund+=msg.value;
       emit projectFundEvent(_pid,msg.value);
       return true;
   } 
    
    
}