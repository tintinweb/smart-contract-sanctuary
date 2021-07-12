/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File contracts/utils/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File contracts/utils/ReentrancyGuard.sol


pragma solidity >=0.6.0 <0.8.0;

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

    constructor () {
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


// File contracts/interfaces/IERC20.sol


pragma solidity >=0.6.0 <0.8.0;

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


// File contracts/utils/Context.sol


pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/interfaces/IERC721Receiver.sol


pragma solidity >=0.6.0 <0.8.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


// File contracts/interfaces/IERC165.sol


pragma solidity >=0.6.0 <0.8.0;

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


// File contracts/interfaces/IERC721.sol


pragma solidity >=0.6.2 <0.8.0;

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


// File contracts/interfaces/IZestyNFT.sol


pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IZestyNFT is IERC721 {
    function getTokenData(uint256 tokenId) 
    external
    view 
    returns (
        address creator,
        uint256 timeCreated,
        uint256 zestyTokenValue,
        string memory uri
    ); 
    function getZestyTokenAddress() external view returns (address);
    function setZestyTokenAddress(address zestyTokenAddress_) external;
    function mint(string memory _uri) external;
    function burn(uint256 _tokenId) external;
    function setTokenURI(uint256 _tokenId, string memory uri) external;
    function lockZestyToken(uint256 _tokenId, uint256 _value) external;
}


// File contracts/market/ZestyVault.sol

pragma solidity ^0.7.6;



/**
 * @title ZestyVault for depositing ZestyNFTs
 * @author Zesty Market
 * @notice Contract for depositing and withdrawing ZestyNFTs
 */
abstract contract ZestyVault is Context, IERC721Receiver {
    address private _zestyNFTAddress;
    IZestyNFT internal _zestyNFT;
    
    constructor(address zestyNFTAddress_) {
        _zestyNFTAddress = zestyNFTAddress_;
        _zestyNFT = IZestyNFT(zestyNFTAddress_);
    }

    mapping (uint256 => address) private _nftDeposits;
    mapping (address => address) private _nftDepositOperators;

    event DepositZestyNFT(uint256 indexed tokenId, address depositor);
    event WithdrawZestyNFT(uint256 indexed tokenId);
    event AuthorizeOperator(address indexed depositor, address operator);
    event RevokeOperator(address indexed depositor, address operator);

    /*
     * Getter functions
     */

    function getZestyNFTAddress() public virtual view returns (address) {
        return _zestyNFTAddress;
    }

    function getDepositor(uint256 _tokenId) public virtual view returns (address) {
        return _nftDeposits[_tokenId];
    }

    function isDepositor(uint256 _tokenId) public virtual view returns (bool) {
        return _msgSender() == getDepositor(_tokenId);
    }

    function getOperator(address _depositor) public virtual view returns (address) {
        return _nftDepositOperators[_depositor];
    }

    function isOperator(address _depositor, address _operator) public virtual view returns (bool) {
        return _nftDepositOperators[_depositor] == _operator;
    }

    /*
     * Operator functionality
     */
    function authorizeOperator(address _operator) public virtual {
        require(_msgSender() != _operator, "ZestyVault: authorizing self as operator");

        _nftDepositOperators[_msgSender()] = _operator;

        emit AuthorizeOperator(_msgSender(), _operator);
    }

    function revokeOperator(address _operator) public virtual {
        require(_msgSender() != _operator, "ZestyVault: revoking self as operator");

        delete _nftDepositOperators[_msgSender()];

        emit RevokeOperator(_msgSender(), _operator);
    }

    /*
     * NFT Deposit and Withdrawal Functions
     */

    function _depositZestyNFT(uint256 _tokenId) internal virtual {
        require(
            _zestyNFT.getApproved(_tokenId) == address(this),
            "ZestyVault::_depositZestyNFT: Contract is not approved to manage token"
        );

        _nftDeposits[_tokenId] = _msgSender();
        _zestyNFT.safeTransferFrom(_msgSender(), address(this), _tokenId);

        emit DepositZestyNFT(_tokenId, _msgSender());
    }

    function _withdrawZestyNFT(uint256 _tokenId) internal virtual onlyDepositor(_tokenId) {
        delete _nftDeposits[_tokenId];

        _zestyNFT.safeTransferFrom(address(this), _msgSender(), _tokenId);

        emit WithdrawZestyNFT(_tokenId);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }


    modifier onlyDepositor(uint256 _tokenId) {
        require(
            getDepositor(_tokenId) == _msgSender(),
            "ZestyVault::onlyDepositor: Not depositor"
        );
        _;
    }

    modifier onlyOperator(uint256 _tokenId) {
        require(
            getOperator(getDepositor(_tokenId)) == _msgSender(),
            "ZestyVault::onlyOperator: Not operator"
        );
        _;
    }

    modifier onlyDepositorOrOperator(uint256 _tokenId) {
        require(
            getDepositor(_tokenId) == _msgSender() 
            || getOperator(getDepositor(_tokenId)) == _msgSender(),
            "ZestyVault::onlyDepositorOrOperator: Not depositor or operator"
        );
        _;
    }
}


// File contracts/market/ZestyMarket_ERC20_V1_1.sol

pragma solidity ^0.7.6;




contract ZestyMarket_ERC20_V1_1 is ZestyVault, ReentrancyGuard {
    using SafeMath for uint256;

    address private _txTokenAddress;
    IERC20 private _txToken;
    uint256 private _buyerCampaignCount = 1; // 0 is used null values
    uint256 private _sellerAuctionCount = 1; // 0 is used for null values
    uint256 private _contractCount = 1;
    uint8 private constant _FALSE = 1;
    uint8 private constant _TRUE = 2;

    constructor(
        address txTokenAddress_,
        address zestyNFTAddress_
    ) 
        ZestyVault(zestyNFTAddress_) 
    {
        _txTokenAddress = txTokenAddress_;
        _txToken = IERC20(txTokenAddress_);
    }
    
    struct SellerNFTSetting {
        uint256 tokenId;
        address seller;
        uint8 autoApprove;
        uint256 inProgressCount;
    }
    mapping (uint256 => SellerNFTSetting) private _sellerNFTSettings; 
    mapping (address => mapping(address => uint8)) private _sellerBans;

    event SellerNFTDeposit(uint256 indexed tokenId, address seller, uint8 autoApprove);
    event SellerNFTUpdate(uint256 indexed tokenId, uint8 autoApprove, uint256 inProgressCount);
    event SellerNFTWithdraw(uint256 indexed tokenId);
    event SellerBan(address indexed seller, address indexed banAddress);
    event SellerUnban(address indexed seller, address indexed banAddress);

    struct SellerAuction {
        address seller;
        uint256 tokenId;
        uint256 auctionTimeStart;
        uint256 auctionTimeEnd;
        uint256 contractTimeStart;
        uint256 contractTimeEnd;
        uint256 priceStart;
        uint256 pricePending;
        uint256 priceEnd;
        uint256 buyerCampaign;
        uint8 buyerCampaignApproved;
    }
    mapping (uint256 => SellerAuction) private _sellerAuctions; 

    event SellerAuctionCreate(
        uint256 indexed sellerAuctionId, 
        address seller,
        uint256 tokenId,
        uint256 auctionTimeStart,
        uint256 auctionTimeEnd,
        uint256 contractTimeStart,
        uint256 contractTimeEnd,
        uint256 priceStart,
        uint8 buyerCampaignApproved
    );
    event SellerAuctionCancel(uint256 indexed sellerAuctionId);
    event SellerAuctionBuyerCampaignNew(
        uint256 indexed sellerAuctionId, 
        uint256 buyerCampaignId,
        uint256 pricePending
    );
    event SellerAuctionBuyerCampaignBuyerCancel(uint256 indexed sellerAuctionId);
    event SellerAuctionBuyerCampaignApprove( uint256 indexed sellerAuctionId, uint256 priceEnd);
    event SellerAuctionBuyerCampaignReject( uint256 indexed sellerAuctionId);

    struct BuyerCampaign {
        address buyer;
        string uri;
    }
    mapping (uint256 => BuyerCampaign) private _buyerCampaigns;

    event BuyerCampaignCreate(
        uint256 indexed buyerCampaignId, 
        address buyer, 
        string uri
    );

    struct Contract {
        uint256 sellerAuctionId;
        uint256 buyerCampaignId;
        uint256 contractValue;
        uint8 withdrawn;
    }

    mapping (uint256 => Contract) private _contracts; 

    event ContractCreate (
        uint256 indexed contractId,
        uint256 sellerAuctionId,
        uint256 buyerCampaignId,
        uint256 contractTimeStart,
        uint256 contractTimeEnd,
        uint256 contractValue
    );
    event ContractWithdraw(uint256 indexed contractId);

    function getTxTokenAddress() external view returns (address) {
        return _txTokenAddress;
    }

    function getSellerNFTSetting(uint256 _tokenId) 
        public 
        view
        returns (
            uint256 tokenId,
            address seller,
            uint8 autoApprove,
            uint256 inProgressCount
        ) 
    {
        tokenId = _sellerNFTSettings[_tokenId].tokenId;
        seller = _sellerNFTSettings[_tokenId].seller;
        autoApprove = _sellerNFTSettings[_tokenId].autoApprove;
        inProgressCount = _sellerNFTSettings[_tokenId].inProgressCount;
    }

    function getSellerAuctionPrice(uint256 _sellerAuctionId) public view returns (uint256) {
        SellerAuction storage s = _sellerAuctions[_sellerAuctionId];
        uint256 timeNow = block.timestamp;
        uint256 timeTotal = s.contractTimeEnd.sub(s.auctionTimeStart);
        uint256 rescalePriceStart = s.priceStart.mul(100000);
        uint256 gradient = rescalePriceStart.div(timeTotal);

        return rescalePriceStart.sub(gradient.mul(timeNow.sub(s.auctionTimeStart))).div(100000);
    }

    function getSellerAuction(uint256 _sellerAuctionId) 
        public 
        view 
        returns (
            address seller,
            uint256 tokenId,
            uint256 auctionTimeStart,
            uint256 auctionTimeEnd,
            uint256 contractTimeStart,
            uint256 contractTimeEnd,
            uint256 priceStart,
            uint256 pricePending,
            uint256 priceEnd,
            uint256 buyerCampaign,
            uint8 buyerCampaignApproved
        )
    {
        seller = _sellerAuctions[_sellerAuctionId].seller;
        tokenId = _sellerAuctions[_sellerAuctionId].tokenId;
        auctionTimeStart = _sellerAuctions[_sellerAuctionId].auctionTimeStart;
        auctionTimeEnd = _sellerAuctions[_sellerAuctionId].auctionTimeEnd;
        contractTimeStart = _sellerAuctions[_sellerAuctionId].contractTimeStart;
        contractTimeEnd = _sellerAuctions[_sellerAuctionId].contractTimeEnd;
        priceStart = _sellerAuctions[_sellerAuctionId].priceStart;
        pricePending = _sellerAuctions[_sellerAuctionId].pricePending;
        priceEnd = _sellerAuctions[_sellerAuctionId].priceEnd;
        buyerCampaign = _sellerAuctions[_sellerAuctionId].buyerCampaign;
        buyerCampaignApproved = _sellerAuctions[_sellerAuctionId].buyerCampaignApproved;
    }

    function getBuyerCampaign(uint256 _buyerCampaignId)
        public
        view
        returns (
            address buyer,
            string memory uri
        )
    {
        buyer = _buyerCampaigns[_buyerCampaignId].buyer;
        uri = _buyerCampaigns[_buyerCampaignId].uri;
    }

    function getContract(uint256 _contractId)
        public
        view
        returns (
            uint256 sellerAuctionId,
            uint256 buyerCampaignId,
            uint256 contractTimeStart,
            uint256 contractTimeEnd,
            uint256 contractValue,
            uint8 withdrawn
        )
    {
        sellerAuctionId = _contracts[_contractId].sellerAuctionId;
        buyerCampaignId = _contracts[_contractId].buyerCampaignId;
        contractTimeStart = _sellerAuctions[sellerAuctionId].contractTimeStart;
        contractTimeEnd = _sellerAuctions[sellerAuctionId].contractTimeEnd;
        contractValue = _contracts[_contractId].contractValue;
        withdrawn = _contracts[_contractId].withdrawn;
    }

    /* 
     * Buyer logic
     */

    function buyerCampaignCreate(string memory _uri) external {
        _buyerCampaigns[_buyerCampaignCount] = BuyerCampaign(
            msg.sender,
            _uri
        );
        emit BuyerCampaignCreate(
            _buyerCampaignCount,
            msg.sender,
            _uri
        );
        _buyerCampaignCount = _buyerCampaignCount.add(1);
    }

    /* 
     * Seller logic
     */
    function sellerNFTDeposit(
        uint256 _tokenId,
        uint8 _autoApprove
    ) 
        external 
        nonReentrant
    {
        require(
            _autoApprove == _TRUE || _autoApprove == _FALSE,
            "ZestyMarket_ERC20_V1::sellerNFTDeposit: _autoApprove must be uint8 1 (FALSE) or 2 (TRUE)"
        );
        _depositZestyNFT(_tokenId);

        _sellerNFTSettings[_tokenId] = SellerNFTSetting(
            _tokenId,
            msg.sender, 
            _autoApprove,
            0
        );

        emit SellerNFTDeposit(
            _tokenId,
            msg.sender,
            _autoApprove
        );
    }

    function sellerNFTWithdraw(uint256 _tokenId) external onlyDepositor(_tokenId) nonReentrant {
        SellerNFTSetting storage s = _sellerNFTSettings[_tokenId];
        require(
            s.inProgressCount == 0, 
            "ZestyMarket_ERC20_V1::sellerNFTWithdraw Auction or Contact is in progress withdraw"
        );
        _withdrawZestyNFT(_tokenId);
        delete _sellerNFTSettings[_tokenId];
        emit SellerNFTWithdraw(_tokenId);
    }

    function sellerNFTUpdate(
        uint256 _tokenId,
        uint8 _autoApprove
    ) 
        external
        onlyDepositorOrOperator(_tokenId)
    {
        require(
            _autoApprove == _TRUE || _autoApprove == _FALSE,
            "ZestyMarket_ERC20_V1::sellerNFTUpdate _autoApprove must be uint8 1 (FALSE) or 2 (TRUE)"
        );
        SellerNFTSetting storage s = _sellerNFTSettings[_tokenId];
        s.autoApprove = _autoApprove;

        emit SellerNFTUpdate(
            _tokenId,
            _autoApprove,
            s.inProgressCount
        );
    }

    function sellerBan(address _addr) external {
        _sellerBans[msg.sender][_addr] = _TRUE;
        emit SellerBan(msg.sender, _addr);
    }

    function sellerUnban(address _addr) external {
        _sellerBans[msg.sender][_addr] = _FALSE;
        emit SellerUnban(msg.sender, _addr);
    }

    function sellerAuctionCreateBatch(
        uint256 _tokenId,
        uint256[] memory _auctionTimeStart,
        uint256[] memory _auctionTimeEnd,
        uint256[] memory _contractTimeStart,
        uint256[] memory _contractTimeEnd,
        uint256[] memory _priceStart
    ) 
        external 
        onlyDepositorOrOperator(_tokenId)
    {
        require(
            _auctionTimeStart.length == _auctionTimeEnd.length && 
            _auctionTimeEnd.length == _contractTimeStart.length &&
            _contractTimeStart.length == _contractTimeEnd.length &&
            _contractTimeEnd.length == _priceStart.length,
            "ZestyMarket_ERC20_V1::sellerAuctionCreateBatch: Array length not equal"
        );

        address _seller = getDepositor(_tokenId);

        for (uint i=0; i < _auctionTimeStart.length; i++) {
            require(
                _priceStart[i] > 0, 
                "ZestyMarket_ERC20_V1::sellerAuctionCreateBatch: Starting Price of the Auction must be greater than 0"
            );
            require(
                _auctionTimeStart[i] > block.timestamp,
                "ZestyMarket_ERC20_V1::sellerAuctionCreateBatch: Starting time of the Auction must be greater than current block timestamp"
            );
            require(
                _auctionTimeEnd[i] > _auctionTimeStart[i],
                "ZestyMarket_ERC20_V1::sellerAuctionCreateBatch: Ending time of the Auction must be greater than the starting time of Auction"
            );
            require(
                _contractTimeStart[i] > _auctionTimeStart[i],
                "ZestyMarket_ERC20_V1::sellerAuctionCreateBatch: Starting time of the Contract must be greater than the starting time of Auction"
            );
            require(
                _contractTimeEnd[i] > _auctionTimeStart[i],
                "ZestyMarket_ERC20_V1::sellerAuctionCreateBatch: Ending time of the Contract must be greater than the starting time of Contract"
            );
            require(
                _contractTimeEnd[i] > _auctionTimeEnd[i],
                "ZestyMarket_ERC20_V1::sellerAuctionCreateBatch: Ending time of the Contract must be greater than the ending time of Auction"
            );
            require(
                _contractTimeEnd[i] > _contractTimeStart[i],
                "ZestyMarket_ERC20_V1::sellerAuctionCreateBatch: Ending time of the Contract must be greater than the starting time of Contract"
            );

            SellerNFTSetting storage s = _sellerNFTSettings[_tokenId];
            s.inProgressCount = s.inProgressCount.add(1);

            emit SellerNFTUpdate(
                _tokenId,
                s.autoApprove,
                s.inProgressCount
            );

            
            _sellerAuctions[_sellerAuctionCount] = SellerAuction(
                _seller,
                _tokenId,
                _auctionTimeStart[i],
                _auctionTimeEnd[i],
                _contractTimeStart[i],
                _contractTimeEnd[i],
                _priceStart[i],
                0,
                0,
                0,
                s.autoApprove
            );

            emit SellerAuctionCreate(
                _sellerAuctionCount,
                _seller,
                _tokenId,
                _auctionTimeStart[i],
                _auctionTimeEnd[i],
                _contractTimeStart[i],
                _contractTimeEnd[i],
                _priceStart[i],
                s.autoApprove
            );

            _sellerAuctionCount = _sellerAuctionCount.add(1);
        }
    }

    function sellerAuctionCancelBatch(uint256[] memory _sellerAuctionId) external {
        for(uint i=0; i < _sellerAuctionId.length; i++) {
            SellerAuction storage s = _sellerAuctions[_sellerAuctionId[i]];
            require(
                s.seller != address(0), 
                "ZestyMarket_ERC20_V1::sellerAuctionCancelBatch: Seller Auction is invalid"
            );
            require(
                s.seller == msg.sender || isOperator(s.seller, msg.sender), 
                "ZestyMarket_ERC20_V1::sellerAuctionCancelBatch: Not seller or operator for seller"
            );
            require(
                s.buyerCampaign == 0,
                "ZestyMarket_ERC20_V1::sellerAuctionCancelBatch: Reject buyer campaign before cancelling"
            );

            SellerNFTSetting storage se = _sellerNFTSettings[s.tokenId];
            se.inProgressCount = se.inProgressCount.sub(1);

            delete _sellerAuctions[_sellerAuctionId[i]];

            emit SellerAuctionCancel(_sellerAuctionId[i]);
            emit SellerNFTUpdate(
                s.tokenId,
                se.autoApprove,
                se.inProgressCount
            );
        }
    }

    function sellerAuctionBidBatch(uint256[] memory _sellerAuctionId, uint256 _buyerCampaignId) external nonReentrant {
        for (uint i=0; i < _sellerAuctionId.length; i++) {
            SellerAuction storage s = _sellerAuctions[_sellerAuctionId[i]];
            BuyerCampaign storage b = _buyerCampaigns[_buyerCampaignId];
            require(
                block.timestamp >= s.auctionTimeStart, 
                "ZestyMarket_ERC20_V1::sellerAuctionBidBatch: Auction has yet to start"
            );
            require(
                s.auctionTimeEnd >= block.timestamp, 
                "ZestyMarket_ERC20_V1::sellerAuctionBidBatch: Auction has ended"
            );
            require(
                s.seller != address(0), 
                "ZestyMarket_ERC20_V1::sellerAuctionBidBatch: Seller Auction is invalid"
            );
            require(
                s.seller != msg.sender, 
                "ZestyMarket_ERC20_V1::sellerAuctionBidBatch: Cannot bid on own auction"
            );
            require(
                s.buyerCampaign == 0, 
                "ZestyMarket_ERC20_V1::sellerAuctionBidBatch: Already has a bid"
            );
            require(
                b.buyer != address(0), 
                "ZestyMarket_ERC20_V1::sellerAuctionBidBatch: Buyer Campaign is invalid"
            );
            require(
                b.buyer == msg.sender || isOperator(b.buyer, msg.sender), 
                "ZestyMarket_ERC20_V1::sellerAuctionBidBatch: Not buyer or operator for buyer"
            );
            require(
                _sellerBans[s.seller][b.buyer] != _TRUE,
                "ZestyMarket_ERC20_V1::sellerAuctionBidBatch: Banned by seller"
            );

            s.buyerCampaign = _buyerCampaignId;

            uint256 price = getSellerAuctionPrice(_sellerAuctionId[i]);
            require(
                price > 0, 
                "ZestyMarket_ERC20_V1::sellerAuctionBidBatch: Auction has expired"
            );
            s.pricePending = price;

            require(
                _txToken.transferFrom(b.buyer, address(this), price),
                "ZestyMarket_ERC20_V1::sellerAuctionBidBatch: Transfer of ERC20 failed, check if sufficient allowance is provided"
            );

            emit SellerAuctionBuyerCampaignNew(
                _sellerAuctionId[i],
                _buyerCampaignId,
                price
            );

            // if auto approve is set to true
            if (s.buyerCampaignApproved == _TRUE) {
                s.pricePending = 0;
                s.priceEnd = price;
                _contracts[_contractCount] = Contract(
                    _sellerAuctionId[i],
                    _buyerCampaignId,
                    price,
                    _FALSE
                );

                emit SellerAuctionBuyerCampaignApprove( _sellerAuctionId[i], price);
                emit ContractCreate(
                    _contractCount,
                    _sellerAuctionId[i],
                    _buyerCampaignId,
                    s.contractTimeStart,
                    s.contractTimeEnd,
                    price
                );
                _contractCount = _contractCount.add(1);
            }
        }
    }

    function sellerAuctionBidCancelBatch(uint256[] memory _sellerAuctionId) external nonReentrant {
        for (uint i=0; i < _sellerAuctionId.length; i++) {
            BuyerCampaign storage b = _buyerCampaigns[_sellerAuctions[_sellerAuctionId[i]].buyerCampaign];
            require(
                _sellerAuctions[_sellerAuctionId[i]].seller != address(0), 
                "ZestyMarket_ERC20_V1::sellerAuctionBidCancelBatch: Seller Auction is invalid");
            require(
                msg.sender == b.buyer || isOperator(b.buyer, msg.sender), 
                "ZestyMarket_ERC20_V1::sellerAuctionBidCancelBatch: Not buyer or operator for buyer"
            );
            require(
                _sellerAuctions[_sellerAuctionId[i]].buyerCampaignApproved == _FALSE, 
                "ZestyMarket_ERC20_V1::sellerAuctionBidCancelBatch: Seller has approved"
            );

            uint256 pricePending = _sellerAuctions[_sellerAuctionId[i]].pricePending;
            _sellerAuctions[_sellerAuctionId[i]].pricePending = 0;
            _sellerAuctions[_sellerAuctionId[i]].buyerCampaign = 0;

            require(
                _txToken.transfer(b.buyer, pricePending),
                "ZestyMarket_ERC20_V1::sellerAuctionBidCancelBatch: Transfer of ERC20 failed"
            );

            emit SellerAuctionBuyerCampaignBuyerCancel(_sellerAuctionId[i]);
        }
    }

    function sellerAuctionApproveBatch(uint256[] memory _sellerAuctionId) external nonReentrant {
        for (uint i=0; i < _sellerAuctionId.length; i++) {
            SellerAuction storage s = _sellerAuctions[_sellerAuctionId[i]];
            require(
                s.seller != address(0), 
                "ZestyMarket_ERC20_V1::sellerAuctionApproveBatch: Seller auction is invalid"
            );
            require(
                s.seller == msg.sender || isOperator(s.seller, msg.sender), 
                "ZestyMarket_ERC20_V1::sellerAuctionApproveBatch: Not seller or operator for seller"
            );
            require(
                s.buyerCampaign != 0, 
                "ZestyMarket_ERC20_V1::sellerAuctionApproveBatch: Does not have a bid"
            );
            require(
                s.buyerCampaignApproved == _FALSE, 
                "ZestyMarket_ERC20_V1::sellerAuctionApproveBatch: Already approved"
            );

            uint256 price = getSellerAuctionPrice(_sellerAuctionId[i]);
            require(
                price > 0, 
                "ZestyMarket_ERC20_V1::sellerAuctionApproveBatch: Auction has expired"
            );

            s.priceEnd = price;
            uint256 priceDiff = s.pricePending.sub(s.priceEnd);
            s.pricePending = 0;

            require(
                _txToken.transfer(_buyerCampaigns[s.buyerCampaign].buyer, priceDiff),
                "ZestyMarket_ERC20_V1::sellerAuctionApproveBatch: Transfer of ERC20 failed"
            );

            s.buyerCampaignApproved = _TRUE;
            _contracts[_contractCount] = Contract(
                _sellerAuctionId[i],
                s.buyerCampaign,
                s.priceEnd,
                _FALSE
            );

            emit SellerAuctionBuyerCampaignApprove( _sellerAuctionId[i], s.priceEnd);
            emit ContractCreate(
                _contractCount,
                _sellerAuctionId[i],
                s.buyerCampaign,
                s.contractTimeStart,
                s.contractTimeEnd,
                s.priceEnd
            );
            _contractCount = _contractCount.add(1);
        }
    }

    function sellerAuctionRejectBatch(uint256[] memory _sellerAuctionId) external nonReentrant {
        for (uint i=0; i < _sellerAuctionId.length; i++) {
            SellerAuction storage s = _sellerAuctions[_sellerAuctionId[i]];
            require(
                s.seller != address(0), 
                "ZestyMarket_ERC20_V1::sellerAuctionRejectBatch: Seller auction is invalid"
            );
            require(
                s.seller == msg.sender || isOperator(s.seller, msg.sender), 
                "ZestyMarket_ERC20_V1::sellerAuctionRejectBatch: Not seller or operator for seller"
            );
            require(
                s.buyerCampaign != 0, 
                "ZestyMarket_ERC20_V1::sellerAuctionRejectBatch: Does not have a bid"
            );
            require(
                s.buyerCampaignApproved == _FALSE,
                "ZestyMarket_ERC20_V1::sellerAuctionRejectBatch: Already approved"
            );

            uint256 pricePending = s.pricePending;
            s.pricePending = 0;

            require(
                _txToken.transfer(_buyerCampaigns[s.buyerCampaign].buyer, pricePending),
                "ZestyMarket_ERC20_V1::sellerAuctionRejectBatch: Transfer of ERC20 failed"
            );

            s.buyerCampaign = 0;

            emit SellerAuctionBuyerCampaignReject(_sellerAuctionId[i]);
        }
    }

    function contractWithdrawBatch(uint256[] memory _contractId) external nonReentrant {
        for(uint i=0; i < _contractId.length; i++) {
            Contract storage c = _contracts[_contractId[i]];
            SellerAuction storage s = _sellerAuctions[c.sellerAuctionId];

            require(
                s.seller == msg.sender || isOperator(s.seller, msg.sender), 
                "ZestyMarket_ERC20_V1::contractWithdrawBatch: Not seller or operator"
            );
            require(
                c.sellerAuctionId != 0 && c.buyerCampaignId != 0,
                "ZestyMarket_ERC20_V1::contractWithdrawBatch: Invalid contract"
            );
            require(
                block.timestamp > s.contractTimeEnd, 
                "ZestyMarket_ERC20_V1::contractWithdrawBatch: Contract has not ended"
            );
            require(
                c.withdrawn == _FALSE, 
                "ZestyMarket_ERC20_V1::contractWithdrawBatch: Already withdrawn"
            );

            c.withdrawn = _TRUE;

            require(
                _txToken.transfer(s.seller, c.contractValue),
                "ZestyMarket_ERC20_V1::contractWithdrawBatch: Transfer of ERC20 failed"

            );

            SellerNFTSetting storage se = _sellerNFTSettings[s.tokenId];
            se.inProgressCount = se.inProgressCount.sub(1);

            emit SellerNFTUpdate(
                se.tokenId,
                se.autoApprove,
                se.inProgressCount
            );

            emit ContractWithdraw(_contractId[i]);
        }
    }
}