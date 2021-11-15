// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
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

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

// File: contracts/common/utils/ExternalCaller.sol



pragma solidity ^0.5.0;

contract ExternalCaller {
    function externalTransfer(address _to, uint256 _value) internal {
        require(address(this).balance >= _value, "ExternalCaller: insufficient ether balance");
        externalCall(_to, _value, "");
    }

    function externalCall(address _to, uint256 _value, bytes memory _data) internal {
        (bool success, bytes memory returndata) = _to.call.value(_value)(_data);
        require(success, string(returndata));
    }
}

// File: contracts/common/utils/BalanceCarrier.sol



pragma solidity ^0.5.0;



contract BalanceCarrier is ExternalCaller {
    address private _ethTokenAddress;

    constructor (address ethTokenAddress) internal {
        _ethTokenAddress = ethTokenAddress;
    }

    function transfer(address tokenAddress, address to, uint256 amount) internal returns (bool) {
        if (tokenAddress == _ethTokenAddress) {
            externalTransfer(to, amount);
            return true;
        } else {
            return IERC20(tokenAddress).transfer(to, amount);
        }
    }

    function balanceOf(address tokenAddress) internal view returns (uint256) {
        if (tokenAddress == _ethTokenAddress) {
            return address(this).balance;
        } else {
            return IERC20(tokenAddress).balanceOf(address(this));
        }
    }
}

// File: contracts/liquidity/ILiquidityProxy.sol



pragma solidity ^0.5.0;

contract ILiquidityProxy {
    function getTotalReserve(address tokenAddress) external view returns (uint256);

    function getRepaymentAddress(address tokenAddress) external view returns (address);

    function getRepaymentAmount(address tokenAddress, uint256 tokenAmount) view external returns (uint256);

    function borrow(address tokenAddress, uint256 tokenAmount) external;
}

// File: contracts/common/invoke/IInvokable.sol



pragma solidity ^0.5.0;

contract IInvokable {
    function execute(bytes calldata data) external payable;
}

// File: contracts/common/invoke/IInvocationHook.sol



pragma solidity ^0.5.0;

contract IInvocationHook {
    function currentSender() external view returns (address);

    function currentTokenAddress() external view returns (address);

    function currentTokenAmount() external view returns (uint256);

    function currentRepaymentAmount() external view returns (uint256);
}

// File: contracts/common/invoke/IInvoker.sol



pragma solidity ^0.5.0;


contract IInvoker is IInvocationHook {
    function invoke(address invokeTo, bytes calldata invokeData, address tokenAddress, uint256 tokenAmount)
    external
    payable;

    function invokeCallback() external;

    function poolReward() external view returns (uint256);

    function poolRewardAddress(address tokenAddress) external view returns (address);

    function platformReward() external view returns (uint256);

    function platformVaultAddress() external view returns (address);

    function isTokenAddressRegistered(address tokenAddress) public view returns (bool);

    function totalLiquidity(address tokenAddress) external view returns (uint256);
}

// File: contracts/Invoker.sol



pragma solidity ^0.5.0;


contract Invoker is IInvoker, Ownable, BalanceCarrier {
    using SafeMath for uint256;

    event Invocation(address invokeTo, uint256 invokeValue, bytes32 invokeDataHash, uint256 underlyingAmount);
    event Reward(uint256 poolReward, uint256 platformReward, address tokenAddress);

    mapping(address => address[]) internal _liquidityProxies;
    uint256 internal _poolRewardBips;
    mapping(address => address) _poolRewardAddresses;
    uint256 internal _platformRewardBips;
    address internal _platformVaultAddress;

    bool internal _scheduled;
    uint256 internal _schedulePriorTokenAmount;
    address internal _scheduleInvokeSender;
    address internal _scheduleInvokeTo;
    uint256 internal _scheduleInvokeValue;
    bytes internal _scheduleInvokeData;
    uint256 internal _scheduleIndex;
    address internal _scheduleTokenAddress;
    uint256 internal _scheduleTokenAmount;
    uint256[] internal _scheduleTokenAmounts;
    uint256 internal _scheduleRepayAmount;
    uint256[] internal _scheduleRepayAmounts;
    uint256 internal _schedulePoolReward;
    uint256 internal _schedulePlatformReward;

    constructor () public BalanceCarrier(address(1)) { }

    function invoke(address invokeTo, bytes calldata invokeData, address tokenAddress, uint256 tokenAmount)
    external
    payable
    onlyFresh
    {
        require(isTokenAddressRegistered(tokenAddress), "Invoker: no liquidity for token");
        require(invokeTo != address(this), "Invoker: cannot invoke this contract");

        scheduleExecution(msg.sender, invokeTo, msg.value, invokeData, tokenAddress, tokenAmount);

        invokeNext();

        disburseReward();

        cleanSchedule();
    }

    function invokeNext() internal {
        ILiquidityProxy proxy = ILiquidityProxy(liquidityProxy(_scheduleIndex));
        proxy.borrow(_scheduleTokenAddress, _scheduleTokenAmounts[_scheduleIndex]);
    }

    function invokeCallback() external onlyScheduled {
        _scheduleIndex++;
        if (_scheduleIndex == _scheduleTokenAmounts.length) {
            invokeFinal();
        } else {
            invokeNext();
        }
    }

    function invokeFinal() internal {
        uint256 expectedPriorTokenAmount = _schedulePriorTokenAmount.add(_scheduleTokenAmount);
        uint256 currentTokenAmount = balanceOf(_scheduleTokenAddress).sub(payableReserveAdjustment());
        require(currentTokenAmount == expectedPriorTokenAmount, "Invoker: incorrect liquidity amount sourced");
        require(transfer(_scheduleTokenAddress, _scheduleInvokeTo, _scheduleTokenAmount), "Invoker: transfer failed");

        IInvokable(_scheduleInvokeTo).execute.value(_scheduleInvokeValue)(_scheduleInvokeData);
        emit Invocation(_scheduleInvokeTo, _scheduleInvokeValue, keccak256(_scheduleInvokeData), _scheduleTokenAmount);

        uint256 expectedResultingTokenAmount = _schedulePriorTokenAmount.add(_scheduleRepayAmount);
        require(balanceOf(_scheduleTokenAddress) == expectedResultingTokenAmount, "Invoker: incorrect repayment amount");

        for (uint256 i = 0; i < _scheduleRepayAmounts.length; i++) {
            address repaymentAddress = ILiquidityProxy(liquidityProxy(i)).getRepaymentAddress(_scheduleTokenAddress);
            require(transfer(_scheduleTokenAddress, repaymentAddress, _scheduleRepayAmounts[i]),  "Invoker: pool repayment transfer failed");
        }
    }

    function disburseReward() internal {
        uint256 modifiedPoolReward = _poolRewardAddresses[_scheduleTokenAddress] == address(0) ? 0 : _schedulePoolReward;
        if (modifiedPoolReward > 0) {
            require(transfer(_scheduleTokenAddress, _poolRewardAddresses[_scheduleTokenAddress], modifiedPoolReward),  "Invoker: pool reward transfer failed");
        }
        if (_schedulePlatformReward > 0) {
            require(transfer(_scheduleTokenAddress, _platformVaultAddress, _schedulePlatformReward),  "Invoker: platform reward transfer failed");
        }
        emit Reward(modifiedPoolReward, _schedulePlatformReward, _scheduleTokenAddress);
    }

    /*
     * EXECUTION SCHEDULING
     */

    function scheduleExecution(
        address invokeSender,
        address invokeTo,
        uint256 invokeValue,
        bytes memory invokeData,
        address tokenAddress,
        uint256 tokenAmount
    ) internal {
        _scheduleInvokeSender = invokeSender;
        _scheduleInvokeTo = invokeTo;
        _scheduleInvokeValue = invokeValue;
        _scheduleInvokeData = invokeData;
        _scheduleTokenAddress = tokenAddress;
        _scheduleTokenAmount = tokenAmount;
        _schedulePriorTokenAmount = balanceOf(tokenAddress).sub(payableReserveAdjustment());

        uint256 tokenAmountLeft = tokenAmount;
        for (uint256 i = 0; i < liquidityProxiesForToken(); i++) {
            ILiquidityProxy proxy = ILiquidityProxy(liquidityProxy(i));
            uint totalReserve = proxy.getTotalReserve(tokenAddress);
            if (totalReserve == 0) {
                continue;
            }
            if (tokenAmountLeft <= totalReserve) {
                uint256 proxyRepayAmount = proxy.getRepaymentAmount(tokenAddress, tokenAmountLeft);
                _scheduleTokenAmounts.push(tokenAmountLeft);
                _scheduleRepayAmounts.push(proxyRepayAmount);
                _scheduleRepayAmount = _scheduleRepayAmount.add(proxyRepayAmount);
                tokenAmountLeft = 0;
                break;
            } else {
                uint256 proxyRepayAmount = proxy.getRepaymentAmount(tokenAddress, totalReserve);
                _scheduleTokenAmounts.push(totalReserve);
                _scheduleRepayAmounts.push(proxyRepayAmount);
                _scheduleRepayAmount = _scheduleRepayAmount.add(proxyRepayAmount);
                tokenAmountLeft = tokenAmountLeft.sub(totalReserve);
            }
        }
        require(tokenAmountLeft == 0, "Invoker: not enough liquidity");

        _schedulePoolReward = calculatePoolReward(_scheduleTokenAmount);
        _schedulePlatformReward = calculatePlatformReward(_scheduleTokenAmount);
        _scheduleRepayAmount = _scheduleRepayAmount.add(_schedulePoolReward).add(_schedulePlatformReward);

        _scheduled = true;
    }

    function cleanSchedule() internal {
        _scheduled = false;
        _schedulePriorTokenAmount = 0;
        _scheduleInvokeSender = address(0);
        _scheduleInvokeTo = address(0);
        _scheduleInvokeValue = 0;
        delete _scheduleInvokeData;
        _scheduleIndex = 0;
        _scheduleTokenAddress = address(0);
        _scheduleTokenAmount = 0;
        delete _scheduleTokenAmounts;
        _scheduleRepayAmount = 0;
        delete _scheduleRepayAmounts;
        _schedulePoolReward = 0;
        _schedulePlatformReward = 0;
    }

    /*
     * INVOKABLE HELPERS
     */

    function currentSender() external view returns (address) {
        return _scheduleInvokeSender;
    }

    function currentTokenAddress() external view returns (address) {
        return _scheduleTokenAddress;
    }

    function currentTokenAmount() external view returns (uint256) {
        return _scheduleTokenAmount;
    }

    function currentRepaymentAmount() external view returns (uint256) {
        return _scheduleRepayAmount;
    }

    function estimateRepaymentAmount(address tokenAddress, uint256 tokenAmount) external view returns (uint256) {
        require(isTokenAddressRegistered(tokenAddress), "Invoker: no liquidity for token");

        uint256 repaymentAmount = 0;
        uint256 tokenAmountLeft = tokenAmount;

        for (uint256 i = 0; i < _liquidityProxies[tokenAddress].length; i++) {
            ILiquidityProxy proxy = ILiquidityProxy(_liquidityProxies[tokenAddress][i]);
            uint totalReserve = proxy.getTotalReserve(tokenAddress);
            if (tokenAmountLeft <= totalReserve) {
                uint256 proxyRepayAmount = proxy.getRepaymentAmount(tokenAddress, tokenAmountLeft);
                repaymentAmount = repaymentAmount.add(proxyRepayAmount);
                tokenAmountLeft = 0;
                break;
            } else {
                uint256 proxyRepayAmount = proxy.getRepaymentAmount(tokenAddress, totalReserve);
                repaymentAmount = repaymentAmount.add(proxyRepayAmount);
                tokenAmountLeft = tokenAmountLeft.sub(totalReserve);
            }
        }
        require(tokenAmountLeft == 0, "Invoker: not enough liquidity");

        return repaymentAmount
        .add(calculatePoolReward(tokenAmount))
        .add(calculatePlatformReward(tokenAmount));
    }

    /*
     * REWARDS
     */

    function calculatePoolReward(uint256 tokenAmount) internal view returns (uint256) {
        return tokenAmount.mul(_poolRewardBips).div(10000);
    }

    function calculatePlatformReward(uint256 tokenAmount) internal view returns (uint256) {
        return tokenAmount.mul(_platformRewardBips).div(10000);
    }

    function poolReward() external view returns (uint256) {
        return _poolRewardBips;
    }

    function poolRewardAddress(address tokenAddress) external view returns (address) {
        return _poolRewardAddresses[tokenAddress];
    }

    function platformReward() external view returns (uint256) {
        return _platformRewardBips;
    }

    function platformVaultAddress() external view returns (address) {
        return _platformVaultAddress;
    }

    function setPoolReward(uint256 poolRewardBips) external onlyFresh onlyOwner {
        _poolRewardBips = poolRewardBips;
    }

    function setPoolRewardAddress(address tokenAddress, address poolRewardAddress) external onlyFresh onlyOwner {
        _poolRewardAddresses[tokenAddress] = poolRewardAddress;
    }

    function setPlatformReward(uint256 platformRewardBips) external onlyFresh onlyOwner {
        _platformRewardBips = platformRewardBips;
    }

    function setPlatformVaultAddress(address platformVaultAddress) external onlyFresh onlyOwner {
        _platformVaultAddress = platformVaultAddress;
    }

    /*
     * ASSET HELPERS
     */

    function payableReserveAdjustment() internal returns (uint256) {
        return _scheduleTokenAddress == address(1) ? _scheduleInvokeValue : 0;
    }

    /*
     * LIQUIDITY PROXIES
     */

    function setLiquidityProxies(address tokenAddress, address[] calldata liquidityProxies) external onlyFresh onlyOwner {
        _liquidityProxies[tokenAddress] = liquidityProxies;
    }

    function liquidityProxies(address tokenAddress) external view returns (address[] memory) {
        return _liquidityProxies[tokenAddress];
    }

    function isTokenAddressRegistered(address tokenAddress) public view returns (bool) {
        return _liquidityProxies[tokenAddress].length > 0;
    }

    function liquidityProxy(uint256 index) internal view returns (address) {
        return _liquidityProxies[_scheduleTokenAddress][index];
    }

    function liquidityProxiesForToken() internal view returns (uint256) {
        return _liquidityProxies[_scheduleTokenAddress].length;
    }

    function totalLiquidity(address tokenAddress) external view returns (uint256) {
        if (isTokenAddressRegistered(tokenAddress)) {
            uint256 total = 0;
            for (uint256 i = 0; i < _liquidityProxies[tokenAddress].length; i++) {
                ILiquidityProxy proxy = ILiquidityProxy(_liquidityProxies[tokenAddress][i]);
                total = total.add(proxy.getTotalReserve(tokenAddress));
            }
            return total;
        }
        return 0;
    }

    /* This contract should never have a token balance at rest. If so it is in error,
       allow tokens to be moved to vault */
    function removeStuckTokens(address tokenAddress, address to, uint256 amount)
    external
    onlyFresh
    onlyOwner
    returns (bool)
    {
        return transfer(tokenAddress, _platformVaultAddress, amount);
    }

    /*
     * MODIFIERS
     */

    modifier onlyFresh() {
        require(!_scheduled, "Invoker: not fresh environment");
        _;
    }

    modifier onlyScheduled() {
        require(_scheduled, "Invoker: not scheduled");
        _;
    }

    function () external payable { }
}

