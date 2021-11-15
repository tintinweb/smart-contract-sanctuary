// SPDX-License-Identifier: MIT OR Apache-2.0
pragma abicoder v2;
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/introspection/ERC165Upgradeable.sol";

import "./base/mixins/OZ/ERC1155Upgradeable.sol";
import "./base/mixins/TreasuryNode.sol";
import "./base/mixins/roles/MarketAdminRole.sol";
import "./base/mixins/roles/MarketOperatorRole.sol";
import "./base/mixins/HasSecondarySaleFees.sol";
import "./base/mixins/NFTCore.sol";
import "./base/mixins/NFT1155Market.sol";
import "./base/mixins/NFT1155Mint.sol";
import "./base/mixins/NFT1155Creator.sol";
import "./base/mixins/NFT1155Metadata.sol";
import "./base/mixins/AccountMigration.sol";

contract PocmonCreatureNFTs is
    TreasuryNode,
    MarketAdminRole,
    MarketOperatorRole,
    AccountMigration,
    ERC165Upgradeable,
    HasSecondarySaleFees,
    ERC1155Upgradeable,
    NFTCore,
    NFT1155Creator,
    NFT1155Market,
    NFT1155Metadata,
    NFT1155Mint
{
    using AddressLibrary for address;

    mapping (uint256=>uint256) public classIds;


    function getClassId(uint256 tokenId) public view returns (uint256) {
        return classIds[tokenId];
    }
    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This farms the initialize call out to inherited contracts as needed.
     */
    function initialize(
        address payable treasury,
        string memory name,
        string memory symbol,
        MintRequirementsChoice _mintRequirement
    ) public initializer {
        TreasuryNode._initializeTreasuryNode(treasury);

        ERC1155Upgradeable.__ERC1155_init(name, symbol, "ipfs://");
        HasSecondarySaleFees._initializeHasSecondarySaleFees();
        NFT1155Creator._initializeNFT1155Creator();
        NFT1155Mint._initializeNFT1155Mint(_mintRequirement);
    }

    /**
     * @notice Allows a Market admin to update NFT config variables.
     * @dev This must be called right after the initial call to `initialize`.
     */
    function adminUpdateConfig(address _nftMarket, string memory _baseURI) public onlyMarketAdmin {
        _updateNFTMarket(_nftMarket);
        _setURI(_baseURI);
    }

    function uri(uint256 tokenId) public view virtual override(ERC1155Upgradeable, NFT1155Mint, NFT1155Metadata) returns (string memory) {
        return NFT1155Metadata.uri(tokenId);
    }


    /**
     * @notice Minting with permission check
     */
    function mint(
        address to,
        string memory _tokenIPFSPath,
        uint256 classId,
        uint256 _amount
    ) public returns (uint256 tokenId) {
        if(mintRequirement == MintRequirementsChoice.Limited) {
            require(isWhitelistedCreator(msg.sender) || _isMinterOperator(msg.sender),
                    "NFT1155Mint: Only operator or whitelisted sender could mint");
        } else if(mintRequirement == MintRequirementsChoice.OnlyOperator) {
            require(_isMinterOperator(msg.sender), "NFT1155Mint: Only operator can mint");
        }
        tokenId = _mint(to, _tokenIPFSPath, _amount);
        classIds[tokenId] = classId;
    }
    
    /**
     * @notice Batch Minting with permission check
     */
    function mintBatch(
        address to,
        string[] memory _tokenIPFSPaths,
        uint256[] memory _classIds,
        uint256[] memory _amounts
    ) public returns (uint256[] memory tokenIds) {
        if(mintRequirement == MintRequirementsChoice.Limited) {
            require(isWhitelistedCreator(msg.sender) || _isMinterOperator(msg.sender),
                    "NFT1155Mint: Only operator or whitelisted sender could mint");
        } else if(mintRequirement == MintRequirementsChoice.OnlyOperator) {
            require(_isMinterOperator(msg.sender), "NFT1155Mint: Only operator can mint");
        }
        require(_classIds.length == _amounts.length,
                "classIds size should be equal to amounts size");
        tokenIds = super.mintBatch(to, _tokenIPFSPaths, _amounts);
        for(uint i=0; i < tokenIds.length; i++) {
            classIds[tokenIds[i]] = _classIds[i];
        }
    }

    /*
     * @notice Deny direct minting without classId
     */
    function mint(
        address to,
        string memory _tokenIPFSPath,
        uint256 _amount
    ) public override returns (uint256) {
        revert("Direct minting forbidden");
    }
    
    function mintBatch(
        address to,
        string[] memory _tokenIPFSPaths,
        uint256[] memory _amounts
    ) public override returns (uint256[] memory tokenIds) {
        revert("Direct minting forbidden");
    }

    function mint(
        address to,
        string memory _tokenIPFSPath,
        uint256 _amount,
        uint256 timestamp,
        bytes memory signature
    ) public override returns (uint256 tokenId) {
        revert("Direct minting forbidden");
    }

    function mintOnTransfer(
        string memory _tokenIPFSPath,
        uint256 _amount,
        address creator,
        bytes memory signature
    ) public override returns (uint256 tokenId) {
        revert("Direct minting forbidden");
    }

    function _burnBatch(address _account, uint256[] memory _tokenIds, uint256[] memory _amounts)
        internal
        override(ERC1155Upgradeable, NFT1155Creator, NFT1155Mint)
    {
        super._burnBatch(_account, _tokenIds, _amounts);
    }
    
    /**
     * @dev This is a no-op, just an explicit override to address compile errors due to inheritance.
     */
    function _burn(address _account, uint256 tokenId, uint256 _amount)
        internal
        override(ERC1155Upgradeable, NFT1155Creator, NFT1155Metadata, NFT1155Mint)
    {
        super._burn(_account, tokenId, _amount);
    }


}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
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
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155MetadataURIUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;


    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string internal _uri;

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

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory name_, string memory symbol_, string memory uri_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }


    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
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
    function uri(uint256) external view virtual override returns (string memory) {
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
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

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
        uint256 amount
    )
        public
        virtual
    {
        _safeTransferFrom(from, to, id, amount, "");
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
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        internal
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
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
        uint256[] memory amounts
    )
        public
        virtual
    {
        safeBatchTransferFrom(from, to, ids, amounts, "");
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address[] memory tos,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        public
        virtual
    {

        for (uint256 i = 0; i < ids.length; ++i) {
            address to = tos[i];
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            _safeTransferFrom(from, to, id, amount, "");
        }
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
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
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
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
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
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
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
    { }

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
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable(to).onERC1155Received.selector) {
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
    )
        private
    {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @notice A mixin that stores a reference to the treasury contract.
 */
abstract contract TreasuryNode is Initializable {
  using AddressUpgradeable for address payable;

  address payable private treasury;

  /**
   * @dev Called once after the initial deployment to set the market treasury address.
   */
  function _initializeTreasuryNode(address payable _treasury) internal initializer {
    require(_treasury.isContract(), "TreasuryNode: Address is not a contract");
    treasury = _treasury;
  }

  /**
   * @notice Returns the address of the market treasury.
   */
  function getTreasury() public view returns (address payable) {
    return treasury;
  }

  // `______gap` is added to each mixin to allow adding new data slots or additional mixins in an upgrade-safe way.
  uint256[2000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "../../interfaces/IAdminRole.sol";

import "../TreasuryNode.sol";

/**
 * @notice Allows a contract to leverage the admin role defined by the market treasury.
 */
abstract contract MarketAdminRole is TreasuryNode {
  // This file uses 0 data slots (other than what's included via TreasuryNode)

  modifier onlyMarketAdmin() {
    require(_isMarketAdmin(), "MarketAdminRole: caller does not have the Admin role");
    _;
  }

  function _isMarketAdmin() internal view returns (bool) {
    return IAdminRole(getTreasury()).isAdmin(msg.sender);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "../../interfaces/ITreasury.sol";
import "../TreasuryNode.sol";

/**
 * @notice Allows a contract to leverage the operator role defined by the market treasury.
 */
abstract contract MarketOperatorRole is TreasuryNode {
  // This file uses 0 data slots (other than what's included via TreasuryNode)

  function _isMigraterOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isMigraterOperator(account);
  }

  function _isCancelOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isCancelOperator(account);
  }

  function _isFeeSetterOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isFeeSetterOperator(account);
  }
  
  function _isMinterOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isMinterOperator(account);
  }
  
  function _isSuperOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isSuperOperator(account);
  }

  function _isWhitelistOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isWhitelistOperator(account);
  }
  
  modifier onlyMigraterOperator() {
    require(_isMigraterOperator(msg.sender), "OperatorRole: caller does not have the Migrater role");

    _;
  }

  modifier onlyCancelOperator() {
    require(_isCancelOperator(msg.sender), "OperatorRole: caller does not have the Cancel role");

    _;
  }

  modifier onlyFeeSetterOperator() {
    require(_isFeeSetterOperator(msg.sender), "OperatorRole: caller does not have the FeeSetter role");

    _;
  }

  modifier onlyWhitelistOperator() {
    require(_isWhitelistOperator(msg.sender), "OperatorRole: caller does not have the whitelist manage role");

    _;
  }

  modifier onlyMinterOperator() {
    require(_isMinterOperator(msg.sender), "OperatorRole: caller does not have the Minter role");

    _;
  }

}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @notice An interface for communicating fees to 3rd party marketplaces.
 * @dev Originally implemented in mainnet contract 0x44d6e8933f8271abcf253c72f9ed7e0e4c0323b3
 */
abstract contract HasSecondarySaleFees is Initializable, ERC165Upgradeable {
  /*
   * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
   * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
   *
   * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
   */
  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

  /**
   * @dev Called once after the initial deployment to register the interface with ERC165.
   */
  function _initializeHasSecondarySaleFees() internal initializer {
    _registerInterface(_INTERFACE_ID_FEES);
  }

  function getFeeRecipients(uint256 id) public view virtual returns (address payable[] memory);

  function getFeeBps(uint256 id) public view virtual returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

/**
 * @notice A place for common modifiers and functions used by various NFT721 mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 */
abstract contract NFTCore {
  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/INFTMarket.sol";

import "./TreasuryNode.sol";
import "./HasSecondarySaleFees.sol";
import "./NFT1155Creator.sol";

/**
 * @notice Holds a reference to the Market Market and communicates fees to 3rd party marketplaces.
 */
abstract contract NFT1155Market is TreasuryNode, HasSecondarySaleFees, NFT1155Creator {
  using AddressUpgradeable for address;

  event NFTMarketUpdated(address indexed nftMarket);

  INFTMarket private nftMarket;

  /**
   * @notice Returns the address of the Market NFTMarket contract.
   */
  function getNFTMarket() public view returns (address) {
    return address(nftMarket);
  }

  function _updateNFTMarket(address _nftMarket) internal {
    require(_nftMarket.isContract(), "NFT1155Market: Market address is not a contract");
    nftMarket = INFTMarket(_nftMarket);

    emit NFTMarketUpdated(_nftMarket);
  }

  /**
   * @notice Returns an array of recipient addresses to which fees should be sent.
   * The expected fee amount is communicated with `getFeeBps`.
   */
  function getFeeRecipients(uint256 id) public view override returns (address payable[] memory) {
    require(_exists(id), "ERC721Metadata: Query for nonexistent token");

    address payable[] memory result = new address payable[](2);
    result[0] = getTreasury();
    result[1] = getTokenCreatorPaymentAddress(id);
    return result;
  }

  /**
   * @notice Returns an array of fees in basis points.
   * The expected recipients is communicated with `getFeeRecipients`.
   */
  function getFeeBps(
    uint256 /* id */
  ) public view override returns (uint256[] memory) {
    (, uint256 secondaryFeeBasisPoints, uint256 secondaryCreatorFeeBasisPoints) = nftMarket.getFeeConfig();
    uint256[] memory result = new uint256[](2);
    result[0] = secondaryFeeBasisPoints;
    result[1] = secondaryCreatorFeeBasisPoints;
    return result;
  }

  /**
   * @notice Get fee recipients and fees in a single call.
   * The data is the same as when calling getFeeRecipients and getFeeBps separately.
   */
  function getFees(uint256 tokenId)
    public
    view
    returns (address payable[2] memory recipients, uint256[2] memory feesInBasisPoints)
  {
    require(_exists(tokenId), "ERC721Metadata: Query for nonexistent token");

    recipients[0] = getTreasury();
    recipients[1] = getTokenCreatorPaymentAddress(tokenId);
    (, uint256 secondaryFeeBasisPoints, uint256 secondaryCreatorFeeBasisPoints) = nftMarket.getFeeConfig();
    feesInBasisPoints[0] = secondaryFeeBasisPoints;
    feesInBasisPoints[1] = secondaryCreatorFeeBasisPoints;
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma abicoder v2;
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./OZ/ERC1155Upgradeable.sol";
import "./NFT1155Creator.sol";
import "./NFT1155Market.sol";
import "./NFT1155Metadata.sol";
import "../libraries/AddressLibrary.sol";
import "./AccountMigration.sol";

/**
 * @notice Allows creators to mint NFTs.
 */
abstract contract NFT1155Mint is Initializable, AccountMigration, ERC1155Upgradeable, NFT1155Creator, NFT1155Market, NFT1155Metadata {
    using AddressLibrary for address;

    // Mapping from token ID to account balances
    mapping (uint256 => uint256) private _tokenIdAmount;
    uint256 private nextTokenId;

    enum MintRequirementsChoice {
        Everybody,
        Limited,
        OnlyOperator,
        Nobody
    }

    MintRequirementsChoice public mintRequirement;

    event Minted(
        address indexed creator,
        uint256 indexed tokenId,
        string indexed indexedTokenIPFSPath,
        string tokenIPFSPath,
        uint256 amount
    );
    
    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return nextTokenId;
    }

    /**
    * @notice Gets the tokenId of the next NFT minted.
     */
    function getNextTokenId() public view returns (uint256) {
        return nextTokenId;
    }

    function uri(uint256 tokenId) public view virtual override(ERC1155Upgradeable, NFT1155Metadata) returns (string memory) {
        return NFT1155Metadata.uri(tokenId);
    }

    /**
     * @dev Called once after the initial deployment to set the initial tokenId.
     */
    function _initializeNFT1155Mint(MintRequirementsChoice _mintRequirement) internal initializer {
        // Use ID 1 for the first NFT tokenId
        nextTokenId = 1;
        mintRequirement = _mintRequirement;
    }

    function setMintRequirements(MintRequirementsChoice _mintRequirement) public onlyWhitelistOperator {
        require(_mintRequirement >= MintRequirementsChoice.Everybody && _mintRequirement <= MintRequirementsChoice.Nobody,
                "NFT1155Mint: Incorrect mint requirements");
        mintRequirement = _mintRequirement;
    }

    /**
     * @notice Allows a creator to mint an NFT.
     */
    function mint(
        address _account,
        string memory _tokenIPFSPath,
        uint256 _amount,
        uint256 timestamp,
        bytes memory signature
    ) public virtual returns (uint256 tokenId) {
        require(mintRequirement == MintRequirementsChoice.Limited || mintRequirement == MintRequirementsChoice.OnlyOperator,
                "NFT1155Mint: Signed minting only in limited or only operator mode");
        require(timestamp >= block.timestamp,
                "NFT1155Mint: timestamp should be in future");

        bytes memory data = abi.encodePacked(
            "I authorized ",
            super._toAsciiString(msg.sender),
            " to mint ", 
            _tokenIPFSPath,
            " on ",
            super._toAsciiString(address(this)),
            " but not after ",
            Strings.toString(timestamp)
        );
        bytes32 hash = super._toEthSignedMessage(data);
        address signer = ECDSA.recover(hash, signature);
        require(_isMinterOperator(signer),
                "NFT1155Mint: Signature must be from an operator");
        tokenId = _mint(_account, _tokenIPFSPath, _amount);
    }

    /**
    * @dev mint single token with specified amount
    **/
    function mint(
        address to,
        string memory _tokenIPFSPath,
        uint256 _amount
    ) virtual public 
    returns (uint256 tokenId) {
        if(mintRequirement == MintRequirementsChoice.Limited) {
            require(isWhitelistedCreator(msg.sender) || _isMinterOperator(msg.sender),
                    "NFT1155Mint: Only operator or whitelisted sender could mint");
        } else if(mintRequirement == MintRequirementsChoice.OnlyOperator) {
            require(_isMinterOperator(msg.sender), "NFT1155Mint: Only operator can mint");
        }
        tokenId = _mint(to, _tokenIPFSPath, _amount);
    }


    /**
    *
    * @notice Allows a buyer to mint on transfer an NFT.
     */
    function mintOnTransfer(
        string memory _tokenIPFSPath,
        uint256 _amount,
        address creator,
        bytes memory signature
    ) public virtual returns (uint256 tokenId) {
        require(mintRequirement == MintRequirementsChoice.Everybody,
                "NFT1155Mint: Signed minting only for everybody mode");

        bytes memory data = abi.encodePacked(
            "Creator ",
            super._toAsciiString(creator),
            " authorized the market to mint ",
            _tokenIPFSPath,
            " on transfer"
        );
        bytes32 hash = super._toEthSignedMessage(data);
        address signer = ECDSA.recover(hash, signature);
        require(signer == creator, "NFT1155Mint: Signer is not creator");
        tokenId = _mint(msg.sender, creator, _tokenIPFSPath, _amount);
    }

    function _mint(
        address to,
        string memory _tokenIPFSPath,
        uint256 _amount
    ) internal 
    returns (uint256 tokenId) {
        require(mintRequirement != MintRequirementsChoice.Nobody, "NFT1155Mint: Minting is not permitted");
        tokenId = _mint(to, to, _tokenIPFSPath, _amount);
    }

    function _mint(
        address to,
        address creator,
        string memory _tokenIPFSPath,
        uint256 _amount
    ) internal 
    returns (uint256 tokenId) {
        require(mintRequirement != MintRequirementsChoice.Nobody, "NFT1155Mint: Minting is not permitted");
        tokenId = nextTokenId++;

        _mint(to, tokenId, _amount, "");
        emit Minted(creator, tokenId, _tokenIPFSPath, _tokenIPFSPath, _amount);
        _updateTokenCreator(tokenId, payable(creator));
        _setTokenIPFSPath(tokenId, _tokenIPFSPath);
        _tokenIdAmount[tokenId] = _amount;
    }

    function mintBatch(
        address to,
        string[] memory tokenIPFSPaths,
        uint256[] memory _amounts
    ) virtual public returns (uint256[] memory tokenIds) {
        if(mintRequirement == MintRequirementsChoice.Limited) {
            require(isWhitelistedCreator(msg.sender) || _isMinterOperator(msg.sender),
                    "NFT1155Mint: Only operator or whitelisted sender could mint");
        } else if(mintRequirement == MintRequirementsChoice.OnlyOperator) {
            require(_isMinterOperator(msg.sender), "NFT1155Mint: Only operator can mint");
        }
        require(mintRequirement != MintRequirementsChoice.Nobody, "NFT1155Mint: Minting is not permitted");
        require(tokenIPFSPaths.length == _amounts.length, "ipfs path length should be equal to amounts");

        tokenIds = new uint256[](tokenIPFSPaths.length);

        for(uint i=0; i < tokenIPFSPaths.length; i++) {
            tokenIds[i] = nextTokenId++;
        }

        _mintBatch(to, tokenIds, _amounts, "");

        for(uint i=0; i < tokenIds.length; i++) {
            _updateTokenCreator(tokenIds[i], payable(to));
            _setTokenIPFSPath(tokenIds[i], tokenIPFSPaths[i]);
            _tokenIdAmount[tokenIds[i]] = _amounts[i];
            emit Minted(to, tokenIds[i], tokenIPFSPaths[i], tokenIPFSPaths[i], _amounts[i]);
        }
    }

    /**
     * @notice Allows a creator to mint an NFT and set approval for the Market marketplace.
     * This can be used by creators the first time they mint an NFT to save having to issue a separate
     * approval transaction before starting an auction.
     */
    function mintAndApproveMarket(string memory tokenIPFSPath, uint256 _amount) public returns (uint256 tokenId) {
      tokenId = mint(msg.sender, tokenIPFSPath, _amount);
      setApprovalForAll(getNFTMarket(), true);
    }

    /**
     * @notice Allows a creator to mint an NFT and have creator revenue/royalties sent to an alternate address.
     */
    function mintWithCreatorPaymentAddress(string memory tokenIPFSPath, uint256 _amount, address payable tokenCreatorPaymentAddress)
      public
      returns (uint256 tokenId)
    {
      require(tokenCreatorPaymentAddress != address(0), "NFT1155Mint: tokenCreatorPaymentAddress is required");
      tokenId = mint(msg.sender, tokenIPFSPath, _amount);
      _setTokenCreatorPaymentAddress(tokenId, tokenCreatorPaymentAddress);
    }

    /**
     * @notice Allows a creator to mint an NFT and have creator revenue/royalties sent to an alternate address.
     * Also sets approval for the Market marketplace.  This can be used by creators the first time they mint an NFT to
     * save having to issue a separate approval transaction before starting an auction.
     */
    function mintWithCreatorPaymentAddressAndApproveMarket(
      string memory tokenIPFSPath,
      uint256 _amount,
      address payable tokenCreatorPaymentAddress
    ) public returns (uint256 tokenId) {
      tokenId = mintWithCreatorPaymentAddress(tokenIPFSPath, _amount, tokenCreatorPaymentAddress);
      setApprovalForAll(getNFTMarket(), true);
    }

    /**
     * @notice Allows an operator to mint and transfer an NFT.
     */
    function mintAndTransfer(
        address to,
        string memory _tokenIPFSPath,
        uint256 _amount
    ) public returns (uint256 tokenId) {
        require(_isMinterOperator(msg.sender),
                "NFT1155Mint: Only operator able to mint and transfer");
        tokenId = _mint(msg.sender, _tokenIPFSPath, _amount);
        safeTransferFrom(msg.sender, to, tokenId, _amount, "");
    }

    /**
     * @notice Allows an operator to mint and transfer an NFTs.
     */
    function mintAndTransferBatch(address[] memory to, string memory _tokenIPFSPath, uint256[] memory _amounts) public returns (uint256 tokenId) {
        require(_isMinterOperator(msg.sender),
                "NFT1155Mint: Only operator able to mint and transfer");
        require(to.length == _amounts.length,
                "NFT1155Mint: to && _amounts should be the same size");
        uint256 _amount = 0;
        for(uint i; i < to.length; i++) {
            require(_amounts[i] > 0, "NFT1155Mint: unexpected _amounts");
            _amount += _amounts[i];
        }

        tokenId = _mint(msg.sender, _tokenIPFSPath, _amount);
        for(uint i; i < to.length; i++) {
            safeTransferFrom(msg.sender, to[i], tokenId, _amounts[i], "");
        }
    }

    /**
     * @dev Explicit override to address compile errors.
     */
    function _burnBatch(
        address _account,
        uint256[] memory tokenIds,
        uint256[] memory _amounts
    ) internal virtual override(ERC1155Upgradeable, NFT1155Creator) {
        super._burnBatch(_account, tokenIds, _amounts);
    }

    /**
     * @dev Explicit override to address compile errors.
     */
    function _burn(
        address _account,
        uint256 tokenId,
        uint256 _amount
    ) internal virtual override(ERC1155Upgradeable, NFT1155Creator, NFT1155Metadata) {
        super._burn(_account, tokenId, _amount);
    }

    uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "../libraries/AddressLibrary.sol";
import "../libraries/BytesLibrary.sol";

import "./OZ/ERC1155Upgradeable.sol";
import "./AccountMigration.sol";
import "./roles/MarketAdminRole.sol";

/**
 * @notice Allows each token to be associated with a creator.
 */
abstract contract NFT1155Creator is Initializable, AccountMigration, ERC1155Upgradeable {
  using SafeMathUpgradeable for uint256;
  using AddressLibrary for address;
  using BytesLibrary for bytes;

  mapping(address => bool) private creatorsPermittedToMint;

  mapping(uint256 => address payable) private tokenIdToCreator;

  /**
   * @dev Stores an optional alternate address to receive creator revenue and royalty payments.
   */
  mapping(uint256 => address payable) private tokenIdToCreatorPaymentAddress;

  event TokenCreatorUpdated(address indexed fromCreator, address indexed toCreator, uint256 indexed tokenId);
  event TokenCreatorPaymentAddressSet(
    address indexed fromPaymentAddress,
    address indexed toPaymentAddress,
    uint256 indexed tokenId
  );
  event NFTCreatorMigrated(uint256 indexed tokenId, address indexed originalAddress, address indexed newAddress);
  event NFTOwnerMigrated(uint256 indexed tokenId, address indexed originalAddress, address indexed newAddress);
  event PaymentAddressMigrated(
    uint256 indexed tokenId,
    address indexed originalAddress,
    address indexed newAddress,
    address originalPaymentAddress,
    address newPaymentAddress
  );

  /*
   * bytes4(keccak256('tokenCreator(uint256)')) == 0x40c1a064
   */
  bytes4 private constant _INTERFACE_TOKEN_CREATOR = 0x40c1a064;

  /*
   * bytes4(keccak256('getTokenCreatorPaymentAddress(uint256)')) == 0xec5f752e;
   */
  bytes4 private constant _INTERFACE_TOKEN_CREATOR_PAYMENT_ADDRESS = 0xec5f752e;

  /**
   * @dev Called once after the initial deployment to register the interface with ERC165.
   */
  function _initializeNFT1155Creator() internal initializer {
    _registerInterface(_INTERFACE_TOKEN_CREATOR);
  }

  /**
   * @notice Allows ERC165 interfaces which were not included originally to be registered.
   * @dev Currently this is the only new interface, but later other mixins can overload this function to do the same.
   */
  function registerInterfaces() public {
    _registerInterface(_INTERFACE_TOKEN_CREATOR_PAYMENT_ADDRESS);
  }

  /**
   * @notice Returns the creator's address for a given tokenId.
   */
  function tokenCreator(uint256 tokenId) public view returns (address payable) {
    return tokenIdToCreator[tokenId];
  }

  /**
   * @notice Returns the payment address for a given tokenId.
   * @dev If an alternate address was not defined, the creator is returned instead.
   */
  function getTokenCreatorPaymentAddress(uint256 tokenId)
    public
    view
    returns (address payable tokenCreatorPaymentAddress)
  {
    tokenCreatorPaymentAddress = tokenIdToCreatorPaymentAddress[tokenId];
    if (tokenCreatorPaymentAddress == address(0)) {
      tokenCreatorPaymentAddress = tokenIdToCreator[tokenId];
    }
  }

  function _updateTokenCreator(uint256 tokenId, address payable creator) internal {
    emit TokenCreatorUpdated(tokenIdToCreator[tokenId], creator, tokenId);

    tokenIdToCreator[tokenId] = creator;
  }

  /**
   * @dev Allow setting a different address to send payments to for both primary sale revenue
   * and secondary sales royalties.
   */
  function _setTokenCreatorPaymentAddress(uint256 tokenId, address payable tokenCreatorPaymentAddress) internal {
    emit TokenCreatorPaymentAddressSet(tokenIdToCreatorPaymentAddress[tokenId], tokenCreatorPaymentAddress, tokenId);
    tokenIdToCreatorPaymentAddress[tokenId] = tokenCreatorPaymentAddress;
  }

  /**
   * @notice Allows the creator to burn if they currently own the NFT.
   */
  function burn(uint256 tokenId, uint256 _amount) public {
    _burn(msg.sender, tokenId, _amount);
  }

  /**
   * @notice Allows the creator to burn if they currently own the NFT.
   */
  function burnBatch(uint256[] memory tokenIds, uint256[] memory _amounts) public {
    _burnBatch(msg.sender, tokenIds, _amounts);
  }

  /**
   * @notice Allows a split recipient and Market to work together in order to update the payment address
   * to a new account.
   * @param signature Message `I authorize Market to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   */
  function adminAccountMigrationForPaymentAddresses(
    uint256[] calldata paymentAddressTokenIds,
    address paymentAddressFactory,
    bytes memory paymentAddressCallData,
    uint256 addressLocationInCallData,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) public onlyAuthorizedAccountMigration(originalAddress, newAddress, signature) {
    _adminAccountRecoveryForPaymentAddresses(
      paymentAddressTokenIds,
      paymentAddressFactory,
      paymentAddressCallData,
      addressLocationInCallData,
      originalAddress,
      newAddress
    );
  }

  /**
   * @dev Split into a second function to avoid stack too deep errors
   */
  function _adminAccountRecoveryForPaymentAddresses(
    uint256[] calldata paymentAddressTokenIds,
    address paymentAddressFactory,
    bytes memory paymentAddressCallData,
    uint256 addressLocationInCallData,
    address originalAddress,
    address payable newAddress
  ) private {
    // Call the factory and get the originalPaymentAddress
    address payable originalPaymentAddress = paymentAddressFactory.functionCallAndReturnAddress(paymentAddressCallData);

    // Confirm the original address and swap with the new address
    paymentAddressCallData.replaceAtIf(addressLocationInCallData, originalAddress, newAddress);

    // Call the factory and get the newPaymentAddress
    address payable newPaymentAddress = paymentAddressFactory.functionCallAndReturnAddress(paymentAddressCallData);

    // For each token, confirm the expected payment address and then update to the new one
    for (uint256 i = 0; i < paymentAddressTokenIds.length; i++) {
      uint256 tokenId = paymentAddressTokenIds[i];
      require(
        tokenIdToCreatorPaymentAddress[tokenId] == originalPaymentAddress,
        "NFT1155Creator: Payment address is not the expected value"
      );

      _setTokenCreatorPaymentAddress(tokenId, newPaymentAddress);
      emit PaymentAddressMigrated(tokenId, originalAddress, newAddress, originalPaymentAddress, newPaymentAddress);
    }
  }

  /**
   * @dev check if sender is whitelisted creator
   */
  function isWhitelistedCreator(address _creator) public view returns (bool) {
      return _isMinterOperator(_creator) || creatorsPermittedToMint[_creator];
  }

  /**
   * @dev permit address to mint nft
   */
  function grantMint(address _creator) public onlyWhitelistOperator {
      creatorsPermittedToMint[_creator] = true;
  }

  /**
   * @dev revoke address to mint nft
   */
  function revokeMint(address _creator) public onlyWhitelistOperator {
      creatorsPermittedToMint[_creator] = false;
  }

  /**
   * @dev Remove the creator record when burned.
   */
  function _burn(address account, uint256 tokenId, uint256 _amount) internal virtual override {
    delete tokenIdToCreator[tokenId];

    super._burn(account, tokenId, _amount);
  }

  /**
   * @dev Explicit override to address compile errors.
   */
  function _burnBatch(
    address _account,
    uint256[] memory _tokenIds,
    uint256[] memory _amounts
  ) internal virtual override(ERC1155Upgradeable) {
    for (uint i = 0; i < _tokenIds.length; i++) {
        uint256 _actualAmount = balanceOf(_account, _tokenIds[i]);
        if(_actualAmount > 0 && _actualAmount.sub(_amounts[i], "ERC1155: overflow") == 0) {
            delete tokenIdToCreator[_tokenIds[i]];
        }
    }

    super._burnBatch(_account, _tokenIds, _amounts);
  }

  /**
   * @dev fallback for checking (TODO: remove)
   **/
  function _exists(uint256) pure internal returns(bool) {
      return true;
  }


  uint256[999] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./NFTCore.sol";
import "./NFT1155Creator.sol";

/**
 * @notice A mixin to extend the OpenZeppelin metadata implementation.
 */
abstract contract NFT1155Metadata is NFT1155Creator {
    using StringsUpgradeable for uint256;

    /**
     * @dev Stores hashes minted by a creator to prevent duplicates.
     */
    mapping(address => mapping(string => bool)) private creatorToIPFSHashToMinted;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    event URI(string URI);
    /**
     * @notice Checks if the creator has already minted a given NFT.
     */
    function getHasCreatorMintedIPFSHash(address creator, string memory tokenIPFSPath) public view returns (bool) {
        return creatorToIPFSHashToMinted[creator][tokenIPFSPath];
    }

    function baseURI() public view returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(bytes(_tokenURIs[tokenId]).length > 0,
                "ERC1155Metadata: URI query for nonexistent token"); 
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        return string(abi.encodePacked(base, _tokenURI));
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev The IPFS path should be the CID + file.extension, e.g.
     * `QmfPsfGwLhiJrU8t9HpG4wuyjgPo9bk8go4aQqSu9Qg4h7/metadata.json`
     */
    function _setTokenIPFSPath(uint256 tokenId, string memory _tokenIPFSPath) internal {
        // 46 is the minimum length for an IPFS content hash, it may be longer if paths are used
        require(bytes(_tokenIPFSPath).length >= 46, "NFT1155Metadata: Invalid IPFS path");
        require(!creatorToIPFSHashToMinted[msg.sender][_tokenIPFSPath], "NFT1155Metadata: NFT was already minted");

        creatorToIPFSHashToMinted[msg.sender][_tokenIPFSPath] = true;
        _setTokenURI(tokenId, _tokenIPFSPath);
    }

    /**
     * @dev When a token is burned, remove record of it allowing that creator to re-mint the same NFT again in the future.
     */
    function _burn(address account, uint256 tokenId, uint256 amount) internal virtual override {
        super._burn(account, tokenId, amount);
        if (balanceOf(account, tokenId) == 0) {
            delete creatorToIPFSHashToMinted[account][uri(tokenId)];
        }
    }

    uint256[999] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./roles/MarketOperatorRole.sol";
import "../interfaces/IERC1271.sol";

/**
 * @notice Checks for a valid signature authorizing the migration of an account to a new address.
 * @dev This is shared by both the NFT721 and NFTMarket, and the same signature authorizes both.
 */
abstract contract AccountMigration is MarketOperatorRole {
  // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/cryptography
  function _isValidSignatureNow(
    address signer,
    bytes32 hash,
    bytes memory signature
  ) internal view returns (bool) {
    if (Address.isContract(signer)) {
      try IERC1271(signer).isValidSignature(hash, signature) returns (bytes4 magicValue) {
        return magicValue == IERC1271(signer).isValidSignature.selector;
      } catch {
        return false;
      }
    } else {
      return ECDSA.recover(hash, signature) == signer;
    }
  }

  // From https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
  function _toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(42);
    s[0] = "0";
    s[1] = "x";
    for (uint256 i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i + 2] = _char(hi);
      s[2 * i + 3] = _char(lo);
    }
    return string(s);
  }

  function _char(bytes1 b) private pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

  // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/cryptography/ECDSA.sol
  // Modified to accept messages (instead of the message hash)
  function _toEthSignedMessage(bytes memory message) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(message.length), message));
  }

  /**
   * @dev Confirms the msg.sender is a Market operator and that the signature provided is valid.
   * @param signature Message `I authorize Market to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   */
  modifier onlyAuthorizedAccountMigration(
    address originalAddress,
    address newAddress,
    bytes memory signature
  ) {
    require(_isMigraterOperator(msg.sender), "AccountMigration: Caller is not an operator");
    bytes32 hash =
      _toEthSignedMessage(
        abi.encodePacked("I authorize Market to migrate my account to ", _toAsciiString(newAddress))
      );
    require(
      _isValidSignatureNow(originalAddress, hash, signature),
      "AccountMigration: Signature must be from the original account"
    );
    _;
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC1155Upgradeable.sol";

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

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * _Available since v3.1._
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

/**
 * @notice Interface for AdminRole which wraps the default admin role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IAdminRole {
  function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable

pragma solidity ^0.7.0;

import "./IOperatorRole.sol";


interface ITreasury {
  function SUPER_OPERATOR_ROLE() external;
  function ONLY_MINTER_ROLE() external;
  function ONLY_MIGRATER_ROLE() external;
  function ONLY_CANCEL_ROLE() external;
  function ONLY_FEE_SETTER_ROLE() external;
  function ONLY_WHITELIST_ROLE() external;

  function withdrawFunds(address payable to, uint256 amount) external;
  function grantAdmin(address account) external;
  function revokeAdmin(address account) external;
  function isAdmin(address account) external view returns (bool);

  function grantSuperOperator(address account) external;
  function revokeSuperOperator(address account) external;
  function isSuperOperator(address account) external view returns (bool);
  function isMigraterOperator(address account) external view returns (bool);
  function isMinterOperator(address account) external view returns (bool);
  function isCancelOperator(address account) external view returns (bool);
  function isFeeSetterOperator(address account) external view returns (bool);
  function isWhitelistOperator(address account) external view returns (bool);

  function initialize(address admin) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

/**
 * @notice Interface for OperatorRole which wraps a role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IOperatorRole {
  function hasRole(bytes32 role, address account) external view returns (bool);
  function grantRole(bytes32 role, address account) external view returns (bool);
  function revokeRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable
pragma abicoder v2;
pragma solidity ^0.7.0;

interface INFTMarket {
  event ReserveAuctionConfigUpdated(
    uint256 minPercentIncrementInBasisPoints,
    uint256 maxBidIncrementRequirement,
    uint256 duration,
    uint256 extensionDuration,
    uint256 goLiveDate
  );

  event ReserveAuctionCreated(
    address indexed seller,
    address indexed nftContract,
    uint256 indexed tokenId,
    uint256 duration,
    uint256 extensionDuration,
    uint256 reservePrice,
    uint256 auctionId
  );
  event ReserveAuctionUpdated(uint256 indexed auctionId, uint256 reservePrice);
  event ReserveAuctionCanceled(uint256 indexed auctionId);
  event ReserveAuctionBidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 endTime);
  event ReserveAuctionFinalized(
    uint256 indexed auctionId,
    address indexed seller,
    address indexed bidder,
    uint256 marketFee,

    uint256 creatorFee,
    uint256 ownerRev
  );
  event ReserveAuctionCanceledByAdmin(uint256 indexed auctionId, string reason);
  event ReserveAuctionSellerMigrated(
    uint256 indexed auctionId,
    address indexed originalSellerAddress,
    address indexed newSellerAddress
  );
  struct ReserveAuction {
    address nftContract;
    uint256 tokenId;
    address payable seller;
    uint256 duration;
    uint256 extensionDuration;
    uint256 endTime;
    address payable bidder;
    uint256 amount;
  }

  function adminUpdateConfig(
    uint256 minPercentIncrementInBasisPoints,
    uint256 duration,
    uint256 primaryFeeBasisPoints,
    uint256 secondaryFeeBasisPoints,
    uint256 secondaryCreatorFeeBasisPoints
  ) external;

  function getReserveAuction(uint256 auctionId) external view returns (ReserveAuction memory);

  function getReserveAuctionIdFor(address nftContract, uint256 tokenId) external view returns (uint256);

  function getReserveAuctionConfig() external view returns (uint256 minPercentIncrementInBasisPoints, uint256 duration);

  function createReserveAuction(
    address nftContract,
    uint256 tokenId,
    uint256 reservePrice
  ) external;

  function updateReserveAuction(uint256 auctionId, uint256 reservePrice) external;

  function cancelReserveAuction(uint256 auctionId) external;

  function placeBid(uint256 auctionId) external payable;

  function finalizeReserveAuction(uint256 auctionId) external;

  function getMinBidAmount(uint256 auctionId) external view returns (uint256);

  function adminCancelReserveAuction(uint256 auctionId, string memory reason) external;

  function adminAccountMigration(
    uint256[] calldata listedAuctionIds,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) external;

  function getFeeConfig()
    external
    view
    returns (
      uint256 primaryFeeBasisPoints,
      uint256 secondaryFeeBasisPoints,
      uint256 secondaryCreatorFeeBasisPoints
    );
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev Named this way to avoid conflicts with `Address` from OZ.
 */
library AddressLibrary {
  using Address for address;

  function functionCallAndReturnAddress(address paymentAddressFactory, bytes memory paymentAddressCallData)
    internal
    returns (address payable result)
  {
    bytes memory returnData = paymentAddressFactory.functionCall(paymentAddressCallData);

    // Skip the length at the start of the bytes array and return the data, casted to an address
    // solhint-disable-next-line no-inline-assembly
    assembly {
      result := mload(add(returnData, 32))
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

library BytesLibrary {
  function replaceAtIf(
    bytes memory data,
    uint256 startLocation,
    address expectedAddress,
    address newAddress
  ) internal pure {
    bytes memory expectedData = abi.encodePacked(expectedAddress);
    bytes memory newData = abi.encodePacked(newAddress);
    // An address is 20 bytes long
    for (uint256 i = 0; i < 20; i++) {
      uint256 dataLocation = startLocation + i;
      require(data[dataLocation] == expectedData[i], "Bytes: Data provided does not include the expectedAddress");
      data[dataLocation] = newData[i];
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/interfaces/IERC1271.sol
 */
interface IERC1271 {
  /**
   * @dev Should return whether the signature provided is valid for the provided data
   * @param hash      Hash of the data to be signed
   * @param signature Signature byte array associated with _data
   */
  function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

