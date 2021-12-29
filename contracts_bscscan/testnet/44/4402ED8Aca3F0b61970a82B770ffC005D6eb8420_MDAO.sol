// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./IERC20.sol";
import './SafeMath.sol';
import './Counters.sol';
import "./Ownable.sol";
import "./IterableMapping.sol";

contract MDAO is Ownable{
    using SafeMath for uint256;
	using Counters for Counters.Counter;
	using IterableMapping for IterableMapping.Map;
	
     //setcoin
    address  public setToken=address(0x0c18d1bE6777Dc66Ee5BA80fa9c3Be1dD71d2169);
    //address  public setToken=address(0x3B5fA3Fb89a712500ACcFC6E392572D19441957f);
    
    mapping(address => SnapshotsDelegates) private delegatesFromMe;
    mapping(address => IterableMapping.Map) private delegatesToMe;
    
    struct Delegates {
		uint256 fromBlock;
		address fromDelegate;
		address toDelegate;
		uint createTime;
	}
    
    struct SnapshotsDelegates {
		uint256[] ids;
		uint256[] fromBlock;
		address[] fromDelegate;
		address[] toDelegate;
		uint[] createTime;
	}
  
	bytes32 public constant DOMAIN_TYPEHASH =keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');
	bytes32 public constant DELEGATION_TYPEHASH =keccak256('Delegation(address delegatee,uint256 nonce,uint256 expiry)');
	mapping(address => uint256) public nonces;
	
	event Snapshot(uint256 id);
	event DelegateChanged(address indexed fromDelegate, address indexed toDelegate,uint256 fromBlock,uint createTime);
	
	Counters.Counter public _currentSnapshotId;
    
     constructor(){
        _currentSnapshotId.increment();
    }
    
   	function getCurrentVotes(address account) external view  returns (uint256) {
   	    
   	    uint256 balance=getSetCoinBalance(account);
   	    uint256 toMeBalance=0;
   	    SnapshotsDelegates storage snapshots=delegatesFromMe[account];
   	    if(snapshots.ids.length>0){
   	        uint256 len=snapshots.ids.length;
   	        address fromDelegate=snapshots.fromDelegate[len-1];
   	        address toDelegate=snapshots.toDelegate[len-1];
   	        if(fromDelegate==account && toDelegate!=account){
   	            balance=0;
   	        }
   	    }
   	    //how many toMeBalance
   	    IterableMapping.Map storage map=delegatesToMe[account];
   	    for (uint i = 0; i < map.size(); i++) {
            address key = map.getKeyAtIndex(i);
           
            if(account!=key){
                 uint256 keyBalance=getSetCoinBalance(key);
                 toMeBalance=toMeBalance.add(keyBalance);
            }
        }
		return balance.add(toMeBalance);
	}
	
	function getDelegatesFromMe(address  account) public view returns (SnapshotsDelegates memory) {
	   return delegatesFromMe[account];
	}
	
	function getDelegatesToMe(address  account) public view returns (address[] memory) {
	   return delegatesToMe[account].keys;
	}
	
	function _delegate(address delegateFrom,address delegateTo) internal {
        
		uint256 blockNumber = safe32(block.number, 'MDAO::_writeCheckpoint: block number exceeds 32 bits');
		uint nowTime=block.timestamp;
        SnapshotsDelegates storage snapshots=delegatesFromMe[delegateFrom];
        
   	    if(snapshots.ids.length>0){
   	       uint256 len=snapshots.ids.length;
   	       address oldDelegateTo=snapshots.toDelegate[len-1];
   	       IterableMapping.Map storage map=delegatesToMe[oldDelegateTo];
   	       map.remove(delegateFrom);
   	    }
   	    
   	   
   	     IterableMapping.Map storage mapAdd=delegatesToMe[delegateTo];
   	     uint256 maplen=mapAdd.size();
   	     mapAdd.set(delegateFrom, maplen);
        
		uint256 currentId = _currentSnapshotId.current();
		if (_lastSnapshotId(snapshots.ids) < currentId) {
			snapshots.ids.push(currentId);
			snapshots.fromBlock.push(blockNumber);
			snapshots.fromDelegate.push(delegateFrom);
			snapshots.toDelegate.push(delegateTo);
			snapshots.createTime.push(nowTime);
		}else{
		    uint256 len=snapshots.ids.length;
		    snapshots.fromBlock[len-1]=blockNumber;
		    snapshots.fromDelegate[len-1]=delegateFrom;
			snapshots.toDelegate[len-1]=delegateTo;
			snapshots.createTime[len-1]=nowTime;
		}
		emit DelegateChanged(delegateFrom, delegateTo,blockNumber,nowTime);
	}
   
    
    function snapshot() external  onlyOwner returns (uint256) {
		_currentSnapshotId.increment();
		uint256 currentId = _currentSnapshotId.current();
		emit Snapshot(currentId);
		return currentId;
	}
    
    function getSetCoinBalance(address ac) public view returns(uint256){
          return IERC20(setToken).balanceOf(ac);
     } 
     
    function delegate(address delegateTo) external {
		return _delegate(msg.sender, delegateTo);
	}
	
	function delegateBySig(
		address delegatee,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external {
		bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes('M-DAO')), getChainId(), address(this)));
		bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
		bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
		address signatory = ecrecover(digest, v, r, s);
		require(signatory != address(0), 'MDAO::delegateBySig: invalid signature');
		require(nonce == nonces[signatory]++, 'MDAO::delegateBySig: invalid nonce');
		require(block.timestamp <= expiry, 'MDAO::delegateBySig: signature expired');
		return _delegate(signatory, delegatee);
	}
	
	function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
		if (ids.length == 0) {
			return 0;
		} else {
			return ids[ids.length - 1];
		}
	}
	
	function safe32(uint256 n, string memory errorMessage) internal pure returns (uint256) {
		require(n < 2**32, errorMessage);
		return uint256(n);
	}
	
	function getChainId() internal view returns (uint256) {
		uint256 chainId;
		assembly {
			chainId := chainid()
		}
		return chainId;
	}
}