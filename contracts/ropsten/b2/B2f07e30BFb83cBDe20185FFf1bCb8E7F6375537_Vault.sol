pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IWETH.sol";
import "./MainProxy.sol";

/**
 * @title A vault contract for safe managment of deposited assets.
 * @notice A contract that tracks amount of assets (tokens and ether) deposited to the platform by the user and amount of assets locked in orders.
 * @dev Ether balances are kept in vaultBalances mapping and Ether amount is mapped to with the 0 address.
 */
contract Vault {
    using SafeERC20 for IERC20;

    address public mainProxy;
    MainProxy MainProxyInstance;

    address payable public weth;
    IWETH WETH;

    mapping(address => mapping(address => uint256)) internal vaultBalances;
    mapping(address => mapping(address => uint256)) internal inOrders;

    event Deposit(
        address from,
        address indexed to,
        address indexed asset,
        uint256 indexed amount
    );
    event Withdraw(
        address from,
        address indexed to,
        address indexed asset,
        uint256 indexed amount
    );
    event MovedToOrder(
        address user, // no need to index user, since this info can be retrieved from Main via orderHash
        address asset, // no need to index asset, since this info can be retrieved from Main via orderHash
        uint256 indexed amount,
        bytes32 indexed order
    );
    event MovedFromOrder(
        address user, // no need to index user, since this info can be retrieved from Main via orderHash
        address asset, // no need to index asset, since this info can be retrieved from Main via orderHash
        uint256 indexed amount,
        bytes32 indexed order
    );
    event FundsReleased(
        address user, // no need to index user, since this info can be retrieved from Main via orderHash
        address assetA, // no need to index asset, since this info can be retrieved from Main via orderHash
        uint256 indexed amountA,
        address indexed destination,
        bytes32 indexed orderHash
    );
    event FillExecuted(
        address user, // no need to index user, since this info can be retrieved from Main via orderHash
        address assetB, // no need to index asset, since this info can be retrieved from Main via orderHash
        uint256 indexed amountB,
        bytes32 indexed orderHash
    );
    event InternalMatchTransfer(
        bytes32 indexed orderA,
        bytes32 orderB, // no need to index second order
        uint256 indexed baseAmount,
        uint256 indexed quoteAmount
    ); // event doesn't contain baseToken and quoteToken addresses, since they can be retrieved via orderA hash and baseToken is always baseToken of orderA

    /**
     * @dev Constructs the Vault contract.
     * @param _mainProxy An address of the EIP1967 Upgradable Proxy for the Main.
     * @param _weth An address of Wrapped Ether contract.
     */
    constructor(address payable _mainProxy, address payable _weth) {
        mainProxy = _mainProxy;
        MainProxyInstance = MainProxy(_mainProxy);

        weth = _weth;
        WETH = IWETH(_weth);
    }

    // used for safe asset managment by the contracts ecosystem
    modifier onlyAllowed() {
        // sender must be either main proxy, current implementation or previous implementation that is a valid, non security risk version
        require(
            MainProxyInstance.isActiveImplementation(msg.sender) == true || msg.sender == mainProxy,
            "You are not allowed to call this function."
        );
        _;
    }

    /**
     * @notice Function called for depositing Ether. A value of the message will be the amount credited.
     * @param toUser An address of the account on the platform to which deposited Ether amount will be credited. In most cases this will be the sender.
     */
    function depositEther(address toUser) external payable {
        vaultBalances[toUser][address(0)] += msg.value;

        emit Deposit(msg.sender, toUser, address(0), msg.value);
    }

    /**
     * @notice Function called to withdraw Ether.
     * @dev The call will fail if vault balance of the sender is insufficient.
     * @param toAddress An address to which withdrawn Ether will be sent.
     * @param amount An amount of Ether to be withdrawn.
     */
    function withdrawEther(address payable toAddress, uint256 amount) external {
        require(
            amount <= vaultBalances[msg.sender][address(0)],
            "Insufficient amount of assets in vault."
        );

        vaultBalances[msg.sender][address(0)] -= amount;

        toAddress.transfer(amount);

        emit Withdraw(msg.sender, toAddress, address(0), amount);
    }

    /**
     * @notice Function called to deposit tokens. Sender must approve vault contract as a token spender for the amount to be deposited.
     * @dev The call will fail if token balance of the sender is insufficient or if approval for the vault contract is insufficient.
     * @param token An address of the token to be deposited.
     * @param amount An amount of token to be deposited.
     * @param toUser An address of the platform user to whom the funds will be credited.
     */
    function depositToken(
        address token,
        uint256 amount,
        address toUser
    ) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        vaultBalances[toUser][token] += amount;

        emit Deposit(msg.sender, toUser, token, amount);
    }

    /**
     * @notice Function used to withdraw tokens.
     * @dev The call will fail if vault token balance of the sender is insufficient.
     * @param token An addess of the token to be withdrawn.
     * @param amount An amount of tokens to be withdrawn.
     * @param toAddress An address to which the tokens will be withdrawn.
     */
    function withdrawToken(
        address token,
        uint256 amount,
        address toAddress
    ) external {
        require(
            amount <= vaultBalances[msg.sender][token],
            "Insufficient amount assets in vault."
        );

        vaultBalances[msg.sender][token] -= amount;

        IERC20(token).safeTransfer(toAddress, amount);

        emit Withdraw(msg.sender, toAddress, token, amount);
    }

    /**
     * @notice Function used to retrieve asset balance of specific address. This balance does not include amount locked in orders.
     * @dev To retrieve Ether balance, use 0 address for the asset parameter.
     * @param asset An addess of the asset (token address or 0 address for the Ether) to be checked.
     * @param user An address of the user whose balance should be checked.
     */
    function vaultBalanceOf(address asset, address user)
        external
        view
        returns (uint256 balance)
    {
        return vaultBalances[user][asset];
    }

    /**
     * @notice Function used to retrieve asset balance of specific address locked in order(s).
     * @dev To retrieve Ether balance, use 0 address for the asset parameter.
     * @param asset An addess of the asset (token address or 0 address for the Ether) to be checked.
     * @param user An address of the user whose balance should be checked.
     */
    function inOrderBalanceOf(address asset, address user)
        external
        view
        returns (uint256 balance)
    {
        return inOrders[user][asset];
    }

    /**
     * @dev Function used to allocate tokens in the order. The call will fail if vault token balance of the user is insufficient. To prevent malicious contracts from manipulating user funds without approval, this function requires that tx originates from the actual owner of the funds, i.e. tx.origin will be treated as user.
     * @param asset An addess of the asset to be added to the order (i.e. token address or zero address for ether).
     * @param amount An amount of tokens to be allocated into order.
     * @param orderHash A hash of the order that triggered allocation.
     */
    function moveToOrder(
        address asset,
        uint256 amount,
        bytes32 orderHash
    ) external onlyAllowed {
        require(
            amount <= vaultBalances[tx.origin][asset],
            "Insufficient vault balance."
        );

        vaultBalances[tx.origin][asset] -= amount;
        inOrders[tx.origin][asset] += amount;

        emit MovedToOrder(tx.origin, asset, amount, orderHash);
    }

    /**
     * @dev Function used to allocate tokens from order, back to the vault upon cancellation. The call will fail if in order token balance of the user is insufficient. To prevent malicious contracts from manipulating user funds without approval, this function requires that tx originates from the actual owner of the funds, i.e. tx.origin will be treated as user.
     * @param asset An addess of the asset to be removed from order balance (i.e. token address or zero address for ether).
     * @param amount An amount of tokens to be allocated into vault.
     * @param orderHash A hash of the order that triggered deallocation.
     */
    function orderCancellation(
        address asset,
        uint256 amount,
        bytes32 orderHash
    ) external onlyAllowed {
        require(
            amount <= inOrders[tx.origin][asset],
            "Insufficient in order balance."
        );

        inOrders[tx.origin][asset] -= amount;
        vaultBalances[tx.origin][asset] += amount;

        emit MovedFromOrder(tx.origin, asset, amount, orderHash);
    }

    /**
     * @dev Function used to allocate tokens from order, back to the vault upon expiration. The call will fail if in order token balance of the user is insufficient.
     * @param asset An addess of the asset to be removed from order balance (i.e. token address or zero address for ether).
     * @param amount An amount of tokens to be allocated into vault.
     * @param orderHash A hash of the order that triggered deallocation.
     * @param user An address of the user.
     */
    function orderExpiration(
        address asset,
        uint256 amount,
        bytes32 orderHash,
        address user
    ) external onlyAllowed {
        require(
            amount <= inOrders[user][asset],
            "Insufficient in order balance."
        );

        inOrders[user][asset] -= amount;
        vaultBalances[user][asset] += amount;

        emit MovedFromOrder(user, asset, amount, orderHash);
    }

    /**
     * @dev Function used to release funds to order module, to execute trade/swap.
     * @param user An address of the user.
     * @param assetA An addess of the asset to be released (i.e. token address or zero address for ether).
     * @param amountA An amount of tokens to be released.
     * @param orderHash The hash of the order being executed.
     * @param destination An address of the order module, that will execute the trade/swap.
     * @param wrap If true, will wrap Ether as WETH9 before release, if asset is zero address.
     */
    function orderFill_ReleaseFunds(
        address user,
        address assetA,
        uint256 amountA,
        bytes32 orderHash,
        address payable destination,
        bool wrap
    ) external onlyAllowed {
        require(
            amountA <= inOrders[user][assetA],
            "Insufficient in order balance."
        );

        if (assetA == address(0)) {
            if (wrap) {
                WETH.deposit{value: amountA}();

                IERC20(weth).safeTransfer(destination, amountA);
            } else destination.transfer(amountA);
        } else IERC20(assetA).safeTransfer(destination, amountA);

        inOrders[user][assetA] -= amountA;

        emit FundsReleased(user, assetA, amountA, destination, orderHash);
    }

    /**
     * @dev Function called after order fill had been successfull and balances need to be rebalanced. Funds must be sent to contract before triggering this function! IMPORTANT: Does no check if assets have been returned!
     * @param user An address of the user.
     * @param assetB An addess of the asset gotten from trade/swap.
     * @param amountB An amount of asset gotten from trade/swap.
     * @param orderHash The hash of the order that triggered this change.
	 * @param unwrap If order received and sent WETH to the Vault from handler, setting this to anything other than 0 will unwrap that amount of WETH.
     */
    function orderFill_Succeeded(
        address user,
        address assetB,
        uint256 amountB,
        bytes32 orderHash,
		uint256 unwrap
    ) external onlyAllowed {
		if (assetB == address(0) && unwrap > 0) WETH.withdraw(unwrap);

        vaultBalances[user][assetB] += amountB;

        emit FillExecuted(user, assetB, amountB, orderHash);
    }

    /**
     * @dev Function called to adjust the balance in Vault contract for the second order when internal match happens. A and B arguments are respective to the first order.
     * @param orderA Hash of the first order.
     * @param orderB Hash of the second order (order to be updated).
     * @param userA Creator of the first order.
     * @param userB Creator of the second order.
     * @param assetA Base asset of first order and quote asset of second order.
     * @param assetB Quote asset of first order and base asset of second order.
     * @param amountA Volume of base token taken from first order and received by the second order.
     * @param amountB Volume of quote token received in first order and taken from second order.
     */
    function internalMatch(
        bytes32 orderA,
        bytes32 orderB,
        address userA,
        address userB,
        address assetA,
        address assetB,
        uint256 amountA,
        uint256 amountB
    ) external onlyAllowed {
        vaultBalances[userB][assetA] += amountA;
        inOrders[userA][assetA] -= amountA;
        inOrders[userB][assetB] -= amountB;

        emit InternalMatchTransfer(orderA, orderB, amountA, amountB); // InternalMatchTransfer is equialent of FillExecuted
    }

    fallback() external payable {}
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// taken from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IWETH.sol
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @title A transparent EIP1967 based upgradable proxy for Main.
 * @dev This contract allows for upgrades of Main contract and manages balances for DeFire users.
 *
 * Take a look at https://docs.openzeppelin.com/contracts/3.x/api/proxy#TransparentUpgradeableProxy[this link] for more details about the mechanics of the underlying contract architecture.
 */
contract MainProxy is TransparentUpgradeableProxy {
    mapping(address => bool) internal previousVersions;

    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {
        previousVersions[_logic] = true;
    }

    /**
     * @notice Returns an address of the current implementation.
     *
     * @return An address of the current implementation.
     */
    function getImplementation() external view returns (address) {
        return _implementation();
    }

    /**
     * @notice Checks if certain address is an active implementation that can be used.
     *
     * @return Returns true if provided address is an active implementation, else returns false.
     */
    function isActiveImplementation(address _impl)
        external
        view
        returns (bool)
    {
        return previousVersions[_impl];
    }

    /**
     * @dev Sets new implementation. Must be used instead of 'upgradeTo()' and 'upgradeToAndCall()'! Can only be called by admin.
     * @param _impl An address of new implementation.
     */
    function newImplementation(address _impl) external ifAdmin {
        _upgradeToAndCall(_impl, bytes(""), false);

        previousVersions[_impl] = true;
    }

    /**
     * @dev Revokes previous implementation, due to it being unsecure, inefficient, etc.
     * @param _impl An address of the implementation to be revoked.
     * @param _sub Substitute address, if the version being revoked is the newest one.
     */
    function revokeImplementation(address _impl, address _sub)
        external
        ifAdmin
    {
        if (_implementation() == _impl) {
            _upgradeToAndCall(_sub, bytes(""), false);

            previousVersions[_sub] = true;
        }

        previousVersions[_impl] = false;
    }

	function _fallback() internal override {
        _delegate(_implementation());
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(address newImplementation, bytes memory data, bool forceCall) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature(
                    "upgradeTo(address)",
                    oldImplementation
                )
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _setImplementation(newImplementation);
            emit Upgraded(newImplementation);
        }
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            Address.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}