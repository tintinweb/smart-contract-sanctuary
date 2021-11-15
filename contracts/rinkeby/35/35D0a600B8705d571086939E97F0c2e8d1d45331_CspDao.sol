// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library Common {
    enum PoolStatus { OPENED, CLOSED, DISTRIBUTING, FINISHED }

    enum Tier { NONE, ASSOCIATE, PRINCIPAL, PARTNER, SENIOR_PARTNER, TOP_TEN }

    struct Pool {
        string name;
        string iconUrl;
        bool isTopTen;
        uint256 minAllocation; // example: 100 should be sent as 100 * 10^18
        uint256 maxAllocation; // example: 30000 should be sent as 30000 * 10^18
        uint256 feePercent; // example 1% should be sent as 1
        uint256 maxAssociateAllocation; // same as min/maxAllocation
        uint256 maxPrincipalAllocation; // same as min/maxAllocation
        uint256 maxPartnerAllocation; // same as min/maxAllocation
        uint256 maxSeniorPartnerAllocation; // same as min/maxAllocation
        uint256 maxTopTenAllocation; // same as min/maxAllocation
        address[] contributionTokens;
        uint256[] contributionMultipliers; // example: 1.4 should be sent as 1.4 * 10^18
        uint256 ethMultiplier; // example: 1830.34 should be sent as 1830.34 * 10^18
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICspDao.sol";
import "./helpers/AddressSets.sol";
import "./Common.sol";

contract CspDao is Ownable, ICspDao {
    using Math for uint256;
    using SafeMath for uint256;
    using AddressSets for AddressSets.AddressSet;

    uint256 private constant MIN_ASSOCIATE_NEBO_BALANCE = 1000 ether;
    uint256 private constant MIN_PRINCIPAL_NEBO_BALANCE = 2500 ether;
    uint256 private constant MIN_PARTNER_NEBO_BALANCE = 5000 ether;
    uint256 private constant MIN_SENIOR_PARTNER_NEBO_BALANCE = 10000 ether;

    IERC20 private neboToken;
    AddressSets.AddressSet private topTen;
    Common.Pool[] private pools;
    mapping(uint256 => Common.PoolStatus) private poolStatuses;
    mapping(uint256 => uint256) private poolContributions;
    mapping(uint256 => uint256) private poolEthContributions;
    mapping(uint256 => mapping(address => uint256)) private poolTokenContributions;
    mapping(uint256 => mapping(address => uint256)) private poolMemberContributions;
    mapping(uint256 => mapping(address => uint256)) private poolMemberEthContributions;
    mapping(uint256 => mapping(address => mapping(address => uint256))) private poolMemberTokenContributions;
    mapping(uint256 => mapping(Common.Tier => uint256)) private poolTierMaxAllocations;
    uint256 private lockedEth;
    mapping(address => uint256) lockedToken;

    constructor(address _neboToken) public {
        neboToken = IERC20(_neboToken);
    }

    modifier sufficientEth(uint256 _amount) {
        require(address(this).balance >= _amount, "Insufficient eth amount.");
        _;
    }

    modifier sufficientToken(IERC20 _token, uint256 _amount) {
        require(_token.balanceOf(address(this)) >= _amount, "Insufficient token amount.");
        _;
    }

    modifier validContributionPool(uint256 _poolId) {
        require(_poolId >= 0 && _poolId < pools.length, "Invalid pool.");
        require(poolStatuses[_poolId] == Common.PoolStatus.OPENED, "Pool not opened for contributions.");
        require(poolContributions[_poolId] < pools[_poolId].maxAllocation, "Max allocation reached.");
        _;
    }

    modifier ethContributionPool(uint256 _poolId) {
        require(pools[_poolId].ethMultiplier > 0, "ETH not allowed.");
        _;
    }

    modifier tokenContributionPool(uint256 _poolId, address _token) {
        uint256 contributionTokensCount = pools[_poolId].contributionTokens.length;
        for (uint256 i; i < contributionTokensCount; i++) {
            if (pools[_poolId].contributionTokens[i] == _token) {
                _;
            }
        }
        require(false, "Invalid contribution token.");
    }

    modifier memberContributionAllowed(address _sender, uint256 _poolId) {
        Common.Tier tier = getTier(_sender);
        require(tier != Common.Tier.NONE, "No tier assigned.");
        require(poolTierMaxAllocations[_poolId][tier] > 0, "Tier not allowed.");
        require(
            poolTierMaxAllocations[_poolId][tier] > poolMemberContributions[_poolId][_sender],
            "Tier max allocation reached."
        );
        _;
    }

    function setNeboToken(IERC20 _token) external override onlyOwner {
        neboToken = _token;
    }

    function getNeboToken() external view override returns (address) {
        return address(neboToken);
    }

    function transferEth(address payable _recipient, uint256 _amount)
        external
        override
        onlyOwner
        sufficientEth(_amount)
    {
        _recipient.transfer(_amount);
    }

    function transferToken(
        IERC20 _token,
        address _recipient,
        uint256 _amount
    ) external override onlyOwner sufficientToken(_token, _amount) {
        require(_token.transfer(_recipient, _amount), "Token transfer failed.");
    }

    function setTopTen(address[] memory _topTen) external override onlyOwner {
        topTen.setAddresses(_topTen);
    }

    function getTopTen() external view override returns (address[] memory) {
        return topTen.getAddresses();
    }

    function getTier(address _member) public view override returns (Common.Tier) {
        if (topTen.contains(_member)) {
            return Common.Tier.TOP_TEN;
        }

        uint256 memberNeboBalance = neboToken.balanceOf(_member);

        if (memberNeboBalance >= MIN_SENIOR_PARTNER_NEBO_BALANCE) {
            return Common.Tier.SENIOR_PARTNER;
        }
        if (memberNeboBalance >= MIN_PARTNER_NEBO_BALANCE) {
            return Common.Tier.PARTNER;
        }
        if (memberNeboBalance >= MIN_PRINCIPAL_NEBO_BALANCE) {
            return Common.Tier.PRINCIPAL;
        }
        if (memberNeboBalance >= MIN_ASSOCIATE_NEBO_BALANCE) {
            return Common.Tier.ASSOCIATE;
        }
        return Common.Tier.NONE;
    }

    function createPool(Common.Pool memory _pool) external override onlyOwner {
        uint256 poolId = pools.length;
        pools.push(_pool);
        poolStatuses[poolId] = Common.PoolStatus.OPENED;
        poolTierMaxAllocations[poolId][Common.Tier.ASSOCIATE] = _pool.maxAssociateAllocation;
        poolTierMaxAllocations[poolId][Common.Tier.PRINCIPAL] = _pool.maxPrincipalAllocation;
        poolTierMaxAllocations[poolId][Common.Tier.PARTNER] = _pool.maxPartnerAllocation;
        poolTierMaxAllocations[poolId][Common.Tier.SENIOR_PARTNER] = _pool.maxSeniorPartnerAllocation;
        poolTierMaxAllocations[poolId][Common.Tier.TOP_TEN] = _pool.maxTopTenAllocation;
    }

    function getPools() external view override returns (Common.Pool[] memory) {
        return pools;
    }

    function contributeEth(uint256 _poolId)
        external
        payable
        override
        validContributionPool(_poolId)
        ethContributionPool(_poolId)
        memberContributionAllowed(msg.sender, _poolId)
    {
        uint256 memberLeftover =
            poolTierMaxAllocations[_poolId][getTier(msg.sender)].sub(poolMemberContributions[_poolId][msg.sender]);
        uint256 totalLeftover = pools[_poolId].maxAllocation.sub(poolContributions[_poolId]);
        uint256 leftover = Math.min(memberLeftover, totalLeftover);

        uint256 multipliedValue = msg.value.mul(pools[_poolId].ethMultiplier).div(10**18);
        uint256 contribution = Math.min(leftover, multipliedValue);

        poolContributions[_poolId] = poolContributions[_poolId].add(contribution);
        poolEthContributions[_poolId] = poolEthContributions[_poolId].add(contribution);
        poolMemberContributions[_poolId][msg.sender] = poolMemberContributions[_poolId][msg.sender].add(contribution);
        poolMemberEthContributions[_poolId][msg.sender] = poolMemberEthContributions[_poolId][msg.sender].add(
            contribution
        );
    }

    function contributeToken(
        uint256 _poolId,
        IERC20 _token,
        uint256 _amount
    )
        external
        override
        validContributionPool(_poolId)
        tokenContributionPool(_poolId, address(_token))
        memberContributionAllowed(msg.sender, _poolId)
    {}

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library AddressSets {
    struct AddressSet {
        mapping(address => bool) isAddressInSet;
        address[] addresses;
    }

    function setAddresses(AddressSet storage set, address[] memory _addresses) internal {
        // reset
        uint256 addressesCount = set.addresses.length;
        for (uint256 i; i < addressesCount; i++) {
            set.isAddressInSet[set.addresses[i]] = false;
        }

        // set new
        uint256 newAddressesCount = _addresses.length;
        for (uint256 i; i < newAddressesCount; i++) {
            set.isAddressInSet[_addresses[i]] = true;
        }
        set.addresses = _addresses;
    }

    function getAddresses(AddressSet storage set) internal view returns (address[] memory) {
        return set.addresses;
    }

    function contains(AddressSet storage set, address _address) internal view returns (bool) {
        return set.isAddressInSet[_address];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Common.sol";

interface ICspDao {
    // nebo
    function setNeboToken(IERC20 _token) external;

    function getNeboToken() external view returns (address);

    function transferEth(address payable _recipient, uint256 _amount) external;

    function transferToken(
        IERC20 _token,
        address _recipient,
        uint256 _amount
    ) external;

    // members
    function setTopTen(address[] memory _topTen) external;

    function getTopTen() external view returns (address[] memory);

    function getTier(address _member) external view returns (Common.Tier);

    // pools
    function createPool(Common.Pool memory _pool) external;

    function getPools() external view returns (Common.Pool[] memory);

    /*
    function closePool(uint256 _poolId, address payable _recipient) external;

    function distributePool(uint256 _poolId, address _sender, uint256 _amount) external;

    function refundPool(uint256 _poolId, uint256 _percent) external;
    */

    // users
    function contributeEth(uint256 _poolId) external payable;

    function contributeToken(
        uint256 _poolId,
        IERC20 _token,
        uint256 _amount
    ) external;

    /*
    function claim(uint256 _poolId) external;

    function refund(uint256 _poolId) external;
    */
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

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

// SPDX-License-Identifier: MIT

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

