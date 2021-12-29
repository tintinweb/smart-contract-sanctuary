//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract OneOfX is IERC721Metadata, IERC721Enumerable, EIP712 {
    event WithdrawnBatch(address indexed user, uint256[] tokenIds);
    event TransferWithMetadata(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        string metaData
    );
    event ProjectCreated(uint256 indexed projectId);
    event ProjectComplete(uint256 indexed projectId);
    event ProjectSetActive(uint256 indexed projectId, bool active);
    event TokenListed(uint256 indexed tokenId, uint256 price);
    event TokenUnlisted(uint256 indexed tokenId);
    event TokenPurchased(uint256 indexed tokenId, uint256 price);

    struct Voucher {
        uint256 projectId;
        uint256 tokenId;
        uint256 price;
        string uri;
        bytes signature;
    }

    struct Project {
        bool active;
        address payable artist;
        uint256 maxSupply;
        uint256 revSharePercent;
        uint256 royaltyPercent;
        uint256[] tokenIds;
    }

    string public override name = "1 of X";
    string public override symbol = "1/X";
    string public contractURI = "";
    uint256 public registrationPrice = 0;
    address private signerAddress;
    address payable private payoutAddress;
    string private constant SIGNING_DOMAIN = "1/X";
    string private constant SIGNATURE_VERSION = "1";
    uint256 private constant REV_SHARE_PERCENT = 8;

    string private constant ERR_NOT_AUTHORIZED = "NOT_AUTHORIZED";
    string private constant ERR_BAD_REQUEST = "BAD_REQUEST";
    string private constant ERR_BAD_SIG = "BAD_SIGNATURE";
    string private constant ERR_BAD_RECEIVER = "BAD_RECEIVER";

    // keccak256("Voucher(uint256 projectId,uint256 tokenId,uint256 price,string uri)"),
    uint256 private constant HASH_MINT =
        0xda23fdd34f87fc366001e6fa219513efc3fab1bbb5680e299134e0ecd89e6bbe;

    mapping(uint256 => Project) public projects;
    mapping(uint256 => bool) public withdrawnTokens;
    mapping(address => bool) public administrators;
    mapping(address => bool) public depositors;
    mapping(uint256 => address) private tokenApprovals;
    mapping(uint256 => address) private tokenOwners;
    mapping(uint256 => string) public override tokenURI;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    mapping(address => uint256[]) public addressToTokenIds;
    mapping(uint256 => uint256) internal tokenIdToIndexInOwner;
    mapping(uint256 => uint256) internal tokenIdToIndex;

    mapping(uint256 => uint256) public listedTokens;
    uint256[] public indexToTokenId;

    mapping(uint256 => uint256) internal tokenIdToProjectId;

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        signerAddress = _msgSender();
        payoutAddress = payable(_msgSender());
        administrators[signerAddress] = true;
    }

    modifier onlyAdmin() {
        require(administrators[_msgSender()], ERR_NOT_AUTHORIZED);
        _;
    }

    modifier onlyDepositor() {
        require(depositors[_msgSender()], ERR_NOT_AUTHORIZED);
        _;
    }

    modifier onlyArtist(uint256 id) {
        require(
            administrators[_msgSender()] || projects[id].artist == _msgSender(),
            ERR_NOT_AUTHORIZED
        );
        _;
    }

    function setPayoutAddress(address payable addr) public onlyAdmin {
        payoutAddress = addr;
    }

    function setSignerAddress(address payable addr) public onlyAdmin {
        signerAddress = addr;
    }

    function setRegistrationPrice(uint256 price) public onlyAdmin {
        registrationPrice = price;
    }

    function setAdmin(address addr, bool isAdmin) public onlyAdmin {
        administrators[addr] = isAdmin;
    }

    function setDepositor(address addr, bool isDepositor) public onlyAdmin {
        depositors[addr] = isDepositor;
    }

    function setContractURI(string memory uri) public onlyAdmin {
        contractURI = uri;
    }

    function createProject(
        uint256 id,
        uint256 maxSupply,
        uint256 royaltyPercent
    ) public payable {
        require(
            projects[id].artist == address(0) &&
                (administrators[_msgSender()] ||
                    registrationPrice == msg.value),
            ERR_BAD_REQUEST
        );

        if (msg.value > 0) payoutAddress.transfer(msg.value);

        projects[id].active = false;
        projects[id].artist = payable(_msgSender());
        projects[id].maxSupply = maxSupply;
        projects[id].revSharePercent = REV_SHARE_PERCENT;
        projects[id].royaltyPercent = royaltyPercent;
        emit ProjectCreated(id);
    }

    function updateArtist(uint256 id, address payable artist) public onlyAdmin {
        projects[id].artist = artist;
    }

    function setProjectActive(uint256 id, bool active) public onlyArtist(id) {
        projects[id].active = active;
        emit ProjectSetActive(id, active);
    }

    function setProjectRevShare(uint256 id, uint256 revSharePercent)
        public
        onlyArtist(id)
    {
        require(
            revSharePercent >= 0 && revSharePercent <= 100,
            ERR_BAD_REQUEST
        );
        projects[id].revSharePercent = revSharePercent;
    }

    function projectTokenIds(uint256 projectId)
        external
        view
        returns (uint256[] memory)
    {
        return projects[projectId].tokenIds;
    }

    function balanceOf(address addr) external view returns (uint256 balance) {
        return addressToTokenIds[addr].length;
    }

    function ownerOf(uint256 tokenId)
        public
        view
        override
        returns (address owner)
    {
        return tokenOwners[tokenId];
    }

    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address owner)
    {
        require(_exists(tokenId), ERR_BAD_REQUEST);
        return tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return operatorApprovals[owner][operator];
    }

    function isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        address owner = tokenOwners[tokenId];
        require(owner != address(0), ERR_BAD_REQUEST);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function redeemTo(address redeemer, Voucher calldata voucher)
        public
        payable
    {
        verify(voucher);

        require(
            redeemer != address(0) &&
                msg.value == voucher.price &&
                projects[voucher.projectId].active &&
                projects[voucher.projectId].tokenIds.length <
                projects[voucher.projectId].maxSupply &&
                !_exists(voucher.tokenId),
            ERR_BAD_REQUEST
        );

        projects[voucher.projectId].tokenIds.push(voucher.tokenId);

        if (
            projects[voucher.projectId].tokenIds.length ==
            projects[voucher.projectId].maxSupply
        ) {
            emit ProjectComplete(voucher.projectId);
        }

        tokenURI[voucher.tokenId] = voucher.uri;
        tokenIdToProjectId[voucher.tokenId] = voucher.projectId;

        _mint(redeemer, voucher.tokenId);

        if (msg.value > 0) {
            uint256 value = msg.value;
            uint256 oneOfXAmount = (value / 100) *
                projects[voucher.projectId].revSharePercent;

            if (oneOfXAmount > 0) {
                payoutAddress.transfer(oneOfXAmount);
                value -= oneOfXAmount;
            }

            projects[voucher.projectId].artist.transfer(value);
        }

        emit TokenPurchased(voucher.tokenId, msg.value);
    }

    function list(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == _msgSender(), ERR_NOT_AUTHORIZED);
        require(price > 0, ERR_BAD_REQUEST);

        listedTokens[tokenId] = price;

        emit TokenListed(tokenId, price);
    }

    function unlist(uint256 tokenId) public {
        require(ownerOf(tokenId) == _msgSender(), ERR_NOT_AUTHORIZED);

        delete listedTokens[tokenId];

        emit TokenUnlisted(tokenId);
    }

    function purchaseTo(uint256 tokenId, address addr) public payable {
        require(msg.value > 0, ERR_BAD_REQUEST);
        require(listedTokens[tokenId] == msg.value, ERR_NOT_AUTHORIZED);

        uint256 projectId = tokenIdToProjectId[tokenId];

        uint256 value = msg.value;
        uint256 oneOfXAmount = (value / 100) *
            projects[projectId].revSharePercent;
        uint256 royaltyAmount = (value / 100) *
            projects[projectId].royaltyPercent;

        if (oneOfXAmount > 0) {
            payoutAddress.transfer(oneOfXAmount);
            value -= oneOfXAmount;
        }

        if (royaltyAmount > 0) {
            projects[projectId].artist.transfer(royaltyAmount);
            value -= royaltyAmount;
        }

        payable(ownerOf(tokenId)).transfer(value);

        _safeTransfer(ownerOf(tokenId), addr, tokenId, "");

        emit TokenPurchased(tokenId, msg.value);
    }

    function verify(Voucher calldata voucher) internal view {
        require(
            signerAddress ==
                ECDSA.recover(
                    _hashTypedDataV4(
                        keccak256(
                            abi.encode(
                                HASH_MINT,
                                voucher.projectId,
                                voucher.tokenId,
                                voucher.price,
                                keccak256(bytes(voucher.uri))
                            )
                        )
                    ),
                    voucher.signature
                ),
            ERR_BAD_SIG
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        _safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override {
        _safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        require(isApprovedOrOwner(_msgSender(), tokenId), ERR_NOT_AUTHORIZED);
        _safeTransfer(from, to, tokenId, "");
    }

    function approve(address to, uint256 tokenId) external override {
        require(_exists(tokenId), ERR_BAD_REQUEST);
        address owner = ownerOf(tokenId);
        require(
            (to != owner && _msgSender() == owner) ||
                isApprovedForAll(owner, _msgSender()),
            ERR_BAD_REQUEST
        );
        _approve(to, tokenId);
    }

    function totalSupply() external view returns (uint256) {
        return indexToTokenId.length;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId)
    {
        require(addressToTokenIds[owner].length > index, ERR_BAD_REQUEST);
        return addressToTokenIds[owner][index];
    }

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory tokenId)
    {
        return addressToTokenIds[owner];
    }

    function tokenByIndex(uint256 index) external view returns (uint256) {
        require(indexToTokenId.length > index, ERR_BAD_REQUEST);
        return indexToTokenId[index];
    }

    function getChainID() external view returns (uint256) {
        uint256 id;

        assembly {
            id := chainid()
        }

        return id;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function deposit(address user, uint256[] calldata tokenIds) public {
        uint256 length = tokenIds.length;
        for (uint256 i; i < length; i++) {
            deposit(user, tokenIds[i]);
        }
    }

    function deposit(address user, uint256 tokenId) public onlyDepositor {
        require(withdrawnTokens[tokenId], ERR_NOT_AUTHORIZED);
        withdrawnTokens[tokenId] = false;
        _mint(user, tokenId);
    }

    function withdraw(uint256 tokenId) public {
        require(_msgSender() == ownerOf(tokenId), ERR_NOT_AUTHORIZED);

        withdrawnTokens[tokenId] = true;

        emit TransferWithMetadata(
            ownerOf(tokenId),
            address(0),
            tokenId,
            tokenURI[tokenId]
        );

        _burn(tokenId);
    }

    function withdraw(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        require(length <= 20, ERR_BAD_REQUEST);
        for (uint256 i; i < length; i++) {
            withdraw(tokenIds[i]);
        }

        emit WithdrawnBatch(_msgSender(), tokenIds);
    }

    // private

    function _mint(address to, uint256 tokenId) internal {
        _addToAddress(tokenId, to);
        tokenIdToIndex[tokenId] = indexToTokenId.length;
        indexToTokenId.push(tokenId);

        emit Transfer(address(0), to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, ""),
            ERR_BAD_RECEIVER
        );
    }

    function _exists(uint256 tokenId) private view returns (bool) {
        return ownerOf(tokenId) != address(0) && !withdrawnTokens[tokenId];
    }

    function _isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private {
        require(isApprovedOrOwner(_msgSender(), tokenId), ERR_NOT_AUTHORIZED);
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            ERR_BAD_RECEIVER
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        require(ownerOf(tokenId) == from && to != address(0), ERR_BAD_REQUEST);
        delete tokenApprovals[tokenId];
        delete listedTokens[tokenId];

        _removeFromAddress(tokenId, from);
        _addToAddress(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    function _removeFromAddress(uint256 tokenId, address from) internal {
        delete tokenOwners[tokenId];

        uint256 tokenIndex = tokenIdToIndexInOwner[tokenId];

        addressToTokenIds[from][tokenIndex] = addressToTokenIds[from][
            addressToTokenIds[from].length - 1
        ];
        addressToTokenIds[from].pop();

        delete tokenIdToIndexInOwner[tokenId];
    }

    function _addToAddress(uint256 tokenId, address to) internal {
        tokenOwners[tokenId] = to;
        tokenIdToIndexInOwner[tokenId] = addressToTokenIds[to].length;
        addressToTokenIds[to].push(tokenId);
    }

    function _approve(address to, uint256 tokenId) private {
        tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) private {
        require(owner != operator, ERR_BAD_REQUEST);
        operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (_isContract(to)) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(ERR_BAD_RECEIVER);
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

    function _msgSender() internal view returns (address payable sender) {
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

    function _burn(uint256 tokenId) private {
        delete tokenApprovals[tokenId];
        delete listedTokens[tokenId];
        address owner = ownerOf(tokenId);

        _removeFromAddress(tokenId, owner);

        uint256 tokenIndex = tokenIdToIndex[tokenId];
        indexToTokenId[tokenIndex] = indexToTokenId[indexToTokenId.length - 1];
        indexToTokenId.pop();

        delete tokenIdToIndex[tokenId];

        emit Transfer(owner, address(0), tokenId);
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

import "./ECDSA.sol";

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
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

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
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
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
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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