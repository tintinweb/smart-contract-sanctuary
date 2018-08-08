pragma solidity ^0.4.15;

// File: contracts/interfaces/IAuctions.sol

contract IAuctions {

    function currentPrice(uint _tokenId) public constant returns (uint256);
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration) public;
    function createReleaseAuction(
        uint _tokenId,
        uint _startingPrice,
        uint _endingPrice,
        uint _startedAt,
        uint _duration) public;
    function cancelAuction(uint256 _tokenId) external;
    function cancelAuctionWhenPaused(uint256 _tokenId) external;
    function bid(uint256 _tokenId, address _owner) external payable;
    function market() public constant returns (
        uint[] tokens,
        address[] sellers,
        uint8[] generations,
        uint8[] speeds,
        uint[] prices
    );
    function auctionsOf(address _of) public constant returns (
        uint[] tokens,
        uint[] prices
    );
    function signature() external constant returns (uint _signature);
}

// File: contracts/interfaces/IPaintings.sol

contract IPaintings {
    function createPainting(uint _tokenId) external;
    function sendAsGift(address _to, uint _tokenId) external;
    function collectionOf(address _of) public constant returns (
        uint[] tokens,
        bool[] pending,
        bool[] forSale,
        bool[] locked,
        uint8[] generations,
        uint8[] speeds
    );
    function collectionCountsOf(address _of)
        public constant returns (uint total, uint pending, uint forSale);
    function signature() external constant returns (uint _signature);
}

// File: contracts/interfaces/IStorage.sol

contract IStorage {
    function isOwner(address _address) public constant returns (bool);

    function isAllowed(address _address) external constant returns (bool);
    function developer() public constant returns (address);
    function setDeveloper(address _address) public;
    function addAdmin(address _address) public;
    function isAdmin(address _address) public constant returns (bool);
    function removeAdmin(address _address) public;
    function contracts(uint _signature) public returns (address _address);

    function exists(uint _tokenId) external constant returns (bool);
    function paintingsCount() public constant returns (uint);
    function increaseOwnershipTokenCount(address _address) public;
    function decreaseOwnershipTokenCount(address _address) public;
    function setOwnership(uint _tokenId, address _address) public;
    function getPainting(uint _tokenId)
        external constant returns (address, uint, uint, uint, uint8, uint8);
    function createPainting(
        address _owner,
        uint _tokenId,
        uint _parentId,
        uint8 _generation,
        uint8 _speed,
        uint _artistId,
        uint _releasedAt) public;
    function approve(uint _tokenId, address _claimant) external;
    function isApprovedFor(uint _tokenId, address _claimant)
        external constant returns (bool);
    function createEditionMeta(uint _tokenId) public;
    function getPaintingOwner(uint _tokenId)
        external constant returns (address);
    function getPaintingGeneration(uint _tokenId)
        public constant returns (uint8);
    function getPaintingSpeed(uint _tokenId)
        external constant returns (uint8);
    function getPaintingArtistId(uint _tokenId)
        public constant returns (uint artistId);
    function getOwnershipTokenCount(address _address)
        external constant returns (uint);
    function isReady(uint _tokenId) public constant returns (bool);
    function getPaintingIdAtIndex(uint _index) public constant returns (uint);
    function lastEditionOf(uint _index) public constant returns (uint);
    function getPaintingOriginal(uint _tokenId)
        external constant returns (uint);
    function canBeBidden(uint _tokenId) public constant returns (bool _can);

    function addAuction(
        uint _tokenId,
        uint _startingPrice,
        uint _endingPrice,
        uint _duration,
        address _seller) public;
    function addReleaseAuction(
        uint _tokenId,
        uint _startingPrice,
        uint _endingPrice,
        uint _startedAt,
        uint _duration) public;
    function initAuction(
        uint _tokenId,
        uint _startingPrice,
        uint _endingPrice,
        uint _startedAt,
        uint _duration,
        address _seller,
        bool _byTeam) public;
    function _isOnAuction(uint _tokenId) internal constant returns (bool);
    function isOnAuction(uint _tokenId) external constant returns (bool);
    function removeAuction(uint _tokenId) public;
    function getAuction(uint256 _tokenId)
        external constant returns (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt);
    function getAuctionSeller(uint256 _tokenId)
        public constant returns (address);
    function getAuctionEnd(uint _tokenId)
        public constant returns (uint);
    function canBeCanceled(uint _tokenId) external constant returns (bool);
    function getAuctionsCount() public constant returns (uint);
    function getTokensOnAuction() public constant returns (uint[]);
    function getTokenIdAtIndex(uint _index) public constant returns (uint);
    function getAuctionStartedAt(uint256 _tokenId) public constant returns (uint);

    function getOffsetIndex() public constant returns (uint);
    function nextOffsetIndex() public returns (uint);
    function canCreateEdition(uint _tokenId, uint8 _generation)
        public constant returns (bool);
    function isValidGeneration(uint8 _generation)
        public constant returns (bool);
    function increaseGenerationCount(uint _tokenId, uint8 _generation) public;
    function getEditionsCount(uint _tokenId) external constant returns (uint8[3]);
    function setLastEditionOf(uint _tokenId, uint _editionId) public;
    function setEditionLimits(uint _tokenId, uint8 _gen1, uint8 _gen2, uint8 _gen3) public;
    function getEditionLimits(uint _tokenId) external constant returns (uint8[3]);

    function hasEditionInProgress(uint _tokenId) external constant returns (bool);
    function hasEmptyEditionSlots(uint _tokenId) external constant returns (bool);

    function setPaintingName(uint _tokenId, string _name) public;
    function setPaintingArtist(uint _tokenId, string _name) public;
    function purgeInformation(uint _tokenId) public;
    function resetEditionLimits(uint _tokenId) public;
    function resetPainting(uint _tokenId) public;
    function decreaseSpeed(uint _tokenId) public;
    function isCanceled(uint _tokenId) public constant returns (bool _is);
    function totalPaintingsCount() public constant returns (uint _total);
    function isSecondary(uint _tokenId) public constant returns (bool _is);
    function secondarySaleCut() public constant returns (uint8 _cut);
    function sealForChanges(uint _tokenId) public;
    function canBeChanged(uint _tokenId) public constant returns (bool _can);

    function getPaintingName(uint _tokenId) public constant returns (string);
    function getPaintingArtist(uint _tokenId) public constant returns (string);

    function signature() external constant returns (bytes4);
}

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

// File: contracts/libs/BitpaintingBase.sol

contract BitpaintingBase is Pausable {
    /*** EVENTS ***/
    event Create(uint _tokenId,
        address _owner,
        uint _parentId,
        uint8 _generation,
        uint _createdAt,
        uint _completedAt);

    event Transfer(address from, address to, uint256 tokenId);

    IStorage public bitpaintingStorage;

    modifier canPauseUnpause() {
        require(msg.sender == owner || msg.sender == bitpaintingStorage.developer());
        _;
    }

    function setBitpaintingStorage(address _address) public onlyOwner {
        require(_address != address(0));
        bitpaintingStorage = IStorage(_address);
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() public canPauseUnpause whenNotPaused {
        super._pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external canPauseUnpause whenPaused {
        super._unpause();
    }

    function canUserReleaseArtwork(address _address)
        public constant returns (bool _can) {
        return (bitpaintingStorage.isOwner(_address)
            || bitpaintingStorage.isAdmin(_address)
            || bitpaintingStorage.isAllowed(_address));
    }

    function canUserCancelArtwork(address _address)
        public constant returns (bool _can) {
        return (bitpaintingStorage.isOwner(_address)
            || bitpaintingStorage.isAdmin(_address));
    }

    modifier canReleaseArtwork() {
        require(canUserReleaseArtwork(msg.sender));
        _;
    }

    modifier canCancelArtwork() {
        require(canUserCancelArtwork(msg.sender));
        _;
    }

    /// @dev Assigns ownership of a specific Painting to an address.
    function _transfer(address _from, address _to, uint256 _tokenId)
        internal {
        bitpaintingStorage.setOwnership(_tokenId, _to);
        Transfer(_from, _to, _tokenId);
    }

    function _createOriginalPainting(uint _tokenId, uint _artistId, uint _releasedAt) internal {
        address _owner = owner;
        uint _parentId = 0;
        uint8 _generation = 0;
        uint8 _speed = 10;
        _createPainting(_owner, _tokenId, _parentId, _generation, _speed, _artistId, _releasedAt);
    }

    function _createPainting(
        address _owner,
        uint _tokenId,
        uint _parentId,
        uint8 _generation,
        uint8 _speed,
        uint _artistId,
        uint _releasedAt
    )
        internal
    {
        require(_tokenId == uint256(uint32(_tokenId)));
        require(_parentId == uint256(uint32(_parentId)));
        require(_generation == uint256(uint8(_generation)));

        bitpaintingStorage.createPainting(
            _owner, _tokenId, _parentId, _generation, _speed, _artistId, _releasedAt);

        uint _createdAt;
        uint _completedAt;
        (,,_createdAt, _completedAt,,) = bitpaintingStorage.getPainting(_tokenId);

        // emit the create event
        Create(
            _tokenId,
            _owner,
            _parentId,
            _generation,
            _createdAt,
            _completedAt
        );

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, _tokenId);
    }

}

// File: contracts/libs/ERC721.sol

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function totalSupply() public constant returns (uint256 total);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external constant returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external constant returns (bool);
}

// File: contracts/libs/ERC721Metadata.sol

/// @title The external contract that is responsible for generating metadata for the kitties,
///  it has one function that will return the data as bytes.
contract ERC721Metadata {
    /// @dev Given a token Id, returns a byte array that is supposed to be converted into string.
    function getMetadata(uint256 _tokenId, string) public constant returns (bytes32[4] buffer, uint256 count) {
        if (_tokenId == 1) {
            buffer[0] = "Hello World! :D";
            count = 15;
        } else if (_tokenId == 2) {
            buffer[0] = "I would definitely choose a medi";
            buffer[1] = "um length string.";
            count = 49;
        } else if (_tokenId == 3) {
            buffer[0] = "Lorem ipsum dolor sit amet, mi e";
            buffer[1] = "st accumsan dapibus augue lorem,";
            buffer[2] = " tristique vestibulum id, libero";
            buffer[3] = " suscipit varius sapien aliquam.";
            count = 128;
        }
    }
}

// File: contracts/libs/PaintingOwnership.sol

contract PaintingOwnership is BitpaintingBase, ERC721 {

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant name = "BitPaintings";
    string public constant symbol = "BP";

    ERC721Metadata public erc721Metadata;

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256(&#39;name()&#39;)) ^
        bytes4(keccak256(&#39;symbol()&#39;)) ^
        bytes4(keccak256(&#39;totalSupply()&#39;)) ^
        bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
        bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
        bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;transfer(address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;tokensOfOwner(address)&#39;)) ^
        bytes4(keccak256(&#39;tokenMetadata(uint256,string)&#39;));

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    function supportsInterface(bytes4 _interfaceID) external constant returns (bool)
    {
        // DEBUG ONLY
        //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    /// @dev Set the address of the sibling contract that tracks metadata.
    ///  CEO only.
    function setMetadataAddress(address _contractAddress) public onlyOwner {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }

    function _owns(address _claimant, uint256 _tokenId) internal constant returns (bool) {
        return bitpaintingStorage.getPaintingOwner(_tokenId) == _claimant;
    }

    function balanceOf(address _owner) public constant returns (uint256 count) {
        return bitpaintingStorage.getOwnershipTokenCount(_owner);
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        bitpaintingStorage.approve(_tokenId, _approved);
    }

    function _approvedFor(address _claimant, uint256 _tokenId)
        internal constant returns (bool) {
        return bitpaintingStorage.isApprovedFor(_tokenId, _claimant);
    }

    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_owns(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }

    function approve(
      address _to,
      uint256 _tokenId
    )
      external
      whenNotPaused
    {
      require(_owns(msg.sender, _tokenId));
      _approve(_tokenId, _to);

      Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(
      address _from,
      address _to,
      uint256 _tokenId
    )
        external whenNotPaused {
        _transferFrom(_from, _to, _tokenId);
    }

    function _transferFrom(
      address _from,
      address _to,
      uint256 _tokenId
    )
        internal
        whenNotPaused
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public constant returns (uint) {
      return bitpaintingStorage.paintingsCount();
    }

    function ownerOf(uint256 _tokenId)
        external constant returns (address) {
        return _ownerOf(_tokenId);
    }

    function _ownerOf(uint256 _tokenId)
        internal constant returns (address) {
        return bitpaintingStorage.getPaintingOwner(_tokenId);
    }

    function tokensOfOwner(address _owner)
        external constant returns(uint256[]) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
          return new uint256[](0);
        }

        uint256[] memory result = new uint256[](tokenCount);
        uint256 totalCats = totalSupply();
        uint256 resultIndex = 0;

        uint256 paintingId;

        for (paintingId = 1; paintingId <= totalCats; paintingId++) {
            if (bitpaintingStorage.getPaintingOwner(paintingId) == _owner) {
                result[resultIndex] = paintingId;
                resultIndex++;
            }
        }

        return result;
    }

    /// @dev Adapted from memcpy() by @arachnid (Nick Johnson <arachnid@notdot.net>)
    ///  This method is licenced under the Apache License.
    ///  Ref: https://github.com/Arachnid/solidity-stringutils/blob/2f6ca9accb48ae14c66f1437ec50ed19a0616f78/strings.sol
    function _memcpy(uint _dest, uint _src, uint _len) private constant {
      // Copy word-length chunks while possible
      for(; _len >= 32; _len -= 32) {
          assembly {
              mstore(_dest, mload(_src))
          }
          _dest += 32;
          _src += 32;
      }

      // Copy remaining bytes
      uint256 mask = 256 ** (32 - _len) - 1;
      assembly {
          let srcpart := and(mload(_src), not(mask))
          let destpart := and(mload(_dest), mask)
          mstore(_dest, or(destpart, srcpart))
      }
    }

    /// @dev Adapted from toString(slice) by @arachnid (Nick Johnson <arachnid@notdot.net>)
    ///  This method is licenced under the Apache License.
    ///  Ref: https://github.com/Arachnid/solidity-stringutils/blob/2f6ca9accb48ae14c66f1437ec50ed19a0616f78/strings.sol
    function _toString(bytes32[4] _rawBytes, uint256 _stringLength) private constant returns (string) {
      var outputString = new string(_stringLength);
      uint256 outputPtr;
      uint256 bytesPtr;

      assembly {
          outputPtr := add(outputString, 32)
          bytesPtr := _rawBytes
      }

      _memcpy(outputPtr, bytesPtr, _stringLength);

      return outputString;
    }

    /// @notice Returns a URI pointing to a metadata package for this token conforming to
    ///  ERC-721 (https://github.com/ethereum/EIPs/issues/721)
    /// @param _tokenId The ID number of the Kitty whose metadata should be returned.
    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external constant returns (string infoUrl) {
      require(erc721Metadata != address(0));
      bytes32[4] memory buffer;
      uint256 count;
      (buffer, count) = erc721Metadata.getMetadata(_tokenId, _preferredTransport);

      return _toString(buffer, count);
    }

    function withdraw() external onlyOwner {
        owner.transfer(this.balance);
    }
}

// File: contracts/BitpaintingPaintings.sol

contract BitpaintingPaintings is PaintingOwnership, IPaintings {

    uint version = 2;

    function release(
        uint _tokenId,
        uint _artistId,
        uint _releasedAt,
        uint8[] _gens,
        uint _auctionStartingPrice,
        uint _auctionEndingPrice,
        uint _auctionDuration,
        string _artist,
        string _name
    ) external canReleaseArtwork whenNotPaused {
        _createOriginalPainting(_tokenId, _artistId, _releasedAt);
        _approve(_tokenId, owner);
        bitpaintingStorage.setEditionLimits(_tokenId, _gens[0], _gens[1],_gens[2]);
        auctionsContract().createReleaseAuction(
            _tokenId,
            _auctionStartingPrice,
            _auctionEndingPrice,
            _releasedAt,
            _auctionDuration);
        bitpaintingStorage.setPaintingArtist(_tokenId, _artist);
        bitpaintingStorage.setPaintingName(_tokenId, _name);
    }

    function releaseNow(
        uint _tokenId,
        uint _artistId,
        uint8[] _gens,
        uint _auctionStartingPrice,
        uint _auctionEndingPrice,
        uint _auctionDuration,
        string _artist,
        string _name
    ) external canReleaseArtwork whenNotPaused {
        uint _releasedAt = now;
        _createOriginalPainting(_tokenId, _artistId, _releasedAt);
        _approve(_tokenId, owner);
        bitpaintingStorage.setEditionLimits(_tokenId, _gens[0], _gens[1],_gens[2]);
        auctionsContract().createReleaseAuction(
            _tokenId,
            _auctionStartingPrice,
            _auctionEndingPrice,
            now, // _releasedAt
            _auctionDuration);
        bitpaintingStorage.setPaintingArtist(_tokenId, _artist);
        bitpaintingStorage.setPaintingName(_tokenId, _name);
    }

    function cancel(uint _tokenId) external canCancelArtwork whenNotPaused {
        require(bitpaintingStorage.isOnAuction(_tokenId));
        require(bitpaintingStorage.canBeChanged(_tokenId));

        bitpaintingStorage.resetPainting(_tokenId);
        bitpaintingStorage.removeAuction(_tokenId);
        bitpaintingStorage.resetEditionLimits(_tokenId);
        bitpaintingStorage.purgeInformation(_tokenId);
    }

    function auctionsContract() internal returns (IAuctions auctions){
        uint _signature = uint(keccak256("auctions"));
        return IAuctions(bitpaintingStorage.contracts(_signature));
    }

    function createPainting(uint _tokenId)
        external canReleaseArtwork whenNotPaused {
        _createOriginalPainting(_tokenId, 1, now);
        _approve(_tokenId, owner);
    }

    function sendAsGift(address _to, uint _tokenId) external whenNotPaused {
        require(_to != address(0));
        require(_to != address(this));
        require(_owns(msg.sender, _tokenId));
        require(bitpaintingStorage.isReady(_tokenId));
        require(!bitpaintingStorage.hasEditionInProgress(_tokenId));

        if (bitpaintingStorage.isOnAuction(_tokenId)) {
            bitpaintingStorage.removeAuction(_tokenId);
        }

        bitpaintingStorage.sealForChanges(_tokenId);
        _transfer(msg.sender, _to, _tokenId);
        bitpaintingStorage.increaseOwnershipTokenCount(_to);
        bitpaintingStorage.decreaseOwnershipTokenCount(msg.sender);
    }

    function allTokenIds() public constant returns (uint[] tokenIds) {
        uint len = bitpaintingStorage.totalPaintingsCount();
        uint resultLen = bitpaintingStorage.paintingsCount();
        tokenIds = new uint[](resultLen);
        uint pointer = 0;
        for (uint index = 0; index < len; index++) {
            uint token = bitpaintingStorage.getPaintingIdAtIndex(index);
            if (bitpaintingStorage.isCanceled(token)) {
                continue;
            }
            tokenIds[pointer] = token;
            pointer++;
        }
    }

    function collectionOf(address _of) public constant returns (
            uint[] tokens,
            bool[] pending,
            bool[] forSale,
            bool[] locked,
            uint8[] generations,
            uint8[] speeds
        ) {

        uint tokenCount = bitpaintingStorage.totalPaintingsCount();
        uint length = balanceOf(_of);
        uint pointer;

        tokens = new uint[](length);
        pending = new bool[](length);
        forSale = new bool[](length);
        locked = new bool[](length);
        generations = new uint8[](length);
        speeds = new uint8[](length);

        for(uint index = 0; index < tokenCount; index++) {
            uint tokenId = bitpaintingStorage.getPaintingIdAtIndex(index);

            if (_ownerOf(tokenId) != _of) {
                continue;
            }

            uint _createdAt;
            (,,_createdAt,,,) = bitpaintingStorage.getPainting(tokenId);
            if (_createdAt == 0) {
                continue;
            }

            tokens[pointer] = tokenId;
            pending[pointer] = !bitpaintingStorage.isReady(tokenId);
            forSale[pointer] = (bitpaintingStorage.getAuctionStartedAt(tokenId) > 0);
            uint edition = bitpaintingStorage.lastEditionOf(tokenId);
            if (edition == 0) {
                locked[pointer] = false;
            } else {
                locked[pointer] = !bitpaintingStorage.isReady(edition);
            }
            generations[pointer] = bitpaintingStorage.getPaintingGeneration(tokenId);
            speeds[pointer] = bitpaintingStorage.getPaintingSpeed(tokenId);

            pointer++;
        }

    }

    function collectionCountsOf(address _of) public constant
        returns (uint total, uint pending, uint forSale) {
        uint tokenCount = totalSupply();

        for(uint index = 0; index < tokenCount; index++) {
            uint tokenId = bitpaintingStorage.getPaintingIdAtIndex(index);

            if (_ownerOf(tokenId) != _of) {
                continue;
            }

            total++;

            if (bitpaintingStorage.isReady(tokenId)) {
                if (bitpaintingStorage.getAuctionStartedAt(tokenId) > 0) {
                    forSale++;
                }

                continue;
            }

            if (!bitpaintingStorage.isReady(tokenId)) {
                pending++;
                continue;
            }

        }

    }

    function signature() external constant returns (uint _signature) {
        return uint(keccak256("paintings"));
    }

}