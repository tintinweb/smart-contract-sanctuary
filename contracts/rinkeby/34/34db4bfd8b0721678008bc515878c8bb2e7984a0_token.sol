/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

pragma solidity ^0.8.7;
contract token {
    //table of who owns what
    mapping (address=>uint256) public balances;

    constructor() {
        balances[0xcd6D93C666B21073345ACcdAeEf29461ec745DAF]=100;

    }

    function transfer(address _to, uint256 _amount) public {
        // take the caller row in the table and 
        // make sure that msg.sender has _amount
        require(balances[msg.sender] >= _amount,"Insufficient Balance");
        balances[msg.sender]=balances[msg.sender] - _amount;
        // decrease its value by _amount
        balances[_to]=balances[_to] + _amount;
        // take the recipient row and increase it by _amount

    }
}