/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity =0.6.6;

contract UniswapV2Pair4124{


    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = 0;
        _reserve1 = 0;
        _blockTimestampLast = 0;
    }


  // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address token0, address token1) public pure returns (address pair) {

        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }


}