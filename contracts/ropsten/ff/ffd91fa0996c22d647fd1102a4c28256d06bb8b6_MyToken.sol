pragma solidity >=0.4.22 <0.6.0;
       contract MyToken {
           string public name;
string public symbol;
uint8 public decimals;
        /* This creates an array with all balances */
        mapping (address => uint256) public balanceOf;
event Transfer(address indexed from, address indexed to, uint256 value);
 /* Initializes contract with initial supply tokenstokens to the creator of the contract */
    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol, uint8 decimalUnits) public {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
name = tokenName;                           
symbol = tokenSymbol;
decimals = decimalUnits;} 
    function transfer(address _to, uint256 _value) public {
        /* Check if sender has balance and for overflows */
        require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);

        /* Add and subtract new balances */
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        /* Notify anyone listening that this transfer took place */
        emit Transfer(msg.sender, _to, _value);
    }
}