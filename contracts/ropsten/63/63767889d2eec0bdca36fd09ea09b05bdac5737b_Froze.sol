/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

pragma solidity ^0.4.10;
//https://etherscan.io/token/0x0d8775f648430679a709e98d2b0cb6250d2887ef

//WRITE CONTRACT
contract Froze {
    
    // public values
    uint256 public totalFroze;
    uint256[] public lockedblocks;
    uint256[] public lockedfunds;
	
	address public frozeTokenContract;
	address public unfrozeReceiver;
    
    // public events
    event AddLock(uint256 _block, uint256 _value);
	event RunLock(address _frozeTokenContract, address _unfrozeReceiver);
	
    // constructor
    function StandardFroze( address _frozeTokenContract, address _unfrozeReceiver ) public {
      frozeTokenContract = _frozeTokenContract;
      unfrozeReceiver = _unfrozeReceiver;
      emit RunLock(frozeTokenContract, unfrozeReceiver);
    }
		
	function nextBlockOn() public constant returns (uint256 blockNumber) {
        return lockedblocks[0];
    }
	
	function nextAmountOn() public constant returns (uint256 amountFroze) {
		return lockedfunds[ lockedblocks[0] ];
    }
	
	function addlock(uint256 _block, uint256 _value) public {
	  require(_value > 0, "Amount is too low");
	  require(block.number < _block, "Block is too low");
	  require(lockedfunds[_block] <= 0, "Block lock exist");
      lockedblocks[lockedfunds.length + 1] = _block;
	  lockedfunds[_block] = _value;
	  totalFroze += _value;
      emit AddLock(_block, _value);
    }
}