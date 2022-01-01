// SPDX-License-Identifier: MIT

// IQ Protocol. Risk-free collateral-less utility renting
// https://iq.space/docs/iq-yellow-paper.pdf
// (C) Blockvis & PARSIQ
// 🖖 Stake strong!

pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IConverter.sol";
import "./libs/Errors.sol";

/**
 * Noop converter
 */
contract DefaultConverter is IConverter {
    function estimateConvert(
        IERC20 source,
        uint256 amount,
        IERC20 target
    ) external pure override returns (uint256) {
        require(address(source) == address(target), Errors.DC_UNSUPPORTED_PAIR);

        return amount;
    }

    /**
     * @dev Converts `source` tokens to `target` tokens.
     * Converted tokens must be on `msg.sender` address after exiting this function
     */
    function convert(
        IERC20 source,
        uint256 amount,
        IERC20 target
    ) external pure override returns (uint256) {
        require(address(source) == address(target), Errors.DC_UNSUPPORTED_PAIR);
        return amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Currency converter interface.
 */
interface IConverter {
    /**
     * After calling this function it is expected that requested currency will be
     * transferred to the msg.sender automatically
     */
    function convert(
        IERC20 source,
        uint256 amount,
        IERC20 target
    ) external returns (uint256);

    /**
     * Estimates conversion of `source` currency into `target` currency
     */
    function estimateConvert(
        IERC20 source,
        uint256 amount,
        IERC20 target
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title Errors library
 * @dev Error messages prefix glossary:
 *  - EXP = ExpMath
 *  - ERC20 = ERC20
 *  - ERC721 = ERC721
 *  - ERC721META = ERC721Metadata
 *  - ERC721ENUM = ERC721Enumerable
 *  - DC = DefaultConverter
 *  - DE = DefaultEstimator
 *  - E = Enterprise
 *  - EO = EnterpriseOwnable
 *  - ES = EnterpriseStorage
 *  - IO = InitializableOwnable
 *  - PT = PowerToken
 */
library Errors {
    // common errors
    string internal constant NOT_INITIALIZED = "1";
    string internal constant ALREADY_INITIALIZED = "2";
    string internal constant CALLER_NOT_OWNER = "3";
    string internal constant CALLER_NOT_ENTERPRISE = "4";
    string internal constant INVALID_ADDRESS = "5";
    string internal constant UNREGISTERED_POWER_TOKEN = "6";
    string internal constant INVALID_ARRAY_LENGTH = "7";

    // contract specific errors
    string internal constant EXP_INVALID_PERIOD = "8";

    string internal constant ERC20_INVALID_PERIOD = "9";
    string internal constant ERC20_TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE = "10";
    string internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = "11";
    string internal constant ERC20_TRANSFER_FROM_THE_ZERO_ADDRESS = "12";
    string internal constant ERC20_TRANSFER_TO_THE_ZERO_ADDRESS = "13";
    string internal constant ERC20_TRANSFER_AMOUNT_EXCEEDS_BALANCE = "14";
    string internal constant ERC20_MINT_TO_THE_ZERO_ADDRESS = "15";
    string internal constant ERC20_BURN_FROM_THE_ZERO_ADDRESS = "16";
    string internal constant ERC20_BURN_AMOUNT_EXCEEDS_BALANCE = "17";
    string internal constant ERC20_APPROVE_FROM_THE_ZERO_ADDRESS = "18";
    string internal constant ERC20_APPROVE_TO_THE_ZERO_ADDRESS = "19";

    string internal constant ERC721_BALANCE_QUERY_FOR_THE_ZERO_ADDRESS = "20";
    string internal constant ERC721_OWNER_QUERY_FOR_NONEXISTENT_TOKEN = "21";
    string internal constant ERC721_APPROVAL_TO_CURRENT_OWNER = "22";
    string internal constant ERC721_APPROVE_CALLER_IS_NOT_OWNER_NOR_APPROVED_FOR_ALL = "23";
    string internal constant ERC721_APPROVED_QUERY_FOR_NONEXISTENT_TOKEN = "24";
    string internal constant ERC721_APPROVE_TO_CALLER = "25";
    string internal constant ERC721_TRANSFER_CALLER_IS_NOT_OWNER_NOR_APPROVED = "26";
    string internal constant ERC721_TRANSFER_TO_NON_ERC721RECEIVER_IMPLEMENTER = "27";
    string internal constant ERC721_OPERATOR_QUERY_FOR_NONEXISTENT_TOKEN = "28";
    string internal constant ERC721_MINT_TO_THE_ZERO_ADDRESS = "29";
    string internal constant ERC721_TOKEN_ALREADY_MINTED = "30";
    string internal constant ERC721_TRANSFER_OF_TOKEN_THAT_IS_NOT_OWN = "31";
    string internal constant ERC721_TRANSFER_TO_THE_ZERO_ADDRESS = "32";

    string internal constant ERC721META_URI_QUERY_FOR_NONEXISTENT_TOKEN = "33";

    string internal constant ERC721ENUM_OWNER_INDEX_OUT_OF_BOUNDS = "34";
    string internal constant ERC721ENUM_GLOBAL_INDEX_OUT_OF_BOUNDS = "35";

    string internal constant DC_UNSUPPORTED_PAIR = "36";

    string internal constant DE_INVALID_ENTERPRISE_ADDRESS = "37";
    string internal constant DE_LABMDA_NOT_GT_0 = "38";

    string internal constant E_CALLER_NOT_RENTAL_TOKEN = "39";
    string internal constant E_INVALID_BASE_TOKEN_ADDRESS = "40";
    string internal constant E_SERVICE_LIMIT_REACHED = "41";
    string internal constant E_INVALID_RENTAL_PERIOD_RANGE = "42";
    string internal constant E_SERVICE_ENERGY_GAP_HALVING_PERIOD_NOT_GT_0 = "43";
    string internal constant E_UNSUPPORTED_PAYMENT_TOKEN = "44";
    string internal constant E_RENTAL_PERIOD_OUT_OF_RANGE = "45";
    string internal constant E_INSUFFICIENT_LIQUIDITY = "46";
    string internal constant E_RENTAL_PAYMENT_SLIPPAGE = "47";
    string internal constant E_INVALID_RENTAL_TOKEN_ID = "48";
    string internal constant E_INVALID_RENTAL_PERIOD = "49";
    string internal constant E_FLASH_LIQUIDITY_REMOVAL = "50";
    string internal constant E_SWAPPING_DISABLED = "51";
    string internal constant E_RENTAL_TRANSFER_NOT_ALLOWED = "52";
    string internal constant E_INVALID_CALLER_WITHIN_RENTER_ONLY_RETURN_PERIOD = "53";
    string internal constant E_INVALID_CALLER_WITHIN_ENTERPRISE_ONLY_COLLECTION_PERIOD = "54";

    string internal constant EF_INVALID_ENTERPRISE_IMPLEMENTATION_ADDRESS = "55";
    string internal constant EF_INVALID_POWER_TOKEN_IMPLEMENTATION_ADDRESS = "56";
    string internal constant EF_INVALID_STAKE_TOKEN_IMPLEMENTATION_ADDRESS = "57";
    string internal constant EF_INVALID_RENTAL_TOKEN_IMPLEMENTATION_ADDRESS = "58";

    string internal constant EO_INVALID_ENTERPRISE_ADDRESS = "59";

    string internal constant ES_INVALID_ESTIMATOR_ADDRESS = "60";
    string internal constant ES_INVALID_COLLECTOR_ADDRESS = "61";
    string internal constant ES_INVALID_WALLET_ADDRESS = "62";
    string internal constant ES_INVALID_CONVERTER_ADDRESS = "63";
    string internal constant ES_INVALID_RENTER_ONLY_RETURN_PERIOD = "64";
    string internal constant ES_INVALID_ENTERPRISE_ONLY_COLLECTION_PERIOD = "65";
    string internal constant ES_STREAMING_RESERVE_HALVING_PERIOD_NOT_GT_0 = "66";
    string internal constant ES_MAX_SERVICE_FEE_PERCENT_EXCEEDED = "67";
    string internal constant ES_INVALID_BASE_TOKEN_ADDRESS = "68";
    string internal constant ES_INVALID_RENTAL_PERIOD_RANGE = "69";
    string internal constant ES_SWAPPING_ALREADY_ENABLED = "70";
    string internal constant ES_INVALID_PAYMENT_TOKEN_ADDRESS = "71";
    string internal constant ES_UNREGISTERED_PAYMENT_TOKEN = "72";

    string internal constant IO_INVALID_OWNER_ADDRESS = "73";

    string internal constant PT_INSUFFICIENT_AVAILABLE_BALANCE = "74";

    string internal constant E_ENTERPRISE_SHUTDOWN = "75";
    string internal constant E_INVALID_RENTAL_AMOUNT = "76";
    string internal constant ES_INVALID_BONDING_POLE = "77";
    string internal constant ES_INVALID_BONDING_SLOPE = "78";
    string internal constant ES_TRANSFER_ALREADY_ENABLED = "79";
    string internal constant PT_TRANSFER_DISABLED = "80";
    string internal constant E_INVALID_ENTERPRISE_NAME = "81";
    string internal constant PT_INVALID_MAX_RENTAL_PERIOD = "82";
    string internal constant E_INVALID_ENTERPRISE_FACTORY_ADDRESS = "83";
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../libs/Errors.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function initialize(string memory name_, string memory symbol_) public {
        require(bytes(_name).length == 0, Errors.ALREADY_INITIALIZED);
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), Errors.ERC721_BALANCE_QUERY_FOR_THE_ZERO_ADDRESS);
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), Errors.ERC721_OWNER_QUERY_FOR_NONEXISTENT_TOKEN);
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), Errors.ERC721META_URI_QUERY_FOR_NONEXISTENT_TOKEN);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overridden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, Errors.ERC721_APPROVAL_TO_CURRENT_OWNER);

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            Errors.ERC721_APPROVE_CALLER_IS_NOT_OWNER_NOR_APPROVED_FOR_ALL
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), Errors.ERC721_APPROVED_QUERY_FOR_NONEXISTENT_TOKEN);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external virtual override {
        require(operator != msg.sender, Errors.ERC721_APPROVE_TO_CALLER);

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), Errors.ERC721_TRANSFER_CALLER_IS_NOT_OWNER_NOR_APPROVED);

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
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
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), Errors.ERC721_TRANSFER_CALLER_IS_NOT_OWNER_NOR_APPROVED);
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            Errors.ERC721_TRANSFER_TO_NON_ERC721RECEIVER_IMPLEMENTER
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), Errors.ERC721_OPERATOR_QUERY_FOR_NONEXISTENT_TOKEN);
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            Errors.ERC721_TRANSFER_TO_NON_ERC721RECEIVER_IMPLEMENTER
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), Errors.ERC721_MINT_TO_THE_ZERO_ADDRESS);
        require(!_exists(tokenId), Errors.ERC721_TOKEN_ALREADY_MINTED);

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
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
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, Errors.ERC721_TRANSFER_OF_TOKEN_THAT_IS_NOT_OWN);
        require(to != address(0), Errors.ERC721_TRANSFER_TO_THE_ZERO_ADDRESS);

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(Errors.ERC721_TRANSFER_TO_NON_ERC721RECEIVER_IMPLEMENTER);
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
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

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "./libs/Errors.sol";
import "./interfaces/IInitializableOwnable.sol";

/**
 * @dev Ownable contract with `initialize` function instead of constructor. Primary usage is for proxies like ERC-1167 with no constructor.
 */
abstract contract InitializableOwnable is IInitializableOwnable {
    // This is the keccak-256 hash of "iq.protocol.owner" subtracted by 1
    bytes32 private constant _OWNER_SLOT = 0x4f471908b72bb76dae5bd24599026e7bf3ddb256497722888ffa422f83729ede;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the owner of the contract. The inheritor of this contract *MUST* ensure this method is not called twice.
     */
    function initialize(address initialOwner) public {
        require(owner() == address(0), Errors.ALREADY_INITIALIZED);
        require(initialOwner != address(0), Errors.IO_INVALID_OWNER_ADDRESS);
        StorageSlot.getAddressSlot(_OWNER_SLOT).value = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return StorageSlot.getAddressSlot(_OWNER_SLOT).value;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, Errors.CALLER_NOT_OWNER);
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), Errors.IO_INVALID_OWNER_ADDRESS);
        emit OwnershipTransferred(owner(), newOwner);
        StorageSlot.getAddressSlot(_OWNER_SLOT).value = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IInitializableOwnable {
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "./IInitializableOwnable.sol";
import "./IStakeToken.sol";
import "./IRentalToken.sol";
import "./IConverter.sol";

interface IEnterpriseStorage is IInitializableOwnable {
    struct RentalAgreement {
        // slot 1, 0 bytes left
        uint112 rentalAmount; // 14 bytes
        uint16 powerTokenIndex; // 2 bytes
        uint32 startTime; // 4 bytes
        uint32 endTime; // 4 bytes
        uint32 renterOnlyReturnTime; // 4 bytes
        uint32 enterpriseOnlyCollectionTime; // 4 bytes
        // slot 2, 16 bytes left
        uint112 gcRewardAmount; // 14 bytes
        uint16 gcRewardTokenIndex; // 2 bytes
    }

    function initialize(
        string memory enterpriseName,
        string calldata baseUri,
        uint16 gcFeePercent,
        IConverter converter,
        ProxyAdmin proxyAdmin,
        address initialOwner
    ) external;

    function initializeTokens(
        IERC20Metadata enterpriseToken,
        IStakeToken stakeToken,
        IRentalToken rentalToken
    ) external;

    function getBaseUri() external view returns (string memory);

    function getConverter() external view returns (IConverter);

    function getEnterpriseToken() external view returns (IERC20Metadata);

    function isSupportedPaymentToken(address token) external view returns (bool);

    function getGCFeePercent() external view returns (uint16);

    function getAvailableReserve() external view returns (uint256);

    function getUsedReserve() external view returns (uint256);

    function getReserve() external view returns (uint256);

    function getBondingCurve() external view returns (uint256 pole, uint256 slope);

    function getRentalAgreement(uint256 rentalTokenId) external view returns (RentalAgreement memory);

    function getPaymentToken(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";
import "../../access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IStakeTokenStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IStakeToken is IERC721, IStakeTokenStorage {
    function mint(address to) external returns (uint256);

    function burn(uint256 tokenId) external;

    function getNextTokenId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IRentalTokenStorage.sol";

interface IRentalToken is IERC721, IRentalTokenStorage {
    function mint(address to) external returns (uint256);

    function burn(uint256 tokenId, address burner) external;

    function getNextTokenId() external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
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

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
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

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./IEnterprise.sol";

interface IStakeTokenStorage is IERC721Enumerable {
    function initialize(
        string memory name,
        string memory symbol,
        IEnterprise enterprise
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IEnterpriseStorage.sol";

interface IEnterprise is IEnterpriseStorage {
    function transferRental(
        address from,
        address to,
        uint256 rentalTokenId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IEnterprise.sol";

interface IRentalTokenStorage {
    function initialize(
        string memory name,
        string memory symbol,
        IEnterprise enterprise
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "./interfaces/IPowerToken.sol";
import "./interfaces/IStakeToken.sol";
import "./interfaces/IRentalToken.sol";
import "./interfaces/IConverter.sol";
import "./interfaces/IEnterpriseStorage.sol";
import "./InitializableOwnable.sol";
import "./EnterpriseFactory.sol";
import "./math/ExpMath.sol";
import "./libs/Errors.sol";

/**
 * @dev Contract which stores Enterprise state
 * To prevent Enterprise from front-running it's users, it is supposed to be owned by some
 * Governance system. For example: OpenZeppelin `TimelockController` contract can
 * be used as an `owner` of this contract
 */
abstract contract EnterpriseStorage is InitializableOwnable, IEnterpriseStorage {
    struct Stake {
        uint256 amount;
        uint256 shares;
        uint256 block;
    }
    struct PaymentTokenInfo {
        address paymentToken;
        bool enabled;
    }

    // This is the keccak-256 hash of "iq.protocol.proxy.admin" subtracted by 1
    bytes32 private constant _PROXY_ADMIN_SLOT = 0xd1248cccb5fef9131c731321e43e9a924840ffee7dc68c7d1d3e5cb7dedcae03;

    /**
     * @dev ERC20 token backed by enterprise services
     */
    IERC20Metadata internal _enterpriseToken;

    /**
     * @dev ERC721 stake bearing token
     */
    IStakeToken internal _stakeToken;

    /**
     * @dev ERC721 rental agreement bearing token
     */
    IRentalToken internal _rentalToken;

    /**
     * @dev Enterprise factory address
     */
    EnterpriseFactory internal _factory;

    /**
     * @dev This is a time period after which the half of the received pool fee will be streamed to the renting pool.
     */
    uint32 internal _streamingReserveHalvingPeriod;

    bool internal _enterpriseShutdown;

    /**
     * @dev Token conversion service address
     */
    IConverter internal _converter;

    /**
     * @dev Account which have rights to collect power tokens after rental agreement expiration
     */
    address internal _enterpriseCollector;

    /**
     * @dev Enterprise wallet address
     */
    address internal _enterpriseWallet;

    uint32 internal _renterOnlyReturnPeriod;
    uint32 internal _enterpriseOnlyCollectionPeriod;
    uint16 internal _gcFeePercent; // 100 is 1%, 10_000 is 100%

    mapping(address => int16) internal _paymentTokensIndex;
    address[] internal _paymentTokens;

    /**
     * @dev Fixed amount of enterprise tokens currently present in the renting pool
     */
    uint256 internal _fixedReserve;

    /**
     * @dev Total amount of used enterprise tokens
     */
    uint256 internal _usedReserve;

    /**
     * @dev Outstanding amount of enterprise tokens (rental payments) which is being continuously streamed to the renting pool
     */
    uint112 internal _streamingReserve;
    uint112 internal _streamingReserveTarget;
    uint32 internal _streamingReserveUpdated;

    /**
     * @dev Total number of renting pool shares issued to the stakers
     */
    uint256 internal _totalShares;

    /**
     * @dev Bonding factor calculation parameters
     */
    uint256 internal _bondingSlope;
    uint256 internal _bondingPole;

    string internal _name;
    string internal _baseUri;
    mapping(uint256 => RentalAgreement) internal _rentalAgreements;
    mapping(uint256 => Stake) internal _stakes;
    mapping(address => bool) internal _registeredPowerTokens;
    IPowerToken[] internal _powerTokens;

    event EnterpriseOnlyCollectionPeriodChanged(uint32 period);
    event RenterOnlyReturnPeriodChanged(uint32 period);
    event BondingChanged(uint256 pole, uint256 slope);
    event ConverterChanged(address converter);
    event StreamingReserveHalvingPeriodChanged(uint32 period);
    event GcFeePercentChanged(uint16 percent);
    event EnterpriseShutdown();
    event FixedReserveChanged(uint256 fixedReserve);
    event StreamingReserveChanged(uint112 streamingReserve, uint112 streamingReserveTarget);
    event PaymentTokenChange(address paymentToken, bool enabled);
    event EnterpriseWalletChanged(address wallet);
    event EnterpriseCollectorChanged(address collector);
    event BaseUriChanged(string baseUri);

    modifier whenNotShutdown() {
        require(!_enterpriseShutdown, Errors.E_ENTERPRISE_SHUTDOWN);
        _;
    }

    modifier onlyRentalToken() {
        require(msg.sender == address(_rentalToken), Errors.E_CALLER_NOT_RENTAL_TOKEN);
        _;
    }

    modifier onlyStakeTokenOwner(uint256 stakeTokenId) {
        require(_stakeToken.ownerOf(stakeTokenId) == msg.sender, Errors.CALLER_NOT_OWNER);
        _;
    }

    function initialize(
        string memory enterpriseName,
        string calldata baseUri,
        uint16 gcFeePercent,
        IConverter converter,
        ProxyAdmin proxyAdmin,
        address owner
    ) external override {
        require(bytes(_name).length == 0, Errors.ALREADY_INITIALIZED);
        require(bytes(enterpriseName).length > 0, Errors.E_INVALID_ENTERPRISE_NAME);
        InitializableOwnable.initialize(owner);
        StorageSlot.getAddressSlot(_PROXY_ADMIN_SLOT).value = address(proxyAdmin);
        _factory = EnterpriseFactory(msg.sender);
        _name = enterpriseName;
        _baseUri = baseUri;
        _gcFeePercent = gcFeePercent;
        _converter = converter;
        _enterpriseWallet = owner;
        _enterpriseCollector = owner;
        _streamingReserveHalvingPeriod = 7 days;
        _renterOnlyReturnPeriod = 12 hours;
        _enterpriseOnlyCollectionPeriod = 1 days;
        _bondingPole = uint256(5 << 64) / 100; // 5%
        _bondingSlope = uint256(3 << 64) / 10; // 0.3

        emit BaseUriChanged(baseUri);
        emit GcFeePercentChanged(_gcFeePercent);
        emit ConverterChanged(address(_converter));
        emit EnterpriseWalletChanged(_enterpriseWallet);
        emit EnterpriseCollectorChanged(_enterpriseCollector);
        emit StreamingReserveHalvingPeriodChanged(_streamingReserveHalvingPeriod);
        emit RenterOnlyReturnPeriodChanged(_renterOnlyReturnPeriod);
        emit EnterpriseOnlyCollectionPeriodChanged(_enterpriseOnlyCollectionPeriod);
        emit BondingChanged(_bondingPole, _bondingSlope);
    }

    function initializeTokens(
        IERC20Metadata enterpriseToken,
        IStakeToken stakeToken,
        IRentalToken rentalToken
    ) external override {
        require(address(_enterpriseToken) == address(0), Errors.ALREADY_INITIALIZED);
        require(address(enterpriseToken) != address(0), Errors.INVALID_ADDRESS);
        _enterpriseToken = enterpriseToken;
        _stakeToken = stakeToken;
        _rentalToken = rentalToken;
        // Initially the enterprise token is the only accepted payment token.
        _enablePaymentToken(address(enterpriseToken));
    }

    function isRegisteredPowerToken(address powerToken) external view returns (bool) {
        return _registeredPowerTokens[powerToken];
    }

    function getEnterpriseToken() external view override returns (IERC20Metadata) {
        return _enterpriseToken;
    }

    function getStakeToken() external view returns (IStakeToken) {
        return _stakeToken;
    }

    function getRentalToken() external view returns (IRentalToken) {
        return _rentalToken;
    }

    function getPaymentTokens() external view returns (PaymentTokenInfo[] memory) {
        uint256 length = _paymentTokens.length;
        PaymentTokenInfo[] memory info = new PaymentTokenInfo[](length);
        for (uint256 i = 0; i < length; i++) {
            address token = _paymentTokens[i];
            info[i] = PaymentTokenInfo(token, _paymentTokensIndex[token] > 0);
        }
        return info;
    }

    function getPaymentTokenIndex(address token) public view returns (int16) {
        return _paymentTokensIndex[token] - 1;
    }

    function getPaymentToken(uint256 index) external view override returns (address) {
        return _paymentTokens[index];
    }

    function isSupportedPaymentToken(address token) public view override returns (bool) {
        return _paymentTokensIndex[token] > 0;
    }

    function getProxyAdmin() public view returns (ProxyAdmin) {
        return ProxyAdmin(StorageSlot.getAddressSlot(_PROXY_ADMIN_SLOT).value);
    }

    function getEnterpriseCollector() external view returns (address) {
        return _enterpriseCollector;
    }

    function getEnterpriseWallet() external view returns (address) {
        return _enterpriseWallet;
    }

    function getRenterOnlyReturnPeriod() external view returns (uint32) {
        return _renterOnlyReturnPeriod;
    }

    function getEnterpriseOnlyCollectionPeriod() external view returns (uint32) {
        return _enterpriseOnlyCollectionPeriod;
    }

    function getStreamingReserveHalvingPeriod() external view returns (uint32) {
        return _streamingReserveHalvingPeriod;
    }

    function getConverter() external view override returns (IConverter) {
        return _converter;
    }

    function getBaseUri() external view override returns (string memory) {
        return _baseUri;
    }

    function getFactory() external view returns (address) {
        return address(_factory);
    }

    function getInfo()
        external
        view
        returns (
            string memory name,
            string memory baseUri,
            uint32 streamingReserveHalvingPeriod,
            uint32 renterOnlyReturnPeriod,
            uint32 enterpriseOnlyCollectionPeriod,
            uint16 gcFeePercent,
            uint256 totalShares,
            uint256 fixedReserve,
            uint256 usedReserve,
            uint112 streamingReserve,
            uint112 streamingReserveTarget,
            uint32 streamingReserveUpdated
        )
    {
        return (
            _name,
            _baseUri,
            _streamingReserveHalvingPeriod,
            _renterOnlyReturnPeriod,
            _enterpriseOnlyCollectionPeriod,
            _gcFeePercent,
            _totalShares,
            _fixedReserve,
            _usedReserve,
            _streamingReserve,
            _streamingReserveTarget,
            _streamingReserveUpdated
        );
    }

    function getPowerTokens() external view returns (IPowerToken[] memory) {
        return _powerTokens;
    }

    function getRentalAgreement(uint256 rentalTokenId) external view override returns (RentalAgreement memory) {
        _rentalToken.ownerOf(rentalTokenId); // will throw on non existent tokenId
        return _rentalAgreements[rentalTokenId];
    }

    function getStake(uint256 stakeTokenId) external view returns (Stake memory) {
        _stakeToken.ownerOf(stakeTokenId); // will throw on non existent tokenId
        return _stakes[stakeTokenId];
    }

    function getReserve() public view override returns (uint256) {
        return _fixedReserve + _getStreamingReserve();
    }

    function getUsedReserve() external view override returns (uint256) {
        return _usedReserve;
    }

    function getAvailableReserve() public view override returns (uint256) {
        return _getAvailableReserve(getReserve());
    }

    function getBondingCurve() external view override returns (uint256 pole, uint256 slope) {
        return (_bondingPole, _bondingSlope);
    }

    function setEnterpriseCollector(address newCollector) external onlyOwner {
        require(newCollector != address(0), Errors.ES_INVALID_COLLECTOR_ADDRESS);
        _enterpriseCollector = newCollector;
        emit EnterpriseCollectorChanged(newCollector);
    }

    function setEnterpriseWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), Errors.ES_INVALID_WALLET_ADDRESS);
        _enterpriseWallet = newWallet;
        emit EnterpriseWalletChanged(newWallet);
    }

    function setConverter(IConverter newConverter) external onlyOwner {
        require(address(newConverter) != address(0), Errors.ES_INVALID_CONVERTER_ADDRESS);
        _converter = newConverter;
        emit ConverterChanged(address(newConverter));
    }

    function setBondingCurve(uint256 pole, uint256 slope) external onlyOwner {
        require(pole <= uint256(3 << 64) / 10, Errors.ES_INVALID_BONDING_POLE); // max is 30%
        require(slope <= (1 << 64), Errors.ES_INVALID_BONDING_SLOPE);
        _bondingPole = pole;
        _bondingSlope = slope;
        emit BondingChanged(_bondingPole, _bondingSlope);
    }

    function setRenterOnlyReturnPeriod(uint32 newPeriod) external onlyOwner {
        require(newPeriod <= _enterpriseOnlyCollectionPeriod, Errors.ES_INVALID_RENTER_ONLY_RETURN_PERIOD);

        _renterOnlyReturnPeriod = newPeriod;
        emit RenterOnlyReturnPeriodChanged(newPeriod);
    }

    function setEnterpriseOnlyCollectionPeriod(uint32 newPeriod) external onlyOwner {
        require(_renterOnlyReturnPeriod <= newPeriod, Errors.ES_INVALID_ENTERPRISE_ONLY_COLLECTION_PERIOD);

        _enterpriseOnlyCollectionPeriod = newPeriod;
        emit EnterpriseOnlyCollectionPeriodChanged(newPeriod);
    }

    function setBaseUri(string calldata baseUri) external onlyOwner {
        _baseUri = baseUri;
        emit BaseUriChanged(baseUri);
    }

    function setStreamingReserveHalvingPeriod(uint32 streamingReserveHalvingPeriod) external onlyOwner {
        require(streamingReserveHalvingPeriod > 0, Errors.ES_STREAMING_RESERVE_HALVING_PERIOD_NOT_GT_0);
        _streamingReserveHalvingPeriod = streamingReserveHalvingPeriod;
        emit StreamingReserveHalvingPeriodChanged(streamingReserveHalvingPeriod);
    }

    function upgrade(
        address enterpriseFactory,
        address enterpriseImplementation,
        address rentalTokenImplementation,
        address stakeTokenImplementation,
        address powerTokenImplementation,
        address[] calldata powerTokens
    ) external onlyOwner {
        require(enterpriseFactory != address(0), Errors.E_INVALID_ENTERPRISE_FACTORY_ADDRESS);
        _factory = EnterpriseFactory(enterpriseFactory);
        ProxyAdmin admin = getProxyAdmin();
        if (enterpriseImplementation != address(0)) {
            admin.upgrade(TransparentUpgradeableProxy(payable(address(this))), enterpriseImplementation);
        }
        if (rentalTokenImplementation != address(0)) {
            admin.upgrade(TransparentUpgradeableProxy(payable(address(_rentalToken))), rentalTokenImplementation);
        }
        if (stakeTokenImplementation != address(0)) {
            admin.upgrade(TransparentUpgradeableProxy(payable(address(_stakeToken))), stakeTokenImplementation);
        }
        if (powerTokenImplementation != address(0)) {
            for (uint256 i = 0; i < powerTokens.length; i++) {
                require(_registeredPowerTokens[powerTokens[i]], Errors.UNREGISTERED_POWER_TOKEN);
                admin.upgrade(TransparentUpgradeableProxy(payable(powerTokens[i])), powerTokenImplementation);
            }
        }
    }

    function setGcFeePercent(uint16 newGcFeePercent) external onlyOwner {
        _gcFeePercent = newGcFeePercent;
        emit GcFeePercentChanged(newGcFeePercent);
    }

    function getGCFeePercent() external view override returns (uint16) {
        return _gcFeePercent;
    }

    function enablePaymentToken(address token) external onlyOwner {
        require(token != address(0), Errors.ES_INVALID_PAYMENT_TOKEN_ADDRESS);
        _enablePaymentToken(token);
    }

    function disablePaymentToken(address token) external onlyOwner {
        require(_paymentTokensIndex[token] != 0, Errors.ES_UNREGISTERED_PAYMENT_TOKEN);

        if (_paymentTokensIndex[token] > 0) {
            _paymentTokensIndex[token] = -_paymentTokensIndex[token];
            emit PaymentTokenChange(token, false);
        }
    }

    function _enablePaymentToken(address token) internal {
        if (_paymentTokensIndex[token] == 0) {
            _paymentTokens.push(token);
            _paymentTokensIndex[token] = int16(uint16(_paymentTokens.length));
            emit PaymentTokenChange(token, true);
        } else if (_paymentTokensIndex[token] < 0) {
            _paymentTokensIndex[token] = -_paymentTokensIndex[token];
            emit PaymentTokenChange(token, true);
        }
    }

    function _getStreamingReserve() internal view returns (uint112) {
        return
            _streamingReserveTarget -
            ExpMath.halfLife(
                _streamingReserveUpdated,
                _streamingReserveTarget - _streamingReserve,
                _streamingReserveHalvingPeriod,
                uint32(block.timestamp)
            );
    }

    function _increaseStreamingReserveTarget(uint112 delta) internal {
        _streamingReserve = _getStreamingReserve();
        _streamingReserveTarget += delta;
        _streamingReserveUpdated = uint32(block.timestamp);
        emit StreamingReserveChanged(_streamingReserve, _streamingReserveTarget);
    }

    function _flushStreamingReserve() internal returns (uint112 streamingReserve) {
        streamingReserve = _getStreamingReserve();

        _streamingReserve = 0;
        _streamingReserveTarget -= streamingReserve;
        _streamingReserveUpdated = uint32(block.timestamp);
        emit StreamingReserveChanged(_streamingReserve, _streamingReserveTarget);
    }

    function _getAvailableReserve(uint256 reserve) internal view returns (uint256) {
        return reserve - _usedReserve;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IPowerTokenStorage.sol";

interface IPowerToken is IERC20Metadata, IPowerTokenStorage {
    function forceTransfer(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function notifyNewRental(uint256 rentalTokenId) external;

    function estimateRentalFee(
        address paymentToken,
        uint112 rentalAmount,
        uint32 rentalPeriod
    )
        external
        view
        returns (
            uint112 poolFee,
            uint112 serviceFee,
            uint112 gcFee
        );
}

// SPDX-License-Identifier: MIT

// IQ Protocol. Risk-free collateral-less utility renting
// https://iq.space/docs/iq-yellow-paper.pdf
// (C) Blockvis & PARSIQ
// 🖖 Stake strong!

pragma solidity 0.8.4;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "./interfaces/IConverter.sol";
import "./interfaces/IEnterprise.sol";
import "./interfaces/IStakeToken.sol";
import "./interfaces/IRentalToken.sol";
import "./interfaces/IPowerToken.sol";
import "./libs/Errors.sol";

contract EnterpriseFactory {
    event EnterpriseDeployed(
        address indexed creator,
        address indexed enterpriseToken,
        string name,
        string baseUri,
        address deployed
    );

    address private immutable _enterpriseImpl;
    address private immutable _powerTokenImpl;
    address private immutable _stakeTokenImpl;
    address private immutable _rentalTokenImpl;

    constructor(
        address enterpriseImpl,
        address powerTokenImpl,
        address stakeTokenImpl,
        address rentalTokenImpl
    ) {
        require(enterpriseImpl != address(0), Errors.EF_INVALID_ENTERPRISE_IMPLEMENTATION_ADDRESS);
        require(powerTokenImpl != address(0), Errors.EF_INVALID_POWER_TOKEN_IMPLEMENTATION_ADDRESS);
        require(stakeTokenImpl != address(0), Errors.EF_INVALID_STAKE_TOKEN_IMPLEMENTATION_ADDRESS);
        require(rentalTokenImpl != address(0), Errors.EF_INVALID_RENTAL_TOKEN_IMPLEMENTATION_ADDRESS);
        _enterpriseImpl = enterpriseImpl;
        _powerTokenImpl = powerTokenImpl;
        _stakeTokenImpl = stakeTokenImpl;
        _rentalTokenImpl = rentalTokenImpl;
    }

    function deploy(
        string calldata name,
        IERC20Metadata enterpriseToken,
        string calldata baseUri,
        uint16 gcFeePercent,
        IConverter converter
    ) external returns (IEnterprise) {
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        IEnterprise enterprise = IEnterprise(deployProxy(_enterpriseImpl, proxyAdmin));
        proxyAdmin.transferOwnership(address(enterprise));
        {
            enterprise.initialize(name, baseUri, gcFeePercent, converter, proxyAdmin, msg.sender);
        }
        {
            IStakeToken stakeToken = _deployStakeToken(enterpriseToken.symbol(), enterprise, proxyAdmin);
            IRentalToken rentalToken = _deployRentalToken(enterpriseToken.symbol(), enterprise, proxyAdmin);
            enterprise.initializeTokens(enterpriseToken, stakeToken, rentalToken);
        }

        emit EnterpriseDeployed(msg.sender, address(enterpriseToken), name, baseUri, address(enterprise));

        return enterprise;
    }

    function deployProxy(address implementation, ProxyAdmin admin) internal returns (address) {
        return address(new TransparentUpgradeableProxy(implementation, address(admin), ""));
    }

    function deployService(ProxyAdmin admin) external returns (IPowerToken) {
        return IPowerToken(deployProxy(_powerTokenImpl, admin));
    }

    function _deployStakeToken(
        string memory symbol,
        IEnterprise enterprise,
        ProxyAdmin proxyAdmin
    ) internal returns (IStakeToken) {
        string memory stakeTokenName = string(abi.encodePacked("Staking ", symbol));
        string memory stakeTokenSymbol = string(abi.encodePacked("s", symbol));

        IStakeToken stakeToken = IStakeToken(deployProxy(_stakeTokenImpl, proxyAdmin));
        stakeToken.initialize(stakeTokenName, stakeTokenSymbol, enterprise);
        return stakeToken;
    }

    function _deployRentalToken(
        string memory symbol,
        IEnterprise enterprise,
        ProxyAdmin proxyAdmin
    ) internal returns (IRentalToken) {
        string memory rentalTokenName = string(abi.encodePacked("Rental ", symbol));
        string memory rentalTokenSymbol = string(abi.encodePacked("r", symbol));

        IRentalToken rentalToken = IRentalToken(deployProxy(_rentalTokenImpl, proxyAdmin));
        rentalToken.initialize(rentalTokenName, rentalTokenSymbol, enterprise);
        return rentalToken;
    }

    function getEnterpriseImpl() external view returns (address) {
        return _enterpriseImpl;
    }

    function getPowerTokenImpl() external view returns (address) {
        return _powerTokenImpl;
    }

    function getStakeTokenImpl() external view returns (address) {
        return _stakeTokenImpl;
    }

    function getRentalTokenImpl() external view returns (address) {
        return _rentalTokenImpl;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "../libs/Errors.sol";

library ExpMath {
    uint256 private constant ONE = 1 << 144;
    uint256 private constant LOG_ONE_HALF = 15457698658747239244624307340191628289589491; // log(0.5) * 2 ** 144

    function halfLife(
        uint32 t0,
        uint112 c0,
        uint32 t12,
        uint32 t
    ) internal pure returns (uint112) {
        unchecked {
            require(t >= t0, Errors.EXP_INVALID_PERIOD);

            t -= t0;
            c0 >>= t / t12;
            t %= t12;
            if (t == 0 || c0 == 0) return c0;

            uint256 sum = 0;
            uint256 z = c0;
            uint256 x = (LOG_ONE_HALF * t) / t12;
            uint256 i = ONE;

            while (z != 0) {
                sum += z;
                z = (z * x) / i;
                i += ONE;
                sum -= z;
                z = (z * x) / i;
                i += ONE;
            }

            return uint112(sum);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IEnterprise.sol";

interface IPowerTokenStorage {
    function initialize(
        IEnterprise enterprise,
        IERC20Metadata baseToken,
        uint112 baseRate,
        uint96 minGCFee,
        uint16 serviceFeePercent,
        uint32 energyGapHalvingPeriod,
        uint16 index,
        uint32 minRentalPeriod,
        uint32 maxRentalPeriod,
        bool swappingEnabled
    ) external;

    function isAllowedRentalPeriod(uint32 period) external view returns (bool);

    function getIndex() external view returns (uint16);

    function isSwappingEnabled() external view returns (bool);

    function isTransferEnabled() external view returns (bool);
}

// SPDX-License-Identifier: MIT

// IQ Protocol. Risk-free collateral-less utility renting
// https://iq.space/docs/iq-yellow-paper.pdf
// (C) Blockvis & PARSIQ
// 🖖 Stake strong!

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./math/ExpMath.sol";
import "./token/ERC20.sol";
import "./interfaces/IPowerToken.sol";
import "./PowerTokenStorage.sol";
import "./libs/Errors.sol";

contract PowerToken is IPowerToken, PowerTokenStorage, ERC20 {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    uint256 internal constant ONE = 1 << 64;

    function mint(address to, uint256 value) external override onlyEnterprise {
        _mint(to, value, true);
    }

    function burnFrom(address account, uint256 value) external override onlyEnterprise {
        _burn(account, value, true);
    }

    function availableBalanceOf(address account) external view returns (uint256) {
        return balanceOf(account) - _states[account].lockedBalance;
    }

    function energyAt(address who, uint32 timestamp) external view returns (uint112) {
        State memory state = _states[who];
        return _getEnergy(state, who, timestamp);
    }

    function _getEnergy(
        State memory state,
        address who,
        uint32 timestamp
    ) internal view returns (uint112) {
        uint112 balance = uint112(balanceOf(who));
        if (balance > state.energy) {
            return
                balance - ExpMath.halfLife(state.timestamp, balance - state.energy, _energyGapHalvingPeriod, timestamp);
        } else {
            return
                balance + ExpMath.halfLife(state.timestamp, state.energy - balance, _energyGapHalvingPeriod, timestamp);
        }
    }

    function forceTransfer(
        address from,
        address to,
        uint256 amount
    ) external override onlyEnterprise returns (bool) {
        _transfer(from, to, amount, true);
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 value,
        bool isRentedTokenTransfer
    ) internal override {
        bool isMinting = (from == address(0));
        bool isBurning = (to == address(0));
        require(isMinting || isBurning || _transferEnabled, Errors.PT_TRANSFER_DISABLED);

        uint32 timestamp = uint32(block.timestamp);
        if (!isMinting) {
            State memory fromState = _states[from];
            fromState.energy = _getEnergy(fromState, from, timestamp);
            fromState.timestamp = timestamp;
            if (!isRentedTokenTransfer) {
                require(balanceOf(from) - value >= fromState.lockedBalance, Errors.PT_INSUFFICIENT_AVAILABLE_BALANCE);
            } else {
                fromState.lockedBalance -= uint112(value);
            }
            _states[from] = fromState;
        }

        if (!isBurning) {
            State memory toState = _states[to];
            toState.energy = _getEnergy(toState, to, timestamp);
            toState.timestamp = timestamp;
            if (isRentedTokenTransfer) {
                toState.lockedBalance += uint112(value);
            }
            _states[to] = toState;
        }
    }

    function getInfo()
        external
        view
        returns (
            string memory name,
            string memory symbol,
            IERC20Metadata baseToken,
            uint112 baseRate,
            uint96 minGCFee,
            uint16 serviceFeePercent,
            uint32 energyGapHalvingPeriod,
            uint16 index,
            uint32 minRentalPeriod,
            uint32 maxRentalPeriod,
            bool swappingEnabled,
            bool transferEnabled
        )
    {
        return (
            this.name(),
            this.symbol(),
            _baseToken,
            _baseRate,
            _minGCFee,
            _serviceFeePercent,
            _energyGapHalvingPeriod,
            _index,
            _minRentalPeriod,
            _maxRentalPeriod,
            _swappingEnabled,
            _transferEnabled
        );
    }

    /**
     * @dev Swaps enterprise tokens to power tokens
     *
     * One must approve sufficient amount of enterprise tokens to
     * corresponding PowerToken address before calling this function
     */
    function swapIn(uint256 amount) external returns (bool) {
        require(_swappingEnabled, Errors.E_SWAPPING_DISABLED);

        getEnterprise().getEnterpriseToken().safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount, false);
        return true;
    }

    /**
     * @dev Swaps power tokens back to enterprise tokens
     */
    function swapOut(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount, false);
        getEnterprise().getEnterpriseToken().safeTransfer(msg.sender, amount);
        return true;
    }

    function estimateRentalFee(
        address paymentToken,
        uint112 rentalAmount,
        uint32 rentalPeriod
    )
        external
        view
        override
        returns (
            uint112 poolFee,
            uint112 serviceFee,
            uint112 gcFee
        )
    {
        require(getEnterprise().isSupportedPaymentToken(paymentToken), Errors.E_UNSUPPORTED_PAYMENT_TOKEN);
        require(isAllowedRentalPeriod(rentalPeriod), Errors.E_RENTAL_PERIOD_OUT_OF_RANGE);

        uint112 rentalBaseFeeInBaseTokens = estimateRentalBaseFee(rentalAmount, rentalPeriod);
        uint256 rentalBaseFee = getEnterprise().getConverter().estimateConvert(
            _baseToken,
            rentalBaseFeeInBaseTokens,
            IERC20(paymentToken)
        );

        serviceFee = uint112((rentalBaseFee * _serviceFeePercent) / 10_000);
        poolFee = uint112(rentalBaseFee - serviceFee);
        gcFee = _estimateGCFee(paymentToken, rentalBaseFee);
    }

    function _estimateGCFee(address paymentToken, uint256 amount) internal view returns (uint112) {
        uint112 gcFeeAmount = uint112((amount * getEnterprise().getGCFeePercent()) / 10_000);
        uint112 minGcFee = uint112(
            getEnterprise().getConverter().estimateConvert(_baseToken, _minGCFee, IERC20(paymentToken))
        );
        return gcFeeAmount < minGcFee ? minGcFee : gcFeeAmount;
    }

    function notifyNewRental(uint256 rentalTokenId) external override {}

    /**
     * @dev
     * f(x) = ((1 - t) * k) / (x - t) + (1 - k)
     * h(x) = x * f((T - x) / T)
     * g(x) = h(U + x) - h(U)
     */
    function estimateRentalBaseFee(uint112 rentalAmount, uint32 rentalPeriod) internal view returns (uint112) {
        IEnterprise enterprise = getEnterprise();
        uint256 reserve = enterprise.getReserve();
        uint256 usedReserve = enterprise.getUsedReserve();
        uint256 availableReserve = reserve - usedReserve;
        if (availableReserve <= rentalAmount) return type(uint112).max;

        int8 decimalsDiff = int8(enterprise.getEnterpriseToken().decimals()) - int8(_baseToken.decimals());

        (uint256 pole, uint256 slope) = enterprise.getBondingCurve();

        uint256 baseFee = g(rentalAmount, pole, slope, reserve, usedReserve) * rentalPeriod;

        if (decimalsDiff > 0) {
            baseFee = ((baseFee * _baseRate) / 10**uint8(decimalsDiff)) >> 64;
        } else if (decimalsDiff < 0) {
            baseFee = ((baseFee * _baseRate) * 10**(uint8(-decimalsDiff))) >> 64;
        } else {
            baseFee = (baseFee * _baseRate) >> 64;
        }
        return uint112(baseFee);
    }

    function g(
        uint128 x,
        uint256 pole,
        uint256 slope,
        uint256 reserve,
        uint256 usedReserve
    ) internal pure returns (uint256) {
        return h(usedReserve + x, pole, slope, reserve) - h(usedReserve, pole, slope, reserve);
    }

    function h(
        uint256 x,
        uint256 pole,
        uint256 slope,
        uint256 reserve
    ) internal pure returns (uint256) {
        return (x * f(uint128(((reserve - x) << 64) / reserve), pole, slope)) >> 64;
    }

    function f(
        uint256 x,
        uint256 pole,
        uint256 slope
    ) internal pure returns (uint256) {
        if (x <= pole) return type(uint128).max;
        return (((ONE - pole) * slope)) / (x - pole) + (ONE - slope);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../libs/Errors.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external {
        require(bytes(_name).length == 0, Errors.ALREADY_INITIALIZED);
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount, false);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount, false);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, Errors.ERC20_TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE);
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, Errors.ERC20_DECREASED_ALLOWANCE_BELOW_ZERO);
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount,
        bool isRentedTokenTransfer
    ) internal virtual {
        require(sender != address(0), Errors.ERC20_TRANSFER_FROM_THE_ZERO_ADDRESS);
        require(recipient != address(0), Errors.ERC20_TRANSFER_TO_THE_ZERO_ADDRESS);

        _beforeTokenTransfer(sender, recipient, amount, isRentedTokenTransfer);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, Errors.ERC20_TRANSFER_AMOUNT_EXCEEDS_BALANCE);
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(
        address account,
        uint256 amount,
        bool isRentedTokenTransfer
    ) internal virtual {
        require(account != address(0), Errors.ERC20_MINT_TO_THE_ZERO_ADDRESS);

        _beforeTokenTransfer(address(0), account, amount, isRentedTokenTransfer);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(
        address account,
        uint256 amount,
        bool isRentedTokenTransfer
    ) internal virtual {
        require(account != address(0), Errors.ERC20_BURN_FROM_THE_ZERO_ADDRESS);

        _beforeTokenTransfer(account, address(0), amount, isRentedTokenTransfer);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, Errors.ERC20_BURN_AMOUNT_EXCEEDS_BALANCE);
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), Errors.ERC20_APPROVE_FROM_THE_ZERO_ADDRESS);
        require(spender != address(0), Errors.ERC20_APPROVE_TO_THE_ZERO_ADDRESS);

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount,
        bool isRentedTokenTransfer
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IEnterprise.sol";
import "./interfaces/IPowerTokenStorage.sol";
import "./EnterpriseOwnable.sol";
import "./libs/Errors.sol";

// This contract cannot be extended anymore. If you need to add state variables to PowerToken
// consider creating PowerTokenStorage2 or similar contract, make PowerToken inherit it
// and add state variables there
abstract contract PowerTokenStorage is EnterpriseOwnable, IPowerTokenStorage {
    uint16 internal constant MAX_SERVICE_FEE_PERCENT = 5000; // 50%
    struct State {
        uint112 lockedBalance;
        uint112 energy;
        uint32 timestamp;
    }
    // slot 1, 0 bytes left
    uint112 internal _baseRate; // base rate for price calculations, nominated in baseToken
    uint96 internal _minGCFee; // fee for collecting expired PowerTokens
    uint32 internal _energyGapHalvingPeriod; // fixed, not updatable
    uint16 internal _index; // index in _powerTokens array. Not updatable
    // slot 2, 0 bytes left
    IERC20Metadata internal _baseToken;
    uint32 internal _minRentalPeriod;
    uint32 internal _maxRentalPeriod;
    uint16 internal _serviceFeePercent; // 100 is 1%, 10_000 is 100%. Fee which goes to the enterprise to cover service operational costs for this service
    bool internal _swappingEnabled; // allows swapping enterprise tokens into PowerTokens
    bool internal _transferEnabled; // allows transfers of PowerTokens

    mapping(address => State) internal _states;

    event BaseRateChanged(uint112 baseRate, address baseToken, uint96 minGCFee);
    event ServiceFeePercentChanged(uint16 percent);
    event RentalPeriodLimitsChanged(uint32 minRentalPeriod, uint32 maxRentalPeriod);
    event SwappingEnabled();
    event TransferEnabled();

    function initialize(
        IEnterprise enterprise,
        IERC20Metadata baseToken,
        uint112 baseRate,
        uint96 minGCFee,
        uint16 serviceFeePercent,
        uint32 energyGapHalvingPeriod,
        uint16 index,
        uint32 minRentalPeriod,
        uint32 maxRentalPeriod,
        bool swappingEnabled
    ) external override {
        require(_energyGapHalvingPeriod == 0, Errors.ALREADY_INITIALIZED);
        require(energyGapHalvingPeriod > 0, Errors.E_SERVICE_ENERGY_GAP_HALVING_PERIOD_NOT_GT_0);
        require(maxRentalPeriod > 0, Errors.PT_INVALID_MAX_RENTAL_PERIOD);
        require(minRentalPeriod <= maxRentalPeriod, Errors.ES_INVALID_RENTAL_PERIOD_RANGE);

        EnterpriseOwnable.initialize(enterprise);
        _baseToken = baseToken;
        _baseRate = baseRate;
        _minGCFee = minGCFee;
        _serviceFeePercent = serviceFeePercent;
        _energyGapHalvingPeriod = energyGapHalvingPeriod;
        _index = index;
        _minRentalPeriod = minRentalPeriod;
        _maxRentalPeriod = maxRentalPeriod;
        _swappingEnabled = swappingEnabled;

        emit BaseRateChanged(baseRate, address(baseToken), minGCFee);
        emit ServiceFeePercentChanged(serviceFeePercent);
        emit RentalPeriodLimitsChanged(minRentalPeriod, maxRentalPeriod);
        if (swappingEnabled) {
            emit SwappingEnabled();
        }
    }

    function setBaseRate(
        uint112 baseRate,
        IERC20Metadata baseToken,
        uint96 minGCFee
    ) external onlyEnterpriseOwner {
        require(address(_baseToken) != address(0), Errors.ES_INVALID_BASE_TOKEN_ADDRESS);

        _baseRate = baseRate;
        _baseToken = baseToken;
        _minGCFee = minGCFee;

        emit BaseRateChanged(baseRate, address(baseToken), minGCFee);
    }

    function setServiceFeePercent(uint16 newServiceFeePercent) external onlyEnterpriseOwner {
        require(newServiceFeePercent <= MAX_SERVICE_FEE_PERCENT, Errors.ES_MAX_SERVICE_FEE_PERCENT_EXCEEDED);

        _serviceFeePercent = newServiceFeePercent;
        emit ServiceFeePercentChanged(newServiceFeePercent);
    }

    function setRentalPeriodLimits(uint32 minRentalPeriod, uint32 maxRentalPeriod) external onlyEnterpriseOwner {
        require(minRentalPeriod <= maxRentalPeriod, Errors.ES_INVALID_RENTAL_PERIOD_RANGE);

        _minRentalPeriod = minRentalPeriod;
        _maxRentalPeriod = maxRentalPeriod;
        emit RentalPeriodLimitsChanged(minRentalPeriod, maxRentalPeriod);
    }

    function enableSwappingForever() external onlyEnterpriseOwner {
        require(!_swappingEnabled, Errors.ES_SWAPPING_ALREADY_ENABLED);

        _swappingEnabled = true;
        emit SwappingEnabled();
    }

    function enableTransferForever() external onlyEnterpriseOwner {
        require(!_transferEnabled, Errors.ES_TRANSFER_ALREADY_ENABLED);

        _transferEnabled = true;
        emit TransferEnabled();
    }

    function isAllowedRentalPeriod(uint32 period) public view override returns (bool) {
        return _minRentalPeriod <= period && period <= _maxRentalPeriod;
    }

    function getBaseRate() external view returns (uint112) {
        return _baseRate;
    }

    function getMinGCFee() external view returns (uint96) {
        return _minGCFee;
    }

    function getEnergyGapHalvingPeriod() external view returns (uint32) {
        return _energyGapHalvingPeriod;
    }

    function getIndex() external view override returns (uint16) {
        return _index;
    }

    function getBaseToken() external view returns (IERC20Metadata) {
        return _baseToken;
    }

    function getMinRentalPeriod() external view returns (uint32) {
        return _minRentalPeriod;
    }

    function getMaxRentalPeriod() external view returns (uint32) {
        return _maxRentalPeriod;
    }

    function getServiceFeePercent() external view returns (uint16) {
        return _serviceFeePercent;
    }

    function getState(address account) external view returns (State memory) {
        return _states[account];
    }

    function isSwappingEnabled() external view override returns (bool) {
        return _swappingEnabled;
    }

    function isTransferEnabled() external view override returns (bool) {
        return _transferEnabled;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/IEnterprise.sol";
import "./libs/Errors.sol";

/**
 * @dev Ownable contract with `initialize` function instead of constructor. Primary usage is for proxies like ERC-1167 with no constructor.
 */
abstract contract EnterpriseOwnable {
    IEnterprise private _enterprise;

    /**
     * @dev Initializes the enterprise of the contract. The inheritor of this contract *MUST* ensure this method is not called twice.
     */
    function initialize(IEnterprise enterprise) public {
        require(address(_enterprise) == address(0), Errors.ALREADY_INITIALIZED);
        require(address(enterprise) != address(0), Errors.EO_INVALID_ENTERPRISE_ADDRESS);
        _enterprise = IEnterprise(enterprise);
    }

    /**
     * @dev Returns the address of the current enterprise.
     */
    function getEnterprise() public view returns (IEnterprise) {
        return _enterprise;
    }

    /**
     * @dev Throws if called by any account other than the enterprise.
     */
    modifier onlyEnterprise() {
        require(address(_enterprise) == msg.sender, Errors.CALLER_NOT_ENTERPRISE);
        _;
    }

    modifier onlyEnterpriseOwner() {
        require(_enterprise.owner() == msg.sender, Errors.CALLER_NOT_OWNER);
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./EnterpriseOwnable.sol";
import "./token/ERC721Enumerable.sol";
import "./interfaces/IStakeTokenStorage.sol";

abstract contract StakeTokenStorage is IStakeTokenStorage, EnterpriseOwnable, ERC721Enumerable {
    uint256 internal _tokenIdTracker;

    function initialize(
        string memory name,
        string memory symbol,
        IEnterprise enterprise
    ) external override {
        EnterpriseOwnable.initialize(enterprise);
        ERC721.initialize(name, symbol);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./ERC721.sol";

/**
 * This is a copy of OpenZeppelin ERC721Enumerable contract
 */
/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), Errors.ERC721ENUM_OWNER_INDEX_OUT_OF_BOUNDS);
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) external view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), Errors.ERC721ENUM_GLOBAL_INDEX_OUT_OF_BOUNDS);
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

// IQ Protocol. Risk-free collateral-less utility renting
// https://iq.space/docs/iq-yellow-paper.pdf
// (C) Blockvis & PARSIQ
// 🖖 Stake strong!

pragma solidity 0.8.4;

import "./interfaces/IStakeToken.sol";
import "./interfaces/IEnterprise.sol";
import "./StakeTokenStorage.sol";

contract StakeToken is StakeTokenStorage, IStakeToken {
    function getNextTokenId() public view override returns (uint256) {
        return uint256(keccak256(abi.encodePacked("s", address(this), _tokenIdTracker)));
    }

    function _baseURI() internal view override returns (string memory) {
        string memory baseURI = getEnterprise().getBaseUri();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "stake/")) : "";
    }

    function mint(address to) external override onlyEnterprise returns (uint256) {
        uint256 tokenId = getNextTokenId();
        _safeMint(to, tokenId);
        _tokenIdTracker++;
        return tokenId;
    }

    function burn(uint256 tokenId) external override onlyEnterprise {
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IConverter.sol";

/**
 * Mock converter, for testing purposes only
 * DO NOT USE IN PRODUCTION!!!
 */
contract MockConverter is IConverter {
    mapping(IERC20 => mapping(IERC20 => uint256)) rates;

    function estimateConvert(
        IERC20 source,
        uint256 amount,
        IERC20 target
    ) external view override returns (uint256) {
        if (address(source) == address(target)) return amount;

        return _estimateConvert(source, amount, target);
    }

    function _estimateConvert(
        IERC20 source,
        uint256 amount,
        IERC20 target
    ) internal view returns (uint256) {
        uint256 rate = rates[source][target];

        uint256 source_one = 10**IERC20Metadata(address(source)).decimals();

        return
            normalize(IERC20Metadata(address(source)), IERC20Metadata(address(target)), (amount * source_one) / rate);
    }

    /**
     * @dev Converts `source` tokens to `target` tokens.
     * Converted tokens must be on `msg.sender` address after exiting this function
     */
    function convert(
        IERC20 source,
        uint256 amount,
        IERC20 target
    ) external override returns (uint256) {
        if (address(source) == address(target)) return amount;

        uint256 converted = _estimateConvert(source, amount, target);

        source.transferFrom(msg.sender, address(this), amount);
        target.transfer(msg.sender, converted);

        return converted;
    }

    function setRate(
        IERC20Metadata source,
        IERC20Metadata target,
        uint256 rate
    ) public {
        rates[source][target] = rate;

        uint256 source_one = 10**source.decimals();

        uint256 inverseRate = normalize(source, target, (source_one * 10**source.decimals()) / rate);

        rates[target][source] = inverseRate;
    }

    function normalize(
        IERC20Metadata source,
        IERC20Metadata target,
        uint256 rate
    ) internal view returns (uint256) {
        if (source.decimals() > target.decimals()) {
            return rate / 10**(source.decimals() - target.decimals());
        } else if (source.decimals() < target.decimals()) {
            return rate * 10**(target.decimals() - source.decimals());
        }
        return rate;
    }
}

// SPDX-License-Identifier: MIT

// IQ Protocol. Risk-free collateral-less utility renting
// https://iq.space/docs/iq-yellow-paper.pdf
// (C) Blockvis & PARSIQ
// 🖖 Stake strong!

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./token/ERC20.sol";
import "./interfaces/IStakeToken.sol";
import "./interfaces/IRentalToken.sol";
import "./interfaces/IConverter.sol";
import "./interfaces/IPowerToken.sol";
import "./interfaces/IEnterprise.sol";
import "./EnterpriseStorage.sol";

contract Enterprise is EnterpriseStorage, IEnterprise {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    enum StakeOperation {
        Reward,
        Stake,
        Unstake,
        Increase,
        Decrease
    }

    event StakeChanged(
        uint256 indexed stakeTokenId,
        address indexed staker,
        StakeOperation indexed operation,
        uint256 amountDelta,
        uint256 amount,
        uint256 sharesDelta,
        uint256 shares,
        uint256 totalShares,
        uint256 totalReserve,
        uint256 totalUsedReserve
    );

    event ServiceRegistered(address indexed powerToken);

    event Rented(
        uint256 indexed rentalTokenId,
        address indexed renter,
        address indexed powerToken,
        address paymentToken,
        uint112 rentalAmount,
        uint112 poolFee,
        uint112 serviceFee,
        uint112 gcFee,
        uint32 startTime,
        uint32 endTime,
        uint32 renterOnlyReturnTime,
        uint32 enterpriseOnlyCollectionTime,
        uint256 totalReserve,
        uint256 totalUsedReserve
    );

    event RentalPeriodExtended(
        uint256 indexed rentalTokenId,
        address indexed renter,
        address paymentToken,
        uint112 poolFee,
        uint112 serviceFee,
        uint32 endTime,
        uint32 renterOnlyReturnTime,
        uint32 enterpriseOnlyCollectionTime
    );

    event RentalReturned(
        uint256 indexed rentalTokenId,
        address indexed returner,
        address indexed powerToken,
        uint112 rentalAmount,
        uint112 gcRewardAmount,
        address gcRewardToken,
        uint256 totalReserve,
        uint256 totalUsedReserve
    );

    function registerService(
        string memory serviceName,
        string memory serviceSymbol,
        uint32 energyGapHalvingPeriod,
        uint112 baseRate,
        address baseToken,
        uint16 serviceFeePercent,
        uint32 minRentalPeriod,
        uint32 maxRentalPeriod,
        uint96 minGCFee,
        bool swappingEnabledForever
    ) external onlyOwner whenNotShutdown {
        require(address(baseToken) != address(0), Errors.E_INVALID_BASE_TOKEN_ADDRESS);
        require(_powerTokens.length < type(uint16).max, Errors.E_SERVICE_LIMIT_REACHED);

        // Deploy new power token.
        IPowerToken powerToken = _factory.deployService(getProxyAdmin());
        {
            string memory tokenSymbol = _enterpriseToken.symbol();
            string memory powerTokenSymbol = string(abi.encodePacked(tokenSymbol, " ", serviceSymbol));
            ERC20(address(powerToken)).initialize(serviceName, powerTokenSymbol, _enterpriseToken.decimals());
        }

        // Configure service parameters.
        powerToken.initialize(
            this,
            IERC20Metadata(baseToken),
            baseRate,
            minGCFee,
            serviceFeePercent,
            energyGapHalvingPeriod,
            uint16(_powerTokens.length),
            minRentalPeriod,
            maxRentalPeriod,
            swappingEnabledForever
        );

        // Complete service registration.
        _powerTokens.push(powerToken);
        _registeredPowerTokens[address(powerToken)] = true;

        emit ServiceRegistered(address(powerToken));
    }

    function rent(
        address powerToken,
        address paymentToken,
        uint112 rentalAmount,
        uint32 rentalPeriod,
        uint256 maxPayment
    ) external whenNotShutdown {
        require(rentalAmount > 0, Errors.E_INVALID_RENTAL_AMOUNT);
        require(_registeredPowerTokens[powerToken], Errors.UNREGISTERED_POWER_TOKEN);
        require(rentalAmount <= getAvailableReserve(), Errors.E_INSUFFICIENT_LIQUIDITY);

        // Estimate rental fee.
        (uint112 poolFee, uint112 serviceFee, uint112 gcFee) = IPowerToken(powerToken).estimateRentalFee(
            paymentToken,
            rentalAmount,
            rentalPeriod
        );
        {
            // Ensure no rental fee payment slippage.
            // GC fee does not go to the pool but must be accounted for slippage calculation.
            require(poolFee + serviceFee + gcFee <= maxPayment, Errors.E_RENTAL_PAYMENT_SLIPPAGE);

            // Handle rental fee transfer and distribution.
            handleRentalPayment(IERC20(paymentToken), serviceFee, poolFee);

            // Transfer GC fee to the rental token contract.
            IERC20(paymentToken).safeTransferFrom(msg.sender, address(_rentalToken), gcFee);

            // Update used reserve.
            _usedReserve += rentalAmount;
        }

        // Calculate rental agreement timestamps.
        uint32 endTime = uint32(block.timestamp) + rentalPeriod;
        uint32 renterOnlyReturnTime = endTime + _renterOnlyReturnPeriod;
        uint32 enterpriseOnlyCollectionTime = endTime + _enterpriseOnlyCollectionPeriod;

        // Precalculate rental token ID to associate rental agreement.
        uint256 rentalTokenId = _rentalToken.getNextTokenId();

        _rentalAgreements[rentalTokenId] = RentalAgreement(
            rentalAmount,
            IPowerToken(powerToken).getIndex(),
            uint32(block.timestamp),
            endTime,
            renterOnlyReturnTime,
            enterpriseOnlyCollectionTime,
            gcFee,
            uint16(getPaymentTokenIndex(paymentToken))
        );

        // Mint rental token to the renter address.
        // This also mints corresponding amount of PowerTokens.
        assert(_rentalToken.mint(msg.sender) == rentalTokenId);

        // Notify power token contract about new rental.
        IPowerToken(powerToken).notifyNewRental(rentalTokenId);

        emit Rented(
            rentalTokenId,
            msg.sender,
            powerToken,
            paymentToken,
            rentalAmount,
            poolFee,
            serviceFee,
            gcFee,
            uint32(block.timestamp),
            endTime,
            renterOnlyReturnTime,
            enterpriseOnlyCollectionTime,
            getReserve(),
            _usedReserve
        );
    }

    function extendRentalPeriod(
        uint256 rentalTokenId,
        address paymentToken,
        uint32 rentalPeriod,
        uint256 maxPayment
    ) external whenNotShutdown {
        RentalAgreement storage rentalAgreement = _rentalAgreements[rentalTokenId];
        require(rentalAgreement.rentalAmount > 0, Errors.E_INVALID_RENTAL_TOKEN_ID);
        IPowerToken powerToken = _powerTokens[rentalAgreement.powerTokenIndex];
        require(rentalAgreement.endTime + rentalPeriod >= block.timestamp, Errors.E_INVALID_RENTAL_PERIOD);

        // Simulate rental return to ensure correct reserves during new rental fee calculation.
        uint256 usedReserve = _usedReserve;
        _usedReserve = usedReserve - rentalAgreement.rentalAmount;
        // Estimate new rental fee.
        (uint112 poolFee, uint112 serviceFee, ) = powerToken.estimateRentalFee(
            paymentToken,
            rentalAgreement.rentalAmount,
            rentalPeriod
        );

        // Simulate renting.
        _usedReserve = usedReserve;

        // Ensure no rental fee payment slippage.
        require(poolFee + serviceFee <= maxPayment, Errors.E_RENTAL_PAYMENT_SLIPPAGE);

        // Handle rental payment transfer and distribution.
        handleRentalPayment(IERC20(paymentToken), serviceFee, poolFee);

        // Calculate new rental agreement timestamps.
        uint32 newEndTime = rentalAgreement.endTime + rentalPeriod;
        uint32 newRenterOnlyReturnTime = newEndTime + _renterOnlyReturnPeriod;
        uint32 newEnterpriseOnlyCollectionTime = newEndTime + _enterpriseOnlyCollectionPeriod;

        // Update rental agreement.
        rentalAgreement.endTime = newEndTime;
        rentalAgreement.renterOnlyReturnTime = newRenterOnlyReturnTime;
        rentalAgreement.enterpriseOnlyCollectionTime = newEnterpriseOnlyCollectionTime;

        // Notify power token contract about new rental.
        powerToken.notifyNewRental(rentalTokenId);

        emit RentalPeriodExtended(
            rentalTokenId,
            msg.sender,
            paymentToken,
            poolFee,
            serviceFee,
            newEndTime,
            newRenterOnlyReturnTime,
            newEnterpriseOnlyCollectionTime
        );
    }

    function handleRentalPayment(
        IERC20 paymentToken,
        uint256 serviceFee,
        uint112 poolFee
    ) internal {
        uint256 rentalFee;
        unchecked {
            rentalFee = serviceFee + poolFee;
        }
        // Transfer base rental fee to the enterprise.
        paymentToken.safeTransferFrom(msg.sender, address(this), rentalFee);
        IERC20 enterpriseToken = _enterpriseToken;

        // Initially assume rental fee payment is made in enterprise tokens.
        uint256 serviceFeeInEnterpriseTokens = serviceFee;
        uint112 poolFeeInEnterpriseTokens = poolFee;

        // Should the rental fee payment be made in tokens other than enterprise tokens,
        // the payment amount gets converted to enterprise tokens automatically.
        if (address(paymentToken) != address(enterpriseToken)) {
            paymentToken.approve(address(_converter), rentalFee);
            uint256 rentalFeeInEnterpriseTokens = _converter.convert(paymentToken, rentalFee, enterpriseToken);
            serviceFeeInEnterpriseTokens = (serviceFee * rentalFeeInEnterpriseTokens) / rentalFee;
            poolFeeInEnterpriseTokens = uint112(rentalFeeInEnterpriseTokens - serviceFeeInEnterpriseTokens);
        }

        // Transfer service fee (enterprise tokens) to the enterprise wallet.
        enterpriseToken.safeTransfer(_enterpriseWallet, serviceFeeInEnterpriseTokens);
        // Update streaming target.
        _increaseStreamingReserveTarget(poolFeeInEnterpriseTokens);
    }

    function returnRental(uint256 rentalTokenId) external {
        RentalAgreement memory rentalAgreement = _rentalAgreements[rentalTokenId];
        require(rentalAgreement.rentalAmount > 0, Errors.E_INVALID_RENTAL_TOKEN_ID);

        address renter = _rentalToken.ownerOf(rentalTokenId);
        uint32 timestamp = uint32(block.timestamp);

        require(
            rentalAgreement.renterOnlyReturnTime < timestamp || msg.sender == renter,
            Errors.E_INVALID_CALLER_WITHIN_RENTER_ONLY_RETURN_PERIOD
        );
        require(
            rentalAgreement.enterpriseOnlyCollectionTime < timestamp ||
                msg.sender == renter ||
                msg.sender == _enterpriseCollector,
            Errors.E_INVALID_CALLER_WITHIN_ENTERPRISE_ONLY_COLLECTION_PERIOD
        );

        if (!_enterpriseShutdown) {
            // When enterprise is shut down, usedReserve equals zero.
            _usedReserve -= rentalAgreement.rentalAmount;
        }

        emit RentalReturned(
            rentalTokenId,
            msg.sender,
            address(_powerTokens[rentalAgreement.powerTokenIndex]),
            rentalAgreement.rentalAmount,
            rentalAgreement.gcRewardAmount,
            _paymentTokens[rentalAgreement.gcRewardTokenIndex],
            getReserve(),
            _usedReserve
        );

        // Burn rental token and delete associated rental agreement.
        // This also burns corresponding amount of PowerTokens and transfers GC fee to the transaction sender address.
        _rentalToken.burn(rentalTokenId, msg.sender);
        delete _rentalAgreements[rentalTokenId];
    }

    /**
     * One must approve sufficient amount of enterprise tokens to
     * Enterprise address before calling this function
     */
    function stake(uint256 stakeAmount) external whenNotShutdown {
        // Transfer enterprise tokens to the enterprise.
        _enterpriseToken.safeTransferFrom(msg.sender, address(this), stakeAmount);

        // Calculate number of new shares to be issued.
        uint256 reserve = getReserve();
        uint256 stakeShares = (_totalShares == 0 ? stakeAmount : _liquidityToShares(stakeAmount, reserve));

        // Increase total reserves & shares.
        _increaseReserveAndShares(stakeAmount, stakeShares);

        // Mint new stake token and associate stake information.
        uint256 stakeTokenId = _stakeToken.mint(msg.sender);
        _stakes[stakeTokenId] = Stake(stakeAmount, stakeShares, block.number);

        emit StakeChanged(
            stakeTokenId,
            msg.sender,
            StakeOperation.Stake,
            stakeAmount,
            stakeAmount,
            stakeShares,
            stakeShares,
            _totalShares,
            reserve + stakeAmount,
            _usedReserve
        );
    }

    function claimStakingReward(uint256 stakeTokenId) external onlyStakeTokenOwner(stakeTokenId) {
        Stake storage stakeInfo = _stakes[stakeTokenId];

        uint256 stakeAmount = stakeInfo.amount;
        uint256 stakeShares = stakeInfo.shares;
        uint256 reserve = getReserve();

        // Calculate reward & check if reserves are sufficient to fulfill withdrawal request.
        uint256 rewardAmount = _calculateStakingReward(stakeShares, stakeAmount, reserve);
        require(rewardAmount <= _getAvailableReserve(reserve), Errors.E_INSUFFICIENT_LIQUIDITY);

        // Transfer reward to the stake token owner.
        _enterpriseToken.safeTransfer(msg.sender, rewardAmount);

        // Recalculate the remaining number of shares after reward withdrawal.
        uint256 remainingStakeShares = _liquidityToShares(stakeAmount, reserve);
        uint256 stakeSharesDelta = stakeShares - remainingStakeShares;

        // Decrease total reserves & shares.
        _decreaseReserveAndShares(rewardAmount, stakeSharesDelta);

        // Update stake information.
        stakeInfo.shares = remainingStakeShares;

        emit StakeChanged(
            stakeTokenId,
            msg.sender,
            StakeOperation.Reward,
            rewardAmount,
            stakeAmount,
            stakeSharesDelta,
            remainingStakeShares,
            _totalShares,
            reserve - rewardAmount,
            _usedReserve
        );
    }

    function unstake(uint256 stakeTokenId) external onlyStakeTokenOwner(stakeTokenId) {
        Stake storage stakeInfo = _stakes[stakeTokenId];
        require(stakeInfo.block < block.number, Errors.E_FLASH_LIQUIDITY_REMOVAL);

        // Calculate owing enterprise token amount including accrued reward.
        uint256 stakeShares = stakeInfo.shares;
        uint256 reserve = getReserve();
        uint256 stakeAmountWithReward = _sharesToLiquidity(stakeShares, reserve);
        require(stakeAmountWithReward <= _getAvailableReserve(reserve), Errors.E_INSUFFICIENT_LIQUIDITY);

        // Transfer enterprise tokens to the stake token owner.
        _enterpriseToken.safeTransfer(msg.sender, stakeAmountWithReward);

        // Decrease total reserves & shares.
        _decreaseReserveAndShares(stakeAmountWithReward, stakeShares);

        // Burn stake token and delete associated stake information.
        _stakeToken.burn(stakeTokenId);
        delete _stakes[stakeTokenId];

        emit StakeChanged(
            stakeTokenId,
            msg.sender,
            StakeOperation.Unstake,
            stakeAmountWithReward,
            0,
            stakeShares,
            0,
            _totalShares,
            reserve - stakeAmountWithReward,
            _usedReserve
        );
    }

    function decreaseStake(uint256 stakeTokenId, uint256 stakeAmountDelta) external onlyStakeTokenOwner(stakeTokenId) {
        Stake memory stakeInfo = _stakes[stakeTokenId];
        require(stakeInfo.block < block.number, Errors.E_FLASH_LIQUIDITY_REMOVAL);
        require(stakeInfo.amount >= stakeAmountDelta, Errors.E_INSUFFICIENT_LIQUIDITY);
        uint256 reserve = getReserve();
        require(stakeAmountDelta <= _getAvailableReserve(reserve), Errors.E_INSUFFICIENT_LIQUIDITY);

        // Transfer enterprise tokens to the stake token owner.
        _enterpriseToken.safeTransfer(msg.sender, stakeAmountDelta);

        // Calculate number of shares to be destroyed.
        uint256 stakeSharesDelta = _liquidityToShares(stakeAmountDelta, reserve);
        if (stakeSharesDelta > stakeInfo.shares) {
            stakeSharesDelta = stakeInfo.shares;
        }

        // Decrease total reserves & shares.
        _decreaseReserveAndShares(stakeAmountDelta, stakeSharesDelta);

        // Update stake information.
        unchecked {
            stakeInfo.shares -= stakeSharesDelta;
            stakeInfo.amount -= stakeAmountDelta;
        }
        _stakes[stakeTokenId].shares = stakeInfo.shares;
        _stakes[stakeTokenId].amount = stakeInfo.amount;

        emit StakeChanged(
            stakeTokenId,
            msg.sender,
            StakeOperation.Decrease,
            stakeAmountDelta,
            stakeInfo.amount,
            stakeSharesDelta,
            stakeInfo.shares,
            _totalShares,
            reserve - stakeAmountDelta,
            _usedReserve
        );
    }

    function increaseStake(uint256 stakeTokenId, uint256 stakeAmountDelta)
        external
        whenNotShutdown
        onlyStakeTokenOwner(stakeTokenId)
    {
        // Transfer enterprise tokens to the enterprise.
        _enterpriseToken.safeTransferFrom(msg.sender, address(this), stakeAmountDelta);

        // Calculate number of new shares to be issued.
        uint256 reserve = getReserve();
        uint256 stakeSharesDelta = (
            _totalShares == 0 ? stakeAmountDelta : _liquidityToShares(stakeAmountDelta, reserve)
        );

        // Increase total reserves & shares.
        _increaseReserveAndShares(stakeAmountDelta, stakeSharesDelta);

        // Update stake information.
        Stake storage stakeInfo = _stakes[stakeTokenId];
        uint256 stakeAmount = stakeInfo.amount + stakeAmountDelta;
        uint256 stakeShares = stakeInfo.shares + stakeSharesDelta;
        stakeInfo.amount = stakeAmount;
        stakeInfo.shares = stakeShares;
        stakeInfo.block = block.number;

        emit StakeChanged(
            stakeTokenId,
            msg.sender,
            StakeOperation.Increase,
            stakeAmountDelta,
            stakeAmount,
            stakeSharesDelta,
            stakeShares,
            _totalShares,
            reserve + stakeAmountDelta,
            _usedReserve
        );
    }

    function estimateRentalFee(
        address powerToken,
        address paymentToken,
        uint112 rentalAmount,
        uint32 rentalPeriod
    ) external view whenNotShutdown returns (uint256) {
        require(_registeredPowerTokens[powerToken], Errors.UNREGISTERED_POWER_TOKEN);
        (uint112 poolFee, uint112 serviceFee, uint112 gcFee) = IPowerToken(powerToken).estimateRentalFee(
            paymentToken,
            rentalAmount,
            rentalPeriod
        );

        return poolFee + serviceFee + gcFee;
    }

    function _increaseReserveAndShares(uint256 reserveDelta, uint256 sharesDelta) internal {
        _totalShares += sharesDelta;
        uint256 fixedReserve = _fixedReserve + reserveDelta;
        _fixedReserve = fixedReserve;
        emit FixedReserveChanged(fixedReserve);
    }

    function _decreaseReserveAndShares(uint256 reserveDelta, uint256 sharesDelta) internal {
        uint256 fixedReserve = _fixedReserve;
        _totalShares -= sharesDelta;
        if (fixedReserve >= reserveDelta) {
            unchecked {
                fixedReserve -= reserveDelta;
            }
        } else {
            uint256 streamingReserve = _flushStreamingReserve();
            fixedReserve = (fixedReserve + streamingReserve) - reserveDelta;
        }
        _fixedReserve = fixedReserve;
        emit FixedReserveChanged(fixedReserve);
    }

    function _liquidityToShares(uint256 liquidityAmount, uint256 reserve) internal view returns (uint256) {
        return (_totalShares * liquidityAmount) / reserve;
    }

    function _sharesToLiquidity(uint256 shares, uint256 reserve) internal view returns (uint256) {
        return (reserve * shares) / _totalShares;
    }

    function transferRental(
        address from,
        address to,
        uint256 rentalTokenId
    ) external override onlyRentalToken {
        RentalAgreement memory rentalAgreement = _rentalAgreements[rentalTokenId];

        require(rentalAgreement.rentalAmount > 0, Errors.E_INVALID_RENTAL_TOKEN_ID);

        bool isExpiredRentalAgreement = (block.timestamp > rentalAgreement.endTime);
        bool isMinting = (from == address(0));
        bool isBurning = (to == address(0));
        IPowerToken powerToken = _powerTokens[rentalAgreement.powerTokenIndex];

        if (isBurning) {
            powerToken.burnFrom(from, rentalAgreement.rentalAmount);
        } else if (isMinting) {
            powerToken.mint(to, rentalAgreement.rentalAmount);
        } else if (!isExpiredRentalAgreement) {
            powerToken.forceTransfer(from, to, rentalAgreement.rentalAmount);
        } else {
            revert(Errors.E_RENTAL_TRANSFER_NOT_ALLOWED);
        }
    }

    function getStakingReward(uint256 stakeTokenId) public view returns (uint256) {
        Stake storage stakeInfo = _stakes[stakeTokenId];
        return _calculateStakingReward(stakeInfo.shares, stakeInfo.amount, getReserve());
    }

    function _calculateStakingReward(
        uint256 stakeShares,
        uint256 stakeAmount,
        uint256 reserve
    ) internal view returns (uint256) {
        uint256 liquidity = _sharesToLiquidity(stakeShares, reserve);
        // Due to rounding errors calculated liquidity could be insignificantly less than provided liquidity
        return liquidity <= stakeAmount ? 0 : liquidity - stakeAmount;
    }

    /**
     * @dev Shuts down Enterprise.
     *  * Unlocks all reserves, stakers can withdraw their tokens
     *  * Disables staking
     *  * Disables renting
     *  * Disables swapping
     *
     * !!! Cannot be undone !!!
     */
    function shutdownEnterpriseForever() external whenNotShutdown onlyOwner {
        _enterpriseShutdown = true;
        _usedReserve = 0;
        _streamingReserve = _streamingReserveTarget;

        emit EnterpriseShutdown();
    }
}

// SPDX-License-Identifier: MIT

// IQ Protocol. Risk-free collateral-less utility renting
// https://iq.space/docs/iq-yellow-paper.pdf
// (C) Blockvis & PARSIQ
// 🖖 Stake strong!

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IRentalToken.sol";
import "./interfaces/IEnterprise.sol";
import "./RentalTokenStorage.sol";

contract RentalToken is RentalTokenStorage, IRentalToken {
    using SafeERC20 for IERC20;

    function mint(address to) external override onlyEnterprise returns (uint256) {
        uint256 tokenId = getNextTokenId();
        _safeMint(to, tokenId);
        _tokenIdTracker++;
        return tokenId;
    }

    function burn(uint256 tokenId, address burner) external override onlyEnterprise {
        // Transfer GC reward to the burner address.
        IEnterprise enterprise = getEnterprise();
        IEnterprise.RentalAgreement memory rentalAgreement = enterprise.getRentalAgreement(tokenId);
        IERC20 paymentToken = IERC20(enterprise.getPaymentToken(rentalAgreement.gcRewardTokenIndex));
        paymentToken.safeTransfer(burner, rentalAgreement.gcRewardAmount);

        _burn(tokenId);
    }

    function getNextTokenId() public view override returns (uint256) {
        return uint256(keccak256(abi.encodePacked("r", address(this), _tokenIdTracker)));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        getEnterprise().transferRental(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        string memory baseURI = getEnterprise().getBaseUri();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "rental/")) : "";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./token/ERC721Enumerable.sol";
import "./interfaces/IRentalTokenStorage.sol";
import "./interfaces/IEnterprise.sol";
import "./EnterpriseOwnable.sol";

abstract contract RentalTokenStorage is EnterpriseOwnable, ERC721Enumerable, IRentalTokenStorage {
    uint256 internal _tokenIdTracker;

    function initialize(
        string memory name,
        string memory symbol,
        IEnterprise enterprise
    ) external override {
        EnterpriseOwnable.initialize(enterprise);
        ERC721.initialize(name, symbol);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    uint8 internal _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        uint256 _totalSupply
    ) ERC20(name, symbol) {
        _decimals = decimals_;
        _mint(msg.sender, _totalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../math/ExpMath.sol";

contract ExpMathMock {
    uint112 public result;
    uint256 public gas;

    function measure(
        uint32 t0,
        uint112 c0,
        uint32 t12,
        uint32 t
    ) public {
        uint256 tgas = gasleft();
        uint112 tmp = halfLife(t0, c0, t12, t);
        gas = tgas - gasleft();
        result = tmp;
    }

    function halfLife(
        uint32 t0,
        uint112 c0,
        uint32 t12,
        uint32 t
    ) public pure returns (uint112) {
        return ExpMath.halfLife(t0, c0, t12, t);
    }
}