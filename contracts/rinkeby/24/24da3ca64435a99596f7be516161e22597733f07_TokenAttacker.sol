/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

pragma solidity ^0.7.3;

interface IToken {
    function transfer(address _to, uint _value) external returns (bool);
}

contract TokenAttacker {
    IToken public token;
    address public to;

    constructor(IToken _token, address _to) {
        token = IToken(_token);
        to = _to;
    }
    
    function sendBack(uint value) external payable {
        token.transfer(to, value);
    }
    
    receive() external payable {}
}