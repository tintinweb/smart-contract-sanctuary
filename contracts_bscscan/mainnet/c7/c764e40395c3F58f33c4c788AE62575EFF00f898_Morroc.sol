//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IAlberta.sol";
import "./interfaces/IByalan.sol";
import "./Izlude.sol";
import "./Prontera.sol";

contract Morroc is Context, ReentrancyGuard {
    using Address for address payable;
    using SafeERC20 for IERC20;

    Prontera public immutable prontera;
    Izlude public immutable izlude;
    IAlberta public immutable alberta;

    constructor(
        address _prontera,
        address _izlude,
        address _alberta
    ) {
        prontera = Prontera(_prontera);
        izlude = Izlude(_izlude);
        alberta = IAlberta(_alberta);

        Izlude(_izlude).want().safeApprove(_alberta, type(uint256).max);
    }

    function harvestKSW() external {
        prontera.update(address(izlude), _msgSender());
    }

    function _deposit(uint256 _amount) internal {
        require(_amount > 0, "invalid amount");

        izlude.want().safeApprove(address(izlude), 0);
        izlude.want().safeApprove(address(izlude), _amount);
        izlude.depositFromMorroc(_amount, _msgSender());
        prontera.update(address(izlude), _msgSender());
    }

    // deposit lp
    function deposit(uint256 _amount) public {
        izlude.want().safeTransferFrom(_msgSender(), address(this), _amount);
        _deposit(_amount);
    }

    function depositAll() external {
        deposit(izlude.want().balanceOf(_msgSender()));
    }

    // convert ether to lp then call deposit
    function depositEther(uint256 _maxPriceImpact) external payable nonReentrant {
        uint256 beforeBal = izlude.want().balanceOf(address(this));
        if (msg.value > 0) {
            alberta.add{value: msg.value}(address(0), address(izlude.want()), address(this), 0, _maxPriceImpact);
        }
        uint256 afterBal = izlude.want().balanceOf(address(this));
        _deposit(afterBal - beforeBal);
    }

    // convert token to lp then call deposit
    function depositToken(
        address _token,
        uint256 _amount,
        uint256 _maxPriceImpact
    ) public {
        IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);

        uint256 beforeBal = izlude.want().balanceOf(address(this));

        IERC20(_token).safeApprove(address(alberta), 0);
        IERC20(_token).safeApprove(address(alberta), type(uint256).max);
        alberta.add(_token, address(izlude.want()), address(this), _amount, _maxPriceImpact);

        uint256 afterBal = izlude.want().balanceOf(address(this));
        _deposit(afterBal - beforeBal);
    }

    function depositTokenAll(address _token, uint256 _maxPriceImpact) external {
        depositToken(_token, IERC20(_token).balanceOf(_msgSender()), _maxPriceImpact);
    }

    // withdraw lp using jellopy from izlude to this morroc
    function _withdraw(uint256 _jellopy) internal returns (uint256) {
        require(_jellopy > 0, "invalid jellopy");

        uint256 lp = izlude.withdrawFromMorroc(_jellopy, _msgSender());
        prontera.update(address(izlude), _msgSender());
        return lp;
    }

    // withdraw lp using jellopy and transfer lp back to user
    function withdraw(uint256 _jellopy) public {
        uint256 amount = _withdraw(_jellopy);
        izlude.want().transfer(_msgSender(), amount);
    }

    function withdrawAll() external {
        withdraw(izlude.balanceOf(_msgSender()));
    }

    // withdraw lp then convert to ether
    function withdrawEther(uint256 _jellopy, uint256 _maxPriceImpact) public nonReentrant {
        uint256 beforeWantBal = izlude.want().balanceOf(address(this));
        _withdraw(_jellopy);
        uint256 afterWantBal = izlude.want().balanceOf(address(this));

        uint256 beforeBal = address(this).balance;
        alberta.remove(
            address(0),
            address(izlude.want()),
            address(this),
            afterWantBal - beforeWantBal,
            _maxPriceImpact
        );
        uint256 afterBal = address(this).balance;
        payable(_msgSender()).sendValue(afterBal - beforeBal);
    }

    function withdrawAllEther(uint256 _maxPriceImpact) external {
        withdrawEther(izlude.balanceOf(_msgSender()), _maxPriceImpact);
    }

    // withdraw lp then convert to token
    function withdrawToken(
        address _token,
        uint256 _jellopy,
        uint256 _maxPriceImpact
    ) public {
        uint256 beforeWantBal = izlude.want().balanceOf(address(this));
        _withdraw(_jellopy);
        uint256 afterWantBal = izlude.want().balanceOf(address(this));

        uint256 beforeBal = IERC20(_token).balanceOf(address(this));
        alberta.remove(_token, address(izlude.want()), address(this), afterWantBal - beforeWantBal, _maxPriceImpact);
        uint256 afterBal = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_msgSender(), afterBal - beforeBal);
    }

    function withdrawAllToken(address _token, uint256 _maxPriceImpact) external {
        withdrawToken(_token, izlude.balanceOf(_msgSender()), _maxPriceImpact);
    }

    receive() external payable {}
}

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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAlberta {
    function add(
        address _paidToken,
        address _wantToken,
        address _user,
        uint256 _amountIn,
        uint256 _maxPriceImpact
    ) external payable;

    function remove(
        address _paidToken,
        address _wantToken,
        address _user,
        uint256 _amountIn,
        uint256 _maxPriceImpact
    ) external payable;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IByalanIsland.sol";
import "./ISailor.sol";

interface IByalan is IByalanIsland, ISailor {
    function want() external view returns (address);

    function beforeDeposit() external;

    function deposit() external;

    function withdraw(uint256) external;

    function balanceOf() external view returns (uint256);

    function balanceOfWant() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function balanceOfMasterChef() external view returns (uint256);

    function pendingReward() external view returns (uint256);

    function harvest() external;

    function retireStrategy() external;

    function panic() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IByalan.sol";
import "./interfaces/IFeeKafra.sol";
import "./interfaces/IAllocKafra.sol";

contract Izlude is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    struct ByalanCandidate {
        address implementation;
        uint256 proposedTime;
    }

    // The last proposed byalan to switch to.
    ByalanCandidate public byalanCandidate;
    // The byalan currently in use by the izlude.
    IByalan public byalan;
    // The minimum time it has to pass before a strat candidate can be approved.
    uint256 public immutable approvalDelay;

    address public morroc;
    IFeeKafra public feeKafra;
    IAllocKafra public allocKafra;

    event NewStrategyCandidate(address implementation);
    event UpgradeStrategy(address implementation);

    constructor(IByalan _byalan, uint256 _approvalDelay) {
        byalan = _byalan;
        approvalDelay = _approvalDelay;
    }

    modifier onlyMorroc() {
        require(_msgSender() == morroc, "!morroc");
        _;
    }

    function setMorroc(address _morroc) external onlyOwner {
        morroc = _morroc;
    }

    function setFeeKafra(IFeeKafra _feeKafra) external onlyOwner {
        feeKafra = _feeKafra;
    }

    function setAllocKafra(IAllocKafra _allocKafra) external onlyOwner {
        allocKafra = _allocKafra;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return _balances[_account];
    }

    function _mint(address _account, uint256 _jellopy) private {
        require(_account != address(0), "mint to the zero address");

        _totalSupply += _jellopy;
        _balances[_account] += _jellopy;
    }

    // burn jellopy from account
    function _burn(address _account, uint256 _jellopy) private {
        require(_account != address(0), "burn from the zero address");

        uint256 accountBalance = _balances[_account];
        require(accountBalance >= _jellopy, "burn amount exceeds balance");
        _balances[_account] = accountBalance - _jellopy;
        _totalSupply -= _jellopy;
    }

    function want() public view returns (IERC20) {
        return IERC20(byalan.want());
    }

    /**
     * @dev It calculates the total underlying value of {token} held by the system.
     * It takes into account the izlude contract balance, the strategy contract balance
     *  and the balance deployed in other contracts as part of the strategy.
     */
    function balance() public view returns (uint256) {
        return want().balanceOf(address(this)) + byalan.balanceOf();
    }

    /**
     * @dev Custom logic in here for how much the izlude allows to be borrowed.
     * We return 100% of tokens for now. Under certain conditions we might
     * want to keep some of the system funds at hand in the izlude, instead
     * of putting them to work.
     */
    function available() public view returns (uint256) {
        return want().balanceOf(address(this));
    }

    /**
     * @dev Function for various UIs to display the current value of one of our yield tokens.
     * Returns an uint256 with 18 decimals of how much underlying asset one izlude share represents.
     */
    function getPricePerFullShare() external view returns (uint256) {
        return totalSupply() == 0 ? 1e18 : (balance() * 1e18) / totalSupply();
    }

    function calculateDepositFee(uint256 _amount, address _user) public view returns (uint256) {
        if (address(feeKafra) == address(0)) {
            return 0;
        }
        return feeKafra.calculateDepositFee(_amount, _user);
    }

    function calculateWithdrawFee(uint256 _amount, address _user) public view returns (uint256) {
        if (address(feeKafra) == address(0)) {
            return 0;
        }
        return feeKafra.calculateWithdrawFee(_amount, _user);
    }

    function _deposit(uint256 _amount, address _user) private nonReentrant returns (uint256) {
        byalan.beforeDeposit();

        uint256 _pool = balance();
        want().safeTransferFrom(_msgSender(), address(this), _amount);
        uint256 _after = balance();

        _amount = _after - _pool;
        uint256 fee = calculateDepositFee(_amount, _user);
        if (fee > 0) {
            want().safeTransfer(address(feeKafra), fee);
            feeKafra.distributeDepositFee(want(), _user);
        }

        earn();

        _after = balance();
        _amount = _after - _pool; // Additional check for deflationary tokens

        require(
            address(allocKafra) == address(0) ||
                allocKafra.canAllocate(_amount, byalan.balanceOf(), byalan.balanceOfMasterChef(), _user),
            "capacity limit reached"
        );

        uint256 jellopy = 0;
        if (totalSupply() == 0) {
            jellopy = _amount;
        } else {
            jellopy = (_amount * totalSupply()) / _pool;
        }
        _mint(_user, jellopy);
        return jellopy;
    }

    function depositFromMorroc(uint256 _amount, address _user) external onlyMorroc returns (uint256) {
        return _deposit(_amount, _user);
    }

    /**
     * @dev Function to send funds into the strategy and put them to work. It's primarily called
     * by the izlude's deposit() function.
     */
    function earn() public {
        uint256 _bal = available();
        want().safeTransfer(address(byalan), _bal);
        byalan.deposit();
    }

    // burn user jellopy and convert back to want
    // then transfer want to the caller
    // user and caller might not be the same address
    function _withdraw(uint256 _jellopy, address _user) private nonReentrant returns (uint256) {
        uint256 r = (balance() * _jellopy) / totalSupply();
        _burn(_user, _jellopy);

        uint256 b = want().balanceOf(address(this));
        if (b < r) {
            uint256 amount = r - b;
            byalan.withdraw(amount);
            uint256 _after = want().balanceOf(address(this));
            uint256 diff = _after - b;
            if (diff < amount) {
                r = b + diff;
            }
        }

        uint256 fee = calculateWithdrawFee(r, _user);
        if (fee > 0) {
            r -= fee;
            want().safeTransfer(address(feeKafra), fee);
            feeKafra.distributeWithdrawFee(want(), _user);
        }
        want().safeTransfer(_msgSender(), r);
        return r;
    }

    // withdrawFromMorroc jellopy for the user, returns want
    // want will transfer directly to user
    function withdrawFromMorroc(uint256 _jellopy, address _user) external onlyMorroc returns (uint256) {
        return _withdraw(_jellopy, _user);
    }

    /**
     * @dev Sets the candidate for the new strat to use with this izlude.
     * @param _implementation The address of the candidate strategy.
     */
    function proposeStrategy(address _implementation) external onlyOwner {
        require(address(this) == IByalan(_implementation).izlude(), "proposal invalid");
        byalanCandidate = ByalanCandidate({implementation: _implementation, proposedTime: block.timestamp});

        emit NewStrategyCandidate(_implementation);
    }

    /**
     * @dev It switches the active strategy for the strategy candidate. After upgrading, the
     * candidate implementation is set to the 0x00 address, and proposedTime to a time
     * happening in +100 years for safety.
     */
    function upgradeStrategy() external onlyOwner nonReentrant {
        require(byalanCandidate.implementation != address(0), "There is no candidate");
        require(byalanCandidate.proposedTime + approvalDelay < block.timestamp, "Delay has not passed");

        emit UpgradeStrategy(byalanCandidate.implementation);

        byalan.retireStrategy();

        byalan = IByalan(byalanCandidate.implementation);
        byalanCandidate.implementation = address(0);
        byalanCandidate.proposedTime = 5000000000;

        earn();
    }

    /**
     * @dev Rescues random funds stuck that the strat can't handle.
     * @param _token address of the token to rescue.
     */
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        require(_token != address(want()), "!token");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_msgSender(), amount);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Izlude.sol";
import "./PronteraCastle.sol";

abstract contract PronteraGuard is Ownable {
    mapping(address => bool) private _guards;

    event GuardAdded(address indexed user, address indexed guard);
    event GuardRemoved(address indexed user, address indexed guard);

    modifier onlyPronteraGuard() {
        require(isGuard(_msgSender()), "!guard");
        _;
    }

    function addGuard(address _guard) public onlyOwner {
        require(_guard != address(0), "can not add address(0)");
        require(!isGuard(_guard), "guard already in access list");
        emit GuardAdded(msg.sender, _guard);
        _guards[_guard] = true;
    }

    function removeGuard(address _guard) public onlyOwner {
        require(_guard != address(0), "can not add address(0)");
        require(isGuard(_guard), "guard already not in access list");
        emit GuardRemoved(msg.sender, _guard);
        _guards[_guard] = false;
    }

    function isGuard(address _guard) public view returns (bool) {
        return _guards[_guard];
    }
}

contract Prontera is Ownable, PronteraGuard {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 share; // How many share the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of KSWs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.share * pool.accKSWPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws share to a pool. Here's what happens:
        //   1. The pool's `accKSWPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `share` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        Izlude izlude; // Address of izlude contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. KSWs to distribute per block.
        uint256 lastRewardBlock; // Last block number that KSWs distribution occurs.
        uint256 accKSWPerShare; // Accumulated KSWs per share, times 1e12. See below.
    }

    // Castle
    PronteraCastle public immutable castle;

    // KSW tokens created per block.
    uint256 public kswPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // address to pool id
    mapping(address => uint256) public izludeToPool;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when KSW mining starts.
    uint256 public startBlock;

    event SetKSWPerBlock(address indexed user, uint256 kswPerBlock);
    event SetStartBlock(address indexed user, uint256 startBlock);

    constructor(
        address _castle,
        uint256 _kswPerBlock,
        uint256 _startBlock
    ) {
        castle = PronteraCastle(_castle);
        kswPerBlock = _kswPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(
        uint256 _allocPoint,
        address _izlude,
        bool _withUpdate
    ) external onlyOwner {
        if (poolInfo.length > 0) {
            uint256 pid = izludeToPool[_izlude];
            PoolInfo storage pool = poolInfo[pid];
            require(address(pool.izlude) != _izlude, "duplicated");
        }

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint += _allocPoint;
        poolInfo.push(
            PoolInfo({
                izlude: Izlude(_izlude),
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accKSWPerShare: 0
            })
        );
        izludeToPool[_izlude] = poolInfo.length - 1;
    }

    // Update the given pool's KSW allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint -= poolInfo[_pid].allocPoint;
        totalAllocPoint += _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (castle.stakingBalance() == 0) {
            return 0;
        }
        return _to - _from;
    }

    // View function to see pending KSWs on frontend.
    function pendingKSW(address _izlude, address _user) external view returns (uint256) {
        uint256 pid = izludeToPool[_izlude];
        PoolInfo storage pool = poolInfo[pid];
        require(address(pool.izlude) == _izlude, "invalid pool id");
        UserInfo storage user = userInfo[pid][_user];
        uint256 accKSWPerShare = pool.accKSWPerShare;
        uint256 lpSupply = pool.izlude.totalSupply();
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 kswReward = (multiplier * kswPerBlock * pool.allocPoint) / totalAllocPoint;
            accKSWPerShare += (kswReward * 1e12) / lpSupply;
        }

        uint256 r = ((user.share * accKSWPerShare) / 1e12) - user.rewardDebt;
        uint256 stakingBal = castle.stakingBalance();
        if (r > stakingBal) {
            r = stakingBal;
        }
        return r;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.izlude.totalSupply();
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 kswReward = (multiplier * kswPerBlock * pool.allocPoint) / totalAllocPoint;
        pool.accKSWPerShare += (kswReward * 1e12) / lpSupply;
        pool.lastRewardBlock = block.number;
    }

    function update(address _izlude, address _user) external onlyPronteraGuard {
        uint256 pid = izludeToPool[_izlude];
        PoolInfo storage pool = poolInfo[pid];
        require(address(pool.izlude) == _izlude, "invalid pool id");
        UserInfo storage user = userInfo[pid][_user];
        updatePool(pid);
        if (user.share > 0) {
            uint256 pending = ((user.share * pool.accKSWPerShare) / 1e12) - user.rewardDebt;
            if (pending > 0) {
                castle.stakingWithdraw(_user, pending);
            }
        }
        user.share = Izlude(_izlude).balanceOf(_user);
        user.rewardDebt = (user.share * pool.accKSWPerShare) / 1e12;
    }

    function setKSWPerBlock(uint256 _kswPerBlock) external onlyOwner {
        massUpdatePools();
        kswPerBlock = _kswPerBlock;
        emit SetKSWPerBlock(msg.sender, _kswPerBlock);
    }

    function setStartBlock(uint256 _startBlock) external onlyOwner {
        require(_startBlock > block.number, "invalid block");

        massUpdatePools();
        startBlock = _startBlock;
        emit SetStartBlock(msg.sender, _startBlock);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IByalanIsland {
    function izlude() external view returns (address);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISailor {
    function MAX_FEE() external view returns (uint256);

    function totalFee() external view returns (uint256);

    function callFee() external view returns (uint256);

    function kswFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeeKafra {
    function MAX_FEE() external view returns (uint256);

    function depositFee() external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    function treasuryFeeDeposit() external view returns (uint256);

    function kswFeeDeposit() external view returns (uint256);

    function treasuryFeeWithdraw() external view returns (uint256);

    function kswFeeWithdraw() external view returns (uint256);

    function calculateDepositFee(uint256 _wantAmount, address _user) external view returns (uint256);

    function calculateWithdrawFee(uint256 _wantAmount, address _user) external view returns (uint256);

    function distributeDepositFee(IERC20 _token, address _fromUser) external;

    function distributeWithdrawFee(IERC20 _token, address _fromUser) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAllocKafra {
    function MAX_ALLOCATION() external view returns (uint16);

    function limitAllocation() external view returns (uint16);

    function canAllocate(
        uint256 _amount,
        uint256 _balanceOfWant,
        uint256 _balanceOfMasterChef,
        address _user
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./KillSwitchToken.sol";

contract PronteraCastle is Ownable {
    KillSwitchToken public immutable ksw;
    address public prontera;

    enum Category {
        FOUNDER,
        TEAM,
        RESERVE,
        MARKETING,
        ADVISOR,
        SEED_FUND,
        PRIVATE_SALE,
        PUBLIC_SALE,
        EXCHANGE_LIQUIDITY,
        AIR_DROP,
        STAKING
    }

    mapping(Category => uint256) private _balances;

    uint256 public constant FOUNDER_CAP = 20_000_000 ether;
    uint256 public constant TEAM_CAP = 20_000_000 ether;
    uint256 public constant RESERVE_CAP = 20_000_000 ether;
    uint256 public constant MARKETING_CAP = 10_000_000 ether;
    uint256 public constant ADVISOR_CAP = 6_000_000 ether;
    uint256 public constant SEED_FUND_CAP = 20_000_000 ether;
    uint256 public constant PRIVATE_SALE_CAP = 14_000_000 ether;
    uint256 public constant PUBLIC_SALE_CAP = 20_000_000 ether;
    uint256 public constant EXCHANGE_LIQUIDITY_CAP = 4_000_000 ether;
    uint256 public constant AIR_DROP_CAP = 2_000_000 ether;
    uint256 public constant STAKING_CAP = 64_000_000 ether;

    event Withdraw(Category cate, address from, address to, uint256 amount);

    constructor(address _ksw) {
        ksw = KillSwitchToken(_ksw);

        _balances[Category.FOUNDER] = FOUNDER_CAP;
        _balances[Category.TEAM] = TEAM_CAP;
        _balances[Category.RESERVE] = RESERVE_CAP;
        _balances[Category.MARKETING] = MARKETING_CAP;
        _balances[Category.ADVISOR] = ADVISOR_CAP;
        _balances[Category.SEED_FUND] = SEED_FUND_CAP;
        _balances[Category.PRIVATE_SALE] = PRIVATE_SALE_CAP;
        _balances[Category.PUBLIC_SALE] = PUBLIC_SALE_CAP;
        _balances[Category.EXCHANGE_LIQUIDITY] = EXCHANGE_LIQUIDITY_CAP;
        _balances[Category.AIR_DROP] = AIR_DROP_CAP;
        _balances[Category.STAKING] = STAKING_CAP;
    }

    function setProntera(address _prontera) external onlyOwner {
        prontera = _prontera;
    }

    function founderBalance() external view returns (uint256) {
        return _balances[Category.FOUNDER];
    }

    function teamBalance() external view returns (uint256) {
        return _balances[Category.TEAM];
    }

    function reserveBalance() external view returns (uint256) {
        return _balances[Category.RESERVE];
    }

    function marketingBalance() external view returns (uint256) {
        return _balances[Category.MARKETING];
    }

    function advisorBalance() external view returns (uint256) {
        return _balances[Category.ADVISOR];
    }

    function seedFundBalance() external view returns (uint256) {
        return _balances[Category.SEED_FUND];
    }

    function privateSaleBalance() external view returns (uint256) {
        return _balances[Category.PRIVATE_SALE];
    }

    function publicSaleBalance() external view returns (uint256) {
        return _balances[Category.PUBLIC_SALE];
    }

    function exchangeLiquidityBalance() external view returns (uint256) {
        return _balances[Category.EXCHANGE_LIQUIDITY];
    }

    function airDropBalance() external view returns (uint256) {
        return _balances[Category.AIR_DROP];
    }

    function stakingBalance() external view returns (uint256) {
        return _balances[Category.STAKING];
    }

    function founderWithdraw(address _to, uint256 _amount) external onlyOwner {
        _safeTransfer(Category.FOUNDER, _to, _amount);
    }

    function teamWithdraw(address _to, uint256 _amount) external onlyOwner {
        _safeTransfer(Category.TEAM, _to, _amount);
    }

    function reserveWithdraw(address _to, uint256 _amount) external onlyOwner {
        _safeTransfer(Category.RESERVE, _to, _amount);
    }

    function marketingWithdraw(address _to, uint256 _amount) external onlyOwner {
        _safeTransfer(Category.MARKETING, _to, _amount);
    }

    function advisorWithdraw(address _to, uint256 _amount) external onlyOwner {
        _safeTransfer(Category.ADVISOR, _to, _amount);
    }

    function seedFundWithdraw(address _to, uint256 _amount) external onlyOwner {
        _safeTransfer(Category.SEED_FUND, _to, _amount);
    }

    function privateSaleWithdraw(address _to, uint256 _amount) external onlyOwner {
        _safeTransfer(Category.PRIVATE_SALE, _to, _amount);
    }

    function publicSaleWithdraw(address _to, uint256 _amount) external onlyOwner {
        _safeTransfer(Category.PUBLIC_SALE, _to, _amount);
    }

    function exchangeLiquidityWithdraw(address _to, uint256 _amount) external onlyOwner {
        _safeTransfer(Category.EXCHANGE_LIQUIDITY, _to, _amount);
    }

    function airDropWithdraw(address _to, uint256 _amount) external onlyOwner {
        _safeTransfer(Category.AIR_DROP, _to, _amount);
    }

    function stakingWithdraw(address _to, uint256 _amount) external {
        require(msg.sender == prontera, "!prontera");

        _safeTransfer(Category.STAKING, _to, _amount);
    }

    function _safeTransfer(
        Category cate,
        address _to,
        uint256 _amount
    ) private {
        if (_amount > _balances[cate]) {
            _amount = _balances[cate];
        }

        uint256 kswBal = ksw.balanceOf(address(this));
        if (_amount > kswBal) {
            _amount = kswBal;
        }
        require(_amount > 0, "invalid amount");

        _balances[cate] -= _amount;
        ksw.transfer(_to, _amount);

        if (cate != Category.STAKING) {
            emit Withdraw(cate, msg.sender, _to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract KillSwitchToken is ERC20Capped {
    constructor() ERC20("KillswitchToken", "KSW") ERC20Capped(200_000_000 ether) {
        ERC20._mint(msg.sender, 200_000_000 ether);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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

