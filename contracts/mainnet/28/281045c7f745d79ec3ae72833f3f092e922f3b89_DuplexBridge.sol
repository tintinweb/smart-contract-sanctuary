/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "OpenZeppelin/[email protected]/contracts/token/ERC20/SafeERC20.sol";
//import "OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol";
//import "OpenZeppelin/[email protected]/contracts/math/SafeMath.sol";
//import "./ITangoFactory.sol";

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC20/utils/SafeERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC20/IERC20.sol";
// //import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/utils/math/SafeMath.sol";

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

interface ITangoFactory { 
    function withdraw(uint256 _amount) external;
    function invest4(uint256[4] memory _param) external;
    function invest(address, uint256) external;
    function adminClaimRewardForSCRT(address, bytes memory) external;
    function userClaimReward() external;
}

/// @title MultiSignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <[email protected]>
/// @author Itzik Grossman - modified contract for swapping purposes
contract DuplexBridge {
    // No longer needed in 0.8+
    //using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Withdraw(uint indexed transactionId);
    event WithdrawFailure(uint indexed transactionId);
    event Swap(uint amount, bytes recipient);
    event OwnerAddition(address indexed owner);
    event FeeCollectorChange(address indexed collector);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);
    event SwapToken(address sender, bytes recipient, uint256 amount, address tokenAddress, uint256 toSCRT);
    /*
     *  Constants
     */
    uint constant public MAX_OWNER_COUNT = 50;

    /*
     *  Storage
     */
    mapping (address => uint) public tokenWhitelist;

    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    mapping(address => uint) public secretTxNonce;
    mapping(address => uint) public tokenBalances;
    mapping(address => uint) public tokenLimits;


    address[] public tokens;
    address[] public owners;
    address   public investorContract;
    address payable public feeCollector;

    uint public required;
    uint public transactionCount;
    bool public paused = false;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
        uint nonce;
        address token;
        uint amount;
        uint fee;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    // is above limit
    modifier isNotGoingAboveLimit(address _tokenAddress, uint _amount) {
		// overflow doesn't matter
        require(tokenBalances[_tokenAddress] + _amount <= tokenLimits[_tokenAddress], "Cannot swap more than hard limit");
        _;
    }

    // is not below limit
    modifier isNotUnderflowingBalance(address _tokenAddress, uint _amount) {
        require(tokenBalances[_tokenAddress] - _amount < tokenBalances[_tokenAddress], "Cannot swap more than balance");
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], "Owner does not exist");
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != address(0));
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notSubmitted(address token, uint nonce) {
        require(secretTxNonce[token] == 0 || secretTxNonce[token] < nonce, "Transaction already computed");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    modifier isSecretAddress(bytes memory _address) {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(7);
        for (i = 0; i < 7 && _address[i] != 0; i++) {
            bytesArray[i] = _address[i];
        }
        require(keccak256(bytesArray) == keccak256(bytes("secret1")));
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT
        && _required <= ownerCount
        && _required != 0
            && ownerCount != 0);
        _;
    }

    modifier notTokenWhitelisted(address token) {
        require(tokenWhitelist[token] == 0);
        _;
    }


    modifier tokenWhitelisted(address token) {
        require(tokenWhitelist[token] > 0);
        _;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    receive()
    external
    payable
    {
        revert();
    }

    /// @dev Returns the execution status of a transaction.
    /// useful in case an execution fails for some reason - so we can easily see that it failed, and handle it manually
    /// @param transactionId Transaction ID.
    /// @return Execution status.
    function isExecuted(uint transactionId)
    public
    view
    returns (bool)
    {
        return transactions[transactionId].executed;
    }

    function pauseSwaps()
    public
    onlyWallet
    {
        paused = true;
    }

    function unPauseSwaps()
    public
    //ownerExists(msg.sender) // todo: remove before production
    onlyWallet
    {
        paused = false;
    }

    function SupportedTokens()
    public
    view
    returns (address[] memory)
    {
        return tokens;
    }

    function setLimit(address _tokenAddress, uint limit)
    public
    ownerExists(msg.sender)
    {
        tokenLimits[_tokenAddress] = limit;
    }

    function changeInvestorContract(address _address)
    public
    ownerExists(msg.sender)
    // OnlyWallet todo: consider this as OnlyWallet
    {
        investorContract = _address;
    }

    function addToken(address _tokenAddress, uint min_amount, uint limit)
    public
    ownerExists(msg.sender)
    notTokenWhitelisted(_tokenAddress)
    // OnlyWallet todo: consider this as OnlyWallet
    {
        tokenWhitelist[_tokenAddress] = min_amount;
        tokenLimits[_tokenAddress] = limit;

        tokens.push(_tokenAddress);
    }

    function removeToken(address _tokenAddress)
    public
    ownerExists(msg.sender)
    // OnlyWallet todo: consider this as OnlyWallet
    {
        delete tokenWhitelist[_tokenAddress];

        for (uint i = 0; i < tokens.length - 1; i++) {
            if (tokens[i] == _tokenAddress) {
                tokens[i] = tokens[tokens.length - 1];
                break;
            }
        }
        tokens.pop();
    }

    function getTokenNonce(address _tokenAddress)
    public
    view
    returns (uint)
    {
        return secretTxNonce[_tokenAddress];
    }

    function releaseToken(address _tokenAddress, uint _amount, address _recipient, uint fee)
    public
    notPaused()
    onlyWallet()
    notNull(investorContract)
    isNotUnderflowingBalance(_tokenAddress, _amount)
    {
        ITangoFactory investor = ITangoFactory(investorContract);
        IERC20 ercToken = IERC20(_tokenAddress);

        tokenBalances[_tokenAddress] = tokenBalances[_tokenAddress] - _amount;
        
        // There's no way of knowing how many tokens we got from this, so either give us allowance
        // or we hack it this way
        uint curBalanceBefore = ercToken.balanceOf(address(this));
        
        //investor.withdrawAndClaimReward(_tokenAddress, _amount, false);
        investor.withdraw(_amount);
        
        // There's no way of knowing how many tokens we got from this, so either give us allowance
        // or we hack it this way
        uint curBalanceAfter = ercToken.balanceOf(address(this));
        
        ercToken.safeTransfer(feeCollector, fee);
        ercToken.safeTransfer(_recipient, curBalanceAfter - curBalanceBefore - fee);
    }

    /*
    * Send funds to multisig account, and emit a SwapToken event for emission to the Secret Network
    *
    * @param _recipient: The intended recipient's Secret Network address.
    * @param _amount: The amount of ENG tokens to be itemized.
    * @param _tokenAddress: The address of the token being swapped
    * @param _toSCRT: Amount of SCRT to be minted - will be deducted from the amount swapped
    */
    function swapToken(bytes memory _recipient, uint256 _amount, address _tokenAddress, uint256 _toSCRT)
    public
    notPaused()
    tokenWhitelisted(_tokenAddress)
    isSecretAddress(_recipient)
    isNotGoingAboveLimit(_tokenAddress, _amount)
    {
        IERC20 ercToken = IERC20(_tokenAddress);
        ITangoFactory investor = ITangoFactory(investorContract);

        require(_amount >= tokenWhitelist[_tokenAddress], "Require transfer greater than minimum");

        tokenBalances[_tokenAddress] = tokenBalances[_tokenAddress] + _amount;

        // if (ercToken.allowance(investorContract, address(this)) < _amount) {
        //     require(token.approve(address(recipient), uint(-1)), "Approve has failed");
        // }

        if (ercToken.allowance(address(this), investorContract) < _amount) {
            ercToken.safeApprove(investorContract, type(uint256).max);
        }

        ercToken.safeTransferFrom(msg.sender, address(this), _amount);

        investor.invest(_tokenAddress, _amount);

        emit SwapToken(
            msg.sender,
            _recipient,
            _amount,
            _tokenAddress, 
            _toSCRT
        );
    }

    function swap(bytes memory _recipient)
    public
    notPaused()
    isSecretAddress(_recipient)
    payable {
//        require(msg.value >= 1000000000000000); // 0.001 ETH
//        emit Swap(msg.value, _recipient);
        revert();
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    // todo: list of supported tokens?
    constructor (address[] memory _owners, uint _required, address payable _feeCollector, address _investorContract)
    validRequirement(_owners.length, _required)
    notNull(_feeCollector)
    notNull(_investorContract)
    {
        for (uint i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        feeCollector = _feeCollector;
        investorContract = _investorContract;
    }

    function getFeeCollector()
    public
    view
    returns (address)
    {
        return feeCollector;
    }

    /// @dev Allows change of the fee collector address. Transaction has to be sent by wallet.
    /// @param _feeCollector Address that fees will be sent to.
    function replaceFeeCollector(address payable _feeCollector)
    public
    onlyWallet
    notNull(_feeCollector)
    {
        feeCollector = _feeCollector;
        emit FeeCollectorChange(_feeCollector);
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
    public
    onlyWallet
    ownerDoesNotExist(owner)
    notNull(owner)
    validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
    public
    onlyWallet
    ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i = 0; i < owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.pop();
        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address owner, address newOwner)
    public
    onlyWallet
    ownerExists(owner)
    ownerDoesNotExist(newOwner)
    notNull(newOwner)
    {
        for (uint i = 0; i < owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
    public
    onlyWallet
    validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param fee amount of token or ether to transfer to fee collector
    /// @param data Transaction data payload.
    /// @return transactionId - Returns transaction ID.
    function submitTransaction(address destination, uint value, uint nonce, address token, uint fee, uint amount, bytes memory data)
    public
    ownerExists(msg.sender)
    notSubmitted(token, nonce)
    isNotUnderflowingBalance(token, amount)
    returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, nonce, token, fee, amount, data);
        secretTxNonce[token] = nonce;

        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
    public
    ownerExists(msg.sender)
    transactionExists(transactionId)
    notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
    public
    ownerExists(msg.sender)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /// @dev Transfers the amount in tnx.fee to the fee collector
    /// @param transactionId Transaction ID.
    function collectFee(uint transactionId)
    internal
    {
        Transaction storage txn = transactions[transactionId];
        if (txn.token == address(0)) {
            feeCollector.transfer(txn.fee);
        } else {
            IERC20 token = IERC20(txn.token);
            token.safeTransfer(feeCollector, txn.fee);
        }
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
    public
    ownerExists(msg.sender)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];

            txn.executed = true;

            if (txn.fee > 0) {
                collectFee(transactionId);
            }

            require(gasleft() >= 3000);

            if (external_call(txn.destination, txn.value, txn.data, gasleft() - 3000))
                emit Withdraw(transactionId);
            else {
                emit WithdrawFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint value, bytes memory data, uint256 txGas)
        internal
        returns (bool success) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := call(
                txGas,
                destination,
                value,
                add(data, 0x20),     // First 32 bytes are the padded length of data, so exclude that
                mload(data),       // Size of the input (in bytes) - this is what fixes the padding problem
                0,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return success;
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
    public
    view
    returns (bool)
    {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
        return false;
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return transactionId - Returns transaction ID.
    function addTransaction(address destination, uint value, uint nonce, address token, uint fee, uint amount, bytes memory data)
    internal
    notNull(destination)
    returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination : destination,
            value : value,
            data : data,
            executed : false,
            nonce : nonce,
            token : token,
            amount: amount,
            fee: fee
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return count - Number of confirmations.
    function getConfirmationCount(uint transactionId)
    public
    view
    returns (uint count)
    {
        for (uint i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return count - Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
    public
    view
    returns (uint count)
    {
        for (uint i = 0; i < transactionCount; i++)
            if (pending && !transactions[i].executed
            || executed && transactions[i].executed)
                count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
    public
    view
    returns (address[] memory)
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return _confirmations - Returns array of owner addresses.
    function getConfirmations(uint transactionId)
    public
    view
    returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return _transactionIds - Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
    public
    view
    returns (uint[] memory _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i = 0; i < transactionCount; i++)
            if (pending && !transactions[i].executed
            || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i = from; i < to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}