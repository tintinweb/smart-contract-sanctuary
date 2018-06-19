pragma solidity ^0.4.16;
contract HDTTokenTest {

    string public name;
    string public symbol;
    uint8 public decimals;

    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

   
    function HDTTokenTest() public
    {
        balanceOf[msg.sender] = 21000000;
        name =&#39;HDTTokenTest&#39;;
        symbol = &#39;TCC_HDT&#39;;
        decimals = 8;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public returns(bool success) {
        /* if the sender doenst have enough balance then stop */
        if (balanceOf[msg.sender] < _value) return false;
        if (balanceOf[_to] + _value < balanceOf[_to]) return false;

        /* Add and subtract new balances */
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        /* Notifiy anyone listening that this transfer took place */
        Transfer(msg.sender, _to, _value);
    }
}