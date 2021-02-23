/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// Standard ERC-20 interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface GasToken {
    function mint(uint256 value) external;
    function free(uint256 value) external returns (bool success);
    function freeUpTo(uint256 value) external returns (uint256 freed);
    function freeFrom(address from, uint256 value) external returns (bool success);
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

//https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
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

//https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IWETH.sol
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract Whitelist {
    mapping(address=>bool) whitelist;
    constructor (address initOwner) {
        whitelist[initOwner] = true;
    }
    modifier onlyWhitelist() {
        require(whitelist[msg.sender] == true, "not in whitelist");
        _;
    }
    function addToWhitelist(address newAddress) external onlyWhitelist() {
        require(whitelist[newAddress] == false, "already in whitelist");
        whitelist[newAddress] = true;
    }
}

contract GasTokenSwitcherV2 is Whitelist(tx.origin) {

    receive() external payable {
    }

    //transfers ETH from this contract
    function transferETH(address payable dest, uint256 amount) external onlyWhitelist() {
        dest.transfer(amount);
    }

    //transfers ERC20 from this contract
    function transferERC20(address tokenAddress, uint256 amountTokens, address dest) external onlyWhitelist() {
        IERC20(tokenAddress).transfer(dest, amountTokens);
    }

    modifier discountGasToken(address burnToken) {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        GasToken(burnToken).freeUpTo((gasSpent + 14154) / 41130);
    }

    function mintAndBurn(address burnToken, address mintToken, uint256 newTokens)
        external onlyWhitelist() discountGasToken(burnToken) {
        GasToken(mintToken).mint(newTokens);
    }

    function burnMintSellChi(address burnToken, uint256 newTokens)
        external onlyWhitelist() discountGasToken(burnToken) {
        //mint CHI
        GasToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c).mint(newTokens);
        //CHI is token0 for the UniV2 ETH-CHI pool at 0xa6f3ef841d371a82ca757FaD08efc0DeE2F1f5e2
        //emulate UniV2 getAmountOut functionality
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(0xa6f3ef841d371a82ca757FaD08efc0DeE2F1f5e2).getReserves();
        uint amountInWithFee = (newTokens * 997);
        uint numerator = (amountInWithFee * reserve1);
        uint denominator = (reserve0 * 1000) + amountInWithFee;
        uint amountOut = numerator / denominator;
        //transfer new CHI to UniV2 pool
        IERC20(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c).transfer(0xa6f3ef841d371a82ca757FaD08efc0DeE2F1f5e2, newTokens);
        //get the appropriate amount out in WETH
        IUniswapV2Pair(0xa6f3ef841d371a82ca757FaD08efc0DeE2F1f5e2).swap(newTokens, amountOut, address(this), new bytes(0));
        //withdraw the WETH -- UniV2 uses WETH at 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).withdraw(amountOut);
    }

    function burnAndDeploy(address burnToken, bytes memory data)
        external onlyWhitelist() discountGasToken(burnToken) returns(address contractAddress) {
        assembly {
            contractAddress := create(0, add(data, 32), mload(data))
        }
    }

    function sendBatchedTransaction (address[] calldata dest, uint256[] calldata eth, bytes[] calldata hexData)
        external onlyWhitelist() {
        require(dest.length == eth.length && dest.length == hexData.length, "unequal input lengths");
        for(uint256 i = 0; i < hexData.length; i++) {
            (bool success,) = dest[i].call{value:eth[i]}(hexData[i]);
            if (!success) revert("internal call failed");
        }
    }

    function discountBatchedTransaction (address burnToken, address[] calldata dest, uint256[] calldata eth, bytes[] calldata hexData)
        external onlyWhitelist() discountGasToken(burnToken) {
        require(dest.length == eth.length && dest.length == hexData.length, "unequal input lengths");
        for(uint256 i = 0; i < hexData.length; i++) {
            (bool success,) = dest[i].call{value:eth[i]}(hexData[i]);
            if (!success) revert("internal call failed");
        }
    }
}