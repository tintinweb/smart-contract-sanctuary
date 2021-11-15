// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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

    constructor () {
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (governor) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governor account will be the one that deploys the contract. This
 * can later be changed with {transferGovernorship}.
 *
 */
contract Governed is Context, Initializable {
    address public governor;
    address private proposedGovernor;

    event UpdatedGovernor(address indexed previousGovernor, address indexed proposedGovernor);

    /**
     * @dev Initializes the contract setting the deployer as the initial governor.
     */
    constructor() {
        address msgSender = _msgSender();
        governor = msgSender;
        emit UpdatedGovernor(address(0), msgSender);
    }

    /**
     * @dev If inheriting child is using proxy then child contract can use
     * _initializeGoverned() function to initialization this contract
     */
    function _initializeGoverned() internal initializer {
        address msgSender = _msgSender();
        governor = msgSender;
        emit UpdatedGovernor(address(0), msgSender);
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor {
        require(governor == _msgSender(), "not-the-governor");
        _;
    }

    /**
     * @dev Transfers governorship of the contract to a new account (`proposedGovernor`).
     * Can only be called by the current owner.
     */
    function transferGovernorship(address _proposedGovernor) external onlyGovernor {
        require(_proposedGovernor != address(0), "proposed-governor-is-zero");
        proposedGovernor = _proposedGovernor;
    }

    /**
     * @dev Allows new governor to accept governorship of the contract.
     */
    function acceptGovernorship() external {
        require(proposedGovernor == _msgSender(), "not-the-proposed-governor");
        emit UpdatedGovernor(governor, proposedGovernor);
        governor = proposedGovernor;
        proposedGovernor = address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface ManagerLike {
    function cdpCan(
        address,
        uint256,
        address
    ) external view returns (uint256);

    function ilks(uint256) external view returns (bytes32);

    function owns(uint256) external view returns (address);

    function urns(uint256) external view returns (address);

    function vat() external view returns (address);

    function open(bytes32, address) external returns (uint256);

    function give(uint256, address) external;

    function cdpAllow(
        uint256,
        address,
        uint256
    ) external;

    function urnAllow(address, uint256) external;

    function frob(
        uint256,
        int256,
        int256
    ) external;

    function flux(
        uint256,
        address,
        uint256
    ) external;

    function move(
        uint256,
        address,
        uint256
    ) external;

    function exit(
        address,
        uint256,
        address,
        uint256
    ) external;

    function quit(uint256, address) external;

    function enter(address, uint256) external;

    function shift(uint256, uint256) external;
}

interface VatLike {
    function can(address, address) external view returns (uint256);

    function ilks(bytes32)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function dai(address) external view returns (uint256);

    function urns(bytes32, address) external view returns (uint256, uint256);

    function frob(
        bytes32,
        address,
        address,
        address,
        int256,
        int256
    ) external;

    function hope(address) external;

    function nope(address) external;

    function move(
        address,
        address,
        uint256
    ) external;
}

interface GemJoinLike {
    function dec() external view returns (uint256);

    function gem() external view returns (address);

    function ilk() external view returns (bytes32);

    function join(address, uint256) external payable;

    function exit(address, uint256) external;
}

interface DaiJoinLike {
    function vat() external returns (VatLike);

    function dai() external view returns (address);

    function join(address, uint256) external payable;

    function exit(address, uint256) external;
}

interface JugLike {
    function drip(bytes32) external returns (uint256);
}

interface SpotterLike {
    function ilks(bytes32) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface ICollateralManager {
    function addGemJoin(address[] calldata _gemJoins) external;

    function borrow(uint256 _amount) external;

    function createVault(bytes32 _collateralType) external returns (uint256 _vaultNum);

    function depositCollateral(uint256 _amount) external;

    function payback(uint256 _amount) external;

    function transferVaultOwnership(address _newOwner) external;

    function withdrawCollateral(uint256 _amount) external;

    function getVaultBalance(address _vaultOwner) external view returns (uint256 collateralLocked);

    function getVaultDebt(address _vaultOwner) external view returns (uint256 daiDebt);

    function getVaultInfo(address _vaultOwner)
        external
        view
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        );

    function mcdManager() external view returns (address);

    function vaultNum(address _vaultOwner) external view returns (uint256 _vaultNum);

    function whatWouldWithdrawDo(address _vaultOwner, uint256 _amount)
        external
        view
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../Governed.sol";
import "../../interfaces//maker/IMakerDAO.sol";
import "../../interfaces/vesper/ICollateralManager.sol";

contract DSMath {
    uint256 internal constant RAY = 10**27;
    uint256 internal constant WAD = 10**18;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = ((x * y) + (WAD / 2)) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = ((x * WAD) + (y / 2)) / y;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = ((x * y) + (RAY / 2)) / RAY;
    }

    function toRad(uint256 wad) internal pure returns (uint256 rad) {
        rad = wad * RAY;
    }

    /// @notice It will work only if _dec < 18
    function convertTo18(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = _amt * 10**(18 - _dec);
    }
}

contract CollateralManager is ICollateralManager, DSMath, ReentrancyGuard, Governed {
    using SafeERC20 for IERC20;

    // Vault number to collateral type
    mapping(uint256 => bytes32) public collateralType;
    // Vault owner to vault num mapping
    mapping(address => uint256) public override vaultNum;
    // Collateral type to Gem join address of that type
    mapping(bytes32 => address) public mcdGemJoin;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public override mcdManager = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address public mcdDaiJoin = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address public mcdSpot = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address public mcdJug = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address public treasury;
    uint256 internal constant MAX_UINT_VALUE = type(uint256).max;

    event AddedGemJoin(address indexed gemJoin, bytes32 ilk);
    event CreatedVault(address indexed owner, uint256 indexed vaultNum, bytes32 indexed collateralType);
    event TransferredVaultOwnership(uint256 indexed vaultNum, address indexed previousOwner, address indexed newOwner);
    event UpdatedMCDAddresses(address mcdManager, address mcdDaiJoin, address mcdSpot, address mcdJug);
    event UpdatedTreasury(address indexed previousTreasury, address indexed newTreasury);

    modifier onlyVaultOwner() {
        require(vaultNum[msg.sender] != 0, "caller-doesn't-own-any-vault");
        _;
    }

    /**
     * @dev Add gemJoin adapter address from Maker in mapping
     * @param _gemJoins Array of gem join addresses
     */
    function addGemJoin(address[] calldata _gemJoins) external override onlyGovernor {
        require(_gemJoins.length != 0, "no-gemJoin-address");
        for (uint256 i; i < _gemJoins.length; i++) {
            address gemJoin = _gemJoins[i];
            bytes32 ilk = GemJoinLike(gemJoin).ilk();
            mcdGemJoin[ilk] = gemJoin;
            emit AddedGemJoin(gemJoin, ilk);
        }
    }

    /**
     * @notice Create new Maker vault
     * @dev Store caller of this function as vault owner.
     * @param _collateralType Collateral type for Maker vault
     * @return _vaultNum Newly created vault number
     */
    function createVault(bytes32 _collateralType) external override returns (uint256 _vaultNum) {
        require(vaultNum[msg.sender] == 0, "caller-owns-another-vault");
        ManagerLike manager = ManagerLike(mcdManager);
        _vaultNum = manager.open(_collateralType, address(this));
        manager.cdpAllow(_vaultNum, address(this), 1);

        vaultNum[msg.sender] = _vaultNum;
        collateralType[_vaultNum] = _collateralType;
        emit CreatedVault(msg.sender, _vaultNum, _collateralType);
    }

    /**
     * @notice Transfer vault ownership to another address/strategy
     * @param _newOwner Address of new owner of vault
     */
    function transferVaultOwnership(address _newOwner) external override onlyVaultOwner {
        _transferVaultOwnership(vaultNum[msg.sender], msg.sender, _newOwner);
    }

    /**
     * @notice Transfer vault ownership to another address/strategy
     * @param _vaultNum Number of vault being transferred
     * @param _owner Address of owner of vault
     * @param _newOwner Address of new owner of vault
     */
    function transferVaultOwnership(
        uint256 _vaultNum,
        address _owner,
        address _newOwner
    ) external onlyGovernor {
        require(_vaultNum != 0, "vault-number-is-zero");
        require(_owner != address(0), "owner-address-zero");
        _transferVaultOwnership(_vaultNum, _owner, _newOwner);
    }

    /**
     * @dev Update MCD addresses.
     */
    function updateMCDAddresses(
        address _mcdManager,
        address _mcdDaiJoin,
        address _mcdSpot,
        address _mcdJug
    ) external onlyGovernor {
        require(_mcdManager != address(0), "mcdManager-address-is-zero");
        require(_mcdDaiJoin != address(0), "mcdDaiJoin-address-is-zero");
        require(_mcdSpot != address(0), "mcdSpot-address-is-zero");
        require(_mcdJug != address(0), "mcdJug-address-is-zero");
        mcdManager = _mcdManager;
        mcdDaiJoin = _mcdDaiJoin;
        mcdSpot = _mcdSpot;
        mcdJug = _mcdJug;
        emit UpdatedMCDAddresses(_mcdManager, _mcdDaiJoin, _mcdSpot, _mcdJug);
    }

    /**
     * @notice Update treasure address
     */
    function updateTreasury(address _treasury) external onlyGovernor {
        require(_treasury != address(0), "treasury-address-is-zero");
        emit UpdatedTreasury(treasury, _treasury);
        treasury = _treasury;
    }

    /**
     * @dev Deposit ERC20 collateral.
     * @param _amount ERC20 amount to deposit.
     */
    function depositCollateral(uint256 _amount) external override nonReentrant onlyVaultOwner {
        uint256 _vaultNum = vaultNum[msg.sender];
        // Receives Gem amount, approve and joins it into the vat.
        // Also convert amount to 18 decimal
        _amount = _joinGem(mcdGemJoin[collateralType[_vaultNum]], _amount);

        ManagerLike manager = ManagerLike(mcdManager);
        // Locks Gem amount into the CDP
        VatLike(manager.vat()).frob(
            collateralType[_vaultNum],
            manager.urns(_vaultNum),
            address(this),
            address(this),
            int256(_amount),
            0
        );
    }

    /**
     * @dev Withdraw collateral.
     * @param _amount Collateral amount to withdraw.
     */
    function withdrawCollateral(uint256 _amount) external override nonReentrant onlyVaultOwner {
        uint256 _vaultNum = vaultNum[msg.sender];
        ManagerLike manager = ManagerLike(mcdManager);
        GemJoinLike gemJoin = GemJoinLike(mcdGemJoin[collateralType[_vaultNum]]);
        uint256 amount18 = convertTo18(gemJoin.dec(), _amount);
        // Unlocks Gem amount18 from the CDP
        manager.frob(_vaultNum, -int256(amount18), 0);
        // Moves Gem amount18 from the CDP urn to this address
        manager.flux(_vaultNum, address(this), amount18);
        // Exits Gem amount to this address as a token
        gemJoin.exit(address(this), _amount);
        // Send Gem to pool's address
        IERC20(gemJoin.gem()).safeTransfer(msg.sender, _amount);
    }

    /**
     * @dev Payback borrowed DAI.
     * @param _amount Dai amount to payback.
     */
    function payback(uint256 _amount) external override onlyVaultOwner {
        uint256 _vaultNum = vaultNum[msg.sender];
        ManagerLike manager = ManagerLike(mcdManager);
        address urn = manager.urns(_vaultNum);
        address vat = manager.vat();
        bytes32 ilk = collateralType[_vaultNum];
        // Calculate dai debt
        uint256 _daiDebt = _getVaultDebt(ilk, urn, vat);
        require(_daiDebt >= _amount, "paying-excess-debt");
        // Approve and join dai in vat
        _joinDai(urn, _amount);
        manager.frob(_vaultNum, 0, _getWipeAmount(ilk, urn, vat));
    }

    /**
     * @notice Borrow DAI.
     * @dev In edge case, when we hit DAI mint limit, we might end up borrowing
     * less than what is being asked.
     * @param _amount Dai amount to borrow. Actual borrow amount may be less than "amount"
     */
    function borrow(uint256 _amount) external override onlyVaultOwner {
        uint256 _vaultNum = vaultNum[msg.sender];
        ManagerLike manager = ManagerLike(mcdManager);
        address vat = manager.vat();
        // Safety check in scenario where current debt and request borrow will exceed max dai limit
        uint256 _maxAmount = _maxAvailableDai(vat, collateralType[_vaultNum]);
        if (_amount > _maxAmount) {
            _amount = _maxAmount;
        }

        // Generates debt in the CDP
        manager.frob(_vaultNum, 0, _getBorrowAmount(vat, manager.urns(_vaultNum), _vaultNum, _amount));
        // Moves the DAI amount (balance in the vat in rad) to pool's address
        manager.move(_vaultNum, address(this), toRad(_amount));
        // Allows adapter to access to pool's DAI balance in the vat
        if (VatLike(vat).can(address(this), mcdDaiJoin) == 0) {
            VatLike(vat).hope(mcdDaiJoin);
        }
        // Exits DAI as a token to user's address
        DaiJoinLike(mcdDaiJoin).exit(msg.sender, _amount);
    }

    /// @dev sweep given ERC20 token to treasury pool
    function sweepErc20(address _fromToken) external {
        require(treasury != address(0), "treasury-not-set");
        uint256 amount = IERC20(_fromToken).balanceOf(address(this));
        IERC20(_fromToken).safeTransfer(treasury, amount);
    }

    /**
     * @dev Get current dai debt of vault.
     * @param _vaultOwner Address of vault owner
     */
    function getVaultDebt(address _vaultOwner) external view override returns (uint256 daiDebt) {
        uint256 _vaultNum = vaultNum[_vaultOwner];
        require(_vaultNum != 0, "invalid-vault-number");
        address _urn = ManagerLike(mcdManager).urns(_vaultNum);
        address _vat = ManagerLike(mcdManager).vat();
        bytes32 _ilk = collateralType[_vaultNum];
        daiDebt = _getVaultDebt(_ilk, _urn, _vat);
    }

    /**
     * @dev Get current collateral balance of vault.
     * @param _vaultOwner Address of vault owner
     */
    function getVaultBalance(address _vaultOwner) external view override returns (uint256 collateralLocked) {
        uint256 _vaultNum = vaultNum[_vaultOwner];
        require(_vaultNum != 0, "invalid-vault-number");
        address _vat = ManagerLike(mcdManager).vat();
        address _urn = ManagerLike(mcdManager).urns(_vaultNum);
        (collateralLocked, ) = VatLike(_vat).urns(collateralType[_vaultNum], _urn);
    }

    /**
     * @dev Calculate state based on withdraw amount.
     * @param _vaultOwner Address of vault owner
     * @param _amount Collateral amount to withdraw.
     */
    function whatWouldWithdrawDo(address _vaultOwner, uint256 _amount)
        external
        view
        override
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        )
    {
        uint256 _vaultNum = vaultNum[_vaultOwner];
        require(_vaultNum != 0, "invalid-vault-number");
        (collateralLocked, daiDebt, collateralUsdRate, collateralRatio, minimumDebt) = getVaultInfo(_vaultOwner);

        GemJoinLike _gemJoin = GemJoinLike(mcdGemJoin[collateralType[_vaultNum]]);
        uint256 _amount18 = convertTo18(_gemJoin.dec(), _amount);
        require(_amount18 <= collateralLocked, "insufficient-collateral-locked");
        collateralLocked = collateralLocked - _amount18;
        collateralRatio = _getCollateralRatio(collateralLocked, collateralUsdRate, daiDebt);
    }

    /**
     * @dev Get vault info
     * @param _vaultOwner Address of vault owner
     */
    function getVaultInfo(address _vaultOwner)
        public
        view
        override
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        )
    {
        uint256 _vaultNum = vaultNum[_vaultOwner];
        require(_vaultNum != 0, "invalid-vault-number");
        (collateralLocked, collateralUsdRate, daiDebt, minimumDebt) = _getVaultInfo(_vaultNum);
        collateralRatio = _getCollateralRatio(collateralLocked, collateralUsdRate, daiDebt);
    }

    /**
     * @notice Get max available DAI safe to borrow for given collateral type.
     * @param _collateralType Collateral type.
     */
    function maxAvailableDai(bytes32 _collateralType) public view returns (uint256) {
        return _maxAvailableDai(ManagerLike(mcdManager).vat(), _collateralType);
    }

    /**
     * @notice Get max available DAI safe to borrow
     * @dev Calculation based on current DAI debt and DAI limit for given collateral type.
     * @param _vat Vat address
     * @param _collateralType Vault collateral type.
     */
    function _maxAvailableDai(address _vat, bytes32 _collateralType) internal view returns (uint256) {
        // Get stable coin Art(debt) [wad], rate [ray], line [rad]
        //solhint-disable-next-line var-name-mixedcase
        (uint256 Art, uint256 rate, , uint256 line, ) = VatLike(_vat).ilks(_collateralType);
        // Calculate total issued debt is Art * rate [rad]
        // Calculate total available dai [wad]
        uint256 _totalAvailableDai = (line - (Art * rate)) / RAY;
        // For safety reason, return 99% of available
        return (_totalAvailableDai * 99) / 100;
    }

    function _joinDai(address _urn, uint256 _amount) internal {
        DaiJoinLike _daiJoin = DaiJoinLike(mcdDaiJoin);
        // Transfer Dai from strategy or pool to here
        IERC20(DAI).safeTransferFrom(msg.sender, address(this), _amount);
        // Approves adapter to move dai.
        IERC20(DAI).safeApprove(mcdDaiJoin, 0);
        IERC20(DAI).safeApprove(mcdDaiJoin, _amount);
        // Joins DAI into the vat
        _daiJoin.join(_urn, _amount);
    }

    function _joinGem(address _adapter, uint256 _amount) internal returns (uint256) {
        GemJoinLike gemJoin = GemJoinLike(_adapter);

        IERC20 token = IERC20(gemJoin.gem());
        // Transfer token from strategy or pool to here
        token.safeTransferFrom(msg.sender, address(this), _amount);
        // Approves adapter to take the Gem amount
        token.safeApprove(_adapter, 0);
        token.safeApprove(_adapter, _amount);
        // Joins Gem collateral into the vat
        gemJoin.join(address(this), _amount);
        // Convert amount to 18 decimal
        return convertTo18(gemJoin.dec(), _amount);
    }

    /**
     * @dev Get borrow dai amount.
     */
    function _getBorrowAmount(
        address _vat,
        address _urn,
        uint256 _vaultNum,
        uint256 _wad
    ) internal returns (int256 amount) {
        // Updates stability fee rate
        uint256 rate = JugLike(mcdJug).drip(collateralType[_vaultNum]);
        // Gets DAI balance of the urn in the vat
        uint256 dai = VatLike(_vat).dai(_urn);
        // If there was already enough DAI in the vat balance, just exits it without adding more debt
        if (dai < _wad * RAY) {
            // Calculates the needed amt so together with the existing dai in the vat is enough to exit wad amount of DAI tokens
            amount = int256(((_wad * RAY) - dai) / rate);
            // This is needed due lack of precision. It might need to sum an extra amt wei (for the given DAI wad amount)
            amount = (uint256(amount) * rate) < (_wad * RAY) ? amount + 1 : amount;
        }
    }

    /// @notice Transfer vault ownership
    function _transferVaultOwnership(
        uint256 _vaultNum,
        address _owner,
        address _newOwner
    ) internal {
        require(_newOwner != address(0), "new-owner-address-is-zero");
        require(vaultNum[_owner] == _vaultNum, "invalid-vault-num");
        require(vaultNum[_newOwner] == 0, "new-owner-owns-another-vault");

        vaultNum[_newOwner] = _vaultNum;
        vaultNum[_owner] = 0;
        emit TransferredVaultOwnership(_vaultNum, _owner, _newOwner);
    }

    /**
     * @dev Get Vault Debt Amount.
     */
    function _getVaultDebt(
        bytes32 _ilk,
        address _urn,
        address _vat
    ) internal view returns (uint256 wad) {
        // Get normalized debt [wad]
        (, uint256 art) = VatLike(_vat).urns(_ilk, _urn);
        // Get stable coin rate [ray]
        (, uint256 rate, , , ) = VatLike(_vat).ilks(_ilk);
        // Get balance from vat [rad]
        uint256 dai = VatLike(_vat).dai(_urn);
        wad = _getVaultDebt(art, rate, dai);
    }

    function _getVaultInfo(uint256 _vaultNum)
        internal
        view
        returns (
            uint256 collateralLocked,
            uint256 collateralUsdRate,
            uint256 daiDebt,
            uint256 minimumDebt
        )
    {
        address _urn = ManagerLike(mcdManager).urns(_vaultNum);
        address _vat = ManagerLike(mcdManager).vat();
        bytes32 _ilk = collateralType[_vaultNum];
        // Get minimum liquidation ratio [ray]
        (, uint256 mat) = SpotterLike(mcdSpot).ilks(_ilk);
        // Get collateral locked and normalized debt [wad] [wad]
        (uint256 ink, uint256 art) = VatLike(_vat).urns(_ilk, _urn);
        // Get stable coin and collateral rate  and min debt [ray] [ray] [rad]
        (, uint256 rate, uint256 spot, , uint256 dust) = VatLike(_vat).ilks(_ilk);

        collateralLocked = ink;
        daiDebt = _getVaultDebt(art, rate, VatLike(_vat).dai(_urn));
        minimumDebt = dust / RAY;
        // Calculate collateral rate in 18 decimals
        collateralUsdRate = rmul(mat, spot) / 10**9;
    }

    /**
     * @dev Get Payback amount.
     * @notice We need to fetch latest art, rate and dai to calculate payback amount.
     */
    function _getWipeAmount(
        bytes32 _ilk,
        address _urn,
        address _vat
    ) internal view returns (int256 amount) {
        // Get normalize debt, rate and dai balance from Vat
        (, uint256 _art) = VatLike(_vat).urns(_ilk, _urn);
        (, uint256 _rate, , , ) = VatLike(_vat).ilks(_ilk);
        uint256 _dai = VatLike(_vat).dai(_urn);

        // Uses the whole dai balance in the vat to reduce the debt
        amount = int256(_dai / _rate);
        // Checks the calculated amt is not higher than urn.art (total debt), otherwise uses its value
        amount = uint256(amount) <= _art ? -amount : -int256(_art);
    }

    /// @notice Get collateral ratio
    function _getCollateralRatio(
        uint256 _collateralLocked,
        uint256 _collateralRate,
        uint256 _daiDebt
    ) internal pure returns (uint256) {
        if (_collateralLocked == 0) {
            return 0;
        }

        if (_daiDebt == 0) {
            return MAX_UINT_VALUE;
        }

        require(_collateralRate != 0, "collateral-rate-is-zero");
        return wdiv(wmul(_collateralLocked, _collateralRate), _daiDebt);
    }

    /// @notice Get vault debt
    function _getVaultDebt(
        uint256 _art,
        uint256 _rate,
        uint256 _dai
    ) internal pure returns (uint256 wad) {
        if (_dai < (_art * _rate)) {
            uint256 rad = ((_art * _rate) - _dai);
            wad = rad / RAY;
            wad = (wad * RAY) < rad ? wad + 1 : wad;
        } else {
            wad = 0;
        }
    }
}

