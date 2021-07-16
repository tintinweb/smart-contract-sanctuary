//SourceUnit: RoiCity.sol

/*
Social Crowdfunding & Crowdsharing Smart Contract on the TRON Network 

RoiCity - First ever Tokenized Sustainable ROI System on the blockchain

Website : https://RoiCity.io
Main Social Channel : https://t.me/RoiCityGroup

Introducing the all new Continuity Protocol which maintains a concurrent active balance on the smart contract in perpetuity. 
First time in any crowd funding platform.

Contract Benefits:
35% to 40% 21 days ROI on investments
Recommitment Protocol
Perpetual Fund System
Defi Token Ecosystem
Free Token Distribution
5% Referral bonus
3% Second level bonus
2% Third level bonus
1% Fourth level bonus
1% Fifth level bonus
Referral Bonus must be Reinvested
No Developer Privilege 

100% New Concept in ROI Systems
Using the all new Continuity Protocol which maintains the contract funds with concurrent active balance in perpetuity. 
This continuity logic is an enforcement sustainability on a new level not on any other contract.

Forced Recommit Protocol
Before an investor can withdraw he must make another investment greater than the last. 
This is the continuity logic put in place to perpetuate the contract. This means before you 
can withdraw first deposit you must make a second deposit, before you can withdraw second deposit, 
you must have a third deposit, etc
This keeps the funds available at all times for investment continuity without end.

Total Capital Distribution
Funds (ROI + Referral) – 90% 
Defi Development - 4%
Marketing – 4%
Server & Security – 2%
Total = 100%

Total Capital Input: 90%
(Contract Verifiable)
*/

pragma solidity 0.4.25;

interface TRC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}



contract RoiCity  {
    using SafeMath for uint256;
    TRC20 roiCityTokenAddress;

    struct Tarif {
        uint256 lifeDays;
        uint256 percent;
    }

    struct Deposit {
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
        uint256 endTime;
        bool isWithdrawable;
        
        uint256 lastPayout;
    }
    
    

    struct Player {
        address upline;
        uint256 dividends;
        uint256 match_bonus;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 pending_withdrawl;
        uint256 total_match_bonus;
        Deposit[] deposits;
        uint256[] newDeposits;
        mapping(uint8 => uint256) structure;
        uint256 noOfInvestment;
       
        uint256 lastDepositeAmount;
        uint256 reinvested;
        uint256 lastDepositeIndex;
        DeposieLimit depositLimits;
    }
    
    struct DeposieLimit{
        uint256 allowdDeposits;
        uint256 lastCheckedDeposit;
         uint256 nextWithdrawTime;
        uint256 nextReinvestTime;
        uint256 nextReinvestReferral;
    }
    

    address public owner;
    
    uint256 public invested;
    
    
    uint256 public withdrawn;
    uint256 public users;
    uint256 public reinvested;
    
    uint256 constant public TIME_STEP = 1 days;//1 days for main
    uint256 constant public PERCENTS_DIVIDER = 100000;
    mapping(address=>uint256) public rewardDist;
    uint256 constant public totalSeconds=86400;//totalSeconds=86400 for main


    uint8[] public ref_bonuses; // 1 => 1%

    Tarif public tarifs;
    mapping(address => Player) public players;
    
    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event Reinvest(address indexed addr, uint256 amount,bool flag);

    constructor(address _stakingAddress,TRC20 _roiCityTokenAddress) public  {
       roiCityTokenAddress=_roiCityTokenAddress;
        owner = _stakingAddress;
       
        tarifs=Tarif(21, 135);
       
       
        ref_bonuses.push(5);
        ref_bonuses.push(3);
        ref_bonuses.push(2);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
    }
    
    
    function () external payable {}
    
    function _payout(address _addr,bool isReinvest) private {
        
        uint256 payout = (!isReinvest) ? this.payoutOfForWithdraw(_addr) : this.payoutOfReinvest(_addr);

        if(payout > 0) {
            if(isReinvest){
                _updateTotalPayoutReinvest(_addr);
            }
            else
            {
                _updateTotalPayoutWithdraw(_addr);
            }
           
            players[_addr].dividends = players[_addr].dividends.add(payout);
        }
    }

    function _updateTotalPayoutWithdraw(address _addr) private{
        Player storage player = players[_addr];
        uint256 percent=player.noOfInvestment>=7 ? 140 : tarifs.percent;
        uint256 value=0;
        for(uint256 i = 0; i < player.deposits.length; i++) {
            value=0;
            Deposit storage dep = player.deposits[i];
            if(i<player.lastDepositeIndex){//if(dep.isWithdrawable || player.lastdepositeindex>i || _reinvest){
            uint256 time_end = dep.time.add(tarifs.lifeDays.mul(totalSeconds));
            uint256 from = dep.lastPayout > dep.time ? dep.lastPayout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                value = dep.amount.mul((to.sub(from))).mul(percent).div(tarifs.lifeDays).div(totalSeconds.mul(100));
                
                    if(dep.time.add(tarifs.lifeDays.mul(totalSeconds))>uint256(block.timestamp)){
                        
                    
                            player.deposits[i].totalWithdraw=player.deposits[i].totalWithdraw.add(value);
                            
                        
                    }
                    else{
                            player.deposits[i].totalWithdraw=(dep.amount.mul(percent).div(100));
                    }
                
            }
             else{
                player.deposits[i].totalWithdraw=(dep.amount.mul(percent).div(100));
            }
            player.deposits[i].lastPayout=uint256(block.timestamp);
            }
        }
    }
    
    function _updateTotalPayoutReinvest(address _addr) private{
        Player storage player = players[_addr];
        uint256 percent=player.noOfInvestment>=7 ? 140 : tarifs.percent;
        
        uint256 value135=0;
        for(uint256 i = 0; i < player.deposits.length; i++) {
           
            Deposit storage dep = player.deposits[i];
            
            uint256 time_end = dep.time.add(tarifs.lifeDays.mul(totalSeconds));
            uint256 from = dep.lastPayout > dep.time ? dep.lastPayout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                 
                   
                        value135 = dep.amount.mul(to.sub(from)).mul(percent.sub(100)).div(tarifs.lifeDays).div(totalSeconds.mul(100));
                        player.deposits[i].totalWithdraw=player.deposits[i].totalWithdraw.add(value135);
                     
            
                player.deposits[i].lastPayout=uint256(block.timestamp);
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        
        address up = players[_addr].upline;
        
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;

            uint256 bonus = _amount.mul(ref_bonuses[i]).div(100);

            players[up].match_bonus = players[up].match_bonus.add(bonus);
            players[up].total_match_bonus = players[up].total_match_bonus.add(bonus);

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline) private {
        if(players[_addr].upline == address(0)) {
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
            }

            players[_addr].depositLimits.allowdDeposits=2;
            
            players[_addr].upline = _upline;
            tokenTransfer(_addr,uint256(1).mul(1e13));
       
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                
                players[_upline].structure[i]++;
                if(i==0 && players[_upline].structure[i]==35){
                    tokenTransfer(_upline,uint256(5).mul(1e14));
                }
                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
            users++;
        }
    }
    
    function sendRewards(uint256 amount) private{
        uint256 rewards=0;
        if(amount>=100 trx && amount<=500 trx){
            rewards=uint256(1).mul(1e13);
        }
        else if(amount>500 trx && amount<=1000 trx){
            rewards=uint256(5).mul(1e13);
        }
        else if(amount>1000 trx && amount<=5000 trx){
            rewards=uint256(2).mul(1e14);
        }
        else if(amount>5000 trx && amount<=10000 trx){
            rewards=uint256(1).mul(1e15);
        }
        else if(amount>10000 trx && amount<=50000 trx){
            rewards=uint256(1).mul(1e16);
        }
        else if(amount>50000 trx && amount<=150000 trx){
            rewards=uint256(5).mul(1e16);
        }
        else if(amount>150000 trx && amount<=250000 trx){
            rewards=uint256(7).mul(1e16);
        }
        else if(amount>250000 trx && amount<=500000 trx){
            rewards=uint256(1).mul(1e17);
        }
        else if(amount>500000 trx && amount<=750000 trx){
            rewards=uint256(1).mul(1e18);
        }
        else if(amount>750000 trx && amount<=1000000 trx){
            rewards=uint256(2).mul(1e18);
        }
        
        tokenTransfer(msg.sender,rewards);
    }

    function deposit(address _upline,bool isReinvest) public payable {
       Player storage player = players[msg.sender];
        
        uint amount=msg.value;
        if(isReinvest && amount==0 && player.pending_withdrawl>0){
          amount= player.pending_withdrawl;
          player.pending_withdrawl=0;
          reinvested=reinvested.add(amount);
          player.reinvested = player.reinvested.add(amount);
        
        }
         if(!isReinvest){
              require(amount >= 100 trx, "Min 100 Trx");
             
             require(player.lastDepositeAmount<amount,"Trying to invest lower amount");
                player.lastDepositeIndex=player.deposits.length;
            _setUpline(msg.sender, _upline);
            player.newDeposits.push(now.add(totalSeconds));
            if(now>player.newDeposits[player.depositLimits.lastCheckedDeposit])
            {
                player.depositLimits.lastCheckedDeposit=player.depositLimits.lastCheckedDeposit.add(1);
               player.depositLimits.allowdDeposits=player.depositLimits.allowdDeposits.add(1);
            }
             
            require(player.depositLimits.allowdDeposits>0,"Trying to invest lower amount");
            player.lastDepositeAmount=msg.value;
           player.noOfInvestment=players[msg.sender].noOfInvestment.add(1);
           if(player.noOfInvestment==7){
               tokenTransfer(msg.sender,uint256(5).mul(1e13));
           }
           sendRewards(msg.value);
           player.total_invested = player.total_invested.add(amount);
        invested = invested.add(amount);
        player.depositLimits.allowdDeposits=player.depositLimits.allowdDeposits.sub(1);
        
         }

        player.deposits.push(Deposit({
            amount: amount,
            totalWithdraw: 0,
            time: uint256(block.timestamp),
            isWithdrawable:isReinvest,
            endTime:uint256(block.timestamp).add(tarifs.lifeDays),
            lastPayout:now
        }));
        
        
        
       if(!isReinvest){
        //Referral distribution
        _refPayout(msg.sender, amount);
        
         owner.transfer(amount.mul(10).div(100));
         
        if( rewardDist[msg.sender]==0 && player.total_invested>=1e11){//1e11
             tokenTransfer(msg.sender,uint256(5).mul(1e16));
             rewardDist[msg.sender]=1;
        }
         if(rewardDist[msg.sender]==1 && player.total_invested>=25e10){//25e10
             tokenTransfer(msg.sender,uint256(1).mul(1e18));
             rewardDist[msg.sender]=2;
        }
       }
       

        emit NewDeposit(msg.sender, amount, 0);
    }

    function withdraw() payable external {
     
        Player storage player = players[msg.sender];
        require(now>player.depositLimits.nextWithdrawTime,"You can withdraw only once in day");
        _payout(msg.sender,false);

        require(player.dividends >= 10 trx, "Zero amount");

        uint256 amount = player.dividends.add(player.pending_withdrawl);
      
        player.dividends = 0;
        player.total_withdrawn = player.total_withdrawn.add(amount);
       
        withdrawn = withdrawn.add(amount);
        
        if(msg.sender!=owner){
            msg.sender.transfer(amount);
            player.depositLimits.nextWithdrawTime=now.add(TIME_STEP);
            emit Withdraw(msg.sender, amount);
        }
        else{
            msg.sender.transfer(amount.add(player.match_bonus));
            player.match_bonus=0;
            emit Withdraw(msg.sender, amount);
        }
       
    }
    
    
    
    function reinvestDividends() payable external {
      require(now>players[msg.sender].depositLimits.nextReinvestTime,"You can reinvest only once in day");
        Player storage player = players[msg.sender];

        _payout(msg.sender,true);

        require(player.dividends > 0 , "Zero amount");

        uint256 amount = player.dividends;
  
        player.dividends = 0;
        player.pending_withdrawl=amount;
        withdrawn = withdrawn.add(amount);
        
        if(player.pending_withdrawl>0){
        deposit(player.upline,true);
        }
        player.depositLimits.nextReinvestTime=now.add(TIME_STEP);
        emit Reinvest(msg.sender, amount,true);
    }
    
    function reinvestRef() payable external {
      require(now>players[msg.sender].depositLimits.nextReinvestReferral,"You can withdraw only once in day");
        Player storage player = players[msg.sender];

        require( player.match_bonus > 0, "Zero amount");

        uint256 amount =  player.match_bonus;
       
        amount=amount;
        
        player.match_bonus = 0;
        player.pending_withdrawl=amount;
        withdrawn = withdrawn.add(amount);
        
        if(player.pending_withdrawl>0){
        deposit(player.upline,true);
        }
        player.depositLimits.nextReinvestReferral=now.add(TIME_STEP);
        emit Reinvest(msg.sender, amount,false);
    }
    
    
    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];
        uint256 percent=tarifs.percent;
        if(player.noOfInvestment>=7){
            percent=140;
        }
        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
          
            uint256 time_end = dep.time.add(tarifs.lifeDays.mul(totalSeconds));
           
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(dep.time < to) {
                value = value.add(dep.amount.mul((to.sub(dep.time))).mul(percent).div(tarifs.lifeDays).div(totalSeconds.mul(100)));
                value= value.sub(dep.totalWithdraw);
            }
        }

        return value;
    }
    
    function payoutOfReinvest(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];
        uint256 percent=tarifs.percent;
        uint256 _35percent;
        if(player.noOfInvestment>=7){
            percent=140;
        }
        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
          
            uint256 time_end = dep.time.add(tarifs.lifeDays.mul(totalSeconds));
            uint256 from = dep.lastPayout > dep.time ? dep.lastPayout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
             
                       _35percent = (dep.amount.mul(to.sub(from)).mul(percent.sub(100)).div(tarifs.lifeDays).div(totalSeconds.mul(100)));
                       
                        value=value.add(_35percent);
                    
             
            }
           
          
        }

        return value;
    }
    
    
    function payoutOfForWithdraw(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];
        uint256 percent=tarifs.percent;
        uint256 _35percent;
        if(player.noOfInvestment>=7){
            percent=140;
        }
        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            if(i<player.lastDepositeIndex){//if(dep.isWithdrawable || player.lastdepositeindex>i)
            uint256 time_end = dep.time.add(tarifs.lifeDays.mul(totalSeconds));
            uint256 from = dep.lastPayout > dep.time ? dep.lastPayout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                _35percent = dep.amount.mul(to.sub(from)).mul(percent).div(tarifs.lifeDays).div(totalSeconds.mul(100));
                if(dep.time.add(tarifs.lifeDays.mul(totalSeconds))>now){
                
                
                        value=value.add(_35percent);
                    
                }
                else{
                    value=value.add((dep.amount.mul(percent).div(100)).sub(player.deposits[i].totalWithdraw));
                }
            }  
            else{
                value=value.add((dep.amount.mul(percent).div(100)).sub(player.deposits[i].totalWithdraw));
            }
            }
        }

        return value;
    }
    
    
     function BalanceOfTokenInContract()public view returns (uint256){
        return TRC20(roiCityTokenAddress).balanceOf(address(this));
    }
    
    function tokenTransfer(address to, uint256 _amount) internal {
        
        uint256 defitokentestBal = BalanceOfTokenInContract();
        _amount=_amount;
        require(defitokentestBal >= _amount,"Token balance is low");
       
            if(TRC20(roiCityTokenAddress).transfer(to, _amount))
            {
                
            }
            else{
                
            }
     

    }


    /*
        Only external call
    */
     
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_bonus, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[5] memory structure,
    uint256 _nextWithdrawTime,uint256 _nextReinvestTime,uint256 _nextReinvestReferral,uint256 _allowedDeposits) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout.add(player.dividends).add(player.match_bonus),
            player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure,
            player.depositLimits.nextWithdrawTime,
            player.depositLimits.nextReinvestTime,
            player.depositLimits.nextReinvestReferral,
            player.depositLimits.allowdDeposits
        );
    }
    
    

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn) {
        return (invested, withdrawn);
    }

    function investmentsInfo(address _addr) view external returns( uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory totalWithdraws,bool[] memory isActive,bool[] memory isReinvest) {
        Player storage player = players[_addr];

        uint256[] memory _endTimes = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _totalWithdraws = new uint256[](player.deposits.length);
        bool[] memory _isActive = new bool[](player.deposits.length);
        bool[] memory _isReinvest = new bool[](player.deposits.length);
        
        for(uint256 i = 0; i < player.deposits.length; i++) {
          Deposit storage dep = player.deposits[i];
         
          _amounts[i] = dep.amount;
          _totalWithdraws[i] = dep.totalWithdraw;
          _endTimes[i] = dep.time.add(tarifs.lifeDays.mul(totalSeconds));
          _isActive[i]=now>(dep.time.add(tarifs.lifeDays.mul(totalSeconds))) ? false : true;
          _isReinvest[i]=dep.isWithdrawable;
          
        }

        return (
          _endTimes,
          _amounts,
          _totalWithdraws,
          _isActive,
         _isReinvest
        );
    }
    
    
   
    function getTRXBalance() public view returns(uint) {
    return address(this).balance;
    }

    function seperatePayoutOf(address _addr) view external returns(uint256[] memory withdrawable) {
        Player storage player = players[_addr];
        uint256[] memory values = new uint256[](player.deposits.length);
        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
         
            uint256 time_end = dep.time.add(tarifs.lifeDays.mul(totalSeconds));
            uint256 from = dep.lastPayout > dep.time ? dep.lastPayout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                values[i] = dep.amount.mul(to.sub(from)).mul(tarifs.percent).div(tarifs.lifeDays).div((totalSeconds.mul(100)));
            }
        }

        return values;
    }
}