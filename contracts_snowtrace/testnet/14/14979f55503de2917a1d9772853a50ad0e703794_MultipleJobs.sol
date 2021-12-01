/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-30
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.3;

contract MultipleJobs {

    address public owner = 0x47104585B2BDBa0B65C3082B9DA70d864355933a;

    enum Status { Active, Paid, Dispute, Refund }

    struct Project{
        address payable employer;
        address payable engineer;
        address payable reviewer;
        address validator;
        uint128 engineerPriceETH;
        uint128 reviewerPriceETH;
        uint16 engineerPriceUSD;
        uint16 reviewerPriceUSD;
        Status jobStatus;
    }

    mapping(uint => Project) public projects;

    event statusUpdated(uint32 projectId, Status status);

    function createJob(uint32 projectId,address payable engineer,address payable reviewer,uint128 engineerPriceETH,uint128 reviewerPriceETH,uint16 engineerPriceUSD,uint16 reviewerPriceUSD) public payable{

        require(msg.value == (engineerPriceETH+reviewerPriceETH), "Employer have to pay full job price");
        require(msg.sender != address(0), "Employer address not valid");
        require(projects[projectId].employer == address(0), "Project Id already in use");

        Project memory newProject = Project(msg.sender,engineer,reviewer,address(0),engineerPriceETH,reviewerPriceETH,engineerPriceUSD,reviewerPriceUSD,Status.Active);
        projects[projectId] = newProject;

        emit statusUpdated(projectId, newProject.jobStatus);
    }

    function acceptJob(uint32 projectId) public {
        require(msg.sender == projects[projectId].employer, "Only registered employer can verify the Job");

        projects[projectId].engineer.transfer(projects[projectId].engineerPriceETH);
        
        if(projects[projectId].reviewer != address(0)){

            projects[projectId].reviewer.transfer(projects[projectId].reviewerPriceETH);

        }

        projects[projectId].jobStatus = Status.Paid;

        emit statusUpdated(projectId, Status.Paid);
    }

    function openDispute(uint32 projectId,address validator) public {
        require(msg.sender == projects[projectId].employer || msg.sender == projects[projectId].engineer , "Only registered Employer or Enginner can dispute the Job");

        projects[projectId].validator = validator;

        projects[projectId].jobStatus = Status.Dispute;

        emit statusUpdated(projectId, Status.Dispute);
    }

    function jobStatus(uint32 projectId) public view returns (address,address,uint128,uint128,uint16,uint16,Status) {
        require(projects[projectId].employer != address(0), "Project id not available");

        return (projects[projectId].employer, projects[projectId].engineer, projects[projectId].engineerPriceETH, projects[projectId].reviewerPriceETH, projects[projectId].engineerPriceUSD, projects[projectId].reviewerPriceUSD, projects[projectId].jobStatus);
    }

    function markAsPass(uint32 projectId) public {
        require(projects[projectId].jobStatus == Status.Dispute, "Job has to be in dispute state");
        require(msg.sender == projects[projectId].validator, "Only registered validator can pass the job");

        projects[projectId].engineer.transfer(projects[projectId].engineerPriceETH);

        if(projects[projectId].reviewer != address(0)){

            projects[projectId].reviewer.transfer(projects[projectId].reviewerPriceETH);

        }

        projects[projectId].jobStatus = Status.Paid;

        emit statusUpdated(projectId, Status.Paid);
    }

    function markAsFail(uint32 projectId) public {
        require(projects[projectId].jobStatus == Status.Dispute, "Job has to be in dispute state");
        require(msg.sender == projects[projectId].validator, "Only registered validator can Refund");

        projects[projectId].employer.transfer(projects[projectId].engineerPriceETH);

        if(projects[projectId].reviewer != address(0)){

            projects[projectId].reviewer.transfer(projects[projectId].reviewerPriceETH);

        }
        
        projects[projectId].jobStatus = Status.Refund;

        emit statusUpdated(projectId, Status.Refund);
    }
}