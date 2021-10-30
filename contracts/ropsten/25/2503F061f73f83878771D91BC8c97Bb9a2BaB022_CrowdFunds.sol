/**
 *Submitted for verification at Etherscan.io on 2021-10-30
*/

pragma solidity ^0.8.0;
interface token {
	function transfer(address receiver, uint amount) external returns(bool success);
}
library SafeMath {
	function add(uint a, uint b) internal pure returns (uint) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
	function sub(uint a, uint b) internal pure returns (uint) {
		assert(b <= a);
		return a - b;
	}
	function mul(uint a, uint b) internal pure returns (uint) {
		if (a == 0) {
			return 0;
		}
		uint c = a * b;
assert(c / a == b);
		return c;
	}
	function div(uint a, uint b) internal pure returns (uint) {
		uint c = a / b;
		return c;
	}

}
contract CrowdFunds {
    using SafeMath for uint;
    address payable public beneficiary;
    uint public deadline;
    uint public targetFunds;
    uint public price;
    token public tokenReward;
    bool public reachedGoal = false;
    uint public fundsRaisedTotal = 0;
    mapping(address => uint) public balanceOf;
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address investor, uint amount, bool isContribution);
    event InvestorWithdraw(address investor, uint amount, bool success); // 投资人提现事件
    event BeneficiaryWithdraw(address beneficiary, uint amount, bool success); // 受益人提现事件
    constructor(
        address payable _beneficiary,
        uint _targetFunds,
        uint _duration,
        uint _price,
        address _tokenAddress
    ) {
        beneficiary = _beneficiary;
        deadline = block.timestamp + _duration * 1 weeks;
        targetFunds = _targetFunds * 1 ether;
        price = _price * 1e16;//10000finney
        tokenReward = token(_tokenAddress);
    }
    modifier afterddl() { // 修改器
        require(
            deadline<=block.timestamp
        );
        _;
    }
        receive() payable external {
        require(!reachedGoal);// 判断众筹是否达标
        require(block.timestamp<deadline); 
        uint amount = msg.value;
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        fundsRaisedTotal = fundsRaisedTotal.add(amount);
        uint tokenNum = (amount / price)*10 ** 18;
        if (fundsRaisedTotal >= targetFunds) {
            reachedGoal = true; 
            emit GoalReached(beneficiary, fundsRaisedTotal);
        }
        tokenReward.transfer(msg.sender, tokenNum);
        emit FundTransfer(msg.sender, amount, true);
    }
     fallback() external payable {}
    function withdraw() afterddl public {
            if (!reachedGoal) {
            uint amout = balanceOf[msg.sender];
            address payable _payableAddr = payable(msg.sender);
            if (amout > 0 &&  _payableAddr.send(balanceOf[msg.sender])) {
               balanceOf[msg.sender] = 0;
                emit InvestorWithdraw(msg.sender, amout, true);
            } else {
                emit InvestorWithdraw(msg.sender, amout, false);
            }
            } else { 
            if (msg.sender == beneficiary && beneficiary.send(fundsRaisedTotal)) {
                emit BeneficiaryWithdraw(beneficiary, fundsRaisedTotal, true);
            } else {
                emit BeneficiaryWithdraw(msg.sender, fundsRaisedTotal, false);
            }
        }
    }
}