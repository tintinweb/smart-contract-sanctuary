// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenSale is Ownable, ReentrancyGuard {
	uint256 public maticPrice;
	uint256 public usdcPrice;
	uint256 public maxBuyAmount;
	uint256 public immutable cap;
	IERC20 immutable TokenContract;
	uint256 public tokensSold;
	address usdcAddress = 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926;
	uint256 public immutable releaseTime;
	uint256 public immutable unlockTime;
	bool public refundable = false;
	uint256 immutable multiplier = 30;

	struct PurchasedAmount {
		uint256 maticAmount;
		uint256 maticInvested;
		uint256 usdcAmount;
		uint256 usdcInvested;
	}

	struct LockedAmount {
		uint256 maticAmount;
		uint256 usdcAmount;
	}

	mapping(address => PurchasedAmount) public purchasedAmount;
	mapping(address => LockedAmount) public lockedAmount;

	event Sold(address indexed buyer, uint256 amount, bool isNative);

	constructor(
		IERC20 _saleToken,
		uint256 _maticPrice,
		uint256 _usdcPrice,
		uint256 _maxBuyAmount,
		uint256 _cap,
		uint256 _releaseTime,
		uint256 _unlockTime
	) {
		maticPrice = _maticPrice;
		usdcPrice = _usdcPrice;
		maxBuyAmount = _maxBuyAmount;
		cap = _cap;
		releaseTime = _releaseTime;
		unlockTime = _unlockTime;
		TokenContract = _saleToken;
	}

	function setMaticPrice(uint256 _maticPrice) external onlyOwner() {
		maticPrice = _maticPrice;
	}

	function setUSDCPrice(uint256 _usdcPrice) external onlyOwner() {
		usdcPrice = _usdcPrice;
	}

	function setMaxBuyAmount(uint256 _maxBuyAmount) external onlyOwner() {
		maxBuyAmount = _maxBuyAmount;
	}

	function buy(uint256 _buyAmount) external payable {
		require(
			releaseTime >= block.timestamp,
			"Cannot buy after the sale end"
		);
		require(
			tokensSold + _buyAmount <= cap,
			"Cannot buy that exceeds the cap"
		);
		require(
			msg.value == (maticPrice * _buyAmount) / 1e4 && msg.value != 0,
			"Incorrect pay amount"
		);
		PurchasedAmount storage allocation = purchasedAmount[msg.sender];

		allocation.maticAmount += (_buyAmount * multiplier) / 100;
		allocation.maticInvested += msg.value;

		LockedAmount storage allocationLocked = lockedAmount[msg.sender];

		allocationLocked.maticAmount += (_buyAmount * (100 - multiplier)) / 100;

		require(
			allocation.maticAmount +
				allocation.usdcAmount +
				allocationLocked.maticAmount +
				allocationLocked.usdcAmount <=
				maxBuyAmount
		);
		tokensSold += _buyAmount;

		emit Sold(msg.sender, _buyAmount, true);
	}

	function buyByUSDC(uint256 _buyAmount) external virtual {
		require(
			releaseTime >= block.timestamp,
			"Cannot buy after the sale end"
		);
		require(
			tokensSold + _buyAmount <= cap,
			"Cannot buy that exceeds the cap"
		);
		PurchasedAmount storage allocation = purchasedAmount[msg.sender];
		uint256 amount;
		amount = (usdcPrice * _buyAmount) / 1e4 / 1e12; // GoGo token decimals - USDC token decimals
		require(amount > 0, "Min amount limit");
		require(
			IERC20(usdcAddress).transferFrom(msg.sender, address(this), amount),
			"TF: Check allowance"
		);

		allocation.usdcAmount += (_buyAmount * multiplier) / 100;

		LockedAmount storage allocationLocked = lockedAmount[msg.sender];

		allocationLocked.usdcAmount += (_buyAmount * (100 - multiplier)) / 100;
		allocation.usdcInvested += amount;

		require(
			allocation.maticAmount +
				allocation.usdcAmount +
				allocationLocked.maticAmount +
				allocationLocked.usdcAmount <=
				maxBuyAmount
		);

		tokensSold += _buyAmount;

		emit Sold(msg.sender, _buyAmount, false);
	}

	function claim() external nonReentrant {
		require(
			releaseTime < block.timestamp,
			"Cannot claim before the sale ends"
		);
		PurchasedAmount memory allocation = purchasedAmount[msg.sender];
		uint256 totalAmount = allocation.usdcAmount + allocation.maticAmount;
		delete purchasedAmount[msg.sender];
		require(TokenContract.transfer(msg.sender, totalAmount));
	}

	function unLock() external nonReentrant {
		require(
			unlockTime < block.timestamp,
			"Cannot unlock before the unlock time"
		);
		LockedAmount storage allocationLocked = lockedAmount[msg.sender];
		uint256 totalAmount = allocationLocked.usdcAmount +
			allocationLocked.maticAmount;
		delete lockedAmount[msg.sender];
		require(TokenContract.transfer(msg.sender, totalAmount));
	}

	function getRefund() external nonReentrant {
		require(
			releaseTime < block.timestamp,
			"Cannot get refunded before the sale ends"
		);
		require(refundable, "Not possible to refund now");
		PurchasedAmount memory allocation = purchasedAmount[msg.sender];
		require(
			IERC20(usdcAddress).transfer(msg.sender, allocation.usdcInvested)
		);
		payable(msg.sender).transfer(allocation.maticInvested);
		delete purchasedAmount[msg.sender];
		delete lockedAmount[msg.sender];
	}

	function setRefundable(bool _flag) external onlyOwner() {
		refundable = _flag;
	}

	function endSale() external onlyOwner() {
		require(
			releaseTime < block.timestamp,
			"Cannot get fund back before the release time"
		);
		require(
			TokenContract.transfer(
				msg.sender,
				TokenContract.balanceOf(address(this))
			)
		);
		IERC20 usdc = IERC20(usdcAddress);
		usdc.transfer(msg.sender, usdc.balanceOf(address(this)));
		payable(msg.sender).transfer(address(this).balance);
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