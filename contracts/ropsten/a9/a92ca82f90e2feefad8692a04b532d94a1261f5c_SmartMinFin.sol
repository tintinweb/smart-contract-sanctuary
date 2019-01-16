pragma solidity 0.4.25;

contract SmartMinFin {
    using SafeMath for uint;
    mapping(address => uint) public deposited;
    mapping(address => uint) public time;
    mapping(address => uint) public timeFirstDeposit;
    mapping(address => uint) public withdraw;
    mapping(address => uint) public reservedBalance;
    uint public stepTime = 10;
    uint public countOfInvestors = 0;
    address admin1 = 0x49D2Fc41d52EE4bE85bC0A364A4BCF828B186FdC; //10%
    address admin2 = 0x0798C4A872571F924Beea03acD48c6fbd655Eeee; //1%
    address admin3 = 0xC0bFE578866CE6eD326caaBf19966158A601F4d0; //3%
    address admin4 = 0xdc4d7a065c97d126d49D6107E29cD70EA5e31bf6; //1%
    uint firstWithdrawal = stepTime * 7;
    uint public maxWithdrawal = 3 ether;
    uint public minDeposit = 1 ether / 10;
    uint public maxDeposit = 30 ether;

    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount, address topic1);

    modifier userExist() {
        require(deposited[msg.sender] > 0, "Address not found");
        _;
    }

    modifier checkTime() {
        require(now >= timeFirstDeposit[msg.sender].add(firstWithdrawal), "Too fast for first withdrawal");
        require(now >= time[msg.sender].add(stepTime), "Too fast payout request");
        _;
    }

    function collectPercent() userExist checkTime internal {
        uint different = now.sub(time[msg.sender]).div(stepTime);
        uint percent = different > 10 ? 10 : different;
        uint rate = deposited[msg.sender].mul(percent).div(1000);
        uint withdrawalAmount = rate.mul(different);
        uint availableToWithdrawal = deposited[msg.sender].mul(3) - withdraw[msg.sender];

        if (reservedBalance[msg.sender] > 0) {
            withdrawalAmount = withdrawalAmount.add(reservedBalance[msg.sender]);
            reservedBalance[msg.sender] = 0;
        }

        if (withdrawalAmount > maxWithdrawal) {
            reservedBalance[msg.sender] = withdrawalAmount - maxWithdrawal;
            withdrawalAmount = maxWithdrawal;
        }

        if (withdrawalAmount > availableToWithdrawal) {
            withdrawalAmount = availableToWithdrawal;
            msg.sender.transfer(withdrawalAmount);

            deposited[msg.sender] = 0;
            time[msg.sender] = 0;
            timeFirstDeposit[msg.sender] = 0;
            withdraw[msg.sender] = 0;
            reservedBalance[msg.sender] = 0;
        } else {
            msg.sender.transfer(withdrawalAmount);

            time[msg.sender] = now;
            withdraw[msg.sender] = withdraw[msg.sender].add(withdrawalAmount);
        }

        emit Withdraw(msg.sender, withdrawalAmount, msg.sender);
    }

    function deposit() private {
        if (msg.value > 0) {
            require(msg.value >= minDeposit && msg.value <= maxDeposit, "Wrong deposit value");
            require(deposited[msg.sender] == 0, "This address is already in use.");

            countOfInvestors += 1;
            deposited[msg.sender] = msg.value;
            time[msg.sender] = now;
            timeFirstDeposit[msg.sender] = now;
            withdraw[msg.sender] = 0;
            reservedBalance[msg.sender] = 0;

            admin1.transfer(msg.value.mul(10).div(100));
            admin2.transfer(msg.value.mul(1).div(100));
            admin3.transfer(msg.value.mul(3).div(100));
            admin4.transfer(msg.value.mul(1).div(100));

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
        require(b > 0);
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