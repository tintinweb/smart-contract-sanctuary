// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./GaucheBase.sol";
import "./LibGauche.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GaucheGrimoire is GaucheBase {
    uint256 constant MAX_LEVEL = 255;

    event WordAdded(uint256 indexed _tokenId, bytes32 _wordHash, uint256 _wordSlot, uint256 _wordId);
    event HashUpdated(uint256 indexed _tokenId, bytes32 _hash);

    mapping(uint256 => bytes32) public tokenHashes; // Offset of tokenId + wordId. Tracked by spent total in gaucheToken
    GaucheLevel[] public gaucheLevels;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseURI,
        uint64 _pricePerToken,
        address _accessTokenAddress,
        address _artistAddress,
        address _developerAddress
    ) GaucheBase(_tokenName, _tokenSymbol, _baseURI, _pricePerToken, _accessTokenAddress, _artistAddress, _developerAddress) {
        gaucheLevels.push(GaucheLevel(1, _pricePerToken, artistAddress, "https://neophorion.art/api/projects/GaucheGrimoire/metadata/"));
    }

        // Modifiers

    modifier notNullWord(bytes32 _wordHash) {
        checkNotNullWord(_wordHash);
        _;
    }

    modifier mustBeBelowMaxLevel(uint256 _tokenId) {
        checkMaxLevel(_tokenId);
        _;
    }

    modifier tokenExists(uint256 _tokenId) {
        checkTokenExists(_tokenId);
        _;
    }

    function checkTokenExists(uint256 _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "GG: Token does not exist");
    }

    function getProjectDetails(uint256 _gLevelId) public view returns (GaucheLevel memory gLevel) {
        require(_gLevelId <= gaucheLevels.length, "GG: Max 255");
        gLevel = gaucheLevels[_gLevelId];
        return gLevel;
    }

    function getProjectLevel() public view returns (uint256) {
        return gaucheLevels.length;
    }
    function addProjectLevel(uint8 _wordPrice, uint64 _price, address _artistAddress, string memory _tokenURI)  onlyAllowed(Auth.Owner) public {
        require(gaucheLevels.length <= MAX_LEVEL, "GG: Max 255");
        gaucheLevels.push(GaucheLevel(_wordPrice, _price, _artistAddress, _tokenURI));
    }

    // Public functions for state changes
    function spendRealityChange(uint256 _tokenToChange, bytes32 _wordHash)
        onlyIfTokenOwner(_tokenToChange)
        isNotMode(SalesState.Finalized)
        notNullWord(_wordHash)
        mustBeBelowMaxLevel(_tokenToChange)
    public payable {
        uint256 tokenLevel = getLevel(_tokenToChange);
        uint8 levelWordPrice = gaucheLevels[tokenLevel].wordPrice;
        require(getFree(_tokenToChange) >= levelWordPrice, "GG: No free lvl");
        uint256 levelEthPrice = gaucheLevels[tokenLevel].price;
        require(msg.value >= levelEthPrice, "GG: Too cheap");

        _changeReality(_tokenToChange, _wordHash, tokenLevel, levelWordPrice);
    }

    function burnIntoToken(uint256 _tokenToBurn, uint256 _tokenToChange)
        onlyIfTokenOwner(_tokenToBurn)
        onlyIfTokenOwner(_tokenToChange)
        mustBeBelowMaxLevel(_tokenToChange)
        isMode(SalesState.Maintenance)
    public {
        // Get how many free slots the burnt token has
        uint256 burntTokenFree = getFree(_tokenToBurn);
        uint256 tokenTotalFreeLevels = getFree(_tokenToChange);

        // We check if adding the extra free levels + the 1 free we get from a burn overflows the max level
        // Every token ends with 1 more level than it started (at a minimum) as burning a token grants a level, even if none are free
        require(tokenTotalFreeLevels + burntTokenFree + 1 <= 255, "GG: Max 255");

        bytes32 newHash = bytes32((uint256(tokenHashes[_tokenToChange]) + uint(0x01) + burntTokenFree));

        tokenHashes[_tokenToChange] = newHash;
        emit HashUpdated(_tokenToChange, newHash); // This is to inform frontend services that we have new properties in hash 0

        // We set the burnt token state to 1, since we are burning it
        tokenHashes[_tokenToBurn] = bytes32((uint256(tokenHashes[_tokenToBurn]) + uint(0x010000)));
        // Bye Bye token
        _burn(msg.sender, _tokenToBurn);
    }

    // Public View Functions - We can use the public view functions here rather than internal since we dont pay for gas on them... usually ;)
    function verifyTruth(uint256 _tokenId, uint256 _wordSlot, string calldata _word)
        tokenExists(_tokenId)
     public view returns (bool answer) {
        require(_wordSlot < tokenLevel(_tokenId) && _wordSlot != 0, "GG: Word slot out of bounds");
        bytes32 word = tokenHashes[getShifted(_tokenId) + _wordSlot];
        bytes32 assertedTruth = keccak256(abi.encodePacked(_word));

        return (word == assertedTruth);
    }

    function tokenURI(uint256 tokenId)
        tokenExists(tokenId)
     public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function tokenProjectURI(uint256 _tokenId, uint256 _projectId)
        tokenExists(_tokenId)
    public view returns (string memory tokenURI) {
        require(_projectId < gaucheLevels.length, "GG: Must be within project range");
        require(tokenHashes[_tokenId] != 0, "GG: Token not found");
        require(_projectId < getLevel(_tokenId) , "GG: Level too low");
        tokenURI = string(abi.encodePacked(gaucheLevels[_projectId].baseURI, Strings.toString(_tokenId)));
        return tokenURI;
    }

    //
    function tokenFullData(uint256 _tokenId)
    public view returns (GaucheToken memory token) {
        return  GaucheToken(_tokenId, tokenFreeChanges(_tokenId), tokenLevel(_tokenId), tokenBurned(_tokenId), tokenHashesOwned(_tokenId));
    }

    function tokenHash(uint256 _tokenId)
        tokenExists(_tokenId)
    public view returns (bytes32) {
        return tokenHashes[_tokenId];
    }

    function tokenSlotHash(uint256 _tokenId, uint256 _slot)
        tokenExists(_tokenId)
    public view returns (bytes32) {
        require(_slot != 0x0, "GG: Slot must be non-zero");
        require(getLevel(_tokenId) > _slot , "GG: Level too low");
        return tokenHashes[getShifted(_tokenId) + _slot];
    }

    //We dont need to check if the token exists since only burned tokens will be non zero
    function tokenBurned(uint256 _tokenId) public view returns (bool _burned) {
        return getBurned(_tokenId) > 0;
    }

    function tokenHashesOwned(uint256 _tokenId)
        tokenExists(_tokenId)
    public view returns (bytes32[] memory ownedHashes) {
        uint256 tokenShiftedId = getShifted(_tokenId);
        uint256 tokenLevel = getLevel(_tokenId);
        ownedHashes = new bytes32[](tokenLevel);
        ownedHashes[0] = tokenHashes[_tokenId];

        for (uint256 i = 1; i < tokenLevel; i++) {
            ownedHashes[i] = tokenHashes[tokenShiftedId + i];
        }
        return ownedHashes;
    }

    function tokenFreeChanges(uint256 _tokenId)
        tokenExists(_tokenId)
    public view returns (uint) {
        return getFree(_tokenId);
    }

    function tokenLevel(uint256 _tokenId)
        tokenExists(_tokenId)
    public view returns (uint) {
        return getLevel(_tokenId);
    }

    // Internal View Functions. These should all have a shifted value passed into them.
    function checkNotNullWord(bytes32 _wordHash) internal view {
        require(_wordHash != 0x0, "GG: Cannot insert a null word");
    }

    function checkMaxLevel(uint256 _tokenId) internal view {
        require(getLevel(_tokenId) < gaucheLevels.length , "GG: Max level reached");
    }

    function getFree(uint256 _tokenId) internal view returns(uint256) {
        uint256 hash = uint256(tokenHashes[_tokenId]) & 0xFF;
        return hash;
    }

    function getLevel(uint256 _tokenId) internal view returns(uint256) {
        uint256 hash = uint256(tokenHashes[_tokenId]) & 0xFF00;
        return hash >> 8;
    }

    function getBurned(uint256 _tokenId) internal view returns(uint256) {
        uint256 hash = uint256(tokenHashes[_tokenId]) & 0xFF0000;
        return hash >> 16;
    }

    function getBurnedCount() public view returns(uint256) {
        return balanceOf(0x000000000000000000000000000000000000dEaD);
    }

    function getTotalSupply() public view returns(uint256) {
        return totalSupply() - balanceOf(0x000000000000000000000000000000000000dEaD);
    }
    // We use this function to shift the tokenid 16bits to the left, since we use the last 8bits to store injected hashes
    // Example: Token 0x03e9 (1001) becomes 0x03e90000 . With 0x0000 storing the traits, and 0x0001+ storing new hashes
    // Overflow within this schema is impossible as there is 65535 entries between tokens in this schema and our max level is 255
    function getShifted(uint256 _tokenId) internal view returns(uint256) {
        return (_tokenId << 16);
    }

    // Internal Functions for Mutating State
    function _mintToken(address _toAddress, uint256 _count, bool _batch) internal override returns (uint256[] memory _tokenIds) {
        uint256 currentSupply = totalSupply();

        if (_batch) {
            _safeMint(_toAddress, _count);
            _tokenIds = new uint256[](_count);
        } else {
            _safeMint(_toAddress, 1);
            _tokenIds = new uint256[](1);
        }
        // This is ugly buts its kinda peak performance. We use the final two bytes of the hash to store free uses
        // Then we use the two bytes preceeding that for the level.
        // We also bitshift the tokenid so we can use the hashes mapping to store words ^^

        for(uint256 i = 0; i < _count; i++) {
            uint256 tokenId = currentSupply + i;
            bytes32 level0hash = bytes32( ( uint256(keccak256(abi.encodePacked(_msgSender(), tokenId)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000) + uint(0x0100) + ( _batch ? uint(0x01) : _count) ) );
            tokenHashes[tokenId] = level0hash;
            emit HashUpdated(tokenId, level0hash); // This is to inform frontend services that we have new properties in hash 0
            _tokenIds[i] = tokenId;
            if(!_batch) {
                break;
            }
        }

        return _tokenIds;
    }
    // Internal functions pass a shifted ide
    function _changeReality(uint256 _tokenId, bytes32 _wordHash, uint256 _newSlot, uint256 _levelWordPrice) internal  {
        uint256 wordSlot = getShifted(_tokenId) +_newSlot;
        // Store the incoming word
        tokenHashes[wordSlot] = _wordHash;

        bytes32 levelZeroHash; //Create the storage value so we can act on it with the if statement

        // A level up always moves the token up 1 level only, regardless of the price, even if free
        levelZeroHash = bytes32((((uint256(tokenHashes[_tokenId]) + uint(0x0100) )- _levelWordPrice)));

        tokenHashes[_tokenId] = levelZeroHash;
        emit WordAdded(_tokenId, _wordHash, _newSlot, wordSlot);
        emit HashUpdated(_tokenId, levelZeroHash); // This is to inform frontend services that we have new properties in hash 0
    }

    function _burn(address owner, uint256 tokenId) internal virtual {
        transferFrom(owner, 0x000000000000000000000000000000000000dEaD, tokenId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LibGauche.sol";

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract GaucheBase is ERC721A, Ownable {
    mapping(uint256 => bool) public accessTokenUsed;

    address public artistAddress;
    address public developerAddress;
    address public ownerAddress;
    GaucheSale internal sale;

    string public baseURI;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseURI,
        uint64 _pricePerToken,
        address _accessTokenAddress,
        address _artistAddress,
        address _developerAddress
    ) ERC721A(_tokenName, _tokenSymbol, 20, 3333) {
        baseURI = _baseURI;
        sale = GaucheSale(SalesState.Closed, 0x0BB9, _pricePerToken, _accessTokenAddress);
        artistAddress = _artistAddress;
        developerAddress = _developerAddress;
        ownerAddress = msg.sender;
    }

    modifier onlyAllowed(Auth _auth) {
        _checkAuthorization(_auth);
        _;
    }

    modifier onlyIfTokenOwner(uint256 _tokenId) {
        _checkTokenOwner(_tokenId);
        _;
    }
    function _checkTokenOwner(uint256 _tokenId) internal view {
        require(ERC721A.ownerOf(_tokenId) == _msgSender(),"ERC721: Must own token to call this function");
    }

    modifier isMode(SalesState _mode) {
        _checkMode(_mode);
        _;
    }

    modifier isNotMode(SalesState _mode) {
        _checkNotMode(_mode);
        _;
    }

    function _checkMode(SalesState _mode) internal view {
        require(_mode == sale.saleState ,"GG: Contract must be in matching mode");
    }

    function _checkNotMode(SalesState _mode) internal view {
        require(_mode != sale.saleState ,"GG: Contract must not be in matching mode");
    }

    function _checkAuthorization(Auth param) internal view {
        if (param == Auth.Owner) {
            require(msg.sender == ownerAddress, "GB: Only the owner can do this.");
        } else if (param == Auth.Developer) {
            require(msg.sender == developerAddress, "GB: Only the developer can do this.");
        } else if (param == Auth.Artist) {
            require(msg.sender == artistAddress, "GB: Only the artist can do this.");
        } else {
            require(false, "GB: Denied");
        }
    }

    function updateArtistAddress(address _artistAddress) public onlyAllowed(Auth.Artist) {
        artistAddress = _artistAddress;
    }

    function updateDeveloperAddress(address _developerAddress) public onlyAllowed(Auth.Developer) {
        developerAddress = _developerAddress;
    }

    function updateOwnerAddress(address _ownerAddress) public onlyOwner {
        ownerAddress = _ownerAddress;
    }

    function updateBaseURI(string memory _baseURI) public onlyAllowed(Auth.Owner) {
        baseURI = _baseURI;
    }

    function updateSaleState(SalesState _state) public onlyAllowed(Auth.Owner) {
        require(sale.saleState != SalesState.Finalized, "GB: Can't change state if Finalized");
        sale.saleState = _state;
    }

    function getSaleState() public view returns(uint)  {
        return uint(sale.saleState);
    }

    function multiMint(uint256 count) public payable isMode(SalesState.Active) returns (uint256[] memory _tokenIds) {
        uint256 price = sale.pricePerToken * count;
        require(msg.value >= price, "Ether amount is under set price");
        require(count >= 1, "GG: Token count must match length of hashes or be 1.");
        require(totalSupply() < sale.maxPublicTokens, "GG: Max tokens reached");

        return  _mintToken(_msgSender(), count, true);
    }

    function mint(uint256 count) public payable isMode(SalesState.Active) returns (uint256[] memory _tokenIds) {
        uint256 price = sale.pricePerToken * count;
        require(msg.value >= price, "Ether amount is under set price");
        require(count >= 1, "GG: Min Lvl 1"); // Must buy atleast 1 level, since all tokens start at level 1
        require(count <= 255, "GG: Max 255 lvl"); // We stop at 254 because we have a max combined level of 255, as all tokens start at level 1
        require(totalSupply() + count < sale.maxPublicTokens, "GG: Max tokens reached");

        return  _mintToken(_msgSender(), count, false);
    }

    function mintAccessToken(uint256 _id) isMode(SalesState.AccessToken) public payable returns (uint256[] memory _tokenIds) {
        require(msg.value >= sale.pricePerToken, "Ether amount is under set price");
        IERC721 accessToken = IERC721(sale.accessTokenAddress);
        require(accessToken.ownerOf(_id) == _msgSender(), "Access token not owned");
        require(accessTokenUsed[_id] == false, "Access token already used");

        accessTokenUsed[_id] = true;

        // Wassilikes holders get 1 mint with 3 levels.
        return _mintToken(_msgSender(), 3, false);
    }

    function checkIfAccessTokenIsUsed(uint256 _tokenId) public view returns (bool) {
        return accessTokenUsed[_tokenId];
    }

    function _mintToken(address _toAddress, uint256 _count, bool _batch) internal virtual returns (uint256[] memory _tokenId);

    function withdrawFunds() public onlyAllowed(Auth.Owner) {
        uint256 share =  address(this).balance / 20;
        uint256 artistPayout = share * 13;
        uint256 developerPayout =   share * 7;

        if (artistPayout > 0) {
            (bool sent, bytes memory data) = payable(artistAddress).call{value: artistPayout}("");
            require(sent, "Failed to send Ether");
        }

        if (developerPayout > 0) {
            (bool sent, bytes memory data) =  payable(developerAddress).call{value: developerPayout}("");
            require(sent, "Failed to send Ether");
        }
    }

}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

enum SalesState {
    Closed,
    Active,
    AccessToken,
    Maintenance,
    Finalized
}

enum Auth{
    Owner,
    Artist,
    Developer
}

struct GaucheSale {
    SalesState saleState;
    uint16 maxPublicTokens;
    uint64 pricePerToken;
    address accessTokenAddress;
}
struct GaucheToken {
    uint256 tokenId;
    uint256 free;
    uint256 spent;
    bool burned;
    bytes32[] ownedHashes;
}

struct GaucheLevel {
    uint8 wordPrice;
    uint64 price;
    address artistAddress;
    string baseURI;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using Address for address;
  using Strings for uint256;

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }

  uint256 private currentIndex = 0;

  uint256 internal immutable collectionSize;
  uint256 internal immutable maxBatchSize;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) private _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev
   * `maxBatchSize` refers to how much a minter can mint at a time.
   * `collectionSize_` refers to how many tokens are in the collection.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) {
    require(
      collectionSize_ > 0,
      "ERC721A: collection must have a nonzero supply"
    );
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return currentIndex;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

    uint256 lowestTokenToCheck;
    if (tokenId >= maxBatchSize) {
      lowestTokenToCheck = tokenId - maxBatchSize + 1;
    }

    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }

    revert("ERC721A: unable to determine the owner of token");
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
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
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
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
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
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
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - there must be `quantity` tokens remaining unminted in the total collection.
   * - `to` cannot be the zero address.
   * - `quantity` cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "ERC721A: token already minted");
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + uint128(quantity)
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
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
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(
      isApprovedOrOwner,
      "ERC721A: transfer caller is not owner nor approved"
    );

    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0;

  /**
   * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
   */
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > collectionSize - 1) {
      endIndex = collectionSize - 1;
    }
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
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
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
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
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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