/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
interface I {
	function balanceOf(address a) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function transferFrom(address sender,address recipient, uint amount) external returns (bool);
	function totalSupply() external view returns (uint);
//	function getLastVoted(address account) external view returns (uint lastVoted); function changeAddress(address acc,address acc1) external;
	function getRewards(address a,uint rewToClaim) external returns(bool);
	function deposits(address a) external view returns(uint);
//	function providerMigr(address a,uint lpShare,uint lastClaim,uint lastEpoch,uint tknAmount,bool status) external;function lockerMigr(address a,uint amount,uint lockUpTo) external;
}

// did change it a small bit: founders are unable to stake generic liquidity on top of their share, or it will be too expensive to sload
// for that they will have to use another address

contract StakingContract {
	uint128 private _foundingETHDeposited;
	uint128 private _foundingLPtokensMinted;
	address private _tokenETHLP;
	uint32 private _genesis;
	uint private _genLPtokens;

	struct LPProvider {uint32 lastClaim; uint16 lastEpoch; bool founder; uint128 tknAmount; uint128 lpShare;uint128 lockedAmount;uint128 lockUpTo;}
	struct TokenLocker {uint128 amount;uint128 lockUpTo;}

	bytes32[] private _epochs;
	bytes32[] public founderEpochs;

	mapping(address => LPProvider) private _ps;
	mapping(address => TokenLocker) private _ls;
//	mapping(address => address) public newAddresses;
//	mapping(address => bool) private _takenNew;

	function genesis(uint foundingETH, address tkn, uint gen) public {
		require(msg.sender == 0x31A188024FcD6E462aBF157F879Fb7da37D6AB2f && _genesis != 0);
		_foundingETHDeposited = uint128(foundingETH);
		_foundingLPtokensMinted = uint128(I(tkn).balanceOf(address(this)));
		_tokenETHLP = tkn;
		_genesis = uint32(gen);
		_createEpoch(0,false);
		_createEpoch(1e24,true);
	}

	function claimFounderStatus() public {
		uint ethContributed = I(0x31A188024FcD6E462aBF157F879Fb7da37D6AB2f).deposits(msg.sender);
		require(ethContributed > 0);
		require(_genesis != 0 && _ps[msg.sender].founder == false);
		_ps[msg.sender].founder = true;
		uint foundingETH = _foundingETHDeposited;
		uint lpShare = _foundingLPtokensMinted*ethContributed/foundingETH;
		uint tknAmount = ethContributed*1e24/foundingETH;
		_ps[msg.sender].lpShare = uint128(lpShare);
		_ps[msg.sender].tknAmount = uint128(tknAmount);
		_ps[msg.sender].lastClaim = uint32(_genesis);
	}

	function unstakeLp(bool ok,uint amount) public {
		(uint lastClaim,bool status,uint tknAmount,uint lpShare,uint lockedAmount) = getProvider(msg.sender);
		require(lpShare-lockedAmount >= amount && ok == true);
		if (lastClaim != block.number) {_getRewards(msg.sender);}
		_ps[msg.sender].lpShare = uint128(lpShare - amount);
		uint toSubtract = tknAmount*amount/lpShare; // not an array of deposits. if a provider stakes and then stakes again, and then unstakes - he loses share as if he staked only once at lowest price he had
		_ps[msg.sender].tknAmount = uint128(tknAmount-toSubtract);
		bytes32 epoch; uint length;
		if (status == true) {length = founderEpochs.length; epoch = founderEpochs[length-1];}
		else{length = _epochs.length; epoch = _epochs[length-1];_genLPtokens -= amount;}
		(uint80 eBlock,uint96 eAmount,) = _extractEpoch(epoch);
		eAmount -= uint96(toSubtract);
		_storeEpoch(eBlock,eAmount,status,length);
		I(_tokenETHLP).transfer(address(msg.sender), amount);
	}

	function getRewards() public {_getRewards(msg.sender);}

	function _getRewards(address a) internal {
		uint lastClaim = _ps[a].lastClaim;
		uint epochToClaim = _ps[a].lastEpoch;
		bool status = _ps[a].founder;
		uint tknAmount = _ps[a].tknAmount;
		require(block.number>lastClaim);
		_ps[a].lastClaim = uint32(block.number);
		uint rate = _getRate();
		uint eBlock; uint eAmount; uint eEnd; bytes32 epoch; uint length; uint toClaim;
		if (status) {length = founderEpochs.length;} else {length = _epochs.length;}
		if (length>0 && epochToClaim < length-1) {
			for (uint i = epochToClaim; i<length;i++) {
				if (status) {epoch = founderEpochs[i];} else {epoch = _epochs[i];}
				(eBlock,eAmount,eEnd) = _extractEpoch(epoch);
				if(i == length-1) {eBlock = lastClaim;}
				toClaim += _computeRewards(eBlock,eAmount,eEnd,tknAmount,rate);
			}
			_ps[a].lastEpoch = uint16(length-1);
		} else {
			if(status){epoch = founderEpochs[length-1];} else {epoch = _epochs[length-1];}
			eAmount = uint96(bytes12(epoch << 80)); toClaim = _computeRewards(lastClaim,eAmount,block.number,tknAmount,rate);
		}
		bool success = I(0x05658a207a56AA2d6b2821883D373f59Ac6A2fC3).getRewards(a, toClaim); require(success == true);
	}

	function _getRate() internal view returns(uint){uint rate = 84e15; uint halver = block.number/1e7;if (halver>1) {for (uint i=1;i<halver;i++) {rate=rate*3/4;}}return rate;}

	function _computeRewards(uint eBlock, uint eAmount, uint eEnd, uint tknAmount, uint rate) internal view returns(uint){
		if(eEnd==0){eEnd = block.number;} uint blocks = eEnd - eBlock; return (blocks*tknAmount*rate/eAmount);
	}

// this function has to be expensive as an alert of something fishy just in case
// metamask has to somehow provide more info about a transaction
/*	function newAddress(address a) public {
		require(_takenNew[a] == false && _ps[a].lpShare == 0 && _ls[a].amount == 0);
		if(_ps[msg.sender].lockedAmount>0||_ls[msg.sender].amount>0){require(_isContract(msg.sender) == false);}
		_takenNew[a] = true;
		newAddresses[msg.sender] = a;
	}
// nobody should trust dapp interface. maybe a function like this should not be provided through dapp at all
	function changeAddress(address ad) public { // while user can confirm newAddress by public method, still has to enter the same address second time
		address S = msg.sender;	address a = newAddresses[S];
		require(a != address(0) && a == ad && a != msg.sender && block.number - 172800 > I(*governance address).getLastVoted(S));
		if (_ps[S].lpShare > 0) {
			_ps[a].lastClaim = _ps[S].lastClaim;_ps[a].lastEpoch = _ps[S].lastEpoch;_ps[a].founder = _ps[S].founder;_ps[a].tknAmount = _ps[S].tknAmount;
			_ps[a].lpShare = _ps[S].lpShare;_ps[a].lockUpTo = _ps[S].lockUpTo;_ps[a].lockedAmount = _ps[S].lockedAmount;delete _ps[S];
		}
		if (_ls[S].amount > 0) {_ls[a].amount=_ls[S].amount;_ls[a].lockUpTo=_ls[S].lockUpTo;delete _ls[S];}
	}*/

	function lockFor6Months(bool ok, address tkn, uint amount) public {// the game theory disallows deployer to exploit this lock
		require(ok==true && amount>0);
		if(tkn ==_tokenETHLP) {
			require(_ps[msg.sender].lpShare-_ps[msg.sender].lockedAmount>=amount); _ps[msg.sender].lockUpTo=uint128(block.number+1e6);_ps[msg.sender].lockedAmount+=uint128(amount);	
		}
		if(tkn == 0xEd7C1848FA90E6CDA4faAC7F61752857461af284) {
			require(I(tkn).balanceOf(msg.sender)>=amount);
			_ls[msg.sender].lockUpTo=uint128(block.number+1e6);
			_ls[msg.sender].amount+=uint128(amount);
			I(tkn).transferFrom(msg.sender,address(this),amount);
		}
	}

	function unlock() public {
		if (_ps[msg.sender].lockedAmount > 0 && block.number>=_ps[msg.sender].lockUpTo) {_ps[msg.sender].lockedAmount = 0;}
		uint amount = _ls[msg.sender].amount;
		if (amount > 0 && block.number>=_ls[msg.sender].lockUpTo) {I(0xEd7C1848FA90E6CDA4faAC7F61752857461af284).transfer(msg.sender,amount);_ls[msg.sender].amount = 0;}
	}

	function stake(uint amount) public {
		address tkn = _tokenETHLP;
		uint length = _epochs.length;
		uint lastClaim = _ps[msg.sender].lastClaim;
		require(_ps[msg.sender].founder==false && I(tkn).balanceOf(msg.sender)>=amount);
		I(tkn).transferFrom(msg.sender,address(this),amount);
		if(lastClaim==0){_ps[msg.sender].lastClaim = uint32(block.number);}
		else if (lastClaim != block.number) {_getRewards(msg.sender);}
		bytes32 epoch = _epochs[length-1];
		(uint80 eBlock,uint96 eAmount,) = _extractEpoch(epoch);
		eAmount += uint96(amount);
		_storeEpoch(eBlock,eAmount,false,length);
		_ps[msg.sender].lastEpoch = uint16(_epochs.length);
		uint genLPtokens = _genLPtokens;
		genLPtokens += amount;
		_genLPtokens = genLPtokens;
		uint share = amount*I(0xEd7C1848FA90E6CDA4faAC7F61752857461af284).balanceOf(tkn)/genLPtokens;
		_ps[msg.sender].tknAmount += uint128(share);
		_ps[msg.sender].lpShare += uint128(amount);
	}

	function _extractEpoch(bytes32 epoch) internal pure returns (uint80,uint96,uint80){
		uint80 eBlock = uint80(bytes10(epoch));
		uint96 eAmount = uint96(bytes12(epoch << 80));
		uint80 eEnd = uint80(bytes10(epoch << 176));
		return (eBlock,eAmount,eEnd);
	}
 
	function _storeEpoch(uint80 eBlock, uint96 eAmount, bool founder, uint length) internal {
		uint eEnd;
		if(block.number-80640>eBlock){eEnd = block.number-1;}// so an epoch can be bigger than 2 weeks, it's normal behavior and even desirable
		bytes memory by = abi.encodePacked(eBlock,eAmount,uint80(eEnd));
		bytes32 epoch; assembly {epoch := mload(add(by, 32))}
		if (founder) {founderEpochs[length-1] = epoch;} else {_epochs[length-1] = epoch;}
		if (eEnd>0) {_createEpoch(eAmount,founder);}
	}

	function _createEpoch(uint amount, bool founder) internal {
		bytes memory by = abi.encodePacked(uint80(block.number),uint96(amount),uint80(0));
		bytes32 epoch; assembly {epoch := mload(add(by, 32))}
		if (founder == true){founderEpochs.push(epoch);} else {_epochs.push(epoch);}
	}

/*	function migrate(address contr,address tkn,uint amount) public lock {//can support any amount of bridges
		if (tkn == _tokenETHLP) {
			(uint lastClaim,bool status,uint tknAmount,uint lpShare,uint lockedAmount) = getProvider(msg.sender);
			if (lastClaim != block.number) {_getRewards(msg.sender);}
			require(lpShare-lockedAmount >= amount);
			_ps[msg.sender].lpShare = uint128(lpShare - amount);
			uint toSubtract = amount*tknAmount/lpShare;
			_ps[msg.sender].tknAmount = uint128(tknAmount-toSubtract);
			uint length; bytes32 epoch;
			if (status == true){length = founderEpochs.length; epoch = founderEpochs[length-1];}
			else{length = _epochs.length; epoch = _epochs[length-1]; _genLPtokens -= amount;}
			(uint80 eBlock, uint96 eAmount,) = _extractEpoch(epoch);
			eAmount -= uint96(toSubtract);
			_storeEpoch(eBlock,eAmount,status,length);
			I(tkn).transfer(contr, amount);
			I(contr).provider(msg.sender,amount,_ps[msg.sender].lastClaim,_ps[msg.sender].lastEpoch,toSubtract,status);
		}
		if (tkn == 0xEd7C1848FA90E6CDA4faAC7F61752857461af284) {
			uint lockedAmount = _ls[msg.sender].amount;
			require(lockedAmount >= amount);
			I(tkn).transfer(contr, amount);
			_ls[msg.sender].amount = uint128(lockedAmount-amount);
			I(contr).locker(msg.sender,amount,_ls[msg.sender].lockUpTo);
		}
	}*/
// VIEW FUNCTIONS ==================================================
	function getVoter(address a) external view returns (uint128,uint128,uint128,uint128,uint128,uint128) {
		return (_ps[a].tknAmount,_ps[a].lpShare,_ps[a].lockedAmount,_ps[a].lockUpTo,_ls[a].amount,_ls[a].lockUpTo);
	}

	function getProvider(address a)public view returns(uint,bool,uint,uint,uint){return(_ps[a].lastClaim,_ps[a].founder,_ps[a].tknAmount,_ps[a].lpShare,_ps[a].lockedAmount);}
}