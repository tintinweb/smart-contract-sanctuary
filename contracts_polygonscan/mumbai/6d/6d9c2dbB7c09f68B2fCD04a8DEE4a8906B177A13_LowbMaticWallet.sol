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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721LOWB is IERC721 {

    function holderOf(uint256 tokenId) external view returns (address holder);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721LOWB.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LowbMaticWallet {
  
  
  
  address public lowbTokenAddress;
  address public owner;
  uint fee;
  
  mapping (address => uint) public balanceOf;
  mapping (address => bool) public isAwardAddress;
  mapping (address => mapping (address => bool)) public isApprovededAddress;
  
  event Deposit(address indexed user, uint amount);
  event Withdraw(address indexed user, uint amount);
  event Award(address indexed contractAddress, address indexed user, uint amount);
  event Use(address indexed contractAddress, address indexed user, uint amount);
  event NFTLocked(address indexed contractAddress, uint indexed tokenId, address indexed user);
  event NFTUnlocked(address indexed contractAddress, uint indexed tokenId, address indexed user);
  
  constructor(address lowbToken_) {
    lowbTokenAddress = lowbToken_;
    owner = msg.sender;
  }
  
  function deposit(uint amount) public {
    require(amount > 0, "You deposit nothing!");
    IERC20 token = IERC20(lowbTokenAddress);
    require(token.transferFrom(msg.sender, address(this), amount), "Lowb transfer failed");
    balanceOf[msg.sender] +=  amount;
    
    emit Deposit(msg.sender, amount);
  }

  function withdraw(uint amount) public {
    require(amount <= balanceOf[msg.sender], "amount larger than the balance");  
    balanceOf[msg.sender] -= amount;
    IERC20 token = IERC20(lowbTokenAddress);
    require(token.transfer(tx.origin, amount), "Lowb transfer failed");
    
    emit Withdraw(msg.sender, amount);
  }
  
  function approve(address addr, bool b) public {
    isApprovededAddress[msg.sender][addr] = b;
  }
  
  function approveAward(address addr, bool b) public {
    require(msg.sender == owner, "You are not admin");
    isAwardAddress[addr] = b;
  }
  
  function setFee(uint fee_) public {
    require(msg.sender == owner, "You are not admin");
    fee = fee_;
  }
  
  function use(address user, uint amount) public {
    require(isApprovededAddress[user][msg.sender], "you are not approved to use this user's lowb");  
    require(amount <= balanceOf[msg.sender], "amount larger than the balance");  
    balanceOf[user] -= amount;
    
    emit Use(msg.sender, user, amount);
  }
  
  function award(address user, uint amount) public {
    require(isAwardAddress[msg.sender], "you are not approved to award lowb to others");  
    balanceOf[user] += amount;
    
    emit Award(msg.sender, user, amount);
  }
  
  function lockNFT(address nftAddress, uint tokenId) public {
    IERC721LOWB nft = IERC721LOWB(nftAddress);
    require(nft.ownerOf(tokenId) == msg.sender && nft.holderOf(tokenId) == msg.sender, "You don't have access to lock this nft.");
    
    require(fee <= balanceOf[msg.sender], "fee larger than the balance");
    balanceOf[msg.sender] -= fee;
    
    nft.transferFrom(msg.sender, address(this), tokenId);
    
    emit NFTLocked(nftAddress, tokenId, msg.sender);
  }
  
  function unlockNFT(address nftAddress, uint tokenId, address user) public {
    require(msg.sender == owner, "You are not admin");
  
    IERC721LOWB nft = IERC721LOWB(nftAddress);
    require(nft.ownerOf(tokenId) == address(this), "this nft is not loced in the contract");
    
    nft.transferFrom(address(this), user, tokenId);
    
    emit NFTUnlocked(nftAddress, tokenId, user);
  }
  
  
}