pragma solidity ^0.4.19;


//
// SVLightBallotBox
// Single use contract to manage a ballot
// Author: Max Kaye <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7419150c340711170106115a021b0011">[email&#160;protected]</a>>
// (c) SecureVote 2018
//
// Architecture:
// * Ballot authority declares public key with which to encrypt ballots (optional - stored in ballot spec)
// * Users submit encrypted or plaintext ballots as blobs (dependent on above)
// * These ballots are tracked by the ETH address of the sender
// * Following the conclusion of the ballot, the secret key is provided
//   by the ballot authority, and all users may transparently and
//   independently validate the results
//
// Notes:
// * Since ballots are encrypted the only validation we can do is length, but UI takes care of most of the rest
//


contract SVLightBallotBox {
    //// ** Storage Variables

    // Std owner pattern
    address public owner;

    // test mode - operations like changing start/end times
    bool public testMode = false;

    // struct for ballot
    struct Ballot {
        bytes32 ballotData;
        address sender;
        // we use a uint32 here because addresses are 20 bytes and this might help
        // solidity pack the block number well. gives us a little room to expand too if needed.
        uint32 blockN;
    }

    // Maps to store ballots, along with corresponding log of voters.
    // Should only be modified through `addBallotAndVoter` internal function
    mapping (uint256 => Ballot) public ballotMap;
    mapping (uint256 => bytes32) public associatedPubkeys;
    uint256 public nVotesCast = 0;

    // Use a map for voters to look up their ballot
    mapping (address => uint256) public voterToBallotID;

    // NOTE - We don&#39;t actually want to include the PublicKey because _it&#39;s included in the ballotSpec_.
    // It&#39;s better to ensure ppl actually have the ballot spec by not including it in the contract.
    // Plus we&#39;re already storing the hash of the ballotSpec anyway...

    // Private key to be set after ballot conclusion - curve25519
    bytes32 public ballotEncryptionSeckey;
    bool seckeyRevealed = false;

    // Timestamps for start and end of ballot (UTC)
    uint64 public startTime;
    uint64 public endTime;
    uint64 public creationBlock;
    uint64 public startingBlockAround;

    // specHash by which to validate the ballots integrity
    bytes32 public specHash;
    bool public useEncryption;

    // deprecation flag - doesn&#39;t actually do anything besides signal that this contract is deprecated;
    bool public deprecated = false;

    //// ** Events
    event CreatedBallot(address _creator, uint64[2] _openPeriod, bool _useEncryption, bytes32 _specHash);
    event SuccessfulPkVote(address voter, bytes32 ballot, bytes32 pubkey);
    event SuccessfulVote(address voter, bytes32 ballot);
    event SeckeyRevealed(bytes32 secretKey);
    event TestingEnabled();
    event Error(string error);
    event DeprecatedContract();
    event SetOwner(address _owner);


    //// ** Modifiers

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier ballotOpen {
        require(uint64(block.timestamp) >= startTime && uint64(block.timestamp) < endTime);
        _;
    }

    modifier onlyTesting {
        require(testMode);
        _;
    }

    modifier isTrue(bool _b) {
        require(_b == true);
        _;
    }

    modifier isFalse(bool _b) {
        require(_b == false);
        _;
    }

    //// ** Functions

    uint16 constant F_USE_ENC = 0;
    uint16 constant F_TESTING = 1;
    // Constructor function - init core params on deploy
    // timestampts are uint64s to give us plenty of room for millennia
    // flags are [_useEncryption, enableTesting]
    function SVLightBallotBox(bytes32 _specHash, uint64[2] openPeriod, bool[2] flags) public {
        owner = msg.sender;

        // take the max of the start time provided and the blocks timestamp to avoid a DoS against recent token holders
        // (which someone might be able to do if they could set the timestamp in the past)
        startTime = max(openPeriod[0], uint64(block.timestamp));
        endTime = openPeriod[1];
        useEncryption = flags[F_USE_ENC];
        specHash = _specHash;
        creationBlock = uint64(block.number);
        // add a rough prediction of what block is the starting block
        startingBlockAround = uint64((startTime - block.timestamp) / 15 + block.number);

        if (flags[F_TESTING]) {
            testMode = true;
            TestingEnabled();
        }

        CreatedBallot(msg.sender, [startTime, endTime], useEncryption, specHash);
    }

    // Ballot submission
    function submitBallotWithPk(bytes32 encryptedBallot, bytes32 senderPubkey) isTrue(useEncryption) ballotOpen public {
        addBallotAndVoterWithPk(encryptedBallot, senderPubkey);
        SuccessfulPkVote(msg.sender, encryptedBallot, senderPubkey);
    }

    function submitBallotNoPk(bytes32 ballot) isFalse(useEncryption) ballotOpen public {
        addBallotAndVoterNoPk(ballot);
        SuccessfulVote(msg.sender, ballot);
    }

    // Internal function to ensure atomicity of voter log
    function addBallotAndVoterWithPk(bytes32 encryptedBallot, bytes32 senderPubkey) internal {
        uint256 ballotNumber = addBallotAndVoterNoPk(encryptedBallot);
        associatedPubkeys[ballotNumber] = senderPubkey;
    }

    function addBallotAndVoterNoPk(bytes32 encryptedBallot) internal returns (uint256) {
        uint256 ballotNumber = nVotesCast;
        ballotMap[ballotNumber] = Ballot(encryptedBallot, msg.sender, uint32(block.number));
        voterToBallotID[msg.sender] = ballotNumber;
        nVotesCast += 1;
        return ballotNumber;
    }

    // Allow the owner to reveal the secret key after ballot conclusion
    function revealSeckey(bytes32 _secKey) onlyOwner public {
        require(block.timestamp > endTime);

        ballotEncryptionSeckey = _secKey;
        seckeyRevealed = true; // this flag allows the contract to be locked
        SeckeyRevealed(_secKey);
    }

    function getEncSeckey() public constant returns (bytes32) {
        return ballotEncryptionSeckey;
    }

    // Test functions
    function setEndTime(uint64 newEndTime) onlyTesting onlyOwner public {
        endTime = newEndTime;
    }

    function setDeprecated() onlyOwner public {
        deprecated = true;
        DeprecatedContract();
    }

    function setOwner(address newOwner) onlyOwner public {
        owner = newOwner;
        SetOwner(newOwner);
    }

    // utils
    function max(uint64 a, uint64 b) pure internal returns(uint64) {
        if (a > b) {
            return a;
        }
        return b;
    }
}


//
// The Index by which democracies and ballots are tracked (and optionally deployed).
// Author: Max Kaye <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="016c6079417264627473642f776e7564">[email&#160;protected]</a>>
// (c) SecureVote 2018
//

contract SVLightIndexShim {

    address public owner;

    struct Ballot {
        bytes32 specHash;
        bytes32 extraData;
        address votingContract;
        uint64 startTs;
    }

    struct Democ {
        string name;
        address admin;
        Ballot[] ballots;
    }

    mapping (bytes32 => Democ) public democs;
    bytes32[] public democList;

    bool public paymentEnabled = false;

    SVLightIndexShim prevIndex;

    //* EVENTS /

    event PaymentMade(uint128[2] valAndRemainder);
    event DemocInit(string name, bytes32 democHash, address admin);
    event BallotInit(bytes32 specHash, uint64[2] openPeriod, bool[2] flags);
    event BallotAdded(bytes32 democHash, bytes32 specHash, bytes32 extraData, address votingContract);
    event SetFees(uint128[2] _newFees);
    event PaymentEnabled(bool _feeEnabled);

    //* MODIFIERS /

    modifier onlyBy(address _account) {
        require(msg.sender == _account);
        _;
    }

    //* FUNCTIONS /


    // constructor
    constructor(SVLightIndexShim _prevIndex) public {
        owner = msg.sender;
        prevIndex = _prevIndex;

        bytes32 democHash;
        bytes32 specHash;
        bytes32 extraData;
        address votingContract;
        uint64 startTime;

        for (uint i = 0; i < prevIndex.nDemocs(); i++) {
            democHash = prevIndex.democList(i);
            democList.push(democHash);
            // only democracies are SWM
            democs[democHash].admin = msg.sender;

            for (uint j = 0; j < prevIndex.nBallots(democHash); j++) {
                (specHash, extraData, votingContract, startTime) = prevIndex.getNthBallot(democHash, j);
                democs[democHash].ballots.push(Ballot(specHash, extraData, votingContract, startTime));
            }
        }
    }

    //* GLOBAL INFO */

    function nDemocs() public constant returns (uint256) {
        return democList.length;
    }

    //* PAYMENT AND OWNER FUNCTIONS */

    function setOwner(address _owner) onlyBy(owner) public {
        owner = _owner;
    }

    function setDemocAdminEmergency(bytes32 democHash, address newAdmin) onlyBy(owner) public {
        democs[democHash].admin = newAdmin;
    }

    //* DEMOCRACY FUNCTIONS - INDIVIDUAL */

    function getDemocInfo(bytes32 democHash) public constant returns (string name, address admin, uint256 nBallots) {
        // only democs are SWM Gov democs
        return ("SWM Governance", democs[democHash].admin, democs[democHash].ballots.length);
    }

    function setAdmin(bytes32 democHash, address newAdmin) onlyBy(democs[democHash].admin) public {
        democs[democHash].admin = newAdmin;
    }

    function nBallots(bytes32 democHash) public constant returns (uint256) {
        return democs[democHash].ballots.length;
    }

    function getNthBallot(bytes32 democHash, uint256 n) public constant returns (bytes32 specHash, bytes32 extraData, address votingContract, uint64 startTime) {
        return (democs[democHash].ballots[n].specHash, democs[democHash].ballots[n].extraData, democs[democHash].ballots[n].votingContract, democs[democHash].ballots[n].startTs);
    }

    //* ADD BALLOT TO RECORD */

    function _commitBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, address votingContract, uint64 startTs) internal {
        democs[democHash].ballots.push(Ballot(specHash, extraData, votingContract, startTs));
        BallotAdded(democHash, specHash, extraData, votingContract);
    }

    function addBallot(bytes32 democHash, bytes32 extraData, address votingContract)
                      onlyBy(democs[democHash].admin)
                      public
                      {
        SVLightBallotBox bb = SVLightBallotBox(votingContract);
        bytes32 specHash = bb.specHash();
        uint64 startTs = bb.startTime();
        _commitBallot(democHash, specHash, extraData, votingContract, startTs);
    }

    function deployBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData,
                          uint64[2] openPeriod, bool[2] flags)
                          onlyBy(democs[democHash].admin)
                          public payable {
        // the start time is max(startTime, block.timestamp) to avoid a DoS whereby a malicious electioneer could disenfranchise
        // token holders who have recently acquired tokens.
        uint64 startTs = max(openPeriod[0], uint64(block.timestamp));
        SVLightBallotBox votingContract = new SVLightBallotBox(specHash, [startTs, openPeriod[1]], flags);
        votingContract.setOwner(msg.sender);
        _commitBallot(democHash, specHash, extraData, address(votingContract), startTs);
        BallotInit(specHash, [startTs, openPeriod[1]], flags);
    }

    // utils
    function max(uint64 a, uint64 b) pure internal returns(uint64) {
        if (a > b) {
            return a;
        }
        return b;
    }
}