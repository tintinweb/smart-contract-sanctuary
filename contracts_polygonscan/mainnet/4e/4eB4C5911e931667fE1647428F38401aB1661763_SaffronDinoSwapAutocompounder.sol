// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ISaffron_DinoSwap_AdapterV2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../SaffronConverter.sol";
import "../interfaces/IFossilFarms.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IUniswapRouterV2.sol";

contract SaffronDinoSwapAutocompounder is SaffronConverter, ReentrancyGuard {
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
  bool public autocompound_enabled = true;

  // Saffron
  ISaffron_DinoSwap_AdapterV2 public adapter; 
  
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
  
  // Reset approvals to uint128.max
  function reset_approvals() external {
    // Reset LP token
    IERC20(lp).safeApprove(address(dinoswap), 0);
    IERC20(lp).safeApprove(address(dinoswap), type(uint128).max);
    
    // Reset conversion approvals
    preapprove_conversions();
  }

  // Deposit into DinoSwap and autocompound
  function fossilize(uint256 amount_qlp) external {
    require(msg.sender == address(adapter), "must be adapter");
    dinoswap.deposit(pid, amount_qlp);
  }

  // Withdraw from DinoSwap and return funds to router
  function excavate(uint256 amount, address to) external {
    require(msg.sender == address(adapter), "must be adapter");
    dinoswap.withdraw(pid, amount);
    IERC20(lp).safeTransfer(to, amount);
  }

  // Autocompound rewards into more lp tokens
  function autocompound() external nonReentrant {
    if (!autocompound_enabled) return;

    // Deposit 0 to DinoSwap to harvest tokens

    dinoswap.deposit(pid, 0);
    
    // Convert rewards
    uint256 lp_before = IERC20(lp).balanceOf(address(this));

    convert();
    uint256 lp_rewards = IERC20(lp).balanceOf(address(this)) - lp_before;



    // Deposit rewards if any
    if (lp_rewards > 0) dinoswap.deposit(pid, lp_rewards);
  }

  /// GETTERS 
  // Get autocompounder holdings after autocompounding 
  function get_autocompounder_holdings() external returns (uint256) {
    return dinoswap.userInfo(pid, address(this));
  }

  // Get holdings from DinoSwap Fossil Farms contract
  function get_dinoswap_holdings() external view returns (uint256) {
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

  // Withdraw funds from DinoSwap Fossil Farms in case of emergency
  function emergency_withdraw(uint256 _pid, uint256 _amount) external {
    require(msg.sender == governance, "must be governance");
    dinoswap.withdraw(_pid, _amount);
  }
}

contract Saffron_DinoSwap_Adapter is ISaffron_DinoSwap_AdapterV2, ReentrancyGuard {
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
  function deploy_capital(uint256 lp_amount) external override nonReentrant {
    require(msg.sender == saffron_pool, "must be pool");

    // Send lp to autocompounder and deposit into DinoSwap
    emit CapitalDeployed(lp_amount);
    LP.safeTransfer(address(autocompounder), lp_amount);
    autocompounder.fossilize(lp_amount);
  }

  // Returns funds to user. Called from pool's withdraw function
  function return_capital(uint256 lp_amount, address to) external override nonReentrant {
    require(msg.sender == saffron_pool, "must be pool");
    emit CapitalReturned(lp_amount, to);
    autocompounder.excavate(lp_amount, to);
  }

  // Updates autocompounder state and returns its holdings. Will execute an autocompound()
  function get_holdings() external override nonReentrant returns(uint256 holdings) {
    holdings = autocompounder.get_autocompounder_holdings();
    emit Holdings(holdings);
  }

  function get_holdings_view() external override view returns(uint256 holdings) {
    return autocompounder.get_dinoswap_holdings();
  }

  /// GOVERNANCE
  // Set a new Saffron autocompounder address
  function set_autocompounder(address _autocompounder) external {
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
    require(to != address(0), "can't set to 0");
    new_governance = to;
  }

  // Governance transfer
  function accept_governance() external override {
    require(msg.sender == new_governance, "must be new governance");
    governance = msg.sender;
    new_governance = address(0);
  }

  // Sweep funds in case of emergency
  function sweep_erc(address _token, address _to) external {
    require(msg.sender == governance, "must be governance");
    IERC20 token = IERC20(_token);
    uint256 token_balance = token.balanceOf(address(this));
    emit ErcSwept(msg.sender, _to, _token, token_balance);
    token.transfer(_to, token_balance);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISaffron_DinoSwap_AdapterV2 {
    function set_pool(address pool) external;
    function deploy_capital(uint256 lp_amount) external;
    function return_capital(uint256 lp_amount, address to) external;
    function get_holdings() external returns(uint256);
    function set_lp(address addr) external;
    function propose_governance(address to) external;
    function accept_governance() external;
    function get_holdings_view() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
 
import "./interfaces/IUniswapRouterV2.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract SaffronConverter {
  using SafeERC20 for IERC20;
  
  // Governance
  address public governance;        // Governance address for operations
  address public new_governance;    // Proposed new governance address
  
  // Conversion steps for swapping tokens with any Uniswap V2 style router
  struct Conversion {
    address router;      // Router to do the conversion: QuickSwap, SushiSwap, etc.
    address token_from;  // Token to convert from
    address token_to;    // Token to convert to
    uint256 percentage;  // Percentage of tokenFrom to convert: 50 == half, 100 == all
    uint256 operation;        // 0- add, 1 - remove, 2- swap
  }
  Conversion[] public conversions;
  
  // Conversion flags, can be combined, order is remove, swap, then add
  uint256 private constant REMOVE_LIQUIDITY_FLAG = 1;  // Uniswap router removeLiquidity
  uint256 private constant SWAP_LIQUIDITY_FLAG   = 2;  // Uniswap router swapExactTokensForTokens
  uint256 private constant ADD_LIQUIDITY_FLAG    = 4;  // Uniswap router addLiquidity

  // Additional Reentrancy Guard
  uint256 private _convert_status = 1;
  modifier non_reentrant_convert() {
    require(_convert_status != 2, "ReentrancyGuard: reentrant call");
    _convert_status = 2;
    _;
    _convert_status = 1;
  }

  event FundsConverted(address token_from, address token_to, uint256 amount_from, uint256 amount_to);
  event ErcSwept(address who, address to, address token, uint256 amount);
  
  // Preapprove/reset approvals to uint128.max
  function preapprove_conversions() public {
    // Loop through conversions
    for (uint256 i = 0; i < conversions.length; ++i) {
      Conversion memory cv = get_conversion(i);
      
      if (cv.operation & REMOVE_LIQUIDITY_FLAG != 0) {
          
        address factory = IUniswapRouterV2(cv.router).factory();
        address pairAddress = IUniswapV2Factory(factory).getPair( cv.token_from, cv.token_to );
        IERC20(pairAddress).safeApprove(cv.router, 0);
        IERC20(pairAddress).safeApprove(cv.router, type(uint128).max);
          
      }
      
      // Approve both tokens for swapping
      IERC20(cv.token_from).safeApprove(cv.router, 0);
      IERC20(  cv.token_to).safeApprove(cv.router, 0);
      IERC20(cv.token_from).safeApprove(cv.router, type(uint128).max);
      IERC20(  cv.token_to).safeApprove(cv.router, type(uint128).max);
      
    }
  }  
  
  // Set the conversions array and reset approvals
  function init_conversions(address[] memory routers, address[] memory tokens_from, address[] memory tokens_to, uint256[] memory percentages, uint256[] memory operations) external {
//  function init_conversions(address[] memory routers, address[] memory tokens_from, address[] memory tokens_to, uint256[] memory percentages) public {
    require(msg.sender == governance, "must be governance");

    // Verify that the lengths of all arrays are equal and non-zero and the final conversion has an lp token address
    require(routers.length > 0 && (routers.length + tokens_from.length + tokens_to.length + percentages.length + operations.length) / 5 == routers.length, "invalid conversions");
    // require(routers.length > 0 && (routers.length + tokens_from.length + tokens_to.length + percentages.length) / 4 == routers.length, "invalid conversions");

    // Clear the conversions array if it was already initialized
    delete conversions;
    
    // Build the conversions array
    for (uint256 i = 0; i < routers.length; ++i) {
      require(percentages[i] <= 100, "bad percentage");
      require(operations[i] <= 7, "bad operations");
      Conversion memory cv = Conversion({
        router:      routers[i],
        token_from:  tokens_from[i],
        token_to:    tokens_to[i],
        percentage:  percentages[i],
        operation: operations[i]
      });
      conversions.push(cv);
    }
    
    // Pre-approve the conversions
    preapprove_conversions();
  }
 
  // Convert funds to other funds (only remove liquidity on conversions[0])
  function convert() internal non_reentrant_convert {

    for (uint256 i = 0; i < conversions.length; ++i) {
      Conversion memory cv = get_conversion(i);
      
      // Detect type of conversion and act accordingly
      if (cv.operation & REMOVE_LIQUIDITY_FLAG != 0 ) {
        address factory = IUniswapRouterV2(cv.router).factory();
        address pairAddress = IUniswapV2Factory(factory).getPair( cv.token_from, cv.token_to );
        
        // Check reserves
        uint256 balance_to_burn = IERC20(pairAddress).balanceOf(address(this));

        if (balance_to_burn > 0 && !remove_liquidity_would_return_zero(balance_to_burn, pairAddress)) {
          IUniswapRouterV2(cv.router).removeLiquidity(cv.token_from, cv.token_to, balance_to_burn, 0, 0, address(this), block.timestamp + 60);
        }
      } 
      
      if(cv.operation & SWAP_LIQUIDITY_FLAG != 0) {

        // Measure the amount to swap from percentage in conversions[] and swap if possible
        uint256 amount_from = IERC20(cv.token_from).balanceOf(address(this)) * cv.percentage / 100;

        if (amount_from > 0) {
          address[] memory path;
          path = new address[](2);
          path[0] = cv.token_from;
          path[1] = cv.token_to;

          // Calculate tokens to be returned from conversion and swap if the amount out will be greater than 0
          uint256[] memory amounts_out = IUniswapRouterV2(cv.router).getAmountsOut(amount_from, path);
          if(amounts_out[1] > 0) {
            amounts_out = IUniswapRouterV2(cv.router).swapExactTokensForTokens(amount_from, 0, path, address(this), block.timestamp + 60);
            emit FundsConverted(path[0], path[1], amount_from, amounts_out[1]);
          } else {
            return;
          }
        } else {
          return;
        }
      }
      
      if (cv.operation & ADD_LIQUIDITY_FLAG != 0) {

        uint256 token_from_balance = IERC20(cv.token_from).balanceOf(address(this));
        uint256 token_to_balance   = IERC20(cv.token_to).balanceOf(address(this));

        // Add liquidity only if we have some amount of both tokens
        if (token_from_balance > 0 && token_to_balance > 0) {
          IUniswapRouterV2(cv.router).addLiquidity(cv.token_from, cv.token_to, token_from_balance, token_to_balance, 0, 0, address(this), block.timestamp + 60);
        }
      }
    }
  }
  
  function remove_liquidity_would_return_zero(uint256 balance_to_burn, address _pair_address) internal view returns (bool) {
    (uint256 balance0, uint256 balance1, uint256 blocktime) = IUniswapV2Pair(_pair_address).getReserves();
    uint256 totalSupply = IUniswapV2Pair(_pair_address).totalSupply();
    uint256 amount0 = balance_to_burn * balance0 / totalSupply;
    uint256 amount1 = balance_to_burn * balance1 / totalSupply;


    return (amount0 == 0 || amount1 == 0);
  }  

  // Read a Conversion item into memory for efficient lookup
  function get_conversion(uint256 i) internal view returns (Conversion memory cv) {
    return Conversion({
      router:      conversions[i].router,
      token_from:  conversions[i].token_from,
      token_to:    conversions[i].token_to,
      percentage:  conversions[i].percentage,
      operation:        conversions[i].operation
    });
  }

  // Governance transfer
  function propose_governance(address to) external {
    require(msg.sender == governance, "must be governance");
    require(to != address(0), "can't set to 0");
    new_governance = to;
  }

  // Governance transfer
  function accept_governance() external {
    require(msg.sender == new_governance, "must be new governance");
    governance = msg.sender;
    new_governance = address(0);
  }

  // Sweep funds in case of emergency
  function sweep_erc(address _token, address _to) external {
    require(msg.sender == governance, "must be governance");
    IERC20 token = IERC20(_token);
    uint256 token_balance = token.balanceOf(address(this));
    emit ErcSwept(msg.sender, _to, _token, token_balance);
    token.transfer(_to, token_balance);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFossilFarms {
  function userInfo(uint256 _pid, address _user) external view returns (uint256);
  function pendingDino(uint256 _pid, address _user) external view returns (uint256);
  function deposit(uint256 _pid, uint256 _amount) external;
  function withdraw(uint256 _pid, uint256 _amount) external;
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

    constructor() {
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
    function factory() external pure returns (address);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Pair {
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function totalSupply() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}