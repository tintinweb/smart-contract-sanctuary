// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.6.3;

/**
 @title Main Storage of the Living Assets Platform
 @author Freeverse.io, www.freeverse.io
 @notice Responsible for all storage, including upgrade pointers to external contracts to mange updates/challenges 
*/

import "../interfaces/IStorage.sol";
import "../storage/RolesSetters.sol";

contract Storage is IStorage, RolesSetters {
    constructor(address company, address superUser) {
        // Setup main roles:
        _company = company;
        _superUser = superUser;

        // Setup main global variables:
        _nLevelsPerChallengeNextVerses = 4;
        _maxTimeWithoutVerseProduction = 604800; // 1 week

        // Setup TXBatchReference variables:
        _referenceVerse = 1;
        _verseInterval = 15 * 60;
        _referenceTime =
            block.timestamp +
            _verseInterval -
            (block.timestamp % _verseInterval);

        // Initialize with null TXBatch and null Ownership Root
        _txBatches.push(TXBatch(bytes32(0x0), 0, 0, 3, 4, 0));
        _ownerships.push(Ownership(bytes32(0x0), 1));
        _challenges.push(
            Challenge(bytes32(0x0), bytes32(0x0), bytes32(0x0), 0)
        );
    }

    /**
     * @notice Sets max time period for new verse production.
     *  Beyond this deadline several functions can be activated.
     */
    function setTimeWithoutVerseProduction(uint256 time)
        external
        onlySuperUser
    {
        require(
            time < 2592000,
            "setTimeWithoutVerseProduction: cannot set a time larger than 1 month"
        );
        _maxTimeWithoutVerseProduction = time;
    }

    /**
     * @notice Sets num of levels per challenge to be used for new verses
     */
    function setLevelsPerChallengeNextVerses(uint8 value)
        external
        onlySuperUser
    {
        _nLevelsPerChallengeNextVerses = value;
    }

    /**
     * @notice Sets the challenge window, in secs, that affects new verses
     */
    function setChallengeWindowNextVerses(uint256 newTime)
        external
        onlySuperUser
    {
        _challengeWindowNextVerses = newTime;
        emit NewChallengeWindow(newTime);
    }

    /**
     * @notice Sets the reference values used to compute the expected time
     *  of production for new verses
     */
    function setTXBatchReference(
        uint256 refVerse,
        uint256 refTime,
        uint256 vInterval
    ) external onlySuperUser {
        _referenceVerse = refVerse;
        _verseInterval = vInterval;
        _referenceTime = refTime;
        emit NewTXBatchReference(refVerse, refTime, vInterval);
    }

    /**
     * @notice Creates a new universe controlled by owner
     *  The universeIdx is forced as input as a redundancy / replay-attack check.
     */
    function createUniverse(
        uint256 universeIdx,
        address owner,
        string calldata name
    ) external onlySuperUser {
        require(
            nUniverses() == universeIdx,
            "createUniverse: universeIdx does not equal nUniverses"
        );

        // Prepare init arrays
        bytes32[] memory initRootArray = new bytes32[](1);
        initRootArray[0] = bytes32(0);
        uint256[] memory initRootTimeStamp = new uint256[](1);
        initRootTimeStamp[0] = block.timestamp;

        // Create and emit event
        _universes.push(
            Universe(
                owner,
                name,
                initRootArray,
                initRootTimeStamp,
                false,
                false
            )
        );
        emit CreateUniverse(universeIdx, owner, name);
    }

    /**
     * @notice Closes a universe so that it cannot be updated further
     */
    function changeUniverseClosure(
        uint256 universeIdx,
        bool closureRequested,
        bool closureConfirmed
    ) external onlyWriterContract {
        _universes[universeIdx].closureRequested = closureRequested;
        _universes[universeIdx].closureConfirmed = closureConfirmed;
    }

    /**
     * @notice Changes name of a universe
     */
    function changeUniverseName(uint256 universeIdx, string calldata name)
        external
        onlySuperUser
    {
        require(universeIdx < nUniverses(), "universeIdx does not exist");
        _universes[universeIdx].name = name;
    }

    /**
     * @notice Adds a new universe root struct to the universes array
     */
    function pushUniverseRoot(
        uint256 universeIdx,
        bytes32 newRoot,
        uint256 submissionTime
    ) external onlyWriterContract returns (uint256 verse) {
        _universes[universeIdx].roots.push(newRoot);
        _universes[universeIdx].rootsSubmissionTimes.push(submissionTime);
        return _universes[universeIdx].roots.length - 1;
    }

    /**
    * @notice Sets last ownership root to provided value
    */
    function setLastOwnershipRoot(bytes32 newRoot) external onlyWriterContract {
        _ownerships[_ownerships.length - 1].root = newRoot;
    }

    /**
    * @notice Sets last ownership submission time to provided value
    */
    function setLastOwnershipSubmissionTime(uint256 newTime) external onlyWriterContract {
        _ownerships[_ownerships.length - 1].submissionTime = newTime;
    }

    /**
    * @notice Deletes the Challenges array
    */
    function deleteChallenges() external onlyWriterContract {
        delete _challenges;
    }

    /**
    * @notice Pushes a new TXBatch to the txBatches array
    */
    function pushTXRoot(
        bytes32 newTXsRoot,
        uint256 submissionTime,
        uint256 nTXs,
        uint8 levelVeriableByBC
    ) external onlyWriterContract returns (uint256 txVerse) {
        _txBatches.push(
            TXBatch(
                newTXsRoot,
                submissionTime,
                nTXs,
                levelVeriableByBC,
                _nLevelsPerChallengeNextVerses,
                _challengeWindowNextVerses
            )
        );
        return _txBatches.length - 1;
    }

    /**
    * @notice Pushes a new Ownership stuct to the ownerships array
    */
    function pushOwnershipRoot(
        bytes32 newOwnershipRoot,
        uint256 submissionTime
    ) external onlyWriterContract returns (uint256 ownVerse) {
        _ownerships.push(Ownership(newOwnershipRoot, submissionTime));
        return _ownerships.length - 1;
    }

    /**
     * @notice Pushes a new challenge to the challenges array
     */
    function pushChallenge(
        bytes32 ownershipRoot,
        bytes32 transitionsRoot,
        bytes32 rootAtEdge,
        uint256 pos
    ) external onlyWriterContract {
        _challenges.push(
            Challenge(ownershipRoot, transitionsRoot, rootAtEdge, pos)
        );
    }

    /**
     * @notice Pops the last entry from the challenges array
     */
    function popChallenge() external onlyWriterContract {
        _challenges.pop();
    }

    /**
     * @notice Sets the exportInfo struct associated to an assetId
     */
    function setExportInfo(uint256 assetId, address owner, uint256 requestVerse, uint256 completedVerse)
        external
        onlyAssetExporterContract
    {
        _exportInfo[assetId] = ExportInfo(owner, requestVerse, completedVerse);
    }

    /**
     * @notice Pushes an entry at the end of the claims array 
     */
    function addClaim() external onlySuperUser {
        _claims.push();
    }

    /**
     * @notice Sets a claim with to a provided key-value pair
     */
    function setClaim(
        uint256 claimIdx,
        uint256 key,
        uint256 verse,
        string memory value
    ) external onlyWriterContract {
        Claim memory c = Claim(verse, value);
        _claims[claimIdx][key] = c;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @title Getters for storage data
 @author Freeverse.io, www.freeverse.io
 @dev Main storage getters
*/

import "../storage/StorageBase.sol";
import "../interfaces/IStorageGetters.sol";

contract StorageGetters is IStorageGetters, StorageBase {
    modifier onlyCompany() {
        require(msg.sender == _company, "Only company is authorized.");
        _;
    }

    modifier onlySuperUser() {
        require(msg.sender == _superUser, "Only superUser is authorized.");
        _;
    }

    modifier onlyUniversesRelayer() {
        require(
            msg.sender == _universesRelayer,
            "Only relayer of universes is authorized."
        );
        _;
    }

    modifier onlyTXRelayer() {
        require(
            msg.sender == _txRelayer,
            "Only relayer of TXs is authorized."
        );
        _;
    }

    modifier onlyWriterContract() {
        require(msg.sender == _writer, "Only updates contract is authorized.");
        _;
    }

    modifier onlyAssetExporterContract() {
        require(
            msg.sender == _assetExporter,
            "Only assetExporter contract is authorized."
        );
        _;
    }

    // UNIVERSE GETTERS

    function universeOwner(uint256 universeIdx) external view returns (address) {
        return _universes[universeIdx].owner;
    }

    function universeName(uint256 universeIdx)
        external
        view
        returns (string memory)
    {
        return _universes[universeIdx].name;
    }

    function universeVerse(uint256 universeIdx) external view returns (uint256) {
        return _universes[universeIdx].roots.length - 1;
    }

    function universeRootAtVerse(uint256 universeIdx, uint256 verse)
        external
        view
        returns (bytes32)
    {
        return _universes[universeIdx].roots[verse];
    }

    function universeRootCurrent(uint256 universeIdx)
        external
        view
        returns (bytes32)
    {
        return
            _universes[universeIdx].roots[
                _universes[universeIdx].roots.length - 1
            ];
    }

    function nUniverses() public view returns (uint256) {
        return _universes.length;
    }

    function universeRootSubmissionTimeAtVerse(
        uint256 universeIdx,
        uint256 verse
    ) external view returns (uint256) {
        return _universes[universeIdx].rootsSubmissionTimes[verse];
    }

    function universeRootSubmissionTimeCurrent(uint256 universeIdx)
        external
        view
        returns (uint256)
    {
        return
            _universes[universeIdx].rootsSubmissionTimes[
                _universes[universeIdx].rootsSubmissionTimes.length - 1
            ];
    }

    function universeIsClosed(uint256 universeIdx) external view returns (bool) {
        return _universes[universeIdx].closureConfirmed;
    }

    function universeIsClosureRequested(uint256 universeIdx)
        external
        view
        returns (bool)
    {
        return _universes[universeIdx].closureRequested;
    }

    // OWNERSHIP GETTERS
    // - Global variables
    function challengeWindowNextVerses() external view returns (uint256) {
        return _challengeWindowNextVerses;
    }

    function nLevelsPerChallengeNextVerses() external view returns (uint8) {
        return _nLevelsPerChallengeNextVerses;
    }

    function maxTimeWithoutVerseProduction() external view returns (uint256) {
        return _maxTimeWithoutVerseProduction;
    }

    function exportRequestInfo(uint256 assetId)
        external
        view
        returns (
            address owner,
            uint256 requestVerse,
            uint256 completedVerse
        )
    {
        ExportInfo memory request = _exportInfo[assetId];
        return (request.owner, request.requestVerse, request.completedVerse);
    }

    function exportOwner(uint256 assetId) external view returns (address owner) {
        return _exportInfo[assetId].owner;
    }

    function exportRequestVerse(uint256 assetId) external view returns (uint256 requestVerse) {
        return _exportInfo[assetId].requestVerse;
    }

    function exportCompletedVerse(uint256 assetId) external view returns (uint256 completedVerse) {
        return _exportInfo[assetId].completedVerse;
    }

    // - Verses
    function ownershipCurrentVerse() external view returns (uint256) {
        return _ownerships.length - 1;
    }

    function txRootsCurrentVerse() external view returns (uint256) {
        return _txBatches.length - 1;
    }

    // - TXBatches interval time info
    function referenceVerse() external view returns (uint256) {
        return _referenceVerse;
    }

    function referenceTime() external view returns (uint256) {
        return _referenceTime;
    }

    function verseInterval() external view returns (uint256) {
        return _verseInterval;
    }

    // - TXBatches and Ownership data: queries at a given verse
    function ownershipRootAtVerse(uint256 verse) external view returns (bytes32) {
        return _ownerships[verse].root;
    }

    function txRootAtVerse(uint256 verse) external view returns (bytes32) {
        return _txBatches[verse].root;
    }

    function nLevelsPerChallengeAtVerse(uint256 verse)
        external
        view
        returns (uint8)
    {
        return _txBatches[verse].nLevelsPerChallenge;
    }

    function levelVerifiableOnChainAtVerse(uint256 verse)
        external
        view
        returns (uint8)
    {
        return _txBatches[verse].levelVerifiableOnChain;
    }

    function nTXsAtVerse(uint256 verse) external view returns (uint256) {
        return _txBatches[verse].nTXs;
    }

    function challengeWindowAtVerse(uint256 verse)
        external
        view
        returns (uint256)
    {
        return _txBatches[verse].challengeWindow;
    }

    function txSubmissionTimeAtVerse(uint256 verse)
        external
        view
        returns (uint256)
    {
        return _txBatches[verse].submissionTime;
    }

    function ownershipSubmissionTimeAtVerse(uint256 verse)
        external
        view
        returns (uint256)
    {
        return _ownerships[verse].submissionTime;
    }

    // - TXBatches and Ownership data: queries about most recent entry
    function ownershipRootCurrent() external view returns (bytes32) {
        return _ownerships[_ownerships.length - 1].root;
    }

    function txRootCurrent() external view returns (bytes32) {
        return _txBatches[_txBatches.length - 1].root;
    }

    function nLevelsPerChallengeCurrent() public view returns (uint8) {
        return _txBatches[_txBatches.length - 1].nLevelsPerChallenge;
    }

    function levelVerifiableOnChainCurrent() public view returns (uint8) {
        return _txBatches[_txBatches.length - 1].levelVerifiableOnChain;
    }

    function nTXsCurrent() external view returns (uint256) {
        return _txBatches[_txBatches.length - 1].nTXs;
    }

    function challengeWindowCurrent() external view returns (uint256) {
        return _txBatches[_txBatches.length - 1].challengeWindow;
    }

    function txSubmissionTimeCurrent() external view returns (uint256) {
        return _txBatches[_txBatches.length - 1].submissionTime;
    }

    function ownershipSubmissionTimeCurrent() external view returns (uint256) {
        return _ownerships[_ownerships.length - 1].submissionTime;
    }

    // CHALLENGES GETTERS
    function challengesOwnershipRoot(uint8 level)
        external
        view
        returns (bytes32)
    {
        return _challenges[level].ownershipRoot;
    }

    function challengesTransitionsRoot(uint8 level)
        external
        view
        returns (bytes32)
    {
        return _challenges[level].transitionsRoot;
    }

    function challengesRootAtEdge(uint8 level) external view returns (bytes32) {
        return _challenges[level].rootAtEdge;
    }

    function challengesPos(uint8 level) public view returns (uint256) {
        return _challenges[level].pos;
    }

    function challengesLevel() public view returns (uint8) {
        return uint8(_challenges.length);
    }

    function areAllChallengePosZero() public view returns (bool) {
        for (uint8 level = 0; level < challengesLevel(); level++) {
            if (challengesPos(level) != 0) return false;
        }
        return true;
    }

    function nLeavesPerChallengeCurrent() public view returns (uint256) {
        return 2**uint256(nLevelsPerChallengeCurrent());
    }

    // this getter is included as part of the storage due to high savings in gas cost 
    function computeBottomLevelLeafPos(uint256 finalTransEndPos)
        external
        view
        returns (uint256 bottomLevelLeafPos)
    {
        require(
            (challengesLevel() + 1) == levelVerifiableOnChainCurrent(),
            "not enough challenges to compute bottomLevelLeafPos"
        );
        bottomLevelLeafPos = finalTransEndPos;
        uint256 factor = nLeavesPerChallengeCurrent();
        // _challengePos[level = 0] is always 0 (the first challenge is a challenge to one single root)
        for (uint8 level = challengesLevel() - 1; level > 0; level--) {
            bottomLevelLeafPos += challengesPos(level) * factor;
            factor *= factor;
        }
    }

    // ROLES GETTERS
    function company() external view returns (address) {
        return _company;
    }

    function proposedCompany() external view returns (address) {
        return _proposedCompany;
    }

    function superUser() external view returns (address) {
        return _superUser;
    }

    function universesRelayer() external view returns (address) {
        return _universesRelayer;
    }

    function txRelayer() external view returns (address) {
        return _txRelayer;
    }

    function stakers() external view returns (address) {
        return _stakers;
    }

    function writer() external view returns (address) {
        return _writer;
    }

    function directory() external view returns (address) {
        return _directory;
    }

    function externalNFTContract() external view returns (address) {
        return _externalNFTContract;
    }

    function assetExporter() external view returns (address) {
        return _assetExporter;
    }

    // CLAIMS
    function claim(uint256 claimIdx, uint256 key)
        external
        view
        returns (uint256 verse, string memory value)
    {
        Claim memory c = _claims[claimIdx][key];
        return (c.verse, c.value);
    }

    function nClaims() external view returns (uint256 len) {
        return _claims.length;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @title Declaration of all storage variables
 @author Freeverse.io, www.freeverse.io
*/

import "../interfaces/IStorageBase.sol";

contract StorageBase is IStorageBase {
    /**
    @dev ROLES ADDRESSES
    */
    // Responsible for changing superuser:
    address internal _company;
    address internal _proposedCompany;

    // Responsible for changing lower roles:
    address internal _superUser;

    // Submitters:
    //   - stakers submits ownership;
    //   - relayers: submit universeRoots & TXRoots
    address internal _universesRelayer;
    address internal _txRelayer;
    address internal _stakers;

    /**
    @dev EXTERNAL CONTRACTS THAT INTERACT WITH STORAGE
    */
    // External contract responsible for writing to storage from the Updates & Challenges contracts:
    address internal _writer;

    // External contract for exporting standard assets:
    address internal _assetExporter;

    // External contract for exporting standard assets:
    address internal _externalNFTContract;

    // Directory contract contains the addresses of all contracts of this dApp:
    address internal _directory;

    /**
    @dev INTERNAL VARIABLES & STRUCTS 
    */
    // GLOBAL VARIABLES
    // - Beyond this _maxTimeWithoutVerseProduction time, assets can be exported without new verses being produced
    // - Useful in case of cease of operations
    uint256 internal _maxTimeWithoutVerseProduction;
    // - The next two are pushed to txBatches.challengeWindows and txBatches.nLevelsPerChallenge
    uint256 internal _challengeWindowNextVerses;
    uint8 internal _nLevelsPerChallengeNextVerses;

    // - Params that determine when to relay txBatches
    uint256 internal _verseInterval;
    uint256 internal _referenceVerse;
    uint256 internal _referenceTime;

    // UNIVERSES
    Universe[] internal _universes;

    // OWNERSHIP
    // A Transaction Batch containing requests to update Ownership tree accordingly
    // It stores the data required to govern a potential challenge process
    TXBatch[] internal _txBatches;

    // OWNERSHIP
    // Ownership is stored as a 256-level Sparse Merkle Tree where each leaf is labeled by assetId
    Ownership[] internal _ownerships;

    // CHALLENGES
    Challenge[] internal _challenges;

    // ASSET EXPORT
    // Data stored when an owner requests, and then completes, 
    // the export of an asset, so that it is minted as a standard L1 NFT
    mapping(uint256 => ExportInfo) internal _exportInfo;

    // Future usage
    mapping(uint256 => Claim)[] internal _claims;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @title Manages authorized addresses
 @author Freeverse.io, www.freeverse.io
 @dev Setters for all roles
 @dev Company owner can reset every other role.
*/

import "../interfaces/IRolesSetters.sol";
import "../storage/StorageGetters.sol";

contract RolesSetters is IRolesSetters, StorageGetters {
    /**
     * @dev Proposes a new company owner, who needs to later accept it
     */
    function proposeCompany(address addr) external onlyCompany {
        _proposedCompany = addr;
        emit NewProposedCompany(addr);
    }

    /**
     * @dev The proposed owner uses this function to become the new owner
     */
    function acceptCompany() external {
        require(
            msg.sender == _proposedCompany,
            "only proposed owner can become owner"
        );
        _company = _proposedCompany;
        _proposedCompany = address(0);
        emit NewCompany(_company);
    }

    function setSuperUser(address addr) external onlyCompany {
        _superUser = addr;
        emit NewSuperUser(addr);
    }

    function setUniversesRelayer(address addr) external onlySuperUser {
        _universesRelayer = addr;
        emit NewUniversesRelayer(addr);
    }

    function setTxRelayer(address addr) external onlySuperUser {
        _txRelayer = addr;
        emit NewTxRelayer(addr);
    }

    function setWriter(address addr) public onlySuperUser {
        _writer = addr;
        emit NewWriter(addr);
    }

    function setStakers(address addr) external onlySuperUser {
        _stakers = addr;
        emit NewStakers(addr);
    }

    function setExternalNFTContract(address addr) external onlySuperUser {
        _externalNFTContract = addr;
        emit NewExternalNFTContract(addr);
    }

    function setAssetExporter(address addr) public onlySuperUser {
        _assetExporter = addr;
        emit NewAssetExporter(addr);
    }

    function setDirectory(address addr) public onlySuperUser {
        _directory = addr;
        emit NewDirectory(addr);
    }

    /**
    * @dev Upgrading amounts to changing the contracts with write permissions to storage,
           and reporting new contract addresses in a new Directory contract
    */
    function upgrade(
        address newWriter,
        address newAssetExporter,
        address newDirectory
    ) external onlySuperUser {
        setWriter(newWriter);
        setAssetExporter(newAssetExporter);
        setDirectory(newDirectory);
    }

    /**
     * @dev The owner of a universe must sign any transaction that updates the state of the corresponding universe assets
     */
    function setUniverseOwner(uint256 universeIdx, address newOwner)
        external
        onlySuperUser
    {
        require(universeIdx < nUniverses(), "universeIdx does not exist");
        _universes[universeIdx].owner = newOwner;
        emit NewUniverseOwner(universeIdx, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @title The interface to the main storage getters
*/

interface IStorageGetters {
    // UNIVERSE GETTERS

    function universeOwner(uint256 universeIdx) external view returns (address);

    function universeName(uint256 universeIdx) external view returns (string memory);

    function universeVerse(uint256 universeIdx) external view returns (uint256);

    function universeRootAtVerse(uint256 universeIdx, uint256 verse) external view returns (bytes32);

    function universeRootCurrent(uint256 universeIdx) external view returns (bytes32);

    function nUniverses() external view returns (uint256);

    function universeRootSubmissionTimeAtVerse(uint256 universeIdx, uint256 verse) external view returns (uint256);

    function universeRootSubmissionTimeCurrent(uint256 universeIdx) external view returns (uint256);

    function universeIsClosed(uint256 universeIdx) external view returns (bool);

    function universeIsClosureRequested(uint256 universeIdx) external view returns (bool);

    // OWNERSHIP GETTERS
    // - Global variables
    function challengeWindowNextVerses() external view returns (uint256);

    function nLevelsPerChallengeNextVerses() external view returns (uint8);

    function maxTimeWithoutVerseProduction() external view returns (uint256);

    function exportRequestInfo(uint256 assetId) external view returns (address owner, uint256 requestVerse, uint256 completedVerse);

    function exportOwner(uint256 assetId) external view returns (address owner);

    function exportRequestVerse(uint256 assetId) external view returns (uint256 requestVerse);

    function exportCompletedVerse(uint256 assetId) external view returns (uint256 completedVerse);

    // - Verses
    function ownershipCurrentVerse() external view returns (uint256);

    function txRootsCurrentVerse() external view returns (uint256);

    // - TXBatches interval time info
    function referenceVerse() external view returns (uint256);

    function referenceTime() external view returns (uint256);

    function verseInterval() external view returns (uint256);

    // - TXBatches and Ownership data: queries at a given verse
    function ownershipRootAtVerse(uint256 verse) external view returns (bytes32);

    function txRootAtVerse(uint256 verse) external view returns (bytes32);

    function nLevelsPerChallengeAtVerse(uint256 verse) external view returns (uint8);

    function levelVerifiableOnChainAtVerse(uint256 verse) external view returns (uint8);

    function nTXsAtVerse(uint256 verse) external view returns (uint256);

    function challengeWindowAtVerse(uint256 verse) external view returns (uint256);

    function txSubmissionTimeAtVerse(uint256 verse) external view returns (uint256);

    function ownershipSubmissionTimeAtVerse(uint256 verse) external view returns (uint256);

    // - TXBatches and Ownership data: queries about most recent entry
    function ownershipRootCurrent() external view returns (bytes32);

    function txRootCurrent() external view returns (bytes32);

    function nLevelsPerChallengeCurrent() external view returns (uint8);

    function levelVerifiableOnChainCurrent() external view returns (uint8);

    function nTXsCurrent() external view returns (uint256);

    function challengeWindowCurrent() external view returns (uint256);

    function txSubmissionTimeCurrent() external view returns (uint256);

    function ownershipSubmissionTimeCurrent() external view returns (uint256);

    // CHALLENGES GETTERS
    function challengesOwnershipRoot(uint8 level) external view returns (bytes32);

    function challengesTransitionsRoot(uint8 level) external view returns (bytes32);

    function challengesRootAtEdge(uint8 level) external view returns (bytes32);

    function challengesPos(uint8 level) external view returns (uint256);

    function challengesLevel() external view returns (uint8);

    function areAllChallengePosZero() external view returns (bool);

    function nLeavesPerChallengeCurrent() external view returns (uint256);

    // this getter is included as part of the storage due to high savings in gas cost 
    function computeBottomLevelLeafPos(uint256 finalTransEndPos) external view returns (uint256 bottomLevelLeafPos);

    // ROLES GETTERS
    function company() external view returns (address);

    function proposedCompany() external view returns (address);

    function superUser() external view returns (address);

    function universesRelayer() external view returns (address);

    function txRelayer() external view returns (address);

    function stakers() external view returns (address);

    function writer() external view returns (address);

    function directory() external view returns (address);

    function externalNFTContract() external view returns (address);

    function assetExporter() external view returns (address);

    // CLAIMS
    function claim(uint256 claimIdx, uint256 key) external view returns (uint256 verse, string memory value);

    function nClaims() external view returns (uint256 len);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Declaration of all storage variables
*/

interface IStorageBase {
    struct Universe {
        address owner;
        string name;
        bytes32[] roots;
        uint256[] rootsSubmissionTimes;
        bool closureRequested;
        bool closureConfirmed;
    }

    struct TXBatch {
        bytes32 root;
        uint256 submissionTime;
        uint256 nTXs;
        uint8 levelVerifiableOnChain;
        uint8 nLevelsPerChallenge;
        uint256 challengeWindow;
    }

    struct Ownership {
        // The settled ownership Roots, one per verse
        bytes32 root;
        // The submission timestamp upon reception of a new ownershipRoot,
        // or the lasttime the corresponding challenge was updated.
        uint256 submissionTime;
    }

    struct Challenge {
        bytes32 ownershipRoot;
        bytes32 transitionsRoot;
        bytes32 rootAtEdge;
        uint256 pos;
    }

    struct ExportInfo {
        address owner;
        uint256 requestVerse;
        uint256 completedVerse;
    }

    struct Claim {
        uint256 verse;
        string value;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @title Main Storage of the Living Assets Platform
 @notice Responsible for all storage, including upgrade pointers to external contracts to mange updates/challenges 
*/

interface IStorage {
    event NewChallengeWindow(uint256 newTime);
    event CreateUniverse(
        uint256 universeIdx,
        address owner,
        string name
    );
    event NewTXBatchReference(
        uint256 refVerse,
        uint256 refTime,
        uint256 vInterval
    );

    /**
     * @notice Closes a universe so that it cannot be updated further
     */
    function changeUniverseClosure(uint256 universeIdx, bool closureRequested, bool closureConfirmed) external;

    /**
     * @notice Adds a new universe root struct to the universes array
     */
    function pushUniverseRoot(uint256 universeIdx, bytes32 newRoot, uint256 submissionTime) external returns (uint256 verse);

    /**
    * @notice Sets last ownership root to provided value
    */
    function setLastOwnershipRoot(bytes32 newRoot) external;

    /**
    * @notice Sets last ownership submission time to provided value
    */
    function setLastOwnershipSubmissionTime(uint256 newTime) external;

    /**
    * @notice Deletes the Challenges array
    */
    function deleteChallenges() external;

    /**
    * @notice Pushes a new TXBatch to the txBatches array
    */
    function pushTXRoot(
        bytes32 newTXsRoot,
        uint256 submissionTime,
        uint256 nTXs,
        uint8 levelVeriableByBC
    ) external returns (uint256 txVerse);

    /**
    * @notice Pushes a new Ownership stuct to the ownerships array
    */
    function pushOwnershipRoot(
        bytes32 newOwnershipRoot,
        uint256 submissionTime
    ) external returns (uint256 ownVerse) ;

    /**
     * @notice Pushes a new challenge to the challenges array
     */
    function pushChallenge(
        bytes32 ownershipRoot,
        bytes32 transitionsRoot,
        bytes32 rootAtEdge,
        uint256 pos
    ) external;

    /**
     * @notice Pops the last entry from the challenges array
     */
    function popChallenge() external;

    /**
     * @notice Sets the exportInfo struct associated to an assetId
     */
    function setExportInfo(uint256 assetId, address owner, uint256 requestVerse, uint256 completedVerse) external;

    /**
     * @notice Sets a claim with to a provided key-value pair
     */
    function setClaim(
        uint256 claimIdx,
        uint256 key,
        uint256 verse,
        string memory value
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Setters for all roles
*/

interface IRolesSetters {
    event NewDirectory(address addr);
    event NewCompany(address addr);
    event NewProposedCompany(address addr);
    event NewWriter(address addr);
    event NewSuperUser(address addr);
    event NewUniversesRelayer(address addr);
    event NewTxRelayer(address addr);
    event NewStakers(address addr);
    event NewUniverseOwner(uint256 universeIdx, address owner);
    event NewExternalNFTContract(address addr);
    event NewAssetExporter(address addr);
}