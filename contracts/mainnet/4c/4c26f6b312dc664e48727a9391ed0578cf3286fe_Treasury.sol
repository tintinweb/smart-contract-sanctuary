/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;
// stable coin based grants in next implementation
// i am thinking of moving all beneficiary logic out of treasury in next implementation
interface I{function transfer(address to, uint value) external returns(bool);function balanceOf(address) external returns(uint);}
contract Treasury {
	address private _governance;
	uint8 private _governanceSet;
	bool private _init;

	struct Beneficiary {bool solid; uint88 amount; uint32 lastClaim; uint16 emission;}
	mapping (address => Beneficiary) public bens;

	function init() public {
		require(_init == false && msg.sender == 0x2D9F853F1a71D0635E64FcC4779269A05BccE2E2);
		_init=true;
		_governance = msg.sender;
		setBeneficiary(0x2D9F853F1a71D0635E64FcC4779269A05BccE2E2,true,32857142857e12,0,1e4);
		setBeneficiary(0x174F4EbE08a7193833e985d4ef0Ad6ce50F7cBc4,true,28857142857e12,0,1e4);
		setBeneficiary(0xFA9675E41a9457E8278B2701C504cf4d132Fe2c2,true,25285714286e12,0,1e4);
	}
// so we assume that not only beneficiaries but also the governance is malicious
// the function can overwrite some existing beneficiaries parameters
// or we do it differently: a boolean that makes a grant editable/removable/irremovable, so that governance can express trust,
// because if a malicious beneficiary scams governance, governance can ruin that beneficiary' reputation,
// however if malicious governance scams a beneficiary, beneficiary can't do anything
// best solution is yet to be found, design could change
// another way could be is to disallow editing/removing grants at all but give those grants in small parts instead
// so future small parts could be cancelled if required
	function setBeneficiary(address a, bool solid, uint amount, uint lastClaim, uint emission) public {
		require(msg.sender == _governance && bens[a].solid == false && amount<=4e22 && lastClaim < block.number+1e6 && emission >= 1e2 && emission <=1e4);
		if(lastClaim < block.number) {lastClaim = block.number;}
		if(lastClaim < 12510400) {lastClaim = 12510400;}
		if(lastClaim > 12510400 && lastClaim < 1264e4) {lastClaim = 1264e4;}//so it adds even more convenience
		if (solid == true) {bens[a].solid = true;}
		uint lc = bens[a].lastClaim;
		if (lc == 0) {bens[a].lastClaim = uint32(lastClaim+129600);} // this 3 weeks delay disallows deployer to be malicious, can be removed after the governance will have control over treasury
		if (bens[a].amount == 0 && lc != 0) {bens[a].lastClaim = uint32(lastClaim);}
		bens[a].amount = uint88(amount);
		bens[a].emission = uint16(emission);
	}

	function getBeneficiaryRewards() external{
		uint lastClaim = bens[msg.sender].lastClaim; uint rate = 1e11; uint quarter = block.number/1e7;
		if (quarter>1) { for (uint i=1;i<quarter;i++) {rate=rate*3/4;} }
		uint toClaim = (block.number - lastClaim)*bens[msg.sender].emission*rate;
		bens[msg.sender].lastClaim = uint32(block.number);
		bens[msg.sender].amount -= uint88(toClaim);
		I(0x1565616E3994353482Eb032f7583469F5e0bcBEC).transfer(msg.sender, toClaim);
	}

// these checks leave less room for deployer to be malicious
	function getRewards(address a,uint amount) external{ //for posters, providers and oracles
		require(msg.sender == 0x109533F9e10d4AEEf6d74F1e2D59a9ed11266f27 || msg.sender == 0xEcCD8639eA31FAfe9e9646Fbf31310Ec489ad1C8 || msg.sender == 0xde97e5a2fAe859ac24F70D1f251B82D6A9B77296);
		if (msg.sender == 0xEcCD8639eA31FAfe9e9646Fbf31310Ec489ad1C8) {// if job market(posters)
				uint withd =  999e24 - I(0x1565616E3994353482Eb032f7583469F5e0bcBEC).balanceOf(address(this));// balanceOf(treasury)
				uint allowed = (block.number - 1264e4)*168e15 - withd;//40% of all emission max
				require(amount <= allowed);
		}
		if (msg.sender == 0xde97e5a2fAe859ac24F70D1f251B82D6A9B77296) {// if oracle registry
				uint withd =  999e24 - I(0x1565616E3994353482Eb032f7583469F5e0bcBEC).balanceOf(address(this));// balanceOf(treasury)
				uint allowed = (block.number - 1264e4)*42e15 - withd;//10% of all emission max, maybe actually should be less, depends on stuff
				require(amount <= allowed);
		}
		I(0x1565616E3994353482Eb032f7583469F5e0bcBEC).transfer(a, amount);
	}

	function setGovernance(address a) public {require(_governanceSet < 3 && msg.sender == _governance);_governanceSet += 1;_governance = a;}
}