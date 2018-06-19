/**
 * This reservation contract accepts investments, which will be sent to the ICO contract as soon as it starts buy calling buyTokens().
 * Investors may withdraw their funds anytime if they change their mind as long as the tokens have not yet been purchased.
 * Author: Julia Altenried
 * Internal audit: Alex Bazhanau, Andrej Ruckij
 * Audit: Blockchain & Smart Contract Security Group
 **/

pragma solidity ^0.4.15;

contract ICO {
	function invest(address receiver) payable {}
}

contract SafeMath {

	function safeAdd(uint a, uint b) internal returns(uint) {
		uint c = a + b;
		assert(c >= a && c >= b);
		return c;
	}

	function safeMul(uint a, uint b) internal returns(uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}
}

contract owned {
  address public owner;
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function owned() {
    owner = msg.sender;
  }

  function changeOwner(address newOwner) onlyOwner {
    owner = newOwner;
  }
}

contract mortal is owned {
  function close() onlyOwner {
		require(address(this).balance == 0);
    selfdestruct(owner);
  }
}

contract Reservation2 is mortal, SafeMath {
	ICO public ico;
	address[] public investors;
	mapping(address => uint) public balanceOf;
	mapping(address => bool) invested;
	uint public weiCap;


	/** constructs an investment contract for an ICO contract **/
	function Reservation2(address _icoAddr, uint _etherCap) {
		ico = ICO(_icoAddr);
		weiCap = safeMul(_etherCap, 1 ether);
	}

	/** make an investment **/
	function() payable {
		require(msg.value > 0);

		require(weiCap == 0 || this.balance <= weiCap);

		if (!invested[msg.sender]) {
			investors.push(msg.sender);
			invested[msg.sender] = true;
		}
		balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], msg.value);
	}

	/** buys tokens in behalf of the investors by calling the ico contract
	 *   starting with the investor at index from and ending with investor at index to.
	 *   This function will be called as soon as the ICO starts and as often as necessary, until all investments were made. **/
	function buyTokens(uint _from, uint _to) onlyOwner {
		require(address(ico)!=0x0);//would fail anyway below, but to be sure
		uint amount;
		if (_to > investors.length)
			_to = investors.length;
		for (uint i = _from; i < _to; i++) {
			if (balanceOf[investors[i]] > 0) {
				amount = balanceOf[investors[i]];
				delete balanceOf[investors[i]];
				ico.invest.value(amount)(investors[i]);
			}
		}
	}

	/** In case an investor wants to retrieve his or her funds he or she can call this function.
	 *   (only possible before tokens are bought) **/
	function withdraw() {
		uint amount = balanceOf[msg.sender];
		require(amount > 0);
		
		balanceOf[msg.sender] = 0;
		msg.sender.transfer(amount);
	}

	/** returns the number of investors **/
	function getNumInvestors() constant returns(uint) {
		return investors.length;
	}
	
	function setICO(address _icoAddr) onlyOwner {
		ico = ICO(_icoAddr);
	}

}