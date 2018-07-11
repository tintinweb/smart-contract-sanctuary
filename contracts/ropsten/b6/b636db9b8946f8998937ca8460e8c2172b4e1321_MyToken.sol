pragma solidity ^0.4.24;

contract MyToken {
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /*Creates an array with all balances*/
    mapping (address => uint256) public balanceOf;
	
	string public name;
	string public symbol;
	uint8 public decimals;
    
    constructor(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits) public {
        initialSupply = balanceOf[msg.sender];
        name = tokenName;   //allow custom name in constructor func.
        symbol = tokenSymbol; //allow custom token symbol
        decimals = decimalUnits; //allow custom decimal length
    }
    
    function transfer(address _to, uint256 _value) public{
        /* Check if sender has balance and for overflow */
		require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);
        
        /* Add and subtract new balances*/
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
         /*Notify anyone listening that this transfer took place */
        emit Transfer(msg.sender, _to, _value);
    }
}