/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

pragma solidity ^0.4.24;
contract class23{
    
    string public string_1;

    event setNumber(string _from);

    constructor() public {
        
    }

    function xx(string x) public returns(string) {

        string_1 = x;
        emit setNumber(string_1);
        return string_1;
    }
    
}