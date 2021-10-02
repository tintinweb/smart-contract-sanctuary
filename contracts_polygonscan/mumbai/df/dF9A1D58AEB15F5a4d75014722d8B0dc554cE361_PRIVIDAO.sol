// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IManageCommunityToken.sol";
import "./interfaces/ICommunityEjectMember.sol";

import "./constant.sol";

contract PRIVIDAO {
    mapping(uint => CommunityCreationProposal) _communityCPs;
    mapping(address => Community) _communities;

    uint[] _communityCPIds;
    address[] _communityIds;

    address _exchangeContractAddress;
    address _auctionContractAddress;

    address _manageCommunityTokenContractAddress;
    address _ejectMemberContractAddress;

    uint _communityCPCounter;
    uint _communityCounter;

    constructor(address exchangeContractAddress, address auctionContractAddress) {
        _exchangeContractAddress = exchangeContractAddress;
        _auctionContractAddress = auctionContractAddress;
    }

    function getCommunityIdByIndex(uint index) public view returns(address){
        return _communityIds[index];
    }

    function getCommunityCounter() public view returns(uint) {
        return _communityCounter;
    }

    function getCommunityCPIdByIndex(uint index) public view returns(uint){
        return _communityCPIds[index];
    }

    function getCommunityCPCounter() public view returns(uint) {
        return _communityCPCounter;
    }

    function getExchangeContractAddress() public view returns(address) {
        return _exchangeContractAddress;
    }

    function getAuctionContractAddress() public view returns(address) {
        return _auctionContractAddress;
    }
    
    function getIdOfFounders(Community memory community, address founder) public pure returns(uint, bool) {
        for(uint i = 0; i < community.foundersCount; i++) {
            if(community.founders[i] == founder) {
                return (i, true);
            }
        }
        return (0, false);
    }

    function getCreationProposal(uint proposalId) public view returns(CommunityCreationProposal memory){
        return _communityCPs[proposalId];
    }

    function getCommunity(address communityId) public view returns(Community memory) {
        return _communities[communityId];
    }

    function updateCommunity(Community memory community) public {
        uint index;
        bool flag = false;

        for(uint i = 0; i < _communityCounter; i++) {
            if(_communityIds[i] == community.communityAddress) {
                index = i;
                flag = true;
                break;
            }
        }
        
        require(flag, "community is not exist");

        _communityIds[index] = community.communityAddress;
        _communities[community.communityAddress] = community;
    }

    function updateCommunityCreationProposal(CommunityCreationProposal memory communityCP) internal {
        uint index;
        bool flag = false;

        for(uint i = 0; i < _communityCPCounter; i++) {
            if(_communityCPIds[i] == communityCP.proposalId) {
                index = i;
                flag = true;
                break;
            }
        }
        
        require(flag, "community creation proposal is not exist");

        _communityCPIds[index] = communityCP.proposalId;
        
        _communityCPs[communityCP.proposalId].proposal = communityCP.proposal;
        _communityCPs[communityCP.proposalId].proposalCreator = communityCP.proposalCreator;
        _communityCPs[communityCP.proposalId].proposalId = communityCP.proposalId;
        _communityCPs[communityCP.proposalId].date = communityCP.date;

        for(uint j = 0; j < communityCP.proposal.foundersCount; j++) {
            _communityCPs[communityCP.proposalId].approvals[j].IsVoted = communityCP.approvals[j].IsVoted;
            _communityCPs[communityCP.proposalId].approvals[j].Vote = communityCP.approvals[j].Vote;
        }
    }

    function setManageCommunityTokenContractAddress(address manageCommunityTokenContractAddress) external {
        _manageCommunityTokenContractAddress = manageCommunityTokenContractAddress;
    }

    function setEjectMemberContractAddress(address ejectMemberContractAddress) external {
        _ejectMemberContractAddress = ejectMemberContractAddress;
    }

    function deleteCommunityCreationProposal(uint proposalId) public {
        delete _communityCPs[proposalId];
    }

    function cancelCreationProposal(CancelProposalRequest calldata cancelProposalRequest) external {
        CommunityCreationProposal memory communityCreationProposal;
        communityCreationProposal = getCreationProposal(cancelProposalRequest.proposalId);

        uint creationDateDiff = (block.timestamp - communityCreationProposal.date);

        require(
            (communityCreationProposal.proposalCreator == msg.sender) || 
                (creationDateDiff >= (7 * 24 * 3600)),
            "just proposal creator can cancel proposal"
        );

        deleteCommunityCreationProposal(cancelProposalRequest.proposalId);
    }

    function CreateCommunity(Community calldata community) external {
        uint founderIndex;
        bool result;
        (founderIndex, result) = getIdOfFounders(community, msg.sender);
        require(result == true, "creator should be one of founders");
        require((keccak256(abi.encodePacked(community.entryType)) == keccak256(abi.encodePacked(CommunityEntryTypeApproval))) ||
            (keccak256(abi.encodePacked(community.entryType)) == keccak256(abi.encodePacked(CommunityEntryTypeOpenToJoin))) ||
            (keccak256(abi.encodePacked(community.entryType)) == keccak256(abi.encodePacked(CommunityEntryTypeStaking)))
            , "Wrong entry type of the community");
        require((keccak256(abi.encodePacked(community.entryType)) != keccak256(abi.encodePacked(CommunityEntryTypeStaking))) ||
            (community.entryConditionCount != 0), "entry conditions should be defined by staking option");
        require((keccak256(abi.encodePacked(community.entryType)) == keccak256(abi.encodePacked(CommunityEntryTypeStaking))) ||
            (community.entryConditionCount == 0), "entry conditions should not be defined by not staking option");
        uint foundersSharesSum = 0;
        for(uint i = 0; i < community.foundersCount; i++) {
            foundersSharesSum += community.foundersShares[i];
        }
        require(foundersSharesSum == 10000, "founders shares sum shoud be 10000");// *10^4
        require(community.foundersVotingTime >= (3600 * 24), "founders Voting Time should be longer than 1 day");
        require(community.treasuryVotingTime >= (3600 * 24), "treasury Voting Time should be longer than 1 day");
        require(
            (community.foundersConsensus >= 0) && (community.foundersConsensus < 10000), 
            "founders Consensus should be between 0 and 10000"
        );
        require(
            (community.treasuryConsensus >= 0) && (community.treasuryConsensus < 10000), 
            "treasury Consensus should be between 0 and 10000"
        );

        if(keccak256(abi.encodePacked(community.entryType)) == keccak256(abi.encodePacked(CommunityEntryTypeStaking))) {
            for(uint i = 0; i < community.entryConditionCount; i++) {
                bool isTokenExist = IManageCommunityToken(_manageCommunityTokenContractAddress).isTokenExist(community.entryConditionSymbols[i]);
                require(
                    isTokenExist, 
                    "entry conditions token with symbol does not exist"
                );
                require(community.entryConditionValues[i] > 0, "entry condition token amount should be greater than 0");
            }
        }
        
        if(community.foundersCount == 1) {
            for(uint i = 0; i < community.foundersCount; i++) {
                Member memory founder;
                founder.communityId = community.communityAddress;
                founder.memberAddress = msg.sender;
                founder.memberType = FounderMemberType;
                founder.share = community.foundersShares[i];

                ICommunityEjectMember(_ejectMemberContractAddress).updateMember(founder);
            }

            _communities[community.communityAddress] = community;
            _communityIds.push(community.communityAddress);
            _communityCounter++;            
            return;
        }

        uint proposalId = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _communityCPCounter)));
        _communityCPs[proposalId].proposal = community;
        _communityCPs[proposalId].proposal.date = block.timestamp;
        _communityCPs[proposalId].proposalCreator = msg.sender;
        _communityCPs[proposalId].proposalId = proposalId;
        
        for(uint i = 0; i < community.foundersCount; i++) {
            _communityCPs[proposalId].approvals[i] = Vote(false, false);
        }
        _communityCPs[proposalId].date = block.timestamp;
        _communityCPIds.push(proposalId);
        _communityCPCounter++;
    }

    function VoteCreationProposal(VoteProposal calldata voteProposal) external {
        require(voteProposal.communityId != address(0), "community id is not valid");
        require(voteProposal.proposalId != 0, "community creation proposal id is not valid");

        CommunityCreationProposal memory communityCP;
        communityCP = getCreationProposal(voteProposal.proposalId);
        
        uint voterId;
        bool result;
        (voterId, result) = getIdOfFounders(communityCP.proposal, msg.sender);
        require(result, "voter should be founder");
        require(communityCP.approvals[voterId].IsVoted == false, "voter can not vote second time");

        uint creationDiff = (block.timestamp - communityCP.date);
        require(creationDiff <= (7*24*3600), "voting time is over");

        if(!voteProposal.decision) {
            deleteCommunityCreationProposal(voteProposal.proposalId);
            return;
        }

        communityCP.approvals[voterId].IsVoted = true;
        communityCP.approvals[voterId].Vote = true;
        
        bool creationAppproved = true;

        for(uint i = 0; i < communityCP.proposal.foundersCount; i++) {
            if(communityCP.approvals[i].Vote == false){
                creationAppproved = false;
                break;
            }
        }

        if(creationAppproved) {
            communityCP.date = block.timestamp;

            for(uint i = 0; i < communityCP.proposal.foundersCount; i++) {
                Member memory founder;
                founder.communityId = communityCP.proposal.communityAddress;
                founder.memberAddress = communityCP.proposal.founders[i];
                founder.memberType = FounderMemberType;
                founder.share = communityCP.proposal.foundersShares[i];

                ICommunityEjectMember(_ejectMemberContractAddress).updateMember(founder);
            }

            _communities[voteProposal.communityId] = communityCP.proposal;
            _communityIds.push(voteProposal.communityId);
            _communityCounter++;

            deleteCommunityCreationProposal(voteProposal.proposalId);
            return;
        }

        updateCommunityCreationProposal(communityCP);        
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