pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title MarketsRegistry
 * @dev Implements market proposal and approval/denial
 */
contract MarketsRegistry {
  /// @notice Admins
  mapping(address => uint256) public admins;

  uint256 constant PENDING = 0;
  uint256 constant APPROVED = 1;
  uint256 constant DENIED = 2;

  modifier onlyAdmin() {
    require(admins[msg.sender] == 1, 'Not admin');
    _;
  }

  function addAdmin(address newAdmin) public onlyAdmin {
    admins[newAdmin] = 1;
    emit AddNewAdministrator(msg.sender, newAdmin);
  }

  function removeAdmin(address admin) public onlyAdmin {
    admins[admin] = 0;
    emit RemoveAdminstrator(msg.sender, admin);
  }

  function isAdmin(address account) external view returns (bool) {
    return admins[account] == 1;
  }

  struct MarketProposal {
    uint256 marketProposalId;
    string title;
    string description;
    uint256 resolutionTimestampUnix;
    uint256 status;
  }

  /// @notice Total number of proposals ever
  uint256 public marketProposalCount;

  /// @notice
  uint256 public totalPendingProposals;

  /// @notice
  uint256 public totalApprovedProposals;

  /// @notice all available market proposals
  mapping(uint256 => MarketProposal) public proposals;

  // Events

  /// @notice An event emitted when a new admin is added
  event AddNewAdministrator(address admin, address newAdmin);

  /// @notice An event emitted when an admin is removed
  event RemoveAdminstrator(address admin, address removedAdmin);

  /// @notice An event emitted when a Proposal is submitted
  event ProposalSubmitted(
    address proposer,
    uint256 marketProposalId,
    string title,
    string description,
    uint256 resolutionTimestamp
  );

  /// @notice An event emitted when a Proposal is approved
  event ProposalApproved(address admin, uint256 marketProposalId);

  /// @notice An event emitted when a Proposal is denied
  event ProposalDenied(address admin, uint256 marketProposalId);

  constructor() {
    admins[msg.sender] = 1;
  }

  /// @notice Get approved market proposals
  function getAllApprovedMarketProposals() external view returns (MarketProposal[] memory) {
    MarketProposal[] memory marketProposals = new MarketProposal[](totalApprovedProposals);
    uint256 index;
    for (uint256 i = 0; i < marketProposalCount; i++) {
      MarketProposal storage marketProposal = proposals[i];

      //check that the MarketProposal struct has been initialized and approved
      if (marketProposal.status == APPROVED) {
        marketProposals[index] = marketProposal;
        index++;
      }
    }
    return marketProposals;
  }

  /// @notice Get pending market proposals
  function getPendingMarketProposals() external view returns (MarketProposal[] memory) {
    MarketProposal[] memory marketProposals = new MarketProposal[](totalPendingProposals);
    uint256 index;
    for (uint256 i = 0; i < marketProposalCount; i++) {
      MarketProposal storage marketProposal = proposals[i];
      if (marketProposal.status == PENDING) {
        marketProposals[index] = marketProposal;
        index++;
      }
    }
    return marketProposals;
  }

  /// @notice submits a new market proposal to the registry
  function submitNewMarketProposal(
    string calldata title,
    string calldata description,
    uint256 resolutionTimestamp
  ) external returns (uint256) {
    require(bytes(title).length > 0, 'Title is required');
    require(bytes(description).length > 0, 'Description is required');
    require(
      resolutionTimestamp > block.timestamp,
      'ResolutionTimestamp can not be in the past time'
    );

    uint256 proposalId = marketProposalCount;
    proposals[proposalId] = MarketProposal({
      marketProposalId: proposalId,
      title: title,
      description: description,
      resolutionTimestampUnix: resolutionTimestamp,
      status: PENDING
    });

    marketProposalCount++;
    totalPendingProposals++;
    emit ProposalSubmitted(msg.sender, proposalId, title, description, resolutionTimestamp);
    return proposalId;
  }

  function approveMarketProposal(uint256 marketProposalId) external onlyAdmin {
    MarketProposal storage marketProposal = proposals[marketProposalId];
    //require that the marketProposal struct was initialized
    require(isMarketProposalInitialized(marketProposal), "MarketProposal doesn't exist");
    //necessary so we dont approve a proposal twice
    require(marketProposal.status != APPROVED, 'MarketProposal already approved');

    marketProposal.status = APPROVED;
    totalApprovedProposals++;
    totalPendingProposals--;
    emit ProposalApproved(msg.sender, marketProposalId);
  }

  function denyMarketProposal(uint256 marketProposalId) external onlyAdmin {
    MarketProposal storage marketProposal = proposals[marketProposalId];
    //require that the marketProposal struct was initialized
    require(isMarketProposalInitialized(marketProposal), "MarketProposal doesn't exist");

    if (marketProposal.status == APPROVED) {
      //If the market proposal has already been approved, decrement totalApprovedProposals
      totalApprovedProposals--;
      marketProposal.status = DENIED;
    }

    if (marketProposal.status == PENDING) {
      totalPendingProposals--;
      delete proposals[marketProposalId];
    }
    emit ProposalDenied(msg.sender, marketProposalId);
  }

  function isMarketProposalInitialized(MarketProposal memory marketProposal)
    internal
    pure
    returns (bool)
  {
    return bytes(marketProposal.title).length > 0;
  }
}