pragma solidity >=0.5.0;

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.3;

import { IFlashSwapResolver } from "./interfaces/IFlashSwapResolver.sol";
import { IUniswapV2Pair } from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

contract FlashSwapAction is IFlashSwapResolver{

    function resolveUniswapV2Call(
        address sender,
        address tokenRequested,
        address tokenToReturn,
        uint256 amountRecived,
        uint256 amountToReturn,
        bytes calldata _data
        ) external payable override{

        ( 
            address target, 
            bytes memory datacall 
        ) = abi.decode(_data, (
                address, bytes
            )
        );

        execute(target, datacall);

    }

    function execute(
        address _target, bytes memory _data
        ) 
        internal
        returns (bytes32 response)
        {

        require(_target != address(0));

        // dynamic call passing ETH value, and where this would be msg.sender
        assembly {

            let succeeded := call(
                sub(gas(), 5000),  // we are passing the remaining gas except for 5000
                _target, // the target contract
                callvalue(), // ETH value sent to this function
                add(_data, 0x20), // pointer to data (the first 0x20 (32) bytes indicates de length)
                mload(_data), // size of data (the first 0x20 (32) bytes indicates de length)
                0, // pointer to store returned data
                32) // size of the memory where will be stored the data (defined 32 bytes fixed)
            response := mload(0)      // load call output
            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }

    }

}

pragma solidity >=0.6.0 <0.8.0;

interface IFlashSwapResolver{

    /**
    @param sender The address who calls IUniswapV2Pair.swap.
    @param tokenRequested The address of the token that was requested to IUniswapV2Pair.swap.
    @param tokenToReturn The address of the token that should be returned to IUniswapV2Pair(msg.sender).
    @param amountRecived The ammount recived of tokenRequested.
    @param amountToReturn The ammount recived of tokenRequested.
    @param _data dataForResolveUniswapV2Call: check FlashSwapProxy.uniswapV2Call documentation
     */
    function resolveUniswapV2Call(
            address sender,
            address tokenRequested,
            address tokenToReturn,
            uint256 amountRecived,
            uint256 amountToReturn,
            bytes calldata _data
            ) external payable;
}