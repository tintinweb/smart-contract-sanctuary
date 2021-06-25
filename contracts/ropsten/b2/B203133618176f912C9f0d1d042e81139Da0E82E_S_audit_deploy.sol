/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: MIT (@JVP, @jasper#2866, @j00324)

/* SOHO Token contract
* Reflective token with 4 types of fees:
* 1) Charity fee
* 2) Auto liquidity adding + BNB claims
* 3) Charity fee
* 4) Burn fee
*
* Fees can be changed by the owner, BUT: total combined fees can never be higher than 15%!
* Fees are taken on each transfer, unless excempt from fees.
*
* Anti whale features:
* 1) Limitation on token amount to transfer (except buying)
* 2) Limitation on token amount to transfer based on total supply (except buying)
* 3) Limitation on token amount to transfer based on wallet balance (except buying)
* 4) Limitation on token transfers based on time delay between transfers (except buying)
* These limitations can be changed by the owner
* However, limitations on the limitations are hard-coded!* 
*
* Solved issue in Ownable contract which allowed the owner to re-claim ownership after a certain sequence of lock/unlocks
* Solved issue where token balances may drop after being excluded from RFI rewards
* Solved issue where address in a combination of 'excluded from's cannot receive any tokens
* Solved issue in transfer events
* ...
*
* https://www.sohotoken.com/
*/

pragma solidity >=0.6.8;

interface IBEP20 {

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
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
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an BNB balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
        require(_owner == _msgSender(), "Ownable: caller is not the token owner");
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
        _previousOwner = address(0);
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakePair {
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

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
}

// File: contracts/protocols/bep/Utils.sol

pragma solidity >=0.6.8;


library Utils {
    using SafeMath for uint256;

    function calculateBNBReward(
        uint256 currentBalance,
        uint256 currentBNBPool,
        uint256 totalSupply
    ) public pure returns (uint256) {
        // calculate reward to send       
        // now calculate reward
        uint256 reward = currentBNBPool.mul(currentBalance).div(totalSupply);

        return reward;
    }

    function calculateTopUpClaim(
        uint256 currentRecipientBalance,
        uint256 baseRewardCycleBlock,
        uint256 threshHoldTopUpRate,
        uint256 amount
    ) public view returns (uint256) {
        if (currentRecipientBalance == 0) {
            return block.timestamp + baseRewardCycleBlock;
        }
        else {
            // calculate the % of tokens the recipient will receive
            // If the % received is higher than tresHoldTopUpRate, update cycle
            // Prevents users spamming small amounts to bigger wallets, thereby disabling their claims
            uint256 rate = amount.mul(100).div(currentRecipientBalance); 

            if (uint256(rate) >= threshHoldTopUpRate) {
                uint256 incurCycleBlock = baseRewardCycleBlock.mul(uint256(rate)).div(100);

                if (incurCycleBlock >= baseRewardCycleBlock) {
                    incurCycleBlock = baseRewardCycleBlock;
                }

                return incurCycleBlock;
            }

            return 0;
        }
    }

    function swapTokensForEth(
        address routerAddress,
        uint256 tokenAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function swapETHForTokens(
        address routerAddress,
        address recipient,
        uint256 ethAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of BNB
            path,
            address(recipient),
            block.timestamp + 360
        );
    }

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360
        );
    }
}

// File: contracts/protocols/bep/ReentrancyGuard.sol

pragma solidity >=0.6.8;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}

// File: contracts/protocols/SOHO Token.sol

pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;



contract S_audit_deploy is Context, IBEP20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    bool public preSalesEnded = false;
    address public preSalesAddress;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromRFI;
    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping (address => bool) private _isExcludedFromTimelock;
    mapping (address => bool) private _isExcludedFromAntiWhale;
    mapping (address => uint256) private lastTransfer;

    address[] private _excluded;

    modifier onlyOwnerOrPresales() {
        require(owner() == _msgSender() || preSalesAddress == _msgSender(), "Ownable: caller is not the owner nor presales");
        _;
    }

    // in percentage, token redistribution
    // contract activation changes it to 1
    uint256 private _taxFee = 0; 
    uint256 private _previousTaxFee = _taxFee;

    // in percentage, 50% added to pool, 50% converted to BNB
    // contract activation changes it to 6
    uint256 private _liquidityFee = 0; 
    uint256 private _previousLiquidityFee = _liquidityFee;

    // in percentage, sent to charity address
    // contract activation changes it to 1
    uint private _charityFee = 0;
    uint256 private _previousCharityFee = _charityFee;

    // in percentage, will be burned
    // contract activation changes it to 2
    uint private _burnFee = 0;
    uint256 private _previousBurnFee = _burnFee;

    // determines the delay between consecutive BNB claims
    // contract activation sets reward to 2 days, easyreward to 7 day
    // set actual values here, otherwise users from the presales can't claim or can claim immediatly
    uint256 private rewardCycleBlock = 2 days;
    uint256 private easyRewardCycleBlock = 7 days;

    // If the amount of tokens received is higher than threshHoldTopUpRate
    // as compared to the wallet balance,
    // the BNB claim delay is reset according to the factor of amountReceived/balance
    // max delay is the rewardcycleblock()
    // set to actual amount to trigger users buying from presales
    uint256 private threshHoldTopUpRate = 20; // 20 percent

    // if BNB amount able to claim is higher than _rewardThreshold,
    // 20% of the BNB reward is used to buy tokens,
    // bought tokens are then burned
    // contract activation sets it to 0.1BNB
    uint256 private _rewardThreshold = 0 ether;

    mapping(address => uint256) private nextAvailableClaimDate;

    // contract activation sets it to true
    bool private swapAndLiquifyEnabled = false; 

    // two phases of claiming with different claim delays
    // contract activation sets it to one week after activation
    uint256 private disableEasyRewardFrom = 0;

    // determines the threshold of tokens on the token contract
    // after which a swap to BNB and LP position is done
    // contract activation sets it to 20B token (=1/30th of total supply moved at 6% fee)
    // should always be lower than the maxTxAmount and maxTotalSupplyPrct!
    // absolute amount with decimals
    uint256 private _minTokenNumberToSell = _tTotal;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1 * 10 ** 15 * 10 ** 9; // 1 quadrillion tokens
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "S_audit Token";
    string private _symbol = "S_audit";
    uint8 private _decimals = 9;

    address private charityWallet = address(0x68793Bd9E38BA703A8efd3E2d06b63CE8eEFb4C6); // change as required

    IPancakeRouter02 public pancakeSwapV2Router;
    address public pancakeSwapV2Pair;

    bool inSwapAndLiquify = false;

    uint256 private _timeDelta = 0; //initated at 0, later set at 3600 seconds
    uint256 private _maxBalancePrct = 100; // initiated at 100%, later set to 10%
    uint256 private _maxTotalSupplyPrct = 10000; // initiated at 100%, later set to 10 -> 10/10000 = 0.1% = 100B tokens
    uint256 private _minBalanceToClaim = 5 * 10**6 * 10**9; // 5M tokens needed in wallet to be able to claim BNB
    uint256 private _maxTxAmount = _tTotal; // should be 0.05% percent per transaction, will be set again at activateContract() function

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event ClaimBNBSuccessfully(
        address recipient,
        uint256 ethReceived,
        uint256 nextAvailableClaimDate
    );

    constructor () {
        _rOwned[_msgSender()] = _rTotal;

        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //ropsten
        
        // Create a pancake pair for this new token
        pancakeSwapV2Pair = IPancakeFactory(_pancakeRouter.factory())
        .createPair(address(this), _pancakeRouter.WETH());

        // set the rest of the contract variables
        pancakeSwapV2Router = _pancakeRouter;

        //exclude from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[charityWallet] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[address(0x000000000000000000000000000000000000dEaD)] = true;
        _isExcludedFromMaxTx[address(0)] = true;
        _isExcludedFromMaxTx[charityWallet] = true;

        // exclude from anti-whale features
        _isExcludedFromAntiWhale[owner()] = true;
        _isExcludedFromAntiWhale[address(this)] = true;
        _isExcludedFromAntiWhale[charityWallet] = true;
        _isExcludedFromAntiWhale[pancakeSwapV2Pair] = true; //only check with 'from' -> buy
        _isExcludedFromAntiWhale[address(pancakeSwapV2Router)] = true; //only check 'from' -> remove liq event

        // exclude timelock
        _isExcludedFromTimelock[owner()] = true;
        _isExcludedFromTimelock[address(this)] = true;
        _isExcludedFromTimelock[address(pancakeSwapV2Router)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromRFI[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    // allow users to 'donate' tokens to be reflected to the holders
    function deliver(uint256 tAmount) external {
        address sender = _msgSender();
        require(!_isExcludedFromRFI[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) private view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) external onlyOwner {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Pancake router.');
        require(!_isExcludedFromRFI[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = balanceOf(account);
        }
        _isExcludedFromRFI[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromRFI[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                uint256 currentRate = _getRate();
                _rOwned[account] = _tOwned[account].mul(currentRate);
                _tOwned[account] = 0;
                _isExcludedFromRFI[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function setExcludeFromFee(address _address, bool value) external onlyOwner {
        _isExcludedFromFee[_address] = value;
    }

    function setExcludeFromAntiwhale(address _address, bool value) external onlyOwner {
        _isExcludedFromAntiWhale[_address] = value;
    }

    function setExcludeFromMaxTx(address _address, bool value) external onlyOwner {
        _isExcludedFromMaxTx[_address] = value;
    }

    function setExcludeFromTimeock(address _address, bool value) external onlyOwner {
        _isExcludedFromTimelock[_address] = value;
    }
    
    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcludedFromRFI[account];
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromAntiWhale(address account) external view returns (bool) {
        return _isExcludedFromAntiWhale[account];
    }

    function isExcludedFromMaxTx(address account) external view returns (bool) {
        return _isExcludedFromMaxTx[account];
    }

    function isExcludedFromTimelock(address account) external view returns (bool) {
        return _isExcludedFromTimelock[account];
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcludedFromRFI[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function _takeCharity(uint256 tCharity) private {
        uint256 currentRate = _getRate();
        uint256 rCharity = tCharity.mul(currentRate);
        _rOwned[charityWallet] = _rOwned[charityWallet].add(rCharity);
        if (_isExcludedFromRFI[charityWallet])
            _tOwned[charityWallet] = _tOwned[charityWallet].add(tCharity);
    }

    // structs to get the t & r values
    struct tAmountsStruct {
      uint256 tFee;
      uint256 tLiquidity;
      uint256 tCharity;
      uint256 tBurn;
    }

    struct tValuesStruct {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tCharity;
        uint256 tBurn;
    }

    struct rValuesStruct {
        uint256 rAmount;
        uint256 rFee;
        uint256 rLiquidity;
        uint256 rCharity;
        uint256 rBurn;
    }

    // reflective token works with two balances: T values if excluded from RFI, R values if included
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        tValuesStruct memory tValues;
        (tValues.tTransferAmount, tValues.tFee, tValues.tLiquidity, tValues.tCharity, tValues.tBurn) = _getTValues(tAmount);

        //(uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 tBurn) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tValues.tFee, tValues.tLiquidity, tValues.tCharity, tValues.tBurn, _getRate());
        return (rAmount, rTransferAmount, rFee, tValues.tTransferAmount, tValues.tFee, tValues.tLiquidity, tValues.tCharity, tValues.tBurn);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        tAmountsStruct memory tAmounts;
        tAmounts.tFee = _calculateTaxFee(tAmount);
        tAmounts.tLiquidity = _calculateLiquidityFee(tAmount);
        tAmounts.tCharity = _calculateCharityFee(tAmount);
        tAmounts.tBurn = _calculateBurnFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tAmounts.tFee).sub(tAmounts.tLiquidity).sub(tAmounts.tCharity).sub(tAmounts.tBurn);
        return (tTransferAmount, tAmounts.tFee, tAmounts.tLiquidity, tAmounts.tCharity, tAmounts.tBurn);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 tBurn, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        rValuesStruct memory rAmounts;
        rAmounts.rAmount = tAmount.mul(currentRate);
        rAmounts.rFee = tFee.mul(currentRate);
        rAmounts.rLiquidity = tLiquidity.mul(currentRate);
        rAmounts.rCharity = tCharity.mul(currentRate);
        rAmounts.rBurn = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmounts.rAmount.sub(rAmounts.rFee).sub(rAmounts.rLiquidity).sub(rAmounts.rCharity).sub(rAmounts.rBurn);
        return (rAmounts.rAmount, rTransferAmount, rAmounts.rFee);
    }

    function _getRate() public view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() public view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    // functions to calculate the different fees
    function _calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10 ** 2
        );
    }

    function _calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10 ** 2
        );
    }

    function _calculateCharityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_charityFee).div(
            10 ** 2
        );
    }

    function _calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(
            10 ** 2
        );
    }

    // if excluded from fee, remove fees, process transfer, then restore fees
    function _removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0 && _charityFee == 0  && _burnFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousCharityFee = _charityFee;
        _previousBurnFee = _burnFee;

        _taxFee = 0;
        _liquidityFee = 0;
        _charityFee = 0;
        _burnFee = 0;
    }

    function _restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _charityFee = _previousCharityFee;
        _burnFee = _previousBurnFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // different transfers, based on isExcludedFromRFI (= token redistribution)
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(from != address(0x000000000000000000000000000000000000dEaD), "BEP20: transfer from the dead address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (preSalesEnded == false) {
            require(from == preSalesAddress || to == preSalesAddress || from == owner() || to == owner(), "Tokens cannot be transfered until the presales is over");
        }

        else {
            // "anti-whales" :
            ensureAntiWhale(from, to, amount);
            ensureTimeLock(from);
            ensureMaxTxAmount(from, amount);

            // swap and liquify
            swapAndLiquify(from, to);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee)
            _removeAllFee();

        // top up claim cycle
        topUpClaimCycleAfterTransfer(recipient, amount);

        if (_isExcludedFromRFI[sender] && !_isExcludedFromRFI[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromRFI[sender] && _isExcludedFromRFI[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromRFI[sender] && !_isExcludedFromRFI[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromRFI[sender] && _isExcludedFromRFI[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee)
            _restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 tBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _takeCharity(tCharity);
        emit Transfer(sender, recipient, tTransferAmount);
        emit Transfer(sender, address(this), tLiquidity);
        emit Transfer(sender, charityWallet, tCharity);
        emit Transfer(sender, address(0), tBurn);

    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 tBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _takeCharity(tCharity);
        emit Transfer(sender, recipient, tTransferAmount);
        emit Transfer(sender, address(this), tLiquidity);
        emit Transfer(sender, charityWallet, tCharity);
        emit Transfer(sender, address(0), tBurn);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 tBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _takeCharity(tCharity);
        emit Transfer(sender, recipient, tTransferAmount);
        emit Transfer(sender, address(this), tLiquidity);
        emit Transfer(sender, charityWallet, tCharity);
        emit Transfer(sender, address(0), tBurn);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 tBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _takeCharity(tCharity);
        emit Transfer(sender, recipient, tTransferAmount);
        emit Transfer(sender, address(this), tLiquidity);
        emit Transfer(sender, charityWallet, tCharity);
        emit Transfer(sender, address(0), tBurn);
    }

    // anti whale features
    function ensureMaxTxAmount(address from, uint256 amount) private view {
        if (_isExcludedFromMaxTx[from] == false && from != owner()) {  
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
    }

    function ensureAntiWhale(address from, address to, uint256 amount) private view {
        if (
            _isExcludedFromAntiWhale[from] == false && 
            from != owner() &&
            to != owner() &&
            to != address(this)
         ) {  
            (, uint256 tSupply) = _getCurrentSupply();
            require(amount <= tSupply.mul(_maxTotalSupplyPrct).div(10000), "Sent too high % of total supply");
            require(amount <= balanceOf(from).mul(_maxBalancePrct).div(100), "Sent too high % of account balance");
        }
    }

    function ensureTimeLock(address from) private {
        if (_isExcludedFromTimelock[from] == false && from != owner()) {
            require(lastTransfer[from].add(_timeDelta) <= block.timestamp || _isExcludedFromTimelock[from] == true, "Max tx per hour reached");
            lastTransfer[from] = block.timestamp;
        }
    }

    function getNextTransferDate(address account) external view returns(uint256) {
        return lastTransfer[account].add(_timeDelta);
    }

    // BNB rewards & liquidification
    function calcBNBReward(address ofAddress) public view returns (uint256) {
        uint256 _totalSupply = uint256(_tTotal)
        .sub(balanceOf(address(0)))
        .sub(balanceOf(0x000000000000000000000000000000000000dEaD)) // exclude burned wallet
        .sub(balanceOf(address(pancakeSwapV2Pair)))
        .sub(balanceOf(address(this)));
        // exclude liquidity wallet

        return Utils.calculateBNBReward(
            balanceOf(address(ofAddress)),
            address(this).balance,
            _totalSupply
        );
    }

    function getRewardCycleBlock() public view returns (uint256) {
        if (block.timestamp >= disableEasyRewardFrom) return rewardCycleBlock;
        return easyRewardCycleBlock;
    }

    function claimBNBReward() isHuman nonReentrant external {
        require(nextAvailableClaimDate[msg.sender] <= block.timestamp, 'Error: next available date not reached');
        require(balanceOf(msg.sender) >= _minBalanceToClaim, 'Error: must own SOHO to claim reward');

        uint256 reward = calcBNBReward(msg.sender);

        // reward threshold
        if (reward >= _rewardThreshold) {
            inSwapAndLiquify = true;
            Utils.swapETHForTokens(
                address(pancakeSwapV2Router),
                address(0x000000000000000000000000000000000000dEaD),
                reward.div(5) //buy SOHO with 20% of the reward
            );
            reward = reward.sub(reward.div(5));
            inSwapAndLiquify = false;
        }

        // update rewardCycleBlock
        nextAvailableClaimDate[msg.sender] = block.timestamp + getRewardCycleBlock();
        emit ClaimBNBSuccessfully(msg.sender, reward, nextAvailableClaimDate[msg.sender]);

        (bool sent,) = payable(msg.sender).call{value : reward}("");
        require(sent, 'Error: Cannot withdraw reward');
    }

    function topUpClaimCycleAfterTransfer(address recipient, uint256 amount) private {
        uint256 currentRecipientBalance = balanceOf(recipient); //before the transfer has occured
        uint256 baseRewardCycleBlock = getRewardCycleBlock();

        nextAvailableClaimDate[recipient] = nextAvailableClaimDate[recipient] + Utils.calculateTopUpClaim(
            currentRecipientBalance,
            baseRewardCycleBlock,
            threshHoldTopUpRate,
            amount
        );
    }

    function swapAndLiquify(address from, address to) private {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancake pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool shouldSell = contractTokenBalance >= _minTokenNumberToSell;

        if (
            !inSwapAndLiquify &&
        shouldSell &&
        from != pancakeSwapV2Pair &&
        swapAndLiquifyEnabled &&
        !(from == address(this) && to == address(pancakeSwapV2Pair)) // swap 1 time
        ) {
            inSwapAndLiquify = true;

            // only sell for _minTokenNumberToSell, decouple from _maxTxAmount
            contractTokenBalance = _minTokenNumberToSell;

            // split the contract balance into halves
            // sell 3/4 of the tokens, add 1/4 of the tokens with BNB
            uint256 quarter = contractTokenBalance.div(4);
            uint256 threeQuarters = contractTokenBalance.sub(quarter);

            uint256 initialBalance = address(this).balance;

            // Swap tokens for native
            Utils.swapTokensForEth(address(pancakeSwapV2Router), threeQuarters);
            uint256 addedBySwap = address(this).balance.sub(initialBalance);

            // add liquidity to pancake
            // sends tokens to owner
            // use quarter as amount of tokens, use the BNB from the 3/4th sell
            // amount of tokens take the lead -> leftover BNB will be returned
            Utils.addLiquidity(address(pancakeSwapV2Router), owner(), quarter, addedBySwap); 

            emit SwapAndLiquify(threeQuarters, addedBySwap, quarter);
            inSwapAndLiquify = false;
        }
    }

    function getNextAvailableClaimDate(address account) external view returns(uint256) {
        return nextAvailableClaimDate[account];
    }

    function consultFeeParameters() external view returns(
        uint256,
        uint256,
        uint256,
        uint256,
        address)
        {
        return (
        _taxFee,
        _liquidityFee,
        _charityFee,
        _burnFee, 
        charityWallet
        );
    }

    function consultLiqParameters() external view returns(
        bool,
        uint256,
        uint256)
        {
        return (
        swapAndLiquifyEnabled,
        _liquidityFee,
        _minTokenNumberToSell);
    }

    function consultBnbRewardParameters() external view returns(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256)
        {
        return (disableEasyRewardFrom,
        rewardCycleBlock,
        easyRewardCycleBlock,
        threshHoldTopUpRate,
        _rewardThreshold);
    }

    function consultAntiWhaleParameters() external view returns(
        uint256,
        uint256,
        uint256,
        uint256)
        {
        return (
        _maxTxAmount,
        _maxTotalSupplyPrct,
        _maxBalancePrct,
        _timeDelta);
    }

    // initiate contract variables
    // we are not calling the set... functions since the msg.sender will be the presales contract
    // no reason to add another master account that would have access to those functions
    function activateContract() external onlyOwnerOrPresales {
        preSalesEnded = true;

        // reward claim
        disableEasyRewardFrom = block.timestamp + 1 weeks;
        rewardCycleBlock = 2 days;
        easyRewardCycleBlock = 7 days;

        // protocol anti-whale
        // set _maxTxAmount
        _maxTxAmount = 10 * 10**12 * 10**decimals();

        // set _maxTotalSupplyPrct
        _maxTotalSupplyPrct = 10; // uses factor 10 000

        // set _maxBalancePrct
        _maxBalancePrct = 10; // in %

        swapAndLiquifyEnabled = true;

        // set tax fees
        _taxFee = 1; // in %
        _liquidityFee = 6; // in %, combines liquidity & bnb rewards (50-50)
        _charityFee = 1; // in %
        _burnFee = 2; // in %

        // set thresholdtoupdate
        threshHoldTopUpRate = 20; //in %

        // set _rewardThreshold
        _rewardThreshold = 1 * 10**17; //0.1BNB

        // set _minTokenNumberToSell to 20B tokens
        // 1/50000th of the tokens at 6% fee = 1/30th total supply transfered
        _minTokenNumberToSell = 20 * 10**9 * 10**decimals();

        // set _timedelta to 1 hour
        _timeDelta = 3600;

        // approve contract
        _approve(address(this), address(pancakeSwapV2Router), 2 ** 256 - 1);
    }

    // called by presales contract
    function setPreSalesEnded() external onlyOwnerOrPresales {
        preSalesEnded = true;
    }

    function setPreSalesAddress(address account) external onlyOwner {
        preSalesAddress = account;
    }

    // set functions
    function setTaxFee(uint256 taxFee) public onlyOwner {
        require(taxFee + _liquidityFee + _charityFee + _burnFee <= 15, "Total fee set too high! Max 15% total");

        _previousTaxFee = _taxFee;
        _taxFee = taxFee;
    }

    function setLiquidityFee(uint256 liquidityFee) public onlyOwner {
        require(liquidityFee + _taxFee + _charityFee + _burnFee <= 15, "Total fee set too high! Max 15% total");

        _previousLiquidityFee = _liquidityFee;
        _liquidityFee = liquidityFee;
    }

    function setCharityFee(uint256 charityFee) public onlyOwner {
        require(charityFee + _taxFee + _liquidityFee + _burnFee <= 15, "Total fee set too high! Max 15% total");

        _previousCharityFee = _charityFee;
        _charityFee = charityFee;
    }

    function setBurnFee(uint256 burnFee) public onlyOwner {
        require(burnFee + _taxFee + _liquidityFee + _charityFee <= 15, "Total fee set too high! Max 15% total");

        _previousBurnFee = _burnFee;
        _burnFee = burnFee;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setMaxTxAmount(uint256 maxTxAmount) public onlyOwner {
        require(maxTxAmount > 1 * 10**6 * 10**_decimals, "MaxTxAmount too low: must be at least 1M!"); //always allow 1M transfers
        _maxTxAmount = maxTxAmount;
    }

    function setMaxTotalSupply(uint256 maxTotalSupplyPrct) public onlyOwner {
        require(maxTotalSupplyPrct > 0, "Cannot set the maxTotalSupplyPrct to zero!");
        _maxTotalSupplyPrct =_tTotal.mul(maxTotalSupplyPrct).div(10000);
    }

    function setMaxBalancePrct(uint256 maxBalancePrct) public onlyOwner {
        require(maxBalancePrct > 2, "Cannot set the maxBalancePrct lower than 2%");
        _maxBalancePrct = maxBalancePrct;
    }

    function setTimeDelta(uint256 timeDelta) public onlyOwner {
        require(timeDelta < 5 days, "Cannot sent the timedelta longer than 5 days!");
        _timeDelta = timeDelta;
    }

    // the reward thresholds is an amount in BNB in wei
    // users claiming more than this threshold, get a 20% penalty
    // this 20% of the bnb reward is used to buy tokens and burn them
    function setRewardThreshold(uint256 rewardThreshold) public onlyOwner {
        _rewardThreshold = rewardThreshold;
    }

    function setMinTokenNumberToSell(uint256 minTokenNumberToSell) public onlyOwner {
        _minTokenNumberToSell = minTokenNumberToSell;
    }

    function setDisableEasyRewardFrom(uint256 newDate) public onlyOwner {
        disableEasyRewardFrom = newDate;
    }

    function setEasyRewardCycleBlock(uint256 newTimeSpan) public onlyOwner {
        easyRewardCycleBlock = newTimeSpan;
    }

    function setRewardCycleBlock(uint256 newTimeSpan) public onlyOwner {
        rewardCycleBlock = newTimeSpan;
    }

    function setThresholdToUpdate(uint256 newThreshHoldTopUpRate) public onlyOwner {
        threshHoldTopUpRate = newThreshHoldTopUpRate; //in percentage!
    }

    function setCharityAddress(address account) external onlyOwner {
        charityWallet = account;
    }

    //to receive BNB from pancakeRouter when swapping
    receive() external payable {}
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "evmVersion": "constantinople",
  "libraries": {
    "/C/Users/Greg/Documents/Truffletest/Soho - Copy/contracts/SOHO_Token.sol": {
      "Utils": "0xe7335b1a6FA4078f43E5d81E0cF1aFf25BEEA1f6"
    }
  },
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