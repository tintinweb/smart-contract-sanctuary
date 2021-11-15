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
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface Gen2Contract{
  function getTimesMated(uint birbID) external view returns (uint256);
}

contract BirbStoreV2 is Context, Pausable, Ownable{
  address internal Gen2Address;
  address internal Gen1Address;

  address payable internal communityWallet = payable(0x690d89B461dD2038b3601382b485807eac45741D);

  uint internal feePercent = 2;

  mapping(uint => uint) public prices;
  mapping(uint => address) public owners;
  mapping(uint => uint) public expirations;

  constructor(address _Gen1Address, address _Gen2Address) {
    Gen1Address = _Gen1Address;
    Gen2Address = _Gen2Address;
  }
  
  event depositedInStore(uint birbId, uint price, address seller, uint expireBlock);
  event removedFromStore(uint birbId, uint price, bool sale, address receiver);

  function multiDepositForSale(uint[] memory birbIds, uint[] memory birbPrices, uint expireBlock) external whenNotPaused{
    uint i;

    require(birbIds.length <= 32,"Too many Birbs");
    for(i = 0; i < birbIds.length; i++){
      require(birbIds[i] < 16383,"One of the birbs does not exist");
      require(Gen2Contract(Gen2Address).getTimesMated(birbIds[i]) == 0,"All Birbs must be virgin");
      require(birbPrices[i] > 0 ether && birbPrices[i] < 10000 ether,"Invalid price"); 
      if(birbIds[i] <= 8192){
        require(IERC721(Gen1Address).ownerOf(birbIds[i]) == _msgSender(),"You must own all the Birbs");
      }else{
        require(IERC721(Gen2Address).ownerOf(birbIds[i]) == _msgSender(),"You must own all the Birbs");
      }
      prices[birbIds[i]] = birbPrices[i];
      owners[birbIds[i]] = _msgSender();
      expirations[birbIds[i]] = expireBlock;
      emit depositedInStore(birbIds[i], birbPrices[i], _msgSender(), expireBlock);
    }
  }

  function sendViaCall(address payable _to, uint amount) internal {
      (bool sent, bytes memory data) = _to.call{value: amount}("");
      require(sent, "Failed to send Ether");
  }

  function multiBuy(uint[] memory birbIds) external payable whenNotPaused{
    uint i;
    uint totalPrice = 0;
      
    require(birbIds.length <= 32,"Too many Birbs");
    for(i = 0; i < birbIds.length; i++){
      require(birbIds[i] < 16383,"One of the Birbs does not exists");
      require(prices[birbIds[i]] > 0,"One of the Birbs has an invalid price");
      require(expirations[birbIds[i]] < block.number || expirations[birbIds[i]] == 0,"One of the Birbs is not on sale anymore");
      require(Gen2Contract(Gen2Address).getTimesMated(birbIds[i]) == 0,"One of the Birbs is not virgin");
      if(birbIds[i] <= 8192){
        require(IERC721(Gen1Address).ownerOf(birbIds[i]) == owners[birbIds[i]],"One of the Birbs changed owner");
      }else{
        require(IERC721(Gen2Address).ownerOf(birbIds[i]) == owners[birbIds[i]],"One of the Birbs changed owner");
      }
      totalPrice = totalPrice + prices[birbIds[i]];
    }

    require(msg.value == totalPrice,"Invalid msg.value");

    for(i = 0; i < birbIds.length; i++){
      uint amountAfterFee = prices[birbIds[i]] - (prices[birbIds[i]]*5)/100;
      sendViaCall(payable (owners[birbIds[i]]),amountAfterFee);
      if(birbIds[i] <= 8192){
        IERC721(Gen1Address).safeTransferFrom(owners[birbIds[i]], _msgSender(), birbIds[i]);
      }else{
        IERC721(Gen2Address).safeTransferFrom(owners[birbIds[i]], _msgSender(), birbIds[i]);
      }
      owners[birbIds[i]] = address(0x0);
      prices[birbIds[i]] = 0;
      emit removedFromStore(birbIds[i], prices[birbIds[i]], true, _msgSender());
    }
  }
  
  function removeBirbsFromSale(uint[] memory birbIds) external {
    uint i;
    require(birbIds.length <= 32,"Too many Birbs");
    for(i = 0; i < birbIds.length; i++){
      require(birbIds[i] < 16383,"One of the Birbs does not exists");
      require(owners[birbIds[i]] == _msgSender(),"You must be the owner of all the Birbs");
      if(birbIds[i] <= 8192){
        require(IERC721(Gen1Address).ownerOf(birbIds[i]) == owners[birbIds[i]],"One of the Birbs changed owner");
      }else{
        require(IERC721(Gen2Address).ownerOf(birbIds[i]) == owners[birbIds[i]],"One of the Birbs changed owner");
      }
      owners[birbIds[i]] = address(0x0);
      emit removedFromStore(birbIds[i], prices[birbIds[i]], false, _msgSender());
    } 
  }

  function withdrawFunds() external {
    communityWallet.transfer(address(this).balance);
  }

  function pause() external onlyOwner whenNotPaused{
    _pause();
  }

  function unpause() external onlyOwner whenPaused{
    _unpause();
  }

}

