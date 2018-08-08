pragma solidity 0.4.24;

/* (c) 2018 SecureVote (Exo One Pty Ltd) */

contract BBFarmEvents {
    event BallotCreatedWithID(uint ballotId);
    event BBFarmInit(bytes4 namespace);
    event Sponsorship(uint ballotId, uint value);
    event Vote(uint indexed ballotId, bytes32 vote, address voter, bytes extra);
}

library BBLib {
    using BytesLib for bytes;

    // ballot meta
    uint256 constant BB_VERSION = 6;
    /* 4 deprecated due to insecure vote by proxy
       5 deprecated to
        - add `returns (address)` to submitProxyVote
    */

    // voting settings
    uint16 constant USE_ETH = 1;          // 2^0
    uint16 constant USE_SIGNED = 2;       // 2^1
    uint16 constant USE_NO_ENC = 4;       // 2^2
    uint16 constant USE_ENC = 8;          // 2^3

    // ballot settings
    uint16 constant IS_BINDING = 8192;    // 2^13
    uint16 constant IS_OFFICIAL = 16384;  // 2^14
    uint16 constant USE_TESTING = 32768;  // 2^15

    // other consts
    uint32 constant MAX_UINT32 = 0xFFFFFFFF;

    //// ** Storage Variables

    // struct for ballot
    struct Vote {
        bytes32 voteData;
        bytes32 castTsAndSender;
        bytes extra;
    }

    struct Sponsor {
        address sender;
        uint amount;
    }

    //// ** Events
    event CreatedBallot(bytes32 _specHash, uint64 startTs, uint64 endTs, uint16 submissionBits);
    event SuccessfulVote(address indexed voter, uint voteId);
    event SeckeyRevealed(bytes32 secretKey);
    event TestingEnabled();
    event DeprecatedContract();


    // The big database struct


    struct DB {
        // Maps to store ballots, along with corresponding log of voters.
        // Should only be modified through internal functions
        mapping (uint256 => Vote) votes;
        uint256 nVotesCast;

        // we need replay protection for proxy ballots - this will let us check against a sequence number
        // note: votes directly from a user ALWAYS take priority b/c they do not have sequence numbers
        // (sequencing is done by Ethereum itself via the tx nonce).
        mapping (address => uint32) sequenceNumber;

        // NOTE - We don&#39;t actually want to include the encryption PublicKey because _it&#39;s included in the ballotSpec_.
        // It&#39;s better to ensure ppl actually have the ballot spec by not including it in the contract.
        // Plus we&#39;re already storing the hash of the ballotSpec anyway...

        // Private key to be set after ballot conclusion - curve25519
        bytes32 ballotEncryptionSeckey;

        // packed contains:
        // 1. Timestamps for start and end of ballot (UTC)
        // 2. bits used to decide which options are enabled or disabled for submission of ballots
        uint256 packed;

        // specHash by which to validate the ballots integrity
        bytes32 specHash;
        // extradata if we need it - allows us to upgrade spechash format, etc
        bytes16 extraData;

        // allow tracking of sponsorship for this ballot & connection to index
        Sponsor[] sponsors;
        IxIface index;

        // deprecation flag - doesn&#39;t actually do anything besides signal that this contract is deprecated;
        bool deprecated;

        address ballotOwner;
        uint256 creationTs;
    }


    // ** Modifiers -- note, these are functions here to allow use as a lib
    function requireBallotClosed(DB storage db) internal view {
        require(now > BPackedUtils.packedToEndTime(db.packed), "!b-closed");
    }

    function requireBallotOpen(DB storage db) internal view {
        uint64 _n = uint64(now);
        uint64 startTs;
        uint64 endTs;
        (, startTs, endTs) = BPackedUtils.unpackAll(db.packed);
        require(_n >= startTs && _n < endTs, "!b-open");
        require(db.deprecated == false, "b-deprecated");
    }

    function requireBallotOwner(DB storage db) internal view {
        require(msg.sender == db.ballotOwner, "!b-owner");
    }

    function requireTesting(DB storage db) internal view {
        require(isTesting(BPackedUtils.packedToSubmissionBits(db.packed)), "!testing");
    }

    /* Library meta */

    function getVersion() external pure returns (uint) {
        // even though this is constant we want to make sure that it&#39;s actually
        // callable on Ethereum so we don&#39;t accidentally package the constant code
        // in with an SC using BBLib. This function _must_ be external.
        return BB_VERSION;
    }

    /* Functions */

    // "Constructor" function - init core params on deploy
    // timestampts are uint64s to give us plenty of room for millennia
    function init(DB storage db, bytes32 _specHash, uint256 _packed, IxIface ix, address ballotOwner, bytes16 extraData) external {
        require(db.specHash == bytes32(0), "b-exists");

        db.index = ix;
        db.ballotOwner = ballotOwner;

        uint64 startTs;
        uint64 endTs;
        uint16 sb;
        (sb, startTs, endTs) = BPackedUtils.unpackAll(_packed);

        bool _testing = isTesting(sb);
        if (_testing) {
            emit TestingEnabled();
        } else {
            require(endTs > now, "bad-end-time");

            // 0x1ff2 is 0001111111110010 in binary
            // by ANDing with subBits we make sure that only bits in positions 0,2,3,13,14,15
            // can be used. these correspond to the option flags at the top, and ETH ballots
            // that are enc&#39;d or plaintext.
            require(sb & 0x1ff2 == 0, "bad-sb");

            // if we give bad submission bits (e.g. all 0s) then refuse to deploy ballot
            bool okaySubmissionBits = 1 == (isEthNoEnc(sb) ? 1 : 0) + (isEthWithEnc(sb) ? 1 : 0);
            require(okaySubmissionBits, "!valid-sb");

            // take the max of the start time provided and the blocks timestamp to avoid a DoS against recent token holders
            // (which someone might be able to do if they could set the timestamp in the past)
            startTs = startTs > now ? startTs : uint64(now);
        }
        require(_specHash != bytes32(0), "null-specHash");
        db.specHash = _specHash;

        db.packed = BPackedUtils.pack(sb, startTs, endTs);
        db.creationTs = now;

        if (extraData != bytes16(0)) {
            db.extraData = extraData;
        }

        emit CreatedBallot(db.specHash, startTs, endTs, sb);
    }

    /* sponsorship */

    function logSponsorship(DB storage db, uint value) internal {
        db.sponsors.push(Sponsor(msg.sender, value));
    }

    /* getters */

    function getVote(DB storage db, uint id) internal view returns (bytes32 voteData, address sender, bytes extra, uint castTs) {
        return (db.votes[id].voteData, address(db.votes[id].castTsAndSender), db.votes[id].extra, uint(db.votes[id].castTsAndSender) >> 160);
    }

    function getSequenceNumber(DB storage db, address voter) internal view returns (uint32) {
        return db.sequenceNumber[voter];
    }

    function getTotalSponsorship(DB storage db) internal view returns (uint total) {
        for (uint i = 0; i < db.sponsors.length; i++) {
            total += db.sponsors[i].amount;
        }
    }

    function getSponsor(DB storage db, uint i) external view returns (address sender, uint amount) {
        sender = db.sponsors[i].sender;
        amount = db.sponsors[i].amount;
    }

    /* ETH BALLOTS */

    // Ballot submission
    // note: if USE_ENC then curve25519 keys should be generated for
    // each ballot (then thrown away).
    // the curve25519 PKs go in the extra param
    function submitVote(DB storage db, bytes32 voteData, bytes extra) external {
        _addVote(db, voteData, msg.sender, extra);
        // set the sequence number to max uint32 to disable proxy submitted ballots
        // after a voter submits a transaction personally - effectivley disables proxy
        // ballots. You can _always_ submit a new vote _personally_ with this scheme.
        if (db.sequenceNumber[msg.sender] != MAX_UINT32) {
            // using an IF statement here let&#39;s us save 4800 gas on repeat votes at the cost of 20k extra gas initially
            db.sequenceNumber[msg.sender] = MAX_UINT32;
        }
    }

    // Boundaries for constructing the msg we&#39;ll validate the signature of
    function submitProxyVote(DB storage db, bytes32[5] proxyReq, bytes extra) external returns (address voter) {
        // a proxy vote (where the vote is submitted (i.e. tx fee paid by someone else)
        // docs for datastructs: https://github.com/secure-vote/tokenvote/blob/master/Docs/DataStructs.md

        bytes32 r = proxyReq[0];
        bytes32 s = proxyReq[1];
        uint8 v = uint8(proxyReq[2][0]);
        // converting to uint248 will truncate the first byte, and we can then convert it to a bytes31.
        // we truncate the first byte because it&#39;s the `v` parm used above
        bytes31 proxyReq2 = bytes31(uint248(proxyReq[2]));
        // proxyReq[3] is ballotId - required for verifying sig but not used for anything else
        bytes32 ballotId = proxyReq[3];
        bytes32 voteData = proxyReq[4];

        // using abi.encodePacked is much cheaper than making bytes in other ways...
        bytes memory signed = abi.encodePacked(proxyReq2, ballotId, voteData, extra);
        bytes32 msgHash = keccak256(signed);
        // need to be sure we are signing the entire ballot and any extra data that comes with it
        voter = ecrecover(msgHash, v, r, s);

        // we need to make sure that this is the most recent vote the voter made, and that it has
        // not been seen before. NOTE: we&#39;ve already validated the BBFarm namespace before this, so
        // we know it&#39;s meant for _this_ ballot.
        uint32 sequence = uint32(proxyReq2);  // last 4 bytes of proxyReq2 - the sequence number
        _proxyReplayProtection(db, voter, sequence);

        _addVote(db, voteData, voter, extra);
    }

    function _addVote(DB storage db, bytes32 voteData, address sender, bytes extra) internal returns (uint256 id) {
        requireBallotOpen(db);

        id = db.nVotesCast;
        db.votes[id].voteData = voteData;
        // pack the casting ts right next to the sender
        db.votes[id].castTsAndSender = bytes32(sender) ^ bytes32(now << 160);
        if (extra.length > 0) {
            db.votes[id].extra = extra;
        }
        db.nVotesCast += 1;
        emit SuccessfulVote(sender, id);
    }

    function _proxyReplayProtection(DB storage db, address voter, uint32 sequence) internal {
        // we want the replay protection sequence number to be STRICTLY MORE than what
        // is stored in the mapping. This means we can set sequence to MAX_UINT32 to disable
        // any future votes.
        require(db.sequenceNumber[voter] < sequence, "bad-sequence-n");
        db.sequenceNumber[voter] = sequence;
    }

    /* Admin */

    function setEndTime(DB storage db, uint64 newEndTime) external {
        uint16 sb;
        uint64 sTs;
        (sb, sTs,) = BPackedUtils.unpackAll(db.packed);
        db.packed = BPackedUtils.pack(sb, sTs, newEndTime);
    }

    function revealSeckey(DB storage db, bytes32 sk) internal {
        db.ballotEncryptionSeckey = sk;
        emit SeckeyRevealed(sk);
    }

    /* Submission Bits (Ballot Classifications) */

    // do (bits & SETTINGS_MASK) to get just operational bits (as opposed to testing or official flag)
    uint16 constant SETTINGS_MASK = 0xFFFF ^ USE_TESTING ^ IS_OFFICIAL ^ IS_BINDING;

    function isEthNoEnc(uint16 submissionBits) pure internal returns (bool) {
        return checkFlags(submissionBits, USE_ETH | USE_NO_ENC);
    }

    function isEthWithEnc(uint16 submissionBits) pure internal returns (bool) {
        return checkFlags(submissionBits, USE_ETH | USE_ENC);
    }

    function isOfficial(uint16 submissionBits) pure internal returns (bool) {
        return (submissionBits & IS_OFFICIAL) == IS_OFFICIAL;
    }

    function isBinding(uint16 submissionBits) pure internal returns (bool) {
        return (submissionBits & IS_BINDING) == IS_BINDING;
    }

    function isTesting(uint16 submissionBits) pure internal returns (bool) {
        return (submissionBits & USE_TESTING) == USE_TESTING;
    }

    function qualifiesAsCommunityBallot(uint16 submissionBits) pure internal returns (bool) {
        // if submissionBits AND any of the bits that make this _not_ a community
        // ballot is equal to zero that means none of those bits were active, so
        // it could be a community ballot
        return (submissionBits & (IS_BINDING | IS_OFFICIAL | USE_ENC)) == 0;
    }

    function checkFlags(uint16 submissionBits, uint16 expected) pure internal returns (bool) {
        // this should ignore ONLY the testing/flag bits - all other bits are significant
        uint16 sBitsNoSettings = submissionBits & SETTINGS_MASK;
        // then we want ONLY expected
        return sBitsNoSettings == expected;
    }
}

library BPackedUtils {

    // the uint16 ending at 128 bits should be 0s
    uint256 constant sbMask        = 0xffffffffffffffffffffffffffff0000ffffffffffffffffffffffffffffffff;
    uint256 constant startTimeMask = 0xffffffffffffffffffffffffffffffff0000000000000000ffffffffffffffff;
    uint256 constant endTimeMask   = 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000;

    function packedToSubmissionBits(uint256 packed) internal pure returns (uint16) {
        return uint16(packed >> 128);
    }

    function packedToStartTime(uint256 packed) internal pure returns (uint64) {
        return uint64(packed >> 64);
    }

    function packedToEndTime(uint256 packed) internal pure returns (uint64) {
        return uint64(packed);
    }

    function unpackAll(uint256 packed) internal pure returns (uint16 submissionBits, uint64 startTime, uint64 endTime) {
        submissionBits = uint16(packed >> 128);
        startTime = uint64(packed >> 64);
        endTime = uint64(packed);
    }

    function pack(uint16 sb, uint64 st, uint64 et) internal pure returns (uint256 packed) {
        return uint256(sb) << 128 | uint256(st) << 64 | uint256(et);
    }

    function setSB(uint256 packed, uint16 newSB) internal pure returns (uint256) {
        return (packed & sbMask) | uint256(newSB) << 128;
    }

    // function setStartTime(uint256 packed, uint64 startTime) internal pure returns (uint256) {
    //     return (packed & startTimeMask) | uint256(startTime) << 64;
    // }

    // function setEndTime(uint256 packed, uint64 endTime) internal pure returns (uint256) {
    //     return (packed & endTimeMask) | uint256(endTime);
    // }
}

interface CommAuctionIface {
    function getNextPrice(bytes32 democHash) external view returns (uint);
    function noteBallotDeployed(bytes32 democHash) external;

    // add more when we need it

    function upgradeMe(address newSC) external;
}

library IxLib {
    /**
     * Usage: `using IxLib for IxIface`
     * The idea is to (instead of adding methods that already use
     * available public info to the index) we can create `internal`
     * methods in the lib to do this instead (which means the code
     * is inserted into other contracts inline, without a `delegatecall`.
     *
     * For this reason it&#39;s crucial to have no methods in IxLib with the
     * same name as methods in IxIface
     */

    /* Global price and payments data */

    function getPayTo(IxIface ix) internal view returns (address) {
        return ix.getPayments().getPayTo();
    }

    /* Global Ix data */

    function getBBFarmFromBallotID(IxIface ix, uint256 ballotId) internal view returns (BBFarmIface) {
        bytes4 bbNamespace = bytes4(ballotId >> 48);
        uint8 bbFarmId = ix.getBBFarmID(bbNamespace);
        return ix.getBBFarm(bbFarmId);
    }

    /* Global backend data */

    function getGDemocsN(IxIface ix) internal view returns (uint256) {
        return ix.getBackend().getGDemocsN();
    }

    function getGDemoc(IxIface ix, uint256 n) internal view returns (bytes32) {
        return ix.getBackend().getGDemoc(n);
    }

    function getGErc20ToDemocs(IxIface ix, address erc20) internal view returns (bytes32[] democHashes) {
        return ix.getBackend().getGErc20ToDemocs(erc20);
    }

    /* Democ specific payment/account data */

    function accountInGoodStanding(IxIface ix, bytes32 democHash) internal view returns (bool) {
        return ix.getPayments().accountInGoodStanding(democHash);
    }

    function accountPremiumAndInGoodStanding(IxIface ix, bytes32 democHash) internal view returns (bool) {
        IxPaymentsIface payments = ix.getPayments();
        return payments.accountInGoodStanding(democHash) && payments.getPremiumStatus(democHash);
    }

    function payForDemocracy(IxIface ix, bytes32 democHash) internal {
        ix.getPayments().payForDemocracy.value(msg.value)(democHash);
    }

    /* Democ getters */

    function getDOwner(IxIface ix, bytes32 democHash) internal view returns (address) {
        return ix.getBackend().getDOwner(democHash);
    }

    function isDEditor(IxIface ix, bytes32 democHash, address editor) internal view returns (bool) {
        return ix.getBackend().isDEditor(democHash, editor);
    }

    function getDBallotsN(IxIface ix, bytes32 democHash) internal view returns (uint256) {
        return ix.getBackend().getDBallotsN(democHash);
    }

    function getDBallotID(IxIface ix, bytes32 democHash, uint256 n) internal view returns (uint256) {
        return ix.getBackend().getDBallotID(democHash, n);
    }

    function getDInfo(IxIface ix, bytes32 democHash) internal view returns (address erc20, address admin, uint256 _nBallots) {
        return ix.getBackend().getDInfo(democHash);
    }

    function getDErc20(IxIface ix, bytes32 democHash) internal view returns (address erc20) {
        return ix.getBackend().getDErc20(democHash);
    }

    function getDHash(IxIface ix, bytes13 prefix) internal view returns (bytes32) {
        return ix.getBackend().getDHash(prefix);
    }

    function getDCategoriesN(IxIface ix, bytes32 democHash) internal view returns (uint) {
        return ix.getBackend().getDCategoriesN(democHash);
    }

    function getDCategory(IxIface ix, bytes32 democHash, uint categoryId) internal view returns (bool, bytes32, bool, uint) {
        return ix.getBackend().getDCategory(democHash, categoryId);
    }

    function getDArbitraryData(IxIface ix, bytes32 democHash, bytes key) external view returns (bytes) {
        return ix.getBackend().getDArbitraryData(democHash, key);
    }
}

contract SVBallotConsts {
    // voting settings
    uint16 constant USE_ETH = 1;          // 2^0
    uint16 constant USE_SIGNED = 2;       // 2^1
    uint16 constant USE_NO_ENC = 4;       // 2^2
    uint16 constant USE_ENC = 8;          // 2^3

    // ballot settings
    uint16 constant IS_BINDING = 8192;    // 2^13
    uint16 constant IS_OFFICIAL = 16384;  // 2^14
    uint16 constant USE_TESTING = 32768;  // 2^15
}

contract safeSend {
    bool private txMutex3847834;

    // we want to be able to call outside contracts (e.g. the admin proxy contract)
    // but reentrency is bad, so here&#39;s a mutex.
    function doSafeSend(address toAddr, uint amount) internal {
        doSafeSendWData(toAddr, "", amount);
    }

    function doSafeSendWData(address toAddr, bytes data, uint amount) internal {
        require(txMutex3847834 == false, "ss-guard");
        txMutex3847834 = true;
        // we need to use address.call.value(v)() because we want
        // to be able to send to other contracts, even with no data,
        // which might use more than 2300 gas in their fallback function.
        require(toAddr.call.value(amount)(data), "ss-failed");
        txMutex3847834 = false;
    }
}

contract payoutAllC is safeSend {
    address private _payTo;

    event PayoutAll(address payTo, uint value);

    constructor(address initPayTo) public {
        // DEV NOTE: you can overwrite _getPayTo if you want to reuse other storage vars
        assert(initPayTo != address(0));
        _payTo = initPayTo;
    }

    function _getPayTo() internal view returns (address) {
        return _payTo;
    }

    function _setPayTo(address newPayTo) internal {
        _payTo = newPayTo;
    }

    function payoutAll() external {
        address a = _getPayTo();
        uint bal = address(this).balance;
        doSafeSend(a, bal);
        emit PayoutAll(a, bal);
    }
}

contract payoutAllCSettable is payoutAllC {
    constructor (address initPayTo) payoutAllC(initPayTo) public {
    }

    function setPayTo(address) external;
    function getPayTo() external view returns (address) {
        return _getPayTo();
    }
}

contract owned {
    address public owner;

    event OwnerChanged(address newOwner);

    modifier only_owner() {
        require(msg.sender == owner, "only_owner: forbidden");
        _;
    }

    modifier owner_or(address addr) {
        require(msg.sender == addr || msg.sender == owner, "!owner-or");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address newOwner) only_owner() external {
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }
}

contract CanReclaimToken is owned {

    /**
    * @dev Reclaim all ERC20Basic compatible tokens
    * @param token ERC20Basic The address of the token contract
    */
    function reclaimToken(ERC20Interface token) external only_owner {
        uint256 balance = token.balanceOf(this);
        require(token.approve(owner, balance));
    }

}

contract CommunityAuctionSimple is owned {
    // about $1USD at $600usd/eth
    uint public commBallotPriceWei = 1666666666000000;

    struct Record {
        bytes32 democHash;
        uint ts;
    }

    mapping (address => Record[]) public ballotLog;
    mapping (address => address) public upgrades;

    function getNextPrice(bytes32) external view returns (uint) {
        return commBallotPriceWei;
    }

    function noteBallotDeployed(bytes32 d) external {
        require(upgrades[msg.sender] == address(0));
        ballotLog[msg.sender].push(Record(d, now));
    }

    function upgradeMe(address newSC) external {
        require(upgrades[msg.sender] == address(0));
        upgrades[msg.sender] = newSC;
    }

    function getBallotLogN(address a) external view returns (uint) {
        return ballotLog[a].length;
    }

    function setPriceWei(uint newPrice) only_owner() external {
        commBallotPriceWei = newPrice;
    }
}

contract controlledIface {
    function controller() external view returns (address);
}

contract hasAdmins is owned {
    mapping (uint => mapping (address => bool)) admins;
    uint public currAdminEpoch = 0;
    bool public adminsDisabledForever = false;
    address[] adminLog;

    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed oldAdmin);
    event AdminEpochInc();
    event AdminDisabledForever();

    modifier only_admin() {
        require(adminsDisabledForever == false, "admins must not be disabled");
        require(isAdmin(msg.sender), "only_admin: forbidden");
        _;
    }

    constructor() public {
        _setAdmin(msg.sender, true);
    }

    function isAdmin(address a) view public returns (bool) {
        return admins[currAdminEpoch][a];
    }

    function getAdminLogN() view external returns (uint) {
        return adminLog.length;
    }

    function getAdminLog(uint n) view external returns (address) {
        return adminLog[n];
    }

    function upgradeMeAdmin(address newAdmin) only_admin() external {
        // note: already checked msg.sender has admin with `only_admin` modifier
        require(msg.sender != owner, "owner cannot upgrade self");
        _setAdmin(msg.sender, false);
        _setAdmin(newAdmin, true);
    }

    function setAdmin(address a, bool _givePerms) only_admin() external {
        require(a != msg.sender && a != owner, "cannot change your own (or owner&#39;s) permissions");
        _setAdmin(a, _givePerms);
    }

    function _setAdmin(address a, bool _givePerms) internal {
        admins[currAdminEpoch][a] = _givePerms;
        if (_givePerms) {
            emit AdminAdded(a);
            adminLog.push(a);
        } else {
            emit AdminRemoved(a);
        }
    }

    // safety feature if admins go bad or something
    function incAdminEpoch() only_owner() external {
        currAdminEpoch++;
        admins[currAdminEpoch][msg.sender] = true;
        emit AdminEpochInc();
    }

    // this is internal so contracts can all it, but not exposed anywhere in this
    // contract.
    function disableAdminForever() internal {
        currAdminEpoch++;
        adminsDisabledForever = true;
        emit AdminDisabledForever();
    }
}

contract EnsOwnerProxy is hasAdmins {
    bytes32 public ensNode;
    ENSIface public ens;
    PublicResolver public resolver;

    /**
     * @param _ensNode The node to administer
     * @param _ens The ENS Registrar
     * @param _resolver The ENS Resolver
     */
    constructor(bytes32 _ensNode, ENSIface _ens, PublicResolver _resolver) public {
        ensNode = _ensNode;
        ens = _ens;
        resolver = _resolver;
    }

    function setAddr(address addr) only_admin() external {
        _setAddr(addr);
    }

    function _setAddr(address addr) internal {
        resolver.setAddr(ensNode, addr);
    }

    function returnToOwner() only_owner() external {
        ens.setOwner(ensNode, owner);
    }

    function fwdToENS(bytes data) only_owner() external {
        require(address(ens).call(data), "fwding to ens failed");
    }

    function fwdToResolver(bytes data) only_owner() external {
        require(address(resolver).call(data), "fwding to resolver failed");
    }
}

contract permissioned is owned, hasAdmins {
    mapping (address => bool) editAllowed;
    bool public adminLockdown = false;

    event PermissionError(address editAddr);
    event PermissionGranted(address editAddr);
    event PermissionRevoked(address editAddr);
    event PermissionsUpgraded(address oldSC, address newSC);
    event SelfUpgrade(address oldSC, address newSC);
    event AdminLockdown();

    modifier only_editors() {
        require(editAllowed[msg.sender], "only_editors: forbidden");
        _;
    }

    modifier no_lockdown() {
        require(adminLockdown == false, "no_lockdown: check failed");
        _;
    }


    constructor() owned() hasAdmins() public {
    }


    function setPermissions(address e, bool _editPerms) no_lockdown() only_admin() external {
        editAllowed[e] = _editPerms;
        if (_editPerms)
            emit PermissionGranted(e);
        else
            emit PermissionRevoked(e);
    }

    function upgradePermissionedSC(address oldSC, address newSC) no_lockdown() only_admin() external {
        editAllowed[oldSC] = false;
        editAllowed[newSC] = true;
        emit PermissionsUpgraded(oldSC, newSC);
    }

    // always allow SCs to upgrade themselves, even after lockdown
    function upgradeMe(address newSC) only_editors() external {
        editAllowed[msg.sender] = false;
        editAllowed[newSC] = true;
        emit SelfUpgrade(msg.sender, newSC);
    }

    function hasPermissions(address a) public view returns (bool) {
        return editAllowed[a];
    }

    function doLockdown() external only_owner() no_lockdown() {
        disableAdminForever();
        adminLockdown = true;
        emit AdminLockdown();
    }
}

contract upgradePtr {
    address ptr = address(0);

    modifier not_upgraded() {
        require(ptr == address(0), "upgrade pointer is non-zero");
        _;
    }

    function getUpgradePointer() view external returns (address) {
        return ptr;
    }

    function doUpgradeInternal(address nextSC) internal {
        ptr = nextSC;
    }
}

interface ERC20Interface {
    // Get the total token supply
    function totalSupply() constant external returns (uint256 _totalSupply);

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant external returns (uint256 balance);

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) external returns (bool success);

    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) external returns (bool success);

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant external returns (uint256 remaining);

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ixEvents {
    event PaymentMade(uint[2] valAndRemainder);
    event AddedBBFarm(uint8 bbFarmId);
    event SetBackend(bytes32 setWhat, address newSC);
    event DeprecatedBBFarm(uint8 bbFarmId);
    event CommunityBallot(bytes32 democHash, uint256 ballotId);
    event ManuallyAddedBallot(bytes32 democHash, uint256 ballotId, uint256 packed);
    // copied from BBFarm - unable to inherit from BBFarmEvents...
    event BallotCreatedWithID(uint ballotId);
    event BBFarmInit(bytes4 namespace);
}

contract ixBackendEvents {
    event NewDemoc(bytes32 democHash);
    event ManuallyAddedDemoc(bytes32 democHash, address erc20);
    event NewBallot(bytes32 indexed democHash, uint ballotN);
    event DemocOwnerSet(bytes32 indexed democHash, address owner);
    event DemocEditorSet(bytes32 indexed democHash, address editor, bool canEdit);
    event DemocEditorsWiped(bytes32 indexed democHash);
    event DemocErc20Set(bytes32 indexed democHash, address erc20);
    event DemocDataSet(bytes32 indexed democHash, bytes32 keyHash);
    event DemocCatAdded(bytes32 indexed democHash, uint catId);
    event DemocCatDeprecated(bytes32 indexed democHash, uint catId);
    event DemocCommunityBallotsEnabled(bytes32 indexed democHash, bool enabled);
    event DemocErc20OwnerClaimDisabled(bytes32 indexed democHash);
    event DemocClaimed(bytes32 indexed democHash);
    event EmergencyDemocOwner(bytes32 indexed democHash, address newOwner);
}

library SafeMath {
    function subToZero(uint a, uint b) internal pure returns (uint) {
        if (a < b) {  // then (a - b) would overflow
            return 0;
        }
        return a - b;
    }
}

contract ixPaymentEvents {
    event UpgradedToPremium(bytes32 indexed democHash);
    event GrantedAccountTime(bytes32 indexed democHash, uint additionalSeconds, bytes32 ref);
    event AccountPayment(bytes32 indexed democHash, uint additionalSeconds);
    event SetCommunityBallotFee(uint amount);
    event SetBasicCentsPricePer30Days(uint amount);
    event SetPremiumMultiplier(uint8 multiplier);
    event DowngradeToBasic(bytes32 indexed democHash);
    event UpgradeToPremium(bytes32 indexed democHash);
    event SetExchangeRate(uint weiPerCent);
    event FreeExtension(bytes32 democHash);
    event SetBallotsPer30Days(uint amount);
    event SetFreeExtension(bytes32 democHash, bool hasFreeExt);
    event SetDenyPremium(bytes32 democHash, bool isPremiumDenied);
    event SetPayTo(address payTo);
    event SetMinorEditsAddr(address minorEditsAddr);
    event SetMinWeiForDInit(uint amount);
}

interface hasVersion {
    function getVersion() external pure returns (uint);
}

contract BBFarmIface is BBFarmEvents, permissioned, hasVersion, payoutAllC {
    /* global bbfarm getters */

    function getNamespace() external view returns (bytes4);
    function getBBLibVersion() external view returns (uint256);
    function getNBallots() external view returns (uint256);

    /* init a ballot */

    // note that the ballotId returned INCLUDES the namespace.
    function initBallot( bytes32 specHash
                       , uint256 packed
                       , IxIface ix
                       , address bbAdmin
                       , bytes24 extraData
                       ) external returns (uint ballotId);

    /* Sponsorship of ballots */

    function sponsor(uint ballotId) external payable;

    /* Voting functions */

    function submitVote(uint ballotId, bytes32 vote, bytes extra) external;
    function submitProxyVote(bytes32[5] proxyReq, bytes extra) external;

    /* Ballot Getters */

    function getDetails(uint ballotId, address voter) external view returns
            ( bool hasVoted
            , uint nVotesCast
            , bytes32 secKey
            , uint16 submissionBits
            , uint64 startTime
            , uint64 endTime
            , bytes32 specHash
            , bool deprecated
            , address ballotOwner
            , bytes16 extraData);

    function getVote(uint ballotId, uint voteId) external view returns (bytes32 voteData, address sender, bytes extra);
    function getTotalSponsorship(uint ballotId) external view returns (uint);
    function getSponsorsN(uint ballotId) external view returns (uint);
    function getSponsor(uint ballotId, uint sponsorN) external view returns (address sender, uint amount);
    function getCreationTs(uint ballotId) external view returns (uint);

    /* Admin on ballots */
    function revealSeckey(uint ballotId, bytes32 sk) external;
    function setEndTime(uint ballotId, uint64 newEndTime) external;  // note: testing only
    function setDeprecated(uint ballotId) external;
    function setBallotOwner(uint ballotId, address newOwner) external;
}

contract BBFarm is BBFarmIface {
    using BBLib for BBLib.DB;
    using IxLib for IxIface;

    // namespaces should be unique for each bbFarm
    bytes4 constant NAMESPACE = 0x00000001;
    // last 48 bits
    uint256 constant BALLOT_ID_MASK = 0x00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    uint constant VERSION = 2;

    mapping (uint224 => BBLib.DB) dbs;
    // note - start at 100 to avoid any test for if 0 is a valid ballotId
    // also gives us some space to play with low numbers if we want.
    uint nBallots = 0;

    /* modifiers */

    modifier req_namespace(uint ballotId) {
        // bytes4() will take the _first_ 4 bytes
        require(bytes4(ballotId >> 224) == NAMESPACE, "bad-namespace");
        _;
    }

    /* Constructor */

    constructor() payoutAllC(msg.sender) public {
        // this bbFarm requires v5 of BBLib (note: v4 deprecated immediately due to insecure submitProxyVote)
        // note: even though we can&#39;t test for this in coverage, this has stopped me deploying to kovan with the wrong version tho, so I consider it tested :)
        assert(BBLib.getVersion() == 6);
        emit BBFarmInit(NAMESPACE);
    }

    /* base SCs */

    function _getPayTo() internal view returns (address) {
        return owner;
    }

    function getVersion() external pure returns (uint) {
        return VERSION;
    }

    /* global funcs */

    function getNamespace() external view returns (bytes4) {
        return NAMESPACE;
    }

    function getBBLibVersion() external view returns (uint256) {
        return BBLib.getVersion();
    }

    function getNBallots() external view returns (uint256) {
        return nBallots;
    }

    /* db lookup helper */

    function getDb(uint ballotId) internal view returns (BBLib.DB storage) {
        // cut off anything above 224 bits (where the namespace goes)
        return dbs[uint224(ballotId)];
    }

    /* Init ballot */

    function initBallot( bytes32 specHash
                       , uint256 packed
                       , IxIface ix
                       , address bbAdmin
                       , bytes24 extraData
                ) only_editors() external returns (uint ballotId) {
        // calculate the ballotId based on the last 224 bits of the specHash.
        ballotId = uint224(specHash) ^ (uint256(NAMESPACE) << 224);
        // we need to call the init functions on our libraries
        getDb(ballotId).init(specHash, packed, ix, bbAdmin, bytes16(uint128(extraData)));
        nBallots += 1;

        emit BallotCreatedWithID(ballotId);
    }

    /* Sponsorship */

    function sponsor(uint ballotId) external payable {
        BBLib.DB storage db = getDb(ballotId);
        db.logSponsorship(msg.value);
        doSafeSend(db.index.getPayTo(), msg.value);
        emit Sponsorship(ballotId, msg.value);
    }

    /* Voting */

    function submitVote(uint ballotId, bytes32 vote, bytes extra) req_namespace(ballotId) external {
        getDb(ballotId).submitVote(vote, extra);
        emit Vote(ballotId, vote, msg.sender, extra);
    }

    function submitProxyVote(bytes32[5] proxyReq, bytes extra) req_namespace(uint256(proxyReq[3])) external {
        // see https://github.com/secure-vote/tokenvote/blob/master/Docs/DataStructs.md for breakdown of params
        // pr[3] is the ballotId, and pr[4] is the vote
        uint ballotId = uint256(proxyReq[3]);
        address voter = getDb(ballotId).submitProxyVote(proxyReq, extra);
        bytes32 vote = proxyReq[4];
        emit Vote(ballotId, vote, voter, extra);
    }

    /* Getters */

    // note - this is the maxmimum number of vars we can return with one
    // function call (taking 2 args)
    function getDetails(uint ballotId, address voter) external view returns
            ( bool hasVoted
            , uint nVotesCast
            , bytes32 secKey
            , uint16 submissionBits
            , uint64 startTime
            , uint64 endTime
            , bytes32 specHash
            , bool deprecated
            , address ballotOwner
            , bytes16 extraData) {
        BBLib.DB storage db = getDb(ballotId);
        uint packed = db.packed;
        return (
            db.getSequenceNumber(voter) > 0,
            db.nVotesCast,
            db.ballotEncryptionSeckey,
            BPackedUtils.packedToSubmissionBits(packed),
            BPackedUtils.packedToStartTime(packed),
            BPackedUtils.packedToEndTime(packed),
            db.specHash,
            db.deprecated,
            db.ballotOwner,
            db.extraData
        );
    }

    function getVote(uint ballotId, uint voteId) external view returns (bytes32 voteData, address sender, bytes extra) {
        (voteData, sender, extra, ) = getDb(ballotId).getVote(voteId);
    }

    function getSequenceNumber(uint ballotId, address voter) external view returns (uint32 sequence) {
        return getDb(ballotId).getSequenceNumber(voter);
    }

    function getTotalSponsorship(uint ballotId) external view returns (uint) {
        return getDb(ballotId).getTotalSponsorship();
    }

    function getSponsorsN(uint ballotId) external view returns (uint) {
        return getDb(ballotId).sponsors.length;
    }

    function getSponsor(uint ballotId, uint sponsorN) external view returns (address sender, uint amount) {
        return getDb(ballotId).getSponsor(sponsorN);
    }

    function getCreationTs(uint ballotId) external view returns (uint) {
        return getDb(ballotId).creationTs;
    }

    /* ADMIN */

    // Allow the owner to reveal the secret key after ballot conclusion
    function revealSeckey(uint ballotId, bytes32 sk) external {
        BBLib.DB storage db = getDb(ballotId);
        db.requireBallotOwner();
        db.requireBallotClosed();
        db.revealSeckey(sk);
    }

    // note: testing only.
    function setEndTime(uint ballotId, uint64 newEndTime) external {
        BBLib.DB storage db = getDb(ballotId);
        db.requireBallotOwner();
        db.requireTesting();
        db.setEndTime(newEndTime);
    }

    function setDeprecated(uint ballotId) external {
        BBLib.DB storage db = getDb(ballotId);
        db.requireBallotOwner();
        db.deprecated = true;
    }

    function setBallotOwner(uint ballotId, address newOwner) external {
        BBLib.DB storage db = getDb(ballotId);
        db.requireBallotOwner();
        db.ballotOwner = newOwner;
    }
}

contract IxIface is hasVersion,
                    ixPaymentEvents,
                    ixBackendEvents,
                    ixEvents,
                    SVBallotConsts,
                    owned,
                    CanReclaimToken,
                    upgradePtr,
                    payoutAllC {

    /* owner functions */
    function addBBFarm(BBFarmIface bbFarm) external returns (uint8 bbFarmId);
    function setABackend(bytes32 toSet, address newSC) external;
    function deprecateBBFarm(uint8 bbFarmId, BBFarmIface _bbFarm) external;

    /* global getters */
    function getPayments() external view returns (IxPaymentsIface);
    function getBackend() external view returns (IxBackendIface);
    function getBBFarm(uint8 bbFarmId) external view returns (BBFarmIface);
    function getBBFarmID(bytes4 bbNamespace) external view returns (uint8 bbFarmId);
    function getCommAuction() external view returns (CommAuctionIface);

    /* init a democ */
    function dInit(address defualtErc20, bool disableErc20OwnerClaim) external payable returns (bytes32);

    /* democ owner / editor functions */
    function setDEditor(bytes32 democHash, address editor, bool canEdit) external;
    function setDNoEditors(bytes32 democHash) external;
    function setDOwner(bytes32 democHash, address newOwner) external;
    function dOwnerErc20Claim(bytes32 democHash) external;
    function setDErc20(bytes32 democHash, address newErc20) external;
    function dAddCategory(bytes32 democHash, bytes32 categoryName, bool hasParent, uint parent) external;
    function dDeprecateCategory(bytes32 democHash, uint categoryId) external;
    function dUpgradeToPremium(bytes32 democHash) external;
    function dDowngradeToBasic(bytes32 democHash) external;
    function dSetArbitraryData(bytes32 democHash, bytes key, bytes value) external;
    function dSetCommunityBallotsEnabled(bytes32 democHash, bool enabled) external;
    function dDisableErc20OwnerClaim(bytes32 democHash) external;

    /* democ getters (that used to be here) should be called on either backend or payments directly */
    /* use IxLib for convenience functions from other SCs */

    /* ballot deployment */
    // only ix owner - used for adding past or special ballots
    function dAddBallot(bytes32 democHash, uint ballotId, uint256 packed) external;
    function dDeployCommunityBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, uint128 packedTimes) external payable;
    function dDeployBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, uint256 packed) external payable;
}

contract SVIndex is IxIface {
    uint256 constant VERSION = 2;

    // generated from: `address public owner;`
    bytes4 constant OWNER_SIG = 0x8da5cb5b;
    // generated from: `address public controller;`
    bytes4 constant CONTROLLER_SIG = 0xf77c4791;

    /* backend & other SC storage */

    IxBackendIface backend;
    IxPaymentsIface payments;
    EnsOwnerProxy public ensOwnerPx;
    BBFarmIface[] bbFarms;
    CommAuctionIface commAuction;
    // mapping from bbFarm namespace to bbFarmId
    mapping (bytes4 => uint8) bbFarmIdLookup;
    mapping (uint8 => bool) deprecatedBBFarms;

    //* MODIFIERS /

    modifier onlyDemocOwner(bytes32 democHash) {
        require(msg.sender == backend.getDOwner(democHash), "!d-owner");
        _;
    }

    modifier onlyDemocEditor(bytes32 democHash) {
        require(backend.isDEditor(democHash, msg.sender), "!d-editor");
        _;
    }

    /* FUNCTIONS */

    // constructor
    constructor( IxBackendIface _b
               , IxPaymentsIface _pay
               , EnsOwnerProxy _ensOwnerPx
               , BBFarmIface _bbFarm0
               , CommAuctionIface _commAuction
               ) payoutAllC(msg.sender) public {
        backend = _b;
        payments = _pay;
        ensOwnerPx = _ensOwnerPx;
        _addBBFarm(0x0, _bbFarm0);
        commAuction = _commAuction;
    }

    /* payoutAllC */

    function _getPayTo() internal view returns (address) {
        return payments.getPayTo();
    }

    /* UPGRADE STUFF */

    function doUpgrade(address nextSC) only_owner() not_upgraded() external {
        doUpgradeInternal(nextSC);
        backend.upgradeMe(nextSC);
        payments.upgradeMe(nextSC);
        ensOwnerPx.setAddr(nextSC);
        ensOwnerPx.upgradeMeAdmin(nextSC);
        commAuction.upgradeMe(nextSC);

        for (uint i = 0; i < bbFarms.length; i++) {
            bbFarms[i].upgradeMe(nextSC);
        }
    }

    function _addBBFarm(bytes4 bbNamespace, BBFarmIface _bbFarm) internal returns (uint8 bbFarmId) {
        uint256 bbFarmIdLong = bbFarms.length;
        require(bbFarmIdLong < 2**8, "too-many-farms");
        bbFarmId = uint8(bbFarmIdLong);

        bbFarms.push(_bbFarm);
        bbFarmIdLookup[bbNamespace] = bbFarmId;
        emit AddedBBFarm(bbFarmId);
    }

    // adding a new BBFarm
    function addBBFarm(BBFarmIface bbFarm) only_owner() external returns (uint8 bbFarmId) {
        bytes4 bbNamespace = bbFarm.getNamespace();

        require(bbNamespace != bytes4(0), "bb-farm-namespace");
        require(bbFarmIdLookup[bbNamespace] == 0 && bbNamespace != bbFarms[0].getNamespace(), "bb-namespace-used");

        bbFarmId = _addBBFarm(bbNamespace, bbFarm);
    }

    function setABackend(bytes32 toSet, address newSC) only_owner() external {
        emit SetBackend(toSet, newSC);
        if (toSet == bytes32("payments")) {
            payments = IxPaymentsIface(newSC);
        } else if (toSet == bytes32("backend")) {
            backend = IxBackendIface(newSC);
        } else if (toSet == bytes32("commAuction")) {
            commAuction = CommAuctionIface(newSC);
        } else {
            revert("404");
        }
    }

    function deprecateBBFarm(uint8 bbFarmId, BBFarmIface _bbFarm) only_owner() external {
        require(address(_bbFarm) != address(0));
        require(bbFarms[bbFarmId] == _bbFarm);
        deprecatedBBFarms[bbFarmId] = true;
        emit DeprecatedBBFarm(bbFarmId);
    }

    /* Getters for backends */

    function getPayments() external view returns (IxPaymentsIface) {
        return payments;
    }

    function getBackend() external view returns (IxBackendIface) {
        return backend;
    }

    function getBBFarm(uint8 bbFarmId) external view returns (BBFarmIface) {
        return bbFarms[bbFarmId];
    }

    function getBBFarmID(bytes4 bbNamespace) external view returns (uint8 bbFarmId) {
        return bbFarmIdLookup[bbNamespace];
    }

    function getCommAuction() external view returns (CommAuctionIface) {
        return commAuction;
    }

    //* GLOBAL INFO */

    function getVersion() external pure returns (uint256) {
        return VERSION;
    }

    //* DEMOCRACY FUNCTIONS - INDIVIDUAL */

    function dInit(address defaultErc20, bool disableErc20OwnerClaim) not_upgraded() external payable returns (bytes32) {
        require(msg.value >= payments.getMinWeiForDInit());
        bytes32 democHash = backend.dInit(defaultErc20, msg.sender, disableErc20OwnerClaim);
        payments.payForDemocracy.value(msg.value)(democHash);
        return democHash;
    }

    // admin methods

    function setDEditor(bytes32 democHash, address editor, bool canEdit) onlyDemocOwner(democHash) external {
        backend.setDEditor(democHash, editor, canEdit);
    }

    function setDNoEditors(bytes32 democHash) onlyDemocOwner(democHash) external {
        backend.setDNoEditors(democHash);
    }

    function setDOwner(bytes32 democHash, address newOwner) onlyDemocOwner(democHash) external {
        backend.setDOwner(democHash, newOwner);
    }

    function dOwnerErc20Claim(bytes32 democHash) external {
        address erc20 = backend.getDErc20(democHash);
        // test if we can call the erc20.owner() method, etc
        // also limit gas use to 3000 because we don&#39;t know what they&#39;ll do with it
        // during testing both owned and controlled could be called from other contracts for 2525 gas.
        if (erc20.call.gas(3000)(OWNER_SIG)) {
            require(msg.sender == owned(erc20).owner.gas(3000)(), "!erc20-owner");
        } else if (erc20.call.gas(3000)(CONTROLLER_SIG)) {
            require(msg.sender == controlledIface(erc20).controller.gas(3000)(), "!erc20-controller");
        } else {
            revert();
        }
        // now we are certain the sender deployed or controls the erc20
        backend.setDOwnerFromClaim(democHash, msg.sender);
    }

    function setDErc20(bytes32 democHash, address newErc20) onlyDemocOwner(democHash) external {
        backend.setDErc20(democHash, newErc20);
    }

    function dAddCategory(bytes32 democHash, bytes32 catName, bool hasParent, uint parent) onlyDemocEditor(democHash) external {
        backend.dAddCategory(democHash, catName, hasParent, parent);
    }

    function dDeprecateCategory(bytes32 democHash, uint catId) onlyDemocEditor(democHash) external {
        backend.dDeprecateCategory(democHash, catId);
    }

    function dUpgradeToPremium(bytes32 democHash) onlyDemocOwner(democHash) external {
        payments.upgradeToPremium(democHash);
    }

    function dDowngradeToBasic(bytes32 democHash) onlyDemocOwner(democHash) external {
        payments.downgradeToBasic(democHash);
    }

    function dSetArbitraryData(bytes32 democHash, bytes key, bytes value) external {
        if (msg.sender == backend.getDOwner(democHash)) {
            backend.dSetArbitraryData(democHash, key, value);
        } else if (backend.isDEditor(democHash, msg.sender)) {
            backend.dSetEditorArbitraryData(democHash, key, value);
        } else {
            revert();
        }
    }

    function dSetCommunityBallotsEnabled(bytes32 democHash, bool enabled) onlyDemocOwner(democHash) external {
        backend.dSetCommunityBallotsEnabled(democHash, enabled);
    }

    // this is one way only!
    function dDisableErc20OwnerClaim(bytes32 democHash) onlyDemocOwner(democHash) external {
        backend.dDisableErc20OwnerClaim(democHash);
    }

    /* Democ Getters - deprecated */
    // NOTE: the getters that used to live here just proxied to the backend.
    // this has been removed to reduce gas costs + size of Ix contract
    // For SCs you should use IxLib for convenience.
    // For Offchain use you should query the backend directly (via ix.getBackend())

    /* Add and Deploy Ballots */

    // manually add a ballot - only the owner can call this
    // WARNING - it&#39;s required that we make ABSOLUTELY SURE that
    // ballotId is valid and can resolve via the appropriate BBFarm.
    // this function _DOES NOT_ validate that everything else is done.
    function dAddBallot(bytes32 democHash, uint ballotId, uint256 packed)
                      only_owner()
                      external {

        _addBallot(democHash, ballotId, packed, false);
        emit ManuallyAddedBallot(democHash, ballotId, packed);
    }


    function _deployBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, uint packed, bool checkLimit, bool alreadySentTx) internal returns (uint ballotId) {
        require(BBLib.isTesting(BPackedUtils.packedToSubmissionBits(packed)) == false, "b-testing");

        // the most significant byte of extraData signals the bbFarm to use.
        uint8 bbFarmId = uint8(extraData[0]);
        require(deprecatedBBFarms[bbFarmId] == false, "bb-dep");
        BBFarmIface _bbFarm = bbFarms[bbFarmId];

        // anything that isn&#39;t a community ballot counts towards the basic limit.
        // we want to check in cases where
        // the ballot doesn&#39;t qualify as a community ballot
        // OR (the ballot qualifies as a community ballot
        //     AND the admins have _disabled_ community ballots).
        bool countTowardsLimit = checkLimit;
        bool performedSend;
        if (checkLimit) {
            uint64 endTime = BPackedUtils.packedToEndTime(packed);
            (countTowardsLimit, performedSend) = _basicBallotLimitOperations(democHash, _bbFarm);
            _accountOkayChecks(democHash, endTime);
        }

        if (!performedSend && msg.value > 0 && alreadySentTx == false) {
            // refund if we haven&#39;t send value anywhere (which might happen if someone accidentally pays us)
            doSafeSend(msg.sender, msg.value);
        }

        ballotId = _bbFarm.initBallot(
            specHash,
            packed,
            this,
            msg.sender,
            // we are certain that the first 8 bytes are for index use only.
            // truncating extraData like this means we can occasionally
            // save on gas. we need to use uint192 first because that will take
            // the _last_ 24 bytes of extraData.
            bytes24(uint192(extraData)));

        _addBallot(democHash, ballotId, packed, countTowardsLimit);
    }

    function dDeployCommunityBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, uint128 packedTimes) external payable {
        uint price = commAuction.getNextPrice(democHash);
        require(msg.value >= price, "!cb-fee");

        doSafeSend(payments.getPayTo(), price);
        doSafeSend(msg.sender, msg.value - price);

        bool canProceed = backend.getDCommBallotsEnabled(democHash) || !payments.accountInGoodStanding(democHash);
        require(canProceed, "!cb-enabled");

        uint256 packed = BPackedUtils.setSB(uint256(packedTimes), (USE_ETH | USE_NO_ENC));

        uint ballotId = _deployBallot(democHash, specHash, extraData, packed, false, true);
        commAuction.noteBallotDeployed(democHash);

        emit CommunityBallot(democHash, ballotId);
    }

    // only way a democ admin can deploy a ballot
    function dDeployBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, uint256 packed)
                          onlyDemocEditor(democHash)
                          external payable {

        _deployBallot(democHash, specHash, extraData, packed, true, false);
    }

    // internal logic around adding a ballot
    function _addBallot(bytes32 democHash, uint256 ballotId, uint256 packed, bool countTowardsLimit) internal {
        // backend handles events
        backend.dAddBallot(democHash, ballotId, packed, countTowardsLimit);
    }

    // check an account has paid up enough for this ballot
    function _accountOkayChecks(bytes32 democHash, uint64 endTime) internal view {
        // if the ballot is marked as official require the democracy is paid up to
        // some relative amount - exclude NFP accounts from this check
        uint secsLeft = payments.getSecondsRemaining(democHash);
        // must be positive due to ending in future check
        uint256 secsToEndTime = endTime - now;
        // require ballots end no more than twice the time left on the democracy
        require(secsLeft * 2 > secsToEndTime, "unpaid");
    }

    function _basicBallotLimitOperations(bytes32 democHash, BBFarmIface _bbFarm) internal returns (bool shouldCount, bool performedSend) {
        // if we&#39;re an official ballot and the democ is basic, ensure the democ
        // isn&#39;t over the ballots/mo limit
        if (payments.getPremiumStatus(democHash) == false) {
            uint nBallotsAllowed = payments.getBasicBallotsPer30Days();
            uint nBallotsBasicCounted = backend.getDCountedBasicBallotsN(democHash);

            // if the democ has less than nBallotsAllowed then it&#39;s guarenteed to be okay
            if (nBallotsAllowed > nBallotsBasicCounted) {
                // and we should count this ballot
                return (true, false);
            }

            // we want to check the creation timestamp of the nth most recent ballot
            // where n is the # of ballots allowed per month. Note: there isn&#39;t an off
            // by 1 error here because if 1 ballots were allowed per month then we&#39;d want
            // to look at the most recent ballot, so nBallotsBasicCounted-1 in this case.
            // similarly, if X ballots were allowed per month we want to look at
            // nBallotsBasicCounted-X. There would thus be (X-1) ballots that are _more_
            // recent than the one we&#39;re looking for.
            uint earlyBallotId = backend.getDCountedBasicBallotID(democHash, nBallotsBasicCounted - nBallotsAllowed);
            uint earlyBallotTs = _bbFarm.getCreationTs(earlyBallotId);

            // if the earlyBallot was created more than 30 days in the past we should
            // count the new ballot
            if (earlyBallotTs < now - 30 days) {
                return (true, false);
            }

            // at this point it may be the case that we shouldn&#39;t allow the ballot
            // to be created. (It&#39;s an official ballot for a basic tier democracy
            // where the Nth most recent ballot was created within the last 30 days.)
            // We should now check for payment
            uint extraBallotFee = payments.getBasicExtraBallotFeeWei();
            require(msg.value >= extraBallotFee, "!extra-b-fee");

            // now that we know they&#39;ve paid the fee, we should send Eth to `payTo`
            // and return the remainder.
            uint remainder = msg.value - extraBallotFee;
            doSafeSend(address(payments), extraBallotFee);
            doSafeSend(msg.sender, remainder);
            emit PaymentMade([extraBallotFee, remainder]);
            // only in this case (for basic) do we want to return false - don&#39;t count towards the
            // limit because it&#39;s been paid for here.
            return (false, true);

        } else {  // if we&#39;re premium we don&#39;t count ballots
            return (false, false);
        }
    }
}

contract IxBackendIface is hasVersion, ixBackendEvents, permissioned, payoutAllC {
    /* global getters */
    function getGDemocsN() external view returns (uint);
    function getGDemoc(uint id) external view returns (bytes32);
    function getGErc20ToDemocs(address erc20) external view returns (bytes32[] democHashes);

    /* owner functions */
    function dAdd(bytes32 democHash, address erc20, bool disableErc20OwnerClaim) external;
    function emergencySetDOwner(bytes32 democHash, address newOwner) external;

    /* democ admin */
    function dInit(address defaultErc20, address initOwner, bool disableErc20OwnerClaim) external returns (bytes32 democHash);
    function setDOwner(bytes32 democHash, address newOwner) external;
    function setDOwnerFromClaim(bytes32 democHash, address newOwner) external;
    function setDEditor(bytes32 democHash, address editor, bool canEdit) external;
    function setDNoEditors(bytes32 democHash) external;
    function setDErc20(bytes32 democHash, address newErc20) external;
    function dSetArbitraryData(bytes32 democHash, bytes key, bytes value) external;
    function dSetEditorArbitraryData(bytes32 democHash, bytes key, bytes value) external;
    function dAddCategory(bytes32 democHash, bytes32 categoryName, bool hasParent, uint parent) external;
    function dDeprecateCategory(bytes32 democHash, uint catId) external;
    function dSetCommunityBallotsEnabled(bytes32 democHash, bool enabled) external;
    function dDisableErc20OwnerClaim(bytes32 democHash) external;

    /* actually add a ballot */
    function dAddBallot(bytes32 democHash, uint ballotId, uint256 packed, bool countTowardsLimit) external;

    /* global democ getters */
    function getDOwner(bytes32 democHash) external view returns (address);
    function isDEditor(bytes32 democHash, address editor) external view returns (bool);
    function getDHash(bytes13 prefix) external view returns (bytes32);
    function getDInfo(bytes32 democHash) external view returns (address erc20, address owner, uint256 nBallots);
    function getDErc20(bytes32 democHash) external view returns (address);
    function getDArbitraryData(bytes32 democHash, bytes key) external view returns (bytes value);
    function getDEditorArbitraryData(bytes32 democHash, bytes key) external view returns (bytes value);
    function getDBallotsN(bytes32 democHash) external view returns (uint256);
    function getDBallotID(bytes32 democHash, uint n) external view returns (uint ballotId);
    function getDCountedBasicBallotsN(bytes32 democHash) external view returns (uint256);
    function getDCountedBasicBallotID(bytes32 democHash, uint256 n) external view returns (uint256);
    function getDCategoriesN(bytes32 democHash) external view returns (uint);
    function getDCategory(bytes32 democHash, uint catId) external view returns (bool deprecated, bytes32 name, bool hasParent, uint parent);
    function getDCommBallotsEnabled(bytes32 democHash) external view returns (bool);
    function getDErc20OwnerClaimEnabled(bytes32 democHash) external view returns (bool);
}

contract SVIndexBackend is IxBackendIface {
    uint constant VERSION = 2;

    struct Democ {
        address erc20;
        address owner;
        bool communityBallotsDisabled;
        bool erc20OwnerClaimDisabled;
        uint editorEpoch;
        mapping (uint => mapping (address => bool)) editors;
        uint256[] allBallots;
        uint256[] includedBasicBallots;  // the IDs of official ballots

    }

    struct BallotRef {
        bytes32 democHash;
        uint ballotId;
    }

    struct Category {
        bool deprecated;
        bytes32 name;
        bool hasParent;
        uint parent;
    }

    struct CategoriesIx {
        uint nCategories;
        mapping(uint => Category) categories;
    }

    mapping (bytes32 => Democ) democs;
    mapping (bytes32 => CategoriesIx) democCategories;
    mapping (bytes13 => bytes32) democPrefixToHash;
    mapping (address => bytes32[]) erc20ToDemocs;
    bytes32[] democList;

    // allows democ admins to store arbitrary data
    // this lets us (for example) set particular keys to signal cerain
    // things to client apps s.t. the admin can turn them on and off.
    // arbitraryData[democHash][key]
    mapping (bytes32 => mapping (bytes32 => bytes)) arbitraryData;

    /* constructor */

    constructor() payoutAllC(msg.sender) public {
        // do nothing
    }

    /* base contract overloads */

    function _getPayTo() internal view returns (address) {
        return owner;
    }

    function getVersion() external pure returns (uint) {
        return VERSION;
    }

    /* GLOBAL INFO */

    function getGDemocsN() external view returns (uint) {
        return democList.length;
    }

    function getGDemoc(uint id) external view returns (bytes32) {
        return democList[id];
    }

    function getGErc20ToDemocs(address erc20) external view returns (bytes32[] democHashes) {
        return erc20ToDemocs[erc20];
    }

    /* DEMOCRACY ADMIN FUNCTIONS */

    function _addDemoc(bytes32 democHash, address erc20, address initOwner, bool disableErc20OwnerClaim) internal {
        democList.push(democHash);
        Democ storage d = democs[democHash];
        d.erc20 = erc20;
        if (disableErc20OwnerClaim) {
            d.erc20OwnerClaimDisabled = true;
        }
        // this should never trigger if we have a good security model - entropy for 13 bytes ~ 2^(8*13) ~ 10^31
        assert(democPrefixToHash[bytes13(democHash)] == bytes32(0));
        democPrefixToHash[bytes13(democHash)] = democHash;
        erc20ToDemocs[erc20].push(democHash);
        _setDOwner(democHash, initOwner);
        emit NewDemoc(democHash);
    }

    /* owner democ admin functions */

    function dAdd(bytes32 democHash, address erc20, bool disableErc20OwnerClaim) only_owner() external {
        _addDemoc(democHash, erc20, msg.sender, disableErc20OwnerClaim);
        emit ManuallyAddedDemoc(democHash, erc20);
    }

    /* Preferably for emergencies only */

    function emergencySetDOwner(bytes32 democHash, address newOwner) only_owner() external {
        _setDOwner(democHash, newOwner);
        emit EmergencyDemocOwner(democHash, newOwner);
    }

    /* user democ admin functions */

    function dInit(address defaultErc20, address initOwner, bool disableErc20OwnerClaim) only_editors() external returns (bytes32 democHash) {
        // generating the democHash in this way guarentees it&#39;ll be unique/hard-to-brute-force
        // (particularly because prevBlockHash and now are part of the hash)
        democHash = keccak256(abi.encodePacked(democList.length, blockhash(block.number-1), defaultErc20, now));
        _addDemoc(democHash, defaultErc20, initOwner, disableErc20OwnerClaim);
    }

    function _setDOwner(bytes32 democHash, address newOwner) internal {
        Democ storage d = democs[democHash];
        uint epoch = d.editorEpoch;
        d.owner = newOwner;
        // unset prev owner as editor - does little if one was not set
        d.editors[epoch][d.owner] = false;
        // make new owner an editor too
        d.editors[epoch][newOwner] = true;
        emit DemocOwnerSet(democHash, newOwner);
    }

    function setDOwner(bytes32 democHash, address newOwner) only_editors() external {
        _setDOwner(democHash, newOwner);
    }

    function setDOwnerFromClaim(bytes32 democHash, address newOwner) only_editors() external {
        Democ storage d = democs[democHash];
        // make sure that the owner claim is enabled (i.e. the disabled flag is false)
        require(d.erc20OwnerClaimDisabled == false, "!erc20-claim");
        // set owner and editor
        d.owner = newOwner;
        d.editors[d.editorEpoch][newOwner] = true;
        // disable the ability to claim now that it&#39;s done
        d.erc20OwnerClaimDisabled = true;
        emit DemocOwnerSet(democHash, newOwner);
        emit DemocClaimed(democHash);
    }

    function setDEditor(bytes32 democHash, address editor, bool canEdit) only_editors() external {
        Democ storage d = democs[democHash];
        d.editors[d.editorEpoch][editor] = canEdit;
        emit DemocEditorSet(democHash, editor, canEdit);
    }

    function setDNoEditors(bytes32 democHash) only_editors() external {
        democs[democHash].editorEpoch += 1;
        emit DemocEditorsWiped(democHash);
    }

    function setDErc20(bytes32 democHash, address newErc20) only_editors() external {
        democs[democHash].erc20 = newErc20;
        erc20ToDemocs[newErc20].push(democHash);
        emit DemocErc20Set(democHash, newErc20);
    }

    function dSetArbitraryData(bytes32 democHash, bytes key, bytes value) only_editors() external {
        bytes32 k = keccak256(key);
        arbitraryData[democHash][k] = value;
        emit DemocDataSet(democHash, k);
    }

    function dSetEditorArbitraryData(bytes32 democHash, bytes key, bytes value) only_editors() external {
        bytes32 k = keccak256(_calcEditorKey(key));
        arbitraryData[democHash][k] = value;
        emit DemocDataSet(democHash, k);
    }

    function dAddCategory(bytes32 democHash, bytes32 name, bool hasParent, uint parent) only_editors() external {
        uint catId = democCategories[democHash].nCategories;
        democCategories[democHash].categories[catId].name = name;
        if (hasParent) {
            democCategories[democHash].categories[catId].hasParent = true;
            democCategories[democHash].categories[catId].parent = parent;
        }
        democCategories[democHash].nCategories += 1;
        emit DemocCatAdded(democHash, catId);
    }

    function dDeprecateCategory(bytes32 democHash, uint catId) only_editors() external {
        democCategories[democHash].categories[catId].deprecated = true;
        emit DemocCatDeprecated(democHash, catId);
    }

    function dSetCommunityBallotsEnabled(bytes32 democHash, bool enabled) only_editors() external {
        democs[democHash].communityBallotsDisabled = !enabled;
        emit DemocCommunityBallotsEnabled(democHash, enabled);
    }

    function dDisableErc20OwnerClaim(bytes32 democHash) only_editors() external {
        democs[democHash].erc20OwnerClaimDisabled = true;
        emit DemocErc20OwnerClaimDisabled(democHash);
    }

    //* ADD BALLOT TO RECORD */

    function _commitBallot(bytes32 democHash, uint ballotId, uint256 packed, bool countTowardsLimit) internal {
        uint16 subBits;
        subBits = BPackedUtils.packedToSubmissionBits(packed);

        uint localBallotId = democs[democHash].allBallots.length;
        democs[democHash].allBallots.push(ballotId);

        // do this for anything that doesn&#39;t qualify as a community ballot
        if (countTowardsLimit) {
            democs[democHash].includedBasicBallots.push(ballotId);
        }

        emit NewBallot(democHash, localBallotId);
    }

    // what SVIndex uses to add a ballot
    function dAddBallot(bytes32 democHash, uint ballotId, uint256 packed, bool countTowardsLimit) only_editors() external {
        _commitBallot(democHash, ballotId, packed, countTowardsLimit);
    }

    /* democ getters */

    function getDOwner(bytes32 democHash) external view returns (address) {
        return democs[democHash].owner;
    }

    function isDEditor(bytes32 democHash, address editor) external view returns (bool) {
        Democ storage d = democs[democHash];
        // allow either an editor or always the owner
        return d.editors[d.editorEpoch][editor] || editor == d.owner;
    }

    function getDHash(bytes13 prefix) external view returns (bytes32) {
        return democPrefixToHash[prefix];
    }

    function getDInfo(bytes32 democHash) external view returns (address erc20, address owner, uint256 nBallots) {
        return (democs[democHash].erc20, democs[democHash].owner, democs[democHash].allBallots.length);
    }

    function getDErc20(bytes32 democHash) external view returns (address) {
        return democs[democHash].erc20;
    }

    function getDArbitraryData(bytes32 democHash, bytes key) external view returns (bytes) {
        return arbitraryData[democHash][keccak256(key)];
    }

    function getDEditorArbitraryData(bytes32 democHash, bytes key) external view returns (bytes) {
        return arbitraryData[democHash][keccak256(_calcEditorKey(key))];
    }

    function getDBallotsN(bytes32 democHash) external view returns (uint256) {
        return democs[democHash].allBallots.length;
    }

    function getDBallotID(bytes32 democHash, uint256 n) external view returns (uint ballotId) {
        return democs[democHash].allBallots[n];
    }

    function getDCountedBasicBallotsN(bytes32 democHash) external view returns (uint256) {
        return democs[democHash].includedBasicBallots.length;
    }

    function getDCountedBasicBallotID(bytes32 democHash, uint256 n) external view returns (uint256) {
        return democs[democHash].includedBasicBallots[n];
    }

    function getDCategoriesN(bytes32 democHash) external view returns (uint) {
        return democCategories[democHash].nCategories;
    }

    function getDCategory(bytes32 democHash, uint catId) external view returns (bool deprecated, bytes32 name, bool hasParent, uint256 parent) {
        deprecated = democCategories[democHash].categories[catId].deprecated;
        name = democCategories[democHash].categories[catId].name;
        hasParent = democCategories[democHash].categories[catId].hasParent;
        parent = democCategories[democHash].categories[catId].parent;
    }

    function getDCommBallotsEnabled(bytes32 democHash) external view returns (bool) {
        return !democs[democHash].communityBallotsDisabled;
    }

    function getDErc20OwnerClaimEnabled(bytes32 democHash) external view returns (bool) {
        return !democs[democHash].erc20OwnerClaimDisabled;
    }

    /* util for calculating editor key */

    function _calcEditorKey(bytes key) internal pure returns (bytes) {
        return abi.encodePacked("editor.", key);
    }
}

contract IxPaymentsIface is hasVersion, ixPaymentEvents, permissioned, CanReclaimToken, payoutAllCSettable {
    /* in emergency break glass */
    function emergencySetOwner(address newOwner) external;

    /* financial calcluations */
    function weiBuysHowManySeconds(uint amount) public view returns (uint secs);
    function weiToCents(uint w) public view returns (uint);
    function centsToWei(uint c) public view returns (uint);

    /* account management */
    function payForDemocracy(bytes32 democHash) external payable;
    function doFreeExtension(bytes32 democHash) external;
    function downgradeToBasic(bytes32 democHash) external;
    function upgradeToPremium(bytes32 democHash) external;

    /* account status - getters */
    function accountInGoodStanding(bytes32 democHash) external view returns (bool);
    function getSecondsRemaining(bytes32 democHash) external view returns (uint);
    function getPremiumStatus(bytes32 democHash) external view returns (bool);
    function getFreeExtension(bytes32 democHash) external view returns (bool);
    function getAccount(bytes32 democHash) external view returns (bool isPremium, uint lastPaymentTs, uint paidUpTill, bool hasFreeExtension);
    function getDenyPremium(bytes32 democHash) external view returns (bool);

    /* admin utils for accounts */
    function giveTimeToDemoc(bytes32 democHash, uint additionalSeconds, bytes32 ref) external;

    /* admin setters global */
    function setPayTo(address) external;
    function setMinorEditsAddr(address) external;
    function setBasicCentsPricePer30Days(uint amount) external;
    function setBasicBallotsPer30Days(uint amount) external;
    function setPremiumMultiplier(uint8 amount) external;
    function setWeiPerCent(uint) external;
    function setFreeExtension(bytes32 democHash, bool hasFreeExt) external;
    function setDenyPremium(bytes32 democHash, bool isPremiumDenied) external;
    function setMinWeiForDInit(uint amount) external;

    /* global getters */
    function getBasicCentsPricePer30Days() external view returns(uint);
    function getBasicExtraBallotFeeWei() external view returns (uint);
    function getBasicBallotsPer30Days() external view returns (uint);
    function getPremiumMultiplier() external view returns (uint8);
    function getPremiumCentsPricePer30Days() external view returns (uint);
    function getWeiPerCent() external view returns (uint weiPerCent);
    function getUsdEthExchangeRate() external view returns (uint centsPerEth);
    function getMinWeiForDInit() external view returns (uint);

    /* payments stuff */
    function getPaymentLogN() external view returns (uint);
    function getPaymentLog(uint n) external view returns (bool _external, bytes32 _democHash, uint _seconds, uint _ethValue);
}

contract SVPayments is IxPaymentsIface {
    uint constant VERSION = 2;

    struct Account {
        bool isPremium;
        uint lastPaymentTs;
        uint paidUpTill;
        uint lastUpgradeTs;  // timestamp of the last time it was upgraded to premium
    }

    struct PaymentLog {
        bool _external;
        bytes32 _democHash;
        uint _seconds;
        uint _ethValue;
    }

    // this is an address that&#39;s only allowed to make minor edits
    // e.g. setExchangeRate, setDenyPremium, giveTimeToDemoc
    address public minorEditsAddr;

    // payment details
    uint basicCentsPricePer30Days = 125000; // $1250/mo
    uint basicBallotsPer30Days = 10;
    uint8 premiumMultiplier = 5;
    uint weiPerCent = 0.000016583747 ether;  // $603, 4th June 2018

    uint minWeiForDInit = 1;  // minimum 1 wei - match existing behaviour in SVIndex

    mapping (bytes32 => Account) accounts;
    PaymentLog[] payments;

    // can set this on freeExtension democs to deny them premium upgrades
    mapping (bytes32 => bool) denyPremium;
    // this is used for non-profits or organisations that have perpetual licenses, etc
    mapping (bytes32 => bool) freeExtension;


    /* BREAK GLASS IN CASE OF EMERGENCY */
    // this is included here because something going wrong with payments is possibly
    // the absolute worst case. Note: does this have negligable benefit if the other
    // contracts are compromised? (e.g. by a leaked privkey)
    address public emergencyAdmin;
    function emergencySetOwner(address newOwner) external {
        require(msg.sender == emergencyAdmin, "!emergency-owner");
        owner = newOwner;
    }
    /* END BREAK GLASS */


    constructor(address _emergencyAdmin) payoutAllCSettable(msg.sender) public {
        emergencyAdmin = _emergencyAdmin;
        assert(_emergencyAdmin != address(0));
    }

    /* base SCs */

    function getVersion() external pure returns (uint) {
        return VERSION;
    }

    function() payable public {
        _getPayTo().transfer(msg.value);
    }

    function _modAccountBalance(bytes32 democHash, uint additionalSeconds) internal {
        uint prevPaidTill = accounts[democHash].paidUpTill;
        if (prevPaidTill < now) {
            prevPaidTill = now;
        }

        accounts[democHash].paidUpTill = prevPaidTill + additionalSeconds;
        accounts[democHash].lastPaymentTs = now;
    }

    /* Financial Calculations */

    function weiBuysHowManySeconds(uint amount) public view returns (uint) {
        uint centsPaid = weiToCents(amount);
        // multiply by 10**18 to ensure we make rounding errors insignificant
        uint monthsOffsetPaid = ((10 ** 18) * centsPaid) / basicCentsPricePer30Days;
        uint secondsOffsetPaid = monthsOffsetPaid * (30 days);
        uint additionalSeconds = secondsOffsetPaid / (10 ** 18);
        return additionalSeconds;
    }

    function weiToCents(uint w) public view returns (uint) {
        return w / weiPerCent;
    }

    function centsToWei(uint c) public view returns (uint) {
        return c * weiPerCent;
    }

    /* account management */

    function payForDemocracy(bytes32 democHash) external payable {
        require(msg.value > 0, "need to send some ether to make payment");

        uint additionalSeconds = weiBuysHowManySeconds(msg.value);

        if (accounts[democHash].isPremium) {
            additionalSeconds /= premiumMultiplier;
        }

        if (additionalSeconds >= 1) {
            _modAccountBalance(democHash, additionalSeconds);
        }
        payments.push(PaymentLog(false, democHash, additionalSeconds, msg.value));
        emit AccountPayment(democHash, additionalSeconds);

        _getPayTo().transfer(msg.value);
    }

    function doFreeExtension(bytes32 democHash) external {
        require(freeExtension[democHash], "!free");
        uint newPaidUpTill = now + 60 days;
        accounts[democHash].paidUpTill = newPaidUpTill;
        emit FreeExtension(democHash);
    }

    function downgradeToBasic(bytes32 democHash) only_editors() external {
        require(accounts[democHash].isPremium, "!premium");
        accounts[democHash].isPremium = false;
        // convert premium minutes to basic
        uint paidTill = accounts[democHash].paidUpTill;
        uint timeRemaining = SafeMath.subToZero(paidTill, now);
        // if we have time remaining: convert it
        if (timeRemaining > 0) {
            // prevent accounts from downgrading if they have time remaining
            // and upgraded less than 24hrs ago
            require(accounts[democHash].lastUpgradeTs < (now - 24 hours), "downgrade-too-soon");
            timeRemaining *= premiumMultiplier;
            accounts[democHash].paidUpTill = now + timeRemaining;
        }
        emit DowngradeToBasic(democHash);
    }

    function upgradeToPremium(bytes32 democHash) only_editors() external {
        require(denyPremium[democHash] == false, "upgrade-denied");
        require(!accounts[democHash].isPremium, "!basic");
        accounts[democHash].isPremium = true;
        // convert basic minutes to premium minutes
        uint paidTill = accounts[democHash].paidUpTill;
        uint timeRemaining = SafeMath.subToZero(paidTill, now);
        // if we have time remaning then convert it - otherwise don&#39;t need to do anything
        if (timeRemaining > 0) {
            timeRemaining /= premiumMultiplier;
            accounts[democHash].paidUpTill = now + timeRemaining;
        }
        accounts[democHash].lastUpgradeTs = now;
        emit UpgradedToPremium(democHash);
    }

    /* account status - getters */

    function accountInGoodStanding(bytes32 democHash) external view returns (bool) {
        return accounts[democHash].paidUpTill >= now;
    }

    function getSecondsRemaining(bytes32 democHash) external view returns (uint) {
        return SafeMath.subToZero(accounts[democHash].paidUpTill, now);
    }

    function getPremiumStatus(bytes32 democHash) external view returns (bool) {
        return accounts[democHash].isPremium;
    }

    function getFreeExtension(bytes32 democHash) external view returns (bool) {
        return freeExtension[democHash];
    }

    function getAccount(bytes32 democHash) external view returns (bool isPremium, uint lastPaymentTs, uint paidUpTill, bool hasFreeExtension) {
        isPremium = accounts[democHash].isPremium;
        lastPaymentTs = accounts[democHash].lastPaymentTs;
        paidUpTill = accounts[democHash].paidUpTill;
        hasFreeExtension = freeExtension[democHash];
    }

    function getDenyPremium(bytes32 democHash) external view returns (bool) {
        return denyPremium[democHash];
    }

    /* admin utils for accounts */

    function giveTimeToDemoc(bytes32 democHash, uint additionalSeconds, bytes32 ref) owner_or(minorEditsAddr) external {
        _modAccountBalance(democHash, additionalSeconds);
        payments.push(PaymentLog(true, democHash, additionalSeconds, 0));
        emit GrantedAccountTime(democHash, additionalSeconds, ref);
    }

    /* admin setters global */

    function setPayTo(address newPayTo) only_owner() external {
        _setPayTo(newPayTo);
        emit SetPayTo(newPayTo);
    }

    function setMinorEditsAddr(address a) only_owner() external {
        minorEditsAddr = a;
        emit SetMinorEditsAddr(a);
    }

    function setBasicCentsPricePer30Days(uint amount) only_owner() external {
        basicCentsPricePer30Days = amount;
        emit SetBasicCentsPricePer30Days(amount);
    }

    function setBasicBallotsPer30Days(uint amount) only_owner() external {
        basicBallotsPer30Days = amount;
        emit SetBallotsPer30Days(amount);
    }

    function setPremiumMultiplier(uint8 m) only_owner() external {
        premiumMultiplier = m;
        emit SetPremiumMultiplier(m);
    }

    function setWeiPerCent(uint wpc) owner_or(minorEditsAddr) external {
        weiPerCent = wpc;
        emit SetExchangeRate(wpc);
    }

    function setFreeExtension(bytes32 democHash, bool hasFreeExt) owner_or(minorEditsAddr) external {
        freeExtension[democHash] = hasFreeExt;
        emit SetFreeExtension(democHash, hasFreeExt);
    }

    function setDenyPremium(bytes32 democHash, bool isPremiumDenied) owner_or(minorEditsAddr) external {
        denyPremium[democHash] = isPremiumDenied;
        emit SetDenyPremium(democHash, isPremiumDenied);
    }

    function setMinWeiForDInit(uint amount) owner_or(minorEditsAddr) external {
        minWeiForDInit = amount;
        emit SetMinWeiForDInit(amount);
    }

    /* global getters */

    function getBasicCentsPricePer30Days() external view returns (uint) {
        return basicCentsPricePer30Days;
    }

    function getBasicExtraBallotFeeWei() external view returns (uint) {
        return centsToWei(basicCentsPricePer30Days / basicBallotsPer30Days);
    }

    function getBasicBallotsPer30Days() external view returns (uint) {
        return basicBallotsPer30Days;
    }

    function getPremiumMultiplier() external view returns (uint8) {
        return premiumMultiplier;
    }

    function getPremiumCentsPricePer30Days() external view returns (uint) {
        return _premiumPricePer30Days();
    }

    function _premiumPricePer30Days() internal view returns (uint) {
        return uint(premiumMultiplier) * basicCentsPricePer30Days;
    }

    function getWeiPerCent() external view returns (uint) {
        return weiPerCent;
    }

    function getUsdEthExchangeRate() external view returns (uint) {
        // this returns cents per ether
        return 1 ether / weiPerCent;
    }

    function getMinWeiForDInit() external view returns (uint) {
        return minWeiForDInit;
    }

    /* payments stuff */

    function getPaymentLogN() external view returns (uint) {
        return payments.length;
    }

    function getPaymentLog(uint n) external view returns (bool _external, bytes32 _democHash, uint _seconds, uint _ethValue) {
        _external = payments[n]._external;
        _democHash = payments[n]._democHash;
        _seconds = payments[n]._seconds;
        _ethValue = payments[n]._ethValue;
    }
}

interface SvEnsIface {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns (bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
}

interface ENSIface {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
}

contract PublicResolver {

    bytes4 constant INTERFACE_META_ID = 0x01ffc9a7;
    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant CONTENT_INTERFACE_ID = 0xd8389dc5;
    bytes4 constant NAME_INTERFACE_ID = 0x691f3431;
    bytes4 constant ABI_INTERFACE_ID = 0x2203ab56;
    bytes4 constant PUBKEY_INTERFACE_ID = 0xc8690233;
    bytes4 constant TEXT_INTERFACE_ID = 0x59d1d43c;

    event AddrChanged(bytes32 indexed node, address a);
    event ContentChanged(bytes32 indexed node, bytes32 hash);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexedKey, string key);

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    struct Record {
        address addr;
        bytes32 content;
        string name;
        PublicKey pubkey;
        mapping(string=>string) text;
        mapping(uint256=>bytes) abis;
    }

    ENSIface ens;

    mapping (bytes32 => Record) records;

    modifier only_owner(bytes32 node) {
        require(ens.owner(node) == msg.sender);
        _;
    }

    /**
     * Constructor.
     * @param ensAddr The ENS registrar contract.
     */
    constructor(ENSIface ensAddr) public {
        ens = ensAddr;
    }

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param addr The address to set.
     */
    function setAddr(bytes32 node, address addr) public only_owner(node) {
        records[node].addr = addr;
        emit AddrChanged(node, addr);
    }

    /**
     * Sets the content hash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * Note that this resource type is not standardized, and will likely change
     * in future to a resource type based on multihash.
     * @param node The node to update.
     * @param hash The content hash to set
     */
    function setContent(bytes32 node, bytes32 hash) public only_owner(node) {
        records[node].content = hash;
        emit ContentChanged(node, hash);
    }

    /**
     * Sets the name associated with an ENS node, for reverse records.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param name The name to set.
     */
    function setName(bytes32 node, string name) public only_owner(node) {
        records[node].name = name;
        emit NameChanged(node, name);
    }

    /**
     * Sets the ABI associated with an ENS node.
     * Nodes may have one ABI of each content type. To remove an ABI, set it to
     * the empty string.
     * @param node The node to update.
     * @param contentType The content type of the ABI
     * @param data The ABI data.
     */
    function setABI(bytes32 node, uint256 contentType, bytes data) public only_owner(node) {
        // Content types must be powers of 2
        require(((contentType - 1) & contentType) == 0);

        records[node].abis[contentType] = data;
        emit ABIChanged(node, contentType);
    }

    /**
     * Sets the SECP256k1 public key associated with an ENS node.
     * @param node The ENS node to query
     * @param x the X coordinate of the curve point for the public key.
     * @param y the Y coordinate of the curve point for the public key.
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) public only_owner(node) {
        records[node].pubkey = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    /**
     * Sets the text data associated with an ENS node and key.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(bytes32 node, string key, string value) public only_owner(node) {
        records[node].text[key] = value;
        emit TextChanged(node, key, key);
    }

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string key) public view returns (string) {
        return records[node].text[key];
    }

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x, y the X and Y coordinates of the curve point for the public key.
     */
    function pubkey(bytes32 node) public view returns (bytes32 x, bytes32 y) {
        return (records[node].pubkey.x, records[node].pubkey.y);
    }

    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) public view returns (uint256 contentType, bytes data) {
        Record storage record = records[node];
        for (contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && record.abis[contentType].length > 0) {
                data = record.abis[contentType];
                return;
            }
        }
        contentType = 0;
    }

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) public view returns (string) {
        return records[node].name;
    }

    /**
     * Returns the content hash associated with an ENS node.
     * Note that this resource type is not standardized, and will likely change
     * in future to a resource type based on multihash.
     * @param node The ENS node to query.
     * @return The associated content hash.
     */
    function content(bytes32 node) public view returns (bytes32) {
        return records[node].content;
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public view returns (address) {
        return records[node].addr;
    }

    /**
     * Returns true if the resolver implements the interface specified by the provided hash.
     * @param interfaceID The ID of the interface to check for.
     * @return True if the contract implements the requested interface.
     */
    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == ADDR_INTERFACE_ID ||
        interfaceID == CONTENT_INTERFACE_ID ||
        interfaceID == NAME_INTERFACE_ID ||
        interfaceID == ABI_INTERFACE_ID ||
        interfaceID == PUBKEY_INTERFACE_ID ||
        interfaceID == TEXT_INTERFACE_ID ||
        interfaceID == INTERFACE_META_ID;
    }
}

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don&#39;t need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let&#39;s prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes_slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes _bytes, uint _start, uint _length) internal  pure returns (bytes) {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don&#39;t care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we&#39;re done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin&#39;s length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let&#39;s just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint(bytes _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don&#39;t match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there&#39;s
                //  no said feature for inline assembly loops
                // cb = 1 - don&#39;t breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don&#39;t match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let&#39;s prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there&#39;s
                        //  no said feature for inline assembly loops
                        // cb = 1 - don&#39;t breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}