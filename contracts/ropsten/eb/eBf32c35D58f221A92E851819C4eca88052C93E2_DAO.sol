// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

// Interfaces
import "./interfaces/iERC20.sol";
import "./interfaces/iUTILS.sol";
import "./interfaces/iVADER.sol";
import "./interfaces/iVAULT.sol";
import "./interfaces/iROUTER.sol";

//======================================VADER=========================================//
contract DAO {
    struct GrantDetails {
        address recipient;
        uint256 amount;
    }

    bool private inited;
    uint256 public proposalCount;
    address public VADER;
    address public USDV;
    address public VAULT;
    uint256 public coolOffPeriod;

    mapping(uint256 => GrantDetails) public mapPID_grant;
    mapping(uint256 => address) public mapPID_address;

    mapping(uint256 => string) public mapPID_type;
    mapping(uint256 => uint256) public mapPID_votes;
    mapping(uint256 => uint256) public mapPID_timeStart;
    mapping(uint256 => bool) public mapPID_finalising;
    mapping(uint256 => bool) public mapPID_finalised;
    mapping(uint256 => mapping(address => uint256)) public mapPIDMember_votes;

    event NewProposal(address indexed member, uint256 indexed proposalID, string proposalType);
    event NewVote(
        address indexed member,
        uint256 indexed proposalID,
        uint256 voteWeight,
        uint256 totalVotes,
        string proposalType
    );
    event ProposalFinalising(
        address indexed member,
        uint256 indexed proposalID,
        uint256 timeFinalised,
        string proposalType
    );
    event CancelProposal(
        address indexed member,
        uint256 indexed oldProposalID,
        uint256 oldVotes,
        uint256 newVotes,
        uint256 totalWeight
    );
    event FinalisedProposal(
        address indexed member,
        uint256 indexed proposalID,
        uint256 votesCast,
        uint256 totalWeight,
        string proposalType
    );

    //=====================================CREATION=========================================//
    // Constructor
    constructor() {}

    function init(
        address _vader,
        address _usdv,
        address _vault
    ) public {
        require(inited == false);
        inited = true;
        VADER = _vader;
        USDV = _usdv;
        VAULT = _vault;
        coolOffPeriod = 1;
    }

    //============================== CREATE PROPOSALS ================================//
    // Action with funding
    function newGrantProposal(address recipient, uint256 amount) public {
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
    function voteProposal(uint256 proposalID) public returns (uint256 voteWeight) {
        bytes memory _type = bytes(mapPID_type[proposalID]);
        voteWeight = countMemberVotes(proposalID);
        if (hasQuorum(proposalID) && mapPID_finalising[proposalID] == false) {
            if (isEqual(_type, "DAO") || isEqual(_type, "UTILS") || isEqual(_type, "REWARD")) {
                if (hasMajority(proposalID)) {
                    _finalise(proposalID);
                }
            } else {
                _finalise(proposalID);
            }
        }
        emit NewVote(msg.sender, proposalID, voteWeight, mapPID_votes[proposalID], string(_type));
    }

    function _finalise(uint256 _proposalID) internal {
        bytes memory _type = bytes(mapPID_type[_proposalID]);
        mapPID_finalising[_proposalID] = true;
        mapPID_timeStart[_proposalID] = block.timestamp;
        emit ProposalFinalising(msg.sender, _proposalID, block.timestamp + coolOffPeriod, string(_type));
    }

    // If an existing proposal, allow a minority to cancel
    function cancelProposal(uint256 oldProposalID, uint256 newProposalID) public {
        require(mapPID_finalising[oldProposalID], "Must be finalising");
        require(hasMinority(newProposalID), "Must have minority");
        require(isEqual(bytes(mapPID_type[oldProposalID]), bytes(mapPID_type[newProposalID])), "Must be same");
        mapPID_votes[oldProposalID] = 0;
        emit CancelProposal(
            msg.sender,
            oldProposalID,
            mapPID_votes[oldProposalID],
            mapPID_votes[newProposalID],
            iVAULT(VAULT).totalWeight()
        );
    }

    // Proposal with quorum can finalise after cool off period
    function finaliseProposal(uint256 proposalID) public {
        require((block.timestamp - mapPID_timeStart[proposalID]) > coolOffPeriod, "Must be after cool off");
        require(mapPID_finalising[proposalID] == true, "Must be finalising");
        if (!hasQuorum(proposalID)) {
            _finalise(proposalID);
        }
        bytes memory _type = bytes(mapPID_type[proposalID]);
        if (isEqual(_type, "GRANT")) {
            grantFunds(proposalID);
        } else if (isEqual(_type, "UTILS")) {
            moveUtils(proposalID);
        } else if (isEqual(_type, "REWARD")) {
            moveRewardAddress(proposalID);
        }
    }

    function completeProposal(uint256 _proposalID) internal {
        string memory _typeStr = mapPID_type[_proposalID];
        emit FinalisedProposal(
            msg.sender,
            _proposalID,
            mapPID_votes[_proposalID],
            iVAULT(VAULT).totalWeight(),
            _typeStr
        );
        mapPID_votes[_proposalID] = 0;
        mapPID_finalised[_proposalID] = true;
        mapPID_finalising[_proposalID] = false;
    }

    //============================== BUSINESS LOGIC ================================//

    function grantFunds(uint256 _proposalID) internal {
        GrantDetails memory _grant = mapPID_grant[_proposalID];
        require(_grant.amount <= iERC20(USDV).balanceOf(VAULT) / 10, "Not more than 10%");
        completeProposal(_proposalID);
        iVAULT(VAULT).grant(_grant.recipient, _grant.amount);
    }

    function moveUtils(uint256 _proposalID) internal {
        address _proposedAddress = mapPID_address[_proposalID];
        require(_proposedAddress != address(0), "No address proposed");
        iVADER(VADER).changeUTILS(_proposedAddress);
        completeProposal(_proposalID);
    }

    function moveRewardAddress(uint256 _proposalID) internal {
        address _proposedAddress = mapPID_address[_proposalID];
        require(_proposedAddress != address(0), "No address proposed");
        iVADER(VADER).setRewardAddress(_proposedAddress);
        completeProposal(_proposalID);
    }

    //============================== CONSENSUS ================================//

    function countMemberVotes(uint256 _proposalID) internal returns (uint256 voteWeight) {
        mapPID_votes[_proposalID] -= mapPIDMember_votes[_proposalID][msg.sender];
        voteWeight = iVAULT(VAULT).getMemberWeight(msg.sender);
        mapPID_votes[_proposalID] += voteWeight;
        mapPIDMember_votes[_proposalID][msg.sender] = voteWeight;
    }

    function hasMajority(uint256 _proposalID) public view returns (bool) {
        uint256 votes = mapPID_votes[_proposalID];
        uint256 consensus = iVAULT(VAULT).totalWeight() / 2; // >50%
        if (votes > consensus) {
            return true;
        } else {
            return false;
        }
    }

    function hasQuorum(uint256 _proposalID) public view returns (bool) {
        uint256 votes = mapPID_votes[_proposalID];
        uint256 consensus = iVAULT(VAULT).totalWeight() / 3; // >33%
        if (votes > consensus) {
            return true;
        } else {
            return false;
        }
    }

    function hasMinority(uint256 _proposalID) public view returns (bool) {
        uint256 votes = mapPID_votes[_proposalID];
        uint256 consensus = iVAULT(VAULT).totalWeight() / 6; // >16%
        if (votes > consensus) {
            return true;
        } else {
            return false;
        }
    }

    function isEqual(bytes memory part1, bytes memory part2) public pure returns (bool) {
        if (sha256(part1) == sha256(part2)) {
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

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transferTo(address, uint256) external returns (bool);

    function burn(uint256) external;

    function burnFrom(address, uint256) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iROUTER {
    function setParams(
        uint256 newFactor,
        uint256 newTime,
        uint256 newLimit
    ) external;

    function addLiquidity(
        address base,
        uint256 inputBase,
        address token,
        uint256 inputToken
    ) external returns (uint256);

    function removeLiquidity(
        address base,
        address token,
        uint256 basisPoints
    ) external returns (uint256 amountBase, uint256 amountToken);

    function swap(
        uint256 inputAmount,
        address inputToken,
        address outputToken
    ) external returns (uint256 outputAmount);

    function swapWithLimit(
        uint256 inputAmount,
        address inputToken,
        address outputToken,
        uint256 slipLimit
    ) external returns (uint256 outputAmount);

    function swapWithSynths(
        uint256 inputAmount,
        address inputToken,
        bool inSynth,
        address outputToken,
        bool outSynth
    ) external returns (uint256 outputAmount);

    function swapWithSynthsWithLimit(
        uint256 inputAmount,
        address inputToken,
        bool inSynth,
        address outputToken,
        bool outSynth,
        uint256 slipLimit
    ) external returns (uint256 outputAmount);

    function getILProtection(
        address member,
        address base,
        address token,
        uint256 basisPoints
    ) external view returns (uint256 protection);

    function curatePool(address token) external;

    function listAnchor(address token) external;

    function replacePool(address oldToken, address newToken) external;

    function updateAnchorPrice(address token) external;

    function getAnchorPrice() external view returns (uint256 anchorPrice);

    function getVADERAmount(uint256 USDVAmount) external view returns (uint256 vaderAmount);

    function getUSDVAmount(uint256 vaderAmount) external view returns (uint256 USDVAmount);

    function isCurated(address token) external view returns (bool curated);

    function reserveUSDV() external view returns (uint256);

    function reserveVADER() external view returns (uint256);

    function getMemberBaseDeposit(address member, address token) external view returns (uint256);

    function getMemberTokenDeposit(address member, address token) external view returns (uint256);

    function getMemberLastDeposit(address member, address token) external view returns (uint256);

    function getMemberCollateral(
        address member,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256);

    function getMemberDebt(
        address member,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256);

    function getSystemCollateral(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemDebt(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemInterestPaid(address collateralAsset, address debtAsset) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iUTILS {
    function getFeeOnTransfer(uint256 totalSupply, uint256 maxSupply) external pure returns (uint256);

    function assetChecks(address collateralAsset, address debtAsset) external;

    function isBase(address token) external view returns (bool base);

    function calcValueInBase(address token, uint256 amount) external view returns (uint256);

    function calcValueInToken(address token, uint256 amount) external view returns (uint256);

    function calcValueOfTokenInToken(
        address token1,
        uint256 amount,
        address token2
    ) external view returns (uint256);

    function calcSwapValueInBase(address token, uint256 amount) external view returns (uint256);

    function calcSwapValueInToken(address token, uint256 amount) external view returns (uint256);

    function requirePriceBounds(
        address token,
        uint256 bound,
        bool inside,
        uint256 targetPrice
    ) external view;

    function getRewardShare(address token, uint256 rewardReductionFactor) external view returns (uint256 rewardShare);

    function getReducedShare(uint256 amount) external view returns (uint256);

    function getProtection(
        address member,
        address token,
        uint256 basisPoints,
        uint256 timeForFullProtection
    ) external view returns (uint256 protection);

    function getCoverage(address member, address token) external view returns (uint256);

    function getCollateralValueInBase(
        address member,
        uint256 collateral,
        address collateralAsset,
        address debtAsset
    ) external returns (uint256 debt, uint256 baseValue);

    function getDebtValueInCollateral(
        address member,
        uint256 debt,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256, uint256);

    function getInterestOwed(
        address collateralAsset,
        address debtAsset,
        uint256 timeElapsed
    ) external returns (uint256 interestOwed);

    function getInterestPayment(address collateralAsset, address debtAsset) external view returns (uint256);

    function getDebtLoading(address collateralAsset, address debtAsset) external view returns (uint256);

    function calcPart(uint256 bp, uint256 total) external pure returns (uint256);

    function calcShare(
        uint256 part,
        uint256 total,
        uint256 amount
    ) external pure returns (uint256);

    function calcSwapOutput(
        uint256 x,
        uint256 X,
        uint256 Y
    ) external pure returns (uint256);

    function calcSwapFee(
        uint256 x,
        uint256 X,
        uint256 Y
    ) external pure returns (uint256);

    function calcSwapSlip(uint256 x, uint256 X) external pure returns (uint256);

    function calcLiquidityUnits(
        uint256 b,
        uint256 B,
        uint256 t,
        uint256 T,
        uint256 P
    ) external view returns (uint256);

    function getSlipAdustment(
        uint256 b,
        uint256 B,
        uint256 t,
        uint256 T
    ) external view returns (uint256);

    function calcSynthUnits(
        uint256 b,
        uint256 B,
        uint256 P
    ) external view returns (uint256);

    function calcAsymmetricShare(
        uint256 u,
        uint256 U,
        uint256 A
    ) external pure returns (uint256);

    function calcCoverage(
        uint256 B0,
        uint256 T0,
        uint256 B1,
        uint256 T1
    ) external pure returns (uint256);

    function sortArray(uint256[] memory array) external pure returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iVADER {
    function UTILS() external view returns (address);

    function DAO() external view returns (address);

    function emitting() external view returns (bool);

    function minting() external view returns (bool);

    function secondsPerEra() external view returns (uint256);

    function flipEmissions() external;

    function flipMinting() external;

    function setParams(uint256 newEra, uint256 newCurve) external;

    function setRewardAddress(address newAddress) external;

    function changeUTILS(address newUTILS) external;

    function changeDAO(address newDAO) external;

    function purgeDAO() external;

    function upgrade(uint256 amount) external;

    function redeem() external returns (uint256);

    function redeemToMember(address member) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iVAULT {
    function setParams(
        uint256 newEra,
        uint256 newDepositTime,
        uint256 newGrantTime
    ) external;

    function grant(address recipient, uint256 amount) external;

    function deposit(address synth, uint256 amount) external;

    function depositForMember(
        address synth,
        address member,
        uint256 amount
    ) external;

    function harvest(address synth) external returns (uint256 reward);

    function calcCurrentReward(address synth, address member) external view returns (uint256 reward);

    function calcReward(address synth, address member) external view returns (uint256);

    function withdraw(address synth, uint256 basisPoints) external returns (uint256 redeemedAmount);

    function totalWeight() external view returns (uint256);

    function reserveUSDV() external view returns (uint256);

    function reserveVADER() external view returns (uint256);

    function getMemberDeposit(address synth, address member) external view returns (uint256);

    function getMemberWeight(address member) external view returns (uint256);

    function getMemberLastTime(address synth, address member) external view returns (uint256);
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