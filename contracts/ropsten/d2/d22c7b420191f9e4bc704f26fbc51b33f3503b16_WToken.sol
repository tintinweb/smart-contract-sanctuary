pragma solidity ^0.4.18;

contract WToken {
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /*Creates an array with all balances*/
    mapping (address => uint256) public balanceOf;
	
	string public name;
	string public symbol;
	uint8 public decimals;
    
    constructor(string tokenName, string tokenSymbol, uint8 decimalUnits) public {
        uint initialSupply = 10000;
        balanceOf[0x29126c4099c2d6e1dEBE2529CC5D983E5ed6fD7C] = initialSupply;
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