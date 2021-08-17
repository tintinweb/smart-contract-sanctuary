/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function mint(address account, uint amount) external;
  function burn(address account, uint amount) external;
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

interface IVault is IERC20 {
  function deposit(address _account, uint _amount) external;
  function depositETH(address _account) external payable;
  function withdraw(uint _amount) external;
  function withdrawETH(uint _amount) external;
  function withdrawFrom(address _source, uint _amount) external;
  function withdrawFromETH(address _source, uint _amount) external;
  function withdrawAll() external;
  function withdrawAllETH() external;
  function pushToken(address _token, uint _amount) external;
  function setDepositsEnabled(bool _value) external;
  function addIncome(uint _addAmount) external;
  function rewardRate() external view returns(uint);
  function underlying() external view returns(address);
  function pendingAccountReward(address _account) external view returns(uint);
  function claim(address _account) external;
}

interface IVaultController {
  function depositsEnabled() external view returns(bool);
  function depositLimit(address _vault) external view returns(uint);
  function setRebalancer(address _rebalancer) external;
  function rebalancer() external view returns(address);
}

interface IVaultFactory {
  function isVault(address _vault) external view returns(bool);
}

interface IOwnable {
  function transferOwnership(address _newOwner) external;
  function acceptOwnership() external;
}

interface IRewardDistribution {

  function distributeReward(address _account, address _token) external;
  function setTotalRewardPerBlock(uint _value) external;
  function migrateRewards(address _recipient, uint _amount) external;
  function accrueAllPools() external;
  function pendingAccountReward(address _account, address _pair) external view returns(uint);

  function addPool(
    address _pair,
    address _token,
    bool    _isSupply,
    uint    _points
  ) external;

  function setReward(
    address _pair,
    address _token,
    bool    _isSupply,
    uint    _points
  ) external;
}

interface ILendingController {
  function interestRateModel() external view returns(address);
  function rewardDistribution() external view returns(IRewardDistribution);
  function feeRecipient() external view returns(address);
  function LIQ_MIN_HEALTH() external view returns(uint);
  function minBorrowUSD() external view returns(uint);
  function liqFeeSystem(address _token) external view returns(uint);
  function liqFeeCaller(address _token) external view returns(uint);
  function liqFeesTotal(address _token) external view returns(uint);
  function colFactor(address _token) external view returns(uint);
  function depositLimit(address _lendingPair, address _token) external view returns(uint);
  function borrowLimit(address _lendingPair, address _token) external view returns(uint);
  function originFee(address _token) external view returns(uint);
  function depositsEnabled() external view returns(bool);
  function borrowingEnabled() external view returns(bool);
  function setFeeRecipient(address _feeRecipient) external;
  function setColFactor(address _token, uint _value) external;
  function tokenPrice(address _token) external view returns(uint);
  function tokenSupported(address _token) external view returns(bool);
  function setRewardDistribution(address _value) external;
  function setInterestRateModel(address _value) external;
  function targetLiqHealth() external view returns(uint);
  function setDepositLimit(address _pair, address _token, uint _value) external;
}

interface ILendingPair {
  function checkAccountHealth(address _account) external view;
  function accrueAccount(address _account) external;
  function accrue() external;
  function accountHealth(address _account) external view returns(uint);
  function totalDebt(address _token) external view returns(uint);
  function tokenA() external view returns(address);
  function tokenB() external view returns(address);
  function lpToken(address _token) external view returns(IERC20);
  function debtOf(address _account, address _token) external view returns(uint);
  function pendingDebtTotal(address _token) external view returns(uint);
  function pendingSupplyTotal(address _token) external view returns(uint);
  function lastBlockAccrued() external view returns(uint);
  function deposit(address _account, address _token, uint _amount) external;
  function pendingBorrowInterest(address _token, address _account) external view returns(uint);
  function pendingSupplyInterest(address _token, address _account) external view returns(uint);
  function supplyRatePerBlock(address _token) external view returns(uint);
  function withdraw(address _token, uint _amount) external;
  function borrow(address _token, uint _amount) external;
  function repay(address _token, uint _amount) external;
  function withdrawAll(address _token) external;
  function depositRepay(address _account, address _token, uint _amount) external;
  function withdrawBorrow(address _token, uint _amount) external;
  function lendingController() external view returns(ILendingController);

  function borrowBalance(
    address _account,
    address _borrowedToken,
    address _returnToken
  ) external view returns(uint);

  function supplyBalance(
    address _account,
    address _suppliedToken,
    address _returnToken
  ) external view returns(uint);

  function convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount
  ) external view returns(uint);
}

interface IPairFactory {

  function pairByTokens(address _tokenA, address _tokenB) external view returns(address);

  function createPair(
    address _tokenA,
    address _tokenB
  ) external returns(address);
}

interface IVaultRebalancer {
  function unload(address _vault, address _pair, uint _amount) external;
  function distributeIncome(address _vault) external;
}

library Math {

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute.
    return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
  }

  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }
}

contract Ownable {

  address public owner;
  address public pendingOwner;

  event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferInitiated(owner, _newOwner);
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external {
    require(msg.sender == pendingOwner, "Ownable: caller is not pending owner");
    emit OwnershipTransferConfirmed(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
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

contract ReentrancyGuard {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor () {
    _status = _NOT_ENTERED;
  }

  modifier nonReentrant() {
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }
}

interface IWETH {
  function deposit() external payable;
  function withdraw(uint wad) external;
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function approve(address spender, uint amount) external returns (bool);
}

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

contract TransferHelper {

  using SafeERC20 for IERC20;

  // Mainnet
  IWETH internal constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  function _safeTransferFrom(address _token, address _sender, uint _amount) internal virtual {
    require(_amount > 0, "TransferHelper: amount must be > 0");
    IERC20(_token).safeTransferFrom(_sender, address(this), _amount);
  }

  function _safeTransfer(address _token, address _recipient, uint _amount) internal virtual {
    require(_amount > 0, "TransferHelper: amount must be > 0");
    IERC20(_token).safeTransfer(_recipient, _amount);
  }

  function _wethWithdrawTo(address _to, uint _amount) internal virtual {
    require(_amount > 0, "TransferHelper: amount must be > 0");
    require(_to != address(0), "TransferHelper: invalid recipient");

    WETH.withdraw(_amount);
    (bool success, ) = _to.call { value: _amount }(new bytes(0));
    require(success, 'TransferHelper: ETH transfer failed');
  }

  function _depositWeth() internal {
    require(msg.value > 0, "TransferHelper: amount must be > 0");
    WETH.deposit { value: msg.value }();
  }
}

contract VaultRebalancer is IVaultRebalancer, TransferHelper, Ownable, ReentrancyGuard {

  using Address for address;

  uint private constant DISTRIBUTION_PERIOD = 45_800; // 7 days - 3600 * 24 * 7 / 13.2

  uint public callIncentive;

  address public immutable vaultController;
  address public immutable vaultFactory;
  address public immutable pairFactory;

  /**
   * pairDeposits value is lost when we redeploy rebalancer.
   * The impact is limited to the loss of unclaimed income.
   * It's recommended to call accrue()
   * on all vaults/pairs before replacing the rebalancer.
  **/
  mapping (address => uint) public pairDeposits;

  event InitiateRebalancerMigration(address indexed newOwner);
  event Rebalance(address indexed fromPair, address indexed toPair, uint amount);
  event FeeDistribution(uint amount);
  event NewCallIncentive(uint value);

  modifier onlyVault() {
    require(IVaultFactory(vaultFactory).isVault(msg.sender), "VaultRebalancer: caller is not the vault");
    _;
  }

  modifier vaultOrOwner() {
    require(
      IVaultFactory(vaultFactory).isVault(msg.sender) ||
      msg.sender == owner,
      "VaultRebalancer: unauthorized");
    _;
  }

  receive() external payable {}

  constructor(
    address _vaultController,
    address _vaultFactory,
    address _pairFactory,
    uint    _callIncentive
  ) {

    _requireContract(_vaultController);
    _requireContract(_vaultFactory);
    _requireContract(_pairFactory);

    vaultController = _vaultController;
    vaultFactory    = _vaultFactory;
    pairFactory     = _pairFactory;
    callIncentive   = _callIncentive;
  }

  function rebalance(
    address _vault,
    address _fromPair,
    address _toPair,
    uint    _withdrawAmount
  ) external onlyOwner nonReentrant {

    _validatePair(_fromPair);
    _validatePair(_toPair);

    uint income          = _pairWithdrawWithIncome(_vault, _fromPair, _withdrawAmount);
    uint callerIncentive = Math.min(income * callIncentive / 100e18, 1e17);
    address underlying   = _underlying(_vault);

    _pairDeposit(_vault, underlying, _toPair, _withdrawAmount);
    IERC20(underlying).transfer(msg.sender, callerIncentive);

    emit Rebalance(address(_fromPair), address(_toPair), _withdrawAmount);
  }

  // Deploy assets from the vault
  function enterPair(
    address _vault,
    address _toPair,
    uint    _depositAmount
  ) external onlyOwner nonReentrant {

    _validatePair(_toPair);

    // Since there is no earned income yet
    // we calculate caller incentive as (_depositAmount / 1000)
    // and cap it to at most 0.1 ETH
    uint callerIncentive = Math.min(_depositAmount / 1000, 1e17);

    address underlying = address(_underlying(_vault));

    IVault(_vault).pushToken(underlying, _depositAmount);
    _pairDeposit(_vault, underlying, _toPair, _depositAmount - callerIncentive);
    IERC20(underlying).transfer(msg.sender, callerIncentive);

    emit Rebalance(address(0), address(_toPair), _depositAmount);
  }

  // Pull in income without rebalancing
  function accrue(
    address _vault,
    address _pair
  ) external onlyOwner {
    _pairWithdrawWithIncome(_vault, _pair, 0);
  }

  // Increase the vault buffer
  function unload(
    address _vault,
    address _pair,
    uint    _amount
  ) external override vaultOrOwner {

    _validatePair(_pair);
    _pairWithdrawWithIncome(_vault, _pair, _amount);
    _safeTransfer(_underlying(_vault), _vault, _amount);
  }

  function distributeIncome(address _vault) external override onlyOwner nonReentrant {

    IERC20 underlying = IERC20(_underlying(_vault));
    uint income       = underlying.balanceOf(address(this));
    uint callerReward = Math.min(income * callIncentive / 100e18, 1e17);
    uint netIncome    = income - callerReward;

    underlying.approve(_vault, income);
    IVault(_vault).addIncome(netIncome);

    underlying.transfer(msg.sender, callerReward);

    emit FeeDistribution(netIncome);
  }

  function setCallIncentive(uint _value) external onlyOwner {
    callIncentive = _value;
    emit NewCallIncentive(_value);
  }

  // In case anything goes wrong
  function rescueToken(address _token, uint _amount) external onlyOwner {
    _safeTransfer(_token, msg.sender, _amount);
  }

  function _pairWithdrawWithIncome(
    address _vault,
    address _pair,
    uint    _amount
  ) internal returns(uint) {

    address underlying = _underlying(_vault);
    ILendingPair pair = ILendingPair(_pair);

    _ensureDepositRecord(_vault, underlying, _pair);
    uint income = _balanceWithPendingInterest(_vault, underlying, _pair) - pairDeposits[_pair];
    uint transferAmount = _amount + income;

    if (transferAmount > 0) {
      IVault(_vault).pushToken(address(pair.lpToken(underlying)), transferAmount);
      pair.withdraw(underlying, transferAmount);
      pairDeposits[_pair] = _balanceWithPendingInterest(_vault, underlying, _pair);
    }

    return income;
  }

  function _ensureDepositRecord(
    address _vault,
    address _underlying,
    address _pair
  ) internal {

    if (pairDeposits[_pair] == 0) {
      pairDeposits[_pair] = _balanceWithPendingInterest(_vault, _underlying, _pair);
    }
  }

  function _pairDeposit(
    address _vault,
    address _underlying,
    address _pair,
    uint    _amount
  ) internal {

    IERC20(_underlying).approve(_pair, _amount);
    ILendingPair(_pair).deposit(_vault, _underlying, _amount);
    pairDeposits[_pair] = _balanceWithPendingInterest(_vault, _underlying, _pair);
  }

  function _balanceWithPendingInterest(
    address _vault,
    address _underlying,
    address _pair
  ) internal view returns(uint) {

    ILendingPair pair = ILendingPair(_pair);
    uint balance = pair.supplyBalance(_vault, _underlying, _underlying);
    uint pending = pair.pendingSupplyInterest(_underlying, _vault);
    return balance + pending;
  }

  function _lpBalance(
    address _pair,
    address _underlying
  ) internal view returns(uint) {
    return IERC20(ILendingPair(_pair).lpToken(_underlying)).balanceOf(address(this));
  }

  function _validatePair(address _pair) internal view {
    ILendingPair pair = ILendingPair(_pair);

    require(
      _pair == IPairFactory(pairFactory).pairByTokens(pair.tokenA(), pair.tokenB()),
      "VaultRebalancer: invalid lending pair"
    );
  }

  function _requireContract(address _value) internal view {
    require(_value.isContract(), "VaultRebalancer: must be a contract");
  }

  function _underlying(address _vault) internal view returns(address) {
    return IVault(_vault).underlying();
  }
}