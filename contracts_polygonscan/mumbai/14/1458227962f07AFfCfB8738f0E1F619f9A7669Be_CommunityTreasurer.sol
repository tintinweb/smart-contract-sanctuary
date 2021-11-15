// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IPRIVIDAO.sol";
import "./interfaces/ICommunityEjectMember.sol";

import "./constant.sol";

contract CommunityTreasurer {
    mapping(uint => ManageTreasurerProposal) _treasurerProposals;

    uint[] _treasurerProposalIds;
    uint _treasurerProposalCount;

    address _daoContractAddress;
    address _ejectMemberContractAddress;

    constructor(address daoContractAddress, address ejectMemberContractAddress) {
        _daoContractAddress = daoContractAddress;
        _ejectMemberContractAddress = ejectMemberContractAddress;
    }

    function getTreasurerProposalCount() public view returns(uint) {
        return _treasurerProposalCount;
    }

    function getTreasurerProposalIds(uint index) public view returns(uint) {
        return _treasurerProposalIds[index];
    }

    function getTreasurerProposal(uint proposalId) public view returns(ManageTreasurerProposal memory) {
        require(
            _treasurerProposals[proposalId].proposalId == proposalId, 
            "proposalId is not valid"
        );

        return _treasurerProposals[proposalId];
    }

    function checkPrerequisitesToTreasurer(ManageTreasurerProposal memory treasurerProposal) internal view {
        Community memory community;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(treasurerProposal.communityId);
        require(community.communityAddress != address(0), "community not registered");

        for(uint i = 0; i < treasurerProposal.treasurerCount; i++) {
            require(treasurerProposal.treasurerAddresses[i] != address(0), "address invalid");
        }

        Member[] memory treasurers;
        uint treasurersCount;

        (treasurers, treasurersCount) = ICommunityEjectMember(_ejectMemberContractAddress).getMembersByType(community.communityAddress, TreasurerMemberType);
        require(
            (treasurersCount != 0) || (treasurerProposal.isAddingTreasurers), 
            "cannot remove treasurers as no treasurers are registered" 
        );

        if(treasurerProposal.isAddingTreasurers) {
            for(uint i = 0; i < treasurersCount; i++) {
                uint index;
                bool flag = false;
                for(uint j = 0; j < treasurerProposal.treasurerCount; j++) {
                    if(treasurerProposal.treasurerAddresses[j] == treasurers[i].memberAddress) {
                        index = j;
                        flag = true;
                        break;
                    }
                }
                require(!flag, "treasurer with address: is already registered as a treasurer");
            }
        }       
    }

    function updateTreasurerProposal(ManageTreasurerProposal memory treasurerProposal) internal {
        Community memory community;
        bool result;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(treasurerProposal.communityId);

        result = false;
        for(uint i = 0; i < _treasurerProposalCount; i++) {
            if(_treasurerProposalIds[i] == treasurerProposal.proposalId) {
                result = true;
                break;
            }
        }

        if(!result) {
            _treasurerProposalCount++;
            _treasurerProposalIds.push(treasurerProposal.proposalId);
        }
        
        _treasurerProposals[treasurerProposal.proposalId].proposalId = treasurerProposal.proposalId;
        _treasurerProposals[treasurerProposal.proposalId].communityId = treasurerProposal.communityId;
        _treasurerProposals[treasurerProposal.proposalId].proposalCreator = treasurerProposal.proposalCreator;
        _treasurerProposals[treasurerProposal.proposalId].treasurerCount = treasurerProposal.treasurerCount;
        _treasurerProposals[treasurerProposal.proposalId].isAddingTreasurers = treasurerProposal.isAddingTreasurers;
        _treasurerProposals[treasurerProposal.proposalId].date = treasurerProposal.date;

        for(uint i = 0; i < community.foundersCount; i++) {
            _treasurerProposals[treasurerProposal.proposalId].approvals[i].IsVoted = treasurerProposal.approvals[i].IsVoted;
            _treasurerProposals[treasurerProposal.proposalId].approvals[i].Vote = treasurerProposal.approvals[i].Vote;
        }

        _treasurerProposals[treasurerProposal.proposalId].treasurerAddresses = treasurerProposal.treasurerAddresses;
    }

    function deleteTreasurerProposal(uint proposalId) internal {
        delete _treasurerProposals[proposalId];
    }

    function cancelTreasurerProposal(CancelProposalRequest calldata cancelProposalRequest) external {
        ManageTreasurerProposal memory treasurerProposal;
        Community memory community;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(cancelProposalRequest.communityId);

        treasurerProposal = getTreasurerProposal(cancelProposalRequest.proposalId);

        uint creationDateDiff = (block.timestamp - treasurerProposal.date);

        require(
            (treasurerProposal.proposalCreator == msg.sender) || 
                (creationDateDiff >= community.foundersVotingTime),
            "just proposal creator can cancel proposal"
        );

        deleteTreasurerProposal(cancelProposalRequest.proposalId);
    }

    function CreateTreasurerProposal(ManageTreasurerProposal calldata treasurerProposalInput) external {
        checkPrerequisitesToTreasurer(treasurerProposalInput);
        
        ManageTreasurerProposal memory treasurerProposal;
        Community memory community;
        bool result;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(treasurerProposalInput.communityId);

        for(uint i = 0; i< community.foundersCount; i++) {
            treasurerProposal.approvals[i].IsVoted = false;
            treasurerProposal.approvals[i].Vote = false;
        }

        treasurerProposal.date = block.timestamp;

        uint founderIndex;
        (founderIndex, result) = IPRIVIDAO(_daoContractAddress).getIdOfFounders(community, msg.sender);
        require(result, "should be founder");

        if((community.foundersCount == 1) && (community.foundersShares[founderIndex] > 0)) {
            for(uint i = 0; i < treasurerProposalInput.treasurerCount; i++) {
                Member memory treasurer;
                treasurer.communityId = treasurerProposalInput.communityId;
                treasurer.memberAddress = treasurerProposalInput.treasurerAddresses[i];
                treasurer.memberType = TreasurerMemberType;

                if(treasurerProposalInput.isAddingTreasurers) {
                    ICommunityEjectMember(_ejectMemberContractAddress).updateMember(treasurer);
                } else {
                    ICommunityEjectMember(_ejectMemberContractAddress).deleteMember(treasurerProposalInput.treasurerAddresses[i], treasurerProposalInput.communityId, TreasurerMemberType);
                }
            }
            return;
        }

        treasurerProposal.proposalId = uint(keccak256(abi.encodePacked(block.difficulty, treasurerProposal.date, _treasurerProposalCount + 1)));
        treasurerProposal.communityId = treasurerProposalInput.communityId;
        treasurerProposal.treasurerAddresses = treasurerProposalInput.treasurerAddresses;
        treasurerProposal.treasurerCount = treasurerProposalInput.treasurerCount;           
        treasurerProposal.proposalCreator = msg.sender;
        treasurerProposal.isAddingTreasurers = treasurerProposalInput.isAddingTreasurers;

        updateTreasurerProposal(treasurerProposal);
    }

    function VoteTreasurerProposal(VoteProposal calldata voteTreasurerInput) external {
        ManageTreasurerProposal memory treasurerProposal;
        Community memory community;
        bool result;

        community =  IPRIVIDAO(_daoContractAddress).getCommunity(voteTreasurerInput.communityId);

        treasurerProposal = getTreasurerProposal(voteTreasurerInput.proposalId);

        uint founderIndex;
        (founderIndex, result) = IPRIVIDAO(_daoContractAddress).getIdOfFounders(community, msg.sender);
        require(result, "voter has to be an founder of the community");
        require(!treasurerProposal.approvals[founderIndex].IsVoted, "voter can not vote second time");

        uint creationDateDiff = (block.timestamp - treasurerProposal.date);
        require(creationDateDiff <= community.foundersVotingTime, "voting time is over");

        treasurerProposal.approvals[founderIndex].IsVoted = true;
        treasurerProposal.approvals[founderIndex].Vote = voteTreasurerInput.decision;

        uint consensusScoreRequirement = community.foundersConsensus;
        uint consensusScore;
        uint negativeConsensusScore;

        for(uint i = 0; i < community.foundersCount; i++) {
            if(treasurerProposal.approvals[i].Vote) {
                consensusScore += community.foundersShares[i]; 
            }
            
            if(!treasurerProposal.approvals[i].Vote && treasurerProposal.approvals[i].IsVoted) {
                negativeConsensusScore += community.foundersShares[i];
            }
        }

        if(consensusScore >= consensusScoreRequirement) {
            for(uint i = 0; i < treasurerProposal.treasurerCount; i++) {
                Member memory treasurer;
                treasurer.communityId = treasurerProposal.communityId;
                treasurer.memberAddress = treasurerProposal.treasurerAddresses[i];
                treasurer.memberType = TreasurerMemberType;

                if(treasurerProposal.isAddingTreasurers) {
                    ICommunityEjectMember(_ejectMemberContractAddress).updateMember(treasurer);
                } else {
                    ICommunityEjectMember(_ejectMemberContractAddress).deleteMember(treasurerProposal.treasurerAddresses[i], treasurerProposal.communityId, TreasurerMemberType);
                }
            }

            deleteTreasurerProposal(treasurerProposal.proposalId);
            return;
        }

        if(negativeConsensusScore > (10000 - consensusScoreRequirement)) { // *10^4
            deleteTreasurerProposal(treasurerProposal.proposalId);
            return;
        }

        updateTreasurerProposal(treasurerProposal);
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

