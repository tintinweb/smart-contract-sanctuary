// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AggregatorV3Interface.sol";

contract BAPSaleContract is Ownable {
    address private immutable BAP;
    address private immutable BAP_OWNER;
    uint256 private BAP_PRICE;

    mapping(address => address) private PRICE_FEEDERS;

    constructor(address _BAP, address _BAP_OWNER) {
        BAP = _BAP;
        BAP_OWNER = _BAP_OWNER;
        BAP_PRICE = 11000000; // means 0.11$

        // ETH/USD
        PRICE_FEEDERS[
            address(0)
        ] = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e; // 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        // USDT/USD
        PRICE_FEEDERS[
            address(0xdAC17F958D2ee523a2206206994597C13D831ec7)
        ] = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
        // USDC/USD
        PRICE_FEEDERS[
            address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)
        ] = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    }

    event PriceChanged(uint256 price);
    event Purchased(address receiver, uint256 amount);

    function bapPrice() public view returns (uint256) {
        return BAP_PRICE;
    }

    function setBapPrice(uint256 price) public onlyOwner {
        BAP_PRICE = price;
        emit PriceChanged(price);
    }

    /**
     * Request the quantity of purchasing BAP with ETH or stable coins (such as USDC, USDT) and specified amount
     */
    function buy(
        uint256 quantity,
        address token,
        uint256 amount
    ) public payable {
        require(IERC20(BAP).balanceOf(BAP_OWNER) > quantity, "Required BAP exceeds the balance");
        require(quantity > 0 || (token == address(0) && msg.value > 0) || amount > 0, "You have wrong parameters");

        if (token == address(0)) {
            amount = msg.value;
        }
        uint256 payment = (uint256(getLatestPrice(PRICE_FEEDERS[token])) * amount) / (quantity * BAP_PRICE);
        require(amount >= payment, "You have paid less than expected");

        if (token != address(0)) {
            IERC20(token).transferFrom(msg.sender, address(this), payment);
        }

        uint256 remain = amount - payment;
        if (token == address(0) && remain > 0) {
            payable(msg.sender).transfer(remain);
        }

        IERC20(BAP).transferFrom(BAP_OWNER, msg.sender, quantity);
        
        emit Purchased(msg.sender, quantity);
    }

    function withraw(address token, uint256 amount) public payable onlyOwner {
        uint256 balance = 0;
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }

        require(balance >= amount, "Required amount exceeds the balance");

        if (token == address(0)) {
            payable(BAP_OWNER).transfer(amount);
        } else {
            IERC20(token).transfer(BAP_OWNER, amount);
        }
    }

    function getLatestPrice(address feeder) public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(feeder).latestRoundData();
        return price;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

pragma solidity ^0.8.4;

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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