//SourceUnit: TronAvail.sol

pragma solidity 0.5.10;


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
   

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
   
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract OldTronAvail {
    using SafeMath for uint256;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    address public owner;

    address payable public marketingAddress;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256 bonus;
        uint256 referrals;
        uint256 match_bonus;
        uint256 direct_bonus;
        uint256 payouts;
        mapping(address => UserReferralLevels) UserReferralCountsValue;

    }

    struct UserReferralLevels {
        uint256 level1;
        uint256 level2;
        uint256 level3;
    }

    mapping (address => User) public users;
    mapping(uint256 => address) public userIds;


    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserDownlineCount(address _addr) view external returns(uint256, uint256, uint256) {
        return (users[_addr].UserReferralCountsValue[_addr].level1, users[_addr].UserReferralCountsValue[_addr].level2, users[_addr].UserReferralCountsValue[_addr].level3);
    }
}

contract TronAvail {
    using SafeMath for uint256;

    uint256 constant public INVEST_MIN_AMOUNT = 100e6;
    uint256 public BASE_PERCENT = 10; //1%
    uint256[] public REFERRAL_PERCENTS = [50, 20, 10];
    uint256 public MARKETING_FEE = 120; //12%
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public CONTRACT_BALANCE_STEP = 3000000e6;
    uint256 constant public TIME_STEP = 1 days;
    uint8[] public ref_bonuses;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    address public owner;
    
    OldTronAvail public oldTronAvail;
    uint256 oldUserId = 1;

    address payable public marketingAddress;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256 bonus;
        uint256 referrals;
        uint256 match_bonus;
        uint256 direct_bonus;
        uint256 payouts;
        mapping(address => UserReferralLevels) UserReferralCountsValue;
    }

    struct UserReferralLevels {
        uint256 level1;
        uint256 level2;
        uint256 level3;
    }

    mapping (address => User) public users;
    mapping(uint256 => address) public userIds;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor(address payable marketingAddr, address oldTronAvailAddr) public {
        require(!isContract(marketingAddr));
        marketingAddress = marketingAddr;
        oldTronAvail = OldTronAvail(oldTronAvailAddr);
        owner = msg.sender;
        ref_bonuses.push(10); //1
        ref_bonuses.push(10); //2
        ref_bonuses.push(10); //3
        ref_bonuses.push(10); //4
        ref_bonuses.push(10); //5
        ref_bonuses.push(10); //6
        ref_bonuses.push(10); //7
        ref_bonuses.push(10); //8
        ref_bonuses.push(10); //9
        ref_bonuses.push(10); //10
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].referrer;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
           
            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;
               
                users[up].match_bonus += bonus;

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].referrer;
        }
    }


    function invest(address referrer) public payable {
        require(msg.value >= INVEST_MIN_AMOUNT, "investment less than min investment");

        marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
        emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));

        User storage user = users[msg.sender];
        users[referrer].referrals++;


        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                 if (upline != address(0)) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    users[upline].bonus = users[upline].bonus.add(amount);
                    if(i == 0){
                        users[upline].UserReferralCountsValue[upline].level1 = users[upline].UserReferralCountsValue[upline].level1.add(1);
                        users[upline].direct_bonus = users[upline].direct_bonus.add(amount);
                    } else if(i == 1){
                        users[upline].UserReferralCountsValue[upline].level2 = users[upline].UserReferralCountsValue[upline].level2.add(1);
                    } else if(i == 2){
                        users[upline].UserReferralCountsValue[upline].level3 = users[upline].UserReferralCountsValue[upline].level3.add(1);
                    }
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;

            }

        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalUsers = totalUsers.add(1);
            userIds[totalUsers] = msg.sender;
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(msg.value, 0, block.timestamp));

        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);

        emit NewDeposit(msg.sender, msg.value);

    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint256 userPercentRate = getUserPercentRate(msg.sender);

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
                } else {
                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }
                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
                    dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
                   
                }
               
                user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
                totalAmount = totalAmount.add(dividends);
            }
        }

        uint256 generationIncome = totalAmount;

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
            user.bonus = 0;
        }

        if(user.match_bonus > 0) {
            uint256 match_bonus = user.match_bonus;
            user.match_bonus = user.match_bonus.sub(match_bonus);
            totalAmount = totalAmount.add(match_bonus);
        }

        require(totalAmount > 0, "User has no dividends");

        //pay ref generation
        _refPayout(msg.sender, generationIncome);

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.payouts = user.payouts.add(totalAmount);

        user.checkpoint = block.timestamp;

        msg.sender.transfer(totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);

    }

    function getUserAvailable(address userAddress) public view returns(uint256) {
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractBalanceRate() public view returns (uint256) {
        uint256 contractBalance = address(this).balance;
        uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);
        return BASE_PERCENT.add(contractBalancePercent);
    }

    function getUserPercentRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 contractBalanceRate = getContractBalanceRate();
        if (isActive(userAddress)) {
            uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP);
            return contractBalanceRate.add(timeMultiplier);
        } else {
            return contractBalanceRate;
        }
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 userPercentRate = getUserPercentRate(userAddress);

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
                    dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
                }

                totalDividends = totalDividends.add(dividends);

                /// no update of withdrawn because that is view function

            }

        }

        return totalDividends;
    }

    function getUserCheckpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns(address) {
        return users[userAddress].referrer;
    }
   
    function getUserReferralBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].bonus;
    }

    function getUserAvailableBalanceForWithdrawal(address userAddress) public view returns(uint256) {
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
                return true;
            }
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn);
        }

        return amount;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function getHoldBonus(address userAddress) public view returns(uint256) {
        if(getUserPercentRate(userAddress) <= getContractBalanceRate()
            || getUserPercentRate(userAddress).sub(getContractBalanceRate()) < BASE_PERCENT) {
                return 0;
        } else {
            return getUserPercentRate(userAddress).sub(getContractBalanceRate()).sub(BASE_PERCENT);
        }
    }

    function setMinuteRate(uint256 _roiPer) public returns(bool) {
        require(msg.sender == owner, "Access denied");
        BASE_PERCENT = _roiPer;
        return true;
    }
    
    function() external payable {
        if(msg.sender != owner) {
            invest(owner);
        }
    }

    function startSync(uint256 limit) public {
        require(address(oldTronAvail) != address(0), "Initialize closed");
        
        for (uint256 i = oldUserId; i <= limit; i++) {
            User memory oldUserStruct;
            
            address oldUser = oldTronAvail.userIds(oldUserId);
            
            (oldUserStruct.checkpoint, 
            oldUserStruct.referrer, 
            oldUserStruct.bonus,
            oldUserStruct.referrals,  
            oldUserStruct.match_bonus,
            oldUserStruct.direct_bonus,
            oldUserStruct.payouts) = oldTronAvail.users(oldUser);
    
            users[oldUser].checkpoint = oldUserStruct.checkpoint;
            users[oldUser].referrer = oldUserStruct.referrer;
            users[oldUser].bonus = oldUserStruct.bonus;
            users[oldUser].referrals = oldUserStruct.referrals;
            users[oldUser].match_bonus = oldUserStruct.match_bonus;
            users[oldUser].direct_bonus = oldUserStruct.direct_bonus;
            users[oldUser].payouts = oldUserStruct.payouts;

            for (uint256 j = 0; j < oldTronAvail.getUserAmountOfDeposits(oldUser); j++) {
                uint256 amount;
                uint256 withdrawn;
                uint256 start;
                (amount, withdrawn, start) =  oldTronAvail.getUserDepositInfo(oldUser, j);
                users[oldUser].deposits.push(Deposit(amount, withdrawn, start));
            }
            
            (users[oldUser].UserReferralCountsValue[oldUser].level1,
            users[oldUser].UserReferralCountsValue[oldUser].level2,
            users[oldUser].UserReferralCountsValue[oldUser].level3) = oldTronAvail.getUserDownlineCount(oldUser);
            
            userIds[oldUserId] = oldUser;
            
            oldUserId++;
        }
        
        totalUsers = oldTronAvail.totalUsers();
        totalInvested = oldTronAvail.totalInvested();
        totalWithdrawn = oldTronAvail.totalWithdrawn();
        totalDeposits = oldTronAvail.totalDeposits();
    }

    function closeSync() public {
        require(msg.sender == owner, "Access denied");
        oldTronAvail = OldTronAvail(0);
    }
    
    function getUserDownlineCount(address _addr) view external returns(uint256, uint256, uint256) {
        return (users[_addr].UserReferralCountsValue[_addr].level1, users[_addr].UserReferralCountsValue[_addr].level2, users[_addr].UserReferralCountsValue[_addr].level3);
    }

    function getMatchBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].match_bonus;
    }
}