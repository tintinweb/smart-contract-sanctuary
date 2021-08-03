// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface ICurveZap {
    function compound(uint256 _amount, address _vault) external returns (uint256);
    function emergencyWithdraw(uint256 _amount, address _vault) external;
}

interface ICvVault {
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function poolInfo(uint256 _pid) external view returns (address, address, address, address, address, bool);
}

interface ICvStake {
    function balanceOf(address _account) external view returns (uint256);
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external;
    function getReward() external returns(bool);
    function extraRewards(uint256 _index) external view returns (address);
    function extraRewardsLength() external view returns (uint256);
}

interface ICvRewards {
    function rewardToken() external view returns (address);
}

interface ISushiRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IWETH is IERC20Upgradeable {
    function withdraw(uint256 _amount) external;
}

contract EarnStrategyUNIv2 is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IWETH;

    ISushiRouter private constant _sushiRouter = ISushiRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    ISushiRouter private constant _uniRouter = ISushiRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    ICvVault private constant _cvVault = ICvVault(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    ICvStake public cvStake;
    ICurveZap public curveZap;

    IWETH private constant _WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20Upgradeable private constant _CVX = IERC20Upgradeable(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20Upgradeable private constant _CRV = IERC20Upgradeable(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20Upgradeable public lpToken;

    address public vault;
    uint256 public pid; // Index for Convex pool

    // Fees
    uint256 public yieldFeePerc;
    address public admin;
    address public communityWallet;
    address public strategist;

    event Invest(uint256 amount);
    event Yield(uint256 amtToCompound, uint256 lpTokenBal);
    event YieldFee(uint256 yieldFee);
    event Withdraw(uint256 lpTokenBalance);
    event EmergencyWithdraw(uint256 lpTokenBalance);
    event SetVault(address indexed vaultAddress);
    event SetCurveZap(address indexed curveZap);
    event SetYieldFeePerc(uint256 indexed percentage);
    event SetCommunityWallet(address indexed communityWalletAddress);
    event SetAdmin(address indexed adminAddress);
    event SetStrategist(address indexed strategistAddress);

    modifier onlyVault {
        require(msg.sender == vault, "Only vault");
        _;
    }

    /// @notice Initialize this strategy contract
    /// @notice This function can only be execute once (by strategy factory contract)
    /// @param _pid Index of pool in Convex
    /// @param _curveZap Address of CurveZap contract
    /// @param _admin Address of admin
    /// @param _communityWallet Address of community wallet
    /// @param _strategist Address of strategist
    function initialize(
        uint256 _pid, address _curveZap,
        address _admin, address _communityWallet, address _strategist
    ) external initializer {
        __Ownable_init();

        yieldFeePerc = 2000;
        admin = _admin;
        communityWallet = _communityWallet;
        strategist = _strategist;
        curveZap = ICurveZap(_curveZap);
        pid = _pid;

        // _CVX.safeApprove(address(_sushiRouter), type(uint256).max);
        // _CRV.safeApprove(address(_sushiRouter), type(uint256).max);
        // _WETH.safeApprove(_curveZap, type(uint256).max);

        // Add pool
        // (address _lpTokenAddr, , , address _cvStakeAddr, , ) = _cvVault.poolInfo(_pid);
        lpToken = IERC20Upgradeable(0xBB06dF04f0D508FC4b1bdBbf164d82884C5F677A);
        // lpToken.safeApprove(address(_cvVault), type(uint256).max);
        // cvStake = ICvStake(_cvStakeAddr);
    }

    /// @notice Function to invest token into Convex
    /// @param _amount Amount to invest (18 decimals)
    function invest(uint256 _amount) external {
        require(msg.sender == vault || msg.sender == address(curveZap), "Only authorized caller");
        lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        _cvVault.deposit(pid, _amount, true);
        emit Invest(_amount);
    }

    /// @notice Function to yield farms rewards
    function yield() external onlyVault {
        cvStake.getReward();
        uint256 _amtToCompound = _yield();
        // Deposit _amtToCompound (in WETH) to CurveZap contract, zap it to LP token and transfer back here
        uint256 _lpTokenBal = curveZap.compound(_amtToCompound, address(vault));
        emit Yield(_amtToCompound, _lpTokenBal);
    }

    /// @notice Derived function from yield()
    function _yield() private returns (uint256) {
        uint256 _CVXBalance = _CVX.balanceOf(address(this));
        if (_CVXBalance > 0) {
            _swap(address(_CVX), address(_WETH), _CVXBalance);
        }
        uint256 _CRVBalance = _CRV.balanceOf(address(this));
        if (_CRVBalance > 0) {
            _swap(address(_CRV), address(_WETH), _CRVBalance);
        }
        // Dealing with extra reward tokens if available
        if (cvStake.extraRewardsLength() > 0) {
            // Extra reward tokens might more than 1
            for (uint256 _i = 0; _i < cvStake.extraRewardsLength(); _i++) {
                IERC20Upgradeable _extraRewardToken = IERC20Upgradeable(ICvRewards(cvStake.extraRewards(_i)).rewardToken());
                uint256 _extraRewardTokenBalance = _extraRewardToken.balanceOf(address(this));
                if (_extraRewardTokenBalance > 0) {
                    // We do token approval here, because the reward tokens have many kinds and 
                    // might be added in future by Convex
                    if (_extraRewardToken.allowance(address(this), address(_uniRouter)) == 0) {
                        _extraRewardToken.safeApprove(address(_uniRouter), type(uint256).max);
                    }
                    address[] memory _path = new address[](2);
                    _path[0] = address(_extraRewardToken);
                    _path[1] = address(_WETH);
                    _uniRouter.swapExactTokensForTokens(_extraRewardTokenBalance, 0, _path, address(this), block.timestamp);
                }
            }
        }
        // Split yield fees
        uint256 _WETHBalance = _WETH.balanceOf(address(this));
        uint256 _yieldFee = _WETHBalance - (_WETHBalance * yieldFeePerc / 10000);
        _WETH.withdraw(_yieldFee);
        uint256 _yieldFeeInETH = address(this).balance * 2 / 5;
        (bool _a,) = admin.call{value: _yieldFeeInETH}(""); // 40%
        require(_a, "Fee transfer failed");
        (bool _t,) = communityWallet.call{value: _yieldFeeInETH}(""); // 40%
        require(_t, "Fee transfer failed");
        (bool _s,) = strategist.call{value: (address(this).balance)}(""); // 20%
        require(_s, "Fee transfer failed");

        emit YieldFee(_yieldFee);
        return _WETHBalance - _yieldFee;
    }

    // To enable receive ETH from WETH in _yield()
    receive() external payable {}

    /// @notice Function to withdraw token from Convex
    /// @param _amount Amount of token to withdraw (18 decimals)
    function withdraw(uint256 _amount) external onlyVault returns (uint256 _lpTokenBal) {
        cvStake.withdrawAndUnwrap(_amount, false);
        _lpTokenBal = lpToken.balanceOf(address(this));
        lpToken.safeTransfer(address(vault), _lpTokenBal);
        emit Withdraw(_lpTokenBal);
    }

    /// @notice Swap tokens with Sushi
    /// @param _tokenA Token to be swapped
    /// @param _tokenB Token to be received
    /// @param _amount Amount of token to be swapped
    function _swap(address _tokenA, address _tokenB, uint256 _amount) private {
        address[] memory _path = new address[](2);
        _path[0] = _tokenA;
        _path[1] = _tokenB;
        _sushiRouter.swapExactTokensForTokens(_amount, 0, _path, address(this), block.timestamp);
    }

    /// @notice Function to withdraw all funds from farm and transfer to vault
    function emergencyWithdraw() external onlyVault {
        cvStake.withdrawAndUnwrap(getTotalPool(), true);
        uint256 _amtToDeposit = _yield();
        curveZap.emergencyWithdraw(_amtToDeposit, address(vault));
        uint256 _lpTokenBal = lpToken.balanceOf(address(this));
        lpToken.safeTransfer(address(vault), _lpTokenBal);
        emit EmergencyWithdraw(_lpTokenBal);
    }

    /// @notice Function to set vault address that interact with this contract. This function can only execute once when deployment.
    /// @param _vault Address of vault contract
    function setVault(address _vault) external {
        require(vault == address(0), "Vault set");
        vault = _vault;
        emit SetVault(_vault);
    }

    /// @notice Function to set new CurveZap contract address from vault contract
    /// @param _curveZap Address of new CurveZap contract
    function setCurveZap(address _curveZap) external onlyVault {
        curveZap = ICurveZap(_curveZap);
        _WETH.safeApprove(_curveZap, type(uint256).max);
        emit SetCurveZap(_curveZap);
    }

    /// @notice Function to set new yield fee percentage from vault contract
    /// @param _percentage Percentage of new yield fee
    function setYieldFeePerc(uint256 _percentage) external onlyVault {
        yieldFeePerc = _percentage;
        emit SetYieldFeePerc(_percentage);
    }

    /// @notice Function to set new community wallet from vault contract
    /// @param _communityWallet Address of new community wallet
    function setCommunityWallet(address _communityWallet) external onlyVault {
        communityWallet = _communityWallet;
        emit SetCommunityWallet(_communityWallet);
    }

    /// @notice Function to set new admin address from vault contract
    /// @param _admin Address of new admin
    function setAdmin(address _admin) external onlyVault {
        admin = _admin;
        emit SetAdmin(_admin);
    }

    /// @notice Function to set new strategist address from vault contract
    /// @param _strategist Address of new strategist
    function setStrategist(address _strategist) external onlyVault {
        strategist = _strategist;
        emit SetStrategist(_strategist);
    }

    /// @notice Get total LP token in strategy
    /// @return Total LP token in strategy (18 decimals)
    function getTotalPool() public view returns (uint256) {
        return cvStake.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}