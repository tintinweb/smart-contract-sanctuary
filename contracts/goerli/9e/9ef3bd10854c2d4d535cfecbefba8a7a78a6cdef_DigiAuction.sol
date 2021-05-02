/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: contracts/IDigiNFT.sol

pragma solidity 0.6.5;

interface IDigiNFT {
    function mint(
        address wallet,
        string calldata cardName,
        bool cardPhysical
    ) external returns (uint256);

    function cardName(uint256 tokenId) external view returns (string memory);
    function cardPhysical(uint256 tokenId) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

// File: contracts/DigiAuction.sol

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;






contract DigiAuction is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint8;

    uint256 BIGNUMBER = 10 ** 18;

    /******************
    CONFIG
    ******************/
    uint256 public purchaseFee = 500;   // 5%
    uint256 public digiAmountRequired = 1000 * (BIGNUMBER);

    /******************
    EVENTS
    ******************/
    event CreatedAuction(uint256 auctionId, address indexed wallet, uint256 tokenId, uint256 created);
    event CanceledAuction(uint256 auctionId, address indexed wallet, uint256 tokenId, uint256 created);
    event NewHighestOffer(uint256 auctionId, address indexed wallet, uint256 amount, uint256 created);
    event DirectBuyed(uint256 auctionId, address indexed wallet, uint256 amount, uint256 created);
    event Claimed(uint256 auctionId, address indexed wallet, uint256 amount, uint256 created);
    event Log(uint256 data);

    /******************
    INTERNAL ACCOUNTING
    *******************/
    address public stakeERC20;
    address public digiERC271;
    address public stableERC20;
    address[] public feesDestinators;
    uint256[] public feesPercentages;

    uint256 public auctionCount = 0;

    mapping (uint256 => Auction) public auctions;
    mapping (uint256 => bool) public claimedAuctions;
    mapping (uint256 => Offer) public highestOffers;
    mapping (uint256 => uint256) public lastAuctionByToken;

    struct Auction {
        uint256 tokenId;
        address owner;
        uint256 minPrice;
        uint256 fixedPrice;
        bool buyed;
        uint256 endDate;
    }

    struct Offer {
        address buyer;
        uint256 offer;
        uint256 date;
    }

    /******************
    PUBLIC FUNCTIONS
    *******************/
    constructor(
        address _stakeERC20,
        address _digiERC271,
        address _stableERC20
    )
        public
    {
        require(address(_stakeERC20) != address(0)); 
        require(address(_digiERC271) != address(0));
        require(address(_stableERC20) != address(0));

        stakeERC20 = _stakeERC20;
        digiERC271 = _digiERC271;
        stableERC20 = _stableERC20;
    }

    /**
    * @dev User deposits DIGI NFT for auction.
    */
    function createAuction(
        uint256 _tokenId,
        uint256 _minPrice,
        uint256 _fixedPrice,
        uint256 _duration
    )
        public
        returns (uint256)
    {
        IDigiNFT(digiERC271).transferFrom(msg.sender, address(this), _tokenId);

        uint256 timeNow = _getTime();
        uint256 newAuction = auctionCount;
        auctionCount += 1;

        auctions[newAuction] = Auction({
            tokenId: _tokenId,
            owner: msg.sender,
            minPrice: _minPrice,
            fixedPrice: _fixedPrice,
            buyed: false,
            endDate: timeNow + _duration
        });
        lastAuctionByToken[_tokenId] = newAuction;

        emit CreatedAuction(newAuction, msg.sender, _tokenId, timeNow);

        return newAuction;
    }

    /**
    * @dev User makes an offer for the DIGI NFT.
    */
    function participateAuction(uint256 _auctionId, uint256 _amount)
        public
        nonReentrant()
        requiredAmount(msg.sender, digiAmountRequired)
        inProgress(_auctionId)
        minPrice(_auctionId, _amount)
        newHighestOffer(_auctionId, _amount)
    {
        IERC20(stableERC20).transferFrom(msg.sender, address(this), _amount);

        _returnPreviousOffer(_auctionId);

        uint256 timeNow = _getTime();
        highestOffers[_auctionId] = Offer({
            buyer: msg.sender,
            offer: _amount,
            date: timeNow
        });

        emit NewHighestOffer(_auctionId, msg.sender, _amount, timeNow);
    }

    /**
    * @dev User directly buyes the DIGI NFT at fixed price.
    */
    function directBuy(uint256 _auctionId)
        public
        notClaimed(_auctionId)
        inProgress(_auctionId)
    {
        require(IERC20(stableERC20).balanceOf(msg.sender) > auctions[_auctionId].fixedPrice, 'DigiAuction: User does not have enough balance');
        require(auctions[_auctionId].fixedPrice > 0, 'DigiAuction: Direct buy not available');
        
        uint amount = auctions[_auctionId].fixedPrice;
        uint256 feeAmount = amount.mul(purchaseFee).div(10000);
        uint256 amountAfterFee = amount.sub(feeAmount);

        IERC20(stableERC20).transferFrom(msg.sender, address(this), feeAmount);
        IERC20(stableERC20).transferFrom(msg.sender, auctions[_auctionId].owner, amountAfterFee);
        IDigiNFT(digiERC271).transferFrom(address(this), msg.sender, auctions[_auctionId].tokenId);
        
        uint256 timeNow = _getTime();
        auctions[_auctionId].buyed = true;

        claimedAuctions[_auctionId] = true;

        _returnPreviousOffer(_auctionId);

        emit DirectBuyed(_auctionId, msg.sender, auctions[_auctionId].fixedPrice, timeNow);
    }

    /**
    * @dev Winner user claims DIGI NFT for ended auction.
    */
    function claim(uint256 _auctionId)
        public
        ended(_auctionId)
        notClaimed(_auctionId)
    {
        require(highestOffers[_auctionId].buyer != address(0x0), "DigiAuction: Ended without winner");

        uint256 timeNow = _getTime();
        uint256 amount = highestOffers[_auctionId].offer;
        uint256 feeAmount = amount.mul(purchaseFee).div(10000);
        uint256 amountAfterFee = amount.sub(feeAmount);

        IERC20(stableERC20).transfer(auctions[_auctionId].owner, amountAfterFee);
        IDigiNFT(digiERC271).transferFrom(address(this), highestOffers[_auctionId].buyer, auctions[_auctionId].tokenId);

        claimedAuctions[_auctionId] = true;

        emit Claimed(_auctionId, highestOffers[_auctionId].buyer, amount, timeNow);
    }

    /**
    * @dev Send all the acumulated fees for one token to the fee destinators.
    */
    function withdrawAcumulatedFees() public {
        uint256 total = IERC20(stableERC20).balanceOf(address(this));
        
        for (uint8 i = 0; i < feesDestinators.length; i++) {
            IERC20(stableERC20).transfer(
                feesDestinators[i],
                total.mul(feesPercentages[i]).div(100)
            );
        }
    }

    /**
    * @dev Cancel auction and returns token.
    */
    function cancel(uint256 _auctionId)
        public
        ended(_auctionId)
    {
        require(auctions[_auctionId].owner == msg.sender, 'DigiAuction: User is not the token owner');
        require(highestOffers[_auctionId].buyer == address(0x0), "DigiAuction: Ended but has winner");

        uint256 timeNow = _getTime();

        auctions[_auctionId].endDate = timeNow;

        IDigiNFT(digiERC271).transferFrom(
            address(this),
            auctions[_auctionId].owner,
            auctions[_auctionId].tokenId
        );

        emit CanceledAuction(_auctionId, msg.sender, auctions[_auctionId].tokenId, timeNow);
    }

    /**
    * @dev Sets the purchaseFee for every withdraw.
    */
    function setFee(uint256 _purchaseFee) public onlyOwner() {
        require(_purchaseFee <= 3000, "DigiAuction: Max fee 30%");
        purchaseFee = _purchaseFee;
    }

    /**
    * @dev Configure how to distribute the fees for user's withdraws.
    */
    function setFeesDestinatorsWithPercentages(
        address[] memory _destinators,
        uint256[] memory _percentages
    )
        public
        onlyOwner()
    {
        require(_destinators.length == _percentages.length, "DigiAuction: Destinators and percentageslenght are not equals");

        uint256 total = 0;
        for (uint8 i = 0; i < _percentages.length; i++) {
            total += _percentages[i];
        }
        require(total == 100, "DigiAuction: Percentages sum must be 100");

        feesDestinators = _destinators;
        feesPercentages = _percentages;
    }

    /******************
    PRIVATE FUNCTIONS
    *******************/
    function _returnPreviousOffer(uint256 _auctionId) internal {
        Offer memory currentOffer = highestOffers[_auctionId];
        if (currentOffer.offer > 0) {
            IERC20(stableERC20).transfer(currentOffer.buyer, currentOffer.offer);
        }
    }

    function _getTime() internal view returns (uint256) {
        return block.timestamp;
    }

    /******************
    MODIFIERS
    *******************/
    modifier requiredAmount(address _wallet, uint256 _amount) {
        require(
            IERC20(stakeERC20).balanceOf(_wallet) > _amount,
            'DigiAuction: User needs more token balance in order to do this action'
        );
        _;
    }

    modifier newHighestOffer(uint256 _auctionId, uint256 _amount) {
        require(
            _amount > highestOffers[_auctionId].offer,
            'DigiAuction: Amount must be higher'
        );
        _;
    }

    modifier minPrice(uint256 _auctionId, uint256 _amount) {
        require(
            _amount >= auctions[_auctionId].minPrice,
            'DigiAuction: Insufficient offer amount for this auction'
        );
        _;
    }

    modifier inProgress(uint256 _auctionId) {
        require(
            (auctions[_auctionId].endDate > _getTime()) && auctions[_auctionId].buyed == false,
            'DigiAuction: Auction closed'
        );
        _;
    }

    modifier ended(uint256 _auctionId) {
        require(
            (_getTime() > auctions[_auctionId].endDate) && auctions[_auctionId].buyed == false,
            'DigiAuction: Auction not closed'
        );
        _;
    }

    modifier notClaimed(uint256 _auctionId) {
        require(
            (claimedAuctions[_auctionId] == false),
            'DigiAuction: Already claimed'
        );
        _;
    }
}