/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

pragma solidity 0.8.7;

contract Test {
    mapping(address => string) strs;
    
    function changeStr(address _adr, string memory _str) external {
        strs[_adr] = _str;
    }
}