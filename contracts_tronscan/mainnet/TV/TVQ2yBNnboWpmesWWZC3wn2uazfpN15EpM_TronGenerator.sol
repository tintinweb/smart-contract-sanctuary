//SourceUnit: Trongenerator.sol

/*SPDX-License-Identifier: MIT License*/
pragma solidity 0.5.9;

contract TronGenerator {

    struct LevelEarnings {
        uint256 level;
        uint256 earnings;
    }

    struct Tracking {
        uint256 totalWithdrawn;
        uint256 totalMatchupBonus;
        uint256 totalRefBonus;
        uint256 totalDeposits;
    }

    struct User {
        bool hasDeposited;
        address upline;
        uint256 refBonus;
        uint40 paidAt;
        uint256 matchupBonus;
        uint256 currentDepositAmount;
        uint256 currentTotalWithdrawn;
        uint256 dailyGainWithdrawal;
        uint40 depAt;
        uint256 prevDeposit;
        uint256 numberOfReferrals;
        bool owner;
        mapping(uint256 => LevelEarnings) levelEarningsStruct;
    }

    uint256 public grandTotal;
    address payable mainAddress;
    uint256 public totalUsers = 0;
    uint256 public totalRefRewards;
    uint256[] public matchUpBonus;
    mapping(address => User) public users;
    mapping(address => Tracking) public tracks;
    constructor(address payable _main, 
    address _main1,
    address _main2,
    address _main3,
    address _main4,
    address _main5,
    address _main6,
    address _main7,
    address _main8,
    address _main9,
    address _main10) public {
        mainAddress =  _main;
        users[_main1].hasDeposited = true;
        users[_main1].upline = address(0);
        users[_main1].owner = true;
        setEarnings(_main1);

        users[_main2].hasDeposited = true;
        users[_main2].upline = _main1;
        users[_main2].owner = true;
        setEarnings(_main2);

        users[_main3].hasDeposited = true;
        users[_main3].upline = _main2;
        users[_main3].owner = true;
        setEarnings(_main3);

        users[_main4].hasDeposited = true;
        users[_main4].upline = _main3;
        users[_main4].owner = true;
        setEarnings(_main4);

        users[_main5].hasDeposited = true;
        users[_main5].upline = _main4;
        users[_main5].owner = true;
        setEarnings(_main5);

        users[_main6].hasDeposited = true;
        users[_main6].upline = _main5;
        users[_main6].owner = true;  
        setEarnings(_main6);

        users[_main7].hasDeposited = true;
        users[_main7].upline = _main6;
        users[_main7].owner = true;   
        setEarnings(_main7);

        users[_main8].hasDeposited = true;
        users[_main8].upline = _main7;
        users[_main8].owner = true;
        setEarnings(_main8);

        users[_main9].hasDeposited = true;
        users[_main9].upline = _main8;
        users[_main9].owner = true;
        setEarnings(_main9);

        users[_main10].hasDeposited = true;
        users[_main10].upline = _main9;
        users[_main10].owner = true;   
        setEarnings(_main10);

        
        matchUpBonus.push(30);
        matchUpBonus.push(20);
        matchUpBonus.push(10);
        matchUpBonus.push(10);
        matchUpBonus.push(5);
        matchUpBonus.push(5);
        matchUpBonus.push(5);
        matchUpBonus.push(5);
        matchUpBonus.push(5);
        matchUpBonus.push(5);

    }

    
    function referral(address _user, uint256 _amount) private {
        users[_user].refBonus += _amount * 8 / 100;
        totalRefRewards += _amount * 8 / 100;
    }

    function setEarnings(address _user) private {
        users[_user].levelEarningsStruct[0] = LevelEarnings(1,0);
        users[_user].levelEarningsStruct[1] = LevelEarnings(2,0);
        users[_user].levelEarningsStruct[2] = LevelEarnings(3,0);
        users[_user].levelEarningsStruct[3] = LevelEarnings(4,0);
        users[_user].levelEarningsStruct[4] = LevelEarnings(5,0);
        users[_user].levelEarningsStruct[5] = LevelEarnings(6,0);
        users[_user].levelEarningsStruct[6] = LevelEarnings(7,0);
        users[_user].levelEarningsStruct[7] = LevelEarnings(8,0);
        users[_user].levelEarningsStruct[8] = LevelEarnings(9,0);
        users[_user].levelEarningsStruct[9] = LevelEarnings(10,0);
    }



    function deposit(address _upline) external payable {
        require(msg.value >= 500 trx, "Value is not enough");
        require(!(users[msg.sender].currentDepositAmount > 0), "Deposit is active");
        require(users[msg.sender].prevDeposit <= msg.value, 'Next deposit must be greater than or equal to previous deposit');
        if(!users[msg.sender].hasDeposited){
            users[msg.sender].upline = _upline;
            totalUsers++;
            users[_upline].numberOfReferrals += 1;
        }
        grandTotal += msg.value;
        tracks[msg.sender].totalDeposits += msg.value;
        users[msg.sender].currentDepositAmount = msg.value;
        users[msg.sender].hasDeposited = true;
        users[msg.sender].depAt = uint40(block.timestamp);
        mainAddress.transfer(msg.value * 15 / 100);
        referral(users[msg.sender].upline, msg.value);
    }

    function getEarningsByLevel(address _sender)public view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
        User storage user = users[_sender];

        return (user.levelEarningsStruct[0].earnings,
                user.levelEarningsStruct[1].earnings,
                user.levelEarningsStruct[2].earnings,
                user.levelEarningsStruct[3].earnings,
                user.levelEarningsStruct[4].earnings,
                user.levelEarningsStruct[5].earnings,
                user.levelEarningsStruct[6].earnings,
                user.levelEarningsStruct[7].earnings,
                user.levelEarningsStruct[8].earnings,
                user.levelEarningsStruct[9].earnings
                );
    }

    function _earnDaily(address _sender) public view returns(uint256) {
        User storage user = users[_sender];
        //get total earnings
            if(user.currentDepositAmount > 0){
                uint40 from = user.paidAt > 0 ? user.paidAt: user.depAt;
                 //calculate daily earnings from time of deposit
                return  user.currentDepositAmount * (uint40(block.timestamp) - from) * 3 / 86400 / 100;
            }else {
                return 0;
            }
    }

    function _max(uint256 _amount) public pure returns(uint256) {
        return _amount * 45 / 10;
    }

    function getTotalEarnings(address _sender) public view returns(uint256 total) {
        User storage user = users[_sender];

        total = user.refBonus + user.matchupBonus;
        return total;
    }
    function _matchBonus(address user, uint256 _amount) private {
        address up = user;
        for(uint i = 0;i < matchUpBonus.length;i++ ){
            if(up == address(0)){
                break;
            }
            if((users[up].hasDeposited && users[up].currentDepositAmount > 0) || users[user].owner == true){
                if((users[user].numberOfReferrals >= (i+1)) || users[user].owner == true){
                    uint256 bonus = _amount * matchUpBonus[i] / 100;
                    users[up].matchupBonus += bonus;
                    users[up].levelEarningsStruct[i].earnings += bonus;
                }
            }

            up = users[up].upline;
        }
    }

    function withdraw() external {
        require(users[msg.sender].currentDepositAmount > 0, 'No active deposits');
        
        uint256 dailyEarnings = uint256(this._earnDaily(msg.sender));
        uint256 separateEarnings = getTotalEarnings(msg.sender);
        uint256 amount = separateEarnings  + dailyEarnings + users[msg.sender].dailyGainWithdrawal;//CHECK IF MAX
        uint256 maxWithdrawable = _max(users[msg.sender].currentDepositAmount);
        uint256 available;
        if(amount  > maxWithdrawable && users[msg.sender].owner == false){
            available = maxWithdrawable - (users[msg.sender].currentTotalWithdrawn + users[msg.sender].dailyGainWithdrawal);
            if(available <= 0){
                users[msg.sender].prevDeposit = users[msg.sender].currentDepositAmount;
                if(users[msg.sender].owner == false){
                    users[msg.sender].currentDepositAmount = 0;
                } 
                users[msg.sender].paidAt = uint40(block.timestamp);
                users[msg.sender].depAt = 0;
                tracks[msg.sender].totalWithdrawn += (users[msg.sender].currentTotalWithdrawn + available + users[msg.sender].dailyGainWithdrawal);
                tracks[msg.sender].totalRefBonus += users[msg.sender].refBonus;
                tracks[msg.sender].totalMatchupBonus += users[msg.sender].matchupBonus;
                users[msg.sender].currentTotalWithdrawn = 0;
                users[msg.sender].matchupBonus = 0;
                users[msg.sender].refBonus = 0;
                users[msg.sender].dailyGainWithdrawal = 0;
            }else {
                _matchBonus(users[msg.sender].upline, dailyEarnings);
                tracks[msg.sender].totalWithdrawn += (users[msg.sender].currentTotalWithdrawn + available + users[msg.sender].dailyGainWithdrawal);
                tracks[msg.sender].totalRefBonus += users[msg.sender].refBonus;
                users[msg.sender].prevDeposit = users[msg.sender].currentDepositAmount;
                tracks[msg.sender].totalMatchupBonus += users[msg.sender].matchupBonus;
                users[msg.sender].currentTotalWithdrawn = 0;
                if(users[msg.sender].owner == false){
                    users[msg.sender].currentDepositAmount = 0;    
                }
                users[msg.sender].depAt = 0;
                users[msg.sender].paidAt = uint40(block.timestamp);
                
                users[msg.sender].matchupBonus = 0;
                users[msg.sender].refBonus = 0;
                users[msg.sender].dailyGainWithdrawal = 0;
                msg.sender.transfer(available);
            }
        }else {
            available = (separateEarnings  + dailyEarnings) - users[msg.sender].currentTotalWithdrawn;
            users[msg.sender].currentTotalWithdrawn += (available - dailyEarnings);

            users[msg.sender].paidAt = uint40(block.timestamp);
            _matchBonus(users[msg.sender].upline, dailyEarnings);
             users[msg.sender].dailyGainWithdrawal += dailyEarnings;
             msg.sender.transfer(available);
        }

    }
}