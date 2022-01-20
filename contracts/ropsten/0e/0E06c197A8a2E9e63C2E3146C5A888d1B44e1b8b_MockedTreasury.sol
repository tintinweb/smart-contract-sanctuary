// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";


contract MockedTreasury {

    address public tokenA;
    address public tokenB;

    constructor (address _tokenA, address _tokenB) {
        (tokenA, tokenB) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
    }

    function getReserves() public view returns (uint amountA, uint amountB, uint32 blockTimestampLast) {
        amountA = IERC20(tokenA).balanceOf(address(this));
        amountB = IERC20(tokenB).balanceOf(address(this));
        blockTimestampLast = uint32(block.timestamp);
    }

    function transfer() external payable {}

    function withdraw(address to, uint amountA, uint amountB) external {
        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}