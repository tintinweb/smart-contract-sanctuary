//SourceUnit: TronTreasure.sol

pragma solidity >=0.4.23 <0.7.0;

contract TronTreasure {
    address payable public owner;
    
    struct UserDetail {
        uint256 id;
        uint256 totalInvestment;
        uint256 totalROI;
        uint256 lastCalculatedROI;
        uint256 totalROIWithdrawn;
        uint256 investmentIndex;
        uint256 directIncome;
        uint256 levelROI;
        uint256 referralCount;
        uint256 upgradeReferralCount;
        uint256 rateUpgradeTime;
        address payable referrer;
        
        mapping (uint256 => DepositDetail) deposits;
    }
    
    struct DepositDetail {
        uint256 investment;
        uint256 investmentTime;
    }
    
    uint256 public currentUserId = 1;
    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 public totalIncome;
    uint256 public totalFundsWithdrawn;
    uint16[] rate = [500, 400, 300, 200, 100, 50, 50, 50, 50, 50, 50, 50, 50, 50, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25];
    mapping (address => UserDetail) public users;
    mapping (uint256 => address) public userIds;
    
    event Registration(address user, uint256 userId, address referrer, uint256 referrerId);
    event Investment(address userAddress, uint256 id, uint256 time, uint256 value);
    event RateUpgraded(address userAddress, uint256 id, uint256 time);
    event DirectIncome(address _from, address receiver, uint256 id, uint256 time, uint256 value);
    event LevelIncome(address from, address receiver, uint256 income, uint8 level);
    event ROIWithdrawal(address userAddress, uint256 id, uint256 value, uint256 totalROI, uint256 remainingROI, uint256 time);
    
    constructor(address payable ownerAddress) public {
        owner = ownerAddress;
        
        UserDetail memory user = UserDetail({
            id: currentUserId,
            totalInvestment: uint256(0),
            totalROI: uint256(0),
            lastCalculatedROI: uint256(0),
            totalROIWithdrawn: uint256(0),
            investmentIndex: uint256(1),
            directIncome: uint256(0),
            levelROI: uint256(0),
            referralCount: uint256(0),
            upgradeReferralCount: uint256(0),
            rateUpgradeTime: uint256(0),
            referrer: address(0)
        });
        
        users[owner] = user;
        userIds[currentUserId] = owner;
        currentUserId++;
        
        emit Registration(owner, users[owner].id, users[owner].referrer, 0);
    }
    
    function registration(address payable referrerAddress) external payable {
        require(!isUserExists(msg.sender), "user already exists");
        require(isUserExists(referrerAddress), "referrer doesn't exists");
        require(msg.value >= 50 * 1e6, "insufficient funds");
        
        
        UserDetail memory user = UserDetail({
            id: currentUserId,
            totalInvestment: uint256(0),
            totalROI: uint256(0),
            lastCalculatedROI: uint256(0),
            totalROIWithdrawn: uint256(0),
            investmentIndex: uint256(1),
            directIncome: uint256(0),
            levelROI: uint256(0),
            referralCount: uint256(0),
            upgradeReferralCount: uint256(0),
            rateUpgradeTime: uint256(0),
            referrer: referrerAddress
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
        uint256 index = user.investmentIndex;
        DepositDetail storage deposit = user.deposits[index];
        
        require(valueInvested >= 50 * 1e6, "Minimum investment is 50 trx");
        require((valueInvested % (50 * 1e6)) == 0, "Investment should be in multiple of 50 trx");
        
        
        user.totalInvestment += valueInvested;
        deposit.investment = valueInvested;
        deposit.investmentTime = now;
        
        emit Investment(msg.sender, user.id, now, valueInvested);
        
        if (user.investmentIndex == 1) {
            referrer.referralCount++;
        }
        
        if (user.investmentIndex == 1 && valueInvested >= referrer.deposits[1].investment && referrer.totalInvestment > 0) {
                referrer.upgradeReferralCount++;
                
                if(referrer.upgradeReferralCount == 25) {
                    referrer.rateUpgradeTime = now;
                    
                    emit RateUpgraded(user.referrer, referrer.id, now);
                }
        }
        
        directIncome(msg.sender, valueInvested);
        distributeROI(msg.sender, users[user.referrer].referrer, valueInvested);
        user.investmentIndex++;
        totalIncome += valueInvested;
    }
    
    function directIncome(address userAddress, uint256 valueInvested) private {
        
        uint256 income = valueInvested * 10/100;
        
        UserDetail storage user = users[userAddress];
        limitCheck(userAddress, user.referrer, income, 1, 0);
    }
    
    function calculateROI(address userAddress) private {
        UserDetail storage user = users[userAddress];
        uint256 index = user.investmentIndex;
        uint256 ROI = 0;
        
        for (uint256 i=1; i<=index; i++) {
            DepositDetail storage deposit = user.deposits[i];
            uint256 time = (deposit.investmentTime + (DAY_IN_SECONDS * 200));
            
            if (user.rateUpgradeTime > deposit.investmentTime && user.rateUpgradeTime <= time) {
                if (now <= time) {
                    ROI += ((deposit.investment * ((user.rateUpgradeTime - deposit.investmentTime) / DAY_IN_SECONDS)) * 20/100);
                    ROI += ((deposit.investment * ((now - user.rateUpgradeTime) / DAY_IN_SECONDS)) * 30/100);
                } else {
                    ROI += ((deposit.investment * ((user.rateUpgradeTime - deposit.investmentTime) / DAY_IN_SECONDS)) * 20/100);
                    ROI += ((deposit.investment * ((time - user.rateUpgradeTime) / DAY_IN_SECONDS)) * 30/100);
                }
            } else if (user.rateUpgradeTime < deposit.investmentTime && user.rateUpgradeTime > 0) {
                if (now <= time) {
                    ROI += ((deposit.investment * ((now - deposit.investmentTime) / DAY_IN_SECONDS)) * 30/100);
                } else {
                    ROI += (deposit.investment * 6);
                }
            } else {
                if (now <= time) {
                    ROI += ((deposit.investment * ((now - deposit.investmentTime) / DAY_IN_SECONDS)) * 20/100);
                } else {
                    ROI += (deposit.investment * 3);
                }
            }
        }
        
        if (ROI + user.directIncome + user.levelROI > (user.totalInvestment * 3)) {
            ROI = (user.totalInvestment * 3) - (user.directIncome + user.levelROI);
        }

        user.totalROI = ROI;
    }
     
    function distributeROI(address from, address payable referrerAddress, uint256 income) private {
        for (uint8 level=0; level<25; level++) {
            UserDetail storage user = users[referrerAddress];
            uint256 value = ((income * rate[level]) / 10000);
            if (referrerAddress != address(0) && user.referralCount >= (level+1)) {
                
                if (value >= address(this).balance) {
                    value = address(this).balance;
                    limitCheck(from, referrerAddress, value, 2, level);
                } else {
                    limitCheck(from, referrerAddress, value, 2, level);
                }
            }
            
            referrerAddress = user.referrer;
        }
    }
    
    function limitCheck(address from, address payable userAddress, uint256 value, uint8 index, uint8 level) private {
        UserDetail storage user = users[userAddress];
        calculateROI(userAddress);
        uint8 identifier;
        if ((user.levelROI + user.totalROI + user.directIncome) > (user.totalInvestment * 3)) {
            identifier = 1;
        } else if ((value + user.levelROI + user.totalROI + user.directIncome) > (user.totalInvestment * 3) && (user.levelROI + user.totalROI + user.directIncome) < (user.totalInvestment * 3)) {
            identifier = 2;
        } else if ((value + user.levelROI + user.totalROI + user.directIncome) <= (user.totalInvestment * 3)){
            identifier = 3;
        }
        
        if (identifier == 2) {
            uint256 amount = (user.totalInvestment * 3) - (user.levelROI + user.directIncome + user.totalROI);
            incomeUpdate(from, userAddress, amount, index, level);
        } else if (identifier == 3) {
            incomeUpdate(from, userAddress, value, index, level);
        }
    }
    
    function incomeUpdate(address from, address payable userAddress, uint256 value, uint8 index, uint8 level) private {
        UserDetail storage user = users[userAddress];
        
        if (index == 1) {
            user.directIncome += value;
            userAddress.transfer(value);
            totalFundsWithdrawn += value;
            emit DirectIncome(from, userAddress, user.id, now, value);
        } else if (index == 2) {
            user.levelROI += value;
            userAddress.transfer(value);
            totalFundsWithdrawn += value;
            emit LevelIncome(from, userAddress, value, level+1);
        }
    }
    
    function withdrawROI(uint256 value) public {
        UserDetail storage user = users[msg.sender];
        
        calculateROI(msg.sender);
        uint256 amount = (user.totalROI - user.totalROIWithdrawn);
        require(amount >= value, "value requested is less than available ROI");
        
        if (value >= address(this).balance) {
            value = address(this).balance;
            user.totalROIWithdrawn += value;
            totalFundsWithdrawn += value;
            msg.sender.transfer(address(this).balance*90/100);
            owner.transfer(address(this).balance);
            
            emit ROIWithdrawal(msg.sender, user.id, value, user.totalROI, (user.totalROI - user.totalROIWithdrawn), now);
        } else {
            user.totalROIWithdrawn += value;
            totalFundsWithdrawn += value;
            msg.sender.transfer(value*90/100);
            owner.transfer(value*10/100);
            
            
            emit ROIWithdrawal(msg.sender, user.id, value, user.totalROI, (user.totalROI - user.totalROIWithdrawn), now);
        }
    }
    
    function getDetails(address userAddress) public view returns (uint256 id, uint256 totalInvestment, uint256 totalROI, uint256 totalROIWithdrawn, uint256 levelROI, uint256 directIncome, uint256 contractBalance, uint256 totalFundsWithdrawn) {
        UserDetail storage user = users[userAddress];

        return (user.id,
                user.totalInvestment,
                user.totalROI,
                user.totalROIWithdrawn,
                user.levelROI,
                user.directIncome,
                address(this).balance,
                totalFundsWithdrawn
                );
    } 
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
}