// SPDX-License-Identifier: MIT
// Gearbox forked by Platinum . Uncollateralized protocol for margin trading
pragma solidity ^0.6.0;

import "Ownable.sol";
import "SafeMath.sol";
import "PoolACL.sol";

/**
 * @title Leverage Repository
 * @author Platinum Forked
 * @notice Stores Leve
 * @dev Do not use in mainnet.
 */
contract PositionRepository is Ownable, PoolACL {
    using SafeMath for uint256;

    struct Position {
        uint256 mainTokenAmount;
        uint256 leveragedTokenAmount;
        mapping(address => bool) tokensListMap;
        // Tokens which trader has
        // ToDo: move to ERC20 tokens
        mapping(address => uint256) tokensBalances;
        // cumulative index at open
        uint256 cumulativeIndexAtOpen;
        // Active is true if leverage is opened
        bool active;
        // Exists is true if leverage was created sometime
        bool exists;
        address[] tokensList;
    }

    mapping(address => address[]) private _traders;
    mapping(address => mapping(address => Position)) private _positions;

    modifier activePositionOnly(address trader) {
        require(
            _positions[msg.sender][trader].active,
            "Position doesn't not exists"
        );
        _;
    }

   modifier activePoolPositionOnly(address pool, address trader) {
        require(
            _positions[pool][trader].active,
            "Position doesn't not exists"
        );
        _;
    }

    function hasOpenPosition(address pool, address trader)
        external
        view
        returns (bool)
    {
        return _positions[pool][trader].active;
    }

    // Returns quantity of leverages holders
    function tradersCount(address pool) external view returns (uint256) {
        return _traders[pool].length;
    }

    // Returns trader address by id
    function getTraderById(address pool, uint256 id)
        external
        view
        returns (address)
    {
        return _traders[pool][id];
    }

    function getPositionDetails(address pool, address trader)
        external
        view
        returns (
            uint256 amount,
            uint256 leveragedAmount,
            uint256 cumulativeIndex
        )
    {
        Position memory position = _positions[pool][trader];
        amount = position.mainTokenAmount;
        leveragedAmount = position.leveragedTokenAmount;
        cumulativeIndex = position.cumulativeIndexAtOpen;
    }

    // @dev Opens leverage for trader
    function openPosition(
        address trader,
        address mainAsset,
        uint256 mainTokenAmount,
        uint256 leveragedTokenAmount,
        uint256 cumulativeIndex
    ) external onlyPoolService {
        address pool = msg.sender;
        // Check that trader doesn't have open leverages
        require(!_positions[pool][trader].active, "Position is already opened");

        // Add trader to list if he creates leverage first time
        if (!_positions[pool][trader].exists) {
            _traders[pool].push(trader);
        } else {}

        address[] memory emptyArray;
        // Create leverage
        _positions[pool][trader] = Position({
            mainTokenAmount: mainTokenAmount,
            leveragedTokenAmount: leveragedTokenAmount,
            cumulativeIndexAtOpen: cumulativeIndex,
            tokensList: emptyArray,
            active: true,
            exists: true
        });

        _updateLeverageToken(pool, trader, mainAsset, leveragedTokenAmount);
    }

    function closePosition(address trader)
        external
        onlyPoolService
        activePositionOnly(trader)
    {
        address pool = msg.sender;
        for (uint256 i = 0; i < getTokenListCount(pool, trader); i++) {
            (address token, ) = getTokenById(pool, trader, i);
            delete _positions[pool][trader].tokensListMap[token];
            delete _positions[pool][trader].tokensBalances[token];
        }
        _positions[pool][trader].active = false;
        _positions[pool][trader].mainTokenAmount = 0;
        _positions[pool][trader].leveragedTokenAmount = 0;
        _positions[pool][trader].cumulativeIndexAtOpen = 0;
    }

    function swapAssets(
        address trader,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    ) external onlyPoolService activePositionOnly(trader) {
        address pool = msg.sender;
        require(
            _positions[pool][trader].tokensBalances[tokenIn] >= amountIn,
            "Insufficient funds"
        );

        _updateLeverageToken(
            pool,
            trader,
            tokenIn,
            _positions[pool][trader].tokensBalances[tokenIn].sub(amountIn)
        );
        _updateLeverageToken(
            pool,
            trader,
            tokenOut,
            _positions[pool][trader].tokensBalances[tokenOut].add(amountOut)
        );
    }

    function getTokenListCount(address pool, address trader)
        public
        view
        activePoolPositionOnly(pool, trader)
        returns (uint256)
    {
        return _positions[pool][trader].tokensList.length;
    }

    function getTokenById(
        address pool,
        address trader,
        uint256 id
    ) public view activePoolPositionOnly(pool, trader) returns (address, uint256) {
        address tokenAddr = _positions[pool][trader].tokensList[id];
        uint256 amount = _positions[pool][trader].tokensBalances[tokenAddr];
        return (tokenAddr, amount);
    }

    // @dev updates leverage token balances
    function _updateLeverageToken(
        address pool,
        address trader,
        address token,
        uint256 amount
    ) internal activePoolPositionOnly(pool, trader) {
        if (!_positions[pool][trader].tokensListMap[token]) {
            _positions[pool][trader].tokensListMap[token] = true;
            _positions[pool][trader].tokensList.push(token);
        }

        _positions[pool][trader].tokensBalances[token] = amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "Context.sol";
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.10;
import "Ownable.sol";

contract PoolACL is Ownable{

    mapping(address => bool) private _poolServices;

    modifier onlyPoolService() {
        require(_poolServices[msg.sender], "Allowed for pool services only");
        _;
    }

    function addToPoolServicesList(address poolService) external onlyOwner{
        _poolServices[poolService] = true;
    }
}