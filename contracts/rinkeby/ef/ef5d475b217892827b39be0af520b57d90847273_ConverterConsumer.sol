/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^0.8.1;

interface IConverter{
    
    function stringToUint(string memory s) external pure returns (uint256);
    
}

contract ConverterConsumer{
    
    IConverter private _converter;
    
    constructor(address converterAddress) {
        _converter = IConverter(converterAddress);
    }
    
    function doMyTest(string memory s) public view returns (uint256) {
        return _converter.stringToUint(s);
    }
}