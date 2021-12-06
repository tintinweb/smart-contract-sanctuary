// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract EnsMapper is Ownable {

    using Strings for uint256;

    ENS private ens;
    mapping(bytes32=>mapping(string=>string)) texts;
    bytes32 public domainHash = 0x8f3a1b2178b34835e7251c9ca4794808653bbee9c882f634f3472d21b8989f22; //0x8f3a1b2178b34835e7251c9ca4794808653bbee9c882f634f3472d21b8989f22
    address public owner_address = 0x082Fc1776d44f69988C475958A0505A5BC2cd77b;
    mapping(bytes32 => uint256) public hashes;
    mapping(string => bytes32) public domainMap;
    mapping(uint256 => bytes32) public tokenHashmap;
    mapping(bytes32 => string) public hashToDomainMap;

    mapping(uint256 => bool) public whitelist;
    mapping(address => bool) public address_whitelist;

    IERC721Enumerable public nft;

    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    constructor(){
        ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        nft = IERC721Enumerable(0x1EC61E200d56F1fD46D24BDeB544F85e18B6D658);
    }

    function setNftAddress(address addy) public onlyOwner{
        nft = IERC721Enumerable(addy);
    }
    function setEnsAddress(address addy) public onlyOwner {
        ens = ENS(addy);
    }

    function setDomain(string calldata label, uint256 token_id) public {
        require(nft.ownerOf(token_id) == msg.sender, "not owner of token");
        require(tokenHashmap[token_id] == 0x0, "Token has already been set");
        require(whitelist[token_id] || address_whitelist[msg.sender], "Token or address not currently on the whitelist");
        require(labelToId(label) == 0, "Label is currently being used");


        bytes32 encoded_label = keccak256(abi.encodePacked(label));
        bytes32 big_hash = keccak256(abi.encodePacked(domainHash, encoded_label));

        require(!ens.recordExists(big_hash), "sub-domain already exists");
        
        ens.setSubnodeRecord(domainHash, encoded_label, owner_address, address(this), 0);

        domainMap[label] = big_hash;
        hashes[big_hash] = token_id;        
        tokenHashmap[token_id] = big_hash;
        hashToDomainMap[big_hash] = label;

        if(whitelist[token_id]){
            whitelist[token_id] = false;
        }
        else{
            address_whitelist[msg.sender] = false;
        }       
    }

    function addWhitelist(uint256[] calldata ids) public onlyOwner {
        for(uint256 i; i < ids.length; i++){
           whitelist[ids[i]] = true;     
        }
    }

    function addAddressWhitelist(address[] calldata addresses) public onlyOwner {
        for(uint256 i; i < addresses.length; i++){
           address_whitelist[addresses[i]] = true;     
        }
    }

    function resetHash(uint256 token_id) public {
        require(owner() == msg.sender || nft.ownerOf(token_id) == msg.sender, "Not authorised to reset sub-domain");
        bytes32 domain = tokenHashmap[token_id];
        require(ens.recordExists(domain), "Sub-domain does not exist");
        tokenHashmap[token_id] = 0x0;
        hashes[domain] == 0;
        hashToDomainMap[domain] = "";
    }

    function setOwner(address addy) public onlyOwner {
        owner_address = addy;
    }

    function setDomainHash(bytes32 hash) public onlyOwner {
        domainHash = hash;
    }

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == 0x3b3b57de //addr
        || interfaceID == 0x59d1d43c //text
        || interfaceID == 0x691f3431 //name
        || interfaceID == 0x01ffc9a7; //supportsInterface
    }

    function addr(bytes32 nodeID) public view returns (address) {
        require(hashes[nodeID] > 0, "cannot find address");
        return nft.ownerOf(hashes[nodeID]);
    }

    function name(bytes32 node) view public returns (string memory){
        return hashToDomainMap[node];
    }

    function labelToId(string calldata label) public view returns (uint256){
        return hashes[domainMap[label]];
    }

    function getClaimableIds(address addy) private view returns(uint256[] memory){
        uint256 balance = nft.balanceOf(addy);
        uint256[] memory ids = new uint256[](balance);
        uint256 count;
        for(uint256 i; i < balance; i++){
            uint256 id = nft.tokenOfOwnerByIndex(addy, i);
            if(whitelist[id]){
                ids[count++] = id;
            }
        }
        uint256[] memory wl_ids = new uint256[](count);

        uint256 final_count;
        for(uint256 i; i < balance; i++){
            if(ids[i] > 0){
                wl_ids[final_count] = ids[i];
                final_count++;
            }
        }

        return wl_ids;
    }

    function getClaimableIdsForAddress(address addy) public view returns(uint256[] memory){
        if(address_whitelist[addy]){
            return getAllIds(addy);
        }
        else{
            return getClaimableIds(addy);
        }
    }

    function getAllIds(address addy) private view returns(uint256[] memory){
        uint256 balance = nft.balanceOf(addy);
        uint256[] memory ids = new uint256[](balance);
        uint256 count;
        for(uint256 i; i < balance; i++){
            uint256 id = nft.tokenOfOwnerByIndex(addy, i);
            if(tokenHashmap[id] == 0x0){
                ids[count++] = id;
            }
        }

        uint256[] memory trim_ids = new uint256[](count);
        for(uint256 i; i < count; i++){
            trim_ids[i] = ids[i];
        }

        return trim_ids;
    }

    function text(bytes32 node, string calldata key) external view returns (string memory) {
        require(hashes[node] > 0, "sub-domain does not exist");
        if(keccak256(abi.encodePacked(key)) == keccak256("avatar")){
            return string(abi.encodePacked("eip155:1/erc721:", addressToString(address(nft)), "/", hashes[node].toString()));
        }
        else{
            return texts[node][key];
        }
    }

    function setText(bytes32 node, string calldata key, string calldata value) external {
        require(keccak256(abi.encodePacked(key)) != keccak256("avatar"), "cannot set avatar");
        require(nft.ownerOf(hashes[node]) == msg.sender || owner() == msg.sender, "not authorised");
        texts[node][key] = value;
        emit TextChanged(node, key, key);
    }

    //requires testing
    function getAllCatsWithDomains(address addy) public view returns(uint256[] memory){
        uint256 balance = nft.balanceOf(addy);
        uint256[] memory ids = new uint256[](balance);
        uint256 count;
        for(uint256 i; i < balance; i++){
            uint256 id = nft.tokenOfOwnerByIndex(addy, i);
            if(tokenHashmap[id] != 0x0){
                ids[count++] = id;
            }
        }

        uint256[] memory trim_ids = new uint256[](count);
        for(uint256 i; i < count; i++){
            trim_ids[i] = ids[i];
        }

        return trim_ids;
    }

    function addressToString(address _addr) public pure returns(string memory) {
    bytes32 value = bytes32(uint256(uint160(_addr)));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(51);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < 20; i++) {
        str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
    }
    return string(str);
}
}

pragma solidity >=0.8.4;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
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