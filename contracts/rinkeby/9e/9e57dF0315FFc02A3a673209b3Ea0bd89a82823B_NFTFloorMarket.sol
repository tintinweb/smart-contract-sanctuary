//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRoyaltyEngineV1.sol";

contract NFTFloorMarket is ReentrancyGuard, Ownable {

    // Events
    event OfferPlaced(
        uint256 _offerId,
        address indexed _contract,
        address _offerer,
        uint256 _value
    );

    event OfferWithdrawn(
        uint256 _offerId,
        address indexed _contract,
        address _offerer,
        uint256 _value
    );

    event OfferAccepted(
        uint256 _offerId,
        address indexed _contract,
        address _offerer,
        address _seller,
        uint256 _tokenId,
        uint256 _value
    );


    // Offer Structure
    struct Offer {
        address _contract;
        address _offerer;
        uint256 _value;
        uint128 _contractListIndex; // This and the following are 128 to make use of bitpacking on the struct
        uint128 _offererListIndex;
    }

    // Offer Details Structure
    struct OfferDetails {
        uint256 _offerId;
        address _contract;
        address _offerer;
        uint256 _value;
    }


    // Keep track of latest offer ID
    uint256 public lastOfferId = 0;

    // Keep track of all offers
    mapping(uint256 => Offer) public offers;

    // Keep track of offer IDs per contract
    mapping(address => uint128[]) public offersByContract;

    // Keep track of offer per offerer address
    mapping(address => uint128[]) public offersByOfferer;


    // Royalty Fee Address
    address public MANIFOLD_ROYALTY_ENGINE;


    // Anti-Griefing
    uint256 public MINIMUM_BUY_OFFER = 10000000000000000; // 0.01 ETH


    /**
     * Royalties - lookup for all royalty addresses
     **/
    function setRoyaltyEngineAddress(address _addr) public onlyOwner {
        MANIFOLD_ROYALTY_ENGINE = _addr;
    }

    /**
     * Set the minimum buy order amount - anti-griefing mechanic
     **/
    function setMinimumBuyOffer(uint256 _minValue) public onlyOwner {
        MINIMUM_BUY_OFFER = _minValue;
    }


    /**
     * Constructor
     **/
    constructor(
        address _MANIFOLD_ROYALTY_ENGINE,
        uint256 _MINIMUM_BUY_OFFER
    ) {
        setRoyaltyEngineAddress(_MANIFOLD_ROYALTY_ENGINE);
        setMinimumBuyOffer(_MINIMUM_BUY_OFFER);
    }


    /**
     * Wrapper to get all royalties for a given contract + tokenId at a given value
     **/
    function getRoyalties(
        address _contract,
        uint256 _tokenId,
        uint256 _value
    )
        public
        view
        returns (
            address payable[] memory recipients,
            uint256[] memory amounts
        )
    {
        if (MANIFOLD_ROYALTY_ENGINE != address(0)) {
            try IRoyaltyEngineV1(MANIFOLD_ROYALTY_ENGINE).getRoyaltyView(_contract, _tokenId, _value) returns(address payable[] memory _recipients, uint256[] memory _amounts) {
                return (_recipients, _amounts);
            } catch {}
        }
    }


    /**
     * Make an offer on any NFT within a contract
     **/
    function makeOffer(
        address _contract
    )
        public
        payable
        nonReentrant
    {
        // Require that the contract is a valid ERC721 token
        require(IERC721(_contract).supportsInterface(0x80ac58cd), "Not a valid ERC-721 Contract");
        require(msg.value >= MINIMUM_BUY_OFFER, "Buy order too low");

        // Store the records
        offers[lastOfferId] = Offer(
            _contract,
            msg.sender,
            msg.value,
            uint128(offersByContract[_contract].length),
            uint128(offersByOfferer[msg.sender].length)
        );
        offersByContract[_contract].push(uint128(lastOfferId));
        offersByOfferer[msg.sender].push(uint128(lastOfferId));

        // On to the next offer ID
        lastOfferId += 1;

        // Announce offer placed
        emit OfferPlaced(lastOfferId, _contract, msg.sender, msg.value);
    }


    /**
     * Withdraw an offer on any NFT within a contract
     **/
    function withdrawOffer(
        uint256 _offerId
    )
        public
        nonReentrant
    {
        // Get the offer
        Offer memory _offer = offers[_offerId];

        // Make sure that the sender is the owner of the offer ID
        require(_offer._offerer == msg.sender, "Sender does not own offer");

        // Remove the offer
        _removeOffer(_offer, _offerId);

        // Send the value back to the offerer
        msg.sender.call{value: _offer._value}('');

        // Announce offer withdrawn
        emit OfferWithdrawn(_offerId, _offer._contract, msg.sender, _offer._value);
    }


    /**
     * Take an offer on any NFT within a contract
     **/
    function takeOffer(
        uint256 _offerId,
        uint256 _tokenId
    )
        public
        nonReentrant
    {
        // Get the offer
        Offer memory _offer = offers[_offerId];

        // Make sure the offer exists
        require(_offer._contract != address(0), "Offer does not exist");

        // Remove the offer
        _removeOffer(_offer, _offerId);

        // Transfer NFT to the buyer
        IERC721(_offer._contract).safeTransferFrom(msg.sender, _offer._offerer, _tokenId, "");

        // Retrieve the royalties here
        uint256 totalRoyaltyFee;
        (address payable[] memory _recipients, uint256[] memory _amounts) = getRoyalties(_offer._contract, _tokenId, _offer._value);
        if (_recipients.length > 0 && _amounts.length > 0 && _amounts.length == _recipients.length) {
            for (uint256 idx; idx < _recipients.length; idx++) {
                totalRoyaltyFee += _amounts[idx];
                _recipients[idx].call{value: _amounts[idx]}('');
            }
        }

        // Split the value among royalties, seller, and market
        uint256 sellerValue = _offer._value - totalRoyaltyFee;

        // Send the value to the seller
        msg.sender.call{value: sellerValue}('');

        // Announce offer accepted
        emit OfferAccepted(_offerId, _offer._contract, _offer._offerer, msg.sender, _tokenId, _offer._value);
    }


    /**
     * Getters
     **/
    function getOffersByContractCount(
        address _contract
    )
        public
        view
        returns (uint256 _length)
    {
        return offersByContract[_contract].length;
    }

    function getOffersByContract(
        address _contract,
        uint256 _limit,
        uint256 _offset
    )
        public
        view
        returns (OfferDetails[] memory _offers)
    {
        // Limits & Offers
        if (_limit == 0) {
            _limit = 1;
        }

        // Keep track of all offers
        _offers = new OfferDetails[](_limit);

        // Iterate through offers by contract
        uint256 offerIdx;
        for (uint256 idx = _offset * _limit; idx < offersByContract[_contract].length && offerIdx < _limit; idx++) {
            _offers[offerIdx++] = OfferDetails(
                offersByContract[_contract][idx],
                offers[offersByContract[_contract][idx]]._contract,
                offers[offersByContract[_contract][idx]]._offerer,
                offers[offersByContract[_contract][idx]]._value
            );
        }

        return _offers;
    }

    function getOffersByOffererCount(
        address _offerer
    )
        public
        view
        returns (uint256 _length)
    {
        return offersByOfferer[_offerer].length;
    }

    function getOffersByOfferer(
        address _offerer,
        uint256 _limit,
        uint256 _offset
    )
        public
        view
        returns (OfferDetails[] memory _offers)
    {
        // Limits & Offers
        if (_limit == 0) {
            _limit = 1;
        }

        // Keep track of all offers
        _offers = new OfferDetails[](_limit);

        // Iterate through offers by contract
        uint256 offerIdx;
        for (uint256 idx = _offset * _limit; idx < offersByOfferer[_offerer].length && offerIdx < _limit; idx++) {
            _offers[offerIdx++] = OfferDetails(
                offersByOfferer[_offerer][idx],
                offers[offersByOfferer[_offerer][idx]]._contract,
                offers[offersByOfferer[_offerer][idx]]._offerer,
                offers[offersByOfferer[_offerer][idx]]._value
            );
        }

        return _offers;
    }


    /**
     * Internal Helper Functions 
     **/
    function _removeOffer(Offer memory _offer, uint256 _offerId) private {
        // Find and remove from the contract list and offerer list
        _removeFromContractList(_offer._contract, _offer._contractListIndex);
        _removeFromOffererList(_offer._offerer, _offer._offererListIndex);

        // Remove the offer
        delete offers[_offerId];
    }


    function _removeFromContractList(address _contract, uint128 index) private {
        uint256 _length = offersByContract[_contract].length;

        // If this index is less than the last element, then replace this element with the last element
        if (index < _length - 1) {
            // Get the last offer ID in the list
            uint128 otherOfferId = offersByContract[_contract][_length - 1];

            // Replace with the last element
            offersByContract[_contract][index] = otherOfferId;

            // Update the position within offers
            offers[otherOfferId]._contractListIndex = index;
        }

        // Remove the last index
        offersByContract[_contract].pop();
    }

    function _removeFromOffererList(address offerer, uint128 index) private {
        uint256 _length = offersByOfferer[offerer].length;

        // If this index is less than the last element, then replace this element with the last element
        if (index < _length - 1) {
            // Get the last offer ID in the list
            uint128 otherOfferId = offersByOfferer[offerer][_length - 1];

            // Replace with the last element
            offersByOfferer[offerer][index] = otherOfferId;

            // Update the position within offers
            offers[otherOfferId]._offererListIndex = index;
        }

        // Remove the last index
        offersByOfferer[offerer].pop();
    }


    /**
     * Do not accept value sent directly to contract
     **/
    receive() external payable {
        revert("No value accepted");
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
     * by making the `nonReentrant` function external, and make it call a
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

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyEngineV1 is IERC165 {

    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) external returns(address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value) external view returns(address payable[] memory recipients, uint256[] memory amounts);
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