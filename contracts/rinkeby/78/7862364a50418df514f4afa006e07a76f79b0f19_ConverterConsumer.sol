/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^0.4.26;

interface IConverter{
    
    function stringToUint(string s) external pure returns (uint256);
    
}

contract ConverterConsumer{
    
    IConverter private _converter;
    
    constructor(address converterAddress) public {
        _converter = IConverter(converterAddress);
    }
    
    function doMyTest(string s) public view returns (uint256) {
        return _converter.stringToUint(s);
    }
}