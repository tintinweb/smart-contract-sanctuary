/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// pragma solidity ^0.5.0;

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
     * // importANT: Beware that changing an allowance with this method brings the risk
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


// Dependency file: @openzeppelin/contracts/math/SafeMath.sol

// pragma solidity ^0.5.0;

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


// Dependency file: @openzeppelin/contracts/utils/Address.sol

// pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [// importANT]
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
     * // importANT: because control is transferred to `recipient`, care must be
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


// Dependency file: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

// pragma solidity ^0.5.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

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


// Dependency file: contracts/interfaces/IStaking.sol

// pragma solidity >=0.5.0;

interface IStaking {
    function incomeRateChanged() external;
    function rewardRateChanged() external;
    function hashRateToken() external view returns(address);
    function totalSupply() external view returns(uint256);
}

// Dependency file: contracts/interfaces/IMineParam.sol

// pragma solidity >=0.5.0;

interface IMineParam {
    function minePrice() external view returns (uint256);
    function getMinePrice() external view returns (uint256);
    function mineIncomePerTPerSecInWei() external view returns(uint256);
    function incomePerTPerSecInWei() external view returns(uint256);
    function setIncomePerTPerSecInWeiAndUpdateMinePrice(uint256 _incomePerTPerSecInWei) external;
    function updateMinePrice() external;
    function paramSetter() external view returns(address);
    function addListener(address _listener) external;
    function removeListener(address _listener) external returns(bool);
}

// Dependency file: contracts/interfaces/ILpStaking.sol

// pragma solidity >=0.5.0;

interface ILpStaking {
    function stakingLpToken() external view returns (address);
    function totalSupply() external view returns(uint256);
}

// Dependency file: contracts/interfaces/ITokenTreasury.sol

// pragma solidity >=0.5.0;

interface ITokenTreasury {
    function claim(address _token, uint _amount) external;
}

// Dependency file: contracts/modules/Pausable.sol

// pragma solidity >=0.5.0;

contract Pausable {

    event Paused();

    event Unpaused();

    bool private _paused;

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function _pause() internal {
        _paused = true;
        emit Paused();
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function _unpause() internal {
        _paused = false;
        emit Unpaused();
    }
}


// Dependency file: contracts/modules/POWERC20.sol

// pragma solidity >=0.5.0;

// import "@openzeppelin/contracts/math/SafeMath.sol";
// import 'contracts/modules/Pausable.sol';

contract POWERC20 is Pausable{
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function initializeToken(string memory tokenName, string memory tokenSymbol) internal {
        name = tokenName;
        symbol = tokenSymbol;

        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external whenNotPaused returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) whenNotPaused external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'HashRateERC20: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'HashRateERC20: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// Dependency file: contracts/modules/Ownable.sol

// pragma solidity >=0.5.0;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: FORBIDDEN');
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


// Dependency file: contracts/modules/Paramable.sol

// pragma solidity >=0.5.0;

// import 'contracts/modules/Ownable.sol';

contract Paramable is Ownable {
    address public paramSetter;

    event ParamSetterChanged(address indexed previousSetter, address indexed newSetter);

    constructor() public {
        paramSetter = msg.sender;
    }

    modifier onlyParamSetter() {
        require(msg.sender == owner || msg.sender == paramSetter, "!paramSetter");
        _;
    }

    function setParamSetter(address _paramSetter) external onlyOwner {
        require(_paramSetter != address(0), "param setter is the zero address");
        emit ParamSetterChanged(paramSetter, _paramSetter);
        paramSetter = _paramSetter;
    }

}


// Dependency file: contracts/interfaces/IERC20Detail.sol

// pragma solidity >=0.5.0;

interface IERC20Detail {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
}

// Dependency file: contracts/interfaces/ISwapPair.sol

// pragma solidity >=0.5.0;

interface ISwapPair {
    function totalSupply() external view returns(uint256);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// Root file: contracts/POWToken.sol

pragma solidity >=0.5.0;

// import '/Users/tercel/work/bmining/bmining-protocol/node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';
// import '/Users/tercel/work/bmining/bmining-protocol/node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import 'contracts/interfaces/IStaking.sol';
// import 'contracts/interfaces/IMineParam.sol';
// import 'contracts/interfaces/ILpStaking.sol';
// import 'contracts/interfaces/ITokenTreasury.sol';
// import 'contracts/modules/POWERC20.sol';
// import 'contracts/modules/Paramable.sol';
// import "contracts/interfaces/IERC20Detail.sol";
// import 'contracts/interfaces/ISwapPair.sol';

contract POWToken is Paramable, POWERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool internal initialized;
    address public minter;
    address public stakingPool;
    address public mineParam;
    address public treasury;

    uint256 public elecPowerPerTHSec;
    uint256 public startMiningTime;

    uint256 public electricCharge;
    uint256 public minerPoolFeeNumerator;
    uint256 public depreciationNumerator;
    uint256 public workingRateNumerator;
    uint256 public workingHashRate;
    uint256 public totalHashRate;
    uint256 public workerNumLastUpdateTime;

    address public incomeToken;
    uint256 public incomeRate;
    address public rewardsToken;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public rewardPeriodFinish;
  
    address[] public stakings;
    mapping(address => uint256) public stakingRewardWeight;
    uint256 public stakingRewardWeightTotal;
    mapping(address => uint256) public lpStakingIncomeWeight;
    uint256 public lpStakingIncomeWeightTotal;

    mapping(address => uint256) public stakingType;  // 0: unknown, 1: normal erc20 token, 2: LP token

    function initialize(string memory name, string memory symbol, address _stakingPool, address _lpStakingPool, address _lpStakingPool2, address _minter, address _mineParam, address _incomeToken, address _rewardsToken, address _treasury, uint256 _elecPowerPerTHSec, uint256 _electricCharge, uint256 _minerPoolFeeNumerator, uint256 _totalHashRate) public {
        require(!initialized, "Token already initialized");
        require(_minerPoolFeeNumerator < 1000000, "nonlegal minerPoolFeeNumerator.");

        initialized = true;
        initializeToken(name, symbol);

        stakingPool = _stakingPool; // POWStaking address
        _setStakingPool(stakingPool, 1);
        _setStakingPool(_lpStakingPool, 2);
        _setStakingPool(_lpStakingPool2, 2);

        minter = _minter; // TokenExchange address
        mineParam = _mineParam;
        incomeToken = _incomeToken;
        rewardsToken = _rewardsToken;
        treasury = _treasury;
        elecPowerPerTHSec = _elecPowerPerTHSec;
        startMiningTime =  block.timestamp;
        electricCharge = _electricCharge;
        minerPoolFeeNumerator = _minerPoolFeeNumerator;
        totalHashRate = _totalHashRate;

        rewardsDuration = 30 days;
        depreciationNumerator = 1000000;
        workingHashRate = _totalHashRate;
        workerNumLastUpdateTime = startMiningTime;

        updateIncomeRate();
    }

    function isStakingPool(address _pool) public view  returns (bool) {
        return stakingType[_pool] != 0;
    }

    function setStakingPools(address[] calldata _pools, uint256[] calldata _values) external onlyOwner {
        require(_pools.length == _values.length, 'invalid parameters');
        for(uint256 i; i< _pools.length; i++) {
            _setStakingPool(_pools[i], _values[i]);
        }
        updateStakingPoolsIncome();
        updateStakingPoolsReward();
    }

    function setStakingPool(address _pool, uint256 _value) external onlyOwner {
        _setStakingPool(_pool, _value);
        updateStakingPoolsIncome();
        updateStakingPoolsReward();
    }

    function _setStakingPool(address _pool, uint256 _value) internal {
        if(_pool != address(0)) {
            stakingType[_pool] = _value;
            if(foundStaking(_pool) == false) {
                stakings.push(_pool);
            } 
        }
    }

    function foundStaking(address _pool) public view returns (bool) {
        for(uint256 i; i< stakings.length; i++) {
            if(stakings[i] == _pool) {
                return true;
            }
        }
        return false;
    }

    function countStaking() public view  returns (uint256) {
        return stakings.length;
    }

    function setStakingRewardWeights(address[] calldata _pools, uint256[] calldata _values) external onlyParamSetter {
        require(_pools.length == _values.length, "illegal parameters");
        updateStakingPoolsReward();
        for(uint256 i; i<_pools.length; i++) {
            _setStakingRewardWeight(_pools[i], _values[i]);
        }
    }

    function setStakingRewardWeight(address _pool, uint256 _value) external onlyParamSetter {
        updateStakingPoolsReward();
        _setStakingRewardWeight(_pool, _value);
    }

    function _setStakingRewardWeight(address _pool, uint256 _value) internal {
        require(isStakingPool(_pool), "illegal pool");
        stakingRewardWeightTotal = stakingRewardWeightTotal.sub(stakingRewardWeight[_pool]).add(_value);
        stakingRewardWeight[_pool] = _value;
    }

    function getStakingRewardRate(address _pool) public view returns(uint256) {
        if(stakingRewardWeightTotal == 0) {
            return 0;
        }
        return rewardRate.mul(stakingRewardWeight[_pool]).div(stakingRewardWeightTotal);
    }

    function setLpStakingIncomeWeights(address[] calldata _pools, uint256[] calldata _values) external onlyParamSetter {
        require(_pools.length == _values.length, "illegal parameters");
        updateStakingPoolsIncome();
        for(uint256 i; i<_pools.length; i++) {
            _setLpStakingIncomeWeight(_pools[i], _values[i]);
        }
    }

    function setLpStakingIncomeWeight(address _pool, uint256 _value) external onlyParamSetter {
        updateStakingPoolsIncome();
        _setLpStakingIncomeWeight(_pool, _value);
    }
        
    function _setLpStakingIncomeWeight(address _pool, uint256 _value) internal {
        require(stakingType[_pool] == 2, "illegal pool");
        lpStakingIncomeWeightTotal = lpStakingIncomeWeightTotal.sub(lpStakingIncomeWeight[_pool]).add(_value);
        lpStakingIncomeWeight[_pool] = _value;
    }

    function getLpStakingSupply(address _pool) public view returns(uint256) {
        if(totalSupply == 0 || stakingType[_pool] != 2 || lpStakingIncomeWeightTotal == 0) {
            return 0;
        }

        uint256 poolAmount;
        uint256 windfallAmount;
        {
            uint256 stakingPoolSupply;
            if (stakingPool != address(0)) {
                stakingPoolSupply = IStaking(stakingPool).totalSupply();
            }
            uint256 poolsTotal;
            uint256 unknown;
            (poolAmount, poolsTotal) = getLpStakingsReserve(_pool);
            if(totalSupply > stakingPoolSupply.add(poolsTotal)) {
                unknown = totalSupply.sub(stakingPoolSupply).sub(poolsTotal);
            }
            windfallAmount = unknown.mul(lpStakingIncomeWeight[_pool]).div(lpStakingIncomeWeightTotal);
        }
       
        return poolAmount.add(windfallAmount);
    }

    function getLpStakingsReserve(address _pool) public view returns (uint256, uint256) {
        uint256 total;
        uint256 amount;
        for (uint256 i; i<stakings.length; i++) {
            if(stakingType[stakings[i]] == 2) {
                uint256 _amount = getLpStakingReserve(stakings[i]);
                total = total.add(_amount);
                if(_pool == stakings[i]) {
                    amount = _amount;
                }
            }
        }
        return (amount, total);
    }

    function getLpStakingReserve(address _pool) public view returns (uint256) {
        address pair = ILpStaking(_pool).stakingLpToken();
        if(pair == address(0)) {
            return 0;
        }
        uint256 reserve = getReserveFromLp(pair);
        if(reserve == 0) {
            return 0;
        }
        uint256 stakingAmount = ILpStaking(_pool).totalSupply();
        uint256 pairTotal = ISwapPair(pair).totalSupply();
        if(pairTotal > 0 && reserve.mul(stakingAmount) > pairTotal) {
            return reserve.mul(stakingAmount).div(pairTotal);
        }
        return 0;
    }

    function getReserveFromLp(address _pair) public view returns (uint256) {
        address token0 = ISwapPair(_pair).token0();
        address token1 = ISwapPair(_pair).token1();
        (uint256 reserve0, uint256 reserve1, ) = ISwapPair(_pair).getReserves();
        if (token0 == address(this)) {
            return reserve0;
        } else if (token1 == address(this)) {
            return reserve1;
        }
        return 0;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function pause() onlyOwner external {
        _pause();
    }

    function unpause() onlyOwner external {
        _unpause();
    }

    function weiToIncomeTokenValue(uint256 amount) public view returns (uint256) {
        uint256 decimals = 18;
        if(incomeToken != address(0)) {
            decimals = uint256(IERC20Detail(incomeToken).decimals());
        }
        if(decimals < 18) {
            uint diff = 18 - decimals;
            amount = amount.div(10**diff);
        } else if(decimals > 18) {
            uint diff = decimals - 18;
            amount = amount.mul(10**diff);
        }
        return amount;
    }

    function remainingAmount() public view returns(uint256) {
        return totalHashRate.mul(1e18).sub(totalSupply);
    }

    function mint(address to, uint value) external whenNotPaused {
        require(msg.sender == minter, "!minter");
        require(value <= remainingAmount(), "not sufficient supply.");
        _mint(to, value);
        updateStakingPoolsIncome();
    }

    function setMinter(address _minter) external onlyParamSetter {
        require(minter != _minter, "same minter.");
        minter = _minter;
    }

    function addHashRate(uint256 hashRate) external onlyParamSetter {
        require(hashRate > 0, "hashRate cannot be 0");

        // should keep current workingRate and incomeRate unchanged.
        totalHashRate = totalHashRate.add(hashRate.mul(totalHashRate).div(workingHashRate));
        workingHashRate = workingHashRate.add(hashRate);
    }

    function setMineParam(address _mineParam) external onlyParamSetter {
        require(mineParam != _mineParam, "same mineParam.");
        mineParam = _mineParam;
        updateIncomeRate();
    }

    function setStartMiningTime(uint256 _startMiningTime) external onlyParamSetter {
        require(startMiningTime != _startMiningTime, "same startMiningTime.");
        require(startMiningTime > block.timestamp, "already start mining.");
        require(_startMiningTime > block.timestamp, "nonlegal startMiningTime.");
        startMiningTime = _startMiningTime;
        workerNumLastUpdateTime = _startMiningTime;
    }

    function setElectricCharge(uint256 _electricCharge) external onlyParamSetter {
        require(electricCharge != _electricCharge, "same electricCharge.");
        electricCharge = _electricCharge;
        updateIncomeRate();
    }

    function setMinerPoolFeeNumerator(uint256 _minerPoolFeeNumerator) external onlyParamSetter {
        require(minerPoolFeeNumerator != _minerPoolFeeNumerator, "same minerPoolFee.");
        require(_minerPoolFeeNumerator < 1000000, "nonlegal minerPoolFee.");
        minerPoolFeeNumerator = _minerPoolFeeNumerator;
        updateIncomeRate();
    }

    function setDepreciationNumerator(uint256 _depreciationNumerator) external onlyParamSetter {
        require(depreciationNumerator != _depreciationNumerator, "same depreciationNumerator.");
        require(_depreciationNumerator <= 1000000, "nonlegal depreciation.");
        depreciationNumerator = _depreciationNumerator;
        updateIncomeRate();
    }

    function setWorkingHashRate(uint256 _workingHashRate) external onlyParamSetter {
        require(workingHashRate != _workingHashRate, "same workingHashRate.");
        //require(totalHashRate >= _workingHashRate, "param workingHashRate not legal.");

        if (block.timestamp > startMiningTime) {
            workingRateNumerator = getHistoryWorkingRate();
            workerNumLastUpdateTime = block.timestamp;
        }

        workingHashRate = _workingHashRate;
        updateIncomeRate();
    }

    function getHistoryWorkingRate() public view returns (uint256) {
        if (block.timestamp > startMiningTime) {
            uint256 time_interval = block.timestamp.sub(workerNumLastUpdateTime);
            uint256 totalRate = workerNumLastUpdateTime.sub(startMiningTime).mul(workingRateNumerator).add(time_interval.mul(getCurWorkingRate()));
            uint256 totalTime = block.timestamp.sub(startMiningTime);

            return totalRate.div(totalTime);
        }

        return 0;
    }

    function getCurWorkingRate() public view  returns (uint256) {
        return 1000000 * workingHashRate / totalHashRate;
    }

    function getPowerConsumptionMineInWeiPerSec() public view returns(uint256){
        uint256 minePrice = IMineParam(mineParam).minePrice();
        if (minePrice != 0) {
            uint256 Base = 1e18;
            uint256 elecPowerPerTHSecAmplifier = 1000;
            uint256 powerConsumptionPerHour = elecPowerPerTHSec.mul(Base).div(elecPowerPerTHSecAmplifier).div(1000);
            uint256 powerConsumptionMineInWeiPerHour = powerConsumptionPerHour.mul(electricCharge).div(1000000).div(minePrice);
            return powerConsumptionMineInWeiPerHour.div(3600);
        }
        return 0;
    }

    function getIncomeMineInWeiPerSec() public view returns(uint256){
        uint256 paramDenominator = 1000000;
        uint256 afterMinerPoolFee = 0;
        {
            uint256 mineIncomePerTPerSecInWei = IMineParam(mineParam).mineIncomePerTPerSecInWei();
            afterMinerPoolFee = mineIncomePerTPerSecInWei.mul(paramDenominator.sub(minerPoolFeeNumerator)).div(paramDenominator);
        }

        uint256 afterDepreciation = 0;
        {
            afterDepreciation = afterMinerPoolFee.mul(depreciationNumerator).div(paramDenominator);
        }

        return afterDepreciation;
    }

    function updateIncomeRate() public {
        //not start mining yet.
        if (block.timestamp > startMiningTime) {
            // update income first.
            updateStakingPoolsIncome();
        }

        uint256 oldValue = incomeRate;

        //compute electric charge.
        uint256 powerConsumptionMineInWeiPerSec = getPowerConsumptionMineInWeiPerSec();

        //compute mine income
        uint256 incomeMineInWeiPerSec = getIncomeMineInWeiPerSec();

        if (incomeMineInWeiPerSec > powerConsumptionMineInWeiPerSec) {
            uint256 targetRate = incomeMineInWeiPerSec.sub(powerConsumptionMineInWeiPerSec);
            incomeRate = targetRate.mul(workingHashRate).div(totalHashRate);
        }
        //miner close down.
        else {
            incomeRate = 0;
        }

        emit IncomeRateChanged(oldValue, incomeRate);
    }

    function updateStakingPoolsIncome() public {
        for (uint256 i; i<stakings.length; i++) {
            if(msg.sender != stakings[i] && isStakingPool(stakings[i]) && address(this) == IStaking(stakings[i]).hashRateToken()) {
                IStaking(stakings[i]).incomeRateChanged();
            }
        }
    }

    function updateStakingPoolsReward() public {
        for (uint256 i; i<stakings.length; i++) {
            if(msg.sender != stakings[i] && isStakingPool(stakings[i]) && address(this) == IStaking(stakings[i]).hashRateToken()) {
                IStaking(stakings[i]).rewardRateChanged();
            }
        }
    }

    function _setRewardRate(uint256 _rewardRate) internal {
        updateStakingPoolsReward();
        emit RewardRateChanged(rewardRate, _rewardRate);
        rewardRate = _rewardRate;
        rewardPeriodFinish = block.timestamp.add(rewardsDuration);
    }

    function setRewardRate(uint256 _rewardRate)  external onlyParamSetter {
        _setRewardRate(_rewardRate);
    }

    function getRewardRateByReward(uint256 reward) public view returns (uint256) {
        if (block.timestamp >= rewardPeriodFinish) {
            return reward.div(rewardsDuration);
        } else {
            // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
            uint256 remaining = rewardPeriodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            return reward.add(leftover).div(rewardsDuration);
        }
    }

    function notifyRewardAmount(uint256 reward) external onlyParamSetter {
        uint _rewardRate = getRewardRateByReward(reward);
        _setRewardRate(_rewardRate);

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        uint balance = IERC20(rewardsToken).balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        emit RewardAdded(reward);
    }

    function takeFromTreasury(address token, uint256 amount) internal {
        if(treasury == address(0)) {
            return;
        }

        uint256 balance;
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
        if(amount > balance) {
            ITokenTreasury(treasury).claim(token, amount.sub(balance));
        }
    }

    function claimIncome(address to, uint256 amount) external payable {
        require(to != address(0), "to is the zero address");
        require(isStakingPool(msg.sender), "No permissions");
        
        takeFromTreasury(incomeToken, amount);
        if (incomeToken == address(0)) {
            safeTransferETH(to, amount);
        } else {
            IERC20(incomeToken).safeTransfer(to, amount);
        }

    }

    function claimReward(address to, uint256 amount) external {
        require(to != address(0), "to is the zero address");
        require(isStakingPool(msg.sender), "No permissions");
        
        takeFromTreasury(rewardsToken, amount);
        if (rewardsToken == address(0)) {
            safeTransferETH(to, amount);
        } else {
            IERC20(rewardsToken).safeTransfer(to, amount);
        }
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) external onlyOwner {
        if (_token == address(0)) {
            safeTransferETH(msg.sender, _amount);
        } else {
            IERC20(_token).safeTransfer(msg.sender, _amount);
        }
    }

    function depositeETH() external payable {
        emit DepositedETH(msg.sender, msg.value);
    }

    function safeTransferETH(address to, uint amount) internal {
        address(uint160(to)).transfer(amount);
    }
        
    function () external payable {
    }

    event IncomeRateChanged(uint256 oldValue, uint256 newValue);
    event RewardAdded(uint256 reward);
    event RewardRateChanged(uint256 oldValue, uint256 newValue);
    event DepositedETH(address indexed _user, uint256 _amount);
}