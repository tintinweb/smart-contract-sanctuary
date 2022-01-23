/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
    {
        return
        functionStaticCall(
            target,
            data,
            "Address: low-level static call failed"
        );
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
    function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
    {
        return
        functionDelegateCall(
            target,
            data,
            "Address: low-level delegate call failed"
        );
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

// File: Louverture/interfaces/IERC20.sol


pragma solidity ^0.8.0;

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
// File: Louverture/library/SafeERC20.sol


pragma solidity ^0.8.0;



// OpenZeppelin Contracts v4.3.2 (token/ERC20/utils/SafeERC20.sol)

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        //unchecked {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(
            oldAllowance >= value,
            "SafeERC20: decreased allowance below zero"
        );
        uint256 newAllowance = oldAllowance - value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
        //}
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: Louverture/interfaces/IERC20Metadata.sol


pragma solidity ^0.8.0;


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

// File: Louverture/abstract/Context.sol


pragma solidity ^0.8.0;

/*
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

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// File: Louverture/contract/PaymentSplitter.sol


pragma solidity ^0.8.0;





// OpenZeppelin Contracts v4.3.2 (finance/PaymentSplitter.sol)

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(
        IERC20 indexed token,
        address to,
        uint256 amount
    );
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(
            payees.length == shares_.length,
            "PaymentSplitter: payees and shares length mismatch"
        );
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account)
    public
    view
    returns (uint256)
    {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(account)
        );

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) +
        totalReleased(token);
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(token, account)
        );

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return
        (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(
            account != address(0),
            "PaymentSplitter: account is the zero address"
        );
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(
            _shares[account] == 0,
            "PaymentSplitter: account already has shares"
        );

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

// File: Louverture/contract/Ownable.sol


pragma solidity ^0.8.0;


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// File: Louverture/interfaces/IPancakePair.sol


pragma solidity ^0.8.0;

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
// File: Louverture/interfaces/IPancakeFactory.sol


pragma solidity ^0.8.0;

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
// File: Louverture/interfaces/IPancakeRouter01.sol


pragma solidity ^0.8.0;

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
// File: Louverture/interfaces/IPancakeRouter02.sol


pragma solidity ^0.8.0;


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
// File: Louverture/library/IterableMapping.sol


pragma solidity ^0.8.0;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
    public
    view
    returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
    public
    view
    returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}
// File: Louverture/library/SafeMath.sol


pragma solidity ^0.8.0;

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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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

// File: NODERewardManagement.sol


pragma solidity ^0.8.0;



contract NODERewardManagement {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    struct NodeEntity {
        string name;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 lastSellTime;
        uint256 rewardMult;
        uint256 nodeValue;
        uint256 rewardAvailable;
        uint256 addValueCount;
    }

    IterableMapping.Map private nodeOwners;
    mapping(address => NodeEntity[]) private _nodesOfUser;

    uint256 public nodeMinPrice;
    uint256 public rewardPerValue;
    uint256 public claimTime;
    uint256 public sellTime;
    uint256 public sellPercent;

    address public gateKeeper;
    address public token;

    bool public autoDistri = true;
    bool public distribution = false;

    uint256 public gasForDistribution = 300000;
    uint256 public lastDistributionCount = 0;
    uint256 public lastIndexProcessed = 0;

    uint256[] public tierLevel = [100000,105000,110000,120000,130000,140000];
    uint256[] public tierSlope = [1000,500,100,50,10,0];

    uint256 public totalNodesCreated = 0;
    uint256 public totalRewardStaked = 0;

    constructor(
        uint256 _nodeMinPrice,
        uint256 _rewardPerValue,
        uint256 _claimTime,
        uint256 _sellTime,
        uint256 _sellPercent
    ) {
        nodeMinPrice = _nodeMinPrice;
        rewardPerValue = _rewardPerValue;
        claimTime = _claimTime;
        sellTime = _sellTime;
        sellPercent = _sellPercent;
        gateKeeper = msg.sender;
    }

    modifier onlySentry() {
        require(msg.sender == token || msg.sender == gateKeeper, "Fuck off");
        _;
    }

    function setToken (address token_) external onlySentry {
        token = token_;
    }

    function distributeRewards(uint256 gas, uint256 rewardValue)
    private
    returns (
        uint256,
        uint256,
        uint256
    )
    {
        distribution = true;
        uint256 numberOfnodeOwners = nodeOwners.keys.length;
        require(numberOfnodeOwners > 0, "DISTRI REWARDS: NO NODE OWNERS");
        if (numberOfnodeOwners == 0) {
            return (0, 0, lastIndexProcessed);
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 newGasLeft;
        uint256 localLastIndex = lastIndexProcessed;
        uint256 iterations = 0;
        uint256 newClaimTime = block.timestamp;
        uint256 nodesCount;
        uint256 claims = 0;
        NodeEntity[] storage nodes;
        NodeEntity storage _node;

        while (gasUsed < gas && iterations < numberOfnodeOwners) {
            localLastIndex++;
            if (localLastIndex >= nodeOwners.keys.length) {
                localLastIndex = 0;
            }
            nodes = _nodesOfUser[nodeOwners.keys[localLastIndex]];
            nodesCount = nodes.length;
            for (uint256 i = 0; i < nodesCount; i++) {
                _node = nodes[i];
                if (claimable(_node)) {
                    _node.rewardAvailable += rewardValue;
                    _node.lastClaimTime = newClaimTime;
                    totalRewardStaked += rewardValue;
                    claims++;
                }
            }
            iterations++;

            newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }
        lastIndexProcessed = localLastIndex;
        distribution = false;
        return (iterations, claims, lastIndexProcessed);
    }

    function createNode(address account, string memory nodeName, uint256  _nodeInitialValue) external onlySentry {
        require(
            isNameAvailable(account, nodeName),
            "CREATE NODE: Name not available"
        );
        _nodesOfUser[account].push(
            NodeEntity({
                name: nodeName,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                lastSellTime: block.timestamp,
                rewardMult: 100000,
                nodeValue: _nodeInitialValue,
                addValueCount: 0,
                rewardAvailable: rewardPerValue
            })
        );
        nodeOwners.set(account, _nodesOfUser[account].length);
        totalNodesCreated++;
        if (autoDistri && !distribution) {
            distributeRewards(gasForDistribution, rewardPerValue);
        }
    }

    function isNameAvailable(address account, string memory nodeName)
    private
    view
    returns (bool)
    {
        NodeEntity[] memory nodes = _nodesOfUser[account];
        for (uint256 i = 0; i < nodes.length; i++) {
            if (keccak256(bytes(nodes[i].name)) == keccak256(bytes(nodeName))) {
                return false;
            }
        }
        return true;
    }

    function _burn(uint256 index) internal {
        require(index < nodeOwners.size());
        nodeOwners.remove(nodeOwners.getKeyAtIndex(index));
    }

    function _getNodeWithCreatime(
        NodeEntity[] storage nodes,
        uint256 _creationTime
    ) private view returns (NodeEntity storage) {
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        bool found = false;
        int256 index = binary_search(nodes, 0, numberOfNodes, _creationTime);
        uint256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = uint256(index);
        }
        require(found, "NODE SEARCH: No NODE Found with this blocktime");
        return nodes[validIndex];
    }

    function binary_search(
        NodeEntity[] memory arr,
        uint256 low,
        uint256 high,
        uint256 x
    ) private view returns (int256) {
        if (high >= low) {
            uint256 mid = (high + low).div(2);
            if (arr[mid].creationTime == x) {
                return int256(mid);
            } else if (arr[mid].creationTime > x) {
                return binary_search(arr, low, mid - 1, x);
            } else {
                return binary_search(arr, mid + 1, high, x);
            }
        } else {
            return -1;
        }
    }

    function _cashoutNodeReward(address account, uint256 _creationTime)
    external onlySentry
    returns (uint256)
    {
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
        uint256 rewardNode = node.rewardAvailable.mul(node.rewardMult).mul(node.nodeValue).div(100000).div(1e18);
        node.rewardAvailable = 0;
        node.rewardMult = 100000;
        node.addValueCount = 0;
        return rewardNode;
    }

    function _cashoutAllNodesReward(address account)
    external onlySentry
    returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity storage _node;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            rewardsTotal += _node.rewardAvailable.mul(_node.rewardMult).mul(_node.nodeValue).div(100000).div(1e18);
            _node.rewardAvailable = 0;
            _node.rewardMult = 100000;
            _node.addValueCount = 0;
        }
        return rewardsTotal;
    }

    function _sellTokensInAllNodes(address account, bool isWhiteUser)
    external onlySentry
    returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity storage _node;
        uint256 rewardsTotal = 0;
        uint256 rewardsTemp = 0;
        uint256 totalPercent = 100;
        uint256 availablePercent = totalPercent.sub(sellPercent);

        if (isWhiteUser) {
            for (uint256 i = 0; i < nodesCount; i++) {
                _node = nodes[i];
                rewardsTotal += _node.rewardAvailable.mul(_node.rewardMult).mul(_node.nodeValue).div(100000).div(1e18);
                _node.rewardAvailable = 0;
                _node.rewardMult = 100000;
                _node.addValueCount = 0;
            }
        } else {
            for (uint256 i = 0; i < nodesCount; i++) {
                _node = nodes[i];
                if (sellable(_node)) {
                    rewardsTemp = _node.rewardAvailable.mul(_node.rewardMult).mul(_node.nodeValue).div(100000).div(1e18);
                    rewardsTotal += rewardsTemp.mul(sellPercent).div(totalPercent);
                    _node.rewardAvailable = _node.rewardAvailable.mul(availablePercent).div(totalPercent);
                    _node.lastSellTime = block.timestamp;
                }
            }
        }
        
        return rewardsTotal;
    }

    function _addNodeValue(address account, uint256 _creationTime)
    external onlySentry
    returns (uint256)
    {
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
        uint256 rewardNode = node.rewardAvailable.mul(node.rewardMult).mul(node.nodeValue).div(100000).div(1e18);
        node.nodeValue += rewardNode;
        uint256 prevMult = node.rewardMult;
        if (rewardNode > 0) {
            if (prevMult >= tierLevel[5]) {
                node.rewardMult += tierSlope[5];
            } else if (prevMult >= tierLevel[4]) {
                node.rewardMult += tierSlope[4];
            } else if (prevMult >= tierLevel[3]) {
                node.rewardMult += tierSlope[2];
            } else if (prevMult >= tierLevel[2]) {
                node.rewardMult += tierSlope[2];
            } else if (prevMult >= tierLevel[1]) {
                node.rewardMult += tierSlope[1]; 
            } else {
                node.rewardMult += tierSlope[0];
            }

            node.rewardAvailable = 0;
            node.addValueCount += 1;
        }
        return rewardNode;
    }

    function _addAllNodeValue(address account)
    external onlySentry
    returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity storage _node;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            rewardsTotal += _node.rewardAvailable.mul(_node.rewardMult).mul(_node.nodeValue).div(100000).div(1e18);
            _node.nodeValue += _node.rewardAvailable.mul(_node.rewardMult).mul(_node.nodeValue).div(100000).div(1e18);
            uint256 prevMult = _node.rewardMult;
            if ( _node.rewardAvailable > 0) {
                if (prevMult >= tierLevel[5]) {
                    _node.rewardMult += tierSlope[5];
                } else if (prevMult >= tierLevel[4]) {
                    _node.rewardMult += tierSlope[4];
                } else if (prevMult >= tierLevel[3]) {
                    _node.rewardMult += tierSlope[2]; 
                } else if (prevMult >= tierLevel[2]) {
                    _node.rewardMult += tierSlope[2];
                } else if (prevMult >= tierLevel[1]) {
                    _node.rewardMult += tierSlope[1];
                } else {
                    _node.rewardMult += tierSlope[0];
                }
                _node.rewardAvailable = 0;
                _node.addValueCount += 1; 
            }
        }
        return rewardsTotal;
    }

    function claimable(NodeEntity memory node) private view returns (bool) {
        return node.lastClaimTime + claimTime <= block.timestamp;
    }

    function sellable(NodeEntity memory node) private view returns (bool) {
        return node.lastSellTime + sellTime <= block.timestamp;
    }

    function _getNodeValueOf(address account)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        uint256 nodesCount;
        uint256 valueCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            valueCount += nodes[i].nodeValue;
        }

        return valueCount;
    }


    function _getNodeValueOf(address account, uint256 _creationTime)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
        uint256 valueNode = node.nodeValue;
        return valueNode;
    }


    function _getNodeValueAmountOf(address account, uint256 creationTime)
    external
    view
    returns (uint256)
    {
        return
        _getNodeWithCreatime(_nodesOfUser[account], creationTime)
        .nodeValue;
    }

    function _getAddValueCountOf(address account, uint256 _creationTime)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
        uint256 valueNode = node.addValueCount;
        return valueNode;
    }

    function _getRewardMultOf(address account)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        uint256 nodesCount;
        uint256 valueCount = 0;
        uint256 totalCount = 0;
        uint256 rewardMult;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            totalCount += nodes[i].nodeValue.mul(nodes[i].rewardMult);
            valueCount += nodes[i].nodeValue;
        }

        rewardMult = totalCount.div(valueCount);

        return rewardMult;
    }


    function _getRewardMultOf(address account, uint256 _creationTime)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
        uint256 valueNode = node.rewardMult;
        return valueNode;
    }

    function _getRewardMultAmountOf(address account, uint256 creationTime)
    external
    view
    returns (uint256)
    {
        return
        _getNodeWithCreatime(_nodesOfUser[account], creationTime)
        .rewardMult;
    }


    function _getRewardAmountOf(address account)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        uint256 nodesCount;
        uint256 rewardCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            rewardCount += nodes[i].rewardAvailable.mul(nodes[i].rewardMult).mul(nodes[i].nodeValue).div(100000).div(1e18);
        }

        return rewardCount;
    }


    function _getRewardAmountOf(address account, uint256 _creationTime)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
        uint256 rewardNode = node.rewardAvailable.mul(node.rewardMult).mul(node.nodeValue).div(100000).div(1e18);
        return rewardNode;
    }

    function _getNodeRewardAmountOf(address account, uint256 creationTime)
    external
    view
    returns (uint256)
    {
        return
        _getNodeWithCreatime(_nodesOfUser[account], creationTime)
        .rewardAvailable.mul(_getNodeWithCreatime(_nodesOfUser[account], creationTime).rewardMult).mul(_getNodeWithCreatime(_nodesOfUser[account], creationTime).nodeValue).div(100000).div(1e18);
    }

    function _getNodesNames(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET NAMES: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory names = nodes[0].name;
        string memory separator = "#";
        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            names = string(abi.encodePacked(names, separator, _node.name));
        }
        return names;
    }

    function _getNodesCreationTime(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _creationTimes = uint2str(nodes[0].creationTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _creationTimes = string(
                abi.encodePacked(
                    _creationTimes,
                    separator,
                    uint2str(_node.creationTime)
                )
            );
        }
        return _creationTimes;
    }

    function _getNodesRewardAvailable(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET REWARD: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _rewardsAvailable = uint2str(nodes[0].rewardAvailable.mul(nodes[0].rewardMult).mul(nodes[0].nodeValue).div(100000).div(1e18));
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            uint256 _totalReward = _node.rewardAvailable.mul(_node.rewardMult).mul(_node.nodeValue).div(100000).div(1e18);
            _rewardsAvailable = string(
                abi.encodePacked(
                    _rewardsAvailable,
                    separator,
                    uint2str(_totalReward)
                )
            );
        }
        return _rewardsAvailable;
    }

    function _getNodesLastClaimTime(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "LAST CLAIME TIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _lastClaimTimes = uint2str(nodes[0].lastClaimTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _lastClaimTimes = string(
                abi.encodePacked(
                    _lastClaimTimes,
                    separator,
                    uint2str(_node.lastClaimTime)
                )
            );
        }
        return _lastClaimTimes;
    }

    function _getNodesLastSellTime(address account)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "LAST SELL TIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account]; 
        return nodes[0].lastSellTime;
    }

    function uint2str(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _changeNodeMinPrice(uint256 newNodeMinPrice) external onlySentry {
        nodeMinPrice = newNodeMinPrice;
    }

    function _changeRewardPerValue(uint256 newPrice) external onlySentry {
        rewardPerValue = newPrice;
    }

    function _changeClaimTime(uint256 newTime) external onlySentry {
        claimTime = newTime;
    }

    function _changeSellTime(uint256 newTime) external onlySentry {
        sellTime = newTime;
    }

    function _changeSellPercent(uint256 newPercent) external onlySentry {
        require(newPercent >= 0, "Must be equal or greater than 0");
        require(newPercent <= 100, "Must be equal or smaller than 100");
        sellPercent = newPercent;
    }

    function _changeAutoDistri(bool newMode) external onlySentry {
        autoDistri = newMode;
    }

    function _changeTierSystem(uint256[] memory newTierLevel, uint256[] memory newTierSlope) external onlySentry {
        tierLevel = newTierLevel;
        tierSlope = newTierSlope;
    }

    function _changeGasDistri(uint256 newGasDistri) external onlySentry {
        gasForDistribution = newGasDistri;
    }

    function _getNodeNumberOf(address account) public view returns (uint256) {
        return nodeOwners.get(account);
    }

    function isNodeOwner(address account) private view returns (bool) {
        return nodeOwners.get(account) > 0;
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return isNodeOwner(account);
    }

    function _distributeRewards()
    external  onlySentry
    returns (
        uint256,
        uint256,
        uint256
    )
    {
        return distributeRewards(gasForDistribution, rewardPerValue);
    }
}

// File: Louverture/contract/ERC20.sol


pragma solidity ^0.8.0;





contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
    function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
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
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
     * will be to transferred to `to`.
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
}

// File: LVT.sol


pragma solidity ^0.8.0;











contract LVT is ERC20, Ownable, PaymentSplitter {
    using SafeMath for uint256;

    NODERewardManagement public nodeRewardManager;

    // IJoeRouter02 public uniswapV2Router;
    IPancakeRouter02 public uniswapV2Router;

    address public uniswapV2Pair;
    address public futurUsePool;
    address public distributionPool;
    address public devPool;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 public rewardsFee;
    uint256 public liquidityPoolFee;
    uint256 public futurFee;
    uint256 public totalFees;

    uint256 public cashoutFee;

    uint256 private rwSwap;
    uint256 private devShare;
    bool private swapping = false;
    bool private swapLiquify = true;
    uint256 public swapTokensAmount;

    bool private tradingOpen = false;
    uint256 private snipeBlockAmt;
    uint256 private _openTradingBlock = 0;
    uint256 private maxTx = 1;

    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public _isWhitelisted;
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(
        address[] memory payees,
        uint256[] memory shares,
        address[] memory addresses,
        uint256[] memory balances,
        address uniV2Router,
        uint256 snipeBlkAmt
    ) ERC20("Louverture", "LVT") PaymentSplitter(payees, shares) {

        futurUsePool = addresses[4];
        distributionPool = addresses[5];
        devPool = addresses[6];
        snipeBlockAmt = snipeBlkAmt;

        require(futurUsePool != address(0) && distributionPool != address(0) && devPool != address(0), "FUTUR, DEV & REWARD ADDRESS CANNOT BE ZERO");

        require(uniV2Router != address(0), "ROUTER CANNOT BE ZERO");
        IPancakeRouter02 _uniswapV2Router = IPancakeRouter02(uniV2Router);

        address _uniswapV2Pair = IPancakeFactory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        futurFee = 20;
        rewardsFee = 70;
        liquidityPoolFee = 10;
        cashoutFee = 10;
        rwSwap = 4;
        devShare = 50;

        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);

        require(addresses.length > 0 && balances.length > 0, "CONSTR: addresses array length must be greater than zero");
        require(addresses.length == balances.length, "CONSTR: addresses arrays length mismatch");

        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], balances[i] * (10**18));
        }
        require(totalSupply() == 1000000000e18, "CONSTR: totalSupply must equal 1 billion");
        swapTokensAmount = 500 * (10**18);
    }

    function setNodeManagement(address nodeManagement) external onlyOwner {
        nodeRewardManager = NODERewardManagement(nodeManagement);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "TKN: The router already has that address");
        
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IPancakeRouter02(newAddress);
        
        address _uniswapV2Pair = IPancakeFactory(uniswapV2Router.factory())
        .createPair(address(this), uniswapV2Router.WETH());

        uniswapV2Pair = _uniswapV2Pair;
    }

    function updateSwapTokensAmount(uint256 newVal) external onlyOwner {
        swapTokensAmount = newVal;
    }

    function updateFuturWall(address payable wall) external onlyOwner {
        futurUsePool = wall;
    }

    function updateDevWall(address payable wall) external onlyOwner {
        devPool = wall;
    }

    function updateRewardsWall(address payable wall) external onlyOwner {
        distributionPool = wall;
    }

    function updateRewardsFee(uint256 value) external onlyOwner {
        rewardsFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);
    }

    function updateLiquiditFee(uint256 value) external onlyOwner {
        liquidityPoolFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);
    }

    function updateFuturFee(uint256 value) external onlyOwner {
        futurFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);
    }

    function updateCashoutFee(uint256 value) external onlyOwner {
        cashoutFee = value;
    }

    function updateRwSwapFee(uint256 value) external onlyOwner {
        rwSwap = value;
    }

    function updateDevShare(uint256 value) external onlyOwner {
        devShare = value;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "TKN: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function blacklistMalicious(address account, bool value)
    external
    onlyOwner
    {
        _isBlacklisted[account] = value;
    }

    function whitelistBounty(address account, bool value)
    external
    onlyOwner
    {
        _isWhitelisted[account] = value;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "TKN: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(
            !_isBlacklisted[from] && !_isBlacklisted[to],
            "Blacklisted address"
        );
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (from != address(this) && to == uniswapV2Pair && !_isWhitelisted[from]) {
            require(nodeRewardManager._isNodeOwner(from), "Can't sell token if you don't have node");
            require(getNodesLastSells(from) + getSellTime() <= block.timestamp, "Can sell once by day");

            // uint256 maxSellAmount = balanceOf(from).mul(getSellPercent()).div(100);
            uint256 maxSellAmount = getAllNodeValueOf(from).mul(getSellPercent()).div(100);
            require(amount < maxSellAmount, "Can sell only specific percent max of their node token");
        }

        if (from != owner() && to != uniswapV2Pair && to != address(uniswapV2Router) && to != address(this) && from != address(this)) {
            require(tradingOpen, "Trading not yet enabled.");

            // anti whale
            if (to != futurUsePool && to != distributionPool && to != devPool && from != futurUsePool && from != distributionPool && from != devPool) {
                uint256 totalSupply = totalSupply();
                uint256 walletBalance = balanceOf(address(to));
                require(
                    amount.add(walletBalance) <= totalSupply.mul(maxTx).div(10000), 
                    "STOP TRYING TO BECOME A WHALE. WE KNOW WHO YOU ARE.")
                ;
            }
        }
        super._transfer(from, to, amount);
    }

    function swapAndSendToFee(address destination, uint256 tokens) private {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance).sub(initialETHBalance);
        payable(destination).transfer(newBalance);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    // function sellTokensForEth() external {
    //     address sender = _msgSender();
    //     require(sender != address(0), "MANIA CSHT:  creation from the zero address");
    //     require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
    //     require(sender != futurUsePool && sender != distributionPool, "MANIA CSHT: futur and rewardsPool cannot cashout rewards");
    //     uint256 rewardAmount = 0;
    //     if (_isWhitelisted[sender]) {
    //         rewardAmount = nodeRewardManager._getRewardAmountOf(sender);
    //     } else {
    //         rewardAmount = nodeRewardManager._getRewardAmountOf(sender).mul(getSellPercent()).div(100);
    //     }

    //     require(rewardAmount > 0,"MANIA CSHT: You don't have enough reward to cash out");
    //     if (!_isWhitelisted[sender]) {
    //         require(nodeRewardManager._isNodeOwner(_msgSender()), "Can't sell token if you don't have node");
    //         require(getNodesLastSells() + getSellTime() <= block.timestamp, "Can sell once by day");
    //     }
    //     if (swapLiquify && !_isWhitelisted[sender]) {
    //         uint256 feeAmount;
    //         if (cashoutFee > 0) {
    //             feeAmount = rewardAmount.mul(cashoutFee).div(100);
    //             swapAndSendToFee(futurUsePool, feeAmount);
    //         }
    //         rewardAmount -= feeAmount;
    //     }
    //     super._transfer(distributionPool, address(this), rewardAmount);
    //     swapAndSendToFee(sender, rewardAmount);
    //     nodeRewardManager._sellTokensInAllNodes(sender, _isWhitelisted[sender]);
    // }

    // swap tokenAmount of Tokens into Eth in this contract address
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0),
            block.timestamp
        );
    }

    function createNodeWithTokens(string memory name, uint256  _initValue) public {
        require(
            bytes(name).length > 3 && bytes(name).length < 32,
            "NODE CREATION: NAME SIZE INVALID"
        );
        address sender = _msgSender();
        require(
            sender != address(0),
            "NODE CREATION:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "NODE CREATION: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool && sender != devPool,
            "NODE CREATION: futur, dev and rewardsPool cannot create node"
        );

        uint256 nodeMinPrice = nodeRewardManager.nodeMinPrice();
        uint256 nodePrice = _initValue;
        require(
            nodePrice >= nodeMinPrice,
            "NODE CREATION: Node Value set below nodeMinPrice"
        );
        require(
            balanceOf(sender) >= nodePrice.mul(1e18),
            "NODE CREATION: Balance too low for creation. Use lower initValue"
        );
        uint256 contractTokenBalance = balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (
            swapAmountOk &&
            swapLiquify &&
            !swapping &&
            sender != owner() &&
            !_isWhitelisted[sender] &&
            !automatedMarketMakerPairs[sender]
        ) {
            swapping = true;

            uint256 fdTokens = contractTokenBalance.mul(futurFee).div(100);
            uint256 devTokens = fdTokens.mul(devShare).div(100);
            uint256 futurTokens = fdTokens.sub(devTokens);

            swapAndSendToFee(devPool, devTokens);
            swapAndSendToFee(futurUsePool, futurTokens);

            uint256 rewardsPoolTokens = contractTokenBalance
            .mul(rewardsFee)
            .div(100);

            uint256 rewardsTokenstoSwap = rewardsPoolTokens.mul(rwSwap).div(
                100
            );

            swapAndSendToFee(distributionPool, rewardsTokenstoSwap);
            super._transfer(
                address(this),
                distributionPool,
                rewardsPoolTokens.sub(rewardsTokenstoSwap)
            );

            uint256 swapTokens = contractTokenBalance.mul(liquidityPoolFee).div(
                100
            );

            swapAndLiquify(swapTokens);

            swapTokensForEth(balanceOf(address(this)));

            swapping = false;
        }
        super._transfer(sender, address(this), nodePrice.mul(1e18));
        nodeRewardManager.createNode(sender, name, _initValue.mul(1e18));
    }

    function cashoutReward(uint256 blocktime) public {
        address sender = _msgSender();
        require(sender != address(0), "CSHT:  creation from the zero address");
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "CSHT: futur and rewardsPool cannot cashout rewards"
        );
        uint256 rewardAmount = nodeRewardManager._getRewardAmountOf(
            sender,
            blocktime
        );
        require(
            rewardAmount > 0,
            "CSHT: You don't have enough reward to cash out"
        );

        if (swapLiquify && !_isWhitelisted[sender]) {
            uint256 feeAmount;
            if (cashoutFee > 0) {
                feeAmount = rewardAmount.mul(cashoutFee).div(100);
                swapAndSendToFee(futurUsePool, feeAmount);
            }
            rewardAmount -= feeAmount;
        }
        super._transfer(distributionPool, sender, rewardAmount);
        nodeRewardManager._cashoutNodeReward(sender, blocktime);
    }

    function cashoutAll() public {
        address sender = _msgSender();
        require(
            sender != address(0),
            "MANIA CSHT:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "MANIA CSHT: futur and rewardsPool cannot cashout rewards"
        );
        uint256 rewardAmount = nodeRewardManager._getRewardAmountOf(sender);
        require(
            rewardAmount > 0,
            "MANIA CSHT: You don't have enough reward to cash out"
        );
        if (swapLiquify && !_isWhitelisted[sender]) {
            uint256 feeAmount;
            if (cashoutFee > 0) {
                feeAmount = rewardAmount.mul(cashoutFee).div(100);
                swapAndSendToFee(futurUsePool, feeAmount);
            }
            rewardAmount -= feeAmount;
        }
        super._transfer(distributionPool, sender, rewardAmount);
        nodeRewardManager._cashoutAllNodesReward(sender);
    }

    function addNodeValue(uint256 blocktime) public {
        address sender = _msgSender();
        require(sender != address(0), "CSHT:  creation from the zero address");
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool && sender != devPool,
            "CSHT: futur, dev and rewardsPool cannot compound nodes"
        );
        uint256 rewardAmount = nodeRewardManager._getRewardAmountOf(
            sender,
            blocktime
        );
        require(
            rewardAmount > 0,
            "CSHT: You don't have enough reward to compound your node"
        );

        if (swapLiquify && !_isWhitelisted[sender]) {
            uint256 feeAmount;
            if (cashoutFee > 0) {
                feeAmount = rewardAmount.mul(cashoutFee).div(100);
                swapAndSendToFee(devPool, feeAmount);
            }
            rewardAmount -= feeAmount;
        }

        super._transfer(distributionPool, address(this), rewardAmount);
        nodeRewardManager._addNodeValue(sender, blocktime);
    }

    function addAllNodeValue() public {
        address sender = _msgSender();
        require(
            sender != address(0),
            "MANIA CSHT:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool && sender != devPool,
            "MANIA CSHT: futur, dev and rewardsPool cannot cashout rewards"
        );
        uint256 rewardAmount = nodeRewardManager._getRewardAmountOf(sender);
        require(
            rewardAmount > 0,
            "MANIA CSHT: You don't have enough reward to compound"
        );
        if (swapLiquify && !_isWhitelisted[sender]) {
            uint256 feeAmount;
            if (cashoutFee > 0) {
                feeAmount = rewardAmount.mul(cashoutFee).div(100);
                swapAndSendToFee(devPool, feeAmount);
            }
            rewardAmount -= feeAmount;
        }
        super._transfer(distributionPool, address(this), rewardAmount);
        nodeRewardManager._addAllNodeValue(sender);
    }

    function getNodeMultiplier(uint256 blocktime) public view returns (uint256) {
        return nodeRewardManager._getRewardMultOf(
            _msgSender(),
            blocktime
        );
    }

    function getNodeMultiplierOf(address account, uint256 blocktime) public view returns(uint256) {
        return nodeRewardManager._getRewardMultOf(
            account,
            blocktime
        );
    }

    function getNodeValue(uint256 blocktime) public view returns (uint256) {
        return nodeRewardManager._getNodeValueOf(
            _msgSender(),
            blocktime
        );
    }

    function getNodeValueOf(address account, uint256 blocktime) public view returns(uint256) {
        return nodeRewardManager._getNodeValueOf(
            account,
            blocktime
        );
    }

    function getAllNodeValue() public view returns (uint256) {
        return nodeRewardManager._getNodeValueOf(
            _msgSender()
        );
    }

    function getAllNodeValueOf(address account) public view returns (uint256) {
        return nodeRewardManager._getNodeValueOf(
            account
        );
    }

    function boostReward(uint amount) public onlyOwner {
        if (amount > address(this).balance) amount = address(this).balance;
        payable(owner()).transfer(amount);
    }


    function changeSwapLiquify(bool newVal) public onlyOwner {
        swapLiquify = newVal;
    }

    function getNodeNumberOf(address account) public view returns (uint256) {
        return nodeRewardManager._getNodeNumberOf(account);
    }

    function getRewardAmountOf(address account)
    public
    view
    onlyOwner
    returns (uint256)
    {
        return nodeRewardManager._getRewardAmountOf(account);
    }

    function getRewardAmount() public view returns (uint256) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(
            nodeRewardManager._isNodeOwner(_msgSender()),
            "NO NODE OWNER"
        );
        return nodeRewardManager._getRewardAmountOf(_msgSender());
    }

    function changeNodeMinPrice(uint256 newNodeMinPrice) public onlyOwner {
        nodeRewardManager._changeNodeMinPrice(newNodeMinPrice);
    }

    function changeTierSystem(uint256[] memory newTierLevels, uint256[] memory newTierSlopes) public onlyOwner {
        require(newTierLevels.length == 6, "newTierLevels length has to be 6");
        require(newTierSlopes.length == 6, "newTierSlopes length has to be 6");
        nodeRewardManager._changeTierSystem(newTierLevels, newTierSlopes);
    }

    function getNodeMinPrice() public view returns (uint256) {
        return nodeRewardManager.nodeMinPrice();
    }

    function changeRewardPerValue(uint256 newPrice) public onlyOwner {
        nodeRewardManager._changeRewardPerValue(newPrice);
    }

    function getRewardPerValue() public view returns (uint256) {
        return nodeRewardManager.rewardPerValue();
    }

    function changeClaimTime(uint256 newTime) public onlyOwner {
        nodeRewardManager._changeClaimTime(newTime);
    }

    function getClaimTime() public view returns (uint256) {
        return nodeRewardManager.claimTime();
    }

    function changeSellTime(uint256 newTime) public onlyOwner {
        nodeRewardManager._changeSellTime(newTime);
    }

    function getSellTime() public view returns (uint256) {
        return nodeRewardManager.sellTime();
    }

    function changeSellPercent(uint256 newPercent) public onlyOwner {
        nodeRewardManager._changeSellPercent(newPercent);
    }

    function getSellPercent() public view returns (uint256) {
        return nodeRewardManager.sellPercent();
    }

    function changeAutoDistri(bool newMode) public onlyOwner {
        nodeRewardManager._changeAutoDistri(newMode);
    }

    function getAutoDistri() public view returns (bool) {
        return nodeRewardManager.autoDistri();
    }

    function changeGasDistri(uint256 newGasDistri) public onlyOwner {
        nodeRewardManager._changeGasDistri(newGasDistri);
    }

    function getGasDistri() public view returns (uint256) {
        return nodeRewardManager.gasForDistribution();
    }

    function getDistriCount() public view returns (uint256) {
        return nodeRewardManager.lastDistributionCount();
    }

    function getNodesNames() public view returns (string memory) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(
            nodeRewardManager._isNodeOwner(_msgSender()),
            "NO NODE OWNER"
        );
        return nodeRewardManager._getNodesNames(_msgSender());
    }

    function getNodesCreatime() public view returns (string memory) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(
            nodeRewardManager._isNodeOwner(_msgSender()),
            "NO NODE OWNER"
        );
        return nodeRewardManager._getNodesCreationTime(_msgSender());
    }

    function getNodesRewards() public view returns (string memory) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(
            nodeRewardManager._isNodeOwner(_msgSender()),
            "NO NODE OWNER"
        );
        return nodeRewardManager._getNodesRewardAvailable(_msgSender());
    }

    function getNodesLastClaims() public view returns (string memory) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(
            nodeRewardManager._isNodeOwner(_msgSender()),
            "NO NODE OWNER"
        );
        return nodeRewardManager._getNodesLastClaimTime(_msgSender());
    }

    function getNodesLastSells(address caller) public view returns (uint256) {
        require(caller != address(0), "SENDER CAN'T BE ZERO");
        return nodeRewardManager._getNodesLastSellTime(caller);
    }

    function distributeRewards()
    public
    onlyOwner
    returns (
        uint256,
        uint256,
        uint256
    )
    {
        return nodeRewardManager._distributeRewards();
    }

    function publiDistriRewards() public {
        nodeRewardManager._distributeRewards();
    }

    function getTotalStakedReward() public view returns (uint256) {
        return nodeRewardManager.totalRewardStaked();
    }

    function getTotalCreatedNodes() public view returns (uint256) {
        return nodeRewardManager.totalNodesCreated();
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        tradingOpen = true;
        _openTradingBlock = block.number;
    }

    function updateMaxTxAmount(uint256 newVal) public onlyOwner {
        maxTx = newVal;
    }

}