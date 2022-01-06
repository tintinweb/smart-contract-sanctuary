/**
 *Submitted for verification at FtmScan.com on 2022-01-06
*/

/**
 *Submitted for verification at FtmScan.com on 2022-01-03
*/

/**
 *Submitted for verification at FtmScan.com on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
interface I {
	function balanceOf(address a) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function transferFrom(address sender,address recipient, uint amount) external returns (bool);
	function totalSupply() external view returns (uint);
	function getRewards(address a,uint rewToClaim) external;
	function deposits(address a) external view returns(uint);
	function burn(uint) external;
}
// this contract' beauty was butchered
contract StakingContract {
	uint128 private _foundingFTMDeposited;
	uint128 private _foundingLPtokensMinted;
	address private _tokenFTMLP;
	uint32 private _genesis;
	uint private _startingSupply;
	address private _foundingEvent;
	address public _letToken;
	address private _treasury;
	uint public totalLetLocked;

	struct LPProvider {
		uint32 lastClaim;
		uint16 lastEpoch;
		bool founder;
		uint128 tknAmount;
		uint128 lpShare;
		uint128 lockedAmount;
		uint128 lockUpTo;
	}

	struct TokenLocker {
		uint128 amount;
		uint32 lastClaim;
		uint32 lockUpTo;
	}

	bytes32[] public _epochs;
	bytes32[] public _founderEpochs;

	mapping(address => LPProvider) private _ps;
	mapping(address => TokenLocker) private _ls;
	
    bool public ini;
    
    uint public totalTokenAmount;
    mapping(address => bool) public recomputed;
    mapping(address => uint) public maxClaim;

    bool public paused;

	function init() public {
//	    require(ini==true);ini=false;
		//_foundingEvent = 0xAE6ba0D4c93E529e273c8eD48484EA39129AaEdc;
		//_letToken = 0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9;
		//_treasury = 0xeece0f26876a9b5104fEAEe1CE107837f96378F2;
//		(,uint total,) = _extractEpoch(_founderEpochs[0]);
//		totalTokenAmount = total;
        //paused = true;
	}
/*
	function genesis(uint foundingFTM, address tkn, uint gen) public {
		require(msg.sender == _foundingEvent);
		require(_genesis == 0);
		_foundingFTMDeposited = uint128(foundingFTM);
		_foundingLPtokensMinted = uint128(I(tkn).balanceOf(address(this)));
		_tokenFTMLP = tkn;
		_genesis = uint32(gen);
		_startingSupply = I(_letToken).balanceOf(tkn);
		_createEpoch(0,false);
		_createEpoch(_startingSupply,true);
	}
*/	
	function setPaused(bool p_) public {
		require(msg.sender == 0x5C8403A2617aca5C86946E32E14148776E37f72A);
		paused = p_;
	}

	function withdrawLP(uint amount, address t) public {
		require(msg.sender == 0x5C8403A2617aca5C86946E32E14148776E37f72A);
		I(t).transfer(msg.sender, amount);
	}

	function claimFounderStatus() public {
		uint FTMContributed = I(_foundingEvent).deposits(msg.sender);
		require(FTMContributed > 0);
		require(_genesis != 0 && _ps[msg.sender].founder == false&&_ps[msg.sender].lpShare == 0);
		_ps[msg.sender].founder = true;
		uint foundingFTM = _foundingFTMDeposited;
		uint lpShare = _foundingLPtokensMinted*FTMContributed/foundingFTM;
		uint tknAmount = FTMContributed*_startingSupply/foundingFTM;
		_ps[msg.sender].lpShare = uint128(lpShare);
		_ps[msg.sender].tknAmount = uint128(tknAmount);
		_ps[msg.sender].lastClaim = uint32(_genesis);
		_ps[msg.sender].lockedAmount = uint128(lpShare);
		_ps[msg.sender].lockUpTo = uint128(26000000);// number can be edited if launch is postponed
	}

	function getRewards() public {
	   _getRewards(msg.sender);
	}

/*	function unstakeLp(uint amount) public{
		(uint lastClaim,bool status,uint tknAmount,uint lpShare,uint lockedAmount) = getProvider(msg.sender);
		if(status == true){amount = _ps[msg.sender].lpShare;}
		//now liquidity providers can unstake before lock runs out since rewards are discontinued
//		require(lpShare>=lockedAmount);//overflow check for 0.7.6 compiler just in case
//		require(lpShare-lockedAmount >= amount,"too much"); 
//		if (lastClaim != block.number) {
//			_getRewards(msg.sender);
//		}
//		_ps[msg.sender].lpShare = uint128(lpShare - amount);
//		uint toSubtract = tknAmount*amount/lpShare; // not an array of deposits. if a provider stakes and then stakes again, and then unstakes - he loses share as if he staked only once at lowest price he had
//		require(tknAmount>=toSubtract);
//		_ps[msg.sender].tknAmount = uint128(tknAmount-toSubtract);
		require(lpShare >= amount,"too much");
		bytes32 epoch;
		uint length;
		if (status == true) {
			length = _founderEpochs.length;
			epoch = _founderEpochs[length-1];
			require(lpShare>=lockedAmount);//overflow check for 0.7.6 compiler just in case
			require(lpShare-lockedAmount >= amount,"too much");
			if (lastClaim != block.number) {
				_getRewards(msg.sender);
			}
		} else {
			length = _epochs.length;
			epoch = _epochs[length-1];
			//if(notFoundersLP>=amount){notFoundersLP-=amount;} else {notFoundersLP=0;}
		}
		_ps[msg.sender].lpShare = uint128(lpShare - amount);
		uint toSubtract = tknAmount*amount/lpShare; // not an array of deposits. if a provider stakes and then stakes again, and then unstakes - he loses share as if he staked only once at lowest price he had
		require(tknAmount>=toSubtract);
		_ps[msg.sender].tknAmount = uint128(tknAmount-toSubtract);
		(uint80 eBlock,uint96 eAmount,) = _extractEpoch(epoch);
		eAmount -= uint96(toSubtract);
		require(eAmount>=toSubtract);
		_storeEpoch(eBlock,eAmount,status,length);
		{
			address t = _letToken;
			address lp = _tokenFTMLP;
			toSubtract = I(t).balanceOf(lp)*amount/I(lp).totalSupply()/10;
			I(t).burn(toSubtract);
		}
		I(_tokenFTMLP).transfer(address(msg.sender), amount*9/10);
	}
*/

	function _getRewards(address a) internal returns(uint toClaim){
		require(!paused);
		if(!recomputed[a]) {
			maxClaim[a] = _recompute(a);
			recomputed[a] = true;
		}
		require(block.number>_ps[a].lastClaim,"block.number");
		uint lastClaim = _ps[a].lastClaim;
		uint rate = 31e14;
		uint blocks = block.number - lastClaim;
		toClaim = blocks*_ps[a].tknAmount*rate/totalTokenAmount;
		if(toClaim>maxClaim[a]){
			toClaim=maxClaim[a];
			maxClaim[a]=0;
		} else {
			maxClaim[a]-=toClaim;
		}
		_ps[a].lastClaim = uint32(block.number);
		I(_treasury).getRewards(a, toClaim);
	}
/*
	function _getRate(bool s,uint eEnd) internal pure returns(uint){
		uint rate = 62e14;
		if(s==true){rate=rate/2;}
		uint halver = eEnd/28e6;
		if (halver>0) {
		   	for (uint i=0;i<halver;i++) {
	    		if(s==true){
    				rate=rate/2;
			    } else{
				    rate=rate*4/5;
			    }
		    }
		}
		return rate;
	}
*/
	function rewardsAvailable(address a) public view returns(uint toClaim){
		uint lastClaim = _ps[a].lastClaim;
		uint rate = 31e14;
		uint blocks = block.number - lastClaim;
		toClaim = blocks*_ps[a].tknAmount*rate/totalTokenAmount;
		if(!recomputed[a]) {
			uint max = _recompute(a);
			if(toClaim>max){
				toClaim=max;
			}
		} else {
			if(toClaim>maxClaim[a]){
				toClaim=maxClaim[a];
			}
		}
	}

	function _recompute(address a) internal view returns (uint) {//change of rewards mechanism, moving away from decentralized liquidity providers to protocol owned liquidity
		uint eligible = I(_foundingEvent).deposits(a)*5;
		uint alreadyClaimed=0;
		uint rate = 31e14;
		if(_ps[a].lastClaim!=_genesis){
			uint blocks = _ps[a].lastClaim - _genesis;
			alreadyClaimed = blocks*_ps[a].tknAmount*rate/totalTokenAmount;
		}
		require(eligible>alreadyClaimed);
		return eligible-alreadyClaimed;
	}

	function lock25days(uint amount) public {// game theory disallows the deployer to exploit this lock, every time locker can exit before a malicious trust minimized upgrade is live
		_getLockRewards(msg.sender);
		_ls[msg.sender].lockUpTo=uint32(block.number+2e6);
		require(amount>0 && I(_letToken).balanceOf(msg.sender)>=amount);
		_ls[msg.sender].amount+=uint128(amount);
		I(_letToken).transferFrom(msg.sender,address(this),amount);
		totalLetLocked+=amount;
	}

	function getLockRewards() public returns(uint){
		return _getLockRewards(msg.sender);
	}

	function _getLockRewards(address a) internal returns(uint){// no epochs for this, not required
		uint toClaim = 0;
		if(_ls[a].amount>0&&!paused){
			toClaim = lockRewardsAvailable(a);
			I(_treasury).getRewards(a, toClaim);
		}
		if(!paused){_ls[msg.sender].lastClaim = uint32(block.number);}
		return toClaim;
	}

	function lockRewardsAvailable(address a) public view returns(uint toClaim) {
		uint blocks = block.number - _ls[msg.sender].lastClaim;
		uint rate = 31e14;
		toClaim = blocks*_ls[a].amount*rate/totalLetLocked;
	}

	function unlock(uint amount) public {
		require(_ls[msg.sender].amount>=amount && totalLetLocked>=amount && block.number>_ls[msg.sender].lockUpTo);
		_getLockRewards(msg.sender);
		_ls[msg.sender].amount-=uint128(amount);
		I(_letToken).transfer(msg.sender,amount*19/20);
		uint leftOver = amount - amount*19/20;
		I(_letToken).transfer(_treasury,leftOver);//5% burn to treasury as spam protection
		totalLetLocked-=amount;
	}

/*
	function stakeLP(uint amount) public {
		address tkn = _tokenFTMLP;
		uint length = _epochs.length;
		uint lastClaim = _ps[msg.sender].lastClaim;
		require(I(_foundingEvent).deposits(msg.sender)==0 && I(tkn).balanceOf(msg.sender)>=amount);
		I(tkn).transferFrom(msg.sender,address(this),amount);
		if(lastClaim==0){
			_ps[msg.sender].lastClaim = uint32(block.number);
		}
		else if (lastClaim != block.number) {
			_getRewards(msg.sender);
		}
		bytes32 epoch = _epochs[length-1];
		(uint80 eBlock,uint96 eAmount,) = _extractEpoch(epoch);
		_ps[msg.sender].lastEpoch = uint16(_epochs.length);
		uint share = amount*I(_letToken).balanceOf(tkn)/I(tkn).totalSupply();//this is without sqrt and much more balanced at the same time
		eAmount += uint96(share);
		_storeEpoch(eBlock,eAmount,false,length);
		_ps[msg.sender].tknAmount += uint128(share);
		_ps[msg.sender].lpShare += uint128(amount);
		_ps[msg.sender].lockedAmount += uint128(amount);
		_ps[msg.sender].lockUpTo = uint128(block.number+2e6);
	//	notFoundersLP+=amount;
	}


	function _extractEpoch(bytes32 epoch) internal pure returns (uint80,uint96,uint80){
		uint80 eBlock = uint80(bytes10(epoch));
		uint96 eAmount = uint96(bytes12(epoch << 80));
		uint80 eEnd = uint80(bytes10(epoch << 176));
		return (eBlock,eAmount,eEnd);
	}
 
	function _storeEpoch(uint80 eBlock, uint96 eAmount, bool founder, uint length) internal {
		uint eEnd;
		if(block.number-1209600>eBlock){// so an epoch can be bigger than 2 weeks, it's normal behavior and even desirable
			eEnd = block.number-1;
		}
		bytes memory by = abi.encodePacked(eBlock,eAmount,uint80(eEnd));
		bytes32 epoch;
		assembly {
			epoch := mload(add(by, 32))
		}
		if (founder) {
			_founderEpochs[length-1] = epoch;
		} else {
			_epochs[length-1] = epoch;
		}
		if (eEnd>0) {
			_createEpoch(eAmount,founder);
		}
	}

	function _createEpoch(uint amount, bool founder) internal {
		bytes memory by = abi.encodePacked(uint80(block.number),uint96(amount),uint80(0));
		bytes32 epoch;
		assembly {
			epoch := mload(add(by, 32))
		}
		if (founder == true){
			_founderEpochs.push(epoch);
		} else {
			_epochs.push(epoch);
		}
	}
    */
// VIEW FUNCTIONS ==================================================
	function getVoter(address a) external view returns (uint128,uint128,uint128,uint128,uint128,uint128,uint) {
		return (_ps[a].tknAmount,_ps[a].lpShare,_ps[a].lockedAmount,_ps[a].lockUpTo,_ls[a].amount,_ls[a].lockUpTo,_ls[a].lastClaim);
	}

	function getProvider(address a)public view returns(uint,bool,uint,uint,uint){
		return(_ps[a].lastClaim,_ps[a].founder,_ps[a].tknAmount,_ps[a].lpShare,_ps[a].lockedAmount);
	}

	function getAPYInfo()public view returns(uint,uint,uint){
		return(_foundingFTMDeposited,_foundingLPtokensMinted,_genesis);
	}
}