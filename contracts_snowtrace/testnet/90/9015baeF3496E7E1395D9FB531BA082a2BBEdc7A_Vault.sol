// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./VaultBase.sol";

contract Vault is VaultBase {
  struct TkERC20 {
    address token;
    uint256 amount;
  }

  struct TkERC721 {
    address token;
    uint256[] ids;
  }

  struct Deposit {
    uint256 coin;
    TkERC20[] erc20s;
    TkERC721[] erc721s;
  }

  mapping(uint256 => Deposit) private deposits;

  constructor(address utility) VaultBase(utility) {}

  function depositERC20(
    uint256 tokenId,
    address[] calldata tokens,
    uint256[] calldata amounts
  ) public payable onlyOwner(tokenId) {
    if (msg.value > 0) {
      deposits[tokenId].coin += msg.value;
    }
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      uint256 amount = amounts[i];
      IERC20(token).transferFrom(msg.sender, address(this), amount);
      deposits[tokenId].erc20s.push(TkERC20(token, amount));
    }
  }

  function depositERC721(
    uint256 tokenId,
    address erc721Token,
    uint256[] calldata erc721TokenIds
  ) public onlyOwner(tokenId) {
    for (uint256 i = 0; i < erc721TokenIds.length; i++) {
      uint256 erc721TokenId = erc721TokenIds[i];
      IERC721(erc721Token).transferFrom(msg.sender, address(this), erc721TokenId);
    }
    deposits[tokenId].erc721s.push(TkERC721(erc721Token, erc721TokenIds));
  }

  function registerERC20(
    uint256 tokenId,
    address token,
    uint256 amount
  ) public onlyUtility {
    deposits[tokenId].erc20s.push(TkERC20(token, amount));
  }

  function withdrawERC20(
    address to,
    address token,
    uint256 amount
  ) public onlyUtility {
    IERC20(token).transfer(to, amount);
  }

  function viewDeposits(uint256 tokenId) public view onlyPublic(tokenId) returns (Deposit memory deposit) {
    deposit = deposits[tokenId];
  }

  function emergencyClaimTokens(uint256 tokenId, uint256 max) public onlyOwner(tokenId) {
    Deposit storage deposit = deposits[tokenId];
    if (deposit.coin > 0) {
      payable(msg.sender).transfer(deposit.coin);
      delete deposit.coin;
    }

    uint256 length = deposit.erc20s.length;
    if (length > max) {
      for (uint256 i = 1; i <= max; i++) {
        address token = deposit.erc20s[length - i].token;
        uint256 amount = deposit.erc20s[length - i].amount;
        IERC20(token).transfer(msg.sender, amount);
        deposit.erc20s.pop();
      }
    } else {
      for (uint256 i = 0; i < length; i++) {
        address token = deposit.erc20s[i].token;
        uint256 amount = deposit.erc20s[i].amount;
        IERC20(token).transfer(msg.sender, amount);
      }
      delete deposit.erc20s;
    }
  }

  function emergencyClaimERC721s(
    uint256 tokenId,
    uint256 tokenIndex,
    uint256 max
  ) public onlyOwner(tokenId) {
    address token = deposits[tokenId].erc721s[tokenIndex].token;
    uint256[] storage ids = deposits[tokenId].erc721s[tokenIndex].ids;
    uint256 length = ids.length;
    if (length > max) {
      for (uint256 i = 1; i <= max; i++) {
        IERC721(token).transferFrom(address(this), msg.sender, ids[length - i]);
        ids.pop();
      }
    } else {
      for (uint256 i = 0; i < length; i++) {
        IERC721(token).transferFrom(address(this), msg.sender, ids[i]);
      }
      delete deposits[tokenId].erc721s[tokenIndex].ids;
    }
  }

  function claimDeposits(uint256 tokenId, address to) external virtual override onlyUtility {
    Deposit storage deposit = deposits[tokenId];
    if (deposit.coin > 0) {
      payable(to).transfer(deposit.coin);
      delete deposit.coin;
    }

    if (deposit.erc20s.length > 0) {
      for (uint256 i = 0; i < deposit.erc20s.length; i++) {
        address token = deposit.erc20s[i].token;
        uint256 amount = deposit.erc20s[i].amount;
        IERC20(token).transfer(to, amount);
      }
      delete deposit.erc20s;
    }

    if (deposit.erc721s.length > 0) {
      for (uint256 i = 0; i < deposit.erc721s.length; i++) {
        address token = deposit.erc721s[i].token;
        uint256[] storage ids = deposit.erc721s[i].ids;
        for (uint256 j = 0; j < ids.length; j++) {
          IERC721(token).transferFrom(address(this), to, ids[j]);
        }
      }
      delete deposit.erc721s;
    }
  }

  function isEmpty(uint256 tokenId) external view virtual override returns (bool) {
    Deposit storage deposit = deposits[tokenId];
    return (deposit.coin == 0 && deposit.erc20s.length == 0 && deposit.erc721s.length == 0);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
pragma solidity ^0.8.0;

import "../interfaces/IUtility.sol";

abstract contract VaultBase {
  IUtility public immutable utility;

  constructor(address _utility) {
    utility = IUtility(_utility);
  }

  modifier onlyUtility() {
    require(msg.sender == address(utility));
    _;
  }

  modifier onlyPublic(uint256 tokenId) {
    require(utility.isPublic(tokenId));
    _;
  }

  modifier onlyOwner(uint256 tokenId) {
    require(utility.ownerOf(tokenId) == msg.sender);
    require(utility.isPublic(tokenId));
    _;
  }

  function isEmpty(uint256 tokenId) external view virtual returns (bool);

  function claimDeposits(uint256 tokenId, address to) external virtual;
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
pragma solidity ^0.8.0;

interface IUtility {
  function factory() external view returns (address);

  function ownerOf(uint256 tokenId) external view returns (address);

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function isPublic(uint256 tokenId) external view returns (bool);

  function setIndex(uint256 index) external;
}