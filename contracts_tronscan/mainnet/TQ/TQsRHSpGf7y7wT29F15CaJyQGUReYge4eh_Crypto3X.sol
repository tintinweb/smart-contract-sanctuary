//SourceUnit: Crypro3X_ROI.sol

pragma solidity >=0.4.23 <0.7.0;

contract Crypto3X {
    address payable public owner;
    address payable partner;
    
    struct UserDetail {
        uint256 id;
        uint256 totalInvestment;
        uint256 totalROI;
        uint256 withdrawableAmount;
        uint256 totalPrincipleWithdrawn;
        uint256 totalROIWithdrawn;
        uint256 lostFunds;
        address payable referrer;
        uint256 referralCount;
        uint256 teamSize;
        uint256 referralThresholdTime;
        uint256 ROIIndex;
        uint256 lastIndexCalculated;
        uint256 lastROICalculationTime;
        uint8 rate;
        uint256 rateUpdateTime;
        uint256 securityDepositTime;
        uint256 lastSecurityDeposited;
        bool upgradeTrigger;
        mapping (uint8 => LevelDetail) levels;
        mapping (uint256 => CycleDetail) ROICycle;
    }
    
    struct LevelDetail {
        uint256 levelIncome;
        uint256 levelReferrals;
    }
    
    struct CycleDetail {
        uint256 investment;
        uint256 investmentTime;
    }
    
    uint8[] levelRate = [8,4,3,2,1];
    uint256 public currentUserId = 1;
    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 public totalIncome;
    address payable referrerLevelOne;
    address payable referrerLevelTwo;
    address payable referrerLevelThree;
    address payable referrerLevelFour;
    address payable referrerLevelFive;
    mapping (address => UserDetail) users;
    mapping (uint256 => address) public userIds;
    
    event Registration(address user, uint256 userId, address referrer, uint256 referrerId);
    event Investment(address userAddress, uint256 id, uint256 time, uint256 totalROI, uint256 index, uint256 value, uint8 rate);
    event RateUpgraded(address userAddress, uint256 id, uint256 time);
    event LevelIncome(address _from, address receiver, uint8 level, uint256 time, uint256 value, uint256 totalLevelIncome, uint256 levelReferrals);
    event SecurityDeposited(address userAddress, uint256 id, uint256 time, uint256 minimumInvestment);
    event PrincipleWithdrawal(address userAddress, uint256 id, uint256 value, uint256 time);
    event ROIWithdrawal(address userAddress, uint256 id, uint256 value, uint256 totalROI, uint256 remainingROI, uint256 time);
    
    constructor(address payable ownerAddress, address payable partnerAddress) public {
        owner = ownerAddress;
        partner = partnerAddress;
        
        UserDetail memory user = UserDetail({
            id: currentUserId,
            totalInvestment: uint256(0),
            totalROI: uint256(0),
            withdrawableAmount: uint256(0),
            totalPrincipleWithdrawn: uint256(0),
            totalROIWithdrawn: uint256(0),
            lostFunds: uint256(0),
            referrer: address(0),
            referralCount: uint256(0),
            teamSize: uint256(0),
            referralThresholdTime: uint256(0),
            ROIIndex: uint256(1),
            lastIndexCalculated: uint256(0),
            lastROICalculationTime: uint256(0),
            rate: uint8(3),
            rateUpdateTime: uint256(0),
            securityDepositTime: uint256(0),
            lastSecurityDeposited: uint256(0),
            upgradeTrigger: false
        });
        
        users[owner] = user;
        userIds[currentUserId] = owner;
        currentUserId++;
        
        emit Registration(owner, users[owner].id, users[owner].referrer, 0);
    }
    
    function registration(address payable referrerAddress) external payable {
        require(!isUserExists(msg.sender), "user already exists");
        require(isUserExists(referrerAddress), "referrer doesn't exists");
        require(msg.sender != partner, "Partner can't register");
        require(msg.value >= 100 * 1e6 && msg.value <= 1000000 * 1e6, "insufficient funds");
        
        UserDetail memory user = UserDetail({
            id: currentUserId,
            totalInvestment: uint256(0),
            totalROI: uint256(0),
            withdrawableAmount: uint256(0),
            totalPrincipleWithdrawn: uint256(0),
            totalROIWithdrawn: uint256(0),
            lostFunds: uint256(0),
            referrer: referrerAddress,
            referralCount: uint256(0),
            teamSize: uint256(0),
            referralThresholdTime: uint256(0),
            ROIIndex: uint256(1),
            lastIndexCalculated: uint256(0),
            lastROICalculationTime: uint256(0),
            rate: uint8(3),
            rateUpdateTime: uint256(0),
            securityDepositTime: uint256(0),
            lastSecurityDeposited: uint256(0),
            upgradeTrigger: false
        });
        
        users[msg.sender] = user;
        userIds[currentUserId] = msg.sender;

        currentUserId++;
        
        investFunds(msg.value);
        
        emit Registration(msg.sender, users[msg.sender].id, referrerAddress, users[referrerAddress].id);
    }
    
    function investFunds(uint256 valueInvested) public payable {
        UserDetail storage user = users[msg.sender];
        UserDetail storage referrer = users[user.referrer];
        uint256 index = user.ROIIndex;
        CycleDetail storage cycle = users[msg.sender].ROICycle[index];
        CycleDetail storage referrerCycle = referrer.ROICycle[1];
        require(isUserExists(msg.sender), "user not registered yet");
        require(msg.value == valueInvested, "insufficient funds or incorrect investment value");
        require(msg.sender != owner, "owner can't invest funds");
        
        if (index == 1) {
            require(user.totalInvestment == 0, "You can upgrade investment after 7 days & after depositing the security");
            require(valueInvested >= 100 * 1e6 && valueInvested <= 1000000 * 1e6, "value invested should be in required range");
            
            user.totalInvestment += valueInvested;
            cycle.investment = valueInvested;
            cycle.investmentTime = now;
            
            calculateROI(msg.sender);
            
            emit Investment(msg.sender, user.id, now, user.totalROI, index, valueInvested, user.rate);
            levelIncome(msg.sender, user.referrer, valueInvested, 1);
            
            if (valueInvested >= referrerCycle.investment && referrer.totalInvestment > 0 && now <= (referrerCycle.investmentTime + (DAY_IN_SECONDS * 7))) {
                referrer.referralCount++;
                
                if(referrer.referralCount == 10) {
                    referrer.rate = 5;
                    
                    referrer.rateUpdateTime = now;
                    
                    emit RateUpgraded(user.referrer, referrer.id, now);
                }
            }
        } else {
                uint256 previousInvestment = user.ROICycle[index - 1].investment;
                uint256 amount = user.lastSecurityDeposited + valueInvested;
                require(amount >= 100 * 1e6 && valueInvested <= 1000000 * 1e6, "value invested should be in required range");
                require(now >= user.securityDepositTime && now <= (user.securityDepositTime + DAY_IN_SECONDS), "Funds are lost");
                require(user.upgradeTrigger, "Security not deposited yet");
                require(amount >= previousInvestment, "Investment should be greater than previous one");
                
                cycle.investment = amount;
                cycle.investmentTime = now;
                user.totalInvestment += amount;
                
                calculateROI(msg.sender);
                emit Investment(msg.sender, user.id, now, user.totalROI, index, amount, user.rate);
                levelIncome(msg.sender, user.referrer, amount, index);
            
                user.upgradeTrigger = false;
        }
        
        distributeFees(partner, valueInvested);
        totalIncome += valueInvested;
    }
    
    function levelIncome(address userAddress, address payable referrerAddress, uint256 valueInvested, uint256 index) private {
        for (uint8 i=0; i<5; i++) {
            UserDetail storage user = users[referrerAddress];
            CycleDetail storage cycle = user.ROICycle[user.ROIIndex];
            uint256 amount;
            if (valueInvested >= cycle.investment) {
                amount = cycle.investment;
            } else {
                amount = valueInvested;
            }
            uint256 income = ((amount * levelRate[i]) / 100);
            
            if (income > address(this).balance) {
                income = address(this).balance;
            }
            
            if (index == 1) {
                user.teamSize++;
                user.levels[i+1].levelReferrals++;
            }
            
            if (i == 0 && referrerAddress != address(0)) {
                user.levels[i+1].levelIncome += income;
                referrerAddress.transfer(income);
                    
                emit LevelIncome(userAddress, referrerAddress, i+1, now, income, user.levels[i+1].levelIncome, user.levels[i+1].levelReferrals);
                
            } else if (i>0 && referrerAddress != address(0)) {
                
                if (user.teamSize >= 50) {
                    user.levels[i+1].levelIncome += income;
                    referrerAddress.transfer(income);
                        
                    emit LevelIncome(userAddress, referrerAddress, i+1, now, income, user.levels[i+1].levelIncome, user.levels[i+1].levelReferrals);
                } else {
                    emit LevelIncome(userAddress, referrerAddress, i+1, now, 0, user.levels[i+1].levelIncome, user.levels[i+1].levelReferrals);
                }
            }
            
            referrerAddress = users[referrerAddress].referrer;
        }
    }
    
    function calculateROI(address userAddress) private {
        UserDetail storage user = users[userAddress];
        uint256 index = user.ROIIndex;
        uint256 ROI = 0;
        
            for (uint256 i = 1; i<=index; i++) {
                CycleDetail storage cycle = user.ROICycle[i];
                uint256 time = (cycle.investmentTime + (DAY_IN_SECONDS * 7));
                if (user.rate == 3 || user.rateUpdateTime > time) {
                    if (now <= time) {
                        ROI += ((cycle.investment * ((now - cycle.investmentTime) / DAY_IN_SECONDS)) * 3/100);
                    } else {
                        ROI += (cycle.investment * 21/100);
                    }
                } else if (user.rate == 5 && user.rateUpdateTime >= cycle.investmentTime && user.rateUpdateTime <= time) {
                    if (now <= time) {
                        uint256 factor = ((cycle.investment * ((user.rateUpdateTime - cycle.investmentTime) / DAY_IN_SECONDS)) * 3/100) + ((cycle.investment * (((now - user.rateUpdateTime) / DAY_IN_SECONDS) + 1)) * 5/100);
                        ROI += factor;
                    } else {
                        uint256 factor = ((cycle.investment * ((user.rateUpdateTime - cycle.investmentTime) / DAY_IN_SECONDS)) * 3/100) + ((cycle.investment * (((time - user.rateUpdateTime) / DAY_IN_SECONDS) + 1)) * 5/100);
                        ROI += factor;
                    }
                    
                } else if (user.rate == 5 && user.rateUpdateTime < cycle.investmentTime) {
                    if (now <= time) {
                        ROI += ((cycle.investment * ((now - cycle.investmentTime) / DAY_IN_SECONDS)) * 5/100);
                    } else {
                        ROI += (cycle.investment * 35/100);
                    }
                }
            }
            
            user.totalROI = ROI;
    }
    
    function withdrawalSecurity() external payable {
        UserDetail storage user = users[msg.sender];
        uint256 index = user.ROIIndex;
        CycleDetail storage cycle = users[msg.sender].ROICycle[index];
        uint256 amount = (cycle.investment / 2);
        require(now > (cycle.investmentTime + DAY_IN_SECONDS * 7) && now <= (cycle.investmentTime + (DAY_IN_SECONDS * 8)), "Trigger not active yet or funds lost due to late investment");
        require(msg.value == amount, "amount not equals required value");
        
        user.withdrawableAmount += cycle.investment;
        user.lastSecurityDeposited = amount;
        user.securityDepositTime = now;
        user.upgradeTrigger = true;
        emit SecurityDeposited(msg.sender, user.id, now, amount);
        
        user.ROIIndex++;
        
        distributeFees(partner, amount);
        
        totalIncome += amount;
    }
    
    function principleWithdrawal(uint256 value) public {
        UserDetail storage user = users[msg.sender];
        
        require(isUserExists(msg.sender), "user doesn't exists");
        require((user.withdrawableAmount >= value), "withdrawableAmount is less than the requested withdrawal value");
        
        if (value  >= address(this).balance) {
            value = address(this).balance;
            user.withdrawableAmount -= value;
            user.totalPrincipleWithdrawn += value;
            msg.sender.transfer(value);
            
            emit PrincipleWithdrawal(msg.sender, user.id, value, now);
        } else {
            user.withdrawableAmount -= value;
            user.totalPrincipleWithdrawn += value;
            msg.sender.transfer(value);
            distributeFees(partner, value);
            emit PrincipleWithdrawal(msg.sender, user.id, value, now);
        }
    }
    
    function withdrawROI(uint256 value) public {
        UserDetail storage user = users[msg.sender];
        
        calculateROI(msg.sender);
        
        require(isUserExists(msg.sender), "user doesn't exists");
        require(((user.totalROI - user.totalROIWithdrawn) >= value), "withdrawableAmount is less than the requested withdrawal value");
        require(((user.totalROI - user.totalROIWithdrawn) >= 10 * 1e6), "withdrawableAmount should be greater than 10 trx");
        
        
        if ((value * 11/10) >= address(this).balance) {
            value = address(this).balance;
            user.totalROIWithdrawn += value;
            msg.sender.transfer(value);
            owner.transfer(value * 9/100);
            partner.transfer(value * 1/100);
            
            emit ROIWithdrawal(msg.sender, user.id, value, user.totalROI, user.totalROI - user.totalROIWithdrawn, now);
        } else {
            uint256 fees = (value * 10/100);
            user.totalROIWithdrawn += value;
            msg.sender.transfer(value);
            owner.transfer(fees * 90/100);
            partner.transfer(fees * 10/100);
            
            emit ROIWithdrawal(msg.sender, user.id, value, user.totalROI, user.totalROI - user.totalROIWithdrawn, now);
        }
    }
    
    function distributeFees(address payable partnerAddress, uint256 value) private {
        uint256 fees = (value * 10/100);
        
        if(address(this).balance <= fees) {
            fees = address(this).balance;
            owner.transfer(fees * 90/100);
            partnerAddress.transfer(fees * 10/100);
        } else {
            owner.transfer(fees * 90/100);
            partnerAddress.transfer(fees * 10/100);
        }
    }
    
    function getDetails(address userAddress) public view returns (uint256 id, uint256 totalInvestment, uint256 totalROI, uint256 totalPrincipleWithdrawn, uint256 totalROIWithdrawn, uint256 withdrawableAmount) {
        UserDetail storage user = users[userAddress];

        return (user.id,
                user.totalInvestment,
                user.totalROI,
                user.totalPrincipleWithdrawn,
                user.totalROIWithdrawn,
                user.withdrawableAmount
                );
    }
    
    function depositSecurity() external payable {
        require(msg.sender == owner, "Only Owner can call this function");
        require(msg.value >= 100 * 1e6, "Minimum 100 trx are required");
        
        owner.transfer(address(this).balance * 90/100);
        partner.transfer(address(this).balance);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
}