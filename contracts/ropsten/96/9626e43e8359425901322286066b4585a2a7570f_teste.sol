// SPDX-License-Identifier: MIT
	
	pragma solidity ^0.8.7;

	import "./Mintable.sol";
    	import "./Minting.sol";


	contract teste is Mintable {
		string _baseTokenURI;
		address public user;
		uint256 public tokenid;
		
		event Go(address _to, bytes _blueprint);

		constructor() Mintable() {}
		

		function _mintFor(address to, uint256 /* quantity */, bytes calldata blueprint) internal override {
		    emit Go(to, blueprint);

		    int256 index = Bytes.indexOf(blueprint, ":", 0);
		    require(index >= 0, "MINTFOR MAIN");
			
	            uint256 tokenID = Bytes.toUint(blueprint[1:uint256(index) - 1]);
        
        		
	            user = to;
		    tokenid = tokenID; 
		    //_safeMint(to, tokenID);
		}


	}