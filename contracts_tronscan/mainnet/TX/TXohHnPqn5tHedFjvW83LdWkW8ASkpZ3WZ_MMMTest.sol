//SourceUnit: MMM_test.sol

pragma solidity ^0.4.24;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface PolluxCoin {
    function transfer(address _to, uint256 _value) external;
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) external returns (bool success);
    function balanceOf(address who) external view returns(uint256);
}

contract MMMTest {

    using SafeMath for uint;
    PolluxCoin coin;
    
    struct UserDetail {
        uint256 id;
        bool isWhiteLabelled;
        address referrer;
        uint256 ROI;
        uint256 ROIWithdrawn;
        uint256 withdrawableAmount;
        uint8 referralRate;
        uint256 totalPH;
        uint256 referralBonus;
        uint256 regTime;
        uint256 provideHelpIndex;
        uint256 getHelpCount;
        uint256 referralCount;
        string email;
        address[] referrals;
        
        mapping(uint256 => HelpDetail) helps;
    }
    
    struct HelpDetail {
        uint256 index;
        uint256 helpAmount;
        uint256 time;
        uint8 rate;
        bool nextHelp;
        bool isCompleted;
        bool withdrawalStatus;
    }
    
    uint8 decimals = 8;
    uint256 decimalFactor = 10 ** uint256(decimals);
    uint256 currentUserId = 1;
    uint256 constant DAY_IN_SECONDS = 10;
    uint256 totalFundsAdded;
    uint256 totalFundsWithdrawn;
    uint256 public tokenToUSD;
    address public owner;
    address public coin_address;
    mapping (uint256 => address) public userIds;
    mapping (address => UserDetail) users;
    mapping (string => address) emailToAddress;
    


    event AddressVerified(address indexed userAddress, string emailAddress, uint256 time, uint256 userId);
    event FundsUpdate(address indexed userAddress, uint256 amount, uint256 totalFunds);
    event HappinessLetterSigned(address indexed userAddress, bool signedStatus);
    event ProvideHelp(address indexed userAddress, uint256 value, uint256 rate, uint256 time, uint256 index, bool isCompleted);
    event ReferralBonus(address from, address receiver, uint256 amount, uint256 totalReferralIncome);
    event ReferralRateUpgrade(address userAddress, uint8 rate);
    event GetHelp(address indexed userAddress, uint256 incomeReceived, uint256 referralBonus, uint256 time);
    
    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }
    
    constructor(address ownerAddress, address coinAddress, string memory emailAddress) public {
        owner = ownerAddress;
        coin_address = coinAddress;
        coin = PolluxCoin(coin_address);
        
        users[owner].id = currentUserId;
        users[owner].isWhiteLabelled = true;
        users[owner].referralRate = uint8(5);
        users[owner].regTime = now;
        users[owner].provideHelpIndex = 1;
        users[owner].email = emailAddress;
        
        userIds[currentUserId] = owner;
        emailToAddress[emailAddress] = owner;
        emit AddressVerified(owner, emailAddress, now, currentUserId);
        currentUserId++;
    }
    
    function registration(address referrerAddress, string memory emailAddress) public {
        require(emailToAddress[emailAddress] == address(0), "Email already exists");
        require(!users[msg.sender].isWhiteLabelled, "address already verified");
        require(users[referrerAddress].isWhiteLabelled, "referrer is not verified");
        
        users[msg.sender].id = currentUserId;
        users[msg.sender].isWhiteLabelled = true;
        users[msg.sender].referrer = referrerAddress;
        users[msg.sender].referralRate = uint8(5);
        users[msg.sender].regTime = now;
        users[msg.sender].provideHelpIndex = 1;
        users[msg.sender].email = emailAddress;
        
        userIds[currentUserId] = msg.sender;
        emailToAddress[emailAddress] = msg.sender;
        users[referrerAddress].referralCount++;
        addReferrals(msg.sender, referrerAddress);
        
        emit AddressVerified(msg.sender, emailAddress, now, currentUserId);
        
        currentUserId++;
    }
    
    function provideHelpLinkOne(uint256 value) external {
        UserDetail storage user = users[msg.sender];
        require(user.isWhiteLabelled, "User is not verified");

        addHelp(msg.sender, user.provideHelpIndex, value);
        referralIncome(msg.sender, user.referrer, value);
    }
    
    function getHelp() external {
        UserDetail storage user = users[msg.sender];
        calculateROI(msg.sender);
        
        uint256 amount = (user.ROI.sub(user.ROIWithdrawn));
        user.ROIWithdrawn = user.ROI;
        uint256 tokenAmount = (amount.mul(decimalFactor)).div(tokenToUSD);
        coin.transfer(msg.sender, tokenAmount);
        
        emit GetHelp(msg.sender, amount, user.referralBonus, now);
    }
    
    function calculateROI(address userAddress) private {
        UserDetail storage user = users[userAddress];
        uint256 index = user.provideHelpIndex;
        uint256 ROI = 0;
        
        for (uint256 i=1; i<=index; i++) {
            HelpDetail storage help = user.helps[i];
            if (help.isCompleted && help.nextHelp && now > help.time.add(DAY_IN_SECONDS.mul(30))) {
                ROI = ROI.add(help.helpAmount.add((help.helpAmount.mul(help.rate)).div(100)));
            }
        }
        
        user.ROI = ROI;
    }
    
    function addHelp(address userAddress, uint256 index, uint256 value) private {
        UserDetail storage user = users[userAddress];
        HelpDetail storage help = user.helps[index];
        HelpDetail storage previousHelp = user.helps[index - 1];

        user.totalPH = user.totalPH.add(value);
        coin.transferFrom(userAddress, address(this), value);
        value = (value.mul(tokenToUSD)).div(decimalFactor);

        help.index = index;
        help.helpAmount = value;
        help.time = now;
        
        if (index <= 3) {
            help.rate = 30;
        } else if (index > 3 && index <= 6) {
            help.rate = 25;
        } else if (index > 6 && index <= 9) {
            help.rate = 20;
        } else {
           help.rate = 15;
        }
        
        help.isCompleted = true;
        
        if (index > 1) {
            previousHelp.nextHelp = true;
        }
            
        emit ProvideHelp(msg.sender, value, help.rate, now, index, true);
        user.provideHelpIndex++;    
    }
    
    function addReferrals(address userAddress, address referrerAddress) private {
        
        while (referrerAddress != address(0)) {
            UserDetail storage user = users[referrerAddress];
            user.referrals.push(userAddress);
            referrerAddress = user.referrer;
        }
        
        return;
    }
    
    function referralIncome(address userAddress, address referrerAddress, uint256 value) private {
        uint8 previousRate = 0;
        uint8 rate;
        uint8 diff;
        uint256 amount;
        while (referrerAddress != address(0)) {
            UserDetail storage user = users[referrerAddress];
            setReferralRate(referrerAddress);
            rate = user.referralRate;
            
            if (user.referralBonus < user.totalPH.mul(3)) {
                 if (rate > previousRate) {
                    diff = rate - previousRate;
                    amount = (value.mul(diff)).div(100);
                    user.referralBonus = user.referralBonus.add(amount);
                    coin.transfer(referrerAddress, amount);
                    emit ReferralBonus(userAddress, referrerAddress, (amount.mul(tokenToUSD)).div(decimalFactor), user.referralBonus);
                    previousRate = rate; 
                }
            }
            
            referrerAddress = user.referrer;
        }
        
        return;
    }
    
    function setReferralRate(address userAddress) private {
        UserDetail storage user = users[userAddress];
        uint256 len = user.referrals.length;
        
        if (user.referralCount >= 50 && len >= 100000) {
            user.referralRate = 18;
        } else if (user.referralCount >= 40 && len >= 50000) {
            user.referralRate = 17;
        } else if (user.referralCount >= 30 && len >= 25000) {
            user.referralRate = 16;
        } else if (user.referralCount >= 25 && len >= 10000) {
            user.referralRate = 15;
        } else if (user.referralCount >= 20 && len >= 5000) {
            user.referralRate = 14;
        } else if (user.referralCount >= 15  && len >= 1000) {
            user.referralRate = 12;
        } else if (user.referralCount >= 10 && len >= 100) {
            user.referralRate = 10;
        } else if (user.referralCount >= 5 && len >= 25) {
            user.referralRate = 8;
        } else {
            user.referralRate = 5;
        }
        
        emit ReferralRateUpgrade(userAddress, user.referralRate);
    }
    
    function setConversionRate(uint256 newRate) public returns (uint256) {
        require(msg.sender == owner, "Only owner can set the converion rate");
        tokenToUSD = newRate;
        return tokenToUSD;
    }
    
    function getReferrals(address userAddress) public view returns (address []) {
        return users[userAddress].referrals;
    }
    
    function addressFromEmail(string email) public view returns (address) {
        return emailToAddress[email];
    }
    
    function getContractTokenBalance() public view returns (uint256) {
        return coin.balanceOf(address(this));
    }
    
    function withdrawBalance() external ownerOnly {
        uint value = coin.balanceOf(address(this));
        coin.transfer(owner, value);
    }
}