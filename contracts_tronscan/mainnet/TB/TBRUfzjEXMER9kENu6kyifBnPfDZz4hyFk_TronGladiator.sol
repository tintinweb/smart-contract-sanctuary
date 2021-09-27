//SourceUnit: TronGladiator.sol

 /*  Tron Gladiator Smart Contract - https://trongladiator.top - Telegram Community: @trongladiator - Channel: @trongladiatorchannel
 ^
 ^   TronGladiator is a high risk ROI GAME where players do a deposit and share the deposit with the community. The game will go ahead if new people enter the game. With the good strategies you can reach high winnings.
 ^   Remember that ROI/ROC games are more similat to gambling than investments, if you win someone else lose, this is simple, everything governed by the contract math rules, there is no external income.
 ^   You are responsible of your choices, remember there are high risks to lose, always educate yourself.
 ^
 ^   The smart contract released from the devs has been tested and reviewed internally for security bugs before deployment. There is no responsibility if there are unknown bugs in the game logics.
 ^   The contract is decentralized, immutable once written in the blockchain. It works as a Community Contribution Pool with daily ROC (Return Of Contribution) and it's based on TRX blockchain smart-contract technology. 
 ^   The withdrawals from the contract are paid with the main balance, coming from the deposits. The Smart Contract source is verified (public) and available to everyone. By partecipating you agree to the code rules.
 ^   The community of players are the contract, they decide when the game must end. When the balance is zero the players won't be able to withdraw and the game is considered finished.
 ^
 ^   [USAGE INSTRUCTION]
 ^
 ^   1) Connect TRON browser extension TronLink, or mobile wallet apps like TronLink Pro / Klever
 ^   2) Ask your sponsor the login link and contribute to the contract with at least the minimum amount of TRX required + Blockchain Fees
 ^   3) Wait for your earnings. You can withdraw at the end of the countdown (1 time per day). First withdraw when you want
 ^   4) Invite your friends and earn some referral bonus also when they withdraw (due to the auto-redeposit feature). Referral commissions are payd with direct transfers
 ^   5) Withdraw earnings (dividends) using our website "Withdraw" button. 
 ^   6) Deposit more if you want. You can also applay your personal re-deposit strategy
 ^   7) Help the smart contract balance to grow and have fun. Remember to deposit only what you can afford to lose
 ^
 ^   Note: Remember that the contract has 10 referral levels so the gas will be high, withdraw only when you have a decent amount of dividends or freeze 10-30K TRX to have some energy and burn less TRX.
 ^
 ^   [SMART CONTRACT FEATURES AND TECH DETAILS]
 ^
 ^   - ROC (return of contribution): base rate 5% every 24h - max 250% for every deposit
 ^   - Dynamic ROC percentage Boost feature: +0.05% every 1M of contract balance, globally for the contract, applied to new and old deposits
 ^   - Dynamic Protect Feature: decrease the ROC daily rate if the contract balance starts dumping (from an ATH reference). From ATH daily rate to 1/10 of the ATH daily rate, with steps of 1/10
 ^   - Minimum deposit: 400 TRX, no max limit
 ^   - Single button withdraw for dividends, with countdown
 ^   - Locked Redeposit feature: automatic 35% Redeposit when withdrawing, considered like a new deposit, but locked until you reach the 250% of the previous (re)deposits (sequential unlock)
 ^   - Referral bonus distribution also with automatic redeposits, paid at the time it's created
 ^   - Max Withdraw 200K TRX for each withdraw during normal conditions. Min Withdraw 200 TRX
 ^   - Max withdraw 100K when the contract is dumping (from the ATH) and the balance is below 2.8M TRX
 ^   - Max withdraw 50K when the contract is dumping (from the ATH) and the balance is below 1.2M TRX
 ^   - Minimum withdraw 200 TRX to prevent bot activity and fair participation in the game
 ^   - First Withdraw when you want, then 1 withdraw every 24h
 ^   - Integration with the future plans/contracts (registerUserFromPlan) to leverage the same referral hierarchy with 2 level limit for commissions in there is no deposits
 ^   - Addresses for dev fees and marketing fees can be changed by the admin for management purposes
 ^
 ^   [REFERRAL SYSTEM TECH DETAILS]
 ^
 ^   - 10-level referral commission: 2% - 2% - 3% - 1% - 1% - 0.5% - 0.5% - 0.5% - 0.5% - 1% - Earn more from the third line and the last line!
 ^   - Referral commissions are paid using direct transfers to the user's wallet (P2P)
 ^   - Extra Bonus! The referral commissions are paid also on the automatic redeposits (same percentages, but calculated on the 35% redeposit)
 ^   - If you don't have a sponsor, you can still join: the admin (adminAddress) will be your sponsor
 ^   - Your sponsor must be a registered user, otherwise the admin will be your sponsor
 ^   - You can be only registered without deposits if you are depositing into the other available plans connected with this smart contract (future possible features)
 ^   - Once joined you cannot change your sponsor (also in the case you join depositing into another plan first)
 ^
 ^   [FUNDS DISTRIBUTION OF THE DEPOSITS]
 ^
 ^   - 70% Platform main balance, participants payouts (ROC). This is the game balance.
 ^   - 10% Admin Fee (owner fee for PM, operating costs, support, big marketing expenses, ...)
 ^   - 5% Developers fee
 ^   - 3% Advertising and promotion expenses
 ^   - 12% Affiliate program bonuses
 ^
 */

pragma solidity 0.5.9;

contract TronGladiator {
    using SafeMath for uint256;

    // Operating costs 
	uint256 constant public MARKETING_FEE = 300;
	uint256 constant public ADMIN_FEE = 1000;
	uint256 constant public DEV_FEE = 500;
    // Referral percentages
    uint16[10] public REF_PERCENTS = [200, 200, 300, 100, 100, 50, 50, 50, 50, 100];	
    uint256 constant public PERCENTS_DIVIDER = 10000;
    // Limits
    uint256 public constant DEPOSIT_MIN_AMOUNT = 400e6;
    uint256 public constant MAX_REFERENCE_STEP = 500000e6;
    uint256 public constant WITHDRAW_MAX_AMOUNT_NOM = 200000e6;        // Before redeposit
    uint256 public constant WITHDRAW_MIN_AMOUNT = 200e6;        // Before redeposit
    uint256 public constant TIME_UNIT = 1 days;         // Must be 1 days
    uint256 public constant WITHDRAWAL_DEADTIME_NOM = TIME_UNIT;
    // Base daily rate and related MAX ROC (Return of contribution)
    uint16 public constant DAILY_RATE_BASE = 500;
    uint256 public constant CONTRIBUTION_PERC = 25000;
    // Per-thousand increase every X contract balance
	uint256 constant public BALANCE_STEP = 1000000e6;			// Balance Step associated to PERCENT_INCR (in SUN)
	uint16 constant public PERCENT_INCR = 5;					// increment value added to base percentage every BALANCE_STEP
    // Auto-redeposit during withdraw
    uint16 public constant AUTO_REDEPOSIT_PERCENTAGE = 3500;
    // Operating addresses
    address payable public marketingAddress;    // Marketing manager
	address payable public adminAddress;        // Project manager 
	address payable public devAddress;          // Developer

    uint256 public total_players;
    uint256 public total_contributed;
    uint256 public total_withdrawn;
    uint256 public total_referral_bonus;
    uint256 public max_reference = 0;
    uint256 public withdrawal_deadtime;
    uint256 public withdraw_max_amount;
    uint16 public last_ath_daily_rate;
    uint16 public current_daily_rate;


    struct PlayerDeposit {
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
        uint256 threshold_amount;   // Only redeposits have threshold_amount > 0
    }

     struct PlayerWitdraw{
        uint256 time;
        uint256 amount;
    }

    struct Player {
        address referral;
        uint256 dividends;
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
    mapping(address => bool) public enabled_plan_contract;      

    // Events 
    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event ReDeposit(address indexed addr, uint256 amount, uint256 thr_amount);
    event UnlockedRedeposit(address indexed addr, uint256 index, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);


	constructor(address payable marketingAddr, address payable adminAddr, address payable devAddr) public {
	    require(!isContract(marketingAddr) && !isContract(adminAddr) && !isContract(devAddr));
		marketingAddress = marketingAddr;
		adminAddress = adminAddr;
		devAddress = devAddr;
        // Set initial percentage
        current_daily_rate = DAILY_RATE_BASE;
        last_ath_daily_rate = current_daily_rate;
        // Set initial limits
        withdrawal_deadtime = WITHDRAWAL_DEADTIME_NOM;
        withdraw_max_amount = WITHDRAW_MAX_AMOUNT_NOM;
	}


    // Fallback function to send money to the contract from other contracts
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
        require(msg.value >= DEPOSIT_MIN_AMOUNT, "Deposit is below minimum amount");
        Player storage player = players[msg.sender];
        require(player.deposits.length < 1500, "Max 1500 deposits per address");
        // Check and set referral (register user if not registered)
        _setReferral(msg.sender, _referral);
        // Create deposit
        player.deposits.push(PlayerDeposit({
            amount: msg.value,
            totalWithdraw: 0,
            time: uint256(block.timestamp),
            threshold_amount: 0
        }));
        // Add new user if this is first deposit
        if(player.total_contributed == 0){
            total_players += 1;
        }
        player.total_contributed += msg.value;
        total_contributed += msg.value;
        // Generate referral rewards
        _referralPayout(msg.sender, msg.value);
        // Pay fees
		_feesPayout(msg.value);
        emit Deposit(msg.sender, msg.value);
        // Update dynamic percentage and limits
        update_dynamic_percentage_and_limits();
        // Check if some redeposits need to be unlocked and unlock them
        _checkUnlockRedeposits(msg.sender);
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
            for(uint8 i = 0; i < REF_PERCENTS.length; i++) {
                players[_referral].referrals_per_level[i]++;
                if (_referral == adminAddress) break;
                _referral = players[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }


    // Pay referral with direct transfers
    function _referralPayout(address _addr, uint256 _amount) private {
        address ref = players[_addr].referral;
        // Generate upline rewards
        for(uint8 i = 0; i < REF_PERCENTS.length; i++) {
            if (ref == address(0)) break;
            // Require a deposit to be eligible for >2nd level commissions (multiple plan case, for future purposes)
            if (players[ref].deposits.length > 0 || i < 2) {
                uint256 bonus = _amount * REF_PERCENTS[i] / PERCENTS_DIVIDER;
                players[ref].total_referral_bonus += bonus;
                total_referral_bonus += bonus;
                // Do the P2P transfer (casting to payable address)
                address(uint160(ref)).transfer(bonus);
                emit ReferralPayout(ref, bonus, (i+1));
            }
            if (ref == adminAddress) break;
            ref = players[ref].referral;
        }
    }


    function _feesPayout(uint256 _amount) private {
        // Send fees if there is enough balance
        if (address(this).balance > _feesTotal(_amount)) {
            marketingAddress.transfer(_amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
            adminAddress.transfer(_amount.mul(ADMIN_FEE).div(PERCENTS_DIVIDER));
            devAddress.transfer(_amount.mul(DEV_FEE).div(PERCENTS_DIVIDER));
        }
    }


    // Total fees amount
    function _feesTotal(uint256 _amount) private pure returns(uint256 fees_tot) {
        fees_tot = _amount.mul(MARKETING_FEE+ADMIN_FEE+DEV_FEE).div(PERCENTS_DIVIDER);
    }



    function withdraw() public {
        Player storage player = players[msg.sender];
        // Can withdraw once every withdrawal_deadtime days after the wirst withdraw. You can do the first withdraw when you want!
        require(uint256(block.timestamp) > (player.last_withdrawal + withdrawal_deadtime) || (player.withdrawals.length <= 0), "You cannot withdraw during deadtime");
        require(address(this).balance > 0, "Cannot withdraw, contract balance is 0");
        require(player.deposits.length < 1500, "Max 1500 deposits per address");
        // User must do at least 1 deposit to be able to withdraw something
        require(player.deposits.length > 0, "You must do at leas one deposit to be able to withdraw");
        // Calculate dividends (ROC) for the game
        uint256 payout = this.payoutOf(msg.sender);
        player.dividends += payout;
        // Calculate the amount we should withdraw
        uint256 amount_withdrawable = player.dividends;
        require(amount_withdrawable > 0, "Zero amount to withdraw");
        require(amount_withdrawable >= WITHDRAW_MIN_AMOUNT, "Minimum withdrawable amount not reached");
        // Max withdrawable amount (before redeposit) each time we withdraw
        if (amount_withdrawable > withdraw_max_amount){
			amount_withdrawable = withdraw_max_amount;
        }
        // Calculate the redeposit part and the wallet part
        uint256 autoRedepositAmount = amount_withdrawable.mul(AUTO_REDEPOSIT_PERCENTAGE).div(PERCENTS_DIVIDER);
        uint256 withdrawableLessAutoRedeposit = amount_withdrawable.sub(autoRedepositAmount);
        // Do Withdraw
        if (address(this).balance <= withdrawableLessAutoRedeposit) {
            // Recalculate if contract balance is not enough and disable auto-redeposit
			withdrawableLessAutoRedeposit = address(this).balance;
            amount_withdrawable = withdrawableLessAutoRedeposit;
            autoRedepositAmount = 0;
		}
        msg.sender.transfer(withdrawableLessAutoRedeposit);
        // Update player state
        player.dividends = (player.dividends).sub(amount_withdrawable);
        player.total_withdrawn += amount_withdrawable;      // Include redeposited part (like if we withdraw and then redeposit)
        total_withdrawn += amount_withdrawable;             // Include redeposited part (like if we withdraw and then redeposit)
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
        // Do the forced redeposit of part of the withdrawn amount
        if (autoRedepositAmount > 0) {
            redeposit(msg.sender, autoRedepositAmount);
        }
        // Update dynamic percentage and limits
        update_dynamic_percentage_and_limits();
        // Check if some redeposits need to be unlocked and unlock them
        _checkUnlockRedeposits(msg.sender);
    }



    function redeposit(address _addrs, uint256 _amount) private {
        Player storage player = players[_addrs];
        // Create new lockd redeposit (sequential unlock based on total dividends+withdraw amount)
        uint256 thr_amount = player.total_contributed * CONTRIBUTION_PERC / PERCENTS_DIVIDER;
        player.deposits.push(PlayerDeposit({
            amount: _amount,
            totalWithdraw: 0,
            time: 0,        // Locked
            threshold_amount: thr_amount    // Unlock threshold
        }));
        player.total_contributed += _amount;
        total_contributed += _amount;
        // Generate referral rewards
        _referralPayout(_addrs, _amount);
        // Pay fees
		_feesPayout(_amount);
        emit ReDeposit(_addrs, _amount, thr_amount);
    }



    // Dynamic percentage and limits
    function update_dynamic_percentage_and_limits() private {
        // Update max reference if needed
        if (address(this).balance >= max_reference + MAX_REFERENCE_STEP) {
            max_reference = uint256(address(this).balance / MAX_REFERENCE_STEP) * MAX_REFERENCE_STEP;       // rounded using steps of MAX_REFERENCE_STEP
            last_ath_daily_rate = current_daily_rate;
        }
        // Set the ROC percentage and the limits
        // Decrease the percentage if the balance goes down, using as reference the current percentage. Decrease the withdraw_max_amount
        if (address(this).balance < max_reference) {
            // Determine slot
            uint256 ten_percent = max_reference * 10 / 100;
            uint16 dump_step = uint16(address(this).balance / ten_percent + 1);     // 10 to 1
            current_daily_rate = last_ath_daily_rate * dump_step / 10;
            // Change the withdraw limits dynamically (consecutive halving)
            if (address(this).balance < WITHDRAW_MAX_AMOUNT_NOM*14) {
                // 20 * WITHDRAW_MAX_AMOUNT_NOM * 70/100
                withdraw_max_amount = WITHDRAW_MAX_AMOUNT_NOM/2;
            }
            if (address(this).balance < WITHDRAW_MAX_AMOUNT_NOM*6) {
                // 20 * WITHDRAW_MAX_AMOUNT_NOM * 30/100
                withdraw_max_amount = withdraw_max_amount/2;
            }   
        } else {
            // Restore the withdraw_max_amount
            if (withdraw_max_amount != WITHDRAW_MAX_AMOUNT_NOM) {
                withdraw_max_amount = WITHDRAW_MAX_AMOUNT_NOM;
            }
            // Restore or update the dynamic percentage
            uint256 total_balance = address(this).balance;
            uint256 multip = total_balance >= BALANCE_STEP ? total_balance / BALANCE_STEP : 0;
            current_daily_rate = DAILY_RATE_BASE + PERCENT_INCR*uint16(multip);
        }   
    }



    function _updateTotalPayout(address _addr) private {
        Player storage player = players[_addr];
        // For every deposit calculate the ROC and update the withdrawn part
        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];
            // Consider only the manual deposits and the unlocked (dep.time > 0) redeposits (dep.threshold_amount > 0)
            if (dep.threshold_amount == 0 || (dep.threshold_amount > 0 && dep.time > 0)) {
                uint256 last_checkpoint = player.last_payout > dep.time ? player.last_payout : dep.time;
                uint256 elapsed = block.timestamp - last_checkpoint;
                // calculate the amount related to the last period
                uint256 amnt = (dep.amount * current_daily_rate / PERCENTS_DIVIDER) * elapsed / TIME_UNIT;
                uint256 max_amount_per_deposit = dep.amount * CONTRIBUTION_PERC / PERCENTS_DIVIDER;
                // Coerce to CONTRIBUTION_PERC amount
                if (amnt + dep.totalWithdraw >= max_amount_per_deposit) {
                    amnt = max_amount_per_deposit - dep.totalWithdraw;
                    amnt = amnt > max_amount_per_deposit ? 0 : amnt;
                }
                if (amnt > 0) {
                    player.deposits[i].totalWithdraw += amnt;
                }
            }
        }
    }


    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];
        // For every deposit calculate the ROC and update the withdrawn part
        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];
            // Consider only the manual deposits and the unlocked (dep.time > 0) redeposits (dep.threshold_amount > 0)
            if (dep.threshold_amount == 0 || (dep.threshold_amount > 0 && dep.time > 0)) {
                uint256 last_checkpoint = player.last_payout > dep.time ? player.last_payout : dep.time;
                uint256 elapsed = block.timestamp - last_checkpoint;
                // calculate the amount related to the last period
                uint256 amnt = (dep.amount * current_daily_rate / PERCENTS_DIVIDER) * elapsed / TIME_UNIT;
                uint256 max_amount_per_deposit = dep.amount * CONTRIBUTION_PERC / PERCENTS_DIVIDER;
                // Coerce to CONTRIBUTION_PERC amount
                if (amnt + dep.totalWithdraw >= max_amount_per_deposit) {
                    amnt = max_amount_per_deposit - dep.totalWithdraw;
                    amnt = amnt > max_amount_per_deposit ? 0 : amnt;
                }
                value += amnt;
            }
        }
        // Total dividends from all deposits and redeposits
        return value;
    }


    // Check and unlock redeposits depending on the ongoing earnings (dividends cumulated + withdraws) and the redeposit threshold
    function _checkUnlockRedeposits(address _addr) private {
        Player storage player = players[_addr];
        uint256 ongoing_earnings = player.dividends + player.total_withdrawn;
        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];
            if (dep.time > 0) {
                continue;       // Already unlocked or a manual deposit, skip this one
            } else if (ongoing_earnings >= dep.threshold_amount) {
                // Unlock it
                player.deposits[i].time = uint256(block.timestamp);
                emit UnlockedRedeposit(_addr, i+1, dep.amount);
            } else {
                // No need to go futher, next redeposits can have only greater thresholds
                break;
            }
        }
    }


    function contractInfo() view external returns(uint256 _total_contributed, uint256 _total_players, uint256 _total_withdrawn, uint256 _total_referral_bonus, uint16 current_rate) {
        return (total_contributed, total_players, total_withdrawn, total_referral_bonus, current_daily_rate);
    }


    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 ongoing_earnings, uint256 deposited, uint256 withdrawn, uint256 referral_bonus, uint256[10] memory referrals, uint256 _last_withdrawal) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        // Calculate number of referrals for each level
        for(uint8 i = 0; i < REF_PERCENTS.length; i++) {
            referrals[i] = player.referrals_per_level[i];
        }
        // Return user information
        return (
            payout + player.dividends,
            payout + player.dividends + player.total_withdrawn,
            player.total_contributed,
            player.total_withdrawn,
            player.total_referral_bonus,
            referrals,
            player.last_withdrawal
        );
    }
    

    function withdrawalsOf(address _addrs) view external returns(uint256 _amount) {
        Player storage player = players[_addrs];
        // Calculate all the withdrawn amount (redeposit included)
        for(uint256 n = 0; n < player.withdrawals.length; n++){
            _amount += player.withdrawals[n].amount;
        }
        return _amount;
    }


    function getUplineArray(address _addr) public view returns(address[] memory upline) {
        address current_parent = _addr;
        // Determine the hierarchy length
        uint8 ref_len = 0;
        for(uint8 i = 0; i < REF_PERCENTS.length; i++) {
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

 
    function contributionsInfo(address _addr) view external returns(uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory max_profits, uint256[] memory totalWithdraws, uint256[] memory redeposits_thresholds, uint256[] memory redeposits_remainings, uint8[] memory redeposits_lock_status) {
        Player storage player = players[_addr];
        uint256 ongoing_earnings = this.payoutOf(_addr) + player.dividends + player.total_withdrawn;
        endTimes = new uint256[](player.deposits.length);
        amounts = new uint256[](player.deposits.length);
        max_profits = new uint256[](player.deposits.length);
        totalWithdraws = new uint256[](player.deposits.length);
        redeposits_thresholds = new uint256[](player.deposits.length);      // Use to discriminate between normal deposits (threshold == 0) and automatic redeposits (threshold > 0)
        redeposits_remainings = new uint256[](player.deposits.length);
        redeposits_lock_status = new uint8[](player.deposits.length);
        // Create arrays with deposits info, each index is related to a deposit
        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];
            amounts[i] = dep.amount;
            totalWithdraws[i] = dep.totalWithdraw;
            max_profits[i] = dep.amount * CONTRIBUTION_PERC / PERCENTS_DIVIDER;
            // Calculate end times
            uint256 remaining_seconds = (max_profits[i] - dep.totalWithdraw) * TIME_UNIT * PERCENTS_DIVIDER / (current_daily_rate * dep.amount);
            uint256 last_checkpoint = player.last_payout > dep.time ? player.last_payout : dep.time;
            endTimes[i] = last_checkpoint + remaining_seconds;
            // Redeposits information
            redeposits_thresholds[i] = dep.threshold_amount;
            redeposits_remainings[i] = ongoing_earnings >= dep.threshold_amount ? 0 : dep.threshold_amount - ongoing_earnings;
            // Lock status
            if (redeposits_remainings[i] == 0) {
                if (dep.time > 0) {
                    // Unlocked (Active)
                    redeposits_lock_status[i] = 2;
                } else {
                    // Unlockable
                    redeposits_lock_status[i] = 1;
                }
            } else {
                // Locked
                redeposits_lock_status[i] = 0;
            }
        }
    }



	// Returns the enabled status for the withdraw button and the countdown in seconds
	function getWithdrawEnabledAndCountdown(address _addr) public view returns(bool enabled, uint256 countdown_sec, uint256 end_timestamp) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        // Button enabled (clickable) if: there is at least one deposit AND deadtime expired AND requires satisfied
        // countdown is the time from now to the end of the deadtime
        bool at_least_one_deposit = (player.deposits.length > 0);
        bool deadtime_expired = (block.timestamp > (player.last_withdrawal + withdrawal_deadtime) || player.withdrawals.length <= 0);
        uint256 amount_withdrawable = payout + player.dividends;
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


    function changeDevFeeDestination(address payable devAddress_new) external {
        require(msg.sender == adminAddress, "Only admin can do this");
        devAddress = devAddress_new;
    }
    

    function changeMarketingFeeDestination(address payable marketingAddress_new) external {
        require(msg.sender == adminAddress, "Only admin can do this");
        marketingAddress = marketingAddress_new;
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