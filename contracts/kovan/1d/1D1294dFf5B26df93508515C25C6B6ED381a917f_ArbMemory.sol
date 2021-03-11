/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


// 
contract ArbMemory {

	mapping (uint256 => uint256) internal muint;

	function setUint(uint256 id_, uint256 val_) external {
		if (id_ != 0) muint[id_] = val_;
	}

	function getUint(uint256 id_, uint256 val_) external returns (uint num_) {
		if (id_ == 0) {
			num_ = val_;
		}else{
			num_ = muint[id_];
			delete muint[id_];
		}
	}

}