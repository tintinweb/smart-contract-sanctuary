//SourceUnit: tronmars.sol

 /*  Tron Mars - Community Contribution pool with daily ROC (Return Of Contribution) based on TRX blockchain smart-contract technology. 
 *   Safe and decentralized. The Smart Contract source is verified and available to everyone. The community decides the future of the project!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://tronmars.space                                     │
 *   │                                                                       │
 *   │   Telegram Public Group and Support: @tronmarsofficial                |
 *   |                                                                       |        
 *   |   E-mail: admin@tronmars.space                                        |
 *   |                                                                       |        
 *   |   Contract Address: TDQHyxB9aJAW6Cdv7XawvTXEcJuJ1TvAYo                |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like TronLink Pro / Klever
 *   2) Ask your sponsor the login link and contribute to the contract with at least the minimum amount of TRX required (200 TRX)
 *   3) Wait for your earnings. You can withdraw once every 24h
 *   4) Invite your friends and earn some referral bonus. Help the smart contract balance to grow and have fun
 *   5) Withdraw earnings (dividends+referral) using our website "Withdraw" button 
 *   6) Deposit more if you want. You can also do manual compounding depositing part of your earnings
 *
 *   [SMART CONTRACT DETAILS]
 *
 *   - ROC (return of contribution): 5% every 24h - max 300% (in 60 days) for every deposit
 *   - Minimal deposit: 200 TRX, no maximal limit
 *   - Single button withdraw for dividends and cumulated referral bonus
 *   - Withdraw any time, but with the limit of max 1 withdraw every 24h. No max withdraw limit.
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 3-level referral commission: 7% - 5% - 3%
 *   - If you don't have a sponsor, you can still join: the admin (adminAddress) will be your sponsor
 *   - Your sponsor must be a registered user (another participant who deposited), otherwise the admin will be your sponsor
 *   - Once joined you cannot change your sponsor
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 74% Platform main balance, participants payouts
 *   - 5% Developer fee, website bandwidth
 *   - 3% Support work, admin fee
 *   - 3% Marketing fee
 *   - 15% Affiliate program bonuses
 */

pragma solidity 0.5.9;

contract TronMars {
    using SafeMath for uint256;

    // Operating costs 
	uint256 constant public MARKETING_FEE = 30;
	uint256 constant public ADMIN_FEE = 30;
	uint256 constant public DEV_FEE = 50;
	uint256 constant public PERCENTS_DIVIDER = 1000;
    // Referral percentages
    uint8 public constant FIRST_REF = 7;
    uint8 public constant SECOND_REF = 5;
    uint8 public constant THIRD_REF = 3;
    // Limits
    uint256 public constant DEPOSIT_MIN_AMOUNT = 200 trx;
    // Before reinvest
    uint256 public constant WITHDRAWAL_DEADTIME = 1 days;
    // Max ROC days and related MAX ROC (Return of contribution)
    uint8 public constant CONTRIBUTION_DAYS = 60;
    uint256 public constant CONTRIBUTION_PERC = 300;
    // Operating addresses
    address payable owner;      // Smart Contract Owner (who deploys)
    address payable public marketingAddress;    // Marketing manager
	address payable public adminAddress;        // Project manager 
	address payable public devAddress;          // Developer

    uint256 total_investors;
    uint256 total_contributed;
    uint256 total_withdrawn;
    uint256 total_referral_bonus;
    uint8[] referral_bonuses;
    
    uint private releaseTime = 1623675590; // June 14, 2021 - 1PM GMT

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


	constructor(address payable marketingAddr, address payable adminAddr, address payable devAddr) public {
	    require(!isContract(marketingAddr) && !isContract(adminAddr) && !isContract(devAddr));

		marketingAddress = marketingAddr;
		adminAddress = adminAddr;
		devAddress = devAddr;
        owner = msg.sender;

        // Add referral bonuses (max 8 levels) - We use 3 levels
        referral_bonuses.push(10 * FIRST_REF);
        referral_bonuses.push(10 * SECOND_REF);
        referral_bonuses.push(10 * THIRD_REF);
	}


    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }


    function deposit(address _referral) external payable {
        require(now >= releaseTime, "Not yet released!");
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(!isContract(_referral));
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
            // If referral is a registered user, set it as ref, otherwise set adminAddress as ref
            if(players[_referral].total_contributed > 0) {
                players[_addr].referral = _referral;
            } else {
                players[_addr].referral = adminAddress;
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
            marketingAddress.transfer(_amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
            adminAddress.transfer(_amount.mul(ADMIN_FEE).div(PERCENTS_DIVIDER));
            devAddress.transfer(_amount.mul(DEV_FEE).div(PERCENTS_DIVIDER));
        }
    }

    // Total fees amount
    function _feesTotal(uint256 _amount) private view returns(uint256 _fees_tot) {
        _fees_tot = _amount.mul(MARKETING_FEE+ADMIN_FEE+DEV_FEE).div(PERCENTS_DIVIDER);

    }


    function withdraw() public {
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

        // Do Withdraw
        if (address(this).balance < amount_withdrawable) {
            player.dividends = amount_withdrawable.sub(address(this).balance);
			amount_withdrawable = address(this).balance;
		} else {
            player.dividends = 0;
        }
        msg.sender.transfer(amount_withdrawable);

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


        emit Withdraw(msg.sender, amount_withdrawable);
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
                player.deposits[i].totalWithdraw += dep.amount * (to - from) * CONTRIBUTION_PERC / CONTRIBUTION_DAYS / 8640000;
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
                value += dep.amount * (to - from) * CONTRIBUTION_PERC / CONTRIBUTION_DAYS / 8640000;
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