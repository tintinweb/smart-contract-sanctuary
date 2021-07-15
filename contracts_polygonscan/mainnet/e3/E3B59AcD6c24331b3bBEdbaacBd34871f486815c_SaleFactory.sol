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
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/ISaleFactory.sol";
import "./interfaces/ITokenLocker.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./libraries/CommonStructures.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
}

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint256);
}

contract BaseSale is ReentrancyGuard {
    using SafeERC20 for IERC20Extended;
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    uint256 constant DIVISOR = 10000;

    //This gets the sale config passed from sale factory
    CommonStructures.SaleConfig public saleConfig;
    //Used to track the progress and status of the sale
    CommonStructures.SaleInfo public saleInfo;
    //Stores the user data,used to track contribution and refund data
    mapping(address => CommonStructures.UserData) public userData;

    ISaleFactory internal saleSpawner;
    address[] internal contributors;

    IUniswapV2Router02 internal router;
    ITokenLocker internal locker;
    IERC20Extended internal token;
    IERC20Extended internal fundingToken;
    IERC20 internal pair;
    IWETH internal weth;

    event Contributed(address user, uint256 amount);
    event TokensClaimed(address user, uint256 amount);
    event ExcessRefunded(address user, uint256 amount);
    event Refunded(address user, uint256 amount);
    event TeamShareSent(address user, uint256 amount);
    event FactoryFeeSent(uint256 amount);
    event SentToken(address token, uint256 amount);
    event Finalized(bool liqLocked, uint256 liqUnlockTime, uint256 lockId);

    modifier onlySaleCreator {
        require(msg.sender == saleConfig.creator, "Caller is not sale creator");
        _;
    }

    modifier onlySaleFactoryOwner {
        require(msg.sender == saleSpawner.owner(), "Caller is not sale creator or factory allowed");
        _;
    }

    modifier onlySaleCreatororFactoryOwner {
        require(
            msg.sender == saleConfig.creator || msg.sender == address(saleSpawner) || msg.sender == saleSpawner.owner(),
            "Caller is not sale creator or factory allowed"
        );
        _;
    }

    //Primary sale data getters
    function isETHSale() public view returns (bool) {
        return address(fundingToken) == address(0);
    }

    function saleStarted() public view returns (bool) {
        return
            (saleInfo.saleForceStarted || block.timestamp >= saleConfig.startTime) &&
            token.balanceOf(address(this)) >= getRequiredAllocationOfTokens() &&
            !saleInfo.refundEnabled;
    }

    function isSaleOver() external view returns (bool) {
        return saleInfo.totalRaised >= saleConfig.hardCap || saleInfo.finalized;
    }

    //Primary allocation and token amount calculation functions
    function scaleToTokenAmount(uint256 input) public view returns (uint256) {
        uint256 fundingDecimals = getFundingDecimals();
        if (fundingDecimals == 18) return input;
        uint256 toScaleDown = getFundingDecimals() - token.decimals();
        return input / 10**toScaleDown;
    }

    function getFundingDecimals() public view returns (uint256) {
        if (isETHSale()) return 18;
        else return fundingToken.decimals();
    }

    function calculateTokensClaimable(uint256 valueIn) public view returns (uint256) {
        return scaleToTokenAmount(valueIn) * saleConfig.salePrice;
    }

    function getTokensToAdd(uint256 ethAmount) public view returns (uint256) {
        return scaleToTokenAmount(ethAmount) * saleConfig.listingPrice;
    }

    //This returns amount of tokens we need to allocate based on sale config
    function getRequiredAllocationOfTokens() public view returns (uint256) {
        uint256 saleTokens = calculateTokensClaimable(saleConfig.hardCap);
        uint256 feeToFactory = (saleConfig.hardCap * saleSpawner.getETHFee()) / DIVISOR;
        uint256 FundingBudget = getAmountToListWith(saleConfig.hardCap, feeToFactory);
        uint256 listingTokens = getTokensToAdd(FundingBudget);
        return listingTokens + saleTokens;
    }

    //This is used for token allocation calc from the saleconfig
    function getAmountToListWith(uint256 baseValue, uint256 factoryFee) public view returns (uint256 FundingBudget) {
        FundingBudget = baseValue - factoryFee;
        if (saleConfig.teamShare != 0) FundingBudget -= (FundingBudget * saleConfig.teamShare) / DIVISOR;
    }

    //User views to get status and remain alloc
    function getRemainingContribution() external view returns (uint256) {
        return saleConfig.hardCap - saleInfo.totalRaised;
    }

    //Gets how much of the funding source balance is in contract
    function getFundingBalance() public view returns (uint256) {
        if (isETHSale()) return address(this).balance;
        return fundingToken.balanceOf(address(this));
    }

    //Used to see if a sale has remaining balance that a user could claim refunds from
    function shouldRefundWithBal() external view returns (bool) {
        return getFundingBalance() > 0 && shouldRefund();
    }

    function shouldRefund() public view returns (bool) {
        return (saleInfo.refundEnabled || saleInfo.totalRaised < saleConfig.hardCap);
    }

    function userEligibleToClaimRefund(address user) external view returns (bool) {
        CommonStructures.UserData storage userDataSender = userData[user];
        return !userDataSender.tokensClaimed && !userDataSender.refundTaken && userDataSender.contributedAmount > 0;
    }

    //This creates and returns the pair for the sale if it doesnt exist
    function createPair(address baseToken, address saleToken) internal returns (IERC20) {
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        address curPair = factory.getPair(baseToken, saleToken);
        if (curPair != address(0)) return IERC20(curPair);
        return IERC20(factory.createPair(baseToken, saleToken));
    }

    //This is the initializer so that minimal proxy clones can be initialized once
    function initialize(CommonStructures.SaleConfig calldata saleConfigNew) public {
        require(!saleInfo.initialized, "Already initialized");
        saleConfig = saleConfigNew;
        router = IUniswapV2Router02(saleConfigNew.router);
        token = IERC20Extended(saleConfig.token);
        saleSpawner = ISaleFactory(msg.sender);
        locker = ITokenLocker(saleSpawner.locker());
        if (saleConfigNew.fundingToken != address(0)) fundingToken = IERC20Extended(saleConfigNew.fundingToken);
        weth = IWETH(router.WETH());
        pair = createPair(address(fundingToken) == address(0) ? address(weth) : address(saleConfigNew.fundingToken), address(token));
        saleInfo.initialized = true;
    }

    receive() external payable {
        if (msg.sender != address(router)) {
            buyTokens();
        }
    }

    //Upon receiving ETH This is called
    function buyTokens() public payable nonReentrant {
        require(isETHSale(), "This sale does not accept ETH");
        require(saleStarted(), "Not started yet");
        _handlePurchase(msg.sender, msg.value);
    }

    //This function is used to contribute to sales that arent taking eth as contrib
    function contributeTokens(uint256 _amount) public nonReentrant {
        require(!isETHSale(), "This sale accepts ETH, use buyTokens instead");
        require(saleStarted(), "Not started yet");
        //Transfer funding token to this address
        fundingToken.safeTransferFrom(msg.sender, address(this), _amount);
        _handlePurchase(msg.sender, _amount);
    }

    function calculateLimitForUser(uint256 contributedAmount, uint256 value) internal view returns (uint256 limit) {
        limit = saleInfo.totalRaised + value > saleConfig.hardCap ? (saleInfo.totalRaised + value) - saleConfig.hardCap : value;
        limit = (contributedAmount + limit) > saleConfig.maxBuy ? Math.min(saleConfig.maxBuy, this.getRemainingContribution()) : limit;
    }

    function _handlePurchase(address user, uint256 value) internal {
        //First check tx price,if higher than max gas price and gas limits are enabled reject it
        require(saleSpawner.checkTxPrice(tx.gasprice), "Above gas price limit");
        CommonStructures.UserData storage userDataSender = userData[user];
        uint256 FundsToContribute = calculateLimitForUser(userDataSender.contributedAmount, value);
        if (FundsToContribute == 0) {
            //If there is no balance possible just refund it all
            _handleFundingTransfer(user, value);
            emit ExcessRefunded(user, value);
            return;
        }
        //Check if it surpases max buy
        require(userDataSender.contributedAmount + FundsToContribute <= saleConfig.maxBuy, "Exceeds max buy");
        //Check if it passes hardcap
        require(saleInfo.totalRaised + FundsToContribute <= saleConfig.hardCap, "HardCap will be reached");
        //If this is a new user add to array of contributors
        if (userDataSender.contributedAmount == 0) contributors.push(user);
        //Update contributed amount
        userDataSender.contributedAmount += FundsToContribute;
        //Update total raised
        saleInfo.totalRaised += FundsToContribute;
        uint256 tokensToAdd = calculateTokensClaimable(FundsToContribute);
        //Update users tokens they can claim
        userDataSender.tokensClaimable += tokensToAdd;
        //Add to total tokens to keep
        saleInfo.totalTokensToKeep += tokensToAdd;
        //Refund excess
        if (FundsToContribute < value) {
            uint256 amountToRefund = value - FundsToContribute;
            _handleFundingTransfer(user, amountToRefund);
            emit ExcessRefunded(user, amountToRefund);
        }

        emit Contributed(user, value);
    }

    function _handleFundingTransfer(address user, uint256 value) internal {
        if (isETHSale()) payable(user).sendValue(value);
        else fundingToken.safeTransfer(user, value);
    }

    function getRefund() external nonReentrant {
        require(shouldRefund(), "Refunds not enabled or doesnt pass config");

        CommonStructures.UserData storage userDataSender = userData[msg.sender];

        require(!userDataSender.tokensClaimed, "Tokens already claimed");
        require(!userDataSender.refundTaken, "Refund already claimed");
        require(userDataSender.contributedAmount > 0, "No contribution");

        userDataSender.refundTaken = true;
        _handleFundingTransfer(msg.sender, userDataSender.contributedAmount);
        //If this refund was called when refund was not enabled and under hardcap reduce from total raised
        saleInfo.totalRaised -= userDataSender.contributedAmount;
        emit Refunded(msg.sender, userDataSender.contributedAmount);
    }

    function claimTokens() external nonReentrant {
        require(!saleInfo.refundEnabled, "Refunds enabled");
        require(saleInfo.finalized, "Sale not finalized yet");

        CommonStructures.UserData storage userDataSender = userData[msg.sender];

        require(!userDataSender.tokensClaimed, "Tokens already claimed");
        require(!userDataSender.refundTaken, "Refund was claimed");
        require(userDataSender.tokensClaimable > 0, "No tokens to claim");

        userDataSender.tokensClaimed = true;
        token.safeTransfer(msg.sender, userDataSender.tokensClaimable);
        emit TokensClaimed(msg.sender, userDataSender.tokensClaimable);
    }

    // Admin only functions
    function enableRefunds() public onlySaleCreatororFactoryOwner {
        saleInfo.refundEnabled = true;
        saleInfo.totalTokensToKeep = 0;
    }

    function forceStartSale() external onlySaleCreatororFactoryOwner {
        saleInfo.saleForceStarted = true;
    }

    function cancelSale() external onlySaleCreatororFactoryOwner {
        enableRefunds();
        //Send back tokens to creator of the sale
        token.transfer(saleConfig.creator, token.balanceOf(address(this)));
    }

    //Recover any tokens thats sent to BaseSale by factory owner
    function recoverTokens(address _token) external onlySaleFactoryOwner {
        IERC20 iToken = IERC20(_token);
        uint256 amount = iToken.balanceOf(address(this));
        iToken.safeTransfer(msg.sender, amount);
        emit SentToken(_token, amount);
    }

    //This function takes care of adding liq to the specified base pair
    function addLiquidity(
        uint256 fundingAmount,
        uint256 tokenAmount,
        bool fETH
    ) internal returns (uint256 lockId) {
        //If this is ETH,deposit in WETH from contract
        if (fETH) {
            weth.deposit{value: fundingAmount}();
            weth.approve(address(router), fundingAmount);
        }

        //Then call addliquidity with token0 and weth and token1 as the token,so that we dont rely on addLiquidityETH
        router.addLiquidity(
            fETH ? address(weth) : address(fundingToken),
            address(token),
            fundingAmount,
            tokenAmount,
            fundingAmount,
            tokenAmount,
            saleConfig.lpUnlockTime != 0 ? address(this) : saleConfig.creator,
            block.timestamp
        );
        if (saleConfig.lpUnlockTime != 0) {
            //Initate lock and emit
            lockId = locker.getNextLockId();
            pair.approve(address(locker), pair.balanceOf(address(this)));
            //Do lock
            locker.initNewLock(
                ITokenLocker.LockInfo({
                    token: pair,
                    beneficiary: saleConfig.creator,
                    unlockTime: saleConfig.lpUnlockTime,
                    lockAmount: pair.balanceOf(address(this))
                })
            );
        }
    }

    //NOTE: Do not add liq before sale finalizes or finalize will fail if price on pair is different from the configured listing price
    //This call finalizes the sale and lists on the uniswap dex (or any other dex given in the router)
    function finalize() external onlySaleCreatororFactoryOwner nonReentrant {
        require(saleInfo.totalRaised > saleConfig.softCap, "Raise amount didnt pass softcap");
        require(!saleInfo.finalized, "Sale already finalized");

        uint256 FundingBudget = saleInfo.totalRaised;

        //Send team their eth
        if (saleConfig.teamShare > 0) {
            uint256 teamShare = (saleInfo.totalRaised * saleConfig.teamShare) / DIVISOR;
            FundingBudget -= teamShare;
            _handleFundingTransfer(saleConfig.creator, teamShare);
            emit TeamShareSent(saleConfig.creator, teamShare);
        }

        //Send fee to factory
        uint256 feeToFactory = (saleInfo.totalRaised * saleSpawner.getETHFee()) / DIVISOR;
        _handleFundingTransfer(address(saleSpawner), feeToFactory);
        emit FactoryFeeSent(feeToFactory);
        FundingBudget -= feeToFactory;

        require(FundingBudget <= getFundingBalance(), "not enough in contract");
        //Approve router to spend tokens
        token.safeApprove(address(router), type(uint256).max);
        //Add liq as given
        uint256 tokensToAdd = getTokensToAdd(FundingBudget);
        uint256 lockId = addLiquidity(FundingBudget, tokensToAdd, isETHSale());

        //If we have excess send it to factory
        uint256 remain = getFundingBalance();
        if (remain > 0) {
            _handleFundingTransfer(address(saleSpawner), remain);
        }

        //If we have excess tokens after finalization send that to the creator
        uint256 remainToken = token.balanceOf(address(this));
        if (remainToken > saleInfo.totalTokensToKeep) {
            token.safeTransfer(saleConfig.creator, remainToken - saleInfo.totalTokensToKeep);
            require(token.balanceOf(address(this)) == saleInfo.totalTokensToKeep, "we have more leftover");
        }

        saleInfo.finalized = true;
        emit Finalized(saleConfig.lpUnlockTime > 0, saleConfig.lpUnlockTime, lockId);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BaseSale.sol";
import "./TokenLocker.sol";

contract SaleFactory is Ownable {
    using Address for address payable;
    using SafeERC20 for IERC20;

    //Percent of ETH as service fee,scaled by 100,2% = 200
    uint256 fee;
    //Max gas price in gwei
    uint256 public gasPriceLimit;

    //Toggle to limit max gas per contribution tx
    bool public limitGas;

    //Base sale which we minimal proxy clone for a new sale
    address public baseSale;
    address public locker;

    //Internal array to track all sales deployed
    address[] internal salesDeployed;

    //Events for all admin or nonadmin calls
    event CreatedSale(address newSale);
    event ETHRetrived(address receiver);
    event BaseSaleUpdated(address newBase);
    event LockerUpdated(address newLocker);
    event ServiceFeeUpdated(uint256 newFee);
    event GasPriceLimitUpdated(uint256 newPrice);
    event LimitToggled(bool cur);
    event SentToken(address token, uint256 amount);

    //Used to receive the service fees
    receive() external payable {}

    constructor() {
        //2% of raised ETH
        fee = 200;
        baseSale = address(new BaseSale());
        locker = address(new TokenLocker());
        gasPriceLimit = 10 gwei;
        limitGas = false;
    }

    function setBaseSale(address _newBaseSale) external onlyOwner {
        baseSale = _newBaseSale;
        emit BaseSaleUpdated(_newBaseSale);
    }

    function setLocker(address _newLocker) external onlyOwner {
        locker = _newLocker;
        emit LockerUpdated(_newLocker);
    }

    function setNewFee(uint256 _newFee) external onlyOwner {
        fee = _newFee;
        emit ServiceFeeUpdated(_newFee);
    }

    function setGasPriceLimit(uint256 _newPrice) external onlyOwner {
        gasPriceLimit = _newPrice;
        emit GasPriceLimitUpdated(_newPrice);
    }

    function toggleLimit() external onlyOwner {
        limitGas = !limitGas;
        emit LimitToggled(limitGas);
    }

    //Used by base sale to check gas prices
    function checkTxPrice(uint256 txGasPrice) external view returns (bool) {
        return limitGas ? txGasPrice <= gasPriceLimit : true;
    }

    function deploySale(CommonStructures.SaleConfig calldata saleConfigNew) external returns (address payable newSale) {
        require(baseSale != address(0), "Base sale contract not set");
        require(saleConfigNew.creator != address(0), "Sale creator is empty");
        require(saleConfigNew.hardCap > saleConfigNew.softCap, "Sale hardcap is lesser than softcap");
        require(saleConfigNew.router != address(0), "Sale target router is empty");
        require(saleConfigNew.creator == msg.sender, "Creator doesnt match the caller");
        require(saleConfigNew.token != address(0), "Token not set");
        IERC20 targetToken = IERC20(saleConfigNew.token);
        // require(saleConfigNew.)
        bytes20 addressBytes = bytes20(baseSale);
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newSale := create(0, clone_code, 0x37)
        }

        BaseSale(newSale).initialize(saleConfigNew);

        //Now that this is initialized,transfer tokens to sale contract to get sale prepared
        uint256 tokensNeeded = BaseSale(newSale).getRequiredAllocationOfTokens();
        targetToken.safeTransferFrom(msg.sender, newSale, tokensNeeded);
        require(targetToken.balanceOf(newSale) >= tokensNeeded, "Not enough tokens gotten to new sale");

        salesDeployed.push(newSale);
        emit CreatedSale(newSale);
    }

    function getAllSales() public view returns (address[] memory) {
        return salesDeployed;
    }

    function getETHFee() external view returns (uint256) {
        return fee;
    }

    //Get all eth fees from factory
    function retriveETH() external onlyOwner {
        payable(owner()).sendValue(address(this).balance);
        emit ETHRetrived(msg.sender);
    }

    //Used to retrive tokens which are sent here
    function retriveToken(address token) external onlyOwner {
        IERC20 iToken = IERC20(token);
        uint256 amount = iToken.balanceOf(address(this));
        iToken.safeTransfer(msg.sender, amount);
        emit SentToken(token, amount);
    }
}

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITokenLocker.sol";

//This contract allows to lock multiple tokens with different lockids

contract TokenLocker is Ownable, ITokenLocker {
    ITokenLocker.LockInfo[] public locks;

    event LockCreated(uint256 id, address token, address beneficiary, uint256 unlockTime);

    modifier onlyOwnerOrBeneficiary(address beneficiary) {
        require(msg.sender == owner() || msg.sender == beneficiary);
        _;
    }

    //Give this id to user to call
    function getNextLockId() public view override returns (uint256) {
        return locks.length > 0 ? locks.length + 1 : 0;
    }

    function initNewLock(ITokenLocker.LockInfo calldata lockConfig) external override {
        require(address(lockConfig.token) != address(0), "INVALID_TOKEN");
        require(lockConfig.beneficiary != address(0), "INVALID_BENEFICIARY");
        require(lockConfig.unlockTime >= block.timestamp, "INVALID_UNLOCKTIME");
        require(lockConfig.token.transferFrom(msg.sender, address(this), lockConfig.lockAmount), "LOCK_TX_FAILED");
        emit LockCreated(getNextLockId(), address(lockConfig.token), lockConfig.beneficiary, lockConfig.unlockTime);
        locks.push(lockConfig);
    }

    function getLockInfo(uint256 index) external view override returns (ITokenLocker.LockInfo memory info) {
        require(index <= locks.length, "INVALID_INDEX");
        return locks[index];
    }

    function extendLock(uint256 index, uint256 increment) external {
        require(index <= locks.length, "INVALID_INDEX");
        require(increment > 0, "INVALID_INC");
        require(locks[index].beneficiary == msg.sender, "INVALID_CALLER");
        locks[index].unlockTime += increment;
    }

    function unlock(uint256 index) external {
        require(index <= locks.length, "INVALID_INDEX");
        require(locks[index].beneficiary == msg.sender, "INVALID_CALLER");
        locks[index].token.transfer(msg.sender, locks[index].lockAmount);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

interface ISaleFactory {
    function owner() external view returns (address);

    function checkTxPrice(uint256 txGasPrice) external view returns (bool);

    function getETHFee() external view returns (uint256);

    function getAllSales() external view returns (address[] memory);

    function locker() external view returns (address);

    function retriveETH() external;

    function retriveToken(address token) external;

    function setBaseSale(address _newBaseSale) external;

    function setLocker(address _newLocker) external;

    function setNewFee(uint256 _newFee) external;

    function setGasPriceLimit(uint256 _newPrice) external;

    function toggleLimit() external;
}

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenLocker {
    struct LockInfo {
        IERC20 token;
        address beneficiary;
        uint256 unlockTime;
        uint256 lockAmount;
    }

    function initNewLock(LockInfo calldata lockConfig) external;

    function getLockInfo(uint256 index) external view returns (LockInfo memory info);

    function getNextLockId() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IUniswapRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

library CommonStructures {
    // enum SaleTypes {
    //     PRESALE,
    //     DUTCH_AUCTION
    // }

    struct SaleConfig {
        //The token being sold
        address token;
        //The token / asset being accepted as contributions,for ETH its address(0)
        address fundingToken;
        //Max buy in wei
        uint256 maxBuy;
        uint256 softCap;
        uint256 hardCap;
        //Sale price in integers,example 1 or 2 tokens per eth
        uint256 salePrice;
        uint256 listingPrice;
        uint256 startTime;
        uint256 lpUnlockTime;
        //This contains the sale data from backend url
        string detailsJSON;
        //The router which we add liq to
        address router;
        //Maker of the sale
        address creator;
        //Share of eth / tokens that goes to the team
        uint256 teamShare;
    }

    struct SaleInfo {
        //Total amount of ETH or tokens raised
        uint256 totalRaised;
        //The amount of tokens to have to fullfill claims
        uint256 totalTokensToKeep;
        //Force started incase start time is wrong
        bool saleForceStarted;
        //Refunds started incase of a issue with sale contract
        bool refundEnabled;
        //Used to check if the baseSale is init
        bool initialized;
        //Returns if the sale was finalized and listed
        bool finalized;
        // Used as a way to display quality checked sales,shows up on the main page if so
        bool qualitychecked;
    }

    struct SaleDataCombined {
        SaleConfig config;
        SaleInfo info;
    }

    struct UserData {
        //total amount of funding amount contributed
        uint256 contributedAmount;
        uint256 tokensClaimable;
        bool tokensClaimed;
        bool refundTaken;
    }
}