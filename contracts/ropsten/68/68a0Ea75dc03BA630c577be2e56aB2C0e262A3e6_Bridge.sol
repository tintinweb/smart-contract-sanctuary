/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: MIT

pragma solidity  = 0.8.8;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function burn(uint256 _amount) external;
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
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address public pendingOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "no permission");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    //转移owner权限函数
    function transferOwnership(address newOwner)  public onlyOwner {
        pendingOwner = newOwner;//设置pendingOwner为newOwner
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    //接受owner权限函数，仅pendingOwner可调用
    function acceptOwnership()  public onlyPendingOwner {
        emit OwnershipTransferred(_owner, pendingOwner);
        _owner = pendingOwner;//更新owner为pendingOwner
        pendingOwner = address(0);//pendingOwner置为零地址
    }

}
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface Controller {
    function bridgeMint(address to, uint256 amount) external  returns (bool);
}

interface BlackList{
    function isblackAddr(address _account) external view  returns(bool);
}

contract Bridge is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    mapping(address => bool) public ccTokenStatus; //检测代币是否为cctoken代币
    address public storehouse; //仓库地址
    address public signatoryAddres;//签名地址
    address public WETH; //WETH地址
    BlackList blacklist;
    address public configurationController;
    mapping(address => mapping(uint256 => mapping(address => bindingTokenInfo))) public bindingToken; //两个链代币转换的关系绑定
    mapping(address => address) public controllerAddr; //指定cctoken代币对应的controller地址
    mapping(bytes => bool) public orderIDStatus; //订单使用状态
    uint256 public ID;
    struct bindingTokenInfo{
        bool pauseStatus; //暂停状态
        bool bindingStatus; //绑定状态;
        uint256 minAmount; //交易最小数量；
    }
    struct exchangeInfo{
        address _tokenA;
        address _tokenB;
        uint256 _chainIDB;
        uint256 _amount;
        address _to;
        bytes8 _r;
        bytes8 _s;
        uint8 _v;
        uint256 _deadline;
        uint256 _fee;
        bytes16 _challenge;
    }

    struct transferAndMintInfo{
        address _tokenA;
        address _tokenB;
        uint256 _chainIDA;
        uint256 _amount;
        address _to;
        uint256 _fee;
        bytes _orderID;
    }

    event Exchange(
        bytes indexed _orderID,
        address indexed _sourceAccount,
        address _tokenA,
        address _tokenB,
        uint256 _chainIDA,
        uint256 _chainIDB,
        uint256 _amount,
        address _to,
        uint256 _deadline,
        uint256 _fee
    );

    event TransferAndMint(
        bytes indexed _orderID,
        address indexed _sourceAccount,
        address _tokenA,
        address _tokenB,
        uint256 _chainIDA,
        uint256 _amount,
        address _to,
        uint256 _fee
    );
    event SetConfigAdmin(address _owner, address _account);
    event SetBindingToken(address _tokenA, uint256 _chainID, address _tokenB, bool _pauseStatus, bool _bindingStatus, uint256 _minAmount);
    event SetCcToken(address _cctoken, bool _status);
    event SetAdressParms(address _storehouse, address _signatoryAddres, address _WETH,address _blacklist);
    event SetControllerAddr(address _cctoken, address _controller);
    constructor(address _WETH, address _signatoryAddres, address _configurationController, BlackList _blacklist) {
        WETH = _WETH;
        signatoryAddres = _signatoryAddres;
        configurationController = _configurationController;
        blacklist = _blacklist;
    }

    modifier onlyConfigurationController() {
        require(msg.sender== configurationController, "caller is not the admin");
        _;
    }


    function setBindingToken(address _tokenA, uint256 _chainID, address _tokenB, bool _pauseStatus, 
    bool _bindingStatus, uint256 _minAmount) public onlyConfigurationController{
        bindingTokenInfo storage blindInfo = bindingToken[_tokenA][_chainID][_tokenB];
        blindInfo.pauseStatus = _pauseStatus;
        blindInfo.bindingStatus = _bindingStatus;
        blindInfo.minAmount = _minAmount;
        emit SetBindingToken(_tokenA, _chainID, _tokenB, _pauseStatus, _bindingStatus, _minAmount);
    }

    //设置指定代币为cctoken代币
    function setCcToken(address _cctoken, bool _status) public onlyConfigurationController{
        ccTokenStatus[_cctoken] = _status;
        emit SetCcToken(_cctoken, _status);
    }

    //设置指定cctoken对应的controller地址
    function setControllerAddr(address _cctoken, address _controller)  public onlyConfigurationController{
        controllerAddr[_cctoken] = _controller;
        emit SetControllerAddr(_cctoken, _controller);
    }

    //修改仓库地址,签名地址,WETH地址
    function setAdressParms(address _storehouse, address _signatoryAddress, address _WETH, BlackList _blacklist) public onlyConfigurationController{
        require(_storehouse != address(0), "the storehouse is zero address");
        require(_signatoryAddress != address(0), "the signatoryAddress is zero address");
        require(_WETH != address(0), "the WETH is zero address");
        require(address(_blacklist) != address(0), "the blacklist address is zero address");
        storehouse = _storehouse;
        signatoryAddres = _signatoryAddress;
        WETH = _WETH;
        blacklist = _blacklist;
        emit SetAdressParms(_storehouse, _signatoryAddress, _WETH, address(_blacklist));
    }

    //添加配置权限的管理员
    function setConfigurationController(address _configurationController) public onlyOwner{
        require(_configurationController != address(0), "the account is zero address");
        emit SetConfigAdmin(configurationController, _configurationController);
        configurationController = _configurationController;

    }


    function getChainId() internal view returns(uint256){
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function checkFee(exchangeInfo memory info) view internal {
        bytes  memory salt=abi.encodePacked(info._tokenA, info._tokenB, getChainId(), info._chainIDB, info._amount, info._deadline, info._fee, info._challenge);
        bytes  memory Message=abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    salt.length,
                    salt
                );
        bytes32 digest = keccak256(Message);
        address signer=ecrecover(digest, info._v, info._r, info._s);
        require(signer != address(0), "0 address");
        require(signer == signatoryAddres, "invalid signature");
    }
    function myencode(uint16 a, uint16 b, uint64 c) public pure returns (bytes memory) {
        return abi.encodePacked(a, b, c);
    }
     function exchange(exchangeInfo memory info) public payable returns(bool){
        bindingTokenInfo storage blindInfo = bindingToken[info._tokenA][info._chainIDB][info._tokenB];
        require(!blacklist.isblackAddr(info._tokenA) && !blacklist.isblackAddr(info._to), "the caller or to address is blacklist address");
         require(info._amount >= info._fee, "the amount less than fee");
         if (info._tokenA == address(0)){
            info._amount = msg.value;
            checkFee(info);
         } else {
            checkFee(info);
        }

        require(!blindInfo.pauseStatus && blindInfo.bindingStatus && info._amount >= blindInfo.minAmount, "the exchage token not meet the configuration");
        bytes memory _orderID = myencode(uint16(getChainId()), uint16(info._chainIDB),uint64(ID));
        ID++;
        if (ccTokenStatus[info._tokenA]){ //cctoke类型的代币直接销毁
            IERC20(info._tokenA).safeTransferFrom(msg.sender, address(this), info._amount);
            IERC20(info._tokenA).burn(info._amount);
            emit Exchange(_orderID, msg.sender, info._tokenA, info._tokenB, getChainId(), info._chainIDB, info._amount, info._to, info._deadline, info._fee);
            return true;
        }

        if (info._tokenA == address(0)){//ETH换成WETH转入仓库地址
            uint256 ethAmount = msg.value;
            IWETH(WETH).deposit{value:ethAmount}();
            IERC20(WETH).safeTransfer(storehouse, ethAmount);
            emit Exchange(_orderID, msg.sender, info._tokenA, info._tokenB, getChainId(), info._chainIDB, ethAmount, info._to, info._deadline, info._fee);
            return true;
        }
        //其他代币直接转入仓库地址
        IERC20(info._tokenA).safeTransferFrom(msg.sender, storehouse, info._amount);
        emit Exchange(_orderID, msg.sender, info._tokenA, info._tokenB, getChainId(), info._chainIDB, info._amount, info._to, info._deadline, info._fee);
        return true;
    }

    function transferAndMint(transferAndMintInfo memory info) public onlyConfigurationController returns(bool){
        bindingTokenInfo storage blindInfo = bindingToken[info._tokenB][info._chainIDA][info._tokenA];
        require(!blacklist.isblackAddr(info._to), "the caller or to address is blacklist address");
        require(!orderIDStatus[info._orderID], "the orderID already finished");
        orderIDStatus[info._orderID] = true;
        uint256 realAmount =  info._amount.sub(info._fee);//真实转账数量
        require(!blindInfo.pauseStatus && blindInfo.bindingStatus && info._amount >= blindInfo.minAmount, "the exchage token not meet the configuration");
        if (ccTokenStatus[info._tokenB]) { //如果转出代币为cctoken代币
            address controller = controllerAddr[info._tokenB]; //通过转出代币的地址找到controller地址
            require(Controller(controller).bridgeMint(info._to, realAmount), " mint failed"); //调用controller合约的接口进行铸币
            emit TransferAndMint(info._orderID, msg.sender, info._tokenA, info._tokenB, info._chainIDA, info._amount, info._to, info._fee);
            return true;
        }

        if(info._tokenB == address(0)){//如果转出的币为平台币
            IERC20(WETH).safeTransferFrom(storehouse, address(this), realAmount);
            IWETH(WETH).withdraw(realAmount);
            payable(info._to).transfer(realAmount);
            emit TransferAndMint(info._orderID, msg.sender, info._tokenA, info._tokenB, info._chainIDA, info._amount, info._to, info._fee);
            return true;
        }
        //其他代币正常从仓库合约转出
        IERC20(info._tokenB).safeTransferFrom(storehouse, info._to, realAmount);
        emit TransferAndMint(info._orderID, msg.sender, info._tokenA, info._tokenB, info._chainIDA, info._amount, info._to, info._fee);
        return true;    
    }

    function witdrawToken(address _token) public onlyOwner{
        IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

}