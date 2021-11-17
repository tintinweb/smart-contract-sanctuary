// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vesting is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public stableCoin;
    address public vestToken;

    event TokensBought(
        address indexed _from,
        uint256 indexed _tierId,
        uint256 _value
    );

    event TokensVested(
        address indexed _from,
        uint256 indexed _tierId,
        uint256 _value
    );

    event TierCreated(
        uint256 _tierId,
        uint256 _maxTokensPerWallet,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxTokensForTier,
        uint256 _price,
        bool _isPrivate
    );

    event TierUpdated(
        uint256 _tierId,
        uint256 _maxTokensPerWallet,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxTokensForTier,
        uint256 _price,
        bool _isPrivate
    );

    event AddressWhitelistedStatus(
        address indexed _address,
        uint256 _tier,
        bool _isWhitelisted
    );

    event AddDistributionMonthAndPercent(
        uint256 _tierId,
        uint256 _month,
        uint256 _percent
    );

    event VestingTimeForTier(uint256 _tierId, uint256 _startTime);

    uint256 public secondsInMonth = 30 days;

    /*
     * Params
     * address - stablecoin token address
     * address - vesting token address
     *
     * Deploys Vesting contract
     */

    constructor(address _stableCoin, address _vestToken) {
        stableCoin = _stableCoin;
        vestToken = _vestToken;
    }

    struct PreSaleTierInfo {
        uint256 maxTokensPerWallet;
        uint256 startTime;
        uint256 endTime;
        uint256 maxTokensForTier;
        uint256 price;
        bool isPrivate;
    }

    struct TierVestingInfo {
        uint256 totalTokensBoughtForTier;
        uint256 vestingStartTime;
        uint256 totalAllocationDone;
    }

    // tierId => month => percentage
    mapping(uint256 => mapping(uint256 => uint256)) public allocationPerMonth;

    // tierId => TierVestingInfo
    mapping(uint256 => TierVestingInfo) public tierVestingInfo;

    // user address => tierId => tokensBought
    mapping(address => mapping(uint256 => uint256)) public tokensBought;

    // user address => tierId => tokensBought
    mapping(address => mapping(uint256 => bool)) public isAddressWhitelisted;

    // user address => tierId => month => vestedMonth
    mapping(address => mapping(uint256 => uint256))
        public userVestedTokensMonth;

    /*
     * list of pre sale tiers
     */

    PreSaleTierInfo[] public tierInfo;

    /*
     * Params
     * uint256 - How many tokens in total a wallet can buy?
     * uint256 - When does the sale for this tier start?
     * uint256 - When does the sale for this tier end?
     * uint256 - What is the total amount of tokens sold in this Tier?
     * uint256 - What is the price per one token?
     * bool - Do wallets need to be whitelisted?
     *
     * Adds new presale tier to the list (array)
     */

    function createPreSaleTier(
        uint256 _maxTokensPerWallet,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxTokensForTier,
        uint256 _price,
        bool _isPrivate
    ) external onlyOwner {
        tierInfo.push(
            PreSaleTierInfo({
                maxTokensPerWallet: _maxTokensPerWallet,
                startTime: _startTime,
                endTime: _endTime,
                price: _price,
                maxTokensForTier: _maxTokensForTier,
                isPrivate: _isPrivate
            })
        );
        emit TierCreated(
            tierInfo.length.sub(1),
            _maxTokensPerWallet,
            _startTime,
            _endTime,
            _maxTokensForTier,
            _price,
            _isPrivate
        );
    }

    /*
     * Params
     * uint256 - What is ID of a Tier you want to update? (starting from 0)
     * uint256 - What
     * uint256 - How many tokens in total a wallet can buy?
     * uint256 - When does the sale for this tier start?
     * uint256 - When does the sale for this tier end?
     * uint256 - What is the total amount of tokens sold in this Tier?
     * uint256 - What is the price per one token?
     * bool - Do wallets need to be whitelisted?
     *
     * Updates Tier info
     * You can only update Tier, that has not started yet.
     */

    function updatePreSaleTier(
        uint256 _tierId,
        uint256 _maxTokensPerWallet,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxTokensForTier,
        uint256 _price,
        bool _isPrivate
    ) external onlyOwner {
        require(
            tierInfo[_tierId].startTime > block.timestamp,
            "Pre sale already in progress"
        );
        tierInfo[_tierId].maxTokensPerWallet = _maxTokensPerWallet;
        tierInfo[_tierId].startTime = _startTime;
        tierInfo[_tierId].endTime = _endTime;
        tierInfo[_tierId].maxTokensForTier = _maxTokensForTier;
        tierInfo[_tierId].price = _price;
        tierInfo[_tierId].isPrivate = _isPrivate;
        emit TierUpdated(
            _tierId,
            _maxTokensPerWallet,
            _startTime,
            _endTime,
            _maxTokensForTier,
            _price,
            _isPrivate
        );
    }

    /*
     * Returns number of tiers in the list
     */

    function tierLength() external view returns (uint256) {
        return tierInfo.length;
    }

    /*
     * Params
     * address - Who do you want to add to whitelist?
     * uint256 - What is ID of a Tier?
     *
     * Adds address to the whitelist of specific tier
     */

    function whitelistAddress(address _address, uint256 _tierId)
        public
        onlyOwner
    {
        require(_tierId <= tierInfo.length, "Invalid tier id");
        require(tierInfo[_tierId].isPrivate, "Tier needs to be private");
        isAddressWhitelisted[_address][_tierId] = true;
        emit AddressWhitelistedStatus(_address, _tierId, true);
    }

    /*
     * Params
     * address - Who do you want to remove from whitelist?
     * uint256 - What is ID of a Tier?
     *
     * Removes address from the whitelist of specific tier
     * Only users that have not bought any tokens can be removed
     */

    function removeWhitelistAddress(address _address, uint256 _tierId)
        public
        onlyOwner
    {
        require(_tierId <= tierInfo.length, "Invalid tier id");
        require(
            tokensBought[msg.sender][_tierId] == 0,
            "User already bought tokens"
        );
        isAddressWhitelisted[_address][_tierId] = false;
        emit AddressWhitelistedStatus(_address, _tierId, false);
    }

    /*
     * uint256 - What is ID of the Tier you want to set allocations?
     * uint256 - What month do you want to add allocation? (should be in the range 1 to 36)
     * uint256 - What is the allocation amount for this month? (can not be more than 10000)
     *
     * Function sets allocation for specific tier for specific month
     * You can not set allocation for the tier that has already started
     * When you finish setting allocation for this Tier, its' total allocation amount should be 10000
     */

    function setDistributionPercent(
        uint256 _tierId,
        uint256 _month,
        uint256 _percent
    ) public onlyOwner {
        require(_month > 0, "Invalid month number");
        require(_month < 37, "Invalid month number");
        require(_tierId <= tierInfo.length, "Invalid tier id");
        require(
            tierVestingInfo[_tierId].totalAllocationDone.add(_percent) <= 10000,
            "Allocation cant be more than 10000"
        );
        require(
            tierVestingInfo[_tierId].vestingStartTime < block.timestamp,
            "Vesting started"
        );
        tierVestingInfo[_tierId].totalAllocationDone = tierVestingInfo[_tierId]
            .totalAllocationDone
            .add(_percent);
        allocationPerMonth[_tierId][_month] = _percent;
        emit AddDistributionMonthAndPercent(_tierId, _month, _percent);
    }

    /*
     * Params
     * uint256 - What is ID of a Tier, you want to set vesting start time for?
     * uint256 - When do you want to start vesting of this tier? (can not be smaller than Tier starting time)
     *
     * Sets vesting start time for a specific Tier
     * Total allocations of this Tier should already be equal 10000
     */

    function setVestingTimeForTier(uint256 _tierId, uint256 _startTime)
        public
        onlyOwner
    {
        require(_tierId < tierInfo.length, "Invalid tier id");
        require(
            tierVestingInfo[_tierId].totalAllocationDone == 10000,
            "Total allocation less than 10000"
        );
        tierVestingInfo[_tierId].vestingStartTime = _startTime;
        emit VestingTimeForTier(_tierId, _startTime);
    }

    /*
     * Params
     * uint256 - What is ID of a tier, from which you want to buy tokens?
     * uint256 - How many tokens do you want to buy?
     *
     * Function allows to pre-purchase vesting tokens in exchange for stable coins
     *
     * Function will fail if:
     *** Pre sale has not started or already is over
     *** Maximum tokens amount for tier of user walled was reached or will be exceeded after transaction
     *** User walled was not whitelisted
     */

    function buyVestingTokens(uint256 _tierId, uint256 _numTokens) public {
        require(tx.origin == msg.sender, "Wallets only!");
        require(
            tierInfo[_tierId].startTime < block.timestamp,
            "Pre sale not yet started"
        );
        require(tierInfo[_tierId].endTime > block.timestamp, "Pre sale over");
        require(
            tierVestingInfo[_tierId].totalTokensBoughtForTier.add(_numTokens) <=
                tierInfo[_tierId].maxTokensForTier,
            "Cant buy more tokens for this tier"
        );
        require(
            tokensBought[msg.sender][_tierId] + _numTokens <=
                tierInfo[_tierId].maxTokensPerWallet,
            "You cant buy more tokens"
        );

        if (tierInfo[_tierId].isPrivate) {
            require(
                isAddressWhitelisted[msg.sender][_tierId],
                "Not allowed to buy tokens"
            );
        }

        uint256 totalTokenAmount;
        if (tierInfo[_tierId].price > 0) {
            totalTokenAmount = tierInfo[_tierId].price.mul(_numTokens).div(
                10e17
            );
        } else {
            totalTokenAmount = _numTokens;
        }

        IERC20(stableCoin).transferFrom(
            msg.sender,
            address(this),
            totalTokenAmount
        );

        tokensBought[msg.sender][_tierId] = tokensBought[msg.sender][_tierId]
            .add(_numTokens);
        tierVestingInfo[_tierId].totalTokensBoughtForTier = tierVestingInfo[
            _tierId
        ].totalTokensBoughtForTier.add(_numTokens);

        emit TokensBought(msg.sender, _tierId, _numTokens);
    }

    /*
     * Params
     * uint256 - What is ID of a Tier you want to vest tokens?
     *
     * Function vests tokens for specific tier and transfers them to user's address
     * Can be used multiple times - if there are still tokens left to vest, user will receive them
     *
     * Function will fail if:
     *** Vesting for tier has not started
     *** Allocation for tier is not 10000
     *** User has not bought any tokens
     *** User has already vested tokens
     */

    function vestTokens(uint256 _tierId) public {
        require(
            tierVestingInfo[_tierId].vestingStartTime < block.timestamp,
            "Vesting for tier not yet started"
        );
        require(
            tokensBought[msg.sender][_tierId] > 0,
            "Your token balance is zero"
        );
        require(
            tierVestingInfo[_tierId].totalAllocationDone == 10000,
            "Allocation is not 10000%"
        );

        uint256 monthsPassed = (block.timestamp -
            tierVestingInfo[_tierId].vestingStartTime) / secondsInMonth;

        require(
            monthsPassed > userVestedTokensMonth[msg.sender][_tierId],
            "You already vested tokens"
        );

        uint256 i = 0;
        uint256 totalAllocation = 0;
        uint256 loopUpperLimit = 0;

        if (monthsPassed < 37) {
            loopUpperLimit = monthsPassed;
        } else {
            loopUpperLimit = 36;
        }

        for (
            i = userVestedTokensMonth[msg.sender][_tierId] + 1;
            i <= loopUpperLimit;
            i++
        ) {
            totalAllocation = totalAllocation + allocationPerMonth[_tierId][i];
        }

        uint256 amount = tokensBought[msg.sender][_tierId]
            .mul(totalAllocation)
            .div(10000);

        userVestedTokensMonth[msg.sender][_tierId] = monthsPassed;
        IERC20(vestToken).transfer(msg.sender, amount);

        emit TokensVested(msg.sender, _tierId, amount);
    }

    /*
     * Params
     * uint256 - How many stable coins to withdraw. Amount in Decimals
     *
     * Function transfers the amount tokens from to contract to his wallet.
     *
     *** Only for admin.
     */

    function adminWithdrawStableCoin(uint256 _amount) public onlyOwner {
        IERC20(stableCoin).transfer(msg.sender, _amount);
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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