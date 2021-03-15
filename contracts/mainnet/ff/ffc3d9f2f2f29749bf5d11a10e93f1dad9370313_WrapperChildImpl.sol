/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File contracts/token/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function claim(uint256[] memory indices) external returns (uint256);
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File contracts/token/IERC165.sol


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


// File contracts/token/IERC721.sol


pragma solidity ^0.8.0;

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


// File contracts/WrapperChild.sol

pragma solidity ^0.8.0;


interface IWrapperChildImpl {
    function initialize(address user) external;
    function unwrap(uint256 num) external;
}

interface IWrapperParent {
  function nftxFund() external view returns (address);
  function xToken() external view returns (address);
  function vaultID() external view returns (uint256);
}

interface INFTXFund {
    function mint(uint256 vaultId, uint256[] memory nftIds, uint256 d2Amount) external;
    function redeem(uint256 game, uint256 option) external;
}

interface IWaifuDungeon {
    function commitSwapWaifus(uint256[] calldata _ids) external;
    function revealWaifus() external;
}

contract WrapperChildImpl {
  IERC721 constant WAIFUSION = IERC721(0x2216d47494E516d8206B70FCa8585820eD3C4946);
  IERC20 constant WET = IERC20(0x76280AF9D18a868a0aF3dcA95b57DDE816c1aaf2);
  IWaifuDungeon constant WAIFU_DUNGEON = IWaifuDungeon(0xB291984262259BcFe6Aa02b66a06e9769C5c1eF3);
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
  uint256 private constant UNSET = 1 << 255;
  uint256 private constant MAX_SWAP = 3;

  bool private initialized;
  IWrapperParent public parent;
  address public user; 

  uint256 private receivedNftID;

  function initialize(address _parent, address _user) external {
    require(!initialized, "already initialized");
    initialized = true;

    parent = IWrapperParent(_parent);
    user = _user;
    IERC20(parent.xToken()).approve(parent.nftxFund(), type(uint256).max);
    WET.approve(address(WAIFU_DUNGEON), type(uint256).max);

    WAIFUSION.setApprovalForAll(address(WAIFU_DUNGEON), true);
    receivedNftID = UNSET;
  }

  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
      if (from == address(WAIFU_DUNGEON)) {
        // Use msg.sender here to allow arbitrary NFTs from dungeon.
        IERC721(msg.sender).safeTransferFrom(address(this), user, tokenId);
      } else if (from == address(parent.nftxFund())) {
        receivedNftID = tokenId;
      } else {
        revert("invalid from");
      }
      return _ERC721_RECEIVED;
  }

  function commitSwapWaifus(uint256 num) external onlyParent() {
    IERC20(parent.xToken()).transferFrom(user, address(this), num * 1 ether);
    uint256[] memory ids = new uint256[](num);
    for (uint256 i = 0; i < num; i++) {
      INFTXFund(parent.nftxFund()).redeem(parent.vaultID(), 1);
      ids[i] = receivedNftID;
    }
    WET.transferFrom(user, address(this), num * 5490 ether);
    WAIFU_DUNGEON.commitSwapWaifus(ids);
  }

  function revealWaifus() external onlyParent() {
    WAIFU_DUNGEON.revealWaifus();
  }

  modifier onlyParent() {
    require(msg.sender == address(parent), "not parent");
    _;
  } 
}