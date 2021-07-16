//SourceUnit: Mobility.sol

pragma solidity ^0.5.0;

import './TRC20.sol';

contract Mobility {

	event MobilityTransfer(address indexed from, address indexed to, uint256 tetherValue, uint256 saltValue);

	function sendToken(address _tetherTokenAddress,address _saltTokenAddress, address _to, uint256 _tetherValue, uint256 _saltValue ) public returns (bool) {
		require(_to != address(0));
		
		// transferFrom tetherToken
		TRC20 tetherToken = TRC20(_tetherTokenAddress);
		assert(tetherToken.transferFrom(msg.sender, _to, _tetherValue) == true);
		
		// transferFrom saltToken
		TRC20 saltToken = TRC20(_saltTokenAddress);
		assert(saltToken.transferFrom(msg.sender, _to, _saltValue) == true);
		
		emit MobilityTransfer(msg.sender, _to, _tetherValue, _saltValue);
		return true;
	}
}


//SourceUnit: TRC20.sol

pragma solidity ^0.5.0;

contract TRC20 {
  function transferFrom( address from, address to, uint value) public returns (bool);
}