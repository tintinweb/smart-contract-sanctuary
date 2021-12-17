/**
 *Submitted for verification at polygonscan.com on 2021-12-17
*/

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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


// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}


pragma solidity ^0.5.0;

/*
 * The Charg Service Contract
 *
 * Handles Charg Swap Exchange, Bridge, Services and Feedbacks on Any Blockchain
 *
 */

contract AnyChgCoinService is ERC20Detailed, ERC20 {
  
	using SafeMath for uint;
    address payable public owner;

    /**
	 * the node main data
	 */
	struct NodeData {

		bool registered;
		bool authorized;

        /* lat, lon values, multiplied by 10^7 */
		int128 latitude;
		int128 longitude;

		/* main parameters */
		string name;
		string phone;
		string location;
		string connector;
		string power;
	}

    /**
	 * service parameters for the particular node 
	 */
	struct ServiceData {
		bool allowed; // service allowed on the node
		uint rate;    // service rate in coins gwei per second
		uint maxTime; // max service time in seconds (0==unlimited)
		bool stopable; // return allowed
	}


    /* service action data */
	struct ServiceAction {
		uint started;
		uint finished;
		bool stopable;
		address node;
		address payer;
		uint serviceRate;
		uint16 serviceId;
		uint8 feedbackRate;
		string feedbackText;
	}

	uint16 public servicesCount = 0; 
	mapping (uint16 => string) public services;  // array of possible services

    mapping (address => mapping (bytes32 => string)) public nodeParameters;  //node => parametrHash => parameterValue

    mapping (address => NodeData) public registeredNodes;

    mapping (address => mapping (uint16 => ServiceData)) public nodeService;  //node => serviceId => ServiceData

	mapping (bytes32 => ServiceAction) public serviceActions; // paymentHash => ServiceAction
	
	/**
	 * minimal CHG balance for start service on the node
	 */
    uint public minCoinsBalance = 500 * 10 ** 18; // 500 CHG default
    
	/**
	 *   Exchange Service Structures
	 */
	struct Order {
		address user;
		uint amountGive;
		uint amountGet;
		uint expire;
	}
  
	mapping (bytes32 => Order) public sellOrders;
	mapping (bytes32 => Order) public buyOrders;
	
	/*  balance of exchange nodes  */
	mapping (address => uint) public ethBalance; // the other blochchain native token

	/*  sevice events  */
 	event NodeRegistered ( address indexed addr, int128 indexed latitude, int128 indexed longitude, string name, string location, string phone, string connector, string power );

	event DepositEther  ( address sender, uint EthValue, uint EthBalance );
	event WithdrawEther ( address sender, uint EthValue, uint EthBalance );
	
	event DepositCoins  ( address sender, uint CoinValue, uint CoinBalance );
	event WithdrawCoins ( address sender, uint CoinValue, uint CoinBalance );
 
	event SellOrder ( bytes32 indexed orderHash, uint amountGive, uint amountGet, uint expire, address seller );
	event BuyOrder  ( bytes32 indexed orderHash, uint amountGive, uint amountGet, uint expire, address buyer );
	
	event CancelSellOrder ( bytes32 indexed orderHash );
	event CancelBuyOrder  ( bytes32 indexed orderHash );

	event Sell ( bytes32 indexed orderHash, uint amountGive, uint amountGet, address seller );
	event Buy  ( bytes32 indexed orderHash, uint amountGive, uint amountGet, address buyer );
	
	event ServiceOn  ( address indexed nodeAddr, address indexed payer, bytes32 paymentHash, uint16 serviceId, uint chgAmount, uint serviceTime, uint finished);
	event ServiceOff ( address indexed nodeAddr, address indexed payer, bytes32 paymentHash, uint16 serviceId, uint chgAmount, uint serviceTime, uint finished);
	event Feedback   ( address indexed nodeAddr, address indexed payer, bytes32 paymentHash, uint16 serviceId, uint8 feedbackRate);

    /*
     *  Bridge 
     */
    uint64 public networkId; // this network id
    uint256 public minBridgeValue = 1 * 10**18; // min. bridge transfer value (1 CHG)
    uint256 public maxBridgeValue = 10000 * 10**18; // max. bridge transfer value (10000 CHG)

	struct Chain {
        bool active;
        string networkName;
	}

	mapping (uint64 => Chain) public chains; // networkId => Chain

    mapping (bytes32 => bool) public swaps;

    mapping (address => bool) public isValidator;

    event Swap(address indexed from, address indexed to, uint256 value, uint64 chainId, bytes32 chainHash);
    event Validated(bytes32 indexed txHash, address indexed account, uint256 value);


	/**
	 * constructor
	 */
    constructor(uint64 _networkId) ERC20Detailed("Charg Coin", "CHG", 18) public {
        owner = msg.sender;
        isValidator[owner] = true;
        networkId = _networkId;

		/*  initial services  */
		services[servicesCount] = 'Charg';
		servicesCount++;

		services[servicesCount] = 'Parking';
		servicesCount++;

		services[servicesCount] = 'Internet';
		servicesCount++;

        /*  initial chains  */
        chains[1]       = Chain(true, 'Ethereum Mainnet');
        chains[56]      = Chain(true, 'Binance Smart Chain');
        chains[128]     = Chain(true, 'Heco Chain');
        chains[137]     = Chain(true, 'Polygon Network');
        chains[32659]   = Chain(true, 'Fusion Network');
        chains[42161]   = Chain(true, 'Arbitrum One Chain');
        chains[22177]   = Chain(true, 'Native Charg Network');
    }

    function destroy() public {
        require(msg.sender == owner, "only owner");
        selfdestruct(owner);
    }

	function() external payable {
		//revert();
		depositEther();
	}

    function setOwner(address payable newOwner) public {
        require(msg.sender == owner, "only owner");
        owner = newOwner;
    }
    
    /* add a new service to the smart contract */
	function addService( string memory name ) public {
        require(msg.sender == owner, "only owner");
		services[servicesCount] = name;
		servicesCount++;
	}


    /* register a new node */
    function registerNode( int128 latitude, int128 longitude, string memory name, string memory location, string memory phone, string memory connector, string memory power, uint chargRate, uint parkRate, uint inetRate) public {

		// check if node is not registered, or authorized for update
        require ( !registeredNodes[msg.sender].registered || registeredNodes[msg.sender].authorized, "already registered" );

		// check minimal coins balance
        require (balanceOf(msg.sender) >= minCoinsBalance);

		if (!registeredNodes[msg.sender].registered) {
			registeredNodes[msg.sender].registered = true;
			registeredNodes[msg.sender].authorized = true;
		}

		registeredNodes[msg.sender].latitude = latitude;
		registeredNodes[msg.sender].longitude = longitude;

		registeredNodes[msg.sender].name = name;
		registeredNodes[msg.sender].location = location;
		registeredNodes[msg.sender].phone = phone;
		registeredNodes[msg.sender].connector = connector;
		registeredNodes[msg.sender].power = power;

        if (chargRate > 0) {
			nodeService[msg.sender][0].allowed = true;
			nodeService[msg.sender][0].stopable = true;
			nodeService[msg.sender][0].maxTime = 0;
			nodeService[msg.sender][0].rate = chargRate;
		}

        if (parkRate > 0) {
			nodeService[msg.sender][1].allowed = true;
			nodeService[msg.sender][1].stopable = true;
			nodeService[msg.sender][1].maxTime = 0;
			nodeService[msg.sender][1].rate = parkRate;
		}

        if (inetRate > 0) {
			nodeService[msg.sender][2].allowed = true;
			nodeService[msg.sender][2].stopable = true;
			nodeService[msg.sender][2].maxTime = 0;
			nodeService[msg.sender][2].rate = inetRate;
		}
		emit NodeRegistered( msg.sender, latitude, longitude, name, location, phone, connector, power );
	}


    /* setup the node parameters */
    function setNodeParameter(bytes32 parameterHash, string memory parameterValue) public {
        require (registeredNodes[msg.sender].registered, "not registered");
        nodeParameters[msg.sender][parameterHash] = parameterValue;
    }
	

    /* setup the node services */
	function setupNodeService( uint16 serviceId, bool allowed, bool stopable, uint rate, uint maxTime ) public {
        require (registeredNodes[msg.sender].registered, "not registered");
        require (serviceId < servicesCount);

        nodeService[msg.sender][serviceId].allowed = allowed;
        nodeService[msg.sender][serviceId].stopable = stopable;
        nodeService[msg.sender][serviceId].rate = rate;
        nodeService[msg.sender][serviceId].maxTime = maxTime;
	}

    /* change the node authorization */ 
    function modifyNodeAuthorization (address addr, bool authorized) public {
        require(msg.sender == owner, "only owner");
        require (registeredNodes[msg.sender].registered, "not registered");
        registeredNodes[addr].authorized = authorized;
    }

    /* set minimal coins balance for the node */ 
    function setMinCoinsBalance(uint _newValue) public {
        require(msg.sender == owner, "only owner");
		minCoinsBalance = _newValue;
	}

	function setMinBridgeValue(uint256 _value) public {
        require(msg.sender == owner, "only owner");
        require (_value > 0, "wrong value");
        minBridgeValue = _value;
	}

	function setMaxBridgeValue(uint256 _value) public {
        require(msg.sender == owner, "only owner");
        require (_value > 0, "wrong value");
        maxBridgeValue = _value;
	}

	function addValidator( address _validator ) public {
        require(msg.sender == owner, "only owner");
        isValidator[_validator] = true;
	}

	function removeValidator( address _validator ) public {
        require(msg.sender == owner, "only owner");
        isValidator[_validator] = false;
	}

    /*  cross-chain parameters  */
	function setChain(bool _active, uint64 _networkId, string memory _networkName) public {
        require(msg.sender == owner, "only owner");
		chains[_networkId].active = _active;
		chains[_networkId].networkName = _networkName;
	}

    function startSwapTo(address _to, uint256 _value, uint64 _networkId, bytes32 _chainHash) public {
        require(_networkId != networkId, "swap in the same network not allowed");
        require(chains[_networkId].active, "swap not allowed");
        require(_value >= minBridgeValue && _value <= maxBridgeValue, "wrong value");
        _burn(msg.sender, _value);
        emit Swap(msg.sender, _to, _value, _networkId, _chainHash);
    }

    function startSwap(uint256 _value, uint64 _networkId, bytes32 _chainHash) public {
        startSwapTo(msg.sender, _value, _networkId, _chainHash);
    }

    /*  bridge transactions validation  */
    function validate(bytes32 txHash, address account, uint256 value, uint256 fee) public {
        require (isValidator[msg.sender], "only validators");
        require(!swaps[txHash], "already validated");
        _mint(account, value);
        if (fee > 0) {
            _mint(msg.sender, fee);
        }
        swaps[txHash] = true;
        emit Validated(txHash, account, value);
    }

	function depositEther() public payable {
		ethBalance[msg.sender] = ethBalance[msg.sender].add(msg.value);
		emit DepositEther(msg.sender, msg.value, ethBalance[msg.sender]);
	}

	function withdrawEther(uint amount) public {
		require(ethBalance[msg.sender] >= amount);
		ethBalance[msg.sender] = ethBalance[msg.sender].sub(amount);
		msg.sender.transfer(amount);
		emit WithdrawEther(msg.sender, amount, ethBalance[msg.sender]);
	}

	function buyOrder(uint amountGive, uint amountGet, uint expire) public {
		require(amountGive > 0 && amountGet > 0 && amountGive <= ethBalance[msg.sender]);
		bytes32 orderHash = sha256(abi.encodePacked(msg.sender, amountGive, amountGet, block.number));
		buyOrders[orderHash] = Order(msg.sender, amountGive, amountGet, expire);
		emit BuyOrder(orderHash, amountGive, amountGet, expire, msg.sender);
	}

	function sellOrder(uint amountGive, uint amountGet, uint expire) public {
		require(amountGive > 0 && amountGet > 0 && amountGive <= balanceOf(msg.sender));
		bytes32 orderHash = sha256(abi.encodePacked(msg.sender, amountGive, amountGet, block.number));
		sellOrders[orderHash] = Order(msg.sender, amountGive, amountGet, expire);
		emit SellOrder(orderHash, amountGive, amountGet, expire, msg.sender);
	}

	function cancelBuyOrder(bytes32 orderHash) public {
		require( buyOrders[orderHash].expire > now && buyOrders[orderHash].user == msg.sender);
		buyOrders[orderHash].expire = 0; 
		emit CancelBuyOrder(orderHash);
	}

	function cancelSellOrder(bytes32 orderHash) public {
		require( sellOrders[orderHash].expire > now && sellOrders[orderHash].user == msg.sender);
		sellOrders[orderHash].expire = 0; 
		emit CancelSellOrder(orderHash);
	}

	function buy(bytes32 orderHash) public payable {
        require(sellOrders[orderHash].user != msg.sender, "order owner");
		require(msg.value > 0 && now <= sellOrders[orderHash].expire && 0 <= sellOrders[orderHash].amountGet.sub(msg.value));
		
		uint amountGet; //in CHG
		
		if (msg.value == sellOrders[orderHash].amountGet) {
			amountGet = sellOrders[orderHash].amountGive;
			require(0 <= balanceOf(sellOrders[orderHash].user).sub(amountGet));
			sellOrders[orderHash].amountGive = 0; 
			sellOrders[orderHash].amountGet = 0; 
			sellOrders[orderHash].expire = 0; 
		} else {
			amountGet = sellOrders[orderHash].amountGive.mul(msg.value).div(sellOrders[orderHash].amountGet);
			require(0 <= balanceOf(sellOrders[orderHash].user).sub(amountGet) && 0 <= sellOrders[orderHash].amountGive.sub(amountGet));
			sellOrders[orderHash].amountGive = sellOrders[orderHash].amountGive.sub(amountGet); 
			sellOrders[orderHash].amountGet = sellOrders[orderHash].amountGet.sub(msg.value); 
		}
			
        _transfer(sellOrders[orderHash].user, msg.sender, amountGet);
		ethBalance[sellOrders[orderHash].user] = ethBalance[sellOrders[orderHash].user].add(msg.value);

		emit Buy(orderHash, sellOrders[orderHash].amountGive, sellOrders[orderHash].amountGet, msg.sender);
	}

	function sell(bytes32 orderHash, uint amountGive) public {
        require(buyOrders[orderHash].user != msg.sender, "order owner");
		require(amountGive > 0 && now <= buyOrders[orderHash].expire && 0 <= balanceOf(msg.sender).sub(amountGive) &&  0 <= buyOrders[orderHash].amountGet.sub(amountGive));

		uint amountGet;

		if (amountGive == buyOrders[orderHash].amountGet) {
			amountGet = buyOrders[orderHash].amountGive;
			require(0 <= ethBalance[buyOrders[orderHash].user].sub(amountGet));
			buyOrders[orderHash].amountGive = 0; 
			buyOrders[orderHash].amountGet = 0; 
			buyOrders[orderHash].expire = 0; 
		} else {
			amountGet = buyOrders[orderHash].amountGive.mul(amountGive) / buyOrders[orderHash].amountGet;
			require(0 <= ethBalance[buyOrders[orderHash].user].sub(amountGet) && 0 <= buyOrders[orderHash].amountGive.sub(amountGet));
			buyOrders[orderHash].amountGive = buyOrders[orderHash].amountGive.sub(amountGet); 
			buyOrders[orderHash].amountGet = buyOrders[orderHash].amountGet.sub(amountGive); 
		}

		ethBalance[buyOrders[orderHash].user] = ethBalance[buyOrders[orderHash].user].sub(amountGet);
        _transfer(msg.sender, buyOrders[orderHash].user, amountGive);
        msg.sender.transfer(amountGet);

		emit Sell(orderHash, buyOrders[orderHash].amountGive, buyOrders[orderHash].amountGet, msg.sender);
	}

	/*
	 * Method serviceOn
	 * Make an exchange and start service on the node
	 *
	 * nodeAddr - the node which provides service
	 * serviceId - id of the started service, described in Node Service Contract (0-charge, 1-parking, 2-internet ...)
	 * orderHash - hash of exchange sell order 
	 * paymentHash - hash of the payment transaction 
	 */
	function serviceOn(address nodeAddr, uint16 serviceId, uint time, bytes32 paymentHash, bytes32 orderHash) public payable returns (bytes32) {

		require ( registeredNodes[nodeAddr].authorized          // the node is registered and authorized
				&& (balanceOf(nodeAddr) >= minCoinsBalance) // minimal balance of the node
				&& nodeService[nodeAddr][serviceId].allowed );  // sevice is allowed on the node

		if (paymentHash == 0)
			paymentHash = keccak256(abi.encodePacked(msg.sender, now, serviceId));

		require (serviceActions[paymentHash].started == 0, 'payment served');

        uint chgAmount;
		if (msg.value > 0) {
            // payment in ether, exchange required
			require(now <= sellOrders[orderHash].expire && 0 <= sellOrders[orderHash].amountGet.sub(msg.value));
			if (msg.value == sellOrders[orderHash].amountGet) {
				chgAmount = sellOrders[orderHash].amountGive;
    			require(0 <= balanceOf(sellOrders[orderHash].user).sub(chgAmount));
				sellOrders[orderHash].amountGive = 0; 
				sellOrders[orderHash].amountGet = 0; 
				sellOrders[orderHash].expire = 0; 
			} else {
				chgAmount = sellOrders[orderHash].amountGive.mul(msg.value) / sellOrders[orderHash].amountGet;
				require(0 <= balanceOf(sellOrders[orderHash].user).sub(chgAmount) && 0 <= sellOrders[orderHash].amountGive.sub(chgAmount));
				sellOrders[orderHash].amountGive = sellOrders[orderHash].amountGive.sub(chgAmount); 
				sellOrders[orderHash].amountGet = sellOrders[orderHash].amountGet.sub(msg.value); 
			}
			// time will be calculated by amount
			time = chgAmount.div(nodeService[nodeAddr][serviceId].rate);
			require ( time <= nodeService[nodeAddr][serviceId].maxTime || nodeService[nodeAddr][serviceId].maxTime == 0);

            if (sellOrders[orderHash].user != nodeAddr) {
                // no need to transfer if it is the same account
                _transfer(sellOrders[orderHash].user, nodeAddr, chgAmount);
            }
            ethBalance[sellOrders[orderHash].user] = ethBalance[sellOrders[orderHash].user].add(msg.value);
			emit Buy(orderHash, sellOrders[orderHash].amountGive, sellOrders[orderHash].amountGet, msg.sender);

		} else {
            // CHG payment
			require ( time <= nodeService[nodeAddr][serviceId].maxTime || nodeService[nodeAddr][serviceId].maxTime == 0);
			chgAmount = time * nodeService[nodeAddr][serviceId].rate;
			require( chgAmount > 0 && 0 <= balanceOf(msg.sender).sub(chgAmount) );
            _transfer(msg.sender, nodeAddr, chgAmount);
		}

        serviceActions[paymentHash].node = nodeAddr; 
        serviceActions[paymentHash].payer = msg.sender; //will allow feedback for the sender
        serviceActions[paymentHash].serviceRate = nodeService[nodeAddr][serviceId].rate;
        serviceActions[paymentHash].serviceId = serviceId;
        serviceActions[paymentHash].started = now;
        serviceActions[paymentHash].finished = now + time;
        serviceActions[paymentHash].stopable = nodeService[nodeAddr][serviceId].stopable;

		emit ServiceOn (nodeAddr, msg.sender, paymentHash, serviceId, chgAmount, time, now + time);

		return paymentHash;
	}

	
	/*
	 * Method serviceOff
	 * Turn off the service on the node
	 */
	function serviceOff( bytes32 paymentHash ) public {

		require(serviceActions[paymentHash].started > 0 
                    && serviceActions[paymentHash].stopable
					&& now < serviceActions[paymentHash].finished 
					&& serviceActions[paymentHash].payer == msg.sender);

		uint time = serviceActions[paymentHash].finished.sub(now);
		uint chgAmount = time.mul(serviceActions[paymentHash].serviceRate);
        serviceActions[paymentHash].finished = now;

        _transfer(serviceActions[paymentHash].node, msg.sender, chgAmount);
        
		emit ServiceOff (serviceActions[paymentHash].node, msg.sender, paymentHash, serviceActions[paymentHash].serviceId, chgAmount, time, now);
	}


	/*
	 * Method sendFeedback
	 * Store feedback of the successful payment transaction in the smart contract
	 * paymentHash - hash of the payment transaction
	 * rate - the node raiting 1..10 points 
	 */
	function sendFeedback(bytes32 paymentHash, uint8 feedbackRate, string memory feedbackText) public {

		require(serviceActions[paymentHash].payer == msg.sender && serviceActions[paymentHash].feedbackRate == 0);

		serviceActions[paymentHash].feedbackRate = feedbackRate > 10 ? 10 : (feedbackRate < 1 ? 1 : feedbackRate);
		serviceActions[paymentHash].feedbackText = feedbackText;
		
		emit Feedback (serviceActions[paymentHash].node, msg.sender, paymentHash, serviceActions[paymentHash].serviceId, serviceActions[paymentHash].feedbackRate);
	}
}