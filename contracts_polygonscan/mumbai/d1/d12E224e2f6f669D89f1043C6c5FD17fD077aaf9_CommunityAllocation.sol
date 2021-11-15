// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IPRIVIDAO.sol";
import "./interfaces/IManageCommunityToken.sol";

import "./constant.sol";

contract CommunityAllocation {
    mapping(uint => AllocationProposal) _allocationProposals;
    mapping(uint => CommunityAllocationStreamingRequest) _communityASRs;

    uint[] _allocationProposalIds;
    uint[] _communityASRIds;

    uint _allocationProposalCount;
    uint _communityASRCount;

    address _daoContractAddress;
    address _manageCommunityTokenContractAddress;

    constructor(address daoContractAddress, address manageCommunityTokenContractAddress) {
        _daoContractAddress = daoContractAddress;
        _manageCommunityTokenContractAddress = manageCommunityTokenContractAddress;
    }

    function getAllocationProposalCount() public view returns(uint) {
        return _allocationProposalCount;
    }

    function getAllocationProposalIds(uint index) public view returns(uint) {
        return _allocationProposalIds[index];
    }

    function getAllocationProposal(uint proposalId) public view returns(AllocationProposal memory) {
        require(
            _allocationProposals[proposalId].proposalId == proposalId, 
            "proposalId is not valid"
        );

        return _allocationProposals[proposalId];
    }

    function getAllocationSum(AllocationProposal memory allocationProposal) public pure returns(address[] memory, uint) {
        uint allocationSum;
        address[] memory allocationAddresses = new address[](allocationProposal.allocateCount);

        for(uint i = 0; i < allocationProposal.allocateCount; i++) {
            allocationSum += allocationProposal.allocateAmounts[i];
            allocationAddresses[i] = allocationProposal.allocateAddresses[i];
        }

        return (allocationAddresses, allocationSum);
    }

    function checkPrerequisitesToAllocation(AllocationProposal memory allocation, address requester) internal view {
        Community memory community;
        bool result;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(allocation.communityId);
        require(community.communityAddress != address(0), "community not registered");

        uint founderIndex;
        (founderIndex, result) = IPRIVIDAO(_daoContractAddress).getIdOfFounders(community, requester);
        require(result, "requester has to be the founder");

        CommunityToken memory communityToken;
        communityToken = IManageCommunityToken(_manageCommunityTokenContractAddress).getCommunityToken(community.tokenId);

        uint amountToAllocate;

        for(uint i = 0; i < allocation.allocateCount; i++) {
            amountToAllocate += allocation.allocateAmounts[i];
        }

        require(
            (communityToken.initialSupply - communityToken.airdropAmount - communityToken.allocationAmount) >= amountToAllocate,
            "number of free tokens to allocate is not enough"
        );

        for(uint i = 0; i < allocation.allocateCount; i++) {
            require(allocation.allocateAddresses[i] != address(0), "allocation address is not vaild");
        }
    }

    function updateAllocationProposal(AllocationProposal memory allocationProposal) internal {
        bool flag = false;

        for(uint i = 0; i < _allocationProposalCount; i++) {
            if(_allocationProposalIds[i] == allocationProposal.proposalId) {
                flag = true;
                break;
            }
        }

        if(!flag) {
            _allocationProposalCount++;
            _allocationProposalIds.push(allocationProposal.proposalId);
        }

        for(uint j = 0; j < 20; j++) {
            _allocationProposals[allocationProposal.proposalId].approvals[j].IsVoted = allocationProposal.approvals[j].IsVoted;
            _allocationProposals[allocationProposal.proposalId].approvals[j].Vote = allocationProposal.approvals[j].Vote;
        }

        _allocationProposals[allocationProposal.proposalId].proposalId = allocationProposal.proposalId;
        _allocationProposals[allocationProposal.proposalId].communityId = allocationProposal.communityId;
        _allocationProposals[allocationProposal.proposalId].proposalCreator = allocationProposal.proposalCreator;
        _allocationProposals[allocationProposal.proposalId].allocateCount = allocationProposal.allocateCount;

        for(uint j = 0; j < _allocationProposals[allocationProposal.proposalId].allocateCount; j++) {
            _allocationProposals[allocationProposal.proposalId].allocateAddresses.push(allocationProposal.allocateAddresses[j]);
            _allocationProposals[allocationProposal.proposalId].allocateAmounts.push(allocationProposal.allocateAmounts[j]);
        }

        _allocationProposals[allocationProposal.proposalId].date = allocationProposal.date;
    }

    function updateCommunityTokenWithNewAllocationSum(uint tokenId, AllocationProposal memory allocationProposal, bool isAdded) public
     returns(CommunityToken memory){
        CommunityToken memory  communityToken;

        communityToken = IManageCommunityToken(_manageCommunityTokenContractAddress).getCommunityToken(tokenId);

        uint allocationSum;
        (, allocationSum) = getAllocationSum(allocationProposal);

        if(isAdded) {
            communityToken.allocationAmount += allocationSum;
        } else {
            communityToken.allocationAmount -= allocationSum;
        }

        IManageCommunityToken(_manageCommunityTokenContractAddress).updateCommunityToken(communityToken);

        return communityToken;
    }

    function deleteAllocationProposal(uint proposalId) internal {
        delete _allocationProposals[proposalId]; 
    }

    function cancelAllocationProposal(CancelProposalRequest calldata cancelProposalRequest) external {
        AllocationProposal memory proposal;
        Community memory community;
        bool result;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(cancelProposalRequest.communityId);

        proposal = getAllocationProposal(cancelProposalRequest.proposalId);

        uint creationDateDiff = (block.timestamp - proposal.date);

        require(
            (proposal.proposalCreator == msg.sender) || 
                (creationDateDiff >= community.foundersVotingTime),
            "just proposal creator can cancel proposal"
        );

        CommunityToken memory communityToken;
        communityToken  = updateCommunityTokenWithNewAllocationSum(community.tokenId, proposal, false);

        uint allocationSum;
        (, allocationSum) = getAllocationSum(proposal);

        address tokenContractAddress;

        (tokenContractAddress, result) = IManageCommunityToken(_manageCommunityTokenContractAddress)
            .getTokenContractAddress(communityToken.tokenSymbol);
        require(result, "token contract address is not valid");

        IERC20(tokenContractAddress).transferFrom(community.escrowAddress, community.communityAddress, allocationSum);

        deleteAllocationProposal(cancelProposalRequest.proposalId);
    }

    function performAllocation(Community memory community, AllocationProposal memory allocationProposal, bool withEscrowTransfer) internal {
        CommunityToken memory communityToken;
        bool result;

        communityToken = IManageCommunityToken(_manageCommunityTokenContractAddress).getCommunityToken(community.tokenId);

        uint currentDate = block.timestamp;
        uint allocationSum;

        address tokenContractAddress;
        (tokenContractAddress, result) = IManageCommunityToken(_manageCommunityTokenContractAddress)
            .getTokenContractAddress(communityToken.tokenSymbol);
        require(result, "token contract address is not valid");

        for(uint i = 0; i < allocationProposal.allocateCount; i++) {
            allocationSum += allocationProposal.allocateAmounts[i];
            uint transferAmount = (allocationProposal.allocateAmounts[i] * communityToken.immediateAllocationPct);
            IERC20(tokenContractAddress).transferFrom(community.escrowAddress, allocationProposal.allocateAddresses[i], transferAmount);

            //streaming
            _communityASRCount++;
            _communityASRs[_communityASRCount].communityId = community.communityAddress;
            _communityASRs[_communityASRCount].senderAddress = community.escrowAddress;
            _communityASRs[_communityASRCount].receiverAddress = allocationProposal.allocateAddresses[i];
            _communityASRs[_communityASRCount].tokenSymbol = communityToken.tokenSymbol;
            _communityASRs[_communityASRCount].frequency = 1;
            _communityASRs[_communityASRCount].amount = communityToken.vestedAllocationPct;
            _communityASRs[_communityASRCount].startingDate = currentDate;
            _communityASRs[_communityASRCount].endingDate = (currentDate + communityToken.vestingTime*30*24*60*60); 
        }

        if(withEscrowTransfer) {
            IERC20(tokenContractAddress).transferFrom(community.communityAddress, community.escrowAddress, allocationSum);
        }
    }

    function transferAllocationTokensToEscrow(AllocationProposal memory allocationProposal, Community memory community) internal {
        CommunityToken memory allocationToken;
        address tokenContractAddress;
        uint allocationAmount;
        bool result;

        for(uint i = 0; i < allocationProposal.allocateCount; i++) {
            allocationAmount += allocationProposal.allocateAmounts[i];
        }

        allocationToken = IManageCommunityToken(_manageCommunityTokenContractAddress).getCommunityToken(community.tokenId);

        (tokenContractAddress, result) = IManageCommunityToken(_manageCommunityTokenContractAddress)
            .getTokenContractAddress(allocationToken.tokenSymbol);
        require(result, "token contract address is not valid");

        IERC20(tokenContractAddress).transferFrom(community.communityAddress, community.escrowAddress, allocationAmount);
    }

    function AllocateTokenProposal(AllocationProposal calldata allocationProposalInput) external {
        require(
            allocationProposalInput.allocateCount > 0, 
            "at least one address is required to create allocate token proposal"
        );
        for(uint i = 0; i < allocationProposalInput.allocateCount; i++) {
            require(allocationProposalInput.allocateAmounts[i] > 0, "amount cannot be negative or zero");
        }

        checkPrerequisitesToAllocation(allocationProposalInput, msg.sender);

        Community memory community;
        bool result;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(allocationProposalInput.communityId);

        uint founderIndex;
        (founderIndex, result) = IPRIVIDAO(_daoContractAddress).getIdOfFounders(community, msg.sender);
        require(result, "allocation creator should be founder");

        AllocationProposal memory allocationProposal;

        for(uint i = 0; i < community.foundersCount; i++) {
            allocationProposal.approvals[i].IsVoted = false;
            allocationProposal.approvals[i].IsVoted = false;
        }

        allocationProposal.date = block.timestamp;

        if((community.foundersCount == 1) && (community.foundersShares[founderIndex] > 0)) {
            performAllocation(community, allocationProposal, true);
            updateCommunityTokenWithNewAllocationSum(community.tokenId, allocationProposalInput, true);
            return;
        }

        allocationProposal.proposalId = uint(keccak256(abi.encodePacked(block.difficulty, allocationProposal.date, _allocationProposalCount + 1)));
        allocationProposal.communityId = allocationProposalInput.communityId;
        allocationProposal.allocateAddresses = allocationProposalInput.allocateAddresses;
        allocationProposal.allocateAmounts = allocationProposalInput.allocateAmounts;
        allocationProposal.allocateCount = allocationProposalInput.allocateCount;
        allocationProposal.proposalCreator = msg.sender;

        updateAllocationProposal(allocationProposal);
        
        updateCommunityTokenWithNewAllocationSum(community.tokenId, allocationProposalInput, true);
        transferAllocationTokensToEscrow(allocationProposal, community);
    }

    function VoteAllocateTokenProposal(VoteProposal calldata voteAllocationInput) external {
        AllocationProposal memory allocationProposal;
        Community memory community;
        uint founderIndex;
        uint creationDateDiff;
        uint consensusScoreRequirement;
        uint consensusScore;
        uint negativeConsensusScore;
        bool result;

        allocationProposal = getAllocationProposal(voteAllocationInput.proposalId);

        community = IPRIVIDAO(_daoContractAddress).getCommunity(voteAllocationInput.communityId);

        (founderIndex, result) = IPRIVIDAO(_daoContractAddress).getIdOfFounders(community, msg.sender);
        require(result, "creator should be founder");
        require(!allocationProposal.approvals[founderIndex].IsVoted, "voter can not vote second time");

        creationDateDiff = (block.timestamp - allocationProposal.date);
        require(creationDateDiff <= community.foundersVotingTime, "voting time is over");

        allocationProposal.approvals[founderIndex].IsVoted = true;
        allocationProposal.approvals[founderIndex].Vote = voteAllocationInput.decision;

        consensusScoreRequirement = community.foundersConsensus;
        for(uint i = 0; i < community.foundersCount; i++) {
            if(allocationProposal.approvals[i].Vote) {
                consensusScore += community.foundersShares[i];
            }
            
            if((!allocationProposal.approvals[i].Vote) && (allocationProposal.approvals[i].IsVoted)) {
                negativeConsensusScore += community.foundersShares[i];
            }
        }

        if(consensusScore >= consensusScoreRequirement) {
            performAllocation(community, allocationProposal, false);
            deleteAllocationProposal(allocationProposal.proposalId);                                            
            return;
        }

        if(negativeConsensusScore > (10000 - consensusScoreRequirement)) { // *10^4
            deleteAllocationProposal(allocationProposal.proposalId);

            CommunityToken memory commmunityToken = updateCommunityTokenWithNewAllocationSum(community.tokenId, allocationProposal, false);
            uint allocationSum;
            (, allocationSum) = getAllocationSum(allocationProposal);

            address tokenContractAddress;
            (tokenContractAddress, result) = IManageCommunityToken(_manageCommunityTokenContractAddress)
                .getTokenContractAddress(commmunityToken.tokenSymbol);
            require(result, "token contract address is not valid");

            IERC20(tokenContractAddress).transferFrom(community.escrowAddress, community.communityAddress, allocationSum);
            return;
        }

        updateAllocationProposal(allocationProposal);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IERC20TokenExchange.sol";
import "./interfaces/IIncreasingPriceERC721Auction.sol";

struct Community {
    address[] founders;
    uint[] foundersShares;
    uint foundersCount;
    string entryType;
    string[] entryConditionSymbols;
    uint[] entryConditionValues;
    uint entryConditionCount;
    uint foundersVotingTime;
    uint foundersConsensus;
    uint treasuryVotingTime;
    uint treasuryConsensus;
    address escrowAddress;
    address stakingAddress;
    address communityAddress;
    uint date;
    uint tokenId;
}

struct Vote {
    bool IsVoted;
    bool Vote;
}

struct Member {
    address communityId;
    address memberAddress;
    string memberType;
    uint share;
}

struct Token {
    string name;
    string symbol;
    address contractAddress;
}

struct CommunityToken {
    uint tokenId;
    address communityId;
    string tokenName;
    string tokenSymbol;
    address tokenContractAddress;
    string fundingToken;
    address ammAddress;
    string tokenType;
    uint initialSupply;
    uint targetPrice;
    uint targetSupply;
    uint vestingTime;
    uint immediateAllocationPct;
    uint vestedAllocationPct;
    uint taxationPct;
    uint date;
    uint airdropAmount;
    uint allocationAmount;
}

struct Airdrop {
    address communityId;
    uint recipientCount;
    address[] recipients;
    uint[] amounts;
}

struct Proposal {
    uint proposalId;
    string proposalType;
    address communityId;
    address proposalCreator;
    Vote[20] approvals;
    uint date;
}

struct CommunityCreationProposal {
    uint proposalId;      
    address proposalCreator;          
    Vote[20] approvals; 
    Community proposal;       
    uint date;           
}

struct VoteProposal {
    uint proposalId;
    address communityId;
    bool decision;
}

struct CommunityTokenProposal {
    uint proposalId;
    address communityId;
    address proposalCreator;
    Vote[20] approvals;
    CommunityToken proposal;
    uint date;
}

struct AirdropProposal {
    uint proposalId;
    address communityId;
    address proposalCreator;
    Vote[20] approvals;
    Airdrop proposal;
    uint date;
}

struct AllocationProposal {
    uint proposalId;
    Vote[20] approvals;
    address communityId;
    address proposalCreator;
    uint allocateCount;
    address[] allocateAddresses;
    uint[] allocateAmounts;
    uint date;
}

struct ManageTreasurerProposal {
    uint proposalId;
    address communityId;
    address proposalCreator;
    Vote[20] approvals;
    address[] treasurerAddresses;
    uint treasurerCount;
    bool isAddingTreasurers;
    uint date;
}

struct CommunityAllocationStreamingRequest {
    address communityId;
    address senderAddress;
    address receiverAddress;
    string tokenSymbol;
    uint frequency;
    uint amount;
    uint startingDate;
    uint endingDate;
}

struct EjectMemberProposal {
    uint proposalId;
    address communityId;
    address proposalCreator;
    Vote[20] approvals;
    address memberAddress;
    uint date;
}

struct JoiningRequest {
    uint proposalId;
    address communityId;
    address joiningRequestAddress;
}

struct EjectMemberRequest {
    address communityId;
    address ejectMemberAddress;
}

struct  CancelMembershipRequest {
    address communityId;
    address memberAddress;
}

struct TransferProposalRequest {
    address communityId;
    string tokenSymbol;
    address to;
    uint amount;
}

struct TransferRequest{
    string transferType;
    address tokenContractAddress;
    address from;
    address to;
    uint amount;
}

struct TransferProposal {
    uint proposalId;
    address communityId;
    address proposalCreator;
    Vote[20] approvals;
    TransferRequest proposal;
    uint date;
}

struct PlaceBidRequest {
    address communityId;
    string mediaSymbol;
    string tokenSymbol;
    uint amount;
}

struct BuyingProposalRequest {
    address communityId;
    uint exchangeId;
    uint offerId;
    address offerTokenAddress;
    uint amount;
    uint price;
}

struct BuyingOrderProposal {
    uint proposalId;
    address communityId;
    address proposalCreator;
    Vote[20] approvals;
    IERC20TokenExchange.PlaceERC20TokenOfferRequest proposal;
    uint date;
}

struct BuyingProposal {
    uint proposalId;
    address communityId;
    address proposalCreator;
    Vote[20] approvals;
    IERC20TokenExchange.OfferRequest proposal;
    uint date;
}

struct CancelProposalRequest {
    uint proposalId;
    address communityId;
}

struct BidProposal {
    uint proposalId;
    address communityId;
    address proposalCreator;
    Vote[20] approvals;
    IIncreasingPriceERC721Auction.PlaceBidRequest proposal;
    uint date;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../model.sol";

interface IPRIVIDAO {
    function getCommunity(address communityId) external view returns(Community memory);
    function updateCommunity(Community memory community) external;
    function getIdOfFounders(Community memory community, address founder) external pure returns(uint, bool);
    function getAuctionContractAddress() external view returns(address);
    function getExchangeContractAddress() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../model.sol";

interface IManageCommunityToken{
    function isTokenExist(string memory tokenSymbol) external view returns(bool);
    function getTokenContractAddress(string  memory tokenSymbol) external view returns(address, bool);
    function getCommunityToken(uint tokenId) external view returns(CommunityToken memory);
    function updateCommunityToken(CommunityToken memory communityToken) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IIncreasingPriceERC721Auction {
    struct Auction {
        address tokenAddress;
        uint256 tokenId;
        address owner;
        uint256 reservePrice;
        bytes32 ipfsHash;
        uint64 startTime;
        uint64 endTime;
        uint256 currentBid;
        uint64 bidIncrement;
        address payable currentBidder;
    }

    struct PlaceBidRequest {
        string mediaSymbol;
        string tokenSymbol;
        address _address;
        address fromAddress;
        uint256 amount;
    }

    function getAuctionsByPartialCompositeKey(string memory mediaSymbol, string memory tokenSymbol)
        external view
        returns (Auction memory _auction, bool canBid);

    function placeBid(PlaceBidRequest memory input) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IERC20TokenExchange {
    struct ERC20Exchange {
        string exchangeName;
        address creatorAddress;
        address exchangeTokenAddress;
        address offerTokenAddress;
        uint initialAmount;
        uint price;
    }

    struct ERC20Offer {
        uint exchangeId;
        uint offerId;
        string offerType;
        address creatorAddress;
        uint amount;
        uint price;
    }

    struct PlaceERC20TokenOfferRequest {
        uint exchangeId;
        uint amount;
        uint price;
    }

    struct OfferRequest {
        uint exchangeId;
        uint offerId;
    }

    function getErc20ExchangeById(uint _exchangeId) external view returns(ERC20Exchange memory);
    function getErc20OfferById(uint _offerId) external view returns(ERC20Offer memory);
    function PlaceERC20TokenBuyingOffer(PlaceERC20TokenOfferRequest calldata input, address caller) external;
    function BuyERC20TokenFromOffer(OfferRequest memory input, address caller) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

string constant IndexCommunities = "COMMUNITY";
string constant IndexCommunityCreationProposal = "COMMUNITY_CREATION_PROPOSAL";
string constant IndexCommunityToken = "COMMUNITY_TOKEN";
string constant IndexJoiningRequest = "COMMUNITY_JOINING_REQUEST";
string constant IndexProposal = "COMMUNITY_PROPOSAL";
string constant IndexMember = "COMMUNITY_MEMBER";
string constant CommunityTokenProposalType = "CommunityToken";
string constant AllocationProposalType = "Allocation";
string constant TreasurerProposalType = "Treasurer";
string constant AirdropProposalType = "Airdrop";
string constant EjectMemberProposalType = "EjectMember";
string constant TransferProposalType = "Transfer";
string constant BidProposalType = "Bid";
string constant BuyingOrderProposalType = "BuyingOrder";
string constant BuyingProposalType = "BuyingProposal";
string constant CommunityCreationProposalType = "CommunityCreation";
string constant FounderMemberType = "founder";
string constant TreasurerMemberType = "treasurer";
string constant MemberType = "member";
string constant CommunityEntryTypeOpenToJoin = "OpenToJoin";
string constant CommunityEntryTypeApproval = "Approval";
string constant CommunityEntryTypeStaking = "Staking";
string constant CommunityTokenTypeLinear = "LINEAR";
string constant CommunityTokenTypeQuadratic = "QUADRATIC";
string constant CommunityTokenTypeExponential = "EXPONENTIAL";
string constant CommunityTokenTypeSigmoid = "SIGMOID";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

