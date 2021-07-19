//SourceUnit: btt.sol

pragma solidity >= 0.5.0;

contract BTT
{
  
    event Multisended(uint256 value , address indexed sender);
    event Airdropped(address indexed _userAddress, uint256 _amount);
   
     address public owner;
     
     
       constructor(address ownerAddress) public {
        owner = ownerAddress;  
    }

    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {       
        uint256 i = 0;
		trcToken id=1002000;
        for (i; i < _contributors.length; i++) 
		{
			_contributors[i].transferToken(_balances[i],id);
        }
        emit Multisended(msg.value, msg.sender);
    }
 
	
}