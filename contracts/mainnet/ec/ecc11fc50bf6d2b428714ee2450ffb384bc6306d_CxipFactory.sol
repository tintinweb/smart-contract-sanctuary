/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

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

contract CxipFactory {

	event Deployed (address addr, uint256 salt);

	function deploy (bytes memory code, uint256 salt) public onlyOwner {
		address addr;
		assembly {
			addr := create2 (0, add (code, 0x20), mload (code), salt)
			if iszero (extcodesize (addr)) {
				revert (0, 0)
			}
		}
		emit Deployed (addr, salt);
	}

	event OwnershipTransferred (address indexed previousOwner, address indexed newOwner);

	address private _owner;

	constructor () {
		_setOwner (tx.origin);
	}

	function _msgSender () internal view returns (address) {
		return msg.sender;
	}

	function owner () public view returns (address) {
		return _owner;
	}

	modifier onlyOwner () {
		require (owner () == _msgSender (), 'Ownable: caller is not the owner');
		_;
	}

	function renounceOwnership () public onlyOwner {
		_setOwner (address (0));
	}

	function transferOwnership (address newOwner) public onlyOwner {
		require (newOwner != address (0), 'Ownable: new owner is the zero address');
		_setOwner (newOwner);
	}

	function _setOwner (address newOwner) private {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred (oldOwner, newOwner);
	}

}