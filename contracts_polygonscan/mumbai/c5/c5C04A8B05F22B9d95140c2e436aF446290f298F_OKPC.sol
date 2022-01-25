/*
////////////////////////////////////////////////////////////////
////%%//%%%%%%//%%//%%%%%%//%%////%%//%%%%%%//%%//%%%%%%//%%////
////%%//////%%//%%//////%%//%%////%%//%%//////%%//%%//////%%////
////%%%%%%//%%//%%%%%%//%%//%%%%%%%%//%%//%%%%%%//%%//%%%%%%////
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
//%%////,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,////%%//
//%%%%//,,,,%%,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,%%,,,,////%%//
////////,,,,,,,,%%%%%%%%,,,,,,%%%%,,,,,,%%%%%%%%,,,,,,,,////////
////%%//,,,,,,%%,,,,,,,,%%,,,,,,,,,,,,%%,,,,,,,,%%,,,,,,//%%////
//%%////,,,,%%,,,,%%%%,,,,%%,,%%%%,,%%,,,,%%%%,,,,%%,,,,////%%//
////////,,,,%%,,,,,,,,,,,,%%,,%%%%,,%%,,,,,,,,,,,,%%,,,,////////
//%%%%//,,,,,,%%%%%%%%%%%%,,,,,,,,,,,,%%%%%%%%%%%%,,,,,,////%%//
//%%////,,,,,,,,,,,,,,,,,,,,,,%%%%,,,,,,,,,,,,,,,,,,,,,,//%%////
////%%//,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,////%%//
//%%%%//,,,,%%%%,,%%%%,,%%%%,,%%%%,,%%%%,,%%%%,,%%%%,,,,//%%////
////%%//,,,,,,,,,,%%%%,,%%%%,,%%%%,,,,%%,,%%%%,,,,,,,,,,////%%//
//%%////,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//%%////
////////,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,////////
////////////////////////////////////////////////////////////////
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
////////////////////////////////////////////////////////////////
////%%%%%%//%%//%%//%%%%%%//%%%%%%////%%//%%//%%//%%//%%//%%////
////%%%%%%//%%//%%//%%//////%%%%%%////%%//%%//%%//%%//%%//%%////
////////////////////////////////////////////////////////////////
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {IProxyRegistry} from './lib/IProxyRegistry.sol';

import {OKPCSupply} from './OKPCSupply.sol';
import {OKPCArt} from './OKPCArt.sol';
import {OKPCPayments} from './OKPCPayments.sol';
import {OKPCRoyalties} from './OKPCRoyalties.sol';
import {OKPCAirdrop} from './OKPCAirdrop.sol';
import {OKPCExpansions} from './OKPCExpansions.sol';
import {IOKPCMetadata} from './interfaces/IOKPCMetadata.sol';

contract OKPC is
  Ownable,
  ReentrancyGuard,
  OKPCSupply,
  OKPCPayments,
  OKPCArt,
  OKPCAirdrop,
  OKPCExpansions,
  OKPCRoyalties
{
  // *** METADATA & RENDERER *** //
  address public metadataAddress;

  // *** ERRORS *** //
  error InvalidTokenID();

  // *** ETC *** //
  address private _openseaProxyRegistry;
  bool private _openseaProxyActive = true;

  // *** CONSTRUCTOR *** //
  constructor() OKPCSupply("oooo", "oooo") {}

  // ***** PHASES ***** //

  /// @notice Allows the owner to start the artist's minting phase.
  /// @dev [Admin] Switches the artist minting flag to true, if the merkle root is set and a minimum amount of art is uploaded.
  function startArtistMint() public onlyOwner {
    // Ensure a merkle root is set for the artist list
    if (OKPCAirdrop._artistsMerkleRoot == bytes32(0))
      revert OKPCAirdrop.MissingConfiguration();

    // Ensure the minimum amount of initial art has been uploaded
    if (OKPCArt._artCount < OKPCArt.MIN_ART) revert NotEnoughArt();

    // Enable artist mint
    phase = Phase.ARTISTS;
  }

  /// @notice Allows the owner to start the social minting phase.
  /// @dev [Admin] Switches the social minting flag to true, if the merkle root is set.
  function startSocialMint() public onlyOwner {
    // Ensure a merkle root is set for the social list
    if (OKPCAirdrop._socialMerkleRoot == bytes32(0))
      revert OKPCAirdrop.MissingConfiguration();
      
    // Enable social mint
    phase = Phase.SOCIAL;
  }

  /// @notice Allows the owner to start the public minting phase.
  /// @dev [Admin] Switches the public minting flag to true.
  function startPublicMint() public onlyOwner {
    if (phase < Phase.SOCIAL) revert MintingNotOpen();

    // Enable public mint
    phase = Phase.PUBLIC;
  }

  // ***** INITIAL ART ***** //

  /// @notice Allows the owner to upload initial art before minting opens.
  /// @dev [Admin] Loops through posted art data (including artist addresses) and stores everything.
  /// @param artists An array of artist addresses
  /// @param titles An array of art titles
  /// @param data1 An array of data1 bytes
  /// @param data2 An array of data2 bytes
  function createInitialArt(
    address[] calldata artists,
    string[] calldata titles,
    uint256[] calldata data1,
    uint256[] calldata data2
  ) external onlyOwner onlyWhenInitializing {
    // Ensure all arrays are the same length
    if (
      artists.length != titles.length ||
      artists.length != data1.length ||
      artists.length != data2.length
    ) revert OKPCArt.InvalidArtData();

    // Ensure the contract doesn't accept more than MIN_ART amount of initial art
    if (_artCount + artists.length > MIN_ART)
      revert OKPCArt.MaxArtAlreadyCreated();

    // Store each artwork
    for (uint256 i = 0; i < artists.length; i++)
      OKPCArt._createArt(artists[i], titles[i], data1[i], data2[i]);
  }

  // *** ART CREATION *** //

  /// @notice Submit art to the OKPC collection if you're on the artist list.
  /// @param title The title of your artwork.
  /// @param data1 A uint256 value representing the first half of the artwork data.
  /// @param data2 A uint256 value representing the second half of the artwork data.
  /// @param merkleProof A Merkle proof of the caller's address in the artist list.
  function createArt(
    string memory title,
    uint256 data1,
    uint256 data2,
    bytes32[] calldata merkleProof
  ) public onlyOKPCOwner onlyValidArtistMerkleProof(merkleProof) {
    OKPCArt._createArt(msg.sender, title, data1, data2);
  }

  // *********** Art *********** //
  // /// @notice Set custom art on your OKPC.
  // /// @dev Ensure exactly 0.01 ETH is specified in the payableAmount field.
  // /// @param title The title of yourthe art.
  // /// @param data1 A uint256 value representing the first half of the art data.
  // /// @param data2 A uint256 value representing the second half of the art data.
  // function setArt(
  //   uint256 pcId,
  //   string memory title,
  //   uint256 data1,
  //   uint256 data2
  // ) public payable {
  //   if (ownerOf(pcId) != msg.sender) revert NotAuthorized();
  //   if (msg.value != CREATE_PRICE) revert IncorrectPaymentAmount();
  //   if (_denyList[msg.sender]) revert NotAuthorized();
  //   _createArt(Art(msg.sender, title, data1, data2, 0));
  //   ownerBalance += CREATE_PRICE;
  // }

  // *** METADATA *** //
  function tokenURI(uint256 tokenID)
    public
    view
    override
    returns (string memory)
  {
    if (!_exists(tokenID)) revert InvalidTokenID();

    return
      IOKPCMetadata(metadataAddress).tokenURI(
        tokenID,
        insight(tokenID),
        OKPCArt.artCountForOKPC[tokenID],
        OKPCArt.art[OKPCArt.activeArtForOKPC[tokenID]]
      );
  }

  function renderArt(uint256 artID, uint256 colorIndex)
    public
    view
    returns (string memory)
  {
    bytes memory data = abi.encodePacked(art[artID].data1, art[artID].data2);

    return IOKPCMetadata(metadataAddress).renderArt(data, colorIndex);
  }

  // *** METADATA & RENDERER *** //
  function setMetadataAddress(address addr) public onlyOwner {
    metadataAddress = addr;
  }

  // *** MODERATION *** //
  function setDenyListStatus(address addr, bool state) public onlyOwner {
    _denyList[addr] = state;
  }

  // *** MINT *** //
  // ***** ARTISTS ***** //
  /// @notice Allows anyone on the artist list to mint an OKPC during the artist minting phase.
  /// @dev Mints an OKPC to the caller if they are on the list and haven't already claimed one.
  /// @dev OKPC ids will be between 1 - 128.
  /// @param merkleProof A Merkle proof of the caller's address in the artist list.
  function mint_ArtistList(bytes32[] calldata merkleProof)
    external
    OKPCSupply.onlyWhenAvailableForArtists
    OKPCAirdrop.onlyValidArtistMerkleProof(merkleProof)
  {
    // Ensure the artist hasn't already claimed their limit of free OKPCs
    if (
      OKPCAirdrop.artistMintsClaimed[msg.sender] ==
      OKPCAirdrop.ARTIST_CLAIMABLE_SUPPLY
    ) revert OKPCAirdrop.AlreadyClaimed();

    // Ensure more than the maximum number of artist OKPCs aren't minted.
    // This shouldn't be true unless the merkle tree has more than RESERVED_SUPPLY / ARTIST_CLAIMABLE_SUPPLY addresses.
    if (OKPCSupply._artistMintCount == OKPCSupply.ARTIST_SUPPLY)
      revert OKPCSupply.MaxSupplyAlreadyMinted();

    // Increment counters and mint the OKPC
    OKPCAirdrop.artistMintsClaimed[msg.sender]++;
    OKPCSupply._artistMintCount++;
    uint256 pcId = OKPCSupply._artistMintCount;
    OKPCSupply._mint(pcId);
    OKPCArt._collectInitialArt(pcId);
  }

  // ***** SOCIAL ***** //
  /// @notice Allows anyone on the social list to mint an OKPC during the early minting phase.
  /// @dev Mints an OKPC to the caller if they are on the list and haven't already claimed one.
  /// @dev OKPC ids will be between 129 - 3968.
  /// @param merkleProof A Merkle proof of the caller's address in the social list.
  function mint_SocialList(bytes32[] calldata merkleProof)
    external
    onlyWhenAvailableForSocial
    onlyValidSocialMerkleProof(merkleProof)
  {
    // Ensure this address hasn't already claimed their free OKPC
    if (socialMintClaimed[msg.sender]) revert AlreadyClaimed();

    // Increment counter, log claim for address, and mint the OKPC
    _publicMintCount++;
    socialMintClaimed[msg.sender] = true;

    // Token IDs have a minimum of ARTIST_SUPPLY + 1 to ensure artist OKPCs are reserved.
    uint256 pcId = _publicMintCount + ARTIST_SUPPLY;
    OKPCSupply._mint(pcId);
    OKPCArt._collectInitialArt(pcId);
  }

  // ***** PUBLIC ***** //
  /// @notice Mint an OKPC.
  /// @dev Ensure exactly 0.08 ETH is specified in the payableAmount field.
  /// @dev OKPC ids will be between 129 - 3968.
  function mint() public payable onlyWhenAvailableForAll {
    // Ensure correct payment amount has been sent.
    if (msg.value != PC_MINT_PRICE) revert IncorrectPaymentAmount();

    // Ensure more than PUBLIC_SUPPLY OKPCs can't be minted.
    if (OKPCSupply._publicMintCount >= OKPCSupply.PUBLIC_SUPPLY)
      revert OKPCSupply.MaxSupplyAlreadyMinted();

    // Increment owner's claimable ETH balance.
    OKPCPayments.ownerWithdrawable += PC_MINT_PRICE;

    // Increment counter and mint the OKPC
    OKPCSupply._publicMintCount++;

    // Token IDs have a minimum of ARTIST_SUPPLY + 1 to ensure artist OKPCs are reserved.
    uint256 pcId = OKPCSupply._publicMintCount + OKPCSupply.ARTIST_SUPPLY;
    OKPCSupply._mint(pcId);
    OKPCArt._collectInitialArt(pcId);
  }

  /// @notice Mint a reserved OKPC
  /// @dev OKPC ids will be between 3969 - 4096.
  /// @dev [Admin] Mints the specified number of reserved OKPCs to the owner.
  function mintReserved(uint16 amount) external onlyOwner {
    // Ensure more than RESERVED_SUPPLY OKPCs can't be minted.
    if (OKPCSupply._reservedMintCount + amount >= OKPCSupply.RESERVED_SUPPLY)
      revert OKPCSupply.MaxSupplyAlreadyMinted();

    // Set minimum tokenID amount to ARTIST_SUPPLY + PUBLIC SUPPLY + 1 to ensure artist OKPCs are reserved.
    uint256 count = OKPCSupply.ARTIST_SUPPLY +
      OKPCSupply.PUBLIC_SUPPLY +
      OKPCSupply._reservedMintCount;

    // Mint the OKPCs
    for (uint256 i = 1; i <= amount; i++) {
      uint256 pcId = count + i;
      OKPCSupply._mint(pcId);
      OKPCArt._collectInitialArt(pcId);
    }

    // Increment reserved mint count
    OKPCSupply._reservedMintCount += amount;
  }

  // *** ART *** //
  /// @notice Collect an artwork on your OKPC.
  /// @dev Ensure exactly 0.01 ETH is specified in the payableAmount field. 100% of this goes to the artist. If you are the artist, you can write 0.
  /// @param pcId The id of the OKPC to collect to. You need to own the OKPC to use this.
  /// @param artId A id of the art you'd like to collect.
  /// @param makeActive Set to true if you'd like to switch your OKPC to displaying this art now too.
  function collectArt(
    uint256 pcId,
    uint256 artId,
    bool makeActive
  ) public payable onlyOKPCOwnerOf(pcId) {
    address artist = art[artId].artist;
    if (artist != msg.sender && msg.value != COLLECT_PRICE)
      revert IncorrectPaymentAmount();

    // Add to artist's withdrawable balance
    OKPCPayments.artistWithdrawable[artist] += msg.value;

    // Collect art on OKPC
    OKPCArt._collectArt(pcId, artId);

    // Set art if requested
    if (makeActive) OKPCArt._setArt(pcId, artId);
  }

  /// @notice Collect multiple artworks on your OKPC.
  /// @dev Ensure exactly 0.01 ETH * the number of artworks you are collecting is specified in the payableAmount field. 100% of this goes to the artists.
  /// @param pcId The id of the OKPC to collect to. You need to own the OKPC to use this.
  /// @param artIds An array of ids for the art you'd like to collect.
  function collectArtMultiple(uint256 pcId, uint256[] calldata artIds)
    public
    payable
    onlyOKPCOwnerOf(pcId)
  {
    // Ensure correct payment amount has been sent.
    if (msg.value != COLLECT_PRICE * artIds.length)
      revert IncorrectPaymentAmount();

    for (uint256 i = 0; i < artIds.length; i++) {
      // Add to artist's withdrawable balance
      OKPCPayments.artistWithdrawable[
        OKPCArt.art[artIds[i]].artist
      ] += COLLECT_PRICE;

      // Collect art on OKPC
      OKPCArt._collectArt(pcId, artIds[i]);
    }
  }

  /// @notice Switch the displayed art on your OKPC.
  /// @param pcId The id of the OKPC to collect to. You need to own the OKPC to use this.
  /// @param artId A id of the art you'd like to display.
  function changeArt(uint256 pcId, uint256 artId)
    public
    onlyOKPCOwnerOf(pcId)
    onlyOKPCArtCollectorOf(pcId, artId)
  {
    OKPCArt._setArt(pcId, artId);
  }

  // ******** OpenSea ******** //
  function setOpenseaProxyActive(bool active) public onlyOwner {
    _openseaProxyActive = active;
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
  {
    IProxyRegistry proxyRegistry = IProxyRegistry(_openseaProxyRegistry);
    if (
      _openseaProxyActive && address(proxyRegistry.proxies(owner)) == operator
    ) {
      return true;
    }
    return super.isApprovedForAll(owner, operator);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Opensea Proxy Registry
interface IProxyRegistry {
    function proxies(address owner) external view returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import {Insightful721, ERC721} from './lib/Insightful721.sol';

abstract contract OKPCSupply is Ownable, ReentrancyGuard, Insightful721 {
  // *** CONFIG *** //
  uint16 public constant ARTIST_SUPPLY = 128;
  uint16 public constant RESERVED_SUPPLY = 128;
  uint16 public constant PUBLIC_SUPPLY = 4096 - ARTIST_SUPPLY - RESERVED_SUPPLY;
  uint256 public constant PC_MINT_PRICE = 0.08 ether;

  // *** STORAGE *** //
  enum Phase {
    INITIALIZING,
    ARTISTS,
    SOCIAL,
    PUBLIC
  }
  Phase public phase;
  uint16 internal _artistMintCount;
  uint16 internal _reservedMintCount;
  uint16 internal _publicMintCount;

  // *** EVENTS & ERRORS *** //
  error NotOKPCOwner();
  error AlreadyInitialized();
  error MintingNotOpen();
  error NotEnoughArt();
  error MaxSupplyAlreadyMinted();

  // *** MODIFIERS *** //
  // ***** OKPC OWNERS ***** //
  modifier onlyOKPCOwner() {
    if (balanceOf(msg.sender) == 0) revert NotOKPCOwner();
    _;
  }
  modifier onlyOKPCOwnerOf(uint256 tokenId) {
    if (ownerOf(tokenId) != msg.sender) revert NotOKPCOwner();
    _;
  }
  // ***** MINT PHASES ***** //
  modifier onlyWhenInitializing() {
    if (phase != Phase.INITIALIZING) revert AlreadyInitialized();
    _;
  }
  modifier onlyWhenAvailableForArtists() {
    if (phase >= Phase.ARTISTS) revert MintingNotOpen();
    _;
  }
  modifier onlyWhenAvailableForSocial() {
    if (phase >= Phase.SOCIAL) revert MintingNotOpen();
    _;
  }
  modifier onlyWhenAvailableForAll() {
    if (phase != Phase.PUBLIC) revert MintingNotOpen();
    _;
  }

  // *** CONSTRUCTOR *** //
  constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

  /// @notice Internal minting function for OKPCs.
  /// @dev Should mint an OKPC to the caller with the specified tokenId.
  /// @dev This function is only called internally.
  /// @param pcId The tokenId of the OKPC to mint.
  function _mint(uint256 pcId) internal {
    _mint(msg.sender, pcId);
  }

  /// @notice Total supply of OKPCs.
  /// @dev Should count all the minted OKPCs and return the total.
  function totalSupply() public view returns (uint256) {
    return _artistMintCount + _publicMintCount + _reservedMintCount;
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

abstract contract OKPCArt {
  // *** CONFIG *** //
  uint8 public constant MIN_ART = 128;
  uint8 public constant MAX_ART_PER_ARTIST = 8;
  uint16 public constant MAX_COLLECTIONS_PER_ART = 1024;
  uint256 public constant CREATE_PRICE = 0.01 ether;
  uint256 public constant COLLECT_PRICE = 0.01 ether;

  // *** STORAGE *** //
  struct Art {
    address artist;
    string title;
    uint256 data1;
    uint256 data2;
    uint256 collected;
  }
  uint256 public _artCount;
  mapping(uint256 => Art) public art;
  mapping(address => uint256) public artistArtCount;
  mapping(uint256 => uint256) public activeArtForOKPC;
  mapping(uint256 => mapping(uint256 => bool)) public artCollectedByOKPC;
  mapping(uint256 => uint256) public artCountForOKPC;
  mapping(bytes32 => bool) internal _artHashRegister;
  mapping(address => bool) internal _denyList;

  event ArtCreated(uint256 indexed artId, address artist);
  event ArtCollected(uint256 pcId, uint256 artId);
  event ArtChanged(uint256 pcId, uint256 artId);
  event ArtTransferred(uint256 fromOKPCId, uint256 toOKPCId, uint256 artId);

  error InvalidArtData();
  error ArtNotCollected();
  error ArtCannotBeActive();
  error ArtCollectedMaximumTimes();
  error ArtAlreadyCollected();
  error DuplicateArt();
  error MaxArtAlreadyCreated();
  error ArtNotFound();
  error IncorrectPaymentAmount();

  // *** MODIFIERS *** //
  modifier onlyWhenArtExists(uint256 artId) {
    if (art[artId].artist == address(0)) revert ArtNotFound();
    _;
  }
  modifier onlyOKPCArtCollectorOf(uint256 pcId, uint256 artId) {
    if (!artCollectedByOKPC[pcId][artId]) revert ArtNotCollected();
    _;
  }

  function _createArt(
    address artist,
    string memory title,
    uint256 data1,
    uint256 data2
  ) internal {
    // Validate art data
    if (bytes(title).length > 16) revert InvalidArtData();
    // if (data1 == 0 && data2 == 0) revert InvalidArtData();

    // Check if artist has already created the maximum number of artworks
    if (artistArtCount[artist] == MAX_ART_PER_ARTIST)
      revert MaxArtAlreadyCreated();

    // Check uniqueness
    bytes32 hash = keccak256(abi.encodePacked(data1, data2));
    if (_artHashRegister[hash]) revert DuplicateArt();

    // Create art
    _artCount++;
    art[_artCount] = Art(artist, title, data1, data2, 0);
    artistArtCount[artist]++;
    _artHashRegister[hash] = true;

    emit ArtCreated(_artCount, artist);
  }

  // *** COLLECTOR FUNCTIONS *** //

  function _collectInitialArt(uint256 pcId) internal {
    // Choose initial art sequentially based on pcId
    uint256 artId = ((pcId - 1) % 128) + 1;

    // Store art collection data and emit event
    artCountForOKPC[pcId] = 1;
    artCollectedByOKPC[pcId][artId] = true;
    emit OKPCArt.ArtCollected(pcId, artId);

    // Set active artwork and emit event
    activeArtForOKPC[pcId] = artId;
    emit ArtChanged(pcId, artId);
  }

  function _collectArt(uint256 pcId, uint256 artId) internal {
    Art memory _art = art[artId];
    if (artCollectedByOKPC[pcId][artId]) revert ArtAlreadyCollected();
    if (_art.collected >= MAX_COLLECTIONS_PER_ART)
      revert ArtCollectedMaximumTimes();

    _art.collected++;
    artCollectedByOKPC[pcId][artId] = true;
    artCountForOKPC[pcId]++;
    emit ArtCollected(pcId, artId);
  }

  function _setArt(uint256 pcId, uint256 artId) internal {
    activeArtForOKPC[pcId] = artId;
    emit ArtChanged(pcId, artId);
  }

  // *** EXPANSIONS *** //

  // Only available via OKPCExpansions Community
  function _deleteArt(uint256 artId, bool addToDenyList) internal {
    artistArtCount[art[artId].artist]--;
    if (addToDenyList) _denyList[art[artId].artist] = true;
    delete art[artId].title;
    delete art[artId].data1;
    delete art[artId].data2;
    delete art[artId].artist;
  }

  // Only available via OKPCExpansions Community
  function _replaceDeletedArt(uint256 artId, Art calldata artwork) internal {
    if (art[artId].artist != address(0)) revert InvalidArtData();
    if (artwork.data1 == 0 && artwork.data2 == 0) revert InvalidArtData();
    if (bytes(artwork.title).length > 16) revert InvalidArtData();
    if (artwork.artist == address(0)) revert InvalidArtData();
    bytes32 hash = keccak256(abi.encodePacked(artwork.data1, artwork.data2));
    if (_artHashRegister[hash]) revert DuplicateArt();
    if (artistArtCount[artwork.artist] >= MAX_ART_PER_ARTIST)
      revert MaxArtAlreadyCreated();
    art[artId].artist = artwork.artist;
    art[artId].title = artwork.title;
    art[artId].data1 = artwork.data1;
    art[artId].data2 = artwork.data2;
  }

  // Only available via OKPCExpansions Marketplace
  function _transferArt(
    uint256 fromOKPCId,
    uint256 toOKPCId,
    uint256 artId
  ) internal {
    // Ensure fromOKPCId owns the art being transferred
    if (!artCollectedByOKPC[fromOKPCId][artId]) revert ArtNotCollected();
    // Ensure toOKPCId doesn't already own this art
    if (artCollectedByOKPC[toOKPCId][artId]) revert ArtAlreadyCollected();
    // Ensure fromOKPCId doesn't have this artwork active currently
    if (activeArtForOKPC[fromOKPCId] == artId) revert ArtCannotBeActive();

    // Remove art from first OKPC
    artCollectedByOKPC[fromOKPCId][artId] = false;
    artCountForOKPC[fromOKPCId]--;

    // Add art to second OKPC
    artCollectedByOKPC[toOKPCId][artId] = true;
    artCountForOKPC[toOKPCId]++;

    emit ArtTransferred(fromOKPCId, toOKPCId, artId);
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';

abstract contract OKPCPayments is Ownable, ReentrancyGuard {
  // *** STORAGE *** //
  uint256 public ownerWithdrawable;
  mapping(address => uint256) public artistWithdrawable;

  // *** EVENTS & ERRORS *** //
  event OwnerDeposit(uint256 amount);
  event OwnerWithdraw(uint256 amount);
  event ArtistDeposit(address indexed artist, uint256 amount);
  event ArtistWithdraw(address indexed artist, uint256 amount);
  error ZeroBalance();
  error TransferFailed();

  // *** METHODS *** //

  /// @notice Collect owner payments.
  function withdrawOwnerBalance() public onlyOwner nonReentrant {
    // Ensure there is a balance to withdraw
    if (ownerWithdrawable == 0) revert ZeroBalance();

    // Transfer the full balance to the caller
    // nonReentrant ensures the reciever can't re-enter the contract
    (bool success, ) = msg.sender.call{value: ownerWithdrawable}('');
    if (!success) revert TransferFailed();

    emit OwnerWithdraw(ownerWithdrawable);
    ownerWithdrawable = 0;
  }

  /// @notice Collect your payments if you're an OKPC artist.
  function withdrawArtistBalance() public nonReentrant {
    // Ensure there is a balance to withdraw
    uint256 balance = artistWithdrawable[msg.sender];
    if (balance == 0) revert ZeroBalance();

    // Transfer the full balance to the caller
    // nonReentrant ensures the reciever can't re-enter the contract
    (bool success, ) = msg.sender.call{value: balance}('');
    if (!success) revert TransferFailed();

    emit ArtistWithdraw(msg.sender, balance);
    artistWithdrawable[msg.sender] = 0;
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import {IERC2981} from '@openzeppelin/contracts/interfaces/IERC2981.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

abstract contract OKPCRoyalties is Ownable, IERC2981 {
  uint256 private constant ROYALTY = 640; // out of 10,000 as %

  function royaltyInfo(uint256, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (owner(), (salePrice * ROYALTY) / 10000);
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

abstract contract OKPCAirdrop is Ownable {
  // *** CONFIG *** //
  uint16 public constant ARTIST_CLAIMABLE_SUPPLY = 2;

  // *** STORAGE *** //
  bytes32 internal _socialMerkleRoot;
  bytes32 internal _artistsMerkleRoot;
  mapping(address => bool) public socialMintClaimed;
  mapping(address => uint8) public artistMintsClaimed;

  // *** EVENTS & ERRORS *** //
  error AlreadyClaimed();
  error NotAuthorized();
  error MissingConfiguration();

  // *** MODIFIERS *** //
  modifier onlyValidArtistMerkleProof(bytes32[] calldata merkleProof) {
    if (
      !MerkleProof.verify(
        merkleProof,
        _artistsMerkleRoot,
        keccak256(abi.encodePacked(msg.sender))
      )
    ) revert NotAuthorized();
    _;
  }
  modifier onlyValidSocialMerkleProof(bytes32[] calldata merkleProof) {
    if (
      !MerkleProof.verify(
        merkleProof,
        _socialMerkleRoot,
        keccak256(abi.encodePacked(msg.sender))
      )
    ) revert NotAuthorized();
    _;
  }

  // *** ADMIN METHODS *** //
  function setArtistsMerkleRoot(bytes32 newRoot) public onlyOwner {
    _artistsMerkleRoot = newRoot;
  }

  function setSocialMerkleRoot(bytes32 newRoot) public onlyOwner {
    _socialMerkleRoot = newRoot;
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import {OKPCArt} from './OKPCArt.sol';
import {OKPCPayments} from './OKPCPayments.sol';

abstract contract OKPCExpansions is Ownable, OKPCPayments, OKPCArt {
  // *** STORAGE *** //
  address public messagingAddress;
  address public communityAddress;
  address public marketplaceAddress;

  error NotCommunity();
  error NotMarketplace();
  error NotOwnerOrCommunity();

  // *** MODIFIERS *** //

  modifier onlyCommunity() {
    if (msg.sender != communityAddress) revert NotCommunity();
    _;
  }
  modifier onlyOwnerOrCommunity() {
    if (msg.sender != owner() && msg.sender != communityAddress)
      revert NotOwnerOrCommunity();
    _;
  }
  modifier onlyMarketplace() {
    if (msg.sender != marketplaceAddress) revert NotMarketplace();
    _;
  }

  // *** COMMUNITY *** //

  function setCommunityAddress(address addr) public onlyOwnerOrCommunity {
    communityAddress = addr;
  }

  function deleteArt(uint256 artId, bool addToDenyList) external onlyCommunity {
    OKPCArt._deleteArt(artId, addToDenyList);
  }

  function replaceDeletedArt(uint256 artId, Art calldata artwork)
    external
    onlyCommunity
  {
    OKPCArt._replaceDeletedArt(artId, artwork);
  }

  // *** MESSAGING *** //

  function setMessagingAddress(address addr) public onlyOwnerOrCommunity {
    messagingAddress = addr;
  }

  // *** MARKETPLACE *** //

  function setMarketplaceAddress(address addr) public onlyOwnerOrCommunity {
    marketplaceAddress = addr;
  }

  function transferArt(
    uint256 fromOKPCId,
    uint256 toOKPCId,
    uint256 artId
  ) public onlyMarketplace {
    OKPCArt._transferArt(fromOKPCId, toOKPCId, artId);
  }

  function addToArtistBalance(address artist) public payable onlyMarketplace {
    OKPCPayments.artistWithdrawable[artist] += msg.value;
  }

  function addToOwnerBalance() public payable onlyMarketplace {
    OKPCPayments.ownerWithdrawable += msg.value;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import {OKPCArt} from '../OKPCArt.sol';
import {IOKPCParts} from './IOKPCParts.sol';

interface IOKPCMetadata {
  error InvalidTokenID();
  error NotEnoughPixelData();

  struct Parts {
    IOKPCParts.Vector headband;
    IOKPCParts.Vector rightSpeaker;
    IOKPCParts.Vector leftSpeaker;
    IOKPCParts.Color color;
    string word;
  }

  function tokenURI(
    uint256 tokenId,
    uint256 clockSpeed,
    uint256 artCollected,
    OKPCArt.Art memory art
  ) external view returns (string memory);

  function renderArt(bytes memory art, uint256 colorIndex)
    external
    view
    returns (string memory);

  function getParts(uint256 tokenId) external view returns (Parts memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

abstract contract Insightful721 is Ownable, ERC721 {
  // * CONFIG * //
  uint256 private maxMultiplier = 24;

  // * STORAGE * //
  struct XP {
    uint256 savedXP;
    uint256 lastSaveBlock;
  }
  mapping(uint256 => XP) public insightMap;

  // * PUBLIC READ FUNCTION * //
  function insight(uint256 tokenID) public view returns (uint256) {
    uint256 lastBlock = insightMap[tokenID].lastSaveBlock;
    if (lastBlock == 0) {
      return 1;
    }
    uint256 delta = block.number - lastBlock;
    uint256 multiplier = delta / 200000;
    if (multiplier > maxMultiplier) {
      multiplier = maxMultiplier;
    }
    uint256 total = insightMap[tokenID].savedXP +
      ((delta * (multiplier + 1)) / 10000);
    if (total < 1) total = 1;
    return total;
  }

  // * TOKEN TRANSFER OVERRIDES * //
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    super._beforeTokenTransfer(from, to, tokenId);
    save(tokenId);
  }

  function save(uint256 tokenID) internal {
    insightMap[tokenID].savedXP = insight(tokenID);
    insightMap[tokenID].lastSaveBlock = block.number;
  }

  // * ADMIN FUNCTIONS * //
  function setMaxMultiplier(uint256 multiplier) public onlyOwner {
    maxMultiplier = multiplier;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
        _setApprovalForAll(_msgSender(), operator, approved);
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

// TODO: rename from parts to something else?
interface IOKPCParts {
  // errors
  error IndexOutOfBounds(uint256 index, uint256 maxIndex);

  // structures
  struct Color {
    bytes6 light;
    bytes6 regular;
    bytes6 dark;
    string name;
  }

  struct Vector {
    string data;
    string name;
  }

  // functions
  function getColor(uint256 index) external view returns (Color memory);

  function getHeadband(uint256 index) external view returns (Vector memory);

  function getSpeaker(uint256 index) external view returns (Vector memory);

  // TODO: rename from word to something else? The name of the OKPC?
  function getWord(uint256 index) external view returns (string memory);
}