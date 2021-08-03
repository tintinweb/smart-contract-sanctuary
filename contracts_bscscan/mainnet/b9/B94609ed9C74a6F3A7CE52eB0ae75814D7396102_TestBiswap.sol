/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

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

interface IPancakePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface PancakeRouter {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IBiswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IBiswapPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface BiswapRouter02 {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
}

interface MasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    
    function withdraw(uint256 _pid, uint256 _amount) external;
}

contract TestBiswap {
    
    address private constant PANCAKE_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address private constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant BISWAP_ROUTER = 0x3a6d8cA21D1CF76F653A67577FA0D27453350dD8;
    address private constant BISWAP_FACTORY = 0x858E3312ed3A876947EA49d572A7C42DE08af7EE;
    address private constant BISWAP_MASTERCHEF = 0xDbc1A13490deeF9c3C12b44FE77b503c1B061739;
    
    address public owner;
    
    event IntLog(string message, uint val);
    event StrLog(string message, address val);
    // Max amount => 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier ownerOnly() {
        require(msg.sender == owner, "You are not contract owner");
        _;
    }
    
    function approveForContract(address _token, address _spender, uint _amount) external ownerOnly {
        IERC20(_token).approve(_spender, _amount);
    }
    
    function balanceOf(address _token, address _address) public view returns (uint) {
        return IERC20(_token).balanceOf(_address);
    }
    
    function allowance(address _token, address _owner, address _spender) public view returns (uint) {
        return IERC20(_token).allowance(_owner, _spender);
    }
    
    function transferBack(address _token, uint _amount) external ownerOnly {
        IERC20(_token).approve(address(this), _amount);
        IERC20(_token).transferFrom(address(this), msg.sender, _amount);
    }
    
    function getPairBiswap(address _tokenA, address _tokenB) public view returns (address) {
        return IBiswapFactory(BISWAP_FACTORY).getPair(_tokenA, _tokenB);
    }
    
    function getToken0Biswap(address _pair) public view returns (address) {
        return IBiswapPair(_pair).token0();
    }
    
    function getToken1Biswap(address _pair) public view returns (address) {
        return IBiswapPair(_pair).token1();
    }
    
    function addLiquidity(address _tokenA, address _tokenB, uint _amountA, uint _amountB) public returns (uint){
        IERC20(_tokenA).approve(BISWAP_ROUTER, _amountA);
        IERC20(_tokenB).approve(BISWAP_ROUTER, _amountB);
        
        (uint amountA, uint amountB, uint liquidity) = BiswapRouter02(BISWAP_ROUTER).addLiquidity(_tokenA, _tokenB, _amountA, _amountB, 1, 1, address(this), block.timestamp);
        emit IntLog("amountA", amountA);
        emit IntLog("amountB", amountB);
        emit IntLog("liquidity", liquidity);
        
        return liquidity;
    }
    
    function removeLiquidity(address _tokenLP, uint _amountLP) public {
        IERC20(_tokenLP).approve(BISWAP_ROUTER, _amountLP);
        BiswapRouter02(BISWAP_ROUTER).removeLiquidity(IBiswapPair(_tokenLP).token0(), IBiswapPair(_tokenLP).token1(), _amountLP, 1, 1, address(this), block.timestamp);
    }
    
    function swapExactTokensForTokens(address _tokenA, address _tokenB, uint _amountIn, uint typeSwap) public {
        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _tokenB;
        if (typeSwap == 1) {
            IERC20(_tokenA).approve(BISWAP_ROUTER, _amountIn);
            BiswapRouter02(BISWAP_ROUTER).swapExactTokensForTokens(_amountIn, 1, path, address(this), block.timestamp);
        } else if (typeSwap == 2) {
            IERC20(_tokenA).approve(PANCAKE_ROUTER, _amountIn);
            PancakeRouter(PANCAKE_ROUTER).swapExactTokensForTokens(_amountIn, 1, path, address(this), block.timestamp);
        }
    }
    
    function swapExactTokensForTokensBiswap(address[] memory _path, uint _amountIn) public {
        require(IERC20(_path[0]).balanceOf(address(this)) >= _amountIn, "No enough balance");
        IERC20(_path[0]).approve(BISWAP_ROUTER, _amountIn);
        BiswapRouter02(BISWAP_ROUTER).swapExactTokensForTokens(_amountIn, 1, _path, address(this), block.timestamp);
    }
    
}