/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity ^0.4.10;

contract BuyCakeSolution {
    mapping(address => uint) public balances;
    uint public price = 2;
    address owner;

    function constructor() public {
        owner = msg.sender;
    }

    function buyCake(uint _amount) payable public {
        uint total = price * _amount;
        require(total / price == _amount); // prevent overflow

        require(total <= msg.value);
        balances[msg.sender] += _amount;
    }
}