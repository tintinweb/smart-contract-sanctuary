/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

contract BNB333 {
    using SafeMath for uint256;
    
    uint256 public constant REFERRER_CODE = 4000;
    uint256 public constant PENALTY_STEP = 250;
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant MAX_INVESTORS = 3;
    uint256 public constant COMMISSION_RATE = 150;
    uint256 public constant DEVELOPER_RATE = 400;
    uint256 public constant RESERVE_RATE = 300;
    uint256 public constant MARKETING_RATE = 400;
    
    address payable public developerAccount;
    address payable public marketingAccount;
    address payable public reserveAccount;
    uint256 public totalStaked;
    uint256 public insuranceFunds;
    
    mapping(uint256 => Investor) public index2Investor;
    mapping(uint256 => Plan) public index2Plan;
    mapping(address => uint256) public address2index;
    mapping(uint256 => Stack) public index2Stack;
    
    Plan[6] internal plans;
    
    uint256 public latestReferredCode;
    uint256 public latestStackId;
    
    struct Plan {
        uint256 amount;
    }
    
    struct Stack {
        uint8 plan;
        uint256[] investors;
        uint256 startDate;
        bool finished;
    }
    
    struct Investor {
        address payable addr;
        uint256 referrer;
        uint256[] investments;
    }
    
    struct Investment {
        uint256 planId;
        uint256 stackId;
    }
    
    event onInvest(address indexed _address, uint256 plan);
    event onWithdrawProfit(address indexed _address, uint256 _plan, uint256 _stackId);
    
    constructor()  public{
        _initPlans();
        latestReferredCode = 1000;
        latestStackId = 5000;
    }
    
    function _initPlans() private {
        plans[0] = Plan({amount : 0.25 ether});
        plans[1] = Plan({amount : 0.5 ether});
        plans[2] = Plan({amount : 1 ether});
        plans[3] = Plan({amount : 5 ether});
        plans[4] = Plan({amount : 10 ether});
        plans[5] = Plan({amount : 50 ether});
    }
    
    function withdrawProfit(uint256 _stackId) public {
        require(index2Stack[_stackId].investors[0] == address2index[msg.sender], "Only the first investor on the stack can withdraw the profit.");
        index2Stack[_stackId].finished = true;
        
        uint256 amount = plans[index2Stack[_stackId].plan].amount.mul(MAX_INVESTORS);
        uint256 commissionAmount = amount.mul(COMMISSION_RATE).div(PERCENTS_DIVIDER);
        uint256 developAmount = commissionAmount.mul(DEVELOPER_RATE).div(PERCENTS_DIVIDER);
        uint256 reserveAmount = commissionAmount.mul(RESERVE_RATE).div(PERCENTS_DIVIDER);
        uint256 marketingAmmount = commissionAmount.mul(MARKETING_RATE).div(PERCENTS_DIVIDER);
        
        msg.sender.transfer(amount);
        developerAccount.transfer(developAmount);
        reserveAccount.transfer(reserveAmount);
        marketingAccount.transfer(marketingAmmount);
        
        modifyInvestorsAndCreateNewStacks(index2Stack[_stackId].plan, _stackId);
        
        emit onWithdrawProfit(msg.sender, index2Stack[_stackId].plan, _stackId);
    }
    
    function modifyInvestorsAndCreateNewStacks(uint8 _plan, uint256 _stackId) private {
        Investor storage investor = index2Investor[address2index[msg.sender]];
        investor.investments[_plan] = 0;
        
        index2Stack[latestStackId] = Stack({
            plan : _plan,
            startDate : block.timestamp,
            finished : false,
            investors : new uint256[](3)
        });
        
        index2Stack[latestStackId].investors[0] = index2Stack[_stackId].investors[1];
        latestStackId++;
        
        index2Stack[latestStackId] = Stack({
            plan : _plan,
            startDate : block.timestamp,
            finished : false,
            investors : new uint256[](3)
        });
        
        index2Stack[latestStackId].investors[0] = index2Stack[_stackId].investors[2];
        latestStackId++;
    }
    
    function calculateProfit(uint256 _plan) internal view returns(uint256){
        uint256 amount = plans[_plan].amount.mul(MAX_INVESTORS);
        uint256 commissionAmount = amount.mul(COMMISSION_RATE).div(PERCENTS_DIVIDER);
        return amount.sub(commissionAmount);
    }
    
    function invest(uint8 _plan, uint256 _referral) public payable {
        require(msg.value == plans[_plan].amount, "Amount other than required by plan");
        
        uint256 _indexInvestor = address2index[msg.sender];
        
        if(_indexInvestor == 0) {
            address2index[msg.sender] = latestReferredCode;
            index2Investor[latestReferredCode] = Investor({
                addr : msg.sender,
                referrer : latestReferredCode,
                investments : new uint256[](6)
            });
            _indexInvestor = latestReferredCode;
            latestReferredCode++;
        }
        
        _invest(_plan, _referral, _indexInvestor);
        
        emit onInvest(msg.sender, _plan);
    }
    
    function _invest(uint8 _plan, uint256 _referral, uint256 _indexInvestor) private {
        if(_referral == 0) {
            index2Stack[latestStackId] = Stack({
                plan : _plan,
                startDate : block.timestamp,
                finished : false,
                investors : new uint256[](3)
                
            });
            index2Stack[latestStackId].investors[0] = _indexInvestor;
            index2Investor[_indexInvestor].investments[_plan] = latestStackId;
            latestStackId++;
        }else {
            require(_referral >= 1000 , "The investor who referred you does not exist");
            Stack storage stack = index2Stack[index2Investor[_referral].investments[_plan]];
        
            for(uint256 i;i<stack.investors.length;i++) {
                if(stack.investors[i] == 0) {
                    stack.investors[i] = _indexInvestor;
                    break;
                }
            }
        }
        
        totalStaked += plans[_plan].amount;
    }
    
    function getInfoStack(uint256 _indexStack) public view returns (uint256, uint256[] memory) {
        return (index2Stack[_indexStack].plan,index2Stack[_indexStack].investors);
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}