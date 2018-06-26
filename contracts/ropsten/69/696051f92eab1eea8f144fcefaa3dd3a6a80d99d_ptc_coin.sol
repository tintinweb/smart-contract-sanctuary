pragma solidity ^0.4.23;

contract ptc_coin {
    /* Public variables of the token */
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor (uint256 _supply, string _name, string _symbol) public {
        /* if supply not given then generate 1 million of the smallest unit of the token */
    
        /* Unless you add other functions these variables will never change */
        totalSupply = _supply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = _name;
        symbol = _symbol;

        /* If you want a divisible token then add the amount of decimals the base unit has  */
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public{
        /* if the sender doenst have enough balance then stop */
        require (balanceOf[msg.sender] >= _value);
        require (balanceOf[_to] + _value >= balanceOf[_to]);

        /* Add and subtract new balances */
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        /* Notifiy anyone listening that this transfer took place */
        emit Transfer(msg.sender, _to, _value);
    }
}