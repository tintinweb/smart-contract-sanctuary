pragma solidity ^0.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./FireZardNFT.sol";
import "./StatsView.sol";
import "./DragonStats.sol";
import {Util} from "./Util.sol";

contract Treasury is Ownable, AccessControlEnumerable {
    address public	nft;
    address public	viewer;
    address public	stats;

    bytes32 public MINTER_ROLE;

    mapping(Util.CardRarity => uint256)	public	reward_table;

    mapping(uint256 => bool)		public	claims;

    string rarity_str;
    string rarity_override_str;

    modifier onlyMinter() {
	require(hasRole(MINTER_ROLE, _msgSender()), "Treasury: must have minter role to claim rewards");
	_;
    }

    constructor(address _nft, address _viewer, address _stats) {
	nft = _nft;
	viewer = _viewer;
	stats = _stats;
	rarity_str  = DragonStats(stats).RARITY_STR();
	rarity_override_str  = DragonStats(stats).RARITY_OVERRIDE_STR();
	MINTER_ROLE = FireZardNFT(nft).MINTER_ROLE();

	super._setupRole(DEFAULT_ADMIN_ROLE,msg.sender);
    }

    /**
     * @notice Sets link to ERC1155 NFT smart contract
    **/
    function linkNFT(address _nft) public virtual onlyOwner {
        nft = _nft;
	MINTER_ROLE = FireZardNFT(nft).MINTER_ROLE();
        emit NFTLink(nft);
    }

    /**
     * @notice Sets link to Tag Storage smart contract
    **/
    function linkViewer(address _viewer) public virtual onlyOwner {
        viewer = _viewer;
        emit ViewLink(viewer);
    }

    /**
     * @notice Sets link to the Stats deriving library
    **/
    function linkStatsLib(address _stats) public virtual onlyOwner {
        stats = _stats;
	rarity_str  = DragonStats(stats).RARITY_STR();
        emit StatsLibLink(stats);
    }

    // Deposit funds
    fallback() external payable {
	emit Deposit(msg.sender, msg.value);
    }

    function withdraw(address recipient, uint256 amount) external onlyOwner {
	(bool _res, bytes memory _data) = recipient.call{value: amount}("");
	require(_res, "Treasury: Failed to withdraw BNB");
	emit Withdraw(recipient, amount);
    }

    function claim(uint256 token_id) external {
	require(FireZardNFT(nft).totalSupply(token_id) == 1, "Treasury: The token must be present in single quantity");

	address to = FireZardNFT(nft).ownerOf(token_id);
	if(to != _msgSender())
	    if(!hasRole(MINTER_ROLE, _msgSender()))
		revert("Treasury: The reward must be claimed to the token owner");

	require(FireZardNFT(nft).typeOf(token_id) == Util.DRAGON_CARD_TYPE_CODE, "Treasury: The token must be of Dragon Card NFT type");
	require(!claims[token_id], "Treasury: The card's reward has been already claimed");

	claims[token_id] = true;
	Util.CardRarity card_rarity;
	if(StatsView(viewer).getStat(Util.DRAGON_CARD_TYPE_CODE, token_id, rarity_override_str).bool_val)
	    card_rarity = Util.CardRarity.Uncommon;
	else
	    card_rarity = Util.CardRarity(StatsView(viewer).getStat(Util.DRAGON_CARD_TYPE_CODE, token_id, rarity_str).int_val);
	uint256 reward_value = reward_table[card_rarity];
	if(reward_value>0){
	    (bool _res, bytes memory _data) = to.call{value: reward_value}("");
	    require(_res, "Treasury: Failed to claim BNB");
	    emit Claimed(to, token_id, reward_value);
	}
    }

    function setReward(Util.CardRarity _rarity, uint256 _reward) external onlyOwner {
	reward_table[_rarity] = _reward;
    }

    function getRewardValue(Util.CardRarity _rarity) external view returns (uint256) {
	return reward_table[_rarity];
    }

    event NFTLink(address contract_addr);
    event ViewLink(address contract_addr);
    event StatsLibLink(address contract_addr);
    event Deposit(address sender, uint256 amount);
    event Withdraw(address sender, uint256 amount);
    event Claimed(address sender, uint256 token_id, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/presets/ERC1155PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";
import "../extensions/ERC1155Burnable.sol";
import "../extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC1155PresetMinterPauser is Context, AccessControlEnumerable, ERC1155Burnable, ERC1155Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    constructor(string memory uri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
		if(_totalSupply[ids[i]] >= amounts[i])
            	    _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Pausable is ERC1155, Pausable {
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
//    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
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
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    function _getBaseURI() internal view returns (string memory) {
	return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
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
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

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
        _setApprovalForAll(_msgSender(), operator, approved);
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
            "ERC1155: transfer caller is not owner nor approved"
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
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);
	_rebalance(from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
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
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

	_rebalance(from, to, ids, amounts, data);

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * Rebalancing token amounts to meet tokens batch transfer order. See {_safeBatchTransferFrom}
     */
    function _rebalance(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
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
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
//        emit ApprovalForAll(owner, operator, approved);
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
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
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
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

/**
 * FireZard utilities lib
 */

pragma solidity ^0.8.0;

//import "./TagStorage.sol";

library Util {
    uint256 public constant MAX_UINT = (~uint256(0)-1);
//    bytes32 public constant DRAGON_CARD_TYPE_CODE = abi.encodePacked(keccak256('DRAGON_CARD'));
    bytes32 public constant DRAGON_CARD_TYPE_CODE = keccak256('DRAGON_CARD');

    enum CardRarity{ Ultra_Rare, Super_Rare, Rare, Uncommon, Common }
    enum CardType{ Fire, Ice, Plant, Electric, Water }
    enum StatType{ Integer, String, ByteArray, Boolean }

    struct Stat{
	string name;
	StatType statType;
	bool is_mutable;
    }

    struct StatValue{
	StatType statType;
	uint256  int_val;
	string   str_val;
	bytes32  bta_val;
	bool     bool_val;
    }

    function getTagKey(uint256 nft_id, string calldata name) public pure returns(bytes32) {
	return keccak256(abi.encodePacked(nft_id, name));
    }

    function getRandomItem(uint256 rvalue, uint256[] calldata distribution, uint256 size) public pure returns(uint256) {
	uint256 ratio = MAX_UINT/size;
	uint256 svalue = 0;
	for(uint256 i=0;i<distribution.length;i++){
	    svalue+=ratio*distribution[i];
	    if(rvalue < svalue)
		return i;
	}
	return distribution.length;
    }

      function deriveCommitment(bytes32 entropy) public pure returns (bytes32){
        return keccak256(abi.encodePacked(entropy));
    }

}

/**
 * @notice Stores FireZard tokens tags related to game mechanics
 * @title FireZard Tag generic storage
 * @notice Stores tags (key-value) pairs of byte32, string, uint256 and boolean types.
 * The storage is agnostic to what contract (editor) and what data are being stored. Tags are formed by 
 * the editor contracts. The storage provides authentication for adding/modifying tags.
 * 
 * Each tag is assigned an editors' group. An editor (contract or user) can be added to one or more groups.
 * An editor can add/modify only those tags that are assigned to a group which the editor belongs to.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Util} from "./Util.sol";


contract TagStorage is Context, Ownable, AccessControlEnumerable {
    bytes32 public constant ADDER_ROLE = keccak256('ADDER_ROLE');

    mapping (bytes32 => uint8) tagGroup;
    mapping (bytes32 => bytes32) tagByte32Value;
    mapping (bytes32 => string) tagStringValue;
    mapping (bytes32 => uint256) tagIntValue;
    mapping (bytes32 => bool) tagBooleanValue;
    mapping (bytes32 => Util.StatType) tagType;
    mapping (bytes32 => bool) groupMember;

    modifier onlyAdder() {
	require(hasRole(ADDER_ROLE, msg.sender),"TagStorage: The caller must have adder's priviledges");
	_;
    }

    modifier onlyAdmin() {
	require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender),"TagStorage: The caller must have admin's priviledges");
	_;
    }

    modifier authorizeEdit(uint8 groupID, bytes32 key) {
	if(tagGroup[key]>0){
	    bytes32 groupMemberKey = keccak256(abi.encode(msg.sender,tagGroup[key]));
	    require(groupMember[groupMemberKey],"TagStorage: Need to be tag's group member");
	}
	tagGroup[key] = groupID;
	_;
    }

    modifier byte32Tag(bytes32 key) {
	require((tagType[key] == Util.StatType.ByteArray), "TagStorage: The tag must be a byte array");
	_;
    }

    modifier stringTag(bytes32 key) {
	require((tagType[key] == Util.StatType.String), "TagStorage: The tag must be a string");
	_;
    }

    modifier intTag(bytes32 key) {
	require((tagType[key] == Util.StatType.Integer), "TagStorage: The tag must be an integer");
	_;
    }

    modifier booleanTag(bytes32 key) {
	require((tagType[key] == Util.StatType.Boolean), "TagStorage: The tag must be a boolean");
	_;
    }

    constructor() {
	super._setupRole(DEFAULT_ADMIN_ROLE,msg.sender);
    }

    function grantAdminRole(address entity) external virtual onlyOwner {
	super._setupRole(DEFAULT_ADMIN_ROLE,entity);
    }

    function revokeAdminRole(address entity) external virtual onlyOwner {
	super.revokeRole(DEFAULT_ADMIN_ROLE,entity);
    }

    function grantAdderRole(address entity) external virtual onlyAdmin {
	super._setupRole(ADDER_ROLE,entity);
    }

    function revokeAdderRole(address entity) external virtual onlyAdmin {
	super.revokeRole(ADDER_ROLE,entity);
    }

    function isAdmin(address entity) external view returns (bool) {
	return hasRole(DEFAULT_ADMIN_ROLE, entity);
    }

    function isAdder(address entity) external view returns (bool) {
	return hasRole(ADDER_ROLE, entity);
    }

    function isGroupMember(address entity, uint8 groupID) external view returns (bool) {
	bytes32 groupMemberKey = keccak256(abi.encode(entity,groupID));
	return groupMember[groupMemberKey];
    }

    /**
     * @notice Add editor to a group
     * 
     * @param entity  Editor's address. It can be contract or user
     * @param groupID The id of the group where to add the entity
    **/
    function addEditor2Group(address entity,uint8 groupID) public virtual onlyAdmin {
	bytes32 groupMemberKey = keccak256(abi.encode(entity,groupID));
	groupMember[groupMemberKey] = true;
    }

    /**
     * @notice Remove editor from the group
     * 
     * @param entity  Editor's address. It can be contract or user
     * @param groupID The id of the group from where to remove the entity
    **/
    function removeEditorFromGroup(address entity,uint8 groupID) public virtual onlyAdmin {
	bytes32 groupMemberKey = keccak256(abi.encode(entity,groupID));
	groupMember[groupMemberKey] = false;
    }

    /**
     * @notice Set a byte array tag. The caller must have an adder role. 
     * The caller with the adder role can create new tag and assign it to any group id.
     * The caller may modify existing tag and assign it to a new group id if the caller belongs to the group currently associated to the tag.
     *
     * @param groupID The ID of the group for the tag
     * @param key     The key of the tag
     * @param value   The value (type byte32) of the tag
    **/
    function setTag(uint8 groupID, bytes32 key, bytes32 value) public virtual onlyAdder authorizeEdit(groupID, key) {
	tagType[key] = Util.StatType.ByteArray;
	tagByte32Value[key] = value;
    }

    /**
     * @notice Set a string tag. The caller must have an adder role.
     * The caller with the adder role can create new tag and assign it to any group id.
     * The caller may modify existing tag and assign it to a new group id if the caller belongs to the group currently associated to the tag.
     *
     * @param groupID The ID of the group for the tag
     * @param key     The key of the tag
     * @param value   The value (type string) of the tag
    **/
    function setTag(uint8 groupID, bytes32 key, string calldata value) public virtual onlyAdder authorizeEdit(groupID, key) {
	tagType[key] = Util.StatType.String;
	tagStringValue[key] = value;
    }

    /**
     * @notice Set an integer tag. The caller must have an adder role.
     * The caller with the adder role can create new tag and assign it to any group id.
     * The caller may modify existing tag and assign it to a new group id if the caller belongs to the group currently associated to the tag.
     *
     * @param groupID The ID of the group for the tag
     * @param key     The key of the tag
     * @param value   The value (type uint256) of the tag
    **/
    function setTag(uint8 groupID, bytes32 key, uint256 value) public virtual onlyAdder authorizeEdit(groupID, key) {
	tagType[key] = Util.StatType.Integer;
	tagIntValue[key] = value;
    }

    /**
     * @notice Set a boolean tag. The caller must have an adder role.
     * The caller with the adder role can create new tag and assign it to any group id.
     * The caller may modify existing tag and assign it to a new group id if the caller belongs to the group currently associated to the tag.
     *
     * @param groupID The ID of the group for the tag
     * @param key     The key of the tag
     * @param value   The value (type boolean) of the tag
    **/
    function setTag(uint8 groupID, bytes32 key, bool value) public virtual onlyAdder authorizeEdit(groupID, key) {
	tagType[key] = Util.StatType.Boolean;
	tagBooleanValue[key] = value;
    }

    /**
     * @notice Gets data type of the tag.
     *
     * @param  key The tag's key
     * @return The tag's value data type
    **/
    function getTagType(bytes32 key) public view returns (Util.StatType) {
	return tagType[key];
    }

    /**
     * @notice Gets tag's value of byte array type.
     *
     * @param key The tag's key
     * @return The tag's value of type bytes32
    **/
    function getByte32Value(bytes32 key) public view byte32Tag(key) returns (bytes32) {
	return tagByte32Value[key];
    }

    /**
     * @notice Gets tag's value of string type.
     *
     * @param key The tag's key
     * @return The tag's value of type string
    **/
    function getStringValue(bytes32 key) public view stringTag(key) returns (string memory) {
	return tagStringValue[key];
    }

    /**
     * @notice Gets tag's value of integer type.
     *
     * @param key The tag's key
     * @return The tag's value of type uint256
    **/
    function getIntValue(bytes32 key) public view intTag(key) returns (uint256) {
	return tagIntValue[key];
    }

    /**
     * @notice Gets tag's value of boolean type.
     *
     * @param key The tag's key
     * @return The tag's value of type boolean
    **/
    function getBooleanValue(bytes32 key) public view booleanTag(key) returns (bool) {
	return tagBooleanValue[key];
    }

    /**
     * @notice Gets tag's associated group
     *
     * @param key The tag's key
     * @return Id of the groupt to which the tag is currently associated
    **/
    function getTagGroup(bytes32 key) public view returns (uint8) {
	return tagGroup[key];
    }

}

pragma solidity ^0.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStatsDerive.sol";
import "./TagStorage.sol";
import {Util} from "./Util.sol";

contract StatsView is Ownable{

    address public	TAG_addr;
    address public	NFT_addr;
    mapping(bytes32 => address) public	stats_lib_addr;

    constructor(address tag_storage, address nft_container){
	TAG_addr = tag_storage;
	NFT_addr = nft_container;
    }

    /**
     * @notice Sets link to Tag Storage smart contract
    **/
    function linkTAG(address tag_storage) public virtual onlyOwner {
        TAG_addr = tag_storage;
        emit TAGLink(tag_storage);
    }

    /**
     * @notice Sets link to ERC1155 NFT smart contract
    **/
    function linkNFT(address nft_container) public virtual onlyOwner {
        NFT_addr = nft_container;
        emit NFTLink(nft_container);
    }

    /**
     * @notice Sets link to the Stats deriving library
    **/
    function linkStatsLib(address stats_lib, bytes32 nft_type) public virtual onlyOwner {
        stats_lib_addr[nft_type] = stats_lib;
        emit StatsLibLink(stats_lib, nft_type);
    }

    /**
     * @notice Defines a set of stats that can be derived
     *
     * @return An enumerable set (actually, an array) of stats that can be derived by the interface implementation
    **/
    function stats(bytes32 nft_type) external view returns (Util.Stat[] memory) {
	return IStatsDerive(stats_lib_addr[nft_type]).stats(nft_type);
	revert('Unknown NFT type');
    }

     /**
     * @notice Read an integer stat
     *
     * @param id An id generated by an RNG
     * @param name The stats' name
     * @return The stats' value
    **/
    function getStat(bytes32 nft_type, uint256 id, string calldata name) external view returns (Util.StatValue memory){
	bytes32 h_name = keccak256(abi.encodePacked(name));

	Util.Stat[] memory _stats = this.stats(nft_type);
	for(uint i=0; i<_stats.length; i++){
	    bytes32 h_stats_name = keccak256(abi.encodePacked(_stats[i].name));
	    if(h_name != h_stats_name)continue;
	    if(_stats[i].is_mutable){
		bytes32 key = Util.getTagKey(id,name);
		if(_stats[i].statType == Util.StatType.Integer)
		    return (Util.StatValue(_stats[i].statType, TagStorage(TAG_addr).getIntValue(key), "", "", false));
		else if(_stats[i].statType == Util.StatType.String)
		    return (Util.StatValue(_stats[i].statType, 0, TagStorage(TAG_addr).getStringValue(key), "", false));
		else if(_stats[i].statType == Util.StatType.ByteArray)
		    return (Util.StatValue(_stats[i].statType, 0, "", TagStorage(TAG_addr).getByte32Value(key), false));
		else if(_stats[i].statType == Util.StatType.Boolean)
		    return (Util.StatValue(_stats[i].statType, 0, "", "", TagStorage(TAG_addr).getBooleanValue(key)));
		revert("Unknown mutable stat type");
	    }else{
		if(_stats[i].statType == Util.StatType.Integer)
		    return (Util.StatValue(_stats[i].statType, IStatsDerive(stats_lib_addr[nft_type]).getStatInt(nft_type, id, name), "", "", false));
		else if(_stats[i].statType == Util.StatType.String)
		    return (Util.StatValue(_stats[i].statType, 0, IStatsDerive(stats_lib_addr[nft_type]).getStatString(nft_type, id, name), "", false));
		else if(_stats[i].statType == Util.StatType.ByteArray)
		    return (Util.StatValue(_stats[i].statType, 0, "", IStatsDerive(stats_lib_addr[nft_type]).getStatByte32(nft_type, id, name), false));
		else if(_stats[i].statType == Util.StatType.Boolean)
		    return (Util.StatValue(_stats[i].statType, 0, "", "", IStatsDerive(stats_lib_addr[nft_type]).getStatBool(nft_type, id, name)));
		revert("Unknown mutable stat type");
	    }
	}
	revert("StatsView: Requested tag not found");
    }

    event	TAGLink(address tag_addr);
    event	NFTLink(address nft_addr);
    event	StatsLibLink(address stats_lib_addr, bytes32 nft_type);

}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract StatsDistrib is Ownable {

    uint256[] public dragonCardRarity;
    uint256   public dragonCardRarityPopulationSize;
    uint256[] public dragonCardType;
    uint256   public dragonCardTypePopulationSize;

    constructor() {
	dragonCardRarity = new uint256[](4);
	dragonCardRarity[0] = 1;
	dragonCardRarity[1] = 3;
	dragonCardRarity[2] = 6;
	dragonCardRarity[3] = 20;
	dragonCardRarityPopulationSize = 738;

	dragonCardType = new uint256[](4);
	dragonCardType[0] = 1;
	dragonCardType[1] = 1;
	dragonCardType[2] = 1;
	dragonCardType[3] = 1;
	dragonCardTypePopulationSize = 5;
    }

    function getDragonCardRarities() public view returns (uint256[] memory){
	return dragonCardRarity;
    }

    function getDragonCardTypes() public view returns (uint256[] memory){
	return dragonCardType;
    }

    function setRarityDistrib(uint8 index, uint256 position) public onlyOwner {
	dragonCardRarity[index] = position;
    }

    function setRarityPopulationSize(uint256 size) public onlyOwner {
	dragonCardRarityPopulationSize = size;
    }
}

/**
 * Derives stats from card ID
 * @title  Interface for deriving dragon card stats from its ID
 * @author CryptoHog
 * @notice Defines an interface for a contract deriving the stats from a randomly generated ID
 */

pragma solidity ^0.8.0;

import "./Util.sol";

interface IStatsDerive {

    /**
     * @notice Derive an integer stat from the card's ID by the stats' name
     *
     * @param id An id generated by an RNG
     * @param name The stats' name
     * @return The stats' value
    **/
    function getStatInt(bytes32 nft_type, uint256 id, string calldata name) external view returns (uint256);

    /**
     * @notice Derive a string stat from the card's ID by the stats' name
     *
     * @param id An id generated by an RNG
     * @param name The stats' name
     * @return The stats' value
    **/
    function getStatString(bytes32 nft_type, uint256 id, string calldata name) external view returns (string calldata);

    /**
     * @notice Derive a 32 byte array stat from the card's ID by the stats' name
     *
     * @param id An id generated by an RNG
     * @param name The stats' name
     * @return The stats' value
    **/
    function getStatByte32(bytes32 nft_type, uint256 id, string calldata name) external view returns (bytes32);

    /**
     * @notice Derive a boolean stat from the card's ID by the stats' name
     *
     * @param id An id generated by an RNG
     * @param name The stats' name
     * @return The stats' value
    **/
    function getStatBool(bytes32 nft_type, uint256 id, string calldata name) external view returns (bool);

    /**
     * @notice Defines a set of stats that can be derived
     *
     * @return An enumerable set (actually, an array) of stats that can be derived by the interface implementation
    **/
    function stats(bytes32 nft_type) external view returns (Util.Stat[] memory);
}

/**
 * FireZard ERC1155 NFT for storinfg game characters and items (both stackable and unstackable)
 */

pragma solidity ^0.8.0;

import "./dependencies/presets/ERC1155PresetMinterPauser.sol";
import "./dependencies/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract FireZardNFT is IERC1155MetadataURI, ERC1155PresetMinterPauser, ERC1155Supply, IERC721Enumerable, IERC721Metadata {
    using Address for address;

    string _name;
    string _symbol;

    // List of all token IDs
    uint256[] public tokens;

    // Token index mapping: toklen_id => token index in tokens list
    mapping(uint256 => uint256) public tokenIndex;

    // Token ownership mapping: token_id ==> array of token_owner_address
    mapping(uint256 => address[]) public ownership;

    // Owner's address position in ownership list for token_id
    mapping(address => mapping(uint256 => uint256)) private ownershipIndex;

    // Token type mapping: token_id ==> token_type (like, DRAGON_CARD_TYPE_CODE, etc.)
    mapping(uint256 => bytes32) public token_type;

    // Inventory: owner_address => array_of_token_ids
    mapping(address => uint256[]) public inventory;

    // Slot: slot position of token_id in owner_address inventory
    mapping(address => mapping(uint256 => uint256)) private slot;

    // Approved transfer of token_id belonging to an owner for an operator
    mapping(uint256 => mapping(address => address)) private approved;

    // Approved transfer of a token_id to an operator. Applicable only for cases where tokens with token_id belong to a single owner
    mapping(uint256 => address) private singleApproved;

    // Token custom URIs
    mapping(uint256 => string) private uris;


    modifier canBeTransferedAsERC721(address from, address to, uint256 token_id) {
	require(totalSupply(token_id)>0,"ERC721: operator query for nonexistent token");
	bool from_owns_token = false;
	for(uint i=0;i<ownership[token_id].length;i++)
	    if(ownership[token_id][i] == from){
		from_owns_token = true;
		break;
	    }
	require(from_owns_token,"ERC721: transfer from incorrect owner");
	require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()) || isApproved(_asSingletonArray(token_id),from),
            "ERC721: transfer caller is not owner nor approved"
        );
	require(to != address(0),"ERC721: transfer to the zero address");
	_;
    }

    constructor(string memory _uri, string memory name_, string memory symbol_) ERC1155PresetMinterPauser(_uri) {
	_name = name_;
	_symbol = symbol_;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155PresetMinterPauser, ERC1155Supply) {
	if(from == address(0)){
	    uint l=32;
	    if(data.length<l)l=data.length;

	    bytes32 _token_type;

	    for(uint i=0;i<l;i++)
		_token_type |= bytes32(data[i] & 0xFF) >> (i*8);

	    for(uint i=0;i<ids.length;i++)
		token_type[ids[i]] = _token_type;
	}
	super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _transferFrom(
	address from,
	address to,
	uint256 tokenId,
	bytes	memory data,
	bool safe_mode,
	bool ERC721_mode
    ) internal {
	if(ERC721_mode)require(from != address(0));
	require(to != address(0));

	uint256[] memory ids = _asSingletonArray(tokenId);
	uint256[] memory amounts = _asSingletonArray(balanceOf(from,tokenId));
	_transferFrom(
	    from,
	    to,
	    ids,
	    amounts,
	    data,
	    safe_mode,
	    ERC721_mode
	);
    }

    function _transferFrom(
	address from,
	address to,
	uint256[] memory ids,
	uint256[] memory amounts,
	bytes	memory data,
	bool	safe_mode,
	bool	ERC721_mode
    ) internal {
	require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
	require(
            from == operator || isApprovedForAll(from, operator) || isApproved(ids, from),
            "ERC1155: caller is not owner nor approved"
        );

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

	uint256[] memory ids_to = idsToChange(ids,to);
	_rebalance(from, to, ids, amounts, data);
	uint256[] memory ids_from = idsToChange(ids,from);

	if(ERC721_mode)
	    removeApproval(ids_from, ids, from);
	else
	    removeApproval(ids_from, new uint256[](0), from);

	addOwnership(ids_to,to);
	addToInventory(ids_to,to);
	removeOwnership(ids_from,from);
	removeFromInventory(ids_from,from);

	if(ids.length>1){
    	    emit TransferBatch(operator, from, to, ids, amounts);
	    for(uint i=0;i<ids.length;i++)
		emit Transfer(from, to, ids[i]);
	}
	else{
	    emit TransferSingle(operator, from, to, ids[0], amounts[0]);
	    emit Transfer(from, to, ids[0]);
	}

	if(!safe_mode)return;
	if(!ERC721_mode)
	    _doERC1155TransferAcceptanceCheck(operator, from, to, ids, amounts, data);
	else
	    _doERC721TransferAcceptanceCheck(from, to, ids[0], data);
    }

    function isApproved(uint256[] memory ids, address owner) internal view returns (bool) {
	for(uint i=0;i<ids.length;i++){
	    if(approved[ids[i]][owner] != _msgSender())
		return false;
	}
	return true;
    }

    function removeApproval(uint256[] memory ids_from, uint256[] memory ids, address owner) internal {
	for(uint i=0;i<ids_from.length;i++){
	    emit Approval(owner, address(0), ids_from[i]);
	    if(approved[ids_from[i]][owner] != address(0)){
		delete approved[ids_from[i]][owner];
	    }
	    if(singleApproved[ids_from[i]] != address(0)){
		delete singleApproved[ids_from[i]];
	    }
	}
	for(uint i=0;i<ids.length;i++){
	    emit Approval(owner, address(0), ids[i]);
	    if(singleApproved[ids[i]] != address(0)){
		delete singleApproved[ids[i]];
	    }
	}
    }

    function idsToChange(uint256[] memory ids, address owner) internal view returns (uint256[] memory){
	uint256[] memory ids_tmp = new uint256[](ids.length);
	uint256 index=0;
	for(uint i=0;i<ids.length;i++){
	    if(balanceOf(owner,ids[i])==0)
		ids_tmp[index++]=ids[i];
	}
	uint256[] memory filtered_ids = new uint256[](index);
	for(uint i=0;i<index;i++)
	    filtered_ids[i] = ids_tmp[i];
	return filtered_ids;
    }

    function addTokens(uint256[] memory ids) internal {
	for(uint i=0;i<ids.length;i++){
	    if(!exists(ids[i])){
		tokenIndex[ids[i]] = tokens.length;
		tokens.push(ids[i]);
	    }
	}
    }

    function removeTokens(uint256[] memory ids) internal {
	for(uint i=0;i<ids.length;i++){
	    if(!exists(ids[i])){
		uint256 token_index = tokenIndex[ids[i]];
		tokens[token_index] = tokens[tokens.length-1];
		tokenIndex[tokens[token_index]] = token_index;
		tokens.pop();
		delete tokenIndex[ids[i]];
	    }
	}
    }

    function addOwnership(uint256[] memory ids, address owner) internal {
	for(uint i=0;i<ids.length;i++){
	    ownershipIndex[owner][ids[i]] = ownership[ids[i]].length;
	    ownership[ids[i]].push(owner);
	}
    }

    function removeOwnership(uint256[] memory ids, address owner) internal {
	for(uint i=0;i<ids.length;i++){
	    uint256 owner_index = ownershipIndex[owner][ids[i]];
	    ownership[ids[i]][owner_index] = ownership[ids[i]][ownership[ids[i]].length-1];
	    ownershipIndex[ownership[ids[i]][owner_index]][ids[i]] = owner_index;
	    ownership[ids[i]].pop();
	    delete ownershipIndex[owner][ids[i]];
	}
    }
    
    function addToInventory(uint256[] memory ids, address owner) internal {
	for(uint i=0;i<ids.length;i++){
	    slot[owner][ids[i]] = inventory[owner].length;
	    inventory[owner].push(ids[i]);
	}
    }

    function removeFromInventory(uint256[] memory ids, address owner) internal {
	for(uint i=0;i<ids.length;i++){
	    uint256 token_index = slot[owner][ids[i]];
	    inventory[owner][token_index] = inventory[owner][inventory[owner].length-1];
	    slot[owner][inventory[owner][token_index]] = token_index;
	    delete slot[owner][ids[i]];
	    inventory[owner].pop();
	}
    }

    function _doERC1155TransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
	    if(ids.length == 1){
		try IERC1155Receiver(to).onERC1155Received(operator, from, ids[0], amounts[0], data) returns (bytes4 response) {
            	    if (response != IERC1155Receiver.onERC1155Received.selector) {
                	revert("ERC1155: ERC1155Receiver rejected tokens");
            	    }
        	} catch Error(string memory reason) {
            	    revert(reason);
        	} catch {
            	    revert("ERC1155: transfer to non ERC1155Receiver implementer");
        	}
	    }else{
        	try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
            	    bytes4 response
        	) {
            	    if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                	revert("ERC1155: ERC1155Receiver rejected tokens");
            	    }
        	} catch Error(string memory reason) {
            	    revert(reason);
        	} catch {
            	    revert("ERC1155: transfer to non ERC1155Receiver implementer");
        	}
	    }
        }
    }

    function _doERC721TransferAcceptanceCheck(
	address from,
	address to,
	uint256 tokenId,
	bytes memory _data
    ) private {
	if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
		if(retval != IERC721Receiver.onERC721Received.selector)
		    revert("ERC721: transfer to non ERC721Receiver implementer");
//                require(retval == IERC721Receiver.onERC721Received.selector);
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * See IERC721
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
    ) external canBeTransferedAsERC721(from, to, tokenId){
	_transferFrom(from, to, tokenId, "", true, true);
    }

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
    ) external canBeTransferedAsERC721(from, to, tokenId){
	_transferFrom(from, to, tokenId, data, true, true);
    }

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * See IERC721
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
    ) external canBeTransferedAsERC721(from, to, tokenId){
	_transferFrom(from, to, tokenId, "", false, true);
    }

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
    ) public virtual override(ERC1155, IERC1155) {
	_transferFrom(from, to, _asSingletonArray(id), _asSingletonArray(amount), data, true, false);
    }

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
    ) public virtual override(ERC1155, IERC1155) {
	_transferFrom(from, to, ids, amounts, data, true, false);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
	uint256[] memory ids = _asSingletonArray(id);
	uint256[] memory amounts = _asSingletonArray(amount);
	mintBatch(to, ids, amounts, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
	require(to != address(0), "FireZardNFT: mint to the zero address");
	uint256[] memory ids_to = idsToChange(ids,to);
	addTokens(ids_to);

	if(ids.length == 1){
	    super.mint(to, ids[0], amounts[0], data);
	    emit Transfer(address(0), to, ids[0]);
	}
	else{
    	    super.mintBatch(to, ids, amounts, data);
	    for(uint i=0;i<ids.length;i++)
		emit Transfer(address(0), to, ids[i]);
	}

	for(uint i=0;i<ids.length;i++){
	    if(ownership[ids[i]].length > 1)
		delete singleApproved[ids[i]];
	}

	addOwnership(ids_to,to);
	addToInventory(ids_to,to);
    }
    
    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public virtual override {
	uint256[] memory ids = _asSingletonArray(id);
	uint256[] memory amounts = _asSingletonArray(amount);
	burnBatch(from, ids, amounts);
    }
    
    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public virtual override {
    	require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()) || isApproved(ids, from),
            "ERC1155: caller is not owner nor approved"
        );

	if(ids.length == 1){
	    super._burn(from, ids[0], amounts[0]);
	    emit Transfer(from, address(0), ids[0]);
	}
	else{
	    super._burnBatch(from, ids, amounts);
	    for(uint i=0;i<ids.length;i++)
		emit Transfer(from, address(0), ids[i]);
	}

	uint256[] memory ids_from = idsToChange(ids,from);
	removeApproval(ids_from, ids, from);

	removeOwnership(ids_from,from);
	removeFromInventory(ids_from,from);
	removeTokens(ids_from);
    }

    function typeOf(uint256 id) public view returns (bytes32) {
	return token_type[id];
    }

    function ownersOf(uint256 id) public view returns (address[] memory) {
	return ownership[id];
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     * See IERC721
     */
    function balanceOf(address owner) external view returns (uint256 balance){
	require(owner != address(0), "ERC721: balance query for the zero address");
	return inventory[owner].length;
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     * See IERC721
     *
     * Requirements:
     *
     * - `tokenId` must exist and belong to a single owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner){
	require(ownership[tokenId].length >= 1, 'ERC721: owner query for nonexistent token');
	require(ownership[tokenId].length == 1, 'FireZardNFT: this query may serve only single token owner');
	
	return ownership[tokenId][0];
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * See IERC721
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external {
	require(to != _msgSender(),"ERC721: approval to current owner");
	require(totalSupply(tokenId)>0,"ERC721: operator query for nonexistent token");
	bool _approved = false;
	if(balanceOf(_msgSender(), tokenId)>0){
	    approved[tokenId][_msgSender()] = to;
	    if(ownership[tokenId].length == 1)
		singleApproved[tokenId] = to;
	    _approved = true;
	    emit Approval(_msgSender(), to, tokenId);
	}
	for(uint i=0;i<ownership[tokenId].length;i++){
	    address owner = ownership[tokenId][i];
	    if((approved[tokenId][owner] == _msgSender())||(isApprovedForAll(owner,_msgSender()))){
		approved[tokenId][owner] = to;
		if(ownership[tokenId].length == 1)
		    singleApproved[tokenId] = to;
		_approved = true;
		emit Approval(owner, to, tokenId);
	    }
	}
	require(_approved, 'ERC721: approve caller is not owner nor approved');
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     * If there are more accounts holding token with same id
     * the function fails.
     *
     * See IERC721
     *
     * Requirements:
     *
     * - `tokenId` must exist and belong to a single account
     */
    function getApproved(uint256 tokenId) external view returns (address operator){
	require(totalSupply(tokenId)>0,"ERC721: approved query for nonexistent token");
	require(ownership[tokenId].length == 1, "FireZardNFT: this query may serve only single token owner");
	return singleApproved[tokenId];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     *
     * See ERC1155Supply
     */
    function exists(uint256 id) public view virtual override returns (bool) {
        return (super.totalSupply(id) > 0);
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view override returns (uint256) {
	return tokens.length;
    }

     /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     *
     * See IERC721Enumerable
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId){
	require(inventory[owner].length>index,"FireZardNFT: owner index out of bounds");
	return inventory[owner][index];
    }

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     *
     * See IERC721Enumerable
     */
    function tokenByIndex(uint256 index) external view returns (uint256){
	require(tokens.length>index,"ERC721Enumerable: global index out of bounds");
	return tokens[index];
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * 
     * See IERC721Enumerable
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
	require(totalSupply(tokenId)>0, "FireZardNFT: URI query for non-existent token");
	return uri(tokenId);
    }

    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) public view virtual override(ERC1155, IERC1155MetadataURI) returns (string memory){
	string memory token_uri = uris[id];
	if(bytes(token_uri).length != 0)
	    return token_uri;
	else
	    return super.uri(id);
    }

    function setURI(string memory token_uri, uint256 token_id) public virtual {
	require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must be admin");
	uris[token_id] = token_uri;
	emit URI(token_uri, token_id);
    }

    function setURI(string memory token_uri) public virtual {
	require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must be admin");
	_setURI(token_uri);
	emit URI(token_uri, 0);
    }

    function baseURI() public virtual view returns (string memory) {
	return _getBaseURI();
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
    ) internal virtual override {
	super._setApprovalForAll(owner, operator, approved);
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override(ERC1155, IERC1155, IERC721) returns (bool) {
        return ERC1155.isApprovedForAll(account, operator);
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override(ERC1155, IERC1155, IERC721) {
        return super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() external view override returns (string memory){
	return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory){
	return _symbol;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC1155PresetMinterPauser, IERC165)
        returns (bool)
    {
        return 
	    interfaceId == type(IERC721).interfaceId ||
	    interfaceId == type(IERC721Enumerable).interfaceId ||
	    interfaceId == type(IERC721Metadata).interfaceId ||
	    super.supportsInterface(interfaceId);
    }


}

/**
 * Derives dragon card stats from card ID
 * @title  Deriving dragon card stats from its ID
 * @author CryptoHog
 * @notice Defines an interface for a contract deriving the stats from a randomly generated ID
 */

pragma solidity ^0.8.0;

import "./Util.sol";
import "./IStatsDerive.sol";
import "./StatsDistrib.sol";

contract DragonStats is IStatsDerive {
    bytes32 public constant VERSION = keccak256(abi.encodePacked('DragonStats-v1'));
    string public constant RARITY_STR = 'rarity';
    string public constant RARITY_OVERRIDE_STR = 'rarity_override';
    string public constant HEALTH_STR = 'health';
    string public constant TYPE_STR   = 'type';
    string public constant ATTACK_STR = 'attack';
    string public constant DEFENSE_STR= 'defense';
    string public constant CHARACTER_STR= 'character';
    string public constant CHARACTER_NAME_STR= 'character_name';
    bytes32 public constant H_RARITY_STR = keccak256(abi.encodePacked(RARITY_STR));
    bytes32 public constant H_RARITY_OVERRIDE_STR = keccak256(abi.encodePacked(RARITY_OVERRIDE_STR));
    bytes32 public constant H_HEALTH_STR = keccak256(abi.encodePacked(HEALTH_STR));
    bytes32 public constant H_TYPE_STR = keccak256(abi.encodePacked(TYPE_STR));
    bytes32 public constant H_ATTACK_STR = keccak256(abi.encodePacked(ATTACK_STR));
    bytes32 public constant H_DEFENSE_STR = keccak256(abi.encodePacked(DEFENSE_STR));
    bytes32 public constant H_CHARACTER_STR = keccak256(abi.encodePacked(CHARACTER_STR));
    bytes32 public constant H_CHARACTER_NAME_STR = keccak256(abi.encodePacked(CHARACTER_NAME_STR));

    string public constant CHARACTER_FIREZARD_STR = 'FireZard';
    string public constant CHARACTER_FLAROZARD_STR = 'FlaroZard';
    string public constant CHARACTER_EMBERZARD_STR = 'EmberZard';
    string public constant CHARACTER_FLAMEBRYO_STR = 'Flamebryo';
    string public constant CHARACTER_BLIZARD_STR = 'BliZard';
    string public constant CHARACTER_FROZARD_STR = 'FroZard';
    string public constant CHARACTER_CHILLAZARD_STR = 'ChillaZard';
    string public constant CHARACTER_COOLBRYO_STR = 'Coolbryo';
    string public constant CHARACTER_FLORAZARD_STR = 'FloraZard';
    string public constant CHARACTER_BLOSZARD_STR = 'BlosZard';
    string public constant CHARACTER_SPROUTYZARD_STR = 'SproutyZard';
    string public constant CHARACTER_SEEDBRYO_STR = 'Seedbryo';
    string public constant CHARACTER_LECTRAZARD_STR = 'LectraZard';
    string public constant CHARACTER_VOLZARD_STR = 'VolZard';
    string public constant CHARACTER_SPARKYZARD_STR = 'SparkyZard';
    string public constant CHARACTER_ZAPBRYO_STR = 'Zapbryo';
    string public constant CHARACTER_HYDRAZARD_STR = 'HydraZard';
    string public constant CHARACTER_AQAZARD_STR = 'AqaZard';
    string public constant CHARACTER_DRIPLAZARD_STR = 'DriplaZard';
    string public constant CHARACTER_SPLASH_STR = 'Splashbryo';

    string[] public CHARACTER_NAMES = [
	CHARACTER_FIREZARD_STR,   // 000
	CHARACTER_FIREZARD_STR,   // 001
	CHARACTER_FLAROZARD_STR,  // 002
	CHARACTER_FLAROZARD_STR,  // 003
	CHARACTER_FLAROZARD_STR,  // 004
	CHARACTER_EMBERZARD_STR,  // 005
	CHARACTER_EMBERZARD_STR,  // 006
	CHARACTER_EMBERZARD_STR,  // 007
	CHARACTER_FLAMEBRYO_STR,  // 008
	CHARACTER_FLAMEBRYO_STR,  // 009
	CHARACTER_FLAMEBRYO_STR,  // 010
	CHARACTER_FLAMEBRYO_STR,  // 011
	CHARACTER_FLAMEBRYO_STR,  // 012
	CHARACTER_BLIZARD_STR,    // 013
	CHARACTER_BLIZARD_STR,    // 014
	CHARACTER_FROZARD_STR,    // 015
	CHARACTER_FROZARD_STR,    // 016
	CHARACTER_FROZARD_STR,    // 017
	CHARACTER_CHILLAZARD_STR, // 018
	CHARACTER_CHILLAZARD_STR, // 019
	CHARACTER_CHILLAZARD_STR, // 020
	CHARACTER_COOLBRYO_STR,   // 021
	CHARACTER_COOLBRYO_STR,   // 022
	CHARACTER_COOLBRYO_STR,   // 023
	CHARACTER_COOLBRYO_STR,   // 024
	CHARACTER_COOLBRYO_STR,   // 025
	CHARACTER_FLORAZARD_STR,  // 026
	CHARACTER_FLORAZARD_STR,  // 027
	CHARACTER_BLOSZARD_STR,   // 028
	CHARACTER_BLOSZARD_STR,   // 029
	CHARACTER_BLOSZARD_STR,   // 030
	CHARACTER_SPROUTYZARD_STR,// 031
	CHARACTER_SPROUTYZARD_STR,// 032
	CHARACTER_SPROUTYZARD_STR,// 033
	CHARACTER_SEEDBRYO_STR,   // 034
	CHARACTER_SEEDBRYO_STR,   // 035
	CHARACTER_SEEDBRYO_STR,   // 036
	CHARACTER_SEEDBRYO_STR,   // 037
	CHARACTER_SEEDBRYO_STR,   // 038
	CHARACTER_LECTRAZARD_STR, // 039
	CHARACTER_LECTRAZARD_STR, // 040
	CHARACTER_VOLZARD_STR,    // 041
	CHARACTER_VOLZARD_STR,    // 042
	CHARACTER_VOLZARD_STR,    // 043
	CHARACTER_SPARKYZARD_STR, // 044
	CHARACTER_SPARKYZARD_STR, // 045
	CHARACTER_SPARKYZARD_STR, // 046
	CHARACTER_ZAPBRYO_STR,    // 047
	CHARACTER_ZAPBRYO_STR,    // 048
	CHARACTER_ZAPBRYO_STR,    // 049
	CHARACTER_ZAPBRYO_STR,    // 050
	CHARACTER_ZAPBRYO_STR,    // 051
	CHARACTER_HYDRAZARD_STR,  // 052
	CHARACTER_HYDRAZARD_STR,  // 053
	CHARACTER_AQAZARD_STR,    // 054
	CHARACTER_AQAZARD_STR,    // 055
	CHARACTER_AQAZARD_STR,    // 056
	CHARACTER_DRIPLAZARD_STR, // 057
	CHARACTER_DRIPLAZARD_STR, // 058
	CHARACTER_DRIPLAZARD_STR, // 059
	CHARACTER_SPLASH_STR,	  // 060
	CHARACTER_SPLASH_STR,	  // 061
	CHARACTER_SPLASH_STR,	  // 062
	CHARACTER_SPLASH_STR,	  // 063
	CHARACTER_SPLASH_STR	  // 064
    ];

    uint256[] private  RARE_CHARACTER_DISTRIB = [1,1];
    uint256   private constant RARE_CHARACTER_DISTRIB_SIZE = 3;
    uint256[] private  UNCOMMON_CHARACTER_DISTRIB = [1,1];
    uint256   private constant UNCOMMON_CHARACTER_DISTRIB_SIZE = 3;
    uint256[] private  COMMON_CHARACTER_DISTRIB = [1,1,1,1];
    uint256   private constant COMMON_CHARACTER_DISTRIB_SIZE = 5;

    address public	statsDistrib;

    constructor(address _statsDistrib){
	linkStatsDistrib(_statsDistrib);
    }

    function linkStatsDistrib(address _statsDistrib) public {
	statsDistrib = _statsDistrib;
	emit StatsDistribLink(statsDistrib);
    }

    function deriveRarity(uint256 id) internal view returns (Util.CardRarity) {
	uint256 rvalue = uint256(keccak256(abi.encode(id,RARITY_STR)));
	return Util.CardRarity(Util.getRandomItem(rvalue, StatsDistrib(statsDistrib).getDragonCardRarities(), StatsDistrib(statsDistrib).dragonCardRarityPopulationSize()));
    }

    function deriveType(uint256 id) internal view returns (Util.CardType) {
	uint256 rvalue = uint256(keccak256(abi.encode(id,TYPE_STR)));
	return Util.CardType(Util.getRandomItem(rvalue, StatsDistrib(statsDistrib).getDragonCardTypes(), StatsDistrib(statsDistrib).dragonCardTypePopulationSize()));
    }

    function deriveCharacter(uint256 id, Util.CardRarity rarity, Util.CardType c_type) public view returns (uint256) {
	uint8 offset;
	if(c_type == Util.CardType.Fire)     offset = 0;
	if(c_type == Util.CardType.Ice)      offset = 13;
	if(c_type == Util.CardType.Plant)    offset = 26;
	if(c_type == Util.CardType.Electric) offset = 39;
	if(c_type == Util.CardType.Water)    offset = 52;

	if(rarity == Util.CardRarity.Ultra_Rare)
	    return offset;
	if(rarity == Util.CardRarity.Super_Rare)
	    return offset+1;

	uint256 rvalue = uint256(keccak256(abi.encode(id,CHARACTER_STR)));

	if(rarity == Util.CardRarity.Rare)
	    return offset+2+Util.getRandomItem(rvalue, RARE_CHARACTER_DISTRIB, RARE_CHARACTER_DISTRIB_SIZE);

	if(rarity == Util.CardRarity.Uncommon)
	    return offset+5+Util.getRandomItem(rvalue, UNCOMMON_CHARACTER_DISTRIB, UNCOMMON_CHARACTER_DISTRIB_SIZE);

	if(rarity == Util.CardRarity.Common)
	    return offset+8+Util.getRandomItem(rvalue, COMMON_CHARACTER_DISTRIB, COMMON_CHARACTER_DISTRIB_SIZE);

	revert("DragonStats: Failed to derive the character");
    }

    function deriveCharacterName(uint256 character) public view returns (string memory) {
	return CHARACTER_NAMES[character];
    }

    /**
     * @notice Derive an integer stat from the card's ID by the stats' name
     *
     * @param id An id generated by an RNG
     * @param name The stats' name
     * @return The stats' value
    **/
    function getStatInt(bytes32 nft_type, uint256 id, string calldata name) external view returns (uint256){
	require(nft_type == Util.DRAGON_CARD_TYPE_CODE, "NFT must be of Dragon Card type");
	bytes32 h_name = keccak256(abi.encodePacked(name));
	if(h_name == H_RARITY_STR)
	    return uint256(deriveRarity(id));
	if(h_name == H_TYPE_STR)
	    return uint256(deriveType(id));
	if(h_name == H_CHARACTER_STR){
	    revert("DragonStats: call deriveCharacter explicitly");
/*	    Util.CardRarity rarity = deriveRarity(id);
	    Util.CardType   type   = deriveType(id);
	    uint256 character = deriveCharacter(id,rarity,type);
	    require(character <= 64, "DragonStats: chartacter number out of bounds (64)");
	    return character;*/
	}
	if((h_name == H_HEALTH_STR)||(h_name == H_ATTACK_STR)||(h_name == H_DEFENSE_STR))
	    return Util.MAX_UINT;
	revert("Unsupported stat");
    }

    /**
     * @notice Derive a string stat from the card's ID by the stats' name
     *
     * @param id An id generated by an RNG
     * @param name The stats' name
     * @return The stats' value
    **/
    function getStatString(bytes32 nft_type, uint256 id, string calldata name) external view returns (string calldata){
	require(nft_type == Util.DRAGON_CARD_TYPE_CODE, "NFT must be of Dragon Card type");
	bytes32 h_name = keccak256(abi.encodePacked(name));
	if(h_name == H_CHARACTER_NAME_STR){
	    revert("DragonStats: call deriveCharacterName explicitly");
	}
	
	revert("Unsupported stat");
    }

    /**
     * @notice Derive a 32 byte array stat from the card's ID by the stats' name
     *
     * @param id An id generated by an RNG
     * @param name The stats' name
     * @return The stats' value
    **/
    function getStatByte32(bytes32 nft_type, uint256 id, string calldata name) external view returns (bytes32){
	require(nft_type == Util.DRAGON_CARD_TYPE_CODE, "NFT must be of Dragon Card type");
	revert("Unsupported stat");
    }

    /**
     * @notice Derive a boolean stat from the card's ID by the stats' name
     *
     * @param id An id generated by an RNG
     * @param name The stats' name
     * @return The stats' value
    **/
    function getStatBool(bytes32 nft_type, uint256 id, string calldata name) external view returns (bool){
	require(nft_type == Util.DRAGON_CARD_TYPE_CODE, "NFT must be of Dragon Card type");
	bytes32 h_name = keccak256(abi.encodePacked(name));
	if(h_name == H_RARITY_OVERRIDE_STR)
	    return false;
	revert("Unsupported stat");
    }

    /**
     * @notice Defines a set of stats that can be derived
     *
     * @return An enumerable set (actually, an array) of stats that can be derived by the interface implementation
    **/
    function stats(bytes32 nft_type) external pure returns (Util.Stat[] memory) {
	require(nft_type == Util.DRAGON_CARD_TYPE_CODE, "NFT must be of Dragon Card type");
	Util.Stat[] memory stats_list = new Util.Stat[](8);
	stats_list[0] = Util.Stat(RARITY_STR, Util.StatType.Integer, false);
	stats_list[1] = Util.Stat(HEALTH_STR, Util.StatType.Integer, true);
	stats_list[2] = Util.Stat(TYPE_STR, Util.StatType.Integer, false);
	stats_list[3] = Util.Stat(ATTACK_STR, Util.StatType.Integer, true);
	stats_list[4] = Util.Stat(DEFENSE_STR, Util.StatType.Integer, true);
	stats_list[5] = Util.Stat(RARITY_OVERRIDE_STR, Util.StatType.Boolean, true);
	stats_list[6] = Util.Stat(CHARACTER_STR, Util.StatType.Integer, false);
	stats_list[7] = Util.Stat(CHARACTER_NAME_STR, Util.StatType.String, false);
	return stats_list;
    }

    event StatsDistribLink(address _statsDistrib);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}