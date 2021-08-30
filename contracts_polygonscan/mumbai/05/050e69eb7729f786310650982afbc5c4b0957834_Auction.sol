/**
 *Submitted for verification at polygonscan.com on 2021-08-29
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/[email protected]

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
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/security/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/Auction.sol
pragma solidity ^0.8.2;



contract Auction is Ownable, ReentrancyGuard {
  uint256 constant ONE = 10**27; // [ray]
  uint256 constant LOWER_BOUND = 10**4;
  uint256 constant UPPER_BOUND = 10**70;

  IERC20 public token;
  bool public isShutdown;

  uint256 public startBlock;
  uint256 public blocksPerPeriod;
  uint256 public tokenPerPeriod; // [wad]
  uint256 public targetTokenPerPeriod; // [wad]
  uint256 public sensitivity; // [ray]

  uint256 public lastPrice; // base/token [ray]
  uint256 public lastTokenSoldInPeriod; // [wad]
  uint256 public lastTransactedPeriod;

  modifier isNotShutdown() {
    require(!isShutdown, "Auction is on shutdown");
    _;
  }

  constructor(
    address initialToken,
    uint256 initialPrice,
    uint256 initialSensitivity,
    uint256 initialBlocksPerPeriod,
    uint256 initialTokenPerPeriod,
    uint256 auctionStart
  ) {
    require(initialSensitivity > ONE, "Sensitivity <= 1");
    token = IERC20(initialToken);
    blocksPerPeriod = initialBlocksPerPeriod;
    tokenPerPeriod = initialTokenPerPeriod;
    targetTokenPerPeriod = initialTokenPerPeriod / 2;
    lastPrice = initialPrice;
    sensitivity = initialSensitivity;
    startBlock = auctionStart;
  }

  function periodSinceStart() public view returns (uint256 period) {
    require(block.number >= startBlock, "Auction not started");
    period = (block.number - startBlock) / blocksPerPeriod;
  }

  function adjustedPrice(
    uint256 priceInLastPeriod,
    uint256 tokenSoldInLastPeriod
  ) public view returns (uint256 nextPrice) {
    bool isPositivePriceAdjustment = tokenSoldInLastPeriod >=
      targetTokenPerPeriod;
    if (isPositivePriceAdjustment) {
      uint256 pctDiff = ((tokenSoldInLastPeriod - targetTokenPerPeriod) * ONE) /
        targetTokenPerPeriod;
      uint256 adjustmentRatio = (pctDiff * (sensitivity - ONE)) / ONE;
      nextPrice =
        priceInLastPeriod +
        (priceInLastPeriod * adjustmentRatio) /
        ONE;
    } else {
      uint256 pctDiff = ((targetTokenPerPeriod - tokenSoldInLastPeriod) * ONE) /
        targetTokenPerPeriod;
      uint256 adjustmentRatio = (pctDiff * ONE) / sensitivity;
      nextPrice =
        priceInLastPeriod -
        (priceInLastPeriod * adjustmentRatio) /
        ONE;
    }
  }

  function currentPrice() public view returns (uint256 price) {
    uint256 currentPeriod = periodSinceStart();
    if (currentPeriod == lastTransactedPeriod) return lastPrice;
    uint256 periodPassed = currentPeriod - lastTransactedPeriod;
    price = lastPrice;
    for (uint256 i = 1; i <= periodPassed; i++) {
      if (i == periodPassed) {
        price = adjustedPrice(price, lastTokenSoldInPeriod);
      } else {
        // No token sold during this period
        price = (price * ONE) / sensitivity;
      }
    }
  }

  function updatePrice() public isNotShutdown {
    uint256 currentPeriod = periodSinceStart();
    if (currentPeriod == lastTransactedPeriod) return;
    lastPrice = currentPrice();
    if (lastPrice < LOWER_BOUND) {
      lastPrice = LOWER_BOUND;
    }
    if (lastPrice > UPPER_BOUND) {
      lastPrice = UPPER_BOUND;
    }
    lastTokenSoldInPeriod = 0;
    lastTransactedPeriod = currentPeriod;
  }

  function buyToken() public payable nonReentrant isNotShutdown {
    updatePrice();
    uint256 amountToPurchase = (msg.value * ONE) / lastPrice;
    uint256 amountPurchased = amountToPurchase >
      tokenPerPeriod - lastTokenSoldInPeriod
      ? tokenPerPeriod - lastTokenSoldInPeriod
      : amountToPurchase;
    lastTokenSoldInPeriod += amountPurchased;
    token.transfer(msg.sender, amountPurchased);
    if (amountToPurchase > amountPurchased) {
      uint256 amountToRefund = ((amountToPurchase - amountPurchased) *
        lastPrice) / ONE;
      (bool success, ) = payable(msg.sender).call{value: amountToRefund}("");
      require(success, "Fail to refund");
    }
  }

  // Default methods

  receive() external payable {
    buyToken();
  }

  fallback() external payable {
    buyToken();
  }

  // Admin methods
  function updatePriceManually(uint256 updatedPrice) public onlyOwner {
    lastPrice = updatedPrice;
    lastTokenSoldInPeriod = 0;
    lastTransactedPeriod = periodSinceStart();
  }

  function emergencyShutdown() public onlyOwner {
    isShutdown = true;
  }

  function withdraw(uint256 amount, address payable to) public onlyOwner {
    (bool success, ) = to.call{value: amount}("");
    require(success, "Withdraw failed");
  }
}