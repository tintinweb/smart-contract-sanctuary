/**
 *Submitted for verification at Etherscan.io on 2020-07-02
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
        (bool success, ) = recipient.call.value(amount)("");
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
        (bool success, bytes memory returndata) = target.call.value(weiValue)(data);
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
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface CTokenInterface {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);

    function borrowBalanceCurrent(address) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function borrow(uint) external returns (uint);
    function underlying() external view returns (address);
    function borrowBalanceStored(address) external view returns (uint);
}

interface CETHInterface {
    function mint() external payable;
    function repayBorrow() external payable;
}

interface ComptrollerInterface {
    function getAssetsIn(address account) external view returns (address[] memory);
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cTokenAddress) external returns (uint);
}

interface AccountInterface {	
    function version() external view returns (uint);	
}

interface ListInterface {
    function accountID(address) external view returns (uint64);
}

interface IndexInterface {
    function master() external view returns (address);
    function list() external view returns (address);
    function isClone(uint, address) external view returns (bool);
}

interface CheckInterface {
    function isOk() external view returns (bool);
}

contract DSMath {
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }
}

contract Helpers is DSMath {
    using SafeERC20 for IERC20;

    address constant internal instaIndex = 0x2971AdFa57b20E5a416aE5a708A8655A9c74f723;
    address constant internal oldInstaPool = 0x1879BEE186BFfBA9A8b1cAD8181bBFb218A5Aa61;
    
    address constant internal comptrollerAddr = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    address constant internal ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant internal cEth = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    mapping (address => bool) public isTknAllowed;
    mapping (address => address) public tknToCTkn;

    mapping (address => uint) public borrowedToken;
    address[] public tokensAllowed;

    bool public checkOldPool = true;

    IndexInterface indexContract = IndexInterface(instaIndex);
    ListInterface listContract = ListInterface(indexContract.list());
    CheckInterface oldInstaPoolContract = CheckInterface(oldInstaPool);

    /**
     * FOR SECURITY PURPOSE
     * only Smart DEFI Account can access the liquidity pool contract
     */
    modifier isDSA {
        uint64 id = listContract.accountID(msg.sender);
        require(id != 0, "not-dsa-id");
        require(indexContract.isClone(AccountInterface(msg.sender).version(), msg.sender), "not-dsa-clone");
        _;
    }

    function tokenBal(address token) internal view returns (uint _bal) {
        _bal = token == ethAddr ? address(this).balance : IERC20(token).balanceOf(address(this));
    }

    function _transfer(address token, uint _amt) internal {
        token == ethAddr ?
            msg.sender.transfer(_amt) :
            IERC20(token).safeTransfer(msg.sender, _amt);
    }
}


contract CompoundResolver is Helpers {

    function borrowAndSend(address[] memory tokens, uint[] memory tknAmt) internal {
        if (tokens.length > 0) {
            for (uint i = 0; i < tokens.length; i++) {
                address token = tokens[i];
                address cToken = tknToCTkn[token];
                require(isTknAllowed[token], "token-not-listed");
                if (cToken != address(0) && tknAmt[i] > 0) {
                    require(CTokenInterface(cToken).borrow(tknAmt[i]) == 0, "borrow-failed");
                    borrowedToken[token] += tknAmt[i];
                    _transfer(token, tknAmt[i]);
                }
            }
        }
    }

    function payback(address[] memory tokens) internal {
        if (tokens.length > 0) {
            for (uint i = 0; i < tokens.length; i++) {
                address token = tokens[i];
                address cToken = tknToCTkn[token];
                if (cToken != address(0)) {
                    CTokenInterface ctknContract = CTokenInterface(cToken);
                    if(token != ethAddr) {
                        require(ctknContract.repayBorrow(uint(-1)) == 0, "payback-failed");
                    } else {
                        CETHInterface(cToken).repayBorrow.value(ctknContract.borrowBalanceCurrent(address(this)))();
                        require(ctknContract.borrowBalanceCurrent(address(this)) == 0, "ETH-flashloan-not-paid");
                    }
                    delete borrowedToken[token];
                }
            }
        }
    }
}

contract AccessLiquidity is CompoundResolver {
    event LogPoolBorrow(address indexed user, address[] tknAddr, uint[] amt);
    event LogPoolPayback(address indexed user, address[] tknAddr);

    /**
     * @dev borrow tokens and use them on DSA.
     * @param tokens Array of tokens.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amounts Array of tokens amount.
    */
    function accessLiquidity(address[] calldata tokens, uint[] calldata amounts) external isDSA {
        require(tokens.length == amounts.length, "length-not-equal");
        borrowAndSend(tokens, amounts);
        emit LogPoolBorrow(
            msg.sender,
            tokens,
            amounts
        );
    }
   
    /**
     * @dev Payback borrowed tokens.
     * @param tokens Array of tokens.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
    */
    function returnLiquidity(address[] calldata tokens) external payable isDSA {
        payback(tokens);
        emit LogPoolPayback(msg.sender, tokens);
    }
    
    function isOk() public view returns(bool ok) {
        ok = true;
        for (uint i = 0; i < tokensAllowed.length; i++) {
            uint tknBorrowed = borrowedToken[tokensAllowed[i]];
            if(tknBorrowed > 0){
                ok = false;
                break;
            }
        }
        if(checkOldPool && ok) {
            bool isOldPoolOk = oldInstaPoolContract.isOk();
            ok = isOldPoolOk;
        }
    }
}


contract ProvideLiquidity is  AccessLiquidity {
    event LogDeposit(address indexed user, address indexed token, uint amount, uint cAmount);
    event LogWithdraw(address indexed user, address indexed token, uint amount, uint cAmount);

    mapping (address => mapping (address => uint)) public liquidityBalance;

    /**
     * @dev Deposit Liquidity.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
    */
    function deposit(address token, uint amt) external payable returns (uint _amt) {
        require(isTknAllowed[token], "token-not-listed");
        require(amt > 0 || msg.value > 0, "amt-not-valid");

        if (msg.value > 0) require(token == ethAddr, "not-eth-addr");

        address cErc20 = tknToCTkn[token];
        uint initalBal = tokenBal(cErc20);
        if (token == ethAddr) {
            _amt = msg.value;
            CETHInterface(cErc20).mint.value(_amt)();
        } else {
            _amt = amt == (uint(-1)) ? IERC20(token).balanceOf(msg.sender) : amt;
            IERC20(token).safeTransferFrom(msg.sender, address(this), _amt);
            require(CTokenInterface(cErc20).mint(_amt) == 0, "mint-failed");
        }
        uint finalBal = tokenBal(cErc20);
        uint ctokenAmt = sub(finalBal, initalBal);

        liquidityBalance[token][msg.sender] += ctokenAmt;

        emit LogDeposit(msg.sender, token, _amt, ctokenAmt);
    }

    
    /**
     * @dev Withdraw Liquidity.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
    */
    function withdraw(address token, uint amt) external returns (uint _amt) {
        uint _userLiq = liquidityBalance[token][msg.sender];
        require(_userLiq > 0, "nothing-to-withdraw");

        uint _cAmt;

        address ctoken = tknToCTkn[token];
        if (amt == uint(-1)) {
            uint initknBal = tokenBal(token);
            require(CTokenInterface(ctoken).redeem(_userLiq) == 0, "redeem-failed");
            uint finTknBal = tokenBal(token);
            _cAmt = _userLiq;
            delete liquidityBalance[token][msg.sender];
            _amt = sub(finTknBal, initknBal);
        } else {
            uint iniCtknBal = tokenBal(ctoken);
            require(CTokenInterface(ctoken).redeemUnderlying(amt) == 0, "redeemUnderlying-failed");
            uint finCtknBal = tokenBal(ctoken);
            _cAmt = sub(iniCtknBal, finCtknBal);
            require(_cAmt <= _userLiq, "not-enough-to-withdraw");
            liquidityBalance[token][msg.sender] -= _cAmt;
            _amt = amt;
        }
        
        _transfer(token, _amt);
       
        emit LogWithdraw(msg.sender, token, _amt, _cAmt);
    }

}


contract Controllers is ProvideLiquidity {
    event LogEnterMarket(address[] token, address[] ctoken);
    event LogExitMarket(address indexed token, address indexed ctoken);

    event LogWithdrawMaster(address indexed user, address indexed token, uint amount);

    modifier isMaster {
        require(msg.sender == indexContract.master(), "not-master");
        _;
    }

    function switchOldPoolCheck() external isMaster {
        checkOldPool = !checkOldPool;
    }

    function _enterMarket(address[] memory cTknAddrs) internal {
        ComptrollerInterface(comptrollerAddr).enterMarkets(cTknAddrs);
        address[] memory tknAddrs = new address[](cTknAddrs.length);
        for (uint i = 0; i < cTknAddrs.length; i++) {
            if (cTknAddrs[i] != cEth) {
                tknAddrs[i] = CTokenInterface(cTknAddrs[i]).underlying();
                IERC20(tknAddrs[i]).safeApprove(cTknAddrs[i], uint(-1));
            } else {
                tknAddrs[i] = ethAddr;
            }
            tknToCTkn[tknAddrs[i]] = cTknAddrs[i];
            require(!isTknAllowed[tknAddrs[i]], "tkn-already-allowed");
            isTknAllowed[tknAddrs[i]] = true;
            tokensAllowed.push(tknAddrs[i]);
        }
        emit LogEnterMarket(tknAddrs, cTknAddrs);
    }

    /**
     * @dev Enter compound market to enable borrowing.
     * @param cTknAddrs Array Ctoken addresses.
    */
    function enterMarket(address[] calldata cTknAddrs) external isMaster {
        _enterMarket(cTknAddrs);
    }

    /**
     * @dev Exit compound market to disable borrowing.
     * @param cTkn Ctoken address.
    */
    function exitMarket(address cTkn) external isMaster {
        address tkn;
        if (cTkn != cEth) {
            tkn = CTokenInterface(cTkn).underlying();
            IERC20(tkn).safeApprove(cTkn, 0);
        } else {
            tkn = ethAddr;
        }
        require(isTknAllowed[tkn], "tkn-not-allowed");

        ComptrollerInterface(comptrollerAddr).exitMarket(cTkn);

        delete isTknAllowed[tkn];

        bool isFound = false;
        uint _length = tokensAllowed.length;
        uint _id;
        for (uint i = 0; i < _length; i++) {
            if (tkn == tokensAllowed[i]) {
                isFound = true;
                _id = i;
                break;
            }
        }
        if (isFound) {
            address _last = tokensAllowed[_length - 1];
            tokensAllowed[_length - 1] = tokensAllowed[_id];
            tokensAllowed[_id] = _last;
            tokensAllowed.pop();
        }
        emit LogExitMarket(tkn, cTkn);
    }

    /**
     * @dev Withdraw Liquidity.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
    */
    function withdrawMaster(address token, uint amt) external isMaster {
        _transfer(token, amt);
        emit LogWithdrawMaster(msg.sender, token, amt);
    }

    function spell(address _target, bytes calldata _data) external isMaster {
        require(_target != address(0), "target-invalid");
        bytes memory _callData = _data;
        assembly {
            let succeeded := delegatecall(gas(), _target, add(_callData, 0x20), mload(_callData), 0, 0)

            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    let size := returndatasize()
                    returndatacopy(0x00, 0x00, size)
                    revert(0x00, size)
                }
        }
    }

}


contract InstaPool is Controllers {
    constructor (address[] memory ctkns) public {
        _enterMarket(ctkns);
    }

    receive() external payable {}
}