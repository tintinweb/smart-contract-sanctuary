/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

pragma solidity ^0.5;

// ERC20 contract interface
contract Token {
    function balanceOf(address) public view returns (uint);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract SushiswapFactory {
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

contract SushiswapPair {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
}

contract TheContract {

    function getSupply(address sushiswap) public view returns(address[] memory) {
        uint256 start = 0;
        address[] memory result;
        
        
        while(start < 1 ) {
            result[start] = SushiswapFactory(sushiswap).allPairs(start);
            start++;
        }
        
        return result;
    }

}