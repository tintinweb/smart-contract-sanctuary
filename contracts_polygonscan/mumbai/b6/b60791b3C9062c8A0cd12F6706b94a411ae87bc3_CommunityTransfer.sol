// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IPRIVIDAO.sol";
import "./interfaces/IManageCommunityToken.sol";
import "./interfaces/ICommunityEjectMember.sol";

import "./constant.sol";

contract CommunityTransfer {
    mapping(uint => TransferProposal) _transferProposals;

    uint[] _transferProposalIds;
    uint _transferProposalCount;

    address _daoContractAddress;
    address _manageCommunityTokenContractAddress;
    address _ejectMemberContractAddress;

    event consensusScoreGenerated(uint indexed);

    constructor(address daoContractAddress, address manageCommunityTokenContractAddress,
        address ejectMemberContractAddress) {
        _daoContractAddress = daoContractAddress;
        _manageCommunityTokenContractAddress = manageCommunityTokenContractAddress;
        _ejectMemberContractAddress = ejectMemberContractAddress;
    }

    function getTransferProposalCount() public view returns(uint) {
        return _transferProposalCount;
    }

    function getTransferProposalIds(uint index) public view returns(uint) {
        return _transferProposalIds[index];
    }

    function getTransferProposal(uint proposalId) public view returns(TransferProposal memory) {
        require(
            _transferProposals[proposalId].proposalId == proposalId, 
            "proposalId is not valid"
        );

        return _transferProposals[proposalId];
    }

    function updateTransferProposal(TransferProposal memory tp) internal {
        Community memory community;
        bool result;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(tp.communityId);

        result = false;
        for(uint i = 0; i < _transferProposalCount; i++) {
            if(_transferProposalIds[i] == tp.proposalId) {
                result = true;
                break;
            }
        }

        if(!result) {
            _transferProposalCount++;
            _transferProposalIds.push(tp.proposalId);
        }

        _transferProposals[tp.proposalId].proposalId = tp.proposalId;
        _transferProposals[tp.proposalId].communityId = tp.communityId;
        _transferProposals[tp.proposalId].proposalCreator = tp.proposalCreator;

        _transferProposals[tp.proposalId].proposal = tp.proposal;
        _transferProposals[tp.proposalId].date = tp.date;

        for(uint i = 0; i < community.foundersCount; i++) {
            _transferProposals[tp.proposalId].approvals[i].IsVoted = tp.approvals[i].IsVoted;
            _transferProposals[tp.proposalId].approvals[i].Vote = tp.approvals[i].Vote;
        }
    }

    function deleteTransferProposal(uint proposalId) internal {
        delete _transferProposals[proposalId];
    }

    function cancelTransferProposal(CancelProposalRequest calldata cancelProposalRequest) external{
        TransferProposal memory transferProposal;
        Community memory community;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(cancelProposalRequest.communityId);

        transferProposal = getTransferProposal(cancelProposalRequest.proposalId);

        uint creationDateDiff = (block.timestamp - transferProposal.date);

        require(
            (transferProposal.proposalCreator == msg.sender) || 
                (creationDateDiff >= community.treasuryVotingTime),
            "just proposal creator can cancel proposal"
        );

        IERC20(transferProposal.proposal.tokenContractAddress)
            .transferFrom(community.escrowAddress, community.communityAddress, transferProposal.proposal.amount);
        
        deleteTransferProposal(cancelProposalRequest.proposalId);
    }

    function CreateTransferProposal(TransferProposalRequest calldata transferProposalRequest) external {
        address tokenContractAddress;
        Community memory community;
        bool result;
        (tokenContractAddress, result) = IManageCommunityToken(_manageCommunityTokenContractAddress)
            .getTokenContractAddress(transferProposalRequest.tokenSymbol);
        require(result, "get token contract address failed with error");

        community = IPRIVIDAO(_daoContractAddress).getCommunity(transferProposalRequest.communityId);

        uint founderIndex;
        (founderIndex, result) = IPRIVIDAO(_daoContractAddress).getIdOfFounders(community, msg.sender);
        bool treasurerFlag;
        Member[] memory treasurers;
        uint treasurerCount;
        (treasurers, treasurerCount) = ICommunityEjectMember(_ejectMemberContractAddress).getMembersByType(transferProposalRequest.communityId, TreasurerMemberType);
        require(treasurerCount > 0, "at least one treasurer required in community");


        for(uint i = 0; i < treasurerCount; i++) {
            if(treasurers[i].memberAddress == msg.sender) {
                treasurerFlag = true;
                break;
            }
        }

        require(
            (result) || (treasurerFlag), 
            "just founders or treasurers can create transfer proposal."
        );

        uint balance = IERC20(tokenContractAddress).balanceOf(community.communityAddress);
        require(balance >= transferProposalRequest.amount, "insufficient funds");

        if(treasurerCount == 1) {
            IERC20(tokenContractAddress).transferFrom(community.communityAddress, community.escrowAddress, transferProposalRequest.amount);
            IERC20(tokenContractAddress).transferFrom(community.escrowAddress, transferProposalRequest.to, transferProposalRequest.amount);
            return;
        }

        TransferProposal memory transferProposal;
        TransferRequest memory transferRequest;

        transferRequest.transferType = "Community_Transfer";
        transferRequest.tokenContractAddress = tokenContractAddress;
        transferRequest.from = community.escrowAddress;
        transferRequest.to = transferProposalRequest.to;
        transferRequest.amount = transferProposalRequest.amount;

        transferProposal.proposalId = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _transferProposalCount + 1)));
        transferProposal.communityId = transferProposalRequest.communityId;
        transferProposal.proposalCreator = msg.sender;
        transferProposal.proposal = transferRequest;
        transferProposal.date = block.timestamp;

        for(uint i = 0; i < community.foundersCount; i++) {
            transferProposal.approvals[i].IsVoted = false;
            transferProposal.approvals[i].Vote = false;
        }

        IERC20(tokenContractAddress).transferFrom(community.communityAddress, community.escrowAddress, transferProposalRequest.amount);
        updateTransferProposal(transferProposal);
    }

    function  VoteTransferProposal(VoteProposal calldata voteProposal) external {
        Community memory community;
        TransferProposal memory transferProposal;
        bool result;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(voteProposal.communityId);

        transferProposal = getTransferProposal(voteProposal.proposalId);

        Member[] memory treasurers;
        uint treasurerCount;

        (treasurers, treasurerCount) = ICommunityEjectMember(_ejectMemberContractAddress).getMembersByType(voteProposal.communityId, TreasurerMemberType);
        require(treasurerCount > 0, "at least one treasurer required in community");

        uint treasurerIndex;
        result = false;
        for(uint i = 0; i < treasurerCount; i++) {
            if(treasurers[i].memberAddress == msg.sender) {
                treasurerIndex = i;
                result = true;
                break;
            }
        }

        require(result, "just treasurers can vote on transfer proposal.");

        require(!transferProposal.approvals[treasurerIndex].IsVoted, "voter can not vote second time");

        uint creationDateDiff = block.timestamp - transferProposal.date;
        require(creationDateDiff <= community.treasuryVotingTime, "voting time is over");

        transferProposal.approvals[treasurerIndex].IsVoted = true;
        transferProposal.approvals[treasurerIndex].Vote = voteProposal.decision;

        uint consensusScoreRequirement = community.treasuryConsensus;
        uint consensusScore;
        uint negativeConsensusScore;

        for(uint i = 0; i < treasurerCount; i++) {
            if(transferProposal.approvals[i].Vote) {
                consensusScore += (10000 / treasurerCount);
            }

            if((!transferProposal.approvals[i].Vote) && (transferProposal.approvals[i].IsVoted)) {
                negativeConsensusScore += (10000 / treasurerCount);
            }
        }

        emit consensusScoreGenerated(consensusScore);

        if(consensusScore >= consensusScoreRequirement) {
            TransferRequest memory proposal = transferProposal.proposal;
            IERC20(proposal.tokenContractAddress).transferFrom(proposal.from, proposal.to, proposal.amount);
            deleteTransferProposal(transferProposal.proposalId);
            return;
        }

        if(negativeConsensusScore > (10000 - consensusScoreRequirement)) { // *10^4
            deleteTransferProposal(transferProposal.proposalId);

            TransferRequest memory proposal = transferProposal.proposal;
            IERC20(proposal.tokenContractAddress).transferFrom(community.escrowAddress, community.communityAddress, proposal.amount);
            return;
        }

        updateTransferProposal(transferProposal);
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

import "../model.sol";

interface ICommunityEjectMember {
    function getMembersByType(address communityId, string memory memberType) external view returns(Member[] memory, uint);
    function getMembers(address communityId) external view returns(Member[] memory, uint);
    function removeMember(address memberAddress, Community memory community) external;
    function updateMember(Member memory member) external;
    function deleteMember(address memberAddress, address communityId, string memory memberType) external;
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

