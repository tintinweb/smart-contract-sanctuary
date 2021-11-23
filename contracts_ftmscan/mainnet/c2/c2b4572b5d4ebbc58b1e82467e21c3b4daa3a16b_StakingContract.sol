/**
 *Submitted for verification at FtmScan.com on 2021-11-22
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
	//bool public ini;

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

	function init() public {
	    //require(ini==false);ini=true;
		//_foundingEvent = 0xAE6ba0D4c93E529e273c8eD48484EA39129AaEdc;
		//_letToken = 0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9;
		//_treasury = 0xeece0f26876a9b5104fEAEe1CE107837f96378F2;
		//_ls[0xCe4F32750BcC4B3d07Cf824467A66B5227c0A6db].lastClaim = 22754402;
	}

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

	function unstakeLp(uint amount) public{
		(uint lastClaim,bool status,uint tknAmount,uint lpShare,uint lockedAmount) = getProvider(msg.sender);
		if(status == true){amount = _ps[msg.sender].lpShare;}
		require(lpShare>=lockedAmount);
		require(lpShare-lockedAmount >= amount,"too much");
		if (lastClaim != block.number) {
			_getRewards(msg.sender);
		}
		_ps[msg.sender].lpShare = uint128(lpShare - amount);
		uint toSubtract = tknAmount*amount/lpShare; // not an array of deposits. if a provider stakes and then stakes again, and then unstakes - he loses share as if he staked only once at lowest price he had
		require(tknAmount>=toSubtract);
		_ps[msg.sender].tknAmount = uint128(tknAmount-toSubtract);
		bytes32 epoch;
		uint length;
		if (status == true) {
			length = _founderEpochs.length;
			epoch = _founderEpochs[length-1];
		} else{
			length = _epochs.length;
			epoch = _epochs[length-1];
		}
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

	function getRewards() public {
	   // _getRewards(msg.sender);
	}

	function _getRewards(address a) internal returns(uint){
		uint lastClaim = _ps[a].lastClaim;
		uint epochToClaim = _ps[a].lastEpoch;
		bool status = _ps[a].founder;
		uint tknAmount = _ps[a].tknAmount;
		require(block.number>lastClaim,"block.number");
		_ps[a].lastClaim = uint32(block.number);
		bytes32 epoch;
		uint length;
		uint toClaim=0;
		uint eBlock;
		uint eAmount;
		uint eEnd;
		if (status) {
			length = _founderEpochs.length;
		} else {
			length = _epochs.length;
		}
		if (length>0 && epochToClaim < length-1) {

			for (uint i = epochToClaim; i<length;i++) {
				if (status) {
					epoch = _founderEpochs[i];
				} else {
					epoch = _epochs[i];
				}
				(eBlock,eAmount,eEnd) = _extractEpoch(epoch);
				if(i == length-1) {
					eBlock = lastClaim;
				}
				toClaim += _computeRewards(eBlock,eAmount,eEnd,tknAmount,status);
			}
			_ps[a].lastEpoch = uint16(length-1);
		} else {
			if(status){
				epoch = _founderEpochs[length-1];
			} else {
				epoch = _epochs[length-1];
			}
			eAmount = uint96(bytes12(epoch << 80)); toClaim = _computeRewards(lastClaim,eAmount,block.number,tknAmount,status);
		}
		I(_treasury).getRewards(a, toClaim);
	}

	function _getRate(bool s,uint eEnd) internal view returns(uint){
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

	function _computeRewards(uint eBlock, uint eAmount, uint eEnd, uint tknAmount, bool s) internal view returns(uint){
		if(eEnd==0){
			eEnd = block.number;
		}
		uint rate = _getRate(s,eEnd);
		uint blocks = eEnd - eBlock;
		uint toClaim = blocks*tknAmount*rate/eAmount;
		return toClaim;
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
//		return _getLockRewards(msg.sender);
	}

	function _getLockRewards(address a) internal returns(uint){// no epochs for this, not required
		uint toClaim = 0;
		if(_ls[a].lockUpTo>block.number&&_ls[a].amount>0){
			uint blocks = block.number - _ls[msg.sender].lastClaim;
			uint rate = _getRate(false, block.number);
			rate = rate/2;
			toClaim = blocks*_ls[a].amount*rate/totalLetLocked;
			I(_treasury).getRewards(a, toClaim);
		}
		_ls[msg.sender].lastClaim = uint32(block.number);
		return toClaim;
	}

	function unlock(address tkn, uint amount) public {
		if(tkn == _tokenFTMLP){
			require(_ps[msg.sender].lockedAmount >= amount && block.number>=_ps[msg.sender].lockUpTo);
			_ps[msg.sender].lockedAmount -= uint128(amount);
		}
		if(tkn == _letToken){
			require(_ls[msg.sender].amount>=amount && totalLetLocked>=amount);
//			_getLockRewards(msg.sender);
			_ls[msg.sender].amount-=uint128(amount);
			I(_letToken).transfer(msg.sender,amount*19/20);
			uint leftOver = amount - amount*19/20;
			I(_letToken).transfer(_treasury,leftOver);//5% burn to treasury as spam protection
			totalLetLocked-=amount;
		}
	}

	function stakeLP(uint amount) public {
		address tkn = _tokenFTMLP;
		uint length = _epochs.length;
		uint lastClaim = _ps[msg.sender].lastClaim;
		require(_ps[msg.sender].founder==false && I(tkn).balanceOf(msg.sender)>=amount);
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