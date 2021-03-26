pragma solidity 0.5.16;


contract Storage {

    address public governance;
    address public controller;

    constructor() public {
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(isGovernance(msg.sender), "S0");
        _;
    }

    function setGovernance(address _governance) public onlyGovernance {
        require(_governance != address(0), "S1");
        governance = _governance;
    }

    function setController(address _controller) public onlyGovernance {
        require(_controller != address(0), "S2");
        controller = _controller;
    }

    function isGovernance(address account) public view returns (bool) {
        return account == governance;
    }

    function isController(address account) public view returns (bool) {
        return account == controller;
    }
}

pragma solidity 0.5.16;

import "./library/SafeMath.sol";
import "./library/Address.sol";
import "./library/SafeERC20.sol";

import "./interface/IStrategy.sol";
import "./interface/IBridgeStrategy.sol";
import "./interface/IERC20.sol";

import "./Storage.sol";

contract StrategyUtil {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    string public name = "Strategy main";
    address public vault;
    address public storages;
    address public underlying;
    uint256 public numerator = 5;
    uint256 public denominator = 100;

    struct strategyData {
        address bridgeStrategy;
        uint256 weight;
    }

    address[] public  strategiesArray;
    mapping(address => strategyData) public strategiesMapping;


    constructor(address _storage, address _vault, address _underlying) public {
        vault = _vault;
        storages = _storage;
        underlying = _underlying;
    }

    modifier onlyGovernance(){
        require(msg.sender == Storage(storages).governance(), "SM0");
        _;
    }
    modifier restricted(){
        require(msg.sender == Storage(storages).controller() || msg.sender == Storage(storages).governance()
            || msg.sender == vault, "SM1");
        _;
    }

    function changeVault(address _vault) public restricted{
        vault = _vault;
    }

    function getStrategy() external view returns(address[] memory){
        return strategiesArray;
    }

    function checkExistStrategy(address _strategy) public view returns (bool isExits){
        isExits = false;
        for (uint256 i = 0; i < strategiesArray.length; i++) {
            if (strategiesArray[i] == _strategy) {
                isExits = true;
                break;
            }
        }
    }

    function addStrategy(address[] calldata _strategies, address[] calldata _bridgeStrategies, uint256[] calldata _weights) external restricted {
        for (uint256 i = 0; i < _strategies.length; i++) {
            require(checkExistStrategy(_strategies[i]) == false, "SM2");
            require(IBridgeStrategy(_bridgeStrategies[i]).vault(_strategies[i]) == address(this), "SM3");
            require(IBridgeStrategy(_bridgeStrategies[i]).underlying(_strategies[i]) == underlying, "SM4");
            require(_strategies[i] != address(0), "SM5");
            strategiesArray.push(_strategies[i]);
            strategiesMapping[_strategies[i]] = strategyData(_bridgeStrategies[i], _weights[i]);
        }
    }

    function setWeight(address[] calldata _strategy, uint256[] calldata _weight) external restricted {
        for (uint256 i = 0; i < _strategy.length; i++) {
            require(checkExistStrategy(_strategy[i]) == true, "SM6");
            strategiesMapping[_strategy[i]].weight = _weight[i];
        }
    }

    function setBridgeStrategy(address[] calldata _strategy, address[]  calldata _bridgeStrategies) external restricted {
        for (uint256 i = 0; i < _strategy.length; i++) {
            require(checkExistStrategy(_strategy[i]) == true, "SM7");
            strategiesMapping[_strategy[i]].bridgeStrategy = _bridgeStrategies[i];
        }
    }

    function removeStrategy(address _strategy) public restricted {
        uint8 flag = 0;
        uint256 _index = 0;
        for (uint256 i = 0; i < strategiesArray.length; i++) {
            if (strategiesArray[i] == _strategy) {
                flag = 1;
                _index = i;
                break;
            }
        }
        require(flag == 1, "SM8");
        delegateCallStrategy(
            strategiesMapping[_strategy].bridgeStrategy,
            abi.encodeWithSelector(
                IBridgeStrategy(strategiesMapping[_strategy].bridgeStrategy).withdrawAllToVault.selector,
                _strategy
            )
        );
        uint256 balance = IERC20(underlying).balanceOf(address(this));
        if (balance >= 10 ** 6) {
            IERC20(underlying).safeTransfer(vault, balance);
        }
        for (uint256 i = _index; i < strategiesArray.length - 1; i++) {
            strategiesArray[i] = strategiesArray[i + 1];
        }
        delete strategiesArray[strategiesArray.length - 1];
        strategiesArray.length --;
        delete strategiesMapping[_strategy];
    }

    function setFractionToSame(uint256 _numerator, uint256 _denominator) public restricted {
        require(_denominator != 0, "SM9");
        require(_denominator >= _numerator, "SM10");
        numerator = _numerator;
        denominator = _denominator;
    }

    function delegateCallStrategy(address bridgeStrategy, bytes memory data) internal {
        (bool status,) = bridgeStrategy.delegatecall(data);
        require(status, "SM11");
    }

    function _withdrawToVault(address _strategy, uint256 _amount) internal {
        delegateCallStrategy(
            strategiesMapping[_strategy].bridgeStrategy,
            abi.encodeWithSelector(
                IBridgeStrategy(strategiesMapping[_strategy].bridgeStrategy).withdrawToVault.selector,
                _strategy,
                _amount
            )
        );
    }

    function _doHardWork(address _strategy) internal {
        delegateCallStrategy(
            strategiesMapping[_strategy].bridgeStrategy,
            abi.encodeWithSelector(
                IBridgeStrategy(strategiesMapping[_strategy].bridgeStrategy).doHardWork.selector,
                _strategy
            )
        );
    }

    function _withdrawAllToVault(address _strategy) internal {
        delegateCallStrategy(
            strategiesMapping[_strategy].bridgeStrategy,
            abi.encodeWithSelector(
                IBridgeStrategy(strategiesMapping[_strategy].bridgeStrategy).withdrawAllToVault.selector,
                _strategy
            )
        );
    }

    function _investedUnderlyingBalance(address _strategy) public view returns (uint256 amount) {
        amount = IBridgeStrategy(strategiesMapping[_strategy].bridgeStrategy).investedUnderlyingBalance(_strategy);
    }

    function calculateWithdrawInStrategy(uint256 amount) public view returns (address[] memory, uint256[] memory){
        address[] memory _strategyAddress = new  address[](strategiesArray.length);
        uint256[] memory _amounts = new  uint256[](strategiesArray.length);
        for (uint256 i = 0; i < strategiesArray.length; i++) {
            uint256 amountInStrategy = _investedUnderlyingBalance(strategiesArray[i]);
            _strategyAddress[i] = strategiesArray[i];
            if (amount < amountInStrategy) {
                _amounts[i] = amount;
                break;
            } else {
                _amounts[i] = amountInStrategy;
                amount = amount.sub(amountInStrategy);
            }
        }
        return (_strategyAddress, _amounts);
    }

}

contract StrategyMain is IStrategy, StrategyUtil {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    constructor(address _storage, address _vault, address _underlying)
    public StrategyUtil(_storage, _vault, _underlying){
    }
    event DoHardWork(address strategy, uint256 amount, uint256 amountInStrategy);
    event Withdraw(address strategy, uint256 amount, uint256 amountInStrategy);

    function doHardWork() public restricted {
        uint256 total = 0;
        for (uint i = 0; i < strategiesArray.length; i++) {
            total += strategiesMapping[strategiesArray[i]].weight;
        }
        require(total != 0, "SM12");
        uint256 totalInvestedBalance = investedUnderlyingBalance();

        for (uint i = 0; i < strategiesArray.length; i++) {
            uint256 amount = totalInvestedBalance.mul(strategiesMapping[strategiesArray[i]].weight).div(total);
            uint investedInStrategy = _investedUnderlyingBalance(strategiesArray[i]);
            if (investedInStrategy > amount && investedInStrategy.sub(amount) > investedInStrategy.mul(numerator).div(denominator)) {
                _withdrawToVault(strategiesArray[i], investedInStrategy.sub(amount));
                emit Withdraw(strategiesArray[i], investedInStrategy.sub(amount), _investedUnderlyingBalance(strategiesArray[i]));
            }
        }

        uint256 balance;
        for (uint i = 0; i < strategiesArray.length; i++) {
            uint256 amount = totalInvestedBalance.mul(strategiesMapping[strategiesArray[i]].weight).div(total);
            uint investedInStrategy = _investedUnderlyingBalance(strategiesArray[i]);
            balance = IERC20(underlying).balanceOf(address(this));
            if (investedInStrategy < amount && amount.sub(investedInStrategy) > amount.mul(numerator).div(denominator) &&
                balance > amount.mul(numerator).div(denominator)) {
                if (balance > amount.sub(investedInStrategy)) {
                    balance = amount.sub(investedInStrategy);
                }
                IERC20(underlying).safeTransfer(strategiesArray[i], balance);
                _doHardWork(strategiesArray[i]);
                emit DoHardWork(strategiesArray[i], balance, _investedUnderlyingBalance(strategiesArray[i]));
            }
        }
        balance = IERC20(underlying).balanceOf(address(this));
        if (balance >= 10 ** 6) {
            IERC20(underlying).safeTransfer(vault, balance);
        }
    }


    function withdrawStrategy(uint256 _amount) external restricted {
        uint256 total = 0;
        for (uint i = 0; i < strategiesArray.length; i++) {
            total += strategiesMapping[strategiesArray[i]].weight;
        }
        require(total != 0, "SM13");
        for (uint i = 0; i < strategiesArray.length; i++) {
            uint256 amount = _amount.mul(strategiesMapping[strategiesArray[i]].weight).div(total);
            if (amount > _investedUnderlyingBalance(strategiesArray[i])) {
                amount = _investedUnderlyingBalance(strategiesArray[i]);
            }
            _withdrawToVault(strategiesArray[i], amount);
        }
        uint256 balance = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(vault, balance);
    }

    function withdrawAllToVault() public restricted {
        for (uint i = 0; i < strategiesArray.length; i++) {
            _withdrawAllToVault(strategiesArray[i]);
        }
        IERC20(underlying).safeTransfer(vault, IERC20(underlying).balanceOf(address(this)));
    }

    function withdrawToVault(uint256 _amount) public restricted {
        if (IERC20(underlying).balanceOf(address(this)) >= _amount) {
            IERC20(underlying).safeTransfer(vault, _amount);
        } else {
            (address[] memory _strategyAddress, uint256[] memory _amounts) = calculateWithdrawInStrategy(_amount.sub(IERC20(underlying).balanceOf(address(this))));
            for (uint i = 0; i < _strategyAddress.length; i++) {
                if (_amounts[i] > 0) {
                    _withdrawToVault(_strategyAddress[i], _amounts[i]);
                }
            }
            uint256 balance = IERC20(underlying).balanceOf(address(this));
            IERC20(underlying).safeTransfer(vault, balance);
        }
    }

    function investedUnderlyingBalance() view public returns (uint256 total) {
        total = 0;
        for (uint256 i = 0; i < strategiesArray.length; i++) {
            total = total.add(_investedUnderlyingBalance(strategiesArray[i]));
        }
        total = total.add(IERC20(underlying).balanceOf(address(this)));
    }


    function depositArbCheck() external view returns (bool){
        return true;
    }

    function transferOnlyGovernance(address _token, uint256 amount, address _to) onlyGovernance public {
        IERC20(_token).safeTransfer(_to, amount);
    }}

pragma solidity 0.5.16;

interface IBridgeStrategy {

    function underlying(address strategy) external view returns (address);

    function vault(address strategy) external view returns (address);

    function withdrawAllToVault(address strategy) external;

    function withdrawToVault(address strategy, uint256 amount) external;

    function investedUnderlyingBalance(address strategy) external view returns (uint256); // itsNotMuch()

    function doHardWork(address strategy) external;

    function depositArbCheck(address strategy) external view returns (bool);

}

pragma solidity 0.5.16;
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

pragma solidity 0.5.16;

interface IStrategy {

    function underlying() external view returns (address);

    function vault() external view returns (address);

    function withdrawAllToVault() external;

    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    function doHardWork() external;

    function depositArbCheck() external view returns (bool);
}

pragma solidity 0.5.16;


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
        assembly {codehash := extcodehash(account)}
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
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity 0.5.16;

import "../interface/IERC20.sol";
import "./Address.sol";
import "./SafeMath.sol";
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

        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.5.16;
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
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