// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IKey is IERC721 {
  function getBlockNumber(
    uint256 tokenId
  )
    external
    view
    returns (uint256);
}

/**
 * @title BearTrapWithTemperatureAugmentationMixin
 * @author the-torn
 */
contract BearTrapWithTemperatureAugmentationMixin {

  address public constant LAVA = 0x000000000000000000000000000000000000dEaD;

  IERC721 public immutable BEAR_CONTRACT;
  IKey public immutable KEY_CONTRACT;
  uint256 public immutable TIME_AT_WHICH_WE_DROP_THE_BEAR_IN_THE_LAVA;

  uint256 public _bearId = 0;
  bool public _bearSaved = false;
  mapping(uint256 => address) public _lockedKeyOwner;

  constructor(
    IERC721 bearContract,
    IKey keyContract,
    uint256 ttd
  ) {
    BEAR_CONTRACT = bearContract;
    KEY_CONTRACT = keyContract;
    TIME_AT_WHICH_WE_DROP_THE_BEAR_IN_THE_LAVA = block.timestamp + ttd;
  }

  function tieUpTheBear(
    uint256 bearId
  )
    external
  {
    require(
      _bearId == 0,
      "Already trapped the bear"
    );
    require(
      BEAR_CONTRACT.ownerOf(bearId) == address(this),
      "Bear not received"
    );
    _bearId = bearId;
  }

  function saveBearWithKey(
    uint256 keyId
  )
    external
  {
    require(
      _bearId != 0,
      "There is no bear"
    );
    require(
      !_bearSaved,
      "Bear already saved"
    );
    uint256 keyNumber = KEY_CONTRACT.getBlockNumber(keyId);
    require(
      isValidKey(keyNumber),
      "Invalid key"
    );
    require(
      KEY_CONTRACT.ownerOf(keyId) == msg.sender,
      "Sender does not have the key"
    );
    _bearSaved = true;
    BEAR_CONTRACT.safeTransferFrom(address(this), msg.sender, _bearId);
  }

  function dropTheBear()
    external
  {
    require(
      block.timestamp >= TIME_AT_WHICH_WE_DROP_THE_BEAR_IN_THE_LAVA,
      "TTD has not elapsed"
    );
    BEAR_CONTRACT.safeTransferFrom(address(this), LAVA, _bearId);
  }

  function lockKey(
    uint256 keyId
  )
    external
  {
    uint256 keyNumber = KEY_CONTRACT.getBlockNumber(keyId);
    require(
      isValidKey(keyNumber),
      "Invalid key"
    );
    KEY_CONTRACT.safeTransferFrom(msg.sender, address(this), keyId);
    _lockedKeyOwner[keyId] = msg.sender;
  }

  function retrievePreviouslyLockedKeyOnlyIfTheBearIsGone(
    uint256 keyId
  )
    external
  {
    require(
      BEAR_CONTRACT.ownerOf(_bearId) != address(this),
      "Still got the bear"
    );
    require(
      _lockedKeyOwner[keyId] == msg.sender,
      "Not the sender's key"
    );
    delete _lockedKeyOwner[keyId];
    KEY_CONTRACT.safeTransferFrom(address(this), msg.sender, keyId);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  )
    external
    pure
    returns(bytes4)
  {
    return 0x150b7a02;
  }

  function isValidKey(
    uint256 x
  )
    private
    view
    returns (bool)
  {
    uint256 z;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let p := mload(0x40)
      mstore(p, 0x20)
      mstore(add(p, 0x20), 0x20)
      mstore(add(p, 0x40), 0x20)
      mstore(add(p, 0x60), 0x02)
      mstore(add(p, 0x80), sub(x, 1))
      mstore(add(p, 0xa0), x)
      if iszero(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, p, 0x20)) {
        revert(0, 0)
      }
      z := mload(p)
    }
    return z == 1;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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