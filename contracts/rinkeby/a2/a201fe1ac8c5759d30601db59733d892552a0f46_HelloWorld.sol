/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity ^0.8.4;

//Hi, this is a test code

contract HelloWorld{
    string public NuestraVariable ;
    constructor () {
        NuestraVariable = "HelloWorld";
    }
    function setter (string memory _variableTemporaria) public{
        NuestraVariable = _variableTemporaria;
    }
    function getter () public view returns(string memory _result){
    }
}