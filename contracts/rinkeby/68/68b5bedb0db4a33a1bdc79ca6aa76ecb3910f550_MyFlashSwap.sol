pragma solidity ^0.6;

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
        require(pairAddress != address(0), 'ERR_BORROW: This pool does not exist');

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
        
        uint amountToken = _amount0 == 0 ? _amount1 : _amount0;

        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        require(msg.sender == uniswapV2Factory.getPair(token0, token1), 'ERR_REPAY: Unauthorized');
        require(_amount0 == 0 || _amount1 == 0, 'ERR_REPAY: The strategy is unidirectional');
        
        path[0] = _amount0 == 0 ? token0 : token1;
        path[1] = _amount0 == 0 ? token1 : token0;
        
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        
        require(balance0 >= 0 || balance1 >= 0, "ERR_REPAY: balance >= 0");

        emit TOKEN_BALNACE(token0, balance0);
        emit TOKEN_BALNACE(token1, balance1);

        uint tokenAmount = _amount0 == 0 ? _amount1 : _amount0;
        uint amountRequired = tokenAmount + tokenAmount * 5 / 1000;
        require(balance0 >= amountRequired || balance1 >= amountRequired, 'ERR_REPAY: balance >= amountRequired');

        IERC20 erc20Token = IERC20(_amount0 == 0 ? token1 : token0);
        erc20Token.transfer(msg.sender, amountRequired);
    }
    
    function kill() public payable {
        require(msg.sender == owner);
        selfdestruct(msg.sender);
    }
}