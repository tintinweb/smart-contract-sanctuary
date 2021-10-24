// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Marketplace.sol";

/// @title Clock sale modified for sale of Robot
contract RobotMarketplace is Marketplace {

    constructor(address _nftAddr, uint256 _cut, address _mekaToken) Marketplace(_nftAddr, _cut, _mekaToken) {}

    /// @dev Creates and begins a new sale.
    /// @param _tokenId - ID of token to sale, sender must be owner.
    /// @param _startingPrice - Price of item (in wei).
    /// @param _seller - Seller, if not the message sender
    function createSale(
        uint256 _tokenId,
        uint256 _startingPrice,
        address _seller
    )
        override external
    {
        require(msg.sender == address(nonFungibleContract), "only nft contract");

        _escrow(_seller, _tokenId);
        Sale memory sale = Sale(
            _seller,
            _startingPrice,
            uint64(block.timestamp)
        );
        _addSale(_tokenId, sale);
    }
}

/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IBEP20.sol";
import "./SafeMath.sol";
import "./IERC721.sol";

/// @title Sale Core
contract SaleBase {
    using SafeMath for uint256;
    
    // Represents an sale on an NFT
    struct Sale {
        // Current owner of NFT
        address seller;
        // Price at beginning of sale
        uint256 startingPrice;
        // Time when sale started
        uint64 startedAt;
    }

    // Reference to contract tracking NFT ownership
    address public nonFungibleContract;
    address public MEKAToken;
    uint256 public ownerCut;

    mapping (uint256 => Sale) tokenIdToSale;

    event SaleCreated(uint256 tokenId, uint256 startingPrice);
    event SaleSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event SaleCancelled(uint256 tokenId);

    constructor (address _token){
        MEKAToken = _token;
    }

    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (IERC721(nonFungibleContract).ownerOf(_tokenId) == _claimant);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        IERC721(nonFungibleContract).transferFrom(_owner, address(this), _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _receiver, uint256 _tokenId) internal {
        IERC721(nonFungibleContract).transferFrom(address(this), _receiver, _tokenId);
    }

    /// @dev Adds an sale to the list of open sales.
    /// @param _tokenId The ID of the token to be put on sale.
    /// @param _sale Sale to add.
    function _addSale(uint256 _tokenId, Sale memory _sale) internal {

        tokenIdToSale[_tokenId] = _sale;

        emit SaleCreated(
            _tokenId,
            _sale.startingPrice
        );
    }

    /// @dev Cancels an sale unconditionally.
    function _cancelSale(uint256 _tokenId, address _seller) internal {
        _removeSale(_tokenId);
        _transfer(_seller, _tokenId);
        emit SaleCancelled(_tokenId);
    }

    /// @dev Computes the price and transfers winnings.
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        // Get a reference to the sale struct
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale), "not on sale");

        // Check that the bid is greater than or equal to the current price
        uint256 price = sale.startingPrice;
        require(_bidAmount == price, "bid different from price");

        address seller = sale.seller;

        // The bid is good! Remove the sale before sending the fees
        // to the sender so we can't have a reentrancy attack.
        _removeSale(_tokenId);

        if (price > 0) {
            uint256 sellerCut = _computeCut(price);
            uint256 sellerProceeds = price - sellerCut;

            require(IBEP20(MEKAToken).transfer(seller, sellerProceeds));
        }

        emit SaleSuccessful(_tokenId, price, msg.sender);

        return price;
    }

    /// @dev Removes an sale from the list of open sales.
    /// @param _tokenId - ID of NFT on sale.
    function _removeSale(uint256 _tokenId) internal {
        
        delete tokenIdToSale[_tokenId];
    }

    /// @dev Returns true if the NFT is on sale.
    /// @param _sale - Sale to check.
    function _isOnSale(Sale storage _sale) internal view returns (bool) {
        return (_sale.startedAt > 0);
    }

    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
  * @dev modifier to allow actions only when the contract IS paused
  */
  modifier whenNotPaused() {
    require (!paused);
    _;
  }

  /**
  * @dev modifier to allow actions only when the contract IS NOT paused
  */
  modifier whenPaused {
    require (paused) ;
    _;
  }

  /**
  * @dev called by the owner to pause, triggers stopped state
  */
  function _pause() onlyOwner public whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
  * @dev called by the owner to unpause, returns to normal state
  */
  function _unpause() onlyOwner public whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Context.sol";


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Pausable.sol";
import "./IBEP20.sol";
import "./SaleBase.sol";
import "./IMarketplace.sol";

/// @title Clock sale for non-fungible tokens.
contract Marketplace is SaleBase, Pausable, IMarketplace {

    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _cut - percent cut the owner takes on each sale, must be
    ///  between 0-10,000.
    constructor(address _nftAddress, uint256 _cut, address _mekaToken) SaleBase(_mekaToken){
        require(_cut <= 10000, "cut too high");
        ownerCut = _cut;
        nonFungibleContract = _nftAddress;
    }

    function withdrawBalance() external onlyOwner {
        IBEP20(MEKAToken).transfer(msg.sender, getBalance());
    }
    
    function changeCut(uint256 _cut) external onlyOwner {
        require(_cut <= 10000, "cut too high");
        ownerCut = _cut;
    }
    
    function getBalance() view public returns(uint256) {
        return IBEP20(MEKAToken).balanceOf(address(this));
    }

    /// @dev Creates and begins a new sale.
    /// @param _tokenId - ID of token to sale, sender must be owner.
    /// @param _startingPrice - Price of item (in wei).
    ///  price and ending price (in seconds).
    /// @param _seller - Seller, if not the message sender
    function createSale(
        uint256 _tokenId,
        uint256 _startingPrice,
        address _seller
    )
        virtual override external
        whenNotPaused
    {
        require(_startingPrice == uint256(uint128(_startingPrice)), "price not compatible uint256");

        require(_owns(msg.sender, _tokenId), "Not tokenId owner");
        _escrow(msg.sender, _tokenId);
        Sale memory sale = Sale(
            _seller,
            _startingPrice,
            uint64(block.timestamp)
        );
        _addSale(_tokenId, sale);
    }

    /// @dev Bids on an open sale, completing the sale and transferring
    ///  ownership of the NFT if enough KAI is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bid(uint256 _tokenId, uint256 _amount)
        external
        whenNotPaused
    {
         require(IBEP20(MEKAToken).transferFrom(msg.sender, address(this), _amount), "transfer not authorized");
         
        _bid(_tokenId, _amount);
        _transfer(msg.sender, _tokenId);
    }

    /// @dev Cancels an sale that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on sale
    function cancelSale(uint256 _tokenId)
        external
        whenNotPaused
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale), "TokenID is a must on sale");
        address seller = sale.seller;
        require(msg.sender == seller);
        _cancelSale(_tokenId, seller);
    }

    /// @dev Cancels an sale when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _tokenId - ID of the NFT on sale to cancel.
    function cancelSaleWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        external
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale), "TokenID is a must on sale");
        _cancelSale(_tokenId, sale.seller);
    }

    /// @dev Returns sale info for an NFT on sale.
    /// @param _tokenId - ID of NFT on sale.
    function getSale(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 startedAt
    ) {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale), "TokenID is a must on sale");
        return (
            sale.seller,
            sale.startingPrice,
            sale.startedAt
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IMarketplace {
    function createSale(
        uint256 _tokenId,
        uint256 _startingPrice,
        address _seller) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./IERC165.sol";

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
pragma solidity ^0.8.2;

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

interface IBEP20 {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}