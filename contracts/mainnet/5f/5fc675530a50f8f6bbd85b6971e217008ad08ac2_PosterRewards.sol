/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface I{
    function getRewards(address a,uint rewToClaim) external returns(bool);
    function balanceOf(address) external view returns(uint);
    function genesisBlock() external view returns(uint);
}
//first implementation, most is off-chain
contract PosterRewards {
	bool private fubuki;
	address private oracle;
	address private deployer;
	struct Poster {uint128 amount; uint128 lastClaim;}
	mapping (address => Poster) public posters;

	function init() public {
		require(fubuki==false);
		fubuki=true; //no reason
		deployer = 0x5C8403A2617aca5C86946E32E14148776E37f72A;
		oracle = 0x5C8403A2617aca5C86946E32E14148776E37f72A;//to change, after giving the oracle different address
	}

	function updatePosters(address[] memory r, uint[] memory amounts) external{//add recipients
		require(msg.sender == oracle);
		for(uint i = 0;i<r.length;i++) {posters[r[i]].amount += uint128(amounts[i]);}
	}

	function getRewards(uint amount)external{
		uint genesisBlock = I(0x31A188024FcD6E462aBF157F879Fb7da37D6AB2f).genesisBlock();
		if(amount>1000e18){amount=1000e18;}
		require(posters[msg.sender].amount>=amount&&posters[msg.sender].lastClaim+1e5<block.number&&genesisBlock != 0);
		uint withd = 9e24 - I(0xEd7C1848FA90E6CDA4faAC7F61752857461af284).balanceOf(0x05658a207a56AA2d6b2821883D373f59Ac6A2fC3);// balanceOf(treasury)
		uint allowed = (block.number - genesisBlock)*84e15 - withd;//only 20% of all emission max. with this additional limit, overflow in treasury is not an issue even before the upgrade
		if (allowed>=amount){
			posters[msg.sender].amount-=uint128(amount);
			posters[msg.sender].lastClaim=uint128(block.number);
			bool success = I(0x05658a207a56AA2d6b2821883D373f59Ac6A2fC3).getRewards(msg.sender, amount); require(success == true);
		}
	}

	function setOracle(address a) public {require(msg.sender==deployer); oracle = a;}

	function getOracleGas(uint amount) public {
		uint genesisBlock = I(0x31A188024FcD6E462aBF157F879Fb7da37D6AB2f).genesisBlock();
		require(msg.sender==oracle&&genesisBlock != 0);
		uint withd = 9e24 - I(0xEd7C1848FA90E6CDA4faAC7F61752857461af284).balanceOf(0x05658a207a56AA2d6b2821883D373f59Ac6A2fC3);// balanceOf(treasury)
		uint allowed = (block.number - genesisBlock)*14e15 - withd;//max ~3.33% of all emission, in case of dumb gas prices and low let price
		if (allowed>=amount){
			bool success = I(0x05658a207a56AA2d6b2821883D373f59Ac6A2fC3).getRewards(msg.sender, amount); require(success == true);
		}
	}
}