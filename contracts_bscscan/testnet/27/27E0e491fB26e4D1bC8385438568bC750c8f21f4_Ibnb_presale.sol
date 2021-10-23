pragma solidity ^0.8.0;
// SPDX-License-Identifier: GPL

/// @title $iBNB - presale and autoliq contract.
/// @notice 3 differents quotas -> whitelisted, "public" (ie any non-whitelisted address) and "reserved" for public listing
/// whitelisted and presale are independent quotas.
/// When presale is over (owner is calling concludeAndAddLiquidity), the liquidity quota is
/// paired with appropriate amount of BNB (if not enough BNB, less token then) -> public price is the constraint
/// + a fixed part is transfered to the main token contract as initial reward pool.
/// Claim() is then possible (AFTER the initial liquidity is added).
/// This contract will then remains at least a week, for late claims (it can be then, manually, destruct -> token left
/// are transfered to the dev multisig.

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Ibnb_presale is Ownable {

  using Address for address payable;

  mapping (address => uint256) public amountBoughtBNB;
  mapping (address => uint256) public amountBoughtTokens;

  mapping (address => bool) public whiteListed;

  enum status {
    beforeSale,
    ongoingSale,
    postSale
  }

  status public sale_status;

  uint256 public presale_end_ts;
  uint256 public presale_token_per_BNB = 341272;  //pre-sale price (10% discount from pcs launch price)
  uint256 public whitelist_token_per_BNB = 496395; //whitelisted-sale price (500K/BNB)
  uint256 public public_token_per_BNB = 310247; //public pancake listing

  uint256 public hardcap_whitelist = 293 ether;
  uint256 public hardcap_presale = 500 ether;
  uint256 public hardcap_public = 293 ether;




  uint256 public total_bought;
  uint256 public total_claimed;

  address public lock_lp;

  struct track {
    uint256 whiteQuota;      
    uint256 presaleQuota;    
    uint256 liquidityQuota;
    uint256 sold_in_public; //track the amount bought by non-whitelisted
    uint256 sold_in_whitelist;
  }

  track public Quotas = track(whitelist_token_per_BNB*hardcap_whitelist/10**9,presale_token_per_BNB*hardcap_presale/10**9, public_token_per_BNB*hardcap_public/10**9, 0, 0);
  
  IERC20 public token_interface;
  IUniswapV2Router02 router;
  IUniswapV2Pair pair;

  uint256 public minBuyBNBPrivate = 2 ether;
  uint256 public minBuyBNBPublic = 1 ether;
  uint256 public maxBuyBNB = 5 ether;

  event Buy(address, uint256, uint256);
  event LiquidityTransferred(uint256, uint256);
  event Claimable(address, uint256, uint256);

  modifier beforeSale() {
    require(sale_status == status.beforeSale, "Sale: already started");
    _;
  }

  modifier ongoingSale() {
    require(sale_status == status.ongoingSale, "Sale: already started");
    _;
  }

  modifier postSale() {
    require(sale_status == status.postSale, "Sale: not ended yet");
    _;
  }
  
  /// @dev this contract should be excluded in the main contract
  constructor(address _router, address _token_address, address _lock_lp) {
      router = IUniswapV2Router02(_router);
      require(router.WETH() != address(0), 'Router error');
      IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
      address pair_adr = factory.getPair(router.WETH(), _token_address);
      pair = IUniswapV2Pair(pair_adr);
      require(pair_adr != address(0), 'Pair error');
      lock_lp = _lock_lp;
      token_interface = IERC20(_token_address);
      sale_status = status.beforeSale;
  }

// -- before sale --

  /// @dev retain capacity to whitelist during the sale (ie too much "zombies" not coming)
  function addWhitelist(address[] calldata _adr) external onlyOwner {
    for(uint256 i=0; i< _adr.length; i++) {
      if(whiteListed[_adr[i]] == false) {
        whiteListed[_adr[i]] = true;
      }
    }
  }

  function isWhitelisted() external view returns (bool){
    return whiteListed[msg.sender];
  }

  function saleStatus() external view returns(uint256) {
    return uint256(sale_status);
  }

// -- Presale launch --

  function startSale() external beforeSale onlyOwner {
    token_interface.transferFrom(msg.sender, address(this), Quotas.whiteQuota + Quotas.presaleQuota + Quotas.liquidityQuota);
    sale_status = status.ongoingSale;
  }

// -- Presale flow --

  /// @dev will revert when quotas are emptied
  function tokenLeftForPublicSale() public view returns (uint256) {
    require(Quotas.presaleQuota >= Quotas.sold_in_public, "Public sale: No more token to sell");
    unchecked {
      return Quotas.presaleQuota - Quotas.sold_in_public;
    }
  }

  function tokenLeftForWhitelistSale() public view returns (uint256) {
    require(Quotas.whiteQuota >= Quotas.sold_in_whitelist, "Whitelist: No more token to sell");
    unchecked {
      return Quotas.whiteQuota - Quotas.sold_in_whitelist;
    }
  }

  function minBuyForUser(address _address) public view returns (uint256) {
   return whiteListed[_address]? minBuyBNBPrivate : minBuyBNBPublic;
  }


  function buy() external payable ongoingSale {
    bool whiteListed_adr = whiteListed[msg.sender];
    require(msg.value >= minBuyForUser(msg.sender) , "Sale: Under min amount"); // 1 bnb min (public presale) 2 bnb min (private presale)
    require(amountBoughtBNB[msg.sender] + msg.value <= maxBuyBNB, "Sale: above max amount"); // 5 bnb max

    uint256 amountToken;

    if(whiteListed_adr) {
      amountToken = msg.value * whitelist_token_per_BNB/10**9;
      require(amountToken <= tokenLeftForWhitelistSale(), "Sale: No token left in whitelist");
      Quotas.sold_in_whitelist += amountToken;
    }
    else {
      amountToken = msg.value * presale_token_per_BNB/10**9;
      require(amountToken <= tokenLeftForPublicSale(), "Sale: No token left in presale");
      Quotas.sold_in_public += amountToken;
    }

    amountBoughtBNB[msg.sender] += msg.value;
    amountBoughtTokens[msg.sender] += amountToken;

    total_bought += amountToken;
    emit Claimable(msg.sender, msg.value, amountToken);
  }

  function allowanceLeftInBNB() external view returns (uint256) {
    return maxBuyBNB - amountBoughtBNB[msg.sender];
  }
  
  function amountTokenBought() external view returns (uint256) {
    return amountBoughtTokens[msg.sender];
  }


// -- post sale --

  function claim() external postSale {
    require(amountBoughtBNB[msg.sender] > 0, "0 tokens to claim");
    uint256 amountToken = amountBoughtTokens[msg.sender];
    amountBoughtBNB[msg.sender] = 0;
    total_claimed += amountToken;
    token_interface.transfer(msg.sender, amountToken);
  }

  /// @dev convert BNB received and token left in pool liquidity. LP send to owner.
  ///     Uni Router handles both scenario : existing and non-existing pair
  /// not in postSale scope to avoid having claim and third-party liq before calling it
  /// @param emergency_slippage modify the token amount desired in addLiquidity
  /// @param correcting_ratio bool to trigger the "anti-pool-spam" mechanism (rebalance and atomically sync)
  /// @param left_over_address dest address for leftover BNB (left over token are only withdrawable after a week, for late claimers)
  function concludeAndAddLiquidity( uint256 emergency_slippage, bool correcting_ratio, address left_over_address) external onlyOwner ongoingSale {

    uint256 bnbtoliq = address(this).balance>=hardcap_public ? hardcap_public : address(this).balance;
    IERC20 wbnb = IERC20(pair.token0() == address(token_interface)? pair.token1(): pair.token0());
    uint256 wbnbbalance = wbnb.balanceOf(address(pair));
    if(wbnbbalance> 0 && correcting_ratio) { // pair contract spammed with BNB ?
      uint256 to_add = wbnbbalance * public_token_per_BNB/10**9;
      token_interface.transfer(address(pair), to_add);
      pair.sync();
    }

    uint256 balance_token = token_interface.balanceOf(address(this));

    if(balance_token > Quotas.liquidityQuota) balance_token = Quotas.liquidityQuota; //public capped at Quotas.liquidityQuota

    if(balance_token *10**9 / bnbtoliq >= public_token_per_BNB) { // too much token for BNB
        balance_token = public_token_per_BNB * bnbtoliq/10**9;
      }
      else { // too much BNB for token left
        bnbtoliq = balance_token *10**9 / public_token_per_BNB;
      }
    
    token_interface.approve(address(router), balance_token);
    router.addLiquidityETH{value: bnbtoliq}(
        address(token_interface),
        balance_token,
        balance_token - (balance_token * emergency_slippage / 100),
        bnbtoliq,
        lock_lp, //liquidity tokens are locked
        block.timestamp
    );

    sale_status = status.postSale;
    presale_end_ts = block.timestamp;
    
    payable(left_over_address).sendValue(address(this).balance);

    emit LiquidityTransferred(bnbtoliq, balance_token);
      
  }

/// @dev wait min 1 week after presale ending, for "late claimers", before emptying the contract 
  function finalClosure(address leftover_dest) external onlyOwner postSale {
    require(block.timestamp >= presale_end_ts + 1 weeks, "finalClosure: grace period");

    if(token_interface.balanceOf(address(this)) != 0) {
      token_interface.transfer(leftover_dest, token_interface.balanceOf(address(this)));
    }

    payable(leftover_dest).sendValue(address(this).balance);
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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
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

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}