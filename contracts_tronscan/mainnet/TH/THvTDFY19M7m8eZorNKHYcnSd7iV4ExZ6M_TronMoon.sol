//SourceUnit: TronMoon.sol

 /*  Tron Moon - Community Contribution pool with daily ROC (Return Of Contribution) based on TRX blockchain smart-contract technology. 
 *   Safe and decentralized ROI Game. The Smart Contract source is verified and available to everyone. The community decides the future of the project!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://tronmoon.space                                     │
 *   │                                                                       │
 *   │   Telegram Public Group and Support: @tronmoonofficial                |
 *   |                                                                       |        
 *   |   E-mail: admin@tronmoon.space                                        |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like TronLink Pro / Klever
 *   2) Ask your sponsor the login link and contribute to the contract with at least the minimum amount of TRX required (200 TRX) + Blockchain Fees
 *   3) Wait for your earnings. You can withdraw at the end of the countdown (1 to 10 days depending on the "dynamic limits" feature). First withdraw when you want
 *   4) Invite your friends and earn some referral bonus also when they withdraw (due to the auto-redeposit feature). 
 *   5) Withdraw earnings (dividends+referral) using our website "Withdraw" button
 *   6) Deposit more if you want. You can also applay your personal re-deposit strategy or leverage the other available plan(s)
 *   7) Help the smart contract balance to grow and have fun. Remember to deposit only what you can afford to lose
 *
 *   [SMART CONTRACT DETAILS]
 *
 *   - ROC (return of contribution): 3% every 24h - max 300% (in 100 days) for every deposit
 *   - Minimum deposit: 200 TRX, no max limit
 *   - Single button withdraw for dividends and cumulated referral bonus
 *   - Automatic 35% Redeposit when withdrawing, considered like a new deposit 
 *   - Referral bonus distribution also with automatic redeposits 
 *   - Max Withdraw 500K TRX for each withdraw. Min Withdraw 50 TRX.
 *   - Dynamic withdrawal deadtime (between withdrawals) depending on the contract balance, from 1 to 10 days
 *   - Max withdraw halved when the delay is 9 and 10 days (balance lower than 20% of last ATH reference step)
 *   - First Withdraw when you want
 *   - Integration with the future plans (registerUserFromPlan) to leverage the same referral hierarchy 
 *   - Receive referral bonus from TronMoon users in your downline (5 levels) also if participating only in the other Plan(s)
 *   - Withdraw referral bonuses only after a first deposit
 *   - Insurance Fee (5% of deposits and redeposits) sent to a dedicated wallet. Manual refund on demand to cover the damages of the whales
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 5-level referral commission: 5% - 3% - 2% - 1% - 4% - Earn more from the last line!
 *   - Extra Bonus! The referral commissions are paid also on the automatic redeposits (same percentages, but calculated on the 35% redeposit)
 *   - If you don't have a sponsor, you can still join: the admin (adminAddress) will be your sponsor
 *   - Your sponsor must be a registered user, otherwise the admin will be your sponsor
 *   - You can be only registered without deposits if you are depositing into the other available plans (soon)
 *   - Withdraw referral bonuses only after doing at least one deposit into the contract
 *   - Once joined you cannot change your sponsor (also in the case you join depositing into another plan first)
 *
 *   [FUNDS DISTRIBUTION OF THE DEPOSITS]
 *
 *   - 68% Platform main balance, participants payouts (ROC)
 *   - 6% Developer fee
 *   - 5% Insurance Wallet
 *   - 4% Advertising and promotion expenses
 *   - 2% Support work, technical functioning, administration fee
 *   - 15% Affiliate program bonuses
 */

pragma solidity 0.5.9;

contract TronMoon {
    using SafeMath for uint256;

    // Operating costs 
	uint256 constant public MARKETING_FEE = 40;
	uint256 constant public ADMIN_FEE = 20;
	uint256 constant public DEV_FEE = 60;
    uint256 constant public INSURANCE_FEE = 50;
	uint256 constant public PERCENTS_DIVIDER = 1000;
    // Referral percentages
    uint8 public constant FIRST_REF = 5;
    uint8 public constant SECOND_REF = 3;
    uint8 public constant THIRD_REF = 2;
    uint8 public constant FOURTH_REF = 1;
    uint8 public constant FIFTH_REF = 4;
    // Limits
    uint256 public constant DEPOSIT_MIN_AMOUNT = 200e6;
    uint256 public constant MAX_REFERENCE_STEP = 500000e6;
    uint256 public constant WITHDRAW_MAX_AMOUNT_NOM = 500000e6;        // Before reinvest
    uint8 public constant MAX_WITHDRAW_HALVING_THRESHOLD = 8;       // Expressed in extra days (0 to 9)
    uint256 public constant WITHDRAW_MIN_AMOUNT = 50e6;        // Before reinvest
    uint256 public constant TIME_UNIT = 1 days;         // Must be 1 days (if not debug)
    uint256 public constant WITHDRAWAL_DEADTIME_NOM = TIME_UNIT;
    // Max ROC days and related MAX ROC (Return of contribution)
    uint8 public constant CONTRIBUTION_DAYS = 100;
    uint256 public constant CONTRIBUTION_PERC = 300;
    // Auto-redeposit during withdraw
    uint8 public constant AUTO_REINVEST_PERCENTAGE = 35;
    // Operating addresses
    address payable public insuranceWallet;     // Manual Insurance Wallet
    address payable public marketingAddress;    // Marketing manager
	address payable public adminAddress;        // Project manager 
	address payable public devAddress;          // Developer

    uint256 public total_investors;
    uint256 public total_contributed;
    uint256 public total_withdrawn;
    uint256 public total_referral_bonus;
    uint8[] public referral_bonuses;
    uint256 public max_reference = 0;
    uint256 public withdrawal_deadtime;
    uint256 public withdraw_max_amount;

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

    mapping(address => Player) public players;
    // Used to link the other/future plans with this contract referral structure (register user from the other plan)
    mapping(address => bool) public enabled_plan_contract;      

    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event ReDeposit(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);


	constructor(address payable marketingAddr, address payable adminAddr, address payable devAddr, address payable insuranceAddr) public {
	    require(!isContract(marketingAddr) && !isContract(adminAddr) && !isContract(devAddr));
		marketingAddress = marketingAddr;
		adminAddress = adminAddr;
		devAddress = devAddr;
        insuranceWallet = insuranceAddr;
        // Add referral bonuses (max 8 levels) - We use 5 levels
        referral_bonuses.push(10 * FIRST_REF);
        referral_bonuses.push(10 * SECOND_REF);
        referral_bonuses.push(10 * THIRD_REF);
        referral_bonuses.push(10 * FOURTH_REF);
        referral_bonuses.push(10 * FIFTH_REF);
        // Set initial limits
        withdrawal_deadtime = WITHDRAWAL_DEADTIME_NOM;
        withdraw_max_amount = WITHDRAW_MAX_AMOUNT_NOM;
	}


    // Fallback function to send money to the contract from other contracts (eg. other plans)
    function () external payable {
        require(msg.value > 0, "Send some TRX!");
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
        // Check and set referral (register user if not registered)
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
        // Update dynamic limits
        update_dynamic_limits();
    }


    function registerUserFromPlan(address _addr, address _referral) external {
        require(enabled_plan_contract[msg.sender], "Only a plan contract can register a new user");
        _setReferral(_addr, _referral);
    }


    function _setReferral(address _addr, address _referral) private {
        // Set referral if the user is a new user
        if(players[_addr].referral == address(0)) {
            // If referral is a registered (has a referral) user (but not self), set it as ref, otherwise set adminAddress as ref
            if(players[_referral].referral != address(0) && _referral != _addr) {
                players[_addr].referral = _referral;
            } else {
                players[_addr].referral = adminAddress;
            }
            // Update the referral counters
            for(uint8 i = 0; i < referral_bonuses.length; i++) {
                players[_referral].referrals_per_level[i]++;
                if (_referral == adminAddress) break;
                _referral = players[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }


    function _referralPayout(address _addr, uint256 _amount) private {
        address ref = players[_addr].referral;
        // Generate upline rewards
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            if (ref == address(0)) break;
            uint256 bonus = _amount * referral_bonuses[i] / 1000;
            players[ref].referral_bonus += bonus;
            players[ref].total_referral_bonus += bonus;
            total_referral_bonus += bonus;
            emit ReferralPayout(ref, bonus, (i+1));
            if (ref == adminAddress) break;
            ref = players[ref].referral;
        }
    }


    function _feesPayout(uint256 _amount) private {
        // Send fees if there is enough balance
        if (address(this).balance > _feesTotal(_amount)) {
            insuranceWallet.transfer(_amount.mul(INSURANCE_FEE).div(PERCENTS_DIVIDER));
            marketingAddress.transfer(_amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
            adminAddress.transfer(_amount.mul(ADMIN_FEE).div(PERCENTS_DIVIDER));
            devAddress.transfer(_amount.mul(DEV_FEE).div(PERCENTS_DIVIDER));
        }
    }


    // Total fees amount
    function _feesTotal(uint256 _amount) private pure returns(uint256 fees_tot) {
        fees_tot = _amount.mul(MARKETING_FEE+ADMIN_FEE+DEV_FEE+INSURANCE_FEE).div(PERCENTS_DIVIDER);
    }



    function withdraw() public {
        Player storage player = players[msg.sender];
        // Can withdraw once every withdrawal_deadtime days after the wirst withdraw. You can do the first withdraw when you want!
        require(uint256(block.timestamp) > (player.last_withdrawal + withdrawal_deadtime) || (player.withdrawals.length <= 0), "You cannot withdraw during deadtime");
        require(address(this).balance > 0, "Cannot withdraw, contract balance is 0");
        require(player.deposits.length < 1500, "Max 1500 deposits per address");
        // User must do at least 1 deposit to be able to withdraw something (for example the referral bonus)
        require(player.deposits.length > 0, "You must do at leas one deposit to be able to withdraw");
        // Calculate dividends (ROC)
        uint256 payout = this.payoutOf(msg.sender);
        player.dividends += payout;
        // Calculate the amount we should withdraw
        uint256 amount_withdrawable = player.dividends + player.referral_bonus;
        require(amount_withdrawable > 0, "Zero amount to withdraw");
        require(amount_withdrawable >= WITHDRAW_MIN_AMOUNT, "Minimum withdrawable amount not reached");
        // Max withdrawable amount (before reinvest) each time we withdraw
        if (amount_withdrawable > withdraw_max_amount){
			amount_withdrawable = withdraw_max_amount;
        }
        // Calculate the reinvest part and the wallet part
        uint256 autoReinvestAmount = amount_withdrawable.mul(AUTO_REINVEST_PERCENTAGE).div(100);
        uint256 withdrawableLessAutoReinvest = amount_withdrawable.sub(autoReinvestAmount);
        // Do Withdraw
        if (address(this).balance <= withdrawableLessAutoReinvest) {
            // Recalculate if contract balance is not enough and disable auto-reinvest
			withdrawableLessAutoReinvest = address(this).balance;
            amount_withdrawable = withdrawableLessAutoReinvest;
            autoReinvestAmount = 0;
		}
        msg.sender.transfer(withdrawableLessAutoReinvest);
        // Update player state
        player.dividends = (player.dividends + player.referral_bonus).sub(amount_withdrawable);
        player.referral_bonus = 0;
        player.total_withdrawn += amount_withdrawable;      // Include reinvested part (like if we withdraw and then redeposit)
        total_withdrawn += amount_withdrawable;             // Include reinvested part (like if we withdraw and then redeposit)
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
        emit Withdraw(msg.sender, amount_withdrawable);
        // Do the forced reinvest of part of the withdrawn amount
        if (autoReinvestAmount > 0) {
            reinvest(msg.sender, autoReinvestAmount);
        }
        // Update dynamic limits
        update_dynamic_limits();
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



    // Dynamic dumping prevention algorithm 
    function update_dynamic_limits() private {
        // Update max reference if needed
        if (address(this).balance >= max_reference + MAX_REFERENCE_STEP) {
            max_reference = uint256(address(this).balance / MAX_REFERENCE_STEP) * MAX_REFERENCE_STEP;       // rounded using steps of MAX_REFERENCE_STEP
        }
        if (address(this).balance < max_reference) {
            // Determine slot
            uint256 ten_percent = max_reference * 10 / 100;
            uint8 extra_days = 10 - uint8(address(this).balance / ten_percent + 1);
            // Deadtime is nominal deadtime (eg. 1 day) + extra days. It will be 1 to 10 days
            uint256 new_deadtime = extra_days * TIME_UNIT + WITHDRAWAL_DEADTIME_NOM;
            // Change the limits dynamically
            if (new_deadtime != withdrawal_deadtime) {
                // update value
                withdrawal_deadtime = new_deadtime;
                if (extra_days >= MAX_WITHDRAW_HALVING_THRESHOLD && withdraw_max_amount == WITHDRAW_MAX_AMOUNT_NOM) {
                    withdraw_max_amount = WITHDRAW_MAX_AMOUNT_NOM / 2;
                } else if (extra_days < MAX_WITHDRAW_HALVING_THRESHOLD && withdraw_max_amount != WITHDRAW_MAX_AMOUNT_NOM) {
                    withdraw_max_amount = WITHDRAW_MAX_AMOUNT_NOM;
                }
            }
        } else {
            if (withdrawal_deadtime != WITHDRAWAL_DEADTIME_NOM) {
                withdrawal_deadtime = WITHDRAWAL_DEADTIME_NOM;
            }
            if (withdraw_max_amount != WITHDRAW_MAX_AMOUNT_NOM) {
                withdraw_max_amount = WITHDRAW_MAX_AMOUNT_NOM;
            }
        }   
    }



    function _updateTotalPayout(address _addr) private {
        Player storage player = players[_addr];
        // For every deposit calculate the ROC and update the withdrawn part
        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];
            uint256 time_end = dep.time + CONTRIBUTION_DAYS * TIME_UNIT;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);
            if(from < to) {
                player.deposits[i].totalWithdraw += dep.amount * (to - from) * CONTRIBUTION_PERC / CONTRIBUTION_DAYS / (TIME_UNIT * 100);
            }
        }
    }


    function withdrawalsOf(address _addrs) view external returns(uint256 _amount) {
        Player storage player = players[_addrs];
        // Calculate all the withdrawn amount (redeposit included)
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
            uint256 time_end = dep.time + CONTRIBUTION_DAYS * TIME_UNIT;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);
            if(from < to) {
                value += dep.amount * (to - from) * CONTRIBUTION_PERC / CONTRIBUTION_DAYS / (TIME_UNIT * 100);
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


    function getUplineArray(address _addr) public view returns(address[] memory upline) {
        address current_parent = _addr;
        // Determine the hierarchy length
        uint8 ref_len = 0;
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            current_parent = players[current_parent].referral;
            if (current_parent == address(0)) {
                break;
            } else if (current_parent == adminAddress) {
                ref_len++;
                break;
            } else {
                ref_len++;
            }
        }
        upline = new address[](ref_len);
        // Update the referral counters
        current_parent = _addr;
        for(uint8 i = 0; i < ref_len; i++) {
            current_parent = players[current_parent].referral;
            upline[i] = current_parent;
        }
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
          _endTimes[i] = dep.time + CONTRIBUTION_DAYS * TIME_UNIT;
        }
        return (
          _endTimes,
          _amounts,
          _totalWithdraws
        );
    }



	// Returns the enabled status for the withdraw button and the countdown in seconds
	function getWithdrawEnabledAndCountdown(address _addr) public view returns(bool enabled, uint256 countdown_sec, uint256 end_timestamp) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        // Button enabled (clickable) if: there is at least one deposit AND deadtime expired AND requires satisfied
        // countdown is the time from now to the end of current deadtime
        bool at_least_one_deposit = (player.deposits.length > 0);
        bool deadtime_expired = (block.timestamp > (player.last_withdrawal + withdrawal_deadtime) || player.withdrawals.length <= 0);
        uint256 amount_withdrawable = payout + player.dividends + player.referral_bonus;
        bool withdraw_requires = (amount_withdrawable >= WITHDRAW_MIN_AMOUNT);
        enabled = at_least_one_deposit && deadtime_expired && withdraw_requires;
        if (!deadtime_expired) {
            end_timestamp = player.last_withdrawal + withdrawal_deadtime;
            countdown_sec = end_timestamp - block.timestamp;
        } else {
            countdown_sec = 0;
            end_timestamp = 0;
        }
	}


    function addNewPlanContract(address plan_contract) external {
        require(msg.sender == adminAddress, "Only admin can add a new plan contract");
        enabled_plan_contract[plan_contract] = true;
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