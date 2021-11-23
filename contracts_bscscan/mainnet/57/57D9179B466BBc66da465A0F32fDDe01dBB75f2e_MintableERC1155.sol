// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155Receiver.sol";
import "./Context.sol";
import "./IERC165.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./StringLibrary.sol";
import "./Ownable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `_interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `_interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


contract HasContractURI is ERC165 {
    string private _contractURI;

    /*
     * bytes4(keccak256('contractURI()')) == 0xe8a3d485
     */
    bytes4 private constant _INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

    constructor(string memory contractURI) public {
        _contractURI = contractURI;
        _registerInterface(_INTERFACE_ID_CONTRACT_URI);
    }

    /**
     * @dev Internal function to set the contract URI
     * @param contractURI string URI prefix to assign
     */
    function _setContractURI(string memory contractURI) internal {
        _contractURI = contractURI;
    }

    function getContractURI() public view returns (string memory){
        return _contractURI;
    }
}


abstract contract HasCopyright is ERC165 {

    struct Copyright {
        address author;
        uint256 feeRateNumerator;
    }

    uint private constant _feeRateDenominator = 10000;

    event SetCopyright(
        uint256 id,
        address creator,
        address author,
        uint256 feeRateNumerator,
        uint256 feeRateDenominator
    );

    /*
     * bytes4(keccak256('getCopyright(uint256)')) == 0x6f4eaff1
     */
    bytes4 private constant _INTERFACE_ID_COPYRIGHT = 0x6f4eaff1;

    // Mapping from id to copyright
    mapping(uint256 => Copyright) internal _copyrights;

    constructor() public {
        _registerInterface(_INTERFACE_ID_COPYRIGHT);
    }

    function _setCopyright(uint256 id, address creator, Copyright[] memory copyrightInfos) internal {
        uint256 copyrightLen = copyrightInfos.length;
        require(copyrightLen <= 1,
            "the length of copyrights must be <= 1");
        if (copyrightLen == 1) {
            require(copyrightInfos[0].author != address(0),
                "the author in copyright can't be zero"
            );
            require(copyrightInfos[0].feeRateNumerator <= _feeRateDenominator,
                "the feeRate in copyright must be <= 1"
            );

            _copyrights[id] = copyrightInfos[0];
            emit SetCopyright(id, creator, copyrightInfos[0].author, copyrightInfos[0].feeRateNumerator, _feeRateDenominator);
        }
    }

    function getFeeRateDenominator() public pure returns (uint256){
        return _feeRateDenominator;
    }

    function getCopyright(uint256 id) public view virtual returns (Copyright memory);
}


contract ERC1155Base is Context, IERC1155MetadataURI, HasCopyright, HasContractURI {
    using SafeMath for uint256;
    using Address for address;
    using StringLibrary for string;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Token URI prefix
    string private _tokenURIPrefix;

    // Mapping from id to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from id to token uri
    mapping(uint256 => string) private _uris;

    // Mapping from id to token supply
    mapping(uint256 => uint256) private _tokenSupply;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    constructor (
        string memory name,
        string memory symbol,
        string memory contractURI,
        string memory tokenURIPrefix
    )
    HasContractURI(contractURI)
    public {
        _name = name;
        _symbol = symbol;
        _tokenURIPrefix = tokenURIPrefix;

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 id) external view virtual override returns (string memory) {
        _requireTokenExisted(id);
        return _tokenURIPrefix.append(_uris[id]);
    }

    function getTokenSupply(uint256 id) external view returns (uint256){
        _requireTokenExisted(id);
        return _tokenSupply[id];
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
    public
    view
    virtual
    override
    returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
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
    )
    public
    virtual
    override
    {
        require(to != address(0), "transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
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
    )
    public
    virtual
    override
    {
        require(ids.length == amounts.length, "ids and amounts length mismatch");
        require(to != address(0), "transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function getName() external view returns (string memory){
        return _name;
    }

    function getSymbol() external view returns (string memory){
        return _symbol;
    }

    function getTokenURIPrefix() external view returns (string memory){
        return _tokenURIPrefix;
    }

    function getCopyright(uint256 id) public view override returns (Copyright memory){
        _requireTokenExisted(id);
        return _copyrights[id];
    }

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
    function _mint(uint256 id, address account, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _tokenSupply[id] = amount;
        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
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
    )
    internal
    virtual
    {}

    /**
     * @dev Internal function to set the token URI for a given token.
     * @param id uint256 ID of the token to set its URI
     * @param tokenURI string URI to assign
     */
    function _setTokenURI(uint256 id, string memory tokenURI) internal {
        _uris[id] = tokenURI;
        emit URI(tokenURI, id);
    }

    /**
     * @dev Internal function to set the token URI prefix.
     * @param tokenURIPrefix string URI prefix to assign
     */
    function _setTokenURIPrefix(string memory tokenURIPrefix) internal {
        _tokenURIPrefix = tokenURIPrefix;
    }

    function _requireTokenExisted(uint256 id) private view {
        require(_tokenSupply[id] != 0, "target token doesn't exist");
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
    private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
    private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}


contract MintableERC1155 is Ownable, ERC1155Base {
    using SafeMath for uint256;

    uint256 private _idCounter;

    constructor (
        string memory name,
        string memory symbol,
        address newOwner,
        string memory contractURI,
        string memory tokenURIPrefix
    )
    public
    ERC1155Base(name, symbol, contractURI, tokenURIPrefix)
    {
        _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
        transferOwnership(newOwner);
    }

    function mint(
        address receiver,
        uint256 amount,
        string memory tokenURI,
        bytes memory data,
        Copyright[] memory copyrightInfos
    ) external {
        require(amount > 0, "amount to mint must be > 0");
        // 1. get id with auto-increment
        uint256 currentId = _idCounter;
        _idCounter = _idCounter.add(1);

        // 2. mint
        _mint(currentId, receiver, amount, data);

        // 3. set tokenURI
        _setTokenURI(currentId, tokenURI);

        // 4. set copyright
        _setCopyright(currentId, msg.sender, copyrightInfos);
    }

    function setTokenURIPrefix(string memory tokenURIPrefix) external onlyOwner {
        _setTokenURIPrefix(tokenURIPrefix);
    }

    function setContractURI(string memory contractURI) external onlyOwner {
        _setContractURI(contractURI);
    }
}