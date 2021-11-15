// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./ERC20/IERC20.sol";
import "./ERC20/IERC20Permit.sol";
import "./ERC20/SafeERC20.sol";
import "./interfaces/IERC3156FlashBorrower.sol";
import "./interfaces/IERC3156FlashLender.sol";
import "./interfaces/IRERC20.sol";
import "./interfaces/IRTokenProxy.sol";
import "./interfaces/IRulerConfig.sol";
import "./interfaces/IRulerPair.sol";
import "./interfaces/IOracle.sol";
import "./utils/Clones.sol";
import "./utils/Create2.sol";
import "./utils/Initializable.sol";
import "./utils/Ownable.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/StringHelper.sol";

/**
 * @title Ruler Pair contract
 * @author crypto-pumpkin
 * Ruler Pair: collateral, paired token, expiry, mintRatio
 *  - ! Paired Token cannot be a deflationary token !
 *  - rTokens have same decimals of each paired token
 *  - all Ratios are 1e18
 *  - rTokens have same decimals as Paired Token
 *  - Collateral cannot be deflationary token, nor rebasing token
 */
contract RulerPair is Ownable, IRulerPair, IERC3156FlashLender, ReentrancyGuard {
  using SafeERC20 for IERC20;

  // following ERC3156 https://eips.ethereum.org/EIPS/eip-3156
  bytes32 public constant FLASHLOAN_CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

  IRulerConfig public override rulerConfig;

  address[] public override collaterals;
  mapping(address => bool) private collateralsMap; // necessary to construct the collateral array
  /// @notice collateral => pairedToken => expiry => mintRatio => Pair
  mapping(address => mapping(address => mapping(uint48 => mapping(uint256 => Pair)))) public override pairs;
  mapping(address => Pair[]) private pairList;
  mapping(address => uint256) public override feesMap;

  modifier onlyNotPaused() {
    require(!rulerConfig.paused(), "paused");
    _;
  }

  function initialize(IRulerConfig _config) external initializer {
    require(address(_config) != address(0), "_config cannot be 0");
    rulerConfig = _config;
    initializeOwner();
    initializeReentrancyGuard();
  }

  /// @notice deposit collateral to a Ruler Pair, sender receives rcTokens and rrTokens
  function deposit(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _colAmt
  ) public override onlyNotPaused nonReentrant {
    Pair memory pair = pairs[_col][_paired][_expiry][_mintRatio];
    require(pair.mintRatio != 0, "pair does not exist");
    require(pair.active, "pair inactive");
    require(pair.expiry - rulerConfig.depositPauseWindow() > block.timestamp, "deposit ended");
    if (pair.isBond) {
      require(msg.sender == pair.minter, "not minter");
    }

    // receive collateral
    IERC20 collateral = IERC20(_col);
    uint256 colBalBefore =  collateral.balanceOf(address(this));
    collateral.safeTransferFrom(msg.sender, address(this), _colAmt);
    uint256 received = collateral.balanceOf(address(this)) - colBalBefore;
    require(received > 0, "transfer failed");
    pairs[_col][_paired][_expiry][_mintRatio].colTotal = pair.colTotal + received;
    feesMap[_col] = feesMap[_col] + _colAmt * rulerConfig.depositFeeRate() / 1e18;

    // mint rTokens for reveiced collateral
    uint256 mintAmount = _getRTokenAmtFromColAmt(received, _col, _paired, pair.mintRatio);
    pair.rcToken.mint(msg.sender, mintAmount);
    pair.rrToken.mint(msg.sender, mintAmount);
    emit Deposit(msg.sender, _col, _paired, _expiry, _mintRatio, received);
  }

  function depositWithPermit(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _colAmt,
    Permit calldata _colPermit
  ) external override {
    _permit(_col, _colPermit);
    deposit(_col, _paired, _expiry, _mintRatio, _colAmt);
  }

  /// @notice redeem with rrTokens and rcTokens before expiry only, sender receives collateral, fees charged on collateral
  function redeem(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _rTokenAmt
  ) external override onlyNotPaused nonReentrant {
    Pair memory pair = pairs[_col][_paired][_expiry][_mintRatio];
    require(pair.mintRatio != 0, "pair does not exist");
    require(block.timestamp <= pair.expiry, "expired, col forfeited");
    pair.rrToken.burnByRuler(msg.sender, _rTokenAmt);
    pair.rcToken.burnByRuler(msg.sender, _rTokenAmt);

    // send collateral to sender
    uint256 colAmountToPay = _getColAmtFromRTokenAmt(_rTokenAmt, _col, address(pair.rcToken), pair.mintRatio);
    // once redeemed, it won't be considered as a loan for the pair anymore
    pairs[_col][_paired][_expiry][_mintRatio].colTotal = pair.colTotal - colAmountToPay;
    // accrue fees on payment
    _sendAmtPostFeesOptionalAccrue(IERC20(_col), colAmountToPay, rulerConfig.depositFeeRate(), false /* accrue */);
    emit Redeem(msg.sender, _col, _paired, _expiry, _mintRatio, _rTokenAmt);
  }

  /// @notice repay with rrTokens and paired token amount, sender receives collateral, no fees charged on collateral
  function repay(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _rrTokenAmt
  ) public override onlyNotPaused nonReentrant {
    Pair memory pair = pairs[_col][_paired][_expiry][_mintRatio];
    require(pair.mintRatio != 0, "pair does not exist");
    require(block.timestamp <= pair.expiry, "expired, col forfeited");
    pair.rrToken.burnByRuler(msg.sender, _rrTokenAmt);

    // receive paired tokens from sender, deflationary token is not allowed
    IERC20 pairedToken = IERC20(_paired);
    uint256 pairedBalBefore =  pairedToken.balanceOf(address(this));
    pairedToken.safeTransferFrom(msg.sender, address(this), _rrTokenAmt);
    require(pairedToken.balanceOf(address(this)) - pairedBalBefore >= _rrTokenAmt, "transfer paired failed");
    feesMap[_paired] = feesMap[_paired] + _rrTokenAmt * rulerConfig.collectFeeRate() / 1e18;

    // send collateral back to sender
    uint256 colAmountToPay = _getColAmtFromRTokenAmt(_rrTokenAmt, _col, address(pair.rrToken), pair.mintRatio);
    _sendAmtPostFeesOptionalAccrue(IERC20(_col), colAmountToPay, rulerConfig.depositFeeRate(), false /* accrue */);
    emit Repay(msg.sender, _col, _paired, _expiry, _mintRatio, _rrTokenAmt);
  }

  function repayWithPermit(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _rrTokenAmt,
    Permit calldata _pairedPermit
  ) external override {
    _permit(_paired, _pairedPermit);
    repay(_col, _paired, _expiry, _mintRatio, _rrTokenAmt);
  }

  /// @notice sender collect paired tokens by returning same amount of rcTokens to Ruler
  function collect(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _rcTokenAmt
  ) external override onlyNotPaused nonReentrant {
    Pair memory pair = pairs[_col][_paired][_expiry][_mintRatio];
    require(pair.mintRatio != 0, "pair does not exist");
    require(block.timestamp > pair.expiry, "not ready");
    pair.rcToken.burnByRuler(msg.sender, _rcTokenAmt);

    IERC20 pairedToken = IERC20(_paired);
    uint256 defaultedLoanAmt = pair.rrToken.totalSupply();
    uint256 collectFeeRate = rulerConfig.collectFeeRate();
    if (defaultedLoanAmt == 0) { // no default, send paired Token to sender
      // no fees accrued as it is accrued on Borrower payment
      _sendAmtPostFeesOptionalAccrue(pairedToken, _rcTokenAmt, collectFeeRate, false /* accrue */);
    } else {
      // rcTokens eligible to collect at expiry (converted from total collateral received, redeemed collateral not counted) == total loan amount at the moment of expiry
      uint256 rcTokensEligibleAtExpiry = _getRTokenAmtFromColAmt(pair.colTotal, _col, _paired, pair.mintRatio);

      // paired token amount to pay = rcToken amount * (1 - default ratio)
      uint256 pairedTokenAmtToCollect = _rcTokenAmt * (rcTokensEligibleAtExpiry - defaultedLoanAmt) / rcTokensEligibleAtExpiry;
      // no fees accrued as it is accrued on Borrower payment
      _sendAmtPostFeesOptionalAccrue(pairedToken, pairedTokenAmtToCollect, collectFeeRate, false /* accrue */);

      // default collateral amount to pay = converted collateral amount (from rcTokenAmt) * default ratio
      uint256 colAmount = _getColAmtFromRTokenAmt(_rcTokenAmt, _col, address(pair.rcToken), pair.mintRatio);
      uint256 colAmountToCollect = colAmount * defaultedLoanAmt / rcTokensEligibleAtExpiry;
      // accrue fees on defaulted collateral since it was never accrued
      _sendAmtPostFeesOptionalAccrue(IERC20(_col), colAmountToCollect, collectFeeRate, true /* accrue */);
    }
    emit Collect(msg.sender, _col, _paired,_expiry,  _mintRatio, _rcTokenAmt);
  }

  function collectFees(IERC20[] calldata _tokens) external override onlyOwner {
    for (uint256 i = 0; i < _tokens.length; i++) {
      IERC20 token = _tokens[i];
      uint256 fee = feesMap[address(token)];
      feesMap[address(token)] = 0;
      uint256 bal = token.balanceOf(address(this));
      if (bal < fee) {
        token.safeTransfer(rulerConfig.feeReceiver(), bal);
      } else {
        token.safeTransfer(rulerConfig.feeReceiver(), fee);
      }
    }
  }

  /**
   * @notice permissionless add a ruler pair, collateral MUST be standard ERC20, no rebase or deflationary tokens
   * @param _col, collateral token for the pair
   * @param _paired, paired token which is also the repayment token borrower must pay with
   * @param _expiry, standard Solidity timestamp in seconds, must be in the future
   * @param _mintRatio, the amount to mint for each collateral unit in 1e18
   * @param _mintRatioString, the string representation of the mintRatio. E.g. WETH has a 1000000000000000000000 _mintRatio, and 1000 _mintRatioString; NEAR has a 1100000000000000000 _mintRatio and 1.1 _mintRatioString
   */
  function createPair(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    string calldata _mintRatioString
  ) external override {
    _createPair(false, _col, _paired, address(0), _expiry, _mintRatio, _mintRatioString);
  }

  /**
   * @notice permissionless add a ruler pair, collateral MUST be standard ERC20, no rebase or deflationary tokens
   * @param _col, collateral token for the pair
   * @param _paired, paired token which is also the repayment token borrower must pay with
   * @param _minter, the address that can deposit and mint rc and rr tokens
   * @param _expiry, standard Solidity timestamp in seconds, must be in the future
   * @param _mintRatio, the amount to mint for each collateral unit in 1e18
   * @param _mintRatioString, the string representation of the mintRatio. E.g. WETH has a 1000000000000000000000 _mintRatio, and 1000 _mintRatioString; NEAR has a 1100000000000000000 _mintRatio and 1.1 _mintRatioString
   */
  function createBond(
    address _col,
    address _paired,
    address _minter,
    uint48 _expiry,
    uint256 _mintRatio,
    string calldata _mintRatioString
  ) external override {
    require(_minter != address(0), "minter is 0");
    _createPair(true, _col, _paired, _minter, _expiry, _mintRatio, _mintRatioString);
  }

  /**
   * @notice allow flash loan borrow allowed tokens up to all core contracts' holdings
   * _receiver will received the requested amount, and need to payback the loan amount + fees
   * _receiver must implement IERC3156FlashBorrower
   * no deflationary tokens
   */
  function flashLoan(
    IERC3156FlashBorrower _receiver,
    address _token,
    uint256 _amount,
    bytes calldata _data
  ) public override onlyNotPaused returns (bool) {
    IERC20 token = IERC20(_token);
    uint256 tokenBalBefore = token.balanceOf(address(this));
    require(tokenBalBefore > 0, "RulerPair: token not supported");
    token.safeTransfer(address(_receiver), _amount);
    uint256 fees = flashFee(_token, _amount);
    require(
      _receiver.onFlashLoan(msg.sender, _token, _amount, fees, _data) == FLASHLOAN_CALLBACK_SUCCESS,
      "IERC3156: Callback failed"
    );

    // receive loans and fees
    token.safeTransferFrom(address(_receiver), address(this), _amount + fees);
    require(token.balanceOf(address(this)) - tokenBalBefore >= fees, "not enough fees");
    feesMap[_token] = feesMap[_token] + fees;
    emit FlashLoan(_token, address(_receiver), _amount);
    return true;
  }

  function setPairActive(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    bool _active
  ) external override onlyOwner {
    pairs[_col][_paired][_expiry][_mintRatio].active = _active;
  }

  /// @notice only owner or current minter can set minter
  function setMinter(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    address _newMinter
  ) external override {
    Pair memory pair = pairs[_col][_paired][_expiry][_mintRatio];
    require(pair.isBond, "method not supported");
    require(msg.sender == owner() || msg.sender == pair.minter, "not authorized");
    emit MinterUpdated(_col, _paired, _expiry, _mintRatio, msg.sender, _newMinter);
    pairs[_col][_paired][_expiry][_mintRatio].minter = _newMinter;
  }

  function getCollateralsLength() external view override returns (uint256) {
    return collaterals.length;
  }

  /// @notice pass uint256 max for endIndex to get all collaterals, otherwise returns [_startIndex, _endIndex]
  function getCollaterals(uint256 _startIndex, uint256 _endIndex) external view override returns (address[] memory) {
    _endIndex = _endIndex >= collaterals.length ? (collaterals.length - 1) : _endIndex;
    address[] memory cols = new address[](_endIndex - _startIndex + 1);
    for (uint256 i = _startIndex; i <= _endIndex; i++) {
      cols[i - _startIndex] = (collaterals[i]);
    }
    return cols;
  }

  function getPairListLength(address _col) external view override returns (uint256) {
    return pairList[_col].length;
  }

  /// @notice pass uint256 max for endIndex to get all pairs for col, otherwise returns [_startIndex, _endIndex]
  function getPairList(address _col, uint256 _startIndex, uint256 _endIndex) external view override returns (Pair[] memory) {
    Pair[] memory colPairList = pairList[_col];
    _endIndex = _endIndex >= colPairList.length ? (colPairList.length - 1) : _endIndex;
    Pair[] memory _pairs = new Pair[](_endIndex - _startIndex + 1);
    for (uint256 i = _startIndex; i <= _endIndex; i++) {
      Pair memory pair = colPairList[i];
      _pairs[i - _startIndex] = pairs[_col][pair.pairedToken][pair.expiry][pair.mintRatio];
    }
    return _pairs;
  }

  /// @notice amount that is eligible to collect
  function viewCollectible(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _rcTokenAmt
  ) external view override returns (uint256 colAmtToCollect, uint256 pairedAmtToCollect) {
    Pair memory pair = pairs[_col][_paired][_expiry][_mintRatio];
    if (pair.mintRatio == 0 || block.timestamp < pair.expiry) return (colAmtToCollect, pairedAmtToCollect);

    uint256 defaultedLoanAmt = pair.rrToken.totalSupply();
    if (defaultedLoanAmt == 0) { // no default, transfer paired Token
      pairedAmtToCollect =  _rcTokenAmt;
    } else {
      // rcTokens eligible to collect at expiry (converted from total collateral received, redeemed collateral not counted) == total loan amount at the moment of expiry
      uint256 rcTokensEligibleAtExpiry = _getRTokenAmtFromColAmt(pair.colTotal, _col, _paired, pair.mintRatio);

      // paired token amount to pay = rcToken amount * (1 - default ratio)
      pairedAmtToCollect = _rcTokenAmt * (rcTokensEligibleAtExpiry - defaultedLoanAmt) * (1e18 - rulerConfig.collectFeeRate()) / 1e18 / rcTokensEligibleAtExpiry;

      // default collateral amount to pay = converted collateral amount (from rcTokenAmt) * default ratio
      uint256 colAmount = _getColAmtFromRTokenAmt(_rcTokenAmt, _col, address(pair.rcToken), pair.mintRatio);
      colAmtToCollect = colAmount * defaultedLoanAmt * (1e18 - rulerConfig.collectFeeRate()) / 1e18 / rcTokensEligibleAtExpiry;
    }
  }

  function maxFlashLoan(address _token) external view override returns (uint256) {
    return IERC20(_token).balanceOf(address(this));
  }

  /// @notice returns the amount of fees charges by for the loan amount. Same feeRate for all tokens
  function flashFee(address, uint256 _amount) public view override returns (uint256 _fees) {
    _fees = _amount * rulerConfig.flashLoanRate() / 1e18;
  }

  /// @notice version of current Ruler Pair hardcoded
  function version() external pure override returns (string memory) {
    return '1.0.0';
  }

  function _sendAmtPostFeesOptionalAccrue(IERC20 _token, uint256 _amount, uint256 _feeRate, bool _accrue) private {
    uint256 fees = _amount * _feeRate / 1e18;
    _token.safeTransfer(msg.sender, _amount - fees);
    if (_accrue) {
      feesMap[address(_token)] = feesMap[address(_token)] + fees;
    }
  }

  function _createPair(
    bool _isBond,
    address _col,
    address _paired,
    address _minter,
    uint48 _expiry,
    uint256 _mintRatio,
    string calldata _mintRatioString
  ) private {
    require(pairs[_col][_paired][_expiry][_mintRatio].mintRatio == 0, "pair exists");
    require(_mintRatio > 0, "_mintRatio <= 0");
    require(_expiry > block.timestamp, "expiry in the past");
    if (!collateralsMap[_col]) {
      collateralsMap[_col] = true;
      collaterals.push(_col);
    }

    string memory expiryStr = StringHelper.uintToTimeString(_expiry);

    Pair memory pair = Pair({
      isBond: _isBond,
      minter: _minter,
      active: true,
      mintRatio: _mintRatio,
      expiry: _expiry,
      pairedToken: _paired,
      rcToken: IRERC20(_createRToken(_col, _paired, _expiry, expiryStr, _mintRatioString, "RC_")),
      rrToken: IRERC20(_createRToken(_col, _paired, _expiry, expiryStr, _mintRatioString, "RR_")),
      colTotal: 0
    });
    pairs[_col][_paired][_expiry][_mintRatio] = pair;
    pairList[_col].push(pair);
    emit PairAdded(_col, _paired, _expiry, _mintRatio);
  }

  function _createRToken(
    address _col,
    address _paired,
    uint256 _expiry,
    string memory _expiryStr,
    string calldata _mintRatioStr,
    string memory _prefix
  ) private returns (address proxyAddr) {
    uint8 decimals = uint8(IERC20(_paired).decimals());
    require(decimals > 0, "RulerPair: paired decimals is 0");

    string memory symbol = string(abi.encodePacked(
      _prefix,
      IERC20(_col).symbol(), "_",
      _mintRatioStr, "_",
      IERC20(_paired).symbol(), "_",
      _expiryStr
    ));

    bytes32 salt = keccak256(abi.encodePacked(_col, _paired, _expiry, _mintRatioStr, _prefix));
    proxyAddr = Clones.cloneDeterministic(rulerConfig.rERC20Impl(), salt);
    IRTokenProxy(proxyAddr).initialize("Ruler Protocol rToken", symbol, decimals);
    emit RTokenCreated(proxyAddr);
  }

  function _getRTokenAmtFromColAmt(uint256 _colAmt, address _col, address _paired, uint256 _mintRatio) private view returns (uint256) {
    uint8 colDecimals = IERC20(_col).decimals();
    // pairedDecimals is the same as rToken decimals
    uint8 pairedDecimals = IERC20(_paired).decimals();
    return _colAmt * _mintRatio * (10 ** pairedDecimals) / (10 ** colDecimals) / 1e18;
  }

  function _getColAmtFromRTokenAmt(uint256 _rTokenAmt, address _col, address _rToken, uint256 _mintRatio) private view returns (uint256) {
    uint8 colDecimals = IERC20(_col).decimals();
    // pairedDecimals == rToken decimals
    uint8 rTokenDecimals = IERC20(_rToken).decimals();
    return _rTokenAmt * (10 ** colDecimals) * 1e18 / _mintRatio / (10 ** rTokenDecimals);
  }

  function _permit(address _token, Permit calldata permit) private {
    IERC20Permit(_token).permit(
      permit.owner,
      permit.spender,
      permit.amount,
      permit.deadline,
      permit.v,
      permit.r,
      permit.s
    );
  }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IERC3156FlashBorrower {

  /**
    * @dev Receive a flash loan.
    * @param initiator The initiator of the loan.
    * @param token The loan currency.
    * @param amount The amount of tokens lent.
    * @param fee The additional amount of tokens to repay.
    * @param data Arbitrary data structure, intended to contain user-defined parameters.
    * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
    */
  function onFlashLoan(
      address initiator,
      address token,
      uint256 amount,
      uint256 fee,
      bytes calldata data
  ) external returns (bytes32);
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
  /**
    * @dev The amount of currency available to be lent.
    * @param token The loan currency.
    * @return The amount of `token` that can be borrowed.
    */
  function maxFlashLoan(
      address token
  ) external view returns (uint256);

  /**
    * @dev The fee to be charged for a given loan.
    * @param token The loan currency.
    * @param amount The amount of tokens lent.
    * @return The amount of `token` to be charged for the loan, on top of the returned principal.
    */
  function flashFee(
      address token,
      uint256 amount
  ) external view returns (uint256);

  /**
    * @dev Initiate a flash loan.
    * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
    * @param token The loan currency.
    * @param amount The amount of tokens lent.
    * @param data Arbitrary data structure, intended to contain user-defined parameters.
    */
  function flashLoan(
      IERC3156FlashBorrower receiver,
      address token,
      uint256 amount,
      bytes calldata data
  ) external returns (bool);
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "../ERC20/IERC20.sol";

/**
 * @title RERC20 contract interface, implements {IERC20}. See {RERC20}.
 * @author crypto-pumpkin
 */
interface IRERC20 is IERC20 {
    /// @notice access restriction - owner (R)
    function mint(address _account, uint256 _amount) external returns (bool);
    function burnByRuler(address _account, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @title Interface of the RTokens Proxy.
 */
interface IRTokenProxy {
  function initialize(string calldata _name, string calldata _symbol, uint8 _decimals) external;
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @title IRulerConfig contract interface. See {RulerConfig}.
 * @author crypto-pumpkin
 */
interface IRulerConfig {
  event AddressUpdated(string _type, address old, address _new);
  event PausedStatusUpdated(bool old, bool _new);
  event RERC20ImplUpdated(address rERC20Impl, address newImpl);
  event FlashLoanRateUpdated(uint256 old, uint256 _new);
  event DepositPauseWindow(uint256 old, uint256 _new);
  event DepositFeeRateUpdated(uint256 old, uint256 _new);
  event CollectFeeRateUpdated(uint256 old, uint256 _new);

  // state vars
  function flashLoanRate() external view returns (uint256);
  function paused() external view returns (bool);
  function responder() external view returns (address);
  function feeReceiver() external view returns (address);
  function rERC20Impl() external view returns (address);
  function depositPauseWindow() external view returns (uint256);
  function depositFeeRate() external view returns (uint256);
  function collectFeeRate() external view returns (uint256);

  // access restriction - owner (dev) & responder
  function setPaused(bool _paused) external;

  // access restriction - owner (dev)
  function setFeeReceiver(address _addr) external;
  function setResponder(address _addr) external;
  function setRERC20Impl(address _addr) external;
  function setFlashLoanRate(uint256 _newRate) external;
  function setDepositPauseWindow(uint256 _newWindow) external;
  function setDepositFeeRate(uint256 _newFeeRate) external;
  function setCollectFeeRate(uint256 _newFeeRate) external;
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./IRERC20.sol";
import "./IRulerConfig.sol";
import "./IOracle.sol";

/**
 * @title IRulerPair contract interface. See {RulerPair}.
 * @author crypto-pumpkin
 */
interface IRulerPair {
  event RTokenCreated(address);
  event CollateralUpdated(address col, uint256 old, uint256 _new);
  event PairAdded(address indexed collateral, address indexed paired, uint48 expiry, uint256 mintRatio);
  event MarketMakeDeposit(address indexed user, address indexed collateral, address indexed paired, uint48 expiry, uint256 mintRatio, uint256 amount);
  event Deposit(address indexed user, address indexed collateral, address indexed paired, uint48 expiry, uint256 mintRatio, uint256 amount);
  event Repay(address indexed user, address indexed collateral, address indexed paired, uint48 expiry, uint256 mintRatio, uint256 amount);
  event Redeem(address indexed user, address indexed collateral, address indexed paired, uint48 expiry, uint256 mintRatio, uint256 amount);
  event Collect(address indexed user, address indexed collateral, address indexed paired, uint48 expiry, uint256 mintRatio, uint256 amount);
  event FlashLoan(address _token, address _borrower, uint256 _amount);
  event MinterUpdated(address indexed collateral, address indexed paired, uint48 expiry, uint256 mintRatio, address _setter, address _newMinter);

  struct Pair {
    bool active; // if false, mint is disabled, only Ruler team can update
    bool isBond; // if true, only minter can mint
    uint48 expiry;
    address pairedToken;
    address minter;
    IRERC20 rcToken; // ruler capitol token, e.g. RC_Dai_wBTC_2_2021
    IRERC20 rrToken; // ruler repayment token, e.g. RR_Dai_wBTC_2_2021
    uint256 mintRatio; // 1e18, price of collateral / collateralization ratio
    uint256 colTotal;
  }

  struct Permit {
    address owner;
    address spender;
    uint256 amount;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  // state vars
  function version() external pure returns (string memory);
  function rulerConfig() external view returns (IRulerConfig);
  function collaterals(uint256 _index) external view returns (address);
  function feesMap(address _token) external view returns (uint256);
  function pairs(address _col, address _paired, uint48 _expiry, uint256 _mintRatio) external view returns (
    bool active,
    bool isBond,
    uint48 expiry, 
    address pairedToken, 
    address minter,
    IRERC20 rcToken, 
    IRERC20 rrToken, 
    uint256 mintRatio, 
    uint256 colTotal
  );

  // extra view
  function getCollateralsLength() external view returns (uint256);
  function getCollaterals(uint256 _startIndex, uint256 _endIndex) external view returns (address[] memory);
  function getPairListLength(address _col) external view returns (uint256);
  function getPairList(address _col, uint256 _startIndex, uint256 _endIndex) external view returns (Pair[] memory);
  function viewCollectible(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _rcTokenAmt
  ) external view returns (uint256 colAmtToCollect, uint256 pairedAmtToCollect);

  function deposit(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _colAmt
  ) external;
  function depositWithPermit(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _colAmt,
    Permit calldata _colPermit
  ) external;
  function redeem(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _rTokenAmt
  ) external;
  function repay(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _rrTokenAmt
  ) external;
  function repayWithPermit(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _rrTokenAmt,
    Permit calldata _pairedPermit
  ) external;
  function collect(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _rcTokenAmt
  ) external;
  function createPair(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    string calldata _mintRatioString
  ) external;
  function createBond(
    address _col,
    address _paired,
    address _minter,
    uint48 _expiry,
    uint256 _mintRatio,
    string calldata _mintRatioString
  ) external;

  // access restriction - owner or current minter
  function setMinter(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    address _newMinter
  ) external;

  // access restriction - owner (dev)
  function collectFees(IERC20[] calldata _tokens) external;

  // access restriction - owner (dev)
  function setPairActive(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    bool _active
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
    function getPriceUSD(address _asset) external view returns (uint256 price);
    function getPricesUSD(address[] calldata _assets) external view returns (uint256[] memory prices);
    
    // admin functions
    function updateFeedETH(address _asset, address _feed) external;
    function updateFeedUSD(address _asset, address _feed) external;
    function setSushiKeeperOracle(address _sushiOracle) external;
    function setUniKeeperOracle(address _uniOracle) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address payable) {
        address payable addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
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
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 * @author crypto-pumpkin
 *
 * By initialization, the owner account will be the one that called initializeOwner. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Ruler: Initializes the contract setting the deployer as the initial owner.
     */
    function initializeOwner() internal initializer {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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

    function initializeReentrancyGuard () internal {
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

import "../libs/BokkyPooBahsDateTimeLibrary.sol";
/**
 * @title Ruler contract interface. See {Ruler}.
 * @author crypto-pumpkin
 * Help convert other types to string
 */
library StringHelper {
  function stringToBytes32(string calldata str) internal pure returns (bytes32 result) {
    bytes memory strBytes = abi.encodePacked(str);
    assembly {
      result := mload(add(strBytes, 32))
    }
  }

  function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
    uint8 i = 0;
    while(i < 32 && _bytes32[i] != 0) {
        i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
        bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }

  // TODO optimized this func, changes were made for solidity 0.8.0
  function uintToString(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return '0';
    } else {
      bytes32 ret;
      while (_i > 0) {
        ret = bytes32(uint(ret) / (2 ** 8));
        ret |= bytes32(((_i % 10) + 48) * 2 ** (8 * 31));
        _i /= 10;
      }
      _uintAsString = bytes32ToString(ret);
    }
  }

  function uintToTimeString(uint timestamp) internal pure returns(string memory){
      (uint year, uint month, uint day) = BokkyPooBahsDateTimeLibrary.timestampToDate(timestamp);
      string memory date = string(abi.encodePacked(
          uintToString(year),
          "_",
          uintToString(month), 
          "_",
          uintToString(day)
      ));
      return date;
  }
}

// SPDX-License-Identifier: MIT

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

/**
 *Submitted for verification at Etherscan.io on 2018-09-02
*/

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.00
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        uint year;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        uint year;
        uint month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

