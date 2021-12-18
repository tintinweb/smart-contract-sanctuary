// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IInterestRateModel.sol";
import "IPriceOracle.sol";
import "ILendingController.sol";
import "SafeOwnable.sol";
import "AddressLibrary.sol";

contract LendingController is ILendingController, SafeOwnable {

  using AddressLibrary for address;

  uint private constant MAX_COL_FACTOR = 99e18;
  uint private constant MAX_LIQ_FEES   = 50e18;

  IPriceOracle public priceOracle;

  address public override interestRateModel;

  bool public override depositsEnabled;
  bool public override borrowingEnabled;
  uint public liqFeeCallerDefault;
  uint public liqFeeSystemDefault;
  uint public override uniMinOutputPct; // 99e18 = 99%

  mapping(address => bool) public isGuardian;
  mapping(address => mapping(address => uint)) public override depositLimit;
  mapping(address => mapping(address => uint)) public override borrowLimit;
  mapping(address => uint) public liqFeeCallerToken; // 1e18  = 1%
  mapping(address => uint) public liqFeeSystemToken; // 1e18  = 1%
  mapping(address => uint) public override colFactor; // 99e18 = 99%
  mapping(address => uint) public override minBorrow;

  event NewInterestRateModel(address indexed interestRateModel);
  event NewPriceOracle(address indexed priceOracle);
  event NewColFactor(address indexed token, uint value);
  event NewDepositLimit(address indexed pair, address indexed token, uint value);
  event NewBorrowLimit(address indexed pair, address indexed token, uint value);
  event AllowGuardian(address indexed guardian, bool value);
  event DepositsEnabled(bool value);
  event BorrowingEnabled(bool value);
  event NewLiqParamsToken(address indexed token, uint liqFeeSystem, uint liqFeeCaller);
  event NewLiqParamsDefault(uint liqFeeSystem, uint liqFeeCaller);
  event NewUniMinOutputPct(uint value);
  event NewMinBorrow(address indexed token, uint value);

  modifier onlyGuardian() {
    require(isGuardian[msg.sender], "LendingController: caller is not a guardian");
    _;
  }

  constructor(
    address _interestRateModel,
    uint _liqFeeSystemDefault,
    uint _liqFeeCallerDefault,
    uint _uniMinOutputPct
  ) {
    _requireContract(_interestRateModel);
    require(_liqFeeSystemDefault + _liqFeeCallerDefault <= MAX_LIQ_FEES, "LendingController: fees too high");

    interestRateModel   = _interestRateModel;
    liqFeeSystemDefault = _liqFeeSystemDefault;
    liqFeeCallerDefault = _liqFeeCallerDefault;
    uniMinOutputPct     = _uniMinOutputPct;
    depositsEnabled     = true;
    borrowingEnabled    = true;
  }

  function setLiqParamsToken(
    address _token,
    uint    _liqFeeSystem,
    uint    _liqFeeCaller
  ) external onlyOwner {
    require(_liqFeeCaller + _liqFeeSystem <= MAX_LIQ_FEES, "LendingController: fees too high");
    _requireContract(_token);

    liqFeeSystemToken[_token] = _liqFeeSystem;
    liqFeeCallerToken[_token] = _liqFeeCaller;

    emit NewLiqParamsToken(_token, _liqFeeSystem, _liqFeeCaller);
  }

  function setLiqParamsDefault(
    uint    _liqFeeSystem,
    uint    _liqFeeCaller
  ) external onlyOwner {
    require(_liqFeeCaller + _liqFeeSystem <= MAX_LIQ_FEES, "LendingController: fees too high");

    liqFeeSystemDefault = _liqFeeSystem;
    liqFeeCallerDefault = _liqFeeCaller;

    emit NewLiqParamsDefault(_liqFeeSystem, _liqFeeCaller);
  }

  function setInterestRateModel(address _value) external onlyOwner {
    _requireContract(_value);
    interestRateModel = _value;
    emit NewInterestRateModel(_value);
  }

  function setPriceOracle(address _value) external onlyOwner {
    _requireContract(_value);
    priceOracle = IPriceOracle(_value);
    emit NewPriceOracle(address(_value));
  }

  function setMinBorrow(address _token, uint _value) external onlyOwner {
    _requireContract(_token);
    minBorrow[_token] = _value;
    emit NewMinBorrow(_token, _value);
  }

  // Allow immediate emergency shutdown of deposits by the guardian.
  function disableDeposits() external onlyGuardian {
    depositsEnabled = false;
    emit DepositsEnabled(false);
  }

  // Re-enabling deposits can only be done by the owner
  function enableDeposits() external onlyOwner {
    depositsEnabled = true;
    emit DepositsEnabled(true);
  }

  function disableBorrowing() external onlyGuardian {
    borrowingEnabled = false;
    emit BorrowingEnabled(false);
  }

  function enableBorrowing() external onlyOwner {
    borrowingEnabled = true;
    emit BorrowingEnabled(true);
  }

  function setDepositLimit(address _pair, address _token, uint _value) external onlyOwner {
    _requireContract(_pair);
    _requireContract(_token);
    depositLimit[_pair][_token] = _value;
    emit NewDepositLimit(_pair, _token, _value);
  }

  function allowGuardian(address _guardian, bool _value) external onlyOwner {
    isGuardian[_guardian] = _value;
    emit AllowGuardian(_guardian, _value);
  }

  function setBorrowLimit(address _pair, address _token, uint _value) external onlyOwner {
    _requireContract(_pair);
    _requireContract(_token);
    borrowLimit[_pair][_token] = _value;
    emit NewBorrowLimit(_pair, _token, _value);
  }

  function setUniMinOutputPct(uint _value) external onlyOwner {
    uniMinOutputPct = _value;
    emit NewUniMinOutputPct(_value);
  }

  function setColFactor(address _token, uint _value) external onlyOwner {
    require(_value <= MAX_COL_FACTOR, "LendingController: _value <= MAX_COL_FACTOR");
    _requireContract(_token);
    colFactor[_token] = _value;
    emit NewColFactor(_token, _value);
  }

  function liqFeeSystem(address _token) public view override returns(uint) {
    return liqFeeSystemToken[_token] > 0 ? liqFeeSystemToken[_token] : liqFeeSystemDefault;
  }

  function liqFeeCaller(address _token) public view override returns(uint) {
    return liqFeeCallerToken[_token] > 0 ? liqFeeCallerToken[_token] : liqFeeCallerDefault;
  }

  function liqFeesTotal(address _token) external view returns(uint) {
    return liqFeeSystem(_token) + liqFeeCaller(_token);
  }

  function tokenPrice(address _token) external view override returns(uint) {
    return priceOracle.tokenPrice(_token);
  }

  function tokenPrices(address _tokenA, address _tokenB) external view override returns (uint, uint) {
    return (
      priceOracle.tokenPrice(_tokenA),
      priceOracle.tokenPrice(_tokenB)
    );
  }

  function tokenSupported(address _token) external view override returns(bool) {
    return priceOracle.tokenSupported(_token);
  }

  function _requireContract(address _value) internal view {
    require(_value.isContract(), "LendingController: must be a contract");
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IInterestRateModel {
  function lpRate(address _pair, address _token) external view returns(uint);
  function interestRatePerBlock(address _pair, address _token, uint _totalSupply, uint _totalDebt) external view returns(uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IPriceOracle {

  function tokenPrice(address _token) external view returns(uint);
  function tokenSupported(address _token) external view returns(bool);
  function convertTokenValues(address _fromToken, address _toToken, uint _amount) external view returns(uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IOwnable.sol";

interface ILendingController is IOwnable {
  function interestRateModel() external view returns(address);
  function liqFeeSystem(address _token) external view returns(uint);
  function liqFeeCaller(address _token) external view returns(uint);
  function uniMinOutputPct() external view returns(uint);
  function colFactor(address _token) external view returns(uint);
  function depositLimit(address _lendingPair, address _token) external view returns(uint);
  function borrowLimit(address _lendingPair, address _token) external view returns(uint);
  function depositsEnabled() external view returns(bool);
  function borrowingEnabled() external view returns(bool);
  function tokenPrice(address _token) external view returns(uint);
  function minBorrow(address _token) external view returns(uint);
  function tokenPrices(address _tokenA, address _tokenB) external view returns (uint, uint);
  function tokenSupported(address _token) external view returns(bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IOwnable {
  function owner() external view returns(address);
  function transferOwnership(address _newOwner) external;
  function acceptOwnership() external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IOwnable.sol";

contract SafeOwnable is IOwnable {

  uint public constant RENOUNCE_TIMEOUT = 12 hours;

  address public override owner;
  address public pendingOwner;
  uint public renouncedAt;

  event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), msg.sender);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external override onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferInitiated(owner, _newOwner);
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external override {
    require(msg.sender == pendingOwner, "Ownable: caller is not pending owner");
    emit OwnershipTransferConfirmed(msg.sender, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }

  function initiateRenounceOwnership() external onlyOwner {
    require(renouncedAt == 0, "Ownable: already initiated");
    renouncedAt = block.timestamp;
  }

  function acceptRenounceOwnership() external onlyOwner {
    require(renouncedAt > 0, "Ownable: not initiated");
    require(block.timestamp - renouncedAt > RENOUNCE_TIMEOUT, "Ownable: too early");
    owner = address(0);
    pendingOwner = address(0);
    renouncedAt = 0;
  }

  function cancelRenounceOwnership() external onlyOwner {
    require(renouncedAt > 0, "Ownable: not initiated");
    renouncedAt = 0;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library AddressLibrary {
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