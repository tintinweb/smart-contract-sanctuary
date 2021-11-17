// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Manages Export of Assets to Standard Layer-1 ERC721 contract
*/

import "../storage/Storage.sol";
import "../view/Info.sol";
import "../erc721/ERC721FV.sol";

contract AssetExport {
    event NewInfoAddress(address addr);
    event NewERC721Address(address addr);
    event RequestAssetExport();

    Info public _info;
    ERC721FV public _erc721;
    Storage public _sto;

    constructor(address storageAddress, address infoAddress) {
        _info = Info(infoAddress);
        _sto = Storage(storageAddress);
        _erc721 = ERC721FV(_sto.externalNFTContract());
    }

    modifier onlySuperUser() {
        require(
            msg.sender == _sto.superUser(),
            "AssetExport: Only superUser is authorized."
        );
        _;
    }

    /**
     * @dev
        OWNERSHIP TRANSFER TO EXTERNAL NFT CONTRACT
        Transfering the ownership of the external NFT contract needs to be done with great care,
        The new owner contract needs to implement a transferOwnership method too.
     */

    function transferERCOwnership(address newOwner) external onlySuperUser {
        _erc721.transferOwnership(newOwner);
    }

    // Main contracts required by AssetExport: Info & external ERC721

    function setInfoAddress(address newAddr) external onlySuperUser {
        _info = Info(newAddr);
        emit NewInfoAddress(newAddr);
    }

    function setERC721Address(address newAddr) external onlySuperUser {
        _erc721 = ERC721FV(newAddr);
        emit NewERC721Address(newAddr);
    }

    /**
     * @dev 
        Requests assset export as first step before exporting asset.
        It requires asset not be frozen / in transfer at this moment. 
        It enforces that, as of next verse, asset marketData will not be able to change.
     */
    function requestAssetExport(
        uint256 assetId,
        bytes memory marketData,
        string memory assetCID,
        bytes memory ownershipProof,
        bytes memory assetPropsProof
    ) external {
        require(
            bytes(assetCID).length > 8,
            "requestAssetExport: only created assets with valid CID can be exported"
        );
        require(
            !tokenHasOwner(assetId),
            "requestAssetExport: asset already exported"
        );
        require(
            !_info.wasAssetFrozen(marketData, _sto.txRootsCurrentVerse()),
            "requestAssetExport: cannot export an asset that is currently frozen"
        );
        require(
            _info.isCurrentOwner(
                assetId,
                msg.sender,
                marketData,
                ownershipProof
            ),
            "requestAssetExport: isCurrentOwner failed"
        );
        require(
            _info.isCurrentAssetProps(assetId, assetCID, assetPropsProof),
            "requestAssetExport: isCurrentAssetProps failed"
        );
        _sto.createExportRequest(assetId, msg.sender);
    }

    /**
     * @dev 
        Completes assset export for an asset that had requested export previously.
        It mints a new token in the external ERC721 contract
        with tokenURI = addIPFSPrefix(assetCID)
     */
    function completeAssetExport(
        uint256 assetId,
        bytes memory marketData,
        string memory assetCID,
        bytes memory ownershipProof,
        bytes memory assetPropsProof
    ) external {
        require(
            bytes(assetCID).length > 8,
            "completeAssetExport: only created assets with valid CID can be exported"
        );
        require(
            !tokenHasOwner(assetId),
            "completeAssetExport: asset already exported"
        );
        require(
            !_info.wasAssetFrozen(marketData, block.timestamp),
            "completeAssetExport: cannot export an asset that is currently frozen"
        );
        require(
            _info.isCurrentOwner(
                assetId,
                msg.sender,
                marketData,
                ownershipProof
            ),
            "completeAssetExport: isCurrentOwner failed"
        );
        require(
            _info.isCurrentAssetProps(assetId, assetCID, assetPropsProof),
            "completeAssetExport: isCurrentAssetProps failed"
        );
        _sto.completeAssetExport(assetId, msg.sender);
        _erc721.mint(msg.sender, assetId, addIPFSPrefix(assetCID));
    }

    /**
    * @dev 
        Returns true if the token has a non-null owner in the external ERC721 contract
        If the token was exported, and then burnt, this function would return false
        This is why it is important that "isExported" is stored and verified in the Storage contract.
    */
    function tokenHasOwner(uint256 assetId) public view returns (bool) {
        return _erc721.exists(assetId);
    }

    /// @dev returns the ipfs path expected for an asset with a given assetCID
    function addIPFSPrefix(string memory assetCID)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("ipfs://", assetCID));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Main interface for applications that require ownership/prop verification 
*/

import "../storage/StorageGetters.sol";
import "../pure/InfoBase.sol";

contract Info is InfoBase {
    StorageGetters private _storage;

    constructor(address storageAddress) {
        _storage = StorageGetters(storageAddress);
    }

    /**
    @dev Returns true only if the input owner owns the asset AND the asset has the provided props
         Proofs need to be provided. They are verified against current Onwerhsip and Universe roots, respectively.
    */
    function isCurrentOwnerOfAssetWithProps(
        uint256 assetId,
        address owner,
        bytes memory marketData,
        string memory assetCID,
        bytes memory ownershipProof,
        bytes memory propsProof
    ) public view returns (bool) {
        return
            isCurrentOwner(assetId, owner, marketData, ownershipProof) &&
            isCurrentAssetProps(assetId, assetCID, propsProof);
    }

    /**
    @dev Returns true only if the ownership provided is correct against the last ownership root stored.
        - if marketDataNeverTraded(marketData) == true (asset has never been included in the ownership tree)
            - it first verifies that it's not in the tree (the leafHash is bytes(0x0))
            - it then verifies that "owner" is the default owner
        - if marketDataNeverTraded(marketData) == false (asset must be included in the ownership tree)
            - it only verifies owner == current onwer stored in the ownership tree
        Once an asset is traded once, marketDataNeverTraded remains false forever.
        If asset has been exported, this function returns false; ownership needs to be queried in the external ERC721 contract.
    */
    function isCurrentOwner(
        uint256 assetId,
        address owner,
        bytes memory marketData,
        bytes memory proof
    ) public view returns (bool) {
        (, , uint256 completedVerse) = _storage.exportRequestInfo(assetId);
        if (completedVerse > 0) return false;
        return
            isOwnerInOwnershipRoot(
                currentSettledOwnershipRoot(),
                assetId,
                owner,
                marketData,
                proof
            );
    }

    /**
    @dev Identical to isCurrentOwner, but referring to Onwership root at a previous verse 
    */
    function wasOwnerAtVerse(
        uint256 verse,
        uint256 assetId,
        address owner,
        bytes memory marketData,
        bytes memory proof
    ) public view returns (bool) {
        (, , uint256 completedVerse) = _storage.exportRequestInfo(assetId);
        if (completedVerse > 0 && completedVerse <= verse) return false;
        return
            isOwnerInOwnershipRoot(
                _storage.ownershipRootAtVerse(verse),
                assetId,
                owner,
                marketData,
                proof
            );
    }

    /**
    @dev Unpacks inputs and calls isCurrentOwner 
    */
    function isCurrentOwnerSerialized(bytes memory data)
        public
        view
        returns (bool)
    {
        return
            isCurrentOwner(
                ownAssetId(data),
                ownOwner(data),
                ownMarketData(data),
                ownProof(data)
            );
    }

    /**
    @dev Unpacks inputs and calls wasOwnerAtVerse 
    */
    function wasOwnerAtVerseSerialized(uint256 verse, bytes memory data)
        public
        view
        returns (bool)
    {
        return
            wasOwnerAtVerse(
                verse,
                ownAssetId(data),
                ownOwner(data),
                ownMarketData(data),
                ownProof(data)
            );
    }

    /**
    @dev Returns true only if assetProps are as provided, verified against current Universe root.
    */
    function isCurrentAssetProps(
        uint256 assetId,
        string memory assetCID,
        bytes memory proof
    ) public view returns (bool) {
        return
            isAssetPropsInUniverseRoot(
                _storage.universeRootCurrent(decodeUniverseIdx(assetId)),
                proof,
                assetId,
                assetCID
            );
    }

    /**
    @dev Returns true only if assetProps were as provided, verified against Universe root at provided verse.
    */
    function wasAssetPropsAtVerse(
        uint256 assetId,
        uint256 verse,
        string memory assetCID,
        bytes memory proof
    ) public view returns (bool) {
        return
            isAssetPropsInUniverseRoot(
                _storage.universeRootAtVerse(decodeUniverseIdx(assetId), verse),
                proof,
                assetId,
                assetCID
            );
    }

    /**
    @dev Returns the last Ownership root that is fully settled (there could be one still in challenge process)
    */
    function currentSettledOwnershipRoot() public view returns (bytes32) {
        (bool isReady, uint8 actualLevel) = isReadyForTXSubmission();
        return
            isReady
                ? _storage.challengesOwnershipRoot(actualLevel - 1)
                : _storage.ownershipRootCurrent();
    }

    /**
     * @dev Computes if the system is ready to accept a new TX Batch submission
     *      Gets data from storage and passes to a pure function.
     */
    function isReadyForTXSubmission()
        public
        view
        returns (bool isReady, uint8 actualLevel)
    {
        (isReady, actualLevel) = isReadyForTXSubmissionPure(
            _storage.nTXsCurrent(),
            _storage.txRootsCurrentVerse(),
            _storage.ownershipSubmissionTimeCurrent(),
            _storage.challengeWindowCurrent(),
            _storage.txSubmissionTimeCurrent(),
            block.timestamp,
            _storage.challengesLevel()
        );
        isReady =
            isReady &&
            (plannedTime(
                _storage.txRootsCurrentVerse() + 1,
                _storage.referenceVerse(),
                _storage.referenceTime(),
                _storage.verseInterval()
            ) < block.timestamp);
    }

    function plannedTime(
        uint256 verse,
        uint256 referenceVerse,
        uint256 referenceTime,
        uint256 verseInterval
    ) public pure returns (uint256) {
        return referenceTime + (verse - referenceVerse) * verseInterval;
    }

    /**
    @dev The system is ready for challenge if and only if the current ownership root is not settled
    */
    function isReadyForChallenge() public view returns (bool) {
        (bool isSettled, , ) = computeChallStatus(
            _storage.nTXsCurrent(),
            block.timestamp,
            _storage.txSubmissionTimeCurrent(),
            _storage.ownershipSubmissionTimeCurrent(),
            _storage.challengeWindowCurrent(),
            _storage.challengesLevel()
        );
        return !isSettled;
    }

    /**
    * @dev Returns the status of the current challenge taking into account the time passed,
           so that the actual level can be less than explicitly written, or just settled.
    */
    function getCurrentChallengeStatus()
        public
        view
        returns (
            bool isSettled,
            uint8 actualLevel,
            uint8 nJumps
        )
    {
        return
            computeChallStatus(
                _storage.nTXsCurrent(),
                block.timestamp,
                _storage.txSubmissionTimeCurrent(),
                _storage.ownershipSubmissionTimeCurrent(),
                _storage.challengeWindowCurrent(),
                _storage.challengesLevel()
            );
    }

    /**
    @dev Returns true if asset export has been required with enough time
         This function requires both the assetId and the owner as inputs, because an asset is blocked
         only if the owner coincides with the address that made the request earlier.
    */
    function isAssetBlockedByExport(uint256 assetId, address owner)
        public
        view
        returns (bool)
    {
        (
            address requestOwner,
            uint256 requestVerse,
            uint256 completedVerse
        ) = _storage.exportRequestInfo(assetId);
        if (completedVerse > 0) return true; // already fully exported
        if (requestOwner == address(0)) return false; // no request entry
        if (owner != requestOwner) return false; // a previous owner had requested, but not completed, the export; current owner is free to operate with it
        // finally: make sure the request arrived, at least, one verse ago.
        return (_storage.ownershipCurrentVerse() > requestVerse);
    }

    /**
     * @dev Simple getter for block.timestamp
     */
    function getNow() public view returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Main storage getters
*/

import "../storage/StorageBase.sol";

contract StorageGetters is StorageBase {
    modifier onlyCompany() {
        require(msg.sender == company(), "Only company is authorized.");
        _;
    }

    modifier onlySuperUser() {
        require(msg.sender == superUser(), "Only superUser is authorized.");
        _;
    }

    modifier onlyUniversesRelayer() {
        require(
            msg.sender == universesRelayer(),
            "Only relayer of universes is authorized."
        );
        _;
    }

    modifier onlyTXRelayer() {
        require(
            msg.sender == txRelayer(),
            "Only relayer of TXs is authorized."
        );
        _;
    }

    modifier onlyWriterContract() {
        require(msg.sender == writer(), "Only updates contract is authorized.");
        _;
    }

    modifier onlyAssetExporterContract() {
        require(
            msg.sender == assetExporter(),
            "Only assetExporter contract is authorized."
        );
        _;
    }

    // UNIVERSE
    function universeOwner(uint256 universeIdx) public view returns (address) {
        return _universes[universeIdx].owner;
    }

    function universeName(uint256 universeIdx)
        public
        view
        returns (string memory)
    {
        return _universes[universeIdx].name;
    }

    function universeBaseURI(uint256 universeIdx)
        public
        view
        returns (string memory)
    {
        return _universes[universeIdx].baseURI;
    }

    function universeVerse(uint256 universeIdx) public view returns (uint256) {
        return _universes[universeIdx].roots.length - 1;
    }

    function universeRootAtVerse(uint256 universeIdx, uint256 verse)
        public
        view
        returns (bytes32)
    {
        return _universes[universeIdx].roots[verse];
    }

    function universeRootCurrent(uint256 universeIdx)
        public
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
    ) public view returns (uint256) {
        return _universes[universeIdx].rootsSubmissionTimes[verse];
    }

    function universeRootSubmissionTimeCurrent(uint256 universeIdx)
        public
        view
        returns (uint256)
    {
        return
            _universes[universeIdx].rootsSubmissionTimes[
                _universes[universeIdx].rootsSubmissionTimes.length - 1
            ];
    }

    function universeIsClosed(uint256 universeIdx) public view returns (bool) {
        return _universes[universeIdx].closureConfirmed;
    }

    function universeIsClosureRequested(uint256 universeIdx)
        public
        view
        returns (bool)
    {
        return _universes[universeIdx].closureRequested;
    }

    // OWNERSHIP
    // - Global variables
    function challengeWindowNextVerses() public view returns (uint256) {
        return _challengeWindowNextVerses;
    }

    function nLevelsPerChallengeNextVerses() public view returns (uint8) {
        return _nLevelsPerChallengeNextVerses;
    }

    function maxTimeWithoutVerseProduction() public view returns (uint256) {
        return _maxTimeWithoutVerseProduction;
    }

    function exportRequestInfo(uint256 assetId)
        public
        view
        returns (
            address owner,
            uint256 requestVerse,
            uint256 completedVerse
        )
    {
        ExportRequest memory request = _exportRequests[assetId];
        return (request.owner, request.requestVerse, request.completedVerse);
    }

    // - TXBatches and Ownership data: get current verse
    function ownershipCurrentVerse() public view returns (uint256) {
        return _ownerships.length - 1;
    }

    function txRootsCurrentVerse() public view returns (uint256) {
        return _txBatches.length - 1;
    }

    // - TXBatches interval time info
    function referenceVerse() public view returns (uint256) {
        return _referenceVerse;
    }

    function referenceTime() public view returns (uint256) {
        return _referenceTime;
    }

    function verseInterval() public view returns (uint256) {
        return _verseInterval;
    }

    // - TXBatches and Ownership data: queries at a given verse
    function ownershipRootAtVerse(uint256 verse) public view returns (bytes32) {
        return _ownerships[verse].root;
    }

    function txRootAtVerse(uint256 verse) public view returns (bytes32) {
        return _txBatches[verse].root;
    }

    function nLevelsPerChallengeAtVerse(uint256 verse)
        public
        view
        returns (uint8)
    {
        return _txBatches[verse].nLevelsPerChallenge;
    }

    function levelVerifiableOnChainAtVerse(uint256 verse)
        public
        view
        returns (uint8)
    {
        return _txBatches[verse].levelVerifiableOnChain;
    }

    function nTXsAtVerse(uint256 verse) public view returns (uint256) {
        return _txBatches[verse].nTXs;
    }

    function challengeWindowAtVerse(uint256 verse)
        public
        view
        returns (uint256)
    {
        return _txBatches[verse].challengeWindow;
    }

    function txSubmissionTimeAtVerse(uint256 verse)
        public
        view
        returns (uint256)
    {
        return _txBatches[verse].submissionTime;
    }

    function ownershipSubmissionTimeAtVerse(uint256 verse)
        public
        view
        returns (uint256)
    {
        return _ownerships[verse].submissionTime;
    }

    // - TXBatches and Ownership data: queries about most recent entry
    function ownershipRootCurrent() public view returns (bytes32) {
        return _ownerships[_ownerships.length - 1].root;
    }

    function txRootCurrent() public view returns (bytes32) {
        return _txBatches[_txBatches.length - 1].root;
    }

    function nLevelsPerChallengeCurrent() public view returns (uint8) {
        return _txBatches[_txBatches.length - 1].nLevelsPerChallenge;
    }

    function levelVerifiableOnChainCurrent() public view returns (uint8) {
        return _txBatches[_txBatches.length - 1].levelVerifiableOnChain;
    }

    function nTXsCurrent() public view returns (uint256) {
        return _txBatches[_txBatches.length - 1].nTXs;
    }

    function challengeWindowCurrent() public view returns (uint256) {
        return _txBatches[_txBatches.length - 1].challengeWindow;
    }

    function txSubmissionTimeCurrent() public view returns (uint256) {
        return _txBatches[_txBatches.length - 1].submissionTime;
    }

    function ownershipSubmissionTimeCurrent() public view returns (uint256) {
        return _ownerships[_ownerships.length - 1].submissionTime;
    }

    // CHALLENGES
    function challengesOwnershipRoot(uint8 level)
        public
        view
        returns (bytes32)
    {
        return _challenges[level].ownershipRoot;
    }

    function challengesTransitionsRoot(uint8 level)
        public
        view
        returns (bytes32)
    {
        return _challenges[level].transitionsRoot;
    }

    function challengesRootAtEdge(uint8 level) public view returns (bytes32) {
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

    function computeBottomLevelLeafPos(uint256 finalTransEndPos)
        public
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
    function company() public view returns (address) {
        return _company;
    }

    function proposedCompany() public view returns (address) {
        return _proposedCompany;
    }

    function superUser() public view returns (address) {
        return _superUser;
    }

    function universesRelayer() public view returns (address) {
        return _universesRelayer;
    }

    function txRelayer() public view returns (address) {
        return _txRelayer;
    }

    function stakers() public view returns (address) {
        return _stakers;
    }

    function writer() public view returns (address) {
        return _writer;
    }

    function directory() public view returns (address) {
        return _directory;
    }

    function externalNFTContract() public view returns (address) {
        return _externalNFTContract;
    }

    function assetExporter() public view returns (address) {
        return _assetExporter;
    }

    // CLAIMS
    function claim(uint256 claimIdx, uint256 key)
        public
        view
        returns (uint256 verse, string memory value)
    {
        Claim memory c = _claims[claimIdx][key];
        return (c.verse, c.value);
    }

    function nClaims() public view returns (uint256 len) {
        return _claims.length;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Declaration of all storage variables
*/

contract StorageBase {
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
    struct Universe {
        address owner;
        string name;
        string baseURI;
        bytes32[] roots;
        uint256[] rootsSubmissionTimes;
        bool closureRequested;
        bool closureConfirmed;
    }

    // OWNERSHIP
    // A Transaction Batch containing requests to update Ownership tree accordingly
    // It stores the data required to govern a potential challenge process
    TXBatch[] internal _txBatches;
    struct TXBatch {
        bytes32 root;
        uint256 submissionTime;
        uint256 nTXs;
        uint8 levelVerifiableOnChain;
        uint8 nLevelsPerChallenge;
        uint256 challengeWindow;
    }

    // OWNERSHIP
    // Ownership is stored as a 256-level Sparse Merkle Tree where each leaf is labeled by assetId
    Ownership[] internal _ownerships;
    struct Ownership {
        // The settled ownership Roots, one per verse
        bytes32 root;
        // The submission timestamp upon reception of a new ownershipRoot,
        // or the lasttime the corresponding challenge was updated.
        uint256 submissionTime;
    }

    // CHALLENGES
    Challenge[] internal _challenges;
    struct Challenge {
        bytes32 ownershipRoot;
        bytes32 transitionsRoot;
        bytes32 rootAtEdge;
        uint256 pos;
    }

    // ASSET EXPORT
    // Data stored when an owner requests an asset to be stored as a standard NFT
    mapping(uint256 => ExportRequest) internal _exportRequests;
    struct ExportRequest {
        address owner;
        uint256 requestVerse;
        uint256 completedVerse;
    }

    // Future usage
    mapping(uint256 => Claim)[] internal _claims;
    struct Claim {
        uint256 verse;
        string value;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Responsible for all storage, including upgrade pointers to external contracts to mange updates/challenges 
*/

import "./RolesSetters.sol";

contract Storage is RolesSetters {
    event NewChallengeWindow(uint256 newTime);
    event CreateUniverse(
        uint256 universeIdx,
        address owner,
        string name,
        string baseURI
    );
    event RequestAssetExport(
        uint256 assetId,
        address owner,
        uint256 currentVerse
    );
    event CompleteAssetExport(
        uint256 assetId,
        address owner,
        uint256 currentVerse
    );
    event NewTXBatchReference(
        uint256 refVerse,
        uint256 refTime,
        uint256 vInterval
    );

    constructor(address company, address superUser) {
        // Setup main roles:
        _company = company;
        _superUser = superUser;

        // Setup main global variables:
        _nLevelsPerChallengeNextVerses = 4;
        _maxTimeWithoutVerseProduction = 604800; // 1 week
        _setInitialTXBatchReference();

        // Initialize with null TXBatch and null Ownership Root
        _txBatches.push(TXBatch(bytes32(0x0), 0, 0, 3, 4, 0));
        _ownerships.push(Ownership(bytes32(0x0), 1));
        _challenges.push(
            Challenge(bytes32(0x0), bytes32(0x0), bytes32(0x0), 0)
        );
    }

    function _setInitialTXBatchReference() private {
        _referenceVerse = 1;
        _verseInterval = 15 * 60;
        _referenceTime =
            block.timestamp +
            _verseInterval -
            (block.timestamp % _verseInterval);
    }

    /**
     * @dev Setters for the global variables
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

    function setLevelsPerChallengeNextVerses(uint8 value)
        external
        onlySuperUser
    {
        _nLevelsPerChallengeNextVerses = value;
    }

    function setChallengeWindowNextVerses(uint256 newTime)
        external
        onlySuperUser
    {
        _challengeWindowNextVerses = newTime;
        emit NewChallengeWindow(newTime);
    }

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
    * @dev Universes are created with an empty initial root.
           The baseURI will be concatenated with assetID without any character in between
           So make sure that baseURI ends in forward slash character '/' if needed.
    */
    function createUniverse(
        uint256 universeIdx,
        address owner,
        string calldata name,
        string calldata baseURI
    ) external onlySuperUser {
        // Redundancy check that request matches metaverse state, to help avoid universes created unnecessarily
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
                baseURI,
                initRootArray,
                initRootTimeStamp,
                false,
                false
            )
        );
        emit CreateUniverse(universeIdx, owner, name, baseURI);
    }

    function changeUniverseClosure(
        uint256 universeIdx,
        bool closureRequested,
        bool closureConfirmed
    ) external onlyWriterContract {
        _universes[universeIdx].closureRequested = closureRequested;
        _universes[universeIdx].closureConfirmed = closureConfirmed;
    }

    function changeUniverseName(uint256 universeIdx, string calldata name)
        external
        onlySuperUser
    {
        require(universeIdx < nUniverses(), "universeIdx does not exist");
        _universes[universeIdx].name = name;
    }

    function changeUniverseBaseURI(uint256 universeIdx, string calldata baseURI)
        external
        onlyAssetExporterContract
    {
        require(universeIdx < nUniverses(), "universeIdx does not exist");
        _universes[universeIdx].baseURI = baseURI;
    }

    function addUniverseRoot(
        uint256 universeIdx,
        bytes32 newRoot,
        uint256 submissionTime
    ) external onlyWriterContract returns (uint256 verse) {
        _universes[universeIdx].roots.push(newRoot);
        _universes[universeIdx].rootsSubmissionTimes.push(submissionTime);
        return _universes[universeIdx].roots.length - 1;
    }

    /**
    * @dev TXs are added in batches. When adding a new batch, the ownership root settled in the previous verse
           is settled, by copying from the challenge struct to the last ownership entry.
    */
    function addTXRoot(
        bytes32 root,
        uint256 submissionTime,
        uint256 nTXs,
        uint8 actualLevel,
        uint8 levelVeriableByBC
    ) external onlyWriterContract returns (uint256 txVerse) {
        // Settle previously open for challenge root:
        _ownerships[_ownerships.length - 1].root = challengesOwnershipRoot(
            actualLevel - 1
        );

        // Add a new TX Batch:
        _txBatches.push(
            TXBatch(
                root,
                submissionTime,
                nTXs,
                levelVeriableByBC,
                _nLevelsPerChallengeNextVerses,
                _challengeWindowNextVerses
            )
        );
        delete _challenges;
        return _txBatches.length - 1;
    }

    /**
    * @dev A new ownership root, ready for challenge is received.
           Registers timestamp of reception, creates challenge and it
           either appends to _ownerships, or rewrites last entry, depending on
           whether it corresponds to a new verse, or it results from a challenge
           to the current verse. 
           The latter can happen when the challenge game moved tacitly to level 0.
    */
    function receiveNewOwnershipRoot(
        bytes32 ownershipRoot,
        uint256 submissionTime
    ) external onlyWriterContract returns (uint256 ownVerse) {
        if (challengesLevel() > 0) {
            // Challenge game had moved tacitly to level 0: rewrite
            delete _challenges;
            _ownerships[_ownerships.length - 1].submissionTime = block
                .timestamp;
        } else {
            // Challenge finished and ownership settled: create ownership struct for new verse
            _ownerships.push(Ownership(bytes32(0x0), submissionTime));
        }
        // A new challenge is born to store the submitted ownershipRoot, with no info about transitionsRoot (set to bytes32(0))
        _challenges.push(Challenge(ownershipRoot, bytes32(0), bytes32(0x0), 0));
        return _ownerships.length - 1;
    }

    function setLastOwnershipSubmissionTime(uint256 value)
        external
        onlyWriterContract
    {
        _ownerships[_ownerships.length - 1].submissionTime = value;
    }

    /**
     * @dev Challenges setters
     */

    function storeChallenge(
        bytes32 ownershipRoot,
        bytes32 transitionsRoot,
        bytes32 rootAtEdge,
        uint256 pos
    ) external onlyWriterContract {
        _challenges.push(
            Challenge(ownershipRoot, transitionsRoot, rootAtEdge, pos)
        );
    }

    function popChallengeDataToLevel(uint8 actualLevel)
        external
        onlyWriterContract
    {
        uint8 currentLevel = challengesLevel();
        require(
            currentLevel > actualLevel,
            "cannot pop unless final level is lower than current level"
        );
        for (uint8 n = 0; n < (currentLevel - actualLevel); n++) {
            _challenges.pop();
        }
    }

    /**
    * @dev Asset export setters
           First step: create an export request. Second step: complete export
    */
    function createExportRequest(uint256 assetId, address owner)
        external
        onlyAssetExporterContract
    {
        ExportRequest memory request = _exportRequests[assetId];
        require(
            request.completedVerse == 0,
            "createExportRequest: asset already exported"
        );
        uint256 currentVerse = ownershipCurrentVerse();
        _exportRequests[assetId] = ExportRequest(owner, currentVerse, 0);
        emit RequestAssetExport(assetId, owner, currentVerse);
    }

    function completeAssetExport(uint256 assetId, address owner)
        external
        onlyAssetExporterContract
    {
        ExportRequest memory request = _exportRequests[assetId];
        require(
            request.completedVerse == 0,
            "completeAssetExport: asset already exported"
        );
        require(
            owner == request.owner,
            "completeAssetExport: must be completed by same owner that request it"
        );
        uint256 currentVerse = ownershipCurrentVerse();

        // Export can be completed 2 verses after request.
        // If operations ceased, verses may not continue being processed. In that case,
        // it suffices to wait for time = _maxTimeWithoutVerseProduction
        if (!(currentVerse > request.requestVerse + 1)) {
            uint256 requestTimestamp = txSubmissionTimeAtVerse(
                request.requestVerse
            );
            require(
                block.timestamp > requestTimestamp,
                "completeAssetExport: request time older than current time"
            );
            require(
                block.timestamp >
                    requestTimestamp + _maxTimeWithoutVerseProduction,
                "completeAssetExport: must wait for at least 1 verse fully confirmed, or enough time since export request"
            );
        }
        _exportRequests[assetId].completedVerse = currentVerse;
        emit CompleteAssetExport(assetId, owner, currentVerse);
    }

    // CLAIMS
    function addClaim() external onlySuperUser {
        _claims.push();
    }

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
 @author Freeverse.io, www.freeverse.io
 @dev Setters for all roles
 @dev Company owner should be a multisig. It can basically reset every other role.
*/

import "../storage/StorageGetters.sol";

contract RolesSetters is StorageGetters {
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
 @dev Serialization of data into bytes memory
*/

contract SerializeSettersBase {
    function addToSerialization(
        bytes memory serialized,
        bytes memory s,
        uint256 counter
    ) public pure returns (uint256 newCounter) {
        for (uint256 i = 0; i < s.length; i++) {
            serialized[counter] = s[i];
            counter++;
        }
        return counter++;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev DeSerialization of data into bytes memory
*/

import "./SerializeBase.sol";

contract SerializeOwnershipGet is SerializeBase {
    function ownAssetId(bytes memory serialized)
        public
        pure
        returns (uint256 assetId)
    {
        assembly {
            assetId := mload(add(serialized, 40))
        }
    }

    function ownOwner(bytes memory serialized)
        public
        pure
        returns (address owner)
    {
        assembly {
            owner := mload(add(serialized, 60))
        }
    }

    function ownMarketData(bytes memory serialized)
        public
        pure
        returns (bytes memory)
    {
        uint32 marketDataLength;
        assembly {
            marketDataLength := mload(add(serialized, 4))
        }
        bytes memory marketData = new bytes(marketDataLength);
        for (uint32 i = 0; i < marketDataLength; i++) {
            marketData[i] = serialized[60 + i];
        }
        return marketData;
    }

    function ownProof(bytes memory serialized)
        public
        pure
        returns (bytes memory)
    {
        uint32 marketDataLength;
        assembly {
            marketDataLength := mload(add(serialized, 4))
        }
        uint32 proofLength;
        assembly {
            proofLength := mload(add(serialized, 8))
        }
        bytes memory proof = new bytes(proofLength);
        for (uint32 i = 0; i < proofLength; i++) {
            proof[i] = serialized[60 + marketDataLength + i];
        }
        return proof;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev DeSerialization of data into bytes memory
*/

import "./SerializeBase.sol";

contract SerializeMerkleGet is SerializeBase {
    // Merkle Proof Getters (for transition proofs, merkle proofs in general)
    function MTPos(bytes memory serialized) public pure returns (uint256 pos) {
        assembly {
            pos := mload(add(serialized, 32))
        }
    }

    function MTLeaf(bytes memory serialized)
        public
        pure
        returns (bytes32 root)
    {
        assembly {
            root := mload(add(serialized, 64))
        } // 8 + 2 * 32
    }

    function MTProof(bytes memory serialized)
        public
        pure
        returns (bytes32[] memory proof)
    {
        // total length = 32 * 2 + 32 * nEntries
        uint32 nEntries = (uint32(serialized.length) - 64) / 32;
        require(
            serialized.length == 32 * 2 + 32 * nEntries,
            "incorrect serialized length"
        );
        return bytesToBytes32ArrayWithoutHeader(serialized, 64, nEntries);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Serialization of data into bytes memory
 @dev ValidUntil and TimeToPay are expressed in units of verse
*/

import "./SerializeSettersBase.sol";

contract SerializeMarketDataSet is SerializeSettersBase {
    function serializeMarketData(
        bytes32 auctionId,
        uint32 validUntil,
        uint32 versesToPay
    ) public pure returns (bytes memory serialized) {
        serialized = new bytes(32 + 4 * 2);
        uint256 counter = 0;
        counter = addToSerialization(
            serialized,
            abi.encodePacked(auctionId),
            counter
        ); // 32
        counter = addToSerialization(
            serialized,
            abi.encodePacked(validUntil),
            counter
        ); // 36
        counter = addToSerialization(
            serialized,
            abi.encodePacked(versesToPay),
            counter
        ); // 40
        return (serialized);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev DeSerialization of data into bytes memory
*/

import "./SerializeBase.sol";

contract SerializeMarketDataGet is SerializeBase {
    function marketDataNeverTraded(bytes memory marketData)
        public
        pure
        returns (bool hasBeenInMarket)
    {
        return marketData.length == 0;
    }

    function marketDataAuctionId(bytes memory marketData)
        public
        pure
        returns (bytes32 auctionId)
    {
        assembly {
            auctionId := mload(add(marketData, 32))
        }
    }

    function marketDataValidUntil(bytes memory marketData)
        public
        pure
        returns (uint32 validUntil)
    {
        assembly {
            validUntil := mload(add(marketData, 36))
        }
    }

    function marketDataTimeToPay(bytes memory marketData)
        public
        pure
        returns (uint32 versesToPay)
    {
        assembly {
            versesToPay := mload(add(marketData, 40))
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev DeSerialization of data into bytes memory
*/

import "./SerializeBase.sol";

contract SerializeFreezeGet is SerializeBase {
    // Transactions Getters

    function freezeTXPosTX(bytes memory serialized)
        public
        pure
        returns (uint256 pos)
    {
        assembly {
            pos := mload(add(serialized, 41))
        } // 1+8 + 32
    }

    function freezeTXSellerHiddenPrice(bytes memory serialized)
        public
        pure
        returns (bytes32 sellerHiddenPrice)
    {
        assembly {
            sellerHiddenPrice := mload(add(serialized, 73))
        } // 1+8 + 2 * 32
    }

    function freezeTXAssetId(bytes memory serialized)
        public
        pure
        returns (uint256 assetId)
    {
        assembly {
            assetId := mload(add(serialized, 105))
        } // 1+8 + 3 *32
    }

    function freezeTXValidUntil(bytes memory serialized)
        public
        pure
        returns (uint32 validUntil)
    {
        assembly {
            validUntil := mload(add(serialized, 109))
        } // + 4
    }

    function freezeTXOfferValidUntil(bytes memory serialized)
        public
        pure
        returns (uint32 offerValidUntil)
    {
        assembly {
            offerValidUntil := mload(add(serialized, 113))
        } // +4
    }

    function freezeTXTimeToPay(bytes memory serialized)
        public
        pure
        returns (uint32 versesToPay)
    {
        assembly {
            versesToPay := mload(add(serialized, 117))
        } // +4
    }

    function freezeTXSellerSig(bytes memory serialized)
        public
        pure
        returns (bytes memory)
    {
        uint32 signatureLength;
        assembly {
            signatureLength := mload(add(serialized, 5))
        }
        bytes memory signature = new bytes(signatureLength);
        for (uint32 i = 0; i < signatureLength; i++) {
            signature[i] = serialized[117 + i];
        }
        return signature;
    }

    function freezeTXProofTX(bytes memory serialized)
        public
        pure
        returns (bytes32[] memory proof)
    {
        uint32 signatureLength;
        assembly {
            signatureLength := mload(add(serialized, 5))
        }
        uint32 nEntries;
        assembly {
            nEntries := mload(add(serialized, 9))
        }
        return
            bytesToBytes32ArrayWithoutHeader(
                serialized,
                117 + signatureLength,
                nEntries
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev DeSerialization of data into bytes memory
*/

import "./SerializeBase.sol";

contract SerializeCompleteGet is SerializeBase {
    // CompleteAucion TX getters

    function complTXAssetPropsVerse(bytes memory serialized)
        public
        pure
        returns (uint256 assetPropsVerse)
    {
        assembly {
            assetPropsVerse := mload(add(serialized, 49))
        }
    }

    function complTXPosTX(bytes memory serialized)
        public
        pure
        returns (uint256 pos)
    {
        assembly {
            pos := mload(add(serialized, 81))
        }
    }

    function complTXAuctionId(bytes memory serialized)
        public
        pure
        returns (bytes32 auctionId)
    {
        assembly {
            auctionId := mload(add(serialized, 113))
        }
    }

    function complTXAssetId(bytes memory serialized)
        public
        pure
        returns (uint256 assetId)
    {
        assembly {
            assetId := mload(add(serialized, 145))
        }
    }

    function complTXBuyerHiddenPrice(bytes memory serialized)
        public
        pure
        returns (bytes32 buyerHiddenPrice)
    {
        assembly {
            buyerHiddenPrice := mload(add(serialized, 177))
        }
    }

    function complTXAssetCID(bytes memory serialized)
        public
        pure
        returns (string memory assetCID)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        bytes memory assetCIDbytes = new bytes(assetCIDlen);
        for (uint32 i = 0; i < assetCIDlen; i++) {
            assetCIDbytes[i] = serialized[177 + i];
        }
        return string(assetCIDbytes);
    }

    function complTXProofProps(bytes memory serialized)
        public
        pure
        returns (bytes memory)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        uint32 proofPropsLen;
        assembly {
            proofPropsLen := mload(add(serialized, 9))
        }

        bytes memory proofProps = new bytes(proofPropsLen);
        for (uint32 i = 0; i < proofPropsLen; i++) {
            proofProps[i] = serialized[177 + assetCIDlen + i];
        }
        return proofProps;
    }

    function complTXBuyerSig(bytes memory serialized)
        public
        pure
        returns (bytes memory)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        uint32 proofPropsLen;
        assembly {
            proofPropsLen := mload(add(serialized, 9))
        }
        uint32 sigLength;
        assembly {
            sigLength := mload(add(serialized, 13))
        }
        bytes memory signature = new bytes(sigLength);
        for (uint32 i = 0; i < sigLength; i++) {
            signature[i] = serialized[177 + assetCIDlen + proofPropsLen + i];
        }
        return signature;
    }

    function complTXProofTX(bytes memory serialized)
        public
        pure
        returns (bytes32[] memory proof)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        uint32 proofPropsLen;
        assembly {
            proofPropsLen := mload(add(serialized, 9))
        }
        uint32 sigLength;
        assembly {
            sigLength := mload(add(serialized, 13))
        }
        uint32 nEntries;
        assembly {
            nEntries := mload(add(serialized, 17))
        }
        return
            bytesToBytes32ArrayWithoutHeader(
                serialized,
                177 + assetCIDlen + proofPropsLen + sigLength,
                nEntries
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev DeSerialization of data into bytes memory
*/

import "./SerializeBase.sol";

contract SerializeBuyNowGet is SerializeBase {
    // CompleteAucion TX getters

    function buyNowTXAssetPropsVerse(bytes memory serialized)
        public
        pure
        returns (uint256 assetPropsVerse)
    {
        assembly {
            assetPropsVerse := mload(add(serialized, 53))
        }
    }

    function buyNowTXPosTX(bytes memory serialized)
        public
        pure
        returns (uint256 pos)
    {
        assembly {
            pos := mload(add(serialized, 85))
        }
    }

    function buyNowTXValidUntil(bytes memory serialized)
        public
        pure
        returns (uint32 validUntil)
    {
        assembly {
            validUntil := mload(add(serialized, 89))
        }
    }

    function buyNowTXAssetId(bytes memory serialized)
        public
        pure
        returns (uint256 assetId)
    {
        assembly {
            assetId := mload(add(serialized, 121))
        }
    }

    function buyNowTXHiddenPrice(bytes memory serialized)
        public
        pure
        returns (bytes32 buyerHiddenPrice)
    {
        assembly {
            buyerHiddenPrice := mload(add(serialized, 153))
        }
    }

    function buyNowTXAssetCID(bytes memory serialized)
        public
        pure
        returns (string memory assetCID)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        bytes memory assetCIDbytes = new bytes(assetCIDlen);
        for (uint32 i = 0; i < assetCIDlen; i++) {
            assetCIDbytes[i] = serialized[153 + i];
        }
        return string(assetCIDbytes);
    }

    function buyNowTXProofProps(bytes memory serialized)
        public
        pure
        returns (bytes memory)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        uint32 proofPropsLen;
        assembly {
            proofPropsLen := mload(add(serialized, 9))
        }

        bytes memory proofProps = new bytes(proofPropsLen);
        for (uint32 i = 0; i < proofPropsLen; i++) {
            proofProps[i] = serialized[153 + assetCIDlen + i];
        }
        return proofProps;
    }

    function buyNowTXSellerSig(bytes memory serialized)
        public
        pure
        returns (bytes memory)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        uint32 proofPropsLen;
        assembly {
            proofPropsLen := mload(add(serialized, 9))
        }
        uint32 sellerSigLength;
        assembly {
            sellerSigLength := mload(add(serialized, 13))
        }
        bytes memory signature = new bytes(sellerSigLength);
        for (uint32 i = 0; i < sellerSigLength; i++) {
            signature[i] = serialized[153 + assetCIDlen + proofPropsLen + i];
        }
        return signature;
    }

    function buyNowTXBuyerSig(bytes memory serialized)
        public
        pure
        returns (bytes memory)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        uint32 proofPropsLen;
        assembly {
            proofPropsLen := mload(add(serialized, 9))
        }
        uint32 sellerSigLength;
        assembly {
            sellerSigLength := mload(add(serialized, 13))
        }
        uint32 buyerSigLength;
        assembly {
            buyerSigLength := mload(add(serialized, 17))
        }
        bytes memory signature = new bytes(buyerSigLength);
        uint32 offset = 153 + assetCIDlen + proofPropsLen + sellerSigLength;
        for (uint32 i = 0; i < buyerSigLength; i++) {
            signature[i] = serialized[offset + i];
        }
        return signature;
    }

    function buyNowTXProofTX(bytes memory serialized)
        public
        pure
        returns (bytes32[] memory proof)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        uint32 proofPropsLen;
        assembly {
            proofPropsLen := mload(add(serialized, 9))
        }
        uint32 sellerSigLength;
        assembly {
            sellerSigLength := mload(add(serialized, 13))
        }
        uint32 buyerSigLength;
        assembly {
            buyerSigLength := mload(add(serialized, 17))
        }
        uint32 nEntries;
        assembly {
            nEntries := mload(add(serialized, 21))
        }
        uint32 offset = 153 +
            assetCIDlen +
            proofPropsLen +
            sellerSigLength +
            buyerSigLength;
        return bytesToBytes32ArrayWithoutHeader(serialized, offset, nEntries);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev DeSerialization of data into bytes memory
*/

contract SerializeBase {
    // For all types of txs you always start with 1 byte for tx type:
    function txGetType(bytes memory serialized)
        public
        pure
        returns (uint8 txType)
    {
        assembly {
            txType := mload(add(serialized, 1))
        }
    }

    function bytesToBytes32ArrayWithoutHeader(
        bytes memory input,
        uint256 offset,
        uint32 nEntries
    ) public pure returns (bytes32[] memory) {
        bytes32[] memory output = new bytes32[](nEntries);

        for (uint32 p = 0; p < nEntries; p++) {
            offset += 32;
            bytes32 thisEntry;
            assembly {
                thisEntry := mload(add(input, offset))
            }
            output[p] = thisEntry;
        }
        return output;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev DeSerialization of data into bytes memory
*/

import "./SerializeBase.sol";

contract SerializeAssetPropsGet is SerializeBase {
    function assetPropsPos(bytes memory assetProps)
        public
        pure
        returns (uint256 pos)
    {
        assembly {
            pos := mload(add(assetProps, 32))
        }
    }

    function assetPropsProof(bytes memory assetProps)
        public
        pure
        returns (bytes32[] memory proof)
    {
        if (assetProps.length == 0) return new bytes32[](0);
        // Length must be a multiple of 32, and less than 2**32.
        require(
            (assetProps.length >= 32) && (assetProps.length < 4294967296),
            "assetProps length beyond boundaries"
        );
        // total length = 32 + 32 * nEntries
        uint32 nEntries = (uint32(assetProps.length) - 32) / 32;
        require(
            assetProps.length == 32 + 32 * nEntries,
            "incorrect assetProps length"
        );
        return bytesToBytes32ArrayWithoutHeader(assetProps, 32, nEntries);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Sparse Merkle Tree functions
*/

contract SparseMerkleTree {
    function updateRootFromProof(
        bytes32 leaf,
        uint256 _index,
        uint256 depth,
        bytes memory proof
    ) public pure returns (bytes32) {
        require(depth <= 256, "depth cannot be larger than 256");
        uint256 p = (depth % 8) == 0 ? depth / 8 : depth / 8 + 1; // length of trail in bytes = ceil( depth // 8 )
        require(
            (proof.length - p) % 32 == 0 && proof.length <= 8224,
            "invalid proof format"
        ); // 8224 = 32 * 256 + 32
        bytes32 proofElement;
        bytes32 computedHash = leaf;
        uint256 proofBits;
        uint256 index = _index;
        assembly {
            proofBits := div(mload(add(proof, 32)), exp(256, sub(32, p)))
        } // 32-p is number of bytes to shift

        for (uint256 d = 0; d < depth; d++) {
            if (proofBits % 2 == 0) {
                // check if last bit of proofBits is 0
                proofElement = 0;
            } else {
                p += 32;
                require(proof.length >= p, "proof not long enough");
                assembly {
                    proofElement := mload(add(proof, p))
                }
            }
            if (computedHash == 0 && proofElement == 0) {
                computedHash = 0;
            } else if (index % 2 == 0) {
                assembly {
                    mstore(0, computedHash)
                    mstore(0x20, proofElement)
                    computedHash := keccak256(0, 0x40)
                }
            } else {
                assembly {
                    mstore(0, proofElement)
                    mstore(0x20, computedHash)
                    computedHash := keccak256(0, 0x40)
                }
            }
            proofBits = proofBits / 2; // shift it right for next bit
            index = index / 2;
        }
        return computedHash;
    }

    function SMTVerify(
        bytes32 expectedRoot,
        bytes32 leaf,
        uint256 _index,
        uint256 depth,
        bytes memory proof
    ) public pure returns (bool) {
        return expectedRoot == updateRootFromProof(leaf, _index, depth, proof);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Pure library to recover address from signatures and add the Eth prefix
*/

contract Messages {
    // FUNCTIONS FOR SIGNATURE MANAGEMENT

    // retrieves the addr that signed a message
    function recoverAddrFromBytes(bytes32 msgHash, bytes memory sig)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return address(0x0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0);
        }
        return ecrecover(msgHash, v, r, s);
    }

    // retrieves the addr that signed a message
    function recoverAddr(
        bytes32 msgHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        return ecrecover(msgHash, v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Base functions for Standard Merkle Trees
*/

contract MerkleTreeBase {
    bytes32 constant NULL_BYTES32 = bytes32(0);

    function hash_node(bytes32 left, bytes32 right)
        public
        pure
        returns (bytes32 hash)
    {
        if ((right == NULL_BYTES32) && (left == NULL_BYTES32))
            return NULL_BYTES32;
        assembly {
            mstore(0x00, left)
            mstore(0x20, right)
            hash := keccak256(0x00, 0x40)
        }
        return hash;
    }

    function buildProof(
        uint256 leafPos,
        bytes32[] memory leaves,
        uint256 nLevels
    ) public pure returns (bytes32[] memory proof) {
        if (nLevels == 0) {
            require(
                leaves.length == 1,
                "buildProof: leaves length must be 0 if nLevels = 0"
            );
            require(
                leafPos == 0,
                "buildProof: leafPos must be 0 if there is only one leaf"
            );
            return proof; // returns the empty array []
        }
        uint256 nLeaves = 2**nLevels;
        require(
            leaves.length == nLeaves,
            "number of leaves is not = pow(2,nLevels)"
        );
        proof = new bytes32[](nLevels);
        // The 1st element is just its pair
        proof[0] = ((leafPos % 2) == 0)
            ? leaves[leafPos + 1]
            : leaves[leafPos - 1];
        // The rest requires computing all hashes
        for (uint8 level = 0; level < nLevels - 1; level++) {
            nLeaves /= 2;
            leafPos /= 2;
            for (uint256 pos = 0; pos < nLeaves; pos++) {
                leaves[pos] = hash_node(leaves[2 * pos], leaves[2 * pos + 1]);
            }
            proof[level + 1] = ((leafPos % 2) == 0)
                ? leaves[leafPos + 1]
                : leaves[leafPos - 1];
        }
    }

    /**
    * @dev 
        if nLevel = 0, there is one single leaf, corresponds to an empty proof
        if nLevels = 1, we need 1 element in the proof array
        if nLevels = 2, we need 2 elements...
            .
            ..   ..
        .. .. .. ..
        01 23 45 67
    */
    function MTVerify(
        bytes32 root,
        bytes32[] memory proof,
        bytes32 leafHash,
        uint256 leafPos
    ) public pure returns (bool) {
        for (uint32 pos = 0; pos < proof.length; pos++) {
            if ((leafPos % 2) == 0) {
                leafHash = hash_node(leafHash, proof[pos]);
            } else {
                leafHash = hash_node(proof[pos], leafHash);
            }
            leafPos /= 2;
        }
        return root == leafHash;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Interface to MerkleTreeVerify that unpacks serialized inputs before calling it
*/

import "../pure/Merkle.sol";
import "../pure/serialization/SerializeMerkleGet.sol";

contract MerkleSerialized is Merkle, SerializeMerkleGet {
    /**
    @dev
         MTData serializes the leaf, its position, and the proof that it belongs to a tree
         MTVerifySerialized returns true if such tree has root that coincides with the provided root.
    */
    function MTVerifySerialized(bytes32 root, bytes memory MTData)
        public
        pure
        returns (bool)
    {
        return MTVerify(root, MTProof(MTData), MTLeaf(MTData), MTPos(MTData));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Computation of Root in Standard Merkle Tree
 @dev Version that does not overwrite the input leaves
*/

import "../pure/MerkleTreeBase.sol";

contract Merkle is MerkleTreeBase {
    /**
    * @dev 
        If it is called with nLeaves != 2**nLevels, then it behaves as if zero-padded to 2**nLevels
        If it is called with nLeaves != 2**nLevels, then it behaves as if zero-padded to 2**nLevels
        Assumed convention:
        nLeaves = 1, nLevels = 0, there is one leaf, which coincides with the root
        nLeaves = 2, nLevels = 1, the root is the hash of both leaves
        nLeaves = 4, nLevels = 2, ...
    */
    function merkleRoot(bytes32[] memory leaves, uint256 nLevels)
        public
        pure
        returns (bytes32)
    {
        if (nLevels == 0) return leaves[0];
        uint256 nLeaves = 2**nLevels;
        require(
            nLeaves >= leaves.length,
            "merkleRoot: not enough levels given the number of leaves"
        );

        /**
        * @dev 
            instead of reusing the leaves array entries to store hashes leaves,
            create a half-as-long array (_leaves) for that purpose, to avoid modifying
            the input array. Solidity passes-by-reference when the function is in the same contract)
            and passes-by-value when calling a function in an external contract
        */
        bytes32[] memory _leaves = new bytes32[](nLeaves);

        // level = 0 uses the original leaves:
        nLeaves /= 2;
        uint256 nLeavesNonNull = (leaves.length % 2 == 0)
            ? (leaves.length / 2)
            : ((leaves.length / 2) + 1);
        if (nLeavesNonNull > nLeaves) nLeavesNonNull = nLeaves;

        for (uint256 pos = 0; pos < nLeavesNonNull; pos++) {
            _leaves[pos] = hash_node(leaves[2 * pos], leaves[2 * pos + 1]);
        }
        for (uint256 pos = nLeavesNonNull; pos < nLeaves; pos++) {
            _leaves[pos] = NULL_BYTES32;
        }

        // levels > 0 reuse the smaller _leaves array:
        for (uint8 level = 1; level < nLevels; level++) {
            nLeaves /= 2;
            nLeavesNonNull = (nLeavesNonNull % 2 == 0)
                ? (nLeavesNonNull / 2)
                : ((nLeavesNonNull / 2) + 1);
            if (nLeavesNonNull > nLeaves) nLeavesNonNull = nLeaves;

            for (uint256 pos = 0; pos < nLeavesNonNull; pos++) {
                _leaves[pos] = hash_node(
                    _leaves[2 * pos],
                    _leaves[2 * pos + 1]
                );
            }
            for (uint256 pos = nLeavesNonNull; pos < nLeaves; pos++) {
                _leaves[pos] = NULL_BYTES32;
            }
        }
        return _leaves[0];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Library of pure functions to help providing info
*/

import "../pure/EncodingAssets.sol";
import "../pure/serialization/SerializeAssetPropsGet.sol";
import "../pure/serialization/SerializeCompleteGet.sol";
import "../pure/serialization/SerializeFreezeGet.sol";
import "../pure/serialization/SerializeBuyNowGet.sol";
import "../pure/serialization/SerializeMerkleGet.sol";
import "../pure/serialization/SerializeOwnershipGet.sol";
import "../pure/serialization/SerializeMarketDataGet.sol";
import "../pure/serialization/SerializeMarketDataSet.sol";
import "../pure/SparseMerkleTree.sol";
import "../pure/MerkleSerialized.sol";
import "../pure/Constants.sol";
import "../pure/Messages.sol";
import "../pure/ChallengeLibStatus.sol";

contract InfoBase is
    Constants,
    EncodingAssets,
    SerializeMarketDataSet,
    SerializeAssetPropsGet,
    SerializeCompleteGet,
    SerializeFreezeGet,
    SerializeBuyNowGet,
    SerializeMerkleGet,
    SerializeOwnershipGet,
    SerializeMarketDataGet,
    SparseMerkleTree,
    MerkleSerialized,
    Messages,
    ChallengeLibStatus
{
    function isOwnerInOwnershipRoot(
        bytes32 owernshipRoot,
        uint256 assetId,
        address owner,
        bytes memory marketData,
        bytes memory proof
    ) public pure returns (bool) {
        if (marketDataNeverTraded(marketData)) {
            return
                (owner == decodeOwner(assetId)) &&
                SMTVerify(
                    owernshipRoot,
                    bytes32(0),
                    assetId,
                    DEPTH_OWNERSHIP_TREE,
                    proof
                );
        }
        bytes32 digest = keccak256(abi.encode(assetId, owner, marketData));
        return
            SMTVerify(
                owernshipRoot,
                digest,
                assetId,
                DEPTH_OWNERSHIP_TREE,
                proof
            );
    }

    function isAssetPropsInUniverseRoot(
        bytes32 root,
        bytes memory proof,
        uint256 assetId,
        string memory assetCID
    ) public pure returns (bool) {
        return
            MTVerify(
                root,
                assetPropsProof(proof),
                computeAssetLeaf(assetId, assetCID),
                assetPropsPos(proof)
            );
    }

    function isOwnerInOwnershipRootSerialized(
        bytes memory data,
        bytes32 ownershipRoot
    ) public pure returns (bool) {
        return
            isOwnerInOwnershipRoot(
                ownershipRoot,
                ownAssetId(data),
                ownOwner(data),
                ownMarketData(data),
                ownProof(data)
            );
    }

    function updateOwnershipTreeSerialized(
        bytes memory txData,
        bytes memory initOwnershipRaw
    ) public pure returns (bytes32) {
        uint256 assetId = ownAssetId(initOwnershipRaw);
        bytes memory newMarketData;
        address owner;
        uint8 txType = txGetType(txData);

        if (txType == TX_IDX_FREEZE) {
            owner = ownOwner(initOwnershipRaw); // owner remains the same
            newMarketData = encodeMarketData(
                assetId,
                freezeTXValidUntil(txData),
                freezeTXOfferValidUntil(txData),
                freezeTXTimeToPay(txData),
                freezeTXSellerHiddenPrice(txData)
            );
        } else {
            owner = (txType == TX_IDX_COMPLETE)
                ? complTXRecoverBuyer(txData)
                : buyNowTXRecoverBuyer(txData); // owner should now be the buyer
            newMarketData = serializeMarketData(bytes32(0), 0, 0);
        }

        bytes32 newLeafVal = keccak256(
            abi.encode(assetId, owner, newMarketData)
        );
        return
            updateOwnershipTree(
                newLeafVal,
                assetId,
                ownProof(initOwnershipRaw)
            );
    }

    function encodeMarketData(
        uint256 assetId,
        uint32 validUntil,
        uint32 offerValidUntil,
        uint32 versesToPay,
        bytes32 sellerHiddenPrice
    ) public pure returns (bytes memory) {
        bytes32 auctionId = computeAuctionId(
            sellerHiddenPrice,
            assetId,
            validUntil,
            offerValidUntil,
            versesToPay
        );
        return serializeMarketData(auctionId, validUntil, versesToPay);
    }

    function complTXRecoverBuyer(bytes memory txData)
        public
        pure
        returns (address)
    {
        return
            recoverAddrFromBytes(
                prefixed(
                    keccak256(
                        abi.encode(
                            complTXAuctionId(txData),
                            complTXBuyerHiddenPrice(txData),
                            complTXAssetCID(txData)
                        )
                    )
                ),
                complTXBuyerSig(txData)
            );
    }

    function buyNowTXRecoverBuyer(bytes memory txData)
        public
        pure
        returns (address)
    {
        return
            recoverAddrFromBytes(
                prefixed(
                    digestBuyNow(
                        buyNowTXHiddenPrice(txData),
                        buyNowTXAssetId(txData),
                        buyNowTXValidUntil(txData),
                        buyNowTXAssetCID(txData)
                    )
                ),
                buyNowTXBuyerSig(txData)
            );
    }

    function digestBuyNow(
        bytes32 hiddenPrice,
        uint256 assetId,
        uint256 validUntil,
        string memory assetCID
    ) public pure returns (bytes32) {
        bytes32 buyNowId = keccak256(
            abi.encode(hiddenPrice, assetId, validUntil)
        );
        return keccak256(abi.encode(buyNowId, assetCID));
    }

    // note that to update the ownership tree we reuse the proof of the previous leafVal, since all siblings remain identical
    // of course, the fact that proofPrevLeafVal actually proves the prevLeafVal needs to be checked before calling this function.
    function updateOwnershipTree(
        bytes32 newLeafVal,
        uint256 assetId,
        bytes memory proofPrevLeafVal
    ) public pure returns (bytes32) {
        return
            updateRootFromProof(
                newLeafVal,
                assetId,
                DEPTH_OWNERSHIP_TREE,
                proofPrevLeafVal
            );
    }

    function computeAuctionId(
        bytes32 hiddenPrice,
        uint256 assetId,
        uint32 validUntil,
        uint32 offerValidUntil,
        uint32 versesToPay
    ) public pure returns (bytes32) {
        return
            (offerValidUntil == 0)
                ? keccak256(
                    abi.encode(hiddenPrice, assetId, validUntil, versesToPay)
                )
                : keccak256(
                    abi.encode(
                        hiddenPrice,
                        assetId,
                        offerValidUntil,
                        versesToPay
                    )
                );
    }

    function wasAssetFrozen(bytes memory marketData, uint256 checkVerse)
        public
        pure
        returns (bool)
    {
        if (marketDataNeverTraded(marketData)) return false;
        return (uint256(marketDataValidUntil(marketData)) +
            uint256(marketDataTimeToPay(marketData)) >
            checkVerse);
    }

    function computeAssetLeaf(uint256 assetId, string memory cid)
        public
        pure
        returns (bytes32 hash)
    {
        return keccak256(abi.encode(assetId, cid));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Main serialization/deserialization of data into an assetId
 @dev assetId = 
 @dev   version(8b) + universeIdx (24) + isImmutable(1b) + isUntradable(1b) + editionIdx (24b) + assetIdx(38b) + initOwner (160b)
*/

contract EncodingAssets {
    function encodeAssetId(
        uint256 universeIdx,
        uint256 editionIdx,
        uint256 assetIdx,
        address initOwner,
        bool isImmutable,
        bool isUntradable
    ) public pure returns (uint256) {
        require(
            universeIdx >> 24 == 0,
            "universeIdx cannot be larger than 24 bit"
        );
        require(assetIdx >> 38 == 0, "assetIdx cannot be larger than 38 bit");
        require(editionIdx >> 24 == 0, "assetIdx cannot be larger than 24 bit");
        return ((universeIdx << 224) |
            (uint256(isImmutable ? 1 : 0) << 223) |
            (uint256(isUntradable ? 1 : 0) << 222) |
            (editionIdx << 198) |
            (assetIdx << 160) |
            uint256(uint160(initOwner)));
    }

    function decodeIsImmutable(uint256 assetId)
        public
        pure
        returns (bool isImmutable)
    {
        return ((assetId >> 223) & 1) == 1;
    }

    function decodeIsUntradable(uint256 assetId)
        public
        pure
        returns (bool isUntradable)
    {
        return ((assetId >> 222) & 1) == 1;
    }

    function decodeEditionIdx(uint256 assetId)
        public
        pure
        returns (uint32 editionIdx)
    {
        return uint32((assetId >> 198) & 16777215); // 2**24 - 1
    }

    function decodeOwner(uint256 assetId)
        public
        pure
        returns (address initOwner)
    {
        return
            address(
                uint160(
                    assetId & 1461501637330902918203684832716283019655932542975
                )
            ); // 2**160 - 1
    }

    function decodeAssetIdx(uint256 assetId)
        public
        pure
        returns (uint256 assetIdx)
    {
        return (assetId >> 160) & 274877906943; // 2**38-1
    }

    function decodeUniverseIdx(uint256 assetId)
        public
        pure
        returns (uint256 assetIdx)
    {
        return (assetId >> 224);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Constants used throughout the project
 @dev Time is always expressed in units of 'verse'
*/

contract Constants {
    uint32 internal constant MAX_VALID_UNTIL = 8640; // 90 days
    uint32 internal constant MAX_VERSES_TO_PAY = 960; // 10 days;

    uint16 internal constant DEPTH_OWNERSHIP_TREE = 256;

    uint8 internal constant TX_IDX_FREEZE = 0;
    uint8 internal constant TX_IDX_COMPLETE = 1;
    uint8 internal constant TX_IDX_BUYNOW = 2;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Pure function to compute the status of a challenge
*/

contract ChallengeLibStatus {
    /**
     * @dev Computes if the system is ready to accept a new TX Batch submission
     *      Data from storage is fetched previous to passing to this function.
     */
    function isReadyForTXSubmissionPure(
        uint256 nTXs,
        uint256 txRootsCurrentVerse,
        uint256 ownershipSubmissionTimeCurrent,
        uint256 challengeWindowCurrent,
        uint256 txSubmissionTimeCurrent,
        uint256 blockTimestamp,
        uint8 challengesLevel
    ) public pure returns (bool isReady, uint8 actualLevel) {
        if (txRootsCurrentVerse == 0) return (true, 1);
        bool isOwnershipMoreRecent = ownershipSubmissionTimeCurrent >=
            txSubmissionTimeCurrent;
        bool isSettled;
        (isSettled, actualLevel, ) = computeChallStatus(
            nTXs,
            blockTimestamp,
            txSubmissionTimeCurrent,
            ownershipSubmissionTimeCurrent,
            challengeWindowCurrent,
            challengesLevel
        );
        isReady = isSettled && isOwnershipMoreRecent;
    }

    /**
    * @dev Pure function to compute if the current challenge is settled already,
           or if due to time passing, one or more challenges have been tacitly accepted.
           In such case, the challenge processs reduces 2 levels per challenge accepted.
           inputs:
            currentTime: now, in secs, as return by block.timstamp
            lastChallTime: time at which the last challenge was received (at level 0, time of submission of ownershipRoot)
            challengeWindow: amount of time available for submitting a new challenge
            writtenLevel: the last stored level of the current challenge game
           returns:
            isSettled: if true, challenges are still accepted
            actualLevel: the level at which the challenge truly is, taking time into account.
            nJumps: the number of challenges tacitly accepted, taking time into account.
    */
    function computeChallStatus(
        uint256 nTXs,
        uint256 currentTime,
        uint256 lastTxSubmissionTime,
        uint256 lastChallTime,
        uint256 challengeWindow,
        uint8 writtenLevel
    )
        public
        pure
        returns (
            bool isSettled,
            uint8 actualLevel,
            uint8 nJumps
        )
    {
        if (challengeWindow == 0)
            return (
                currentTime > lastChallTime,
                (writtenLevel % 2) == 1 ? 1 : 2,
                0
            );
        uint256 numChallPeriods = (currentTime > lastChallTime)
            ? (currentTime - lastChallTime) / challengeWindow
            : 0;
        // actualLevel in the following formula can either end up as 0 or 1.
        actualLevel = (writtenLevel >= 2 * numChallPeriods)
            ? uint8(writtenLevel - 2 * numChallPeriods)
            : (writtenLevel % 2);
        // if we reached actualLevel = 0 via jumps, it means that there was enough time to settle level 2. So we're settled and remain at level = 2.
        if ((writtenLevel > 1) && (actualLevel == 0)) {
            return (true, 2, 0);
        }
        nJumps = (writtenLevel - actualLevel) / 2;
        isSettled =
            (nTXs == 0) ||
            (lastTxSubmissionTime > lastChallTime) ||
            (currentTime > (lastChallTime + (nJumps + 1) * challengeWindow));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from  "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is
    ContextMixin,
    ERC721Enumerable,
    NativeMetaTransaction,
    Ownable
{
    using SafeMath for uint256;

    address proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    function baseTokenURI() public pure virtual returns (string memory);

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Freeverse
 * Contract for NFTs exported from Layer-2
 */

contract ERC721FV is ERC721Tradable {
    /**
     * @dev Mapping from assetID to URI
     * @dev Ideally, URI is an IPFS address in format ipfs://CID
     */
    mapping(uint256 => string) internal assetURI;

    mapping(uint256 => string) internal universeIdToBaseURI;
    bool public isProxyRegistryAddressLocked;

    constructor(string memory _name, string memory _symbol)
        ERC721Tradable(_name, _symbol, address(0))
    {}

    /**
     * @dev Allow to change proxyRegistryAddress after deploy
     */
    function setProxyRegistryAddress(address _newAddr) external onlyOwner {
        require(
            !isProxyRegistryAddressLocked,
            "proxyAddress cannot be modified anymore"
        );
        proxyRegistryAddress = _newAddr;
    }

    /**
     * @dev Avoid any possible future change of proxyRegistry
     */
    function lockProxyRegistryAddress() external onlyOwner {
        isProxyRegistryAddressLocked = true;
    }

    /**
     * @dev Mints a new NFT.
     * @param _to The address that will own the minted NFT.
     * @param _id Unique ID of the NFT to be minted by msg.sender.
     * @param _assetURI The URI with its metadata, ideally an IPFS address
     */
    function mint(
        address _to,
        uint256 _id,
        string calldata _assetURI
    ) external onlyOwner {
        super._mint(_to, _id);
        assetURI[_id] = _assetURI;
    }

    /**
     * @dev Removes a NFT from owner.
     * @notice removed onlyOwner to allow the owner of the NFT to burn permisionlessly
     * @param _id Which NFT we want to remove.
     */
    function burn(uint256 _id) external {
        require(ownerOf(_id) == msg.sender, "msg.sender is not owner of token");
        super._burn(_id);
        delete assetURI[_id];
    }

    /**
        VIEW FUNCTIONS
    */

    /**
     * @dev Returns URI for this _id.
     * @param _id Id for which we want the URI.
     * @return URI of _id.
     */
    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        require(exists(_id), "token does not exist");
        return assetURI[_id];
    }

    function proxyRegistry() public view returns (address) {
        return proxyRegistryAddress;
    }

    function exists(uint256 _id) public view returns (bool) {
        return _exists(_id);
    }

    // The baseTokenURI concept does not apply to this contract
    // Forced to implement, just return an empty string
    function baseTokenURI() public pure override returns (string memory) {
        return "";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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