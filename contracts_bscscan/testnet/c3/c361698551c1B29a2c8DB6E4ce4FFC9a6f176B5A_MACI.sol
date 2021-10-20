// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import { DomainObjs } from './DomainObjs.sol';
import { IncrementalQuinTree } from "./IncrementalQuinTree.sol";
import { IncrementalMerkleTree } from "./IncrementalMerkleTree.sol";
import { SignUpGatekeeper } from "./gatekeepers/SignUpGatekeeper.sol";
import { InitialVoiceCreditProxy } from './initialVoiceCreditProxy/InitialVoiceCreditProxy.sol';
import { SnarkConstants } from './SnarkConstants.sol';
import { ComputeRoot } from './ComputeRoot.sol';
import { MACIParameters } from './MACIParameters.sol';
import { VerifyTally } from './VerifyTally.sol';

interface SnarkVerifier {
    function verifyProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] calldata input
    ) external view returns (bool);
}

contract MACI is DomainObjs, ComputeRoot, MACIParameters, VerifyTally {

    // A nothing-up-my-sleeve zero value
    // Should be equal to 8370432830353022751713833565135785980866757267633941821328460903436894336785
    uint256 ZERO_VALUE = uint256(keccak256(abi.encodePacked('Maci'))) % SNARK_SCALAR_FIELD;

    // Verifier Contracts
    SnarkVerifier internal batchUstVerifier;
    SnarkVerifier internal qvtVerifier;

    // The number of messages which the batch update state tree snark can
    // process per batch
    uint8 public messageBatchSize;

    // The number of state leaves to tally per batch via the vote tally snark
    uint8 public tallyBatchSize;

    // The tree that tracks the sign-up messages.
    IncrementalMerkleTree public messageTree;

    // The tree that tracks each user's public key and votes
    IncrementalMerkleTree public stateTree;

    uint256 public originalSpentVoiceCreditsCommitment = hashLeftRight(0, 0);
    uint256 public originalCurrentResultsCommitment;

    // To store the Merkle root of a tree with 5 **
    // _treeDepths.voteOptionTreeDepth leaves of value 0
    uint256 public emptyVoteOptionTreeRoot;

    // The maximum number of leaves, minus one, of meaningful vote options.
    uint256 public voteOptionsMaxLeafIndex;

    // The total sum of votes
    uint256 public totalVotes;

    // Cached results of 2 ** depth - 1 where depth is the state tree depth and
    // message tree depth
    uint256 public messageTreeMaxLeafIndex;

    // The maximum number of signups allowed
    uint256 public maxUsers;

    // The maximum number of messages allowed
    uint256 public maxMessages;

    // When the contract was deployed. We assume that the signup period starts
    // immediately upon deployment.
    uint256 public signUpTimestamp;

    // Duration of the sign-up and voting periods, in seconds. If these values
    // are set to 0, the contract will be in debug mode - that is, only the
    // coordinator may sign up and publish messages. This makes it possible to
    // submit a large number of signups and messages without having to do so
    // before the signup and voting deadlines.
    uint256 public signUpDurationSeconds;
    uint256 public votingDurationSeconds;

    // Address of the SignUpGatekeeper, a contract which determines whether a
    // user may sign up to vote
    SignUpGatekeeper public signUpGatekeeper;

    // The contract which provides the values of the initial voice credit
    // balance per user
    InitialVoiceCreditProxy public initialVoiceCreditProxy;

    // The coordinator's public key
    PubKey public coordinatorPubKey;

    uint256 public numSignUps = 0;
    uint256 public numMessages = 0;

    TreeDepths public treeDepths;

    bool public hasUnprocessedMessages = true;

    address public coordinatorAddress;

    //----------------------
    // Storage variables that can be reset by coordinatorReset()

    // The Merkle root of the state tree after each signup. Note that
    // batchProcessMessage() will not update the state tree. Rather, it will
    // directly update stateRoot if given a valid proof and public signals.
    uint256 public stateRoot;
    uint256 public stateRootBeforeProcessing;

    // The current message batch index
    uint256 public currentMessageBatchIndex;

    // The batch # for proveVoteTallyBatch
    uint256 public currentQvtBatchNum;

    // To store hashLeftRight(Merkle root of 5 ** voteOptionTreeDepth zeros, 0)
    uint256 public currentResultsCommitment;

    // To store hashLeftRight(0, 0). We precompute it here to save gas.
    uint256 public currentSpentVoiceCreditsCommitment;

    // To store hashLeftRight(Merkle root of 5 ** voteOptionTreeDepth zeros, 0)
    uint256 public currentPerVOSpentVoiceCreditsCommitment;
    //----------------------


    string constant ERROR_PUBLIC_SIGNAL_TOO_LARGE = "E01";
    string constant ERROR_INVALID_BATCH_UST_PROOF = "E02";
    string constant ERROR_INVALID_TALLY_PROOF = "E03";
    string constant ERROR_ONLY_COORDINATOR = "E04";
    string constant ERROR_ALL_BATCHES_TALLIED = "E05";
    string constant ERROR_CURRENT_MESSAGE_BATCH_OUT_OF_RANGE = "E06";
    string constant ERROR_NO_SIGNUPS = "E07";
    string constant ERROR_INVALID_ECDH_PUBKEYS_LENGTH = "E08";
    string constant ERROR_NO_MORE_MESSAGES = "E09";
    string constant ERROR_INVALID_MAX_USERS_OR_MESSAGES = "E10";
    string constant ERROR_SIGNUP_PERIOD_PASSED = "E11";
    string constant ERROR_SIGNUP_PERIOD_NOT_OVER = "E12";
    string constant ERROR_VOTING_PERIOD_PASSED = "E13";
    string constant ERROR_VOTING_PERIOD_NOT_OVER = "E13";

    // Events
    event SignUp(
        PubKey _userPubKey,
        uint256 _stateIndex,
        uint256 _voiceCreditBalance
    );

    event PublishMessage(
        Message _message,
        PubKey _encPubKey
    );

    constructor(
        TreeDepths memory _treeDepths,
        BatchSizes memory _batchSizes,
        MaxValues memory _maxValues,
        SignUpGatekeeper _signUpGatekeeper,
        SnarkVerifier _batchUstVerifier,
        SnarkVerifier _qvtVerifier,
        uint256 _signUpDurationSeconds,
        uint256 _votingDurationSeconds,
        InitialVoiceCreditProxy _initialVoiceCreditProxy,
        PubKey memory _coordinatorPubKey,
        address _coordinatorAddress
    ) public {
        coordinatorAddress = _coordinatorAddress;

        treeDepths = _treeDepths;

        tallyBatchSize = _batchSizes.tallyBatchSize;
        messageBatchSize = _batchSizes.messageBatchSize;

        // Set the verifier contracts
        batchUstVerifier = _batchUstVerifier;
        qvtVerifier = _qvtVerifier;

        // Set the sign-up duration
        signUpTimestamp = block.timestamp;
        signUpDurationSeconds = _signUpDurationSeconds;
        votingDurationSeconds = _votingDurationSeconds;
        
        // Set the sign-up gatekeeper contract
        signUpGatekeeper = _signUpGatekeeper;
        
        // Set the initial voice credit balance proxy
        initialVoiceCreditProxy = _initialVoiceCreditProxy;

        // Set the coordinator's public key
        coordinatorPubKey = _coordinatorPubKey;

        // Calculate and cache the max number of leaves for each tree.
        // They are used as public inputs to the batch update state tree snark.
        messageTreeMaxLeafIndex = uint256(2) ** _treeDepths.messageTreeDepth - 1;

        // Check and store the maximum number of signups
        // It is the user's responsibility to ensure that the state tree depth
        // is just large enough and not more, or they will waste gas.
        uint256 stateTreeMaxLeafIndex = uint256(2) ** _treeDepths.stateTreeDepth - 1;
        maxUsers = _maxValues.maxUsers;

        // The maximum number of messages
        require(
            _maxValues.maxUsers <= stateTreeMaxLeafIndex ||
            _maxValues.maxMessages <= messageTreeMaxLeafIndex,
            ERROR_INVALID_MAX_USERS_OR_MESSAGES
        );
        maxMessages = _maxValues.maxMessages;

        // The maximum number of leaves, minus one, of meaningful vote options.
        // This allows the snark to do a no-op if the user votes for an option
        // which has no meaning attached to it
        voteOptionsMaxLeafIndex = _maxValues.maxVoteOptions;

        // Create the message tree
        messageTree = new IncrementalMerkleTree(_treeDepths.messageTreeDepth, ZERO_VALUE, true);

        // Calculate and store the empty vote option tree root. This value must
        // be set before we call hashedBlankStateLeaf() later
        emptyVoteOptionTreeRoot = calcEmptyVoteOptionTreeRoot(_treeDepths.voteOptionTreeDepth);

        // Calculate and store a commitment to 5 ** voteOptionTreeDepth zeros,
        // and a salt of 0.
        originalCurrentResultsCommitment = hashLeftRight(emptyVoteOptionTreeRoot, 0);

        currentResultsCommitment = originalCurrentResultsCommitment;

        currentSpentVoiceCreditsCommitment = originalSpentVoiceCreditsCommitment;
        currentPerVOSpentVoiceCreditsCommitment = originalCurrentResultsCommitment;

        // Compute the hash of a blank state leaf
        uint256 h = hashedBlankStateLeaf();

        // Create the state tree
        stateTree = new IncrementalMerkleTree(_treeDepths.stateTreeDepth, h, false);

        // Make subsequent insertions start from leaf #1, as leaf #0 is only
        // updated with random data if a command is invalid.
        stateTree.insertLeaf(h);
    }

    /*
     * Returns the deadline to sign up.
     */
    function calcSignUpDeadline() public view returns (uint256) {
        return signUpTimestamp + signUpDurationSeconds;
    }

    /*
     * Ensures that the calling function only continues execution if the
     * current block time is before the sign-up deadline.
     */
    modifier isBeforeSignUpDeadline() {
        if (signUpDurationSeconds != 0) {
            require(block.timestamp < calcSignUpDeadline(), ERROR_SIGNUP_PERIOD_PASSED);
        }
        _;
    }

    /*
     * Ensures that the calling function only continues execution if the
     * current block time is after or equal to the sign-up deadline.
     */
    modifier isAfterSignUpDeadline() {
        if (signUpDurationSeconds != 0) {
            require(block.timestamp >= calcSignUpDeadline(), ERROR_SIGNUP_PERIOD_NOT_OVER);
        }
        _;
    }

    /*
     * Returns the deadline to vote
     */
    function calcVotingDeadline() public view returns (uint256) {
        return calcSignUpDeadline() + votingDurationSeconds;
    }

    /*
     * Ensures that the calling function only continues execution if the
     * current block time is before the voting deadline.
     */
    modifier isBeforeVotingDeadline() {
        if (votingDurationSeconds != 0) {
            require(block.timestamp < calcVotingDeadline(), ERROR_VOTING_PERIOD_PASSED);
        }
        _;
    }

    /*
     * Ensures that the calling function only continues execution if the
     * current block time is after or equal to the voting deadline.
     */
    modifier isAfterVotingDeadline() {
        if (votingDurationSeconds != 0) {
            require(block.timestamp >= calcVotingDeadline(), ERROR_VOTING_PERIOD_NOT_OVER);
        }
        _;
    }

    /*
     * Allows a user who is eligible to sign up to do so. The sign-up
     * gatekeeper will prevent double sign-ups or ineligible users from signing
     * up. This function will only succeed if the sign-up deadline has not
     * passed. It also inserts a fresh state leaf into the state tree.
     * @param _userPubKey The user's desired public key.
     * @param _signUpGatekeeperData Data to pass to the sign-up gatekeeper's
     *     register() function. For instance, the POAPGatekeeper or
     *     SignUpTokenGatekeeper requires this value to be the ABI-encoded
     *     token ID.
     */
    function signUp(
        PubKey memory _userPubKey,
        bytes memory _signUpGatekeeperData,
        bytes memory _initialVoiceCreditProxyData
    ) 
    isBeforeSignUpDeadline
    public {

        if (signUpDurationSeconds == 0) {
            require(
                msg.sender == coordinatorAddress,
                "MACI: only the coordinator can submit signups in debug mode"
            );
        }

        require(numSignUps < maxUsers, "MACI: maximum number of signups reached");

        // Register the user via the sign-up gatekeeper. This function should
        // throw if the user has already registered or if ineligible to do so.
        signUpGatekeeper.register(msg.sender, _signUpGatekeeperData);

        uint256 voiceCreditBalance = initialVoiceCreditProxy.getVoiceCredits(
            msg.sender,
            _initialVoiceCreditProxyData
        );

        // The limit on voice credits is 2 ^ 32 which is hardcoded into the
        // UpdateStateTree circuit, specifically at check that there are
        // sufficient voice credits (using GreaterEqThan(32)).
        require(voiceCreditBalance <= 4294967296, "MACI: too many voice credits");

        // Create, hash, and insert a fresh state leaf
        StateLeaf memory stateLeaf = StateLeaf({
            pubKey: _userPubKey,
            voteOptionTreeRoot: emptyVoteOptionTreeRoot,
            voiceCreditBalance: voiceCreditBalance,
            nonce: 0
        });

        uint256 hashedLeaf = hashStateLeaf(stateLeaf);

        // Insert the leaf
        stateTree.insertLeaf(hashedLeaf);

        // Update a copy of the state tree root
        stateRoot = getStateTreeRoot();

        numSignUps ++;

        // numSignUps is equal to the state index of the leaf which was just
        // added to the state tree above
        emit SignUp(_userPubKey, numSignUps, voiceCreditBalance);
    }

    /*
     * Allows anyone to publish a message (an encrypted command and signature).
     * This function also inserts it into the message tree.
     * @param _message The message to publish
     * @param _encPubKey An epheremal public key which can be combined with the
     *     coordinator's private key to generate an ECDH shared key which which was
     *     used to encrypt the message.
     */
    function publishMessage(
        Message memory _message,
        PubKey memory _encPubKey
    ) 
    isBeforeVotingDeadline
    public {
        if (signUpDurationSeconds == 0) {
            require(
                msg.sender == coordinatorAddress,
                "MACI: only the coordinator can publish messages in debug mode"
            );
        }

        require(numMessages < maxMessages, "MACI: message limit reached");

        // Calculate leaf value
        uint256 leaf = hashMessage(_message);

        // Insert the new leaf into the message tree
        messageTree.insertLeaf(leaf);

        currentMessageBatchIndex = (numMessages / messageBatchSize) * messageBatchSize;

        numMessages ++;

        emit PublishMessage(_message, _encPubKey);
    }

    /*
     * A helper function to convert an array of 8 uint256 values into the a, b,
     * and c array values that the zk-SNARK verifier's verifyProof accepts.
     */
    function unpackProof(
        uint256[8] memory _proof
    ) public pure returns (
        uint256[2] memory,
        uint256[2][2] memory,
        uint256[2] memory
    ) {

        return (
            [_proof[0], _proof[1]],
            [
                [_proof[2], _proof[3]],
                [_proof[4], _proof[5]]
            ],
            [_proof[6], _proof[7]]
        );
    }

    /*
     * A helper function to create the publicSignals array from meaningful
     * parameters.
     * @param _newStateRoot The new state root after all messages are processed
     * @param _ecdhPubKeys The public key used to generated the ECDH shared key
     *                     to decrypt the message
     */
    function genBatchUstPublicSignals(
        uint256 _newStateRoot,
        PubKey[] memory _ecdhPubKeys
    ) public view returns (uint256[] memory) {

        uint256 messageBatchEndIndex;
        if (currentMessageBatchIndex + messageBatchSize <= numMessages) {
            messageBatchEndIndex = currentMessageBatchIndex + messageBatchSize - 1;
        } else {
            messageBatchEndIndex = numMessages - 1;
        }

        uint256[] memory publicSignals = new uint256[](12 + messageBatchSize * 3);

        publicSignals[0] = _newStateRoot;
        publicSignals[1] = coordinatorPubKey.x;
        publicSignals[2] = coordinatorPubKey.y;
        publicSignals[3] = voteOptionsMaxLeafIndex;
        publicSignals[4] = messageTree.root();
        publicSignals[5] = currentMessageBatchIndex;
        publicSignals[6] = messageBatchEndIndex;
        publicSignals[7] = numSignUps;


        for (uint8 i = 0; i < messageBatchSize; i++) {
            uint8 x = 8 + i * 2;
            uint8 y = x + 1;
            publicSignals[x] = _ecdhPubKeys[i].x;
            publicSignals[y] = _ecdhPubKeys[i].y;
        }

        return publicSignals;
    }

    /*
     * Update the stateRoot if the batch update state root proof is
     * valid.
     * @param _newStateRoot The new state root after all messages are processed
     * @param _ecdhPubKeys The public key used to generated the ECDH shared key
     *                     to decrypt the message
     * @param _proof The zk-SNARK proof
     */
    function batchProcessMessage(
        uint256 _newStateRoot,
        PubKey[] memory _ecdhPubKeys,
        uint256[8] memory _proof
    ) 
    isAfterVotingDeadline
    public {
        // Ensure that the current batch index is within range
        require(
            hasUnprocessedMessages,
            ERROR_NO_MORE_MESSAGES
        );
        
        require(
            _ecdhPubKeys.length == messageBatchSize,
            ERROR_INVALID_ECDH_PUBKEYS_LENGTH
        );

        // Ensure that currentMessageBatchIndex is within range
        require(
            currentMessageBatchIndex <= messageTreeMaxLeafIndex,
            ERROR_CURRENT_MESSAGE_BATCH_OUT_OF_RANGE
        );

        // Assemble the public inputs to the snark
        uint256[] memory publicSignals = genBatchUstPublicSignals(
            _newStateRoot,
            _ecdhPubKeys
        );

        // Ensure that each public input is within range of the snark scalar
        // field.
        // TODO: consider having more granular revert reasons
        // TODO: this check is already performed in the verifier contract
        for (uint8 i = 0; i < publicSignals.length; i++) {
            require(
                publicSignals[i] < SNARK_SCALAR_FIELD,
                ERROR_PUBLIC_SIGNAL_TOO_LARGE
            );
        }

        // Unpack the snark proof
        (
            uint256[2] memory a,
            uint256[2][2] memory b,
            uint256[2] memory c
        ) = unpackProof(_proof);

        // Verify the proof
        require(
            batchUstVerifier.verifyProof(a, b, c, publicSignals),
            ERROR_INVALID_BATCH_UST_PROOF
        );

        // Increase the message batch start index to ensure that each message
        // batch is processed in order
        if (currentMessageBatchIndex == 0) {
            hasUnprocessedMessages = false;
        } else {
            currentMessageBatchIndex -= messageBatchSize;
        }

        // Update the state root
        stateRoot = _newStateRoot;
        if (stateRootBeforeProcessing == 0) {
            stateRootBeforeProcessing = stateRoot;
        }
    }

    /*
     * Returns the public signals required to verify a quadratic vote tally
     * snark.
     */
    function genQvtPublicSignals(
        uint256 _intermediateStateRoot,
        uint256 _newResultsCommitment,
        uint256 _newSpentVoiceCreditsCommitment,
        uint256 _newPerVOSpentVoiceCreditsCommitment,
        uint256 _totalVotes
    ) public view returns (uint256[] memory) {

        uint256[] memory publicSignals = new uint256[](10);

        publicSignals[0] = _newResultsCommitment;
        publicSignals[1] = _newSpentVoiceCreditsCommitment;
        publicSignals[2] = _newPerVOSpentVoiceCreditsCommitment;
        publicSignals[3] = _totalVotes;
        publicSignals[4] = stateRoot;
        publicSignals[5] = currentQvtBatchNum;
        publicSignals[6] = _intermediateStateRoot;
        publicSignals[7] = currentResultsCommitment;
        publicSignals[8] = currentSpentVoiceCreditsCommitment;
        publicSignals[9] = currentPerVOSpentVoiceCreditsCommitment;

        return publicSignals;
    }
    
    function hashedBlankStateLeaf() public view returns (uint256) {
        // The pubkey is the first Pedersen base point from iden3's circomlib
        StateLeaf memory stateLeaf = StateLeaf({
            pubKey: PubKey({
                x: 10457101036533406547632367118273992217979173478358440826365724437999023779287,
                y: 19824078218392094440610104313265183977899662750282163392862422243483260492317
            }),
            voteOptionTreeRoot: emptyVoteOptionTreeRoot,
            voiceCreditBalance: 0,
            nonce: 0
        });

        return hashStateLeaf(stateLeaf);
    }

    function hasUntalliedStateLeaves() public view returns (bool) {
        return currentQvtBatchNum < (1 + (numSignUps / tallyBatchSize));
    }

    /*
     * Tally the next batch of state leaves.
     * @param _intermediateStateRoot The intermediate state root, which is
     *     generated from the current batch of state leaves 
     * @param _newResultsCommitment A hash of the tallied results so far
     *     (cumulative)
     * @param _proof The zk-SNARK proof
     */
    function proveVoteTallyBatch(
        uint256 _intermediateStateRoot,
        uint256 _newResultsCommitment,
        uint256 _newSpentVoiceCreditsCommitment,
        uint256 _newPerVOSpentVoiceCreditsCommitment,
        uint256 _totalVotes,
        uint256[8] memory _proof
    ) 
    public {

        require(numSignUps > 0, ERROR_NO_SIGNUPS);
        uint256 totalBatches = 1 + (numSignUps / tallyBatchSize);

        // Ensure that the batch # is within range
        require(
            currentQvtBatchNum < totalBatches,
            ERROR_ALL_BATCHES_TALLIED
        );

        // Generate the public signals
        // public 'input' signals = [output signals, public inputs]
        uint256[] memory publicSignals = genQvtPublicSignals(
            _intermediateStateRoot,
            _newResultsCommitment,
            _newSpentVoiceCreditsCommitment,
            _newPerVOSpentVoiceCreditsCommitment,
            _totalVotes
        );

        // Ensure that each public input is within range of the snark scalar
        // field.
        // TODO: consider having more granular revert reasons
        for (uint8 i = 0; i < publicSignals.length; i++) {
            require(
                publicSignals[i] < SNARK_SCALAR_FIELD,
                ERROR_PUBLIC_SIGNAL_TOO_LARGE
            );
        }

        // Unpack the snark proof
        (
            uint256[2] memory a,
            uint256[2][2] memory b,
            uint256[2] memory c
        ) = unpackProof(_proof);

        // Verify the proof
        bool isValid = qvtVerifier.verifyProof(a, b, c, publicSignals);

        require(isValid == true, ERROR_INVALID_TALLY_PROOF);

        // Save the commitment to the new results for the next batch
        currentResultsCommitment = _newResultsCommitment;

        // Save the commitment to the total spent voice credits for the next batch
        currentSpentVoiceCreditsCommitment = _newSpentVoiceCreditsCommitment;

        // Save the commitment to the per voice credit spent voice credits for the next batch
        currentPerVOSpentVoiceCreditsCommitment = _newPerVOSpentVoiceCreditsCommitment;

        // Save the total votes
        totalVotes = _totalVotes;

        // Increment the batch #
        currentQvtBatchNum ++;
    }

    /*
     * Reset the storage variables which change during message processing and
     * vote tallying. Does not affect any signups or messages. This is useful
     * if the client-side process/tally code has a bug that causes an invalid
     * state transition.
     */
    function coordinatorReset() public {
        require(msg.sender == coordinatorAddress, ERROR_ONLY_COORDINATOR);

        hasUnprocessedMessages = true;
        stateRoot = stateRootBeforeProcessing;
        if (numMessages % messageBatchSize == 0) {
            currentMessageBatchIndex = numMessages - messageBatchSize;
        } else {
            currentMessageBatchIndex = (numMessages / messageBatchSize) * messageBatchSize;
        }
        currentQvtBatchNum = 0;

        currentResultsCommitment = originalCurrentResultsCommitment;
        currentSpentVoiceCreditsCommitment = originalSpentVoiceCreditsCommitment;
        currentPerVOSpentVoiceCreditsCommitment = originalCurrentResultsCommitment;

        totalVotes = 0;
    }

    /*
     * Verify the result of the vote tally using a Merkle proof and the salt.
     */
    function verifyTallyResult(
        uint8 _depth,
        uint256 _index,
        uint256 _leaf,
        uint256[][] memory _pathElements,
        uint256 _salt
    ) public view returns (bool) {
        uint256 computedRoot = computeMerkleRootFromPath(
            _depth,
            _index,
            _leaf,
            _pathElements
        );

        uint256 computedCommitment = hashLeftRight(computedRoot, _salt);
        return computedCommitment == currentResultsCommitment;
    }

    /*
     * Verify the number of voice credits spent for a particular vote option
     * using a Merkle proof and the salt.
     */
    function verifyPerVOSpentVoiceCredits(
        uint8 _depth,
        uint256 _index,
        uint256 _leaf,
        uint256[][] memory _pathElements,
        uint256 _salt
    ) public view returns (bool) {
        uint256 computedRoot = computeMerkleRootFromPath(
            _depth,
            _index,
            _leaf,
            _pathElements
        );

        uint256 computedCommitment = hashLeftRight(computedRoot, _salt);
        return computedCommitment == currentPerVOSpentVoiceCreditsCommitment;
    }

    /*
     * Verify the total number of spent voice credits.
     * @param _spent The value to verify
     * @param _salt The salt which is hashed with the value to generate the
     *              commitment to the spent voice credits.
     */
    function verifySpentVoiceCredits(
        uint256 _spent,
        uint256 _salt
    ) public view returns (bool) {
        uint256 computedCommitment = hashLeftRight(_spent, _salt);
        return computedCommitment == currentSpentVoiceCreditsCommitment;
    }

    function calcEmptyVoteOptionTreeRoot(uint8 _levels) public pure returns (uint256) {
        return computeEmptyQuinRoot(_levels, 0);
    }

    function getMessageTreeRoot() public view returns (uint256) {
        return messageTree.root();
    }

    function getStateTreeRoot() public view returns (uint256) {
        return stateTree.root();
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import { Hasher } from "./Hasher.sol";
import { MACISharedObjs } from "./MACISharedObjs.sol";

contract DomainObjs is Hasher, MACISharedObjs {
    struct StateLeaf {
        PubKey pubKey;
        uint256 voteOptionTreeRoot;
        uint256 voiceCreditBalance;
        uint256 nonce;
    }

    function hashStateLeaf(StateLeaf memory _stateLeaf) public pure returns (uint256) {
        uint256[5] memory plaintext;
        plaintext[0] = _stateLeaf.pubKey.x;
        plaintext[1] = _stateLeaf.pubKey.y;
        plaintext[2] = _stateLeaf.voteOptionTreeRoot;
        plaintext[3] = _stateLeaf.voiceCreditBalance;
        plaintext[4] = _stateLeaf.nonce;

        return hash5(plaintext);
    }

    function hashMessage(Message memory _message) public pure returns (uint256) {
        uint256[] memory plaintext = new uint256[](MESSAGE_DATA_LENGTH + 1);

        plaintext[0] = _message.iv;

        for (uint8 i=0; i < MESSAGE_DATA_LENGTH; i++) {
            plaintext[i+1] = _message.data[i];
        }

        return hash11(plaintext);
    }
}

// SPDX-License-Identifier: MIT

/*
 * MACI - Minimum Anti-Collusion Infrastructure
 * Copyright (C) 2020 Barry WhiteHat <[email protected]>, Kobi
 * Gurkan <[email protected]> and Koh Wei Jie ([email protected])
 *
 * This file is part of MACI.
 *
 * MACI is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * MACI is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with MACI.  If not, see <http://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.12;

import { SnarkConstants } from "./SnarkConstants.sol";
import { Hasher } from "./Hasher.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * An incremental Merkle tree which supports up to 5 leaves per node.
 */
contract IncrementalQuinTree is Ownable, Hasher {
    // The maximum tree depth
    uint8 internal constant MAX_DEPTH = 32;

    // The number of leaves per node
    uint8 internal constant LEAVES_PER_NODE = 5;

    // The tree depth
    uint8 internal treeLevels;

    // The number of inserted leaves
    uint256 internal nextLeafIndex = 0;

    // The Merkle root
    uint256 public root;

    // The zero value per level
    mapping (uint256 => uint256) internal zeros;

    // Allows you to compute the path to the element (but it's not the path to
    // the elements). Caching these values is essential to efficient appends.
    mapping (uint256 => mapping (uint256 => uint256)) internal filledSubtrees;

    // Whether the contract has already seen a particular Merkle tree root
    mapping (uint256 => bool) public rootHistory;

    event LeafInsertion(uint256 indexed leaf, uint256 indexed leafIndex);

    /*
     * Stores the Merkle root and intermediate values (the Merkle path to the
     * the first leaf) assuming that all leaves are set to _zeroValue.
     * @param _treeLevels The number of levels of the tree
     * @param _zeroValue The value to set for every leaf. Ideally, this should
     *                   be a nothing-up-my-sleeve value, so that nobody can
     *                   say that the deployer knows the preimage of an empty
     *                   leaf.
     */
    constructor(uint8 _treeLevels, uint256 _zeroValue) public {
        // Limit the Merkle tree to MAX_DEPTH levels
        require(
            _treeLevels > 0 && _treeLevels <= MAX_DEPTH,
            "IncrementalQuinTree: _treeLevels must be between 0 and 33"
        );
        
        /*
           To initialise the Merkle tree, we need to calculate the Merkle root
           assuming that each leaf is the zero value.

           `zeros` and `filledSubtrees` will come in handy later when we do
           inserts or updates. e.g when we insert a value in index 1, we will
           need to look up values from those arrays to recalculate the Merkle
           root.
         */
        treeLevels = _treeLevels;

        uint256 currentZero = _zeroValue;

        // hash5 requires a uint256[] memory input, so we have to use temp
        uint256[LEAVES_PER_NODE] memory temp;

        for (uint8 i = 0; i < _treeLevels; i++) {
            for (uint8 j = 0; j < LEAVES_PER_NODE; j ++) {
                temp[j] = currentZero;
            }

            zeros[i] = currentZero;
            currentZero = hash5(temp);
        }

        root = currentZero;
    }

    /*
     * Inserts a leaf into the Merkle tree and updates its root.
     * Also updates the cached values which the contract requires for efficient
     * insertions.
     * @param _leaf The value to insert. It must be less than the snark scalar
     *              field or this function will throw.
     * @return The leaf index.
     */
    function insertLeaf(uint256 _leaf) public onlyOwner returns (uint256) {
        require(
            _leaf < SNARK_SCALAR_FIELD,
            "IncrementalQuinTree: insertLeaf argument must be < SNARK_SCALAR_FIELD"
        );

        // Ensure that the tree is not full
        require(
            nextLeafIndex < uint256(LEAVES_PER_NODE) ** uint256(treeLevels),
            "IncrementalQuinTree: tree is full"
        );

        uint256 currentIndex = nextLeafIndex;

        uint256 currentLevelHash = _leaf;

        // hash5 requires a uint256[] memory input, so we have to use temp
        uint256[LEAVES_PER_NODE] memory temp;

        // The leaf's relative position within its node
        uint256 m = currentIndex % LEAVES_PER_NODE;

        for (uint8 i = 0; i < treeLevels; i++) {
            // If the leaf is at relative index 0, zero out the level in
            // filledSubtrees
            if (m == 0) {
                for (uint8 j = 1; j < LEAVES_PER_NODE; j ++) {
                    filledSubtrees[i][j] = zeros[i];
                }
            }

            // Set the leaf in filledSubtrees
            filledSubtrees[i][m] = currentLevelHash;

            // Hash the level
            for (uint8 j = 0; j < LEAVES_PER_NODE; j ++) {
                temp[j] = filledSubtrees[i][j];
            }
            currentLevelHash = hash5(temp);

            currentIndex /= LEAVES_PER_NODE;
            m = currentIndex % LEAVES_PER_NODE;
        }

        root = currentLevelHash;

        rootHistory[root] = true;

        uint256 n = nextLeafIndex;
        nextLeafIndex += 1;

        emit LeafInsertion(_leaf, n);

        return currentIndex;
    }
}

// SPDX-License-Identifier: MIT

/*
 * Semaphore - Zero-knowledge signaling on Ethereum
 * Copyright (C) 2020 Barry WhiteHat <[email protected]>, Kobi
 * Gurkan <[email protected]> and Koh Wei Jie ([email protected])
 *
 * This file is part of Semaphore.
 *
 * Semaphore is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Semaphore is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Semaphore.  If not, see <http://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.12;

import { SnarkConstants } from "./SnarkConstants.sol";
import { Hasher } from "./Hasher.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleZeros } from "./MerkleBinaryMaci.sol";

contract IncrementalMerkleTree is Ownable, Hasher, MerkleZeros {
    // The maximum tree depth
    uint8 internal constant MAX_DEPTH = 32;

    // The tree depth
    uint8 internal treeLevels;

    // The number of inserted leaves
    uint256 internal nextLeafIndex = 0;

    // The Merkle root
    uint256 public root;

    // Allows you to compute the path to the element (but it's not the path to
    // the elements). Caching these values is essential to efficient appends.
    uint256[MAX_DEPTH] internal filledSubtrees;

    // Whether the contract has already seen a particular Merkle tree root
    mapping (uint256 => bool) public rootHistory;

    event LeafInsertion(uint256 indexed leaf, uint256 indexed leafIndex);

    string constant ERROR_LEAF_TOO_LARGE = "E01";
    string constant ERROR_TREE_FULL = "E02";
    string constant ERROR_INVALID_LEVELS = "E03";
    string constant ERROR_INVALID_ZERO = "E04";

    constructor(uint8 _treeLevels, uint256 _zeroValue, bool _isPreCalc) public {
        // Limit the Merkle tree to MAX_DEPTH levels
        require(
            _treeLevels > 0 && _treeLevels <= MAX_DEPTH,
            ERROR_INVALID_LEVELS
        );
        
        if (_isPreCalc) {
            // Use pre-calculated zero values (see MerkleZeros.sol.template)
            populateZeros();
            require(_zeroValue == zeros[0], ERROR_INVALID_ZERO);
            treeLevels = _treeLevels;

            root = zeros[_treeLevels];
        } else {
            /*
               To initialise the Merkle tree, we need to calculate the Merkle root
               assuming that each leaf is the zero value.

                H(H(a,b), H(c,d))
                 /             \
                H(a,b)        H(c,d)
                 /   \        /    \
                a     b      c      d

               `zeros` and `filledSubtrees` will come in handy later when we do
               inserts or updates. e.g when we insert a value in index 1, we will
               need to look up values from those arrays to recalculate the Merkle
               root.
             */
            treeLevels = _treeLevels;

            zeros[0] = _zeroValue;

            uint256 currentZero = _zeroValue;
            for (uint8 i = 1; i < _treeLevels; i++) {
                uint256 hashed = hashLeftRight(currentZero, currentZero);
                zeros[i] = hashed;
                currentZero = hashed;
            }

            root = hashLeftRight(currentZero, currentZero);
        }
    }

    /*
     * Inserts a leaf into the Merkle tree and updates the root and filled
     * subtrees.
     * @param _leaf The value to insert. It must be less than the snark scalar
     *              field or this function will throw.
     * @return The leaf index.
     */
    function insertLeaf(uint256 _leaf) public onlyOwner returns (uint256) {
        require(_leaf < SNARK_SCALAR_FIELD, ERROR_LEAF_TOO_LARGE);

        uint256 currentIndex = nextLeafIndex;

        uint256 depth = uint256(treeLevels);
        require(currentIndex < uint256(2) ** depth, ERROR_TREE_FULL);

        uint256 currentLevelHash = _leaf;
        uint256 left;
        uint256 right;

        for (uint8 i = 0; i < treeLevels; i++) {
            // if current_index is 5, for instance, over the iterations it will
            // look like this: 5, 2, 1, 0, 0, 0 ...

            if (currentIndex % 2 == 0) {
                // For later values of `i`, use the previous hash as `left`, and
                // the (hashed) zero value for `right`
                left = currentLevelHash;
                right = zeros[i];

                filledSubtrees[i] = currentLevelHash;
            } else {
                left = filledSubtrees[i];
                right = currentLevelHash;
            }

            currentLevelHash = hashLeftRight(left, right);

            // equivalent to currentIndex /= 2;
            currentIndex >>= 1;
        }

        root = currentLevelHash;
        rootHistory[root] = true;

        uint256 n = nextLeafIndex;
        nextLeafIndex += 1;

        emit LeafInsertion(_leaf, n);

        return currentIndex;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract SignUpGatekeeper {
    function register(address _user, bytes memory _data) virtual public {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract InitialVoiceCreditProxy {
    function getVoiceCredits(address _user, bytes memory _data) virtual public view returns (uint256) {}
}

// SPDX-License-Identifier: MIT

/*
 * Semaphore - Zero-knowledge signaling on Ethereum
 * Copyright (C) 2020 Barry WhiteHat <[email protected]>, Kobi
 * Gurkan <[email protected]> and Koh Wei Jie ([email protected])
 *
 * This file is part of Semaphore.
 *
 * Semaphore is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Semaphore is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Semaphore.  If not, see <http://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.12;

contract SnarkConstants {
    // The scalar field
    uint256 internal constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import { SnarkConstants } from "./SnarkConstants.sol";
import { Hasher } from "./Hasher.sol";

contract ComputeRoot is Hasher {

    uint8 private constant LEAVES_PER_NODE = 5;

    function computeEmptyRoot(uint8 _treeLevels, uint256 _zeroValue) public pure returns (uint256) {
        // Limit the Merkle tree to MAX_DEPTH levels
        require(
            _treeLevels > 0 && _treeLevels <= 32,
            "ComputeRoot: _treeLevels must be between 0 and 33"
        );

        uint256 currentZero = _zeroValue;
        for (uint8 i = 1; i < _treeLevels; i++) {
            uint256 hashed = hashLeftRight(currentZero, currentZero);
            currentZero = hashed;
        }

        return hashLeftRight(currentZero, currentZero);
    }

    function computeEmptyQuinRoot(uint8 _treeLevels, uint256 _zeroValue) public pure returns (uint256) {
        // Limit the Merkle tree to MAX_DEPTH levels
        require(
            _treeLevels > 0 && _treeLevels <= 32,
            "ComputeRoot: _treeLevels must be between 0 and 33"
        );

        uint256 currentZero = _zeroValue;

        for (uint8 i = 0; i < _treeLevels; i++) {

            uint256[LEAVES_PER_NODE] memory z;

            for (uint8 j = 0; j < LEAVES_PER_NODE; j ++) {
                z[j] = currentZero;
            }

            currentZero = hash5(z);
        }

        return currentZero;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract MACIParameters {
    // This structs help to reduce the number of parameters to the constructor
    // and avoid a stack overflow error during compilation
    struct TreeDepths {
        uint8 stateTreeDepth;
        uint8 messageTreeDepth;
        uint8 voteOptionTreeDepth;
    }

    struct BatchSizes {
        uint8 tallyBatchSize;
        uint8 messageBatchSize;
    }

    struct MaxValues {
        uint256 maxUsers;
        uint256 maxMessages;
        uint256 maxVoteOptions;
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import { Hasher } from "./Hasher.sol";

contract VerifyTally is Hasher {

    uint8 private constant LEAVES_PER_NODE = 5;

    function computeMerkleRootFromPath(
        uint8 _depth,
        uint256 _index,
        uint256 _leaf,
        uint256[][] memory _pathElements
    ) public pure returns (uint256) {
        uint256 pos = _index % LEAVES_PER_NODE;
        uint256 current = _leaf;
        uint8 k;

        uint256[LEAVES_PER_NODE] memory level;

        for (uint8 i = 0; i < _depth; i ++) {
            for (uint8 j = 0; j < LEAVES_PER_NODE; j ++) {
                if (j == pos) {
                    level[j] = current;
                } else {
                    if (j > pos) {
                        k = j - 1;
                    } else {
                        k = j;
                    }
                    level[j] = _pathElements[i][k];
                }
            }

            _index /= LEAVES_PER_NODE;
            pos = _index % LEAVES_PER_NODE;
            current = hash5(level);
        }

        return current;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import {PoseidonT3, PoseidonT6} from "./Poseidon.sol";

import {SnarkConstants} from "./SnarkConstants.sol";

/*
 * Poseidon hash functions for 2, 5, and 11 input elements.
 */
contract Hasher is SnarkConstants {
    function hash5(uint256[5] memory array) public pure returns (uint256) {
        return PoseidonT6.poseidon(array);
    }

    function hash11(uint256[] memory array) public pure returns (uint256) {
        uint256[] memory input11 = new uint256[](11);
        uint256[5] memory first5;
        uint256[5] memory second5;
        for (uint256 i = 0; i < array.length; i++) {
            input11[i] = array[i];
        }

        for (uint256 i = array.length; i < 11; i++) {
            input11[i] = 0;
        }

        for (uint256 i = 0; i < 5; i++) {
            first5[i] = input11[i];
            second5[i] = input11[i + 5];
        }

        uint256[2] memory first2;
        first2[0] = PoseidonT6.poseidon(first5);
        first2[1] = PoseidonT6.poseidon(second5);
        uint256[2] memory second2;
        second2[0] = PoseidonT3.poseidon(first2);
        second2[1] = input11[10];
        return PoseidonT3.poseidon(second2);
    }

    function hashLeftRight(uint256 _left, uint256 _right)
        public
        pure
        returns (uint256)
    {
        uint256[2] memory input;
        input[0] = _left;
        input[1] = _right;
        return PoseidonT3.poseidon(input);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract MACISharedObjs {
    uint8 constant MESSAGE_DATA_LENGTH = 10;
    struct Message {
        uint256 iv;
        uint256[MESSAGE_DATA_LENGTH] data;
    }

    struct PubKey {
        uint256 x;
        uint256 y;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library PoseidonT3 {
    function poseidon(uint256[2] memory input) public pure returns (uint256) {}
}


library PoseidonT6 {
    function poseidon(uint256[5] memory input) public pure returns (uint256) {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract MerkleZeros {
    uint256[33] internal zeros;

    // Binary tree zeros (Keccack hash of 'Maci')
    function populateZeros() internal {
        zeros[0] = uint256(8370432830353022751713833565135785980866757267633941821328460903436894336785);
        zeros[1] = uint256(13883108378505681706501741077199723943829197421795883447299356576923144768890);
        zeros[2] = uint256(15419121528227002346615807695865368688447806543310218580451656713665933966440);
        zeros[3] = uint256(6318262337906428951291657677634338300639543013249211096760913778778957055324);
        zeros[4] = uint256(17768974272065709481357540291486641669761745417382244600494648537227290564775);
        zeros[5] = uint256(1030673773521289386438564854581137730704523062376261329171486101180288653537);
        zeros[6] = uint256(2456832313683926177308273721786391957119973242153180895324076357329047000368);
        zeros[7] = uint256(8719489529991410281576768848178751308798998844697260960510058606396118487868);
        zeros[8] = uint256(1562826620410077272445821684229580081819470607145780146992088471567204924361);
        zeros[9] = uint256(2594027261737512958249111386518678417918764295906952540494120924791242533396);
        zeros[10] = uint256(7454652670930646290900416353463196053308124896106736687630886047764171239135);
        zeros[11] = uint256(5636576387316613237724264020484439958003062686927585603917058282562092206685);
        zeros[12] = uint256(6668187911340361678685285736007075111202281125695563765600491898900267193410);
        zeros[13] = uint256(11734657993452490720698582048616543923742816272311967755126326688155661525563);
        zeros[14] = uint256(13463263143201754346725031241082259239721783038365287587742190796879610964010);
        zeros[15] = uint256(7428603293293611296009716236093531014060986236553797730743998024965500409844);
        zeros[16] = uint256(3220236805148173410173179641641444848417275827082321553459407052920864882112);
        zeros[17] = uint256(5702296734156546101402281555025360809782656712426280862196339683480526959100);
        zeros[18] = uint256(18054517726590450486276822815339944904333304893252063892146748222745553261079);
        zeros[19] = uint256(15845875411090302918698896692858436856780638250734551924718281082237259235021);
        zeros[20] = uint256(15856603049544947491266127020967880429380981635456797667765381929897773527801);
        zeros[21] = uint256(16947753390809968528626765677597268982507786090032633631001054889144749318212);
        zeros[22] = uint256(4409871880435963944009375001829093050579733540305802511310772748245088379588);
        zeros[23] = uint256(3999924973235726549616800282209401324088787314476870617570702819461808743202);
        zeros[24] = uint256(5910085476731597359542102744346894725393370185329725031545263392891885548800);
        zeros[25] = uint256(8329789525184689042321668445575725185257025982565085347238469712583602374435);
        zeros[26] = uint256(21731745958669991600655184668442493750937309130671773804712887133863507145115);
        zeros[27] = uint256(13908786229946466860099145463206281117295829828306413881947857340025780878375);
        zeros[28] = uint256(2746378384965515118858350021060497341885459652705230422460541446030288889144);
        zeros[29] = uint256(4024247518003740702537513711866227003187955635058512298109553363285388770811);
        zeros[30] = uint256(13465368596069181921705381841358161201578991047593533252870698635661853557810);
        zeros[31] = uint256(1901585547727445451328488557530824986692473576054582208711800336656801352314);
        zeros[32] = uint256(3444131905730490180878137209421656122704458854785641062326389124060978485990);
    }
}