pragma solidity ^0.4.24;

/*
* ---How to use:
*  1. Send from ETH wallet to the smart contract address
*     any amount ETH.
*  2. Claim your profit by sending 0 ether transaction (1 time per hour)
*  3. If you earn more than 200%, you can withdraw only one finish time
*/
contract TwoHundredPercent {

    using SafeMath for uint;
    mapping(address => uint) public balance;
    mapping(address => uint) public time;
    mapping(address => uint) public percentWithdraw;
    mapping(address => uint) public allPercentWithdraw;
    uint public stepTime = 1 hours;
    uint public countOfInvestors = 0;
    address public ownerAddress = 0xC24ddFFaaCEB94f48D2771FE47B85b49818204Be;
    uint projectPercent = 10;

    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);

    modifier userExist() {
        require(balance[msg.sender] > 0, "Address not found");
        _;
    }

    modifier checkTime() {
        require(now >= time[msg.sender].add(stepTime), "Too fast payout request");
        _;
    }

    function collectPercent() userExist checkTime internal {
        if ((balance[msg.sender].mul(2)) <= allPercentWithdraw[msg.sender]) {
            balance[msg.sender] = 0;
            time[msg.sender] = 0;
            percentWithdraw[msg.sender] = 0;
        } else {
            uint payout = payoutAmount();
            percentWithdraw[msg.sender] = percentWithdraw[msg.sender].add(payout);
            allPercentWithdraw[msg.sender] = allPercentWithdraw[msg.sender].add(payout);
            msg.sender.transfer(payout);
            emit Withdraw(msg.sender, payout);
        }
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

    function payoutAmount() public view returns(uint256) {
        uint256 percent = percentRate();
        uint256 different = now.sub(time[msg.sender]).div(stepTime);
        uint256 rate = balance[msg.sender].mul(percent).div(1000);
        uint256 withdrawalAmount = rate.mul(different).div(24).sub(percentWithdraw[msg.sender]);

        return withdrawalAmount;
    }

    function deposit() private {
        if (msg.value > 0) {
            if (balance[msg.sender] == 0) {
                countOfInvestors += 1;
            }
            if (balance[msg.sender] > 0 && now > time[msg.sender].add(stepTime)) {
                collectPercent();
                percentWithdraw[msg.sender] = 0;
            }
            balance[msg.sender] = balance[msg.sender].add(msg.value);
            time[msg.sender] = now;

            ownerAddress.transfer(msg.value.mul(projectPercent).div(100));
            emit Invest(msg.sender, msg.value);
        } else {
            collectPercent();
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
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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