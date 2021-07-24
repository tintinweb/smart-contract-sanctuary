/**
 *Submitted for verification at Etherscan.io on 2021-07-24
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

    // No sstore or sload

    constructor() {}
    receive() external payable {}
    fallback() external payable {}

    modifier onlyOwner {
        require(msg.sender == address(0x8C14877fe86b23FCF669350d056cDc3F2fC27029));
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

    function _swapExactWETHToTokens(
        uint amountToFree,
        uint256 inputAmount,
        uint256 outputAmount,
        IUniswapV2Pair p,
        bool whichToken
    ) external onlyOwner {
        // require(IERC20(inputToken).transfer(address(p), inputAmount), "Transfer to pair failed");
        // inputToken.call(abi.encodeWithSelector(0xa9059cbb, address(p), inputAmount)); // transfer()
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).call(abi.encodeWithSelector(0xa9059cbb, address(p), inputAmount)); // WETH.transfer()
        // Last trade, check for slippage here
        if (whichToken) { // Check what token are we buying, 0 or 1 ?
            // 1
            // p.swap(0, outputAmount, recipient, "");
            address(p).call(abi.encodeWithSelector(0x0902f1ac, 0, outputAmount, address(this), "")); // Pair.swap() - this brought gas down from 86k to 42k. What's happening?
        } else {
            // 0
            // p.swap(outputAmount, 0, recipient, "");
            address(p).call(abi.encodeWithSelector(0x0902f1ac, outputAmount, 0, address(this), "")); // Pair.swap() - this brought gas down from 86k to 42k. What's happening?
        }
        if(amountToFree > 0) {
            // require(Gastoken(0x0000000000b3F879cb30FE243b4Dfee438691c04).free(amountToFree));
            address(0x0000000000b3F879cb30FE243b4Dfee438691c04).call(abi.encodeWithSelector(0xd8ccd0f3, amountToFree)); // GST2.free()
        }
    }

    function _swapExactTokensToWETHAndBribe(
        uint amountToFree,
        address inputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 minOutAmount, // only used if outputAmount is zero
        IUniswapV2Pair p,
        bool whichToken,
        uint bribeAmount,
        uint bribePercentage
    ) external {
        if(amountToFree > 0) {
            address(0x0000000000b3F879cb30FE243b4Dfee438691c04).call(abi.encodeWithSelector(0xd8ccd0f3, amountToFree)); // GST2.free()
        }
        // uint startBalance = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).balanceOf(address(this));
        (, bytes memory data) = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).call(abi.encodeWithSelector(0x70a08231, address(this))); // WETH.balanceOf(address);
        uint startBalance = abi.decode(data, (uint256));
        // Last trade, check for slippage here
        if(inputAmount == 0) {
            // inputAmount = IERC20(inputToken).balanceOf(address(this)) - 1; // Leave 1 token in wallet to prevent storage refund
            (, data) = inputToken.call(abi.encodeWithSelector(0x70a08231, address(this))); // inputToken.balanceOf(address);
            inputAmount = abi.decode(data, (uint256)) - 1;
        } // Might be unexpected if it's a deflationary token. But leave this option
        // require(IERC20(inputToken).transfer(address(p), inputAmount), "Transfer to pair failed");
        // inputToken.call(abi.encodeWithSelector(0x23b872dd, address(this), address(p), inputAmount));
        inputToken.call(abi.encodeWithSelector(0xa9059cbb, address(p), inputAmount)); // inputToken.transfer(address,uint256)

        if(outputAmount == 0) {
            if (whichToken) { // Check what token are we buying, 0 or 1 ?
                // 1
                // (uint256 reserveIn, uint256 reserveOut,) = p.getReserves();
                (, data) = address(p).call(abi.encodeWithSelector(0x0902f1ac));
                (uint256 reserveIn, uint256 reserveOut,) = abi.decode(data, (uint256, uint256, uint32));
                inputAmount = inputAmount * 997; // Calculate after fee
                inputAmount = (inputAmount * reserveOut)/(reserveIn * 1000 + inputAmount); // Calculate outputNeeded
                // p.swap(0, inputAmount, recipient, ""); // Swapping
                address(p).call(abi.encodeWithSelector(0x0902f1ac, 0, inputAmount, address(this), ""));
            } else {
                // 0
                // (uint256 reserveOut, uint256 reserveIn,) = p.getReserves();
                (, data) = address(p).call(abi.encodeWithSelector(0x0902f1ac));
                (uint256 reserveOut, uint256 reserveIn,) = abi.decode(data, (uint256, uint256, uint32));
                inputAmount = inputAmount * 997; // Calculate after fee
                inputAmount = (inputAmount * reserveOut)/(reserveIn * 1000 + inputAmount); // Calculate outputNeeded
                // p.swap(inputAmount, 0, recipient, ""); // Swapping
                address(p).call(abi.encodeWithSelector(0x0902f1ac, inputAmount, 0, address(this), ""));
            }
        } else {
            if (whichToken) {
                // p.swap(0, outputAmount, recipient, "");
                address(p).call(abi.encodeWithSelector(0x0902f1ac, 0, outputAmount, address(this), ""));
            } else {
                // p.swap(outputAmount, 0, recipient, "");
                address(p).call(abi.encodeWithSelector(0x0902f1ac, outputAmount, 0, address(this), ""));
            }
        }

        // uint balance = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).balanceOf(address(this));
        (, data) = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).call(abi.encodeWithSelector(0x70a08231, address(this))); // WETH.balanceOf(address);
        uint balance = abi.decode(data, (uint256));
        // uint balance = abi.decode(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).call(abi.encodeWithSelector(0x70a08231, address(this)))[1], (uint256));
        uint profit = balance - startBalance - minOutAmount; // This reverts if not profitable
        if (bribeAmount == 0) {
            bribeAmount = profit * bribePercentage / 100;
        }

        // Should remove this equals sign, but helpful for testing when there's nothing to sandwich
        require(profit >= bribeAmount, "Not enough money to pay bribe"); // however, we may not have enough for the bribe
        // IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).withdraw(bribeAmount);
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).call(abi.encodeWithSelector(0x2e1a7d4d, bribeAmount)); // WETH.withdraw(uint256);
        block.coinbase.call{value: bribeAmount}(new bytes(0));
    }
}