/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

pragma solidity 0.8.1;

contract WriteDataGasFee{
    string str;
    
    function writeStr(string memory _str) public returns(bool){
        str = _str;
        return true;
    }
    
    function getStr() public view returns(string memory _str){
        _str = str;
    }
}