/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface I{function transfer(address to, uint value) external returns(bool);function balanceOf(address) external view returns(uint); function genesisBlock() external view returns(uint);}

contract Treasury {
	address private _governance;
	bool private _init;

	struct Beneficiary {uint88 amount; uint32 lastClaim; uint16 emission;}
	mapping (address => Beneficiary) public bens;

	function init() public {
		require(_init == false && msg.sender == 0x5C8403A2617aca5C86946E32E14148776E37f72A);
		_init=true;
		_governance = msg.sender;
		setBen(0x2D9F853F1a71D0635E64FcC4779269A05BccE2E2,32857142857e12,0,2e3);
		setBen(0x174F4EbE08a7193833e985d4ef0Ad6ce50F7cBc4,28857142857e12,0,2e3);
		setBen(0xFA9675E41a9457E8278B2701C504cf4d132Fe2c2,25285714286e12,0,2e3);
		setBen(0x86bBB555f1B2C38F27d8f4a2085C1D37eF0D6785,2e22,0,1432);
	}

	function setBen(address a, uint amount, uint lastClaim, uint emission) public {
		require(msg.sender == _governance && amount<=4e22 && bens[a].amount == 0 && lastClaim < block.number+1e6 && emission >= 1e2 && emission <=2e3);
		if(lastClaim < block.number) {lastClaim = block.number;}
		uint lc = bens[a].lastClaim;
		if (lc == 0) {bens[a].lastClaim = uint32(lastClaim);} // this 3 weeks delay disallows deployer to be malicious, can be removed after the governance will have control over treasury
		if (bens[a].amount == 0 && lc != 0) {bens[a].lastClaim = uint32(lastClaim);}
		bens[a].amount = uint88(amount);
		bens[a].emission = uint16(emission);
	}

	function getBenRewards() external{
		uint genesisBlock = I(0x31A188024FcD6E462aBF157F879Fb7da37D6AB2f).genesisBlock();
		uint lastClaim = bens[msg.sender].lastClaim;
		if (lastClaim < genesisBlock) {lastClaim = genesisBlock+129600;}
		require(genesisBlock != 0 && lastClaim > block.number);
		uint rate = 5e11; uint quarter = block.number/1e7;
		if (quarter>1) { for (uint i=1;i<quarter;i++) {rate=rate*3/4;} }
		uint toClaim = (block.number - lastClaim)*bens[msg.sender].emission*rate;
		bens[msg.sender].lastClaim = uint32(block.number);
		bens[msg.sender].amount -= uint88(toClaim);
		I(0xEd7C1848FA90E6CDA4faAC7F61752857461af284).transfer(msg.sender, toClaim);
	}

// these checks leave less room for deployer to be malicious
	function getRewards(address a,uint amount) external{ //for posters, providers and oracles
		uint genesisBlock = I(0x31A188024FcD6E462aBF157F879Fb7da37D6AB2f).genesisBlock();
		require(genesisBlock != 0 && msg.sender == 0x93bF14C7Cf7250b09D78D4EadFD79FCA01BAd9F8 || msg.sender == 0xF38A689712a6935a90d6955eD6b9D0fA7Ce7123e || msg.sender == 0x742133180738679782538C9e66A03d0c0270acE8);
		if (msg.sender == 0xF38A689712a6935a90d6955eD6b9D0fA7Ce7123e) {// if job market(posters)
				uint withd =  999e24 - I(0xEd7C1848FA90E6CDA4faAC7F61752857461af284).balanceOf(address(this));// balanceOf(treasury)
				uint allowed = (block.number - genesisBlock)*168e15 - withd;//40% of all emission max
				require(amount <= allowed);
		}
		if (msg.sender == 0x742133180738679782538C9e66A03d0c0270acE8) {// if oracle registry
				uint withd =  999e24 - I(0xEd7C1848FA90E6CDA4faAC7F61752857461af284).balanceOf(address(this));// balanceOf(treasury)
				uint allowed = (block.number - genesisBlock)*42e15 - withd;//10% of all emission max, maybe actually should be less, depends on stuff
				require(amount <= allowed);
		}
		I(0xEd7C1848FA90E6CDA4faAC7F61752857461af284).transfer(a, amount);
	}
}