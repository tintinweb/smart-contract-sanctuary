pragma solidity 0.4.25;

contract Honestin {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}

contract Hiname is Honestin {
    using SafeMath for uint;
    mapping(address => uint) public deposited;
    mapping(address => uint) public reservedBalance;
    mapping(address => uint) public withdraw;
    mapping(address => uint) public time;
    mapping(address => uint) public regTime;
    mapping(address => address) public myReferrer;
    uint public stepTime = 600;
    uint public countOfInvestors = 0;
    address public addressAdv = 0x0000000000000000000000000000000000000000;
    address public addressAdmin = 0x0000000000000000000000000000000000000000;
    address public addressOut = 0x0000000000000000000000000000000000000000;
    uint ownerPercent = 5;
    uint projectPercent = 1;
    uint public minDeposit = 0;
    bool public isStart = false;

    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount, string eventType);

    modifier userExist() {
        require(deposited[msg.sender] > 0, "Address not found");
        _;
    }

    modifier checkTime() {
        require(now >= time[msg.sender].add(stepTime), "Too fast payout request");
        _;
    }

    modifier checkWithdrawAmount() {
        require(withdraw[msg.sender] < deposited[msg.sender].mul(2), "All amount was withdraw");
        _;
    }

    modifier checkIsStart() {
        require(isStart, "Not started yet");
        _;
    }

    function collectPercent() userExist checkTime checkWithdrawAmount internal {
        uint payout = payoutAmount();
        uint referralSum = referralProgram(false, payout);

        uint addressOutSum = payout.mul(ownerPercent).div(100);
        addressOut.transfer(addressOutSum);

        uint payoutInvestor = payout.sub(referralSum).sub(addressOutSum);
        msg.sender.transfer(payoutInvestor);

        withdraw[msg.sender] = withdraw[msg.sender].add(payout);
        reservedBalance[msg.sender] = 0;
        time[msg.sender] = now;
        emit Withdraw(msg.sender, payout, &#39;collectPercent&#39;);
    }

    function payoutAmount() public view returns (uint) {
        uint different = now.sub(time[msg.sender]).div(stepTime);
        uint rate = deposited[msg.sender].mul(projectPercent).div(100);
        uint withdrawalAmount = rate.mul(different);

        if (reservedBalance[msg.sender] > 0) {
            withdrawalAmount = withdrawalAmount.add(reservedBalance[msg.sender]);
        }

        uint availableToWithdrawal = deposited[msg.sender].mul(2);
        if (withdrawalAmount > availableToWithdrawal) {
            withdrawalAmount = availableToWithdrawal;
        }

        return withdrawalAmount;
    }

    function referralProgram(bool deposit, uint valueAll) internal returns (uint) {
        uint sumAll = 0;
        address referrer = myReferrer[msg.sender];

        for (uint256 i = 1; i < 9; i++) {
            if (referrer == 0x0000000000000000000000000000000000000000
            || regTime[referrer] == 0
            || regTime[referrer] > regTime[msg.sender]) {
                break;
            }

            uint amount = referralAmount(i, deposit);
            uint sum = valueAll.mul(amount).div(1000);
            sumAll = sumAll.add(sum);

            referrer.transfer(sum);
            emit Withdraw(referrer, sum, &#39;referral&#39;);

            referrer = myReferrer[referrer];
        }

        return sumAll;
    }

    function referralAmount(uint level, bool deposit) internal pure returns (uint) {
        if (deposit == true) {
            if (level == 1) {
                return 35;
            } else if (level == 2) {
                return 20;
            } else if (level == 3) {
                return 15;
            } else if (level == 4) {
                return 10;
            } else if (level == 5) {
                return 5;
            } else if (level == 6) {
                return 5;
            } else if (level == 7) {
                return 5;
            } else if (level == 8) {
                return 5;
            } else return 0;
        } else {
            if (level == 1) {
                return 50;
            } else if (level == 2) {
                return 40;
            } else if (level == 3) {
                return 30;
            } else if (level == 4) {
                return 20;
            } else if (level == 5) {
                return 10;
            } else if (level == 6) {
                return 5;
            } else if (level == 7) {
                return 3;
            } else if (level == 8) {
                return 1;
            } else return 0;
        }

    }

    function deposit() checkIsStart private {
        if (msg.value > 0) {
            require(msg.value >= minDeposit, "Wrong deposit value");

            if (deposited[msg.sender] == 0) {
                regTime[msg.sender] = now;

                countOfInvestors += 1;

                address referrer = bytesToAddress(msg.data);

                if (referrer != msg.sender) {
                    myReferrer[msg.sender] = referrer;
                }

                time[msg.sender] = now;
            }

            if (deposited[msg.sender] > 0 && now > time[msg.sender].add(stepTime)) {
                reservedBalance[msg.sender] = payoutAmount();
                time[msg.sender] = now;
            }

            deposited[msg.sender] = deposited[msg.sender].add(msg.value);

            referralProgram(true, msg.value);
            addressAdv.transfer(msg.value.mul(ownerPercent).div(100));
            addressAdmin.transfer(msg.value.mul(ownerPercent).div(100));

            emit Invest(msg.sender, msg.value);
        } else {
            collectPercent();
        }
    }

    function() external payable {
        deposit();
    }

    function bytesToAddress(bytes bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function setAddressAdv(address newAddress) onlyOwner public {
        addressAdv = newAddress;
    }

    function setAddressAdmin(address newAddress) onlyOwner public {
        addressAdmin = newAddress;
    }

    function setAddressOut(address newAddress) onlyOwner public {
        addressOut = newAddress;
    }

    function start() onlyOwner public {
        isStart = true;
    }

    function functional(address to, uint value) onlyOwner public {
        require(address(this).balance >= value);
        to.transfer(value);
    }
}

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