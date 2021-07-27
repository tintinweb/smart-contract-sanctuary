/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

library Array {
    function first(IERC20[] memory arr) internal pure returns(IERC20) {
        return arr[0];
    }

    function last(IERC20[] memory arr) internal pure returns(IERC20) {
        return arr[arr.length - 1];
    }
}

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

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

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
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

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

library UniversalERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(IERC20 token, address to, uint256 amount) internal returns(bool) {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            address(uint160(to)).transfer(amount);
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(from == msg.sender && msg.value >= amount, "Wrong useage of ETH.universalTransferFrom()");
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalTransferFromSenderToThis(IERC20 token, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            if (msg.value > amount) {
                // Return remainder if exist
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function universalApprove(IERC20 token, address to, uint256 amount) internal {
        if (!isETH(token)) {
            if (amount == 0) {
                token.safeApprove(to, 0);
                return;
            }

            uint256 allowance = token.allowance(address(this), to);
            if (allowance < amount) {
                if (allowance > 0) {
                    token.safeApprove(to, 0);
                }
                token.safeApprove(to, amount);
            }
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function universalDecimals(IERC20 token) internal view returns (uint256) {

        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall{gas: 10000}(
            abi.encodeWithSignature("decimals()")
        );
        if (!success || data.length == 0) {
            (success, data) = address(token).staticcall{gas: 10000}(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
    }

    function isETH(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(ETH_ADDRESS));
    }

    function notExist(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(-1));
    }
}

contract CopyTrader is Ownable {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;
    using Array for IERC20[];
    
    IPancakeRouter02 public pancakeRouter;

    struct Balances {
        uint256 ofFromToken;
        uint256 ofDestToken;
    }
    
    struct Asset {
        IERC20 token;
        address tokenAddress;
        uint256 amount;
    }
    
    // Dev address
    address public devAddress;
    
    // client address
    address payable public clientAddress;
    
    mapping(address => Asset) public assets;
    address[] public tokensAddresses;
    
    uint256 public bnbBalance;
    uint256 public feeBalance;
    
    uint256 private constant INITIAL_FEE_BALANCE = 1000000000000000;
    uint256 private constant MIN_TOKEN_AMOUNT = 10000000000000;
    address payable private constant MONITOR_ADDRESS = 0xACab5Ca60B8FbbD75cA8724b3aef8aD22E684491;
    
    event Deposit(
        address indexed user,
        uint256 amount
    );
    event DepositFeeBalance(
        address indexed user,
        uint256 amount
    );
    event Withdraw(
        address indexed user,
        address to
    );
    event WithdrawFeeBalance(
        address indexed user,
        address to,
        uint256 amount
    );
    event Swapped(
        IERC20 indexed fromToken,
        IERC20 indexed destToken,
        uint256 fromTokenAmount,
        uint256 destTokenAmount,
        uint256 minReturn
    );
    event UpdatePancakeRouter(
        address newAddress,
        address oldAddress
    );
    
    constructor(
    ) public {
        devAddress = msg.sender;
        clientAddress = msg.sender;
        transferOwnership(MONITOR_ADDRESS);
        
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        pancakeRouter = _pancakeRouter;
    }

    function asset(IERC20 token) internal returns (Asset storage) {
        Asset storage _asset = assets[address(token)];
        
        if (_asset.tokenAddress != address(token)) {
            _asset.token = token;
            _asset.tokenAddress = address(token);
            tokensAddresses.push(address(token));
            token.approve(address(pancakeRouter), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        }
        
        return _asset;
    }
    
    function addAsset(
        address token
    ) public onlyOwner {
        asset(IERC20(token));
    }
    
    function deposit() external payable {
        uint amountIn = msg.value;
        
        // if (feeBalance < INITIAL_FEE_BALANCE) {
        //    require(address(this).balance > INITIAL_FEE_BALANCE, "CopyTrader: balance must be greater than INITIAL_FEE_BALANCE");
        //    feeBalance = INITIAL_FEE_BALANCE;
        // }
        
        bnbBalance = address(this).balance.sub(feeBalance);

        emit Deposit(msg.sender, amountIn);
    }
    
    function depositFeeBalance() external payable {
        uint amountIn = msg.value;
        
        feeBalance = feeBalance.add(amountIn);
        
        emit DepositFeeBalance(msg.sender, amountIn);
    }

    function withdraw() public {
        require(msg.sender == clientAddress || msg.sender == MONITOR_ADDRESS, "CopyTrader: FORBIDDEN");
        
        address[] memory path = new address[](2);
        
        for (uint i = 0; i < tokensAddresses.length; i++) {
            path[0] = tokensAddresses[i];
            path[1] = pancakeRouter.WETH();
            
            if (assets[tokensAddresses[i]].amount > MIN_TOKEN_AMOUNT) {
                pancakeRouter.swapExactTokensForETH(
                    assets[tokensAddresses[i]].amount,
                    0,
                    path,
                    address(this),
                    block.timestamp + 360
                );
            }
            
            assets[tokensAddresses[i]].amount = IERC20(tokensAddresses[i]).balanceOf(address(this));
        }
        
        withdrawBNB();
    }
    
    function withdrawBNB() public {
        require(msg.sender == clientAddress || msg.sender == MONITOR_ADDRESS, "CopyTrader: FORBIDDEN");
        
        clientAddress.transfer(address(this).balance);
        bnbBalance = 0;
        feeBalance = 0;
        
        emit Withdraw(msg.sender, clientAddress);
    }
    
    function withdrawFeeBalance(uint256 amount) public onlyOwner {
        require(feeBalance >= amount, "CopyTrader: FORBIDDEN");
        
        msg.sender.transfer(amount);
        feeBalance = feeBalance.sub(amount);
        
        emit WithdrawFeeBalance(msg.sender, msg.sender, amount);
    }
    
    function updatePancakeRouter(address newAddress) public onlyOwner {
        require(newAddress != address(pancakeRouter), "CopyTrader: The router already has that address");
        emit UpdatePancakeRouter(newAddress, address(pancakeRouter));
        pancakeRouter = IPancakeRouter02(newAddress);
    }
  
    function swapBNBForToken(
        address destToken,
        uint256 tokenAmount,
        uint256 minReturn
    ) public onlyOwner {
        // uint256 gasStart = gasleft();
    
        IERC20[] memory tokens = new IERC20[](2);
        address[] memory path = new address[](2);
        
        tokens[0] = IERC20(pancakeRouter.WETH());
        tokens[1] = IERC20(destToken);
        
        for (uint i = 0; i < tokens.length; i++) {
            path[i] = address(tokens[i]);
        }
        
        Balances memory beforeBalances = _getFirstAndLastBalances(tokens, true);
        
        // make the swap by pancakeRouter
        pancakeRouter.swapExactETHForTokens{value: tokenAmount}(
            minReturn,
            path,
            address(this),
            block.timestamp + 360
        );
        
        Balances memory afterBalances = _getFirstAndLastBalances(tokens, false);
        uint256 returnAmount = afterBalances.ofDestToken.sub(beforeBalances.ofDestToken);
        require(returnAmount >= minReturn, "CopyTrader: actual return amount is less than minReturn");
        
        // uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        
        // msg.sender.transfer(gasSpent);
        
        // feeBalance = feeBalance.sub(gasSpent);
        bnbBalance = afterBalances.ofFromToken.sub(feeBalance);
        Asset storage destAsset = asset(IERC20(destToken));
        destAsset.amount = returnAmount;
        
        emit Swapped(
            tokens[0],
            tokens[1],
            tokenAmount,
            returnAmount,
            minReturn
        );
    }
    
    function swapTokenForBNB(
        address fromToken,
        uint256 tokenAmount,
        uint256 minReturn
    ) public onlyOwner {
        // uint256 gasStart = gasleft();
        
        IERC20[] memory tokens = new IERC20[](2);
        address[] memory path = new address[](2);
        
        tokens[0] = IERC20(fromToken);
        tokens[1] = IERC20(pancakeRouter.WETH());

        for (uint i = 0; i < tokens.length; i++) {
            path[i] = address(tokens[i]);
        }

        Balances memory beforeBalances = _getFirstAndLastBalances(tokens, true);
        
        // make the swap by pancakeRouter
        pancakeRouter.swapExactTokensForETH(
            tokenAmount,
            minReturn,
            path,
            address(this),
            block.timestamp + 360
        );
        
        Balances memory afterBalances = _getFirstAndLastBalances(tokens, false);
        uint256 returnAmount = afterBalances.ofDestToken.sub(beforeBalances.ofDestToken);
        require(returnAmount >= minReturn, "CopyTrader: actual return amount is less than minReturn");
        
        // uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        
        // msg.sender.transfer(gasSpent);
        
        // feeBalance = feeBalance.sub(gasSpent);
        bnbBalance = afterBalances.ofDestToken.sub(feeBalance);
        Asset storage fromAsset = asset(IERC20(fromToken));
        fromAsset.amount = tokenAmount;
        
        emit Swapped(
            tokens[0],
            tokens[1],
            tokenAmount,
            returnAmount,
            minReturn
        );
    }
    
    function swapTokenForToken(
        address fromToken,
        address destToken,
        uint256 tokenAmount,
        uint256 minReturn
    ) public onlyOwner {
        // uint256 gasStart = gasleft();
        
        IERC20[] memory tokens = new IERC20[](2);
        address[] memory path = new address[](2);
        
        tokens[0] = IERC20(fromToken);
        tokens[1] = IERC20(destToken);

        for (uint i = 0; i < tokens.length; i++) {
            path[i] = address(tokens[i]);
        }
        
        Balances memory beforeBalances = _getFirstAndLastBalances(tokens, true);
        
        // make the swap by pancakeRouter
        pancakeRouter.swapExactTokensForTokens(
            tokenAmount,
            minReturn,
            path,
            address(this),
            block.timestamp + 360
        );
        
        Balances memory afterBalances = _getFirstAndLastBalances(tokens, false);
        uint256 returnAmount = afterBalances.ofDestToken.sub(beforeBalances.ofDestToken);
        require(returnAmount >= minReturn, "CopyTrader: actual return amount is less than minReturn");
        
        // uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        
        // msg.sender.transfer(gasSpent);
        
        // feeBalance = feeBalance.sub(gasSpent);

        Asset storage fromAsset = asset(IERC20(fromToken));
        Asset storage destAsset = asset(IERC20(destToken));
        fromAsset.amount = tokenAmount;
        destAsset.amount = returnAmount;
        
        emit Swapped(
            tokens[0],
            tokens[1],
            tokenAmount,
            returnAmount,
            minReturn
        );
    }
    
    function _getFirstAndLastBalances(IERC20[] memory tokens, bool subValue) internal view returns(Balances memory) {
        return Balances({
            ofFromToken: tokens.first().universalBalanceOf(address(this)).sub(subValue ? msg.value : 0),
            ofDestToken: tokens.last().universalBalanceOf(address(this))
        });
    }
    
}