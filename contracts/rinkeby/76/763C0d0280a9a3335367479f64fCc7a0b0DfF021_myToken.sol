/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

pragma solidity ^0.5.16;

contract myToken{
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    string public str="123456";
    
    constructor() public{
                symbol = "HUAWEI";
        name = "HUAWEI CHAI";
        decimals = 18;
        _totalSupply = 12600000000000000000000000000;
    }
    
   function getname() public view returns(string memory)
    {
        return str;
    }
    
    
    function setname(string memory _str) public{
        str=_str;
    }
    
}