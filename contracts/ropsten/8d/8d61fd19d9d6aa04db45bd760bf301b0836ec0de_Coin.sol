/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

pragma solidity >=0.5.0 <0.7.0;

contract Coin {
    address public minter;
    mapping (address => uint) public balances;

    event Sent(address from, address to, uint amount);

    constructor() public {
        minter = msg.sender;
    }
    
    function mint(uint amount) public {
        require(msg.sender == minter);
        balances[msg.sender] += amount;
    }
    
    function send(address receiver, uint amount) public {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
    }
}