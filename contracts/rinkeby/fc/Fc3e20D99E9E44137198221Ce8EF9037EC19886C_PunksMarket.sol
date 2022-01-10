// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/token/ERC721/IERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/security/Pausable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/security/ReentrancyGuard.sol";



/**
 * @title PunksMarket contract
 * @author @FrankPoncelet
 * 
 */
contract PunksMarket is Ownable, Pausable , ReentrancyGuard{

    IERC721 public punksWrapperContract; // instance of the Cryptopunks contract
    ICryptoPunk public punkContract; // Instance of cryptopunk smart contract

    struct Offer {
        bool isForSale;
        uint punkIndex;
        address seller;
        uint256 minValue;          // in WEI
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint punkIndex;
        address bidder;
        uint256 value;
    }

    struct Punk {
        bool wrapped;
        address owner;
        Bid bid;
        Offer offer;
    }

    // keep track of the totale volume processed by this contract.
    uint256 public totalVolume;
    uint constant public TOTAL_PUNKS = 10000;

    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) private punksOfferedForSale;

    // A record of the highest punk bid
    mapping (uint => Bid) private punkBids;

    event PunkOffered(uint indexed punkIndex, uint minValue, address indexed toAddress);
    event PunkBidEntered(uint indexed punkIndex, uint value, address indexed fromAddress);
    event PunkBidWithdrawn(uint indexed punkIndex, uint value, address indexed fromAddress);
    event PunkBought(uint indexed punkIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint indexed punkIndex);

    /* 
    * Initializes contract with an instance of CryptoPunks Wrapper contract
    */
    constructor() {
        punksWrapperContract = IERC721(0x0116ECEe66f1EC1DEf637949a88F16E681611775); // TODO change on deploy main net
        punkContract = ICryptoPunk(0x85252f525456D3fCe3654e56f6EAF034075e231C); // TODO change on deploy main net
    }

    /* Allows the owner of the contract to set a new Cryptopunks WRAPPER contract address */
    function setPunksWrapperContract(address newpunksAddress) public onlyOwner {
      punksWrapperContract = IERC721(newpunksAddress);
    }

    /* Allows the owner of a CryptoPunks to stop offering it for sale */
    function punkNoLongerForSale(uint punkIndex) public nonReentrant() {
        require(punkIndex < 10000,"Token index not valid");
        require(punksWrapperContract.ownerOf(punkIndex) == msg.sender,"you are not the owner of this token");
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, address(0x0));
        emit PunkNoLongerForSale(punkIndex);
    }

    /* Allows a CryptoPunk owner to offer it for sale */
    function offerPunkForSale(uint punkIndex, uint minSalePriceInWei) public whenNotPaused nonReentrant()  {
        require(punkIndex < 10000,"Token index not valid");
        require(punksWrapperContract.ownerOf(punkIndex) == msg.sender,"you are not the owner of this token");
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, address(0x0));
        emit PunkOffered(punkIndex, minSalePriceInWei, address(0x0));
    }

    /* Allows a Cryptopunk owner to offer it for sale to a specific address */
    function offerPunkForSaleToAddress(uint punkIndex, uint minSalePriceInWei, address toAddress) public whenNotPaused nonReentrant() {
        require(punkIndex < 10000,"Token index not valid");
        require(punksWrapperContract.ownerOf(punkIndex) == msg.sender,"you are not the owner of this token");
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, toAddress);
        emit PunkOffered(punkIndex, minSalePriceInWei, toAddress);
    }
    

    /* Allows users to buy a Cryptopunk offered for sale */
    function buyPunk(uint punkIndex) payable public whenNotPaused nonReentrant() {
        require(punkIndex < 10000,"Token index not valid");
        Offer memory offer = punksOfferedForSale[punkIndex];
        require (offer.isForSale,"Punk is not for sale"); // punk not actually for sale
        require (offer.onlySellTo == address(0x0) || offer.onlySellTo == msg.sender,"Private sale.") ;                
        require (msg.value >= offer.minValue,"Not enough ether send"); // Didn't send enough ETH
        address seller = offer.seller;
        require  (seller == punksWrapperContract.ownerOf(punkIndex),'seller no longer owner of punk'); // Seller no longer owner of punk

        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, address(0x0));
        _withdraw(seller,msg.value);
        totalVolume += msg.value;
        punksWrapperContract.safeTransferFrom(seller, msg.sender, punkIndex);

        emit PunkBought(punkIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = punkBids[punkIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            _withdraw(msg.sender,bid.value);
            punkBids[punkIndex] = Bid(false, punkIndex, address(0x0), 0);
        }
    }
    /* Allows users to enter bids for any Cryptopunk */
    function enterBidForPunk(uint punkIndex) payable public whenNotPaused nonReentrant() {
        require(punkIndex < 10000,"Token index not valid");
        require (punksWrapperContract.ownerOf(punkIndex) != msg.sender,"You already own this punk");
        require (msg.value > 0,"Cannot enter bid of zero");
        Bid memory existing = punkBids[punkIndex];
        require (msg.value >= existing.value,"your bid is too low");
        if (existing.value > 0) {
            // Refund the failing bid
            _withdraw(existing.bidder,existing.value);
        }
        punkBids[punkIndex] = Bid(true, punkIndex, msg.sender, msg.value);
        emit PunkBidEntered(punkIndex, msg.value, msg.sender);
    }

    /* Allows Cryptopunk owners to accept bids for their punks */
    function acceptBidForPunk(uint punkIndex, uint minPrice) public whenNotPaused nonReentrant() {
        require(punkIndex < 10000,"Token index not valid");
        require(punksWrapperContract.ownerOf(punkIndex) == msg.sender,'you are not the owner of this token');
        address seller = msg.sender;
        Bid memory bid = punkBids[punkIndex];
        require(bid.hasBid == true,"Punk has no bid"); 
        require (bid.value >= minPrice,"The bid is too low");

        address bidder = bid.bidder;
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, bidder, 0, address(0x0));
        uint amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, address(0x0), 0);

        _withdraw(seller,amount); 
        totalVolume += amount;
        punksWrapperContract.safeTransferFrom(msg.sender, bidder, punkIndex);

        emit PunkBought(punkIndex, bid.value, seller, bidder);
    }

    /* Allows bidders to withdraw their bids */
    function withdrawBidForPunk(uint punkIndex) public nonReentrant() {
        require(punkIndex < 10000,"token index not valid");
        Bid memory bid = punkBids[punkIndex];
        require (bid.bidder == msg.sender,"The bidder is not message sender");
        emit PunkBidWithdrawn(punkIndex, bid.value, msg.sender);
        uint amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, address(0x0), 0);
        // Refund the bid money
        _withdraw(msg.sender,amount);
    }

    ///////// Website only methods ////////////
    function getBid(uint punkIndex) external view returns (Bid memory){
        return punkBids[punkIndex];
    }

    function getOffer(uint punkIndex) external view returns (Offer memory){
        return punksOfferedForSale[punkIndex];
    }
    /**
    * Returns offer, bid and owner data for a specific punk.
    */

    function getPunksDetails(uint index) external view returns (Punk memory) {
            address owner = punkContract.punkIndexToAddress(index);
            bool wrapper = false;
            if (owner==address(punksWrapperContract)){
                owner = punksWrapperContract.ownerOf(index);
                wrapper = true;
            }
            Punk memory punks=Punk(wrapper,owner,punkBids[index],punksOfferedForSale[index]);
        return punks;
    }

    /**
    * Returns the id's of all wrapped punks.
    */
    function getAllWrappedPunks() external view returns (int[] memory){
        int[] memory ids = new int[](TOTAL_PUNKS);
        for (uint i=0; i<TOTAL_PUNKS; i++) {
            ids[i]=-1;
        }
        uint256 j =0;
        for (uint256 i=0; i<TOTAL_PUNKS; i++) {
            if ( punkContract.punkIndexToAddress(i) == address(punksWrapperContract)) {
                ids[j] = int(i);
                j++;
            }
        }
        return ids;
    }

    /**
    * Returns the id's of the UNWRAPPED punks for an address
    */
    function getPunksForAddress(address user) external view returns(uint256[] memory) {
        uint256[] memory punks = new uint256[](punkContract.balanceOf(user));
        uint256 j =0;
        for (uint256 i=0; i<TOTAL_PUNKS; i++) {
            if ( punkContract.punkIndexToAddress(i) == user ) {
                punks[j] = i;
                j++;
            }
        }
        return punks;
    }

    /**
    * Returns the id's of the WRAPPED punks for an address
    */
    function getWrappedPunksForAddress(address user) external view returns(uint256[] memory) {
        uint256[] memory punks = new uint256[](punksWrapperContract.balanceOf(user));
        uint256 j =0;
        for (uint256 i=0; i<TOTAL_PUNKS; i++) {
            try punksWrapperContract.ownerOf(i) returns (address owner){
                if ( owner == user ) {
                    punks[j] = i;
                    j++;
                }
            } catch {
                // ignore
            }
        }
        return punks;
    }

    ////////// safe withdram method //////////
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to send Ether");
    }

    ////////// Contract safety, emergency methods////////
    /**
    * Allow the CONTRACT owner to return a bid. 
    */
    function returnBid(uint punkIndex) public onlyOwner {
        Bid memory bid = punkBids[punkIndex];
        uint amount = bid.value;
        address bidder = bid.bidder;
        punkBids[punkIndex] = Bid(false, punkIndex, address(0x0), 0);
        emit PunkBidWithdrawn(punkIndex, amount, bidder);
        _withdraw(bidder,amount);
    }

    /////////// pause methods /////////////
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    ///////// contract can recieve Ether if needed//////
    fallback() external payable { }
    receive() external payable { }

}

interface ICryptoPunk {
    function punkIndexToAddress(uint punkIndex) external view returns (address);
    function buyPunk(uint punkIndex) external payable;
    function transferPunk(address to, uint punkIndex) external;
    function balanceOf(address) external view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}