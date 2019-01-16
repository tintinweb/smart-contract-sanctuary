pragma solidity ^0.4.18;
contract PimpToken{
        event Transfer(address indexed from, address indexed to, uint256 value);
        string public name;
        string public symbol;
        uint8 public decimals;
        /* This creates an array with all balances */
        mapping (address => uint256) public balanceOf;
           function MyToken(uint256 initialSupply) public {
        balanceOf[msg.sender]=initialSupply;
        name="PimpT";
        symbol="PT";
        decimals=2;
    }
        /* Send coins */
    function transfer(address _to, uint256 _value) public {
        /* Notify anyone listening that this transfer took place */
        Transfer(msg.sender, _to, _value);
        /* Check if sender has balance and for overflows */
        require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);

        /* Add and subtract new balances */
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
    }
}