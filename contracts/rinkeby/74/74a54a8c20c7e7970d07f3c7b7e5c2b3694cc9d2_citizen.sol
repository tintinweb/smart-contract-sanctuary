/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.7.0;

contract citizen
{
    
    string name = 'Citizen';
    address public state_gov;// The address of the state government
    uint internal organizationsLength = 0;

    // Definition of a proposal
    struct Proposal
    {
        uint organizationId;         // Id of organization submitting the proposal
        uint contId;                 // Id of the proposal
        uint costEstimate;           // Estimated cost of this proposal
        string proposalDescription;  // A description of the proposal
        string proposalTitle;        // Title of the proposal
        bool is_awarded;

        /*uint duration; // in months
          uint epoch; // in seconds
        */

    }

    // Definition of a task
    struct Task
    {
       uint taskId;     //Id of the task
       string taskTitle;    //Title of the task
       /*
       string taskDescription;      // a description of the task
       */

       uint propId; // proposal chosen for this taskDescription
       uint numVotes;
       uint status;// (0-100) level of completion
       bool is_completed ;

       /*
       uint propSubmisssionDeadline;
       uint executionDeadline;
       */
       uint[] taskProposalsId;// proposalId's of proposals received for the given task

    }


    struct Organization
    {
        address payable organizationAddress;// hash key for org
        uint organizationId;
        string organizationTitle;
        // uint[] organizationProposalsId; // proposalId's of proposals submitted by this organization
    }

    //Definition of county
    struct County
    {
        address countyAddress; // hash key for county
        string countyTitle;    // title of county
        uint countyId;        // Id of county
        uint[] countyTasksId; // List of Ids of tasks involved with county
    }

    //Definition of Contract
    struct Contract {
        uint countyId;    // Id of county involved with Contract
        uint taskId;    // Id of task for which contract is registred
        bool isIssued;
        uint votes;
        uint[] ProposalIds;
        mapping (address => bool) voted;
    }

    // Definition of Vote
    struct Vote
    {
        uint contId;    // contract for which votes are being cast
        uint vote_points; // vote points voted
    }

    //Definition of citizen
    struct Citizen
    {
        address citizenAddress; // Address if the citizen
        string citizenName;
        uint citizenId;
        // indices of votes which this citizen has cast votes for
    }

    // Definition of Authority
    struct Authority
    {
        address authorityAddress;
        string authorityName;
        uint authorityId;
        uint authWeight;
        uint[] authVote;
    }

    //Definition of payment
    struct Payment
    {
        address to; //Address of receiver
        uint cost;  // Amount Payed
    }

    County[] public countys; //List of Countys registered with state
    Task[] public tasks;    //List of Tasks registered with state
    // Organization[] public organizations;    //List of Organizations registered with state
    Proposal[] public proposals;    //List of Proposals registered by the Organizations
    Citizen[] public citizens;      // List of Citizens enrolled with state
    Authority[] public auths;       //List of Authorities enrolled with state
    Vote[] public votes;            //List of votes cast about task completion
    Contract[] public contracts;    //List of contracts registered
    Payment[] public payments;      //List of payments tansacted
    mapping(address => uint) tag;   //A Dictionary of address mapped to respective category of user
                                    // i.e , state_gov - 1, county -2, organization -3, citizen -4
    mapping(uint => uint) winners;  // List consisting of organizations which have been awarded contracts
    //mapping(address => bool) voted;

    // Dictionary from id's to array indices
    mapping(uint => uint) countyMap;// countydId  to index in county
    mapping(uint => Organization) internal organizations; // orgI to index in organizations
    mapping(uint => uint) taskMap;// taskId to index in tasks
    mapping(uint => uint) propMap;// propId to index in proposals
    mapping(string => uint) citiMap;// citiId to index in citizens


    //mapping(uint => bool) // mapping from contract Id to bool


    constructor() public
    {
        // state_gov = msg.sender;
        tag[msg.sender] = 1;
    }

    function registerTask(uint task_id, string memory task_title) public
    {
        require(msg.sender == state_gov);
        uint[] memory empArr;
        tasks.push(Task({taskId:task_id, taskTitle:task_title, numVotes:0, propId:0, status:0, is_completed: false, taskProposalsId:empArr}));
        taskMap[task_id] = tasks.length-1;
    }

    // Registering a County
    function registerCounty(address county_address, uint county_Id, string memory county_Title) public
    {

        require(msg.sender == state_gov);
        uint[] memory empArr;
        countys.push(County({ countyAddress:county_address, countyId: county_Id, countyTitle:county_Title, countyTasksId:empArr}));
        countyMap[county_Id] = countys.length - 1;
        tag[county_address] = 2;
    }
    // Passing a contract from state government to a particular county
    function passContract(uint task_id, uint county_id) public
    {
        uint[] memory emp;
        contracts.push(Contract({countyId: county_id, taskId: task_id, isIssued: false, votes: 0, ProposalIds: emp}));
        countys[countyMap[county_id]].countyTasksId.push(contracts.length-1);
    }

    // Registering organizations with the state governments
    function registerOrganization(address payable org_address, uint org_Id, string memory org_title) public
    {
        organizations[organizationsLength] = Organization( org_address, org_Id, org_title);
        organizationsLength++;
        // require(msg.sender == state_gov);
        // uint[] memory empArr;
        // organizations.push(Organization({organizationAddress:org_address, organizationId:org_Id, organizationTitle: org_title, organizationProposalsId:empArr}));

        // orgMap[org_Id] = organizations.length-1;
        // tag[org_address] = 3;
    }

    //Issue a particular contract
    function issueContract(uint cont_id) public
    {
        require(tag[msg.sender] == 2);
        contracts[cont_id].isIssued = true;
    }

    //Registering new proposals
    function registerProposal(uint org_Id, uint cont_Id, string memory prop_Desc, string memory prop_Title, uint cost) public
    {
        require(tag[msg.sender] == 3 && contracts[cont_Id].isIssued);

        proposals.push(Proposal({organizationId:org_Id, contId:cont_Id, is_awarded:false, proposalDescription:prop_Desc, proposalTitle:prop_Title, costEstimate: cost}));
        contracts[cont_Id].ProposalIds.push(proposals.length-1);

        // the current proposal has to be added to the respective organization
        // organizations[orgMap[org_Id]].organizationProposalsId.push(proposals.length-1);

    }

    //Choosing the winning Proposal
    function winningProposal(uint cont_Id, uint prop_Id) public
    {
        require(msg.sender==state_gov);
        bool found = false;
        for (uint i = 0; i < contracts[cont_Id].ProposalIds.length; i++)
            if (contracts[cont_Id].ProposalIds[i] == prop_Id)
                found = true;
        require(found);
        proposals[prop_Id].is_awarded = true;
        winners[cont_Id] = prop_Id;
    }

    //Registering new Citizens
    function registerCitizen(address cit_address, uint cit_Id, string memory cit_Name) public
    {
        require(msg.sender == state_gov);
        citizens.push(Citizen({citizenAddress:cit_address, citizenName: cit_Name, citizenId: cit_Id}));
        citiMap[cit_Name] = citizens.length-1;
        tag[cit_address] = 4;
    }

    // Accepting Votes for a particular task
    function taskingVote(uint cont_Id,bool vote) public
    {
        // ensuring that the vote is cast by either a citizen or government and the contract is issued
        require((tag[msg.sender] == 2 || tag[msg.sender] == 4 ) && contracts[cont_Id].isIssued && !contracts[cont_Id].voted[msg.sender]);

        /*
        TODO :
            1. Take care of case when votes are being cast for task that is not awarded yet
            2. Take care of citizen voting on the same task multiple times
        //*/
        uint weight = 1;
        if (tag[msg.sender] == 2)
            weight = 5;

        votes.push(Vote({ contId:cont_Id, vote_points:weight}));

        contracts[cont_Id].voted[msg.sender] = true;

        if (vote == true)
            contracts[cont_Id].votes += weight;
        else
            contracts[cont_Id].votes -= weight;

    }

    // Function to verify completion of the contract
    function verifyCompletion(uint cont_id) view public returns (bool)
    {
        require(msg.sender==state_gov);
        if (contracts[cont_id].votes > 0)
            return true;
        else
            return false;
    }

    //Function to pay the organization post completion of contract
    function payment (uint cont_id) public
    {
        // payment can be done only by the state_gov

        require(verifyCompletion(cont_id));
        payments.push(Payment(organizations[proposals[winners[cont_id]].organizationId].organizationAddress, proposals[winners[cont_id]].costEstimate));
    }



}