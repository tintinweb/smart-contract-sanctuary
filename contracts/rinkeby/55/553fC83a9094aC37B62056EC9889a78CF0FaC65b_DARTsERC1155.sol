// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {AddressArrayUtils} from "./lib/AddressArrayUtils.sol";
import {UintArrayUtils} from "./lib/UintArrayUtils.sol";
import "./ERC2981TokenRoyalties.sol";

contract DARTsERC1155 is ERC1155, ERC1155Supply, AccessControl, ERC2981TokenRoyalties {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADD_MEMBER_ROLE = keccak256("ADD_MEMBER_ROLE");

    using Counters for Counters.Counter;
    using Strings for string;
    using AddressArrayUtils for address[];
    using UintArrayUtils for uint32[];
    using DataTypes for DataTypes.Right;

    string internal _uri;
    Counters.Counter private _tokenIds;

    constructor(string memory _URI) ERC1155(_URI) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(ADD_MEMBER_ROLE, msg.sender);
        setURI(_URI);
        uint32[] memory zero;
        Rights[0] = DataTypes.Right(0, 0,
            new address[](0), zero, new address[](0), zero,
            new address[](0), zero, new address[](0), zero,
            '', false, 0, DataTypes.royaltyTable(0, 100, 0, 0, 0),
            DataTypes.RoyaltyVoting(address(0x0), address(0x0), 0, false), ''
        );
    }

    function grantMintRole(address user) external onlyRole(MINTER_ROLE) {
        require(hasRole(ADD_MEMBER_ROLE, user), "NT");
        _grantRole(MINTER_ROLE, user);
    }

    function create(
        address[] memory owners,
        address[] memory creators,
        address[] memory sponsors,
        address[] memory thanks
    )
    external onlyRole(MINTER_ROLE) returns (uint) {
        require(owners[0] == msg.sender, "NC");
        _tokenIds.increment();
        uint newItemId = _tokenIds.current();

        _mint(owners[0], newItemId, 1, "");

        _grantRole(ADD_MEMBER_ROLE, owners[0]);

        Rights[newItemId] = DataTypes.Right(
            newItemId, 0,
            owners, UintArrayUtils.defaultSetRoyaltyForMember(owners.length),
            creators, UintArrayUtils.defaultSetRoyaltyForMember(creators.length),
            sponsors, UintArrayUtils.defaultSetRoyaltyForMember(sponsors.length),
            thanks, UintArrayUtils.defaultSetRoyaltyForMember(thanks.length),
            uri(newItemId), true, 0, DataTypes.royaltyTable(0, 10000, 0, 0, 0),
            DataTypes.RoyaltyVoting(address(0x0), address(0x0), 0, false),"");
        defaultRoyaltyTable(newItemId);
        return newItemId;
    }

    function clone(uint formerId, uint _initSupply, uint _editType)
    external onlyRole(MINTER_ROLE) returns (uint) {
        require(balanceOf(msg.sender, formerId) == 1, "FO");
        require(msg.sender == Rights[formerId].owners[0], "SO");
        require(Rights[formerId].cloneable == true, "AS");

        uint initSupply = 1;
        bool cloneable = true;

        // SELL TYPE
        // if _edittype is 1; Colen for Sell
        if (_editType == 1) {
            initSupply = _initSupply;
            cloneable = false;
        }

        _tokenIds.increment();
        uint newItemId = _tokenIds.current();

        address[] memory tempArr = new address[](1);
        tempArr[0] = msg.sender;
        uint _order = Rights[formerId].order + 1;
        DataTypes.royaltyTable memory RT;
        uint32[] memory zero;
        Rights[newItemId] = DataTypes.Right(
            newItemId, formerId,
            tempArr, UintArrayUtils.defaultSetRoyaltyForMember(tempArr.length),
            new address[](0), zero,
            new address[](0), zero,
            new address[](0), zero,
            uri(newItemId), cloneable, _order, RT,
            DataTypes.RoyaltyVoting(address(0x0), address(0x0), 0, false), '');
        defaultRoyaltyTable(newItemId);
        _mint(tempArr[0], newItemId, initSupply, '');
        return newItemId;
    }

    /*function addRoyaltyMember(uint _tokenId, address[] memory members, uint32[] memory _shares)
    public onlyRole(ADD_MEMBER_ROLE) returns (uint){
        require(exists(_tokenId), "NS");
        require(members.length == _shares.length, "");

        DataTypes.Right storage tempright = Rights[_tokenId];

        if (msg.sender == tempright.owners[0]) {
            require(balanceOf(msg.sender, _tokenId) != 0, "CD");
            tempright.owners = tempright.owners.concat(members);
            tempright.ownerspercent = tempright.ownerspercent.concat(_shares);
        } else if (msg.sender == tempright.creators[0]) {
            require(hasRole(ADD_MEMBER_ROLE, tempright.creators[0]), "NCA");
            tempright.creators = tempright.creators.concat(members);
            tempright.creatorpercent = tempright.creatorpercent.concat(_shares);
        } else if (msg.sender == tempright.sponsors[0]) {
            require(hasRole(ADD_MEMBER_ROLE, tempright.sponsors[0]), "NSA");
            tempright.sponsors = tempright.sponsors.concat(members);
            tempright.sponsorpercent = tempright.sponsorpercent.concat(_shares);
        } else if (msg.sender == tempright.thanks[0]) {
            require(hasRole(ADD_MEMBER_ROLE, tempright.thanks[0]), "NTA");
            tempright.thanks = tempright.thanks.concat(members);
            tempright.thankpercent = tempright.thankpercent.concat(_shares);
        }

        tempright.royalty_table = defaultRoyaltyTable(_tokenId);
        return _tokenId;
    }*/

    function setGroupAdmin(uint _tokenId, address _newAdmin, uint8 _adminType) external onlyRole(MINTER_ROLE) returns (uint) {
        require(_exists(_tokenId), "NT");
        require(balanceOf(msg.sender, _tokenId) == 1, "FO");
        require(_adminType < 3, "TP");

        uint8 CREATOR_ADMIN = 0;
        uint8 SPONSOR_ADMIN = 1;
        uint8 THANKS_ADMIN = 2;

        address admin = _newAdmin;
        DataTypes.Right memory tempright = getItem(_tokenId);

        if (_adminType == CREATOR_ADMIN) {
            if (tempright.creators.length != 0) {
                _revokeRole(ADD_MEMBER_ROLE, tempright.creators[0]);
            }
            tempright.creators = tempright.creators.add(admin);
            _grantRole(ADD_MEMBER_ROLE, admin);
        } else if (_adminType == SPONSOR_ADMIN) {
            if (tempright.sponsors.length != 0) {
                _revokeRole(ADD_MEMBER_ROLE, tempright.sponsors[0]);
            }
            tempright.sponsors = tempright.sponsors.add(admin);
            _grantRole(ADD_MEMBER_ROLE, admin);
        } else if (_adminType == THANKS_ADMIN) {
            if (tempright.thanks.length != 0) {
                _revokeRole(ADD_MEMBER_ROLE, tempright.thanks[0]);
            }
            tempright.thanks = tempright.thanks.add(admin);
            _grantRole(ADD_MEMBER_ROLE, admin);
        }
        Rights[_tokenId] = tempright;
        return _tokenId;
    }

    function propose(uint _tokenId, uint32 _newRoyalty) external {
        require(exists(_tokenId), "NS");
        require(balanceOf(msg.sender, _tokenId) == 1, "FO");
        require(_newRoyalty < 10000, "");

        Rights[_tokenId].setProposer(_newRoyalty);
    }

    function admit(uint _tokenId) external {
        require(exists(_tokenId), "NS");
        require(balanceOf(msg.sender, Rights[_tokenId].formerId) == 1, "FO");

        Rights[_tokenId].admitPropose();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
        Rights[id].owners[0] = to;
        _grantRole(ADD_MEMBER_ROLE, to);
    }

    function getItem(uint _tokenId) public view returns (DataTypes.Right memory) {
        return Rights[_tokenId];
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
        _uri = newuri;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint[] memory ids, uint[] memory amounts, bytes memory data)
    internal override (ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint _id) public view virtual override returns (string memory) {
        require(_exists(_id), "ERC1155Tradable#uri: NONEXISTENT_TOKEN");
        return string(abi.encodePacked(_uri, Strings.toString(_id), ".json"));
    }

    function supportsInterface(bytes4 interfaceId)
    public view virtual override(ERC1155, AccessControl, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _exists(uint _id) internal pure returns (bool) {
        return _id != 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

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

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

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
        emit ApprovalForAll(owner, operator, approved);
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

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/extensions/ERC1155Supply.sol)

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
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AddressArrayUtils {
    function concat(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        address[] memory updateowners = new address[](A.length + B.length);
        for (uint i = 0; i < A.length; i++) {
            updateowners[i] = A[i];
        }
        for (uint i = 0; i < B.length; i++) {
            updateowners[i + A.length] = B[i];
        }
        return updateowners;
    }

    function add(address[] memory A, address _newAddress) internal pure returns (address[] memory) {
        if (A.length == 0) {
            address[] memory newA = new address[](1);
            newA[0] = _newAddress;
            return newA;
        } else {
            A[0] = _newAddress;
            return A;
        }
    }

    function removeAddr(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        require (B.length <= A.length, "remove count error") ;
        for (uint i = 0; i < A.length-1; i++){
            for (uint j = 0; j < B.length-1; j++){
                if (A[i] == B[j]){
                    for (uint z = i; z<A.length-1; z++){
                        A[z] = A[z+1];
                        delete A[A.length-1];
                    }      
                    continue;              
                }                
            }    
        }
        return A;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes} from "./DataTypes.sol";

library UintArrayUtils {
    function concat(uint32[] memory A, uint32[] memory B) internal pure returns (uint32[] memory) {
        uint32[] memory updatepercent = new uint32[](A.length + B.length);
        for (uint i = 0; i < A.length; i++) {
            updatepercent[i] = A[i];
        }
        for (uint i = 0; i < B.length; i++) {
            updatepercent[i + A.length] = B[i];
        }
        return updatepercent;
    }

    function defaultSetRoyaltyForMember(uint _length) internal pure returns (uint32[] memory){
        if (_length != 0) {
            uint32[] memory percents = new uint32[](_length);
            uint32 average = 10000 / uint32(_length);
            for (uint i = 1; i < _length; i++) {
                percents[i] = average;
            }
            percents[0] = 10000 - average * (uint32(_length) - 1);
            return (percents);
        } else {
            uint32[] memory percents;
            return (percents);
        }
    }

    function concatst(DataTypes.status[] memory A, DataTypes.status[] memory B) internal pure returns (DataTypes.status[] memory) {
        DataTypes.status[] memory updatestatus = new DataTypes.status[](A.length + B.length);
        for (uint i = 0; i < A.length; i++) {
            updatestatus[i] = A[i];
        }
        for (uint i = 0; i < B.length; i++) {
            updatestatus[i + A.length] = B[i];
        }
        return updatestatus;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import {AddressArrayUtils} from "./lib/AddressArrayUtils.sol";
import {UintArrayUtils} from "./lib/UintArrayUtils.sol";
import {DataTypes} from "./lib/DataTypes.sol";

import './ERC2981Base.sol';


/// @dev This is a contract used to add ERC2981 support to 1155

abstract contract ERC2981TokenRoyalties is ERC2981Base {
    using AddressArrayUtils for address[];
    using UintArrayUtils for uint32[];
    using UintArrayUtils for DataTypes.status[];
    using DataTypes for DataTypes.Right;

    mapping(uint256 => DataTypes.RoyaltyInfo) internal _royalties;
    mapping(uint => DataTypes.Right) internal Rights;

    /// @notice default is ROCST = 50;15;15;10;10  
    //              
    /// @param  _tokenId - NFT tokenId and set default table for Royalty
    /// @return royaltyTable  - all numbers have to %
    //                   Percentage decimal is -2: 0 ~ 10000
    //                   Table; R, O, C, S, T;

    function defaultRoyaltyTable(uint _tokenId) internal returns (DataTypes.royaltyTable memory){
        return Rights[_tokenId].defaultRoyaltyTable();
    }

    // TODO: Handshake Royalty
    function setRoyaltyTable(uint _tokenId, uint32[4] memory _tabledata) external returns (DataTypes.royaltyTable memory) {
        require(10000 - Rights[_tokenId].royalty_table.Royalty ==
            _tabledata[0] + _tabledata[1] + _tabledata[2] + _tabledata[3], "Table data Input error");

        Rights[_tokenId].royalty_table = DataTypes.royaltyTable(Rights[_tokenId].royalty_table.Royalty,
            _tabledata[0], _tabledata[1], _tabledata[2], _tabledata[3]);

        return (Rights[_tokenId].royalty_table);
    }

    /// @dev Sets token royalties
    /// @param tokenId the token id for which we register the royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setTokenRoyalty(
        uint256 tokenId,
        address[] memory recipient,
        uint32[] memory value,
        bool is_del_add
    ) internal {
        uint32 total = 0;
        for (uint32 i = 0; i < value.length; i++) {total += value[i];}
        require(total == 10000, "Value should 100%");

        Rights[tokenId].setRoyalty(recipient, value, is_del_add);
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    public
    view
    override
    returns (DataTypes.RoyaltyInfo memory){
        return Rights[_tokenId].royaltyInfo(_salePrice);
    }

    function totalRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) external view
    returns (address[] memory _recepient, uint32[] memory _royaltyPercent, DataTypes.status[] memory _shareflag){

        uint256 t_tokenId = _tokenId;
        uint256 t_salePrice = _salePrice;
        DataTypes.RoyaltyInfo memory t_RoyaltyInfo;
        while (Rights[t_tokenId].order != 0) {

            t_RoyaltyInfo.receiver = t_RoyaltyInfo.receiver.concat(royaltyInfo(t_tokenId, t_salePrice).receiver);
            t_RoyaltyInfo.royaltyPercent = t_RoyaltyInfo.royaltyPercent.concat(royaltyInfo(t_tokenId, t_salePrice).royaltyPercent);
            t_RoyaltyInfo.shareflag = t_RoyaltyInfo.shareflag.concatst(royaltyInfo(t_tokenId, t_salePrice).shareflag);
            t_tokenId = royaltyInfo(t_tokenId, t_salePrice).formerID;
            t_salePrice = royaltyInfo(t_tokenId, t_salePrice).Price;
            // console.log(Rights[t_tokenId].order);        
        }
        return (t_RoyaltyInfo.receiver, t_RoyaltyInfo.royaltyPercent, t_RoyaltyInfo.shareflag);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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
pragma solidity ^0.8.0;

import "./UintArrayUtils.sol";
import "./AddressArrayUtils.sol";

library DataTypes {
    using UintArrayUtils for uint32[];
    using AddressArrayUtils for address[];

    struct Right {
        uint id;
        uint formerId;
        address[] owners;
        uint32[] ownerspercent;
        address[] creators;
        uint32[] creatorpercent;
        address[] sponsors;
        uint32[] sponsorpercent;
        address[] thanks;
        uint32[] thankpercent;
        string uri;
        bool cloneable;
        uint order;
        royaltyTable royalty_table;
        RoyaltyVoting royalty_voting;
        bytes metadata;
    }

    struct royaltyTable {
        uint32 Royalty;
        uint32 holdershare;
        uint32 creatorshare;
        uint32 sponsorshare;
        uint32 thanksshare;
    }

    enum status {
        Owners, Creators, Sponsors, Thanks
    }

    struct RoyaltyInfo {
        address[] receiver;
        uint32[] royaltyPercent;
        status[] shareflag;
        uint formerID;
        uint Price;
    }

    struct RoyaltyVoting {
        address proposer;
        address admitter;
        uint32 newRoyalty;
        bool admitted;
    }

    function defaultRoyaltyTable(Right storage self) internal returns (royaltyTable memory) {
        uint32 creatorpercent = 0;
        uint32 sponsorpercent = 0;
        uint32 thankpercent = 0;
        uint32 royalty = 0;
        if (self.creators.length != 0) {creatorpercent = 1500;
            self.creatorpercent = UintArrayUtils.defaultSetRoyaltyForMember(self.creators.length);}

        if (self.sponsors.length != 0) {sponsorpercent = 1000;
            self.sponsorpercent = UintArrayUtils.defaultSetRoyaltyForMember(self.sponsors.length);}

        if (self.thanks.length != 0) {thankpercent = 1000;
            self.thankpercent = UintArrayUtils.defaultSetRoyaltyForMember(self.thanks.length);}

        if (self.order != 0) {royalty = 5000;}

        uint32 holderspercent = 10000 - creatorpercent - sponsorpercent - thankpercent - royalty;
        self.ownerspercent = UintArrayUtils.defaultSetRoyaltyForMember(self.owners.length);

        return self.royalty_table = royaltyTable(royalty, holderspercent, creatorpercent, sponsorpercent, thankpercent);
    }

    function setRoyalty(Right storage self, address[] memory recipient, uint32[] memory value, bool is_del_add) internal {
        if (msg.sender == self.owners[0]) {
            if (is_del_add == true) {self.owners = self.owners.concat(recipient);}
            else {self.owners = self.owners.removeAddr(recipient);}

            require(self.owners.length == value.length);
            self.ownerspercent = value;
        } else if (msg.sender == self.creators[0]) {
            if (is_del_add == true) {self.creators = self.creators.concat(recipient);}
            else {self.creators = self.creators.removeAddr(recipient);}

            require(self.creators.length == value.length);
            self.creatorpercent = value;
        } else if (msg.sender == self.sponsors[0]) {
            if (is_del_add == true) {self.sponsors = self.sponsors.concat(recipient);}
            else {self.sponsors = self.sponsors.removeAddr(recipient);}

            require(self.sponsors.length == value.length);
            self.sponsorpercent = value;

        } else if (msg.sender == self.thanks[0]) {
            if (is_del_add == true) {self.thanks = self.thanks.concat(recipient);}
            else {self.thanks = self.thanks.removeAddr(recipient);}

            require(self.thanks.length == value.length);
            self.thankpercent = value;
        }
    }

    function royaltyInfo(Right storage self, uint _salePrice) internal view returns (RoyaltyInfo memory) {
        uint index = 0;

        uint formerID = self.formerId;
        // uint _royaltycount = ;

        address[] memory _recepient = new address[](self.owners.length + self.creators.length
        + self.sponsors.length + self.thanks.length);
        uint32[] memory _royaltyPercent = new uint32[](_recepient.length);
        status[] memory _shareflag = new status[](_recepient.length);

        uint j;
        if (self.owners.length == 1) {
            _recepient[index] = self.owners[0];
            _shareflag[index] = status.Owners;
            _royaltyPercent[index] = self.royalty_table.holdershare;
            index++;
        } else if (self.owners.length > 1) {
            _recepient = _recepient.concat(self.owners);
            for (j = 0; j < self.owners.length; j++) {
                // _recepient[index] = self.owners[j];
                _shareflag[index] = status.Owners;
                _royaltyPercent[index] = self.ownerspercent[j] * self.royalty_table.holdershare / 10000;
                index++;
            }
        }
        if (self.creators.length > 0) {
            _recepient = _recepient.concat(self.creators);
            for (j = 0; j < self.creators.length; j++) {
                // _recepient[index] = self.creators[j];
                _shareflag[index] = status.Creators;
                _royaltyPercent[index] = self.creatorpercent[j] * self.royalty_table.creatorshare / 10000;
                index++;
            }
        }
        if (self.sponsors.length > 0) {
            _recepient = _recepient.concat(self.sponsors);
            for (j = 0; j < self.sponsors.length; j++) {
                // _recepient[index] = self.sponsors[j];
                _shareflag[index] = status.Sponsors;
                _royaltyPercent[index] = self.sponsorpercent[j] * self.royalty_table.sponsorshare / 10000;
                index++;
            }
        }
        if (self.thanks.length > 0) {
            _recepient = _recepient.concat(self.thanks);
            for (j = 0; j < self.thanks.length; j++) {
                // _recepient[index] = self.thanks[j];
                _shareflag[index] = status.Thanks;
                _royaltyPercent[index] = self.thankpercent[j] * self.royalty_table.thanksshare / 10000;
                index++;
            }
        }

        uint Price;
        if (self.royalty_voting.admitted == true) {
            Price = self.royalty_voting.newRoyalty * _salePrice / 10000;
        } else {
            Price = self.royalty_table.Royalty * _salePrice / 10000;
        }

        RoyaltyInfo memory royaltyInformation;
        royaltyInformation.receiver = _recepient;
        royaltyInformation.royaltyPercent = _royaltyPercent;
        royaltyInformation.shareflag = _shareflag;
        royaltyInformation.formerID = formerID;
        royaltyInformation.Price = Price;
        return (royaltyInformation);
    }

    function setProposer(Right storage self, uint32 _newRoyalty) internal {
        self.royalty_voting.proposer = msg.sender;
        self.royalty_voting.newRoyalty = _newRoyalty;
        self.royalty_voting.admitted = false;
    }

    function admitPropose(Right storage self) internal {
        self.royalty_voting.admitter = msg.sender;
        self.royalty_voting.admitted = true;

        if (self.royalty_table.Royalty >= self.royalty_voting.newRoyalty) {
            self.royalty_table.holdershare += (self.royalty_table.Royalty - self.royalty_voting.newRoyalty);
        } else {
            require((self.royalty_voting.newRoyalty - self.royalty_table.Royalty) <= self.royalty_table.holdershare);
            self.royalty_table.holdershare -= (self.royalty_voting.newRoyalty - self.royalty_table.Royalty);
        }
        self.royalty_table.Royalty = self.royalty_voting.newRoyalty;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import "./IERC2981Royalties.sol";
import {UintArrayUtils} from "./lib/UintArrayUtils.sol";
// import {DataTypes} from "./lib/DataTypes.sol";

/// @title ERC2981Base
/// @dev  ERC2981 inherite from 165 and Interface

abstract contract ERC2981Base is ERC165, IERC2981Royalties {
    
    /// @notice Recipient kind; named status; Owner = holder, creators, Sponsors, Thanks;
    //          Publisher is creator - one kind of Owner,  Holder is current owner = one of Owner;

    /// @notice Roylaty information realted to certain ID           
    /// @param receiver - all the receivers address 
    /// @param royaltyPercent - % of the royalty 100% == 10000 uint32
    /// @param shareflag -  the each receivers' type O,C,S,T
    /// @param formerID -  Former token ID
    /// @param Price -  Former royatly Amount no % !
    

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
    {
        return
        interfaceId == type(IERC2981Royalties).interfaceId ||
        super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes} from "./lib/DataTypes.sol";
/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
   function royaltyInfo(uint256 _tokenId, uint256 _value)
    external
    view
    returns (DataTypes.RoyaltyInfo memory);
    // address[] memory _receiver, uint32[] memory _royaltyPercent, 
    //         DataTypes.status[] memory shareflag, 
    //         uint formerID,
    //         uint Price);    
}