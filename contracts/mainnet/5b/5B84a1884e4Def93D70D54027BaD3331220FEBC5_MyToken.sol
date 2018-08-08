pragma solidity ^0.4.13;

contract MyToken {
    
    string public name = "MyToken";
    string public symbol = "MY";
    uint8 public deicmals = 18;
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    function MyToken() {
        balanceOf[msg.sender] = 20**20;              // Give the creator all initial tokens
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                    // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
    }
}