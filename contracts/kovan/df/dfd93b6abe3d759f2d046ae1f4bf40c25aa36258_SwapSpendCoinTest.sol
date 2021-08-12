/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity >=0.8.0;

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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


interface IUniswapV2Router {
    function getAmountsIn(uint amountOut, address[] memory path) external view  returns (uint[] memory amounts);

  
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

  
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


interface IUniswapV2Factory {
  function getPair(address token0, address token1) external view returns (address);
}

/** @author SpendCoin Wild Team
  * @title SwapSpendCoin.
  * @dev Swap any token into USDC
  */
contract SwapSpendCoinTest {
    
    address private constant addressTokenOut = 0x67BeF77Fef6D7bbF0fE14723E017c2fda1634Ef8; // WCS (change for USDC)
    //address private constant eny = 0x5161C0F8D8F8721eE30E7d5aBb273c6DA1A554ff; JUST A MEMO
    
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    
    // Change to WMATIC for polygon
    address private constant WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C; 

    // Change to SpendCoin address
    address private constant RECEIVE_ADDRESS = 0xFD31839B5eabB91D88CbBb9e481e9d13ca469A1e; // (chris's address) 
    
    /** @dev Swap any token to USDC using UNISWAP_V2_ROUTER and send USDC to RECEIVE_ADDRESS.
      * @param _tokenIn The token to swap into USDC.
      * @param _amountOut The amount of USDC needed
      */
    function swapToken(address _tokenIn, uint _amountOut) public {
        address tokenOut = addressTokenOut;
        
        uint amountInMax = getAmountInMax(_tokenIn, addressTokenOut, _amountOut);
        
        // Penser a approve le contrat sur le _tokenIn pour chaque nouvel utilisateur
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), amountInMax);
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, amountInMax);
        
        
        address[] memory path = new address[](3);
        path[0] = _tokenIn;
        path[1] = WETH;
        path[2] = tokenOut;
        
        IUniswapV2Router(UNISWAP_V2_ROUTER).swapTokensForExactTokens(_amountOut, amountInMax, path, RECEIVE_ADDRESS, block.timestamp);
        
    }
    
    /** @dev Swap ETH or MATIC to USDC using UNISWAP_V2_ROUTER and send USDC to RECEIVE_ADDRESS.
      * @param _amountOut The amount of USDC needed
      * @notice the msg.value must be egal to the amount return by the function getAmountInMax().
      */
    function swapETH(uint _amountOut) public payable {

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = addressTokenOut;
            
        IUniswapV2Router(UNISWAP_V2_ROUTER).swapETHForExactTokens{value: msg.value}(_amountOut, path, RECEIVE_ADDRESS, block.timestamp);
    }

  
     /** @dev Get the amount max of token to swap.
       * @param _tokenIn The token to swap.
       * @param _tokenOut The token to receive.
       * @param _amountOut The amount of USDC needed.
       * @return the amount of token to swap, or the amount of ETH to send.
       */
    function getAmountInMax(address _tokenIn, address _tokenOut, uint _amountOut) public view returns (uint) {
        
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
          path = new address[](2);
          path[0] = _tokenIn;
          path[1] = _tokenOut;
        } else {
          path = new address[](3);
          path[0] = _tokenIn;
          path[1] = WETH;
          path[2] = _tokenOut;
        }

        // same length as path
        uint[] memory amountInMax =
          IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsIn(_amountOut, path);
    
        return amountInMax[0];
    }

    // Get the pair address of a pair of tokens
    function getPair(address _token0, address _token1) external view returns (address) {
        return IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(_token0, _token1);
    }
    
    // Get the reserve of tokens in a pair via the pair address
    function getReserves(address _pairAddress) public view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
        return IUniswapV2Pair(_pairAddress).getReserves();
    }
    
}