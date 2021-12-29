/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

pragma solidity 0.5.0;

interface IBurnableEtherLegendsToken {
    function burn(uint256 tokenId) external;
}

// File: contracts/ERC721/el/IMintableEtherLegendsToken.sol

pragma solidity 0.5.0;

interface IMintableEtherLegendsToken {
    function mintTokenOfType(address to, uint256 idOfTokenType) external;
}

// File: contracts/ERC721/el/ITokenDefinitionManager.sol

pragma solidity 0.5.0;

interface ITokenDefinitionManager {
    function getNumberOfTokenDefinitions() external view returns (uint256);
    function hasTokenDefinition(uint256 tokenTypeId) external view returns (bool);
    function getTokenTypeNameAtIndex(uint256 index) external view returns (string memory);
    function getTokenTypeName(uint256 tokenTypeId) external view returns (string memory);
    function getTokenTypeId(string calldata name) external view returns (uint256);
    function getCap(uint256 tokenTypeId) external view returns (uint256);
    function getAbbreviation(uint256 tokenTypeId) external view returns (string memory);
}

// File: openzeppelin-solidity/contracts/introspection/IERC165.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others (`ERC165Checker`).
 *
 * For an implementation, see `ERC165`.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.5.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either `approve` or `setApproveForAll`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either `approve` or `setApproveForAll`.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Enumerable.sol

pragma solidity ^0.5.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Metadata.sol

pragma solidity ^0.5.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Full.sol

pragma solidity ^0.5.0;




/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Full is IERC721, IERC721Enumerable, IERC721Metadata {
    // solhint-disable-previous-line no-empty-blocks
}

// File: contracts/ERC721/el/IEtherLegendsToken.sol

pragma solidity 0.5.0;

contract IEtherLegendsToken is IERC721Full, IMintableEtherLegendsToken, IBurnableEtherLegendsToken, ITokenDefinitionManager {
    function totalSupplyOfType(uint256 tokenTypeId) external view returns (uint256);
    function getTypeIdOfToken(uint256 tokenId) external view returns (uint256);
}

// File: contracts/ERC721/el/accessors/BalanceOfTokenTypeId.sol

pragma solidity 0.5.0;

contract BalanceOfTokenTypeId {

  IEtherLegendsToken public elGen1Token;

  constructor() public
  {
      elGen1Token = IEtherLegendsToken(0x395E5461693e0bB5EC78302605030050f69e628d);
  }

  function balanceOfTokenTypeId(address owner, uint256 tokenTypeId) public view returns (uint256) {

    uint256 combinedBalance = elGen1Token.balanceOf(owner);
    uint256 balanceOfType = 0;

    for(uint256 i = 0; i < combinedBalance; i++) {

      uint256 ownedTokenId = elGen1Token.tokenOfOwnerByIndex(owner, i);
      uint256 ownedTokenTypeId = elGen1Token.getTypeIdOfToken(ownedTokenId);

      if(tokenTypeId == ownedTokenTypeId) {
          balanceOfType++;
      }
    }
    return balanceOfType;
  }
}