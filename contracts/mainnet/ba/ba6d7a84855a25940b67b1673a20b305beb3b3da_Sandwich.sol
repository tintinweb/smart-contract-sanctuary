/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
}

interface IWETH {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);

    function deposit() external payable;
    function withdraw(uint wad) external;
}

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

interface Gastoken {
    function free(uint256 value) external returns (bool success);
    function freeUpTo(uint256 value) external returns (uint256 freed);
    function freeFrom(address from, uint256 value) external returns (bool success);
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
    function mint(uint256 value) external;
}

contract Sandwich {

    address owner = address(0x8C14877fe86b23FCF669350d056cDc3F2fC27029);
    IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor() {}
    receive() external payable {}
    fallback() external payable {}

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function mintGastoken(address gasTokenAddress, uint _amount) external {
        Gastoken(gasTokenAddress).mint(_amount);
    }

    function withdrawERC20(address _token, uint _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function approveMax(address router, address token) external onlyOwner {
        IERC20(token).approve(router, type(uint).max);
    }

    function _swapExactTokensToTokens(
        address gasTokenAddress,
        uint amountToFree,
        address inputToken,
        uint256 inputAmount,
        uint256 minOutAmount,
        address recipient,
        // IUniswapV2Pair[] calldata pairs,
        IUniswapV2Pair p,
        // bool[] calldata whichToken
        bool whichToken
    ) external onlyOwner {
        require(Gastoken(gasTokenAddress).free(amountToFree));
        // Last trade, check for slippage here
        if (whichToken) { // Check what token are we buying, 0 or 1 ?
            // 1
            (uint256 reserveIn, uint256 reserveOut,) = p.getReserves();
            require(IERC20(inputToken).transfer(address(p), inputAmount), "Transfer to pair failed");

            inputAmount = inputAmount * 997; // Calculate after fee
            inputAmount = (inputAmount * reserveOut)/(reserveIn * 1000 + inputAmount); // Calculate outputNeeded
            // require(inputAmount >= minOutAmount, "JRouter: not enough out tokens"); // Checking output amount
            p.swap(0, inputAmount, recipient, ""); // Swapping
        } else {
            // 0
            (uint256 reserveOut, uint256 reserveIn,) = p.getReserves();
            require(IERC20(inputToken).transfer(address(p), inputAmount), "Transfer to pair failed");

            inputAmount = inputAmount * 997; // Calculate after fee
            inputAmount = (inputAmount * reserveOut)/(reserveIn * 1000 + inputAmount); // Calculate outputNeeded
            require(inputAmount >= minOutAmount, "JRouter: not enough out tokens"); // Checking output amount
            p.swap(inputAmount, 0, recipient, ""); // Swapping
        }
    }

    function _swapExactTokensToWETHAndBribe(
        address gasTokenAddress,
        uint amountToFree,
        address inputToken,
        uint256 minOutAmount,
        address recipient,
        IUniswapV2Pair p,
        bool whichToken,
        uint bribeAmount,
        uint bribePercentage
    ) external onlyOwner {
        uint startBalance = weth.balanceOf(address(this));
        require(Gastoken(gasTokenAddress).free(amountToFree));
        // Last trade, check for slippage here
        uint inputAmount = IERC20(inputToken).balanceOf(address(this));
        if (whichToken) { // Check what token are we buying, 0 or 1 ?
            // 1
            (uint256 reserveIn, uint256 reserveOut,) = p.getReserves();
            require(IERC20(inputToken).transfer(address(p), inputAmount), "Transfer to pair failed");

            inputAmount = inputAmount * 997; // Calculate after fee
            inputAmount = (inputAmount * reserveOut)/(reserveIn * 1000 + inputAmount); // Calculate outputNeeded
            // require(inputAmount >= minOutAmount, "JRouter: not enough out tokens"); // Checking output amount
            p.swap(0, inputAmount, recipient, ""); // Swapping
        } else {
            // 0
            (uint256 reserveOut, uint256 reserveIn,) = p.getReserves();
            require(IERC20(inputToken).transfer(address(p), inputAmount), "Transfer to pair failed"); // Breaks on Tether
            // IERC20(inputToken).transfer(address(p), inputAmount);

            inputAmount = inputAmount * 997; // Calculate after fee
            inputAmount = (inputAmount * reserveOut)/(reserveIn * 1000 + inputAmount); // Calculate outputNeeded
            // require(inputAmount >= minOutAmount, "JRouter: not enough out tokens"); // Checking output amount
            p.swap(inputAmount, 0, recipient, ""); // Swapping
        }

        uint balance = weth.balanceOf(address(this));
        uint profit = balance - startBalance - minOutAmount; // This reverts if not profitable
        if (bribeAmount == 0) {
            bribeAmount = profit * bribePercentage / 100;
        }

        require(profit > bribeAmount, "Not enough money to pay bribe"); // however, we may not have enough for the bribe
        weth.withdraw(bribeAmount);
        block.coinbase.call{value: bribeAmount}(new bytes(0));
    }
}