/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

pragma solidity >0.4.22;

contract Coin {
    address  minter;
    mapping(address => uint) public balances;



    constructor() public {
        minter = msg.sender;
    }


    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }


    function send(address receiver, uint amount) public {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
    }

}