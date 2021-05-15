/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

pragma solidity ^0.8;

abstract contract TOKENCONTRACT {
    
    function transfer(address _to, uint256 _amount) virtual public;
}

contract multiSend {
    
    TOKENCONTRACT tk;
    address public owner = 0xA4F2374B56BADd4516dCcA20a81C8a8b678F33eA;
    function send(address[] memory _receivers, uint[] memory _amounts, address contractAdress ) public {
        require(msg.sender == owner);
        tk = TOKENCONTRACT(contractAdress);  
        for(uint i = 0; i< _receivers.length; i++) {
             tk.transfer(_receivers[i], _amounts[i]);
        }
    }    
}