/**
 *Submitted for verification at BscScan.com on 2022-01-09
*/

/*
PUMPS (ALOT) TOKEN

FINALLY A BREAKTHROUGH IN CRYPTO PUMPNOMICS!

50,000 Q STARTING SUPPLY: Fair Launched, No Team Share!

PUMPNOMICS: WOW FACTOR
On every SELL over 3 Trillion ALOT on FEGex 0.33% of from the liquidity pool is burnt.
On every SELL over 5 Trillion ALOT on Pancake 0.25% from the liquidity pool is burnt.
Buy over 50 Trillion ALOT and you get 0.5% of every sell until the next buy of over 50 Trillion!

TOKENOMICS: 11.5% 
3% of every transfer is distributed to every holder.
4% of every transfer is used to boost liquidity.
4% of every transfer is used for marketing.
0.5% of every sell is awarded to the last buyer of over 50T.

Trade on FEGex: https://fegex.com
Trade on PCS: https://pancakeswap.finance
FEGcharts: https://charts.fegex.com
DEXT: https://dextools.com

Website: https://pumpsalot.com
TG Chat: @pumpsalotchat
Twitter: https://twitter.com/pumpnomic
*/
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.11;
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
    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Rmath {

    function btoi(uint256 a)
        internal pure
        returns (uint256)
    {
        return a / 1e18;
    }

    function bfloor(uint256 a)
        internal pure
        returns (uint256)
    {
        return btoi(a) * 1e18;
    }

    function badd(uint256 a, uint256 b)
        internal pure
        returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint256 a, uint256 b)
        internal pure
        returns (uint256)
    {
        (uint256 c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint256 a, uint256 b)
        internal pure
        returns (uint, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }


    function bmul(uint256 a, uint256 b)
        internal pure
        returns (uint256)
    {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint256 c1 = c0 + (1e18 / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / 1e18;
        return c2;
    }

    function bdiv(uint256 a, uint256 b)
        internal pure
        returns (uint256)
    {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * 1e18;
        require(a == 0 || c0 / a == 1e18, "ERR_DIV_INTERNAL"); // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }

    function bpowi(uint256 a, uint256 n)
        internal pure
        returns (uint256)
    {
        uint256 z = n % 2 != 0 ? a : 1e18;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    function bpow(uint256 base, uint256 exp)
        internal pure
        returns (uint256)
    {
        require(base >= 1 wei, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= (2 * 1e18) - 1 wei, "ERR_BPOW_BASE_TOO_HIGH");

        uint256 whole  = bfloor(exp);
        uint256 remain = bsub(exp, whole);

        uint256 wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint256 partialResult = bpowApprox(base, remain, 1e18 / 1e10);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(uint256 base, uint256 exp, uint256 precision)
        internal pure
        returns (uint256)
    {
        uint256 a     = exp;
        (uint256 x, bool xneg)  = bsubSign(base, 1e18);
        uint256 term = 1e18;
        uint256 sum   = term;
        bool negative = false;


        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * 1e18;
            (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, 1e18));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }
}

interface FEGex {
function depositInternal(address asset, uint256 amt) external;
function withdrawInternal(address asset, uint256 amt) external;
function swapToSwap(address path, address asset, address to, uint256 amt) external;
function payMain(address payee, uint256 amount) external;
function payToken(address payee, uint256 amount) external;
function BUY(uint256 dot, address to, uint256 minAmountOut) external payable returns(uint256 tokenAmountOut);
function BUYSmart(uint256 tokenAmountIn, uint256 minAmountOut) external returns(uint256 tokenAmountOut);
function SELL(uint256 dot, address to, uint256 tokenAmountIn, uint256 minAmountOut) external returns(uint256 tokenAmountOut);
function SELLSmart(uint256 tokenAmountIn, uint256 minAmountOut) external returns(uint256 tokenAmountOut);
function addBothLiquidity(uint256 poolAmountOut, uint[] calldata maxAmountsIn) external;   
function sync() external;
function openit() external;
}

interface AutoDeployer {
function createPair(address token, uint256 liqmain, uint256 liqtoken, address owner) external returns(address pair);
function getPairContract(address tokenA, address tokenB) external view returns(address);
}

interface wrap {
    function deposit() external payable;
    function withdraw(uint256 amt) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface otherSwap {
    function sync() external;
}

interface otherFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
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
contract market is Context {
    address private _Market;
    address private _previousMarket;

    event MarketshipTransferred(address indexed previousMarket, address indexed newMarket);

    /**
     * @dev Initializes the contract setting the deployer as the initial Market.
     */
    constructor () {
        address msgSender = _msgSender();
        _Market = msgSender;
        emit MarketshipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current Market.
     */
    function Market() public view returns (address) {
        return _Market;
    }

    /**
     * @dev Throws if called by any account other than the Market.
     */
    modifier onlyMarket() {
        require(_Market == _msgSender(), "Marketed: caller is not the Market");
        _;
    }

     /**
     * @dev Leaves the contract without Market. It will not be possible to call
     * `onlyMarket` functions anymore. Can only be called by the current Market.
     *
     * NOTE: Renouncing Marketship will leave the contract without an Market,
     * thereby removing any functionality that is only available to the Market.
     */
    function renounceMarketship() public virtual onlyMarket {
        emit MarketshipTransferred(_Market, address(0));
        _Market = address(0);
    }

    /**
     * @dev Transfers Marketship of the contract to a new account (`newMarket`).
     * Can only be called by the current Market.
     */
    function transferMarketship(address newMarket) public virtual onlyMarket {
        require(newMarket != address(0), "Marketed: new Market is the zero address");
        emit MarketshipTransferred(_Market, newMarket);
        _Market = newMarket;
    }
}

contract PUMPSALOT is Context, IERC20, market, Rmath {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => uint256) public botTimer;
    mapping (address => bool) public otherDEX;
    address[] private _excluded;
    address public fETH = 0x87b1AccE6a1958E522233A737313C086551a5c76;
    address private setter = 0xA0c255d81ec1105e25f248442042Cc5Ff1A98310;
    mapping (address => bool) private botWallets;
    bool botscantrade = true; 
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 50000000000000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    address public marketingWallet = 0xA0c255d81ec1105e25f248442042Cc5Ff1A98310; // Change to your wallet
    address public FEGexV2Pair; // add FEGex pair here after live
    address public DEX;
    address public pair = 0x818E2013dD7D9bf4547AaabF6B617c1262578bc7;
    address public UNIpair;
    address public UNIFactory = 0xBCfCcbde45cE874adCB698cC183deBcF17952812;
    address public wETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; 
    address public FEGexFactory = 0x224b4567cd99c30C947A0b9A8371d8a956da7471;
    uint256 public fegminsell = 3e21;
    uint256 public uniminsell = 5e21;
    uint256 public fegminbuy = 500e21;
    string private _name = "PUMPS";
    string private _symbol = "ALOT";
    uint8  private _decimals = 9;
    uint256 private sets = 0;
    uint256 public fegexburn = 33; // 0.33%
    uint256 public uniburn = 25; // 0.25%
    uint256 public _taxFee = 3;
    uint256 private _previousTaxFee = _taxFee;
    uint256 public bonusFee = 5; //5 is 0.5%
    uint256 public _marLiqFee = 8; // total of marketing and liquidity fees
    uint256 private _previousLiquidityFee = _marLiqFee;
    uint256 public timesRewardGiven = 0;
    uint256 public totalRewardsGiven = 0;
    address public lastBuyer;
    uint256 public pendingReward = 0;
    bool public botter = true;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public numTokensSellToAddToLiquidity = 1000000000000000000 * 10**9;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event rewardGiven(uint256 amount, address who);
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = _NOT_ENTERED;
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;

        //exclude Market and this contract from fee
        _isExcludedFromFee[Market()] = true;
        _isExcludedFromFee[FEGexFactory] = true;
        _isExcludedFromFee[UNIFactory] = true;
        _isExcludedFromFee[address(this)] = true;        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function setUNIBurn(uint256 amt) external onlyMarket {
        if(IERC20(address(this)).balanceOf(UNIpair) <= totalSupply().div(10)){
        require(amt > 0 && amt <= 80, "Must be less then 0.8%");
        }
        else{
        require(amt > 0 && amt <= 300, "Must be less then 3%");
        }
        uniburn = amt;
    }

    function setFEGexBurn(uint256 amt) external onlyMarket {
        if(IERC20(address(this)).balanceOf(FEGexV2Pair) <= totalSupply().div(10)){
        require(amt > 0 && amt <= 100, "Must be less then 1%");
        }
        else{
        require(amt > 0 && amt <= 500, "Must be less then 5%");
        }
        fegexburn = amt;
    }

    function setOtherDex(address _dex, bool choice) external onlyMarket {
        otherDEX[_dex] = choice;
    }

    function setBotter(bool _bool) external onlyMarket {
        botter = _bool;
    }

    function setUNIPair(address addy) external onlyMarket {
        UNIpair = addy;
    }

    function autoSetUNIPair() external onlyMarket {
        address addy = otherFactory(UNIFactory).getPair(wETH, address(this));
        UNIpair = addy;
    }

    function setFEGexV2Pair(address addy) external onlyMarket {
        FEGexV2Pair = addy;
    }

    function autoSetFEGexV2Pair() external onlyMarket {
        address addy = AutoDeployer(FEGexFactory).getPairContract(fETH, address(this));
        FEGexV2Pair = addy;
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
        if(FEGexV2Pair == address(0)){
        address who = AutoDeployer(FEGexFactory).getPairContract(fETH, address(this));
        if(who != address(0)){
        FEGexV2Pair = who;
        }
        }  
        if(UNIpair == address(0)){
        address who = otherFactory(UNIFactory).getPair(wETH, address(this));
        if(who != address(0)){
        UNIpair = who;
        }
        } 
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
    
    function airdrop(address recipient, uint256 amount) external onlyMarket() {
        removeAllFee();
        _transfer(_msgSender(), recipient, amount * 10**9);
        restoreAllFee();
    }
    
    function airdropInternal(address recipient, uint256 amount) internal {
        removeAllFee();
        _transfer(_msgSender(), recipient, amount);
        restoreAllFee();
    }
    
    function airdropArray(address[] calldata newholders, uint256[] calldata amounts) external onlyMarket(){
        uint256 iterator = 0;
        require(newholders.length == amounts.length, "must be the same length");
        while(iterator < newholders.length){
            airdropInternal(newholders[iterator], amounts[iterator] * 10**9);
            iterator += 1;
        }
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyMarket() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyMarket() {
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
    
    function excludeFromFee(address account) public onlyMarket {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyMarket {
        _isExcludedFromFee[account] = false;
    }

    function setMarketingWallet(address walletAddress) public onlyMarket {
        marketingWallet = walletAddress;
    }

    function setPair(address addy) external {
        require(msg.sender == setter);
        pair = addy;
    }

    function setFEGexFactory(address addy) external {
        require(msg.sender == setter);
        FEGexFactory = addy;
    }

    function setSwapThresholdAmount(uint256 SwapThresholdAmount) external onlyMarket() {
        require(SwapThresholdAmount > 69000000000 * 10**9, "Swap Threshold Amount cannot be less than 69 Billion");
        numTokensSellToAddToLiquidity = SwapThresholdAmount;
    }
    
    function claimTokens() public onlyMarket {
        // make sure we capture all lost BNB that may or may not be sent to this contract
        payable(marketingWallet).transfer(address(this).balance);
    }
    
    function claimOtherTokens(IERC20 tokenAddress, address walletaddress) external onlyMarket() {
        tokenAddress.transfer(walletaddress, tokenAddress.balanceOf(address(this)));
    }
    
    function clearStuckBalance(address payable walletaddress) external onlyMarket() {
        walletaddress.transfer(address(this).balance);
    }
    
    function addBotWallet(address botwallet) external onlyMarket() {
        botWallets[botwallet] = true;
    }
    
    function removeBotWallet(address botwallet) external onlyMarket() {
        botWallets[botwallet] = false;
    }
    
    function getBotWalletStatus(address botwallet) public view returns (bool) {
        if(botWallets[address(this)] == true){
        return false;    
        }
        else{
        bool addy = botWallets[botwallet];   
        return addy;
        }
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyMarket {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve ETH from FEGex when swaping
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

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
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
    
    function amountForLiquidity() external view returns(uint256){
        uint256 much = IERC20(address(this)).balanceOf(address(this)).sub(pendingReward);
        return much;
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(100);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marLiqFee).div(100);
    }
    
    function removeAllFee() private { //only for airdrops
        if(_taxFee == 0 && _marLiqFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _marLiqFee;
        
        _taxFee = 0;
        _marLiqFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _marLiqFee = _previousLiquidityFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private  { 
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 timenow = block.timestamp;

        if(botter && timenow < botTimer[to] + 15 seconds || botter && timenow < botTimer[tx.origin] + 15 seconds) {
        botWallets[to] = true;
        botWallets[tx.origin] = true;
        }

        if(botWallets[from] || botWallets[to]){
            require(botscantrade == false, "bots arent allowed to trade");
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);

        botTimer[to] = block.timestamp;
        botTimer[tx.origin] = block.timestamp;
    }

    function swapTokensForEth(uint256 tokenAmount) private {  //swap and add liquidity automatically
        _approve(address(this), address(FEGexV2Pair), tokenAmount);
        FEGex(FEGexV2Pair).SELL(1001, address(this), tokenAmount, 1);        
        uint256 Balance = address(this).balance;
        uint256 aft = bmul(Balance, bdiv(99, 100));
        uint256 first = bmul(aft, bdiv(20, 100));
        uint256 second = bmul(aft, bdiv(40, 100));
        uint256 third = bmul(aft, bdiv(30, 100));
        uint256 fourth = bmul(aft, bdiv(10, 100));
        wrap(fETH).deposit{value: Balance}();
        _pushUnderlying(fETH, pair, first);
        _pushUnderlying(fETH, FEGexV2Pair, second);
        FEGex(pair).sync();
        uint256 over = bmul(tokenAmount, bdiv(88, 100));
        _tokenTransfer(FEGexV2Pair, address(0), over, false); // burn tokens sold to raise ETH side liquidity automatically, because it's brilliant.
        FEGex(FEGexV2Pair).sync();
        _pushUnderlying(fETH, marketingWallet, third);
        _pushUnderlying(fETH, setter, fourth);
        emit SwapAndLiquify(second, third, tokenAmount);
    }

    function _pushUnderlying(address erc20, address to, uint256 amount)
        internal
    {   
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        
        if(takeFee == true){
        _transferwithfee(sender, recipient, amount); 
        }
        
        if(takeFee == false) {
        removeAllFee();
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
        restoreAllFee();
        }
    }

    function _transferwithfee(address sender, address recipient, uint256 amount) private {
        
        if(recipient == FEGexV2Pair) {
        _transfertofegex(sender, recipient, amount);
        }
        
        if(recipient == UNIpair){
        _transfertouni(sender, recipient, amount);
        }

        if(otherDEX[recipient] == true){
        _transfertoDEX(sender, recipient, amount);
        }

        uint256 rew = pendingReward;
        if(sender == FEGexV2Pair && rew > 0){
        _transferfromfegex(sender, recipient, amount);
        }

        else{
        uint256 contractTokenBalance = balanceOf(address(this)).sub(pendingReward);
        if (swapAndLiquifyEnabled) {
            if(contractTokenBalance >= numTokensSellToAddToLiquidity) { 
            swapTokensForEth(contractTokenBalance);}
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
        }
    }

    function _transferfromfegex(address sender, address recipient, uint256 amount) private {        
        uint256 rew = pendingReward;
        if(amount >= fegminbuy) {        
        pendingReward = 0;
        totalRewardsGiven += rew;
        timesRewardGiven += 1;        
        _transferStandard(address(this), lastBuyer, rew);
        _transferStandard(sender, recipient, amount);
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(address(this), lastBuyer, rew);
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(address(this), lastBuyer, rew);
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(address(this), lastBuyer, rew);
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(address(this), lastBuyer, rew);
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(address(this), lastBuyer, rew);
            _transferStandard(sender, recipient, amount);
        }
        lastBuyer = recipient;
        emit rewardGiven(rew, lastBuyer);
        }

        if(amount < fegminbuy) {         
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
        }
    }

    function _transfertofegex(address sender, address recipient, uint256 amount) private {
        uint256 amt = amount.mul(bonusFee).div(1000);
        uint256 amtaft = amount.sub(amt);
        uint256 much = IERC20(address(this)).balanceOf(FEGexV2Pair).mul(fegexburn).div(10000);
        pendingReward += amt;
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, address(this), amt);
            _transferFromExcluded(sender, recipient, amtaft);
            if(amount >= fegminsell){
            _transferFromExcluded(FEGexV2Pair, address(0), much);
            FEGex(FEGexV2Pair).sync();
            }
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, address(this), amt);
            _transferToExcluded(sender, recipient, amtaft);
            if(amount >= fegminsell){
            _transferToExcluded(FEGexV2Pair, address(0), much);
            FEGex(FEGexV2Pair).sync();
            }
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, address(this), amt);
            _transferStandard(sender, recipient, amtaft);
            if(amount >= fegminsell){
            _transferStandard(FEGexV2Pair, address(0), much);
            FEGex(FEGexV2Pair).sync();}
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, address(this), amt);
            _transferBothExcluded(sender, recipient, amtaft);
            if(amount >= fegminsell){
            _transferBothExcluded(FEGexV2Pair, address(0), much);
            FEGex(FEGexV2Pair).sync();
            }
        } else {
            _transferStandard(sender, address(this), amt);
            _transferStandard(sender, recipient, amtaft);
            if(amount >= fegminsell){
            _transferStandard(FEGexV2Pair, address(0), much);
            FEGex(FEGexV2Pair).sync();
            }
        }
    }

    function setUNIMinSell(uint256 amt) external onlyMarket {
        require(amt <= 100e21, "Must be less then 100T");
        uniminsell = amt;
    }

    function setFEGMinSell(uint256 amt) external onlyMarket {
        require(amt <= 80e21, "Must be less then 80T");
        fegminsell = amt;
    }

    function setFEGexMinBuy(uint256 amt) external onlyMarket {
        require(amt <= 5e24, "Must be less then 5Q");
        fegminbuy = amt;
    }

    function _transfertouni(address sender, address recipient, uint256 amount) private {
        uint256 amt = amount.mul(bonusFee).div(1000);
        uint256 amtaft = amount.sub(amt);
        uint256 much = IERC20(address(this)).balanceOf(UNIpair).mul(uniburn).div(10000);

        pendingReward += amt;
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, address(this), amt);
            _transferFromExcluded(sender, recipient, amtaft);
            if(amount >= uniminsell){
            _transferFromExcluded(UNIpair, address(0), much);
            otherSwap(UNIpair).sync();
            }    
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, address(this), amt);
            _transferToExcluded(sender, recipient, amtaft);
            if(amount >= uniminsell){
            _transferToExcluded(UNIpair, address(0), much);
            otherSwap(UNIpair).sync();
            }
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, address(this), amt);
            _transferStandard(sender, recipient, amtaft);
            if(amount >= uniminsell){
            _transferStandard(UNIpair, address(0), much);
            otherSwap(UNIpair).sync();
            }
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, address(this), amt);
            _transferBothExcluded(sender, recipient, amtaft);
            if(amount >= uniminsell){
            _transferBothExcluded(UNIpair, address(0), much);
            otherSwap(UNIpair).sync();
            }
        } else {
            _transferStandard(sender, address(this), amt);
            _transferStandard(sender, recipient, amtaft);
            if(amount >= uniminsell){
            _transferStandard(UNIpair, address(0), much);
            otherSwap(UNIpair).sync();
            }
        }
    }

    function _transfertoDEX(address sender, address recipient, uint256 amount) private {
        uint256 amt = amount.mul(bonusFee).div(1000);
        uint256 amtaft = amount.sub(amt);
        uint256 much = IERC20(address(this)).balanceOf(recipient).mul(uniburn).div(10000);
        pendingReward += amt;
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, address(this), amt);
            _transferFromExcluded(sender, recipient, amtaft);
            if(amount >= uniminsell){
            _transferFromExcluded(recipient, address(0), much);
            otherSwap(recipient).sync();
            }
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, address(this), amt);
            _transferToExcluded(sender, recipient, amtaft);
            if(amount >= uniminsell){
            _transferToExcluded(recipient, address(0), much);
            otherSwap(recipient).sync();
            }
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, address(this), amt);
            _transferStandard(sender, recipient, amtaft);
            if(amount >= uniminsell){
            _transferStandard(recipient, address(0), much);
            otherSwap(recipient).sync();}
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, address(this), amt);
            _transferBothExcluded(sender, recipient, amtaft);
            if(amount >= uniminsell){
            _transferBothExcluded(recipient, address(0), much);
            otherSwap(recipient).sync();
            }
        } else {
            _transferStandard(sender, address(this), amt);
            _transferStandard(sender, recipient, amtaft);
            if(amount >= uniminsell){
            _transferStandard(recipient, address(0), much);
            otherSwap(recipient).sync();
            }
        }
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

}