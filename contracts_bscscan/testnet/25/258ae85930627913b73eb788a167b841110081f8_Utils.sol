/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-22
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



// wrapped BNB interface

interface IWBNB {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint);

    function allowance(address, address) external view returns (uint);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad)
    external
    returns (bool);
    
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
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

// File: contracts/protocols/bep/Utils.sol

pragma solidity >=0.6.8;


library Utils {
    using SafeMath for uint256;

    function random(uint256 from, uint256 to, uint256 salty) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
                    block.gaslimit +
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
                    block.number +
                    salty
                )
            )
        );
        return seed.mod(to - from) + from;
    }



    function calculateBNBReward(
       // uint256 _tTotal,
        uint256 currentBalance,
        uint256 currentBNBPool,
        uint256 totalSupply,
      // address ofAddress,
        uint256 rewardHardcap
    ) public pure returns (uint256) {
        uint256 bnbPool = currentBNBPool;
        
        
        if (bnbPool > rewardHardcap) {
            
        bnbPool = rewardHardcap;     
        }

        // calculate reward to send
     
        uint256 multiplier = 100;

        // now calculate reward
        uint256 reward = bnbPool.mul(multiplier).mul(currentBalance).div(100).div(totalSupply);
  
        return reward;
    }

    function calculateTopUpClaim(
        uint256 currentRecipientBalance,
        uint256 basedRewardCycleBlock,
        uint256 threshHoldTopUpRate,
        uint256 amount
    ) public view returns (uint256) {
        if (currentRecipientBalance == 0) {
            return block.timestamp + basedRewardCycleBlock;
        }
        else {
            uint256 rate = amount.mul(100).div(currentRecipientBalance);

            if (uint256(rate) >= threshHoldTopUpRate) {
                uint256 incurCycleBlock = basedRewardCycleBlock.mul(uint256(rate)).div(100);

                if (incurCycleBlock >= basedRewardCycleBlock) {
                    incurCycleBlock = basedRewardCycleBlock;
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

    
      function swapTokensForTokens(
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
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            ethAmount,         // wbnb input 
            0, // accept any amount of BNB
            path,
            address(recipient),
            block.timestamp + 360
        );
    }
    
  
  
    
    function getAmountsout(uint256 amount,address routerAddress) public view returns(uint256 _amount) {
        
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();                         
        path[1] = address(this);

        // fetch current rate
        uint[] memory amounts =  pancakeRouter.getAmountsOut(amount,path);
        return amounts[1];
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

    constructor () public {
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

// File: contracts/protocols/HODL.sol

pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;

contract HODLV2 is Context, IBEP20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxTx;

    // trace BNB claimed rewards and reinvest value
    mapping(address => uint256) public userClaimedBNB;
    uint256 public totalClaimedBNB = 0; 
   
    mapping(address => uint256) public userreinvested;
    uint256 public totalreinvested = 0;
    
    // trace gas fees distribution
    uint256 public totalgasfeesdistributed = 0;
    mapping(address => uint256) public userrecievedgasfees;
    
    
    
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10 ** 6 * 10 ** 9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "HODL 2.0";
    string private _symbol = "HODL";
    uint8 private _decimals = 9;

    IPancakeRouter02 public immutable pancakeRouter;
    address public immutable pancakePair;

    bool inSwapAndLiquify = false;

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

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (
        address payable routerAddress
    ) public {
        _rOwned[_msgSender()] = _rTotal;

        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(routerAddress);
        // Create a pancake pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory())
        .createPair(address(this), _pancakeRouter.WETH());

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
       

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[address(0x000000000000000000000000000000000000dEaD)] = true;
        _isExcludedFromMaxTx[address(0)] = true;
       
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
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount, 0);
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
        _transfer(sender, recipient, amount, 0);
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Pancake router.');
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

      function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //to receive BNB from pancakeRouter when swapping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

   
  function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }


    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
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

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10 ** 2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10 ** 2
        );
    }
    
    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
      
        _taxFee = 0;
        _liquidityFee = 0;
        
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
       
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount,
        uint256 value
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        ensureMaxTxAmount(from, to, amount, value);

        // swap and liquify
        swapAndLiquify(from, to, amount);
        
        
      
        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || reflectionFeesdiabled) {
            takeFee = false;
        }
        
        
        // take sell fee 
        if (to == address(pancakePair) && from != address(this) && from != owner() ) {
            
        uint256 sellfee = amount.mul(selltax).div(100);
        amount = amount.sub(sellfee);
        
        bool fee = false;    
            
         _tokenTransfer(from, address(this), sellfee, fee);
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee)
            removeAllFee();

        // top up claim cycle for recipient
        topUpClaimCycleAfterTransfer(recipient, amount);

       // top up claim cycle for sender
        topUpClaimCycleAfterTransfer(sender, amount); 

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee)
            restoreAllFee();
    }

     function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // Innovation for protocol by HODL Team
    uint256 public rewardCycleBlock = 1 days;
    uint256 public easyRewardCycleBlock = 1 days;
    uint256 public threshHoldTopUpRate = 25; // 25 percent
    uint256 public _maxTxAmount = _tTotal; // should be 0.05% percent per transaction, will be set again at activateContract() function
    uint256 public disruptiveCoverageFee = 1 ether; // antiwhale
    mapping(address => uint256) public nextAvailableClaimDate;
    bool public swapAndLiquifyEnabled = false; // should be true
    uint256 public disruptiveTransferEnabledFrom = 0;
    uint256 public disableEasyRewardFrom = 0;
    
    bool public reflectionFeesdiabled = false;
   
    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;
    
    
    // uint256 public claimfee = 3;
    // uint256 public claimReservefee = 20;
    
    // bnb claim fee
    uint256 public layer1tax = 0;
    uint256 public layer2tax = 0;
    uint256 public layer3tax = 5;
    uint256 public layer4tax = 10;
    uint256 public layer5tax = 10;
    uint256 public layer6tax = 20;
    
    // reinvest fee
    uint256 public tax1 = 0;
    uint256 public tax2 = 0;
    uint256 public tax3 = 5;
    uint256 public tax4 = 10;
    uint256 public tax5 = 10;
    uint256 public tax6 = 20;
    
    
    uint256 public selltax = 5;
    
    uint256 public marketingshare = 1071;                  // 10.71 % 
    uint256 public buybackshare = 1429;                    // 14.29 %
    uint256 public teamshare = 357;                        // 3.57 %
    

    address public reservewallet = 0xE964808e62C5D90D61891916c4e0CdaA340E8fAb;
    address public teamwallet = 0xf73BE1b2714182dd29236F7136163F4ABE000ae1;
    address public marketingwallet = 0x7A853e323358ba8f6B2Ec38006F663894ba978a7;
    address public reinvestwallet = 0xC59EAEca72Dc9082859567573dfb85De59255543;
    
    
    uint256 public _liquidityFee = 8; 
    uint256 private _previousLiquidityFee = _liquidityFee;
    // uint256 public rewardThreshold = 1 ether;

    uint256 public minTokenNumberToSell = _tTotal.mul(1).div(10000).div(10); // 0.001% max tx amount will trigger swap and add liquidity
    uint256 public minTokenNumberUpperlimit = _tTotal.mul(2).div(100).div(10); 
    
    uint256 public rewardHardcap = 75 ether;
    
    uint256 public claimgasfee = 0.00525 ether;
    
    uint256 public buyBackUpperLimit = 1 * 10**18;
    bool public buyBackEnabled = false;
    uint256 public buyBackthresholdLimit = 10000000000 * 10**9;
    
    uint256 public mintoken = 100000000 * 10**9;
    uint256 public maxtoken = _tTotal;


    function setMaxTxPercent(uint256 maxTxPercent) public onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10000);
    }   

    function setExcludeFromMaxTx(address _address, bool value) public onlyOwner { 
        _isExcludedFromMaxTx[_address] = value;
    }       

    function calculateBNBReward(address ofAddress) public view returns (uint256) {
        uint256 totalsupply = uint256(_tTotal)
        .sub(balanceOf(address(0)))
        .sub(balanceOf(0x000000000000000000000000000000000000dEaD)) // exclude burned wallet
        .sub(balanceOf(address(pancakePair)));
        // exclude liquidity wallet

        return Utils.calculateBNBReward(
          //  _tTotal,
            balanceOf(address(ofAddress)),
            address(this).balance,
            totalsupply,
          //  ofAddress,
            rewardHardcap
        );
    }

    function getRewardCycleBlock() public view returns (uint256) {
        if (block.timestamp >= disableEasyRewardFrom) return rewardCycleBlock;
        return easyRewardCycleBlock;
    }


 
     function redeemRewards(uint256 perc) isHuman nonReentrant public {
        require(nextAvailableClaimDate[msg.sender] <= block.timestamp, 'Error: next available not reached');
        require(balanceOf(msg.sender) >= 0, 'Error: must own HODL2 to claim reward');
          
        uint256 reward = calculateBNBReward(msg.sender);
          
        uint256 rewardBNB = reward.mul(perc).div(100);
         
        uint256 rewardreinvest = reward.sub(rewardBNB);
        

         // BNB REINVEST
        if (rewardreinvest > 0) {
         
         
         // BNB REINVEST tax
        if (rewardreinvest < 0.1 ether )  {
             
            uint256 rewardfee = rewardreinvest.mul(tax1).div(100);
            (bool success, ) = address(reservewallet).call{ value: rewardfee }("");
            require(success, " Error: Cannot send reward");    
            
            rewardreinvest = rewardreinvest.sub(rewardfee);
           }
        
        else if (rewardreinvest < 0.25 ether )  {
             
            uint256 rewardfee = rewardreinvest.mul(tax2).div(100);
            (bool success, ) = address(reservewallet).call{ value: rewardfee }("");
            require(success, " Error: Cannot send reward");    
            
            rewardreinvest = rewardreinvest.sub(rewardfee);
           }
           
          else if (rewardreinvest < 0.5 ether )  {
             
            uint256 rewardfee = rewardreinvest.mul(tax3).div(100);
            (bool success, ) = address(reservewallet).call{ value: rewardfee }("");
            require(success, " Error: Cannot send reward");    
            
            rewardreinvest = rewardreinvest.sub(rewardfee);
           }
           
         else if (rewardreinvest < 0.75 ether )  {
             
            uint256 rewardfee = rewardreinvest.mul(tax4).div(100);
            (bool success, ) = address(reservewallet).call{ value: rewardfee }("");
            require(success, " Error: Cannot send reward");    
            
            rewardreinvest = rewardreinvest.sub(rewardfee);
           }
           
         else if (rewardreinvest < 1 ether )  {
             
            uint256 rewardfee = rewardreinvest.mul(tax5).div(100);
            (bool success, ) = address(reservewallet).call{ value: rewardfee }("");
            require(success, " Error: Cannot send reward");    
            
            rewardreinvest = rewardreinvest.sub(rewardfee);
           }
           
         else {
             
            uint256 rewardfee = rewardreinvest.mul(tax6).div(100);
            (bool success, ) = address(reservewallet).call{ value: rewardfee }("");
            require(success, " Error: Cannot send reward");    
            
            rewardreinvest = rewardreinvest.sub(rewardfee);
           }   
             
             
        // Re-InvestTokens     
        uint256 expectedtoken = Utils.getAmountsout(rewardreinvest,address(pancakeRouter)); 
        
        
        // update reinvest rewards
        userreinvested[msg.sender] += expectedtoken;
        totalreinvested = totalreinvested + expectedtoken;

        // Transfer token equivalent to bnb to user account
        removeAllFee();
        _transferStandard(address(this),msg.sender, expectedtoken);
        restoreAllFee(); 
        
    
        // buy tokens from pancake and send to re-invest wallet
         Utils.swapETHForTokens(address(pancakeRouter), reinvestwallet , rewardreinvest);
         
         } 
         
         
         // BNB CLAIM
         if (rewardBNB > 0) {
         
         // deduct tax
         if (rewardBNB < 0.1 ether )  {
             
            uint256 rewardfee = rewardBNB.mul(layer1tax).div(100);
            (bool success, ) = address(reservewallet).call{ value: rewardfee }("");
            require(success, " Error: Cannot send reward");    
            
            rewardBNB = rewardBNB.sub(rewardfee);
           }
        
        else if (rewardBNB < 0.25 ether )  {
             
            uint256 rewardfee = rewardBNB.mul(layer2tax).div(100);
            (bool success, ) = address(reservewallet).call{ value: rewardfee }("");
            require(success, " Error: Cannot send reward");    
            
            rewardBNB = rewardBNB.sub(rewardfee);
           }
    
        else if (rewardBNB < 0.5 ether )  {
             
            uint256 rewardfee = rewardBNB.mul(layer3tax).div(100);
            (bool success, ) = address(reservewallet).call{ value: rewardfee }("");
            require(success, " Error: Cannot send reward");    
            
            rewardBNB = rewardBNB.sub(rewardfee);
           }
           
         else if (rewardBNB < 0.75 ether )  {
             
            uint256 rewardfee = rewardBNB.mul(layer4tax).div(100);
            (bool success, ) = address(reservewallet).call{ value: rewardfee }("");
            require(success, " Error: Cannot send reward");    
            
            rewardBNB = rewardBNB.sub(rewardfee);
           }
           
         else if (rewardBNB < 1 ether )  {
             
            uint256 rewardfee = rewardBNB.mul(layer5tax).div(100);
            (bool success, ) = address(reservewallet).call{ value: rewardfee }("");
            require(success, " Error: Cannot send reward");    
            
            rewardBNB = rewardBNB.sub(rewardfee);
           }
           
         else {
             
            uint256 rewardfee = rewardBNB.mul(layer6tax).div(100);
            (bool success, ) = address(reservewallet).call{ value: rewardfee }("");
            require(success, " Error: Cannot send reward");    
            
            rewardBNB = rewardBNB.sub(rewardfee);
           }
           
          
        // send bnb to user
        
        // BNB CLAIM
        (bool sent,) = address(msg.sender).call{value : rewardBNB}("");
        require(sent, 'Error: Cannot withdraw reward');

        // update claimed rewards
        userClaimedBNB[msg.sender] += rewardBNB;
        totalClaimedBNB = totalClaimedBNB.add(rewardBNB);
           
        }     
           
       
           
       uint256 userbalance = balanceOf(msg.sender);
    
       // free gas fee
       if (userbalance >= mintoken && userbalance <= maxtoken ) {
           
        // BNB CLAIM
        (bool fee,) = address(msg.sender).call{value : claimgasfee}("");
        require(fee, 'Error: Cannot send fee'); 
        
        totalgasfeesdistributed = totalgasfeesdistributed.add(claimgasfee);
        userrecievedgasfees[msg.sender] += claimgasfee; 
          
       }
       
    

        // update rewardCycleBlock
        nextAvailableClaimDate[msg.sender] = block.timestamp + getRewardCycleBlock();
        emit ClaimBNBSuccessfully(msg.sender, reward, nextAvailableClaimDate[msg.sender]);

        
    }
   
    
    // function calculateapproxReinvestToken(address _user, uint256 perc) public view returns (uint256 _approxtokens) {
        
    //     uint256 reward = calculateBNBReward(_user);
        
    //     uint256 rewardBNB = reward.mul(perc).div(100);
        
    //     uint256 rewardreinvest = reward.sub(rewardBNB);
        
    //     if (rewardreinvest > 0) { 
    //     uint256 expectedtoken = Utils.getAmountsout(rewardreinvest,address(pancakeRouter)); 
        
    //     return expectedtoken;
    //     }
    //     else{
    //         return 0;
    //     }
    // }
    
    
    function topUpClaimCycleAfterTransfer(address _add, uint256 amount) private {
        uint256 currentRecipientBalance = balanceOf(_add);
        uint256 basedRewardCycleBlock = getRewardCycleBlock();
        
        if (_add == owner() && nextAvailableClaimDate[_add] == 0 ){
            
         nextAvailableClaimDate[_add] = block.timestamp + basedRewardCycleBlock;    
        }
        
        else  {
        nextAvailableClaimDate[_add] = nextAvailableClaimDate[_add] + Utils.calculateTopUpClaim(
            currentRecipientBalance,
            basedRewardCycleBlock,
            threshHoldTopUpRate,
            amount
        );
        
        }
    }


    function ensureMaxTxAmount(
        address from,
        address to,
        uint256 amount,
        uint256 value
    ) private view {
        if (
            _isExcludedFromMaxTx[from] == false && // default will be false
            _isExcludedFromMaxTx[to] == false // default will be false
        ) {
            if (value < disruptiveCoverageFee && block.timestamp >= disruptiveTransferEnabledFrom) {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }
        }
    }

    function disruptiveTransfer(address recipient, uint256 amount) public payable returns (bool) {
        _transfer(_msgSender(), recipient, amount, msg.value);
        return true;
    }

    function swapAndLiquify(address from, address to, uint256 amount) private {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancake pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }
 
        bool shouldSell = contractTokenBalance >= minTokenNumberUpperlimit;
        
         if (
        !inSwapAndLiquify &&
        shouldSell &&
        from != pancakePair &&
        swapAndLiquifyEnabled &&
        !(from == address(this) && to == address(pancakePair)) // swap 1 time
        ) {
            // only sell for minTokenNumberToSell, decouple from _maxTxAmount
            contractTokenBalance = minTokenNumberToSell;

                                                   
            uint256 otherPiece = contractTokenBalance.mul(1250).div(10000);                     //  12.5
            uint256 pooledBNB = contractTokenBalance.sub(otherPiece);
              
            uint256 initialBalance = address(this).balance;

            // now is to lock into staking pool
            Utils.swapTokensForEth(address(pancakeRouter), pooledBNB);

            // how much BNB did we just swap into?

            // capture the contract's current BNB balance.
            // this is so that we can capture exactly the amount of BNB that the
            // swap creates, and not make the liquidity event include any BNB that
            // has been manually sent to the contract
            uint256 deltaBalance = address(this).balance.sub(initialBalance);      
            
            
            uint256 bnbToBeAddedToLiquidity = deltaBalance.mul(1429).div(10000);               // 14.29
            
            uint256 marketingreward = deltaBalance.mul(marketingshare).div(10000);             // 10.71
            
            uint256 buybackreward = deltaBalance.mul(buybackshare).div(10000);                 // 14.29
            
            uint256 teamreward = deltaBalance.mul(teamshare).div(10000);                       // 3.57
            
            
            IWBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).deposit{value: buybackreward}();     
            
             // send makreting rewards
             (bool sent,) = address(marketingwallet).call{value : marketingreward}("");
             require(sent, 'Error: Cannot send reward');
             
             // send team rewards
             (bool succ,) = address(teamwallet).call{value : teamreward}("");
             require(succ, 'Error: Cannot send reward');

            // add liquidity to pancake
            Utils.addLiquidity(address(pancakeRouter), owner(), otherPiece, bnbToBeAddedToLiquidity);

            emit SwapAndLiquify(otherPiece, deltaBalance, otherPiece);
        
            if (to == address(pancakePair)) 
               {
             uint256 balance = IWBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).balanceOf(address(this));
             if (buyBackEnabled && balance > uint256(1 * 10**18) && amount > buyBackthresholdLimit ) {
                
                if (balance > buyBackUpperLimit)
                  {  balance = buyBackUpperLimit;  }
                
            uint256 buybackamount = balance.div(100);   
            
             Utils.swapTokensForTokens(address(pancakeRouter), deadAddress, buybackamount);       
             
        }
      }
    }   
  }
    
     
    //   function activateTestNet() public onlyOwner {
    //     // reward claim
    //     disableEasyRewardFrom = block.timestamp;
    //     rewardCycleBlock = 3 minutes;
    //     easyRewardCycleBlock = 3 minutes;

    //     // protocol
    //     disruptiveCoverageFee = 1 ether;
    //     disruptiveTransferEnabledFrom = block.timestamp;
    //     setMaxTxPercent(10000);                   // 100 means 1%   and 1 means 0.01%      
    //     setSwapAndLiquifyEnabled(true);
    //     buyBackEnabled = true;

    //     // approve contract
    //     _approve(address(this), address(pancakeRouter), 2 ** 256 - 1);
    //      IWBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).approve(address(pancakeRouter),2 ** 256 - 1);
    // }
    
    
    
       function activateContract() public onlyOwner {
        // reward claim
        disableEasyRewardFrom = block.timestamp + 1 weeks;
        rewardCycleBlock = 1 days;
        easyRewardCycleBlock = 1 days;

        // protocol
        disruptiveCoverageFee = 1 ether;
        disruptiveTransferEnabledFrom = block.timestamp;
        setMaxTxPercent(10000);
        setSwapAndLiquifyEnabled(true);
        buyBackEnabled = true;
         
        // approve contract
        _approve(address(this), address(pancakeRouter), 2 ** 256 - 1);
        IWBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).approve(address(pancakeRouter),2 ** 256 - 1);
    }
    
    
    
    
    function changerewardCycleBlock(uint256 newcycle) public onlyOwner {
          
      rewardCycleBlock = newcycle;  
    }
    

    
    function changereservewallet(address payable _newaddress) public onlyOwner {
        
        reservewallet = _newaddress;
    }
    
    function changemarketingwallet(address payable _newaddress) public onlyOwner {
        
        marketingwallet = _newaddress;
    }
    
    function changeteamwallet(address payable _newaddress) public onlyOwner {
        
        teamwallet = _newaddress;
    }
    
    function changereinvestwallet(address payable _newaddress) public onlyOwner {
        
        reinvestwallet = _newaddress;
    }
    
    
    // disable enable reflection fee , value == false (enable) 
    function reflectionfeestartstop(bool _value) public onlyOwner {
        
        reflectionFeesdiabled = _value;
    }
    
    
    function migrateToken(address _newadress , uint256 _amount) public onlyOwner {
    
        removeAllFee();
        _transferStandard(address(this), _newadress, _amount);
        restoreAllFee();
    }

    
    function migrateWBnb(address _newadress , uint256 _amount) public onlyOwner {
    
        IWBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).transfer(_newadress,_amount);
    }



    function migrateBnb(address payable _newadd,uint256 amount) public onlyOwner {
        
        (bool success, ) = address(_newadd).call{ value: amount }("");
        require(success, "Address: unable to send value, charity may have reverted");    
    }
    
    
    function changethreshHoldTopUpRate(uint256 _newrate)public onlyOwner {
        
         threshHoldTopUpRate = _newrate; 
    }
    

    
    function changeselltax(uint256 _newtax)public onlyOwner {
        
         selltax = _newtax; 
    } 
     
    function changebnbclaimtax(uint8 layer, uint256 _newfee)public onlyOwner {
        
        
       require (layer == 1 || layer == 2 || layer == 3 || layer == 4 || layer == 5 || layer == 6 , "Select Appropriate Layer");    
        
        if (layer == 1) {
            
        layer1tax = _newfee;  
        }
         
       else if (layer == 2) {
            
        layer2tax = _newfee;
        }     
        
       else if (layer == 3) {
            
        layer3tax = _newfee;
        }
        
       else if (layer == 4) {
            
        layer4tax = _newfee;    
        }
        
       else if (layer == 5) {
            
        layer5tax = _newfee;    
        }
    
        else if (layer == 6) {
            
        layer6tax = _newfee;    
        }
    
    }
    
    
    function changereinvesttax(uint8 layer, uint256 _newfee)public onlyOwner {
        
        
       require (layer == 1 || layer == 2 || layer == 3 || layer == 4 || layer == 5 || layer == 6 , "Select Appropriate Layer");    
        
        if (layer == 1) {
            
        tax1 = _newfee;  
        }
         
       else if (layer == 2) {
            
        tax2 = _newfee;
        }     
        
       else if (layer == 3) {
            
        tax3 = _newfee;
        }
        
       else if (layer == 4) {
            
        tax4 = _newfee;    
        }
        
       else if (layer == 5) {
            
        tax5 = _newfee;    
        }
    
        else if (layer == 6) {
            
        tax6 = _newfee;    
        }
    
    }
    
    
    
    
    function changeclaimgasfee(uint256 _newfee)public onlyOwner {
        
         claimgasfee = _newfee; 
    }
    
    function changeminTokenNumberToSell(uint256 _newvalue)public onlyOwner {
        
        require (_newvalue <= minTokenNumberUpperlimit, "Incorrect Value");
         minTokenNumberToSell = _newvalue; 
    }
    
    function changeminTokenNumberUpperlimit(uint256 _newvalue)public onlyOwner {
        
        require (_newvalue >= minTokenNumberToSell, "Incorrect Value" );
         minTokenNumberUpperlimit = _newvalue; 
    }
    
    function changerewardHardcap(uint256 _newvalue)public onlyOwner {
        
         rewardHardcap = _newvalue; 
    }
    
    
     // 1250 => 12.5 %
    function changemarketingshare(uint256 _newvalue)public onlyOwner {
        
         marketingshare = _newvalue; 
    }
    
     // 1250 => 12.5 %
    function changebuybackshare(uint256 _newvalue)public onlyOwner {
        
         buybackshare = _newvalue; 
    }
    
    function changeteamshare(uint256 _newvalue)public onlyOwner {
        
         teamshare = _newvalue; 
    }
    
    
    function changebuyBackUpperLimit(uint256 _newvalue)public onlyOwner {
        
         buyBackUpperLimit = _newvalue; 
    }
    
    function changebuyBackthresholdLimit(uint256 _newvalue)public onlyOwner {
        
         buyBackthresholdLimit = _newvalue; 
    }
    
    function changemintoken(uint256 _newvalue) public onlyOwner {
        
        mintoken = _newvalue;
    }
    
    function changemaxtoken(uint256 _newvalue) public onlyOwner {
        
        maxtoken = _newvalue;
    }
    

    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
       
    }
 
}