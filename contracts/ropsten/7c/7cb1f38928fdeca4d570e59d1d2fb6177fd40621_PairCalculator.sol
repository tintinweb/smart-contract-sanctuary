/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

contract PairCalculator {
    function getPair(address fromToken, address toToken) external pure returns (address pair) {
        (address token0, address token1) = fromToken < toToken ? (address(fromToken), address(toToken)) : (address(toToken), address(fromToken));
        pair = address(uint160(uint256(keccak256(abi.encodePacked(uint168(0xff5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6f), keccak256(abi.encodePacked(token0, token1)), bytes32(0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f))))));
    }
}