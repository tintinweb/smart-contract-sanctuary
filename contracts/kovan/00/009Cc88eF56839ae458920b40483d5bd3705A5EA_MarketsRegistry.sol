pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;


/**
* @title MarketsRegistry
* @dev Implements market proposal and approval/denial
 */
contract MarketsRegistry {

    /// @notice Admins
    mapping(address=>uint) public admins;

    modifier onlyAdmin() {
        require(admins[msg.sender] == 1, "Not admin");
        _;
    }

    function addAdmin(address newAdmin) onlyAdmin public {
        admins[newAdmin] = 1;
        emit AddNewAdministrator(msg.sender, newAdmin);
    }

    function removeAdmin(address admin) onlyAdmin public {
        admins[admin] = 0;
        emit RemoveAdminstrator(msg.sender, admin);
    }

    function isAdmin(address account) view external returns (bool) {
        return admins[account] == 1;
    }
    
    struct MarketProposal {
        uint marketProposalId;
        string title;
        string description;
        uint resolutionTimestampUnix;
        bool approved;
    }

    /// @notice Total number of proposals ever
    uint public marketProposalCount;

    /// @notice 
    uint public totalPendingProposals;

    /// @notice
    uint public totalApprovedProposals;

    /// @notice all available market proposals
    mapping(uint => MarketProposal) public proposals;

    // Events
    
    /// @notice An event emitted when a new admin is added
    event AddNewAdministrator(address admin, address newAdmin);

    /// @notice An event emitted when an admin is removed
    event RemoveAdminstrator(address admin, address removedAdmin);

    /// @notice An event emitted when a Proposal is submitted 
    event ProposalSubmitted(address proposer, uint marketProposalId, string title, string description, uint resolutionTimestamp);
    
    /// @notice An event emitted when a Proposal is approved
    event ProposalApproved(address admin, uint marketProposalId);
    
    /// @notice An event emitted when a Proposal is denied
    event ProposalDenied(address admin, uint marketProposalId);

    constructor(){
        admins[msg.sender] = 1;
    }

    /// @notice Get approved market proposals
    function getAllApprovedMarketProposals() external view returns (MarketProposal[] memory){
        MarketProposal[] memory marketProposals = new MarketProposal[](totalApprovedProposals);
        for(uint i = 0; i < marketProposalCount; i++){
            MarketProposal storage marketProposal = proposals[i];
            
            //check that the MarketProposal struct has been initialized and approved
            if(bytes(marketProposal.title).length > 0 && marketProposal.approved == true){
                marketProposals[i] = marketProposal;
            }
        }
        return marketProposals;
    }

    /// @notice Get pending market proposals
    function getPendingMarketProposals() external view returns (MarketProposal[] memory){
        MarketProposal[] memory marketProposals = new MarketProposal[](totalPendingProposals);
        for(uint i = 0; i < marketProposalCount; i++){
            MarketProposal storage marketProposal = proposals[i];
            if(bytes(marketProposal.title).length > 0 && marketProposal.approved == false){
                marketProposals[i] = marketProposal;
            }
        }
        return marketProposals;
    }

    /// @notice submits a new market proposal to the registry
    function submitNewMarketProposal(string calldata title, string calldata description, uint resolutionTimestamp) external returns (uint) {
        uint proposalId = marketProposalCount;
        proposals[proposalId] = MarketProposal({
            marketProposalId: proposalId, 
            title: title, 
            description: description, 
            resolutionTimestampUnix: resolutionTimestamp, 
            approved: false
        });

        marketProposalCount++;
        totalPendingProposals++;
        emit ProposalSubmitted(msg.sender, proposalId, title, description, resolutionTimestamp);
        return proposalId;
    }

    function approveMarketProposal(uint marketProposalId) onlyAdmin external {
        MarketProposal storage marketProposal = proposals[marketProposalId];
        //require that the marketProposal struct was initialized
        require(isMarketProposalInitialized(marketProposal), "MarketProposal doesn't exist");    
        //necessary so we dont approve a proposal twice 
        require(!marketProposal.approved, "MarketProposal already approved");
        
        marketProposal.approved = true;
        totalApprovedProposals++;
        totalPendingProposals--;
        emit ProposalApproved(msg.sender, marketProposalId);
    }

    function denyMarketProposal(uint marketProposalId) onlyAdmin external {
        MarketProposal storage marketProposal = proposals[marketProposalId];
        //require that the marketProposal struct was initialized
        require(isMarketProposalInitialized(marketProposal), "MarketProposal doesn't exist");

        if(marketProposal.approved == true){
            //If the market proposal has already been approved, decrement totalApprovedProposals 
            totalApprovedProposals--;
        } 
        if(marketProposal.approved == false){
            //If the market proposal is pending, decrement totalPendingProposals
            totalPendingProposals--;
        }
        delete proposals[marketProposalId];
        emit ProposalDenied(msg.sender, marketProposalId);
    }

    function isMarketProposalInitialized(MarketProposal memory marketProposal) internal pure returns (bool) {
        return bytes(marketProposal.title).length > 0;
    }

}

{
  "optimizer": {
    "enabled": false,
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
  },
  "libraries": {}
}