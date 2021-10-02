// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IPRIVIDAO.sol";
import "./interfaces/IERC20TokenExchange.sol";
import "./interfaces/ICommunityEjectMember.sol";

import "./constant.sol";

contract CommunityBuying {
    mapping(uint => BuyingProposal) _buyingProposals;

    uint[] _buyingProposalIds;
    uint _buyingProposalCount;

    address _daoContractAddress;
    address _ejectMemberContractAddress;

    constructor(address daoContractAddress, address ejectMemberContractAddress) {
        _daoContractAddress = daoContractAddress;
        _ejectMemberContractAddress = ejectMemberContractAddress;
    }

    function getBuyingProposalCount() public view returns(uint) {
        return _buyingProposalCount;
    }

    function getBuyingProposalIds(uint index) public view returns(uint) {
        return _buyingProposalIds[index];
    }

    function getBuyingProposal(uint proposalId) public view returns(BuyingProposal memory) {
        require(
            _buyingProposals[proposalId].proposalId == proposalId, 
            "proposalId is not valid"
        );

        return _buyingProposals[proposalId];
    }

    function updateBuyingProposal(BuyingProposal memory bp) internal {
        Community memory community;
        bool flag = false;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(bp.communityId);

        for(uint i = 0; i < _buyingProposalCount; i++) {
            if(_buyingProposalIds[i] == bp.proposalId) {
                flag = true;
                break;
            }
        }

        if(!flag) {
            _buyingProposalCount++;
            _buyingProposalIds.push(bp.proposalId);
        }

        _buyingProposals[bp.proposalId].proposalId = bp.proposalId;
        _buyingProposals[bp.proposalId].communityId = bp.communityId;
        _buyingProposals[bp.proposalId].proposalCreator = bp.proposalCreator;
        _buyingProposals[bp.proposalId].date = bp.date;
        _buyingProposals[bp.proposalId].proposal.exchangeId = bp.proposal.exchangeId;
        _buyingProposals[bp.proposalId].proposal.offerId = bp.proposal.offerId;

        for(uint i = 0; i < community.foundersCount; i++) {
            _buyingProposals[bp.proposalId].approvals[i].IsVoted = bp.approvals[i].IsVoted;
            _buyingProposals[bp.proposalId].approvals[i].Vote = bp.approvals[i].Vote;
        }
    }

    function deleteBuyingProposal(uint proposalId) internal {
        delete _buyingProposals[proposalId];
    }

    function cancelBuyingProposal(CancelProposalRequest calldata cancelProposalRequest) external {
        BuyingProposal memory buyingProposal;
        Community memory community;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(cancelProposalRequest.communityId);

        buyingProposal = getBuyingProposal(cancelProposalRequest.proposalId);

        uint creationDateDiff = (block.timestamp - buyingProposal.date);

        require(
            (buyingProposal.proposalCreator == msg.sender) || 
                (creationDateDiff >= community.foundersVotingTime),
            "just proposal creator can cancel proposal"
        );

        IERC20TokenExchange.ERC20Offer memory offer;
        address exchangeContractAddress = IPRIVIDAO(_daoContractAddress).getExchangeContractAddress();
        offer = IERC20TokenExchange(exchangeContractAddress).getErc20OfferById(buyingProposal.proposal.offerId);

        IERC20TokenExchange.ERC20Exchange memory exchange;
        exchange = IERC20TokenExchange(exchangeContractAddress).getErc20ExchangeById(offer.exchangeId);

        IERC20(exchange.offerTokenAddress)
            .transferFrom(community.escrowAddress, community.communityAddress, offer.amount);

        deleteBuyingProposal(cancelProposalRequest.proposalId);
    }

    function MakeBuyingProposal(BuyingProposalRequest calldata buyingProposalRequest) external {
        require(buyingProposalRequest.price > 0, "price cannot be zero");
        require(buyingProposalRequest.amount > 0, "amount cannot be zero");

        Community memory community;
        bool result;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(buyingProposalRequest.communityId);

        uint founderIndex;
        (founderIndex, result) = IPRIVIDAO(_daoContractAddress).getIdOfFounders(community, msg.sender);
        {
            bool treasurerFlag;
            bool memberFlag;

            Member[] memory treasurers;
            uint treasurerCount;

            (treasurers, treasurerCount) = ICommunityEjectMember(_ejectMemberContractAddress).getMembersByType(community.communityAddress, TreasurerMemberType);
            for(uint i = 0; i < treasurerCount; i++) {
                if(treasurers[i].memberAddress == msg.sender) {
                    treasurerFlag = true;
                    break;
                }
            }
            
            Member[] memory members;
            uint memberCount;

            (members, memberCount)= ICommunityEjectMember(_ejectMemberContractAddress).getMembers(community.communityAddress);
            for(uint i = 0; i < memberCount; i++) {
                if(members[i].memberAddress == msg.sender) {
                    memberFlag == true;
                    break;
                }
            }

            require(
                (result) || (treasurerFlag) || (memberFlag),
                "just community members can create buying proposal."
            );
        }

        address exchangeContractAddress = IPRIVIDAO(_daoContractAddress).getExchangeContractAddress();

        require(exchangeContractAddress != address(0), "should be set exchange contract address");

        IERC20TokenExchange.ERC20Exchange memory exchange;
        IERC20TokenExchange.ERC20Offer memory offer;

        exchange = IERC20TokenExchange(exchangeContractAddress).getErc20ExchangeById(buyingProposalRequest.exchangeId);
        offer = IERC20TokenExchange(exchangeContractAddress).getErc20OfferById(buyingProposalRequest.offerId);

        require(
            keccak256(abi.encodePacked(offer.offerType)) == keccak256(abi.encodePacked("SELL")), 
            "trying to buy from a non selling order"
        );
        require(
            exchange.offerTokenAddress == buyingProposalRequest.offerTokenAddress, 
            "incorrect offer token"
        );

        uint balance = IERC20(buyingProposalRequest.offerTokenAddress).balanceOf(community.communityAddress);
        require(balance >=  buyingProposalRequest.amount, "insufficient founds");
        
        uint buyingProposalRequestAmount = buyingProposalRequest.amount;
        IERC20(exchange.offerTokenAddress).transferFrom(community.communityAddress, community.escrowAddress, buyingProposalRequestAmount);

        IERC20TokenExchange.OfferRequest memory offerRequest;
        offerRequest.exchangeId = buyingProposalRequest.exchangeId;
        offerRequest.offerId = buyingProposalRequest.offerId;

        BuyingProposal memory buyingProposal;
        buyingProposal.proposalId = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _buyingProposalCount + 1)));
        buyingProposal.communityId = buyingProposalRequest.communityId;
        buyingProposal.proposalCreator = msg.sender;
        buyingProposal.proposal = offerRequest;
        buyingProposal.date = block.timestamp;

        for(uint i = 0; i < community.foundersCount; i++) {
            buyingProposal.approvals[i].IsVoted = false;
            buyingProposal.approvals[i].Vote = false;
        }

        if(community.foundersCount == 1) {
            IERC20TokenExchange(exchangeContractAddress)
                .BuyERC20TokenFromOffer(buyingProposal.proposal, buyingProposal.proposalCreator);
            return;
        }

        updateBuyingProposal(buyingProposal);
    }

    function VoteBuyingProposal(VoteProposal calldata voteProposal) external {
        BuyingProposal memory buyingProposal;
        Community memory community;
        bool result;

        buyingProposal = getBuyingProposal(voteProposal.proposalId);

        community =  IPRIVIDAO(_daoContractAddress).getCommunity(buyingProposal.communityId);

        uint founderIndex;
        (founderIndex, result) = IPRIVIDAO(_daoContractAddress).getIdOfFounders(community, msg.sender);
        require(result, "just founders can vote on buying order proposal.");
        require(!buyingProposal.approvals[founderIndex].IsVoted, "voter can not vote second time");

        IERC20TokenExchange.ERC20Exchange memory exchange;
        IERC20TokenExchange.ERC20Offer memory offer;

        address exchangeContractAddress = IPRIVIDAO(_daoContractAddress).getExchangeContractAddress();

        exchange = IERC20TokenExchange(exchangeContractAddress).getErc20ExchangeById(buyingProposal.proposal.exchangeId);
        offer = IERC20TokenExchange(exchangeContractAddress).getErc20OfferById(buyingProposal.proposal.offerId);

        uint balance = IERC20(exchange.offerTokenAddress).balanceOf(community.escrowAddress);
        require(balance >= offer.amount, "insufficient founds");

        uint creationDateDiff = (block.timestamp - buyingProposal.date);
        require(creationDateDiff <= community.foundersVotingTime, "voting time is over");

        buyingProposal.approvals[founderIndex].IsVoted = true;
        buyingProposal.approvals[founderIndex].Vote = voteProposal.decision;

        uint consensusScoreRequirement = community.foundersConsensus;
        uint consensusScore;
        uint negativeConsensusScore;

        for(uint i = 0; i < community.foundersCount; i++) {
            if(buyingProposal.approvals[i].Vote) {
                consensusScore += community.foundersShares[i];
            }

            if(!buyingProposal.approvals[i].Vote && buyingProposal.approvals[i].IsVoted) {
                negativeConsensusScore += community.foundersShares[i];
            }
        }

        if(consensusScore >= consensusScoreRequirement) {
            IERC20TokenExchange(exchangeContractAddress)
                .BuyERC20TokenFromOffer(buyingProposal.proposal, buyingProposal.proposalCreator);
            deleteBuyingProposal(buyingProposal.proposalId);
            return;
        }

        if(negativeConsensusScore > (10000 - consensusScoreRequirement)) { // *10^4
            deleteBuyingProposal(buyingProposal.proposalId);
            require(
                keccak256(abi.encodePacked(offer.offerType)) == keccak256(abi.encodePacked("SELL")), 
                "trying to buy from a non selling order"
            );

            IERC20(exchange.offerTokenAddress).transferFrom(community.escrowAddress, community.communityAddress, offer.amount);
            return;
        }

        updateBuyingProposal(buyingProposal);
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