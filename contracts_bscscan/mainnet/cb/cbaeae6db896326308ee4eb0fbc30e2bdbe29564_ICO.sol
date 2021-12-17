//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ILockableToken.sol";


contract ICO is Ownable {

    IERC20 public currency;
    ILockableToken public token;

    uint256 public price;
    uint256 public softcap;
    uint256 public hardcap;
    uint256 public minSale;
    uint256 public saleStart;
    uint256 public saleEnd;
    uint256 public collected;

    uint256 public lockShare;
    uint256 public lockDuration;
    uint256 public lockSteps;

    // EVENTS

    event Sale(address indexed buyer, uint256 valueBought, uint256 valueGiven);

    event PriceSet(uint256 price);

    event HardcapSet(uint256 hardcap);

    event MinSaleSet(uint256 minSale);

    event SaleStartSet(uint256 saleStart);

    event SaleEndSet(uint256 saleEnd);

    // CONSTRUCTOR

    constructor(
        IERC20 currency_,
        ILockableToken token_, 
        uint256 price_, 
        uint256 hardcap_, 
        uint256 minSale_, 
        uint256 saleStart_, 
        uint256 saleEnd_,
        uint256 lockShare_,
        uint256 lockDuration_,
        uint256 lockSteps_
    ) Ownable() {
        require(saleEnd_ > saleStart_, "Sale end should be greater than sale start");
        require(lockShare_ <= 100, "Lock share can not be greater than 100%");

        token = token_;
        currency = currency_;

        price = price_;
        hardcap = hardcap_;
        minSale = minSale_;
        saleStart = saleStart_;
        saleEnd = saleEnd_;

        lockShare = lockShare_;
        lockDuration = lockDuration_;
        lockSteps = lockSteps_;
    }

    // PUBLIC FUNCTIONS 

    function buy(uint256 currencyAmount) external {
        require(currencyAmount >= minSale, "Can't buy for less than minSale");
        require(collected + currencyAmount <= hardcap, "Sale overflows hardcap");
        require(block.timestamp >= saleStart, "Sale hasn't started yet");
        require(block.timestamp <= saleEnd, "Sale has finished already");

        currency.transferFrom(msg.sender, address(this), currencyAmount);

        collected += currencyAmount;
        uint256 tokenValue = currencyAmount * price / 10**18;
        token.transferAndLock(msg.sender, tokenValue, lockShare, lockDuration, lockSteps);

        emit Sale(msg.sender, tokenValue, currencyAmount);
    }

    // RESTRICTED FUNCTIONS

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
        emit PriceSet(price);
    }

    function setHardcap(uint256 hardcap_) external onlyOwner {
        hardcap = hardcap_;
        emit HardcapSet(hardcap);
    }

    function setMinSale(uint256 minSale_) external onlyOwner {
        minSale = minSale_;
        emit MinSaleSet(minSale);
    }

    function setSaleStart(uint256 saleStart_) external onlyOwner {
        require(saleStart_ > block.timestamp, "Sale start should be in future");
        require(saleStart_ < saleEnd, "Sale start should be before sale end");
        saleStart = saleStart_;
        emit SaleStartSet(saleStart);
    }

    function setSaleEnd(uint256 saleEnd_) external onlyOwner {
        require(saleEnd_ > block.timestamp, "Sale end should be in future");
        require(saleEnd_ > saleStart, "Sale end should be after sale start");
        saleEnd = saleEnd_;
        emit SaleEndSet(saleEnd);
    }

    function setLockShare(uint256 lockShare_) external onlyOwner {
        require(lockShare_ <= 100, "Lock share can not be greater than 100%");
        lockShare = lockShare_;
    }

    function setLockDuration(uint256 lockDuration_) external onlyOwner {
        lockDuration = lockDuration_;
    }

    function setLockSteps(uint256 lockSteps_) external onlyOwner {
        require(lockSteps_ <= lockDuration, "Lock steps can not be greater than lock duration");
        lockSteps = lockSteps_;
    }

    function withdraw() external onlyOwner {
        currency.transfer(msg.sender, currency.balanceOf(address(this)));
    }

    function burnRemaining() external onlyOwner {
        require(block.timestamp >= saleEnd, "Sale hasn't ended");
        token.burn(token.balanceOf(address(this)));
    }
}

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ILockableToken {
    function transferAndLock(
        address to,
        uint256 amount,
        uint256 lockShare,
        uint256 lockDuration,
        uint256 lockSteps
    ) external;
    function transfer(address to, uint256 amount) external;
    function balanceOf(address account) external returns (uint256);
    function burn(uint256 amount) external;
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