/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// Copyright 2018 Parity Technologies (UK) Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Example block reward contract.

pragma solidity ^0.4.24;

// Copyright 2018 Parity Technologies (UK) Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// The block reward contract interface.

pragma solidity ^0.4.24;


interface BlockReward {
	// produce rewards for the given benefactors, with corresponding reward codes.
	// only callable by `SYSTEM_ADDRESS`
	function reward(address[] benefactors, uint16[] kind)
		external
		returns (address[], uint256[]);
}



contract METABlockReward is BlockReward {
	address systemAddress;

	modifier onlySystem {
		require(msg.sender == systemAddress);
		_;
	}

	constructor(address _systemAddress)
		public
	{
		/* systemAddress = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE; */
		systemAddress = _systemAddress;
	}

	// produce rewards for the given benefactors, with corresponding reward codes.
	// only callable by `SYSTEM_ADDRESS`
	function reward(address[] benefactors, uint16[] kind)
		external
		onlySystem
		returns (address[], uint256[])
	{
		require(benefactors.length == kind.length);
		uint256[] memory rewards = new uint256[](benefactors.length);

		for (uint i = 0; i < rewards.length; i++) {
			rewards[i] = 1000 + kind[i];
		}

		return (benefactors, rewards);
	}
}