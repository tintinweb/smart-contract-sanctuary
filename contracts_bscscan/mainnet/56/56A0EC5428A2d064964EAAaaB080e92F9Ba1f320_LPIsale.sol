// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBEP20.sol";

contract LPIsale is Ownable, ReentrancyGuard {
    bool private fundByTokens = false;
    IBEP20 public fundToken;

    uint256 public startTime;
    uint256 public duration;

    uint256 public rate;
    uint256 public cap;
    uint256 public tokensSold;

    // Max sell per user in currency
    uint256 public maxSell;
    // Min contribution per TX in currency
    uint256 public minSell;

    uint256 public raised;
    uint256 public participants;

    mapping(address => uint256) public balances;

    bool public isWhitelistEnabled = false;
    mapping(address => bool) public whitelisted;

    event RateChanged(uint256 newRate);
    event MinChanged(uint256 value);
    event MaxChanged(uint256 value);
    event StartChanged(uint256 newStartTime);
    event DurationChanged(uint256 newDuration);
    event WhitelistChanged(bool newEnabled);

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor(uint256 _startTime, uint256 _saleDuration, uint256 _rate, uint256 _cap, bool _whitelist, address _fundToken) {
        startTime = _startTime;
        duration = _saleDuration;
        rate = _rate;
        cap = _cap;
        isWhitelistEnabled = _whitelist;
        whitelisted[msg.sender] = true;
        fundByTokens = _fundToken != address(0);
        if (fundByTokens) {
            fundToken = IBEP20(_fundToken);
        }
    }

    modifier ongoingSale(){
        require(isLive(), "Presale is not live");
        _;
    }

    function isLive() public view returns (bool) {
        return block.timestamp > startTime && block.timestamp < startTime + duration;
    }

    function getMinMaxLimits() external view returns (uint256, uint256) {
        return (minSell, maxSell);
    }

    function setMin(uint256 value) public onlyOwner {
        require(maxSell == 0 || value <= maxSell, "Must be smaller than max");
        minSell = value;
        emit MinChanged(value);
    }

    function setMax(uint256 value) public onlyOwner {
        require(minSell == 0 || value >= minSell, "Must be bigger than min");
        maxSell = value;
        emit MaxChanged(value);
    }

    function setRate(uint256 newRate) public onlyOwner {
        require(!isLive(), "Presale is live, rate change not allowed");
        rate = newRate;
        emit RateChanged(rate);
    }

    function setStartTime(uint256 newStartTime) public onlyOwner {
        startTime = newStartTime;
        emit StartChanged(startTime);
    }

    function setSaleDuration(uint256 newDuration) public onlyOwner {
        duration = newDuration;
        emit DurationChanged(duration);
    }

    function setWhitelistEnabled(bool enabled) public onlyOwner {
        isWhitelistEnabled = enabled;
        emit WhitelistChanged(enabled);
    }

    function calculatePurchaseAmount(uint purchaseAmountWei) public view returns (uint256) {
        return purchaseAmountWei * rate;
    }

    receive() external payable {
        require(!fundByTokens, "This presale is funded by tokens, use buyTokens(value)");
        buyTokens();
    }

    function buyTokens() public payable ongoingSale nonReentrant returns (bool) {
        require(!fundByTokens, "Sale: presale is funded by tokens but value is missing");
        require(!isWhitelistEnabled || whitelisted[msg.sender], "Sale: not in whitelist");

        uint256 amount = calculatePurchaseAmount(msg.value);
        require(minSell == 0 || msg.value >= minSell, "Sale: amount is too small");
        require(amount != 0, "Sale: amount is 0");
        require(tokensSold + amount <= cap, "Sale: cap reached");

        address beneficiary = msg.sender;

        tokensSold = tokensSold + amount;
        balances[beneficiary] = balances[beneficiary] + amount;

        require(maxSell == 0 || (balances[beneficiary] / rate) <= maxSell, "Sale: amount exceeds max");

        raised = raised + msg.value;
        participants = participants + 1;

        emit TokensPurchased(_msgSender(), beneficiary, msg.value, amount);
        return true;
    }

    /**
    * The fund token must be first approved to be transferred by presale contract for the given "value".
    */
    function buyTokens(uint256 value) public ongoingSale nonReentrant returns (bool) {
        require(fundByTokens, "Sale: funding by tokens is not allowed");
        require(!isWhitelistEnabled || whitelisted[msg.sender], "Sale: not whitelisted");
        require(fundToken.allowance(msg.sender, address(this)) >= value, 'Sale: fund token not approved');

        uint256 amount = calculatePurchaseAmount(value);
        require(minSell == 0 || value >= minSell, "Sale: amount is too small");
        require(amount != 0, "Sale: amount is 0");
        require(tokensSold + amount <= cap, "Sale: cap reached");

        require(fundToken.transferFrom(msg.sender, address(this), value), 'Sale: failed to transfer payment');

        address beneficiary = msg.sender;

        tokensSold = tokensSold + amount;
        balances[beneficiary] = balances[beneficiary] + amount;

        require(maxSell == 0 || (balances[beneficiary] / rate) <= maxSell, "Sale: amount exceeds max");

        raised = raised + value;
        participants = participants + 1;

        emit TokensPurchased(_msgSender(), beneficiary, value, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function withdrawBalance(uint256 amount) external onlyOwner {
        if (fundByTokens) {
            fundToken.transfer(owner(), amount);
        } else {
            payable(owner()).transfer(amount);
        }
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }

        if (fundByTokens && fundToken.balanceOf(address(this)) > 0) {
            fundToken.transfer(owner(), fundToken.balanceOf(address(this)));
        }
    }

    function batchAddWhitelisted(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = true;
        }
    }
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

pragma solidity >=0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

