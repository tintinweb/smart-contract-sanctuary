pragma solidity ^0.4.25;




contract TwoHundredPercent {
    
    using SafeMath for uint;
    mapping(address => uint) public invested;
    mapping(address => uint) public time;
    mapping(address => uint) public allPercentWithdraw;
    uint public stepTime = 1 hours;
    uint public pause = 1 hours;
   
    uint public countOfInvestors = 0;
    uint public contractBirthDay = 0;
    address public ownerAddress = 0xA8A297C1aC6a11c2118173ba976eA2D45Cc82188;
    uint projectPercent = 10;
    
    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);
    
    constructor() public{
        contractBirthDay = now;
    }
    
     modifier userExist() {
        require(invested[msg.sender] > 0, "Address not found");
        _;
    }

    modifier checkTime() {
        require(now >= time[msg.sender].add(stepTime), "Too fast payout request");
        _;
    }
    
    function collectPercent()  userExist checkTime internal {
        if ((invested[msg.sender].mul(2)) <= allPercentWithdraw[msg.sender]) {
            invested[msg.sender] = 0;
            allPercentWithdraw[msg.sender] = 0;
            time[msg.sender] = 0 hours;
        } else {
            uint payout = payoutAmount();
            allPercentWithdraw[msg.sender] = allPercentWithdraw[msg.sender].add(payout);
            msg.sender.transfer(payout);
            time[msg.sender] = now;
            emit Withdraw(msg.sender, payout);
        }
    }
    
    function payoutAmount() public view returns(uint256) {
        uint256 percent = percentRate();
        uint256 different = now.sub(time[msg.sender]).div(stepTime);
        uint256 rate = invested[msg.sender].mul(percent).div(1000);
        uint256 withdrawalAmount = rate.mul(different).div(24);
        if(allPercentWithdraw[msg.sender] !=0 && allPercentWithdraw[msg.sender].add(withdrawalAmount) > invested[msg.sender].mul(2)){
            withdrawalAmount = invested[msg.sender].mul(2).sub(allPercentWithdraw[msg.sender]);
        }
        if(withdrawalAmount > address(this).balance){
            withdrawalAmount = address(this).balance;
        }
        return withdrawalAmount;
    }
    
    function percentRate() public view returns(uint) {
        uint contractBalance = address(this).balance;

        if (contractBalance < 1000 ether) {
            return (60);
        }
        if (contractBalance >= 1000 ether && contractBalance < 2500 ether) {
            return (72);
        }
        if (contractBalance >= 2500 ether && contractBalance < 5000 ether) {
            return (84);
        }
        if (contractBalance >= 5000 ether) {
            return (90);
        }
    }

    
    
    
    function deposit() private {
        if(now < contractBirthDay.add(pause)){
            if(msg.value > 0){
                if(invested[msg.sender] == 0){
                    countOfInvestors += 1;
                    time[msg.sender] = contractBirthDay.add(pause);
                }
                invested[msg.sender] = invested[msg.sender].add(msg.value);
                ownerAddress.transfer(msg.value.mul(projectPercent).div(100));
                emit Invest(msg.sender, msg.value);
            }            
        }
        else{
            if (msg.value > 0) {
                if (invested[msg.sender] == 0) {
                    countOfInvestors += 1;
                }
                collectPercent();
                invested[msg.sender] = invested[msg.sender].add(msg.value);
                ownerAddress.transfer(msg.value.mul(projectPercent).div(100));
                emit Invest(msg.sender, msg.value);
            }
            else{
                collectPercent();
            }
        }
    }

    function() external payable {
        deposit(); 
    }
    
 
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}