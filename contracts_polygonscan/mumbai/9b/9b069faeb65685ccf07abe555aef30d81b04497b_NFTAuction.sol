/**
 *Submitted for verification at polygonscan.com on 2022-01-20
*/

/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
    abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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


contract NFTAuction is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    uint256 public royaltyPercentage= 200; // 2%
    uint256 public ownerPercentage= 0; // 0%
    uint256 public settlePenalty= 5;    // 5%
    address public royaltyOwner;

    mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;
    mapping(address => mapping(uint256 => Sale)) public nftContractSale;
    mapping(address => mapping(uint256 => address)) public nftOwner;
    mapping(address => uint256) failedTransferCredits;
 
    struct Auction {
        //map token ID to
        uint256 minPrice;
        uint256 auctionBidPeriod; //Increments the length of time the auction is open in which a new bid can be made after each bid.
        uint256 auctionEnd;
        uint256 nftHighestBid;
        uint256 bidIncreasePercentage;
        address nftHighestBidder;
        address nftSeller;
        address nftRecipient; //The bidder can specify a recipient for the NFT if their bid is successful.
        address ERC20Token; // The seller can specify an ERC20 token that can be used to bid or purchase the NFT
    }

    struct Sale{
        address nftSeller;
        address ERC20Token;
        uint256 buyNowPrice;
    }

    modifier minimumBidNotMade(address _nftContractAddress, uint256 _tokenId) {
        require(
            !_isMinimumBidMade(_nftContractAddress, _tokenId),
            "The auction has a valid bid made"
        );
        _;
    }

    modifier auctionOngoing(address _nftContractAddress, uint256 _tokenId) {
        require(
            _isAuctionOngoing(_nftContractAddress, _tokenId),
            "Auction has ended"
        );
        _;
    }

    modifier isAuctionOver(address _nftContractAddress, uint256 _tokenId) {
        require(
            !_isAuctionOngoing(_nftContractAddress, _tokenId),
            "Auction is not yet over"
        );
        _;
    }

    modifier priceGreaterThanZero(uint256 _price) {
        require(_price > 0, "Price cannot be 0");
        _;
    }
    
    modifier paymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _tokenAmount
    ) {
        require(
            _isPaymentAccepted(
                _nftContractAddress,
                _tokenId,
                _erc20Token,
                _tokenAmount
            ),
            "Bid to be made in quantities of specified token or eth"
        );
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "cannot specify 0 address");
        _;
    }

    modifier increasePercentageAboveMinimum(uint256 _bidIncreasePercentage) {
        require(
            _bidIncreasePercentage >= 0,
            "Bid increase percentage must be greater than minimum settable increase percentage"
        );
        _;
    }

    modifier notNftSeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender !=
                nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            "Owner cannot bid on own NFT"
        );
        _;
    }

    modifier biddingPeriodMinimum(
        uint256 _auctionBidPeriod
    ){
        require(_auctionBidPeriod> 600,"Minimum bidding beriod is 10 minutes");
        _;
    }

    modifier bidAmountMeetsBidRequirements(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount
    ) {
        require(
            _doesBidMeetBidRequirements(
                _nftContractAddress,
                _tokenId,
                _tokenAmount
            ),
            "Not enough funds to bid on NFT"
        );
        _;
    }

    modifier onlyNftSeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender ==
                nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            "Only the owner can call this function"
        );
        _;
    }
    
    constructor(address _royaltyOwner) {
        royaltyOwner= _royaltyOwner;
    }

    function _isPaymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _bidERC20Token,
        uint256 _tokenAmount
    ) internal view returns (bool) {
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].ERC20Token;
        if (_isERC20Auction(auctionERC20Token)) {
            return
                msg.value == 0 &&
                auctionERC20Token == _bidERC20Token &&
                _tokenAmount > 0;
        } else {
            return
                msg.value != 0 &&
                _bidERC20Token == address(0) &&
                _tokenAmount == 0;
        }
    }

    function _isERC20Auction(address _auctionERC20Token)
        internal
        pure
        returns (bool)
    {
        return _auctionERC20Token != address(0);
    }

    function _getBidIncreasePercentage(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (uint256) {
        uint256 bidIncreasePercentage = nftContractAuctions[
            _nftContractAddress
        ][_tokenId].bidIncreasePercentage;
        return bidIncreasePercentage;
    }

    function _doesBidMeetBidRequirements(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount
    ) internal view returns (bool) {
        //if the NFT is up for auction, the bid needs to be a % higher than the previous bid
        uint256 bidIncreaseAmount= (nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBid).mul(100 +_getBidIncreasePercentage(_nftContractAddress, _tokenId))/100;
        return (msg.value >= bidIncreaseAmount ||
            _tokenAmount >= bidIncreaseAmount);
    }

    /*
     * NFTs in a batch must contain between 2 and 100 NFTs
    */
    modifier batchWithinLimits(uint256 _batchTokenIdsLength) {
        require(
            _batchTokenIdsLength > 1 && _batchTokenIdsLength <= 10000,
            "Number of NFTs not applicable for batch sale/auction"
        );
        _;
    }

    function _isAuctionOngoing(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        uint256 auctionEndTimestamp = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].auctionEnd;
        //if the auctionEnd is set to 0, the auction is technically on-going, however
        //the minimum bid price (minPrice) has not yet been met.
        return (auctionEndTimestamp == 0 ||
            block.timestamp < auctionEndTimestamp);
    }

    function createBatchNftAuction(
        address _nftContractAddress,
        uint256[] memory _batchTokenIds,
        uint256[] memory _batchTokenPrices,
        address _erc20Token,
        uint256 _auctionBidPeriod, 
        uint256 _bidIncreasePercentage
    )
        external
        batchWithinLimits(_batchTokenIds.length)
        biddingPeriodMinimum(_auctionBidPeriod)
        increasePercentageAboveMinimum(_bidIncreasePercentage)
    {
        require(_batchTokenIds.length == _batchTokenPrices.length,
            "Number of tokens and prices don't match"
        );
        for(uint i=0; i<_batchTokenIds.length; i++){
            require(_batchTokenPrices[i]>0, "Price must be greater than 0");
            nftContractAuctions[_nftContractAddress][_batchTokenIds[i]]
                .auctionBidPeriod = _auctionBidPeriod;
            
            nftContractAuctions[_nftContractAddress][_batchTokenIds[i]]
                .bidIncreasePercentage = _bidIncreasePercentage;
            
            _createNewNftAuction(
                _nftContractAddress,
                _batchTokenIds[i],
                _erc20Token,
                _batchTokenPrices[i]
            );
        }
    }
    
    function createNewNFTAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _minPrice,
        uint256 _auctionBidPeriod, //this is the time that the auction lasts until another bid occurs
        uint256 _bidIncreasePercentage
    ) external
        priceGreaterThanZero(_minPrice)
        biddingPeriodMinimum(_auctionBidPeriod)
        increasePercentageAboveMinimum(_bidIncreasePercentage)
    {
        nftContractAuctions[_nftContractAddress][_tokenId]
            .auctionBidPeriod = _auctionBidPeriod;
        
        nftContractAuctions[_nftContractAddress][_tokenId]
            .bidIncreasePercentage = _bidIncreasePercentage;
        
        _createNewNftAuction(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _minPrice
        );
    }  

    function _setupAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _minPrice
    )
        internal
    { 
        if (_erc20Token != address(0)) {
            nftContractAuctions[_nftContractAddress][_tokenId]
                .ERC20Token = _erc20Token;
        }
        nftContractAuctions[_nftContractAddress][_tokenId].minPrice = _minPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = msg
            .sender;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd= 
        nftContractAuctions[_nftContractAddress][_tokenId]
        .auctionBidPeriod.add(block.timestamp);  
    }

    function _createNewNftAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _minPrice
    ) internal{
        // Sending the NFT to this contract
        IERC721(_nftContractAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
        _setupAuction(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _minPrice
        );
    }

    function _reverseAndResetPreviousBid(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address nftHighestBidder = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBidder;

        uint256 nftHighestBid = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);

        _payout(_nftContractAddress, _tokenId, nftHighestBidder, nftHighestBid);
    }

    function updateMinimumPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _newMinPrice
    )
        external
        onlyNftSeller(_nftContractAddress, _tokenId)
        minimumBidNotMade(_nftContractAddress, _tokenId)
        priceGreaterThanZero(_newMinPrice)
    {
        nftContractAuctions[_nftContractAddress][_tokenId]
            .minPrice = _newMinPrice;
    }

    function _updateHighestBid(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount
    ) internal {
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].ERC20Token;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .nftHighestBidder = msg.sender;

        if (_isERC20Auction(auctionERC20Token)) {
            nftContractAuctions[_nftContractAddress][_tokenId]
                .nftHighestBid = _tokenAmount;
            IERC20(auctionERC20Token).transferFrom(
                msg.sender,
                address(this),
                _tokenAmount
            );
            nftContractAuctions[_nftContractAddress][_tokenId]
                .nftHighestBid = _tokenAmount;
        } else {
            nftContractAuctions[_nftContractAddress][_tokenId]
                .nftHighestBid = msg.value;
        }
    }

    function _reversePreviousBidAndUpdateHighestBid(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount
    ) internal {
        address prevNftHighestBidder = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBidder;

        uint256 prevNftHighestBid = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBid;
        _updateHighestBid(_nftContractAddress, _tokenId, _tokenAmount);

        if (prevNftHighestBidder != address(0)) {
            _payout(
                _nftContractAddress,
                _tokenId,
                prevNftHighestBidder,
                prevNftHighestBid
            );
        }
    }
    
    function _isMinimumBidMade(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        uint256 minPrice = nftContractAuctions[_nftContractAddress][_tokenId]
            .minPrice;
        return
            minPrice > 0 &&
            (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid >=
                minPrice);
    }

    function _setupSale(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _buyNowPrice
    )
        internal
    {
        if (_erc20Token != address(0)) {
            nftContractSale[_nftContractAddress][_tokenId]
                .ERC20Token = _erc20Token;
        }
        nftContractSale[_nftContractAddress][_tokenId]
            .buyNowPrice = _buyNowPrice;
        nftContractSale[_nftContractAddress][_tokenId].nftSeller = msg
            .sender;
    }

    function createSale(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _buyNowPrice
    ) external priceGreaterThanZero(_buyNowPrice) {
        IERC721(_nftContractAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
        _setupSale(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _buyNowPrice
        );
    }

    function createBatchSale(
        address _nftContractAddress,
        uint256[] memory _batchTokenIds,
        uint256[] memory _batchTokenPrice,
        address _erc20Token
    )
        external
        batchWithinLimits(_batchTokenIds.length)
    {
        require(_batchTokenIds.length == _batchTokenPrice.length, "Number of tokens and prices do not match"); 
        for(uint i=0; i< _batchTokenIds.length; i++){
            require(_batchTokenPrice[i]>0, "price cannot be 0 or less");
            IERC721(_nftContractAddress).transferFrom(
            msg.sender,
            address(this),
            _batchTokenIds[i]
        );
            _setupSale(
                _nftContractAddress,
                _batchTokenIds[i],
                _erc20Token,
                _batchTokenPrice[i]
            );
        }
    }

    function buyNFT(
        address _nftContractAddress,
        uint256 _tokenId,
        uint _royaltyPercentage,
        uint256 _ownerPercentage
    )
        external
        payable
        nonReentrant
    {
        address seller= nftContractSale[_nftContractAddress][_tokenId].nftSeller;
        require(msg.sender!=seller, "Seller cannot buy own NFT");
        uint256 buyNowPrice= nftContractSale[_nftContractAddress][_tokenId].buyNowPrice;
        address erc20Token= nftContractSale[_nftContractAddress][_tokenId].ERC20Token;
        if(_isERC20Auction(erc20Token)){
            require(
                IERC20(erc20Token).balanceOf(msg.sender) >= buyNowPrice, 
                "Must be greater than NFT cost"
            );
        }
        else{
            require(
                msg.value >= buyNowPrice, 
                "Must be greater than NFT cost"
            );
        }
        _buyNFT(
            _nftContractAddress,
            _tokenId,
            _royaltyPercentage,
            _ownerPercentage                             
        );
    }
    
    function _buyNFT(
        address _nftContractAddress,
        uint256 _tokenId,
        uint _royaltyPercentage,
        uint256 _ownerPercentage
    )
        internal
    {   
        address seller= nftContractSale[_nftContractAddress][_tokenId].nftSeller;
        address erc20Token= nftContractSale[_nftContractAddress][_tokenId].ERC20Token;
        if(_isERC20Auction(erc20Token)){    // if sale is ERC20
            uint totalAmount= nftContractSale[_nftContractAddress][_tokenId].buyNowPrice;
            uint royaltyAmount= totalAmount.mul(_royaltyPercentage).div(10000);
            uint256 ownerAmount= totalAmount.mul(_ownerPercentage).div(10000);
            uint sellerAmount= totalAmount.sub(royaltyAmount.add(ownerAmount));
            // Reset Sale Data
            _resetSale(_nftContractAddress, _tokenId);
            IERC20(erc20Token).transferFrom(msg.sender, royaltyOwner, royaltyAmount);
            address owner= owner();
            IERC20(erc20Token).transferFrom(msg.sender, owner, ownerAmount);
            IERC20(erc20Token).transferFrom(msg.sender, seller, sellerAmount);
        }
        else{
            uint totalAmount= msg.value;
            uint royaltyAmount= totalAmount.mul(_royaltyPercentage).div(10000);
            uint256 ownerAmount= totalAmount.mul(_ownerPercentage).div(10000);
            uint sellerAmount= totalAmount.sub(royaltyAmount.add(ownerAmount));
            // Reset Sale Data
            _resetSale(_nftContractAddress, _tokenId);
            payable(royaltyOwner).transfer(royaltyAmount);
            address owner= owner();
            payable(owner).transfer(ownerAmount);
            (bool success, ) = payable(seller).call{value: sellerAmount}("");
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
                failedTransferCredits[seller] =
                    failedTransferCredits[seller].add(sellerAmount);
            }
        }
        IERC721(_nftContractAddress).transferFrom(
                address(this),
                msg.sender,
                _tokenId
        );
    }

    function _resetSale(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        nftContractSale[_nftContractAddress][_tokenId]
            .buyNowPrice = 0;
        nftContractSale[_nftContractAddress][_tokenId]
            .nftSeller = address(
            0
        );
        nftContractSale[_nftContractAddress][_tokenId]
            .ERC20Token = address(
            0
        );
    }

    function _makeBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _tokenAmount
    )
        internal
        notNftSeller(_nftContractAddress, _tokenId)
        paymentAccepted(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _tokenAmount
        )
        bidAmountMeetsBidRequirements(
            _nftContractAddress,
            _tokenId,
            _tokenAmount
        )
    {
        _reversePreviousBidAndUpdateHighestBid(
            _nftContractAddress,
            _tokenId,
            _tokenAmount
        );
    }

    function _isABidMade(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return (nftContractAuctions[_nftContractAddress][_tokenId]
            .nftHighestBid > 0);
    }

    function makeBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _tokenAmount
    )
        external
        payable
        nonReentrant
        auctionOngoing(_nftContractAddress, _tokenId)
    {
        require(
            (_tokenAmount>=
            nftContractAuctions[_nftContractAddress][_tokenId].minPrice)            
            || 
            (msg.value >= nftContractAuctions[_nftContractAddress][_tokenId].minPrice)
            ,
            "Must be greater than minimum amount"
        );
        _makeBid(_nftContractAddress, _tokenId, _erc20Token, _tokenAmount);
    }

    /*
     * Reset all auction related parameters for an NFT.
     * This effectively removes an EFT as an item up for auction
    */
    function _resetAuction(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        nftContractAuctions[_nftContractAddress][_tokenId].minPrice = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod = 0;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .bidIncreasePercentage = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = address(
            0
        );
        nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token = address(
            0
        );
    }

    function _payout(
        address _nftContractAddress,
        uint256 _tokenId,
        address _recipient,
        uint256 _amount
    ) internal{
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].ERC20Token;
        if (_isERC20Auction(auctionERC20Token)) {
            // pay royalty owner
            IERC20(auctionERC20Token).transfer(_recipient, _amount);
        } else {
            // attempt to send the funds to the recipient
            (bool success, ) = payable(_recipient).call{value: _amount}("");
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
                failedTransferCredits[_recipient] =
                    failedTransferCredits[_recipient].add(_amount);
            }
        }
    }

    /*
     * If the transfer of a bid has failed, allow the recipient to reclaim their amount later.
    */
    function withdrawAllFailedCredits() external {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0, "no credits to withdraw");

        failedTransferCredits[msg.sender] = 0;

        (bool successfulWithdraw, ) = msg.sender.call{value: amount}("");
        require(successfulWithdraw, "withdraw failed");
    }


    function _resetBids(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        nftContractAuctions[_nftContractAddress][_tokenId]
            .nftHighestBidder = address(0);
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = 0;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .nftRecipient = address(0);
    }

    /*
     * The default value for the NFT recipient is the highest bidder
     */
    function _getNftRecipient(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (address)
    {
        address nftRecipient = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftRecipient;

        if (nftRecipient == address(0)) {
            return
                nftContractAuctions[_nftContractAddress][_tokenId]
                    .nftHighestBidder;
        } else {
            return nftRecipient;
        }
    }
    
    function _payFeesAndSeller(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        uint256 _highestBid
    ) internal {
        // pay royalty and owner
        address erc20Token= nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token;
        uint royaltyAmount= _highestBid.mul(royaltyPercentage).div(10000);
        uint256 ownerAmount= _highestBid.mul(ownerPercentage).div(10000);
        uint sellerAmount= _highestBid.sub(royaltyAmount.add(ownerAmount));
        // Reset Sale Data
        _resetAuction(_nftContractAddress, _tokenId);
        if(_isERC20Auction(erc20Token)){    // if sale is ERC20
            IERC20(erc20Token).transfer(royaltyOwner, royaltyAmount);
            address owner= owner();
            IERC20(erc20Token).transfer(owner, ownerAmount);
        }
        else{
            payable(royaltyOwner).transfer(royaltyAmount);
            address owner= owner();
            payable(owner).transfer(ownerAmount);
        }
        _payout(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            sellerAmount
        );
    }

    /*
     * Query the owner of an NFT deposited for auction
     */
    function ownerOfNFT(address _nftContractAddress, uint256 _tokenId)
        external
        view
        returns (address)
    {
        address nftSeller = nftContractAuctions[_nftContractAddress][_tokenId]
            .nftSeller;
        if (nftSeller != address(0)) {
            return nftSeller;
        }
        address owner = nftOwner[_nftContractAddress][_tokenId];

        require(owner != address(0), "NFT not deposited");
        return owner;
    }

    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId]
            .nftSeller;
        address _nftRecipient = _getNftRecipient(_nftContractAddress, _tokenId);
        uint256 _nftHighestBid = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);
        _payFeesAndSeller(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftHighestBid
        );
        
        IERC721(_nftContractAddress).transferFrom(
            address(this),
            _nftRecipient,
            _tokenId
        );
    }

    function takeHighestBid(address _nftContractAddress, uint256 _tokenId)
        external
        onlyNftSeller(_nftContractAddress, _tokenId)
    {
        require(
            _isABidMade(_nftContractAddress, _tokenId),
            "cannot payout 0 bid"
        );
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);
    }

    function settleAuction(address _nftContractAddress, uint256 _tokenId)
        external
        nonReentrant
        isAuctionOver(_nftContractAddress, _tokenId)
    {
        uint256 _nftHighestBid = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBid;
        require(_nftHighestBid > 0, "No bid has been made");
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);
    }


    function settleAuctionOnlyOwner(address _nftContractAddress, uint256 _tokenId)
        external
        onlyOwner
        nonReentrant
        isAuctionOver(_nftContractAddress, _tokenId)
    {
        require(block.timestamp> (nftContractAuctions[_nftContractAddress][_tokenId]
        .auctionEnd.add(
            86400)), 
            "Can't settle before 1 day of grace period has passed"
        );
        // 10% is cut as a penalty.
        uint totalAmt= nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        address erc20Token= nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token;
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid=
            totalAmt.mul(100-settlePenalty).div(100);
        uint penaltyAmt= totalAmt.mul(settlePenalty).div(100);
        address owner = owner();
        if(_isERC20Auction(erc20Token)){
            IERC20(erc20Token).transfer(owner, penaltyAmt);
        }
        else{
            (bool success, ) = payable(owner).call{value: penaltyAmt}("");
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
                failedTransferCredits[owner] =
                    failedTransferCredits[owner].add(penaltyAmt);
            }
        }
        
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);
    }

    function withdrawSale(address _nftContractAddress, uint256 _tokenId)
        external
        nonReentrant
    {
        address nftSeller= nftContractSale[_nftContractAddress][_tokenId].nftSeller;
        require(nftSeller== msg.sender, "Only the owner can call this function");
        // reset sale
        _resetSale(_nftContractAddress, _tokenId);
        // transfer the NFT back to the Seller
        IERC721(_nftContractAddress).transferFrom(
            address(this),
            nftSeller,
            _tokenId
        );
    }

    function withdrawAuction(address _nftContractAddress, uint256 _tokenId)
        external
        nonReentrant
        onlyNftSeller(_nftContractAddress, _tokenId)
    {
        address _nftRecipient= nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
        address prevNftHighestBidder = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBidder;
        uint256 prevNftHighestBid = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBid;

        // Reset values of this Auction
        _resetBids(_nftContractAddress, _tokenId);
        _resetAuction(_nftContractAddress, _tokenId);
        IERC721(_nftContractAddress).transferFrom(
            address(this),
            _nftRecipient,
            _tokenId
        );
        
        // Pay any bidder if present
        if (prevNftHighestBidder != address(0)) {
            _payout(
                _nftContractAddress,
                _tokenId,
                prevNftHighestBidder,
                prevNftHighestBid
            );
        }
    }

    function setRoyaltyOwner(address _royaltyOwner) external onlyOwner{
        royaltyOwner= _royaltyOwner;
    }
    function setRoyaltyPercentage(uint256 _royaltyPercentage) external onlyOwner{
        royaltyPercentage= _royaltyPercentage;
    }
    function setOwnerPercentage(uint256 _ownerPercentage) external onlyOwner{
        ownerPercentage= _ownerPercentage;
    }
    function setSettlePenalty(uint256 _settlePenalty) external onlyOwner{
        settlePenalty= _settlePenalty;
    }

}