/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;


/// @notice Contract to deploy campaign contracts
contract CampaignFactory {

//---- events

    /// @notice is emittted when new campaign is registered
    event EvntNewCampaign(
        uint indexed _campaignID,
        address indexed _campaignAddress,
        address indexed _campaignManager,
        uint _minimalStake
    );

//---- errors


//----- variables
    mapping (uint => address) deployedCampaigns;
    uint public campaignsCounter;

//----- functions
    /// @notice this function takes minimumContribution as input and deploys a new Campaign constract
    /// @param minimalStake is the desired minimum stake
    function createCampaign(uint minimalStake)
        public  
    {
        deployedCampaigns[campaignsCounter] = address(
            new Campaign({
                minimum: minimalStake, 
                creator: msg.sender
            })
        );

        emit EvntNewCampaign({
            _campaignID: campaignsCounter,
            _campaignAddress: deployedCampaigns[campaignsCounter] ,
            _campaignManager: msg.sender,
            _minimalStake: minimalStake
        });

        campaignsCounter++;
    }

    /// @notice is a function to get contract address by ID
    /// @param _campaignID is an ID of campagn to get
    function getCampaign(uint _campaignID)
        public 
        view
        returns (address campaignAddress) 
    {
            return(deployedCampaigns[_campaignID]); 
    }

// End Of Contract
}




/// @notice Contract accepts minimum stake during deploy ans address of the owner
contract Campaign {
//----types definition
    struct Request {
        bool exists;
        string description;
        uint value;
        address payable recipient;
        bool complete;
        uint approvalCount;
        mapping (address => bool) voters;
    }

//-----Variables
    address public manager; 
    uint public minimumContribution;
    uint public requestsCount;
    uint public stakeholdersCount;
    uint public raisedFunds;
    mapping (address => bool) public stakeholders;
    mapping (address => uint) public balances;
    mapping (uint => Request) public requests;

//-----Errors
/**
    Contribution stake is too low. 
    You have sent  `value` but minimum is `minimum`
    @param minimum is the minimum we accept
    @param value amount you have sent
**/
    error ErrContributionTooSmall(uint minimum, uint value);

    /// Only contract manager `manager` may call this.
    /// @param manager is the manager of this contract
    /// @param from made this transaction
    error ErrNotManager(address from, address manager);

    /// Only stakers may call this.
    error ErrNotStakeholder();

    /// Request with ID `requestID` does not exist.
    /// @param requestID is the ID of the request
    error ErrNonexistingRequest(uint requestID);

    /// Request was already provessed. No voting or processing is allowed.
    /// @param requestID is the ID of the request
    error ErrProcessedRequest(uint requestID);

    /// You have already voted on `requestID`.
    /// @param requestID is the ID of the request
    error ErrAlreadyVoted(uint requestID);

    /// Request doesn't have enoug Yays for request to pass.
    /// There are `votes` Yays which is less then required `threshold`   
    /// @param votes is the number of actual YES
    /// @param threshold is the passing margin 
    error ErrNotEnoughVotes(uint votes, uint threshold);

    /// Request cannot be processed as there is not enough balance to make transfer
    /// @dev gas is of course is not taken into the account. TODO: do something
    /// @param value is requested amount
    /// @param balance is the current balance  
    error ErrNotEnoughFunds(uint value, uint balance);


//-----Events

    /// @notice is emitted on new deposits
    /// @param _stakeholder is a stakeholder
    /// @param _value is the amount `stakeholder` addted to the treasury
    event EvntNewStake(
        address indexed _stakeholder,
        uint _value,
        uint _total
    );

    /// @notice is emitted on apearance of a new request 
    /// @param _requestID is the ID of the request
    /// @param _description is a description of the request
    /// @param _recipient is the address to which funds will be released
    /// @param _value is the requested amount
    event EvntNewRequest(
        uint indexed _requestID,
        string _description,
        address indexed _recipient,
        uint _value
    );

    /// @notice is emitted on new vote on request
    /// @param _requestID is the ID of the request
    /// @param _stakeholder is the stakeholder who voted yes
    event EvntNewVote(
        uint indexed _requestID,
        address indexed _stakeholder
    );

    /// @notice is emitted upon request processing and funds release
    /// @param _requestID is the ID of the request that was EvntRequestProcessed
    /// @param _recipient is the address to which funds were released
    /// @param _value is the amount that was released
    event EvntRequestProcessed(
        uint indexed _requestID,
        address indexed _recipient,
        uint _value
    );


//-------- modifiers
    /// @notice helper function for restricted modifier to use code size trick
    function _restrictedF() private view {
        if (msg.sender != manager){
            revert ErrNotManager({
                from: msg.sender,
                manager: manager
            });
        }
    }
    /// @notice restricted only to contract owner
    modifier restricted(){
        _restrictedF();
        _;
    }

    /// @notice helper function for stakeholder modifier to use code size trick
    function _stakeholderF() private view {
        if (stakeholders[msg.sender] != true){
            revert ErrNotStakeholder();
        }
    }

    /// @notice restricted to contributors only
    modifier stakeholder(){
        _stakeholderF();
        _;
    }

//-------- functions

    /// @notice Contract accepts minimum stake during deploy
    /// @param minimum is the minimal amount supporters need to stake
    /// @param creator is the address to which the ownership will belong
    constructor(uint minimum, address creator){
        manager = creator;
        minimumContribution = minimum;
    } 

    /// @notice call for supporters to enter. Minimum amount should be present in Tx. 
    function contribute() 
        payable 
        public 
    {
        // check if minimum requrements are met
        if (msg.value < minimumContribution){
            revert ErrContributionTooSmall({
                minimum: minimumContribution, 
                value: msg.value
            });
        }

        // increase the number of stakers but do not increase on reentry
        if(stakeholders[msg.sender] != true){
            stakeholdersCount++;
        }

        stakeholders[msg.sender] = true; 
        balances[msg.sender] += msg.value;

        // notify
        emit EvntNewStake({
            _stakeholder: msg.sender,
            _value: msg.value,
            _total: balances[msg.sender]
        });

    }

    /// @notice function to create a request. Only manager can use it.
    /// @param description Is a text description associated with the request.
    /// @param value Is a requested amount `value` to be sent to `recipient`
    /// @param recipient Is an address `recipient` to whre funds will be released
    function createRequest(string memory description, uint value, address payable recipient) 
        public 
        restricted 
    {
        Request storage newRequest = requests[requestsCount];
        newRequest.exists = true; 
        newRequest.description = description;
        newRequest.value = value;
        newRequest.recipient = recipient;
        newRequest.complete = false;
        newRequest.approvalCount = 0;

        // notify
        emit EvntNewRequest({
            _requestID: requestsCount,
            _description: newRequest.description,
            _recipient: newRequest.recipient,
            _value: newRequest.value
        });
        
        // 
        requestsCount++;
    }

    /// @notice a function to approve a request. Should be used by only stakers.
    /// @param requestID is the Identifier of a request to vote
    function approveRequest(uint requestID)
        public 
        stakeholder 
    {
        Request storage request = requests[requestID]; 
        
        // check if request exists
        if(request.exists != true){
            revert ErrNonexistingRequest(requestID);
        }

        // check if voting finished
        if(request.complete != false){
            revert ErrProcessedRequest(requestID);
        }
        
        // check if already voted
        if(request.voters[msg.sender] != false){
            revert ErrAlreadyVoted(requestID);
        }
        
        // make actual vote
        request.approvalCount++;
        request.voters[msg.sender] = true;

        // notify
        emit EvntNewVote({
            _requestID: requestID,
            _stakeholder: msg.sender
        });
    }

    /// @notice a funvtion to calculate threshold to pass the vote on request
    /// @dev this will evolve evetually
    /// @param threshold is the expected threshold value
    function votingThreshold() 
        view 
        public 
        returns(uint threshold)
    {
        threshold = stakeholdersCount >>1; //half of stakers
        return(threshold) ;
    } 

    /// @notice a function to process the request
    /// @param requestID is the ID of a request
    function processRequest(uint requestID)
        public 
        restricted 
    {
        Request storage request = requests[requestID];

        // check if request exists
        if(request.exists != true){
            revert ErrNonexistingRequest(requestID);
        }
        
        // check if hasn't processed already
        if(request.complete != false){
            revert ErrProcessedRequest(requestID);
        }

        // check if voting passed with enough votes
        uint threshold = votingThreshold();  
        if(request.approvalCount < threshold){
            revert ErrNotEnoughVotes(request.approvalCount, threshold);
        }

        // check if treasury has enough funds
        if(request.value > address(this).balance){
            revert ErrNotEnoughFunds(request.value, address(this).balance);
        }

        // process the request and release funds
        request.recipient.transfer(request.value);
        request.complete = true;

        // notify
        emit EvntRequestProcessed({
            _requestID: requestID,
            _recipient: request.recipient,
            _value: request.value
        });
    } 

    /// @notice Balance of the treasury
    function balance() 
        view 
        public 
        returns(uint)
    {
        return(address(this).balance) ;
    } 



}