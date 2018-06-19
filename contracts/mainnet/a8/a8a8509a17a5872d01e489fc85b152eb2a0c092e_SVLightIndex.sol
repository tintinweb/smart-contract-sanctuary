pragma solidity ^0.4.19;


//
// SVLightBallotBox
// Single use contract to manage a ballot
// Author: Max Kaye <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6e030f162e1d0b0d1b1c0b4018011a0b">[email&#160;protected]</a>>
// License: MIT
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
// Author: Max Kaye <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ed808c95ad9e888e989f88c39b829988">[email&#160;protected]</a>>
// License: MIT
//

contract SVLightIndex {

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

    // addresses that do not have to pay for democs
    mapping (address => bool) public democWhitelist;
    // democs that do not have to pay for issues
    mapping (address => bool) public ballotWhitelist;

    // payment details
    address public payTo;
    // uint128&#39;s used because they account for amounts up to 3.4e38 wei or 3.4e20 ether
    uint128 public democFee = 0.05 ether; // 0.05 ether; about $50 at 3 March 2018
    mapping (address => uint128) democFeeFor;
    uint128 public ballotFee = 0.01 ether; // 0.01 ether; about $10 at 3 March 2018
    mapping (address => uint128) ballotFeeFor;
    bool public paymentEnabled = true;

    uint8 constant PAY_DEMOC = 0;
    uint8 constant PAY_BALLOT = 1;

    function getPaymentParams(uint8 paymentType) internal constant returns (bool, uint128, uint128) {
        if (paymentType == PAY_DEMOC) {
            return (democWhitelist[msg.sender], democFee, democFeeFor[msg.sender]);
        } else if (paymentType == PAY_BALLOT) {
            return (ballotWhitelist[msg.sender], ballotFee, ballotFeeFor[msg.sender]);
        } else {
            assert(false);
        }
    }

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

    modifier payReq(uint8 paymentType) {
        // get our whitelist, generalFee, and fee&#39;s for particular addresses
        bool wl;
        uint128 genFee;
        uint128 feeFor;
        (wl, genFee, feeFor) = getPaymentParams(paymentType);
        // init v to something large in case of exploit or something
        uint128 v = 1000 ether;
        // check whitelists - do not require payment in some cases
        if (paymentEnabled && !wl) {
            v = feeFor;
            if (v == 0){
                // if there&#39;s no fee for the individual user then set it to the general fee
                v = genFee;
            }
            require(msg.value >= v);

            // handle payments
            uint128 remainder = uint128(msg.value) - v;
            payTo.transfer(v); // .transfer so it throws on failure
            if (!msg.sender.send(remainder)){
                payTo.transfer(remainder);
            }
            PaymentMade([v, remainder]);
        }

        // do main
        _;
    }


    //* FUNCTIONS /


    // constructor
    function SVLightIndex() public {
        owner = msg.sender;
        payTo = msg.sender;
    }

    //* GLOBAL INFO */

    function nDemocs() public constant returns (uint256) {
        return democList.length;
    }

    //* PAYMENT AND OWNER FUNCTIONS */

    function setPayTo(address newPayTo) onlyBy(owner) public {
        payTo = newPayTo;
    }

    function setEth(uint128[2] newFees) onlyBy(owner) public {
        democFee = newFees[PAY_DEMOC];
        ballotFee = newFees[PAY_BALLOT];
        SetFees([democFee, ballotFee]);
    }

    function setOwner(address _owner) onlyBy(owner) public {
        owner = _owner;
    }

    function setPaymentEnabled(bool _enabled) onlyBy(owner) public {
        paymentEnabled = _enabled;
        PaymentEnabled(_enabled);
    }

    function setWhitelistDemoc(address addr, bool _free) onlyBy(owner) public {
        democWhitelist[addr] = _free;
    }

    function setWhitelistBallot(address addr, bool _free) onlyBy(owner) public {
        ballotWhitelist[addr] = _free;
    }

    function setFeeFor(address addr, uint128[2] fees) onlyBy(owner) public {
        democFeeFor[addr] = fees[PAY_DEMOC];
        ballotFeeFor[addr] = fees[PAY_BALLOT];
    }

    //* DEMOCRACY FUNCTIONS - INDIVIDUAL */

    function initDemoc(string democName) payReq(PAY_DEMOC) public payable returns (bytes32) {
        bytes32 democHash = keccak256(democName, msg.sender, democList.length, this);
        democList.push(democHash);
        democs[democHash].name = democName;
        democs[democHash].admin = msg.sender;
        DemocInit(democName, democHash, msg.sender);
        return democHash;
    }

    function getDemocInfo(bytes32 democHash) public constant returns (string name, address admin, uint256 nBallots) {
        return (democs[democHash].name, democs[democHash].admin, democs[democHash].ballots.length);
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
                      payReq(PAY_BALLOT)
                      public
                      payable
                      {
        SVLightBallotBox bb = SVLightBallotBox(votingContract);
        bytes32 specHash = bb.specHash();
        uint64 startTs = bb.startTime();
        _commitBallot(democHash, specHash, extraData, votingContract, startTs);
    }

    function deployBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData,
                          uint64[2] openPeriod, bool[2] flags)
                          onlyBy(democs[democHash].admin)
                          payReq(PAY_BALLOT)
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