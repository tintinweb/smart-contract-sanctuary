// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import './FeeExchanger.sol';
import '../interface/IFeeDistributor.sol';

/**
 * @author Asaf Silman
 * @title FeeExchanger using Sushiswap
 * @dev This contract is upgradable and should be deployed using Openzeppelin upgrades
 * @notice Exchanges fees for `outputToken` and forwards to `outputAddress`
 */
contract SushiswapExchanger is FeeExchanger {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    // Sushiswap router is implmenented using the uniswap interface
    IUniswapV2Router02 private _sushiswapRouter;
    address[] private _path;

    string constant _name = "Sushiswap Exchanger";

    /**
     * @notice Initialises the Sushiswap Exchanger contract.
     * @dev Most of the initialisation is done as part of the `FeeExchanger` initialisation.
     * @dev This method sets the internal sushiswap router address.
     * @dev This method also initialises the router path.
     * @param routerAddress The address of the sushiswap router.
     * @param inputToken The token which the protocol fees are generated in. This should set to the WETH address.
     * @param outputToken The token which this contract will exchange fees into.
     * @param outputAddress The address where fees will be redirected to.
     */
    function initialize(IUniswapV2Router02 routerAddress, IERC20Upgradeable inputToken, IERC20Upgradeable outputToken, address outputAddress) public initializer {
        FeeExchanger.__FeeExchanger_init(inputToken, outputToken, outputAddress);

        _sushiswapRouter = routerAddress;

        _path = new address[](2);
        _path[0] = address(inputToken);
        _path[1] = address(outputToken);
    }

    /**
     * @notice Exchanges fees on sushiswap
     * @dev This method validates the minAmountOut was transfered to the output address.
     * @dev The expiration time is hardcoded to 1800 seconds, or 30 minutes.
     * @dev This method can only be called by an approved exchanger, see FeeExchanger.sol for more info.
     * @dev This method can be static called to analyse the output amount of tokens at a given time.
     * @param amountIn The input amount of fees to swap.
     * @param minAmountOut The minimum output amount of tokens to receive after the swap has executed.
     * @return The amount of output token which was exchanged
     */
    function exchange(uint256 amountIn, uint256 minAmountOut) nonReentrant onlyExchanger external override returns (uint256) {
        require(FeeExchanger._inputToken.balanceOf(address(this)) >= amountIn, "FE: AMOUNT IN");

        // Approve input token for swapping
        FeeExchanger._inputToken.safeIncreaseAllowance(address(_sushiswapRouter), amountIn);
        
        uint256 balance0 = FeeExchanger._outputToken.balanceOf(address(this));
        
        // Swap tokens using sushi
        _sushiswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
          amountIn,
          minAmountOut, 
          _path,
          address(this),
          block.timestamp + 1800
        );

        uint256 balance1 = FeeExchanger._outputToken.balanceOf(address(this));
        uint256 amountOut = balance1 - balance0;

        // Approve output token to call `burn` on feeDistributor
        // Note, burn will transfer the entire balance of outputToken
        FeeExchanger._outputToken.safeIncreaseAllowance(address(FeeExchanger._outputAddress), balance1);
        // Deposit output token via `burn`
        IFeeDistributor(FeeExchanger._outputAddress).burn(address(FeeExchanger._outputToken));

        emit TokenExchanged(amountIn, amountOut, _name);

        return amountOut;
    }

    /**
     * @notice Updates the swapping path for the router.
     * @dev The first element of the path must be the input token.
     * @dev The last element of the path must be the output token.
     * @dev This method is only callable by an exchanger.
     * @param newPath The new router path.
     */
    function updatePath(address[] memory newPath) onlyExchanger external {
        require(newPath[0]==address(FeeExchanger._inputToken), "FE: PATH INPUT");
        require(newPath[newPath.length-1]==address(FeeExchanger._outputToken), "FE: PATH OUTPUT");

        _path = newPath;
    }

    /**
     * @notice View function to return the router path.
     * @return The router path.
     */
    function getPath() external view returns (address[] memory) {
        return _path;
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import '../interface/IFeeExchanger.sol';

/**
 * @author Asaf Silman
 * @title FeeExchanger Implementation
 * @notice This contract should be inherited by contracts specific to a DEX or exchange strategy for protocol fees.
 * @dev This contract implmenents the basic requirements for a feeExchanger.
 * @dev Contracts which inherit this are required to implmenent the `exchange` function.
 */
abstract contract FeeExchanger is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, IFeeExchanger {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable internal _inputToken;
    IERC20Upgradeable internal _outputToken;

    address internal _outputAddress;

    // Keep an internal mapping of which addresses can exchange fees
    mapping(address => bool) private _canExchange;

    /**
     * @notice Initialises the FeeExchanger.
     * @dev Also intitalises Ownable and ReentrancyGuard 
     * @param inputToken_ The input ERC20 token representing fees.
     * @param outputToken_ The output ERC20 token, fees will be exchanged into this currency.
     * @param outputAddress_ Exchanged fees will be transfered to this address.
     */
    function __FeeExchanger_init(
        IERC20Upgradeable inputToken_, 
        IERC20Upgradeable outputToken_,
        address outputAddress_
    ) internal initializer {       
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        
        _inputToken = inputToken_;
        _outputToken = outputToken_;

        _outputAddress = outputAddress_;

        emit OutputAddressUpdated(address(0), _outputAddress);
    }

    /**
     * @notice Modifier to check if msg.sender can exchange.
     */
    modifier onlyExchanger() {
        require(_canExchange[msg.sender], "FE: NOT EXCHANGER");
        _;
    }

    /**
     * @notice Adds an address as an exchanger.
     * @dev Exchangers have permission to exchange funds via the `exchange` function.
     * @dev This method can only be called by the owner.
     * @param exchanger The address of the exchanger.
     */
    function addExchanger(address exchanger) onlyOwner external override {
        require(!_canExchange[exchanger], "FE: ALREADY EXCHANGER");

        _canExchange[exchanger] = true;

        emit ExchangerUpdated(exchanger, true);
    }

    /**
     * @notice Removed an address as an exchanger.
     * @dev This method can only be called by the owner.
     * @param exchanger The address of the exchanger.
     */
    function removeExchanger(address exchanger) onlyOwner external override {
        require(_canExchange[exchanger], "FE: NOT EXCHANGER");

        _canExchange[exchanger] = false;

        emit ExchangerUpdated(exchanger, false);
    }
    
    /**
     * @notice Check if an address is an exchanger.
     * @dev This is a view method to use with tools such as etherscan.
     * @dev address(0) is not checked for exchanger.
     * @param exchanger The address of the exchanger.
     * @return Boolean whether address is exchanger
     */
    function canExchange(address exchanger) external view override returns (bool) {
        return _canExchange[exchanger];
    }

    /**
     * @notice Update the ouput address.
     * @dev Fees which have been swapped will be sent to the new address after this has been called.
     * @dev address(0) is not checked for newOutputAddress.
     * @param newOutputAddress The new address to send swapped fees to.
     */
    function updateOutputAddress(address newOutputAddress) onlyOwner external override {
        address previousAddress = _outputAddress;
        _outputAddress = newOutputAddress;

        emit OutputAddressUpdated(previousAddress, newOutputAddress);
    }

    /**
     * @notice Return the input token address.
     * @return Input token address.
     */
    function inputToken() external view override returns (IERC20Upgradeable) { return _inputToken; }

    /**
     * @notice Return the ouput token address.
     * @return Output token address.
     */
    function outputToken() external view override returns (IERC20Upgradeable) { return _outputToken; }

    /**
     * @notice Return the output address.
     * @return Output address.
     */
    function outputAddress() external view override returns (address) { return _outputAddress; }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.4;

/**
 * @author Asaf Silman
 * @title FeeDistributor Interface
 * @notice Interface for a FeeDistributor based on curve.finance implementation.
 * @dev This is a minimal implementation of the interface in solidity to implement and test the feeExchanger
 */
interface IFeeDistributor {
    event CheckpointToken(uint256 time, uint256 tokens);

    function checkpoint_token() external;
    function burn(address) external;

    function toggle_allow_checkpoint_token() external;
    function can_checkpoint_token() external returns (bool);
    function token_last_balance() external returns (uint256);
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @author Asaf Silman
 * @title FeeExchanger Interface
 * @dev This interface should be implemented to swap fees generated from a protocol via a DEX.
 */
interface IFeeExchanger {
    /**
     * @notice View function to retrieve the input token address.
     * @return The input token address.
     */
    function inputToken() external view returns (IERC20Upgradeable);
    /**
     * @notice View function to retrieve the output token address.
     * @return The output token address.
     */
    function outputToken() external view returns (IERC20Upgradeable);

    /**
     * @notice Emitted when the output address is updated.
     * @param previousAddress The previous output address.
     * @param newAddress The new output address.
     */
    event OutputAddressUpdated(address previousAddress, address newAddress);
    /**
     * @notice Change the output address.
     * @dev The output address be interpreted as any contract type in the implmentation.
     * @dev For example the output address could be a FeeDistributor contract.
     * @param newOutputAddress The new output address.
     */
    function updateOutputAddress(address newOutputAddress) external;
    /**
     * @notice View function to retrieve the output address.
     * @return The output address.
     */
    function outputAddress() external view returns (address);

    /**
     * @notice Emitted when a token is exchanged.
     * @param amountIn Input token amount exchanged.
     * @param amountOut Output token amount exchanged for.
     * @param exchangeName The exchange name which the swap was performed on.
     */
    event TokenExchanged(uint256 amountIn, uint256 amountOut, string exchangeName);
    /**
     * @notice Perform a token exchange
     * @dev Implement this function specifically for each DEX.
     * @dev This method should only be callable from an exchanger
     * @param amountIn The amount of input token to exchange.
     * @param minAmountOut The minimum amout of output token to receive from the trade.
     */
    function exchange(uint256 amountIn, uint256 minAmountOut) external returns (uint256);

    /**
     * @notice Emitted when an exchanger is updated.
     * @dev An exchanger is simply an address which can call 'exchange(...)'.
     * @param exchanger The exchanger address, can be an EOA or contract.
     * @param canExchange Exchanger state.
     */
    event ExchangerUpdated(address indexed exchanger, bool canExchange);
    /**
     * @notice Adds an address as an exchanger.
     * @param exchanger The exchanger address to add.
     */
    function addExchanger(address exchanger) external;
    /**
     * @notice Removes an address as an exchanger.
     * @param exchanger The exchanger address to remove.
     */
    function removeExchanger(address exchanger) external;
    /**
     * @notice Check if an address is an exchanger.
     * @param exchanger The exchanger address to check.
     * @return True if address is an exchanger. False otherwise.
     */
    function canExchange(address exchanger) external view returns (bool);
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
    "enabled": false,
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