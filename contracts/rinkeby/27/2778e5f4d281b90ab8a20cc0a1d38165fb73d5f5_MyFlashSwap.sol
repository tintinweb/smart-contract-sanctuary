pragma solidity ^0.6;

import './IUniswapV2Callee.sol';

import './UniswapInterfaces.sol';

contract MyFlashSwap is IUniswapV2Callee {
    // CONSTANTS
    IUniswapV2Factory public uniswapV2Factory;
    address owner;

    constructor() public {
        owner = msg.sender;
        // Same for all networks
        uniswapV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    }
    event TOKEN_BALNACE(address addr, uint amount);
    
    function run (
        address token0,
        address token1,
        uint amount0,
        uint amount1
    ) external {
        address pairAddress = uniswapV2Factory.getPair(token0, token1);
        require(pairAddress != address(0), 'This pool does not exist');

        IUniswapV2Pair(pairAddress).swap(
          amount0,
          amount1,
          address(this), 
          bytes('not empty')
        );
    }

    receive() external payable {}

    // Only for test.
    function uniswapV2Call(
        address _sender,
        uint _amount0,
        uint _amount1,
        bytes calldata _data
    ) external override {
        address[] memory path = new address[](2);
        uint amountRequired = 2;
        uint amountToken = _amount0 == 0 ? _amount1 : _amount0;

        // scope for token{0,1}, avoids stack too deep errors
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        // ensure that msg.sender is actually a V2 pair
        require(msg.sender == uniswapV2Factory.getPair(token0, token1), 'Unauthorized');
        // this strategy is unidirectional
        assert(_amount0 == 0 || _amount1 == 0);
        
        path[0] = _amount0 == 0 ? token0 : token1;
        path[1] = _amount0 == 0 ? token1 : token0;
        
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));

        emit TOKEN_BALNACE(token0, balance0);
        emit TOKEN_BALNACE(token1, balance1);

        require(balance0 >= amountRequired || balance1 >= amountRequired, 'Not insufficient tokens');
        

        IERC20 otherToken = IERC20(_amount0 == 0 ? token0 : token1);
        otherToken.approve(tx.origin, amountRequired);
        otherToken.transfer(tx.origin, amountRequired);
    }
    
    function kill() public payable {
        require(msg.sender == owner);
        selfdestruct(msg.sender);
    }
}