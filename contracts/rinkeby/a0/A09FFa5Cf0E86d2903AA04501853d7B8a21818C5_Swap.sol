// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IUniswapV2Router02.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Pair.sol';
import './IERC20.sol';
import './SafeMath.sol';

contract Swap {

    using SafeMath for uint;
    
    uint constant deadline = 10;
    IUniswapV2Router02 public router; // used to get quotes and execute trades on DEX
    IUniswapV2Factory public factory;
    mapping(address => bool) public admins; // admins
    
    constructor(address _router, address[] memory _admins) {
        for (uint i = 0; i < _admins.length; i++) {
            admins[_admins[i]] = true;
        }
        router = IUniswapV2Router02(_router); // pointer to router contract
        factory = IUniswapV2Factory(router.factory()); // pointer to factory contract
    }
    
    function resetRouter(address _router) onlyAdmin() external returns(bool) {
        router = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(router.factory());
        return true;
    }
    
    function getQuote(address token0, address token1, uint amount) onlyAdmin() poolExists(token0, token1) public view returns(uint[] memory) {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        uint[] memory quote = router.getAmountsOut(amount, path);
        return quote;
    }
    
    function swapEthForTokens(address token, uint amount, uint slippage) onlyAdmin() poolExists(router.WETH(), token) external returns(uint) {
        require(IERC20(router.WETH()).balanceOf(msg.sender) > amount, 'insuffient balance');
        IERC20(router.WETH()).transferFrom(msg.sender, address(this), amount); // transfer to contract
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = token;
        IERC20(router.WETH()).approve(address(router), amount); // approve contract
        uint amountRequired = getQuote(router.WETH(), token, amount)[1].mul(1 - slippage.div(100));
        uint amountReceived = router.swapExactETHForTokens(
            amountRequired,
            path,
            msg.sender,
            deadline
        )[1];
        IERC20(token).transfer(msg.sender, amountReceived);
        return amountReceived;
    }
    
    function swapTokensForEth(address token, uint amount, uint slippage) onlyAdmin() poolExists(router.WETH(), token) external returns(uint) {
        require(IERC20(token).balanceOf(msg.sender) > amount, 'insuffient balance');
        IERC20(token).transferFrom(msg.sender, address(this), amount); // transfer to contract
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = router.WETH();
        IERC20(token).approve(address(router), amount); // approve contract
        uint amountRequired = getQuote(token, router.WETH(), amount)[1].mul(1 - slippage.div(100));
        uint amountReceived = router.swapExactTokensForETH(
            amount,
            amountRequired,
            path,
            msg.sender,
            deadline
        )[1];
        IERC20(token).transfer(msg.sender, amountReceived);
        return amountReceived;
    }
    
    function checkLiquidity(address token0, address token1) onlyAdmin() poolExists(token0, token1) external view returns(uint[] memory) {
        address pairAddress = factory.getPair(token0, token1);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        uint[] memory liquidity = new uint[](3);
        (uint reserve0, uint reserve1,) = pair.getReserves();
        uint totalSupply = pair.totalSupply();
        
        liquidity[0] = reserve0;
        liquidity[1] = reserve1;
        liquidity[2] = totalSupply;
        
        return liquidity;
    }
    
    modifier onlyAdmin () {
        require(admins[msg.sender] == true, 'only admins allowed');
        _;
    }
    
    modifier poolExists(address token0, address token1) {
        address pairAddress = factory.getPair(token0, token1);
        require(pairAddress != address(0), 'pool does not exist');
        _;
    }
}