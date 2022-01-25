/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

pragma solidity 0.8.10;


interface P {
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface Token {
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
}

contract Test {
    address router= 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    function test(uint amount, address[] memory path) external {
        Token(path[0]).approve(router, type(uint256).max);
        Token(path[0]).transferFrom(msg.sender, address(this), amount);
        P(router).swapTokensForExactTokens(
            amount,
            0,
            path,
            msg.sender,
            block.timestamp
        );
    }

    function onContract(uint amount, address[] memory path) external {
        Token(path[0]).approve(router, type(uint256).max);
        Token(path[0]).transferFrom(msg.sender, address(this), amount);
        P(router).swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        Token(path[1]).transfer(msg.sender, Token(path[1]).balanceOf(address(this)));
    }

    function fromAddress(uint amount, address[] memory path) external {
        Token(path[0]).approve(router, type(uint256).max);
        Token(path[0]).transferFrom(msg.sender, address(this), amount);
        P(router).swapExactTokensForTokens(
            amount,
            0,
            path,
            msg.sender,
            block.timestamp
        );
        Token(path[0]).transferFrom(msg.sender, address(this), 1);
    }
}