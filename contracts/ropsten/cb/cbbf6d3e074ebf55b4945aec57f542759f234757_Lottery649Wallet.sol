// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import "./Owned.sol";
import "./SafeMath.sol";
import "./ILottery649Wallet.sol";

contract Lottery649Wallet is Owned, ILottery649Wallet {
	using SafeMath for uint256;
	
	uint256 penndingBalances = 0;
	
	uint256 JACKPOT;
	uint256 JACKPOT1;
	
	uint256 constant TICKET_PRICE = 10 finney; //0.01 ETH
	uint256 constant comission = 4 finney;
	uint256 constant JACKPOTcomission = 4 finney;
	uint256 constant JACKPOT1comission = 2 finney;
	
	/* This creates an array with all balances */
	mapping (address => uint256) private balances;
	
    constructor() public {}
    
	receive() external payable {
		if(msg.sender == owner || getIsAuth(msg.sender)) {
			uint256 value = msg.value;
			uint256 JC1 = value.div(2);
			uint256 remaining = value.sub(JC1);
			JACKPOT = JACKPOT.add(JC1);
			JACKPOT1 = JACKPOT1.add(remaining);
			penndingBalances = penndingBalances.add(value);
			emit InitialDeposit(value,JC1,remaining);
		} else {
			depositFunds(msg.sender, msg.value);
		}
    //   	emit Received(msg.sender, msg.value, msg.data);
  	}
  
  	fallback() external payable {
	   if(msg.sender == owner || getIsAuth(msg.sender)) {
			uint256 value = msg.value;
			uint256 JC1 = value.div(2);
			uint256 remaining = value.sub(JC1);
			JACKPOT = JACKPOT.add(JC1);
			JACKPOT1 = JACKPOT1.add(remaining);
			penndingBalances = penndingBalances.add(value);
			emit InitialDeposit(value,JC1,remaining);
		} else {
			depositFunds(msg.sender, msg.value);
		}
    //   	emit Fallback(msg.sender, msg.value, msg.data);
  	}

    
    function depositFunds(address _participant, uint256 _weiAmount) public override payable returns(bool success) {
        require(msg.value == _weiAmount);
        balances[_participant] = balances[_participant].add(_weiAmount);
        penndingBalances = penndingBalances.add(_weiAmount);
        emit DepostFunds(_participant, balances[_participant], _weiAmount, block.timestamp);
        return true;
    }
    
    function withdrawFromBalance(address payable _participant, uint256 _weiAmount) public override payable returns(bool success) {
		require(_participant == msg.sender);
        require(balances[_participant] > 0);
        require(balances[_participant] >= _weiAmount);
        balances[_participant] = balances[_participant].sub(_weiAmount);
	    penndingBalances = penndingBalances.sub(_weiAmount);
        _participant.transfer(_weiAmount);
        emit WithdrawFromBalance(_participant, block.timestamp, _weiAmount);
        return true;
    }
    
	function addBalance(address _participant, uint256 _weiAmount) public override onlyAuth returns(bool success) {
		balances[_participant] = balances[_participant].add(_weiAmount);
		JACKPOT = JACKPOT.sub(_weiAmount);
		if(_weiAmount == JACKPOT || JACKPOT <= JACKPOT1){
			JACKPOT = JACKPOT.add(JACKPOT1.div(2));
			JACKPOT1 = JACKPOT1.div(2);
			emit JC(JACKPOT,JACKPOT1);
		}
		emit AddBalance(_participant, _weiAmount, block.timestamp);
        return true;
	}
	
	function substractBalance(address _participant) public override onlyAuth returns(bool success) {
	    balances[_participant] = balances[_participant].sub(TICKET_PRICE);
	    penndingBalances = penndingBalances.sub(comission);
		JACKPOT = JACKPOT.add(JACKPOTcomission);
		JACKPOT1 = JACKPOT1.add(JACKPOT1comission); 
		emit SubstractBalance(_participant,TICKET_PRICE, block.timestamp);
        return true;
	}
	
	function transferRevenue() public onlyAuth {
		_transfer(msg.sender);
	}
	
	function _transfer(address payable _to) internal {
		uint256 revenue = (address(this).balance).sub(penndingBalances);
		require(revenue > 0,"Revenue must greater than 0");
	    require(address(this).balance >= penndingBalances.add(revenue));
	    _to.transfer(revenue);
	}
	
	function balanceOf(address _participant) public override view returns (uint256 balance) {
		return balances[_participant];
	}
	
	function getJackpot() public override view returns (uint256 _jackpot) {
		return JACKPOT;
	}
	
	function getJackpot1() public override view returns (uint256 _jackpot1) {
		return JACKPOT1;
	}
	
	function getPenndingBalances() public override view returns(uint256 _penndingBalances){
	    return penndingBalances;
	}
}