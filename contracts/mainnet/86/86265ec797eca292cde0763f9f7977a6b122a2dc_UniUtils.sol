/**
 *Submitted for verification at Etherscan.io on 2020-10-31
*/

pragma solidity ^0.6.0;

// SPDX-License-Identifier: UNLICENSED

interface IUniswapV2Pair
{
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

contract UniUtils
{
    constructor() public
    {
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
          addr := mload(add(bys,20))
        } 
    }
    
    function copy(bytes memory dst, bytes memory src, uint start, uint count) private pure {
        for(uint i = 0; i < count; i++)
        {
            dst[start+i] = src[i];
        }
    }

    function getPackedReserves(bytes calldata pack) external view returns (bytes memory)
    {
        uint count = pack.length/20;
        bytes memory result = new bytes(28*count);
        
        for(uint i = 0; i < count; i++)
        {
            uint s = i*20;
            uint e = s + 20;
            bytes calldata ab = pack[s:e];
            
            address a0 = bytesToAddress(ab);
            
            (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(a0).getReserves();
            
            bytes memory r = abi.encodePacked(reserve0,reserve1);
            copy(result, r, i*28, 28);
        }
        
        return result;
    }
}