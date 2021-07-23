/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity ^0.4.10;

contract BuyCake {
    mapping(address => uint) public balances;
    uint public price = 2; // to simplify this example we use the wei units
    address owner;

    function constructor() public {
        owner = msg.sender;
    }

    function buyCake(uint _amount) payable public {
        require(price * _amount <= msg.value);

        balances[msg.sender] += _amount;
    }
}