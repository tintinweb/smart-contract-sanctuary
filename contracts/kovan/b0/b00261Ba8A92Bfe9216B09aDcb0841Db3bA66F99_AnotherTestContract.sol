/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

pragma solidity ^0.8.0;

contract AnotherTestContract {
    event AnEvent(uint256 indexed a, address indexed b, string indexed c, uint256 d, address e, string f);
    
    event PoolCreated (address indexed token0, address indexed token1, uint24 indexed fee, int24 tickSpacing, address pool);
    
    function emitAnEvent(uint256 num, address adr, string memory str) public {
        emit AnEvent(num, adr, str, num, adr, str);
    }
    
    function emitPoolCreatedEvent(uint24 num, address adr, int24 num1) public {
        emit PoolCreated(adr, adr, num, num1, adr);
    }
}