// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/drafts/EIP712.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./interfaces/IDai.sol";
import "./interfaces/IProofOfHumanity.sol";
import "./interfaces/IRng.sol";
import "./interfaces/IErc20PermitMintable.sol";

contract Protocol is EIP712 {

    using SafeMath for uint256;

    modifier onlyExistentPublications(uint256 _publicationId) {
        require(_publicationId < publicationId, "Publication does not exist");
        _;
    }

    modifier onlyPublicationJurors(uint256 _publicationId, address _juror) {
        require(votings[_publicationId].isJuror[_juror], "You are not a juror for this publication");
        _;
    }

    modifier onlyExistentTopics(string calldata _topicId) {
        require(topics[_topicId].created, "Topic does not exists");
        _;
    }

    event TopicCreation(
        string indexed _topicId,
        uint256 _priceToPublish,
        uint256 _priceToBeJuror,
        uint256 _authorReward,
        uint256 _jurorReward,
        uint256 _commitPhaseDuration,
        uint256 _revealPhaseDuration
    );

    event JurorSubscription(address indexed _juror, string indexed _topicId, uint256 _times);

    event PublicationSubmission(
        uint256 indexed _publicationId,
        address indexed _author,
        string indexed _topicId,
        address[] _jurors,
        string _hash,
        uint256 _publishDate
    );

    event VoteCommitment(address indexed _juror, uint256 indexed _publicationId, bytes32 _commitment);

    event VoteReveal(
        address indexed _juror,
        uint256 indexed _publicationId,
        uint8 indexed _voteValue,
        string _justification,
        uint256[] _voteCounters,
        uint256 _winningVote
    );

    event Withdrawal(uint256 indexed _publicationId);

    enum VoteValue {
        None,
        True,
        False,
        Unqualified
    }

    struct Vote {
        uint256 nonce;
        VoteValue value;
        bytes32 commitment;
        string justification;
    }

    struct Voting {
        bool withdrawn;
        address[] jurors;
        uint256[] voteCounters;
        uint256 maxVoteCount;
        VoteValue winningVote;
        mapping (address => bool) isJuror;
        mapping (address => bool) isPenalized;
        mapping (address => Vote) votes;
    }

    struct Publication {
        string hash;
        address author;
        string topicId;
        uint256 publishDate;
    }

    struct Topic {
        bool created;
        bool closed;
        uint256 priceToPublish;
        uint256 priceToBeJuror;
        uint256 authorReward;
        uint256 jurorReward;
        uint256 commitPhaseDuration;
        uint256 revealPhaseDuration;
        uint256 jurorQuantity;
        address[] selectableJurors;
        mapping (address => uint256) jurorTimes;
        mapping (address => uint256) jurorSelectedTimes;
    }

    bytes32 immutable public VOTE_TYPEHASH;
    uint256 immutable public MIN_SELECTABLE_JURORS_QTY;
    uint256 immutable public VOTING_JURORS_QTY;
    uint256 immutable public DEFAULT_PRICE_TO_PUBLISH;
    uint256 immutable public DEFAULT_PRICE_TO_BE_JUROR;
    uint256 immutable public DEFAULT_AUTHOR_REWARD;
    uint256 immutable public DEFAULT_JUROR_REWARD;
    uint256 immutable public DEFAULT_COMMIT_DURATION;
    uint256 immutable public DEFAULT_REVEAL_DURATION;

    IErc20PermitMintable public gazzeth;
    IDai public dai;
    IProofOfHumanity public proofOfHumanity;
    IRng public rng;
    uint256 public publicationId;
    uint256 public protocolDaiBalance;
    mapping (string => Topic) public topics;
    mapping (uint256 => Publication) public publications;
    mapping (uint256 => Voting) public votings;

    /**
     * @dev Constructor of the Gazzeth Protocol contract.
     * @param _gazzeth Address of Gazzeth ERC20 token contract.
     * @param _dai Address of DAI ERC20 token contract.
     * @param _proofOfHumanity Address of Proof of Humanity contract.
     * @param _rng Address of a Random Number Generator contract.
     * @param _minSelectableJurorsQuantity Minimum selectable jurors needed in a topic to publish.
     * @param _votingJurorsQuantity Number of jurors to be selected for voting a publication.
     * @param _defaultPriceToPublish Default price in DAI for publishing in a topic.
     * @param _defaultPriceToBeJuror Default price in DAI for subscribing one time as juror in a topic.
     * @param _defaultAuthorReward Default reward price in DAI for author.
     * @param _defaultJurorReward Default reward price in DAI for juror.
     * @param _defaultCommitDuration Default voting commit phase duration in seconds.
     * @param _defaultRevealDuration Default voting reveal phase duration in seconds.
     */
    constructor(
        IErc20PermitMintable _gazzeth,
        IDai _dai,
        IProofOfHumanity _proofOfHumanity,
        IRng _rng,
        uint256 _minSelectableJurorsQuantity,
        uint256 _votingJurorsQuantity,
        uint256 _defaultPriceToPublish,
        uint256 _defaultPriceToBeJuror,
        uint256 _defaultAuthorReward,
        uint256 _defaultJurorReward,
        uint256 _defaultCommitDuration,
        uint256 _defaultRevealDuration
    ) EIP712("Gazzeth Protocol", "1") {
        gazzeth = _gazzeth;
        dai = _dai;
        proofOfHumanity = _proofOfHumanity;
        rng = _rng;
        MIN_SELECTABLE_JURORS_QTY = _minSelectableJurorsQuantity;
        VOTING_JURORS_QTY = _votingJurorsQuantity;
        DEFAULT_PRICE_TO_PUBLISH = _defaultPriceToPublish;
        DEFAULT_PRICE_TO_BE_JUROR = _defaultPriceToBeJuror;
        DEFAULT_AUTHOR_REWARD = _defaultAuthorReward;
        DEFAULT_JUROR_REWARD = _defaultJurorReward;
        DEFAULT_REVEAL_DURATION = _defaultRevealDuration;
        DEFAULT_COMMIT_DURATION = _defaultCommitDuration;
        VOTE_TYPEHASH = keccak256("Vote(uint256 publicationId,uint8 vote,uint256 nonce)");
    }

    /**
     * @dev Gets the time left to finish voting commit phase.
     * @param _publicationId The publication id corresponding to the publication where to obtain the deadlines.
     * @return An integer representing seconds left to finish voting commit phase. Zero if publication not exists.
     */
    function timeToFinishCommitPhase(uint256 _publicationId) public view returns (uint256) {
        return timeToDeadlineTimestamp(
            publications[_publicationId].publishDate
                .add(topics[publications[_publicationId].topicId].commitPhaseDuration)
        );
    }

    /**
     * @dev Gets the time left to finish voting reveal phase.
     * @param _publicationId The publication id corresponding to the publication where to obtain the deadlines.
     * @return An integer representing seconds left to finish voting reveal phase. Zero if publication not exists.
     */
    function timeToFinishRevealPhase(uint256 _publicationId) public view returns (uint256) {
        return timeToDeadlineTimestamp(
            publications[_publicationId].publishDate
                .add(topics[publications[_publicationId].topicId].commitPhaseDuration)
                .add(topics[publications[_publicationId].topicId].revealPhaseDuration)
        );
    }

    /**
     * @dev Gets nonce juror must use for next commitment in a given publication.
     * @param _juror The address of the juror corresponding to the nonce.
     * @param _publicationId The publication id corresponding to the nonce.
     * @return An integer representing the nonce.
     */
    function getCommitmentNonce(address _juror, uint256 _publicationId) external view returns (uint256) {
        return votings[_publicationId].votes[_juror].nonce;
    }

    /**
     * @dev Gets selectable jurors in a given topic.
     * @param _topicId The topic id where jurors corresponds to.
     * @return An address array representing the jurors.
     */
    function getSelectableJurors(string calldata _topicId) 
        external
        view
        onlyExistentTopics(_topicId)
        returns (address[] memory) 
    {
        return topics[_topicId].selectableJurors;
    }

    /**
     * @dev Gets juror suscribed times in a given topic.
     * @param _topicId The topic id to get times from.
     * @param _juror The juror address.
     * @return An integer representing the times.
     */
    function getJurorTimes(string calldata _topicId, address _juror) 
        external
        view
        onlyExistentTopics(_topicId)
        returns (uint256) 
    {
        return topics[_topicId].jurorTimes[_juror];
    }

    /**
     * @dev Gets juror selected times in publications of the given topic.
     * @param _topicId The topic id where publications corresponds to.
     * @param _juror The juror address.
     * @return An integer representing the times.
     */
    function getJurorSelectedTimes(string calldata _topicId, address _juror) 
        external
        view
        onlyExistentTopics(_topicId)
        returns (uint256)
    {
        return topics[_topicId].jurorSelectedTimes[_juror];
    }

    /**
     * @dev Gets juror in a given publication voting.
     * @param _publicationId The publication id where voting corresponds to.
     * @return An address array representing the jurors.
     */
    function getVotingJurors(uint256 _publicationId)
        external
        view
        onlyExistentPublications(_publicationId)
        returns (address[] memory)
    {
        return votings[_publicationId].jurors;
    }

    /**
     * @dev Gets vote counters in a given publication voting.
     * @param _publicationId The publication id where voting corresponds to.
     * @return An integer array representing the vote counters.
     */
    function getVoteCounters(uint256 _publicationId)
        external
        view
        onlyExistentPublications(_publicationId)
        returns (uint256[] memory)
    {
        return votings[_publicationId].voteCounters;
    }

    /**
     * @dev Verifies if address is juror in a given publication voting.
     * @param _publicationId The publication id where voting corresponds to.
     * @param _address The address to verify if is juror.
     * @return A boolean indicating if address is juror or not.
     */
    function isJuror(uint256 _publicationId, address _address)
        external
        view
        onlyExistentPublications(_publicationId)
        returns (bool)
    {
        return votings[_publicationId].isJuror[_address];
    }

    /**
     * @dev Verifies if juror is penalized for a given publication voting.
     * @param _publicationId The publication id where voting corresponds to.
     * @param _juror The juror address.
     * @return A boolean indicating if juror is penalized or not.
     */
    function isPenalized(uint256 _publicationId, address _juror)
        external
        view 
        onlyExistentPublications(_publicationId)
        onlyPublicationJurors(_publicationId, _juror) 
        returns (bool) 
    {
        return votings[_publicationId].isJuror[_juror];
    }

    /**
     * @dev Gets vote value from juror in publication.
     * @param _publicationId The publication id where voting corresponds to.
     * @param _juror The juror address.
     * @return An integer representing the vote value.
     */
    function getVoteValue(uint256 _publicationId, address _juror)
        external
        view 
        onlyExistentPublications(_publicationId)
        onlyPublicationJurors(_publicationId, _juror) 
        returns (uint8) 
    {
        return uint8(votings[_publicationId].votes[_juror].value);
    }

    /**
     * @dev Subscribes the sender as juror for the given topic. If topic does not extis, then creates it.
     * When adding times to the subscription DAI tokens are pulled from the juror balance.
     * To use as unsuscribe function, set times to zero. Also to create topic without subscribing to it.
     * @param _topicId The topic id to subscribe in.
     * @param _times The total times the juror is willing to be selected as juror simultaneously. Overrides the curent.
     * @param _nonce The nonce as defined in DAI permit function.
     * @param _expiry The expiry as defined in DAI permit function.
     * @param _v The v parameter of ECDSA signature as defined in EIP712.
     * @param _r The r parameter of ECDSA signature as defined in EIP712.
     * @param _s The s parameter of ECDSA signature as defined in EIP712.
     */
    function subscribeAsJuror(
        string calldata _topicId,
        uint256 _times,
        uint256 _nonce,
        uint256 _expiry,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        if (!topics[_topicId].created) {
            createTopic(_topicId);
        }
        if (topics[_topicId].jurorTimes[msg.sender] > _times) {
            decreaseJurorTimes(_topicId, msg.sender, _times);
        } else if (topics[_topicId].jurorTimes[msg.sender] < _times) {
            increaseJurorTimes(_topicId, msg.sender, _times, _nonce, _expiry, _v, _r, _s);
        }
        topics[_topicId].jurorTimes[msg.sender] = _times;
        emit JurorSubscription(msg.sender, _topicId, _times);
    }

    /**
     * @dev Sender publish a new publication in the given topic acting as the author. When publishing DAI tokens are 
     * pulled from the author balance, recovered later if the publication is voted as true by the selcted jurors.
     * @param _publicationHash The publication file hash.
     * @param _topicId The topic id where to publish.
     * @param _nonce The nonce as defined in DAI permit function.
     * @param _expiry The expiry as defined in DAI permit function.
     * @param _v The v parameter of ECDSA signature as defined in EIP712.
     * @param _r The r parameter of ECDSA signature as defined in EIP712.
     * @param _s The s parameter of ECDSA signature as defined in EIP712.
     * @return An integer indicating id assigned to the publication.
     */
    function publish(
        string calldata _publicationHash,
        string calldata _topicId,
        uint256 _nonce,
        uint256 _expiry,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256) {
        require(topics[_topicId].created, "Unexistent topic");
        require(!topics[_topicId].closed, "Closed topic");
        require(
            topics[_topicId].selectableJurors.length >= MIN_SELECTABLE_JURORS_QTY,
            "Insuficient selectable jurors in the topic"
        );
        Publication storage publication = publications[publicationId];
        publication.hash = _publicationHash;
        publication.author = msg.sender;
        publication.publishDate = block.timestamp;
        publication.topicId = _topicId;
        selectJurors(publicationId);
        votings[publicationId].voteCounters = [VOTING_JURORS_QTY, 0, 0, 0];
        dai.permit(msg.sender, address(this), _nonce, _expiry, true, _v, _r, _s);
        dai.transferFrom(msg.sender, address(this), topics[_topicId].priceToPublish);
        emit PublicationSubmission(
            publicationId, msg.sender, _topicId, votings[publicationId].jurors, _publicationHash, block.timestamp
        );
        return publicationId++;
    }

    /**
     * @dev Commits vote commitment for the given publication. First phase of the commit and reveal voting scheme.
     * @param _publicationId The publication id to vote for.
     * @param _commitment The commitment for this vote.
     * @param _nonce The nonce used to generate the given commitment.
     */
    function commitVote(uint256 _publicationId, bytes32 _commitment, uint256 _nonce) 
        external
        onlyExistentPublications(_publicationId)
        onlyPublicationJurors(_publicationId, msg.sender)
    {
        require(timeToFinishCommitPhase(_publicationId) > 0, "Vote commit phase has already finished");
        require(votings[_publicationId].votes[msg.sender].nonce == _nonce, "Invalid nonce");
        require(proofOfHumanity.isRegistered(msg.sender), "You must be registered in Proof of Humanity");
        votings[_publicationId].votes[msg.sender].commitment = _commitment;
        votings[_publicationId].votes[msg.sender].nonce = _nonce + 1;
        emit VoteCommitment(msg.sender, _publicationId, _commitment);
    }

    /**
     * @dev Reveals vote for the given publication. Second phase of the commit and reveal voting scheme. The given
     * parameters must match the last commitment performed by the juror. Calling it in commit phase penalizes you.
     * @param _publicationId The publication id to vote for.
     * @param _vote The actual vote value.
     * @param _justification The justification for the given vote value.
     * @param _nonce The nonce used to generate the vote commitment.
     * @param _v The v parameter of ECDSA signature as defined in EIP712.
     * @param _r The r parameter of ECDSA signature as defined in EIP712.
     * @param _s The s parameter of ECDSA signature as defined in EIP712.
     * @return A boolean indicating if juror was penalized or not.
     */
    function revealVote(
        uint256 _publicationId,
        uint8 _vote,
        uint256 _nonce,
        string calldata _justification,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external 
        onlyExistentPublications(_publicationId)
        onlyPublicationJurors(_publicationId, msg.sender)
        returns (bool) 
    {
        if (timeToFinishCommitPhase(_publicationId) > 0) {
            votings[_publicationId].isPenalized[msg.sender] = true;
        } else {
            require(votings[_publicationId].votes[msg.sender].value == VoteValue.None, "Reveal already done");
            require(!votings[_publicationId].isPenalized[msg.sender], "Penalized juror");
            require(votings[_publicationId].votes[msg.sender].nonce > 0, "Missing vote commitment");
            require(votings[_publicationId].votes[msg.sender].nonce - 1 == _nonce, "Invalid nonce");
            require(timeToFinishRevealPhase(_publicationId) > 0, "Vote reveal phase has already finished");
            require(_vote > uint8(VoteValue.None) && _vote <= uint8(VoteValue.Unqualified), "Invalid vote value");
            require(
                votings[_publicationId].votes[msg.sender].commitment == keccak256(abi.encode(_v, _r, _s)),
                "Invalid vote reveal: revealed values do not match commitment"
            );
            require(
                isValidSignature(_publicationId, msg.sender, _vote, _v, _r, _s),
                "Invalid vote reveal: invalid signature"
            );
            require(proofOfHumanity.isRegistered(msg.sender), "You must be registered in Proof of Humanity");
            countVote(_publicationId, msg.sender, VoteValue(_vote), _justification);
        }
        emitVoteRevealEvent(_publicationId, msg.sender, _vote, _justification);
        return votings[_publicationId].isPenalized[msg.sender];
    }

    /**
     * @dev Withdraws rewards and confirms economic penalizations over the author and jurors after publication voting.
     * @param _publicationId The publication id where perform the withdrawal.
     */
    function withdrawRewards(uint256 _publicationId) external onlyExistentPublications(_publicationId) {
        require(timeToFinishRevealPhase(_publicationId) == 0, "Vote reveal phase has not finished yet");
        require(!votings[_publicationId].withdrawn, "Publication rewards already withdrawn");
        string memory topicId = publications[_publicationId].topicId;
        if (votings[_publicationId].winningVote == VoteValue.True) {
            dai.transferFrom(address(this), publications[_publicationId].author, topics[topicId].priceToPublish);
            gazzeth.mint(publications[_publicationId].author, topics[topicId].authorReward);
        }
        for (uint256 i = 0; i < votings[_publicationId].jurors.length; i++) {
            address juror = votings[_publicationId].jurors[i];
            if (jurorMustBeRewarded(_publicationId, juror)) {
                if (topics[topicId].jurorSelectedTimes[juror] == topics[topicId].jurorTimes[juror]) {
                    topics[topicId].selectableJurors.push(juror);
                }
                gazzeth.mint(juror, topics[topicId].jurorReward);
            } else {
                if (--topics[topicId].jurorTimes[juror] == 0) {
                    topics[topicId].jurorQuantity--;
                }
                // TODO: Take in account the line below when topic prices can be changed by governance
                protocolDaiBalance += topics[topicId].priceToBeJuror;
            }
            topics[topicId].jurorSelectedTimes[juror]--;
        }
        votings[_publicationId].withdrawn = true;
        emit Withdrawal(_publicationId);
    }

    /**
     * @dev Verifies if juror must be rewarded after voting. Must not be penalized and must voted the winning vote.
     * @param _publicationId The publication id where voting corresponds to.
     * @param _juror The juror address.
     * @return A boolean indicating if juror must be rewarded or not.
     */
    function jurorMustBeRewarded(uint256 _publicationId, address _juror) internal view returns (bool) {
        return !votings[_publicationId].isPenalized[_juror]
            && votings[_publicationId].votes[_juror].value != VoteValue.None 
            && votings[_publicationId].votes[_juror].value == votings[_publicationId].winningVote;
    }

    /**
     * @dev Generates the struct hash as defined in EIP712, used to rebuild commitment to perform reveal voting phase.
     * @param _publicationId The publication id where vote commitment corresponds to.
     * @param _vote The vote value revealed.
     * @param _nonce The nonce used for the vote commitment.
     * @return The struct hash according to EIP712 standard.
     */
    function hashStruct(uint256 _publicationId, uint8 _vote, uint256 _nonce) internal view returns (bytes32) {
        return keccak256(abi.encode(VOTE_TYPEHASH, _publicationId, _vote, _nonce));
    }

    /**
     * @dev Returns if is a valid signature recovering the signer adderss and comparing to the juror one.
     * @param _publicationId The publication id.
     * @param _juror The juror address.
     * @param _vote The vote value.
     * @param _v The v parameter of ECDSA signature as defined in EIP712.
     * @param _r The r parameter of ECDSA signature as defined in EIP712.
     * @param _s The s parameter of ECDSA signature as defined in EIP712.
     * @return A boolean indicating if is valid signature or not.
     */
    function isValidSignature(
        uint256 _publicationId,
        address _juror,
        uint8 _vote,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view returns (bool) {
        uint256 nonce = votings[_publicationId].votes[_juror].nonce - 1;
        return ECDSA.recover(_hashTypedDataV4(hashStruct(_publicationId, _vote, nonce)), _v, _r, _s) == _juror;
    }

    /**
     * @dev Counts the given vote for the given publication updating voting statuses.
     * @param _publicationId The publication id to vote for.
     * @param _juror The juror address.
     * @param _vote The actual vote value.
     * @param _justification The justification for the given vote value.
     */
    function countVote(uint256 _publicationId, address _juror, VoteValue _vote, string memory _justification) internal {
        uint8 voteAsIndex = uint8(_vote);
        votings[_publicationId].voteCounters[uint8(VoteValue.None)]--;
        votings[_publicationId].voteCounters[voteAsIndex]++;
        votings[_publicationId].votes[_juror].value = _vote;
        votings[_publicationId].votes[_juror].justification = _justification;
        if (votings[_publicationId].winningVote == _vote) {
            votings[_publicationId].maxVoteCount++;
        } else if (votings[_publicationId].voteCounters[voteAsIndex] == votings[_publicationId].maxVoteCount) {
            votings[_publicationId].winningVote == VoteValue.None;
        } else if (votings[_publicationId].voteCounters[voteAsIndex] > votings[_publicationId].maxVoteCount) {
            votings[_publicationId].winningVote == _vote;
            votings[_publicationId].maxVoteCount = votings[_publicationId].voteCounters[voteAsIndex];
        }
    }

    /**
     * @dev Emits the VoteReveal event. Made as a separated function to avoid 'Stack too deep' error.
     * @param _publicationId The publication id to vote for.
     * @param _juror The juror address.
     * @param _vote The actual vote value.
     * @param _justification The justification for the given vote value.
     */
    function emitVoteRevealEvent(
        uint256 _publicationId,
        address _juror,
        uint8 _vote,
        string memory _justification
    ) internal {
        emit VoteReveal(
            _juror,
            _publicationId,
            votings[_publicationId].isPenalized[_juror] ? uint8(VoteValue.None) : _vote,
            votings[_publicationId].isPenalized[_juror] ? "Penalized juror" : _justification,
            votings[_publicationId].voteCounters,
            uint256(votings[_publicationId].winningVote)
        );
    }

    /**
     * @dev Gets the time left to a given deadline.
     * @param _deadlineTimestamp The deadline where to obtain the time left.
     * @return An integer representing seconds left to reach the given deadline.
     */
    function timeToDeadlineTimestamp(uint256 _deadlineTimestamp) internal view returns (uint256) {
        return _deadlineTimestamp <= block.timestamp ? 0 : _deadlineTimestamp - block.timestamp;
    }

    /**
     * @dev Verifies if author is selectable as juror in a given topic.
     * @param _topicId The id of the topic where author is publishing.
     * @param _author The address of the publication author.
     * @return A boolean indicating if author is selectable or not.
     */
    function isAuthorSelectableAsJuror(string memory _topicId, address _author) internal view returns (bool) {
        return topics[_topicId].jurorTimes[_author] > 0 
            && topics[_topicId].jurorSelectedTimes[_author] < topics[_topicId].jurorTimes[_author];
    }

    /**
     * @dev Randomly selects the jurors for the given publication id.
     * @param _publicationId The publication id where jurors must be selected.
     */
    function selectJurors(uint256 _publicationId) internal {
        uint256[] memory randoms = rng.getRandomNumbers(VOTING_JURORS_QTY);
        string memory topicId = publications[_publicationId].topicId;
        uint256 selectableJurorsLength = topics[topicId].selectableJurors.length;
        if (isAuthorSelectableAsJuror(topicId, publications[_publicationId].author)) {
            avoidAuthorAsSelectableJuror(topicId, publications[_publicationId].author);
            selectableJurorsLength--;
        }
        for (uint256 i = 0; i < VOTING_JURORS_QTY; i++) {
            uint256 selectedJurorIndex = randoms[i].mod(selectableJurorsLength);
            address selectedJuror = topics[topicId].selectableJurors[selectedJurorIndex];
            topics[topicId].jurorSelectedTimes[selectedJuror]++;
            votings[_publicationId].jurors.push(selectedJuror);
            votings[_publicationId].isJuror[selectedJuror] = true;
            topics[topicId].selectableJurors[selectedJurorIndex] 
                = topics[topicId].selectableJurors[selectableJurorsLength - 1];
            if (topics[topicId].jurorSelectedTimes[selectedJuror] == topics[topicId].jurorTimes[selectedJuror]) {
                topics[topicId].selectableJurors[selectableJurorsLength - 1] 
                    = topics[topicId].selectableJurors[topics[topicId].selectableJurors.length - 1];
                topics[topicId].selectableJurors.pop();
            } else {
                topics[topicId].selectableJurors[selectableJurorsLength - 1] = selectedJuror;
            }
            selectableJurorsLength--;
        }
    }

    /**
     * @dev Avoids an author from being selected as juror in a given topic.
     * @param _topicId The id of the topic where author must be avoided.
     * @param _author The address of the author.
     */
    function avoidAuthorAsSelectableJuror(string memory _topicId, address _author) internal {
        uint256 lastSelectableJurorIndex = topics[_topicId].selectableJurors.length - 1;
        uint256 authorIndex = 0;
        while (topics[_topicId].selectableJurors[authorIndex] != _author) {
            authorIndex++;
        }
        topics[_topicId].selectableJurors[authorIndex] = topics[_topicId].selectableJurors[lastSelectableJurorIndex];
        topics[_topicId].selectableJurors[lastSelectableJurorIndex] = _author;
    }

    /**
     * @dev Creates a new topic with the given id and default values.
     * @param _topicId The id of the topic to create.
     */
    function createTopic(string memory _topicId) internal {
        topics[_topicId].created = true;
        topics[_topicId].priceToPublish = DEFAULT_PRICE_TO_PUBLISH;
        topics[_topicId].priceToBeJuror = DEFAULT_PRICE_TO_BE_JUROR;
        topics[_topicId].authorReward = DEFAULT_AUTHOR_REWARD;
        topics[_topicId].jurorReward = DEFAULT_JUROR_REWARD;
        topics[_topicId].commitPhaseDuration = DEFAULT_COMMIT_DURATION;
        topics[_topicId].revealPhaseDuration = DEFAULT_REVEAL_DURATION;
        emit TopicCreation(
            _topicId,
            DEFAULT_PRICE_TO_PUBLISH,
            DEFAULT_PRICE_TO_BE_JUROR,
            DEFAULT_AUTHOR_REWARD,
            DEFAULT_JUROR_REWARD,
            DEFAULT_COMMIT_DURATION,
            DEFAULT_REVEAL_DURATION
        );
    }

    /**
     * @dev Decreases times as juror in the topic. Transfers the freed deposited DAI to the juror.
     * @param _topicId The topic id where to decrease juror times.
     * @param _juror The juror address.
     * @param _times The total times the juror is willing to be selected as juror simultaneously. Overrides the curent.
     */
    function decreaseJurorTimes(string memory _topicId, address _juror, uint256 _times) internal {
        require(
            topics[_topicId].jurorSelectedTimes[_juror] <= _times,
            "Times must be less than current juror votings"
        );
        if (_times == 0) {
            topics[_topicId].jurorQuantity--;
            // This loop can be avoided maintaining a mapping from juror address to its index in selectableJurors array
            uint256 jurorIndex = 0;
            while (topics[_topicId].selectableJurors[jurorIndex] != _juror) {
                jurorIndex++;
            }
            address lastJuror = topics[_topicId].selectableJurors[topics[_topicId].selectableJurors.length - 1];
            topics[_topicId].selectableJurors[jurorIndex] = lastJuror;
            topics[_topicId].selectableJurors.pop();
        }
        // TODO: Lowering topic priceToBeJuror must transfer the DAI left over according to new price for each juror
        dai.transferFrom(
            address(this),
            _juror,
            topics[_topicId].priceToBeJuror.mul(topics[_topicId].jurorTimes[_juror].sub(_times))
        );
    }

    /**
     * @dev Increases times as juror in the topic. Pulls DAI as deposit from the juror.
     * @param _topicId The topic id where to decrease juror times.
     * @param _juror The juror address.
     * @param _times The total times the juror is willing to be selected as juror simultaneously. Overrides the curent.
     * @param _nonce The nonce as defined in DAI permit function.
     * @param _expiry The expiry as defined in DAI permit function.
     * @param _v The v parameter of ECDSA signature as defined in EIP712.
     * @param _r The r parameter of ECDSA signature as defined in EIP712.
     * @param _s The s parameter of ECDSA signature as defined in EIP712.
     */
    function increaseJurorTimes(
        string memory _topicId,
        address _juror,
        uint256 _times,
        uint256 _nonce,
        uint256 _expiry,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal {
        require(proofOfHumanity.isRegistered(_juror), "To be a juror you must be registered on Proof of Humanity");
        if (topics[_topicId].jurorTimes[_juror] == topics[_topicId].jurorSelectedTimes[_juror]) {
            // Take in account that jurorTimes[_juror] == 0 always implies jurorSelectedTimes[_juror] == 0
            topics[_topicId].selectableJurors.push(_juror);
        }
        if (topics[_topicId].jurorTimes[_juror] == 0) {
            topics[_topicId].jurorQuantity++;
        }
        dai.permit(_juror, address(this), _nonce, _expiry, true, _v, _r, _s);
        dai.transferFrom(
            _juror,
            address(this),
            topics[_topicId].priceToBeJuror.mul(_times.sub(topics[_topicId].jurorTimes[_juror]))
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) internal {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = _getChainId();
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view virtual returns (bytes32) {
        if (_getChainId() == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDai is IERC20 {
    
    function permit(
        address _holder, address _spender, uint256 _nonce, uint256 _expiry, bool _allowed, uint8 _v, bytes32 _r, bytes32 _s
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

interface IProofOfHumanity {

    /** 
     * @dev Return true if the submission is registered and not expired.
     * @param _address The address of the submission.
     * @return Whether the submission is registered or not.
     */
    function isRegistered(address _address) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

interface IRng {
    
    /**
     * @param _quantity The quantity of random numbers to output.
     * @return A random number array of the given length.
     */
    function getRandomNumbers(uint256 _quantity) external returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/drafts/IERC20Permit.sol";

interface IErc20PermitMintable is IERC20, IERC20Permit {
    
    function mint(address _toAccount, uint256 _amount) external;

    function burn(address _fromAccount, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

