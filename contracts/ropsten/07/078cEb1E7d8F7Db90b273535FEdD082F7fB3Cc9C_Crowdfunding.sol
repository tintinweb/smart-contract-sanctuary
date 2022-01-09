/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/// @title Crowdfunding.
/// @author andres15alvarez
/// @notice With this contract you cand fund a project or create one. 
/// After a project has finihsed, a percentage going to the addres that deployed the contract.
contract Crowdfunding{
    mapping (uint=>Project) projects;
    mapping (uint=>Transaction[]) projectTransactions;
    mapping (uint=>Contributor[]) projectContributors;
    uint commission;
    uint projectsCounter;
    address payable platform;

    struct Owner {
        address payable ownerAddress;
        string email;
    }

    struct Contributor {
        address payable contributor;
        uint amount;
    }

    struct Transaction {
        address contributor;
        uint amount;
    }

    struct Project {
        uint id;
        uint goal;
        uint amount;
        uint countContributors;
        bool isOpen;
        Owner owner;
        string name;
    }

    /// @notice Alert when a project is created.
    /// @dev Event when a project is created and you need the id of the project to interact with it.
    /// @param id Project Id
    event ProjectCreation(uint id);

    /// @notice Alert of funding in a project.
    /// @dev Event when a contribution to a project was made.
    /// @param contributor Address of the contributor
    /// @param amount Fund amount in wei.
    event FundingAlert(address indexed contributor, uint amount);

    /// @notice Alert when the project collect the goal.
    /// @dev Event when the project has funded all.
    /// @param amount Total amount funded in the project.
    event FundingFinished(uint amount);

    constructor (){
        commission = 50;
        projectsCounter = 0;
        platform = payable(msg.sender);
    }

    modifier isOwner(uint projectId){
        require(
            msg.sender != projects[projectId].owner.ownerAddress,
            "The owner cannot funds its project."
        );
        _;
    }

    modifier isOpen(uint projectId){
        require(
            projects[projectId].isOpen,
            "The project has finished"
        );
        _;
    }

    modifier validProject(uint projectId){
        require(
            projects[projectId].id != 0,
            "The project does not exists"
        );
        _;
    }

    /// @notice Create a crowfunding project.
    /// @dev Explain to a developer any extra details
    /// @param projectGoal Amount in wei to project goal.
    /// @param ownerEmail Email of the project's owner.
    /// @param projectName Name of the project.
    /// @return projectId Id of the project to interact with it.
    function createProject(
        uint projectGoal,
        string memory ownerEmail,
        string memory projectName
    ) public returns (uint){
        Owner memory newOwner = Owner({ownerAddress: payable(msg.sender), email: ownerEmail});
        projectsCounter = projectsCounter + 1;
        uint projectId = projectsCounter;
        Project memory newProject = Project({
            id: projectId,
            name: projectName,
            goal: projectGoal,
            owner: newOwner,
            countContributors: 0,
            amount: 0,
            isOpen: true
        });
        projects[projectId] = newProject;
        emit ProjectCreation(projectId);
        return projectId;
    }

    /// @notice Fund project by its Id.
    /// @dev This method allows fund a project given its id, save the transaction and the msg.sender to contributors it not exists.
    /// @param projectId Project Id.
    /// @return Transaction mapping struct with the amount in wei and tha ddress of the contributor.
    function fundProject(uint projectId) public payable isOpen(projectId) isOwner(projectId) returns (Transaction memory){
        projects[projectId].amount += msg.value;
        if (projects[projectId].countContributors == 0){
            projects[projectId].countContributors = 1;
            projectContributors[projectId].push(
                    Contributor({contributor: payable(msg.sender), amount: msg.value})
            );
        } else{
            for (uint256 i = 0; i < projects[projectId].countContributors; i++) {
                if (projectContributors[projectId][i].contributor == payable(msg.sender)){
                    projectContributors[projectId][i].amount += msg.value;
                    break;
                }
                if (i == projects[projectId].countContributors - 1){
                    projectContributors[projectId].push(
                        Contributor({contributor: payable(msg.sender), amount: msg.value})
                    );
                }
            }
        }
        Transaction memory transaction = Transaction({contributor: msg.sender, amount: msg.value});
        projectTransactions[projectId].push(transaction);
        emit FundingAlert(msg.sender, msg.value);
        if (projects[projectId].amount >= projects[projectId].goal){
            projects[projectId].isOpen = false;
            emit FundingFinished(projects[projectId].amount);
            platform.transfer(projects[projectId].amount * commission / 1000);
            projects[projectId].owner.ownerAddress.transfer(projects[projectId].amount * (1000 - commission) / 1000);
        }
        return transaction;
    }

    /// @notice Obtain all the transactions in a project.
    /// @param projectId Id of the project.
    /// @return Transactions Array of Transactions with contributor and amount.
    function getProjectTransactions(uint projectId) public view validProject(projectId) returns (Transaction[] memory){
        return projectTransactions[projectId];
    }

    /// @notice Obtain all the contributors of a project.
    /// @param projectId Id of the project.
    /// @return Contributors Array of Transactions with contributor and amount.
    function getProjectContributors(uint projectId) public view validProject(projectId) returns (Contributor[] memory){
        return projectContributors[projectId];
    }

    /// @notice Obtain the project current amount funded.
    /// @param projectId Id of the project.
    /// @return amount amount funded in wei.
    function getProjectAmount(uint projectId) public view validProject(projectId) returns (uint){
        return projects[projectId].amount;
    }

    /// @notice Obtain the project goal.
    /// @param projectId Id of the project.
    /// @return goal amount to fund in wei.
    function getProjectGoal(uint projectId) public view validProject(projectId) returns (uint){
        return projects[projectId].goal;
    }

    /// @notice Obtain the project status, if is open.
    /// @param projectId Id of the project.
    /// @return isOpen boolean.
    function getProjectStatus(uint projectId) public view validProject(projectId) returns (bool){
        return projects[projectId].isOpen;
    }

    /// @notice Obtain the project name.
    /// @param projectId Id of the project.
    /// @return name string of the project name.
    function getProjectName(uint projectId) public view validProject(projectId) returns (string memory){
        return projects[projectId].name;
    }

    /// @notice Obtain the project owner.
    /// @param projectId Id of the project.
    /// @return owner struct with ownerAddress and email.
    function getProjectOwner(uint projectId) public view validProject(projectId) returns (Owner memory){
        return projects[projectId].owner;
    }
}