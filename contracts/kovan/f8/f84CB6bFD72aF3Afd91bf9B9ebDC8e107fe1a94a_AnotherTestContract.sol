/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

pragma solidity ^0.8.0;

contract AnotherTestContract {
    event AnEvent(uint256 indexed a, address indexed b, string indexed c, uint256 d, address e, string f);
    
    function emitAnEvent(uint256 num, address adr, string memory str) public  {
        emit AnEvent(num, adr, str, num, adr, str);
    }
}