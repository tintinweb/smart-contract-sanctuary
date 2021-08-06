pragma solidity >= 0.5.17;

import "./math.sol";
import "./Manager.sol";
import "./IERC20.sol";

library useDecimal{
    using uintTool for uint;

    function m278(uint n) internal pure returns(uint){
        return n.mul(278)/1000;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

contract cAirDropBatch is Manager{
    using Address for address;

	function() external payable{}
}

contract AirDropPublic is cAirDropBatch, math{
    using Address for address;
    function() external payable{}


    function AirDropBatchToken(address _airdropTokenaddr, uint _airdropAmounts, address[] memory _deliveryAddrs) public returns (bool) {
        uint _addressAmount = _deliveryAddrs.length;
		uint _totalTokenAmount = _airdropAmounts.mul(_addressAmount);
        uint _thisTokenBalance = IERC20(_airdropTokenaddr).balanceOf(msg.sender);
		require((_thisTokenBalance >= _totalTokenAmount), "Not enough tokens.");
		require(IERC20(_airdropTokenaddr).transferFrom(msg.sender, address(this), _totalTokenAmount), "QPool : Value error.");

        for (uint i = 0; i < _addressAmount; i++){
            require(IERC20(_airdropTokenaddr).transfer(_deliveryAddrs[i], _airdropAmounts));
        }
        return true;
    }

	//--Manager only--//
    function takeTokensToManager(address tokenAddr) external onlyManager{
        uint _thisTokenBalance = IERC20(tokenAddr).balanceOf(address(this));
        require(IERC20(tokenAddr).transfer(msg.sender, _thisTokenBalance));
    }
	
	//--Manager only--//
	function destroy() external onlyManager{ 
        selfdestruct(msg.sender); 
	}
}