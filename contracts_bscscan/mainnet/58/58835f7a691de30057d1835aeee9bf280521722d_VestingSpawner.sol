/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: AGPL-3.0

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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/proxy/Clones.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol



pragma solidity ^0.7.0;

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

// File: contracts/interfaces/IUniswapFactory.sol
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: contracts/vesting/Vesting.sol

pragma solidity ^0.7.6;





contract Vesting is ReentrancyGuard {
    using SafeMath for uint256;

    address public recipient;

    uint256 public startTime;
    uint256 public epochDuration;
    uint256 public epochsCliff;
    uint256 public epochsVesting;

    IERC20 public xgt;
    address public listingFactory;

    uint256 public lastClaimedEpoch;
    uint256 public totalDistributedBalance;
    bool public frontHalf;

    function initialize(
        address _recipient,
        address _xgtTokenAddress,
        uint256 _startTime,
        uint256 _epochDuration,
        uint256 _epochsCliff,
        uint256 _epochsVesting,
        uint256 _totalBalance,
        bool _frontHalf
    ) external {
        require(address(xgt) == address(0), "VESTING-ALREADY-INITIALIZED");
        recipient = _recipient;
        xgt = IERC20(_xgtTokenAddress);
        startTime = _startTime;
        epochDuration = _epochDuration;
        epochsCliff = _epochsCliff;
        epochsVesting = _epochsVesting;
        totalDistributedBalance = _totalBalance;
        frontHalf = _frontHalf;
        require(
            totalDistributedBalance == xgt.balanceOf(address(this)),
            "VESTING-INVALID-BALANCE"
        );
    }

    function claim() public nonReentrant {
        // For IDO investors this is set to true because of their unique vesting schedule
        if (frontHalf) {
            require(block.timestamp >= startTime, "VESTING-NOT-STARTED-YET");
            require(
                tokenHasBeenListed(),
                "VESTING-INITIAL-PAIR-NOT-DEPLOYED-YET"
            );
            uint256 halfBalance = totalDistributedBalance.div(2);
            require(
                xgt.transfer(recipient, halfBalance),
                "VESTING-TRANSFER-FAILED"
            );
            totalDistributedBalance = totalDistributedBalance.sub(halfBalance);
            frontHalf = false;
            return;
        }

        uint256 claimBalance;
        uint256 currentEpoch = getCurrentEpoch();

        require(currentEpoch > epochsCliff, "VESTING-CLIFF-NOT-OVER-YET");
        currentEpoch = currentEpoch.sub(epochsCliff);

        if (currentEpoch >= epochsVesting) {
            lastClaimedEpoch = epochsVesting;
            require(
                xgt.transfer(recipient, xgt.balanceOf(address(this))),
                "VESTING-TRANSFER-FAILED"
            );
            return;
        }

        if (currentEpoch > lastClaimedEpoch) {
            claimBalance =
                ((currentEpoch - lastClaimedEpoch) * totalDistributedBalance) /
                epochsVesting;
        }
        lastClaimedEpoch = currentEpoch;
        if (claimBalance > 0) {
            require(
                xgt.transfer(recipient, claimBalance),
                "VESTING-TRASNFER-FAILED"
            );
        }
    }

    function balance() external view returns (uint256) {
        return xgt.balanceOf(address(this));
    }

    function getCurrentEpoch() public view returns (uint256) {
        if (block.timestamp < startTime) return 0;
        return (block.timestamp - startTime) / epochDuration + 1;
    }

    function hasClaim() external view returns (bool) {
        // For IDO investors this is set to true because of their unique vesting schedule
        if (frontHalf) {
            if (block.timestamp < startTime || !tokenHasBeenListed()) {
                return false;
            }
            return true;
        }

        uint256 currentEpoch = getCurrentEpoch();
        if (currentEpoch <= epochsCliff) {
            return false;
        }
        currentEpoch = currentEpoch.sub(epochsCliff);

        if (currentEpoch >= epochsVesting) {
            return true;
        }

        if (currentEpoch > lastClaimedEpoch) {
            uint256 claimBalance =
                ((currentEpoch - lastClaimedEpoch) * totalDistributedBalance) /
                    epochsVesting;
            if (claimBalance > 0) {
                return true;
            }
        }

        return false;
    }

    // function which determines whether a certain pair has been listed
    // and funded on a uniswap-v2-based dex. This is to ensure for the
    // public sale distribution to only happen after this is the case
    function tokenHasBeenListed() public view returns (bool) {
        IUniswapV2Factory exchangeFactory =
            IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
        address wBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        address pair = exchangeFactory.getPair(address(xgt), wBNB);
        // if the factory returns the 0-address, it hasn't been created
        if (pair == address(0)) {
            return false;
        }
        // if it was created, only return true if the xgt balance is
        // greater than zero == has been funded
        if (xgt.balanceOf(pair) > 0) {
            return true;
        }
        return false;
    }
}

// File: contracts/vesting/VestingSpawner.sol

pragma solidity ^0.7.6;






contract VestingSpawner is Ownable {
    using SafeMath for uint256;

    IERC20 public xgt;
    address public implementation;
    mapping(address => address) public vestingContractOfRecipient;
    address[] public vestingContracts;

    uint256 public constant EPOCH_DURATION_WEEK = 24 * 60 * 60 * 7;
    uint256 public constant EPOCH_DURATION_MONTH = (365 * 24 * 60 * 60) / 12;

    uint256 public constant MINIMUM_CLIFF_EPOCHS_TEAM =
        EPOCH_DURATION_MONTH * 6;
    uint256 public constant MINIMUM_VESTING_EPOCHS_TEAM =
        EPOCH_DURATION_MONTH * 48;

    enum Allocation {Reserve, Founders, Team, Community, MarketMaking}

    uint256 public reserveTokensLeft;
    uint256 public foundersTokensLeft;
    uint256 public teamTokensLeft;
    uint256 public communityTokensLeft;
    uint256 public marketMakingTokensLeft;

    event VestingContractSpawned(
        address indexed recipient,
        uint256 amount,
        uint256 startDate,
        uint256 epochDuration,
        uint256 epochsCliff,
        uint256 epochsVesting
    );

    constructor(
        address _vestingImplementation,
        address _token,
        address _multiSig
    ) {
        implementation = _vestingImplementation;
        xgt = IERC20(_token);
        transferOwnership(_multiSig);
    }

    function fundSpawner(uint256 _allocation, uint256 _amount) external {
        require(
            _allocation >= 0 && _allocation <= 4,
            "VESTING-SPAWNER-INVALID-ALLOCATION"
        );

        require(
            xgt.transferFrom(msg.sender, address(this), _amount),
            "VESTING-SPAWNER-TRANSFER-FAILED"
        );

        if (Allocation(_allocation) == Allocation.Reserve) {
            reserveTokensLeft = reserveTokensLeft.add(_amount);
        } else if (Allocation(_allocation) == Allocation.Founders) {
            foundersTokensLeft = foundersTokensLeft.add(_amount);
        } else if (Allocation(_allocation) == Allocation.Team) {
            teamTokensLeft = teamTokensLeft.add(_amount);
        } else if (Allocation(_allocation) == Allocation.Community) {
            communityTokensLeft = communityTokensLeft.add(_amount);
        } else if (Allocation(_allocation) == Allocation.MarketMaking) {
            marketMakingTokensLeft = marketMakingTokensLeft.add(_amount);
        }
    }

    function spawnVestingContract(
        address _recipient,
        uint256 _amount,
        uint256 _startTime,
        uint256 _epochDuration,
        uint256 _epochsCliff,
        uint256 _epochsVesting,
        uint256 _allocation
    ) public onlyOwner {
        require(
            vestingContractOfRecipient[_recipient] == address(0),
            "VESTING-SPAWNER-RECIPIENT-ALREADY-EXISTS"
        );

        require(
            _epochDuration == EPOCH_DURATION_WEEK ||
                _epochDuration == EPOCH_DURATION_MONTH,
            "VESTING-SPAWNER-INVALID-EPOCH-DURATION"
        );

        require(
            _allocation >= 0 && _allocation <= 3,
            "VESTING-SPAWNER-INVALID-ALLOCATION"
        );

        require(
            _startTime >= 1625673600,
            "VESTING-SPAWNER-START-TIME-TOO-EARLY"
        );

        if (Allocation(_allocation) == Allocation.Reserve) {
            reserveTokensLeft = reserveTokensLeft.sub(_amount);
        } else if (Allocation(_allocation) == Allocation.Founders) {
            require(
                _epochsVesting.mul(_epochDuration) >=
                    MINIMUM_VESTING_EPOCHS_TEAM &&
                    _epochsCliff.mul(_epochDuration) >=
                    MINIMUM_CLIFF_EPOCHS_TEAM,
                "VESTING-SPAWNER-VESTING-DURATION-TOO-SHORT"
            );
            foundersTokensLeft = foundersTokensLeft.sub(_amount);
        } else if (Allocation(_allocation) == Allocation.Team) {
            require(
                _epochsVesting.mul(_epochDuration) >=
                    MINIMUM_VESTING_EPOCHS_TEAM &&
                    _epochsCliff.mul(_epochDuration) >=
                    MINIMUM_CLIFF_EPOCHS_TEAM,
                "VESTING-SPAWNER-VESTING-DURATION-TOO-SHORT"
            );
            teamTokensLeft = teamTokensLeft.sub(_amount);
        } else if (Allocation(_allocation) == Allocation.Community) {
            communityTokensLeft = communityTokensLeft.sub(_amount);
        } else if (Allocation(_allocation) == Allocation.MarketMaking) {
            marketMakingTokensLeft = marketMakingTokensLeft.sub(_amount);
        }

        address newVestingContract = Clones.clone(implementation);
        vestingContractOfRecipient[_recipient] = newVestingContract;
        vestingContracts.push(newVestingContract);

        // Special Case for IDO where 50% is paid out instantly
        // and the rest is vested for 2 weeks
        bool frontHalf = false;
        if (
            _allocation == 0 &&
            _epochDuration == EPOCH_DURATION_WEEK &&
            _epochsVesting == 2 &&
            _epochsCliff == 1
        ) {
            frontHalf = true;
        }

        require(
            xgt.transfer(newVestingContract, _amount),
            "VESTING-SPAWNER-TRANSFER-FAILED"
        );
        Vesting(newVestingContract).initialize(
            _recipient,
            address(xgt),
            _startTime,
            _epochDuration,
            _epochsCliff,
            _epochsVesting,
            _amount,
            frontHalf
        );
        emit VestingContractSpawned(
            _recipient,
            _amount,
            _startTime,
            _epochDuration,
            _epochsCliff,
            _epochsVesting
        );
    }

    function addSeedInvestor(address _recipient, uint256 _amount) external {
        spawnVestingContract(
            _recipient,
            _amount,
            1625673600,
            EPOCH_DURATION_MONTH,
            3,
            12,
            0
        );
    }

    function addPrivateInvestor(address _recipient, uint256 _amount) external {
        spawnVestingContract(
            _recipient,
            _amount,
            1625673600,
            EPOCH_DURATION_MONTH,
            2,
            10,
            0
        );
    }

    function addPublicInvestor(address _recipient, uint256 _amount) external {
        spawnVestingContract(
            _recipient,
            _amount,
            1625673600,
            EPOCH_DURATION_WEEK,
            1,
            2,
            0
        );
    }

    function multiClaim(uint256 _from, uint256 _to) external {
        if (_to == 0) {
            _to = vestingContracts.length - 1;
        }
        for (uint256 i = _from; i <= _to; i++) {
            if (Vesting(vestingContracts[i]).hasClaim()) {
                Vesting(vestingContracts[i]).claim();
            }
        }
    }

    function checkForClaims(uint256 _from, uint256 _to)
        external
        view
        returns (bool)
    {
        if (_to == 0) {
            _to = vestingContracts.length - 1;
        }
        for (uint256 i = _from; i <= _to; i++) {
            if (Vesting(vestingContracts[i]).hasClaim()) {
                return true;
            }
        }
        return false;
    }

    function getVestingContractsAmount() external view returns (uint256) {
        return vestingContracts.length;
    }
}