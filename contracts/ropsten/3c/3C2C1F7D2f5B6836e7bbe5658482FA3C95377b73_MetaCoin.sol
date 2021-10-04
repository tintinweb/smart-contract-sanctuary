/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

pragma solidity >=0.4.25 <0.6.0;
contract MetaCoin {
    mapping (address => uint) balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    constructor() public {
               balances[msg.sender] = 10000;
    }

    function sendCoin(address receiver, uint amount) public returns(bool sufficient) {
        if (balances[msg.sender] < amount) return false;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Transfer(msg.sender, receiver, amount);
        return true;
    }
    function getBalance(address addr) public view returns(uint) {
        return balances[addr];
    }
}