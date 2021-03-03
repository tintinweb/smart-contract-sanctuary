// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./ERC20/IERC20.sol";
import "./ERC20/IERC20Permit.sol";
import "./ERC20/SafeERC20.sol";
import "./interfaces/IRERC20.sol";
import "./interfaces/IRulerCore.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IRulerZap.sol";
import "./utils/Ownable.sol";

/**
 * @title Ruler Protocol Zap
 * @author alan
 * Main logic is in _depositAndAddLiquidity & _depositAndSwapToPaired
 */
contract RulerZap is Ownable, IRulerZap {
    using SafeERC20 for IERC20;
    IRulerCore public override core;
    IRouter public override router;

    constructor (IRulerCore _core, IRouter _router) {
        require(address(_core) != address(0), "RulerZap: _core is 0");
        require(address(_router) != address(0), "RulerZap: _router is 0");
        core = _core;
        router = _router;
        initializeOwner();
    }

    /**
    * @notice Deposit collateral `_col` to receive paired token `_paired` and rrTokens
    *  - deposits collateral to receive rcTokens and rrTokens
    *  - rcTokens are swapped into paired token through router
    *  - paired token and rrTokens are sent to sender
    */
    function depositAndSwapToPaired(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt,
        uint256 _minPairedOut,
        address[] calldata _path,
        uint256 _deadline
    ) external override {
        _depositAndSwapToPaired(
            _col, 
            _paired, 
            _expiry, 
            _mintRatio, 
            _colAmt, 
            _minPairedOut, 
            _path, 
            _deadline
        );
    }

    function depositWithPermitAndSwapToPaired(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt,
        uint256 _minPairedOut,
        address[] calldata _path,
        uint256 _deadline,
        Permit calldata _colPermit
    ) external override {
        _permit(IERC20Permit(_col), _colPermit);
        _depositAndSwapToPaired(
            _col, 
            _paired, 
            _expiry, 
            _mintRatio, 
            _colAmt, 
            _minPairedOut, 
            _path, 
            _deadline
        );
    }

    /**
    * @notice Deposit collateral `_col` to receive LP tokens and rrTokens
    *  - deposits collateral to receive rcTokens and rrTokens
    *  - transfers paired token from sender
    *  - rcTokens and `_paired` tokens are added as liquidity to receive LP tokens
    *  - LP tokens and rrTokens are sent to sender
    */
    function depositAndAddLiquidity(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt,
        uint256 _rcTokenDepositAmt,
        uint256 _pairedDepositAmt,
        uint256 _rcTokenDepositMin,
        uint256 _pairedDepositMin,
        uint256 _deadline
    ) external override {
        _depositAndAddLiquidity(
            _col, 
            _paired, 
            _expiry, 
            _mintRatio, 
            _colAmt, 
            _rcTokenDepositAmt, 
            _pairedDepositAmt, 
            _rcTokenDepositMin, 
            _pairedDepositMin,
            _deadline
        );
    }

    function depositWithColPermitAndAddLiquidity(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt,
        uint256 _rcTokenDepositAmt,
        uint256 _pairedDepositAmt,
        uint256 _rcTokenDepositMin,
        uint256 _pairedDepositMin,
        uint256 _deadline,
        Permit calldata _colPermit
    ) external override {
        _permit(IERC20Permit(_col), _colPermit);
        _depositAndAddLiquidity(
            _col, 
            _paired, 
            _expiry, 
            _mintRatio, 
            _colAmt, 
            _rcTokenDepositAmt, 
            _pairedDepositAmt, 
            _rcTokenDepositMin, 
            _pairedDepositMin,
            _deadline
        );
    }

    function depositWithPairedPermitAndAddLiquidity(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt,
        uint256 _rcTokenDepositAmt,
        uint256 _pairedDepositAmt,
        uint256 _rcTokenDepositMin,
        uint256 _pairedDepositMin,
        uint256 _deadline,
        Permit calldata _pairedPermit
    ) external override {
        _permit(IERC20Permit(_paired), _pairedPermit);
        _depositAndAddLiquidity(
            _col, 
            _paired, 
            _expiry, 
            _mintRatio, 
            _colAmt, 
            _rcTokenDepositAmt, 
            _pairedDepositAmt, 
            _rcTokenDepositMin, 
            _pairedDepositMin,
            _deadline
        );
    }

    function depositWithBothPermitsAndAddLiquidity(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt,
        uint256 _rcTokenDepositAmt,
        uint256 _pairedDepositAmt,
        uint256 _rcTokenDepositMin,
        uint256 _pairedDepositMin,
        uint256 _deadline,
        Permit calldata _colPermit,
        Permit calldata _pairedPermit
    ) external override {
        _permit(IERC20Permit(_col), _colPermit);
        _permit(IERC20Permit(_paired), _pairedPermit);
        _depositAndAddLiquidity(
            _col, 
            _paired, 
            _expiry, 
            _mintRatio, 
            _colAmt, 
            _rcTokenDepositAmt, 
            _pairedDepositAmt, 
            _rcTokenDepositMin, 
            _pairedDepositMin,
            _deadline
        );
    }

    function mmDepositAndAddLiquidity(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _rcTokenDepositAmt,
        uint256 _pairedDepositAmt,
        uint256 _rcTokenDepositMin,
        uint256 _pairedDepositMin,
        uint256 _deadline
    ) external override {
        _mmDepositAndAddLiquidity(
            _col, 
            _paired, 
            _expiry, 
            _mintRatio, 
            _rcTokenDepositAmt, 
            _pairedDepositAmt, 
            _rcTokenDepositMin, 
            _pairedDepositMin,
            _deadline
        );
    }

    function mmDepositWithPermitAndAddLiquidity(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _rcTokenDepositAmt,
        uint256 _pairedDepositAmt,
        uint256 _rcTokenDepositMin,
        uint256 _pairedDepositMin,
        uint256 _deadline,
        Permit calldata _pairedPermit
    ) external override {
        _permit(IERC20Permit(_paired), _pairedPermit);
        _mmDepositAndAddLiquidity(
            _col, 
            _paired, 
            _expiry, 
            _mintRatio, 
            _rcTokenDepositAmt, 
            _pairedDepositAmt, 
            _rcTokenDepositMin, 
            _pairedDepositMin,
            _deadline
        );
    }

    /// @notice This contract should never hold any funds.
    /// Any tokens sent here by accident can be retreived.
    function collect(IERC20 _token) external override onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "RulerZap: balance is 0");
        _token.safeTransfer(msg.sender, balance);
    }

    function updateCore(IRulerCore _core) external override onlyOwner {
        require(address(_core) != address(0), "RulerZap: _core is 0");
        core = _core;
    }

    function updateRouter(IRouter _router) external override onlyOwner {
        require(address(_router) != address(0), "RulerZap: _router is 0");
        router = _router;
    }

    /// @notice check received amount from swap, tokenOut is always the last in array
    function getAmountOut(
        uint256 _tokenInAmt, 
        address[] calldata _path
    ) external view override returns (uint256) {
        return router.getAmountsOut(_tokenInAmt, _path)[_path.length - 1];
    }

    function _depositAndSwapToPaired(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt,
        uint256 _minPairedOut,
        address[] calldata _path,
        uint256 _deadline
    ) private {
        require(_colAmt > 0, "RulerZap: _colAmt is 0");
        require(_path.length >= 2, "RulerZap: _path length < 2");
        require(_path[_path.length - 1] == _paired, "RulerZap: output != _paired");
        require(_deadline >= block.timestamp, "RulerZap: _deadline in past");
        (address _rcToken, uint256 _rcTokensReceived, ) = _deposit(_col, _paired, _expiry, _mintRatio, _colAmt);

        require(_path[0] == _rcToken, "RulerZap: input != rcToken");
        _approve(IERC20(_rcToken), address(router), _rcTokensReceived);
        router.swapExactTokensForTokens(_rcTokensReceived, _minPairedOut, _path, msg.sender, _deadline);
    }

    function _depositAndAddLiquidity(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt,
        uint256 _rcTokenDepositAmt,
        uint256 _pairedDepositAmt,
        uint256 _rcTokenDepositMin,
        uint256 _pairedDepositMin,
        uint256 _deadline
    ) private {
        require(_colAmt > 0, "RulerZap: _colAmt is 0");
        require(_deadline >= block.timestamp, "RulerZap: _deadline in past");
        require(_rcTokenDepositAmt > 0, "RulerZap: 0 rcTokenDepositAmt");
        require(_rcTokenDepositAmt >= _rcTokenDepositMin, "RulerZap: rcToken Amt < min");
        require(_pairedDepositAmt > 0, "RulerZap: 0 pairedDepositAmt");
        require(_pairedDepositAmt >= _pairedDepositMin, "RulerZap: paired Amt < min");

        // deposit collateral to Ruler
        IERC20 rcToken;
        uint256 rcTokensBalBefore;
        { // scope to avoid stack too deep errors
            (address _rcToken, uint256 _rcTokensReceived, uint256 _rcTokensBalBefore) = _deposit(_col, _paired, _expiry, _mintRatio, _colAmt);
            require(_rcTokenDepositAmt <= _rcTokensReceived, "RulerZap: rcToken Amt > minted");
            rcToken = IERC20(_rcToken);
            rcTokensBalBefore = _rcTokensBalBefore;
        }

        // received paired tokens from sender
        IERC20 paired = IERC20(_paired);
        uint256 pairedBalBefore = paired.balanceOf(address(this));
        paired.safeTransferFrom(msg.sender, address(this), _pairedDepositAmt);
        uint256 receivedPaired = paired.balanceOf(address(this)) - pairedBalBefore;
        require(receivedPaired > 0, "RulerZap: paired transfer failed");

        // add liquidity for sender
        _approve(rcToken, address(router), _rcTokenDepositAmt);
        _approve(paired, address(router), _pairedDepositAmt);
        router.addLiquidity(
            address(rcToken), 
            address(paired), 
            _rcTokenDepositAmt, 
            receivedPaired, 
            _rcTokenDepositMin,
            _pairedDepositMin,
            msg.sender,
            _deadline
        );

        // sending leftover tokens back to sender
        uint256 rcTokensLeftover = rcToken.balanceOf(address(this)) - rcTokensBalBefore;
        if (rcTokensLeftover > 0) {
            rcToken.safeTransfer(msg.sender, rcTokensLeftover);
        }
        uint256 pairedTokensLeftover = paired.balanceOf(address(this)) - pairedBalBefore;
        if (pairedTokensLeftover > 0) {
            paired.safeTransfer(msg.sender, pairedTokensLeftover);
        }
    }

    function _mmDepositAndAddLiquidity(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _rcTokenDepositAmt,
        uint256 _pairedDepositAmt,
        uint256 _rcTokenDepositMin,
        uint256 _pairedDepositMin,
        uint256 _deadline
    ) private {
        require(_deadline >= block.timestamp, "RulerZap: _deadline in past");
        require(_rcTokenDepositAmt > 0, "RulerZap: 0 rcTokenDepositAmt");
        require(_rcTokenDepositAmt >= _rcTokenDepositMin, "RulerZap: rcToken Amt < min");
        require(_pairedDepositAmt > 0, "RulerZap: 0 pairedDepositAmt");
        require(_pairedDepositAmt >= _pairedDepositMin, "RulerZap: paired Amt < min");

        // transfer all paired tokens from sender to this contract
        IERC20 paired = IERC20(_paired);
        uint256 pairedBalBefore = paired.balanceOf(address(this));
        paired.safeTransferFrom(msg.sender, address(this), _rcTokenDepositAmt + _pairedDepositAmt);
        require(paired.balanceOf(address(this)) - pairedBalBefore > _rcTokenDepositAmt + _pairedDepositAmt, "RulerZap: paired transfer failed");

        // mmDeposit paired to Ruler to receive rcTokens
        ( , , , IRERC20 rcToken, , , , ) = core.pairs(_col, _paired, _expiry, _mintRatio);
        require(address(rcToken) != address(0), "RulerZap: pair not exist");
        uint256 rcTokenBalBefore = rcToken.balanceOf(address(this));
        _approve(paired, address(core), _rcTokenDepositAmt);
        core.mmDeposit(_col, _paired, _expiry, _mintRatio, _rcTokenDepositAmt);
        uint256 rcTokenReceived = rcToken.balanceOf(address(this)) - rcTokenBalBefore;
        require(_rcTokenDepositAmt <= rcTokenReceived, "RulerZap: rcToken Amt > minted");

        // add liquidity for sender
        _approve(rcToken, address(router), _rcTokenDepositAmt);
        _approve(paired, address(router), _pairedDepositAmt);
        router.addLiquidity(
            address(rcToken),
            _paired,
            _rcTokenDepositAmt, 
            _pairedDepositAmt, 
            _rcTokenDepositMin,
            _pairedDepositMin,
            msg.sender,
            _deadline
        );

        // sending leftover tokens (since the beginning of user call) back to sender
        _transferRem(rcToken, rcTokenBalBefore);
        _transferRem(paired, pairedBalBefore);
    }

    function _deposit(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt
    ) private returns (address rcTokenAddr, uint256 rcTokenReceived, uint256 rcTokenBalBefore) {
        ( , , , IRERC20 rcToken, IRERC20 rrToken, , , ) = core.pairs(_col, _paired, _expiry, _mintRatio);
        require(address(rcToken) != address(0) && address(rrToken) != address(0), "RulerZap: pair not exist");
        // receive collateral from sender
        IERC20 collateral = IERC20(_col);
        uint256 colBalBefore = collateral.balanceOf(address(this));
        collateral.safeTransferFrom(msg.sender, address(this), _colAmt);
        uint256 received = collateral.balanceOf(address(this)) - colBalBefore;
        require(received > 0, "RulerZap: col transfer failed");

        // deposit collateral to Ruler
        rcTokenBalBefore = rcToken.balanceOf(address(this));
        uint256 rrTokenBalBefore = rrToken.balanceOf(address(this));
        _approve(collateral, address(core), received);
        core.deposit(_col, _paired, _expiry, _mintRatio, received);

        // send rrToken back to sender, and record received rcTokens
        _transferRem(rrToken, rrTokenBalBefore);
        rcTokenReceived = rcToken.balanceOf(address(this)) - rcTokenBalBefore;
        rcTokenAddr = address(rcToken);
    }

    function _approve(IERC20 _token, address _spender, uint256 _amount) private {
        uint256 allowance = _token.allowance(address(this), _spender);
        if (allowance < _amount) {
            if (allowance != 0) {
                _token.safeApprove(_spender, 0);
            }
            _token.safeApprove(_spender, type(uint256).max);
        }
    }

    function _permit(IERC20Permit _token, Permit calldata permit) private {
        _token.permit(
            permit.owner,
            permit.spender,
            permit.amount,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
    }

    // transfer remaining amount (since the beginnning of action) back to sender
    function _transferRem(IERC20 _token, uint256 _balBefore) private {
        uint256 tokensLeftover = _token.balanceOf(address(this)) - _balBefore;
        if (tokensLeftover > 0) {
            _token.safeTransfer(msg.sender, tokensLeftover);
        }
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

import "./IRERC20.sol";
import "./IOracle.sol";

/**
 * @title IRulerCore contract interface. See {RulerCore}.
 * @author crypto-pumpkin
 */
interface IRulerCore {
  event RTokenCreated(address);
  event CollateralUpdated(address col, uint256 old, uint256 _new);
  event PairAdded(address indexed collateral, address indexed paired, uint48 expiry, uint256 mintRatio);
  event MarketMakeDeposit(address indexed user, address indexed collateral, address indexed paired, uint48 expiry, uint256 mintRatio, uint256 amount);
  event Deposit(address indexed user, address indexed collateral, address indexed paired, uint48 expiry, uint256 mintRatio, uint256 amount);
  event Repay(address indexed user, address indexed collateral, address indexed paired, uint48 expiry, uint256 mintRatio, uint256 amount);
  event Redeem(address indexed user, address indexed collateral, address indexed paired, uint48 expiry, uint256 mintRatio, uint256 amount);
  event Collect(address indexed user, address indexed collateral, address indexed paired, uint48 expiry, uint256 mintRatio, uint256 amount);
  event AddressUpdated(string _type, address old, address _new);
  event PausedStatusUpdated(bool old, bool _new);
  event RERC20ImplUpdated(address rERC20Impl, address newImpl);
  event FlashLoanRateUpdated(uint256 old, uint256 _new);

  struct Pair {
    bool active;
    uint48 expiry;
    address pairedToken;
    IRERC20 rcToken; // ruler capitol token, e.g. RC_Dai_wBTC_2_2021
    IRERC20 rrToken; // ruler repayment token, e.g. RR_Dai_wBTC_2_2021
    uint256 mintRatio; // 1e18, price of collateral / collateralization ratio
    uint256 feeRate; // 1e18
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
  function oracle() external view returns (IOracle);
  function version() external pure returns (string memory);
  function flashLoanRate() external view returns (uint256);
  function paused() external view returns (bool);
  function responder() external view returns (address);
  function feeReceiver() external view returns (address);
  function rERC20Impl() external view returns (address);
  function collaterals(uint256 _index) external view returns (address);
  function minColRatioMap(address _col) external view returns (uint256);
  function feesMap(address _token) external view returns (uint256);
  function pairs(address _col, address _paired, uint48 _expiry, uint256 _mintRatio) external view returns (
    bool active, 
    uint48 expiry, 
    address pairedToken, 
    IRERC20 rcToken, 
    IRERC20 rrToken, 
    uint256 mintRatio, 
    uint256 feeRate, 
    uint256 colTotal
  );

  // extra view
  function getCollaterals() external view returns (address[] memory);
  function getPairList(address _col) external view returns (Pair[] memory);
  function viewCollectible(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _rcTokenAmt
  ) external view returns (uint256 colAmtToCollect, uint256 pairedAmtToCollect);

  // user action - only when not paused
  function mmDeposit(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _rcTokenAmt
  ) external;
  function mmDepositWithPermit(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    uint256 _rcTokenAmt,
    Permit calldata _pairedPermit
  ) external;
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
  function collectFees(IERC20[] calldata _tokens) external;

  // access restriction - owner (dev) & responder
  function setPaused(bool _paused) external;

  // access restriction - owner (dev)
  function addPair(
    address _col,
    address _paired,
    uint48 _expiry,
    string calldata _expiryStr,
    uint256 _mintRatio,
    string calldata _mintRatioStr,
    uint256 _feeRate
  ) external;
  function setPairActive(
    address _col,
    address _paired,
    uint48 _expiry,
    uint256 _mintRatio,
    bool _active
  ) external;
  function updateCollateral(address _col, uint256 _minColRatio) external;
  function setFeeReceiver(address _addr) external;
  function setResponder(address _addr) external;
  function setRERC20Impl(address _addr) external;
  function setOracle(address _addr) external;
  function setFlashLoanRate(uint256 _newRate) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRouter {
  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
      external
      returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./IRulerCore.sol";
import "./IRouter.sol";
import "../ERC20/IERC20.sol";

interface IRulerZap {
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
    function core() external view returns (IRulerCore);
    function router() external view returns (IRouter);

    // extra view
    function getAmountOut(uint256 _tokenInAmt, address[] calldata _path) external view returns (uint256);

    // user interactions
    function depositAndSwapToPaired(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt,
        uint256 _minPairedOut,
        address[] calldata _path,
        uint256 _deadline
    ) external;

    function depositWithPermitAndSwapToPaired(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt,
        uint256 _minPairedOut,
        address[] calldata _path,
        uint256 _deadline,
        Permit calldata _colPermit
    ) external;

    function depositAndAddLiquidity(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt,
        uint256 _rcTokenDepositAmt,
        uint256 _pairedDepositAmt,
        uint256 _rcTokenDepositMin,
        uint256 _pairedDepositMin,
        uint256 _deadline
    ) external;

    function depositWithColPermitAndAddLiquidity(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt,
        uint256 _rcTokenDepositAmt,
        uint256 _pairedDepositAmt,
        uint256 _rcTokenDepositMin,
        uint256 _pairedDepositMin,
        uint256 _deadline,
        Permit calldata _colPermit
    ) external;

    function depositWithPairedPermitAndAddLiquidity(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt,
        uint256 _rcTokenDepositAmt,
        uint256 _pairedDepositAmt,
        uint256 _rcTokenDepositMin,
        uint256 _pairedDepositMin,
        uint256 _deadline,
        Permit calldata _pairedPermit
    ) external;

    function depositWithBothPermitsAndAddLiquidity(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt,
        uint256 _rcTokenDepositAmt,
        uint256 _pairedDepositAmt,
        uint256 _rcTokenDepositMin,
        uint256 _pairedDepositMin,
        uint256 _deadline,
        Permit calldata _colPermit,
        Permit calldata _pairedPermit
    ) external;

    function mmDepositAndAddLiquidity(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _rcTokenDepositAmt,
        uint256 _pairedDepositAmt,
        uint256 _rcTokenDepositMin,
        uint256 _pairedDepositMin,
        uint256 _deadline
    ) external;

    function mmDepositWithPermitAndAddLiquidity(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _rcTokenDepositAmt,
        uint256 _pairedDepositAmt,
        uint256 _rcTokenDepositMin,
        uint256 _pairedDepositMin,
        uint256 _deadline,
        Permit calldata _pairedPermit
    ) external;

    // admin
    function collect(IERC20 _token) external;
    function updateCore(IRulerCore _core) external;
    function updateRouter(IRouter _router) external;
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

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IOracle {
    function getPriceUSD(address reserve) external view returns (uint256);
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