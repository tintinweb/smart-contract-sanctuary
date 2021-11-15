// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IPRIVIDAO.sol";

import "./constant.sol";

contract ManageCommunityToken {
    mapping(uint => Token) _tokens;
    mapping(uint => CommunityToken) _communityTokens;
    mapping(uint => CommunityTokenProposal) _communityTPs;

    uint[] _communityTokenIds;
    uint[] _communityTPIds;

    uint _tokenCounter;
    uint _communityTokenCounter;
    uint _communityTPCounter;
    

    address _daoContractAddress;

    constructor(address daoContractAddress) {
        require(daoContractAddress != address(0), "dao contract address is not valid");
        _daoContractAddress = daoContractAddress;
    }

    function getTokenCounter() public view returns(uint) {
        return _tokenCounter;
    }

    function getCommunityTokenCounter() public view returns(uint) {
        return _communityTokenCounter;
    }

    function getCommunityTokenIdByIndex(uint index) public view returns(uint) {
        return _communityTokenIds[index];
    }

    function getCommunityTPCounter() public view returns(uint) {
        return _communityTPCounter;
    }

    function getCommunityTPIdByIndex(uint index) public view returns(uint) {
        return _communityTPIds[index];
    }

    function isTokenExist(string memory tokenSymbol) public view returns(bool) {
        for(uint i = 0; i < _tokenCounter; i++) {
            if(keccak256(abi.encodePacked(_tokens[i].symbol)) == keccak256(abi.encodePacked(tokenSymbol))) return true;
        }
        return false;
    }

    function getTokenContractAddress(string  memory tokenSymbol) public view returns(address, bool) {
        address contractAddress;
        for(uint i = 0; i < _tokenCounter; i++) {
            if(keccak256(abi.encodePacked(_tokens[i].symbol)) == keccak256(abi.encodePacked(tokenSymbol))) {
                contractAddress = _tokens[i].contractAddress;
                return (contractAddress, true);
            }
        }
        return (contractAddress, false);
    }

    function getCommunityToken(uint tokenId) public view returns(CommunityToken memory) {
        require(_communityTokens[tokenId].tokenId == tokenId, "tokenId is not valid");
        return _communityTokens[tokenId];
    }

    function updateCommunityToken(CommunityToken memory communityToken) public {
        bool flag = false;

        for(uint i = 0; i < _communityTokenCounter; i++) {
            if(_communityTokenIds[i] == communityToken.tokenId) {
                flag = true;
                break;
            }
        }
        if(!flag) {
            _communityTokenCounter++;
            _communityTokenIds.push(communityToken.tokenId);
        }

        _communityTokens[communityToken.tokenId] = communityToken;
    }

    function getCommunityTokenProposal(uint proposalId) public view returns(CommunityTokenProposal memory) {
        require(
            _communityTPs[proposalId].proposalId == proposalId, 
            "proposalId is not valid"
        );

        return _communityTPs[proposalId];
    }

    function updateCommunityTokenProposal(CommunityTokenProposal memory communityTP) internal  {
        bool flag = false;

        for(uint i = 0; i < _communityTPCounter; i++) {
            if(_communityTPIds[i] == communityTP.proposalId) {
                flag = true;
                break;
            }
        }
        if(!flag) {
            _communityTPCounter++;
            _communityTPIds.push(communityTP.proposalId);
        }
        _communityTPs[communityTP.proposalId].proposalId = communityTP.proposalId;
        _communityTPs[communityTP.proposalId].communityId = communityTP.communityId;
        _communityTPs[communityTP.proposalId].proposalCreator = communityTP.proposalCreator;
        _communityTPs[communityTP.proposalId].proposal = communityTP.proposal;
        _communityTPs[communityTP.proposalId].date = communityTP.date;

        for(uint j = 0; j < 20; j++) {
            _communityTPs[communityTP.proposalId].approvals[j].IsVoted = communityTP.approvals[j].IsVoted;
            _communityTPs[communityTP.proposalId].approvals[j].Vote = communityTP.approvals[j].Vote;
        }
    }

    function registerToken(string memory tokenName, string memory tokenSymbol, address tokenContractAddress) public {
        require(keccak256(abi.encodePacked(tokenName)) != keccak256(abi.encodePacked("")), "token name is not valid");
        require(keccak256(abi.encodePacked(tokenSymbol)) != keccak256(abi.encodePacked("")), "token symbol is not valid");
        require(tokenContractAddress != address(0), "token contract address is not exist");

        Token memory token;
        token.name = tokenName;
        token.symbol = tokenSymbol;
        token.contractAddress = tokenContractAddress;

        _tokens[_tokenCounter] = token;
        _tokenCounter++;
    }

    function checkPropertiesOfToken(CommunityToken memory token) internal view {
        require(
            token.communityId != address(0), "communityId can't be zero"
        );
        require(
            keccak256(abi.encodePacked(token.tokenSymbol)) != keccak256(abi.encodePacked("")), 
            "tokenSymbol can't be empty"
        );
        require(
            keccak256(abi.encodePacked(token.tokenName)) != keccak256(abi.encodePacked("")),
            "tokenName can't be empty"
        );
        require(!isTokenExist(token.tokenSymbol), "token already exist, can't be created");
        require(token.tokenContractAddress != address(0), "token contract address can't be zero");
        require(
            (keccak256(abi.encodePacked(token.tokenType)) == keccak256(abi.encodePacked(CommunityTokenTypeLinear))) ||
            (keccak256(abi.encodePacked(token.tokenType)) == keccak256(abi.encodePacked(CommunityTokenTypeQuadratic))) ||
            (keccak256(abi.encodePacked(token.tokenType)) == keccak256(abi.encodePacked(CommunityTokenTypeExponential))) ||
            (keccak256(abi.encodePacked(token.tokenType)) == keccak256(abi.encodePacked(CommunityTokenTypeSigmoid))),
            "accepted token types are only: LINEAR, QUADRATIC, EXPONENTIAL and SIGMOID"
        );
        require(
            keccak256(abi.encodePacked(token.fundingToken)) != keccak256(abi.encodePacked("")),
            "fundingToken can't be empty"
        );
        require(token.initialSupply > 0, "initialSupply can't be 0");
        require(token.targetPrice > 0, "targetPrice can't be 0");
        require(token.targetSupply > 0, "targetSupply can't be 0");
        require(token.vestingTime >= (30*24*60*60), "vesting time should be longer than 30 days");
        require(token.immediateAllocationPct > 0, "immediateAllocationPct can't be 0");
        require(token.vestedAllocationPct > 0, "vestedAllocationPct can't be 0");
        require(token.taxationPct > 0, "taxationPct can't be 0");
    }

    function deleteCommunityTokenProposal(uint proposalId) internal {
        delete _communityTPs[proposalId];
    }

    function cancelCommunityTokenProposal(CancelProposalRequest calldata cancelProposalRequest) external {
        CommunityTokenProposal memory communityTokenProposal;
        Community memory community;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(cancelProposalRequest.communityId);

        communityTokenProposal = getCommunityTokenProposal(cancelProposalRequest.proposalId);

        uint creationDateDiff = (block.timestamp - communityTokenProposal.date);

        require(
            (communityTokenProposal.proposalCreator == msg.sender) || 
                (creationDateDiff >= community.foundersVotingTime),
            "just proposal creator can cancel proposal"
        );

        deleteCommunityTokenProposal(cancelProposalRequest.proposalId);
    }

    function CreateCommunityToken(CommunityToken calldata token) external {
        checkPropertiesOfToken(token);
        CommunityTokenProposal memory communityTokenProposal;

        Community memory community;
        bool result;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(token.communityId);

        communityTokenProposal.communityId = community.communityAddress;

        for(uint i = 0; i < community.foundersCount; i++) {
            communityTokenProposal.approvals[i].IsVoted = false;
            communityTokenProposal.approvals[i].Vote = false;
        }

        uint founderIndex;
        (founderIndex, result) = IPRIVIDAO(_daoContractAddress).getIdOfFounders(community, msg.sender);
        require(result, "get id of founders failed with error");

        communityTokenProposal.date = block.timestamp;
        communityTokenProposal.proposalCreator = msg.sender;

        if((community.foundersCount == 1) && (community.foundersShares[founderIndex] > 0)) {
            CommunityToken memory communityToken = token;
            communityToken.tokenId = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _communityTokenCounter + 1)));

            updateCommunityToken(communityToken);

            registerToken(communityToken.tokenName, communityToken.tokenSymbol, communityToken.tokenContractAddress);

            community.tokenId = communityToken.tokenId;
            IPRIVIDAO(_daoContractAddress).updateCommunity(community);
            return;
        }
        communityTokenProposal.proposalId = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _communityTPCounter + 1)));
        communityTokenProposal.proposal = token;

        updateCommunityTokenProposal(communityTokenProposal);
    }

    function VoteCommunityTokenProposal(VoteProposal calldata tokenProposalInput) external {
        CommunityTokenProposal memory communityTokenProposal = getCommunityTokenProposal(tokenProposalInput.proposalId);
        
        Community memory community;
        bool result;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(tokenProposalInput.communityId);

        uint founderIndex;
        (founderIndex, result) = IPRIVIDAO(_daoContractAddress).getIdOfFounders(community, msg.sender);
        require(result, "voter has to be an founder of the community");

        require(
            !communityTokenProposal.approvals[founderIndex].IsVoted, 
            "voter can not vote second time"
        );
        require(
            (block.timestamp - communityTokenProposal.date) <= community.foundersVotingTime, 
            "voting time is over"
        );

        communityTokenProposal.approvals[founderIndex].IsVoted = true;
        communityTokenProposal.approvals[founderIndex].Vote = tokenProposalInput.decision;

        // Calculate if consensus already achieved
        uint consensusScoreRequirement = community.foundersConsensus;
        uint consensusScore;
        uint negativeConsensusScore;

        for(uint i = 0; i < community.foundersCount; i++) {
            if(communityTokenProposal.approvals[i].Vote) {
                consensusScore = consensusScore + community.foundersShares[i];
            }
            if(!communityTokenProposal.approvals[i].Vote && communityTokenProposal.approvals[i].IsVoted) {
                negativeConsensusScore = negativeConsensusScore + community.foundersShares[i];
            }
        }
        
        if(consensusScore >= consensusScoreRequirement) {
            uint tokenId = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, communityTokenProposal.proposalId)));
            communityTokenProposal.proposal.tokenId = tokenId;
            updateCommunityToken(communityTokenProposal.proposal);

            registerToken(
                communityTokenProposal.proposal.tokenName, 
                communityTokenProposal.proposal.tokenSymbol, 
                communityTokenProposal.proposal.tokenContractAddress
            );

            community.tokenId = tokenId; 
            IPRIVIDAO(_daoContractAddress).updateCommunity(community);

            deleteCommunityTokenProposal(communityTokenProposal.proposalId);
            return;
        }

        if(negativeConsensusScore >= (10000 - consensusScoreRequirement)) { // *10^4 
            deleteCommunityTokenProposal(communityTokenProposal.proposalId);
            return;
        } 

        updateCommunityTokenProposal(communityTokenProposal);
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

