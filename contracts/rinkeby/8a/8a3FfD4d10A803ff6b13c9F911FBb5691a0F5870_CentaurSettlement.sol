// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import './libraries/Ownable.sol';
import './libraries/SafeMath.sol';
import './interfaces/ICentaurFactory.sol';
import './interfaces/ICentaurPool.sol';
import './interfaces/ICentaurSettlement.sol';

contract CentaurSettlement is ICentaurSettlement, Ownable {

	using SafeMath for uint;

	bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

	address public override factory;
	address public override migrator;
	uint public override settlementDuration;

	// User address -> Token address -> Settlement
	mapping(address => mapping (address => Settlement)) pendingSettlement;

	constructor (address _factory, uint _settlementDuration) public {
		factory = _factory;
		settlementDuration = _settlementDuration;
	}

	function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'CentaurSwap: TRANSFER_FAILED');
    }

	function addSettlement(
		address _sender,
		Settlement memory _pendingSettlement
	) external override {
		require(ICentaurFactory(factory).isValidPool(_pendingSettlement.fPool), 'CentaurSwap: POOL_NOT_FOUND');
		require(ICentaurFactory(factory).isValidPool(_pendingSettlement.tPool), 'CentaurSwap: POOL_NOT_FOUND');

		require(msg.sender == _pendingSettlement.tPool, 'CentaurSwap: INVALID_POOL');

		require(pendingSettlement[_sender][_pendingSettlement.fPool].settlementTimestamp == 0, 'CentaurSwap: SETTLEMENT_EXISTS');
		require(pendingSettlement[_sender][_pendingSettlement.tPool].settlementTimestamp == 0, 'CentaurSwap: SETTLEMENT_EXISTS');

		pendingSettlement[_sender][_pendingSettlement.fPool] = _pendingSettlement;
		pendingSettlement[_sender][_pendingSettlement.tPool] = _pendingSettlement;

	}

	function removeSettlement(
		address _sender,
		address _fPool,
		address _tPool
	) external override {
		require(msg.sender == _tPool, 'CentaurSwap: INVALID_POOL');

		require(pendingSettlement[_sender][_fPool].settlementTimestamp != 0, 'CentaurSwap: SETTLEMENT_DOES_NOT_EXISTS');
		require(pendingSettlement[_sender][_tPool].settlementTimestamp != 0, 'CentaurSwap: SETTLEMENT_DOES_NOT_EXISTS');

		require(block.timestamp >= pendingSettlement[_sender][_fPool].settlementTimestamp, 'CentaurSwap: SETTLEMENT_PENDING');

		_safeTransfer(ICentaurPool(_tPool).baseToken(), _tPool, pendingSettlement[_sender][_fPool].maxAmountOut);

		delete pendingSettlement[_sender][_fPool];
		delete pendingSettlement[_sender][_tPool];
	}

	function getPendingSettlement(address _sender, address _pool) external override view returns (Settlement memory) {
		return pendingSettlement[_sender][_pool];
	}
	
	function hasPendingSettlement(address _sender, address _pool) external override view returns (bool) {
		return (pendingSettlement[_sender][_pool].settlementTimestamp != 0);
	}

	// Helper Functions
	function setFactory(address _factory) onlyOwner external override {
		factory = _factory;
	}

	function setMigrator(address _migrator) onlyOwner external override {
		migrator = _migrator;
	}

	function setSettlementDuration(uint _settlementDuration) onlyOwner external override {
		settlementDuration = _settlementDuration;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";
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

pragma solidity >=0.5.0;

interface ICentaurFactory {
    event PoolCreated(address indexed token, address pool, uint);

    function poolFee() external view returns (uint);

    function poolLogic() external view returns (address);
    function cloneFactory() external view returns (address);
    function settlement() external view returns (address);
    function router() external view returns (address);

    function getPool(address token) external view returns (address pool);
    function allPools(uint) external view returns (address pool);
    function allPoolsLength() external view returns (uint);
    function isValidPool(address pool) external view returns (bool);

    function createPool(address token, address oracle, uint poolUtilizationPercentage) external returns (address pool);
    function addPool(address pool) external;
    function removePool(address pool) external;

    function setPoolLiquidityParameter(address, uint) external;
    function setPoolTradeEnabled(address, bool) external;
    function setPoolDepositEnabled(address, bool) external;
    function setPoolWithdrawEnabled(address, bool) external;
    function setAllPoolsTradeEnabled(bool) external;
    function setAllPoolsDepositEnabled(bool) external;
    function setAllPoolsWithdrawEnabled(bool) external;

    function emergencyWithdrawFromPool(address, address, uint, address) external;

    function setPoolFee(uint) external;
    function setPoolLogic(address) external;
    function setCloneFactory(address) external;
    function setSettlement(address) external;
    function setRouter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ICentaurPool {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    event Mint(address indexed sender, uint amount);
    event Burn(address indexed sender, uint amount, address indexed to);
    event AmountIn(address indexed sender, uint amount);
    event AmountOut(address indexed sender, uint amount, address indexed to);
    event EmergencyWithdraw(uint256 _timestamp, address indexed _token, uint256 _amount, address indexed _to);

    function factory() external view returns (address);
    function settlement() external view returns (address);
    function baseToken() external view returns (address);
    function baseTokenDecimals() external view returns (uint);
    function oracle() external view returns (address);
    function oracleDecimals() external view returns (uint);
    function baseTokenTargetAmount() external view returns (uint);
    function baseTokenBalance() external view returns (uint);
    function liquidityParameter() external view returns (uint);

    function init(address, address, address, uint) external;

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount);

    function swapTo(address _sender, address _fromToken, uint _amountIn, uint _value, address _receiver) external returns (uint maxAmount);
    function swapFrom(address _sender) external returns (uint amount, uint value);
    function swapSettle(address _sender) external returns (uint);

    function getOraclePrice() external view returns (uint price);
    function getAmountOutFromValue(uint _value) external view returns (uint amount);
    function getValueFromAmountIn(uint _amount) external view returns (uint value);
    function getAmountInFromValue(uint _value) external view returns (uint amount);
    function getValueFromAmountOut(uint _amount) external view returns (uint value);

    function setFactory(address) external;
    function setTradeEnabled(bool) external;
    function setDepositEnabled(bool) external;
    function setWithdrawEnabled(bool) external;
    function setLiquidityParameter(uint) external;
    function emergencyWithdraw(address, uint, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

interface ICentaurSettlement {
    // event SettlementAdded(address indexed sender, address indexed _fromToken, uint _amountIn, address indexed _toToken, uint _amountOut);
    // event SettlementRemoved(address indexed sender, address indexed _fromToken, address indexed _toToken);
    struct Settlement {
        address fPool;
        uint amountIn;
        uint fPoolBaseTokenTargetAmount;
        uint fPoolBaseTokenBalance;
        uint fPoolLiquidityParameter;
        address tPool;
        uint maxAmountOut;
        uint tPoolBaseTokenTargetAmount;
        uint tPoolBaseTokenBalance;
        uint tPoolLiquidityParameter;
        address receiver;
        uint settlementTimestamp;
    }

    function factory() external pure returns (address);
    function migrator() external view returns (address);
    function settlementDuration() external pure returns (uint);


    function addSettlement(
        address _sender,
        Settlement memory _pendingSettlement
    ) external;
    function removeSettlement(address _sender, address _fPool, address _tPool) external;
    
    function getPendingSettlement(address _sender, address _pool) external view returns (Settlement memory);
    function hasPendingSettlement(address _sender, address _pool) external view returns (bool);
    // function getSettlementTimestamp(address _sender, address _pool) external returns (uint);

    function setFactory(address) external;
    function setMigrator(address) external;
    function setSettlementDuration(uint) external;
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
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}