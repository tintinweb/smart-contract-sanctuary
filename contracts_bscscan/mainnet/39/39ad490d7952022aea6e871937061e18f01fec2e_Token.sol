/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

/*
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
// SPDX-License-Identifier: MIT
// import "hardhat/console.sol";
pragma solidity ^0.6.12;

library AddrArrayLib {
    using AddrArrayLib for Addresses;
    struct Addresses {
        address[] _items;
        mapping(address => int) map;
    }

    function removeAll(Addresses storage self) internal {
        delete self._items;
    }

    function pushAddress(Addresses storage self, address element, bool allowDup) internal {
        if (allowDup) {
            self._items.push(element);
            self.map[element] = 2;
        } else if (!exists(self, element)) {
            self._items.push(element);
            self.map[element] = 2;
        }
    }

    function removeAddress(Addresses storage self, address element) internal returns (bool) {
        if (!exists(self, element)) {
            return true;
        }
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                self._items[i] = self._items[self.size() - 1];
                self._items.pop();
                self.map[element] = 1;
                return true;
            }
        }
        return false;
    }

    function getAddressAtIndex(Addresses storage self, uint256 index) internal view returns (address) {
        require(index < size(self), "the index is out of bounds");
        return self._items[index];
    }

    function size(Addresses storage self) internal view returns (uint256) {
        return self._items.length;
    }

    function exists(Addresses storage self, address element) internal view returns (bool) {
        return self.map[element] == 2;
    }

    function getAllAddresses(Addresses storage self) internal view returns (address[] memory) {
        return self._items;
    }
}

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
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        (bool success,) = recipient.call{value : amount}("");
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
     * - the calling contract must have an ETH balance of at least `value`.
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
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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

}

interface IUniswapV2Factory {
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

// interface IUniswapV2Pair {
//     event Approval(address indexed owner, address indexed spender, uint value);
//     event Transfer(address indexed from, address indexed to, uint value);

//     function name() external pure returns (string memory);

//     function symbol() external pure returns (string memory);

//     function decimals() external pure returns (uint8);

//     function totalSupply() external view returns (uint);

//     function balanceOf(address owner) external view returns (uint);

//     function allowance(address owner, address spender) external view returns (uint);

//     function approve(address spender, uint value) external returns (bool);

//     function transfer(address to, uint value) external returns (bool);

//     function transferFrom(address from, address to, uint value) external returns (bool);

//     function DOMAIN_SEPARATOR() external view returns (bytes32);

//     function PERMIT_TYPEHASH() external pure returns (bytes32);

//     function nonces(address owner) external view returns (uint);

//     function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

//     event Mint(address indexed sender, uint amount0, uint amount1);
//     event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
//     event Swap(
//         address indexed sender,
//         uint amount0In,
//         uint amount1In,
//         uint amount0Out,
//         uint amount1Out,
//         address indexed to
//     );
//     event Sync(uint112 reserve0, uint112 reserve1);

//     function MINIMUM_LIQUIDITY() external pure returns (uint);

//     function factory() external view returns (address);

//     function token0() external view returns (address);

//     function token1() external view returns (address);

//     function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

//     function price0CumulativeLast() external view returns (uint);

//     function price1CumulativeLast() external view returns (uint);

//     function kLast() external view returns (uint);

//     function mint(address to) external returns (uint liquidity);

//     function burn(address to) external returns (uint amount0, uint amount1);

//     function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

//     function skim(address to) external;

//     function sync() external;

//     function initialize(address, address) external;
// }

interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
interface IERC2612 {

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}
interface IAnyswapV3ERC20 is IERC20, IERC2612 {

    /// @dev Sets `value` as allowance of `spender` account over caller account's AnyswapV3ERC20 token,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on approveAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);

    /// @dev Moves `value` AnyswapV3ERC20 token from caller's account to account (`to`),
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// A transfer to `address(0)` triggers an ERC-20 withdraw matching the sent AnyswapV3ERC20 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` AnyswapV3ERC20 token.
    /// For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external returns (bool);
}

interface ITransferReceiver {
    function onTokenTransfer(address, uint, bytes calldata) external returns (bool);
}

interface IApprovalReceiver {
    function onTokenApproval(address, uint, bytes calldata) external returns (bool);
}


contract Token is IAnyswapV3ERC20, Context, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using AddrArrayLib for AddrArrayLib.Addresses;

    mapping (address => uint256) public override nonces;


    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) public _isExcluded;
    mapping(address => bool) public whitelist;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1_000_000_000 * 10 ** 6 * 10 ** 9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "TESTv10";
    string private _symbol = "TSTv10";
    uint8 public immutable decimals = 9;

    // address public donationAddress = 0xC8D7d7438eF690DdB3941B3eF10a93A3CE1798b8;
    address public holderAddress = 0x05aA6575142d44a4a7E0EA40314065C4fE9e6a57;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public charityWalletAddress = 0x2a80B9b0A833979f50c889Cb30c681E4E5b1899c;


    address public devFundWalletAddress = 0x0F7984743C3Dcc14A3fc52dEeA09e8E9b9Bf4c81;
    address public marketingFundWalletAddress = 0x80447479d3e4A1Da2abb9F79a1dA91A77F8E2271;
    address public lotteryPotWalletAddress = 0x7e8A2d57FFE236d868735cC1Cd7c6CB1116859A2;

    uint256 public _distributionFee = 10; //1%
    uint256 private _previousDistributionFee = _distributionFee;

    uint256 public _charityFee = 20; //2%
    uint256 private _previousCharityFee = _charityFee;

    uint256 public _devFundFee = 10; //1%
    uint256 private _previousDevFundFee = _devFundFee;

    uint256 public _marketingFundFee = 20; //2%
    uint256 private _previousMarketingFundFee = _marketingFundFee;

    uint256 public _lotteryPotFee = 5; //0.5%
    uint256 private _previousLotteryPotFee = _lotteryPotFee;

    uint256 public _burnFee = 10; //1%
    uint256 private _previousBurnFee = _burnFee;

    uint256 public _lotteryHolderFee = 5; //0.5%
    uint256 private _previousLotteryHolderFee = _lotteryHolderFee;

    uint256 public _liquidityFee = 10; //1%
    uint256 private _previousLiquidityFee = _liquidityFee;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    uint256 public _creationTime = now;
    uint256 public _maxTxAmount = 5_000_000 * 10 ** 6 * 10 ** 9;
    uint256 private numTokensSellToAddToLiquidity = 500_000 * 10 ** 6 * 10 ** 9;




    // mint transfer value to get a ticket
    uint256 public lotteryMinTicketValue = 1_000_000_000;
    uint256 public endtime; // when lottery period end and prize get distributed
    mapping(address => uint256) public userTicketsTs;
    bool public disableTicketsTs = false; // disable on testing env only
    bool public lottery1of1kDebug = false; // disable on testing env only

    bool public lottery1of1kEnabled = true;
    address[] private lottery1of1kUsers; // list of tickets for 1000 tx prize
    uint256 public lottery1of1kIndex; // index of last winner
    address public lottery1of1kWinner; // last random winner
    uint256 public lottery1of1kLimit = 3; // TODO: CHANGE THIS TO 1000
    uint256 public lottery1of1kMinLimit = 3;

    bool public lotteryHoldersEnabled = true;
    bool public lotteryHoldersDebug = false;
    uint256 public lotteryHoldersLimit = 3;
    uint256 public lotteryHoldersIndex = 0;
    address public lotteryHoldersWinner;
    uint256 public lotteryHolderMinBalance = 100_000_000_000; // 100

    // list of balance by users illegible for holder lottery
    AddrArrayLib.Addresses private ticketsByBalance;

    event LotteryHolderChooseOne(uint256 tickets, address winner, uint256 prize);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (address mintSupplyTo, address router) public {
        _rOwned[mintSupplyTo] = _rTotal;

        // we whitelist treasure and owner to allow pool management
        whitelist[mintSupplyTo] = true;
        whitelist[owner()] = true;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[mintSupplyTo] = true;
        _isExcludedFromFee[lotteryPotWalletAddress] = true;
        // _isExcludedFromFee[donationAddress] = true;
        _isExcludedFromFee[devFundWalletAddress] = true;
        _isExcludedFromFee[marketingFundWalletAddress] = true;
        _isExcludedFromFee[holderAddress] = true;
        _isExcludedFromFee[charityWalletAddress] = true;
        _isExcludedFromFee[burnAddress] = true;
        emit Transfer(address(0), mintSupplyTo, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
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
    function approveAndCall(address spender, uint256 value, bytes calldata data) external override returns (bool) {
        // _approve(msg.sender, spender, value);
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return IApprovalReceiver(spender).onTokenApproval(msg.sender, value, data);
    }
      /// @dev Moves `value` AnyswapV3ERC20 token from caller's account to account (`to`),
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent AnyswapV3ERC20 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` AnyswapV3ERC20 token.
    /// For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external override returns (bool) {
        require(to != address(0) || to != address(this));
        _transfer(msg.sender, to, value);

        return ITransferReceiver(to).onTokenTransfer(msg.sender, value, data);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
        (rInfo memory rr,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rr.rAmount);
        _rTotal = _rTotal.sub(rr.rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (rInfo memory rr,) = _getValues(tAmount);
            return rr.rAmount;
        } else {
            (rInfo memory rr,) = _getValues(tAmount);
            return rr.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
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
        (rInfo memory rr, tInfo memory tt) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rr.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tt.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rr.rTransferAmount);
        _takeLiquidity(tt.tLiquidity);
        _reflectFee(rr, tt);
        emit Transfer(sender, recipient, tt.tTransferAmount);
    }

    // whitelist to add liquidity
    function setWhitelist(address account, bool _status) public onlyOwner {
        whitelist[account] = _status;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setDistributionFeePercent(uint256 distributionFee) external onlyOwner() {
        _distributionFee = distributionFee;
    }

    function setCharityFeePercent(uint256 charityFee) external onlyOwner() {
        _charityFee = charityFee;
    }

    function setDevFundFeePercent(uint256 devFundFee) external onlyOwner() {
        _devFundFee = devFundFee;
    }

    function setMarketingFundFeePercent(uint256 marketingFundFee) external onlyOwner() {
        _marketingFundFee = marketingFundFee;
    }

    function setLotteryPotFeePercent(uint256 lotteryPotFee) external onlyOwner() {
        _lotteryPotFee = lotteryPotFee;
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
        _burnFee = burnFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10 ** 2
        );
    }

    event SwapAndLiquifyEnabledUpdated(bool _enabled);
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    event feeTransfer(address indexed from, address indexed to, uint256 value);

    function _reflectFee(rInfo memory rr, tInfo memory tt) private {
        _rTotal = _rTotal.sub(rr.rDistributionFee);
        _tFeeTotal = _tFeeTotal.add(tt.tDistributionFee).add(tt.tCharityFee).add(tt.tDevFundFee)
        .add(tt.tMarketingFundFee).add(tt.tLotteryPotFee).add(tt.tBurn).add(tt.tHolderFee);

        _rOwned[holderAddress] = _rOwned[holderAddress].add(rr.rHolderFee);
        _rOwned[charityWalletAddress] = _rOwned[charityWalletAddress].add(rr.rCharityFee);
        _rOwned[devFundWalletAddress] = _rOwned[devFundWalletAddress].add(rr.rDevFundFee);
        _rOwned[marketingFundWalletAddress] = _rOwned[marketingFundWalletAddress].add(rr.rMarketingFundFee);
        _rOwned[lotteryPotWalletAddress] = _rOwned[lotteryPotWalletAddress].add(rr.rLotteryPotFee);
        _rOwned[burnAddress] = _rOwned[burnAddress].add(rr.rBurn);

        if (tt.tHolderFee > 0)
            emit feeTransfer(msg.sender, holderAddress, tt.tHolderFee);

        if (tt.tCharityFee > 0)
            emit feeTransfer(msg.sender, charityWalletAddress, tt.tCharityFee);

        if (tt.tDevFundFee > 0)
            emit feeTransfer(msg.sender, devFundWalletAddress, tt.tDevFundFee);

        if (tt.tMarketingFundFee > 0)
            emit feeTransfer(msg.sender, marketingFundWalletAddress, tt.tMarketingFundFee);

        if (tt.tLotteryPotFee > 0)
            emit feeTransfer(msg.sender, lotteryPotWalletAddress, tt.tLotteryPotFee);

        if (tt.tBurn > 0)
            emit feeTransfer(msg.sender, burnAddress, tt.tBurn);

    }

    struct tInfo {
        uint256 tTransferAmount;
        uint256 tDistributionFee;
        uint256 tLiquidity;
        uint256 tCharityFee;
        uint256 tDevFundFee;
        uint256 tMarketingFundFee;
        uint256 tLotteryPotFee;
        uint256 tBurn;
        uint256 tHolderFee;
    }

    struct rInfo {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rDistributionFee;
        uint256 rCharityFee;
        uint256 rDevFundFee;
        uint256 rMarketingFundFee;
        uint256 rLotteryPotFee;
        uint256 rBurn;
        uint256 rLiquidity;
        uint256 rHolderFee;
    }

    function _getValues(uint256 tAmount) private view returns (rInfo memory rr, tInfo memory tt) {
        tt = _getTValues(tAmount);
        rr = _getRValues(tAmount, tt.tDistributionFee, tt.tCharityFee, tt.tDevFundFee, tt.tMarketingFundFee,
            tt.tLotteryPotFee, tt.tBurn, tt.tHolderFee, tt.tLiquidity, _getRate());
        return (rr, tt);
    }

    function _getTValues(uint256 tAmount) private view returns (tInfo memory tt) {
        tt.tDistributionFee = calculateDistributionFee(tAmount);
        tt.tCharityFee = calculateCharityFee(tAmount);
        tt.tDevFundFee = calculateDevFundFee(tAmount);
        tt.tMarketingFundFee = calculateMarketingFundFee(tAmount);
        tt.tLotteryPotFee = calculateLotteryPotFee(tAmount);
        tt.tBurn = calculateBurnFee(tAmount);
        tt.tHolderFee = calculateHolderFee(tAmount);
        tt.tLiquidity = calculateLiquidityFee(tAmount);
        uint totalFee = tt.tDistributionFee.add(tt.tCharityFee).add(tt.tDevFundFee);
        totalFee = totalFee.add(tt.tMarketingFundFee).add(tt.tLotteryPotFee).add(tt.tBurn);
        totalFee = totalFee.add(tt.tLiquidity).add(tt.tHolderFee);
        tt.tTransferAmount = tAmount.sub(totalFee);
        return tt;
    }

    function _getRValues(uint256 tAmount, uint256 tDistributionFee, uint256 tCharityFee, uint256 tDevFundFee,
        uint256 tMarketingFundFee, uint256 tLotteryPotFee, uint256 tBurn, uint256 rHolderFee, uint256 tLiquidity,
        uint256 currentRate) private pure returns (rInfo memory rr) {
        rr.rAmount = tAmount.mul(currentRate);
        rr.rDistributionFee = tDistributionFee.mul(currentRate);
        rr.rCharityFee = tCharityFee.mul(currentRate);
        rr.rDevFundFee = tDevFundFee.mul(currentRate);
        rr.rMarketingFundFee = tMarketingFundFee.mul(currentRate);
        rr.rLotteryPotFee = tLotteryPotFee.mul(currentRate);
        rr.rBurn = tBurn.mul(currentRate);
        rr.rLiquidity = tLiquidity.mul(currentRate);
        rr.rHolderFee = rHolderFee.mul(currentRate);
        uint totalFee = rr.rDistributionFee.add(rr.rCharityFee).add(rr.rDevFundFee).add(rr.rMarketingFundFee);
        totalFee = totalFee.add(rr.rLotteryPotFee).add(rr.rBurn).add(rr.rLiquidity).add(rr.rHolderFee);
        rr.rTransferAmount = rr.rAmount.sub(totalFee);
        return rr;
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

    function calculateDistributionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_distributionFee).div(1000);
    }

    function calculateCharityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_charityFee).div(1000);
    }

    function calculateDevFundFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_devFundFee).div(1000);
    }

    function calculateMarketingFundFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFundFee).div(1000);
    }

    function calculateLotteryPotFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_lotteryPotFee).div(1000);
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(1000);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(1000);
    }

    function calculateHolderFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_lotteryHolderFee).div(1000);
    }

    function removeAllFee() private {
        if (_distributionFee == 0 && _liquidityFee == 0) return;

        _previousDistributionFee = _distributionFee;
        _previousLiquidityFee = _liquidityFee;

        _previousCharityFee = _charityFee;
        _previousDevFundFee = _devFundFee;
        _previousMarketingFundFee = _marketingFundFee;
        _previousLotteryPotFee = _lotteryPotFee;
        _previousBurnFee = _burnFee;
        _previousLotteryHolderFee = _lotteryHolderFee;

        _distributionFee = 0;
        _charityFee = 0;
        _devFundFee = 0;
        _marketingFundFee = 0;
        _lotteryPotFee = 0;
        _burnFee = 0;
        _liquidityFee = 0;
        _lotteryHolderFee = 0;
    }

    function restoreAllFee() private {
        _distributionFee = _previousDistributionFee;
        _charityFee = _previousCharityFee;
        _devFundFee = _previousDevFundFee;
        _marketingFundFee = _previousMarketingFundFee;
        _lotteryPotFee = _previousLotteryPotFee;
        _burnFee = _previousBurnFee;
        _liquidityFee = _previousLiquidityFee;
        _lotteryHolderFee = _previousLotteryHolderFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _antiAbuse(address from, address to, uint256 amount) private view {

        if (from == owner() || to == owner())
        //  if owner we just return or we can't add liquidity
            return;

        require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        uint256 lastCreationTime;
        uint256 allowedAmount;

        (, uint256 tSupply) = _getCurrentSupply();
        uint256 lastUserBalance = balanceOf(to) + (amount * (100 - getTotalFees()) / 100);

        // bot \ whales prevention
        if (now <= (_creationTime.add(1 days))) {
            lastCreationTime = _creationTime.add(1 days);
            allowedAmount = tSupply.div(10000).mul(10);
            require(lastUserBalance < allowedAmount, "Transfer amount exceeds the max for day 1");
        } else if (now <= (_creationTime.add(2 days))) {
            lastCreationTime = _creationTime.add(2 days);
            allowedAmount = tSupply.div(10000).mul(20);
            require(lastUserBalance < allowedAmount, "Transfer amount exceeds the max for day 2");
        } else if (now <= (_creationTime.add(3 days))) {
            lastCreationTime = _creationTime.add(3 days);
            allowedAmount = tSupply.div(10000).mul(30);
            require(lastUserBalance < allowedAmount, "Transfer amount exceeds the max for day 3");
        }
    }

    event WhiteListTransfer(address from, address to, uint256 amount);

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 contractTokenBalance = balanceOf(address(this));
        // whitelist to allow treasure to add liquidity:
        if (whitelist[from] || whitelist[to]) {
            emit WhiteListTransfer(from, to, amount);
        } else {
            _antiAbuse(from, to, amount);
            // is the token balance of this contract address over the min number of
            // tokens that we need to initiate a swap + liquidity lock?
            // also, don't get caught in a circular liquidity event.
            // also, don't swap & liquify if sender is uniswap pair.

            if (contractTokenBalance >= _maxTxAmount) {
                contractTokenBalance = _maxTxAmount;
            }
        }

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);

        // process lottery if user is paying fee
        lotteryOnTransfer(from, to, amount);
    }

    event SwapAndLiquify(uint256 half, uint256 newBalance, uint256 otherHalf);
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half);
        // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {

        if (!takeFee) {
            removeAllFee();
        }

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
        (rInfo memory rr, tInfo memory tt) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rr.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rr.rTransferAmount);
        _takeLiquidity(tt.tLiquidity);
        _reflectFee(rr, tt);

        emit Transfer(sender, recipient, tt.tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (rInfo memory rr, tInfo memory tt) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rr.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tt.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rr.rTransferAmount);
        _takeLiquidity(tt.tLiquidity);
        _reflectFee(rr, tt);
        emit Transfer(sender, recipient, tt.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (rInfo memory rr, tInfo memory tt) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rr.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rr.rTransferAmount);
        _takeLiquidity(tt.tLiquidity);
        _reflectFee(rr, tt);
        emit Transfer(sender, recipient, tt.tTransferAmount);
    }

    function getTime() public view returns (uint256){
        return block.timestamp;
    }

    function getTotalFees() internal view returns (uint256) {
        return _charityFee + _liquidityFee + _burnFee + _lotteryPotFee + _marketingFundFee + _devFundFee;
    }

    function getPrizeForEach1k() public view returns (uint256) {
        return balanceOf(lotteryPotWalletAddress);
    }

    function getPrizeForHolders() public view returns (uint256) {
        return balanceOf(holderAddress);
    }

    // view to get illegible holders lottery
    function getTicketsByBalance() public view returns (address[] memory){
        return ticketsByBalance.getAllAddresses();
    }

    function setLotteryHoldersLimit(uint256 val) public onlyOwner {
        lotteryHoldersLimit = val;
    }
    function setDisableTicketsTs(bool status) public onlyOwner {
        disableTicketsTs = status;
    }

    function setLotteryHolderMinBalance(uint256 val) public onlyOwner {
        lotteryHolderMinBalance = val;
    }
    function setLotteryHoldersEnabled(bool val) public onlyOwner {
        lotteryHoldersEnabled = val;
    }
    function loterryUserTickets(address _user) public view returns (uint256[] memory){
        uint[] memory my = new uint256[](lottery1of1kUsers.length);
        uint count;
        for (uint256 i = 0; i < lottery1of1kUsers.length; i++) {
            if (lottery1of1kUsers[i] == _user) {
                my[count++] = i;
            }
        }
        return my;
    }

    function lotteryTotalTicket() public view returns (uint256){
        return lottery1of1kUsers.length;
    }

    // process both lottery

    function lotteryOnTransfer(address user, address to, uint256 value) internal {

        if( lottery1of1kEnabled ){
            lottery1of1k(user, to, value);
        }

        if( lotteryHoldersEnabled ){
            lotteryHolders(user, to);
        }
    }


    // 0.5% for holders of certain amount of tokens for random chance every 1000 tx
    // lottery that get triggered on N number of TX
    event lottery1of1kTicket(address user, address to, uint256 value, uint256 lottery1of1kIndex, uint256 lottery1of1kUsers);
    event LotteryTriggerEveryNtx(uint256 ticket, address winner, uint256 prize);
    function setLottery1of1kLimit(uint256 val) public onlyOwner {
        lottery1of1kLimit = val;
    }
    function setLottery1of1kEnabled(bool val) public onlyOwner {
        lottery1of1kEnabled = val;
    }
    function setLottery1of1kDebug(bool val) public onlyOwner {
        lottery1of1kDebug = val;
    }
    function setLotteryHoldersDebug(bool val) public onlyOwner {
        lotteryHoldersDebug = val;
    }
    function lottery1of1k(address user, address to, uint256 value) internal {
        uint256 prize = getPrizeForEach1k();
        if (value >= lotteryMinTicketValue && to == lotteryPotWalletAddress) {
            //if(lottery1of1kDebug) console.log("- lottery1of1k> donation=%s value=%d lottery1of1kLimit=%d", lotteryPotWalletAddress, value, lottery1of1kLimit);
            uint256 uts = userTicketsTs[user];
            if (disableTicketsTs == false || uts == 0 || uts.add(3600) <= block.timestamp) {
                lottery1of1kIndex++;
                lottery1of1kUsers.push(user);
                userTicketsTs[user] = block.timestamp;
                emit lottery1of1kTicket(user, to, value, lottery1of1kIndex, lottery1of1kUsers.length);
                //if(lottery1of1kDebug) console.log("\tlottery1of1k> added index=%d length=%d prize=%d", lottery1of1kIndex, lottery1of1kUsers.length, prize);
            }
        }
        if (prize > 0 && lottery1of1kIndex >= lottery1of1kLimit) {
            uint256 _mod = lottery1of1kUsers.length;
            if (lottery1of1kUsers.length < lottery1of1kMinLimit) return;
            uint256 _randomNumber;
            bytes32 _structHash = keccak256(abi.encode(msg.sender, block.difficulty, gasleft(), prize));
            _randomNumber = uint256(_structHash);
            assembly {_randomNumber := mod(_randomNumber, _mod)}
            lottery1of1kWinner = lottery1of1kUsers[_randomNumber];
            emit LotteryTriggerEveryNtx(_randomNumber, lottery1of1kWinner, prize);
            _tokenTransfer(lotteryPotWalletAddress, lottery1of1kWinner, prize, false);
//            if(lottery1of1kDebug){
//                console.log("\t\tlottery1of1k> TRIGGER _mod=%d rnd=%d prize=%d", _mod, _randomNumber, prize);
//                console.log("\t\tlottery1of1k> TRIGGER winner=%s", lottery1of1kWinner);
//            }
            lottery1of1kIndex = 0;
            delete lottery1of1kUsers;
        }
    }

    // add and remove users according to their balance from holder lottery
    //event LotteryAddToHolder(address from, bool status);
    function addUserToBalanceLottery(address user) internal {
        if (!_isExcludedFromFee[user] && !_isExcluded[user]) {
            uint256 balance = balanceOf(user);
            bool exists = ticketsByBalance.exists(user);
            // emit LotteryAddToHolder(user, exists);
            if (balance >= lotteryHolderMinBalance && !exists) {
                ticketsByBalance.pushAddress(user, false);
//                if(lotteryHoldersDebug)
//                    console.log("ADD HOLDERS=%d PRIZE=%d", ticketsByBalance.size(), getPrizeForHolders());
            } else if (balance < lotteryHolderMinBalance && exists) {
                ticketsByBalance.removeAddress(user);
//                if(lotteryHoldersDebug)
//                    console.log("REMOVE HOLDERS=%d PRIZE=%d", ticketsByBalance.size(), getPrizeForHolders());
            }
        }
    }

    function lotteryHolders(address user, address to) internal {
        lotteryHoldersIndex++;
        uint256 prize = getPrizeForHolders();
        uint256 holders = ticketsByBalance.size();
        addUserToBalanceLottery(user);
        addUserToBalanceLottery(to);
//        if(lotteryHoldersDebug){
//            console.log("\tHOLDERS=%d PRIZE=%d, INDEX=%d", ticketsByBalance.size(), prize, lotteryHoldersIndex );
//        }
        if (prize > 0 && lotteryHoldersIndex >= lotteryHoldersLimit) {
            uint256 _mod = holders - 1;
            uint256 _randomNumber;
            bytes32 _structHash = keccak256(abi.encode(msg.sender, block.difficulty, gasleft()));
            _randomNumber = uint256(_structHash);
            assembly {_randomNumber := mod(_randomNumber, _mod)}
            lotteryHoldersWinner = ticketsByBalance.getAddressAtIndex(_randomNumber);
            emit LotteryHolderChooseOne(ticketsByBalance.size(), lotteryHoldersWinner, prize);
            _tokenTransfer(holderAddress, lotteryHoldersWinner, prize, false);
//            if(lotteryHoldersDebug){
//                console.log("\tprize=%d index=%d", prize, lotteryHoldersIndex);
//                console.log("\tlotteryHoldersWinner=%s rnd=", lotteryHoldersWinner, _randomNumber);
//            }
            lotteryHoldersIndex = 0;
        }
    }

}