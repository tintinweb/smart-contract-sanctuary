// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___        
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_       
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_      
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__     
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____    
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________   
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________  
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________ 
        _______\/////////__\///_______\///__\///////////__\///____________*/

import './ICxipRegistry.sol';

contract CxipProvenanceProxy {

	fallback () payable external {
		address _target = ICxipRegistry (0xC267d41f81308D7773ecB3BDd863a902ACC01Ade).getProvenanceSource ();
		assembly {
			calldatacopy (0, 0, calldatasize ())
			let result := delegatecall (gas (), _target, 0, calldatasize (), 0, 0)
			returndatacopy (0, 0, returndatasize ())
			switch result
				case 0 {
					revert (0, returndatasize ())
				}
				default {
					return (0, returndatasize ())
				}
		}
	}

}