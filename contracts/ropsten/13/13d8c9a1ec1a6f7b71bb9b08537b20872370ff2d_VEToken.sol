pragma solidity ^0.4.24;

contract VEToken {
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

        /* Initializes contract with initial supply tokens to the creator of the contract */
        function MyToken() public {
        balanceOf[msg.sender] = 100000000;
       
    
     }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                    // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
                /* Notify anyone listening that this transfer took place */
        emit Transfer(msg.sender, _to, _value);

            }
            
string public name;
string public symbol;
uint8 public decimals;

    event Transfer(address indexed from, address indexed to, uint256 value);
}