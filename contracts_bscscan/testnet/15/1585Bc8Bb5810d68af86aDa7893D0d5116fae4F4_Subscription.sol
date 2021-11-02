// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IMainPool {
    function transferToPool(
        address _userAddress,
        address _creatorAddress,
        address _token,
        uint256 _conversionRate,
        uint256 _amount,
        uint256 _USDAmount,
        string calldata _code
    ) external;

    function transferTipToPool(
        address _userAddress,
        address _creatorAddress,
        address _token,
        uint256 _amount
    ) external;
}

interface IOraclePrice {
    function getAmountsOut(uint256 _amountIn)
        external
        view
        returns (uint256[] memory amounts);
    function getAmountsOut(uint256 _amountIn, address[] calldata _pairToken)
        external
        view
        returns (uint256[] memory amounts);
    function getPrice(string calldata ref1, string calldata ref2) 
        external
        view 
        returns (uint256 amount);
     function getAmountToken(string calldata string0, string calldata string1, address t0, address t1, uint256 _amountIn)
        external
        view
        returns (uint256 tokenAmount);
}

contract Permission is OwnableUpgradeable {
    mapping(address => bool) blacklist;

    event BanUser(address indexed _address);
    event UnbanUser(address indexed _address);

    modifier onlyAllow() {
        require(!blacklist[msg.sender], "User is banned");
        _;
    }

    function banUser(address _address) public onlyOwner {
        blacklist[_address] = true;
        emit BanUser(_address);
    }

    function unbanUser(address _address) public onlyOwner {
        delete blacklist[_address];
        emit UnbanUser(_address);
    }
}

contract Subscription is Permission {
    
    using SafeMath for uint256;
    uint256 private nextPlanId;
    address private poolAddress;
    address private oraclePriceAddress;
    address private BUSDAddress;
    address private IDOLAddress;

    
    struct Subscript {
        uint256 start;
        uint256 nextPayment;
    }

    struct Plan {
        address creator;
        uint256 amount;
        uint256 duration;
    }
    

    mapping(uint256 => Plan) public plans;
    mapping(uint256 => address[]) public planTokens;
    mapping(address => mapping(uint256 => Subscript)) private subscriptions;
    mapping(address => bool) private creators;

    event CreatorCreated(address creatorAddress);
    event PlanCreated(address[] tokens, uint256 planId, uint256 amount, uint256 duration);
    event PlanUpdated(address[] tokens, uint256 planId, uint256 amount, uint256 duration);
    event Subscribed(
        address token, 
        uint256 planAmount,
        uint256 amount,
        uint256 planId,
        uint256 expiredOn
    );

    event Tipped(address creator, address token, uint256 amount);
    
    function initialize(
      address _poolAddress,
      address _oraclePriceAddress,
      address _BUSDAddress,
      address _IDOLAddress
    ) external {
        poolAddress = _poolAddress;
        oraclePriceAddress = _oraclePriceAddress;
        BUSDAddress = _BUSDAddress;
        IDOLAddress = _IDOLAddress;
        OwnableUpgradeable.__Ownable_init();
    }

    function setOraclePriceAddres(address _oraclePriceAddress)
        external
        onlyOwner
    {
        oraclePriceAddress = _oraclePriceAddress;
    }

    function setPoolAddress(address _poolAddress) external onlyOwner {
        poolAddress = _poolAddress;
    }
    
    function setBUSDAddress(address _BUSDAddress) external onlyOwner {
        BUSDAddress = _BUSDAddress;
    }
    
    function setIDOLAddress(address _IDOLAddress) external onlyOwner {
        IDOLAddress = _IDOLAddress;
    }

    function createCreator() external {
        creators[msg.sender] = true;
        emit CreatorCreated(msg.sender);
    }

    function createPlan(address[] calldata _tokens, uint256 _amount, uint256 _duration)
        external
        onlyAllow
    {
        // validation
        require(checkIsCreator(msg.sender), "caller is not the creator");
        require(_amount > 0, "amount needs to be > 0");
        require(_duration > 0, "duration needs to be > 0");
        plans[nextPlanId] = Plan(msg.sender, _amount, _duration);
        planTokens[nextPlanId] = _tokens;
        emit PlanCreated(_tokens, nextPlanId, _amount, _duration);
        nextPlanId = nextPlanId.add(1);
    }

    function updatePlan(
        address[] calldata _tokens,
        uint256 _planId,
        uint256 _amount,
        uint256 _duration
    ) external onlyAllow {
        require(checkIsCreator(msg.sender), "caller is not the creator");
        require(_amount > 0, "amount needs to be > 0");
        require(_duration > 0, "duration needs to be > 0");
        plans[_planId] = Plan(msg.sender, _amount, _duration);
        planTokens[_planId] = _tokens;
        require(plans[_planId].amount != 0, "plan not exist");
        emit PlanUpdated(_tokens, _planId, _amount, _duration);
    }

    function checkIsCreator(address _address)
        public
        view
        returns (bool isCreator)
    {
        isCreator = creators[_address];
    }
    
    function checkPrice(uint256 _BUSDAmount, address[] memory _pairToken)
        public
        view
        onlyAllow
        returns (uint256 amount)
    {
         // get price from pancake, convert from BUSD to TOKEN
        uint256[] memory pairAmount = IOraclePrice(oraclePriceAddress).getAmountsOut(_BUSDAmount, _pairToken);
        return pairAmount[1];
    }

    function subscribe(uint256 _planId, address _token, string calldata _code) external onlyAllow {
        Plan storage plan = plans[_planId];
        require(plan.creator != address(0), "this plan does not exist");
        // token must exist in plan 
        bool tokenExistInPlan = false;
        address[] memory tokens = planTokens[_planId];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _token) {
                tokenExistInPlan = true;
            }
        }
        require(tokenExistInPlan, "this plan do not contain this token");

        Subscript memory subscription = subscriptions[msg.sender][_planId];

        // can sub to expired plan only
        if (subscription.start != 0) {
            require(
                block.number > subscription.nextPayment,
                "the plan is not expired yet"
            );
        }
        
        // convert USD plan price to BUSD price
        uint256 amount = 0;
        uint256 conversionRate = 0;

        if (_token == BUSDAddress) {
            uint256 BUSDRatio = IOraclePrice(oraclePriceAddress).getPrice("USD", "BUSD");
            amount = (plan.amount.mul(BUSDRatio)).div(10 ** 18);
            // transfer BUSD to pool
        }
        else {
            // pay with other token or IDOL
            // convert BUSD price to token price\
            amount = IOraclePrice(oraclePriceAddress).getAmountToken("BUSD", "USD", BUSDAddress, _token,  plan.amount);
            // transfer token to pool
        }
        //
        conversionRate = IOraclePrice(oraclePriceAddress).getAmountToken("BUSD", "USD", BUSDAddress, IDOLAddress, 10 ** 18);


        // call contract main pool to transfer
        IMainPool(poolAddress).transferToPool(
            msg.sender,
            plan.creator,
            _token,
            conversionRate,
            amount,
            plan.amount,
            _code
        );
        
        // expired date
        uint256 nextPayment = block.number.add(plan.duration);

        emit Subscribed(_token, plan.amount, amount, _planId, nextPayment);

        // add subscription plan to user
        subscription.start = block.number;
        subscription.nextPayment = nextPayment;
        subscriptions[msg.sender][_planId] = subscription;
    }

    function tip(address _creatorAddress, address _token, uint256 _amount)
        external
        onlyAllow
    {
        // call contract main pool to transfer
        IMainPool(poolAddress).transferTipToPool(
            msg.sender,
            _creatorAddress,
            _token,
            _amount
        );
        emit Tipped(_creatorAddress, _token,  _amount);
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}