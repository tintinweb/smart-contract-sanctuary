/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

pragma solidity ^0.8.0;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
abstract contract Context {
   function _msgSender() internal view virtual returns (address) {
    return msg.sender;
}

function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract PuzzleTokenV2 {
   function transfer(address recipient, uint256 amount) external returns (bool) {}
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {}
   function approve(address spender, uint256 amount) external returns (bool){}
   function balanceOf(address account) external view returns (uint256){}

}
contract PuzzleNetwork {
	address public controlContract;
	modifier onlyCtrlContract() {
		require(msg.sender == controlContract);
   		_;
	}
	function getReferrOne(address client) public view returns(address) {}
	function getReferrTwo(address client) public view returns(address) {}
	function getReferrThree(address client) public view returns(address) {}
	function recordIncome(address client, uint percent) public onlyCtrlContract returns (bool) {}
	function registration(address client, address referrer) public onlyCtrlContract returns (bool) {}
	function setMentorStatus(address mentor) public onlyCtrlContract returns (bool) {}
	function getMentorStatus(address mentor) public view returns(bool){}
}
contract PuzzleMentors {
	address public controlContract;
	modifier onlyCtrlContract() {
		require(msg.sender == controlContract);
   		_;
	}
	function buyMentoring(address client, address mentor, uint price, uint income) public onlyCtrlContract returns (bool) {}
	function getPuzzleStrike (address mentor) public view returns(uint) {}
	function getMentorPrice (address mentor) public view returns(uint) {}
}
contract controlPZL is Context{
	address public PZLnetwork;
	address public PZLMentors;
	address public owner;
	address pegasus;
    address perseus;
    uint registrationTax;
	PuzzleTokenV2 PZL2 =  PuzzleTokenV2(0xf6a3eBeB5Bc4a38D4F160F56114ddD76A429c7a1);
	PuzzleNetwork NETPZL = PuzzleNetwork(PZLnetwork);
	PuzzleMentors MENPZL = PuzzleMentors(PZLMentors);
	constructor(address _owner, address _pegasus, address _perseus) public payable{
    	owner = _owner;
    	pegasus = _pegasus;
        perseus = _perseus;
    }

  	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	modifier onlyOwner() {
    	require(msg.sender == owner);
   		_;
  	}

  	function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  	}

  	function setPZLnetwork(address networkContract) public onlyOwner {
  		PZLnetwork = networkContract;
  	}

  	function getPZLmetwork() public view returns (address){
  		return PZLnetwork;
  	}

  	function setPZLmentors(address mentorsContract) public onlyOwner {
  		PZLMentors = mentorsContract;
  	}

  	function getPZLmentors() public view returns (address){
  		return PZLMentors;
  	}

  	function setRegTax(uint tax) public onlyOwner {
  		registrationTax = tax;
  	}
  	function getRegTax() public view returns(uint) {
  		return registrationTax;
  	}
  	function callTransferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        return PZL2.transferFrom(sender ,recipient ,amount);
    }

    function contractTax(address sender, uint256 amount) private returns (uint256) {
        uint256 temp3918 = SafeMath.mul(15, amount);
        callTransferFrom(sender, pegasus, temp3918);
        callTransferFrom(sender, perseus, temp3918);
        return SafeMath.mul(temp3918, 2);
    }

  	function referrerpay(address client, address mentor, uint percent) private returns (uint) {
  		uint256 referTax1 = SafeMath.mul(5, percent);
        uint256 referTax2 = SafeMath.mul(3, percent);
        uint256 referTax3 = SafeMath.mul(2, percent);
        address refer1 = NETPZL.getReferrOne(client);
        address refer2 = NETPZL.getReferrTwo(client);
        address refer3 = NETPZL.getReferrThree(client);
        address mentorRefer1 = NETPZL.getReferrOne(mentor);
        address mentorRefer2 = NETPZL.getReferrTwo(mentor);
        address mentorRefer3 = NETPZL.getReferrThree(mentor);
        callTransferFrom(client, refer1, referTax1);
        callTransferFrom(client, refer2, referTax2);
        callTransferFrom(client, refer3, referTax3);
        callTransferFrom(client, mentorRefer1, referTax1);
        callTransferFrom(client, mentorRefer2, referTax2);
        callTransferFrom(client, mentorRefer3, referTax3);
        NETPZL.recordIncome(client, percent);
        NETPZL.recordIncome(mentor, percent);
        return SafeMath.mul(percent, 20);
  	}
  	function paymentMentoring(address mentor, uint amount)  public returns (bool) {
  		address sender = _msgSender();
  		uint minPrice = MENPZL.getMentorPrice(mentor);
        require (PZL2.balanceOf(sender) >= amount, "PZL: not enough tokens ");
        require (amount >= minPrice, "PZL: The cost of mentoring is higher ");
        NETPZL.setMentorStatus(mentor);
        uint256 percent = SafeMath.div(amount, 100);
		uint256 strikeCheck = MENPZL.getPuzzleStrike(mentor);
		uint mentorPay = percent * 10 * (3 + strikeCheck);
		referrerpay(sender, mentor, percent);
		contractTax(sender, percent);
		MENPZL.buyMentoring(sender, mentor, amount, mentorPay);
		return callTransferFrom(sender, mentor, mentorPay);
  	}
  	function registration(address referrer) public returns (bool) {
  		address client = _msgSender();
  		uint percent =  SafeMath.div(registrationTax, 20);
  		require (PZL2.balanceOf(client) >= registrationTax);
  		bool regCheck = NETPZL.registration(client, referrer);
  		if(regCheck == true)
  			referrerpay(client, referrer, percent);
  		return regCheck;
  	}
}