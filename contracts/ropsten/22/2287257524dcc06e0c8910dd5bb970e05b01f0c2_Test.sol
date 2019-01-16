pragma solidity 0.5.1;

contract Test {
    
    address constant private P3X_ADDRESS = address(0xCD45A142d109BBC8b22Ff6028614027D1dB4E32F);
    
    mapping(address => uint256) public p3xBalances;
    
    modifier onlyP3X
    {
        require(msg.sender == P3X_ADDRESS);
        _;
    }
    
	function tokenFallback(address _from, uint256 _value, bytes calldata _data)
	    external
	    onlyP3X
	{
	    p3xBalances[_from]+= _value;
	}
}