/**
 *Submitted for verification at snowtrace.io on 2022-01-07
*/

pragma solidity ^0.8.6;

interface I{
	function transfer(address to, uint value) external returns(bool);
	function balanceOf(address) external view returns(uint);
	function genesisBlock() external view returns(uint);
	function invested(address a) external returns(uint);
	function claimed(address a) external returns(bool);
	function getNodeNumberOf(address a) external returns(uint);
	function getRewardAmountOf(address a) external returns(uint,uint);
}

contract Treasury {
	address private _governance;
	address private _oracle;
	address private _letToken;
	address private _snowToken;
	address private _snowPresale;
	uint public totalPosters;
	uint public totalAirdrops;
	uint public totBenEmission;
	uint public epochBlock;

	struct Beneficiary {
		uint128 amount;
		uint128 emission;
		uint lastClaim;
	}

	struct Poster {
		uint128 amount;
		uint128 lastClaim;
	}

	struct AirdropRecepient {
		uint128 amount;
		uint128 lastClaim;
	}

	mapping (address => Beneficiary) public bens;
	mapping (address => Poster) public posters;
	mapping (address => AirdropRecepient) public airdrops;
	mapping (address => bool) public snowCheck;
	

	function init() public {
		_governance=msg.sender;
		_letToken = 0x017fe17065B6F973F1bad851ED8c9461c0169c31;////
		_snowPresale = 0x60BA9aAA57Aa638a60c524a3ac24Da91e04cFA5C;
		_snowToken = 0x539cB40D3670fE03Dbe67857C4d8da307a70B305;
	}

	function genesis(uint block) public {
		require(msg.sender == _governance);
		epochBlock = block;
	}

	function setGov(address a)external{
		require(msg.sender==_governance);
		_governance=a;
	}

	function setOracle(address a)external{
		require(msg.sender==_governance);
		_oracle=a;
	}

	function _getRate() internal view returns(uint){
		uint rate = 62e14;////
		//uint quarter = block.number/28e6;////
		//if (quarter>0) {
		//	for (uint i=0;i<quarter;i++) {
		//		rate=rate*4/5;
		//	}
		//}
		return rate;
	}

// ADD
	function addBen(address a, uint amount, uint lastClaim, uint emission) public {
		require(msg.sender == _governance && bens[a].amount == 0 && totBenEmission <=1e23);
		if(lastClaim < block.number) {
			lastClaim = block.number;
		}
		uint lc = bens[a].lastClaim;
		if (lc == 0) {
			bens[a].lastClaim = uint64(lastClaim);
		}
		if (bens[a].amount == 0 && lc != 0) {
			bens[a].lastClaim = uint64(lastClaim);
		}
		bens[a].amount = uint128(amount);
		bens[a].emission = uint128(emission);
		totBenEmission+=emission;
	}

	function addAirdropBulk(address[] memory r,uint[] memory amounts) external {
		require(msg.sender == _governance);
		for(uint i = 0;i<r.length;i++) {
			uint prevA = airdrops[r[i]].amount;
			airdrops[r[i]].amount += uint128(amounts[i]);
			if(prevA<1e20&&airdrops[r[i]].amount>=1e20){
				totalAirdrops+=1;
			}
			if(airdrops[r[i]].lastClaim==0){
				airdrops[r[i]].lastClaim=uint128(block.number);
			}
		}
	}

	function addAirdrop(address r,uint amount) public {
		require(msg.sender == _governance);
		_addAirdrop(r,amount);
	}	

	function _addAirdrop(address r,uint amount) private {
		uint prevA = airdrops[r].amount;
		airdrops[r].amount += uint128(amount);
		if(prevA<1e20&&airdrops[r].amount>=1e20){
			totalAirdrops+=1;
		}
		if(airdrops[r].lastClaim==0){
			airdrops[r].lastClaim=uint128(block.number);
		}
	}

	function snowAirdrop() public {
		require(!snowCheck[msg.sender]);
		uint bonus = 0;
		uint balance = 0;
		uint presale = I(_snowPresale).invested(msg.sender);
		if(presale>0){
			bonus +=1;
			if(!I(_snowPresale).claimed(msg.sender)){
				bonus += 2;
				balance = presale;
			}
		}
		uint l = I(_snowToken).getNodeNumberOf(msg.sender);
		if(l>0){
			if(l==presale/10e18) {
				if(bonus<2){bonus += 1;}
				balance += presale;
			} else {
				balance += l*10e18;
			}
		}
		(uint rew,) = I(_snowToken).getRewardAmountOf(msg.sender);
		if(rew>0){
			balance += rew;
		}
		if(I(_snowToken).balanceOf(msg.sender)>0){
			balance += I(_snowToken).balanceOf(msg.sender);
		}
		snowCheck[msg.sender] = true;
		uint amount = balance*4*(10+bonus)/10;
		_addAirdrop(msg.sender,amount);
	}


	function addPosters(address[] memory r, uint[] memory amounts) external{
		require(msg.sender == _oracle);
		for(uint i = 0;i<r.length;i++) {
			uint prevA = posters[r[i]].amount;
			posters[r[i]].amount += uint128(amounts[i]);
			if(prevA<1e20&&posters[r[i]].amount>=1e20){
				totalPosters+=1;
			}
			if(posters[r[i]].lastClaim==0){
				posters[r[i]].lastClaim=uint128(block.number);
			}
		}
	}
// CLAIM
	function getRewards(address a,uint amount) external{ //for staking
		require(epochBlock != 0 && msg.sender == 0x5E31d498c820d6B4d358FceeEaCA5DE8Cc2f0Cbb);//staking
		I(_letToken).transfer(a,amount);//token
	}

	function claimBenRewards() external returns(uint){
		uint lastClaim = bens[msg.sender].lastClaim;
		if (lastClaim < epochBlock) {
			lastClaim = epochBlock;
		}
		require(epochBlock != 0 && block.number>lastClaim);
		uint rate = _getRate();
		rate = rate*bens[msg.sender].emission/1e23;
		uint toClaim = (block.number - lastClaim)*rate;
		if(toClaim>bens[msg.sender].amount){
			toClaim=bens[msg.sender].amount;
		}
		if(toClaim>I(_letToken).balanceOf(address(this))){//this check was supposed to be added on protocol upgrade, emission was so slow, that it could not possibly trigger overflow
			toClaim=I(_letToken).balanceOf(address(this));
		}
		bens[msg.sender].lastClaim = uint64(block.number);
		bens[msg.sender].amount -= uint128(toClaim);
		I(_letToken).transfer(msg.sender, toClaim);
		return toClaim;
	}

	function claimAirdrop()external {
		uint lastClaim = airdrops[msg.sender].lastClaim;
		if(epochBlock>lastClaim){
			lastClaim=epochBlock;
		}
		airdrops[msg.sender].lastClaim=uint128(block.number);
		require(airdrops[msg.sender].amount>0&&epochBlock!=0&&block.number>lastClaim);
		uint toClaim;
		if(airdrops[msg.sender].amount>=1e20){
			uint rate =_getRate()*2;
			toClaim = (block.number-lastClaim)*rate/totalAirdrops;
			if(toClaim>airdrops[msg.sender].amount){
				toClaim=airdrops[msg.sender].amount;
			}
			if(toClaim>I(_letToken).balanceOf(address(this))){
				toClaim=I(_letToken).balanceOf(address(this));
			}
			airdrops[msg.sender].amount -= uint128(toClaim);
			if(airdrops[msg.sender].amount<1e20){
				totalAirdrops-=1;
				if(airdrops[msg.sender].amount==0){
					delete airdrops[msg.sender];
				}
			}
		} else {
			toClaim = airdrops[msg.sender].amount;
			delete airdrops[msg.sender];
		}
		I(_letToken).transfer(msg.sender, toClaim);
    }

	function claimPosterRewards()external {
		uint lastClaim = posters[msg.sender].lastClaim;
		if(epochBlock>lastClaim){
			lastClaim=epochBlock;
		}
		posters[msg.sender].lastClaim=uint128(block.number);
		require(posters[msg.sender].amount>0&&epochBlock!=0&&block.number>lastClaim);
		uint rate=62e14;rate*=2;//////
		uint toClaim =(block.number-lastClaim)*rate/totalPosters;
		if(toClaim>posters[msg.sender].amount){toClaim=posters[msg.sender].amount;}
		if(toClaim>I(_letToken).balanceOf(address(this))){
			toClaim=I(_letToken).balanceOf(address(this));
		}
		posters[msg.sender].amount-=uint128(toClaim);
		I(_letToken).transfer(msg.sender, toClaim);
		if(posters[msg.sender].amount==0){
			totalPosters-=1;
			posters[msg.sender].lastClaim==0;
		}
	}

// IN CASE OF ANY ISSUE
	function removeAirdrops(address[] memory r) external{
		require(msg.sender == _governance);
		for(uint i = 0;i<r.length;i++) {
			if(airdrops[r[i]].amount>=1e20){
				totalAirdrops -=1;
			}
			delete airdrops[r[i]];
		}
	}

	function removePosters(address[] memory r) external{
		require(msg.sender == _oracle);
		for(uint i = 0;i<r.length;i++) {
			if(airdrops[r[i]].amount>=1e20){
				totalPosters -=1;
			}
			delete posters[r[i]];
		}
	}

	function removeBen(address a) public {
		require(msg.sender == _governance);
		totBenEmission-=bens[a].emission;
		delete bens[a];
	}
}