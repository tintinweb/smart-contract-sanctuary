/**
 *Submitted for verification at polygonscan.com on 2021-08-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

contract Innovatract{

    /*
    * Enums
    */
    // changing GoalAceived to GoalStatus ; Change Inprogress to Active //
    enum GoalStatus { ACTIVE, ACHIEVED, UNACHIEVED }
    
    /* 
    * Storage
    */

    Contract[] public contracts;

    // mapping(uint => User[]) public users; // going to map to fulfillment
    mapping(uint=>Fulfillment[]) fulfillments;

    /*
    * Structs
    */
    
    address owner = 0xBd621d439c76a242A8D0038C45aF81DAD6818f98;

    // Changing User to Contract //
    struct  Contract {
        address owner;
        //address originator;
        uint endDate;
        string data;
        GoalStatus status;
        uint stakeAmount;
        
        //string goalName;
        //uint goalDuration;
        //string goalDescription;
        //uint checkInterval;
        //uint startDate;
        //mapping (address => uint) AmountStake;
        
        //stake Amount should be constant
    }
    
    struct Fulfillment {
        bool achieved;
        address payable fulfiller;
        string data;
    }
     
    //  address public escrowWallet;
    //  mapping (address => Contract) public contracts;
    
    /*
     * @dev Constructor
    */

    constructor() {}
     
     // uint public UserId; // scheduled to delete
     // Removed public in issueContract function (above external) //
    function issueContract(
        string calldata _data,
        uint64 _endDate

        // address contract,
        // uint _stakeAmount, 
        // string memory _goalName
        //string memory _goalDescription, 
        //uint _goalDuration,
        //uint _startDate, 
        //uint _checkInterval,
        
    )  
        external
        payable
        hasValue()
        validateEndDate(_endDate)
        returns (uint)
    {
        // User storage user = users[UserId];
        // user.stakeAmount = _stakeAmount;
        // user.goalDuration = _goalDuration;
        // user.goalDescription = _goalDescription;
        // user.goalName = _goalName;
        // user.checkInterval = _checkInterval;
        // user.startDate = _startDate;
        // user.endDate = _endDate;
        // UserId++;
        // user.AmountStake[msg.sender] = user.stakeAmount;
        
        contracts.push(Contract(payable(msg.sender), _endDate, _data, GoalStatus.ACTIVE, msg.value));
        emit ContractIssued(contracts.length - 1, msg.sender, msg.value, _data);
        return (contracts.length - 1);
    }

    /**
    * fulfilling a contract at endDate 
    */
    function fulfillContract(uint _contractId, string memory _data)
        public
        contractExists(_contractId)
        notOwner(_contractId)
        hasStatus(_contractId, GoalStatus.ACTIVE)
        isAfterEndDate(_contractId)
    {
        fulfillments[_contractId].push(Fulfillment(false, payable(msg.sender), _data));
        emit ContractFulfilled(_contractId, msg.sender, (fulfillments[_contractId].length - 1),_data);
    }

    /**
    * instructs contract to accept the fulfillment - send funds to fulfiller
    */
    function acceptFulfillment(uint _contractId, uint _fulfillmentId)
        public
        contractExists(_contractId)
        fulfillmentExists(_contractId, _fulfillmentId)
        onlyOwner(_contractId)
        hasStatus(_contractId, GoalStatus.ACTIVE)
        fulfillmentNotYetAchieved(_contractId, _fulfillmentId)
    {
        fulfillments[_contractId][_fulfillmentId].achieved = true;
        contracts[_contractId].status = GoalStatus.ACHIEVED;
        fulfillments[_contractId][_fulfillmentId].fulfiller.transfer(contracts[_contractId].stakeAmount);
        emit FulfillmentAchieved(_contractId, contracts[_contractId].owner, fulfillments[_contractId][_fulfillmentId].fulfiller, _fulfillmentId, contracts[_contractId].stakeAmount);
    }

    /**
    * When a goal is unachieved, the money is never transfered. 
    * To transfer funds, remove active emit and uncomment pair. 
    * Update Event at bottom 
    */
    function unachievedContract(uint _contractId)
        public
        contractExists(_contractId)
        onlyOwner(_contractId)
        hasStatus(_contractId, GoalStatus.ACTIVE)
    {
        contracts[_contractId].status = GoalStatus.UNACHIEVED;
        //contracts[_contractId].owner.transfer(contracts[_contractId].stakeAmount);
        //emit ContractUnachieved(_contractId, msg.sender, contracts[_contractId].stakeAmount);
        emit ContractUnachieved(_contractId);
    }

    /**
    * Modifiers 
    */

    modifier hasValue() {
        require(msg.value > 0);
        _;
    }

    modifier contractExists(uint _contractId) {
        require(_contractId < contracts.length);
        _;
    }

    modifier fulfillmentExists(uint _contractId, uint _fulfillmentId) {
        require(_fulfillmentId < fulfillments[_contractId].length);
        _;
    }

    modifier hasStatus(uint _contractId, GoalStatus _desiredStatus) {
        require(contracts[_contractId].status == _desiredStatus);
        _;
    }

    modifier onlyOwner(uint _contractId) {
        require(msg.sender == contracts[_contractId].owner);
        _;
    }

    modifier notOwner(uint _contractId) {
        require(msg.sender != contracts[_contractId].owner);
        _;
    }

    modifier fulfillmentNotYetAchieved(uint _contractId, uint _fulfillmentId) {
        require(fulfillments[_contractId][_fulfillmentId].achieved == false);
        _;
    }

    modifier validateEndDate(uint _newEndDate) {
        require(_newEndDate > block.timestamp);
        _;
    }

    modifier isAfterEndDate(uint _contractId) {
        require(block.timestamp < contracts[_contractId].endDate);
        _;
    }

    // function deposit() external payable {
    // }
    
    // function balance() external view returns(uint){
    //     return address(this).balance;
    // }
    
    // function sendEther(address payable owner, uint stakeAmount) external {
    
    //     //convert stakeAmount to ether from wei
    //     owner.transfer(stakeAmount * 1e18);
    // }

    /* Events */

    event ContractIssued(uint contract_id, address owner, uint amount, string data);
    event ContractFulfilled(uint contract_id, address fulfiller, uint fulfillment_id, string data);
    event FulfillmentAchieved(uint contract_id, address owner, address fulfiller, uint indexed fulfillment_id, uint stakeAmount);
    event ContractUnachieved(uint indexed contract_id);
    // event ContractUnachieved(uint indexed contract_id, address indexed owner, uint stakeAmount); // If uncommented, comment other event. will send funds //
}