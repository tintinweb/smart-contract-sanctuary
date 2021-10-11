/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

/*! [https://bnbmint.app] */
/*! [High-yield Community-funded BNB Staking] */
/*! [0x0c33e2Cf5F048aE5E8314e210116A01100d5851E] */
/*! [https://bnbmint.app/audits/audit-bnbmint.pdf] */
/*! [5% DAILY | STAKE | UNSTAKE | REFERRALS 5% - 3% - 2%] */

pragma solidity 0.5.10;

contract BnbMint {

    using SafeMath for uint256;
    
    uint256[] public REFERRAL_PERCENTS; // 5% - 3% - 2%
    uint256 constant public MARKETING_FEE = 100; // 10% Marketing Fee, Dev & Platform Fees
    uint256 constant public PERCENT_DIVISOR = 1000;
    uint256 constant public STAKE_STEP = 1 days;
    uint256 constant public STAKE_RATE = 50; // 5% DAILY APR
    uint256 constant public STAKE_PENALTY = 500; // -50% ON EARLY UNSTAKE
    uint256 constant public STAKE_MIN = 0.05 ether; // 0.05 BNB
    uint256 constant public STAKE_SAFEHOLD = 15 days; // 15 DAYS HOLD OR GET PENALTY
    uint256 constant public STAKE_COOLDOWN = 1 days; // 24 HOURS COOLDOWN FOR WITHDRAWALS
    
    uint256 public totalStaked;
    uint256 public totalUnstaked;
    uint256 public totalClaimed;
    uint256 public totalReferrals;
    uint256 public totalUsers;

    struct User {
        address referrer;
        uint256 staked;
        uint256 unclaimed;
        uint256 claimed;
        uint256 stakepoint;
        uint256 claimpoint;
        uint256 checkpoint;
        uint256[3] levels;
        uint256 bonus;
        uint256 totalBonus;
    }

    mapping (address => User) internal users;

    address payable public commissionWallet;
    
    uint256 public launchDate = 1634029200; // 10-12-21 9AM GMT

    event NewStake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event RefClaim(address indexed user, uint256 amount);

    constructor(address payable wallet) public {
        REFERRAL_PERCENTS.push(50);
        REFERRAL_PERCENTS.push(30);
        REFERRAL_PERCENTS.push(20);
        commissionWallet = wallet;
    }
    
    function stake(address referrer) public payable {
        
        require(block.timestamp >= launchDate, "Not Yet Open!");
        require(msg.value >= STAKE_MIN, "Insufficient amount!");
        
        User storage user = users[msg.sender];
        
        // set commissionWallet as ref
        if(referrer == address(0) && msg.sender != commissionWallet) referrer = commissionWallet;
        
        if (user.referrer == address(0)) {
        
            // referrer must have deposits
            if (users[referrer].checkpoint > 0 && referrer != msg.sender) user.referrer = referrer;
            // avoid null referrals
            else user.referrer = commissionWallet;
            
            address upline = user.referrer;
            for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i].add(1);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if (upline != address(0)) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENT_DIVISOR);
                    users[upline].bonus = users[upline].bonus.add(amount);
                    users[upline].totalBonus = users[upline].totalBonus.add(amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.checkpoint == 0) {
            totalUsers = totalUsers.add(1);
            user.claimpoint = block.timestamp.sub(STAKE_COOLDOWN);
        } else {
            user.unclaimed = getUserClaimable(msg.sender);
            user.bonus = 0;
        }
        user.checkpoint = block.timestamp;
        user.stakepoint = block.timestamp;
        user.staked = user.staked.add(msg.value);
        totalStaked = totalStaked.add(msg.value);
        commissionWallet.transfer(msg.value.mul(MARKETING_FEE).div(PERCENT_DIVISOR));
        
        emit NewStake(msg.sender, msg.value);
    }
    
    function unstake() public returns (uint256 amount) {
        
        require(block.timestamp >= launchDate, "Not Yet Open!");
        
        User storage user = users[msg.sender];
        
        require(user.staked > 0, "Nothing to unstake!");
        
        amount = user.staked;
        
        user.unclaimed = getUserClaimable(msg.sender);
        user.checkpoint = block.timestamp;
        user.staked = 0;
        user.bonus = 0;
        
        totalUnstaked = totalUnstaked.add(amount);
        emit Unstake(msg.sender, amount);
        
        // check if penalized amount
        if(user.stakepoint.add(STAKE_SAFEHOLD) > block.timestamp)
            amount = amount.sub(amount.mul(STAKE_PENALTY).div(PERCENT_DIVISOR));
        
        // prevent amount overflow
        amount = getContractBalance() < amount ? getContractBalance() : amount;
        
        msg.sender.transfer(amount);
    }

    function claim() public returns (uint256 amount) {
        User storage user = users[msg.sender];
        
        // check cooldown
        require(user.claimpoint.add(STAKE_COOLDOWN) <= block.timestamp, "Not yet available");

        amount = getUserClaimable(msg.sender);

        require(amount > 0, "No claimable!");
        
        // prevent amount overflow
        amount = getContractBalance() < amount ? getContractBalance() : amount;
        
        totalReferrals = totalReferrals.add(user.bonus);
        user.claimed = user.claimed.add(amount);
        msg.sender.transfer(amount);
        
        user.claimpoint = block.timestamp;
        user.checkpoint = block.timestamp;
        user.unclaimed = 0;
        user.bonus = 0;
        
        emit Claim(msg.sender, amount);
        totalClaimed = totalClaimed.add(amount);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUserClaimable(address userAddress) public view returns (uint256 amount) {
        uint256 staked = users[userAddress].staked;
        uint256 checkpoint = users[userAddress].checkpoint;
        if(staked > 0) {
            uint256 daily = staked.mul(STAKE_RATE).div(PERCENT_DIVISOR);
            amount = daily.mul(block.timestamp.sub(checkpoint)).div(STAKE_STEP);
        }
        amount = amount.add(users[userAddress].unclaimed).add(users[userAddress].bonus);
    }

    function getUserReferralInfo(address userAddress) public view returns (uint256 bonus, uint256 totalBonus, uint256[3] memory referrals, address referrer) {
        return (users[userAddress].bonus, users[userAddress].totalBonus, users[userAddress].levels, users[userAddress].referrer);
    }

    function getContractInfo() public view returns (uint256 _totalStaked, uint256 _totalUnstaked, uint256 _totalClaimed, uint256 _totalReferrals, uint256 _totalUsers, uint256 _contractBalance) {
        return(totalStaked, totalUnstaked, totalClaimed, totalReferrals, totalUsers, getContractBalance());
    }

    function getUserInfo(address userAddress) public view returns (uint256 _totalStaked, uint256 _totalClaimed, uint256 _checkpoint, uint256 _stakepoint, uint256 _claimpoint, uint256 _claimable) {
        return(
            users[userAddress].staked,
            users[userAddress].claimed,
            users[userAddress].checkpoint,
            users[userAddress].stakepoint,
            users[userAddress].claimpoint,
            getUserClaimable(userAddress)
        );
    }
}

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
}