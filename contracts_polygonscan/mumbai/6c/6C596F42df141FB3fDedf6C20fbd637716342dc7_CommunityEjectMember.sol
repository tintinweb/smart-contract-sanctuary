// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IPRIVIDAO.sol";
import "./interfaces/IManageCommunityToken.sol";

import "./constant.sol";

contract CommunityEjectMember {
    mapping(uint => EjectMemberProposal) _ejectMemberProposals;
    mapping(uint => Member) _members;

    uint[] _ejectMemberProposalIds;

    uint _ejectMemberProposalCount;
    uint _memberCounter;

    address _daoContractAddress;
    address _manageCommunityTokenContractAddress;

    constructor(address daoContractAddress, address manageCommunityTokenContractAddress) {
        _daoContractAddress = daoContractAddress;
        _manageCommunityTokenContractAddress = manageCommunityTokenContractAddress;
    }

    function getEjectMemberProposalCount() public view returns(uint) {
        return _ejectMemberProposalCount;
    }

    function getEjectmemberProposalIds(uint index) public view returns(uint) {
        return _ejectMemberProposalIds[index];
    }

    function getEjectMemberProposal(uint proposalId) public view returns(EjectMemberProposal memory) {
        require(
            _ejectMemberProposals[proposalId].proposalId == proposalId, 
            "proposalId is not valid"
        );

        return _ejectMemberProposals[proposalId];
    }

    function getMembersByType(address communityId, string memory memberType) public view returns(Member[] memory, uint) {
        Member[] memory members = new Member[](_memberCounter);
        uint counter;
        for(uint i = 0; i < _memberCounter; i++) {
            Member memory member = _members[i];
            if((member.communityId == communityId) && 
                (keccak256(abi.encodePacked(member.memberType)) == keccak256(abi.encodePacked(memberType)))) {
                members[counter] = _members[i];
                counter++;
            }
        }
        return (members, counter);
    }

    function getMembers(address communityId) public view returns(Member[] memory, uint) {
        Member[] memory members = new Member[](_memberCounter);
        uint counter;
        for(uint i = 0; i < _memberCounter; i++) {
            Member memory member = _members[i];
            if(member.communityId == communityId) {
                members[counter] = _members[i];
                counter++;
            }
        }
        return (members, counter);
    }

    function updateMember(Member memory member) public {
        uint memberIndex;
        for(uint i = 0; i < _memberCounter; i++) {
            if(_members[i].memberAddress == member.memberAddress) {
                memberIndex = i;
                break;
            }
        }
        
        if(memberIndex == 0) {
            memberIndex = _memberCounter;
            _memberCounter++;
        }

        _members[memberIndex].communityId = member.communityId;
        _members[memberIndex].memberAddress = member.memberAddress;
        _members[memberIndex].memberType = member.memberType;
        _members[memberIndex].share = member.share;
    }

    function updateEjectMemberProposal(EjectMemberProposal memory em) internal {
        Community memory community;
        bool flag = false;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(em.communityId);

        for(uint i = 0; i < _ejectMemberProposalCount; i++) {
            if(_ejectMemberProposalIds[i] == em.proposalId) {
                flag = true;
                break;
            }
        }

        if(!flag) {
            _ejectMemberProposalCount++;
            _ejectMemberProposalIds.push(em.proposalId);
        }

        
        _ejectMemberProposals[em.proposalId].proposalId = em.proposalId;
        _ejectMemberProposals[em.proposalId].communityId = em.communityId;
        _ejectMemberProposals[em.proposalId].proposalCreator = em.proposalCreator;
        _ejectMemberProposals[em.proposalId].memberAddress = em.memberAddress;
        _ejectMemberProposals[em.proposalId].date = em.date;
        
        for(uint i = 0; i < community.foundersCount; i++) {
            _ejectMemberProposals[em.proposalId].approvals[i].IsVoted = em.approvals[i].IsVoted;
            _ejectMemberProposals[em.proposalId].approvals[i].Vote = em.approvals[i].Vote;
        }
    }

    function deleteMember(address memberAddress, address communityId, string memory memberType) public {
        for(uint i = 0; i < _memberCounter; i++) {
            if((_members[i].memberAddress == memberAddress) && (_members[i].communityId == communityId)
                && (keccak256(abi.encodePacked(_members[i].memberType)) == keccak256(abi.encodePacked(memberType)))) {
                delete _members[i];
                return;
            }
        }
    }

    function removeMember(address memberAddress, Community memory community) public {
        if(keccak256(abi.encodePacked(community.entryType)) == keccak256(abi.encodePacked(CommunityEntryTypeStaking))) {
            for(uint i = 0; i < community.entryConditionCount; i++) {
                address tokenContractAddress;
                bool result;

                (tokenContractAddress, result) = IManageCommunityToken(_manageCommunityTokenContractAddress)
                    .getTokenContractAddress(community.entryConditionSymbols[i]);
                require(result, "token contract address is not valid");
                
                IERC20(tokenContractAddress).transferFrom(community.stakingAddress, memberAddress, community.entryConditionValues[i]);
            }
        }
        deleteMember(memberAddress, community.communityAddress, MemberType);
    }

    function deleteEjectMemberProposal(uint proposalId) internal {
        delete _ejectMemberProposals[proposalId];
    }

    function cancleEjectMemberProposal(CancelProposalRequest calldata cancelProposalRequest) external {
        EjectMemberProposal memory ejectMemberProposal;
        Community memory community;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(cancelProposalRequest.communityId);

        ejectMemberProposal = getEjectMemberProposal(cancelProposalRequest.proposalId);

        uint creationDateDiff = (block.timestamp - ejectMemberProposal.date);

        require(
            (ejectMemberProposal.proposalCreator == msg.sender) || 
                (creationDateDiff >= community.foundersVotingTime),
            "just proposal creator can cancel proposal"
        );

        deleteEjectMemberProposal(cancelProposalRequest.proposalId);
    }

    function CreateEjectMemberProposal(EjectMemberRequest calldata ejectMemberRequest) external {
        Community memory community;
        bool result;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(ejectMemberRequest.communityId);

        uint founderIndex;
        (founderIndex, result) = IPRIVIDAO(_daoContractAddress).getIdOfFounders(community, msg.sender);
        require(result, "should be founder");

        Member[] memory members;
        uint memberCount;

        (members, memberCount) = getMembers(ejectMemberRequest.communityId);
        require(memberCount > 0, "get members failed with error");

        uint memberIndex;
        bool flag = false;
        for(uint i = 0; i < memberCount; i++) {
            if(members[i].memberAddress == ejectMemberRequest.ejectMemberAddress) {
                memberIndex = i;
                flag = true;
                break;
            }
        }
        require(flag, "address is not a member of community");

        EjectMemberProposal memory proposal;
        proposal.proposalId = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _ejectMemberProposalCount + 1)));
        proposal.communityId = ejectMemberRequest.communityId;
        proposal.proposalCreator = msg.sender;
        proposal.memberAddress = ejectMemberRequest.ejectMemberAddress;
        proposal.date = block.timestamp;

        for(uint i = 0; i < community.foundersCount; i++) {
            proposal.approvals[i].IsVoted = false;
            proposal.approvals[i].Vote = false;
        }

        if(community.foundersCount > 1) {
            updateEjectMemberProposal(proposal);
            return;
        }

        removeMember(proposal.memberAddress, community);
    }

    function VoteEjectMemberProposal(VoteProposal calldata voteProposal) external {
        EjectMemberProposal memory ejectMemberProposal;
        Community memory community;
        bool result;

        ejectMemberProposal = getEjectMemberProposal(voteProposal.proposalId);

        community = IPRIVIDAO(_daoContractAddress).getCommunity(voteProposal.communityId);

        uint founderIndex;
        (founderIndex, result) = IPRIVIDAO(_daoContractAddress).getIdOfFounders(community, msg.sender);
        require(result, "a voter has to be a founder of the community");
        require(!ejectMemberProposal.approvals[founderIndex].IsVoted, "a voter can not vote second time");

        require(
            (block.timestamp - ejectMemberProposal.date) <= community.foundersVotingTime, 
            "voting time is over"
        );

        ejectMemberProposal.approvals[founderIndex].IsVoted = true;
        ejectMemberProposal.approvals[founderIndex].Vote = voteProposal.decision;

        uint consensusScoreRequirement = community.foundersConsensus;
        uint consensusScore;
        uint negativeConsensusScore;

        for(uint i = 0; i < community.foundersCount; i++) {
            if(ejectMemberProposal.approvals[i].Vote) {
                consensusScore += community.foundersShares[i]; 
            }

            if(!ejectMemberProposal.approvals[i].Vote && ejectMemberProposal.approvals[i].IsVoted ) {
                negativeConsensusScore += community.foundersShares[i]; 
            }
        }

        if(consensusScore >= consensusScoreRequirement) {
            removeMemberProposal(ejectMemberProposal, community);
            return;
        }

        if(negativeConsensusScore >= (10000 - consensusScoreRequirement)) { // *10^4
            deleteEjectMemberProposal(ejectMemberProposal.proposalId);
            return;
        }

        updateEjectMemberProposal(ejectMemberProposal);
    }

    function removeMemberProposal(EjectMemberProposal memory ejectMemberProposal, Community memory community) internal {
        removeMember(ejectMemberProposal.memberAddress, community);
        deleteEjectMemberProposal(ejectMemberProposal.proposalId);
    }

    function CancelMembership(CancelMembershipRequest calldata cancelMembershipRequest) external {
        Community memory community;
        Member[] memory members;
        uint memberCount;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(cancelMembershipRequest.communityId);

        (members, memberCount) = getMembers(cancelMembershipRequest.communityId);
        require(memberCount > 0 , "get members failed with error");

        uint memberIndex;
        bool flag = false;
        for(uint i = 0; i < memberCount; i++) {
            if(members[i].memberAddress == cancelMembershipRequest.memberAddress) {
                memberIndex = i;
                flag = true;
                break;
            }
        }
        require(flag, "address is not a member of community");

        removeMember(cancelMembershipRequest.memberAddress, community);
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "berlin",
  "libraries": {},
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