//SourceUnit: ATT60054.sol

    /**
     * Únete a la Mejor Comunidad de Emprendedores Digitales. 
     * --------------TRONFREEDOM
     * 
     * Telegram:  https://t.me/tronfreedom
     * Facebook:  https://fb.com/clubtronfreedom
     * Youtube: TRONFREEDOM
     * 
     */


pragma solidity 0.4.25;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}




contract TronFreedom {
     using SafeMath for uint256;
     
    struct User {
        address upline;
        uint256 referrals;
        uint256 payouts;
       
        bankA bankADetails;
       
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
        
        
         mapping(uint=>uint) banka;
         mapping(uint=>uint) bankb;
        mapping(uint=>uint) bankc;
         
         mapping(uint256 => bool) activeSafes;
         mapping(uint256=>uint256) bankBUpgradeEarnings;
         mapping(uint256=>uint256) bankBPendingEarnings;
         mapping(uint256 => uint256) noofpayments;
         mapping(uint256 => uint256) noofpaymentsinactive;
         mapping(uint256=>uint256[]) downline;
         
         uint id;
         
         bankC bankCDetails;
         bankB bankBDetails;
    }
    
    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
        uint256 amountintrx;
    }
    
    struct bankB{
        uint256 bankbearnings;
        uint256 safe1activetime;
        uint256 bankbpayout;
    }
    
    struct bankC{
        uint256 checkpoint;
        uint256 totalInvestment;
        uint256 totalDirectInvestment;
        uint256 bankcpayout;
         Deposit[] deposits;
    }
    
    struct bankA{
         uint256 bankaearnings;
        uint256 totalEarned;
        uint256 totalPayout;
        bool invested;
    }
    
    
    
    
   
    address  public owner;
    address  public tronfreedom;
   
    uint public TRX_FOR_ONE_USD=1;
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public TIME_STEP = 1 days;

    mapping(address => User) public users;

     mapping(uint256 => uint) public safes;
    uint256[] public ref_bonuses;                     // 1 => 1%

    uint8[] public pool_bonuses;                    // 1 => 1%
    uint40 public pool_last_draw = uint40(now);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    uint256 public totalBankAInvested;
    uint256 public totalBankBInvested;
    uint256 public totalBankCInvested;
    uint256 public totalBankCBalance;
    uint256 public totalBankADistributed;
    uint256 public totalBankBDistributed;
    uint256 public totalBankCDistributed;
    
    uint public curruserid=1;
    
    event Upline(address indexed addr, address indexed upline);
   
    event NewDepositBankA(address indexed addr,uint256 amountintrx,uint256 usdvalue,address upline);
    event NewDepositBankB(address indexed addr,uint256 amountintrx,uint256 usdvalue,address upline);
    event NewDepositBankC(address indexed addr,uint256 amountintrx,uint256 usdvalue,address upline);
   
    event MatchPayout(address indexed addr, address indexed from, uint256 amount,uint256 level);
 
    event WithdrawnBankC(address indexed user, uint256 amount,uint256 USDVAL);
    event WithdrawnBankB(address indexed user, uint256 amount,uint256 USDVAL);
    event WithdrawnBankA(address indexed user, uint256 amount,uint256 USDVAL);
    
    event Earnings(address indexed user,uint256 amount,uint256 bankType);

    constructor(address _owner,address _pricesetter) public {
        owner = _owner;
        tronfreedom=_pricesetter;
        ref_bonuses.push(10);
        ref_bonuses.push(20);
        ref_bonuses.push(2);
        ref_bonuses.push(3);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
    
      users[owner].deposit_time=uint40(now);
        
          safes[1] = 30;
          users[owner].activeSafes[1]=true;
       
        for (uint8 ii = 2; ii <= 8; ii++) {
            safes[ii] = safes[ii-1] * 2;
             users[owner].activeSafes[ii]=true;
        }
        
        users[owner].id=curruserid++;
    }
    
    function exchangeratefortrx(uint amountperusd) public {
        require(msg.sender==tronfreedom,"Invalid address");
        TRX_FOR_ONE_USD=amountperusd;
    }
    
    function changeAmountTRXtoUSD(uint256 amount) public view returns(uint256){
        return (amount*1 trx*TRX_FOR_ONE_USD).div(100);
    }
    
    function setPriceSetAddress(address newAddress)public {
        require(msg.sender==owner,"Only owner can edit this");
        tronfreedom=newAddress;
    }
    
    function() payable external {
        _depositBankA(owner);
    }

     function _setUpline(address _addr,address _upline) private 
     {
          if (users[_addr].upline == address(0) && users[_upline].deposit_time> 0 && _upline != msg.sender) {
            users[_addr].upline = _upline;
             users[_addr].id=curruserid++;
            users[_upline].referrals++;
             emit Upline(_addr, _upline);
             
             total_users++;
        }

     }
    
    function _depositBankA(address _upline) public payable {
        uint256 _amount=msg.value;
        address _addr=msg.sender;
      
        _setUpline(_addr,_upline);
       
        require(users[_addr].upline != address(0), "No upline");
        
        require(_amount==(changeAmountTRXtoUSD(55)), "Bad amount");
        
        require(users[_addr].bankADetails.invested==false,"Allready Invested");
        
        
        users[_addr].deposit_amount = _amount;
        
        users[_addr].deposit_time = uint40(now);
        
        users[_addr].bankADetails.invested=true;
        total_deposited += _amount;
        
        _refPayout(msg.sender);
        emit NewDepositBankA(_addr, _amount,TRX_FOR_ONE_USD,users[_addr].upline);

        totalBankAInvested=totalBankAInvested.add(55);
        
        owner.transfer(changeAmountTRXtoUSD(5));
        
    }
    
    function _refPayout(address _addr) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            
                uint256 bonus =  ref_bonuses[i];
                
                if( (users[up].bankADetails.bankaearnings.add(bonus)>30 || users[up].activeSafes[1]) && i<=1){
                     users[up].bankADetails.bankaearnings= users[up].bankADetails.bankaearnings.add(bonus.mul(90).div(100));
                   uint256 amount10=changeAmountTRXtoUSD(bonus.mul(10).div(100));
                     DepositeBankCInternal(up,amount10,amount10.div(TRX_FOR_ONE_USD).div(10000).mul(1 trx));
                   
                    
                }else{
                users[up].bankADetails.bankaearnings =  users[up].bankADetails.bankaearnings.add(bonus);
                emit Earnings(up,bonus,1);
                }
                emit MatchPayout(up, _addr, bonus,i);
                users[up].banka[i+1]++;
             
                if( users[up].bankADetails.bankaearnings>=30 && users[up].activeSafes[1]==false)
                {
                    users[up].bankADetails.bankaearnings = users[up].bankADetails.bankaearnings.sub(30);
                    depositeBankBInternal(up);
                }
                up = users[up].upline;
        }
    }
    
    
    function withdrawBankA() public 
    {   
        uint256 earnings=users[msg.sender].bankADetails.bankaearnings;  
        if(!users[msg.sender].activeSafes[1])   
        require(earnings>30,"Insufficient amount to withdraw"); 
        else    
        require(earnings>0,"Insufficient balance to withdraw"); 
            uint256 payableamount=changeAmountTRXtoUSD(earnings);
        require(address(this).balance>=payableamount,"Contract Balance is low"); 
        if(msg.sender.send(payableamount)){ 
            users[msg.sender].bankADetails.totalPayout=users[msg.sender].bankADetails.totalPayout.add(earnings);
            users[msg.sender].bankADetails.bankaearnings=0; 
            emit WithdrawnBankA(msg.sender,payableamount,TRX_FOR_ONE_USD);
            totalBankADistributed=totalBankADistributed.add(earnings);
        }
       
    }   


   
    
    function _depositBankB(address _upline) public payable {
        uint256 _amount=msg.value;
        address _addr=msg.sender;
         _setUpline(msg.sender, _upline);
        require(users[_addr].upline != address(0), "No upline");
        require(users[_addr].bankADetails.invested,"Bank A need to be activated");
        require(_amount==(changeAmountTRXtoUSD(30)), "Bad amount");
        require(users[msg.sender].activeSafes[1]!=true,"Allready activated");
        
        depositeBankBInternal(msg.sender);
        
        
      
    }
    
    function buySafe(uint8 safeno) public payable
    {
        require(msg.value>=changeAmountTRXtoUSD(safes[safeno]),"Invalid amount");
        require(users[msg.sender].activeSafes[safeno-1],"Need to buy old slot first");
        require(users[msg.sender].activeSafes[safeno]!=true,"Allready activated");
         users[msg.sender].bankBDetails.bankbearnings=users[msg.sender].bankBDetails.bankbearnings.add(users[msg.sender].bankBUpgradeEarnings[safeno-1]);
         users[msg.sender].bankBUpgradeEarnings[safeno-1]=0;
         users[msg.sender].activeSafes[safeno]=true;
        
        placeinMatrix(msg.sender,safeno);
        emit NewDepositBankB(msg.sender,msg.value,TRX_FOR_ONE_USD,users[msg.sender].upline);
        totalBankBInvested=totalBankBInvested.add(safes[safeno]);
    }
    
    function depositeBankBInternal(address _addr) private
    {
         users[_addr].activeSafes[1]=true;
         users[_addr].deposit_time=uint40(now);
         
        users[_addr].bankBDetails.safe1activetime=now;
        placeinMatrix(_addr,1);
        totalBankBInvested=totalBankBInvested.add(safes[1]);
        emit NewDepositBankB(_addr,changeAmountTRXtoUSD(30),TRX_FOR_ONE_USD,users[_addr].upline);
    }
    
    function placeinMatrix(address _addr,uint256 safeno) private{
        address upline=users[_addr].upline;
        if(users[upline].activeSafes[safeno]){
        users[upline].downline[safeno].push(users[_addr].id);
        users[upline].noofpayments[safeno]+=1;
        }
        else
        {
            users[upline].noofpaymentsinactive[safeno]=users[upline].noofpaymentsinactive[safeno].add(1);
        }
       
        if(users[upline].noofpayments[safeno]==3 && users[upline].activeSafes[safeno] && users[upline].activeSafes[safeno+1]==false && safeno<8){
            users[upline].activeSafes[safeno+1]=true;
           
            users[upline].activeSafes[safeno.add(1)]=true;
             users[upline].bankBUpgradeEarnings[safeno]=users[upline].bankBUpgradeEarnings[safeno].add(safes[safeno]);
       
                users[upline].bankBUpgradeEarnings[safeno]=users[upline].bankBUpgradeEarnings[safeno].sub(safes[safeno.add(1)]);
                    
                placeinMatrix(upline,safeno.add(1));
        
        }
        else
        {
            if((users[upline].noofpayments[safeno]>1 && users[upline].noofpayments[safeno]<=3) && !users[upline].activeSafes[safeno+1] && safeno<8){
                
                users[upline].bankBUpgradeEarnings[safeno]=users[upline].bankBUpgradeEarnings[safeno].add(safes[safeno]);
            }
            else{
                if(users[upline].activeSafes[safeno]){
                    users[upline].bankBDetails.bankbearnings=users[upline].bankBDetails.bankbearnings.add(safes[safeno]);
                    emit Earnings(upline,safes[safeno],2);
                }else 
                {
                    users[upline].bankBDetails.bankbearnings=users[upline].bankBDetails.bankbearnings.add(safes[safeno].mul(20).div(100));
                    emit Earnings(upline,safes[safeno].mul(20).div(100),2);
                    TransferToOwner(changeAmountTRXtoUSD(safes[safeno].mul(80).div(100)));
                }
            }
        }
        
        if(users[upline].activeSafes[safeno] && (users[upline].noofpayments[safeno]>3 || (users[upline].noofpayments[safeno]>3 && users[upline].activeSafes[safeno.add(1)]))){
            uint256 amount10= safes[safeno].mul(10).div(100);
            users[upline].bankBDetails.bankbearnings=users[upline].bankBDetails.bankbearnings.sub(amount10);
            DepositeBankCInternal(upline,changeAmountTRXtoUSD(amount10),changeAmountTRXtoUSD(amount10).div(TRX_FOR_ONE_USD).div(10000).mul(1 trx));
            
        }
    }
    
    
    function TransferToOwner(uint256 amount) private
    {
        if(owner.send(amount)){
            
        }
    }
     function withdrawBankB() public    
    {   
        uint256 earnings=users[msg.sender].bankBDetails.bankbearnings;  
        
        require(earnings>0,"Insufficient balance to withdraw"); 
            
        require(address(this).balance>=changeAmountTRXtoUSD(earnings),"Contract Balance is low"); 
        uint256 payableamount=changeAmountTRXtoUSD(earnings); 
        if(msg.sender.send(payableamount)){ 
            users[msg.sender].bankBDetails.bankbpayout=users[msg.sender].bankBDetails.bankbpayout.add(earnings);
            users[msg.sender].bankBDetails.bankbearnings=0; 
            emit WithdrawnBankB(msg.sender,payableamount,TRX_FOR_ONE_USD);
            totalBankBDistributed=totalBankBDistributed.add(earnings);
        }   
    }
    
    function usersBankBearnings(address user,uint256 safeno) public view returns(uint256){
        return users[user].bankBUpgradeEarnings[safeno];
    }
    
    function usersBBearnings(address user) public view returns(uint256){
        return users[user].bankBDetails.bankbearnings;
    }

    function _depositBankC(address _upline) public payable {
        address _addr=msg.sender;
        _setUpline(msg.sender, _upline);
        require(users[_addr].upline != address(0), "No upline");
     
     require(users[_addr].bankCDetails.totalInvestment.add(msg.value)<changeAmountTRXtoUSD(10000), "Invalid amount");
        DepositeBankCInternal(msg.sender,msg.value,msg.value.div(TRX_FOR_ONE_USD).div(10000).mul(1 trx));
        
        
    }
    
    function DepositeBankCInternal(address _addr,uint256 amountintrx,uint256 amountinusd) private {
           if (users[_addr].bankCDetails.deposits.length == 0) {
            users[_addr].bankCDetails.checkpoint = now;
        }
        users[_addr].deposit_time=uint40(now);
        users[_addr].bankCDetails.totalInvestment= users[_addr].bankCDetails.totalInvestment.add(amountinusd);
        users[users[_addr].upline].bankCDetails.totalDirectInvestment= users[users[_addr].upline].bankCDetails.totalDirectInvestment.add(amountinusd);
        users[_addr].bankCDetails.deposits.push(Deposit(amountinusd, 0, now,amountintrx));
        emit NewDepositBankC(_addr,amountintrx,TRX_FOR_ONE_USD,users[_addr].upline);
        totalBankCInvested=totalBankCInvested.add(amountinusd);
        totalBankCBalance=totalBankCBalance.add(amountintrx);
    }
    
    function getUserCustomPercentRate() public view returns (uint256) {
        if(users[msg.sender].bankCDetails.totalInvestment>0 && users[msg.sender].bankCDetails.totalDirectInvestment>0){
       uint256 per= users[msg.sender].bankCDetails.totalDirectInvestment.mul(100).div(users[msg.sender].bankCDetails.totalInvestment);
            if(per<25){
                return 10;
            }
            else if(per>=25 && per<=49){
                return 20;
            }
            else if(per>=50 && per<=74)
            {
                return 30;
            }
            else if(per>=75 && per<=99){
                return 40;
            }
            else if(per>99)
            {
                return 50;
            }
        }
        else{
            return 10;
        }
    }
    
    function getUserPercentRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 contractBalanceRate = getUserCustomPercentRate();
        if (isActive(userAddress)) {
            uint256 timeMultiplier = (now.sub(user.bankCDetails.checkpoint)).div(TIME_STEP);
            return contractBalanceRate.add(timeMultiplier);
        } else {
            return contractBalanceRate;
        }
    }
    
    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (user.bankCDetails.deposits.length > 0) {
            if (user.bankCDetails.deposits[user.bankCDetails.deposits.length-1].withdrawn < user.bankCDetails.deposits[user.bankCDetails.deposits.length-1].amount.mul(2)) {
                return true;
            }
        }
    }
    
    
    
    function withdrawBankC() public {
        User storage user = users[msg.sender];

        uint256 userPercentRate = getUserPercentRate(msg.sender);

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.bankCDetails.deposits.length; i++) {

            if (user.bankCDetails.deposits[i].withdrawn < user.bankCDetails.deposits[i].amount.mul(2)) {

                if (user.bankCDetails.deposits[i].start > user.bankCDetails.checkpoint) {

                    dividends = (user.bankCDetails.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(now.sub(user.bankCDetails.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.bankCDetails.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(now.sub(user.bankCDetails.checkpoint))
                        .div(TIME_STEP);
                }

                if (user.bankCDetails.deposits[i].withdrawn.add(dividends) > user.bankCDetails.deposits[i].amount.mul(2)) {
                    dividends = (user.bankCDetails.deposits[i].amount.mul(2)).sub(user.bankCDetails.deposits[i].withdrawn);
                }

                user.bankCDetails.deposits[i].withdrawn = user.bankCDetails.deposits[i].withdrawn.add(dividends); /// changing of storage data
                totalAmount = totalAmount.add(dividends);

            }
        }
        users[msg.sender].bankCDetails.bankcpayout=users[msg.sender].bankCDetails.bankcpayout.add(totalAmount);
        totalBankCDistributed=totalBankCDistributed.add(totalAmount);
        
        totalAmount=totalAmount.mul(TRX_FOR_ONE_USD).div(100);
        
        
        require(totalBankCBalance>=totalAmount,"Insufficient funds");
        require(totalAmount > 0, "User has no dividends");
        totalBankCBalance=totalBankCBalance.sub(totalAmount);
        
        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.bankCDetails.checkpoint = now;

        msg.sender.transfer(totalAmount);

    

        emit WithdrawnBankC(msg.sender, totalAmount,TRX_FOR_ONE_USD);

    }
    
    
    
        function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 userPercentRate = getUserPercentRate(userAddress);

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.bankCDetails.deposits.length; i++) {

            if (user.bankCDetails.deposits[i].withdrawn < user.bankCDetails.deposits[i].amount.mul(2)) {

                if (user.bankCDetails.deposits[i].start > user.bankCDetails.checkpoint) {

                    dividends = (user.bankCDetails.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(now.sub(user.bankCDetails.deposits[i].start))
                        .div(TIME_STEP);
                } else {
                    dividends = (user.bankCDetails.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(now.sub(user.bankCDetails.checkpoint))
                        .div(TIME_STEP);
                }

                if (user.bankCDetails.deposits[i].withdrawn.add(dividends) > user.bankCDetails.deposits[i].amount.mul(2)) {
                    dividends = (user.bankCDetails.deposits[i].amount.mul(2)).sub(user.bankCDetails.deposits[i].withdrawn);
                }

                totalDividends = totalDividends.add(dividends);

                /// no update of withdrawn because that is view function

            }

        }

        return totalDividends;
    }

   
  

    /*
        Only external call
    */
    function userInfoBankA() public view  returns(uint256[7] memory structure,uint referralIncome)
    {
          for(uint8 i = 1; i <= ref_bonuses.length; i++) {
            structure[i-1] = users[msg.sender].banka[i];
        }
        return (structure,users[msg.sender].bankADetails.bankaearnings);
    }
    
    function userIsActiveSafe(address _add,uint8 level) public view  returns(bool  structure,uint256 noofpayments,uint256 pendingPayments)
    {
         
        return (users[_add].activeSafes[level],users[_add].noofpayments[level].add(users[_add].noofpaymentsinactive[level]),users[_add].bankBPendingEarnings[level]);
    }
    
          function userDownlinebankB(address _addr,uint8 level) public view  returns(uint[3] memory structure)
    {
          for(uint8 i = 0; i < 3; i++) {
              if(users[_addr].downline[level].length>i){
                  
            structure[i] = users[_addr].downline[level][i];
              }
              else
              {
                  structure[i]=0;
              }
        }
        return (structure);
    }
    
    function userDownlinebankBAll(address _addr,uint8 level) public view  returns(uint[] memory structure)
    {
        return  users[_addr].downline[level];
          
         
    }
    
    function getDetails(address userAddress,uint8 i)public view returns(uint256) {
        return users[userAddress].bankCDetails.deposits[i].start;
    }
    
    function getUserTotalDeposits(address userAddress) public view returns(uint256 _amountinusd,uint256 _amountintrx) {
        User storage user = users[userAddress];

        uint256 amount;
        uint256 amountinusd;

        for (uint256 i = 0; i < user.bankCDetails.deposits.length; i++) {
            if (user.bankCDetails.deposits[i].withdrawn < user.bankCDetails.deposits[i].amount.mul(2)) {

            amount = amount.add(user.bankCDetails.deposits[i].amount);
            amountinusd=amountinusd.add(user.bankCDetails.deposits[i].amountintrx);
            }
        }

        return (amount,amountinusd);
    }
    
    function isBankAactivated(address _add)public view returns(bool){
        return users[_add].bankADetails.invested;
    }
    
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 match_bonus,uint256 id, uint256 bankbearnings) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts,  users[_addr].bankADetails.bankaearnings,users[_addr].id,users[_addr].bankBDetails.bankbearnings);
    }
    
    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }
    
    function userInfoBankC(address _addr) view external returns(uint256 totalInvestment, uint256 totalDirectInvestment,uint256 starttime) {
        return (users[_addr].bankCDetails.totalInvestment,users[_addr].bankCDetails.totalDirectInvestment,users[_addr].bankBDetails.safe1activetime);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider,uint256 _totalusers) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]],total_users);
    }
    
    function distributedInfo() view external returns(uint256 _totalAI,uint256 _totalAD,uint256 _totalBI,uint256 _totalBD,uint256 _totalCI,uint256 _totalCD,uint256 _totalBankCBalance){
        return (totalBankAInvested,totalBankADistributed,totalBankBInvested,totalBankBDistributed,totalBankCInvested,totalBankCDistributed,totalBankCBalance);
    }
    
    function userInfoBankEarnings(address _addr) view external returns(uint256 bankaearnings, uint256 bankbearnings,uint256 bankcearnings) {
        return (users[_addr].bankADetails.bankaearnings,users[_addr].bankBDetails.bankbearnings,users[_addr].bankCDetails.bankcpayout);
    }
    
    function userInfoBankPayouts(address _addr) view external returns(uint256 bankaearnings, uint256 bankbearnings,uint256 bankcearnings) {
        return (users[_addr].bankADetails.totalPayout,users[_addr].bankBDetails.bankbpayout,users[_addr].bankCDetails.bankcpayout);
    }

    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
}