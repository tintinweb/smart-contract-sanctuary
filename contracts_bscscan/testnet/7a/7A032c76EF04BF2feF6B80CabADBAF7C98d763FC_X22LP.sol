// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function approve( address, uint256)  external returns(bool);

    function allowance(address, address) external view returns (uint256);
    
    function balanceOf(address)  external view returns(uint256);

    function decimals()  external view returns(uint8);

    function totalSupply() external  view returns(uint256);

    function transferFrom(address,address,uint256) external  returns(bool);

    function transfer(address,uint256) external  returns(bool);
    
    function mint(address , uint256 ) external ;
    function burn(address , uint256 ) external ;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Interface.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface rStrategy {

    function deposit(uint256[3] calldata) external;
    function withdraw(uint256[3] calldata) external;
    function withdrawAll()  external returns(uint256[3] memory);
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


import "./StrategyInterface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "./SafeERC20.sol";

contract X22LP is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 constant public N_COINS=3;
    
    uint256 public constant DENOMINATOR = 10000;

    uint128 public fees = 700; // 7% of amount to withdraw

    uint256 public poolPart = 750 ; // 7.5% of total Liquidity will remain in the pool

    uint256 public selfBalance;

    IERC20[N_COINS] public tokens;

    IERC20 public XPTtoken;

    rStrategy public strategy;
    
    address public wallet;
    
    address public nominatedWallet;

    uint public YieldPoolBalance;
    uint public liquidityProvidersAPY;

    //storage for user related to supply and withdraw
    
    uint256 public lock_period = 1 minutes;

    struct depositDetails {
        uint index;
        uint amount;
        uint256 time;
        uint256 remAmt;
    }
    
    mapping(address => depositDetails[]) public amountSupplied;
    mapping(address => uint256) public requestedAmount;
    mapping(address => uint256) public requestedTime;
    mapping(address => uint256) public requestedIndex;
    
    
    uint256 public coolingPeriod = 86400;
    

    mapping(address => bool)public reserveRecipients;

    uint[N_COINS] public storedFees;
    
    //storage to store total loan given
    uint256 public loanGiven;
    
    uint public loanPart=2000;
    
  
    modifier onlyWallet(){
      require(wallet ==msg.sender, "NA");
      _;
    }
  
     modifier validAmount(uint amount){
      require(amount > 0 , "NV");
      _;
    }
    
    // EVENTS 
    event userSupplied(address user,uint amount,uint index);
    event userRecieved(address user,uint amount,uint index);
    event feesTransfered(address user,uint amount,uint index);
    event loanTransfered(address recipient,uint amount,uint index);
    event loanRepayed(uint amount,uint index);
    event yieldAdded(uint amount,uint index);
    event walletNominated(address newOwner);
    event walletChanged(address oldOwner, address newOwner);
    event requestedWithdraw(address user,uint amount,uint index);
    event WithdrawCancel(address user);
    event userClaimed(address user, uint amount, uint index, bool payingCharges);
   
    
    constructor(address[N_COINS] memory _tokens,address _XPTtoken,address _wallet) {
        require(_wallet != address(0), "Wallet address cannot be 0");
        for(uint8 i=0; i<N_COINS; i++) {
            tokens[i] = IERC20(_tokens[i]);
        }
        XPTtoken = IERC20(_XPTtoken);
        wallet=_wallet;
    }
    
    function nominateNewOwner(address _wallet) external onlyWallet {
        nominatedWallet = _wallet;
        emit walletNominated(_wallet);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedWallet, "You must be nominated before you can accept ownership");
        emit walletChanged(wallet, nominatedWallet);
        wallet = nominatedWallet;
        nominatedWallet = address(0);
    }


    /* INTERNAL FUNCTIONS */
   
    
    //For checking whether array contains any non zero elements or not.
    function checkValidArray(uint256[N_COINS] memory amounts)internal pure returns(bool){
        for(uint8 i=0;i<N_COINS;i++){
            if(amounts[i]>0){
                return true;
            }
        }
        return false;
    }

    // This function deposits the liquidity to yield generation pool using yield Strategy contract
    function _deposit(uint256[N_COINS] memory amounts) internal {
        strategy.deposit(amounts);
        uint decimal;
        for(uint8 i=0;i<N_COINS;i++){
            decimal=tokens[i].decimals();
            YieldPoolBalance =YieldPoolBalance.add(amounts[i].mul(10**18).div(10**decimal));
        }
    }
   

    //This function is used to updating the array of user's individual deposit , called when users withdraw/claim tokens.
    function updateLockedXPT(address recipient,uint256 amount) internal{
        for(uint8 j=0; j<amountSupplied[recipient].length; j++) {
            if(amountSupplied[recipient][j].remAmt > 0 && amount > 0 ) {
                if(amount >= amountSupplied[recipient][j].remAmt) {
                        amount = amount.sub( amountSupplied[recipient][j].remAmt);
                        amountSupplied[recipient][j].remAmt = 0;
                }
                else {
                        amountSupplied[recipient][j].remAmt =(amountSupplied[recipient][j].remAmt).sub(amount);
                        amount = 0;
                }
            }
        }
     }


    // this will withdraw Liquidity from yield genaration pool using yield Strategy
    function _withdraw(uint256[N_COINS] memory amounts) internal {
        strategy.withdraw(amounts);
        uint decimal;
        for(uint8 i=0;i<N_COINS;i++){
            decimal=tokens[i].decimals();
            YieldPoolBalance =YieldPoolBalance.sub(amounts[i].mul(10**18).div(10**decimal));
        }
    }
    
    //This function calculate XPT to be mint or burn
    //amount parameter is amount of token
    //_index can be 0/1/2 
    //0-DAI
    //1-USDC
    //2-USDT
    function calcXPTAmount(uint256 amount,uint _index) public view returns(uint256) {
        uint256 total = calculateTotalToken(true);
        uint256 decimal = 0;
        decimal=tokens[_index].decimals();
        amount=amount.mul(1e18).div(10**decimal);
        if(total==0){
            return amount;
        }
        else{
          return (amount.mul(XPTtoken.totalSupply()).div(total)); 
        }
    }



    //function to check available amount to withdraw for user
    function availableLiquidity(address addr, uint coin,bool _time) public view returns(uint256 token,uint256 XPT) {
        uint256 amount=0;
        for(uint8 j=0; j<amountSupplied[addr].length; j++) {
                if( (!_time || (block.timestamp - amountSupplied[addr][j].time)  > lock_period)&&amountSupplied[addr][j].remAmt >0)   {
                        amount =amount.add(amountSupplied[addr][j].remAmt);
                }
        }
        uint256 total=calculateTotalToken(true);
        uint256 decimal;
        decimal=tokens[coin].decimals();
        return ((amount.mul(total).mul(10**decimal).div(XPTtoken.totalSupply())).div(10**18),amount);
    }
    

    //calculated available total tokens in the pool by substracting withdrawal, reserve amount.
    //In case supply is true , it adds total loan given.
    function calculateTotalToken(bool _supply)public view returns(uint256){
        uint256 decimal;
        uint storedFeesTotal;
        for(uint8 i=0; i<N_COINS; i++) {
            decimal = tokens[i].decimals();
            storedFeesTotal=storedFeesTotal.add(storedFees[i].mul(1e18).div(10**decimal));
        } 
        if(_supply){
            return selfBalance.sub(storedFeesTotal).add(loanGiven);
        }
        else{
            return selfBalance.sub(storedFeesTotal);
        }
        
    }
    
    /* USER FUNCTIONS (exposed to frontend) */
   
    //For depositing liquidity to the pool.
    //_index will be 0/1/2     0-DAI , 1-USDC , 2-USDT
    function supply(uint256 amount,uint256 _index) external nonReentrant  validAmount(amount){
        uint decimal;
        uint256 mintAmount=calcXPTAmount(amount,_index);
        amountSupplied[msg.sender].push(depositDetails(_index,amount,block.timestamp,mintAmount));
        decimal=tokens[_index].decimals();
        selfBalance=selfBalance.add(amount.mul(10**18).div(10**decimal));
        tokens[_index].safeTransferFrom(msg.sender, address(this), amount);
        XPTtoken.mint(msg.sender, mintAmount);
        emit userSupplied(msg.sender, amount,_index);
    }

    
    //for withdrawing the liquidity
    //First Parameter is amount of XPT
    //Second is which token to be withdrawal with this XPT.
    function requestWithdrawWithXPT(uint256 amount,uint256 _index, bool payingCharges) external nonReentrant validAmount(amount){
        require(!reserveRecipients[msg.sender],"Claim first");
        require(XPTtoken.balanceOf(msg.sender) >= amount, "low XPT");
        (,uint availableXPT)=availableLiquidity(msg.sender,_index,true );
        require(availableXPT>=amount,"NA");
        uint256[N_COINS] memory amountWithdraw;
        if(payingCharges == true){
           uint256 total = calculateTotalToken(true);
           uint256 tokenAmount;
           tokenAmount=amount.mul(total).div(XPTtoken.totalSupply());
           uint decimal;
           decimal=tokens[_index].decimals();
           tokenAmount = tokenAmount.mul(10**decimal).div(10**18);
           for(uint8 i=0;i<N_COINS;i++){
              if(i==_index){
                  amountWithdraw[i] = tokenAmount;
              }
              else{
                  amountWithdraw[i] = 0;
              }
           }
            uint256 currentPoolAmount = getBalances(_index);
            if(tokenAmount>currentPoolAmount){
                _withdraw(amountWithdraw);
            }
           
           uint temp = (tokenAmount.mul(fees)).div(10000);
           selfBalance = selfBalance.sub((tokenAmount.sub(temp)).mul(1e18).div(10**decimal));
           tokens[_index].safeTransfer(msg.sender, tokenAmount.sub(temp));
           emit userRecieved(msg.sender,tokenAmount.sub(temp),_index);
           storedFees[_index] =storedFees[_index].add(temp);
           XPTtoken.burn(msg.sender, amount);
           updateLockedXPT(msg.sender,amount);
        }
        else{    
        requestedAmount[msg.sender] = amount;
        requestedTime[msg.sender] = block.timestamp;
        reserveRecipients[msg.sender] = true;
        requestedIndex[msg.sender] = _index;
        emit requestedWithdraw(msg.sender, amount, _index);
        }
        
    }

    function cancelWithdraw() external{
        require(reserveRecipients[msg.sender] == true, 'You did not request anything!');
        requestedAmount[msg.sender] = 0;
        requestedTime[msg.sender] = 0;
        reserveRecipients[msg.sender] =false;
        requestedIndex[msg.sender] = 5;
        emit WithdrawCancel(msg.sender);
    }
    
    //For claiming withdrawal after user added to the reserve recipient.
    function claimTokens(bool payingCharges) external  nonReentrant{
        require(reserveRecipients[msg.sender] , "request withdraw first");
        uint256 total = calculateTotalToken(true);
        uint256 _index = requestedIndex[msg.sender];
        uint256 tokenAmount;
        tokenAmount=requestedAmount[msg.sender].mul(total).div(XPTtoken.totalSupply());
        uint decimal;
        decimal=tokens[_index].decimals();
        tokenAmount = tokenAmount.mul(10**decimal).div(10**18);
        uint temp =0;
        if(payingCharges){
                temp = (tokenAmount.mul(fees)).div(10000);
        }
        else{
            require(requestedTime[msg.sender]+coolingPeriod <= block.timestamp, "You have to wait for 8 days after requesting for withdraw");
        }
        uint256[N_COINS] memory amountWithdraw;
        for(uint8 i=0;i<N_COINS;i++){
              if(i==_index){
                  amountWithdraw[i] = tokenAmount;
              }
              else{
                  amountWithdraw[i] = 0;
              }
           }
            uint256 currentPoolAmount = getBalances(_index);
            if(tokenAmount>currentPoolAmount){
                _withdraw(amountWithdraw);
            }
        selfBalance = selfBalance.sub((tokenAmount.sub(temp)).mul(1e18).div(10**decimal));
        tokens[_index].safeTransfer(msg.sender, tokenAmount.sub(temp));
        emit userClaimed(msg.sender,tokenAmount.sub(temp),_index,payingCharges);
        storedFees[_index] =storedFees[_index].add(temp);
        XPTtoken.burn(msg.sender, requestedAmount[msg.sender]);
        updateLockedXPT(msg.sender,requestedAmount[msg.sender]);
        requestedAmount[msg.sender] = 0;
        reserveRecipients[msg.sender] = false;
        requestedIndex[msg.sender] = 5;
        requestedTime[msg.sender] = 0;
    }

    // this function deposits without minting XPT.
    //Used to deposit Yield
    function depositYield(uint256 amount,uint _index) external{
        uint decimal;
        decimal=tokens[_index].decimals();
        selfBalance=selfBalance.add(amount.mul(1e18).div(10**decimal));
        liquidityProvidersAPY=liquidityProvidersAPY.add(amount.mul(1e18).div(10**decimal));
        tokens[_index].safeTransferFrom(msg.sender,address(this),amount);
        emit yieldAdded(amount,_index);
    }


    /* CORE FUNCTIONS (called by owner only) */

    //Transfer token z`1   o rStrategy by maintaining pool ratio.
    function deposit() onlyWallet() external  {
        uint256[N_COINS] memory amounts;
        uint256 totalAmount;
        uint256 decimal;
        totalAmount=calculateTotalToken(false);
        uint balanceAmount=totalAmount.mul(poolPart).div(N_COINS).div(DENOMINATOR);
        uint tokenBalance;
        for(uint8 i=0;i<N_COINS;i++){
            decimal=tokens[i].decimals();
            amounts[i]=getBalances(i);
            tokenBalance=balanceAmount.mul(10**decimal).div(10**18);
            if(amounts[i]>tokenBalance) {
                amounts[i]=amounts[i].sub(tokenBalance);
                tokens[i].safeTransfer(address(strategy),amounts[i]);
            }
            else{
                amounts[i]=0;
            }
        }
        if(checkValidArray(amounts)){
            _deposit(amounts);
        }
    }
    

  //Withdraw total liquidity from yield generation pool
    function withdrawAll() external onlyWallet() {
        uint[N_COINS] memory amounts;
        amounts=strategy.withdrawAll();
        uint decimal;
        selfBalance=0;
        for(uint8 i=0;i<N_COINS;i++){
            decimal=tokens[i].decimals();
            selfBalance=selfBalance.add((tokens[i].balanceOf(address(this))).mul(1e18).div(10**decimal));
        }
        YieldPoolBalance=0;
    }


    //function for withdraw and  rebalancing royale pool(ratio)       
    function rebalance() onlyWallet() external {
        uint256 currentAmount;
        uint256[N_COINS] memory amountToWithdraw;
        uint256[N_COINS] memory amountToDeposit;
        uint totalAmount;
        uint256 decimal;
        totalAmount=calculateTotalToken(false);
        uint balanceAmount=totalAmount.mul(poolPart).div(N_COINS).div(DENOMINATOR);
        uint tokenBalance;
        for(uint8 i=0;i<N_COINS;i++) {
          currentAmount=getBalances(i);
          decimal=tokens[i].decimals();
          tokenBalance=balanceAmount.mul(10**decimal).div(10**18);
          if(tokenBalance > currentAmount) {
              amountToWithdraw[i] = tokenBalance.sub(currentAmount);
          }
          else if(tokenBalance < currentAmount) {
              amountToDeposit[i] = currentAmount.sub(tokenBalance);
              tokens[i].safeTransfer(address(strategy), amountToDeposit[i]);
               
          }
          else {
              amountToWithdraw[i] = 0;
              amountToDeposit[i] = 0;
          }
        }
        if(checkValidArray(amountToDeposit)){
             _deposit(amountToDeposit);
             
        }
        if(checkValidArray(amountToWithdraw)) {
            _withdraw(amountToWithdraw);
            
        }

    }
    
    //For withdrawing loan from the royale Pool
    function withdrawLoan(uint[N_COINS] memory amounts,address _recipient)external onlyWallet(){
        require(checkValidArray(amounts),"amount can not zero");
        uint decimal;
        uint total;
        for(uint i=0;i<N_COINS;i++){
          decimal=tokens[i].decimals();
          total=total.add(amounts[i].mul(1e18).div(10**decimal));
        }
        require(loanGiven.add(total)<=(calculateTotalToken(true).mul(loanPart).div(DENOMINATOR)),"Exceed limit");
        require(total<calculateTotalToken(false),"Not enough balance");
        bool strategyWithdraw=false;
        for(uint i=0;i<N_COINS;i++){
            if(amounts[i]>getBalances(i)){
                strategyWithdraw=true;
                break;
            }
        }
        if(strategyWithdraw){
          _withdraw(amounts); 
        }
        loanGiven =loanGiven.add(total);
        selfBalance=selfBalance.sub(total);
        for(uint8 i=0; i<N_COINS; i++) {
            if(amounts[i] > 0) {
                tokens[i].safeTransfer(_recipient, amounts[i]);
                emit loanTransfered(_recipient,amounts[i],i);
            }
        }
        
    }
    
  // For repaying the loan to the royale Pool.
    function repayLoan(uint[N_COINS] memory amounts)external {
        require(checkValidArray(amounts),"amount can't be zero");
        uint decimal;
        for(uint8 i=0; i<N_COINS; i++) {
            if(amounts[i] > 0) {
                decimal=tokens[i].decimals();
                loanGiven =loanGiven.sub(amounts[i].mul(1e18).div(10**decimal));
                selfBalance=selfBalance.add(amounts[i].mul(1e18).div(10**decimal));
                tokens[i].safeTransferFrom(msg.sender,address(this),amounts[i]);
                emit loanRepayed(amounts[i],i);
            }
        }
    }

    
    function claimFees() external nonReentrant{
        uint decimal;
        for(uint i=0;i<N_COINS;i++){
            if(storedFees[i] > 0){
            decimal=tokens[i].decimals();
            selfBalance = selfBalance.sub(storedFees[i].mul(1e18).div(10**decimal));
            tokens[i].safeTransfer(wallet,storedFees[i]);
            emit feesTransfered(wallet,storedFees[i],i);
            storedFees[i]=0;
            }
        }
    }
    

    //for changing pool ratio
    function changePoolPart(uint128 _newPoolPart) external onlyWallet()  {
        require(_newPoolPart < DENOMINATOR, "Entered pool part too high");
        poolPart = _newPoolPart;
        
    }

   //For changing yield Strategy
    function changeStrategy(address _strategy) onlyWallet() external  {
        require(YieldPoolBalance==0, "Call withdrawAll function first");
        strategy=rStrategy(_strategy);
        
    }

    function setLockPeriod(uint256 lockperiod) onlyWallet() external  {
        lock_period = lockperiod;
        
    }

     // for changing withdrawal fees  
    function setWithdrawFees(uint128 _fees) onlyWallet() external {
        require(_fees<100, "Entered fees too high");
        fees = _fees;

    }
    
    function setCoolingPeriod(uint128 _period) onlyWallet() external {
        coolingPeriod = _period; //in seconds

    }
    
    function changeLoanPart(uint256 _value)onlyWallet() external{
        require(_value < DENOMINATOR, "Entered loanPart too high");
        loanPart=_value;
    } 
    
    function getBalances(uint _index) public view returns(uint256) {
        return (tokens[_index].balanceOf(address(this)).sub(storedFees[_index]));
    }
}

