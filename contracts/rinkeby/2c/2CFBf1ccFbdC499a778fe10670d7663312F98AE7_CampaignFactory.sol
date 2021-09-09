pragma solidity ^0.4.17;


//Factory contract


contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(string _title, string _description, string _link, uint256 minimum) public payable{
        address newCampaign = new Campaign(_title, _description,  _link, minimum, msg.sender);
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (address[]) {
        return deployedCampaigns;
    }
}

//End of the factory contract

//Main contract

contract Campaign {

    //Variables
    address public manager;
    uint public minimumContribution;
    uint public approversCount;
    mapping(address => bool) public approvers;

    //Added variables
    string public title;
    string public campaignDescription;
    string public link;


    //Struct requests
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    Request[] public requests;


    //Modifier only owner
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }


    //Create campaign function
    function Campaign(string _title, string _description, string _link, uint256 minimum, address creator) public payable {
       
       
       //Add fees when somebody create a campaign (pay it to the contract)
        require(msg.value == .05 ether);
        
        //1st variable declared outside = variable from inside
        title = _title;
        campaignDescription = _description;
        link = _link;
        manager = creator;
        minimumContribution = minimum;
    }


    //Contribute to the campaign
    function contribute() public payable {
        require(msg.value > minimumContribution);

        approvers[msg.sender] = true;
        approversCount++;
    }


    //Create request to use the money
    function createRequest(string description, uint value, address recipient) public restricted {
        Request memory newRequest = Request({
           description: description,
           value: value,
           recipient: recipient,
           complete: false,
           approvalCount: 0
        });

        requests.push(newRequest);
    }


    //Approve request by contributor
    function approveRequest(uint index) public {
        Request storage request = requests[index];

        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);

        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    //Finish the request and send the money
    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];

        require(request.approvalCount > (approversCount / 2));
        require(!request.complete);

        request.recipient.transfer(request.value);
        request.complete = true;
    }

    //Get the summary - details
    function getSummary() public view returns (
        uint, uint, uint, uint, address
    ) {
        return (
            minimumContribution,
            this.balance,
            requests.length,
            approversCount,
            manager
        );
    }

    //Return the number of requests
    function getRequestsCount () public view returns (uint){
        return requests.length;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}