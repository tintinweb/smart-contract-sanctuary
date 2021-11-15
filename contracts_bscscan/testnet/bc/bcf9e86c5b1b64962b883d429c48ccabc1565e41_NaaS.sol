// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
pragma abicoder v2; // required to accept structs as function parameters

import "./abstracts/ERC1155/presets/ERC1155Tradeable.sol";
import "./abstracts/ERC1155/extensions/ERC1155Proxy.sol";
// import "./abstracts/ERC1155/extensions/ERC1155Pausable.sol";
import "./abstracts/ERC1155/extensions/ERC1155Collection.sol";

contract NaaS is ERC1155Tradeable
{
    function initialize(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) public virtual initializer {
        __ERC1155Tradeable_init(_name, _symbol, "1", _proxyRegistryAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@psi-naas/royalties/contracts/abstracts/Royalties.sol";
import "@psi-naas/royalties/contracts/libraries/LibPart.sol";
import "../../../interfaces/ERC1155/IERC1155Tradeable.sol";
import "../../../libraries/LibERC1155Lazy.sol";
import "../../ERC1271/ERC1271Validator.sol";
import "../extensions/ERC1155MetadataURI.sol";
import "../extensions/ERC1155Capped.sol";
import "../extensions/ERC1155Creators.sol";
import "../extensions/ERC1155Collection.sol";
import "../extensions/ERC1155Proxy.sol";
import "../../../utils/Strings.sol";

/**
 * @title ERC1155Tradeable
 * ERC1155Tradeable - ERC1155 contract that whitelists an operator address, has create and mint functionality,
 * and supports useful standards from OpenZeppelin, like exists(), name(), symbol(), and totalSupply()
 */
abstract contract ERC1155Tradeable is
    OwnableUpgradeable,
    ERC1271Validator,
    IERC1155Tradeable,
    ERC1155Capped,
    ERC1155MetadataURI,
    ERC1155Creators,
    ERC1155Collection,
    ERC1155Proxy,
    Royalties
{
    using Strings for string;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    function __ERC1155Tradeable_init(
        string memory _name,
        string memory _symbol,
        string memory version,
        address _proxyRegistryAddress
    ) internal initializer {
        name = _name;
        symbol = _symbol;

        __Ownable_init_unchained();
        __ERC1155_init();
        __ERC1271Validator_init(name, version);
        __ERC1155Proxy_init(_proxyRegistryAddress);
        __ERC1155MetadataURI_init_unchained();
        __ERC1155Collection_init_unchained();
    }

    function mint(
        LibERC1155Lazy.MintData memory data,
        address to,
        uint256[][] memory _amounts
    ) public virtual override {
        require(
            data.minter == _msgSender() ||
                isApprovedForAll(data.minter, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        bytes32 hash = LibERC1155Lazy.hash(data);
        for (uint256 colIdx = 0; colIdx < data.collections.length; colIdx++) {
            if (!collectionExists(data.collections[colIdx].id)) {
                _setCollectionURI(
                    data.collections[colIdx].id,
                    data.collections[colIdx].uri
                );
            }

            uint256[] memory tokenIds = new uint256[](_amounts[colIdx].length);
            for (
                uint256 tokenIdx = 0;
                tokenIdx < data.collections[colIdx].tokens.length;
                tokenIdx++
            ) {
                LibERC1155Lazy.Token memory token = data
                    .collections[colIdx]
                    .tokens[tokenIdx];

                LibPart.Part[] memory _creators = token.creators;
                if (_creators.length == 0)
                    _creators = data.collections[colIdx].creators;
                require(
                    data.minter == _creators[0].account,
                    "Minter is not the first creator"
                );

                LibPart.Part[] memory _royalties = token.royalties;
                if (_royalties.length == 0)
                    _royalties = data.collections[colIdx].royalties;

                if (!exists(token.id)) {
                    require(token.supply > 0, "supply incorrect");
                    _validateCreators(hash, _creators, data.signatures);

                    _setMaximumSupply(token.id, token.supply);
                    _saveRoyalties(token.id, _royalties);
                    _saveCreators(token.id, _creators);
                    _setTokenURI(token.id, token.uri);
                }

                tokenIds[tokenIdx] = token.id;
            }

            _mintBatch(
                to,
                data.collections[colIdx].id,
                tokenIds,
                _amounts[colIdx],
                ""
            );
        }
    }

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override(ERC1155Capped, ERC1155Supply, ERC1155MintBurn) {
        super._mint(account, id, amount, data);
    }

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function _mintBatchSingle(
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual override(ERC1155Capped, ERC1155Supply, ERC1155MintBurn) {
        super._mintBatchSingle(to, id, amount);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override(ERC1155Supply, ERC1155MintBurn) {
        super._burn(account, id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override(ERC1155Supply, ERC1155MintBurn) {
        super._burnBatch(account, ids, amounts);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override(IERC1155Upgradeable, ERC1155, ERC1155Proxy)
        returns (bool)
    {
        return super.isApprovedForAll(account, operator);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC1155, ERC1155MetadataURI, Royalties)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Tradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../../interfaces/ERC1155/IERC1155Proxy.sol";
import "../ERC1155.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract ERC1155Proxy is IERC1155Proxy, OwnableUpgradeable, ERC1155 {
    address public override proxyRegistryAddress;
    address public override proxyRegistryAddressPending;
    uint256 public override proxyRegistryAddressPendingTime;
    uint256 public constant override proxyAddressTimestamp = 604800; // 7 days

    function __ERC1155Proxy_init(address _proxyRegistryAddress)
        internal
        initializer
    {
        __ERC1155_init_unchained();
        __Ownable_init_unchained();
        __ERC1155Proxy_init_unchained(_proxyRegistryAddress);
    }

    function __ERC1155Proxy_init_unchained(address _proxyRegistryAddress)
        internal
        initializer
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
     * @dev Add a new proxy address (only owner)
     * address can be applied after `proxyAddressesTimestamp` seconds have past
     */
    function proxyRegistryAddressAdd(address _proxyRegistryAddress)
        external
        virtual
        override
        onlyOwner
    {
        require(
            proxyRegistryAddressPending != _proxyRegistryAddress,
            "Address already pending"
        );
        proxyRegistryAddressPending = _proxyRegistryAddress;
        proxyRegistryAddressPendingTime =
            block.timestamp +
            proxyAddressTimestamp;
    }

    /**
     * @dev Apply the new proxy address after `proxyAddressesTimestamp` seconds have past (only owner)
     */
    function proxyRegistryAddressApply() external virtual override onlyOwner {
        require(
            proxyRegistryAddressPendingTime > 0 &&
                proxyRegistryAddressPending != address(0x0),
            "No address pending"
        );
        require(
            proxyRegistryAddressPendingTime < block.timestamp,
            "Address still pending"
        );
        proxyRegistryAddress = proxyRegistryAddressPending;
        proxyRegistryAddressPending = address(0x0);
        proxyRegistryAddressPendingTime = 0;
    }

    /**
     * @dev Possibility to revoke a proxy address at all times by the owner
     */
    function proxyRegistryAddressRevoke() external virtual override onlyOwner {
        proxyRegistryAddress = address(0x0);
        proxyRegistryAddressPending = address(0x0);
        proxyRegistryAddressPendingTime = 0;
    }

    /**
     * @dev Override isApprovedForAll to whitelist user's NaaS proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        override(IERC1155Upgradeable, ERC1155)
        returns (bool isOperator)
    {
        if (
            proxyRegistryAddress != address(0x0) &&
            address(ProxyRegistry(proxyRegistryAddress).proxies(_owner)) ==
            _operator
        ) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC1155MintBurn.sol";
import "../../../utils/Strings.sol";
import "../../../interfaces/ERC1155/IERC1155Collection.sol";

/**
 * @dev Introducing collection for ERC1155 tokens.
 *
 * Useful for multiple collection contracts, transfering whole collections and
 * showing collection metadata.
 */
abstract contract ERC1155Collection is IERC1155Collection, ERC1155MintBurn {
    // collection URI's default URI prefix
    string public override baseCollectionURI;

    // Mappings for collection and token IDs
    mapping(uint256 => uint256[]) internal _collectionTokens;

    // Mapping from collection ID to metadata URIs
    mapping(uint256 => string) internal _collectionMetadataURIs;

    // Mappings for collection and token IDs
    mapping(uint256 => uint256) internal _collectionForIds;

    function __ERC1155Collection_init_unchained() internal initializer {
        _setBaseCollectionURI("ipfs://");
    }

    /**
     * @notice Retrieve the token IDs in a collection
     */
    function collectionTokens(uint256 _id)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        return _collectionTokens[_id];
    }

    /**
     * @notice Retrieve the collection ID for a token
     */
    function collectionForToken(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _collectionForIds[_tokenId];
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given collection.
     * @return URI string
     */
    function collectionURI(uint256 _id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (bytes(baseCollectionURI).length == 0)
            return _collectionMetadataURIs[_id];
        if (bytes(_collectionMetadataURIs[_id]).length > 0)
            return
                string(
                    abi.encodePacked(
                        baseCollectionURI,
                        _collectionMetadataURIs[_id]
                    )
                );
        return
            string(
                abi.encodePacked(
                    baseCollectionURI,
                    Strings.uint2str(_id),
                    ".json"
                )
            );
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given collection by token ID.
     * @return URI string
     */
    function collectionURIForToken(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return collectionURI(_collectionForIds[_tokenId]);
    }

    /**
     * @notice Checks if a collection exists by counting it's tokens
     * @return bool exists
     */
    function collectionExists(uint256 collectionId) public view virtual override returns (bool) {
        return _collectionTokens[collectionId].length > 0;
    }

    /**
     * @dev Sets a new base URI
     */
    function _setBaseCollectionURI(string memory _newBaseMetadataURI)
        internal
        virtual
    {
        baseCollectionURI = _newBaseMetadataURI;
    }

    /**
     * @dev Set's the token URI for an ID
     */
    function _setCollectionURI(
        uint256 collectionId,
        string memory _collectionURI
    ) internal virtual {
        if (bytes(_collectionMetadataURIs[collectionId]).length > 0)
            emit URI(_collectionURI, collectionId);
        _collectionMetadataURIs[collectionId] = _collectionURI;
    }

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(
        address account,
        uint256 collectionId,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        super._mint(account, id, amount, data);
        _collectionTokens[collectionId].push(id);
        _collectionForIds[id] = collectionId;
    }

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function _mintBatch(
        address account,
        uint256 collectionId,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        super._mintBatch(account, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            _collectionTokens[collectionId].push(ids[i]);
            _collectionForIds[ids[i]] = collectionId;
        }
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "../interfaces/IRoyalties.sol";
import "../libraries/LibPart.sol";

abstract contract Royalties is
    Initializable,
    ContextUpgradeable,
    IRoyalties,
    ERC165Upgradeable
{
    mapping(uint256 => LibPart.Part[]) public royalties;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IRoyalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getRoyalties(uint256 id)
        external
        view
        override
        returns (LibPart.Part[] memory)
    {
        return royalties[id];
    }

    function _saveRoyalties(uint256 _id, LibPart.Part[] memory _royalties)
        internal
    {
        for (uint256 i = 0; i < _royalties.length; i++) {
            require(
                _royalties[i].account != address(0x0),
                "Recipient should be present"
            );
            require(
                _royalties[i].value != 0,
                "Royalty value should be positive"
            );
            royalties[_id].push(_royalties[i]);
        }

        emit RoyaltiesSet(_id, _royalties);
    }

    function updateRoyaltiesAccount(
        uint256 id,
        address from,
        address to
    ) external virtual override {
        require(_msgSender() == from, "Royalties: not allowed");

        for (uint256 i = 0; i < royalties[id].length; i++) {
            if (royalties[id][i].account == from) {
                royalties[id][i].account = payable(to);
                emit RoyaltiesAccountUpdated(id, from, to);
            }
        }
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library LibPart {
    bytes32 public constant TYPE_HASH =
        keccak256("Part(address account,uint256 value)");

    struct Part {
        address payable account;
        uint256 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../../libraries/LibERC1155Lazy.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";

interface IERC1155Tradeable is IERC1155MetadataURIUpgradeable {

    function mint(LibERC1155Lazy.MintData memory data,
        address to,
        uint256[][] memory _amounts)
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@psi-naas/royalties/contracts/libraries/LibPart.sol";

library LibERC1155Lazy {
    struct Token {
        uint256 id;
        string uri;
        uint256 supply;
        LibPart.Part[] creators;
        LibPart.Part[] royalties;
    }
    struct Collection {
        uint256 id;
        string uri;
        LibPart.Part[] creators;
        LibPart.Part[] royalties;
        Token[] tokens;
    }
    struct MintData {
        address minter;
        Collection[] collections;
        // uint256 nonce;
        bytes[] signatures;
    }

    bytes32 public constant TOKEN_TYPEHASH =
        keccak256(
            "Token(uint256 id,string uri,uint256 supply,Part[] creators,Part[] royalties)Part(address account,uint256 value)"
        );

    bytes32 public constant COLLECTION_TYPEHASH =
        keccak256(
            "Collection(uint256 id,string uri,Part[] creators,Part[] royalties,Token[] tokens)Part(address account,uint256 value)Token(uint256 id,string uri,uint256 supply,Part[] creators,Part[] royalties)"
        );

    bytes32 public constant MINT_TYPEHASH =
        keccak256(
            "MintData(address minter,Collection[] collections)Collection(uint256 id,string uri,Part[] creators,Part[] royalties,Token[] tokens)Part(address account,uint256 value)Token(uint256 id,string uri,uint256 supply,Part[] creators,Part[] royalties)"
        );

    function hash(MintData memory data) internal pure returns (bytes32) {
        bytes32[] memory collectionsBytes = new bytes32[](
            data.collections.length
        );
        for (uint256 i = 0; i < data.collections.length; i++) {
            collectionsBytes[i] = hashCollection(data.collections[i]);
        }
        return
            keccak256(
                abi.encode(
                    MINT_TYPEHASH,
                    data.minter,
                    keccak256(abi.encodePacked(collectionsBytes))
                )
            );
    }

    function hashCollection(Collection memory data) internal pure returns (bytes32) {
        bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);
        for (uint256 i = 0; i < data.royalties.length; i++) {
            royaltiesBytes[i] = LibPart.hash(data.royalties[i]);
        }
        bytes32[] memory creatorsBytes = new bytes32[](data.creators.length);
        for (uint256 i = 0; i < data.creators.length; i++) {
            creatorsBytes[i] = LibPart.hash(data.creators[i]);
        }
        bytes32[] memory tokensBytes = new bytes32[](data.tokens.length);
        for (uint256 i = 0; i < data.tokens.length; i++) {
            tokensBytes[i] = hashToken(data.tokens[i]);
        }
        return
            keccak256(
                abi.encode(
                    COLLECTION_TYPEHASH,
                    data.id,
                    keccak256(abi.encodePacked(data.uri)),
                    keccak256(abi.encodePacked(creatorsBytes)),
                    keccak256(abi.encodePacked(royaltiesBytes)),
                    keccak256(abi.encodePacked(tokensBytes))
                )
            );
    }

    function hashToken(Token memory data) internal pure returns (bytes32) {
        bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);
        for (uint256 i = 0; i < data.royalties.length; i++) {
            royaltiesBytes[i] = LibPart.hash(data.royalties[i]);
        }
        bytes32[] memory creatorsBytes = new bytes32[](data.creators.length);
        for (uint256 i = 0; i < data.creators.length; i++) {
            creatorsBytes[i] = LibPart.hash(data.creators[i]);
        }
        return
            keccak256(
                abi.encode(
                    TOKEN_TYPEHASH,
                    data.id,
                    keccak256(abi.encodePacked(data.uri)),
                    data.supply,
                    keccak256(abi.encodePacked(creatorsBytes)),
                    keccak256(abi.encodePacked(royaltiesBytes))
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC1271.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

abstract contract ERC1271Validator is EIP712Upgradeable {
    using AddressUpgradeable for address;
    using ECDSAUpgradeable for bytes32;

    string constant SIGNATURE_ERROR = "signature verification error";
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     */
    function __ERC1271Validator_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __ERC1271Validator_init_unchained() internal initializer {}

    function validate(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view {
        bytes32 typedHash = _hashTypedDataV4(hash);
        if (signer.isContract()) {
            require(
                ERC1271(signer).isValidSignature(typedHash, signature) == MAGICVALUE,
                SIGNATURE_ERROR
            );
        } else {
            require(typedHash.recover(signature) == signer, SIGNATURE_ERROR);
        }
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "../ERC1155.sol";
import "../../../utils/Strings.sol";

/**
 * @notice Contract that handles metadata related methods.
 */
abstract contract ERC1155MetadataURI is IERC1155MetadataURIUpgradeable, ERC1155 {
    // URI's default URI prefix
    string public baseURI;

    // Mapping from token ID to metadata URIs
    mapping(uint256 => string) internal _tokenMetadataURIs;

    function __ERC1155MetadataURI_init_unchained() internal initializer {
        _setBaseURI("ipfs://");
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev See {IERC1155MetadataURI-uri}.
     * @return URI string
     */
    function uri(uint256 _id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (bytes(baseURI).length == 0) return _tokenMetadataURIs[_id];
        if (bytes(_tokenMetadataURIs[_id]).length > 0)
            return string(abi.encodePacked(baseURI, _tokenMetadataURIs[_id]));
        return
            string(abi.encodePacked(baseURI, Strings.uint2str(_id), ".json"));
    }

    /**
     * @dev Sets a new base URI
     */
    function _setBaseURI(string memory _newBaseMetadataURI)
        internal
        virtual
    {
        baseURI = _newBaseMetadataURI;
    }

    /**
     * @dev Set's the token URI for an ID
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        if (bytes(_tokenMetadataURIs[tokenId]).length > 0)
            emit URI(_tokenURI, tokenId);
        _tokenMetadataURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Supply.sol";
import "../../../utils/Strings.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Capped is ERC1155Supply {
    mapping(uint256 => uint256) private _maximumSupply;

    /**
     * @dev Maximum amount of tokens with a given id.
     */
    function maximumSupply(uint256 id) public view virtual returns (uint256) {
        return _maximumSupply[id];
    }

    /**
     * @dev Set's the maximum supply
     */
    function _setMaximumSupply(uint256 id, uint256 maxSupply) internal virtual {
        _maximumSupply[id] = maxSupply;
    }

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        require(
            maximumSupply(id) == 0 ||
                totalSupply(id) + amount <= maximumSupply(id),
            "ERC1155: Total supply is higher then maximum supply"
        );
        super._mint(account, id, amount, data);
    }

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function _mintBatchSingle(
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        require(
            maximumSupply(id) == 0 ||
                totalSupply(id) + amount <= maximumSupply(id),
            string(
                abi.encodePacked(
                    "ERC1155: Total supply is higher then maximum supply for ID: ",
                    Strings.uint2str(id)
                )
            )
        );
        super._mintBatchSingle(to, id, amount);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
pragma abicoder v2;

import "@psi-naas/royalties/contracts/libraries/LibPart.sol";
import "../../../interfaces/ERC1155/IERC1155Creators.sol";
import "../../../libraries/LibERC1155Creators.sol";
import "../../ERC1271/ERC1271Validator.sol";
import "./ERC1155Supply.sol";

abstract contract ERC1155Creators is
    IERC1155Creators,
    ERC1271Validator,
    ERC1155Supply
{
    mapping(uint256 => LibPart.Part[]) public creators;

    /**
     * @dev Require _msgSender() to be the creator of the token id
     * this only succeeds when the tokens has only 1 creator, other wise use signing
     */
    modifier onlyCreator(uint256 _id) {
        isCreator(_id);
        _;
    }

    /**
     * @dev Require `_msgSender()` to be the creator of the token id
     * this only succeeds when the tokens has only 1 creator, other wise use signing
     * reverts when `_msgSender()` is not the creator
     */
    function isCreator(uint256 _id)
        public
        view
        virtual
        override
        returns (bool)
    {
        require(exists(_id), "Token does not exist");
        require(
            creators[_id].length == 1,
            "There should be only 1 creator, use signing instead"
        );
        require(
            creators[_id][0].account == _msgSender(),
            "Only creator allowed"
        );
        return true;
    }

    function getCreators(uint256 _id)
        external
        view
        virtual
        override
        returns (LibPart.Part[] memory)
    {
        return creators[_id];
    }

    /**
     * @dev Change the creator addresses for given tokens
     * @param _ids token ids to change
     * @param _newCreators new creator addresses
     */
    function setCreatorBatch(
        uint256[] calldata _ids,
        address[] calldata _newCreators
    ) external virtual override {
        for (uint256 i = 0; i < _ids.length; i++) {
            setCreator(_ids[i], _newCreators[i]);
        }
    }

    /**
     * @dev Change the creator address for given token
     * @param _id token id to change
     * @param _newCreator new creator address
     */
    function setCreator(uint256 _id, address _newCreator)
        public
        virtual
        override
        onlyCreator(_id)
    {
        creators[_id][0].account = payable(_newCreator);
        creators[_id][0].value = 10000;
    }

    /**
     * @dev Change the creators for multiple tokens
     * @param data[] the new creators data (signed by all creators) for all tokens
     */
    function setCreatorsBatch(LibERC1155Creators.Data[] memory data)
        external
        virtual
        override
    {
        for (uint256 i = 0; i < data.length; i++) {
            setCreators(data[i]);
        }
    }

    /**
     * @dev Change the creators for given token
     * @param data the new creators data (signed by all creators)
     */
    function setCreators(LibERC1155Creators.Data memory data)
        public
        virtual
        override
    {
        require(exists(data.tokenId), "Token does not exist");
        require(
            creators[data.tokenId].length == data.previousSignatures.length,
            "Not enough previous signatures"
        );
        require(
            data.creators.length == data.signatures.length,
            "Not enough signatures"
        );

        bytes32 hash = LibERC1155Creators.hash(data);
        for (uint256 i = 0; i < creators[data.tokenId].length; i++) {
            address creator = creators[data.tokenId][i].account;
            if (creator != _msgSender()) {
                validate(creator, hash, data.previousSignatures[i]);
            }
        }

        _validateCreators(hash, data.creators, data.signatures);
        _saveCreators(data.tokenId, data.creators);
    }

    function _validateCreators(
        bytes32 hash,
        LibPart.Part[] memory _creators,
        bytes[] memory signatures
    ) internal virtual {
        if (_creators.length == 1 && _creators[0].account == _msgSender())
            return;
        require(
            (_creators.length > 0 && _creators.length == signatures.length),
            "Not enough signatures"
        );

        for (uint256 i = 0; i < _creators.length; i++) {
            address creator = _creators[i].account;
            if (creator != _msgSender()) {
                validate(creator, hash, signatures[i]);
            }
        }
    }

    function _saveCreators(uint256 tokenId, LibPart.Part[] memory _creators)
        internal
        virtual
    {
        delete creators[tokenId];
        uint256 total = 0;
        for (uint256 i = 0; i < _creators.length; i++) {
            require(
                _creators[i].account != address(0x0),
                "Account should be present"
            );
            require(
                _creators[i].value != 0,
                "Creator share should be positive"
            );
            total = total + _creators[i].value;
            creators[tokenId].push(_creators[i]);
        }

        require(
            total == 10000,
            "ERC1155Creators: total amount of creators share should be 10000"
        );
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library Strings {
    /**
     * @notice Convert uint256 to string
     * @param _i Unsigned integer to convert to string
     */
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";

        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        j = _i;
        while (j != 0) {
            bstr[--length] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }

        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "../libraries/LibPart.sol";

interface IRoyalties is IERC165Upgradeable {
    event RoyaltiesSet(uint256 indexed tokenId, LibPart.Part[] royalties);
    event RoyaltiesAccountUpdated(uint256 indexed tokenId, address indexed oldAccount, address indexed newAccount);

    function getRoyalties(uint256 id) external view returns (LibPart.Part[] memory);

    function updateRoyaltiesAccount(uint256 id, address from, address to) external;
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
interface IERC165Upgradeable {
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

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC1271Upgradeable.sol";

abstract contract ERC1271 is IERC1271Upgradeable {
    bytes4 public constant ERC1271_INTERFACE_ID = 0xfb855dc9; // this.isValidSignature.selector

    bytes4 public constant ERC1271_RETURN_VALID_SIGNATURE = 0x1626ba7e;
    bytes4 public constant ERC1271_RETURN_INVALID_SIGNATURE = 0x00000000;

    /**
     * @dev Function must be implemented by deriving contract
     * @param _hash Arbitrary length data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     * @return A bytes4 magic value 0x1626ba7e if the signature check passes, 0x00000000 if not
     *
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        public
        view
        virtual
        override
        returns (bytes4);

    function returnIsValidSignatureMagicNumber(bool isValid)
        internal
        pure
        returns (bytes4)
    {
        return
            isValid
                ? ERC1271_RETURN_VALID_SIGNATURE
                : ERC1271_RETURN_INVALID_SIGNATURE;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
abstract contract ERC1155 is Initializable, ContextUpgradeable, IERC1155Upgradeable, ERC165Upgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;


    function __ERC1155_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained();
    }

    function __ERC1155_init_unchained() internal initializer {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0x0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _setBalance(from, to, id, amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            from,
            to,
            id,
            amount,
            gasleft(),
            data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0x0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            _setBalance(from, to, ids[i], amounts[i]);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            gasleft(),
            data
        );
    }

    /**
     * @dev called from _safeTransferFrom and _safeBatchTransferFrom to update balances
     */
    function _setBalance(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual {
        uint256 fromBalance = _balances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0x0),
            "ERC1155: balance query for the zero address"
        );
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            _msgSender() != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try
                IERC1155ReceiverUpgradeable(to).onERC1155Received{gas: gasLimit}(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155ReceiverUpgradeable(to).onERC1155Received.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256 gasLimit,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try
                IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived{gas: gasLimit}(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155MintBurn.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155MintBurn {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates weither any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        super._mint(account, id, amount, data);
        _totalSupply[id] += amount;
    }

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function _mintBatchSingle(
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._mintBatchSingle(to, id, amount);
        _totalSupply[id] += amount;
    }

    /**
     * @dev See {ERC1155-_burn}.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }

    /**
     * @dev See {ERC1155-_burnBatch}.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        super._burnBatch(account, ids, amounts);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] -= amounts[i];
        }
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../ERC1155.sol";

/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
abstract contract ERC1155MintBurn is ERC1155 {
    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0x0), "ERC1155: mint to the zero address");
        require(amount > 0, "ERC1155: amount to mint is 0");

        _beforeTokenTransfer(
            _msgSender(),
            address(0x0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][account] += amount;
        emit TransferSingle(_msgSender(), address(0x0), account, id, amount);

        _doSafeTransferAcceptanceCheck(
            _msgSender(),
            address(0x0),
            account,
            id,
            amount,
            gasleft(),
            data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0x0), "ERC1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        _beforeTokenTransfer(_msgSender(), address(0x0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _mintBatchSingle(to, ids[i], amounts[i]);
        }

        emit TransferBatch(_msgSender(), address(0x0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            _msgSender(),
            address(0x0),
            to,
            ids,
            amounts,
            gasleft(),
            data
        );
    }

    function _mintBatchSingle(
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(amount > 0, "ERC1155: amount to mint is 0");
        _balances[id][to] += amount;
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0x0), "ERC1155: burn from the zero address");

        _beforeTokenTransfer(
            _msgSender(),
            account,
            address(0x0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        require(
            _balances[id][account] >= amount,
            "ERC1155: burn amount exceeds balance"
        );
        unchecked {
            _balances[id][account] = _balances[id][account] - amount;
        }

        emit TransferSingle(_msgSender(), account, address(0x0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0x0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        _beforeTokenTransfer(
            _msgSender(),
            account,
            address(0x0),
            ids,
            amounts,
            ""
        );

        for (uint256 i = 0; i < ids.length; i++) {
            require(
                _balances[ids[i]][account] >= amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
            unchecked {
                _balances[ids[i]][account] =
                    _balances[ids[i]][account] -
                    amounts[i];
            }
        }

        emit TransferBatch(_msgSender(), account, address(0x0), ids, amounts);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@psi-naas/royalties/contracts/libraries/LibPart.sol";
import "../../libraries/LibERC1155Creators.sol";

interface IERC1155Creators is IERC1155Upgradeable {
    /**
     * @dev Require `_msgSender()` to be the creator of the token id
     * this only succeeds when the tokens has only 1 creator, other wise use signing
     * reverts when `_msgSender()` is not the creator
     */
    function isCreator(uint256 _id) external view returns (bool);

    function getCreators(uint256 _id)
        external
        view
        returns (LibPart.Part[] memory);

    /**
     * @dev Change the creator addresses for given tokens
     * @param _ids token ids to change
     * @param _newCreators new creator addresses
     */
    function setCreatorBatch(
        uint256[] calldata _ids,
        address[] calldata _newCreators
    ) external;

    /**
     * @dev Change the creator address for given token
     * @param _id token id to change
     * @param _newCreator new creator address
     */
    function setCreator(uint256 _id, address _newCreator) external;

    /**
     * @dev Change the creator address for multiple tokens
     * @param data[] the new creators data (signed by all creators) for all tokens
     */
    function setCreatorsBatch(LibERC1155Creators.Data[] memory data) external;

    /**
     * @dev Change the creator address for given token
     * @param data the new creators data (signed by all creators)
     */
    function setCreators(LibERC1155Creators.Data memory data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@psi-naas/royalties/contracts/libraries/LibPart.sol";

library LibERC1155Creators {
    struct Data {
        uint256 tokenId;
        LibPart.Part[] creators;
        bytes[] signatures;
        bytes[] previousSignatures;
    }

    bytes32 public constant CREATORS_TYPEHASH =
        keccak256(
            "CreatorsData(uint256 tokenId,Part[] creators)Part(address account,uint256 value)"
        );

    function hash(Data memory data) internal pure returns (bytes32) {
        bytes32[] memory creatorsBytes = new bytes32[](data.creators.length);
        for (uint256 i = 0; i < data.creators.length; i++) {
            creatorsBytes[i] = LibPart.hash(data.creators[i]);
        }
        return
            keccak256(
                abi.encode(
                    CREATORS_TYPEHASH,
                    data.tokenId,
                    keccak256(abi.encodePacked(creatorsBytes))
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

/**
 * @dev Introducing collection for ERC1155 tokens.
 *
 * Useful for multiple collection contracts, transfering whole collections and
 * showing collection metadata.
 */
interface IERC1155Collection is IERC1155Upgradeable {
    /**
     * @notice Collection URI's default URI prefix
     */
    function baseCollectionURI() external view returns (string memory);

    /**
     * @notice Retrieve the collection ID for a token
     */
    function collectionTokens(uint256 _id)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice returns the collection id for a token
     */
    function collectionForToken(uint256 _tokenId)
        external
        view
        returns (uint256);

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given collection.
     * @return URI string
     */
    function collectionURI(uint256 _id) external view returns (string memory);

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given collection by token ID.
     * @return URI string
     */
    function collectionURIForToken(uint256 _tokenId)
        external
        view
        returns (string memory);

    /**
     * @notice Checks if a collection exists
     * @return bool exists
     */
    function collectionExists(uint256 collectionId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IERC1155Proxy is IERC1155Upgradeable {
    function proxyRegistryAddress() external view returns (address);

    function proxyRegistryAddressPending() external view returns (address);

    function proxyRegistryAddressPendingTime() external view returns (uint256);

    function proxyAddressTimestamp() external view returns (uint256);

    /**
     * @dev Add a new proxy address (only owner)
     * address can be applied after `proxyAddressesTimestamp` seconds have past
     */
    function proxyRegistryAddressAdd(address _proxyRegistryAddress) external;

    /**
     * @dev Apply a new proxy address after `proxyAddressesTimestamp` seconds have past (only owner)
     */
    function proxyRegistryAddressApply() external;

    /**
     * @dev Possibility to revoke a proxy address at all times by the owner
     */
    function proxyRegistryAddressRevoke() external;
}

