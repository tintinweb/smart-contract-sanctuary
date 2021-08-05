pragma solidity ^0.6.0;

import "./ERC20.sol";

contract MSVToken is ERC20{

    address private minerContractAddr = 0x21031603E69468f439a83f5c4eB893C03c3f866E;
    
    address private nodeLockupContractAddr = 0xcC10ECe0c89aD831A64Db614D90Bc0D8A3cBec1c;
    
    address private ecologicalLockupContractAddr = 0xFC932C3f9366B3ad6143EfB2651324d7967D8001;
    
    address private msvTeamAddr = 0xD48d16c0c842698726d7AF349641bFefB340F6b9;
    
	constructor() ERC20("MSV Token","MSV") public {
		uint8 decimals = 18;
		
		uint256 minerSupply = 20000000 * 10 ** uint256(decimals);
		uint256 nodeSupply = 200000 * 10 ** uint256(decimals);
		uint256 ecologicalSupply = 300000 * 10 ** uint256(decimals);
		uint256 teamSupply = 500000 * 10 ** uint256(decimals);
		
		_setupDecimals(decimals);
		_mint(minerContractAddr, minerSupply);
		_mint(nodeLockupContractAddr, nodeSupply);
		_mint(ecologicalLockupContractAddr, ecologicalSupply);
		_mint(msvTeamAddr, teamSupply);
	}
	
	function burn(uint256 amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

}