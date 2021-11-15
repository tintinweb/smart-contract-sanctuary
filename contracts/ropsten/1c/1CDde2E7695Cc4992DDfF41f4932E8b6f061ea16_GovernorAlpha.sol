// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

// Interfaces
import "../interfaces/iTIMELOCK.sol";
import "../interfaces/iVAULT.sol";
import "../interfaces/iVADER.sol";
import "../interfaces/iERC20.sol";
import "../interfaces/iLENDER.sol";
import "../interfaces/iPOOLS.sol";
import "../interfaces/iRESERVE.sol";
import "../interfaces/iROUTER.sol";
import "../interfaces/iUSDV.sol";
import "../interfaces/iUTILS.sol";

contract GovernorAlpha {
    // @notice The name of this contract
    string public constant name = "Vader Governor Alpha";

    // @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function quorumVotes() public view returns (uint) { return iERC20(USDV).totalSupply() * 4 / 100; } // 4 % of USDV

    // @notice The number of votes required in order for a voter to become a proposer
    function proposalThreshold() public view returns (uint) { return iERC20(USDV).totalSupply() / 100; } // 1 % of USDV

    // @notice The maximum number of actions that can be included in a proposal
    function proposalMaxOperations() public pure returns (uint) { return 10; } // 10 actions

    // @notice The delay before voting on a proposal may take place, once proposed
    function votingDelay() public pure returns (uint) { return 1; } // 1 block

    // @notice The duration of voting on a proposal, in blocks
    function votingPeriod() public pure returns (uint) { return 17280; } // ~3 days in blocks (assuming 15s blocks)

    address public immutable VETHER;
    address public immutable USDV;
    address public immutable VAULT;
    address public immutable ROUTER;
    address public immutable LENDER;
    address public immutable POOLS;
    address public immutable FACTORY;
    address public VADER;
    address public RESERVE;
    address public UTILS;
    address public TIMELOCK;
    // @notice The address of the Governor Guardian
    address public GUARDIAN;

    // @notice The total number of proposals
    uint public proposalCount;

    struct Proposal {
        // @notice Unique id for looking up a proposal
        uint id;
        // @notice Creator of the proposal
        address proposer;
        // @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint eta;
        // @notice the ordered list of target addresses for calls to be made
        address[] targets;
        // @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;
        // @notice The ordered list of function signatures to be called
        string[] signatures;
        // @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;
        // @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint startBlock;
        // @notice The block at which voting ends: votes must be cast prior to this block
        uint endBlock;
        // @notice Current number of votes in favor of this proposal
        uint forVotes;
        // @notice Current number of votes in opposition to this proposal
        uint againstVotes;
        // @notice Flag marking whether the proposal has been canceled
        bool canceled;
        // @notice Flag marking whether the proposal has been executed
        bool executed;
        // @notice Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    // @notice Ballot receipt record for a voter
    struct Receipt {
        // @notice Whether or not a vote has been cast
        bool hasVoted;
        // @notice Whether or not the voter supports the proposal
        bool support;
        // @notice The number of votes the voter had, which were cast
        uint256 votes;
    }

    // @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    // @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    // @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    // @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    // @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    event Initialized(address vether, address vader, address usdv, address vault, address router, address lender, address pools, address factory, address reserve, address utils);
    
    // @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);

    // @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support, uint votes);

    // @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    // @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint id, uint eta);

    // @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);

    //==================================== MODIFIER ========================================//

    // Only TIMELOCK can execute
    modifier onlyGUARDIAN() {
        require(msg.sender == GUARDIAN, "sender must be gov guardian");
        _;
    }

    // Only TIMELOCK can execute
    modifier onlyTIMELOCK() {
        require(msg.sender == TIMELOCK, "sender must be gov timelock");
        _;
    }

    //==================================== CREATION ========================================//

    constructor (
        address _vether,
        address _usdv,
        address _vault,
        address _router,
        address _lender,
        address _pools,
        address _factory,
        address _vader,
        address _reserve,
        address _utils,
        address _guardian
    ) {
        VETHER = _vether;
        USDV = _usdv;
        VAULT = _vault;
        ROUTER = _router;
        LENDER = _lender;
        POOLS = _pools;
        FACTORY = _factory;
        VADER = _vader;
        RESERVE = _reserve;
        UTILS = _utils;
        GUARDIAN = _guardian;

        emit Initialized(_vether, _usdv, _vault, _router, _lender, _pools, _factory, _vader, _reserve, _utils);
    }

    function initTimelock(address _timelock) external {
        require(TIMELOCK == address(0), "TimeLock already set");
        TIMELOCK = _timelock;
    }

    //==================================== GOVERNOR ========================================//

    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
        require(iVAULT(VAULT).getPriorVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold(), "proposer votes below proposal threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "proposal function information arity mismatch");
        require(targets.length != 0, "must provide actions");
        require(targets.length <= proposalMaxOperations(), "too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "one live proposal per proposer, found an already pending proposal");
        }

        uint startBlock = add256(block.number, votingDelay());
        uint endBlock = add256(startBlock, votingPeriod());

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.eta = 0;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.canceled = false;
        newProposal.executed = false;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return newProposal.id;
    }

    function queue(uint proposalId) public {
        require(state(proposalId) == ProposalState.Succeeded, "proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint eta = add256(block.timestamp, iTIMELOCK(TIMELOCK).delay());
        for (uint i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function _queueOrRevert(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        require(!iTIMELOCK(TIMELOCK).queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "proposal action already queued at eta");
        iTIMELOCK(TIMELOCK).queueTransaction(target, value, signature, data, eta);
    }

    function execute(uint proposalId) public payable {
        require(state(proposalId) == ProposalState.Queued, "proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            iTIMELOCK(TIMELOCK).executeTransaction{ value: proposal.values[i] }(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) public {
        require(state(proposalId) != ProposalState.Executed, "cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == GUARDIAN || iVAULT(VAULT).getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold(), "proposer above threshold");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            iTIMELOCK(TIMELOCK).cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId);
    }

    function getActions(uint proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= add256(proposal.eta, iTIMELOCK(TIMELOCK).GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVote(uint proposalId, bool support) public {
        return _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "invalid signature");
        return _castVote(signatory, proposalId, support);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "voter already voted");
        uint256 votes = iVAULT(VAULT).getPriorVotes(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }

    function __acceptAdmin() public onlyGUARDIAN {
        iTIMELOCK(TIMELOCK).acceptAdmin();
    }

    function __abdicate() public onlyGUARDIAN {
        GUARDIAN = address(0);
    }

    function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public onlyGUARDIAN {
        iTIMELOCK(TIMELOCK).queueTransaction(address(TIMELOCK), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public onlyGUARDIAN {
        iTIMELOCK(TIMELOCK).executeTransaction(address(TIMELOCK), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    //============================= EXTERNAL ================================//

    function updateVADER(address newAddress) external {
        require(msg.sender == VADER && newAddress != address(0), "!VADER");
        VADER = newAddress;
        iLENDER(LENDER).updateVADER(newAddress);
        iPOOLS(POOLS).updateVADER(newAddress);
        iRESERVE(RESERVE).updateVADER(newAddress);
        iROUTER(ROUTER).updateVADER(newAddress);
        iUSDV(USDV).updateVADER(newAddress);
        iUTILS(UTILS).updateVADER(newAddress);
        iVAULT(VAULT).updateVADER(newAddress);
    }

    function changeUTILS(address newAddress) external onlyTIMELOCK {
        UTILS = newAddress;
    }

    function changeRESERVE(address newAddress) external onlyTIMELOCK {
        RESERVE = newAddress;
    }

    //============================== HELPERS ================================//

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iTIMELOCK {
    function delay() external view returns (uint);

    function GRACE_PERIOD() external view returns (uint);

    function acceptAdmin() external;

    function queuedTransactions(bytes32 hash) external view returns (bool);

    function queueTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external returns (bytes32);

    function cancelTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external;
    
    function executeTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external payable returns (bytes memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iVAULT {    
    function delegates(address) external view returns (address);

    function totalWeight() external view returns (uint256);

    function setParams(uint256 newDepositTime) external;

    function deposit(address asset, uint256 amount) external;

    function depositForMember(
        address asset,
        address member,
        uint256 amount
    ) external;

    function harvest(address asset) external returns (uint256 reward);

    function calcRewardForAsset(address asset) external view returns(uint256 reward);

    function withdraw(address asset, uint256 basisPoints) external returns (uint256 redeemedAmount);

    function withdrawToVader(address asset, uint256 basisPoints) external returns (uint256 redeemedAmount);

    function calcDepositValueForMember(address asset, address member) external view returns (uint256 value);

    function updateVADER(address newAddress) external;

    function getCurrentVotes(address account) external view returns (uint256);

    function getPriorVotes(address account, uint blockNumber) external view returns (uint256);

    function getMemberDeposit(address member, address asset) external view returns (uint256);

    function getMemberLastTime(address member, address asset) external view returns (uint256);

    function getMemberWeight(address member) external view returns (uint256);

    function getAssetDeposit(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iVADER {

    function GovernorAlpha() external view returns (address);

    function Admin() external view returns (address);

    function UTILS() external view returns (address);

    function emitting() external view returns (bool);

    function minting() external view returns (bool);

    function secondsPerEra() external view returns (uint256);

    function era() external view returns(uint256);

    function flipEmissions() external;

    function flipMinting() external;

    function setParams(uint256 newSeconds, uint256 newCurve, uint256 newTailEmissionEra) external;

    function setReserve(address newReserve) external;

    function changeUTILS(address newUTILS) external;

    function changeGovernorAlpha(address newGovernorAlpha) external;

    function purgeGovernorAlpha() external;

    function upgrade(uint256 amount) external;

    function convertToUSDV(uint256 amount) external returns (uint256);

    function convertToUSDVForMember(address member, uint256 amount) external returns (uint256 convertAmount);

    function redeemToVADER(uint256 amount) external returns (uint256);

    function redeemToVADERForMember(address member, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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

    function burn(uint256) external;

    function burnFrom(address, uint256) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iLENDER {
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

    function updateVADER(address newAddress) external;

    function getSystemCollateral(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemDebt(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemInterestPaid(address collateralAsset, address debtAsset) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iPOOLS {
    function pooledVADER() external view returns (uint256);

    function pooledUSDV() external view returns (uint256);

    function addLiquidity(
        address base,
        uint256 inputBase,
        address token,
        uint256 inputToken,
        address member
    ) external returns (uint256 liquidityUnits);

    function removeLiquidity(
        address base,
        address token,
        uint256 basisPoints,
        address member
    ) external returns (uint256 units, uint256 outputBase, uint256 outputToken);

    function sync(address token, uint256 inputToken, address pool) external;

    function swap(
        address base,
        address token,
        uint256 inputToken,
        address member,
        bool toBase
    ) external returns (uint256 outputAmount);

    function deploySynth(address token) external;

    function mintSynth(
        address token,
        uint256 inputBase,
        address member
    ) external returns (uint256 outputAmount);

    function burnSynth(
        address token,
        address member
    ) external returns (uint256 outputBase);

    function syncSynth(address token) external;

    function lockUnits(
        uint256 units,
        address token,
        address member
    ) external;

    function unlockUnits(
        uint256 units,
        address token,
        address member
    ) external;

    function updateVADER(address newAddress) external;

    function isAsset(address token) external view returns (bool);

    function isAnchor(address token) external view returns (bool);

    function getPoolAmounts(address token) external view returns (uint256, uint256);

    function getBaseAmount(address token) external view returns (uint256);

    function getTokenAmount(address token) external view returns (uint256);

    function getUnits(address token) external view returns (uint256);

    function getMemberUnits(address token, address member) external view returns (uint256);

    function getSynth(address token) external returns (address);

    function isSynth(address token) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iRESERVE {
    function setParams(uint256 newSplit, uint256 newDelay, uint256 newShare) external;

    function grant(address recipient, uint256 amount) external;

    function requestFunds(address base, address recipient, uint256 amount) external returns(uint256);

    function requestFundsStrict(address base, address recipient, uint256 amount) external returns(uint256);

    function updateVADER(address newAddress) external;

    function checkReserve() external;

    function getVaultReward() external view returns(uint256);

    function reserveVADER() external view returns (uint256);

    function reserveUSDV() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iROUTER {
    function setParams(
        uint256 newFactor,
        uint256 newTime,
        uint256 newLimit,
        uint256 newInterval
    ) external;
    function setAnchorParams(
        uint256 newLimit,
        uint256 newInside,
        uint256 newOutside
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
    ) external returns (uint256 units, uint256 amountBase, uint256 amountToken);

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

    function updateVADER(address newAddress) external;

    function curatePool(address token) external;

    function replacePool(address oldToken, address newToken) external;

    function listAnchor(address token) external;

    function replaceAnchor(address oldToken, address newToken) external;

    function updateAnchorPrice(address token) external;

    function getAnchorPrice() external view returns (uint256 anchorPrice);

    function getVADERAmount(uint256 USDVAmount) external view returns (uint256 vaderAmount);

    function getUSDVAmount(uint256 vaderAmount) external view returns (uint256 USDVAmount);

    function isCurated(address token) external view returns (bool curated);

    function isBase(address token) external view returns (bool base);

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

interface iUSDV {
    function isMature() external view returns (bool);

    function setParams(uint256 newDelay) external;

    function updateVADER(address newAddress) external;

    function convertToUSDV(uint256 amount) external returns (uint256);

    function convertToUSDVForMember(address member, uint256 amount) external returns (uint256);

    function convertToUSDVDirectly() external returns (uint256 convertAmount);

    function convertToUSDVForMemberDirectly(address member) external returns (uint256 convertAmount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iUTILS {
    function getFeeOnTransfer(uint256 totalSupply, uint256 maxSupply) external pure returns (uint256);

    function assetChecks(address collateralAsset, address debtAsset) external;

    function updateVADER(address newAddress) external;

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

    function getMemberShare(uint256 basisPoints, address token, address member) external view returns(uint256 units, uint256 outputBase, uint256 outputToken);

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

