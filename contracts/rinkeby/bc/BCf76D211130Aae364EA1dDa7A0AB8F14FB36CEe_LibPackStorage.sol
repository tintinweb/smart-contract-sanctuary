// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import 'base64-sol/base64.sol';

library LibPackStorage {
  bytes32 constant STORAGE_POSITION = keccak256("com.universe.packs.storage");

  struct SingleCollectible {
    string title; // Collectible name
    string description; // Collectible description
    uint256 count; // Amount of editions per collectible
    string[] assets; // Each asset in array is a version
    uint256 totalVersionCount; // Total number of existing states
    uint256 currentVersion; // Current existing state
    string[] secondaryAssets; // Each asset in array is a version
    uint256 secondaryTotalVersionCount; // Total number of existing states
    uint256 secondaryCurrentVersion; // Current existing state
  }

  struct Metadata {
    string[] name; // Trait or attribute property field name
    string[] value; // Trait or attribute property value
    bool[] modifiable; // Can owner modify the value of field
    uint256 propertyCount; // Tracker of total attributes
  }

  struct Storage {
    bool initialized;

    // IERC721 pack;

    address payable daoAddress;
    bool daoInitialized;

    string _name; // Contract name
    string _symbol; // Contract symbol
    string _baseURI; // Token ID base URL (recommended as of 7/27/2021: https://arweave.net/)

    mapping (uint256 => SingleCollectible) collectibles; // Unique assets
    mapping (uint256 => Metadata) metadata; // Trait & property attributes, indexes should be coupled with 'collectibles'
    mapping (uint256 => string) licenseURI; // URL to external license or file

    uint256 collectibleCount; // Total unique assets count
    uint256 totalTokenCount; // Total NFT count to be minted
    uint256 tokenPrice;
    uint256 bulkBuyLimit;
    uint256 saleStartTime;
    bool editioned; // Display edition # in token name
    uint256 licenseVersion; // Tracker of latest license

    uint32[] shuffleIDs;
  }

  function packStorage() internal pure returns (Storage storage ds) {
    bytes32 position = STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function random() external view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, packStorage().totalTokenCount)));
  }

  modifier onlyDAO() {
    require(msg.sender == packStorage().daoAddress, "Wrong address");
    _;
  }

  /**
   * Map token order w/ URI upon mints
   * Sample token ID (edition #77) with collection of 12 different assets: 1200077
   */
  function createTokenIDs(uint256 collectibleCount, uint256 editions) private {
    Storage storage ds = packStorage();

    for (uint256 i = 0; i < editions; i++) {
      ds.shuffleIDs.push(uint32((collectibleCount + 1) * 100000 + (i + 1)));
    }
  }

  function addCollectible(string[] memory _coreData, string[] memory _assets, string[] memory _secondaryAssets, string[][] memory _metadataValues) external onlyDAO {
    Storage storage ds = packStorage();

    ds.collectibles[ds.collectibleCount] = SingleCollectible({
      title: _coreData[0],
      description: _coreData[1],
      count: safeParseInt(_coreData[2]),
      assets: _assets,
      currentVersion: 1,
      totalVersionCount: _assets.length,
      secondaryAssets: _secondaryAssets,
      secondaryCurrentVersion: 1,
      secondaryTotalVersionCount: _secondaryAssets.length
    });

    string[] memory propertyNames = new string[](_metadataValues.length);
    string[] memory propertyValues = new string[](_metadataValues.length);
    bool[] memory modifiables = new bool[](_metadataValues.length);
    for (uint256 i = 0; i < _metadataValues.length; i++) {
      propertyNames[i] = _metadataValues[i][0];
      propertyValues[i] = _metadataValues[i][1];
      modifiables[i] = (keccak256(abi.encodePacked((_metadataValues[i][2]))) == keccak256(abi.encodePacked(('1')))); // 1 is modifiable, 0 is permanent
    }

    ds.metadata[ds.collectibleCount] = Metadata({
      name: propertyNames,
      value: propertyValues,
      modifiable: modifiables,
      propertyCount: _metadataValues.length
    });

    uint256 editions = safeParseInt(_coreData[2]);
    createTokenIDs(ds.collectibleCount, editions);

    ds.collectibleCount++;
    ds.totalTokenCount += editions;
  }

  // Modify property field only if marked as updateable
  function updateMetadata(uint256 collectibleId, uint256 propertyIndex, string memory value) public onlyDAO {
    Storage storage ds = packStorage();
    require(ds.metadata[collectibleId - 1].modifiable[propertyIndex], 'Not allowed');
    ds.metadata[collectibleId - 1].value[propertyIndex] = value;
  }

  // Add new asset, does not automatically increase current version
  function addVersion(uint256 collectibleNumber, string memory asset) public onlyDAO {
    Storage storage ds = packStorage();
    ds.collectibles[collectibleNumber - 1].assets[ds.collectibles[collectibleNumber - 1].totalVersionCount - 1] = asset;
    ds.collectibles[collectibleNumber - 1].totalVersionCount++;
  }

  // Set version number, index starts at version 1, collectible 1 (so shifts 1 for 0th index)
  function updateVersion(uint256 collectibleNumber, uint256 versionNumber) public onlyDAO {
    Storage storage ds = packStorage();
    ds.collectibles[collectibleNumber - 1].currentVersion = versionNumber - 1;
  }

  // Secondary asset versioning
  function updateSecondaryVersion(uint256 collectibleNumber, uint256 versionNumber) public onlyDAO {
    Storage storage ds = packStorage();
    ds.collectibles[collectibleNumber - 1].secondaryCurrentVersion = versionNumber - 1;
  }

  function addSecondaryVersion(uint256 collectibleNumber, string memory asset) public onlyDAO {
    Storage storage ds = packStorage();
    ds.collectibles[collectibleNumber - 1].secondaryAssets[ds.collectibles[collectibleNumber - 1].secondaryTotalVersionCount - 1] = asset;
    ds.collectibles[collectibleNumber - 1].secondaryTotalVersionCount++;
  }

  // Adds new license and updates version to latest
  function addNewLicense(string memory _license) public onlyDAO {
    Storage storage ds = packStorage();
    ds.licenseURI[ds.licenseVersion] = _license;
    ds.licenseVersion++;
  }

  // Returns license URI
  function getLicense() public view returns (string memory) {
    Storage storage ds = packStorage();
    return ds.licenseURI[ds.licenseVersion - 1];
  }

  // Returns license version count
  function getLicenseVersion(uint256 versionNumber) public view returns (string memory) {
    Storage storage ds = packStorage();
    return ds.licenseURI[versionNumber - 1];
  }

  function toString(uint256 value) internal pure returns (string memory) {
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
    uint256 index = digits - 1;
    temp = value;
    while (temp != 0) {
        buffer[index--] = bytes1(uint8(48 + temp % 10));
        temp /= 10;
    }
    return string(buffer);
  }

  function safeParseInt(string memory _a) internal pure returns (uint _parsedInt) {
    return safeParseInt(_a, 0);
  }

  function safeParseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
    bytes memory bresult = bytes(_a);
    uint mint = 0;
    bool decimals = false;
    for (uint i = 0; i < bresult.length; i++) {
      if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
        if (decimals) {
            if (_b == 0) break;
            else _b--;
        }
        mint *= 10;
        mint += uint(uint8(bresult[i])) - 48;
      } else if (uint(uint8(bresult[i])) == 46) {
        require(!decimals, 'More than one decimal encountered in string!');
        decimals = true;
      } else {
        revert("Non-numeral character encountered in string!");
      }
    }
    if (_b > 0) {
      mint *= 10 ** _b;
    }
    return mint;
  }

  function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return string(result);
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    Storage storage ds = packStorage();

    uint256 edition = safeParseInt(substring(toString(tokenId), bytes(toString(tokenId)).length - 5, bytes(toString(tokenId)).length)) - 1;
    uint256 collectibleId = (tokenId - edition) / 100000 - 1;
    string memory encodedMetadata = '';

    for (uint i = 0; i < ds.metadata[collectibleId].propertyCount; i++) {
      encodedMetadata = string(abi.encodePacked(
        encodedMetadata,
        '{"trait_type":"',
        ds.metadata[collectibleId].name[i],
        '", "value":"',
        ds.metadata[collectibleId].value[i],
        '"}',
        i == ds.metadata[collectibleId].propertyCount - 1 ? '' : ',')
      );
    }

    string memory encoded = string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"',
                ds.collectibles[collectibleId].title,
                ds.editioned ? ' #' : '',
                ds.editioned ? toString(edition + 1) : '',
                '", "description":"',
                ds.collectibles[collectibleId].description,
                '", "image": "',
                ds._baseURI,
                ds.collectibles[collectibleId].assets[ds.collectibles[collectibleId].currentVersion - 1],
                '", "secondaryAsset": "',
                ds._baseURI,
                ds.collectibles[collectibleId].secondaryAssets[ds.collectibles[collectibleId].secondaryCurrentVersion - 1],
                '", "attributes": [',
                encodedMetadata,
                '] }'
              )
            )
          )
        )
      );

    return encoded;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

