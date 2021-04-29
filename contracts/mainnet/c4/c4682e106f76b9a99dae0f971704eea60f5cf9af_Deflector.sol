//SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

/*
    ▓█████▄ ▓█████   █████▒██▓    ▓█████  ▄████▄  ▄▄▄█████▓ ▒█████   ██▀███
    ▒██▀ ██▌▓█   ▀ ▓██   ▒▓██▒    ▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▒██▒  ██▒▓██ ▒ ██▒
    ░██   █▌▒███   ▒████ ░▒██░    ▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▒██░  ██▒▓██ ░▄█ ▒
    ░▓█▄   ▌▒▓█  ▄ ░▓█▒  ░▒██░    ▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██   ██░▒██▀▀█▄
    ░▒████▓ ░▒████▒░▒█░   ░██████▒░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░ ████▓▒░░██▓ ▒██▒
     ▒▒▓  ▒ ░░ ▒░ ░ ▒ ░   ░ ▒░▓  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░
     ░ ▒  ▒  ░ ░  ░ ░     ░ ░ ▒  ░ ░ ░  ░  ░  ▒       ░      ░ ▒ ▒░   ░▒ ░ ▒░
     ░ ░  ░    ░    ░ ░     ░ ░      ░   ░          ░      ░ ░ ░ ▒    ░░   ░
       ░       ░  ░           ░  ░   ░  ░░ ░                   ░ ░     ░
     ░                                   ░
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IDeflector.sol";
import "./interfaces/IERC20MintSnapshot.sol";

/**
 * @title Deflector
 * @author DEFLECT PROTOCOL
 * @dev This contract handles spendable and global token effects on contracts like farming pools.
 *
 * Default numeric values used for percentage calculations should be divided by 1000.
 * If the default value for amount in Spendable is 20, it's meant to represeent 2% (i * amount / 1000)
 *
 * Range structs range values should be set as ether-values of the wanted values. (r1 = 5, r2 = 10)
 */

contract Deflector is Ownable, IDeflector {
    using SafeMath for uint256;

    uint256 private constant PERCENTAGE_DENOMINATOR = 1000;
    IERC20MintSnapshot public immutable prism;

    struct GlobalBoostLevel {
        uint256 lowerBound;
        uint256 percentage;
    }

    struct LocalBoostLevel {
        uint256 cumulativeCost;
        uint256 percentage;
    }

    struct User {
        address[] tokensLeveled;
        mapping(address => uint256) levelPerToken;
    }

    struct Pool {
        address[] boostTokens;
        bool exists;
        mapping(address => User) users;
        mapping(address => LocalBoostLevel[]) localBoosts;
    }

    mapping(address => Pool) public pools;

    GlobalBoostLevel[] public globalBoosts;

    modifier onlyPool() {
        require(
            pools[msg.sender].exists,
            "Deflector::onlyPool: Insufficient Privileges"
        );
        _;
    }

    constructor(IERC20MintSnapshot _prism) public Ownable() {
        prism = _prism;
        // Tier 1: 15 PRISM -> 5%
        globalBoosts.push(GlobalBoostLevel(15 ether, 50));
        // Tier 2: 30 PRISM -> 10%
        globalBoosts.push(GlobalBoostLevel(30 ether, 100));
        // Tier 3: 75 PRISM -> 25%
        globalBoosts.push(GlobalBoostLevel(75 ether, 250));
        // Tier 4: 150 PRISM -> 50%
        globalBoosts.push(GlobalBoostLevel(150 ether, 500));
    }

    function addPool(address pool) external onlyOwner() {
        pools[pool].exists = true;
    }

    function getPoolInfor(address pool, address _token)
        external
        view
        returns (address[] memory, LocalBoostLevel[] memory)
    {
        uint256 lengthBoostToken = pools[pool].boostTokens.length;
        uint256 lengthlocalBoostLevel = pools[pool].localBoosts[_token].length;
        address[] memory boostTokens = new address[](lengthBoostToken);
        LocalBoostLevel[] memory localBoostLevel =
            new LocalBoostLevel[](lengthlocalBoostLevel);
        // boostTokens[0] = address(0);
        for (uint256 i = 0; i < lengthBoostToken; i++) {
            boostTokens[i] = pools[pool].boostTokens[i];
        }

        for (uint256 i = 0; i < lengthlocalBoostLevel; i++) {
            localBoostLevel[i] = pools[pool].localBoosts[_token][i];
        }
        //  = pools[pool].boostTokens;
        //  = pools[pool].localBoosts;
        return (boostTokens, localBoostLevel);
    }

    function addLocalBoost(
        address _pool,
        address _token,
        uint256[] calldata costs,
        uint256[] calldata percentages
    ) external onlyOwner() {
        require(
            costs.length == percentages.length,
            "Deflector::addLocalBoost: Incorrect cost & percentage length"
        );
        Pool storage pool = pools[_pool];

        if (pool.localBoosts[_token].length == 0) pool.boostTokens.push(_token);

        for (uint256 i = 0; i < costs.length; i++) {
            pool.localBoosts[_token].push(
                LocalBoostLevel(costs[i], percentages[i])
            );
        }
    }

    function updateLocalBoost(
        address _pool,
        address _token,
        uint256[] calldata costs,
        uint256[] calldata percentages
    ) external onlyOwner() {
        require(
            costs.length == percentages.length,
            "Deflector::addLocalBoost: Incorrect cost & percentage length"
        );
        Pool storage pool = pools[_pool];
        for (uint256 i = 0; i < costs.length; i++) {
            pool.localBoosts[_token][i] = LocalBoostLevel(
                costs[i],
                percentages[i]
            );
        }
    }

    function updateLevel(
        address _user,
        address _token,
        uint256 _nextLevel,
        uint256 _balance
    ) external override onlyPool() returns (uint256) {
        Pool storage pool = pools[msg.sender];
        User storage user = pool.users[_user];

        if (user.levelPerToken[_token] == 0) {
            user.tokensLeveled.push(_token);
        }

        user.levelPerToken[_token] = _nextLevel;

        return calculateBoostedBalance(_user, _balance);
    }

    function calculateBoostedBalance(address _user, uint256 _balance)
        public
        view
        override
        returns (uint256)
    {
        uint256 mintedPrism = prism.getPriorMints(_user, block.number - 1);

        // Calculate Global Boost
        uint256 loopLimit = globalBoosts.length;
        uint256 i;
        for (i = 0; i < loopLimit; i++) {
            if (mintedPrism < globalBoosts[i].lowerBound) break;
        }

        uint256 totalBoost;
        if (i > 0) totalBoost = globalBoosts[i - 1].percentage;

        // Calculate Local Boost
        Pool storage pool = pools[msg.sender];

        // Safe arithmetics here
        loopLimit = pool.boostTokens.length;
        for (i = 0; i < loopLimit; i++) {
            address token = pool.boostTokens[i];
            uint256 userLevel = pool.users[_user].levelPerToken[token];
            if (userLevel == 0) continue;
            totalBoost += pool.localBoosts[token][userLevel - 1].percentage;
        }
        return _balance.mul(totalBoost) / PERCENTAGE_DENOMINATOR;
    }

    function calculateCost(
        address _user,
        address _token,
        uint256 _nextLevel
    ) external view override returns (uint256) {
        Pool storage pool = pools[msg.sender];
        User storage user = pool.users[_user];
        require(
            _nextLevel != 0 && _nextLevel <= pool.localBoosts[_token].length,
            "Deflector::calculateCost: Incorrect Level Specified"
        );
        uint256 currentLevel = user.levelPerToken[_token];
        uint256 currentCost =
            currentLevel == 0
                ? 0
                : pool.localBoosts[_token][currentLevel - 1].cumulativeCost;
        return
            pool.localBoosts[_token][_nextLevel - 1].cumulativeCost.sub(
                currentCost
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IDeflector {
    function calculateBoostedBalance(address _user, uint256 _balance)
        external
        view
        returns (uint256);

    function calculateCost(
        address _user,
        address _token,
        uint256 _nextLevel
    ) external view returns (uint256);

    function updateLevel(
        address _user,
        address _token,
        uint256 _nextLevel,
        uint256 _balance
    ) external returns (uint256);
}

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.0 <0.8.0;

interface IERC20MintSnapshot {
    function getPriorMints(address account, uint blockNumber) external view returns (uint224);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}