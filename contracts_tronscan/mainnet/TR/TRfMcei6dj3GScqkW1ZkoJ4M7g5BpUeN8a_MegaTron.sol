//SourceUnit: Megatron.sol

/*SPDX-License-Identifier: MIT License*/
pragma solidity 0.5.9;

contract MegaTron {
    address payable main;
    uint256 public total_investment;
    uint256 public total_matchbonus;
    uint256 public total_refrewards;
    uint256 public total_users;
    uint256[] public match_bonus;

    

    struct Matchup {
        uint256 level;
        uint256 amount;
    }

    struct Deposit {
        uint256 amount;
        uint40 dept_time;
        uint40 payment_time;
        uint40 expiry;
    }

    struct Withdrawal {
        uint256 total_amount;
        uint256 referral;
        uint256 daily_gain;
        uint256 matchup;
    }

    struct Player {
        bool active;
        bool owner;
        address upline;
        uint256 total_matchup;
        uint256 total_direct;
        uint256 total_withdrawn;
        Deposit[] deposits;
        Matchup[] matchup_earnings;
        Withdrawal[] withdrawals;
        uint256 referrals_count;
    }
    mapping(address => Player) public players;

    constructor(
        address payable _main,
        address _main1,
        address _main2,
        address _main3,
        address _main4,
        address _main5,
        address _main6,
        address _main7,
        address _main8,
        address _main9,
        address _main10
    ) public {
        match_bonus.push(30);
        match_bonus.push(20);
        match_bonus.push(10);
        match_bonus.push(10);
        match_bonus.push(5);
        match_bonus.push(5);
        match_bonus.push(5);
        match_bonus.push(5);
        match_bonus.push(5);
        match_bonus.push(5);
        main = _main;

        players[_main1].active = true;
        players[_main1].upline = address(0);
        players[_main1].owner = true;
        setEarnings(_main1);

        players[_main2].active = true;
        players[_main2].upline = _main1;
        players[_main2].owner = true;
        setEarnings(_main2);

        players[_main3].active = true;
        players[_main3].upline = _main2;
        players[_main3].owner = true;
        setEarnings(_main3);

        players[_main4].active = true;
        players[_main4].upline = _main3;
        players[_main4].owner = true;
        setEarnings(_main4);

        players[_main5].active = true;
        players[_main5].upline = _main4;
        players[_main5].owner = true;
        setEarnings(_main5);

        players[_main6].active = true;
        players[_main6].upline = _main5;
        players[_main6].owner = true;
        setEarnings(_main6);

        players[_main7].active = true;
        players[_main7].upline = _main6;
        players[_main7].owner = true;
        setEarnings(_main7);

        players[_main8].active = true;
        players[_main8].upline = _main7;
        players[_main8].owner = true;
        setEarnings(_main8);

        players[_main9].active = true;
        players[_main9].upline = _main8;
        players[_main9].owner = true;
        setEarnings(_main9);

        players[_main10].active = true;
        players[_main10].upline = _main9;
        players[_main10].owner = true;
        setEarnings(_main10);
    }

    function checkUpline(address _upline) public view returns (bool) {
        return players[_upline].active;
    }

    function setEarnings(address _user) private {
        Player storage player = players[_user];
        player.matchup_earnings.push(Matchup(1,0));
        player.matchup_earnings.push(Matchup(2,0));
        player.matchup_earnings.push(Matchup(3,0));
        player.matchup_earnings.push(Matchup(4,0));
        player.matchup_earnings.push(Matchup(5,0));
        player.matchup_earnings.push(Matchup(6,0));
        player.matchup_earnings.push(Matchup(7,0));
        player.matchup_earnings.push(Matchup(8,0));
        player.matchup_earnings.push(Matchup(9,0));
        player.matchup_earnings.push(Matchup(10,0));
    }

    function deposit(address _upline) external payable {
        require(msg.value >= 500 trx, "Value is not enough");
        require(players[_upline].active, "Upline not active");
        Player storage player = players[msg.sender];
        if(!player.active){
            player.upline = _upline;
            players[_upline].referrals_count++;
            setEarnings(msg.sender);
        }
        player.active = true;
        
        player.deposits[player.deposits.length++] = Deposit(msg.value,uint40(block.timestamp),0,uint40(block.timestamp) + 200 days);

        players[_upline].total_direct += (msg.value * 8) / 100;
        total_refrewards += (msg.value * 8) / 100;
        main.transfer((msg.value * 15) / 100);
        total_users++;
        total_investment += msg.value;
    }

    function getScData() public view returns (uint256,uint256,uint256,uint256) {
        return (total_investment,total_matchbonus,total_refrewards,total_users);
    }

    function getDepositCount() public view returns (uint) {
        return players[msg.sender].deposits.length;
    }

    function getWithdrawalCount() public view returns (uint) {
        return players[msg.sender].withdrawals.length;
    }

    function getDeposits(uint index) public view returns (uint256, uint40,uint40) {
        Deposit storage player_deposit = players[msg.sender].deposits[index];
        return (player_deposit.amount,player_deposit.dept_time,player_deposit.expiry);
    }

    function getMatchupEarnings() public view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
        Player storage player = players[msg.sender];
        return (player.matchup_earnings[0].amount,
                player.matchup_earnings[1].amount,
                player.matchup_earnings[2].amount,
                player.matchup_earnings[3].amount,
                player.matchup_earnings[4].amount,
                player.matchup_earnings[5].amount,
                player.matchup_earnings[6].amount,
                player.matchup_earnings[7].amount,
                player.matchup_earnings[8].amount,
                player.matchup_earnings[9].amount
            );
    }

    function getDailygain(uint index) public view returns(uint256) {
        Player storage player = players[msg.sender];
        Deposit storage player_dep = player.deposits[index];

        uint40 from = player_dep.payment_time > 0 ? player_dep.payment_time: player_dep.dept_time;
        uint40 to = uint40(block.timestamp) > player_dep.expiry ? player_dep.expiry: uint40(block.timestamp);
        uint256 gain = player_dep.amount * (to - from ) * 1 / 86400/100;
        if(gain < 0){
            return 0;
        }
        return gain;
    }

    function getDailyEarnings() public view returns (uint256) {
        Player storage player = players[msg.sender];
        uint256 total = 0;

        for (uint256 i = 0; i < player.deposits.length; i++) {
            uint40 from = player.deposits[i].payment_time > 0
                ? player.deposits[i].payment_time
                : player.deposits[i].dept_time;
            uint40 to = uint40(block.timestamp) > player.deposits[i].expiry ? player.deposits[i].expiry: uint40(block.timestamp);
            uint256 gain = player.deposits[i].amount * (to - from) * 1 / 86400 / 100;
            if(gain < 0){
                gain = 0;
            }
            total += gain;
        }

        return total;
    }

    function _updateDepositTime(address _player) private {
        Player storage player = players[_player];
        for(uint i = 0;i < player.deposits.length;i++){
            player.deposits[i].payment_time = uint40(block.timestamp);
        }
    }

    function _matchup(address _player, uint256 _amount) private {
        address up = _player;

        for(uint i = 0;i < match_bonus.length;i++ ){
            if(up == address(0)){
                break;
            }
            uint256 bonus = _amount * match_bonus[i] / 100;
            if(players[up].referrals_count >= (i+1) || players[up].owner == true){
                players[up].total_matchup += bonus;
                players[up].matchup_earnings[i].amount += bonus;
            }
            up = players[up].upline;
        }
    }

    // function matchup(address _upline, uint256 _amount, uint counter) {
    //     Player storage player = players[_upline];
    //     uint256 bonus = _amount * match_bonus[counter]; / 100;
    //     if(player){

    //     }

    // }

    function withdraw() external {
        Player storage player = players[msg.sender];
        uint256 total_gain = getDailyEarnings();
        uint256 available = player.total_matchup + player.total_direct + total_gain;
        msg.sender.transfer(available);
        player.withdrawals[player.withdrawals.length++] = Withdrawal(available,player.total_direct,total_gain,player.total_matchup);
        player.total_withdrawn += available;
        player.total_matchup = 0;
        player.total_direct = 0;
        
        _updateDepositTime(msg.sender);
        _matchup(players[msg.sender].upline, total_gain);
    }
}