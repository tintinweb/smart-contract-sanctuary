/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

pragma solidity ^0.4.26;

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract MyContract {
    mapping (address => uint) balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    constructor() public {
        balances[tx.origin] = 10000;
    }
    
    function sendCoin(address receiver, uint amount) public returns(bool success) {
        if (balances[msg.sender] < amount) return false;
        balances[msg.sender] -= amount; // sub(balances[msg.sender], amount) SAFE MATH EXAMPLE
        balances[receiver] += amount; // add(balances[receiver], amount) SAFE MATH EXAMPLE
        emit Transfer(msg.sender, receiver, amount);
        return true;  
    }

    function getBalance(address addr) public view returns(uint) {
        return balances[addr];
    }
}