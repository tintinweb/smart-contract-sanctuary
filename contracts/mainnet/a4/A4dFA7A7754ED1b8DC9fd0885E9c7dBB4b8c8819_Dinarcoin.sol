pragma solidity ^0.4.24;
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
	require(a>=0);
	require(b>=0);		
        c = a + b;
	require(c >= a);

    }
    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
	require(a>=0);
	require(b>=0);	
        require(b <= a);
        c = a - b;
    }
   
}


contract Dinarcoin is SafeMath {
    mapping (address => uint256) public balanceOf;

    string public name;
    string public symbol;
    uint8 public decimals=18;
    uint256 public totalSupply;
    
    event Transfer( address indexed from, address indexed to, uint256 value);

    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
	uint8 decimal) public {
        totalSupply = initialSupply * 10 ** uint256(decimal);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;      
    }

    /* Send coins */
    function _transfer(address _from, address _to, uint256 _value) internal {
	require(_to!=0x0);
	require(_value>0);
        require(balanceOf[msg.sender] >= _value); 
        require(balanceOf[_to] + _value >= balanceOf[_to]); 
        uint256 previousBalances=balanceOf[_from] + balanceOf[_to];
        balanceOf[msg.sender] =safeSub(balanceOf[msg.sender], _value); 
        balanceOf[_to] =safeAdd(balanceOf[_to], _value); 
	emit Transfer(_from, _to, _value);
	assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        
    }
	function transfer(address _to, uint256 _value) public returns (bool success){

	_transfer(msg.sender, _to, _value);
	return true;
	}

}