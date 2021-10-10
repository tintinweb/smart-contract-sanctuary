// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./BscBank.sol";
import "./BridgeBankPausable.sol";
import "./Ownable.sol";
import "../../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./Validator.sol";
/**
 * @title BridgeBank
 * @dev Bank contract which coordinates asset-related functionality.
 *      BscBank manages the locking and unlocking of BNB/BEP20 token assets
 *      based on Bsc.
 **/

contract BridgeBank is Initializable, BscBank, BridgeBankPausable, Ownable, Validator, ReentrancyGuardUpgradeable{
    using SafeERC20 for BridgeToken;

    address public operator;
    address public timeLockContract;
    /*
     * @dev: Constructor, sets operator
     */
    function initialize(address _operatorAddress, address _timeLockAddress) public payable initializer {
        operator = _operatorAddress;
        timeLockContract = _timeLockAddress;
        owner = payable(msg.sender);
        lockBurnNonce = 0;
        _paused = false;
        __ReentrancyGuard_init();
    }

    /*
     * @dev: Modifier to restrict access to operator
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Must be BridgeBank operator.");
        _;
    }

    /*
    * @dev: Modifier to restrict state change to timeLock smart contract
    */
    modifier isTimeLock() {
        require(msg.sender == timeLockContract, "Must be timeLock smart contract");
        _;
    }

    /*
     * @dev: Change to new Operator
     *
     */
    event LogChangeOperator(address _oldOperator, address _newOperator);
    
    function changeOperator(address _newOperator)
        public
        isTimeLock
    {
        require(_newOperator != address(0), "Operator equals null address");

        emit LogChangeOperator(operator, _newOperator);

        operator = _newOperator;
    }

    /*
     * @dev: Add validator
     *
     */
    function addValidator(address _newValidator)
        public
        isTimeLock
    {   
        _addValidator(_newValidator);
    }

        

    /*
     * @dev: Fallback/receive function allows anyone to send funds to the bank directly
     *
     */

    fallback() external payable {}
    receive() external payable {}
    
    /**
     * @dev Pauses all functions.
     * Set timestamp for current pause
     */
    function pause() public isTimeLock{
        _pause();
    }

    /**
     * @dev Unpauses all functions.
     * No need to reset pausedAt when pausing it will automatically increase
     */
    function unpause() public isTimeLock {
        _unpause();
    }

    /*
     * @dev: Locks received BNB/BEP20 funds.
     *
     * @param _recipient: representation of destination address.
     * @param _token: token address in origin chain (0x0 if ethereum)
     * @param _amount: value of deposit
     */
    function lock(
        address _recipient,
        address _token,
        uint256 _amount,
        string memory _chainName
    ) public payable whenNotPaused nonReentrant{
        string memory symbol;

        // BNB deposit
        if (msg.value > 0) {
            require(
                _token == address(0),
                "BNB deposits require the 'token' address to be the null address"
            );
            require(
                msg.value == _amount,
                "The transactions value must be equal the specified amount (in wei)"
            );
            symbol = "BNB";

            lockFunds(
            payable(msg.sender),
            _recipient,
            _token,
            symbol,
            _amount,
            _chainName
            );

        }// BEP20 deposit
        else {
            
            uint beforeLock = BridgeToken(_token).balanceOf(address(this));

            BridgeToken(_token).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );

            uint afterLock = BridgeToken(_token).balanceOf(address(this));

            // Set symbol to the BEP20 token's symbol
            symbol = BridgeToken(_token).symbol();

            lockFunds(
            payable(msg.sender),
            _recipient,
            _token,
            symbol,
            afterLock - beforeLock,
            _chainName
            );
        }
    }

    /*
     * @dev: Unlocks BNB and BEP20 tokens held on the contract.
     *
     * @param _recipient: recipient's is an bsc address
     * @param _token: token contract address
     * @param _symbol: token symbol
     * @param _amount: wei amount or BEP20 token count
     * 
     * This functions is use for unlock IBC assets
     * - Operator send the 
     */
    function unlock(
        uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS, 
        address payable _recipient,
        address tokenAddress,
        string memory _symbol,
        uint256 _amount,
        uint256 _fee,
        bytes32 _interchainTX
    ) public onlyOperator
             whenNotPaused
             nonReentrant
             validatorPrecheck(sigV, sigR, sigS)
    {
        require(_amount > _fee, "Invalid input amount <= fee");
        require(
            sigV.length == sigR.length && sigR.length == sigS.length && sigV.length > 0
        );

        require(
            _checkUnlockSig(sigV, sigR, sigS, _recipient, tokenAddress, _symbol, _amount, _interchainTX), 
            "Invalid signature"
        );

        require(
            unlockCompleted[_interchainTX].isUnlocked == false,
            "Transactions has been processed before"
        );

        // Check if it is EVRY
        if (tokenAddress == address(0)) {
            address thisadd = address(this);
            require(
                thisadd.balance >= _amount,
                "Insufficient ethereum balance for delivery."
            );
        } else {
            require(
                BridgeToken(tokenAddress).balanceOf(address(this)) >= _amount,
                "Insufficient ERC20 token balance for delivery."
            );
        }

        unlockFunds(_recipient, owner, tokenAddress, _symbol, _amount, _fee, _interchainTX);
    }

    function emergencyWithdraw(uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS, address tokenAddress, uint256 _amount)
        public
        onlyOperator 
        whenPaused
        nonReentrant
        validatorPrecheck(sigV, sigR, sigS)
    {
        require(
            sigV.length == sigR.length && sigR.length == sigS.length && sigV.length > 0
        );

        require(
            _checkEmergencySig(sigV, sigR, sigS, tokenAddress, _amount), 
            "Invalid signature"
        );
        // Check if it is BNB
        if (tokenAddress == address(0)) {
            address thisadd = address(this);
            require(
                thisadd.balance >= _amount,
                "Insufficient ethereum balance for delivery."
            );
            payable(msg.sender).transfer(_amount);
        } else {
            require(
                BridgeToken(tokenAddress).balanceOf(address(this)) >= _amount,
                "Insufficient ERC20 token balance for delivery."
            );
            BridgeToken(tokenAddress).safeTransfer(owner, _amount);
        }
    }

    /*
     * @dev: Refund BNB and BEP20 tokens held on the contract.
     *
     * @param _recipient: recipient's is an bsc address
     * @param _token: token contract address
     * @param _symbol: token symbol
     * @param _amount: wei amount or BEP20 token count
     */
    function refund(
        uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS,
        address payable _recipient,
        address _tokenAddress,
        string memory _symbol,
        uint256 _amount,
        uint256 _nonce
    ) public onlyOperator whenNotPaused nonReentrant validatorPrecheck(sigV, sigR, sigS)
     {
        require(
            sigV.length == sigR.length && sigR.length == sigS.length && sigV.length > 0
        );

        require(
            _checkRefundSig(sigV, sigR, sigS, _recipient, _tokenAddress, _symbol, _amount, _nonce), 
            "Invalid signature"
        );
        require(
            refundCompleted[_nonce].isRefunded == false,
            "This refunds has been processed before"
        );
        require(
            refundCompleted[_nonce].tokenAddress == _tokenAddress,
            "Invalid tokenAdress"
        );
        require(
            refundCompleted[_nonce].sender == _recipient,
            "Invalid recipient"
        );
        require(
            refundCompleted[_nonce].amount == _amount,
            "Invalid amount to be refund"
        );
        // Check if it is BNB
        if (_tokenAddress == address(0)) {
            address thisadd = address(this);
            require(
                thisadd.balance >= _amount,
                "Insufficient ethereum balance for delivery."
            );
        } else {
            require(
                BridgeToken(_tokenAddress).balanceOf(address(this)) >= _amount,
                "Insufficient ERC20 token balance for delivery."
            );
        }
        refunds(_recipient, _tokenAddress, _symbol, _amount, _nonce);
    }

    /*
     * @dev: For validators to get the lock data in order to verify 
     *       if it is correct data that they need to verify with signature
     *
     * @param _recipient: Nonce Number
     * @return lockData
     */
    function getLockData(uint256 _nonce) public view returns (bool, uint256, address, address, uint256, string memory){
        return _getLockData(_nonce);
    }
    
    // This function check the mapping to see if the transaction  is unlockeds
    function checkIsUnlocked(bytes32 _interchainTX) public view returns (bool) {
        UnlockData memory _unlock = unlockCompleted[_interchainTX];
        return _unlock.isUnlocked;
    }

    function checkIsRefunded(uint256 _id) public view returns (bool) {
        RefundData memory _refund = refundCompleted[_id];
        return _refund.isRefunded;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Validator
 * @dev To handle the multisig
 * Author: luc.vu
 * Company: sotatek.com
 **/

contract Validator{

    address[] private validators;
    // Fixed threshold to validate unlock/refund/emergency withdraw equal or more than 2/3 signatures
    uint private constant threshold = 66;
    
    function getValidators() public view returns (address[] memory){
        return  validators;
    }

    event LogAddValidator(address _validator);

    function _addValidator(address _validator) internal {
        require(_validator != address(0), "Must not be null address");
        for(uint index = 0; index < validators.length; index++){
            require(_validator != validators[index], "Must be difference validator");
        }
        validators.push(_validator);

        emit LogAddValidator(_validator);
    }

    event LogRemoveValidator(address _validator);

    function _removeValidator(address _validator) internal {
        require(_validator != address(0), "Must not be null address");
        require(validators.length > 0, "Validators must be more than 0");
        for(uint index = 0; index < validators.length; index++){
            if(_validator == validators[index]){
                validators[index] = validators[validators.length - 1];
                validators.pop();
                emit LogRemoveValidator(_validator);
                return;
            }
        }
        require(false, "Could not find validator to remove");
    }
    
    event LogUpdateValidator(address _oldValidator, address _newValidator);

    function _updateValidator(address _old, address _new) private{
        require(_old != address(0) && _new != address(0), "Must not be null address");
        require(validators.length > 0, "Validators must be more than 0");
        for(uint index = 0; index < validators.length; index++){
            if(_old == validators[index]){
                validators[index] = _new;
                emit LogUpdateValidator(_old, _new);
                return;
            }
        }
        require(false, "Cound not find validator to replace");
    }

    function _checkSignature(uint8 _sigV,
                             bytes32 _sigR,
                             bytes32 _sigS,
                             bytes32 _inputHash) 
    private view returns (bool)
    {
        address checkAdress = ecrecover(_inputHash, _sigV, _sigR, _sigS);
        for(uint index = 0; index < validators.length; index++){
            if(checkAdress == validators[index]){
                return true;
            }
        }
        return  false;
    }

    function _checkUnlockSig(uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS, 
                            address payable _recipient,
                            address tokenAddress,
                            string memory _symbol,
                            uint256 _amount,
                            bytes32 _interchainTX) 
    internal view returns (bool)
    {
            bytes32 funcHash = keccak256("unlock");
            bytes32 symbolHash = keccak256(bytes(_symbol));

            // digest the data to transactionHash
            bytes32 inputHash = keccak256(abi.encode(funcHash, _recipient, tokenAddress, symbolHash, _amount, _interchainTX));
            for(uint index = 0; index < sigV.length; index++){
                // address recoveredAddress = ecrecover(inputHash, sigV[index], sigR[index], sigS[index]);
                if(!_checkSignature(sigV[index], sigR[index], sigS[index], inputHash))
                    return false;
            }
            return true;
    }

    function _checkRefundSig(uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS, 
                            address payable _recipient,
                            address tokenAddress,
                            string memory _symbol,
                            uint256 _amount,
                            uint256 _nonce) 
    internal view returns (bool)
    {
        bytes32 funcHash = keccak256("refund");
        bytes32 symbolHash = keccak256(bytes(_symbol));

        // digest the data to transactionHash
        bytes32 inputHash = keccak256(abi.encode(funcHash, _recipient, tokenAddress, symbolHash, _amount, _nonce));
        for(uint index = 0; index < sigV.length; index++){
            // address recoveredAddress = ecrecover(inputHash, sigV[index], sigR[index], sigS[index]);
            if(!_checkSignature(sigV[index], sigR[index], sigS[index], inputHash))
                return false;
        }
        return true;
    }

    function _checkEmergencySig(uint8[] memory sigV, 
                                bytes32[] memory sigR,
                                bytes32[] memory sigS, 
                                address tokenAddress,
                                uint256 _amount)
    internal view returns (bool)
    {
        bytes32 funcHash = keccak256("emergencyWithdraw");
        // digest the data to transactionHash
        bytes32 inputHash = keccak256(abi.encode(funcHash, tokenAddress, _amount));
        for(uint index = 0; index < sigV.length; index++){
            // address recoveredAddress = ecrecover(inputHash, sigV[index], sigR[index], sigS[index]);
            if(!_checkSignature(sigV[index], sigR[index], sigS[index], inputHash))
                return false;
        }
        return true;
    }


    modifier validatorPrecheck(uint8[] memory _sigV, bytes32[] memory _sigR, bytes32[] memory _sigS){
        require(
            _sigV.length == _sigR.length && _sigR.length == _sigS.length && _sigV.length > 0, 
            "The number of validators must be greater than 0"
        );

        require(
            _sigV.length * 100 / validators.length >= threshold, "The approved validators must be equal or greater than threshold"
        );

        if(_sigV.length >= 2){
            for(uint i = 0; i < _sigV.length; i++){
                bytes32 tempData = keccak256(abi.encodePacked(_sigV[i], _sigR[i], _sigS[i]));
                for(uint j = i + 1; j < _sigV.length; j++){
                    require(tempData != keccak256(abi.encodePacked(_sigV[j], _sigR[j], _sigS[j])), "Can not be the same signature");
                }   
            }
        }
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Ownable {

    // We have owner account is for receiving the fee
    address payable public owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    function getOnwer() public view returns (address) {
        return owner;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Must be the owner of the contract.");
        _;
    }

    function transferOwnership(address payable newOwner) public isOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./BridgeToken.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*
 *  @title: EvrnetBank
 *  @dev: Bsc bank which locks BNB/BEP20/BEP721 token deposits, and unlocks
 *        BNB/BEP20/BEP721 tokens once the prophecy has been successfully processed.
 */
contract BscBank {
    using SafeERC20 for BridgeToken;

    uint256 public lockBurnNonce;

    struct RefundData {
        bool isRefunded;
        uint256 nonce;
        address sender;
        address tokenAddress;
        uint256 amount;
        string chainName;
    }
    struct UnlockData {
        bool isUnlocked;
        address operator;
        address recipient;
        address tokenAddress;
        uint256 amount;
    }

    // Mapping and check if the refunds transaction is completed
    mapping(uint256 => RefundData) internal refundCompleted;
    // Mapping and check if the unlock transaction is completed
    mapping(bytes32 => UnlockData) internal unlockCompleted;

    // For erc20
    /*
     * @dev: Event declarations
     */
    event LogLock(
        address _from,
        address _to,
        address _token,
        string _symbol,
        uint256 _value,
        uint256 _nonce,
        string _chainName
    );

    event LogUnlock(
        address _to,
        address _token,
        string _symbol,
        uint256 _value,
        bytes32 _interchainTX
    );

    event LogRefund(
        address _to,
        address _token,
        string _symbol,
        uint256 _value,
        uint256 _nonce
    );

    event LogUnlockFee(
        address _owner, 
        address _token, 
        string _symbol, 
        uint256 _fee,
        bytes32 _interchainTX

    );

    /*
     * @dev: Gets the amount of locked/funded tokens by address.
     *
     * @param _symbol: The asset's symbol.
     */
    function getLockedFunds(address _token) public view returns (uint256) {
        if (_token == address(0)) {
            return address(this).balance;
        }
        return BridgeToken(_token).balanceOf(address(this));
    }

    /*
     * @dev: Creates a new Evrynet deposit with a unique id.
     *
     * @param _sender: The sender's ethereum address.
     * @param _recipient: The intended recipient's evrnet address.
     * @param _token: The currency type, either erc20 or ethereum.
     * @param _amount: The amount of erc20 tokens/ ethereum (in wei) to be itemized.
     */
    function lockFunds(
        address payable _sender,
        address _recipient,
        address _token,
        string memory _symbol,
        uint256 _amount,
        string memory _chainName
    ) internal {
        lockBurnNonce++;

        refundCompleted[lockBurnNonce] = RefundData(
            false,
            lockBurnNonce,
            _sender,
            _token,
            _amount,
            _chainName
        );

        emit LogLock(
            _sender,
            _recipient,
            _token,
            _symbol,
            _amount,
            lockBurnNonce,
            _chainName
        );
    }

    /*
     * @dev: Unlocks funds held on contract and sends them to the
     *       intended recipient
     *
     * @param _recipient: recipient's Evrynet address
     * @param _token: token contract address
     * @param _symbol: token symbol
     * @param _amount: wei amount or ERC20 token count
     */
    function unlockFunds(
        address payable _recipient,
        address payable _owner,
        address _token,
        string memory _symbol,
        uint256 _amount,
        uint256 _fee,
        bytes32 _interchainTX
    ) internal {
        // Transfer funds to intended recipient
        if (_token == address(0)) {
            _recipient.transfer(_amount - _fee);
            _owner.transfer(_fee);
        } else {
            BridgeToken(_token).safeTransfer(_recipient, _amount);
            BridgeToken(_token).safeTransfer(_owner, _fee);
        }
        unlockCompleted[_interchainTX] = UnlockData(
            true,
            address(this),
            _recipient,
            _token,
            _amount
        );

        emit LogUnlock(_recipient, _token, _symbol, _amount - _fee, _interchainTX);
        emit LogUnlockFee(_owner, _token, _symbol, _fee, _interchainTX);
    }

    /*
     * @dev: Unlocks funds held on contract and sends them to the
     *       intended recipient
     *
     * @param _recipient: recipient's Evrynet address
     * @param _token: token contract address
     * @param _symbol: token symbol
     * @param _amount: wei amount or ERC20 token count
     */
    function refunds(
        address payable _recipient,
        address _tokenAddress,
        string memory _symbol,
        uint256 _amount,
        uint256 _nonce
    ) internal {
        // Transfer funds to intended recipient
        if (_tokenAddress == address(0)) {
            _recipient.transfer(_amount);
        } else {
            BridgeToken(_tokenAddress).safeTransfer(_recipient, _amount);
        }
        refundCompleted[_nonce].isRefunded = true;

        emit LogRefund(_recipient, _tokenAddress, _symbol, _amount, _nonce);
    }

    // For validator to check if evrything in data is correct
    function _getLockData(uint256 _nonce) internal view returns (bool, uint256, address, address, uint256, string memory){
        return (
            refundCompleted[_nonce].isRefunded,
            refundCompleted[_nonce].nonce,
            refundCompleted[_nonce].sender,
            refundCompleted[_nonce].tokenAddress,
            refundCompleted[_nonce].amount,
            refundCompleted[_nonce].chainName
        );
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract BridgeToken is ERC20 {
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../../node_modules/@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract BridgeBankPausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool internal _paused;

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "BridgeBank is paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "BridgeBank is not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}