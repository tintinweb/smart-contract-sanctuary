pragma solidity ^0.4.15;

// File: contracts/libs/Ownable.sol

/**
* @title Ownable
* @dev Manages ownership of the contracts
*/
contract Ownable {

    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function isOwner(address _address) public constant returns (bool) {
        return _address == owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}

// File: contracts/libs/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
    * @dev modifier to allow actions only when the contract IS paused
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev modifier to allow actions only when the contract IS NOT paused
    */
    modifier whenPaused {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function _pause() internal whenNotPaused {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function _unpause() internal whenPaused {
        paused = false;
        Unpause();
    }
}

// File: contracts/libs/BaseStorage.sol

contract BaseStorage is Pausable {

    event AccessAllowed(address _address);
    event AccessDenied(address _address);

    mapping (address => bool) public allowed;
    address public developer;


    modifier canWrite() {
        require(allowed[msg.sender] || isOwner(msg.sender)
            || (msg.sender == developer));
        _;
    }

    function setDeveloper(address _address) public onlyOwner {
        require(_address != address(0));
        developer = _address;
    }

    function allow(address _address) external canWrite {
        require(_address != address(0));
        allowed[_address] = true;
        AccessAllowed(_address);
    }

    function denied(address _address) external canWrite {
        delete allowed[_address];
        AccessDenied(_address);
    }

    function isAllowed(address _address) external constant returns (bool) {
        return allowed[_address];
    }
}

// File: contracts/libs/AccessControlStorage.sol

contract AccessControlStorage is BaseStorage {


    mapping (address => bool) public admins;
    mapping (uint => address) public contracts;

    function addAdmin(address _address) public onlyOwner {
        require(_address != address(0));
        admins[_address] = true;
    }

    function isAdmin(address _address) public constant returns (bool) {
        return admins[_address];
    }

    function removeAdmin(address _address) public onlyOwner {
        require(_address != address(0));
        delete admins[_address];
    }

    function setContract(uint _signature, address _address) external canWrite {
        contracts[_signature] = _address;
    }
}

// File: contracts/libs/AuctionStorage.sol

contract AuctionStorage is BaseStorage {

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price (in wei) at beginning of auction
        uint128 startingPrice;
        // Price (in wei) at end of auction
        uint128 endingPrice;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint startedAt;
        // true = started by team, false = started by ordinary user
        bool byTeam;
    }

    // Map from token ID to their corresponding auction.
    mapping (uint => Auction) public tokenIdToAuction;
    uint auctionsCounter = 0;
    uint8 public secondarySaleCut = 4;

    function addAuction(
        uint _tokenId,
        uint _startingPrice,
        uint _endingPrice,
        uint _duration,
        address _seller) public canWrite {
        require(!_isOnAuction(_tokenId));
        tokenIdToAuction[_tokenId] = Auction({
            seller: _seller,
            startingPrice: uint128(_startingPrice),
            endingPrice: uint128(_endingPrice),
            duration: uint64(_duration),
            startedAt: now,
            byTeam: false
        });
        auctionsCounter++;
    }

    function initAuction(
        uint _tokenId,
        uint _startingPrice,
        uint _endingPrice,
        uint _startedAt,
        uint _duration,
        address _seller,
        bool _byTeam) public canWrite {
        require(!_isOnAuction(_tokenId));
        tokenIdToAuction[_tokenId] = Auction({
            seller: _seller,
            startingPrice: uint128(_startingPrice),
            endingPrice: uint128(_endingPrice),
            duration: uint64(_duration),
            startedAt: _startedAt,
            byTeam: _byTeam
        });
        auctionsCounter++;
    }

    function addReleaseAuction(
        uint _tokenId,
        uint _startingPrice,
        uint _endingPrice,
        uint _startedAt,
        uint _duration) public canWrite {
        bool _byTeam = true;
        address _seller = owner;
        initAuction(
            _tokenId,
            _startingPrice,
            _endingPrice,
            _startedAt,
            _duration,
            _seller,
            _byTeam
        );
    }

    function _isOnAuction(uint _tokenId)
        internal constant returns (bool) {
        return (tokenIdToAuction[_tokenId].startedAt > 0);
    }

    function isOnAuction(uint _tokenId)
        external constant returns (bool) {
        return _isOnAuction(_tokenId);
    }

    function removeAuction(uint _tokenId) public canWrite {
        require(_isOnAuction(_tokenId));
        delete tokenIdToAuction[_tokenId];
        auctionsCounter--;
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
        external
        constant
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction memory auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(_tokenId));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    function getAuctionSeller(uint256 _tokenId)
        public constant returns (address) {
        return tokenIdToAuction[_tokenId].seller;
    }

    function getAuctionStartedAt(uint256 _tokenId)
        public constant returns (uint) {
        return tokenIdToAuction[_tokenId].startedAt;
    }

    function getAuctionEnd(uint _tokenId)
        public constant returns (uint) {
        Auction memory auction = tokenIdToAuction[_tokenId];
        return auction.startedAt + auction.duration;
    }

    function getAuctionsCount() public constant returns (uint) {
        return auctionsCounter;
    }

    function canBeCanceled(uint _tokenId) external constant returns (bool) {
        return getAuctionEnd(_tokenId) <= now;
    }

    function isSecondary(uint _tokenId) public constant returns (bool _is) {
        return (tokenIdToAuction[_tokenId].byTeam == false);
    }

}

// File: contracts/libs/EditionStorage.sol

contract EditionStorage is BaseStorage {

    uint public offset = 1000000;
    uint public offsetIndex = 1;
    uint8[3] public defaultEditionLimits = [10, 89, 200];
    mapping (uint => mapping (uint8 => uint8)) public editionCounts;
    mapping (uint => mapping (uint8 => uint8)) public editionLimits;
    mapping (uint => uint) public lastEditionOf;

    function setOffset(uint _offset) external onlyOwner {
        offset = _offset;
    }

    function getOffsetIndex() public constant returns (uint) {
        return offset + offsetIndex;
    }

    function nextOffsetIndex() public canWrite {
        offsetIndex++;
    }

    function canCreateEdition(uint _tokenId, uint8 _generation)
        public constant returns (bool) {
        uint8 actual = editionCounts[_tokenId][_generation - 1];
        uint limit = editionLimits[_tokenId][_generation - 1];
        return (actual < limit);
    }

    function isValidGeneration(uint8 _generation)
        public constant returns (bool) {
        return (_generation >= 1 && _generation <= 3);
    }

    function increaseGenerationCount(uint _tokenId, uint8 _generation)
        public canWrite {
        require(canCreateEdition(_tokenId, _generation));
        require(isValidGeneration(_generation));
        uint8 _generationIndex = _generation - 1;
        editionCounts[_tokenId][_generationIndex]++;
    }

    function getEditionsCount(uint _tokenId)
        external constant returns (uint8[3])  {
        return [
            editionCounts[_tokenId][0],
            editionCounts[_tokenId][1],
            editionCounts[_tokenId][2]
        ];
    }

    function setLastEditionOf(uint _tokenId, uint _editionId)
        public canWrite {
        lastEditionOf[_tokenId] = _editionId;
    }

    function getEditionLimits(uint _tokenId)
        external constant returns (uint8[3])  {
        return [
            editionLimits[_tokenId][0],
            editionLimits[_tokenId][1],
            editionLimits[_tokenId][2]
        ];
    }


}

// File: contracts/libs/PaintingInformationStorage.sol

contract PaintingInformationStorage {

    struct PaintingInformation {
        string name;
        string artist;
    }

    mapping (uint => PaintingInformation) public information;
}

// File: contracts/libs/PaintingStorage.sol

contract PaintingStorage is BaseStorage {

    struct Painting {
        uint parentId;
        uint originalId;
        uint createdAt;
        uint completedAt;
        uint8 generation;
        uint8 speedIndex;
        uint artistId;
        uint releasedAt;
        bool isFinal;
    }

    uint32[10] public speeds = [
        uint32(8760 hours), // 365 days
        uint32(6480 hours), // 270 days
        uint32(4320 hours), // 180 days
        uint32(2880 hours), // 120 days
        uint32(1920 hours), // 80 days
        uint32(960 hours), // 40 days
        uint32(480 hours), // 20 days
        uint32(240 hours), // 10 days
        uint32(120 hours), // 5 days
        uint32(24 hours) // 1 day
    ];

    uint32[10] public speedsTest = [
        uint32(8760 seconds),
        uint32(6480 seconds),
        uint32(4320 seconds),
        uint32(2880 seconds),
        uint32(1920 seconds),
        uint32(960 seconds),
        uint32(480 seconds),
        uint32(240 seconds),
        uint32(120 seconds),
        uint32(24 seconds)
    ];

    uint32[10] public speedsDev = [
        uint32(0 seconds),
        uint32(0 seconds),
        uint32(0 seconds),
        uint32(0 seconds),
        uint32(0 seconds),
        uint32(0 seconds),
        uint32(0 seconds),
        uint32(0 seconds),
        uint32(0 seconds),
        uint32(0 seconds)
    ];

    mapping (uint => address) public paintingIndexToOwner;
    mapping (uint => Painting) public paintings;
    mapping (uint => address) public paintingIndexToApproved;
    uint[] public paintingIds;
    mapping (uint => uint) public paintingIdToIndex;
    uint public paintingsCount;
    uint public totalPaintingsCount;
    mapping (uint => bool) public isCanceled;
    mapping (uint => bool) public isReleased;

    // @dev A mapping from owner address to count of tokens that address owns.
    // Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) public ownershipTokenCount;

    modifier isNew(uint _tokenId) {
        require(paintings[_tokenId].createdAt == 0);
        _;
    }

    function exists(uint _tokenId) external constant returns (bool) {
        return paintings[_tokenId].createdAt != 0;
    }

    function increaseOwnershipTokenCount(address _address) public canWrite {
        ownershipTokenCount[_address]++;
    }

    function decreaseOwnershipTokenCount(address _address) public canWrite {
        ownershipTokenCount[_address]--;
    }

    function setOwnership(uint _tokenId, address _address) public canWrite {
        paintingIndexToOwner[_tokenId] = _address;
    }

    function getPainting(uint _tokenId) external constant returns (
        address owner,
        uint parent,
        uint createdAt,
        uint completedAt,
        uint8 generation,
        uint8 speed) {
        return (
            paintingIndexToOwner[_tokenId],
            paintings[_tokenId].parentId,
            paintings[_tokenId].createdAt,
            paintings[_tokenId].completedAt,
            paintings[_tokenId].generation,
            paintings[_tokenId].speedIndex + 1
        );
    }

    function approve(uint _tokenId, address _claimant) external canWrite {
        paintingIndexToApproved[_tokenId] = _claimant;
    }

    function isApprovedFor(uint _tokenId, address _claimant) external constant returns (bool) {
        return paintingIndexToApproved[_tokenId] == _claimant;
    }

    function decreaseSpeed(uint _tokenId) public canWrite() {
        uint8 _speed = paintings[_tokenId].speedIndex;

        if (_speed > 0) {
            paintings[_tokenId].speedIndex--;
        }
    }

    function getPaintingOwner(uint _tokenId)
        external constant returns (address) {
        return paintingIndexToOwner[_tokenId];
    }

    function getPaintingGeneration(uint _tokenId)
        public constant returns (uint8) {
        return paintings[_tokenId].generation;
    }

    function getPaintingArtistId(uint _tokenId)
        public constant returns (uint artistId) {
        return paintings[_tokenId].artistId;
    }

    function getPaintingSpeed(uint _tokenId)
        external constant returns (uint8) {
        return paintings[_tokenId].speedIndex + 1;
    }

    function getPaintingOriginal(uint _tokenId)
        external constant returns (uint) {
        return paintings[_tokenId].originalId;
    }

    function getOwnershipTokenCount(address _address)
        external constant returns (uint) {
        return ownershipTokenCount[_address];
    }

    function isReady(uint _tokenId)
        public constant returns (bool) {
        return paintings[_tokenId].completedAt <= now;
    }

    function getPaintingIdAtIndex(uint _index)
        public constant returns (uint) {
        return paintingIds[_index];
    }

    function canBeChanged(uint _tokenId) public constant returns (bool _can) {
        return paintings[_tokenId].isFinal == false;
    }

    function sealForChanges(uint _tokenId) public canWrite {
        if (paintings[_tokenId].isFinal == false) {
            paintings[_tokenId].isFinal = true;
        }
    }

    function canBeBidden(uint _tokenId) public constant returns (bool _can) {
        return (paintings[_tokenId].releasedAt <= now);
    }

}

// File: contracts/BitpaintingStorage.sol

contract BitpaintingStorage is PaintingStorage, PaintingInformationStorage, AccessControlStorage, AuctionStorage, EditionStorage {

    /// 0 = production mode
    /// 1 = testing mode
    /// 2 = development mode
    uint8 mode;

    function BitpaintingStorage(uint8 _mode) public {
        require(_mode >= 0 && _mode <=2);
        mode = _mode;
    }

    function hasEditionInProgress(uint _tokenId)
        external constant returns (bool) {
        uint edition = lastEditionOf[_tokenId];
        if (edition == 0) {
            return false;
        }

        return !isReady(edition);
    }

    function hasEmptyEditionSlots(uint _tokenId)
        external constant returns (bool) {
        uint originalId = paintings[_tokenId].originalId;
        if (originalId == 0) {
            originalId = _tokenId;
        }
        uint8 generation = paintings[_tokenId].generation;
        uint8 limit = editionLimits[originalId][generation];
        uint8 current = editionCounts[originalId][generation];
        return (current < limit);
    }

    function resetPainting(uint _tokenId) public canWrite {
        require(canBeChanged(_tokenId));

        isCanceled[_tokenId] = true;
        paintingsCount--;
        delete paintings[_tokenId];
    }

    function createPainting(
        address _owner,
        uint _tokenId,
        uint _parentId,
        uint8 _generation,
        uint8 _speed,
        uint _artistId,
        uint _releasedAt
    ) public isNew(_tokenId) canWrite {
        require(now <= _releasedAt);
        require(_speed >= 1 && _speed <= 10);
        _speed--;

        uint _createdAt = now;
        uint _completedAt;
        if (_generation == 0) {
            _completedAt = now;
        } else {
            uint _parentSpeed = paintings[_parentId].speedIndex;
            if (mode == 2) {
                _completedAt = now + speedsDev[_parentSpeed];
            } else {
                if (mode == 1) {
                    _completedAt = now + speedsTest[_parentSpeed];
                } else {
                    _completedAt = now + speeds[_parentSpeed];
                }
            }
        }

        uint _originalId;
        if (_generation == 0) {
            _originalId = _tokenId;
        } else {
            if (_generation == 1) {
                _originalId = _parentId;
            } else {
                _originalId = paintings[_parentId].originalId;
            }
        }

        paintings[_tokenId] = Painting({
            parentId: _parentId,
            originalId: _originalId,
            createdAt: _createdAt,
            generation: _generation,
            speedIndex: _speed,
            completedAt: _completedAt,
            artistId: _artistId,
            releasedAt: _releasedAt,
            isFinal: (_generation != 0) // if generation == 1 or 2 or 3, so it cannot be changed
        });

        if (!isReleased[_tokenId]) {
            isReleased[_tokenId] = true;
            paintingIds.push(_tokenId);
            paintingIdToIndex[_tokenId] = totalPaintingsCount;
            increaseOwnershipTokenCount(_owner);
            totalPaintingsCount++;
        }
        isCanceled[_tokenId] = false;
        setOwnership(_tokenId, _owner);
        paintingsCount++;
    }

    function setEditionLimits(
        uint _tokenId,
        uint8 _gen1,
        uint8 _gen2,
        uint8 _gen3)
        public canWrite {
        require(canBeChanged(_tokenId));

        editionLimits[_tokenId][0] = _gen1;
        editionLimits[_tokenId][1] = _gen2;
        editionLimits[_tokenId][2] = _gen3;
    }

    function resetEditionLimits(uint _tokenId) public canWrite {
        setEditionLimits(_tokenId, 0, 0, 0);
    }

    function createEditionMeta(uint _tokenId) public canWrite {
        uint _originalId = paintings[_tokenId].originalId;
        nextOffsetIndex();
        uint editionId = getOffsetIndex();
        setLastEditionOf(_tokenId, editionId);

        uint8 _generation = getPaintingGeneration(_tokenId) + 1;
        increaseGenerationCount(_originalId, _generation);
    }

    function purgeInformation(uint _tokenId) public canWrite {
        require(canBeChanged(_tokenId));

        delete information[_tokenId];
    }

    function setPaintingName(uint _tokenId, string _name) public canWrite {
        information[_tokenId].name = _name;
    }

    function setPaintingArtist(uint _tokenId, string _name) public canWrite {
        information[_tokenId].artist = _name;
    }

    function getTokensOnAuction() public constant returns (uint[] tokens) {
        tokens = new uint[](auctionsCounter);
        uint pointer = 0;

        for(uint index = 0; index < totalPaintingsCount; index++) {
            uint tokenId = getPaintingIdAtIndex(index);

            if (isCanceled[tokenId]) {
                continue;
            }

            if (!_isOnAuction(tokenId)) {
                continue;
            }

            tokens[pointer] = tokenId;
            pointer++;
        }
    }

    function getPaintingName(uint _tokenId) public constant returns (string) {
        uint id = paintings[_tokenId].originalId;
        return information[id].name;
    }

    function getPaintingArtist(uint _tokenId)
        public constant returns (string) {
        uint id = paintings[_tokenId].originalId;
        return information[id].artist;
    }

    function signature() external constant returns (bytes4) {
        return bytes4(keccak256("storage"));
    }


}