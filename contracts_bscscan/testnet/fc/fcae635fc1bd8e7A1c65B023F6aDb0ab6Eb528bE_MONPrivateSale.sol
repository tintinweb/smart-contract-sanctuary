// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MONPrivateSale is Ownable, ReentrancyGuard {

    IERC20 public MON;
    IERC20 public buyingToken;

    uint256 public constant HARD_CAP = 1_400_000_000_000_000_000_000_000_000;      // hardcap 1,400,000,000 MON
    uint256 public constant DECIMAL_PRICE = 10000;

    uint256 public priceToken = 22; // 0.0022 BUSD
    uint256 public minSpend = 100_000_000_000_000_000_000; // min: 100 busd
    uint256 public maxSpend = 10_000_000_000_000_000_000_000;  // max: 10,000 busd
    uint256 public startTime;
    uint256 public endTime;

    // Whitelisting list
    mapping(address => bool) public whiteListed;
    // Total MON token user bought
    mapping(address => uint256) public userBought;
    // Total BUSD token user deposite
    mapping(address => uint256) public userDeposited;
    // Total MON token user claimed
    mapping(address => uint256) public userClaimned;
    // Total MON sold
    uint256 public totalTokenSold = 0;

    // Claim token
    uint256[] public claimableTimestamp;
    mapping(uint256 => uint256) public claimablePercents;
    mapping(address => uint256) public claimCounts;

    event TokenBuy(address user, uint256 tokens);
    event TokenClaim(address user, uint256 tokens);

    constructor(
        address _MON,
        address _buyingToken
    ) {
        MON = IERC20(_MON);
        buyingToken = IERC20(_buyingToken);
    }

    function buy(uint256 _amount) public nonReentrant {
        require(block.timestamp >= startTime, "Private sale has not started");
        require(block.timestamp <= endTime, "Private sale has ended");

        require(userDeposited[_msgSender()] + _amount >= minSpend, "Below minimum amount");
        require(userDeposited[_msgSender()] + _amount <= maxSpend, "You have reached maximum spend amount per user");

        uint256 tokenQuantity = _amount / priceToken * DECIMAL_PRICE;
        require(totalTokenSold + tokenQuantity <= HARD_CAP, "Token private sale hardcap reached");

        buyingToken.transferFrom(_msgSender(), address(this), _amount);

 		userBought[_msgSender()] += tokenQuantity;
 		userDeposited[_msgSender()] += _amount;
        totalTokenSold += tokenQuantity;

        emit TokenBuy(_msgSender(), tokenQuantity);
    }

    
    function claim() external nonReentrant {
        uint256 userBoughtAmount = userBought[_msgSender()];
        require(userBoughtAmount > 0, "Nothing to claim");
        require(claimableTimestamp.length > 0, "Can not claim at this time");
        require(block.timestamp >= claimableTimestamp[0], "Can not claim at this time");

        uint256 startIndex = claimCounts[_msgSender()];
        require(startIndex < claimableTimestamp.length, "You have claimed all token");

        uint256 tokenQuantity = 0;
        for(uint256 index = startIndex; index < claimableTimestamp.length; index++){
            uint256 timestamp = claimableTimestamp[index];
            if(block.timestamp >= timestamp){
                tokenQuantity += userBoughtAmount * claimablePercents[timestamp] / 100;
                claimCounts[_msgSender()]++;
            }else{
                break;
            }
        }

        require(tokenQuantity > 0, "Token quantity is not enough to claim");
        require(MON.transfer(_msgSender(), tokenQuantity), "Can not transfer MON token");

        userClaimned[_msgSender()] += tokenQuantity;

        emit TokenClaim(_msgSender(), tokenQuantity);
    }

    function getTokenBought(address _buyer) public view returns(uint256) {
        require(_buyer != address(0), "Zero address");
        return userBought[_buyer];
    }

    function setSaleInfo(
        uint256 _price,
        uint256 _minSpend,
        uint256 _maxSpend,
        uint256 _startTime,
        uint256 _endTime) external onlyOwner {
        require(_minSpend < _maxSpend, "Spend invalid");
        require(_startTime < _endTime, "Time invalid");

        priceToken = _price;
        minSpend = _minSpend;
        maxSpend = _maxSpend;
        startTime = _startTime;
        endTime = _endTime;
    }

    function setSaleTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_startTime < _endTime, "Time invalid");
        startTime = _startTime;
        endTime = _endTime;
    }

    function getSaleInfo() public view returns(uint256, uint256, uint256, uint256, uint256){
        return (priceToken, minSpend, maxSpend, startTime, endTime);
    }

    function setClaimableTimes(uint256[] memory _timestamp) external onlyOwner {
        require(_timestamp.length > 0, "Empty input");
        claimableTimestamp = _timestamp;
    }

    function setClaimablePercents(uint256[] memory _timestamps, uint256[] memory _percents) external onlyOwner {
        require(_timestamps.length > 0, "Empty input");
        require(_timestamps.length == _percents.length, "Empty input");
        for(uint256 index = 0; index < _timestamps.length; index++){
            claimablePercents[_timestamps[index]] = _percents[index];
        }
    }

    function setBuyingToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero address");
        buyingToken = IERC20(_newAddress);
    }

    function setMONToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero address");
        MON = IERC20(_newAddress);
    }

    function addToWhiteList(address[] memory _accounts) external onlyOwner {
        require(_accounts.length > 0, "Invalid input");
        for (uint256 index; index < _accounts.length; index++) {
            whiteListed[_accounts[index]] = true;
        }
    }

    function removeFromWhiteList(address[] memory _accounts) external onlyOwner {
        require(_accounts.length > 0, "Invalid input");
        for(uint256 index = 0; index < _accounts.length; index++){
            whiteListed[_accounts[index]] = false;
        }
    }

    function withdrawFunds() external onlyOwner {
        buyingToken.transfer(_msgSender(), buyingToken.balanceOf(address(this)));
    }

    function withdrawUnsold() external onlyOwner {
        uint256 tokenQuantity = MON.balanceOf(address(this)) - totalTokenSold;
        MON.transfer(_msgSender(), tokenQuantity);
    }
}