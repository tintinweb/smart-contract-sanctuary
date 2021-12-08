// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./libs/Address.sol";
import "./libs/Context.sol";
import "./libs/Ownable.sol";
import "./libs/ReentrancyGuard.sol";
import "./libs/Pausable.sol";
import "./libs/IERC20.sol";
import "./libs/SafeMath.sol";
import "./libs/SafeERC20.sol";
import "./libs/ERC20.sol";

interface ICurveRewardsOnlyGauge {
  function reward_contract() external returns(address);
  function balanceOf(address _user) external returns (uint256);
  function claim_rewards() external;
  function deposit(uint256 _value) external;
  function withdraw(uint256 _value) external;
}

interface ICurveStableSwapAave {
  function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external;
}

interface IReward {
  function updateRewards(address userAddress, uint256 sharesChange, bool isSharesRemoved) external;
}

interface IRouter {
  function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
  function swapExactTokensForTokensSupportingFeeOnTransferTokens(  uint amountIn,  uint amountOutMin,  address[] calldata path,  address to,  uint deadline) external;
}

contract Curve_PolyCub_Vault is Ownable, ReentrancyGuard, Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public masterChefAddress;
  address public farmContractAddress;
  address public wantAddress;
  address public govAddress;
  address public rewardsAddress;

  address public uniRouterAddress;
  address public token0Address;
  address[] public earnedToToken0Path;

  address public earnedAddress;
  address public maticAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

  uint256 public wantLockedTotal;
  uint256 public sharesTotal;
  uint256 public lastEarnBlock;

  uint256 public entranceFeeFactor;
  uint256 public constant entranceFeeFactorMax = 10000;
  uint256 public constant entranceFeeFactorLL = 9950;

  uint256 public withdrawFeeFactor;
  uint256 public constant withdrawFeeFactorMax = 10000;
  uint256 public constant withdrawFeeFactorLL = 9950;

  uint256 public controllerFee = 1000;
  uint256 public constant controllerFeeMax = 10000; // 100 = 1%
  uint256 public constant controllerFeeUL = 1000;

  uint256 public buyBackRate = 0; // 250;
  uint256 public constant buyBackRateMax = 10000; // 100 = 1%
  uint256 public constant buyBackRateUL = 800;
  address public buyBackAddress = 0x000000000000000000000000000000000000dEaD;

  uint256 public slippageFactor = 0; // 5% default slippage tolerance
  uint256 public constant slippageFactorUL = 995;

  bool public isAutoComp = true;
  bool public isSameAssetDeposit = false;
  bool public onlyGov = true;

  address[] public rewarders;
  address[] public CRVToUSDCPath;

  address public curvePoolAddress;
  address public CRVAddress = 0x172370d5Cd63279eFa6d502DAB29171933a610AF;
  address public reward_contract;

  modifier onlyAllowGov() {
    require(msg.sender == govAddress, "!gov");
    _;
  }

  constructor(
    address _farmContractAddress,
    address[] memory _rewarders,
    address[] memory _CRVToUSDCPath,
    address _masterChefAddress,
    address _wantAddress,
    address _govAddress,
    address _rewardsAddress,
    address _uniRouterAddress,
    address _token0Address,
    address[] memory _earnedToToken0Path,
    address _earnedAddress,
    uint256 _entranceFeeFactor,
    uint256 _withdrawFeeFactor,
    address _reward_contract,
    address _curvePoolAddress
  ) public {
    farmContractAddress = _farmContractAddress;
    rewarders = _rewarders;
    CRVToUSDCPath = _CRVToUSDCPath;
    reward_contract = ICurveRewardsOnlyGauge(farmContractAddress).reward_contract();
    masterChefAddress = _masterChefAddress;
    wantAddress = _wantAddress;
    govAddress = _govAddress;
    rewardsAddress = _rewardsAddress;
    uniRouterAddress = _uniRouterAddress;
    token0Address = _token0Address;
    earnedToToken0Path = _earnedToToken0Path;
    earnedAddress = _earnedAddress;
    entranceFeeFactor = _entranceFeeFactor;
    withdrawFeeFactor = _withdrawFeeFactor;
    rewarders = _rewarders;
    CRVToUSDCPath = _CRVToUSDCPath;
    reward_contract = _reward_contract;
    curvePoolAddress = _curvePoolAddress;
  }

  function updateRewarders(address[] memory _rewarders) public onlyAllowGov {
    rewarders = _rewarders;
  }

  function _harvestReward(
    address _userAddress,
    uint256 _sharesChange,
    bool _isSharesRemoved
  ) internal {
    for (uint256 i=0; i<rewarders.length; i++) {
      if (!Address.isContract(rewarders[i])) {
        continue;
      }
      IReward(rewarders[i]).updateRewards(
        _userAddress,
        _sharesChange,
        _isSharesRemoved
      );
    }
  }

  // Receives new deposits from user
  function deposit(address _userAddress, uint256 _wantAmt)
    public
    onlyOwner
    nonReentrant
    whenNotPaused
    returns (uint256)
  {
    IERC20(wantAddress).safeTransferFrom(
      address(msg.sender),
      address(this),
      _wantAmt
    );
    reward_contract = ICurveRewardsOnlyGauge(farmContractAddress).reward_contract();

    wantLockedTotal = ICurveRewardsOnlyGauge(farmContractAddress).balanceOf(
      address(this)
    );
    uint256 sharesAdded = _wantAmt;
    if (wantLockedTotal > 0 && sharesTotal > 0) {
      sharesAdded = _wantAmt
        .mul(sharesTotal)
        .mul(entranceFeeFactor)
        .div(wantLockedTotal)
        .div(entranceFeeFactorMax);
    }
    sharesTotal = sharesTotal.add(sharesAdded);

    if (isAutoComp) {
      _farm();
    }

    _harvestReward(_userAddress, sharesAdded, false);

    return sharesAdded;
  }

  function _farm() internal {
    require(isAutoComp, "!isAutoComp");
    uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
    IERC20(wantAddress).safeIncreaseAllowance(farmContractAddress, wantAmt);
    ICurveRewardsOnlyGauge(farmContractAddress).deposit(wantAmt);
    wantLockedTotal = ICurveRewardsOnlyGauge(farmContractAddress).balanceOf(
      address(this)
    );
  }

  function _unfarm(uint256 _wantAmt) internal {
    if (_wantAmt == 0) {
      ICurveRewardsOnlyGauge(farmContractAddress).claim_rewards();
    } else {
      ICurveRewardsOnlyGauge(farmContractAddress).withdraw(_wantAmt);
    }
  }

  function withdraw(address _userAddress, uint256 _wantAmt)
    public
    onlyOwner
    nonReentrant
    returns (uint256)
  {
    require(_wantAmt > 0, "_wantAmt <= 0");

    wantLockedTotal = ICurveRewardsOnlyGauge(farmContractAddress).balanceOf(
      address(this)
    );

    uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantLockedTotal);
    if (sharesRemoved > sharesTotal) {
      sharesRemoved = sharesTotal;
    }
    sharesTotal = sharesTotal.sub(sharesRemoved);

    if (withdrawFeeFactor < withdrawFeeFactorMax) {
      _wantAmt = _wantAmt.mul(withdrawFeeFactor).div(
          withdrawFeeFactorMax
      );
    }

    if (isAutoComp) {
      _unfarm(_wantAmt);
    }

    uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
    if (_wantAmt > wantAmt) {
      _wantAmt = wantAmt;
    }

    if (wantLockedTotal < _wantAmt) {
      _wantAmt = wantLockedTotal;
    }

    IERC20(wantAddress).safeTransfer(masterChefAddress, _wantAmt);

    wantLockedTotal = ICurveRewardsOnlyGauge(farmContractAddress).balanceOf(
      address(this)
    );

    _harvestReward(_userAddress, sharesRemoved, true);

    return sharesRemoved;
  }

  function earn() public nonReentrant whenNotPaused {
    require(isAutoComp, "!isAutoComp");
    if (onlyGov) {
      require(msg.sender == govAddress, "!gov");
    }

    // Harvest farm tokens
    _unfarm(0);

    // Converts farm tokens into want tokens
    uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

    earnedAmt = distributeFees(earnedAmt);

    if (isSameAssetDeposit) {
      lastEarnBlock = block.number;
      _farm();
      return;
    }

    if (earnedAmt > 0){
      IERC20(earnedAddress).safeApprove(uniRouterAddress, 0);
      IERC20(earnedAddress).safeIncreaseAllowance(
        uniRouterAddress,
        earnedAmt
      );

      // Swap earned to token0
      _safeSwap(
        uniRouterAddress,
        earnedAmt,
        slippageFactor,
        earnedToToken0Path,
        address(this),
        block.timestamp.add(600)
      );
    }

    _convertCRVToUSDC();

    // Get want tokens, ie. add liquidity
    uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));

    if (token0Amt > 0) {
      IERC20(token0Address).safeApprove(curvePoolAddress, 0);
      IERC20(token0Address).safeIncreaseAllowance(
        curvePoolAddress,
        token0Amt
      );

      ICurveStableSwapAave(curvePoolAddress).add_liquidity([0, token0Amt], 0);
    }

    lastEarnBlock = block.number;

    _farm();
  }

  function distributeFees(uint256 _earnedAmt)
      internal
      virtual
      returns (uint256)
  {
      if (_earnedAmt > 0) {
          // Performance fee
          if (controllerFee > 0) {
              uint256 fee =
                  _earnedAmt.mul(controllerFee).div(controllerFeeMax);
              IERC20(earnedAddress).safeTransfer(rewardsAddress, fee);
              _earnedAmt = _earnedAmt.sub(fee);
          }
      }

      return _earnedAmt;
  }

  function _convertCRVToUSDC() internal {
    uint256 CRVAmt = IERC20(CRVAddress).balanceOf(address(this));
    if (CRVAddress != earnedAddress && CRVAmt > 0) {
      IERC20(CRVAddress).safeIncreaseAllowance(uniRouterAddress, CRVAmt);
      // Swap all dust tokens to earned tokens
      _safeSwap(
        uniRouterAddress,
        CRVAmt,
        slippageFactor,
        CRVToUSDCPath,
        address(this),
        now.add(600)
      );
    }
  }

  function setSettings(
      uint256 _entranceFeeFactor,
      uint256 _withdrawFeeFactor,
      uint256 _controllerFee,
      uint256 _buyBackRate,
      uint256 _slippageFactor
  ) public virtual onlyAllowGov {
      require(
          _entranceFeeFactor >= entranceFeeFactorLL,
          "_entranceFeeFactor too low"
      );
      require(
          _entranceFeeFactor <= entranceFeeFactorMax,
          "_entranceFeeFactor too high"
      );
      entranceFeeFactor = _entranceFeeFactor;

      require(
          _withdrawFeeFactor >= withdrawFeeFactorLL,
          "_withdrawFeeFactor too low"
      );
      require(
          _withdrawFeeFactor <= withdrawFeeFactorMax,
          "_withdrawFeeFactor too high"
      );
      withdrawFeeFactor = _withdrawFeeFactor;

      require(_controllerFee <= controllerFeeUL, "_controllerFee too high");
      controllerFee = _controllerFee;

      require(_buyBackRate <= buyBackRateUL, "_buyBackRate too high");
      buyBackRate = _buyBackRate;

      require(
          _slippageFactor <= slippageFactorUL,
          "_slippageFactor too high"
      );
      slippageFactor = _slippageFactor;
  }

  function setGov(address _govAddress) public virtual onlyAllowGov {
      govAddress = _govAddress;
  }

  function setOnlyGov(bool _onlyGov) public virtual onlyAllowGov {
      onlyGov = _onlyGov;
  }

  function setUniRouterAddress(address _uniRouterAddress)
      public
      virtual
      onlyAllowGov
  {
      uniRouterAddress = _uniRouterAddress;
  }

  function setBuyBackAddress(address _buyBackAddress)
      public
      virtual
      onlyAllowGov
  {
      buyBackAddress = _buyBackAddress;
  }

  function setRewardsAddress(address _rewardsAddress)
      public
      virtual
      onlyAllowGov
  {
      rewardsAddress = _rewardsAddress;
  }

  function changePaused() external onlyAllowGov {
    if (paused()) _unpause();
    else _pause();
  }


  function inCaseTokensGetStuck(
      address _token,
      uint256 _amount,
      address _to
  ) public virtual onlyAllowGov {
      require(_token != earnedAddress, "!safe");
      require(_token != wantAddress, "!safe");
      IERC20(_token).safeTransfer(_to, _amount);
  }

  function _safeSwap(
      address _uniRouterAddress,
      uint256 _amountIn,
      uint256 _slippageFactor,
      address[] memory _path,
      address _to,
      uint256 _deadline
  ) internal virtual {
      uint256[] memory amounts =
          IRouter(_uniRouterAddress).getAmountsOut(_amountIn, _path);
      uint256 amountOut = amounts[amounts.length.sub(1)];

      IRouter(_uniRouterAddress)
          .swapExactTokensForTokensSupportingFeeOnTransferTokens(
          _amountIn,
          amountOut.mul(_slippageFactor).div(1000),
          _path,
          _to,
          _deadline
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
pragma solidity 0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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

    constructor() internal {
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
pragma solidity 0.6.12;

import "./Context.sol";

contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
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
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
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
     * opcode (which leaves remaining gas untouched) while Solidity uses an
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";

library SafeERC20 {
    using SafeMath for uint256;
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
        // solhint-disable-next-line max-line-length
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
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
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
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Context.sol";

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * - `to` cannot be the zero address.
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