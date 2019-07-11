/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

pragma solidity ^0.4.24;
contract MyToken {
    /* Public variables of the token */
    string public name;
    string public symbol;
    uint8 public decimals;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(uint256 _supply, string _name, string _symbol, uint8 _decimals) public {
        /* if supply not given then generate 1 million of the smallest unit of the token */
        if (_supply == 0) _supply = 1000000;

        /* Unless you add other functions these variables will never change */
        balanceOf[msg.sender] = _supply;
        name = _name; 
        symbol = _symbol;

        /* If you want a divisible token then add the amount of decimals the base unit has  */
        decimals = _decimals;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        /* if the sender doenst have enough balance then stop */
        if (balanceOf[msg.sender] < _value) {revert();}
        if (balanceOf[_to] + _value < balanceOf[_to]) {revert();}

        /* Add and subtract new balances */
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        /* Notifiy anyone listening that this transfer took place */
        emit Transfer(msg.sender, _to, _value);
    }
}