//SourceUnit: ReferralTrade_New.sol

pragma solidity 0.5.10;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract OldRT {
    using SafeMath for uint256;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    address payable public ownerAddressOne;
    address payable public ownerAddressTwo;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 totalDeposits;
        uint256 checkpoint;
        address referrer;
        uint256 bonus;
        uint256 level1;
        uint256 level2;
        uint256 level3;
        uint256 level4;
        uint256 level5;
        uint256 bonusWithdrawn;
    }

    mapping(address => User) public users;

    function getUserCheckpoint(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return users[userAddress].referrer;
    }
    
    function getUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        User storage user = users[userAddress];

        return (
            user.deposits[index].amount,
            user.deposits[index].withdrawn,
            user.deposits[index].start
        );
    }

    function getUserAmountOfDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }
    
    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].bonus;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }
    
    function getUserDownlineCount(address userAddress)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            users[userAddress].level1,
            users[userAddress].level2,
            users[userAddress].level3,
            users[userAddress].level4,
            users[userAddress].level5
        );
    }
}


contract ReferralTrade {
    using SafeMath for uint256;

    uint256 public constant INVEST_MIN_AMOUNT = 100e6; //100 trx
    uint256[] public BASE_PERCENT = [10, 15, 30, 50];// 1%, 1.5%, 3%, 5%
    uint256[] public REFERRAL_PERCENTS = [100, 50, 25, 15, 10]; //10%, 5%, 2.5%, 1.5%, 1%
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    address payable public ownerAddressOne;
    address payable public ownerAddressTwo;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 totalDeposits;
        uint256 checkpoint;
        address referrer;
        uint256 bonus;
        uint256 level1;
        uint256 level2;
        uint256 level3;
        uint256 level4;
        uint256 level5;
        uint256 bonusWithdrawn;
    }
    
    OldRT public oldRT;
    uint256 oldUserId = 0;

    mapping(address => User) public users;
    mapping(uint256 => address) public userIds;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor(address _oldRT) public {
        oldRT = OldRT(_oldRT);
        ownerAddressOne = oldRT.ownerAddressOne();
        ownerAddressTwo = oldRT.ownerAddressTwo();
        totalUsers = oldRT.totalUsers();
        totalInvested = oldRT.totalInvested();
        totalWithdrawn = oldRT.totalWithdrawn();
        totalDeposits = oldRT.totalDeposits();
    }

    function invest(address referrer) public payable {
        require(msg.value >= INVEST_MIN_AMOUNT, "Error: Min amount");

        User storage user = users[msg.sender];

        if (
            user.referrer == address(0) &&
            users[referrer].deposits.length > 0 &&
            referrer != msg.sender
        ) {
            user.referrer = referrer;
        }
        
        uint256 userDeposit = (msg.value.mul(4)).div(10);
        uint256 totalReferralAmount;
        
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            //5 level referrals
            for (uint256 i = 0; i < 5; i++) {
                if (upline != address(0)) {
                    
                    //user upline 5 times deposit
                    uint256 userFiveXDeposit = (users[upline].totalDeposits * 5);
                    //referral amunt based on tree level
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    //if bonus amount is greater than 5x deposit
                    if(users[upline].bonus.add(amount) >= userFiveXDeposit) {
                        //get the remaining amount which is greater than 5x deposit
                        uint256 leftAmount = (users[upline].bonus.add(amount)).sub(userFiveXDeposit);
                        ownerAddressOne.transfer(leftAmount.div(2));
                        ownerAddressTwo.transfer(leftAmount.div(2));
                        amount = amount.sub(leftAmount);
                    }
                    //add the bonus amount
                    users[upline].bonus = users[upline].bonus.add(amount);
                    if (i == 0) {
                        users[upline].level1 = users[upline].level1.add(1);
                    } else if (i == 1) {
                        users[upline].level2 = users[upline].level2.add(1);
                    } else if (i == 2) {
                        users[upline].level3 = users[upline].level3.add(1);
                    } else if (i == 3) {
                        users[upline].level4 = users[upline].level4.add(1);
                    } else if (i == 4) {
                        users[upline].level5 = users[upline].level5.add(1);
                    }
                    emit RefBonus(upline, msg.sender, i, amount);
                    totalReferralAmount = totalReferralAmount.add(amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }
        
        uint256 ownerDepsoitAmtLeft = msg.value.sub(totalReferralAmount.add(userDeposit));
        
        ownerAddressOne.transfer(ownerDepsoitAmtLeft.div(2));
        ownerAddressTwo.transfer(ownerDepsoitAmtLeft.div(2));
        
        //first time deposit
        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            userIds[totalUsers] = msg.sender;
            totalUsers = totalUsers.add(1);
            emit Newbie(msg.sender);
        }
    
        //update user deposit array
        user.deposits.push(Deposit(msg.value, 0, block.timestamp));
        //update user total deposits
        user.totalDeposits = user.totalDeposits.add(msg.value);

        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);

        emit NewDeposit(msg.sender, msg.value);
    }

    function withdraw() public {
        User storage user = users[msg.sender];
        
        //return user roi percent(holdingpercent + base percent)
        uint256 userPercentRate = getUserPercentRate(
            msg.sender,
            user.totalDeposits
        );

        uint256 totalAmount;
        uint256 dividends;
        
        //loop thru user deposit array
        for (uint256 i = 0; i < user.deposits.length; i++) {
            //user can withdraw only less than 1.5x(150%) of his deposit
            if (user.deposits[i].withdrawn <= (user.deposits[i].amount.mul(15)).div(10)) {
                //if deposit is after last last withdraw
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (
                        user.deposits[i].amount.mul(userPercentRate).div(
                            PERCENTS_DIVIDER
                        )
                    )
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
                } else/* if deposit is before last withdraw */ {
                    dividends = (
                        user.deposits[i].amount.mul(userPercentRate).div(
                            PERCENTS_DIVIDER
                        )
                    )
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }
                
                //if new withdrawn amount is greater than 1.5x(150%)
                if (
                    user.deposits[i].withdrawn.add(dividends) >
                    ((user.deposits[i].amount.mul(15)).div(10))
                ) {
                    //get the withdrawn amount which is less than 150%
                    dividends = ((user.deposits[i].amount.mul(15)).div(10)).sub(
                        user.deposits[i].withdrawn
                    );
                }
                /// no update of withdrawn because that is view function
                user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
                totalAmount = totalAmount.add(dividends);
            }
        }
        
        //get referral amount whch are  unclaimed
        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
            user.bonus = 0;
            user.bonusWithdrawn = referralBonus;
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        
        //if contract balance is less than total withdrawable amount
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        
        //update user last withdrawn time
        user.checkpoint = block.timestamp;
        
        //transfer amount to user
        msg.sender.transfer(totalAmount);
        
        //update total withdrawn amount
        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractBalanceRate(uint256 investment)
        public
        view
        returns (uint256)
    {
        if (investment <= 1000e6) {
            return BASE_PERCENT[0];
        } else if (investment > 1000e6 && investment <= 3000e6) {
            return BASE_PERCENT[1];
        } else if (investment > 3000e6 && investment <= 10000e6) {
            return BASE_PERCENT[2];
        } else {
            return BASE_PERCENT[3];
        }
    }

    function getUserPercentRate(address userAddress, uint256 investmentAmount)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];
        uint256 contractBalanceRate = getContractBalanceRate(investmentAmount);
        if (isActive(userAddress)) {
            uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP);
            return contractBalanceRate.add(timeMultiplier);
        } else {
            return contractBalanceRate;
        }
    }

    function getUserDividends(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];
        
        //return user roi percent(holdingpercent + base percent)
        uint256 userPercentRate = getUserPercentRate(
            msg.sender,
            user.totalDeposits
        );

        uint256 totalDividends;
        uint256 dividends;
        
        //loop thru user deposit array
        for (uint256 i = 0; i < user.deposits.length; i++) {
            //user can withdraw only less than 1.5x(150%) of his deposit
            if (user.deposits[i].withdrawn <= (user.deposits[i].amount.mul(15)).div(10)) {
                //if deposit is after last last withdraw
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (
                        user.deposits[i].amount.mul(userPercentRate).div(
                            PERCENTS_DIVIDER
                        )
                    )
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
                } else/* if deposit is before last withdraw */ {
                    dividends = (
                        user.deposits[i].amount.mul(userPercentRate).div(
                            PERCENTS_DIVIDER
                        )
                    )
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }
                
                //if new withdrawn amount is greater than 1.5x(150%)
                if (
                    user.deposits[i].withdrawn.add(dividends) >
                    ((user.deposits[i].amount.mul(15)).div(10))
                ) {
                    //get the withdrawn amount which is less than 150%
                    dividends = ((user.deposits[i].amount.mul(15)).div(10)).sub(
                        user.deposits[i].withdrawn
                    );
                }
                /// no update of withdrawn because that is view function
                totalDividends = totalDividends.add(dividends);
            }
        }

        return totalDividends;
    }

    function getUserCheckpoint(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return users[userAddress].referrer;
    }

    function getUserDownlineCount(address userAddress)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            users[userAddress].level1,
            users[userAddress].level2,
            users[userAddress].level3,
            users[userAddress].level4,
            users[userAddress].level5
        );
    }
    
    function startSync(address[] memory _addr, 
    uint256[] memory _value, 
    uint256[] memory _deposit,
    uint256[] memory _checkpoint, 
    address[] memory _referrer,
    uint256[] memory _refBonus,
    uint256 limit) public {
        require(address(oldRT) != address(0), "Initialize closed");
        
        for (uint256 i = oldUserId; i < limit; i++) {
            // User memory oldUserStruct;
            address oldUser = _addr[i];
    
            users[oldUser].checkpoint = _checkpoint[i];
            users[oldUser].referrer = _referrer[i];
            users[oldUser].bonus = _refBonus[i];
            (users[oldUser].level1, 
            users[oldUser].level2,
            users[oldUser].level3,
            users[oldUser].level4,
            users[oldUser].level5) = oldRT.getUserDownlineCount(oldUser);
            users[oldUser].bonusWithdrawn = _value[i];
            users[oldUser].totalDeposits = _deposit[i];

            for (uint256 j = 0; j < oldRT.getUserAmountOfDeposits(oldUser); j++) {
                (uint256 amount, uint256 withdrawn, uint256 start) =  oldRT.getUserDepositInfo(oldUser, j);
                users[oldUser].deposits.push(Deposit(amount, withdrawn, start));
            }
            
            userIds[oldUserId] = oldUser;
            oldUserId++;
        }
    }

    function closeSync() public {
        require(oldRT != OldRT(0));
        oldRT = OldRT(0);
    }

    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].bonus;
    }
    
    function getUserBonusWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].bonusWithdrawn;
    }

    function getUserAvailableBalanceForWithdrawal(address userAddress)
        public
        view
        returns (uint256)
    {
        return
            getUserReferralBonus(userAddress).add(
                getUserDividends(userAddress)
            );
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            if (
                user.deposits[user.deposits.length - 1].withdrawn <
                (user.deposits[user.deposits.length - 1].amount.mul(15)).div(10)
            ) {
                return true;
            }
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        User storage user = users[userAddress];

        return (
            user.deposits[index].amount,
            user.deposits[index].withdrawn,
            user.deposits[index].start
        );
    }

    function getUserAmountOfDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn);
        }

        return amount;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function getHoldBonus(address userAddress) public view returns (uint256) {
        if (getUserCheckpoint(userAddress) == 0) {
            return (block.timestamp.sub(users[userAddress].checkpoint)).mod(24);
        } else {
            return 0;
        }
    }
}