// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IPRIVIDAO.sol";
import "./interfaces/IManageCommunityToken.sol";

import "./constant.sol";

contract CommunityAirdrop {
    mapping(uint => AirdropProposal) _airdropProposals;
    uint _airdropProposalCount;

    uint[] _airdropProposalIds;

    address _daoContractAddress;
    address _manageCommunityTokenContractAddress;

    constructor(address daoContractAddress, address manageCommunityTokenContractAddress) {
        _daoContractAddress = daoContractAddress;
        _manageCommunityTokenContractAddress = manageCommunityTokenContractAddress;
    }

    function getAirdropProposalCount() public view returns(uint) {
        return _airdropProposalCount;
    }

    function getAirdropProposalIds(uint index) public view returns(uint) {
        return _airdropProposalIds[index];
    }

    function getAirdropProposal(uint proposalId) public view returns(AirdropProposal memory) {
        require(
            _airdropProposals[proposalId].proposalId == proposalId, 
            "proposalId is not valid"
        );

        return _airdropProposals[proposalId];
    }

    function getAirdropSum(Airdrop memory airdrop) public pure returns(address[] memory, uint) {
        address[] memory receipments = new address[](airdrop.recipientCount);
        uint airdropSum = 0;
        for(uint i = 0; i < airdrop.recipientCount; i++) {
            receipments[i] = airdrop.recipients[i];
            airdropSum += airdrop.amounts[i];
        }
        return (receipments, airdropSum);
    }

    function checkPropertiesOfAirdrop(Airdrop memory airdrop) internal view {
        require(airdrop.communityId != address(0), "communityId has to be defined");
        require(airdrop.recipientCount != 0, "recipients cant be empty");
        for(uint i = 0; i < airdrop.recipientCount; i++) {
            require(
                airdrop.amounts[i] != 0, 
                "amount of airdrop per address has to be positive number"
            );
        }

        Community memory community;
        community = IPRIVIDAO(_daoContractAddress).getCommunity(airdrop.communityId);

        require(community.communityAddress != address(0), "community does not exist");

        uint airdropSum;
        (,airdropSum) = getAirdropSum(airdrop);
        
        CommunityToken memory communityToken;
        communityToken = IManageCommunityToken(_manageCommunityTokenContractAddress).getCommunityToken(community.tokenId);

        require(
            (communityToken.initialSupply - communityToken.allocationAmount - communityToken.airdropAmount) >= airdropSum,
            "not enough tokens to propose this airdrop"
        );
    }

    function updateCommunityTokenWithNewAirdropSum(uint tokenId, AirdropProposal memory airdropProposal, bool isAddition) public 
        returns(CommunityToken memory) {
        CommunityToken memory communityToken;
        uint airdropSum;

        communityToken = IManageCommunityToken(_manageCommunityTokenContractAddress).getCommunityToken(tokenId);
                
        (,airdropSum) = getAirdropSum(airdropProposal.proposal);
        
        if(isAddition) {
            communityToken.airdropAmount += airdropSum;
        } else {
            communityToken.airdropAmount -= airdropSum;
        }

        IManageCommunityToken(_manageCommunityTokenContractAddress).updateCommunityToken(communityToken);
        return communityToken;
    }

    function updateAirdropProposal(AirdropProposal memory airdropProposal) internal {
        bool flag = false;

        for(uint i = 0; i < _airdropProposalCount; i++) {
            if(_airdropProposalIds[i] == airdropProposal.proposalId) {
                flag = true;
            }
        }

        if(!flag) {
            _airdropProposalCount++;
            _airdropProposalIds.push(airdropProposal.proposalId);
        }

        _airdropProposals[airdropProposal.proposalId].proposalId = airdropProposal.proposalId;
        _airdropProposals[airdropProposal.proposalId].communityId = airdropProposal.communityId;
        _airdropProposals[airdropProposal.proposalId].proposalCreator = airdropProposal.proposalCreator;
        _airdropProposals[airdropProposal.proposalId].proposal = airdropProposal.proposal;
        _airdropProposals[airdropProposal.proposalId].date = airdropProposal.date;

        for(uint j = 0; j < 20; j++) {
            _airdropProposals[airdropProposal.proposalId].approvals[j].IsVoted = airdropProposal.approvals[j].IsVoted;
            _airdropProposals[airdropProposal.proposalId].approvals[j].Vote = airdropProposal.approvals[j].Vote;
        }
    }

    function deleteAirdropProposal(uint proposalId) internal {
        delete _airdropProposals[proposalId]; 
    }

    function cancelAirdropProposal(CancelProposalRequest calldata cancelProposalRequest) external {
        AirdropProposal memory airdropProposal;
        Community memory community;
        bool result;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(cancelProposalRequest.communityId);

        airdropProposal = getAirdropProposal(cancelProposalRequest.proposalId);

        uint creationDateDiff = (block.timestamp - airdropProposal.date);

        require(
            (airdropProposal.proposalCreator == msg.sender) || 
                (creationDateDiff >= community.foundersVotingTime),
            "just proposal creator can cancel proposal"
        );

        CommunityToken memory communityToken;
        communityToken  = updateCommunityTokenWithNewAirdropSum(community.tokenId, airdropProposal, false);

        uint airdropSum;
        (, airdropSum) = getAirdropSum(airdropProposal.proposal);

        address tokenContractAddress;

        (tokenContractAddress, result) = IManageCommunityToken(_manageCommunityTokenContractAddress)
            .getTokenContractAddress(communityToken.tokenSymbol);
        require(result, "token contract address is not valid");
        
        IERC20(tokenContractAddress).transferFrom(community.escrowAddress, community.communityAddress, airdropSum);
        deleteAirdropProposal(cancelProposalRequest.proposalId);
    }

    function performAirdrop(Community memory community, Airdrop memory airdrop, bool withEscrowTransfer) internal {
        CommunityToken memory airdropToken;
        bool result;

        airdropToken = IManageCommunityToken(_manageCommunityTokenContractAddress).getCommunityToken(community.tokenId);

        uint airdropSum = 0;
        address tokenContractAddress;

        (tokenContractAddress, result) = IManageCommunityToken(_manageCommunityTokenContractAddress)
            .getTokenContractAddress(airdropToken.tokenSymbol);
        require(result, "token contract address is not valid");

        for(uint i = 0; i < airdrop.recipientCount; i++) {
            IERC20(tokenContractAddress).transferFrom(community.escrowAddress, airdrop.recipients[i], airdrop.amounts[i]);
            airdropSum += airdrop.amounts[i];
        }

        if(withEscrowTransfer) {
            IERC20(tokenContractAddress).transferFrom(community.communityAddress, community.escrowAddress, airdropSum);
        }
    }

    function transferAirdropTokensToEscrow(Airdrop memory airdrop, Community memory community) internal {
        CommunityToken memory airdropToken;
        address tokenContractAddress;
        uint airdropAmount = 0;
        bool result;
        
        airdropToken = IManageCommunityToken(_manageCommunityTokenContractAddress).getCommunityToken(community.tokenId);

        (tokenContractAddress, result) = IManageCommunityToken(_manageCommunityTokenContractAddress)
            .getTokenContractAddress(airdropToken.tokenSymbol);
        require(result, "token contract address is not valid");

        for(uint i = 0; i < airdrop.recipientCount; i++) {
            airdropAmount += airdrop.amounts[i];
        }

        IERC20(tokenContractAddress).transferFrom(community.communityAddress, community.escrowAddress, airdropAmount);
    }

    function AirdropCommunityToken(Airdrop calldata airdrop) external{
        checkPropertiesOfAirdrop(airdrop);

        AirdropProposal memory airdropProposal;

        Community memory community;

        community = IPRIVIDAO(_daoContractAddress).getCommunity(airdrop.communityId);

        uint founderIndex;
        bool result;
        (founderIndex, result) = IPRIVIDAO(_daoContractAddress).getIdOfFounders(community, msg.sender);
        require(result, "airdrop creator should be founder");

        for(uint i = 0; i < community.foundersCount; i++) {
            airdropProposal.approvals[i].IsVoted = false;
            airdropProposal.approvals[i].Vote = false;
        }

        airdropProposal.date = block.timestamp;
        airdropProposal.proposal = airdrop;

        if((community.foundersCount == 1) && (community.foundersShares[founderIndex] > 0)) {
            performAirdrop(community, airdrop, true);
            updateCommunityTokenWithNewAirdropSum(community.tokenId, airdropProposal, true);
            return;
        }

        airdropProposal.proposalId = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _airdropProposalCount + 1)));
        airdropProposal.communityId = community.communityAddress;
        airdropProposal.proposalCreator = msg.sender;

        CommunityToken memory communityToken;

        communityToken = updateCommunityTokenWithNewAirdropSum(community.tokenId, airdropProposal, true);

        updateAirdropProposal(airdropProposal);

        transferAirdropTokensToEscrow(airdrop, community);
    }    

    function VoteAirdropProposal(VoteProposal calldata voteAirdropInput) external {
        require(voteAirdropInput.proposalId != 0, "proposalId cannot be empty");
        require(voteAirdropInput.communityId != address(0), "communityId cannot be empty");

        AirdropProposal memory airdropProposal;
        Community memory community;
        bool result;

        airdropProposal = getAirdropProposal(voteAirdropInput.proposalId);

        community = IPRIVIDAO(_daoContractAddress).getCommunity(voteAirdropInput.communityId);

        uint founderIndex;
        (founderIndex, result) = IPRIVIDAO(_daoContractAddress).getIdOfFounders(community, msg.sender);
        
        require(result, "only founders can vote");
        require(!airdropProposal.approvals[founderIndex].IsVoted, "voter can not vote second time");

        uint creationDateDiff = (block.timestamp - airdropProposal.date);
        
        require(creationDateDiff <= community.foundersVotingTime, "voting time is over");
        
        airdropProposal.approvals[founderIndex].IsVoted = true;
        airdropProposal.approvals[founderIndex].Vote = voteAirdropInput.decision;

        uint consensusScoreRequirement = community.foundersConsensus;
        uint consensusScore;
        uint negativeConsensusScore;

        for(uint i = 0; i < community.foundersCount; i++) {
            if(airdropProposal.approvals[i].Vote) {
                consensusScore += community.foundersShares[i];
            }

            if(!airdropProposal.approvals[i].Vote && airdropProposal.approvals[i].IsVoted) {
                negativeConsensusScore += community.foundersShares[i];
            }
        }

        if(consensusScore >= consensusScoreRequirement) {
            performAirdrop(community, airdropProposal.proposal, false);
            deleteAirdropProposal(airdropProposal.proposalId);
            return;
        }

        if(negativeConsensusScore >= (10000 - consensusScoreRequirement)) { // *10^4
            deleteAirdropProposal(airdropProposal.proposalId);
            CommunityToken memory airdropToken;
            airdropToken = updateCommunityTokenWithNewAirdropSum(community.tokenId, airdropProposal, false);
            
            uint airdropSum;
            (, airdropSum) = getAirdropSum(airdropProposal.proposal);

            address tokenContractAddress;
            (tokenContractAddress, result) = IManageCommunityToken(_manageCommunityTokenContractAddress)
                .getTokenContractAddress(airdropToken.tokenSymbol);
            require(result, "token contract address is not valid");

            IERC20(tokenContractAddress).transferFrom(community.escrowAddress, community.communityAddress, airdropSum);
            return;
        }

        updateAirdropProposal(airdropProposal);
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