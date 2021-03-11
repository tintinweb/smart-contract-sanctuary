/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File contracts/interfaces/IERC3156FlashBorrower.sol

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


// File contracts/interfaces/IERC3156FlashLender.sol

pragma solidity ^0.8.0;
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
      address receiver,
      address token,
      uint256 amount,
      bytes calldata data
  ) external returns (bool);
}


// File contracts/interfaces/ICErc20.sol

pragma solidity ^0.8.0;

interface ICErc20 {
    function liquidateBorrow(address borrower, uint amount, address collateral) external returns (uint);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function underlying() external view returns (address);
}


// File contracts/ERC20/IERC20.sol

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


// File contracts/interfaces/IWeth.sol

pragma solidity ^0.8.0;
interface IWeth is IERC20 {
    function deposit() external payable;
}


// File contracts/interfaces/IComptroller.sol

pragma solidity ^0.8.0;

interface IComptroller {
    function getAccountLiquidity(address account) external view returns (uint256, uint256, uint256);
}


// File contracts/interfaces/IRouter.sol

pragma solidity ^0.8.0;

interface IRouter {
    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

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
}


// File contracts/utils/Context.sol

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


// File contracts/utils/Ownable.sol

pragma solidity ^0.8.0;
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
    constructor () {
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
}


// File contracts/utils/Address.sol

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


// File contracts/ERC20/SafeERC20.sol

pragma solidity ^0.8.0;
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


// File contracts/AnchorFlashLiquidator.sol

//SPDX-License-Identifier: None

pragma solidity ^0.8.0;
contract AnchorFlashLiquidator is Ownable {
    using SafeERC20 for IERC20;

    IERC3156FlashLender public flashLender =
        IERC3156FlashLender(0x6bdC1FCB2F13d1bA9D26ccEc3983d5D4bf318693);
    IComptroller public comptroller =
        IComptroller(0x4dCf7407AE5C07f8681e1659f626E114A7667339);
    IRouter public constant sushiRouter =
        IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    IRouter public constant uniRouter =
        IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 public constant dola =
        IERC20(0x865377367054516e17014CcdED1e7d814EDC9ce4);
    IWeth public constant weth =
        IWeth(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 public constant dai =
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    struct LiquidationData {
        address cErc20;
        address cTokenCollateral;
        address borrower;
        address caller;
        IRouter dolaRouter;
        IRouter exitRouter;
        uint256 shortfall;
        uint256 minProfit;
        uint256 deadline;
    }

    function liquidate(
        address _flashLoanToken,
        address _cErc20,
        address _borrower,
        address _cTokenCollateral,
        IRouter _dolaRouter,
        IRouter _exitRouter,
        uint256 _minProfit,
        uint256 _deadline
    ) external {
        require(
            (_dolaRouter == sushiRouter || _dolaRouter == uniRouter) &&
                (_exitRouter == sushiRouter || _exitRouter == uniRouter),
            "Invalid router"
        );
        // make sure _borrower is liquidatable
        (, , uint256 shortfall) = comptroller.getAccountLiquidity(_borrower);
        require(shortfall > 0, "!liquidatable");
        address[] memory path = _getDolaPath(_flashLoanToken);
        uint256 tokensNeeded;
        {
            // scope to avoid stack too deep error
            tokensNeeded = _dolaRouter.getAmountsIn(shortfall, path)[0];
            require(
                tokensNeeded <= flashLender.maxFlashLoan(_flashLoanToken),
                "Insufficient lender reserves"
            );
            uint256 fee = flashLender.flashFee(_flashLoanToken, tokensNeeded);
            uint256 repayment = tokensNeeded + fee;
            _approve(IERC20(_flashLoanToken), address(flashLender), repayment);
        }
        bytes memory data =
            abi.encode(
                LiquidationData({
                    cErc20: _cErc20,
                    cTokenCollateral: _cTokenCollateral,
                    borrower: _borrower,
                    caller: msg.sender,
                    dolaRouter: _dolaRouter,
                    exitRouter: _exitRouter,
                    shortfall: shortfall,
                    minProfit: _minProfit,
                    deadline: _deadline
                })
            );
        flashLender.flashLoan(
            address(this),
            _flashLoanToken,
            tokensNeeded,
            data
        );
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(msg.sender == address(flashLender), "Untrusted lender");
        require(initiator == address(this), "Untrusted loan initiator");
        LiquidationData memory liqData = abi.decode(data, (LiquidationData));

        // Step 1: Convert token to DOLA
        _approve(IERC20(token), address(liqData.dolaRouter), amount);
        address[] memory entryPath = _getDolaPath(token);
        liqData.dolaRouter.swapTokensForExactTokens(
            liqData.shortfall,
            type(uint256).max,
            entryPath,
            address(this),
            liqData.deadline
        )[entryPath.length - 1];

        // Step 2: Liquidate borrower and seize their cToken
        _approve(dola, liqData.cErc20, liqData.shortfall);
        ICErc20(liqData.cErc20).liquidateBorrow(
            liqData.borrower,
            liqData.shortfall,
            liqData.cTokenCollateral
        );
        uint256 seizedBal =
            IERC20(liqData.cTokenCollateral).balanceOf(address(this));

        // Step 3: Redeem seized cTokens for collateral
        _approve(IERC20(liqData.cTokenCollateral), liqData.cErc20, seizedBal);
        uint256 ethBalBefore = address(this).balance; // snapshot ETH balance before redeem to determine if it is cEther
        ICErc20(liqData.cTokenCollateral).redeem(seizedBal);
        address underlying;

        // Step 3.1: Get amount of underlying collateral redeemed
        if (address(this).balance > ethBalBefore) {
            // If ETH balance increased, seized cToken is cEther & wrap into WETH
            weth.deposit{value: address(this).balance}();
            underlying = address(weth);
        } else {
            underlying = ICErc20(liqData.cTokenCollateral).underlying();
        }
        uint256 underlyingBal = IERC20(underlying).balanceOf(address(this));

        // Step 4: Swap underlying collateral for token (if collateral != token)
        uint256 tokensReceived;
        if (underlying != token) {
            _approve(
                IERC20(underlying),
                address(liqData.exitRouter),
                underlyingBal
            );
            address[] memory exitPath = _getExitPath(underlying, token);
            tokensReceived = liqData.exitRouter.swapExactTokensForTokens(
                underlyingBal,
                0,
                exitPath,
                address(this),
                liqData.deadline
            )[exitPath.length - 1];
        } else {
            tokensReceived = underlyingBal;
        }

        // Step 5: Sanity check to ensure process is profitable
        require(
            tokensReceived >= amount + fee + liqData.minProfit,
            "Not enough profit"
        );

        // Step 6: Send profits to caller
        IERC20(token).safeTransfer(
            liqData.caller,
            tokensReceived - (amount + fee)
        );
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function receiveEth() external payable {}

    function setFlashLender(IERC3156FlashLender _flashLender)
        external
        onlyOwner
    {
        flashLender = _flashLender;
    }

    function setComptroller(IComptroller _comptroller) external onlyOwner {
        comptroller = _comptroller;
    }

    function _getDolaPath(address _token)
        internal
        pure
        returns (address[] memory path)
    {
        if (_token == address(weth)) {
            path = new address[](2);
            path[0] = address(weth);
            path[1] = address(dola);
        } else {
            path = new address[](3);
            path[0] = _token;
            path[1] = address(weth);
            path[2] = address(dola);
        }
    }

    function _getExitPath(address _underlying, address _token)
        internal
        pure
        returns (address[] memory path)
    {
        if (_underlying == address(weth)) {
            path = new address[](2);
            path[0] = address(weth);
            path[1] = _token;
        } else {
            path = new address[](3);
            path[0] = address(_underlying);
            path[1] = address(weth);
            path[2] = _token;
        }
    }

    function _approve(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) internal {
        if (_token.allowance(address(this), _spender) < _amount) {
            _token.safeApprove(_spender, type(uint256).max);
        }
    }
}