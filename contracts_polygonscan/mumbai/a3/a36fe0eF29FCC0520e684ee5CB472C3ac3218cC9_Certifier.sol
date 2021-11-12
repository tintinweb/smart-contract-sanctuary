// SPDX-License-Identifier: MIT
pragma solidity >=0.6.3;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Main interface for applications that require ownership & asset properties verification 
*/

import "../view/Info.sol";

contract Certifier {
    address private _info;

    constructor(address infoAddress) {
        _info = infoAddress;
    }

    function info() public view returns (address) {
        return _info;
    }

    /**
    @dev Returns true only if the provided owner owns the asset AND the asset has the provided props
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
            Info(_info).isCurrentOwnerOfAssetWithProps(
                assetId,
                owner,
                marketData,
                assetCID,
                ownershipProof,
                propsProof
            );
    }

    /**
    @dev Returns true only if provided owner is the owner of the provided assetId
         If asset has been previously exported, this function returns false;
         in such case, ownership needs to be queried in the external ERC721 contract.
    */
    function isCurrentOwner(
        uint256 assetId,
        address owner,
        bytes memory marketData,
        bytes memory proof
    ) public view returns (bool) {
        return Info(_info).isCurrentOwner(assetId, owner, marketData, proof);
    }

    /**
    @dev Identical to isCurrentOwner, but certifying at the provided previous verse 
    */
    function wasOwnerAtVerse(
        uint256 verse,
        uint256 assetId,
        address owner,
        bytes memory marketData,
        bytes memory proof
    ) public view returns (bool) {
        return Info(_info).wasOwnerAtVerse(verse, assetId, owner, marketData, proof);
    }

    /**
    @dev Returns true only if the provided assetId has the provided props.
    */
    function isCurrentAssetProps(
        uint256 assetId,
        string memory assetCID,
        bytes memory proof
    ) public view returns (bool) {
        return Info(_info).isCurrentAssetProps(assetId, assetCID, proof);
    }

    /**
    @dev Returns true only if the provided assetId had the provided props at the provided verse
    */
    function wasAssetPropsAtVerse(
        uint256 assetId,
        uint256 verse,
        string memory assetCID,
        bytes memory proof
    ) public view returns (bool) {
        return Info(_info).wasAssetPropsAtVerse(assetId, verse, assetCID, proof);
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