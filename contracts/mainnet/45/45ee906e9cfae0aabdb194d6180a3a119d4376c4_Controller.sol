/**
 *Submitted for verification at Etherscan.io on 2021-07-21
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

interface IInterestRateModel {
  function systemRate(ILendingPair _pair, address _token) external view returns(uint);
  function supplyRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
  function borrowRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
}

interface IRewardDistribution {
  function distributeReward(address _account, address _token) external;
}

interface IController {
  function interestRateModel() external view returns(IInterestRateModel);
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
  function tokenPrice(address _token) external view returns(uint);
  function tokenSupported(address _token) external view returns(bool);
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
  function deposit(address _token, uint _amount) external;
  function withdraw(address _token, uint _amount) external;
  function borrow(address _token, uint _amount) external;
  function repay(address _token, uint _amount) external;
  function withdrawBorrow(address _token, uint _amount) external;
  function controller() external view returns(IController);

  function borrowBalance(
    address _account,
    address _borrowedToken,
    address _returnToken
  ) external view returns(uint);

  function convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount
  ) external view returns(uint);
}

interface IPriceOracle {
  function tokenPrice(address _token) external view returns(uint);
  function tokenSupported(address _token) external view returns(bool);
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

contract Controller is Ownable {

  using Address for address;

  uint public  constant LIQ_MIN_HEALTH = 1e18;
  uint private constant MAX_COL_FACTOR = 99e18;
  uint private constant MAX_LIQ_FEES   = 50e18;

  IInterestRateModel  public interestRateModel;
  IPriceOracle        public priceOracle;
  IRewardDistribution public rewardDistribution;

  bool public depositsEnabled;
  bool public borrowingEnabled;
  uint public liqFeeCallerDefault;
  uint public liqFeeSystemDefault;
  uint public originFeeDefault;
  uint public minBorrowUSD;

  mapping(address => mapping(address => uint)) public depositLimit;
  mapping(address => mapping(address => uint)) public borrowLimit;
  mapping(address => uint) public originFeeToken;
  mapping(address => uint) public liqFeeCallerToken; // 1e18  = 1%
  mapping(address => uint) public liqFeeSystemToken; // 1e18  = 1%
  mapping(address => uint) public colFactor; // 99e18 = 99%

  address public feeRecipient;

  event NewFeeRecipient(address feeRecipient);
  event NewInterestRateModel(address interestRateModel);
  event NewPriceOracle(address priceOracle);
  event NewRewardDistribution(address rewardDistribution);
  event NewColFactor(address token, uint value);
  event NewDepositLimit(address pair, address token, uint value);
  event NewBorrowLimit(address pair, address token, uint value);
  event DepositsEnabled(bool value);
  event BorrowingEnabled(bool value);
  event NewLiqParamsToken(address token, uint liqFeeSystem, uint liqFeeCaller);
  event NewLiqParamsDefault(uint liqFeeSystem, uint liqFeeCaller);
  event NewOriginFeeDefault(uint value);
  event NewOriginFeeToken(address token, uint value);
  event NewMinBorrowUSD(uint value);

  constructor(
    address _interestRateModel,
    uint _liqFeeSystemDefault,
    uint _liqFeeCallerDefault,
    uint _originFeeDefault,
    uint _minBorrowUSD
  ) {
    _requireContract(_interestRateModel);
    require(_liqFeeSystemDefault + _liqFeeCallerDefault <= MAX_LIQ_FEES, "Controller: fees too high");

    interestRateModel = IInterestRateModel(_interestRateModel);
    liqFeeSystemDefault = _liqFeeSystemDefault;
    liqFeeCallerDefault = _liqFeeCallerDefault;
    originFeeDefault    = _originFeeDefault;
    minBorrowUSD        = _minBorrowUSD;
    depositsEnabled = true;
    borrowingEnabled = true;
  }

  function setFeeRecipient(address _value) external onlyOwner {
    _requireContract(_value);
    feeRecipient = _value;
    emit NewFeeRecipient(_value);
  }

  function setLiqParamsToken(
    address _token,
    uint    _liqFeeSystem,
    uint    _liqFeeCaller
  ) external onlyOwner {
    require(_liqFeeCaller + _liqFeeSystem <= MAX_LIQ_FEES, "Controller: fees too high");
    _requireContract(_token);

    liqFeeSystemToken[_token] = _liqFeeSystem;
    liqFeeCallerToken[_token] = _liqFeeCaller;

    emit NewLiqParamsToken(_token, _liqFeeSystem, _liqFeeCaller);
  }

  function setLiqParamsDefault(
    uint    _liqFeeSystem,
    uint    _liqFeeCaller
  ) external onlyOwner {
    require(_liqFeeCaller + _liqFeeSystem <= MAX_LIQ_FEES, "Controller: fees too high");

    liqFeeSystemDefault = _liqFeeSystem;
    liqFeeCallerDefault = _liqFeeCaller;

    emit NewLiqParamsDefault(_liqFeeSystem, _liqFeeCaller);
  }

  function setInterestRateModel(address _value) external onlyOwner {
    _requireContract(_value);
    interestRateModel = IInterestRateModel(_value);
    emit NewInterestRateModel(address(_value));
  }

  function setPriceOracle(address _value) external onlyOwner {
    _requireContract(_value);
    priceOracle = IPriceOracle(_value);
    emit NewPriceOracle(address(_value));
  }

  function setRewardDistribution(address _value) external onlyOwner {
    _requireContract(_value);
    rewardDistribution = IRewardDistribution(_value);
    emit NewRewardDistribution(address(_value));
  }

  function setDepositsEnabled(bool _value) external onlyOwner {
    depositsEnabled = _value;
    emit DepositsEnabled(_value);
  }

  function setBorrowingEnabled(bool _value) external onlyOwner {
    borrowingEnabled = _value;
    emit BorrowingEnabled(_value);
  }

  function setDefaultOriginFee(uint _value) external onlyOwner {
    originFeeDefault = _value;
    emit NewOriginFeeDefault(_value);
  }

  function setOriginFee(address _token, uint _value) external onlyOwner {
    _requireContract(_token);
    originFeeToken[_token] = _value;
    emit NewOriginFeeToken(_token, _value);
  }

  function setDepositLimit(address _pair, address _token, uint _value) external onlyOwner {
    _requireContract(_pair);
    _requireContract(_token);
    depositLimit[_pair][_token] = _value;
    emit NewDepositLimit(_pair, _token, _value);
  }

  function setBorrowLimit(address _pair, address _token, uint _value) external onlyOwner {
    _requireContract(_pair);
    _requireContract(_token);
    borrowLimit[_pair][_token] = _value;
    emit NewBorrowLimit(_pair, _token, _value);
  }

  function setMinBorrowUSD(uint _value) external onlyOwner {
    minBorrowUSD = _value;
    emit NewMinBorrowUSD(_value);
  }

  function setColFactor(address _token, uint _value) external onlyOwner {
    require(_value <= MAX_COL_FACTOR, "Controller: _value <= MAX_COL_FACTOR");
    _requireContract(_token);
    colFactor[_token] = _value;
    emit NewColFactor(_token, _value);
  }

  function liqFeeSystem(address _token) public view returns(uint) {
    return liqFeeSystemToken[_token] > 0 ? liqFeeSystemToken[_token] : liqFeeSystemDefault;
  }

  function liqFeeCaller(address _token) public view returns(uint) {
    return liqFeeCallerToken[_token] > 0 ? liqFeeCallerToken[_token] : liqFeeCallerDefault;
  }

  function liqFeesTotal(address _token) external view returns(uint) {
    return liqFeeSystem(_token) + liqFeeCaller(_token);
  }

  function originFee(address _token) external view returns(uint) {
    return originFeeToken[_token] > 0 ? originFeeToken[_token] : originFeeDefault;
  }

  function tokenPrice(address _token) external view returns(uint) {
    return priceOracle.tokenPrice(_token);
  }

  function tokenSupported(address _token) external view returns(bool) {
    return priceOracle.tokenSupported(_token);
  }

  function _requireContract(address _value) internal view {
    require(_value.isContract(), "Controller: must be a contract");
  }
}