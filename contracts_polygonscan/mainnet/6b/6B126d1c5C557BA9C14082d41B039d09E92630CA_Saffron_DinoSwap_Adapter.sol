/**
 *Submitted for verification at polygonscan.com on 2021-09-05
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/interfaces/ISaffron_DinoSwap_AdapterV2.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ISaffron_DinoSwap_AdapterV2 {
    function set_pool(address pool) external;
    function deploy_capital(uint256 lp_amount) external;
    function return_capital(uint256 lp_amount, address to) external;
    function get_holdings() external returns(uint256);
    function set_lp(address addr) external;
    function propose_governance(address to) external;
    function accept_governance() external;
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts/utils/[email protected]


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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


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


// File contracts/interfaces/IFossilFarms.sol


pragma solidity 0.8.4;

interface IFossilFarms {
  function userInfo(uint256 _pid, address _user) external view returns (uint256);
  function pendingDino(uint256 _pid, address _user) external view returns (uint256);
  function deposit(uint256 _pid, uint256 _amount) external;
  function withdraw(uint256 _pid, uint256 _amount) external;
}


// File contracts/adapters/Saffron_DinoSwap_AdapterV2.sol


pragma solidity ^0.8.4;



interface IUniswapRouterV2 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactTokensForTokens( uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function addLiquidity( address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns ( uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityETH( address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns ( uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function removeLiquidity( address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
    function swapETHForExactTokens( uint256 amountOut, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
    function swapExactETHForTokens( uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
}

contract SaffronDinoSwapAutocompounder {
  using SafeERC20 for IERC20;

  // Existing farms and composable protocol connectors to be set in constructor
  IFossilFarms public dinoswap;         // DinoSwap Fossil farm address

  // Constants from Polygon mainnet
  /*
  address public DINO = 0xAa9654BECca45B5BDFA5ac646c939C62b527D394;             // DINO address on Polygon
  address public WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;             // WETH address on Polygon
  address public DINO_WETH_LP = 0x9f03309A588e33A239Bf49ed8D68b2D45C7A1F11;     // Quickswap DINO/WETH QLP
  uint256 public DINO_WETH_pid = 11;                                            // DinoSwap DINO/WETH pid
  address public QUICKSWAP_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // Quickswap router
  address public FOSSIL_FARMS = 0x1948abC5400Aa1d72223882958Da3bec643fb4E5;     // DinoSwap fossil farms
  */

  // DinoSwap Fossil Farms parameters
  address public lp;   // LP token to autocompound into
  uint256 public pid;  // Pool ID in farm's pool array

  // Governance
  address public governance;
  address public new_governance;
  bool public autocompound_enabled = true;

  // Saffron
  ISaffron_DinoSwap_AdapterV2 public adapter; 
  
  // Conversion storage for swaps to autocompound lp tokens
  struct Conversion {
    address router;      // Router to do the conversion: QuickSwap, SushiSwap, etc.
    address token_from;  // Token to convert from
    address token_to;    // Token to convert to
    uint256 percentage;  // Percentage of tokenFrom to convert: 50 == half, 100 == all
  }

  Conversion[] public conversions;

  constructor(address _adapter_address, address _lp_address, uint256 _pid, address _router_address, address _farm_address) {
    require(_adapter_address != address(0) && _lp_address != address(0) && _router_address != address(0) && _farm_address != address(0), "can't construct with 0 address");
    governance = msg.sender;

    // DinoSwap protocol
    dinoswap = IFossilFarms(_farm_address);

    // Saffron protocol
    adapter = ISaffron_DinoSwap_AdapterV2(_adapter_address);

    // Contract state variables
    lp  = _lp_address; 
    pid = _pid;        

    // Approve sending LP tokens to DinoSwap Fossil Farm
    IERC20(_lp_address).safeApprove(_farm_address, type(uint128).max);
  }

  // Initialize conversions with routers, tokens, percentages, and minimum amounts to swap tokens for more lp tokens when autocompounding
  function init_conversions(address[] memory routers, address[] memory tokens_from, address[] memory tokens_to, uint[] memory percentages) public {
    require(msg.sender == governance, "must be governance");

    // Verify that the lengths of all arrays are equal and non-zero and the final conversion has an lp token address
    require(routers.length > 0 && (routers.length + tokens_from.length + tokens_to.length + percentages.length ) / 4 == routers.length, "invalid conversions");

    // Clear the conversions array if it was already initialized
    delete conversions;
    
    // Build the conversions array
    for (uint256 i; i < routers.length; ++i) {
      require(percentages[i] <= 100, "bad percentage");
      Conversion memory cv = Conversion({
        router:      routers[i],
        token_from:  tokens_from[i],
        token_to:    tokens_to[i],
        percentage:  percentages[i]
      });
      conversions.push(cv);
      
      // Approve both tokens for swapping
      IERC20(tokens_from[i]).safeApprove(routers[i], 0);
      IERC20(  tokens_to[i]).safeApprove(routers[i], 0);
      IERC20(tokens_from[i]).safeApprove(routers[i], type(uint128).max);
      IERC20(  tokens_to[i]).safeApprove(routers[i], type(uint128).max);
    }
  }

  // Reset approvals to uint128.max
  function reset_approvals() external {
    // Reset LP token
    IERC20(lp).safeApprove(address(dinoswap), 0);
    IERC20(lp).safeApprove(address(dinoswap), type(uint128).max);

    // Loop through conversions
    for(uint256 i; i < conversions.length; ++i) {
      Conversion memory cv = get_conversion(i);

      // Set approvals to max
      IERC20(cv.token_from).safeApprove(cv.router, 0);
      IERC20(  cv.token_to).safeApprove(cv.router, 0);
      IERC20(cv.token_from).safeApprove(cv.router, type(uint128).max);
      IERC20(  cv.token_to).safeApprove(cv.router, type(uint128).max);
    }
  }

  // Deposit into DinoSwap and autocompound
  function fossilize(uint256 amount_qlp) external {
    require(msg.sender == address(adapter), "must be adapter");
    autocompound();
    dinoswap.deposit(pid, amount_qlp);
  }

  // Withdraw from DinoSwap and return funds to router
  function excavate(uint256 amount, address to) external {
    require(msg.sender == address(adapter), "must be adapter");
    autocompound();
    dinoswap.withdraw(pid, amount);
    IERC20(lp).safeTransfer(to, amount);
  }

  // Autocompound rewards into more lp tokens
  function autocompound() public {
    if (autocompound_enabled == false) return;

    // Deposit 0 to DinoSwap to harvest tokens
    dinoswap.deposit(pid, 0);

    // Step through the conversions array and swap tokens for tokens until we can add liquidity to DinoSwap
    for(uint256 i; i < conversions.length; ++i) {
      Conversion memory cv = get_conversion(i);

      // If balance of token_from is greater than the min amount needed to successfully swap then swap a percentage for token_to
      uint256 amount_from = IERC20(cv.token_from).balanceOf(address(this)) * cv.percentage / 100;
      // Make sure there is something to convert
      if (amount_from > 0) {
        address[] memory path;
        path = new address[](2);
        path[0] = cv.token_from;
        path[1] = cv.token_to;

        // Calculate how many tokens will be returned from conversion
        uint256[] memory amounts_out = IUniswapRouterV2(cv.router).getAmountsOut(amount_from, path);
        // Swap tokens if the amount out will be greater than 0
        if(amounts_out[1] > 0) {
          IUniswapRouterV2(cv.router).swapExactTokensForTokens(amount_from, 0, path, address(this), block.timestamp + 60);
        } else {
          // Swap would return 0 so quit for now
          return;
        }
      } else {
        // Nothing to convert so quit
        return;
      }

      // If we're on the last iteration then we must add liquidity to the pair
      if (i == conversions.length - 1) {
        uint256 token_from_balance = IERC20(cv.token_from).balanceOf(address(this));
        uint256 token_to_balance   = IERC20(cv.token_to).balanceOf(address(this));

        // Add liquidity only if we have some amount of both tokens
        if (token_from_balance > 0 && token_to_balance > 0) {
          uint256 lp_before = IERC20(lp).balanceOf(address(this));
          IUniswapRouterV2(cv.router).addLiquidity(cv.token_from, cv.token_to, token_from_balance, token_to_balance, 0, 0, address(this), block.timestamp + 60);
          dinoswap.deposit(pid, IERC20(lp).balanceOf(address(this)) - lp_before);
        }
      }
    }
  }

  // Read a Conversion item into memory for efficient lookup
  function get_conversion(uint256 i) internal view returns (Conversion memory cv) {
    return Conversion({
      router:      conversions[i].router,
      token_from:  conversions[i].token_from,
      token_to:    conversions[i].token_to,
      percentage:  conversions[i].percentage
    });
  }

  /// GETTERS 
  // Get autocompounder holdings after autocompounding 
  function get_autocompounder_holdings() public returns (uint256) {
    autocompound();
    return dinoswap.userInfo(pid, address(this));
  }

  // Get holdings from DinoSwap Fossil Farms contract
  function get_dinoswap_holdings() public view returns (uint256) {
    return dinoswap.userInfo(pid, address(this));
  }

  /// GOVERNANCE
  // Set new Fossil Farms contract address
  function set_fossil_farm(address _fossil_farm) external {
    require(msg.sender == governance, "must be governance");
    dinoswap = IFossilFarms(_fossil_farm);
  }

  // Toggle autocompounding
  function set_autocompound_enabled(bool _enabled) external {
    require(msg.sender == governance, "must be governance");
    autocompound_enabled = _enabled;
  }

  // Governance transfer
  function propose_governance(address to) external {
    require(msg.sender == governance, "must be governance");
    new_governance = to;
  }

  // Governance transfer
  function accept_governance() external {
    require(msg.sender == new_governance, "must be new governance");
    governance = msg.sender;
    new_governance = address(0);
  }

  // Sweep funds in case of emergency
  function sweep_erc(address _token, address _to) public {
    require(msg.sender == governance, "must be governance");
    IERC20 token = IERC20(_token);
    uint256 token_balance = token.balanceOf(address(this));
    token.transfer(_to, token_balance);
  }

  // Withdraw funds from DinoSwap Fossil Farms in case of emergency
  function emergency_withdraw(uint256 _pid, uint256 _amount) external {
    require(msg.sender == governance, "must be governance");
    dinoswap.withdraw(_pid, _amount);
  }
}

contract Saffron_DinoSwap_Adapter is ISaffron_DinoSwap_AdapterV2 {
  using SafeERC20 for IERC20;

  // Governance and pool 
  address public governance;                          // Governance address
  address public new_governance;                      // Newly proposed governance address
  address public saffron_pool;                        // SaffronPool that owns this adapter

  // Platform-specific vars
  IERC20 public LP;                                   // DINO/WETH QLP address
  IERC20 public DINO;                                 // DINO token
  SaffronDinoSwapAutocompounder public autocompounder;// Auto-Compounder

  // Saffron identifiers
  string public constant platform = "DinoSwap";       // Platform name
  string public name;                                 // Adapter name

  constructor(address _lp_address, string memory _name) {
    require(_lp_address != address(0x0), "can't construct with 0 address");
    governance = msg.sender;
    name       = _name;
    LP         = IERC20(_lp_address);
  }

  event CapitalDeployed(uint256 lp_amount);
  event CapitalReturned(uint256 lp_amount, address to);
  event Holdings(uint256 holdings);
  event ErcSwept(address who, address to, address token, uint256 amount);

  // Adds funds to underlying protocol. Called from pool's deposit function
  function deploy_capital(uint256 lp_amount) external override {
    require(msg.sender == saffron_pool, "must be pool");

    // Send lp to autocompounder and deposit into DinoSwap
    LP.safeTransfer(address(autocompounder), lp_amount);
    autocompounder.fossilize(lp_amount);
    emit CapitalDeployed(lp_amount);
  }

  // Returns funds to user. Called from pool's withdraw function
  function return_capital(uint256 lp_amount, address to) external override {
    require(msg.sender == saffron_pool, "must be pool");
    autocompounder.excavate(lp_amount, to);
    emit CapitalReturned(lp_amount, to);
  }

  // Updates autocompounder state and returns its holdings. Will execute an autocompound()
  function get_holdings() external override returns(uint256 holdings) {
    holdings = autocompounder.get_autocompounder_holdings();
    emit Holdings(holdings);
  }

  /// GOVERNANCE
  // Set a new Saffron autocompounder address
  function set_autocompounder(address _autocompounder) public {
    require(msg.sender == governance, "must be governance");
    autocompounder = SaffronDinoSwapAutocompounder(_autocompounder);
  }

  // Set a new pool address
  function set_pool(address pool) external override {
    require(msg.sender == governance, "must be governance");
    require(pool != address(0x0), "can't set pool to 0 address");
    saffron_pool = pool;
  }

  // Set a new LP token
  function set_lp(address addr) external override {
    require(msg.sender == governance, "must be governance");
    LP=IERC20(addr);
  }

  // Governance transfer
  function propose_governance(address to) external override {
    require(msg.sender == governance, "must be governance");
    new_governance = to;
  }

  // Governance transfer
  function accept_governance() external override {
    require(msg.sender == new_governance, "must be new governance");
    governance = msg.sender;
    new_governance = address(0);
  }

  // Sweep funds in case of emergency
  function erc_sweep(address _token, address _to) public {
    require(msg.sender == governance, "must be governance");

    IERC20 tkn = IERC20(_token);
    uint256 tBal = tkn.balanceOf(address(this));
    tkn.safeTransfer(_to, tBal);

    emit ErcSwept(msg.sender, _to, _token, tBal);
  }
}