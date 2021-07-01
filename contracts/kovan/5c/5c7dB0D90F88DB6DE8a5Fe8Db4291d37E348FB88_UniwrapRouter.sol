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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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

import './libraries/TransferHelper.sol';
import "./interfaces/IUniwrapFactory.sol";
import "./interfaces/IUniwrapPool.sol";
import "./interfaces/IWETH.sol";

pragma solidity ^0.8.0;

contract UniwrapRouter {
  address public immutable factory;
  address public immutable WETH;

  constructor(address _factory, address _WETH) {
    factory = _factory;
    WETH = _WETH;
  }

  function mint(
    string memory symbol,
    address to,
    bytes memory _data
  ) external returns (uint256 tokenId) {
    address poolAddr = IUniwrapFactory(factory).getPool(symbol);
    require(poolAddr != address(0), "UniwrapRouter: pool not exists");
    IUniwrapPool pool = IUniwrapPool(poolAddr);
    address[] memory tokens = pool.tokens();
    uint256[] memory amounts = pool.amounts();
    for (uint256 i = 0; i < tokens.length; i++) {
      TransferHelper.safeTransferFrom(tokens[i], msg.sender, poolAddr, amounts[i]);
    }
    TransferHelper.safeTransferFrom(IUniwrapFactory(factory).wrap(), msg.sender, poolAddr, pool.wrapAmount());
    tokenId = pool.mint(to, _data);
  }

  function mintETH(
    string memory symbol,
    address to,
    bytes memory _data
  ) external payable returns (uint256 tokenId) {
    address poolAddr = IUniwrapFactory(factory).getPool(symbol);
    require(poolAddr != address(0), "UniwrapRouter: pool not exists");
    IUniwrapPool pool = IUniwrapPool(poolAddr);
    address[] memory tokens = pool.tokens();
    uint256[] memory amounts = pool.amounts();
    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i] == WETH) {
        IWETH(WETH).deposit{value: amounts[i]}();
        assert(IWETH(WETH).transfer(poolAddr, amounts[i]));
      } else {
        TransferHelper.safeTransferFrom(tokens[i], msg.sender, poolAddr, amounts[i]);
      }
    }
    if (pool.wrapAmount() > 0) {
      TransferHelper.safeTransferFrom(IUniwrapFactory(factory).wrap(), msg.sender, poolAddr, pool.wrapAmount());
    }
    tokenId = pool.mint(to, _data);
  }

  function redeem(
    string memory symbol,
    uint256 tokenId,
    address to
  ) external returns (bool) {
    address poolAddr = IUniwrapFactory(factory).getPool(symbol);
    require(poolAddr != address(0), "UniwrapRouter: pool not exists");

    IUniwrapPool pool = IUniwrapPool(poolAddr);
    pool.safeTransferFrom(msg.sender, poolAddr, tokenId);
    pool.burn(tokenId, to);

    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniwrapFactory {
  function wrap() external view returns (address);
  function rewardHolder() external view returns (address);
  function getPool(string memory symbol) external view returns (address);
  function getPoolByIndex(uint8 index) external view returns (address);
  function getPoolSize() external view returns (uint8);
  function isPool(address poolAddress) external view returns (bool);

  function create(
    uint256 wrapPerMint,
    string memory name,
    string memory symbol,
    address[] memory tokens,
    uint256[] memory amounts
  ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IUniwrapPool is IERC721, IERC721Metadata {
  // pool
  event Mint(address indexed owner, uint256 tokenId, uint256 wrapAmount);
  event Burn(address indexed to, uint256 tokenId, uint256 wrapAmount);
  event WrapPerMintSetted(uint256 wrap);

  function tokens() external view returns (address[] memory);
  function amounts() external view returns (uint256[] memory);
  function tokensSize() external view returns (uint8);
  function wrapPerMint() external view returns (uint256);
  function wrapAmount() external view returns (uint256);
  function setWrapPerMint(uint256) external returns (bool);
  function mint(address to, bytes memory _data)  external returns (uint256 tokenId);
  function burn(uint256 tokenId, address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::safeApprove: approve failed'
    );
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::safeTransfer: transfer failed'
    );
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::transferFrom: transferFrom failed'
    );
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
  }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}