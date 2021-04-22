// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

// Interfaces
import "./interfaces/iERC20.sol";
import "./interfaces/iUTILS.sol";
import "./interfaces/iVADER.sol";
import "./interfaces/iUSDV.sol";
import "./interfaces/iROUTER.sol";

    //======================================VADER=========================================//
contract DAO {

    struct GrantDetails{
        address recipient;
        uint amount;
    }

    bool private inited;
    uint public proposalCount;
    address public VADER;
    address public USDV;
    uint public coolOffPeriod;

    mapping(uint => GrantDetails) public mapPID_grant;
    mapping(uint => address) public mapPID_address;

    mapping(uint => string) public mapPID_type;
    mapping(uint => uint) public mapPID_votes;
    mapping(uint => uint) public mapPID_timeStart;
    mapping(uint => bool) public mapPID_finalising;
    mapping(uint => bool) public mapPID_finalised;
    mapping(uint => mapping(address => uint)) public mapPIDMember_votes;

    event NewProposal(address indexed member, uint indexed proposalID, string proposalType);
    event NewVote(address indexed member, uint indexed proposalID, uint voteWeight, uint totalVotes, string proposalType);
    event ProposalFinalising(address indexed member,uint indexed proposalID, uint timeFinalised, string proposalType);
    event CancelProposal(address indexed member, uint indexed oldProposalID, uint oldVotes, uint newVotes, uint totalWeight);
    event FinalisedProposal(address indexed member,uint indexed proposalID, uint votesCast, uint totalWeight, string proposalType);

    //=====================================CREATION=========================================//
    // Constructor
    constructor() {
    }
    function init(address _vader, address _usdv) public {
        require(inited == false);
        inited = true;
        VADER = _vader;
        USDV = _usdv;
        coolOffPeriod = 1;
    }

    //============================== CREATE PROPOSALS ================================//
    // Action with funding
    function newGrantProposal(address recipient, uint amount) public {
        string memory typeStr = "GRANT";
        proposalCount += 1;
        mapPID_type[proposalCount] = typeStr;
        GrantDetails memory grant;
        grant.recipient = recipient;
        grant.amount = amount;
        mapPID_grant[proposalCount] = grant;
        emit NewProposal(msg.sender, proposalCount, typeStr);
    }

    // Action with address parameter
    function newAddressProposal(address proposedAddress, string memory typeStr) public {
        proposalCount += 1;
        mapPID_address[proposalCount] = proposedAddress;
        mapPID_type[proposalCount] = typeStr;
        emit NewProposal(msg.sender, proposalCount, typeStr);
    }

//============================== VOTE && FINALISE ================================//

    // Vote for a proposal
    function voteProposal(uint proposalID) public returns (uint voteWeight) {
        bytes memory _type = bytes(mapPID_type[proposalID]);
        voteWeight = countMemberVotes(proposalID);
        if(hasQuorum(proposalID) && mapPID_finalising[proposalID] == false){
            if(isEqual(_type, 'DAO') || isEqual(_type, 'UTILS') || isEqual(_type, 'REWARD')){
                if(hasMajority(proposalID)){
                    _finalise(proposalID);
                }
            } else {
                _finalise(proposalID);
            }
        }
        emit NewVote(msg.sender, proposalID, voteWeight, mapPID_votes[proposalID], string(_type));
    }

    function _finalise(uint _proposalID) internal {
        bytes memory _type = bytes(mapPID_type[_proposalID]);
        mapPID_finalising[_proposalID] = true;
        mapPID_timeStart[_proposalID] = block.timestamp;
        emit ProposalFinalising(msg.sender, _proposalID, block.timestamp+coolOffPeriod, string(_type));
    }

    // If an existing proposal, allow a minority to cancel
    function cancelProposal(uint oldProposalID, uint newProposalID) public {
        require(mapPID_finalising[oldProposalID], "Must be finalising");
        require(hasMinority(newProposalID), "Must have minority");
        require(isEqual(bytes(mapPID_type[oldProposalID]), bytes(mapPID_type[newProposalID])), "Must be same");
        mapPID_votes[oldProposalID] = 0;
        emit CancelProposal(msg.sender, oldProposalID, mapPID_votes[oldProposalID], mapPID_votes[newProposalID], iUSDV(USDV).totalWeight());
    }

    // Proposal with quorum can finalise after cool off period
    function finaliseProposal(uint proposalID) public  {
        require((block.timestamp - mapPID_timeStart[proposalID]) > coolOffPeriod, "Must be after cool off");
        require(mapPID_finalising[proposalID] == true, "Must be finalising");
        if(!hasQuorum(proposalID)){
            _finalise(proposalID);
        }
        bytes memory _type = bytes(mapPID_type[proposalID]);
        if (isEqual(_type, 'GRANT')){
            grantFunds(proposalID);
        } else if (isEqual(_type, 'UTILS')){
            moveUtils(proposalID);
        } else if (isEqual(_type, 'REWARD')){
            moveRewardAddress(proposalID);
        }
    }

    function completeProposal(uint _proposalID) internal {
        string memory _typeStr = mapPID_type[_proposalID];
        emit FinalisedProposal(msg.sender, _proposalID, mapPID_votes[_proposalID], iUSDV(USDV).totalWeight(), _typeStr);
        mapPID_votes[_proposalID] = 0;
        mapPID_finalised[_proposalID] = true;
        mapPID_finalising[_proposalID] = false;
    }

//============================== BUSINESS LOGIC ================================//

    function grantFunds(uint _proposalID) internal {
        GrantDetails memory _grant = mapPID_grant[_proposalID];
        require(_grant.amount <= iERC20(USDV).balanceOf(USDV), "Not more than balance");
        completeProposal(_proposalID);
        iUSDV(USDV).grant(_grant.recipient, _grant.amount);
    }
    function moveUtils(uint _proposalID) internal {
        address _proposedAddress = mapPID_address[_proposalID];
        require(_proposedAddress != address(0), "No address proposed");
        iVADER(VADER).changeUTILS(_proposedAddress);
        completeProposal(_proposalID);
    }
    function moveRewardAddress(uint _proposalID) internal {
        address _proposedAddress = mapPID_address[_proposalID];
        require(_proposedAddress != address(0), "No address proposed");
        iVADER(VADER).setRewardAddress(_proposedAddress);
        completeProposal(_proposalID);
    }
//============================== CONSENSUS ================================//

    function countMemberVotes(uint _proposalID) internal returns (uint voteWeight){
        mapPID_votes[_proposalID] -= mapPIDMember_votes[_proposalID][msg.sender];
        voteWeight = iUSDV(USDV).getMemberWeight(msg.sender);
        mapPID_votes[_proposalID] += voteWeight;
        mapPIDMember_votes[_proposalID][msg.sender] = voteWeight;
    }

    function hasMajority(uint _proposalID) public view returns(bool){
        uint votes = mapPID_votes[_proposalID];
        uint consensus = iUSDV(USDV).totalWeight() / 2; // >50%
        if(votes > consensus){
            return true;
        } else {
            return false;
        }
    }
    function hasQuorum(uint _proposalID) public view returns(bool){
        uint votes = mapPID_votes[_proposalID];
        uint consensus = iUSDV(USDV).totalWeight() / 3; // >33%
        if(votes > consensus){
            return true;
        } else {
            return false;
        }
    }
    function hasMinority(uint _proposalID) public view returns(bool){
        uint votes = mapPID_votes[_proposalID];
        uint consensus = iUSDV(USDV).totalWeight() / 6; // >16%
        if(votes > consensus){
            return true;
        } else {
            return false;
        }
    }
    function isEqual(bytes memory part1, bytes memory part2) public pure returns(bool){
        if(sha256(part1) == sha256(part2)){
            return true;
        } else {
            return false;
        }
    }
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function transferTo(address, uint) external returns (bool);
    function burn(uint) external;
    function burnFrom(address, uint) external;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iROUTER {
    function setParams(uint newFactor, uint newTime, uint newLimit) external;
    function addLiquidity(address base, uint inputBase, address token, uint inputToken) external returns(uint);
    function removeLiquidity(address base, address token, uint basisPoints) external returns (uint amountBase, uint amountToken);
    function swap(uint inputAmount, address inputToken, address outputToken) external returns (uint outputAmount);
    function swapWithLimit(uint inputAmount, address inputToken, address outputToken, uint slipLimit) external returns (uint outputAmount);
    function swapWithSynths(uint inputAmount, address inputToken, bool inSynth, address outputToken, bool outSynth) external returns (uint outputAmount);
    function swapWithSynthsWithLimit(uint inputAmount, address inputToken, bool inSynth, address outputToken, bool outSynth, uint slipLimit) external returns (uint outputAmount);
    
    function getILProtection(address member, address base, address token, uint basisPoints) external view returns(uint protection);
    
    function curatePool(address token) external;
    function listAnchor(address token) external;
    function replacePool(address oldToken, address newToken) external;
    function updateAnchorPrice(address token) external;
    function getAnchorPrice() external view returns (uint anchorPrice);
    function getVADERAmount(uint USDVAmount) external view returns (uint vaderAmount);
    function getUSDVAmount(uint vaderAmount) external view returns (uint USDVAmount);
    function isCurated(address token) external view returns(bool curated);

    function reserveUSDV() external view returns(uint);
    function reserveVADER() external view returns(uint);

    function getMemberBaseDeposit(address member, address token) external view returns(uint);
    function getMemberTokenDeposit(address member, address token) external view returns(uint);
    function getMemberLastDeposit(address member, address token) external view returns(uint);
    function getMemberCollateral(address member, address collateralAsset, address debtAsset) external view returns(uint);
    function getMemberDebt(address member, address collateralAsset, address debtAsset) external view returns(uint);
    function getSystemCollateral(address collateralAsset, address debtAsset) external view returns(uint);
    function getSystemDebt(address collateralAsset, address debtAsset) external view returns(uint);
    function getSystemInterestPaid(address collateralAsset, address debtAsset) external view returns(uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iUSDV {
    function ROUTER() external view returns (address);
    function totalWeight() external view returns(uint);
    function totalRewards() external view returns(uint);
    function isMature() external view returns (bool);
    function setParams(uint newEra, uint newDepositTime, uint newDelay, uint newGrantTime) external;
    function grant(address recipient, uint amount) external;
    function convert(uint amount) external returns(uint convertAmount);
    function convertForMember(address member, uint amount) external returns(uint convertAmount);
    function redeem(uint amount) external returns(uint redeemAmount);
    function redeemForMember(address member, uint amount) external returns(uint redeemAmount);
    function deposit(address token, uint amount) external;
    function depositForMember(address token, address member, uint amount) external;
    function harvest(address token) external returns(uint reward);
    function calcCurrentReward(address token, address member) external view returns(uint reward);
    function calcReward(address member) external view returns(uint);
    function withdraw(address token, uint basisPoints) external returns(uint redeemedAmount);
    function reserveUSDV() external view returns(uint);
    function getTokenDeposits(address token) external view returns(uint);
    function getMemberReward(address token, address member) external view returns(uint);
    function getMemberWeight(address member) external view returns(uint);
    function getMemberDeposit(address token, address member) external view returns(uint);
    function getMemberLastTime(address token, address member) external view returns(uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iUTILS {
    function getFeeOnTransfer(uint totalSupply, uint maxSupply) external pure returns (uint);
    function assetChecks(address collateralAsset, address debtAsset) external;
    function isBase(address token) external view returns(bool base);

    function calcValueInBase(address token, uint amount) external view returns (uint);
    function calcValueInToken(address token, uint amount) external view returns (uint);
    function calcValueOfTokenInToken(address token1, uint amount, address token2) external view returns (uint);
    function calcSwapValueInBase(address token, uint amount) external view returns (uint);
    function calcSwapValueInToken(address token, uint amount) external view returns (uint);
    function requirePriceBounds(address token, uint bound, bool inside, uint targetPrice) external view;

    function getRewardShare(address token, uint rewardReductionFactor) external view returns (uint rewardShare);
    function getReducedShare(uint amount) external view returns(uint);

    function getProtection(address member, address token, uint basisPoints, uint timeForFullProtection) external view returns(uint protection);
    function getCoverage(address member, address token) external view returns (uint);
    
    function getCollateralValueInBase(address member, uint collateral, address collateralAsset, address debtAsset) external returns (uint debt, uint baseValue);
    function getDebtValueInCollateral(address member, uint debt, address collateralAsset, address debtAsset) external view returns(uint, uint);
    function getInterestOwed(address collateralAsset, address debtAsset, uint timeElapsed) external returns(uint interestOwed);
    function getInterestPayment(address collateralAsset, address debtAsset) external view returns(uint);
    function getDebtLoading(address collateralAsset, address debtAsset) external view returns(uint);

    function calcPart(uint bp, uint total) external pure returns (uint);
    function calcShare(uint part, uint total, uint amount) external pure returns (uint);
    function calcSwapOutput(uint x, uint X, uint Y) external pure returns (uint);
    function calcSwapFee(uint x, uint X, uint Y) external pure returns (uint);
    function calcSwapSlip(uint x, uint X) external pure returns (uint);
    function calcLiquidityUnits(uint b, uint B, uint t, uint T, uint P) external view returns (uint);
    function getSlipAdustment(uint b, uint B, uint t, uint T) external view returns (uint);
    function calcSynthUnits(uint b, uint B, uint P) external view returns (uint);
    function calcAsymmetricShare(uint u, uint U, uint A) external pure returns (uint);
    function calcCoverage(uint B0, uint T0, uint B1, uint T1) external pure returns(uint);
    function sortArray(uint[] memory array) external pure returns (uint[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iVADER {
    function UTILS() external view returns (address);
    function DAO() external view returns (address);
    function emitting() external view returns (bool);
    function minting() external view returns (bool);
    function secondsPerEra() external view returns (uint);
    function flipEmissions() external;
    function flipMinting() external;
    function setParams(uint newEra, uint newCurve) external;
    function setRewardAddress(address newAddress) external;
    function changeUTILS(address newUTILS) external;
    function changeDAO(address newDAO) external;
    function purgeDAO() external;
    function upgrade(uint amount) external;
    function redeem() external returns (uint);
    function redeemToMember(address member) external returns (uint);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
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