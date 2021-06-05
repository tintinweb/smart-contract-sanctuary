/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

pragma solidity 0.8.2;

contract Test {
    event TestEvent(bytes indexed testbytes, uint128 indexed testuint, bytes testbytesa, uint128 testuinta);
    function testFunc() public {
        bytes memory str = "String that is so so long so so long so so long so so long so so long so so long so so long so so long so so long so so long so so long so so long so so long so so long so so long";
        uint128 num = 123;
        emit TestEvent(str, num, str, num);
    }
}