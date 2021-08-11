/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";

interface IERC20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(now > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract PrizePool is Ownable {
    /////////////////////////////////////////////////////////////////////////
    // State Variables
    /////////////////////////////////////////////////////////////////////////
    string private _id;
    string private _name;
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapRouter;
    address private _token_address;
    address private _router_address;
    IERC20 private token;

    address payable public winner;
    uint256 nonce;
    uint256 public ticketPrice;
    //all funds
    uint256 public pot;
    //0.3 ethers/bnb
    uint256 public winningsLimit;
    //25
    uint256 public rewardRate;
    //75
    uint256 liquidityPercentage;

    // uint public _token_addressAmount; // ERC20 tokens received or by swapped
    address payable[] public participants;
    
    uint private _count = 0;
    
    //array to to store strcuture : ParticipantTransaction
    ParticipantTransaction[] public participantTransactions;
    
    //structure for storing hisotry of participants
    struct ParticipantTransaction {
        address account; // sender
        uint256 nTickets; // number of tickets purchased `nTickets` argument in participate()
        uint256 value; // BNB value
    }
    

    /////////////////////////////////////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////////////////////////////////////
    event Participated(string poolId, address account, uint256 value);
    event PotIncreased(string poolId, uint256 pot);
    event Payout(address target, uint256 amount, uint256 noOfParticipants);
    event TicketPriceChanged(uint256 lastPrice);
    event ReceiveAbleTokenChanged(
        IERC20 receiveAbleToken,
        string name,
        string symbol,
        uint256 decimals
    );
    event WinningsLimitChanged(uint256);
    event LiquidityAmountEvent(uint256 liquidityAmountEvent);
    event Half(uint256 halfValue);
    event OtherHalf(uint256 otherHalf);
    event WinningReward(uint256 winningReward);
    event BalanceBeforeTransfer(uint256 balanceBeforeTransfer);
    event BalanceAfterTransfer(uint256 balanceAfterTransfer);
    event CurrentBalane(uint256 currentBalance);
    event PrizePoolEnded(
        string id,
        string name,
        address winner,
        address payable[] participants,
        address tokenAddress,
        uint256 pot,
        uint256 ticketPrice,
        uint256 winningsLimit,
        uint256 liquidityPercentage,
        uint256 rewardRate
    );

    /////////////////////////////////////////////////////////////////////////
    // Constructor
    /////////////////////////////////////////////////////////////////////////
    constructor(
        string memory id,
        string memory name,
        uint256 _ticketPrice,
        uint256 _winningsLimit,
        address token_address,
        address router_address
    ) public {
        _id = id;
        _name = name;
        _token_address = token_address;
        _router_address = router_address;
        uniswapRouter = IUniswapV2Router02(_router_address);
        token = IERC20(_token_address);
        liquidityPercentage = 75;
        rewardRate = 25;
        nonce = 0;
        ticketPrice = _ticketPrice;
        winningsLimit = _winningsLimit;
        winner = address(0);
    }

    function id() public view returns (string memory) {
        return _id;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function count() public view returns (uint) {
        return _count;
    }

    function tokenAddress() public view returns (address) {
        return _token_address;
    }

    function quoteTickets(uint256 nTickets) public view returns (uint256) {
        return ticketPrice * nTickets;
    }

    function prize() public view returns (uint256) {
        return (winningsLimit * rewardRate) / 100;
    }

    //to check balance of receiveAbleTokens
    function checkReceivedTokensBalance()
        public
        view
        onlyOwner
        returns (uint256 balance)
    {
        return token.balanceOf(address(this));
    }

    //transfer tokens to msg.sender
    function withdrawTokens() public onlyOwner {
        // require(pot == 0,"cannot withdraw tokens when prize pool is open");
        uint256 tokenAmount = token.balanceOf(address(this));
        address recepient = msg.sender;
        //transfer
        require(
            token.transfer(recepient, tokenAmount),
            "TransferToken: Fialed"
        );
    }

    //a function to set winningsLimit
    function changeWinningLimit(uint256 _winningsLimit)
        public
        onlyOwner
        returns (uint256)
    {
        winningsLimit = _winningsLimit;
        winner = address(0);

        emit WinningsLimitChanged(winningsLimit);
        return winningsLimit;
    }

    //Fuction to change ticketPrice
    function changeTicketPrice(uint256 _ticketPrice) public onlyOwner {
        ticketPrice = _ticketPrice;
        emit TicketPriceChanged(ticketPrice);
    }

    //get totalBalance of contract in BNB
    function totalBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    //function to withdrawFunds from contract
    function withdrawFunds() external onlyOwner() {
        // require(pot==0,"cannot withdraw funds when prize pool is open");
        address myAddress = address(this);
        uint256 etherBalance = myAddress.balance;
        //msg.sender.transfer(this.totalBalance());
        msg.sender.transfer(etherBalance);
    }

    //Participate in prize pool by giving desired amount(msg.value)
    function participate() public payable {
        uint256 nTickets = msg.value / ticketPrice;

        require(nTickets >= 1, "please set correct amount");

        if (pot < winningsLimit || pot == winningsLimit) {
            pot += msg.value;

            for (uint256 i = 0; i < nTickets; i++) {
                participants.push(msg.sender);
                emit Participated(_id, msg.sender, msg.value);
            }
        }
       
        
        emit PotIncreased(_id, pot);
        // pushing participant data to array
        participantTransactions.push(ParticipantTransaction(msg.sender,nTickets,msg.value));
        
        if (pot > winningsLimit || pot == winningsLimit) {
            EndPrizePool();
        }
    }
    

    //https://stackoverflow.com/questions/48282754/what-is-the-best-approach-in-solidity-for-pagination-straightforward-and-based
    function getPaginatedParticipantTransactions(uint _resultsPerPage, uint _page) external view returns (ParticipantTransaction[] memory) {
        
    ParticipantTransaction[] memory result = new ParticipantTransaction[](_resultsPerPage);
  
    for(uint i = _resultsPerPage * _page - _resultsPerPage; i < _resultsPerPage * _page; i++ ){
      result[i] = participantTransactions[i];
    } 
    return result;
}
    
    //this function will reward 25% to winner and 75/2 to liquidity pool in dex
    function EndPrizePool() internal {
        emit CurrentBalane(address(this).balance);
        //total payments in pot
        uint256 totalPayout = pot;
        pot = 0;

        uint256 winningReward;
        //According to the total amount of Ethereum in the current session, determine the bonus that the winner can receive.
        winningReward = (totalPayout * rewardRate) / 100;
        emit WinningReward(winningReward);

        //Take 75% for the Liquidity Pool (rounded down by int-division)
        //winningReward = address(this).balance*rewardRate/100;
        uint256 liquidityAmount = (totalPayout * liquidityPercentage) / 100;

        emit LiquidityAmountEvent(liquidityAmount);

        winner = pickWinner();
        emit BalanceBeforeTransfer(msg.sender.balance);
        winner.transfer(winningReward);
        emit BalanceAfterTransfer(msg.sender.balance);
        // split the contract balance into halves
        uint256 half = liquidityAmount.div(2);
        emit Half(half);

        uint256 otherHalf = liquidityAmount.sub(half);
        emit OtherHalf(otherHalf);

        //swap ETH for tokens
        require(convertEthToTokens(half) == true, "convertEthToDai: Failed");

        uint256 tokenAmount = token.balanceOf(address(this));
        //using remaining half to add liqdity
        addLiquidityEthereum(tokenAmount, address(this).balance);

        emit Payout(winner, pot, participants.length);

        _count += 1;

        emit PrizePoolEnded(
            _id,
            _name,
            winner,
            participants,
            _token_address,
            pot,
            ticketPrice,
            winningsLimit,
            liquidityPercentage,
            rewardRate
        );

        winner = address(0);
        delete participants;
    }

    //internal function for picking winner
    function pickWinner() internal returns (address payable) {
        return participants[random()];
    }

    //generate randomnumber inbetween user's array
    function random() internal returns (uint256 randomnumber) {
        randomnumber =
            uint256(keccak256(abi.encodePacked(block.timestamp, nonce))) %
            participants.length;

        nonce++;
    }

    // function for converting ETH amount to Tokens
    function convertEthToTokens(uint256 ethAmount) internal returns (bool) {
        uint256 deadline = block.timestamp; // using 'now' for convenience, for mainnet pass deadline from frontend!
        uniswapRouter.swapExactETHForTokens{value: ethAmount}(
            0,
            getPathForETHtoDAI(),
            address(this),
            deadline
        );
        // refund leftover ETH to user
        (bool success, ) = address(this).call{value: address(this).balance}("");
        require(success, "refund failed");

        return true;
    }

    // swap tokens with eth
    function convertTokensToEth(uint256 ethAmount) external payable onlyOwner {
        //approving tokens to uniswapRouter
        require(
            token.approve(
                address(uniswapRouter),
                token.balanceOf(address(this))
            ),
            "approve failed"
        );
        uint256 deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
        uniswapRouter.swapExactTokensForETH(
            ethAmount,
            ethAmount,
            getPathForDAItoETH(),
            address(this),
            deadline
        );

        // refund leftover ETH to user
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "refund failed");
    }

    //to get getEstimated ETH value for DAI
    function getEstimatedETHforDAI(uint256 daiAmount)
        private
        view
        returns (uint256[] memory)
    {
        return uniswapRouter.getAmountsIn(daiAmount, getPathForETHtoDAI());
    }

    //path for Eth to Dai from uniswap
    function getPathForETHtoDAI() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = _token_address;

        return path;
    }

    //path for Dai to Eth
    function getPathForDAItoETH() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _token_address;
        path[1] = uniswapRouter.WETH();

        return path;
    }

    function addLiquidityEthereum(uint256 tokenAmount, uint256 ethAmount)
        internal
        returns (bool)
    {
        //approving tokens to uniswapRouter
        IERC20(token).approve(_router_address, tokenAmount);
        require(
            token.allowance(address(this), _router_address) != 0,
            "zero allowance, pleae approve DAI first to be used by this contract"
        );

        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(token),
            tokenAmount, //tkn amount
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
        // refund leftover ETH to user
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "refund failed");
    }

    // important to receive ETH
    receive() external payable {}
}