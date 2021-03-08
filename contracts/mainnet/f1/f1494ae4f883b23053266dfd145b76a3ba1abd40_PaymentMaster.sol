/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-08
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/PaymentHandler.sol

pragma solidity 0.5.16;

// import "./PaymentMaster.sol";




/**
 * The payment handler is responsible for receiving payments.
 * If the payment is in ETH, it auto forwards to its parent master's owner.
 * If the payment is in ERC20, it holds the tokens until it is asked to sweep.
 * It can only sweep ERC20s to the parent master's owner.
 */
contract PaymentHandler {
	using SafeERC20 for IERC20;

	// a boolean to track whether a Proxied instance of this contract has been initialized
	bool public initialized = false;

	// Keep track of the parent master contract - cannot be changed once set
	PaymentMaster public master;

	/**
	 * General constructor called by the master
	 */
	function initialize(PaymentMaster _master) public {
		require(initialized == false, 'Contract is already initialized');
		initialized = true;
		master = _master;
	}

	/**
	 * Helper function to return the parent master's address
	 */
	function getMasterAddress() public view returns (address) {
		return address(master);
	}

	/**
	 * Default payable function - forwards to the owner and triggers event
	 */
	function() external payable {
		// Get the parent master's owner address - explicity convert to payable
		address payable ownerAddress = address(uint160(master.owner()));

		// Forward the funds to the owner
		Address.sendValue(ownerAddress, msg.value);

		// Trigger the event notification in the parent master
		master.firePaymentReceivedEvent(address(this), msg.sender, msg.value);
	}

	/**
	 * Sweep any tokens to the owner of the master
	 */
	function sweepTokens(IERC20 token) public {
		// Get the owner address
		address ownerAddress = master.owner();

		// Get the current balance
		uint balance = token.balanceOf(address(this));

		// Transfer to the owner
		token.safeTransfer(ownerAddress, balance);
	}

}

// File: contracts/Proxy.sol

pragma solidity 0.5.16;

contract Proxy {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    // constructor(bytes memory constructData, address contractLogic) public {
    constructor(address contractLogic) public {
        // save the code address
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, contractLogic)
        }
    }

    function() external payable {
        assembly { // solium-disable-line
            let contractLogic := sload(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7)
            let ptr := mload(0x40)
            calldatacopy(ptr, 0x0, calldatasize)
            let success := delegatecall(gas, contractLogic, ptr, calldatasize, 0, 0)
            let retSz := returndatasize
            returndatacopy(ptr, 0, retSz)
            switch success
            case 0 {
                revert(ptr, retSz)
            }
            default {
                return(ptr, retSz)
            }
        }
    }
}

// File: contracts/PaymentMaster.sol

pragma solidity 0.5.16;


// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * The PaymentMaster sits above the payment handler contracts.
 * It deploys and keeps track of all the handlers.
 * It can trigger events by child handlers when they receive ETH.
 * It allows ERC20 tokens to be swept in bulk to the owner account.
 */
contract PaymentMaster {
	using SafeERC20 for IERC20;

	address public owner;

	// payment handler logic contract address
	address public handlerLogicAddress ;

	// A list of handler addresses for retrieval
  address[] public handlerList;

	// A mapping of handler addresses for lookups
	mapping(address => bool) public handlerMap;

	// Events triggered for listeners
	event HandlerCreated(address indexed _addr);
	event EthPaymentReceived(address indexed _to, address indexed _from, uint256 _amount);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	bool initialized = false;

	function initialize(address _owner, address _handlerLogicAddress) public {
		require(initialized == false, "Already initialized");
		initialized = true;

		handlerLogicAddress = _handlerLogicAddress;
		owner = _owner;
	}

	/**
	 * Anyone can call the function to deploy a new payment handler.
	 * The new contract will be created, added to the list, and an event fired.
	 */
	function deployNewHandler() public {
		// Deploy the new Proxy contract with the handler logic address
		Proxy createdProxy = new Proxy(handlerLogicAddress);

		// instantiate a PaymentHandler contract at the created Proxy address
		PaymentHandler proxyHandler = PaymentHandler(address(createdProxy));

		// initialize the Proxy with this contract's address
		proxyHandler.initialize(this);

		// Add it to the list and the mapping
		handlerList.push(address(createdProxy));
		handlerMap[address(createdProxy)] = true;

		// Emit event to let watchers know that a new handler was created
		emit HandlerCreated(address(createdProxy));
	}

	/**
	 * Allows caller to determine how long the handler list is for convenience
	 */
	function getHandlerListLength() public view returns (uint) {
		return handlerList.length;
	}

	/**
	 * This function is called by handlers when they receive ETH payments.
	 */
	function firePaymentReceivedEvent(address to, address from, uint256 amount) public {
		// Verify the call is coming from a handler
		require(handlerMap[msg.sender], "Only payment handlers are allowed to trigger payment events.");

		// Emit the event
		emit EthPaymentReceived(to, from, amount);
	}

	/**
	 * Allows a caller to sweep multiple handlers in one transaction
	 */
	function multiHandlerSweep(address[] memory handlers, IERC20 tokenContract) public {
		for (uint i = 0; i < handlers.length; i++) {

			// Whitelist calls to only handlers
			require(handlerMap[handlers[i]], "Only payment handlers are valid sweep targets.");

			// Trigger sweep
			PaymentHandler(address(uint160(handlers[i]))).sweepTokens(tokenContract);
		}
	}

	/**
	 * Safety function to allow sweep of ERC20s if accidentally sent to this contract
	 */
	function sweepTokens(IERC20 token) public {
		// Get the current balance
		uint balance = token.balanceOf(address(this));

		// Transfer to the owner
		token.safeTransfer(owner, balance);
	}

	function transferOwnership(address newOwner) public {
		require(msg.sender == owner, "Not owner");
		owner = newOwner;
		emit OwnershipTransferred(msg.sender, newOwner);
	}
}

// File: contracts/PaymentMasterFactory.sol

pragma solidity 0.5.16;

// import "./Proxy.sol";

/**
Deploys new instances of the Payment Master
 */
contract PaymentMasterFactory {

	// payment master logic contract address
	address public masterLogicAddress ;
	address public handlerLogicAddress;

	// Events triggered for listeners
	event MasterCreated(address indexed _addr);

	/** Deploy the payment handler logic contract */
	constructor() public {
		deployLogic();
	}

	/**
	 * Called by the constructor this function deploys impl contracts
	 */
	function deployLogic() internal {
		// Deploy the new master contract
		PaymentMaster createdMaster = new PaymentMaster();
		masterLogicAddress = address(createdMaster);

		// Deploy the new handler contract
		PaymentHandler createdHandler = new PaymentHandler();
		handlerLogicAddress = address(createdHandler);

		// initialize the deployed contracts - not needed but just in case
		createdHandler.initialize(createdMaster);
		createdMaster.initialize(msg.sender, address(handlerLogicAddress));
	}

	/**
	Called to create a new payment master and emit an event
	 */
	function deployNewMaster(address owner) public {
		// Deploy the new Proxy contract with the handler logic address
		Proxy createdProxy = new Proxy(masterLogicAddress);

		// instantiate a PaymentMaster contract at the created Proxy address
		PaymentMaster proxyMaster = PaymentMaster(address(createdProxy));

		// Initialize with the owner address and logic impl address
		proxyMaster.initialize(owner, address(handlerLogicAddress));

		// Emit the event that a new master was deployed
		emit MasterCreated(address(proxyMaster));
	}
}