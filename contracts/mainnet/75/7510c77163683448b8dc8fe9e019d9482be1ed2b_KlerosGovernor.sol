pragma solidity ^0.4.24;

import "./SortitionSumTreeFactory.sol";

/**
 *  @title ExposedSortitionSumTreeFactory
 *  @author Enrique Piqueras - <[email protected]>
 *  @dev Exposed version of SortitionSumTreeFactory for testing.
 */
contract ExposedSortitionSumTreeFactory {
    /* Storage */

    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;
    SortitionSumTreeFactory.SortitionSumTrees internal sortitionSumTrees;

    /**
     *  @dev Public getter for sortitionSumTrees.
     *  @param _key The key of the tree to get.
     *  @return All of the tree's properties.
     */
    function _sortitionSumTrees(bytes32 _key) public view returns(uint K, uint[] stack, uint[] nodes) {
        return (
            sortitionSumTrees.sortitionSumTrees[_key].K,
            sortitionSumTrees.sortitionSumTrees[_key].stack,
            sortitionSumTrees.sortitionSumTrees[_key].nodes
        );
    }

    /* Public */

    /**
     *  @dev Create a sortition sum tree at the specified key.
     *  @param _key The key of the new tree.
     *  @param _K The number of children each node in the tree should have.
     */
    function _createTree(bytes32 _key, uint _K) public {
        sortitionSumTrees.createTree(_key, _K);
    }

    /**
     *  @dev Set a value of a tree.
     *  @param _key The key of the tree.
     *  @param _value The new value.
     *  @param _ID The ID of the value.
     */
    function _set(bytes32 _key, uint _value, bytes32 _ID) public {
        sortitionSumTrees.set(_key, _value, _ID);
    }

    /* Public Views */

    /**
     *  @dev Query the leaves of a tree.
     *  @param _key The key of the tree to get the leaves from.
     *  @param _cursor The pagination cursor.
     *  @param _count The number of items to return.
     *  @return The index at which leaves start, the values of the returned leaves, and whether there are more for pagination.
     */
    function _queryLeafs(bytes32 _key, uint _cursor, uint _count) public view returns(uint startIndex, uint[] values, bool hasMore) {
        return sortitionSumTrees.queryLeafs(_key, _cursor, _count);
    }

    /**
     *  @dev Draw an ID from a tree using a number.
     *  @param _key The key of the tree.
     *  @param _drawnNumber The drawn number.
     *  @return The drawn ID.
     */
    function _draw(bytes32 _key, uint _drawnNumber) public view returns(bytes32 ID) {
        return sortitionSumTrees.draw(_key, _drawnNumber);
    }

    /** @dev Gets a specified candidate's associated value.
     *  @param _key The key of the tree.
     *  @param _ID The ID of the value.
     *  @return The associated value.
     */
    function _stakeOf(bytes32 _key, bytes32 _ID) public view returns(uint value) {
        return sortitionSumTrees.stakeOf(_key, _ID);
    }
}

/**
 *  @authors: [@epiqueras]
 *  @reviewers: [@clesaege, @unknownunknown1, @ferittuncer, @remedcu, @shalzz]
 *  @auditors: []
 *  @bounties: [{ duration: 28 days, link: https://github.com/kleros/kleros/issues/115, maxPayout: 50 ETH }]
 *  @deployments: [ https://etherscan.io/address/0x180eba68d164c3f8c3f6dc354125ebccf4dfcb86 ]
 */

pragma solidity ^0.4.24;

/**
 *  @title SortitionSumTreeFactory
 *  @author Enrique Piqueras - <[email protected]>
 *  @dev A factory of trees that keep track of staked values for sortition.
 */
library SortitionSumTreeFactory {
    /* Structs */

    struct SortitionSumTree {
        uint K; // The maximum number of childs per node.
        // We use this to keep track of vacant positions in the tree after removing a leaf. This is for keeping the tree as balanced as possible without spending gas on moving nodes around.
        uint[] stack;
        uint[] nodes;
        // Two-way mapping of IDs to node indexes. Note that node index 0 is reserved for the root node, and means the ID does not have a node.
        mapping(bytes32 => uint) IDsToNodeIndexes;
        mapping(uint => bytes32) nodeIndexesToIDs;
    }

    /* Storage */

    struct SortitionSumTrees {
        mapping(bytes32 => SortitionSumTree) sortitionSumTrees;
    }

    /* Public */

    /**
     *  @dev Create a sortition sum tree at the specified key.
     *  @param _key The key of the new tree.
     *  @param _K The number of children each node in the tree should have.
     */
    function createTree(SortitionSumTrees storage self, bytes32 _key, uint _K) public {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        require(tree.K == 0, "Tree already exists.");
        require(_K > 1, "K must be greater than one.");
        tree.K = _K;
        tree.stack.length = 0;
        tree.nodes.length = 0;
        tree.nodes.push(0);
    }

    /**
     *  @dev Set a value of a tree.
     *  @param _key The key of the tree.
     *  @param _value The new value.
     *  @param _ID The ID of the value.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function set(SortitionSumTrees storage self, bytes32 _key, uint _value, bytes32 _ID) public {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) { // No existing node.
            if (_value != 0) { // Non zero value.
                // Append.
                // Add node.
                if (tree.stack.length == 0) { // No vacant spots.
                    // Get the index and append the value.
                    treeIndex = tree.nodes.length;
                    tree.nodes.push(_value);

                    // Potentially append a new node and make the parent a sum node.
                    if (treeIndex != 1 && (treeIndex - 1) % tree.K == 0) { // Is first child.
                        uint parentIndex = treeIndex / tree.K;
                        bytes32 parentID = tree.nodeIndexesToIDs[parentIndex];
                        uint newIndex = treeIndex + 1;
                        tree.nodes.push(tree.nodes[parentIndex]);
                        delete tree.nodeIndexesToIDs[parentIndex];
                        tree.IDsToNodeIndexes[parentID] = newIndex;
                        tree.nodeIndexesToIDs[newIndex] = parentID;
                    }
                } else { // Some vacant spot.
                    // Pop the stack and append the value.
                    treeIndex = tree.stack[tree.stack.length - 1];
                    tree.stack.length--;
                    tree.nodes[treeIndex] = _value;
                }

                // Add label.
                tree.IDsToNodeIndexes[_ID] = treeIndex;
                tree.nodeIndexesToIDs[treeIndex] = _ID;

                updateParents(self, _key, treeIndex, true, _value);
            }
        } else { // Existing node.
            if (_value == 0) { // Zero value.
                // Remove.
                // Remember value and set to 0.
                uint value = tree.nodes[treeIndex];
                tree.nodes[treeIndex] = 0;

                // Push to stack.
                tree.stack.push(treeIndex);

                // Clear label.
                delete tree.IDsToNodeIndexes[_ID];
                delete tree.nodeIndexesToIDs[treeIndex];

                updateParents(self, _key, treeIndex, false, value);
            } else if (_value != tree.nodes[treeIndex]) { // New, non zero value.
                // Set.
                bool plusOrMinus = tree.nodes[treeIndex] <= _value;
                uint plusOrMinusValue = plusOrMinus ? _value - tree.nodes[treeIndex] : tree.nodes[treeIndex] - _value;
                tree.nodes[treeIndex] = _value;

                updateParents(self, _key, treeIndex, plusOrMinus, plusOrMinusValue);
            }
        }
    }

    /* Public Views */

    /**
     *  @dev Query the leaves of a tree. Note that if `startIndex == 0`, the tree is empty and the root node will be returned.
     *  @param _key The key of the tree to get the leaves from.
     *  @param _cursor The pagination cursor.
     *  @param _count The number of items to return.
     *  @return startIndex The index at which leaves start.
     *  @return values The values of the returned leaves.
     *  @return hasMore Whether there are more for pagination.
     *  `O(n)` where
     *  `n` is the maximum number of nodes ever appended.
     */
    function queryLeafs(
        SortitionSumTrees storage self,
        bytes32 _key,
        uint _cursor,
        uint _count
    ) public view returns(uint startIndex, uint[] values, bool hasMore) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        // Find the start index.
        for (uint i = 0; i < tree.nodes.length; i++) {
            if ((tree.K * i) + 1 >= tree.nodes.length) {
                startIndex = i;
                break;
            }
        }

        // Get the values.
        uint loopStartIndex = startIndex + _cursor;
        values = new uint[](loopStartIndex + _count > tree.nodes.length ? tree.nodes.length - loopStartIndex : _count);
        uint valuesIndex = 0;
        for (uint j = loopStartIndex; j < tree.nodes.length; j++) {
            if (valuesIndex < _count) {
                values[valuesIndex] = tree.nodes[j];
                valuesIndex++;
            } else {
                hasMore = true;
                break;
            }
        }
    }

    /**
     *  @dev Draw an ID from a tree using a number. Note that this function reverts if the sum of all values in the tree is 0.
     *  @param _key The key of the tree.
     *  @param _drawnNumber The drawn number.
     *  @return ID The drawn ID.
     *  `O(k * log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function draw(SortitionSumTrees storage self, bytes32 _key, uint _drawnNumber) public view returns(bytes32 ID) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = 0;
        uint currentDrawnNumber = _drawnNumber % tree.nodes[0];

        while ((tree.K * treeIndex) + 1 < tree.nodes.length)  // While it still has children.
            for (uint i = 1; i <= tree.K; i++) { // Loop over children.
                uint nodeIndex = (tree.K * treeIndex) + i;
                uint nodeValue = tree.nodes[nodeIndex];

                if (currentDrawnNumber >= nodeValue) currentDrawnNumber -= nodeValue; // Go to the next child.
                else { // Pick this child.
                    treeIndex = nodeIndex;
                    break;
                }
            }

        ID = tree.nodeIndexesToIDs[treeIndex];
    }

    /** @dev Gets a specified ID's associated value.
     *  @param _key The key of the tree.
     *  @param _ID The ID of the value.
     *  @return value The associated value.
     */
    function stakeOf(SortitionSumTrees storage self, bytes32 _key, bytes32 _ID) public view returns(uint value) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) value = 0;
        else value = tree.nodes[treeIndex];
    }

    /* Private */

    /**
     *  @dev Update all the parents of a node.
     *  @param _key The key of the tree to update.
     *  @param _treeIndex The index of the node to start from.
     *  @param _plusOrMinus Wether to add (true) or substract (false).
     *  @param _value The value to add or substract.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function updateParents(SortitionSumTrees storage self, bytes32 _key, uint _treeIndex, bool _plusOrMinus, uint _value) private {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        uint parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus ? tree.nodes[parentIndex] + _value : tree.nodes[parentIndex] - _value;
        }
    }
}

pragma solidity ^0.4.4;

// Test Imports
import "@kleros/kleros-interaction/contracts/standard/rng/ConstantNG.sol";
import "@kleros/kleros-interaction/contracts/standard/arbitration/EnhancedAppealableArbitrator.sol";
import "@kleros/kleros-interaction/contracts/standard/arbitration/TwoPartyArbitrable.sol";

contract Migrations {
    address public owner;
    uint public last_completed_migration;

    modifier isOwner() {
        if (msg.sender == owner) _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setCompleted(uint completed) public isOwner {
        last_completed_migration = completed;
    }

    function upgrade(address newAddress) public isOwner {
        Migrations upgraded = Migrations(newAddress);
        upgraded.setCompleted(last_completed_migration);
    }
}

/**
 *  https://contributing.kleros.io/smart-contract-workflow
 *  @authors: [@epiqueras]
 *  @reviewers: [@clesaege, @unknownunknown1, @ferittuncer, @remedcu, @satello, @fnanni-0, @shalzz, @MerlinEgalite]
 *  @auditors: []
 *  @bounties: [{ duration: 14 days, link: https://github.com/kleros/kleros/issues/117, maxPayout: 50 ETH }]
 *  @deployments: [ https://etherscan.io/address/0x988b3a538b618c7a603e1c11ab82cd16dbe28069 ]
 */
/* solium-disable error-reason */
/* solium-disable security/no-block-members */
pragma solidity ^0.4.24;

import { TokenController } from "minimetoken/contracts/TokenController.sol";
import { Arbitrator, Arbitrable } from "@kleros/kleros-interaction/contracts/standard/arbitration/Arbitrator.sol";
import { MiniMeTokenERC20 as Pinakion } from "@kleros/kleros-interaction/contracts/standard/arbitration/ArbitrableTokens/MiniMeTokenERC20.sol";
import { RNG } from "@kleros/kleros-interaction/contracts/standard/rng/RNG.sol";

import { SortitionSumTreeFactory } from "../data-structures/SortitionSumTreeFactory.sol";

/**
 *  @title KlerosLiquid
 *  @author Enrique Piqueras - <[email protected]>
 *  @dev The main Kleros contract with dispute resolution logic for the Athena release.
 *  This is the contract currently used on mainnet.
 */
contract KlerosLiquid is TokenController, Arbitrator {
    /* Enums */

    // General
    enum Phase {
      staking, // Stake sum trees can be updated. Pass after `minStakingTime` passes and there is at least one dispute without jurors.
      generating, // Waiting for a random number. Pass as soon as it is ready.
      drawing // Jurors can be drawn. Pass after all disputes have jurors or `maxDrawingTime` passes.
    }

    // Dispute
    enum Period {
      evidence, // Evidence can be submitted. This is also when drawing has to take place.
      commit, // Jurors commit a hashed vote. This is skipped for courts without hidden votes.
      vote, // Jurors reveal/cast their vote depending on whether the court has hidden votes or not.
      appeal, // The dispute can be appealed.
      execution // Tokens are redistributed and the ruling is executed.
    }

    /* Structs */

    // General
    struct Court {
        uint96 parent; // The parent court.
        uint[] children; // List of child courts.
        bool hiddenVotes; // Whether to use commit and reveal or not.
        uint minStake; // Minimum tokens needed to stake in the court.
        uint alpha; // Basis point of tokens that are lost when incoherent.
        uint feeForJuror; // Arbitration fee paid per juror.
        // The appeal after the one that reaches this number of jurors will go to the parent court if any, otherwise, no more appeals are possible.
        uint jurorsForCourtJump;
        uint[4] timesPerPeriod; // The time allotted to each dispute period in the form `timesPerPeriod[period]`.
    }
    struct DelayedSetStake {
        address account; // The address of the juror.
        uint96 subcourtID; // The ID of the subcourt.
        uint128 stake; // The new stake.
    }

    // Dispute
    struct Vote {
        address account; // The address of the juror.
        bytes32 commit; // The commit of the juror. For courts with hidden votes.
        uint choice; // The choice of the juror.
        bool voted; // True if the vote has been cast or revealed, false otherwise.
    }
    struct VoteCounter {
        // The choice with the most votes. Note that in the case of a tie, it is the choice that reached the tied number of votes first.
        uint winningChoice;
        mapping(uint => uint) counts; // The sum of votes for each choice in the form `counts[choice]`.
        bool tied; // True if there is a tie, false otherwise.
    }
    struct Dispute { // Note that appeal `0` is equivalent to the first round of the dispute.
        uint96 subcourtID; // The ID of the subcourt the dispute is in.
        Arbitrable arbitrated; // The arbitrated arbitrable contract.
        // The number of choices jurors have when voting. This does not include choice `0` which is reserved for "refuse to arbitrate"/"no ruling".
        uint numberOfChoices;
        Period period; // The current period of the dispute.
        uint lastPeriodChange; // The last time the period was changed.
        // The votes in the form `votes[appeal][voteID]`. On each round, a new list is pushed and packed with as many empty votes as there are draws. We use `dispute.votes.length` to get the number of appeals plus 1 for the first round.
        Vote[][] votes;
        VoteCounter[] voteCounters; // The vote counters in the form `voteCounters[appeal]`.
        uint[] tokensAtStakePerJuror; // The amount of tokens at stake for each juror in the form `tokensAtStakePerJuror[appeal]`.
        uint[] totalFeesForJurors; // The total juror fees paid in the form `totalFeesForJurors[appeal]`.
        uint drawsInRound; // A counter of draws made in the current round.
        uint commitsInRound; // A counter of commits made in the current round.
        uint[] votesInEachRound; // A counter of votes made in each round in the form `votesInEachRound[appeal]`.
        // A counter of vote reward repartitions made in each round in the form `repartitionsInEachRound[appeal]`.
        uint[] repartitionsInEachRound;
        uint[] penaltiesInEachRound; // The amount of tokens collected from penalties in each round in the form `penaltiesInEachRound[appeal]`.
        bool ruled; // True if the ruling has been executed, false otherwise.
    }

    // Juror
    struct Juror {
        // The IDs of subcourts where the juror has stake path ends. A stake path is a path from the general court to a court the juror directly staked in using `_setStake`.
        uint96[] subcourtIDs;
        uint stakedTokens; // The juror's total amount of tokens staked in subcourts.
        uint lockedTokens; // The juror's total amount of tokens locked in disputes.
    }

    /* Events */

    /** @dev Emitted when we pass to a new phase.
     *  @param _phase The new phase.
     */
    event NewPhase(Phase _phase);

    /** @dev Emitted when a dispute passes to a new period.
     *  @param _disputeID The ID of the dispute.
     *  @param _period The new period.
     */
    event NewPeriod(uint indexed _disputeID, Period _period);

    /** @dev Emitted when a juror's stake is set.
     *  @param _address The address of the juror.
     *  @param _subcourtID The ID of the subcourt at the end of the stake path.
     *  @param _stake The new stake.
     *  @param _newTotalStake The new total stake.
     */
    event StakeSet(address indexed _address, uint _subcourtID, uint128 _stake, uint _newTotalStake);

    /** @dev Emitted when a juror is drawn.
     *  @param _address The drawn address.
     *  @param _disputeID The ID of the dispute.
     *  @param _appeal The appeal the draw is for. 0 is for the first round.
     *  @param _voteID The vote ID.
     */
    event Draw(address indexed _address, uint indexed _disputeID, uint _appeal, uint _voteID);

    /** @dev Emitted when a juror wins or loses tokens and ETH from a dispute.
     *  @param _address The juror affected.
     *  @param _disputeID The ID of the dispute.
     *  @param _tokenAmount The amount of tokens won or lost.
     *  @param _ETHAmount The amount of ETH won or lost.
     */
    event TokenAndETHShift(address indexed _address, uint indexed _disputeID, int _tokenAmount, int _ETHAmount);

    /* Storage */

    // General Constants
    uint public constant MAX_STAKE_PATHS = 4; // The maximum number of stake paths a juror can have.
    uint public constant MIN_JURORS = 3; // The global default minimum number of jurors in a dispute.
    uint public constant NON_PAYABLE_AMOUNT = (2 ** 256 - 2) / 2; // An amount higher than the supply of ETH.
    uint public constant ALPHA_DIVISOR = 1e4; // The number to divide `Court.alpha` by.
    // General Contracts
    address public governor; // The governor of the contract.
    Pinakion public pinakion; // The Pinakion token contract.
    RNG public RNGenerator; // The random number generator contract.
    // General Dynamic
    Phase public phase; // The current phase.
    uint public lastPhaseChange; // The last time the phase was changed.
    uint public disputesWithoutJurors; // The number of disputes that have not finished drawing jurors.
    // The block number to get the next random number from. Used so there is at least a 1 block difference from the staking phase.
    uint public RNBlock;
    uint public RN; // The current random number.
    uint public minStakingTime; // The minimum staking time.
    uint public maxDrawingTime; // The maximum drawing time.
    // True if insolvent (`balance < stakedTokens || balance < lockedTokens`) token transfers should be blocked. Used to avoid blocking penalties.
    bool public lockInsolventTransfers = true;
    // General Storage
    Court[] public courts; // The subcourts.
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees; // Use library functions for sortition sum trees.
    SortitionSumTreeFactory.SortitionSumTrees internal sortitionSumTrees; // The sortition sum trees.
    // The delayed calls to `_setStake`. Used to schedule `_setStake`s when not in the staking phase.
    mapping(uint => DelayedSetStake) public delayedSetStakes;
    // The index of the next `delayedSetStakes` item to execute. Starts at 1 because `lastDelayedSetStake` starts at 0.
    uint public nextDelayedSetStake = 1;
    uint public lastDelayedSetStake; // The index of the last `delayedSetStakes` item. 0 is skipped because it is the initial value.

    // Dispute
    Dispute[] public disputes; // The disputes.

    // Juror
    mapping(address => Juror) public jurors; // The jurors.

    /* Modifiers */

    /** @dev Requires a specific phase.
     *  @param _phase The required phase.
     */
    modifier onlyDuringPhase(Phase _phase) {require(phase == _phase); _;}

    /** @dev Requires a specific period in a dispute.
     *  @param _disputeID The ID of the dispute.
     *  @param _period The required period.
     */
    modifier onlyDuringPeriod(uint _disputeID, Period _period) {require(disputes[_disputeID].period == _period); _;}

    /** @dev Requires that the sender is the governor. Note that the governor is expected to not be malicious. */
    modifier onlyByGovernor() {require(governor == msg.sender); _;}

    /* Constructor */

    /** @dev Constructs the KlerosLiquid contract.
     *  @param _governor The governor's address.
     *  @param _pinakion The address of the token contract.
     *  @param _RNGenerator The address of the RNG contract.
     *  @param _minStakingTime The minimum time that the staking phase should last.
     *  @param _maxDrawingTime The maximum time that the drawing phase should last.
     *  @param _hiddenVotes The `hiddenVotes` property value of the general court.
     *  @param _minStake The `minStake` property value of the general court.
     *  @param _alpha The `alpha` property value of the general court.
     *  @param _feeForJuror The `feeForJuror` property value of the general court.
     *  @param _jurorsForCourtJump The `jurorsForCourtJump` property value of the general court.
     *  @param _timesPerPeriod The `timesPerPeriod` property value of the general court.
     *  @param _sortitionSumTreeK The number of children per node of the general court's sortition sum tree.
     */
    constructor(
        address _governor,
        Pinakion _pinakion,
        RNG _RNGenerator,
        uint _minStakingTime,
        uint _maxDrawingTime,
        bool _hiddenVotes,
        uint _minStake,
        uint _alpha,
        uint _feeForJuror,
        uint _jurorsForCourtJump,
        uint[4] _timesPerPeriod,
        uint _sortitionSumTreeK
    ) public {
        // Initialize contract.
        governor = _governor;
        pinakion = _pinakion;
        RNGenerator = _RNGenerator;
        minStakingTime = _minStakingTime;
        maxDrawingTime = _maxDrawingTime;
        lastPhaseChange = now;

        // Create the general court.
        courts.push(Court({
            parent: 0,
            children: new uint[](0),
            hiddenVotes: _hiddenVotes,
            minStake: _minStake,
            alpha: _alpha,
            feeForJuror: _feeForJuror,
            jurorsForCourtJump: _jurorsForCourtJump,
            timesPerPeriod: _timesPerPeriod
        }));
        sortitionSumTrees.createTree(bytes32(0), _sortitionSumTreeK);
    }

    /* External */

    /** @dev Lets the governor call anything on behalf of the contract.
     *  @param _destination The destination of the call.
     *  @param _amount The value sent with the call.
     *  @param _data The data sent with the call.
     */
    function executeGovernorProposal(address _destination, uint _amount, bytes _data) external onlyByGovernor {
        require(_destination.call.value(_amount)(_data)); // solium-disable-line security/no-call-value
    }

    /** @dev Changes the `governor` storage variable.
     *  @param _governor The new value for the `governor` storage variable.
     */
    function changeGovernor(address _governor) external onlyByGovernor {
        governor = _governor;
    }

    /** @dev Changes the `pinakion` storage variable.
     *  @param _pinakion The new value for the `pinakion` storage variable.
     */
    function changePinakion(Pinakion _pinakion) external onlyByGovernor {
        pinakion = _pinakion;
    }

    /** @dev Changes the `RNGenerator` storage variable.
     *  @param _RNGenerator The new value for the `RNGenerator` storage variable.
     */
    function changeRNGenerator(RNG _RNGenerator) external onlyByGovernor {
        RNGenerator = _RNGenerator;
        if (phase == Phase.generating) {
            RNBlock = block.number + 1;
            RNGenerator.requestRN(RNBlock);
        }
    }

    /** @dev Changes the `minStakingTime` storage variable.
     *  @param _minStakingTime The new value for the `minStakingTime` storage variable.
     */
    function changeMinStakingTime(uint _minStakingTime) external onlyByGovernor {
        minStakingTime = _minStakingTime;
    }

    /** @dev Changes the `maxDrawingTime` storage variable.
     *  @param _maxDrawingTime The new value for the `maxDrawingTime` storage variable.
     */
    function changeMaxDrawingTime(uint _maxDrawingTime) external onlyByGovernor {
        maxDrawingTime = _maxDrawingTime;
    }

    /** @dev Creates a subcourt under a specified parent court.
     *  @param _parent The `parent` property value of the subcourt.
     *  @param _hiddenVotes The `hiddenVotes` property value of the subcourt.
     *  @param _minStake The `minStake` property value of the subcourt.
     *  @param _alpha The `alpha` property value of the subcourt.
     *  @param _feeForJuror The `feeForJuror` property value of the subcourt.
     *  @param _jurorsForCourtJump The `jurorsForCourtJump` property value of the subcourt.
     *  @param _timesPerPeriod The `timesPerPeriod` property value of the subcourt.
     *  @param _sortitionSumTreeK The number of children per node of the subcourt's sortition sum tree.
     */
    function createSubcourt(
        uint96 _parent,
        bool _hiddenVotes,
        uint _minStake,
        uint _alpha,
        uint _feeForJuror,
        uint _jurorsForCourtJump,
        uint[4] _timesPerPeriod,
        uint _sortitionSumTreeK
    ) external onlyByGovernor {
        require(courts[_parent].minStake <= _minStake, "A subcourt cannot be a child of a subcourt with a higher minimum stake.");

        // Create the subcourt.
        uint96 subcourtID = uint96(
            courts.push(Court({
                parent: _parent,
                children: new uint[](0),
                hiddenVotes: _hiddenVotes,
                minStake: _minStake,
                alpha: _alpha,
                feeForJuror: _feeForJuror,
                jurorsForCourtJump: _jurorsForCourtJump,
                timesPerPeriod: _timesPerPeriod
            })) - 1
        );
        sortitionSumTrees.createTree(bytes32(subcourtID), _sortitionSumTreeK);

        // Update the parent.
        courts[_parent].children.push(subcourtID);
    }

    /** @dev Changes the `minStake` property value of a specified subcourt. Don't set to a value lower than its parent's `minStake` property value.
     *  @param _subcourtID The ID of the subcourt.
     *  @param _minStake The new value for the `minStake` property value.
     */
    function changeSubcourtMinStake(uint96 _subcourtID, uint _minStake) external onlyByGovernor {
        require(_subcourtID == 0 || courts[courts[_subcourtID].parent].minStake <= _minStake);
        for (uint i = 0; i < courts[_subcourtID].children.length; i++) {
            require(
                courts[courts[_subcourtID].children[i]].minStake >= _minStake,
                "A subcourt cannot be the parent of a subcourt with a lower minimum stake."
            );
        }

        courts[_subcourtID].minStake = _minStake;
    }

    /** @dev Changes the `alpha` property value of a specified subcourt.
     *  @param _subcourtID The ID of the subcourt.
     *  @param _alpha The new value for the `alpha` property value.
     */
    function changeSubcourtAlpha(uint96 _subcourtID, uint _alpha) external onlyByGovernor {
        courts[_subcourtID].alpha = _alpha;
    }

    /** @dev Changes the `feeForJuror` property value of a specified subcourt.
     *  @param _subcourtID The ID of the subcourt.
     *  @param _feeForJuror The new value for the `feeForJuror` property value.
     */
    function changeSubcourtJurorFee(uint96 _subcourtID, uint _feeForJuror) external onlyByGovernor {
        courts[_subcourtID].feeForJuror = _feeForJuror;
    }

    /** @dev Changes the `jurorsForCourtJump` property value of a specified subcourt.
     *  @param _subcourtID The ID of the subcourt.
     *  @param _jurorsForCourtJump The new value for the `jurorsForCourtJump` property value.
     */
    function changeSubcourtJurorsForJump(uint96 _subcourtID, uint _jurorsForCourtJump) external onlyByGovernor {
        courts[_subcourtID].jurorsForCourtJump = _jurorsForCourtJump;
    }

    /** @dev Changes the `timesPerPeriod` property value of a specified subcourt.
     *  @param _subcourtID The ID of the subcourt.
     *  @param _timesPerPeriod The new value for the `timesPerPeriod` property value.
     */
    function changeSubcourtTimesPerPeriod(uint96 _subcourtID, uint[4] _timesPerPeriod) external onlyByGovernor {
        courts[_subcourtID].timesPerPeriod = _timesPerPeriod;
    }

    /** @dev Passes the phase. TRUSTED */
    function passPhase() external {
        if (phase == Phase.staking) {
            require(now - lastPhaseChange >= minStakingTime, "The minimum staking time has not passed yet.");
            require(disputesWithoutJurors > 0, "There are no disputes that need jurors.");
            RNBlock = block.number + 1;
            RNGenerator.requestRN(RNBlock);
            phase = Phase.generating;
        } else if (phase == Phase.generating) {
            RN = RNGenerator.getUncorrelatedRN(RNBlock);
            require(RN != 0, "Random number is not ready yet.");
            phase = Phase.drawing;
        } else if (phase == Phase.drawing) {
            require(disputesWithoutJurors == 0 || now - lastPhaseChange >= maxDrawingTime, "There are still disputes without jurors and the maximum drawing time has not passed yet.");
            phase = Phase.staking;
        }

        lastPhaseChange = now;
        emit NewPhase(phase);
    }

    /** @dev Passes the period of a specified dispute.
     *  @param _disputeID The ID of the dispute.
     */
    function passPeriod(uint _disputeID) external {
        Dispute storage dispute = disputes[_disputeID];
        if (dispute.period == Period.evidence) {
            require(
                dispute.votes.length > 1 || now - dispute.lastPeriodChange >= courts[dispute.subcourtID].timesPerPeriod[uint(dispute.period)],
                "The evidence period time has not passed yet and it is not an appeal."
            );
            require(dispute.drawsInRound == dispute.votes[dispute.votes.length - 1].length, "The dispute has not finished drawing yet.");
            dispute.period = courts[dispute.subcourtID].hiddenVotes ? Period.commit : Period.vote;
        } else if (dispute.period == Period.commit) {
            require(
                now - dispute.lastPeriodChange >= courts[dispute.subcourtID].timesPerPeriod[uint(dispute.period)] || dispute.commitsInRound == dispute.votes[dispute.votes.length - 1].length,
                "The commit period time has not passed yet and not every juror has committed yet."
            );
            dispute.period = Period.vote;
        } else if (dispute.period == Period.vote) {
            require(
                now - dispute.lastPeriodChange >= courts[dispute.subcourtID].timesPerPeriod[uint(dispute.period)] || dispute.votesInEachRound[dispute.votes.length - 1] == dispute.votes[dispute.votes.length - 1].length,
                "The vote period time has not passed yet and not every juror has voted yet."
            );
            dispute.period = Period.appeal;
            emit AppealPossible(_disputeID, dispute.arbitrated);
        } else if (dispute.period == Period.appeal) {
            require(now - dispute.lastPeriodChange >= courts[dispute.subcourtID].timesPerPeriod[uint(dispute.period)], "The appeal period time has not passed yet.");
            dispute.period = Period.execution;
        } else if (dispute.period == Period.execution) {
            revert("The dispute is already in the last period.");
        }

        dispute.lastPeriodChange = now;
        emit NewPeriod(_disputeID, dispute.period);
    }

    /** @dev Sets the caller's stake in a subcourt.
     *  @param _subcourtID The ID of the subcourt.
     *  @param _stake The new stake.
     */
    function setStake(uint96 _subcourtID, uint128 _stake) external {
        require(_setStake(msg.sender, _subcourtID, _stake));
    }

    /** @dev Executes the next delayed set stakes.
     *  @param _iterations The number of delayed set stakes to execute.
     */
    function executeDelayedSetStakes(uint _iterations) external onlyDuringPhase(Phase.staking) {
        uint actualIterations = (nextDelayedSetStake + _iterations) - 1 > lastDelayedSetStake ?
            (lastDelayedSetStake - nextDelayedSetStake) + 1 : _iterations;
        uint newNextDelayedSetStake = nextDelayedSetStake + actualIterations;
        require(newNextDelayedSetStake >= nextDelayedSetStake);
        for (uint i = nextDelayedSetStake; i < newNextDelayedSetStake; i++) {
            DelayedSetStake storage delayedSetStake = delayedSetStakes[i];
            _setStake(delayedSetStake.account, delayedSetStake.subcourtID, delayedSetStake.stake);
            delete delayedSetStakes[i];
        }
        nextDelayedSetStake = newNextDelayedSetStake;
    }

    /** @dev Draws jurors for a dispute. Can be called in parts.
     *  `O(n * k * log_k(j))` where
     *  `n` is the number of iterations to run,
     *  `k` is the number of children per node of the dispute's court's sortition sum tree,
     *  and `j` is the maximum number of jurors that ever staked in it simultaneously.
     *  @param _disputeID The ID of the dispute.
     *  @param _iterations The number of iterations to run.
     */
    function drawJurors(
        uint _disputeID,
        uint _iterations
    ) external onlyDuringPhase(Phase.drawing) onlyDuringPeriod(_disputeID, Period.evidence) {
        Dispute storage dispute = disputes[_disputeID];
        uint endIndex = dispute.drawsInRound + _iterations;
        require(endIndex >= dispute.drawsInRound);

        // Avoid going out of range.
        if (endIndex > dispute.votes[dispute.votes.length - 1].length) endIndex = dispute.votes[dispute.votes.length - 1].length;
        for (uint i = dispute.drawsInRound; i < endIndex; i++) {
            // Draw from sortition tree.
            (
                address drawnAddress,
                uint subcourtID
            ) = stakePathIDToAccountAndSubcourtID(sortitionSumTrees.draw(bytes32(dispute.subcourtID), uint(keccak256(RN, _disputeID, i))));

            // Save the vote.
            dispute.votes[dispute.votes.length - 1][i].account = drawnAddress;
            jurors[drawnAddress].lockedTokens += dispute.tokensAtStakePerJuror[dispute.tokensAtStakePerJuror.length - 1];
            emit Draw(drawnAddress, _disputeID, dispute.votes.length - 1, i);

            // If dispute is fully drawn.
            if (i == dispute.votes[dispute.votes.length - 1].length - 1) disputesWithoutJurors--;
        }
        dispute.drawsInRound = endIndex;
    }

    /** @dev Sets the caller's commit for the specified votes.
     *  `O(n)` where
     *  `n` is the number of votes.
     *  @param _disputeID The ID of the dispute.
     *  @param _voteIDs The IDs of the votes.
     *  @param _commit The commit.
     */
    function castCommit(uint _disputeID, uint[] _voteIDs, bytes32 _commit) external onlyDuringPeriod(_disputeID, Period.commit) {
        Dispute storage dispute = disputes[_disputeID];
        require(_commit != bytes32(0));
        for (uint i = 0; i < _voteIDs.length; i++) {
            require(dispute.votes[dispute.votes.length - 1][_voteIDs[i]].account == msg.sender, "The caller has to own the vote.");
            require(dispute.votes[dispute.votes.length - 1][_voteIDs[i]].commit == bytes32(0), "Already committed this vote.");
            dispute.votes[dispute.votes.length - 1][_voteIDs[i]].commit = _commit;
        }
        dispute.commitsInRound += _voteIDs.length;
    }

    /** @dev Sets the caller's choices for the specified votes.
     *  `O(n)` where
     *  `n` is the number of votes.
     *  @param _disputeID The ID of the dispute.
     *  @param _voteIDs The IDs of the votes.
     *  @param _choice The choice.
     *  @param _salt The salt for the commit if the votes were hidden.
     */
    function castVote(uint _disputeID, uint[] _voteIDs, uint _choice, uint _salt) external onlyDuringPeriod(_disputeID, Period.vote) {
        Dispute storage dispute = disputes[_disputeID];
        require(_voteIDs.length > 0);
        require(_choice <= dispute.numberOfChoices, "The choice has to be less than or equal to the number of choices for the dispute.");

        // Save the votes.
        for (uint i = 0; i < _voteIDs.length; i++) {
            require(dispute.votes[dispute.votes.length - 1][_voteIDs[i]].account == msg.sender, "The caller has to own the vote.");
            require(
                !courts[dispute.subcourtID].hiddenVotes || dispute.votes[dispute.votes.length - 1][_voteIDs[i]].commit == keccak256(_choice, _salt),
                "The commit must match the choice in subcourts with hidden votes."
            );
            require(!dispute.votes[dispute.votes.length - 1][_voteIDs[i]].voted, "Vote already cast.");
            dispute.votes[dispute.votes.length - 1][_voteIDs[i]].choice = _choice;
            dispute.votes[dispute.votes.length - 1][_voteIDs[i]].voted = true;
        }
        dispute.votesInEachRound[dispute.votes.length - 1] += _voteIDs.length;

        // Update winning choice.
        VoteCounter storage voteCounter = dispute.voteCounters[dispute.voteCounters.length - 1];
        voteCounter.counts[_choice] += _voteIDs.length;
        if (_choice == voteCounter.winningChoice) { // Voted for the winning choice.
            if (voteCounter.tied) voteCounter.tied = false; // Potentially broke tie.
        } else { // Voted for another choice.
            if (voteCounter.counts[_choice] == voteCounter.counts[voteCounter.winningChoice]) { // Tie.
                if (!voteCounter.tied) voteCounter.tied = true;
            } else if (voteCounter.counts[_choice] > voteCounter.counts[voteCounter.winningChoice]) { // New winner.
                voteCounter.winningChoice = _choice;
                voteCounter.tied = false;
            }
        }
    }

    /** @dev Computes the token and ETH rewards for a specified appeal in a specified dispute.
     *  @param _disputeID The ID of the dispute.
     *  @param _appeal The appeal.
     *  @return tokenReward The token reward.
     *  @return ETHReward The ETH reward.
     */
    function computeTokenAndETHRewards(uint _disputeID, uint _appeal) private view returns(uint tokenReward, uint ETHReward) {
        Dispute storage dispute = disputes[_disputeID];

        // Distribute penalties and arbitration fees.
        if (dispute.voteCounters[dispute.voteCounters.length - 1].tied) {
            // Distribute penalties and fees evenly between active jurors.
            uint activeCount = dispute.votesInEachRound[_appeal];
            if (activeCount > 0) {
                tokenReward = dispute.penaltiesInEachRound[_appeal] / activeCount;
                ETHReward = dispute.totalFeesForJurors[_appeal] / activeCount;
            } else {
                tokenReward = 0;
                ETHReward = 0;
            }
        } else {
            // Distribute penalties and fees evenly between coherent jurors.
            uint winningChoice = dispute.voteCounters[dispute.voteCounters.length - 1].winningChoice;
            uint coherentCount = dispute.voteCounters[_appeal].counts[winningChoice];
            tokenReward = dispute.penaltiesInEachRound[_appeal] / coherentCount;
            ETHReward = dispute.totalFeesForJurors[_appeal] / coherentCount;
        }
    }

    /** @dev Repartitions tokens and ETH for a specified appeal in a specified dispute. Can be called in parts.
     *  `O(i + u * n * (n + p * log_k(j)))` where
     *  `i` is the number of iterations to run,
     *  `u` is the number of jurors that need to be unstaked,
     *  `n` is the maximum number of subcourts one of these jurors has staked in,
     *  `p` is the depth of the subcourt tree,
     *  `k` is the minimum number of children per node of one of these subcourts' sortition sum tree,
     *  and `j` is the maximum number of jurors that ever staked in one of these subcourts simultaneously.
     *  @param _disputeID The ID of the dispute.
     *  @param _appeal The appeal.
     *  @param _iterations The number of iterations to run.
     */
    function execute(uint _disputeID, uint _appeal, uint _iterations) external onlyDuringPeriod(_disputeID, Period.execution) {
        lockInsolventTransfers = false;
        Dispute storage dispute = disputes[_disputeID];
        uint end = dispute.repartitionsInEachRound[_appeal] + _iterations;
        require(end >= dispute.repartitionsInEachRound[_appeal]);
        uint penaltiesInRoundCache = dispute.penaltiesInEachRound[_appeal]; // For saving gas.
        (uint tokenReward, uint ETHReward) = (0, 0);

        // Avoid going out of range.
        if (
            !dispute.voteCounters[dispute.voteCounters.length - 1].tied &&
            dispute.voteCounters[_appeal].counts[dispute.voteCounters[dispute.voteCounters.length - 1].winningChoice] == 0
        ) {
            // We loop over the votes once as there are no rewards because it is not a tie and no one in this round is coherent with the final outcome.
            if (end > dispute.votes[_appeal].length) end = dispute.votes[_appeal].length;
        } else {
            // We loop over the votes twice, first to collect penalties, and second to distribute them as rewards along with arbitration fees.
            (tokenReward, ETHReward) = dispute.repartitionsInEachRound[_appeal] >= dispute.votes[_appeal].length ? computeTokenAndETHRewards(_disputeID, _appeal) : (0, 0); // Compute rewards if rewarding.
            if (end > dispute.votes[_appeal].length * 2) end = dispute.votes[_appeal].length * 2;
        }
        for (uint i = dispute.repartitionsInEachRound[_appeal]; i < end; i++) {
            Vote storage vote = dispute.votes[_appeal][i % dispute.votes[_appeal].length];
            if (
                vote.voted &&
                (vote.choice == dispute.voteCounters[dispute.voteCounters.length - 1].winningChoice || dispute.voteCounters[dispute.voteCounters.length - 1].tied)
            ) { // Juror was active, and voted coherently or it was a tie.
                if (i >= dispute.votes[_appeal].length) { // Only execute in the second half of the iterations.

                    // Reward.
                    pinakion.transfer(vote.account, tokenReward);
                    // Intentional use to avoid blocking.
                    vote.account.send(ETHReward); // solium-disable-line security/no-send
                    emit TokenAndETHShift(vote.account, _disputeID, int(tokenReward), int(ETHReward));
                    jurors[vote.account].lockedTokens -= dispute.tokensAtStakePerJuror[_appeal];
                }
            } else { // Juror was inactive, or voted incoherently and it was not a tie.
                if (i < dispute.votes[_appeal].length) { // Only execute in the first half of the iterations.

                    // Penalize.
                    uint penalty = dispute.tokensAtStakePerJuror[_appeal] > pinakion.balanceOf(vote.account) ? pinakion.balanceOf(vote.account) : dispute.tokensAtStakePerJuror[_appeal];
                    pinakion.transferFrom(vote.account, this, penalty);
                    emit TokenAndETHShift(vote.account, _disputeID, -int(penalty), 0);
                    penaltiesInRoundCache += penalty;
                    jurors[vote.account].lockedTokens -= dispute.tokensAtStakePerJuror[_appeal];

                    // Unstake juror if his penalty made balance less than his total stake or if he lost due to inactivity.
                    if (pinakion.balanceOf(vote.account) < jurors[vote.account].stakedTokens || !vote.voted)
                        for (uint j = 0; j < jurors[vote.account].subcourtIDs.length; j++)
                            _setStake(vote.account, jurors[vote.account].subcourtIDs[j], 0);

                }
            }
            if (i == dispute.votes[_appeal].length - 1) {
                // Send fees and tokens to the governor if no one was coherent.
                if (dispute.votesInEachRound[_appeal] == 0 || !dispute.voteCounters[dispute.voteCounters.length - 1].tied && dispute.voteCounters[_appeal].counts[dispute.voteCounters[dispute.voteCounters.length - 1].winningChoice] == 0) {
                    // Intentional use to avoid blocking.
                    governor.send(dispute.totalFeesForJurors[_appeal]); // solium-disable-line security/no-send
                    pinakion.transfer(governor, penaltiesInRoundCache);
                } else if (i + 1 < end) {
                    // Compute rewards because we are going into rewarding.
                    dispute.penaltiesInEachRound[_appeal] = penaltiesInRoundCache;
                    (tokenReward, ETHReward) = computeTokenAndETHRewards(_disputeID, _appeal);
                }
            }
        }
        if (dispute.penaltiesInEachRound[_appeal] != penaltiesInRoundCache) dispute.penaltiesInEachRound[_appeal] = penaltiesInRoundCache;
        dispute.repartitionsInEachRound[_appeal] = end;
        lockInsolventTransfers = true;
    }

    /** @dev Executes a specified dispute's ruling. UNTRUSTED.
     *  @param _disputeID The ID of the dispute.
     */
    function executeRuling(uint _disputeID) external onlyDuringPeriod(_disputeID, Period.execution) {
        Dispute storage dispute = disputes[_disputeID];
        require(!dispute.ruled, "Ruling already executed.");
        dispute.ruled = true;
        uint winningChoice = dispute.voteCounters[dispute.voteCounters.length - 1].tied ? 0
            : dispute.voteCounters[dispute.voteCounters.length - 1].winningChoice;
        dispute.arbitrated.rule(_disputeID, winningChoice);
    }

    /* Public */

    /** @dev Creates a dispute. Must be called by the arbitrable contract.
     *  @param _numberOfChoices Number of choices to choose from in the dispute to be created.
     *  @param _extraData Additional info about the dispute to be created. We use it to pass the ID of the subcourt to create the dispute in (first 32 bytes) and the minimum number of jurors required (next 32 bytes).
     *  @return disputeID The ID of the created dispute.
     */
    function createDispute(
        uint _numberOfChoices,
        bytes _extraData
    ) public payable requireArbitrationFee(_extraData) returns(uint disputeID)  {
        (uint96 subcourtID, uint minJurors) = extraDataToSubcourtIDAndMinJurors(_extraData);
        disputeID = disputes.length++;
        Dispute storage dispute = disputes[disputeID];
        dispute.subcourtID = subcourtID;
        dispute.arbitrated = Arbitrable(msg.sender);
        dispute.numberOfChoices = _numberOfChoices;
        dispute.period = Period.evidence;
        dispute.lastPeriodChange = now;
        // As many votes that can be afforded by the provided funds.
        dispute.votes[dispute.votes.length++].length = msg.value / courts[dispute.subcourtID].feeForJuror;
        dispute.voteCounters[dispute.voteCounters.length++].tied = true;
        dispute.tokensAtStakePerJuror.push((courts[dispute.subcourtID].minStake * courts[dispute.subcourtID].alpha) / ALPHA_DIVISOR);
        dispute.totalFeesForJurors.push(msg.value);
        dispute.votesInEachRound.push(0);
        dispute.repartitionsInEachRound.push(0);
        dispute.penaltiesInEachRound.push(0);
        disputesWithoutJurors++;

        emit DisputeCreation(disputeID, Arbitrable(msg.sender));
    }

    /** @dev Appeals the ruling of a specified dispute.
     *  @param _disputeID The ID of the dispute.
     *  @param _extraData Additional info about the appeal. Not used by this contract.
     */
    function appeal(
        uint _disputeID,
        bytes _extraData
    ) public payable requireAppealFee(_disputeID, _extraData) onlyDuringPeriod(_disputeID, Period.appeal) {
        Dispute storage dispute = disputes[_disputeID];
        require(
            msg.sender == address(dispute.arbitrated),
            "Can only be called by the arbitrable contract."
        );
        if (dispute.votes[dispute.votes.length - 1].length >= courts[dispute.subcourtID].jurorsForCourtJump) // Jump to parent subcourt.
            dispute.subcourtID = courts[dispute.subcourtID].parent;
        dispute.period = Period.evidence;
        dispute.lastPeriodChange = now;
        // As many votes that can be afforded by the provided funds.
        dispute.votes[dispute.votes.length++].length = msg.value / courts[dispute.subcourtID].feeForJuror;
        dispute.voteCounters[dispute.voteCounters.length++].tied = true;
        dispute.tokensAtStakePerJuror.push((courts[dispute.subcourtID].minStake * courts[dispute.subcourtID].alpha) / ALPHA_DIVISOR);
        dispute.totalFeesForJurors.push(msg.value);
        dispute.drawsInRound = 0;
        dispute.commitsInRound = 0;
        dispute.votesInEachRound.push(0);
        dispute.repartitionsInEachRound.push(0);
        dispute.penaltiesInEachRound.push(0);
        disputesWithoutJurors++;

        emit AppealDecision(_disputeID, Arbitrable(msg.sender));
        emit NewPeriod(_disputeID, Period.evidence);
    }

    /** @dev Called when `_owner` sends ether to the MiniMe Token contract.
     *  @param _owner The address that sent the ether to create tokens.
     *  @return allowed Whether the operation should be allowed or not.
     */
    function proxyPayment(address _owner) public payable returns(bool allowed) { allowed = false; }

    /** @dev Notifies the controller about a token transfer allowing the controller to react if desired.
     *  @param _from The origin of the transfer.
     *  @param _to The destination of the transfer.
     *  @param _amount The amount of the transfer.
     *  @return allowed Whether the operation should be allowed or not.
     */
    function onTransfer(address _from, address _to, uint _amount) public returns(bool allowed) {
        if (lockInsolventTransfers) { // Never block penalties or rewards.
            uint newBalance = pinakion.balanceOf(_from) - _amount;
            if (newBalance < jurors[_from].stakedTokens || newBalance < jurors[_from].lockedTokens) return false;
        }
        allowed = true;
    }

    /** @dev Notifies the controller about an approval allowing the controller to react if desired.
     *  @param _owner The address that calls `approve()`.
     *  @param _spender The spender in the `approve()` call.
     *  @param _amount The amount in the `approve()` call.
     *  @return allowed Whether the operation should be allowed or not.
     */
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool allowed) { allowed = true; }

    /* Public Views */

    /** @dev Gets the cost of arbitration in a specified subcourt.
     *  @param _extraData Additional info about the dispute. We use it to pass the ID of the subcourt to create the dispute in (first 32 bytes) and the minimum number of jurors required (next 32 bytes).
     *  @return cost The cost.
     */
    function arbitrationCost(bytes _extraData) public view returns(uint cost) {
        (uint96 subcourtID, uint minJurors) = extraDataToSubcourtIDAndMinJurors(_extraData);
        cost = courts[subcourtID].feeForJuror * minJurors;
    }

    /** @dev Gets the cost of appealing a specified dispute.
     *  @param _disputeID The ID of the dispute.
     *  @param _extraData Additional info about the appeal. Not used by this contract.
     *  @return cost The cost.
     */
    function appealCost(uint _disputeID, bytes _extraData) public view returns(uint cost) {
        Dispute storage dispute = disputes[_disputeID];
        uint lastNumberOfJurors = dispute.votes[dispute.votes.length - 1].length;
        if (lastNumberOfJurors >= courts[dispute.subcourtID].jurorsForCourtJump) { // Jump to parent subcourt.
            if (dispute.subcourtID == 0) // Already in the general court.
                cost = NON_PAYABLE_AMOUNT;
            else // Get the cost of the parent subcourt.
                cost = courts[courts[dispute.subcourtID].parent].feeForJuror * ((lastNumberOfJurors * 2) + 1);
        } else // Stay in current subcourt.
            cost = courts[dispute.subcourtID].feeForJuror * ((lastNumberOfJurors * 2) + 1);
    }

    /** @dev Gets the start and end of a specified dispute's current appeal period.
     *  @param _disputeID The ID of the dispute.
     *  @return start The start of the appeal period.
     *  @return end The end of the appeal period.
     */
    function appealPeriod(uint _disputeID) public view returns(uint start, uint end) {
        Dispute storage dispute = disputes[_disputeID];
        if (dispute.period == Period.appeal) {
            start = dispute.lastPeriodChange;
            end = dispute.lastPeriodChange + courts[dispute.subcourtID].timesPerPeriod[uint(Period.appeal)];
        } else {
            start = 0;
            end = 0;
        }
    }

    /** @dev Gets the status of a specified dispute.
     *  @param _disputeID The ID of the dispute.
     *  @return status The status.
     */
    function disputeStatus(uint _disputeID) public view returns(DisputeStatus status) {
        Dispute storage dispute = disputes[_disputeID];
        if (dispute.period < Period.appeal) status = DisputeStatus.Waiting;
        else if (dispute.period < Period.execution) status = DisputeStatus.Appealable;
        else status = DisputeStatus.Solved;
    }

    /** @dev Gets the current ruling of a specified dispute.
     *  @param _disputeID The ID of the dispute.
     *  @return ruling The current ruling.
     */
    function currentRuling(uint _disputeID) public view returns(uint ruling) {
        Dispute storage dispute = disputes[_disputeID];
        ruling = dispute.voteCounters[dispute.voteCounters.length - 1].tied ? 0
            : dispute.voteCounters[dispute.voteCounters.length - 1].winningChoice;
    }

    /* Internal */

    /** @dev Sets the specified juror's stake in a subcourt.
     *  `O(n + p * log_k(j))` where
     *  `n` is the number of subcourts the juror has staked in,
     *  `p` is the depth of the subcourt tree,
     *  `k` is the minimum number of children per node of one of these subcourts' sortition sum tree,
     *  and `j` is the maximum number of jurors that ever staked in one of these subcourts simultaneously.
     *  @param _account The address of the juror.
     *  @param _subcourtID The ID of the subcourt.
     *  @param _stake The new stake.
     *  @return succeeded True if the call succeeded, false otherwise.
     */
    function _setStake(address _account, uint96 _subcourtID, uint128 _stake) internal returns(bool succeeded) {
        if (!(_subcourtID < courts.length))
            return false;

        // Delayed action logic.
        if (phase != Phase.staking) {
            delayedSetStakes[++lastDelayedSetStake] = DelayedSetStake({ account: _account, subcourtID: _subcourtID, stake: _stake });
            return true;
        }

        if (!(_stake == 0 || courts[_subcourtID].minStake <= _stake))
            return false; // The juror's stake cannot be lower than the minimum stake for the subcourt.
        Juror storage juror = jurors[_account];
        bytes32 stakePathID = accountAndSubcourtIDToStakePathID(_account, _subcourtID);
        uint currentStake = sortitionSumTrees.stakeOf(bytes32(_subcourtID), stakePathID);
        if (!(_stake == 0 || currentStake > 0 || juror.subcourtIDs.length < MAX_STAKE_PATHS))
            return false; // Maximum stake paths reached.
        uint newTotalStake = juror.stakedTokens - currentStake + _stake; // Can't overflow because _stake is a uint128.
        if (!(_stake == 0 || pinakion.balanceOf(_account) >= newTotalStake))
            return false; // The juror's total amount of staked tokens cannot be higher than the juror's balance.

        // Update juror's records.
        juror.stakedTokens = newTotalStake;
        if (_stake == 0) {
            for (uint i = 0; i < juror.subcourtIDs.length; i++)
                if (juror.subcourtIDs[i] == _subcourtID) {
                    juror.subcourtIDs[i] = juror.subcourtIDs[juror.subcourtIDs.length - 1];
                    juror.subcourtIDs.length--;
                    break;
                }
        } else if (currentStake == 0) juror.subcourtIDs.push(_subcourtID);

        // Update subcourt parents.
        bool finished = false;
        uint currentSubcourtID = _subcourtID;
        while (!finished) {
            sortitionSumTrees.set(bytes32(currentSubcourtID), _stake, stakePathID);
            if (currentSubcourtID == 0) finished = true;
            else currentSubcourtID = courts[currentSubcourtID].parent;
        }
        emit StakeSet(_account, _subcourtID, _stake, newTotalStake);
        return true;
    }

    /** @dev Gets a subcourt ID and the minimum number of jurors required from a specified extra data bytes array.
     *  @param _extraData The extra data bytes array. The first 32 bytes are the subcourt ID and the next 32 bytes are the minimum number of jurors.
     *  @return subcourtID The subcourt ID.
     *  @return minJurors The minimum number of jurors required.
     */
    function extraDataToSubcourtIDAndMinJurors(bytes _extraData) internal view returns (uint96 subcourtID, uint minJurors) {
        if (_extraData.length >= 64) {
            assembly { // solium-disable-line security/no-inline-assembly
                subcourtID := mload(add(_extraData, 0x20))
                minJurors := mload(add(_extraData, 0x40))
            }
            if (subcourtID >= courts.length) subcourtID = 0;
            if (minJurors == 0) minJurors = MIN_JURORS;
        } else {
            subcourtID = 0;
            minJurors = MIN_JURORS;
        }
    }

    /** @dev Packs an account and a subcourt ID into a stake path ID.
     *  @param _account The account to pack.
     *  @param _subcourtID The subcourt ID to pack.
     *  @return stakePathID The stake path ID.
     */
    function accountAndSubcourtIDToStakePathID(address _account, uint96 _subcourtID) internal pure returns (bytes32 stakePathID) {
        assembly { // solium-disable-line security/no-inline-assembly
            let ptr := mload(0x40)
            for { let i := 0x00 } lt(i, 0x14) { i := add(i, 0x01) } {
                mstore8(add(ptr, i), byte(add(0x0c, i), _account))
            }
            for { let i := 0x14 } lt(i, 0x20) { i := add(i, 0x01) } {
                mstore8(add(ptr, i), byte(i, _subcourtID))
            }
            stakePathID := mload(ptr)
        }
    }

    /** @dev Unpacks a stake path ID into an account and a subcourt ID.
     *  @param _stakePathID The stake path ID to unpack.
     *  @return account The account.
     *  @return subcourtID The subcourt ID.
     */
    function stakePathIDToAccountAndSubcourtID(bytes32 _stakePathID) internal pure returns (address account, uint96 subcourtID) {
        assembly { // solium-disable-line security/no-inline-assembly
            let ptr := mload(0x40)
            for { let i := 0x00 } lt(i, 0x14) { i := add(i, 0x01) } {
                mstore8(add(add(ptr, 0x0c), i), byte(i, _stakePathID))
            }
            account := mload(ptr)
            subcourtID := _stakePathID
        }
    }

    /* Interface Views */

    /** @dev Gets a specified subcourt's non primitive properties.
     *  @param _subcourtID The ID of the subcourt.
     *  @return children The subcourt's child court list.
     *  @return timesPerPeriod The subcourt's time per period.
     */
    function getSubcourt(uint96 _subcourtID) external view returns(
        uint[] children,
        uint[4] timesPerPeriod
    ) {
        Court storage subcourt = courts[_subcourtID];
        children = subcourt.children;
        timesPerPeriod = subcourt.timesPerPeriod;
    }

    /** @dev Gets a specified vote for a specified appeal in a specified dispute.
     *  @param _disputeID The ID of the dispute.
     *  @param _appeal The appeal.
     *  @param _voteID The ID of the vote.
     *  @return account The account for vote.
     *  @return commit  The commit for vote.
     *  @return choice  The choice for vote.
     *  @return voted True if the account voted, False otherwise.
     */
    function getVote(uint _disputeID, uint _appeal, uint _voteID) external view returns(
        address account,
        bytes32 commit,
        uint choice,
        bool voted
    ) {
        Vote storage vote = disputes[_disputeID].votes[_appeal][_voteID];
        account = vote.account;
        commit = vote.commit;
        choice = vote.choice;
        voted = vote.voted;
    }

    /** @dev Gets the vote counter for a specified appeal in a specified dispute.
     *  Note: This function is only to be used by the interface and it won't work if the number of choices is too high.
     *  @param _disputeID The ID of the dispute.
     *  @param _appeal The appeal.
     *  @return winningChoice The winning choice.
     *  @return counts The count.
     *  @return tied Whether the vote tied.
     *  `O(n)` where
     *  `n` is the number of choices of the dispute.
     */
    function getVoteCounter(uint _disputeID, uint _appeal) external view returns(
        uint winningChoice,
        uint[] counts,
        bool tied
    ) {
        Dispute storage dispute = disputes[_disputeID];
        VoteCounter storage voteCounter = dispute.voteCounters[_appeal];
        winningChoice = voteCounter.winningChoice;
        counts = new uint[](dispute.numberOfChoices + 1);
        for (uint i = 0; i <= dispute.numberOfChoices; i++) counts[i] = voteCounter.counts[i];
        tied = voteCounter.tied;
    }

    /** @dev Gets a specified dispute's non primitive properties.
     *  @param _disputeID The ID of the dispute.
     *  @return votesLengths The dispute's vote length.
     *  @return tokensAtStakePerJuror The dispute's required tokens at stake per Juror.
     *  @return totalFeesForJurors The dispute's total fees for Jurors.
     *  @return votesInEachRound The dispute's counter of votes made in each round.
     *  @return repartitionsInEachRound The dispute's counter of vote reward repartitions made in each round.
     *  @return penaltiesInEachRound The dispute's amount of tokens collected from penalties in each round.
     *  `O(a)` where
     *  `a` is the number of appeals of the dispute.
     */
    function getDispute(uint _disputeID) external view returns(
        uint[] votesLengths,
        uint[] tokensAtStakePerJuror,
        uint[] totalFeesForJurors,
        uint[] votesInEachRound,
        uint[] repartitionsInEachRound,
        uint[] penaltiesInEachRound
    ) {
        Dispute storage dispute = disputes[_disputeID];
        votesLengths = new uint[](dispute.votes.length);
        for (uint i = 0; i < dispute.votes.length; i++) votesLengths[i] = dispute.votes[i].length;
        tokensAtStakePerJuror = dispute.tokensAtStakePerJuror;
        totalFeesForJurors = dispute.totalFeesForJurors;
        votesInEachRound = dispute.votesInEachRound;
        repartitionsInEachRound = dispute.repartitionsInEachRound;
        penaltiesInEachRound = dispute.penaltiesInEachRound;
    }

    /** @dev Gets a specified juror's non primitive properties.
     *  @param _account The address of the juror.
     *  @return subcourtIDs The juror's IDs of subcourts where the juror has stake path.
     */
    function getJuror(address _account) external view returns(
        uint96[] subcourtIDs
    ) {
        Juror storage juror = jurors[_account];
        subcourtIDs = juror.subcourtIDs;
    }

    /** @dev Gets the stake of a specified juror in a specified subcourt.
     *  @param _account The address of the juror.
     *  @param _subcourtID The ID of the subcourt.
     *  @return stake The stake.
     */
    function stakeOf(address _account, uint96 _subcourtID) external view returns(uint stake) {
        return sortitionSumTrees.stakeOf(bytes32(_subcourtID), accountAndSubcourtIDToStakePathID(_account, _subcourtID));
    }
}

/**
 *  @authors: [@unknownunknown1]
 *  @reviewers: [@ferittuncer, @clesaege, @satello*, @mtsalenc, @remedcu, @nix1g, @fnanni-0, @MerlinEgalite]
 *  @auditors: []
 *  @bounties: [{ link: https://github.com/kleros/kleros/issues/155, maxPayout: 200 ETH }]
 *  @deployments: []
 *  @tools: [MythX]
 */

/* solium-disable security/no-block-members */
/* solium-disable max-len */
/* solium-disable security/no-send */

pragma solidity ^0.4.26;

import "@kleros/kleros-interaction/contracts/standard/arbitration/Arbitrable.sol";
import "@kleros/kleros-interaction/contracts/libraries/CappedMath.sol";

/** @title KlerosGovernor
 *  Note that this contract trusts that the Arbitrator is honest and will not re-enter or modify its costs during a call.
 *  Also note that tx.origin should not matter in contracts called by the governor.
 */
contract KlerosGovernor is Arbitrable {
    using CappedMath for uint;

    /* *** Contract variables *** */
    enum Status { NoDispute, DisputeCreated, Resolved }

    struct Session {
        Round[] rounds; // Tracks each appeal round of the dispute in the session in the form rounds[appeal].
        uint ruling; // The ruling that was given in this session, if any.
        uint disputeID; // ID given to the dispute of the session, if any.
        uint[] submittedLists; // Tracks all lists that were submitted in a session in the form submittedLists[submissionID].
        uint sumDeposit; // Sum of all submission deposits in a session (minus arbitration fees). This is used to calculate the reward.
        Status status; // Status of a session.
        mapping(bytes32 => bool) alreadySubmitted; // Indicates whether or not the transaction list was already submitted in order to catch duplicates in the form alreadySubmitted[listHash].
        uint durationOffset; // Time in seconds that prolongs the submission period after the first submission, to give other submitters time to react.
    }

    struct Transaction {
        address target; // The address to call.
        uint value; // Value paid by governor contract that will be used as msg.value in the execution.
        bytes data; // Calldata of the transaction.
        bool executed; // Whether the transaction was already executed or not.
    }

    struct Submission {
        address submitter; // The one who submits the list.
        uint deposit; // Value of the deposit paid upon submission of the list.
        Transaction[] txs; // Transactions stored in the list in the form txs[_transactionIndex].
        bytes32 listHash; // A hash chain of all transactions stored in the list. This is used as a unique identifier within a session.
        uint submissionTime; // The time when the list was submitted.
        bool approved; // Whether the list was approved for execution or not.
        uint approvalTime; // The time when the list was approved.
    }

    struct Round {
        mapping (uint => uint) paidFees; // Tracks the fees paid by each side in this round in the form paidFees[submissionID].
        mapping (uint => bool) hasPaid; // True when the side has fully paid its fees, false otherwise in the form hasPaid[submissionID].
        uint feeRewards; // Sum of reimbursable fees and stake rewards available to the parties that made contributions to the side that ultimately wins a dispute.
        mapping(address => mapping (uint => uint)) contributions; // Maps contributors to their contributions for each side in the form contributions[address][submissionID].
        uint successfullyPaid; // Sum of all successfully paid fees paid by all sides.
    }

    uint constant NO_SHADOW_WINNER = uint(-1); // The value that indicates that no one has successfully paid appeal fees in a current round. It's the largest integer and not 0, because 0 can be a valid submission index.

    address public deployer; // The address of the deployer of the contract.

    uint public reservedETH; // Sum of contract's submission deposits and appeal fees. These funds are not to be used in the execution of transactions.

    uint public submissionBaseDeposit; // The base deposit in wei that needs to be paid in order to submit the list.
    uint public submissionTimeout; // Time in seconds allowed for submitting the lists. Once it's passed the contract enters the approval period.
    uint public executionTimeout; // Time in seconds allowed for the execution of approved lists.
    uint public withdrawTimeout; // Time in seconds allowed to withdraw a submitted list.
    uint public sharedMultiplier; // Multiplier for calculating the appeal fee that must be paid by each side in the case where there is no winner/loser (e.g. when the arbitrator ruled "refuse to arbitrate").
    uint public winnerMultiplier; // Multiplier for calculating the appeal fee of the party that won the previous round.
    uint public loserMultiplier; // Multiplier for calculating the appeal fee of the party that lost the previous round.
    uint public constant MULTIPLIER_DIVISOR = 10000; // Divisor parameter for multipliers.

    uint public lastApprovalTime; // The time of the last approval of a transaction list.
    uint public shadowWinner; // Submission index of the first list that paid appeal fees. If it stays the only list that paid appeal fees, it will win regardless of the final ruling.
    uint public metaEvidenceUpdates; // The number of times the meta evidence has been updated. Used to track the latest meta evidence ID.

    Submission[] public submissions; // Stores all created transaction lists. submissions[_listID].
    Session[] public sessions; // Stores all submitting sessions. sessions[_session].

    /* *** Modifiers *** */
    modifier duringSubmissionPeriod() {
        uint offset = sessions[sessions.length - 1].durationOffset;
        require(now - lastApprovalTime <= submissionTimeout.addCap(offset), "Submission time has ended.");
        _;
    }
    modifier duringApprovalPeriod() {
        uint offset = sessions[sessions.length - 1].durationOffset;
        require(now - lastApprovalTime > submissionTimeout.addCap(offset), "Approval time has not started yet.");
        _;
    }
    modifier onlyByGovernor() {require(address(this) == msg.sender, "Only the governor can execute this."); _;}

    /* *** Events *** */
    /** @dev Emitted when a new list is submitted.
     *  @param _listID The index of the transaction list in the array of lists.
     *  @param _submitter The address that submitted the list.
     *  @param _session The number of the current session.
     *  @param _description The string in CSV format that contains labels of list's transactions.
     *  Note that the submitter may give bad descriptions of correct actions, but this is to be seen as UI enhancement, not a critical feature and that would play against him in case of dispute.
     */
    event ListSubmitted(uint indexed _listID, address indexed _submitter, uint indexed _session, string _description);

    /** @dev Constructor.
     *  @param _arbitrator The arbitrator of the contract. It must support appealPeriod.
     *  @param _extraData Extra data for the arbitrator.
     *  @param _submissionBaseDeposit The base deposit required for submission.
     *  @param _submissionTimeout Time in seconds allocated for submitting transaction list.
     *  @param _executionTimeout Time in seconds after approval that allows to execute transactions of the approved list.
     *  @param _withdrawTimeout Time in seconds after submission that allows to withdraw submitted list.
     *  @param _sharedMultiplier Multiplier of the appeal cost that submitters has to pay for a round when there is no winner/loser in the previous round (e.g. when it's the very first round). In basis points.
     *  @param _winnerMultiplier Multiplier of the appeal cost that the winner has to pay for a round. In basis points.
     *  @param _loserMultiplier Multiplier of the appeal cost that the loser has to pay for a round. In basis points.
     */
    constructor (
        Arbitrator _arbitrator,
        bytes _extraData,
        uint _submissionBaseDeposit,
        uint _submissionTimeout,
        uint _executionTimeout,
        uint _withdrawTimeout,
        uint _sharedMultiplier,
        uint _winnerMultiplier,
        uint _loserMultiplier
    ) public Arbitrable(_arbitrator, _extraData) {
        lastApprovalTime = now;
        submissionBaseDeposit = _submissionBaseDeposit;
        submissionTimeout = _submissionTimeout;
        executionTimeout = _executionTimeout;
        withdrawTimeout = _withdrawTimeout;
        sharedMultiplier = _sharedMultiplier;
        winnerMultiplier = _winnerMultiplier;
        loserMultiplier = _loserMultiplier;
        shadowWinner = NO_SHADOW_WINNER;
        sessions.length++;
        deployer = msg.sender;
    }

    /** @dev Sets the meta evidence. Can only be called once.
     *  Convenience function that removes the need to precompute the deployed contract address for the metaevidence data.
     *  @param _metaEvidence The URI of the meta evidence file.
     */
    function setMetaEvidence(string _metaEvidence) external {
        require(msg.sender == deployer, "Can only be called once by the deployer of the contract.");
        deployer = address(0);
        emit MetaEvidence(metaEvidenceUpdates, _metaEvidence);
    }

    /** @dev Changes the value of the base deposit required for submitting a list.
     *  @param _submissionBaseDeposit The new value of the base deposit, in wei.
     */
    function changeSubmissionDeposit(uint _submissionBaseDeposit) public onlyByGovernor {
        submissionBaseDeposit = _submissionBaseDeposit;
    }

    /** @dev Changes the time allocated for submission.
     *  @param _submissionTimeout The new duration of the submission period, in seconds.
     */
    function changeSubmissionTimeout(uint _submissionTimeout) public onlyByGovernor duringSubmissionPeriod {
        submissionTimeout = _submissionTimeout;
    }

    /** @dev Changes the time allocated for list's execution.
     *  @param _executionTimeout The new duration of the execution timeout, in seconds.
     */
    function changeExecutionTimeout(uint _executionTimeout) public onlyByGovernor {
        executionTimeout = _executionTimeout;
    }

    /** @dev Changes list withdrawal timeout. Note that withdrawals are only possible in the first half of the submission period.
     *  @param _withdrawTimeout The new duration of withdraw period, in seconds.
     */
    function changeWithdrawTimeout(uint _withdrawTimeout) public onlyByGovernor {
        withdrawTimeout = _withdrawTimeout;
    }

    /** @dev Changes the proportion of appeal fees that must be added to appeal cost when there is no winner or loser.
     *  @param _sharedMultiplier The new shared multiplier value in basis points.
     */
    function changeSharedMultiplier(uint _sharedMultiplier) public onlyByGovernor {
        sharedMultiplier = _sharedMultiplier;
    }

    /** @dev Changes the proportion of appeal fees that must be added to appeal cost for the winning party.
     *  @param _winnerMultiplier The new winner multiplier value in basis points.
     */
    function changeWinnerMultiplier(uint _winnerMultiplier) public onlyByGovernor {
        winnerMultiplier = _winnerMultiplier;
    }

    /** @dev Changes the proportion of appeal fees that must be added to appeal cost for the losing party.
     *  @param _loserMultiplier The new loser multiplier value in basis points.
     */
    function changeLoserMultiplier(uint _loserMultiplier) public onlyByGovernor {
        loserMultiplier = _loserMultiplier;
    }

    /** @dev Changes the arbitrator of the contract.
     *  @param _arbitrator The new trusted arbitrator.
     *  @param _arbitratorExtraData The extra data used by the new arbitrator.
     */
    function changeArbitrator(Arbitrator _arbitrator, bytes _arbitratorExtraData) public onlyByGovernor duringSubmissionPeriod {
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
    }

    /** @dev Update the meta evidence used for disputes.
     *  @param _metaEvidence URI to the new meta evidence file.
     */
    function changeMetaEvidence(string _metaEvidence) public onlyByGovernor {
        require(deployer == address(0), "Metaevidence was not set.");
        metaEvidenceUpdates++;
        emit MetaEvidence(metaEvidenceUpdates, _metaEvidence);
    }

    /** @dev Creates transaction list based on input parameters and submits it for potential approval and execution.
     *  Transactions must be ordered by their hash.
     *  @param _target List of addresses to call.
     *  @param _value List of values required for respective addresses.
     *  @param _data Concatenated calldata of all transactions of this list.
     *  @param _dataSize List of lengths in bytes required to split calldata for its respective targets.
     *  @param _description String in CSV format that describes list's transactions.
     */
    function submitList (address[] _target, uint[] _value, bytes _data, uint[] _dataSize, string _description) public payable duringSubmissionPeriod {
        require(_target.length == _value.length, "Incorrect input. Target and value arrays must be of the same length.");
        require(_target.length == _dataSize.length, "Incorrect input. Target and datasize arrays must be of the same length.");
        Session storage session = sessions[sessions.length - 1];
        Submission storage submission = submissions[submissions.length++];
        submission.submitter = msg.sender;
        // Do the assignment first to avoid creating a new variable and bypass a 'stack too deep' error.
        submission.deposit = submissionBaseDeposit + arbitrator.arbitrationCost(arbitratorExtraData);
        require(msg.value >= submission.deposit, "Submission deposit must be paid in full.");
        // Using an array to get around the stack limit.
        // 0 - List hash.
        // 1 - Previous transaction hash.
        // 2 - Current transaction hash.
        bytes32[3] memory hashes;
        uint readingPosition;
        for (uint i = 0; i < _target.length; i++) {
            bytes memory readData = new bytes(_dataSize[i]);
            Transaction storage transaction = submission.txs[submission.txs.length++];
            transaction.target = _target[i];
            transaction.value = _value[i];
            for (uint j = 0; j < _dataSize[i]; j++) {
                readData[j] = _data[readingPosition + j];
            }
            transaction.data = readData;
            readingPosition += _dataSize[i];
            hashes[2] = keccak256(abi.encodePacked(transaction.target, transaction.value, transaction.data));
            require(uint(hashes[2]) >= uint(hashes[1]), "The transactions are in incorrect order.");
            hashes[0] = keccak256(abi.encodePacked(hashes[2], hashes[0]));
            hashes[1] = hashes[2];
        }
        require(!session.alreadySubmitted[hashes[0]], "The same list was already submitted earlier.");
        session.alreadySubmitted[hashes[0]] = true;
        submission.listHash = hashes[0];
        submission.submissionTime = now;
        session.sumDeposit += submission.deposit;
        session.submittedLists.push(submissions.length - 1);
        if (session.submittedLists.length == 1)
            session.durationOffset = now.subCap(lastApprovalTime);

        emit ListSubmitted(submissions.length - 1, msg.sender, sessions.length - 1, _description);

        uint remainder = msg.value - submission.deposit;
        if (remainder > 0)
            msg.sender.send(remainder);

        reservedETH += submission.deposit;
    }

    /** @dev Withdraws submitted transaction list. Reimburses submission deposit.
     *  Withdrawal is only possible during the first half of the submission period and during withdrawTimeout seconds after the submission is made.
     *  @param _submissionID Submission's index in the array of submitted lists of the current sesssion.
     *  @param _listHash Hash of a withdrawing list.
     */
    function withdrawTransactionList(uint _submissionID, bytes32 _listHash) public {
        Session storage session = sessions[sessions.length - 1];
        Submission storage submission = submissions[session.submittedLists[_submissionID]];
        require(now - lastApprovalTime <= submissionTimeout / 2, "Lists can be withdrawn only in the first half of the period.");
        // This require statement is an extra check to prevent _submissionID linking to the wrong list because of index swap during withdrawal.
        require(submission.listHash == _listHash, "Provided hash doesn't correspond with submission ID.");
        require(submission.submitter == msg.sender, "Can't withdraw the list created by someone else.");
        require(now - submission.submissionTime <= withdrawTimeout, "Withdrawing time has passed.");
        session.submittedLists[_submissionID] = session.submittedLists[session.submittedLists.length - 1];
        session.alreadySubmitted[_listHash] = false;
        session.submittedLists.length--;
        session.sumDeposit = session.sumDeposit.subCap(submission.deposit);
        msg.sender.transfer(submission.deposit);

        reservedETH = reservedETH.subCap(submission.deposit);
    }

    /** @dev Approves a transaction list or creates a dispute if more than one list was submitted. TRUSTED.
     *  If nothing was submitted changes session.
     */
    function executeSubmissions() public duringApprovalPeriod {
        Session storage session = sessions[sessions.length - 1];
        require(session.status == Status.NoDispute, "Can't approve transaction list while dispute is active.");
        if (session.submittedLists.length == 0) {
            lastApprovalTime = now;
            session.status = Status.Resolved;
            sessions.length++;
        } else if (session.submittedLists.length == 1) {
            Submission storage submission = submissions[session.submittedLists[0]];
            submission.approved = true;
            submission.approvalTime = now;
            uint sumDeposit = session.sumDeposit;
            session.sumDeposit = 0;
            submission.submitter.send(sumDeposit);
            lastApprovalTime = now;
            session.status = Status.Resolved;
            sessions.length++;

            reservedETH = reservedETH.subCap(sumDeposit);
        } else {
            session.status = Status.DisputeCreated;
            uint arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);
            session.disputeID = arbitrator.createDispute.value(arbitrationCost)(session.submittedLists.length, arbitratorExtraData);
            session.rounds.length++;
            session.sumDeposit = session.sumDeposit.subCap(arbitrationCost);

            reservedETH = reservedETH.subCap(arbitrationCost);
            emit Dispute(arbitrator, session.disputeID, metaEvidenceUpdates, sessions.length - 1);
        }
    }

    /** @dev Takes up to the total amount required to fund a side of an appeal. Reimburses the rest. Creates an appeal if at least two lists are funded. TRUSTED.
     *  @param _submissionID Submission's index in the array of submitted lists of the current sesssion. Note that submissionID can be swapped with an ID of a withdrawn list in submission period.
     */
    function fundAppeal(uint _submissionID) public payable {
        Session storage session = sessions[sessions.length - 1];
        require(_submissionID <= session.submittedLists.length - 1, "SubmissionID is out of bounds.");
        require(session.status == Status.DisputeCreated, "No dispute to appeal.");
        require(arbitrator.disputeStatus(session.disputeID) == Arbitrator.DisputeStatus.Appealable, "Dispute is not appealable.");
        (uint appealPeriodStart, uint appealPeriodEnd) = arbitrator.appealPeriod(session.disputeID);
        require(
            now >= appealPeriodStart && now < appealPeriodEnd,
            "Appeal fees must be paid within the appeal period."
        );

        uint winner = arbitrator.currentRuling(session.disputeID);
        uint multiplier;
        // Unlike in submittedLists, in arbitrator "0" is reserved for "refuse to arbitrate" option. So we need to add 1 to map submission IDs with choices correctly.
        if (winner == _submissionID + 1) {
            multiplier = winnerMultiplier;
        } else if (winner == 0) {
            multiplier = sharedMultiplier;
        } else {
            require(now - appealPeriodStart < (appealPeriodEnd - appealPeriodStart)/2, "The loser must pay during the first half of the appeal period.");
            multiplier = loserMultiplier;
        }

        Round storage round = session.rounds[session.rounds.length - 1];
        require(!round.hasPaid[_submissionID], "Appeal fee has already been paid.");
        uint appealCost = arbitrator.appealCost(session.disputeID, arbitratorExtraData);
        uint totalCost = appealCost.addCap((appealCost.mulCap(multiplier)) / MULTIPLIER_DIVISOR);

        // Take up to the amount necessary to fund the current round at the current costs.
        uint contribution; // Amount contributed.
        uint remainingETH; // Remaining ETH to send back.
        (contribution, remainingETH) = calculateContribution(msg.value, totalCost.subCap(round.paidFees[_submissionID]));
        round.contributions[msg.sender][_submissionID] += contribution;
        round.paidFees[_submissionID] += contribution;
        // Add contribution to reward when the fee funding is successful, otherwise it can be withdrawn later.
        if (round.paidFees[_submissionID] >= totalCost) {
            round.hasPaid[_submissionID] = true;
            if (shadowWinner == NO_SHADOW_WINNER)
                shadowWinner = _submissionID;

            round.feeRewards += round.paidFees[_submissionID];
            round.successfullyPaid += round.paidFees[_submissionID];
        }

        // Reimburse leftover ETH.
        msg.sender.send(remainingETH);
        reservedETH += contribution;

        if (shadowWinner != NO_SHADOW_WINNER && shadowWinner != _submissionID && round.hasPaid[_submissionID]) {
            // Two sides are fully funded.
            shadowWinner = NO_SHADOW_WINNER;
            arbitrator.appeal.value(appealCost)(session.disputeID, arbitratorExtraData);
            session.rounds.length++;
            round.feeRewards = round.feeRewards.subCap(appealCost);
            reservedETH = reservedETH.subCap(appealCost);
        }
    }

    /** @dev Returns the contribution value and remainder from available ETH and required amount.
     *  @param _available The amount of ETH available for the contribution.
     *  @param _requiredAmount The amount of ETH required for the contribution.
     *  @return taken The amount of ETH taken.
     *  @return remainder The amount of ETH left from the contribution.
     */
    function calculateContribution(uint _available, uint _requiredAmount)
        internal
        pure
        returns(uint taken, uint remainder)
    {
        if (_requiredAmount > _available)
            taken = _available;
        else {
            taken = _requiredAmount;
            remainder = _available - _requiredAmount;
        }
    }

    /** @dev Sends the fee stake rewards and reimbursements proportional to the contributions made to the winner of a dispute. Reimburses contributions if there is no winner.
     *  @param _beneficiary The address that made contributions to a request.
     *  @param _session The session from which to withdraw.
     *  @param _round The round from which to withdraw.
     *  @param _submissionID Submission's index in the array of submitted lists of the session which the beneficiary contributed to.
     */
    function withdrawFeesAndRewards(address _beneficiary, uint _session, uint _round, uint _submissionID) public {
        Session storage session = sessions[_session];
        Round storage round = session.rounds[_round];
        require(session.status == Status.Resolved, "Session has an ongoing dispute.");
        uint reward;
        // Allow to reimburse if funding of the round was unsuccessful.
        if (!round.hasPaid[_submissionID]) {
            reward = round.contributions[_beneficiary][_submissionID];
        } else if (session.ruling == 0 || !round.hasPaid[session.ruling - 1]) {
            // Reimburse unspent fees proportionally if there is no winner and loser. Also applies to the situation where the ultimate winner didn't pay appeal fees fully.
            reward = round.successfullyPaid > 0
                ? (round.contributions[_beneficiary][_submissionID] * round.feeRewards) / round.successfullyPaid
                : 0;
        } else if (session.ruling - 1 == _submissionID) {
            // Reward the winner. Subtract 1 from ruling to sync submissionID with arbitrator's choice.
            reward = round.paidFees[_submissionID] > 0
                ? (round.contributions[_beneficiary][_submissionID] * round.feeRewards) / round.paidFees[_submissionID]
                : 0;
        }
        round.contributions[_beneficiary][_submissionID] = 0;

        _beneficiary.send(reward); // It is the user responsibility to accept ETH.
        reservedETH = reservedETH.subCap(reward);
    }

    /** @dev Gives a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Refuse to arbitrate".
     */
    function rule(uint _disputeID, uint _ruling) public {
        Session storage session = sessions[sessions.length - 1];
        require(msg.sender == address(arbitrator), "Must be called by the arbitrator.");
        require(session.status == Status.DisputeCreated, "The dispute has already been resolved.");
        require(_ruling <= session.submittedLists.length, "Ruling is out of bounds.");

        if (shadowWinner != NO_SHADOW_WINNER) {
            emit Ruling(Arbitrator(msg.sender), _disputeID, shadowWinner + 1);
            executeRuling(_disputeID, shadowWinner + 1);
        } else {
            emit Ruling(Arbitrator(msg.sender), _disputeID, _ruling);
            executeRuling(_disputeID, _ruling);
        }
    }

    /** @dev Allows to submit evidence for a current session.
     *  @param _evidenceURI Link to evidence.
     */
    function submitEvidence(string _evidenceURI) public {
        if (bytes(_evidenceURI).length > 0)
            emit Evidence(arbitrator, sessions.length - 1, msg.sender, _evidenceURI);
    }

    /** @dev Executes a ruling of a dispute.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Refuse to arbitrate".
     *  If the final ruling is "0" nothing is approved and deposits will stay locked in the contract.
     */
    function executeRuling(uint _disputeID, uint _ruling) internal {
        Session storage session = sessions[sessions.length - 1];
        if (_ruling != 0) {
            Submission storage submission = submissions[session.submittedLists[_ruling - 1]];
            submission.approved = true;
            submission.approvalTime = now;
            submission.submitter.send(session.sumDeposit);
        }
        // If the ruling is "0" the reserved funds of this session become expendable.
        reservedETH = reservedETH.subCap(session.sumDeposit);

        session.sumDeposit = 0;
        shadowWinner = NO_SHADOW_WINNER;
        lastApprovalTime = now;
        session.status = Status.Resolved;
        session.ruling = _ruling;
        sessions.length++;
    }

    /** @dev Executes selected transactions of the list. UNTRUSTED.
     *  @param _listID The index of the transaction list in the array of lists.
     *  @param _cursor Index of the transaction from which to start executing.
     *  @param _count Number of transactions to execute. Executes until the end if set to "0" or number higher than number of transactions in the list.
     */
    function executeTransactionList(uint _listID, uint _cursor, uint _count) public {
        Submission storage submission = submissions[_listID];
        require(submission.approved, "Can't execute list that wasn't approved.");
        require(now - submission.approvalTime <= executionTimeout, "Time to execute the transaction list has passed.");
        for (uint i = _cursor; i < submission.txs.length && (_count == 0 || i < _cursor + _count); i++) {
            Transaction storage transaction = submission.txs[i];
            uint expendableFunds = getExpendableFunds();
            if (!transaction.executed && transaction.value <= expendableFunds) {
                bool callResult = transaction.target.call.value(transaction.value)(transaction.data); // solium-disable-line security/no-call-value
                // An extra check to prevent re-entrancy through target call.
                if (callResult == true) {
                    require(!transaction.executed, "This transaction has already been executed.");
                    transaction.executed = true;
                }
            }
        }
    }

    /** @dev Fallback function to receive funds for the execution of transactions.
     */
    function () public payable {}

    /** @dev Gets the sum of contract funds that are used for the execution of transactions.
     *  @return Contract balance without reserved ETH.
     */
    function getExpendableFunds() public view returns (uint) {
        return address(this).balance.subCap(reservedETH);
    }

    /** @dev Gets the info of the specified transaction in the specified list.
     *  @param _listID The index of the transaction list in the array of lists.
     *  @param _transactionIndex The index of the transaction.
     *  @return The transaction info.
     */
    function getTransactionInfo(uint _listID, uint _transactionIndex)
        public
        view
        returns (
            address target,
            uint value,
            bytes data,
            bool executed
        )
    {
        Submission storage submission = submissions[_listID];
        Transaction storage transaction = submission.txs[_transactionIndex];
        return (
            transaction.target,
            transaction.value,
            transaction.data,
            transaction.executed
        );
    }

    /** @dev Gets the contributions made by a party for a given round of a session.
     *  Note that this function is O(n), where n is the number of submissions in the session. This could exceed the gas limit, therefore this function should only be used for interface display and not by other contracts.
     *  @param _session The ID of the session.
     *  @param _round The position of the round.
     *  @param _contributor The address of the contributor.
     *  @return The contributions.
     */
    function getContributions(
        uint _session,
        uint _round,
        address _contributor
    ) public view returns(uint[] contributions) {
        Session storage session = sessions[_session];
        Round storage round = session.rounds[_round];

        contributions = new uint[](session.submittedLists.length);
        for (uint i = 0; i < contributions.length; i++) {
            contributions[i] = round.contributions[_contributor][i];
        }
    }

    /** @dev Gets the information on a round of a session.
     *  Note that this function is O(n), where n is the number of submissions in the session. This could exceed the gas limit, therefore this function should only be used for interface display and not by other contracts.
     *  @param _session The ID of the session.
     *  @param _round The round to be queried.
     *  @return The round information.
     */
    function getRoundInfo(uint _session, uint _round)
        public
        view
        returns (
            uint[] paidFees,
            bool[] hasPaid,
            uint feeRewards,
            uint successfullyPaid
        )
    {
        Session storage session = sessions[_session];
        Round storage round = session.rounds[_round];
        paidFees = new uint[](session.submittedLists.length);
        hasPaid = new bool[](session.submittedLists.length);

        for (uint i = 0; i < session.submittedLists.length; i++) {
            paidFees[i] = round.paidFees[i];
            hasPaid[i] = round.hasPaid[i];
        }

        feeRewards = round.feeRewards;
        successfullyPaid = round.successfullyPaid;
    }

    /** @dev Gets the array of submitted lists in the session.
     *  Note that this function is O(n), where n is the number of submissions in the session. This could exceed the gas limit, therefore this function should only be used for interface display and not by other contracts.
     *  @param _session The ID of the session.
     *  @return submittedLists Indexes of lists that were submitted during the session.
     */
    function getSubmittedLists(uint _session) public view returns (uint[] submittedLists) {
        Session storage session = sessions[_session];
        submittedLists = session.submittedLists;
    }

    /** @dev Gets the number of transactions in the list.
     *  @param _listID The index of the transaction list in the array of lists.
     *  @return txCount The number of transactions in the list.
     */
    function getNumberOfTransactions(uint _listID) public view returns (uint txCount) {
        Submission storage submission = submissions[_listID];
        return submission.txs.length;
    }

    /** @dev Gets the number of lists created in contract's lifetime.
     *  @return The number of created lists.
     */
    function getNumberOfCreatedLists() public view returns (uint) {
        return submissions.length;
    }

    /** @dev Gets the number of the ongoing session.
     *  @return The number of the ongoing session.
     */
    function getCurrentSessionNumber() public view returns (uint) {
        return sessions.length - 1;
    }

    /** @dev Gets the number rounds in ongoing session.
     *  @return The number of rounds in session.
     */
    function getSessionRoundsNumber(uint _session) public view returns (uint) {
        Session storage session = sessions[_session];
        return session.rounds.length;
    }
}

/**
 *  @title Kleros
 *  @author Clément Lesaege - <[email protected]>
 *  This code implements a simple version of Kleros.
 *  Note that this was the contract used in the first version of Kleros.
 *  Current one is KlerosLiquid.
 *  Bug Bounties: This code hasn't undertaken a bug bounty program yet.
 */

pragma solidity ^0.4.24;

import "@kleros/kleros-interaction/contracts/standard/rng/RNG.sol";
import "@kleros/kleros-interaction/contracts/standard/arbitration/Arbitrator.sol";
import { MiniMeTokenERC20 as Pinakion } from "@kleros/kleros-interaction/contracts/standard/arbitration/ArbitrableTokens/MiniMeTokenERC20.sol";
import { ApproveAndCallFallBack } from "minimetoken/contracts/MiniMeToken.sol";

contract Kleros is Arbitrator, ApproveAndCallFallBack {

    // **************************** //
    // *    Contract variables    * //
    // **************************** //

    // Variables which should not change after initialization.
    Pinakion public pinakion;
    uint public constant NON_PAYABLE_AMOUNT = (2**256 - 2) / 2; // An astronomic amount, practically can't be paid.

    // Variables which will subject to the governance mechanism.
    // Note they will only be able to be changed during the activation period (because a session assumes they don't change after it).
    RNG public rng; // Random Number Generator used to draw jurors.
    uint public arbitrationFeePerJuror = 0.05 ether; // The fee which will be paid to each juror.
    uint16 public defaultNumberJuror = 3; // Number of drawn jurors unless specified otherwise.
    uint public minActivatedToken = 0.1 * 1e18; // Minimum of tokens to be activated (in basic units).
    uint[5] public timePerPeriod; // The minimum time each period lasts (seconds).
    uint public alpha = 2000; // alpha in ‱ (1 / 10 000).
    uint constant ALPHA_DIVISOR = 1e4; // Amount we need to divided alpha in ‱ to get the float value of alpha.
    uint public maxAppeals = 5; // Number of times a dispute can be appealed. When exceeded appeal cost becomes NON_PAYABLE_AMOUNT.
    // Initially, the governor will be an address controlled by the Kleros team. At a later stage,
    // the governor will be switched to a governance contract with liquid voting.
    address public governor; // Address of the governor contract.

    // Variables changing during day to day interaction.
    uint public session = 1;      // Current session of the court.
    uint public lastPeriodChange; // The last time we changed of period (seconds).
    uint public segmentSize;      // Size of the segment of activated tokens.
    uint public rnBlock;          // The block linked with the RN which is requested.
    uint public randomNumber;     // Random number of the session.

    enum Period {
        Activation, // When juror can deposit their tokens and parties give evidences.
        Draw,       // When jurors are drawn at random, note that this period is fast.
        Vote,       // Where jurors can vote on disputes.
        Appeal,     // When parties can appeal the rulings.
        Execution   // When where token redistribution occurs and Kleros call the arbitrated contracts.
    }

    Period public period;

    struct Juror {
        uint balance;      // The amount of tokens the contract holds for this juror.
        // Total number of tokens the jurors can loose in disputes they are drawn in. Those tokens are locked. Note that we can have atStake > balance but it should be statistically unlikely and does not pose issues.
        uint atStake;
        uint lastSession;  // Last session the tokens were activated.
        uint segmentStart; // Start of the segment of activated tokens.
        uint segmentEnd;   // End of the segment of activated tokens.
    }

    mapping (address => Juror) public jurors;

    struct Vote {
        address account; // The juror who casted the vote.
        uint ruling;     // The ruling which was given.
    }

    struct VoteCounter {
        uint winningChoice; // The choice which currently has the highest amount of votes. Is 0 in case of a tie.
        uint winningCount;  // The number of votes for winningChoice. Or for the choices which are tied.
        mapping (uint => uint) voteCount; // voteCount[choice] is the number of votes for choice.
    }

    enum DisputeState { // Not to be confused this with DisputeStatus in Arbitrator contract.
        Open,       // The dispute is opened but the outcome is not available yet (this include when jurors voted but appeal is still possible).
        Resolving,  // The token repartition has started. Note that if it's done in just one call, this state is skipped.
        Executable, // The arbitrated contract can be called to enforce the decision.
        Executed    // Everything has been done and the dispute can't be interacted with anymore.
    }

    struct Dispute {
        Arbitrable arbitrated;       // Contract to be arbitrated.
        uint session;                // First session the dispute was schedule.
        uint appeals;                // Number of appeals.
        uint choices;                // The number of choices available to the jurors.
        uint16 initialNumberJurors;  // The initial number of jurors.
        uint arbitrationFeePerJuror; // The fee which will be paid to each juror.
        DisputeState state;          // The state of the dispute.
        Vote[][] votes;              // The votes in the form vote[appeals][voteID].
        VoteCounter[] voteCounter;   // The vote counters in the form voteCounter[appeals].
        mapping (address => uint) lastSessionVote; // Last session a juror has voted on this dispute. Is 0 if he never did.
        uint currentAppealToRepartition; // The current appeal we are repartitioning.
        AppealsRepartitioned[] appealsRepartitioned; // Track a partially repartitioned appeal in the form AppealsRepartitioned[appeal].
    }

    enum RepartitionStage { // State of the token repartition if oneShotTokenRepartition would throw because there are too many votes.
        Incoherent,
        Coherent,
        AtStake,
        Complete
    }

    struct AppealsRepartitioned {
        uint totalToRedistribute;   // Total amount of tokens we have to redistribute.
        uint nbCoherent;            // Number of coherent jurors for session.
        uint currentIncoherentVote; // Current vote for the incoherent loop.
        uint currentCoherentVote;   // Current vote we need to count.
        uint currentAtStakeVote;    // Current vote we need to count.
        RepartitionStage stage;     // Use with multipleShotTokenRepartition if oneShotTokenRepartition would throw.
    }

    Dispute[] public disputes;

    // **************************** //
    // *          Events          * //
    // **************************** //

    /** @dev Emitted when we pass to a new period.
     *  @param _period The new period.
     *  @param _session The current session.
     */
    event NewPeriod(Period _period, uint indexed _session);

    /** @dev Emitted when a juror wins or loses tokens.
      * @param _account The juror affected.
      * @param _disputeID The ID of the dispute.
      * @param _amount The amount of parts of token which was won. Can be negative for lost amounts.
      */
    event TokenShift(address indexed _account, uint _disputeID, int _amount);

    /** @dev Emited when a juror wins arbitration fees.
      * @param _account The account affected.
      * @param _disputeID The ID of the dispute.
      * @param _amount The amount of weis which was won.
      */
    event ArbitrationReward(address indexed _account, uint _disputeID, uint _amount);

    // **************************** //
    // *         Modifiers        * //
    // **************************** //
    modifier onlyBy(address _account) {require(msg.sender == _account, "Wrong caller."); _;}
    modifier onlyDuring(Period _period) {require(period == _period, "Wrong period."); _;}
    modifier onlyGovernor() {require(msg.sender == governor, "Only callable by the governor."); _;}


    /** @dev Constructor.
     *  @param _pinakion The address of the pinakion contract.
     *  @param _rng The random number generator which will be used.
     *  @param _timePerPeriod The minimal time for each period (seconds).
     *  @param _governor Address of the governor contract.
     */
    constructor(Pinakion _pinakion, RNG _rng, uint[5] _timePerPeriod, address _governor) public {
        pinakion = _pinakion;
        rng = _rng;
        // solium-disable-next-line security/no-block-members
        lastPeriodChange = block.timestamp;
        timePerPeriod = _timePerPeriod;
        governor = _governor;
    }

    // **************************** //
    // *  Functions interacting   * //
    // *  with Pinakion contract  * //
    // **************************** //

    /** @dev Callback of approveAndCall - transfer pinakions of a juror in the contract. Should be called by the pinakion contract. TRUSTED.
     *  @param _from The address making the transfer.
     *  @param _amount Amount of tokens to transfer to Kleros (in basic units).
     */
    function receiveApproval(address _from, uint _amount, address, bytes) public onlyBy(pinakion) {
        require(pinakion.transferFrom(_from, this, _amount), "Transfer failed.");

        jurors[_from].balance += _amount;
    }

    /** @dev Withdraw tokens. Note that we can't withdraw the tokens which are still atStake. 
     *  Jurors can't withdraw their tokens if they have deposited some during this session.
     *  This is to prevent jurors from withdrawing tokens they could lose.
     *  @param _value The amount to withdraw.
     */
    function withdraw(uint _value) public {
        Juror storage juror = jurors[msg.sender];
        // Make sure that there is no more at stake than owned to avoid overflow.
        require(juror.atStake <= juror.balance, "Balance is less than stake.");
        require(_value <= juror.balance-juror.atStake, "Value is more than free balance.");
        require(juror.lastSession != session, "You have deposited in this session.");

        juror.balance -= _value;
        require(pinakion.transfer(msg.sender,_value), "Transfer failed.");
    }

    // **************************** //
    // *      Court functions     * //
    // *    Modifying the state   * //
    // **************************** //

    /** @dev To call to go to a new period. TRUSTED.
     */
    function passPeriod() public {
        // solium-disable-next-line security/no-block-members
        require(block.timestamp - lastPeriodChange >= timePerPeriod[uint8(period)], "Not enough time has passed.");

        if (period == Period.Activation) {
            rnBlock = block.number + 1;
            rng.requestRN(rnBlock);
            period = Period.Draw;
        } else if (period == Period.Draw) {
            randomNumber = rng.getUncorrelatedRN(rnBlock);
            require(randomNumber != 0, "Random number not ready yet.");
            period = Period.Vote;
        } else if (period == Period.Vote) {
            period = Period.Appeal;
        } else if (period == Period.Appeal) {
            period = Period.Execution;
        } else if (period == Period.Execution) {
            period = Period.Activation;
            ++session;
            segmentSize = 0;
            rnBlock = 0;
            randomNumber = 0;
        }

        // solium-disable-next-line security/no-block-members
        lastPeriodChange = block.timestamp;
        emit NewPeriod(period, session);
    }


    /** @dev Deposit tokens in order to have chances of being drawn. Note that once tokens are deposited, 
     *  there is no possibility of depositing more.
     *  @param _value Amount of tokens (in basic units) to deposit.
     */
    function activateTokens(uint _value) public onlyDuring(Period.Activation) {
        Juror storage juror = jurors[msg.sender];
        require(_value <= juror.balance, "Not enough balance.");
        require(_value >= minActivatedToken, "Value is less than the minimum stake.");
        // Verify that tokens were not already activated for this session.
        require(juror.lastSession != session, "You have already activated in this session.");

        juror.lastSession = session;
        juror.segmentStart = segmentSize;
        segmentSize += _value;
        juror.segmentEnd = segmentSize;

    }

    /** @dev Vote a ruling. Juror must input the draw ID he was drawn.
     *  Note that the complexity is O(d), where d is amount of times the juror was drawn.
     *  Since being drawn multiple time is a rare occurrence and that a juror can always vote with less weight than it has, it is not a problem.
     *  But note that it can lead to arbitration fees being kept by the contract and never distributed.
     *  @param _disputeID The ID of the dispute the juror was drawn.
     *  @param _ruling The ruling given.
     *  @param _draws The list of draws the juror was drawn. Draw numbering starts at 1 and the numbers should be increasing.
     */
    function voteRuling(uint _disputeID, uint _ruling, uint[] _draws) public onlyDuring(Period.Vote) {
        Dispute storage dispute = disputes[_disputeID];
        Juror storage juror = jurors[msg.sender];
        VoteCounter storage voteCounter = dispute.voteCounter[dispute.appeals];
        require(dispute.lastSessionVote[msg.sender] != session, "You have already voted."); // Make sure juror hasn't voted yet.
        require(_ruling <= dispute.choices, "Invalid ruling.");
        // Note that it throws if the draws are incorrect.
        require(validDraws(msg.sender, _disputeID, _draws), "Invalid draws.");

        dispute.lastSessionVote[msg.sender] = session;
        voteCounter.voteCount[_ruling] += _draws.length;
        if (voteCounter.winningCount < voteCounter.voteCount[_ruling]) {
            voteCounter.winningCount = voteCounter.voteCount[_ruling];
            voteCounter.winningChoice = _ruling;
        } else if (voteCounter.winningCount==voteCounter.voteCount[_ruling] && _draws.length!=0) { // Verify draw length to be non-zero to avoid the possibility of setting tie by casting 0 votes.
            voteCounter.winningChoice = 0; // It's currently a tie.
        }
        for (uint i = 0; i < _draws.length; ++i) {
            dispute.votes[dispute.appeals].push(Vote({
                account: msg.sender,
                ruling: _ruling
            }));
        }

        juror.atStake += _draws.length * getStakePerDraw();
        uint feeToPay = _draws.length * dispute.arbitrationFeePerJuror;
        msg.sender.transfer(feeToPay);
        emit ArbitrationReward(msg.sender, _disputeID, feeToPay);
    }

    /** @dev Steal part of the tokens and the arbitration fee of a juror who failed to vote.
     *  Note that a juror who voted but without all his weight can't be penalized.
     *  It is possible to not penalize with the maximum weight.
     *  But note that it can lead to arbitration fees being kept by the contract and never distributed.
     *  @param _jurorAddress Address of the juror to steal tokens from.
     *  @param _disputeID The ID of the dispute the juror was drawn.
     *  @param _draws The list of draws the juror was drawn. Numbering starts at 1 and the numbers should be increasing.
     */
    function penalizeInactiveJuror(address _jurorAddress, uint _disputeID, uint[] _draws) public {
        Dispute storage dispute = disputes[_disputeID];
        Juror storage inactiveJuror = jurors[_jurorAddress];
        require(period > Period.Vote, "Must be called after the vote period.");
        require(dispute.lastSessionVote[_jurorAddress] != session, "Juror did vote."); // Verify the juror hasn't voted.
        dispute.lastSessionVote[_jurorAddress] = session; // Update last session to avoid penalizing multiple times.
        require(validDraws(_jurorAddress, _disputeID, _draws), "Invalid draws.");
        uint penality = _draws.length * minActivatedToken * 2 * alpha / ALPHA_DIVISOR;
        // Make sure the penality is not higher than the balance.
        penality = (penality < inactiveJuror.balance) ? penality : inactiveJuror.balance;
        inactiveJuror.balance -= penality;
        emit TokenShift(_jurorAddress, _disputeID, -int(penality));
        jurors[msg.sender].balance += penality / 2; // Give half of the penalty to the caller.
        emit TokenShift(msg.sender, _disputeID, int(penality / 2));
        jurors[governor].balance += penality / 2; // The other half to the governor.
        emit TokenShift(governor, _disputeID, int(penality / 2));
        msg.sender.transfer(_draws.length*dispute.arbitrationFeePerJuror); // Give the arbitration fees to the caller.
    }

    /** @dev Execute all the token repartition.
     *  Note that this function could consume to much gas if there is too much votes. 
     *  It is O(v), where v is the number of votes for this dispute.
     *  In the next version, there will also be a function to execute it in multiple calls 
     *  (but note that one shot execution, if possible, is less expensive).
     *  @param _disputeID ID of the dispute.
     */
    function oneShotTokenRepartition(uint _disputeID) public onlyDuring(Period.Execution) {
        Dispute storage dispute = disputes[_disputeID];
        require(dispute.state == DisputeState.Open, "Dispute is not open.");
        require(dispute.session + dispute.appeals <= session, "Dispute is still active.");

        uint winningChoice = dispute.voteCounter[dispute.appeals].winningChoice;
        uint amountShift = getStakePerDraw();
        for (uint i = 0; i <= dispute.appeals; ++i) {
            // If the result is not a tie, some parties are incoherent. Note that 0 (refuse to arbitrate) winning is not a tie.
            // Result is a tie if the winningChoice is 0 (refuse to arbitrate) and the choice 0 is not the most voted choice.
            // Note that in case of a "tie" among some choices including 0, parties who did not vote 0 are considered incoherent.
            if (winningChoice!=0 || (dispute.voteCounter[dispute.appeals].voteCount[0] == dispute.voteCounter[dispute.appeals].winningCount)) {
                uint totalToRedistribute = 0;
                uint nbCoherent = 0;
                // First loop to penalize the incoherent votes.
                for (uint j = 0; j < dispute.votes[i].length; ++j) {
                    Vote storage vote = dispute.votes[i][j];
                    if (vote.ruling != winningChoice) {
                        Juror storage juror = jurors[vote.account];
                        uint penalty = amountShift<juror.balance ? amountShift : juror.balance;
                        juror.balance -= penalty;
                        emit TokenShift(vote.account, _disputeID, int(-penalty));
                        totalToRedistribute += penalty;
                    } else {
                        ++nbCoherent;
                    }
                }
                if (nbCoherent == 0) { // No one was coherent at this stage. Give the tokens to the governor.
                    jurors[governor].balance += totalToRedistribute;
                    emit TokenShift(governor, _disputeID, int(totalToRedistribute));
                } else { // otherwise, redistribute them.
                    uint toRedistribute = totalToRedistribute / nbCoherent; // Note that few fractions of tokens can be lost but due to the high amount of decimals we don't care.
                    // Second loop to redistribute.
                    for (j = 0; j < dispute.votes[i].length; ++j) {
                        vote = dispute.votes[i][j];
                        if (vote.ruling == winningChoice) {
                            juror = jurors[vote.account];
                            juror.balance += toRedistribute;
                            emit TokenShift(vote.account, _disputeID, int(toRedistribute));
                        }
                    }
                }
            }
            // Third loop to lower the atStake in order to unlock tokens.
            for (j = 0; j < dispute.votes[i].length; ++j) {
                vote = dispute.votes[i][j];
                juror = jurors[vote.account];
                juror.atStake -= amountShift; // Note that it can't underflow due to amountShift not changing between vote and redistribution.
            }
        }
        dispute.state = DisputeState.Executable; // Since it was solved in one shot, go directly to the executable step.
    }

    /** @dev Execute token repartition on a dispute for a specific number of votes.
     *  This should only be called if oneShotTokenRepartition will throw because there are too many votes (will use too much gas).
     *  Note that There are 3 iterations per vote. e.g. A dispute with 1 appeal (2 sessions) and 3 votes per session will have 18 iterations
     *  @param _disputeID ID of the dispute.
     *  @param _maxIterations the maxium number of votes to repartition in this iteration
     */
    function multipleShotTokenRepartition(uint _disputeID, uint _maxIterations) public onlyDuring(Period.Execution) {
        Dispute storage dispute = disputes[_disputeID];
        require(dispute.state <= DisputeState.Resolving, "Dispute is not open.");
        require(dispute.session+dispute.appeals <= session, "Dispute is still active.");
        dispute.state = DisputeState.Resolving; // Mark as resolving so oneShotTokenRepartition cannot be called on dispute.

        uint winningChoice = dispute.voteCounter[dispute.appeals].winningChoice;
        uint amountShift = getStakePerDraw();
        uint currentIterations = 0; // Total votes we have repartitioned this iteration.
        for (uint i = dispute.currentAppealToRepartition; i <= dispute.appeals; ++i) {
            // Allocate space for new AppealsRepartitioned.
            if (dispute.appealsRepartitioned.length < i+1) {
                dispute.appealsRepartitioned.length++;
            }

            // If the result is a tie, no parties are incoherent and no need to move tokens. Note that 0 (refuse to arbitrate) winning is not a tie.
            if (winningChoice==0 && (dispute.voteCounter[dispute.appeals].voteCount[0] != dispute.voteCounter[dispute.appeals].winningCount)) {
                // If ruling is a tie we can skip to at stake.
                dispute.appealsRepartitioned[i].stage = RepartitionStage.AtStake;
            }

            // First loop to penalize the incoherent votes.
            if (dispute.appealsRepartitioned[i].stage == RepartitionStage.Incoherent) {
                for (uint j = dispute.appealsRepartitioned[i].currentIncoherentVote; j < dispute.votes[i].length; ++j) {
                    if (currentIterations >= _maxIterations) {
                        return;
                    }
                    Vote storage vote = dispute.votes[i][j];
                    if (vote.ruling != winningChoice) {
                        Juror storage juror = jurors[vote.account];
                        uint penalty = amountShift<juror.balance ? amountShift : juror.balance;
                        juror.balance -= penalty;
                        emit TokenShift(vote.account, _disputeID, int(-penalty));
                        dispute.appealsRepartitioned[i].totalToRedistribute += penalty;
                    } else {
                        ++dispute.appealsRepartitioned[i].nbCoherent;
                    }

                    ++dispute.appealsRepartitioned[i].currentIncoherentVote;
                    ++currentIterations;
                }

                dispute.appealsRepartitioned[i].stage = RepartitionStage.Coherent;
            }

            // Second loop to reward coherent voters
            if (dispute.appealsRepartitioned[i].stage == RepartitionStage.Coherent) {
                if (dispute.appealsRepartitioned[i].nbCoherent == 0) { // No one was coherent at this stage. Give the tokens to the governor.
                    jurors[governor].balance += dispute.appealsRepartitioned[i].totalToRedistribute;
                    emit TokenShift(governor, _disputeID, int(dispute.appealsRepartitioned[i].totalToRedistribute));
                    dispute.appealsRepartitioned[i].stage = RepartitionStage.AtStake;
                } else { // Otherwise, redistribute them.
                    uint toRedistribute = dispute.appealsRepartitioned[i].totalToRedistribute / dispute.appealsRepartitioned[i].nbCoherent; // Note that few fractions of tokens can be lost but due to the high amount of decimals we don't care.
                    // Second loop to redistribute.
                    for (j = dispute.appealsRepartitioned[i].currentCoherentVote; j < dispute.votes[i].length; ++j) {
                        if (currentIterations >= _maxIterations) {
                            return;
                        }
                        vote = dispute.votes[i][j];
                        if (vote.ruling == winningChoice) {
                            juror = jurors[vote.account];
                            juror.balance += toRedistribute;
                            emit TokenShift(vote.account, _disputeID, int(toRedistribute));
                        }

                        ++currentIterations;
                        ++dispute.appealsRepartitioned[i].currentCoherentVote;
                    }

                    dispute.appealsRepartitioned[i].stage = RepartitionStage.AtStake;
                }
            }

            if (dispute.appealsRepartitioned[i].stage == RepartitionStage.AtStake) {
                // Third loop to lower the atStake in order to unlock tokens.
                for (j = dispute.appealsRepartitioned[i].currentAtStakeVote; j < dispute.votes[i].length; ++j) {
                    if (currentIterations >= _maxIterations) {
                        return;
                    }
                    vote = dispute.votes[i][j];
                    juror = jurors[vote.account];
                    juror.atStake -= amountShift; // Note that it can't underflow due to amountShift not changing between vote and redistribution.

                    ++currentIterations;
                    ++dispute.appealsRepartitioned[i].currentAtStakeVote;
                }

                dispute.appealsRepartitioned[i].stage = RepartitionStage.Complete;
            }

            if (dispute.appealsRepartitioned[i].stage == RepartitionStage.Complete) {
                ++dispute.currentAppealToRepartition;
            }
        }

        dispute.state = DisputeState.Executable;
    }

    // **************************** //
    // *      Court functions     * //
    // *     Constant and Pure    * //
    // **************************** //

    /** @dev Return the amount of jurors which are or will be drawn in the dispute.
     *  The number of jurors is doubled and 1 is added at each appeal. We have proven the formula by recurrence.
     *  This avoid having a variable number of jurors which would be updated in order to save gas.
     *  @param _disputeID The ID of the dispute we compute the amount of jurors.
     *  @return nbJurors The number of jurors which are drawn.
     */
    function amountJurors(uint _disputeID) public view returns (uint nbJurors) {
        Dispute storage dispute = disputes[_disputeID];
        return (dispute.initialNumberJurors + 1) * 2**dispute.appeals - 1;
    }

    /** @dev Must be used to verify that a juror has been draw at least _draws.length times.
     *  We have to require the user to specify the draws that lead the juror to be drawn.
     *  Because doing otherwise (looping through all draws) could consume too much gas.
     *  @param _jurorAddress Address of the juror we want to verify draws.
     *  @param _disputeID The ID of the dispute the juror was drawn.
     *  @param _draws The list of draws the juror was drawn. It draw numbering starts at 1 and the numbers should be increasing.
     *  Note that in most cases this list will just contain 1 number.
     *  @param valid true if the draws are valid.
     */
    function validDraws(address _jurorAddress, uint _disputeID, uint[] _draws) public view returns (bool valid) {
        uint draw = 0;
        Juror storage juror = jurors[_jurorAddress];
        Dispute storage dispute = disputes[_disputeID];
        uint nbJurors = amountJurors(_disputeID);

        if (juror.lastSession != session) return false; // Make sure that the tokens were deposited for this session.
        if (dispute.session+dispute.appeals != session) return false; // Make sure there is currently a dispute.
        if (period <= Period.Draw) return false; // Make sure that jurors are already drawn.
        for (uint i = 0; i < _draws.length; ++i) {
            if (_draws[i] <= draw) return false; // Make sure that draws are always increasing to avoid someone inputing the same multiple times.
            draw = _draws[i];
            if (draw > nbJurors) return false;
            uint position = uint(keccak256(randomNumber, _disputeID, draw)) % segmentSize; // Random position on the segment for draw.
            require(position >= juror.segmentStart, "Invalid draw.");
            require(position < juror.segmentEnd, "Invalid draw.");
        }

        return true;
    }

    // **************************** //
    // *   Arbitrator functions   * //
    // *   Modifying the state    * //
    // **************************** //

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost().
     *  @param _choices Amount of choices the arbitrator can make in this dispute.
     *  @param _extraData Null for the default number. Otherwise, first 16 bytes will be used to return the number of jurors.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(uint _choices, bytes _extraData) public payable returns (uint disputeID) {
        uint16 nbJurors = extraDataToNbJurors(_extraData);
        require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to pay arbitration fees.");

        disputeID = disputes.length++;
        Dispute storage dispute = disputes[disputeID];
        dispute.arbitrated = Arbitrable(msg.sender);
        if (period < Period.Draw) // If drawing did not start schedule it for the current session.
            dispute.session = session;
        else // Otherwise schedule it for the next one.
            dispute.session = session+1;
        dispute.choices = _choices;
        dispute.initialNumberJurors = nbJurors;
        // We store it as the general fee can be changed through the governance mechanism.
        dispute.arbitrationFeePerJuror = arbitrationFeePerJuror;
        dispute.votes.length++;
        dispute.voteCounter.length++;

        DisputeCreation(disputeID, Arbitrable(msg.sender));
        return disputeID;
    }

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Standard but not used by this contract.
     */
    function appeal(uint _disputeID, bytes _extraData) public payable onlyDuring(Period.Appeal) {
        super.appeal(_disputeID,_extraData);
        Dispute storage dispute = disputes[_disputeID];
        require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to pay appeal fees.");
        require(dispute.session+dispute.appeals == session, "Dispute is no longer active."); // Dispute of the current session.
        require(dispute.arbitrated == msg.sender, "Caller is not the arbitrated contract.");
        
        dispute.appeals++;
        dispute.votes.length++;
        dispute.voteCounter.length++;
    }

    /** @dev Execute the ruling of a dispute which is in the state executable. UNTRUSTED.
     *  @param disputeID ID of the dispute to execute the ruling.
     */
    function executeRuling(uint disputeID) public {
        Dispute storage dispute = disputes[disputeID];
        require(dispute.state == DisputeState.Executable, "Dispute is not executable.");

        dispute.state = DisputeState.Executed;
        dispute.arbitrated.rule(disputeID, dispute.voteCounter[dispute.appeals].winningChoice);
    }

    // **************************** //
    // *   Arbitrator functions   * //
    // *    Constant and pure     * //
    // **************************** //

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, 
     *  as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Null for the default number. Other first 16 bits will be used to return the number of jurors.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes _extraData) public view returns (uint fee) {
        return extraDataToNbJurors(_extraData) * arbitrationFeePerJuror;
    }

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, 
     *  as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Is not used there.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint _disputeID, bytes _extraData) public view returns (uint fee) {
        Dispute storage dispute = disputes[_disputeID];

        if(dispute.appeals >= maxAppeals) return NON_PAYABLE_AMOUNT;

        return (2*amountJurors(_disputeID) + 1) * dispute.arbitrationFeePerJuror;
    }

    /** @dev Compute the amount of jurors to be drawn.
     *  @param _extraData Null for the default number. Other first 16 bits will be used to return the number of jurors.
     *  Note that it does not check that the number of jurors is odd, but users are advised to choose a odd number of jurors.
     */
    function extraDataToNbJurors(bytes _extraData) internal view returns (uint16 nbJurors) {
        if (_extraData.length < 2)
            return defaultNumberJuror;
        else
            return (uint16(_extraData[0]) << 8) + uint16(_extraData[1]);
    }

    /** @dev Compute the minimum activated pinakions in alpha.
     *  Note there may be multiple draws for a single user on a single dispute.
     */
    function getStakePerDraw() public view returns (uint minActivatedTokenInAlpha) {
        return (alpha * minActivatedToken) / ALPHA_DIVISOR;
    }


    // **************************** //
    // *     Constant getters     * //
    // **************************** //

    /** @dev Getter for account in Vote.
     *  @param _disputeID ID of the dispute.
     *  @param _appeals Which appeal (or 0 for the initial session).
     *  @param _voteID The ID of the vote for this appeal (or initial session).
     *  @return account The address of the voter.
     */
    function getVoteAccount(uint _disputeID, uint _appeals, uint _voteID) public view returns (address account) {
        return disputes[_disputeID].votes[_appeals][_voteID].account;
    }

    /** @dev Getter for ruling in Vote.
     *  @param _disputeID ID of the dispute.
     *  @param _appeals Which appeal (or 0 for the initial session).
     *  @param _voteID The ID of the vote for this appeal (or initial session).
     *  @return ruling The ruling given by the voter.
     */
    function getVoteRuling(uint _disputeID, uint _appeals, uint _voteID) public view returns (uint ruling) {
        return disputes[_disputeID].votes[_appeals][_voteID].ruling;
    }

    /** @dev Getter for winningChoice in VoteCounter.
     *  @param _disputeID ID of the dispute.
     *  @param _appeals Which appeal (or 0 for the initial session).
     *  @return winningChoice The currently winning choice (or 0 if it's tied). Note that 0 can also be return if the majority refuses to arbitrate.
     */
    function getWinningChoice(uint _disputeID, uint _appeals) public view returns (uint winningChoice) {
        return disputes[_disputeID].voteCounter[_appeals].winningChoice;
    }

    /** @dev Getter for winningCount in VoteCounter.
     *  @param _disputeID ID of the dispute.
     *  @param _appeals Which appeal (or 0 for the initial session).
     *  @return winningCount The amount of votes the winning choice (or those who are tied) has.
     */
    function getWinningCount(uint _disputeID, uint _appeals) public view returns (uint winningCount) {
        return disputes[_disputeID].voteCounter[_appeals].winningCount;
    }

    /** @dev Getter for voteCount in VoteCounter.
     *  @param _disputeID ID of the dispute.
     *  @param _appeals Which appeal (or 0 for the initial session).
     *  @param _choice The choice.
     *  @return voteCount The amount of votes the winning choice (or those who are tied) has.
     */
    function getVoteCount(uint _disputeID, uint _appeals, uint _choice) public view returns (uint voteCount) {
        return disputes[_disputeID].voteCounter[_appeals].voteCount[_choice];
    }

    /** @dev Getter for lastSessionVote in Dispute.
     *  @param _disputeID ID of the dispute.
     *  @param _juror The juror we want to get the last session he voted.
     *  @return lastSessionVote The last session the juror voted.
     */
    function getLastSessionVote(uint _disputeID, address _juror) public view returns (uint lastSessionVote) {
        return disputes[_disputeID].lastSessionVote[_juror];
    }

    /** @dev Is the juror drawn in the draw of the dispute.
     *  @param _disputeID ID of the dispute.
     *  @param _juror The juror.
     *  @param _draw The draw. Note that it starts at 1.
     *  @return drawn True if the juror is drawn, false otherwise.
     */
    function isDrawn(uint _disputeID, address _juror, uint _draw) public view returns (bool drawn) {
        Dispute storage dispute = disputes[_disputeID];
        Juror storage juror = jurors[_juror];
        if (
            juror.lastSession != session || (dispute.session + dispute.appeals != session) || period <= Period.Draw || _draw > amountJurors(_disputeID) || _draw == 0 || segmentSize == 0
        ) {
            return false;
        } else {
            uint position = uint(keccak256(randomNumber,_disputeID,_draw)) % segmentSize;
            return (position >= juror.segmentStart) && (position < juror.segmentEnd);
        }

    }

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The current ruling which will be given if there is no appeal. If it is not available, return 0.
     */
    function currentRuling(uint _disputeID) public view returns (uint ruling) {
        Dispute storage dispute = disputes[_disputeID];
        return dispute.voteCounter[dispute.appeals].winningChoice;
    }

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint _disputeID) public view returns (DisputeStatus status) {
        Dispute storage dispute = disputes[_disputeID];
        if (dispute.session+dispute.appeals < session) // Dispute of past session.
            return DisputeStatus.Solved;
        else if(dispute.session+dispute.appeals == session) { // Dispute of current session.
            if (dispute.state == DisputeState.Open) {
                if (period < Period.Appeal)
                    return DisputeStatus.Waiting;
                else if (period == Period.Appeal)
                    return DisputeStatus.Appealable;
                else return DisputeStatus.Solved;
            } else return DisputeStatus.Solved;
        } else return DisputeStatus.Waiting; // Dispute for future session.
    }

    // **************************** //
    // *     Governor Functions   * //
    // **************************** //

    /** @dev General call function where the contract execute an arbitrary call with data and ETH following governor orders.
     *  @param _data Transaction data.
     *  @param _value Transaction value.
     *  @param _target Transaction target.
     */
    function executeOrder(bytes32 _data, uint _value, address _target) public onlyGovernor {
        _target.call.value(_value)(_data); // solium-disable-line security/no-call-value
    }

    /** @dev Setter for rng.
     *  @param _rng An instance of RNG.
     */
    function setRng(RNG _rng) public onlyGovernor {
        rng = _rng;
    }

    /** @dev Setter for arbitrationFeePerJuror.
     *  @param _arbitrationFeePerJuror The fee which will be paid to each juror.
     */
    function setArbitrationFeePerJuror(uint _arbitrationFeePerJuror) public onlyGovernor {
        arbitrationFeePerJuror = _arbitrationFeePerJuror;
    }

    /** @dev Setter for defaultNumberJuror.
     *  @param _defaultNumberJuror Number of drawn jurors unless specified otherwise.
     */
    function setDefaultNumberJuror(uint16 _defaultNumberJuror) public onlyGovernor {
        defaultNumberJuror = _defaultNumberJuror;
    }

    /** @dev Setter for minActivatedToken.
     *  @param _minActivatedToken Minimum of tokens to be activated (in basic units).
     */
    function setMinActivatedToken(uint _minActivatedToken) public onlyGovernor {
        minActivatedToken = _minActivatedToken;
    }

    /** @dev Setter for timePerPeriod.
     *  @param _timePerPeriod The minimum time each period lasts (seconds).
     */
    function setTimePerPeriod(uint[5] _timePerPeriod) public onlyGovernor {
        timePerPeriod = _timePerPeriod;
    }

    /** @dev Setter for alpha.
     *  @param _alpha Alpha in ‱.
     */
    function setAlpha(uint _alpha) public onlyGovernor {
        alpha = _alpha;
    }

    /** @dev Setter for maxAppeals.
     *  @param _maxAppeals Number of times a dispute can be appealed. When exceeded appeal cost becomes NON_PAYABLE_AMOUNT.
     */
    function setMaxAppeals(uint _maxAppeals) public onlyGovernor {
        maxAppeals = _maxAppeals;
    }

    /** @dev Setter for governor.
     *  @param _governor Address of the governor contract.
     */
    function setGovernor(address _governor) public onlyGovernor {
        governor = _governor;
    }
}

/**
 *  https://contributing.kleros.io/smart-contract-workflow
 *  @authors: [@fnanni-0]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */
pragma solidity ^0.4.24;

import { KlerosLiquid } from "./KlerosLiquid.sol";

/**
 *  @title KlerosLiquidExtraViews
 *  @dev Extra view functions for KlerosLiquid. Not part of bug bounty.
 */
contract KlerosLiquidExtraViews {
    /* Storage */

    KlerosLiquid public klerosLiquid;
    uint private constant NOT_FOUND = uint(-1);

    /* Constructor */

    /** @dev Constructs the KlerosLiquidExtraViews contract.
     *  @param _klerosLiquid The address of KlerosLiquid.
     */
    constructor(KlerosLiquid _klerosLiquid) public {
        klerosLiquid = _klerosLiquid;
    }

    /* External Views */

    /** @dev Gets the stake of a specified juror in a specified subcourt, taking into account delayed set stakes.
     *  @param _account The address of the juror.
     *  @param _subcourtID The ID of the subcourt.
     *  @return The stake.
     */
    function stakeOf(address _account, uint96 _subcourtID) external view returns(uint stake) {
        (
            uint96[] memory subcourtIDs,
            ,
            ,
            uint[] memory subcourtStakes
        ) = getJuror(_account);
        for (uint i = 0; i < subcourtIDs.length; i++) {
            if (_subcourtID + 1 == subcourtIDs[i]) {
                stake = subcourtStakes[i];
            }
        }
    }

    /* Public Views */

    /** @dev Gets a specified juror's properties, taking into account delayed set stakes. Note that subcourt IDs are shifted by 1 so that 0 can be "empty".
     *  @param _account The address of the juror.
     *  @return The juror's properties, taking into account delayed set stakes.
     */
    function getJuror(address _account) public view returns(
        uint96[] subcourtIDs,
        uint stakedTokens,
        uint lockedTokens,
        uint[] subcourtStakes
    ) {
        subcourtIDs = new uint96[](klerosLiquid.MAX_STAKE_PATHS());
        (stakedTokens, lockedTokens) = klerosLiquid.jurors(_account);
        subcourtStakes = new uint[](klerosLiquid.MAX_STAKE_PATHS());

        uint96[] memory actualSubcourtIDs = klerosLiquid.getJuror(_account);
        for (uint i = 0; i < actualSubcourtIDs.length; i++) {
            subcourtIDs[i] = actualSubcourtIDs[i] + 1;
            subcourtStakes[i] = klerosLiquid.stakeOf(_account, actualSubcourtIDs[i]);
        }

        for (i = klerosLiquid.nextDelayedSetStake(); i <= klerosLiquid.lastDelayedSetStake(); i++) {
            (address account, uint96 subcourtID, uint128 stake) = klerosLiquid.delayedSetStakes(i);
            if (_account != account) continue;

            (,, uint courtMinStake,,,) = klerosLiquid.courts(subcourtID);

            if (stake == 0) {
                for (uint j = 0; j < subcourtIDs.length; j++) {
                    if (subcourtID + 1 == subcourtIDs[j]) {
                        stakedTokens = stakedTokens - subcourtStakes[j];
                        subcourtIDs[j] = 0;
                        subcourtStakes[j] = 0;
                        break;
                    }
                }
            } else if (stake >= courtMinStake) {
                uint index = NOT_FOUND;
                for (j = 0; j < subcourtIDs.length; j++) {
                    if (subcourtIDs[j] == 0 && index == NOT_FOUND) {
                        index = j; // Save the first empty index, but keep looking for the subcourt.
                    } else if (subcourtID + 1 == subcourtIDs[j]) {
                        index = j; // Juror is already active in this subcourt. Save and update.
                        break;
                    }
                }

                if (
                    index != NOT_FOUND &&
                    klerosLiquid.pinakion().balanceOf(_account) >= stakedTokens - subcourtStakes[index] + stake
                ) {
                    subcourtIDs[index] = subcourtID + 1;
                    stakedTokens = stakedTokens - subcourtStakes[index] + stake;
                    subcourtStakes[index] = stake;
                }
            }
        }
    }
}

pragma solidity ^0.4.24;

/**
 *  @title PolicyRegistry
 *  @author Enrique Piqueras - <[email protected]>
 *  @dev A contract to maintain a policy for each subcourt.
 */
contract PolicyRegistry {
    /* Events */

    /** @dev Emitted when a policy is updated.
     *  @param _subcourtID The ID of the policy's subcourt.
     *  @param _policy The URI of the policy JSON.
     */
    event PolicyUpdate(uint indexed _subcourtID, string _policy);

    /* Storage */

    address public governor;
    mapping(uint => string) public policies;

    /* Modifiers */

    /** @dev Requires that the sender is the governor. */
    modifier onlyByGovernor() {require(governor == msg.sender, "Can only be called by the governor."); _;}

    /* Constructor */

    /** @dev Constructs the `PolicyRegistry` contract.
     *  @param _governor The governor's address.
     */
    constructor(address _governor) public {governor = _governor;}

    /* External */

    /** @dev Changes the `governor` storage variable.
     *  @param _governor The new value for the `governor` storage variable.
     */
    function changeGovernor(address _governor) external onlyByGovernor {governor = _governor;}

    /** @dev Sets the policy for the specified subcourt.
     *  @param _subcourtID The ID of the specified subcourt.
     *  @param _policy The URI of the policy JSON.
     */
    function setPolicy(uint _subcourtID, string _policy) external onlyByGovernor {
        policies[_subcourtID] = _policy;
        emit PolicyUpdate(_subcourtID, policies[_subcourtID]);
    }
}

/**
*  @title Constant Number Generator
*  @author Clément Lesaege - <[email protected]>
*  @dev A Random Number Generator which always return the same number. Usefull in order to make tests.
*/

pragma solidity ^0.4.15;
import "./RNG.sol";

contract ConstantNG is RNG {

    uint public number;

    /** @dev Constructor.
    *  @param _number The number to always return.
    */
    constructor(uint _number) public {
        number = _number;
    }

    /** @dev Contribute to the reward of a random number. All the ETH will be lost forever.
    *  @param _block Block the random number is linked to.
    */
    function contribute(uint _block) public payable {}


    /** @dev Get the "random number" (which is always the same).
    *  @param _block Block the random number is linked to.
    *  @return RN Random Number. If the number is not ready or has not been required 0 instead.
    */
    function getRN(uint _block) public returns (uint RN) {
        return number;
    }

}

/**
*  @title Random Number Generator Standard
*  @author Clément Lesaege - <[email protected]>
*
*/

pragma solidity ^0.4.15;

contract RNG{

    /** @dev Contribute to the reward of a random number.
    *  @param _block Block the random number is linked to.
    */
    function contribute(uint _block) public payable;

    /** @dev Request a random number.
    *  @param _block Block linked to the request.
    */
    function requestRN(uint _block) public payable {
        contribute(_block);
    }

    /** @dev Get the random number.
    *  @param _block Block the random number is linked to.
    *  @return RN Random Number. If the number is not ready or has not been required 0 instead.
    */
    function getRN(uint _block) public returns (uint RN);

    /** @dev Get a uncorrelated random number. Act like getRN but give a different number for each sender.
    *  This is to prevent users from getting correlated numbers.
    *  @param _block Block the random number is linked to.
    *  @return RN Random Number. If the number is not ready or has not been required 0 instead.
    */
    function getUncorrelatedRN(uint _block) public returns (uint RN) {
        uint baseRN = getRN(_block);
        if (baseRN == 0)
        return 0;
        else
        return uint(keccak256(msg.sender,baseRN));
    }

}

pragma solidity ^0.4.24;

import "./AppealableArbitrator.sol";

/**
 *  @title EnhancedAppealableArbitrator
 *  @author Enrique Piqueras - <[email protected]>
 *  @dev Implementation of `AppealableArbitrator` that supports `appealPeriod`.
 */
contract EnhancedAppealableArbitrator is AppealableArbitrator {
    /* Constructor */

    /** @dev Constructs the `EnhancedAppealableArbitrator` contract.
     *  @param _arbitrationPrice The amount to be paid for arbitration.
     *  @param _arbitrator The back up arbitrator.
     *  @param _arbitratorExtraData Not used by this contract.
     *  @param _timeOut The time out for the appeal period.
     */
    constructor(
        uint _arbitrationPrice,
        Arbitrator _arbitrator,
        bytes _arbitratorExtraData,
        uint _timeOut
    ) public AppealableArbitrator(_arbitrationPrice, _arbitrator, _arbitratorExtraData, _timeOut) {}

    /* Public Views */

    /** @dev Compute the start and end of the dispute's current or next appeal period, if possible.
     *  @param _disputeID ID of the dispute.
     *  @return The start and end of the period.
     */
    function appealPeriod(uint _disputeID) public view returns(uint start, uint end) {
        if (appealDisputes[_disputeID].arbitrator != Arbitrator(address(0)))
            (start, end) = appealDisputes[_disputeID].arbitrator.appealPeriod(appealDisputes[_disputeID].appealDisputeID);
        else {
            start = appealDisputes[_disputeID].rulingTime;
            require(start != 0, "The specified dispute is not appealable.");
            end = start + timeOut;
        }
    }
}

/**
*  https://contributing.kleros.io/smart-contract-workflow
*  @authors: [@epiqueras, @ferittuncer]
*  @reviewers: []
*  @auditors: []
*  @bounties: []
*  @deployments: []
*/

pragma solidity ^0.4.24;

import "./CentralizedArbitrator.sol";

/**
 *  @title AppealableArbitrator
 *  @dev A centralized arbitrator that can be appealed.
 */
contract AppealableArbitrator is CentralizedArbitrator, Arbitrable {
    /* Structs */

    struct AppealDispute {
        uint rulingTime;
        Arbitrator arbitrator;
        uint appealDisputeID;
    }

    /* Storage */

    uint public timeOut;
    mapping(uint => AppealDispute) public appealDisputes;
    mapping(uint => uint) public appealDisputeIDsToDisputeIDs;

    /* Constructor */

    /** @dev Constructs the `AppealableArbitrator` contract.
     *  @param _arbitrationPrice The amount to be paid for arbitration.
     *  @param _arbitrator The back up arbitrator.
     *  @param _arbitratorExtraData Not used by this contract.
     *  @param _timeOut The time out for the appeal period.
     */
    constructor(
        uint _arbitrationPrice,
        Arbitrator _arbitrator,
        bytes _arbitratorExtraData,
        uint _timeOut
    ) public CentralizedArbitrator(_arbitrationPrice) Arbitrable(_arbitrator, _arbitratorExtraData) {
        timeOut = _timeOut;
    }

    /* External */

    /** @dev Changes the back up arbitrator.
     *  @param _arbitrator The new back up arbitrator.
     */
    function changeArbitrator(Arbitrator _arbitrator) external onlyOwner {
        arbitrator = _arbitrator;
    }

    /** @dev Changes the time out.
     *  @param _timeOut The new time out.
     */
    function changeTimeOut(uint _timeOut) external onlyOwner {
        timeOut = _timeOut;
    }

    /* External Views */

    /** @dev Gets the specified dispute's latest appeal ID.
     *  @param _disputeID The ID of the dispute.
     */
    function getAppealDisputeID(uint _disputeID) external view returns(uint disputeID) {
        if (appealDisputes[_disputeID].arbitrator != Arbitrator(address(0)))
            disputeID = AppealableArbitrator(appealDisputes[_disputeID].arbitrator).getAppealDisputeID(appealDisputes[_disputeID].appealDisputeID);
        else disputeID = _disputeID;
    }

    /* Public */

    /** @dev Appeals a ruling.
     *  @param _disputeID The ID of the dispute.
     *  @param _extraData Additional info about the appeal.
     */
    function appeal(uint _disputeID, bytes _extraData) public payable requireAppealFee(_disputeID, _extraData) {
        super.appeal(_disputeID, _extraData);
        if (appealDisputes[_disputeID].arbitrator != Arbitrator(address(0)))
            appealDisputes[_disputeID].arbitrator.appeal.value(msg.value)(appealDisputes[_disputeID].appealDisputeID, _extraData);
        else {
            appealDisputes[_disputeID].arbitrator = arbitrator;
            appealDisputes[_disputeID].appealDisputeID = arbitrator.createDispute.value(msg.value)(disputes[_disputeID].choices, _extraData);
            appealDisputeIDsToDisputeIDs[appealDisputes[_disputeID].appealDisputeID] = _disputeID;
        }
    }

    /** @dev Gives a ruling.
     *  @param _disputeID The ID of the dispute.
     *  @param _ruling The ruling.
     */
    function giveRuling(uint _disputeID, uint _ruling) public {
        require(disputes[_disputeID].status != DisputeStatus.Solved, "The specified dispute is already resolved.");
        if (appealDisputes[_disputeID].arbitrator != Arbitrator(address(0))) {
            require(Arbitrator(msg.sender) == appealDisputes[_disputeID].arbitrator, "Appealed disputes must be ruled by their back up arbitrator.");
            super._giveRuling(_disputeID, _ruling);
        } else {
            require(msg.sender == owner, "Not appealed disputes must be ruled by the owner.");
            if (disputes[_disputeID].status == DisputeStatus.Appealable) {
                if (now - appealDisputes[_disputeID].rulingTime > timeOut)
                    super._giveRuling(_disputeID, disputes[_disputeID].ruling);
                else revert("Time out time has not passed yet.");
            } else {
                disputes[_disputeID].ruling = _ruling;
                disputes[_disputeID].status = DisputeStatus.Appealable;
                appealDisputes[_disputeID].rulingTime = now;
                emit AppealPossible(_disputeID, disputes[_disputeID].arbitrated);
            }
        }
    }

    /* Public Views */

    /** @dev Gets the cost of appeal for the specified dispute.
     *  @param _disputeID The ID of the dispute.
     *  @param _extraData Additional info about the appeal.
     *  @return The cost of the appeal.
     */
    function appealCost(uint _disputeID, bytes _extraData) public view returns(uint cost) {
        if (appealDisputes[_disputeID].arbitrator != Arbitrator(address(0)))
            cost = appealDisputes[_disputeID].arbitrator.appealCost(appealDisputes[_disputeID].appealDisputeID, _extraData);
        else if (disputes[_disputeID].status == DisputeStatus.Appealable) cost = arbitrator.arbitrationCost(_extraData);
        else cost = NOT_PAYABLE_VALUE;
    }

    /** @dev Gets the status of the specified dispute.
     *  @param _disputeID The ID of the dispute.
     *  @return The status.
     */
    function disputeStatus(uint _disputeID) public view returns(DisputeStatus status) {
        if (appealDisputes[_disputeID].arbitrator != Arbitrator(address(0)))
            status = appealDisputes[_disputeID].arbitrator.disputeStatus(appealDisputes[_disputeID].appealDisputeID);
        else status = disputes[_disputeID].status;
    }

    /** @dev Return the ruling of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return ruling The ruling which would or has been given.
     */
    function currentRuling(uint _disputeID) public view returns(uint ruling) {
        if (appealDisputes[_disputeID].arbitrator != Arbitrator(address(0))) // Appealed.
            ruling = appealDisputes[_disputeID].arbitrator.currentRuling(appealDisputes[_disputeID].appealDisputeID); // Retrieve ruling from the arbitrator whom the dispute is appealed to.
        else ruling = disputes[_disputeID].ruling; //  Not appealed, basic case.
    }

    /* Internal */

    /** @dev Executes the ruling of the specified dispute.
     *  @param _disputeID The ID of the dispute.
     *  @param _ruling The ruling.
     */
    function executeRuling(uint _disputeID, uint _ruling) internal {
        require(
            appealDisputes[appealDisputeIDsToDisputeIDs[_disputeID]].arbitrator != Arbitrator(address(0)),
            "The dispute must have been appealed."
        );
        giveRuling(appealDisputeIDsToDisputeIDs[_disputeID], _ruling);
    }
}

/**
 *  @authors: [@clesaege, @n1c01a5, @epiqueras, @ferittuncer]
 *  @reviewers: [@clesaege*, @unknownunknown1*]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.4.15;

import "./Arbitrator.sol";

/** @title Centralized Arbitrator
 *  @dev This is a centralized arbitrator deciding alone on the result of disputes. No appeals are possible.
 */
contract CentralizedArbitrator is Arbitrator {

    address public owner = msg.sender;
    uint arbitrationPrice; // Not public because arbitrationCost already acts as an accessor.
    uint constant NOT_PAYABLE_VALUE = (2**256-2)/2; // High value to be sure that the appeal is too expensive.

    struct DisputeStruct {
        Arbitrable arbitrated;
        uint choices;
        uint fee;
        uint ruling;
        DisputeStatus status;
    }

    modifier onlyOwner {require(msg.sender==owner, "Can only be called by the owner."); _;}

    DisputeStruct[] public disputes;

    /** @dev Constructor. Set the initial arbitration price.
     *  @param _arbitrationPrice Amount to be paid for arbitration.
     */
    constructor(uint _arbitrationPrice) public {
        arbitrationPrice = _arbitrationPrice;
    }

    /** @dev Set the arbitration price. Only callable by the owner.
     *  @param _arbitrationPrice Amount to be paid for arbitration.
     */
    function setArbitrationPrice(uint _arbitrationPrice) public onlyOwner {
        arbitrationPrice = _arbitrationPrice;
    }

    /** @dev Cost of arbitration. Accessor to arbitrationPrice.
     *  @param _extraData Not used by this contract.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes _extraData) public view returns(uint fee) {
        return arbitrationPrice;
    }

    /** @dev Cost of appeal. Since it is not possible, it's a high value which can never be paid.
     *  @param _disputeID ID of the dispute to be appealed. Not used by this contract.
     *  @param _extraData Not used by this contract.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint _disputeID, bytes _extraData) public view returns(uint fee) {
        return NOT_PAYABLE_VALUE;
    }

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost().
     *  @param _choices Amount of choices the arbitrator can make in this dispute. When ruling ruling<=choices.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(uint _choices, bytes _extraData) public payable returns(uint disputeID)  {
        super.createDispute(_choices, _extraData);
        disputeID = disputes.push(DisputeStruct({
            arbitrated: Arbitrable(msg.sender),
            choices: _choices,
            fee: msg.value,
            ruling: 0,
            status: DisputeStatus.Waiting
            })) - 1; // Create the dispute and return its number.
        emit DisputeCreation(disputeID, Arbitrable(msg.sender));
    }

    /** @dev Give a ruling. UNTRUSTED.
     *  @param _disputeID ID of the dispute to rule.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 means "Not able/wanting to make a decision".
     */
    function _giveRuling(uint _disputeID, uint _ruling) internal {
        DisputeStruct storage dispute = disputes[_disputeID];
        require(_ruling <= dispute.choices, "Invalid ruling.");
        require(dispute.status != DisputeStatus.Solved, "The dispute must not be solved already.");

        dispute.ruling = _ruling;
        dispute.status = DisputeStatus.Solved;

        msg.sender.send(dispute.fee); // Avoid blocking.
        dispute.arbitrated.rule(_disputeID,_ruling);
    }

    /** @dev Give a ruling. UNTRUSTED.
     *  @param _disputeID ID of the dispute to rule.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 means "Not able/wanting to make a decision".
     */
    function giveRuling(uint _disputeID, uint _ruling) public onlyOwner {
        return _giveRuling(_disputeID, _ruling);
    }

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint _disputeID) public view returns(DisputeStatus status) {
        return disputes[_disputeID].status;
    }

    /** @dev Return the ruling of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return ruling The ruling which would or has been given.
     */
    function currentRuling(uint _disputeID) public view returns(uint ruling) {
        return disputes[_disputeID].ruling;
    }
}

/**
 *  @title Arbitrator
 *  @author Clément Lesaege - <[email protected]>
 *  Bug Bounties: This code hasn't undertaken a bug bounty program yet.
 */

pragma solidity ^0.4.15;

import "./Arbitrable.sol";

/** @title Arbitrator
 *  Arbitrator abstract contract.
 *  When developing arbitrator contracts we need to:
 *  -Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, use nbDisputes).
 *  -Define the functions for cost display (arbitrationCost and appealCost).
 *  -Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
contract Arbitrator {

    enum DisputeStatus {Waiting, Appealable, Solved}

    modifier requireArbitrationFee(bytes _extraData) {
        require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to cover arbitration costs.");
        _;
    }
    modifier requireAppealFee(uint _disputeID, bytes _extraData) {
        require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to cover appeal costs.");
        _;
    }

    /** @dev To be raised when a dispute is created.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev To be raised when a dispute can be appealed.
     *  @param _disputeID ID of the dispute.
     */
    event AppealPossible(uint indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev To be raised when the current ruling is appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost(_extraData).
     *  @param _choices Amount of choices the arbitrator can make in this dispute.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(uint _choices, bytes _extraData) public requireArbitrationFee(_extraData) payable returns(uint disputeID) {}

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes _extraData) public view returns(uint fee);

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint _disputeID, bytes _extraData) public requireAppealFee(_disputeID,_extraData) payable {
        emit AppealDecision(_disputeID, Arbitrable(msg.sender));
    }

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint _disputeID, bytes _extraData) public view returns(uint fee);

    /** @dev Compute the start and end of the dispute's current or next appeal period, if possible.
     *  @param _disputeID ID of the dispute.
     *  @return The start and end of the period.
     */
    function appealPeriod(uint _disputeID) public view returns(uint start, uint end) {}

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint _disputeID) public view returns(DisputeStatus status);

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint _disputeID) public view returns(uint ruling);
}

/**
 *  @title Arbitrable
 *  @author Clément Lesaege - <[email protected]>
 *  Bug Bounties: This code hasn't undertaken a bug bounty program yet.
 */

pragma solidity ^0.4.15;

import "./IArbitrable.sol";

/** @title Arbitrable
 *  Arbitrable abstract contract.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract. We should do so in executeRuling.
 *  -Allow dispute creation. For this a function must:
 *      -Call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 *      -Create the event Dispute(_arbitrator,_disputeID,_rulingOptions);
 */
contract Arbitrable is IArbitrable {
    Arbitrator public arbitrator;
    bytes public arbitratorExtraData; // Extra data to require particular dispute and appeal behaviour.

    modifier onlyArbitrator {require(msg.sender == address(arbitrator), "Can only be called by the arbitrator."); _;}

    /** @dev Constructor. Choose the arbitrator.
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     */
    constructor(Arbitrator _arbitrator, bytes _arbitratorExtraData) public {
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
    }

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) public onlyArbitrator {
        emit Ruling(Arbitrator(msg.sender),_disputeID,_ruling);

        executeRuling(_disputeID,_ruling);
    }


    /** @dev Execute a ruling of a dispute.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function executeRuling(uint _disputeID, uint _ruling) internal;
}

/**
 *  @title IArbitrable
 *  @author Enrique Piqueras - <[email protected]>
 *  Bug Bounties: This code hasn't undertaken a bug bounty program yet.
 */

pragma solidity ^0.4.15;

import "./Arbitrator.sol";

/** @title IArbitrable
 *  Arbitrable interface.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract. We should do so in executeRuling.
 *  -Allow dispute creation. For this a function must:
 *      -Call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 *      -Create the event Dispute(_arbitrator,_disputeID,_rulingOptions);
 */
interface IArbitrable {
    /** @dev To be emmited when meta-evidence is submitted.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidence A link to the meta-evidence JSON.
     */
    event MetaEvidence(uint indexed _metaEvidenceID, string _evidence);

    /** @dev To be emmited when a dispute is created to link the correct meta-evidence to the disputeID
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID, uint _evidenceGroupID);

    /** @dev To be raised when evidence are submitted. Should point to the ressource (evidences are not to be stored on chain due to gas considerations).
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     *  @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     *  @param _evidence A URI to the evidence JSON file whose name should be its keccak256 hash followed by .json.
     */
    event Evidence(Arbitrator indexed _arbitrator, uint indexed _evidenceGroupID, address indexed _party, string _evidence);

    /** @dev To be raised when a ruling is given.
     *  @param _arbitrator The arbitrator giving the ruling.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling The ruling which was given.
     */
    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) external;
}

/**
 *  @title Two-Party Arbitrable
 *  @author Clément Lesaege - <[email protected]>
 *  Bug Bounties: This code hasn't undertaken a bug bounty program yet.
 */


pragma solidity ^0.4.15;
import "./Arbitrable.sol";


/** @title Two-Party Arbitrable
 *  @dev A contract between two parties which can be arbitrated. Both parties has to pay for the arbitration fee. The winning party will get its fee refunded.
 *  To develop a contract inheriting from this one, you need to:
 *  - Redefine RULING_OPTIONS to explain the consequences of the possible rulings.
 *  - Redefine executeRuling while still calling super.executeRuling to implement the results of the arbitration.
 */
contract TwoPartyArbitrable is Arbitrable {
    uint public timeout; // Time in second a party can take before being considered unresponding and lose the dispute.
    uint8 public amountOfChoices;
    address public partyA;
    address public partyB;
    uint public partyAFee; // Total fees paid by the partyA.
    uint public partyBFee; // Total fees paid by the partyB.
    uint public lastInteraction; // Last interaction for the dispute procedure.
    uint public disputeID;
    enum Status {NoDispute, WaitingPartyA, WaitingPartyB, DisputeCreated, Resolved}
    Status public status;

    uint8 constant PARTY_A_WINS = 1;
    uint8 constant PARTY_B_WINS = 2;
    string constant RULING_OPTIONS = "Party A wins;Party B wins"; // A plain English of what rulings do. Need to be redefined by the child class.

    modifier onlyPartyA{require(msg.sender == partyA, "Can only be called by party A."); _;}
    modifier onlyPartyB{require(msg.sender == partyB, "Can only be called by party B."); _;}
    modifier onlyParty{require(msg.sender == partyA || msg.sender == partyB, "Can only be called by party A or party B."); _;}

    enum Party {PartyA, PartyB}

    /** @dev Indicate that a party has to pay a fee or would otherwise be considered as loosing.
     *  @param _party The party who has to pay.
     */
    event HasToPayFee(Party _party);

    /** @dev Constructor. Choose the arbitrator.
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _timeout Time after which a party automatically loose a dispute.
     *  @param _partyB The recipient of the transaction.
     *  @param _amountOfChoices The number of ruling options available.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     *  @param _metaEvidence Link to the meta-evidence.
     */
    constructor(
        Arbitrator _arbitrator,
        uint _timeout,
        address _partyB,
        uint8 _amountOfChoices,
        bytes _arbitratorExtraData,
        string _metaEvidence
    )
        Arbitrable(_arbitrator,_arbitratorExtraData)
        public
    {
        timeout = _timeout;
        partyA = msg.sender;
        partyB = _partyB;
        amountOfChoices = _amountOfChoices;
        emit MetaEvidence(0, _metaEvidence);
    }


    /** @dev Pay the arbitration fee to raise a dispute. To be called by the party A. UNTRUSTED.
     *  Note that the arbitrator can have createDispute throw, which will make this function
     *  throw and therefore lead to a party being timed-out.
     *  This is not a vulnerability as the arbitrator can rule in favor of one party anyway.
     */
    function payArbitrationFeeByPartyA() public payable onlyPartyA {
        uint arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);
        partyAFee += msg.value;
        require(
            partyAFee >= arbitrationCost,
            "Not enough ETH to cover arbitration costs."
        ); // Require that the total pay at least the arbitration cost.
        require(status < Status.DisputeCreated, "Dispute has already been created."); // Make sure a dispute has not been created yet.

        lastInteraction = now;
        // The partyB still has to pay. This can also happens if he has paid, but arbitrationCost has increased.
        if (partyBFee < arbitrationCost) {
            status = Status.WaitingPartyB;
            emit HasToPayFee(Party.PartyB);
        } else { // The partyB has also paid the fee. We create the dispute
            raiseDispute(arbitrationCost);
        }
    }


    /** @dev Pay the arbitration fee to raise a dispute. To be called by the party B. UNTRUSTED.
     *  Note that this function mirror payArbitrationFeeByPartyA.
     */
    function payArbitrationFeeByPartyB() public payable onlyPartyB {
        uint arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);
        partyBFee += msg.value;
        require(
            partyBFee >= arbitrationCost,
            "Not enough ETH to cover arbitration costs."
        ); // Require that the total pay at least the arbitration cost.
        require(status < Status.DisputeCreated, "Dispute has already been created."); // Make sure a dispute has not been created yet.

        lastInteraction = now;
        // The partyA still has to pay. This can also happens if he has paid, but arbitrationCost has increased.
        if (partyAFee < arbitrationCost) {
            status = Status.WaitingPartyA;
            emit HasToPayFee(Party.PartyA);
        } else { // The partyA has also paid the fee. We create the dispute
            raiseDispute(arbitrationCost);
        }
    }

    /** @dev Create a dispute. UNTRUSTED.
     *  @param _arbitrationCost Amount to pay the arbitrator.
     */
    function raiseDispute(uint _arbitrationCost) internal {
        status = Status.DisputeCreated;
        disputeID = arbitrator.createDispute.value(_arbitrationCost)(amountOfChoices,arbitratorExtraData);
        emit Dispute(arbitrator, disputeID, 0, 0);
    }

    /** @dev Reimburse partyA if partyB fails to pay the fee.
     */
    function timeOutByPartyA() public onlyPartyA {
        require(status == Status.WaitingPartyB, "Not waiting for party B.");
        require(now >= lastInteraction + timeout, "The timeout time has not passed.");

        executeRuling(disputeID,PARTY_A_WINS);
    }

    /** @dev Pay partyB if partyA fails to pay the fee.
     */
    function timeOutByPartyB() public onlyPartyB {
        require(status == Status.WaitingPartyA, "Not waiting for party A.");
        require(now >= lastInteraction + timeout, "The timeout time has not passed.");

        executeRuling(disputeID,PARTY_B_WINS);
    }

    /** @dev Submit a reference to evidence. EVENT.
     *  @param _evidence A link to an evidence using its URI.
     */
    function submitEvidence(string _evidence) public onlyParty {
        require(status >= Status.DisputeCreated, "The dispute has not been created yet.");
        emit Evidence(arbitrator, 0, msg.sender, _evidence);
    }

    /** @dev Appeal an appealable ruling.
     *  Transfer the funds to the arbitrator.
     *  Note that no checks are required as the checks are done by the arbitrator.
     *  @param _extraData Extra data for the arbitrator appeal procedure.
     */
    function appeal(bytes _extraData) public onlyParty payable {
        arbitrator.appeal.value(msg.value)(disputeID,_extraData);
    }

    /** @dev Execute a ruling of a dispute. It reimburse the fee to the winning party.
     *  This need to be extended by contract inheriting from it.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. 1 : Reimburse the partyA. 2 : Pay the partyB.
     */
    function executeRuling(uint _disputeID, uint _ruling) internal {
        require(_disputeID == disputeID, "Wrong dispute ID.");
        require(_ruling <= amountOfChoices, "Invalid ruling.");

        // Give the arbitration fee back.
        // Note that we use send to prevent a party from blocking the execution.
        // In both cases sends the highest amount paid to avoid ETH to be stuck in
        // the contract if the arbitrator lowers its fee.
        if (_ruling==PARTY_A_WINS)
            partyA.send(partyAFee > partyBFee ? partyAFee : partyBFee);
        else if (_ruling==PARTY_B_WINS)
            partyB.send(partyAFee > partyBFee ? partyAFee : partyBFee);

        status = Status.Resolved;
    }

}

pragma solidity ^0.4.18;

/// @dev The token controller contract must implement these functions
contract TokenController {
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) public payable returns(bool);

    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);
}

/**
 *  @title Mini Me Token ERC20
 *  Overwrite the MiniMeToken to make it follow ERC20 recommendation.
 *  This is required because the base token reverts when approve is used with the non zero value while allowed is non zero (which not recommended by the standard, see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md).
 *  @author Clément Lesaege - <[email protected]>
 *  Bug Bounties: This code hasn't undertaken a bug bounty program yet.
 */

pragma solidity ^0.4.18;

import "minimetoken/contracts/MiniMeToken.sol";

contract MiniMeTokenERC20 is MiniMeToken {

    /** @notice Constructor to create a MiniMeTokenERC20
     *  @param _tokenFactory The address of the MiniMeTokenFactory contract that will
     *   create the Clone token contracts, the token factory needs to be deployed first
     *  @param _parentToken Address of the parent token, set to 0x0 if it is a new token
     *  @param _parentSnapShotBlock Block of the parent token that will determine the
     *   initial distribution of the clone token, set to 0 if it is a new token
     *  @param _tokenName Name of the new token
     *  @param _decimalUnits Number of decimals of the new token
     *  @param _tokenSymbol Token Symbol for the new token
     *  @param _transfersEnabled If true, tokens will be able to be transferred
     */
    constructor(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    )  MiniMeToken(
        _tokenFactory,
        _parentToken,
        _parentSnapShotBlock,
        _tokenName,
        _decimalUnits,
        _tokenSymbol,
        _transfersEnabled
    ) public {}

    /** @notice `msg.sender` approves `_spender` to spend `_amount` tokens on its behalf.
      * This is a ERC20 compliant version.
      * @param _spender The address of the account able to transfer the tokens
      * @param _amount The amount of tokens to be approved for transfer
      * @return True if the approval was successful
      */
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled, "Transfers are not enabled.");
        // Alerts the token controller of the approve function call
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount), "Token controller does not approve.");
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
}

/**
 *  @authors: [@mtsalenc]
 *  @reviewers: [@clesaege]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.4.24;


/**
 * @title CappedMath
 * @dev Math operations with caps for under and overflow.
 */
library CappedMath {
    uint constant private UINT_MAX = 2**256 - 1;

    /**
     * @dev Adds two unsigned integers, returns 2^256 - 1 on overflow.
     */
    function addCap(uint _a, uint _b) internal pure returns (uint) {
        uint c = _a + _b;
        return c >= _a ? c : UINT_MAX;
    }

    /**
     * @dev Subtracts two integers, returns 0 on underflow.
     */
    function subCap(uint _a, uint _b) internal pure returns (uint) {
        if (_b > _a)
            return 0;
        else
            return _a - _b;
    }

    /**
     * @dev Multiplies two unsigned integers, returns 2^256 - 1 on overflow.
     */
    function mulCap(uint _a, uint _b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring '_a' not being zero, but the
        // benefit is lost if '_b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0)
            return 0;

        uint c = _a * _b;
        return c / _a == _b ? c : UINT_MAX;
    }
}

pragma solidity ^0.4.18;

/*
    Copyright 2016, Jordi Baylina

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title MiniMeToken Contract
/// @author Jordi Baylina
/// @dev This token contract's goal is to make it easy for anyone to clone this
///  token using the token distribution at a given block, this will allow DAO's
///  and DApps to upgrade their features in a decentralized manner without
///  affecting the original token
/// @dev It is ERC20 compliant, but still needs to under go further testing.

import "./Controlled.sol";
import "./TokenController.sol";

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

/// @dev The actual token contract, the default controller is the msg.sender
///  that deploys the contract, so usually this token will be deployed by a
///  token controller contract, which Giveth will call a "Campaign"
contract MiniMeToken is Controlled {

    string public name;                //The Token's name: e.g. DigixDAO Tokens
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    string public version = 'MMT_0.2'; //An arbitrary versioning scheme


    /// @dev `Checkpoint` is the structure that attaches a block number to a
    ///  given value, the block number attached is the one that last changed the
    ///  value
    struct  Checkpoint {

        // `fromBlock` is the block number that the value was generated from
        uint128 fromBlock;

        // `value` is the amount of tokens at a specific block number
        uint128 value;
    }

    // `parentToken` is the Token address that was cloned to produce this token;
    //  it will be 0x0 for a token that was not cloned
    MiniMeToken public parentToken;

    // `parentSnapShotBlock` is the block number from the Parent Token that was
    //  used to determine the initial distribution of the Clone Token
    uint public parentSnapShotBlock;

    // `creationBlock` is the block number that the Clone Token was created
    uint public creationBlock;

    // `balances` is the map that tracks the balance of each address, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping (address => Checkpoint[]) balances;

    // `allowed` tracks any extra transfer rights as in all ERC20 tokens
    mapping (address => mapping (address => uint256)) allowed;

    // Tracks the history of the `totalSupply` of the token
    Checkpoint[] totalSupplyHistory;

    // Flag that determines if the token is transferable or not.
    bool public transfersEnabled;

    // The factory used to create new clone tokens
    MiniMeTokenFactory public tokenFactory;

////////////////
// Constructor
////////////////

    /// @notice Constructor to create a MiniMeToken
    /// @param _tokenFactory The address of the MiniMeTokenFactory contract that
    ///  will create the Clone token contracts, the token factory needs to be
    ///  deployed first
    /// @param _parentToken Address of the parent token, set to 0x0 if it is a
    ///  new token
    /// @param _parentSnapShotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token, set to 0 if it
    ///  is a new token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    function MiniMeToken(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                 // Set the name
        decimals = _decimalUnits;                          // Set the decimals
        symbol = _tokenSymbol;                             // Set the symbol
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


///////////////////
// ERC20 Methods
///////////////////

    /// @notice Send `_amount` tokens to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

        // The controller of this contract can move tokens around at will,
        //  this is important to recognize! Confirm that you trust the
        //  controller of this contract, which in most situations should be
        //  another open source smart contract or 0x0
        if (msg.sender != controller) {
            require(transfersEnabled);

            // The standard ERC 20 transferFrom functionality
            if (allowed[_from][msg.sender] < _amount) return false;
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

    /// @dev This is the actual transfer function in the token contract, it can
    ///  only be called by other functions in this contract.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) {

           if (_amount == 0) {
               return true;
           }

           require(parentSnapShotBlock < block.number);

           // Do not allow transfer to 0x0 or the token contract itself
           require((_to != 0) && (_to != address(this)));

           // If the amount being transfered is more than the balance of the
           //  account the transfer returns false
           var previousBalanceFrom = balanceOfAt(_from, block.number);
           if (previousBalanceFrom < _amount) {
               return false;
           }

           // Alerts the token controller of the transfer
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

           // First update the balance array with the new value for the address
           //  sending the tokens
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

           // Then update the balance array with the new value for the address
           //  receiving the tokens
           var previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

           // An event to make the transfer easy to find on the blockchain
           Transfer(_from, _to, _amount);

           return true;
    }

    /// @param _owner The address that's balance is being requested
    /// @return The balance of `_owner` at the current block
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        // Alerts the token controller of the approve function call
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @dev This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender
    ) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

    /// @dev This function makes it easy to get the total number of tokens
    /// @return The total number of tokens
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }


////////////////
// Query balance and totalSupply in History
////////////////

    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint _blockNumber) public constant
        returns (uint) {

        // These next few lines are used when the balance of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.balanceOfAt` be queried at the
        //  genesis block for that token as this contains initial balance of
        //  this token
        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                // Has no parent
                return 0;
            }

        // This will return the expected balance during normal situations
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

    /// @notice Total amount of tokens at a specific `_blockNumber`.
    /// @param _blockNumber The block number when the totalSupply is queried
    /// @return The total amount of tokens at `_blockNumber`
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

        // These next few lines are used when the totalSupply of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.totalSupplyAt` be queried at the
        //  genesis block for this token as that contains totalSupply of this
        //  token at this block number.
        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

        // This will return the expected totalSupply during normal situations
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

////////////////
// Clone Token Method
////////////////

    /// @notice Creates a new clone token with the initial distribution being
    ///  this token at `_snapshotBlock`
    /// @param _cloneTokenName Name of the clone token
    /// @param _cloneDecimalUnits Number of decimals of the smallest unit
    /// @param _cloneTokenSymbol Symbol of the clone token
    /// @param _snapshotBlock Block when the distribution of the parent token is
    ///  copied to set the initial distribution of the new clone token;
    ///  if the block is zero than the actual block, the current block is used
    /// @param _transfersEnabled True if transfers are allowed in the clone
    /// @return The address of the new MiniMeToken Contract
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) public returns(address) {
        if (_snapshotBlock == 0) _snapshotBlock = block.number;
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            _snapshotBlock,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
            );

        cloneToken.changeController(msg.sender);

        // An event to make the token easy to find on the blockchain
        NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }

////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint _amount
    ) public onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function destroyTokens(address _owner, uint _amount
    ) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

////////////////
// Enable tokens transfers
////////////////


    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

////////////////
// Internal helper functions to query and set a value in a snapshot array
////////////////

    /// @dev `getValueAt` retrieves the number of tokens at a given block number
    /// @param checkpoints The history of values being queried
    /// @param _block The block number to retrieve the value at
    /// @return The number of tokens being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    /// @dev `updateValueAtNow` used to update the `balances` map and the
    ///  `totalSupplyHistory`
    /// @param checkpoints The history of data being updated
    /// @param _value The new number of tokens
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

    /// @dev Helper function to return a min betwen the two uints
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

    /// @notice The fallback function: If the contract's controller has not been
    ///  set to 0, then the `proxyPayment` method is called which relays the
    ///  ether and creates tokens as described in the token controller contract
    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

////////////////
// Events
////////////////
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}


////////////////
// MiniMeTokenFactory
////////////////

/// @dev This contract is used to generate clone contracts from a contract.
///  In solidity this is the way to create a contract from a contract of the
///  same class
contract MiniMeTokenFactory {

    /// @notice Update the DApp by creating a new token with new functionalities
    ///  the msg.sender becomes the controller of this clone token
    /// @param _parentToken Address of the token being cloned
    /// @param _snapshotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    /// @return The address of the new token contract
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken) {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
            );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

pragma solidity ^0.4.18;

contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

{
  "metadata": {
    "useLiteralContent": true
  },
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