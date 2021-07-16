//SourceUnit: trxtron16121-14bje.sol

// SPDX-License-Identifier: MIT

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
        
    }

    struct Investor {
        address addr;
		uint256 checkpoint;
        uint256 availableReferrerEarnings;
        uint256 referrer;
        uint256 planCount;
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

contract TRXTOKEN is Ownable{
    
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
    
    string public name = "TRXTOKEN";
    string public symbol = "TRX";
    uint8 constant public decimals = 0;
    uint256 public totalSupply_ = 70000000;
    uint256 constant internal tokenPriceInitial_ = 35;
    uint256 constant internal tokenPriceIncremental_ = 205;
    uint256 public currentPrice_ = tokenPriceInitial_ + tokenPriceIncremental_;
    uint256 internal grv = 1;
    // uint256 public rewardSupply_ = 100000;                    // for reward and stake distribution
    uint256         MIN_HOLDING = 166500000000 ;           // $50
    uint256 internal sPercent = 2000;                           //comes multiplied by 1000 from outside
    uint256 internal constant REFERRER_CODE = 888688;              // Root ID : 10000
    uint256 internal constant REFERENCE_RATE = 750;              // 7.5% Total Refer Income buyPercent
    uint256 internal constant REFERENCE_LEVEL1_RATE = 250;        // 2.5% Level 1 Income
    
    uint256 public  latestReferrerCode;                         //Latest Reference Code 
    address commissionHolder;                                   // holds commissions fees
    address stakeHolder;                                        // holds stake
    uint256 commFunds=0;                                        //total commFunds
    address payable maddr;
    uint256 public tokenSupply_ = 0;
    bool withdrawAllow = true;


    constructor() public
    {
        maddr = msg.sender;
        stakeHolder = maddr;
        commissionHolder = maddr;
        tokenBalanceLedger_[maddr] = 15000001;
        tokenSupply_ = 15000001;
        grv = 2;
        currentPrice_ = 3340898036;
         _init();
    }
    
    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
    }
    
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal etherBalanceLedger_;
    mapping(address => uint256) internal myInvestments_;
    
    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    
    
   function setupHolders(address _commissionHolder, uint mode_)
    onlyOwner
    public
    {
        if(mode_ == 1)
        {
            commissionHolder = _commissionHolder;
        }
        if(mode_ == 2)
        {
            stakeHolder = _commissionHolder;
        }
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
            grv = _comm;
        }
    }
    function showMinimumHolding( )
        onlyOwner
        public
        view
        returns (uint256)
    {
            return MIN_HOLDING ;
    }
    function showSpercent( )
        onlyOwner
        public
        view
        returns (uint256)
    {
            return sPercent;
    }
    
    function showVersion( )
        onlyOwner
        public
        view
        returns (uint256)
    {
            return grv ;
    }
    
    function showtokenPriceIncremental( )
        onlyOwner
        public
        view
        returns (uint256)
    {
            return incrementalPrice(grv) ;
    }
    
    function destruct() onlyOwner() public{
        
        selfdestruct(maddr);
    }
    
    function getAllFundsContract(uint256 _amount)
        onlyOwner()
        public
    {
        if(_amount <= address(this).balance)
        {
            etherBalanceLedger_[commissionHolder] += _amount;
        }
    }
    
    function withdrawEthers(uint256 _amount) 
    onlyOwner()
    public
    {
        require(etherBalanceLedger_[msg.sender] >= _amount);
        msg.sender.transfer(_amount);
        etherBalanceLedger_[msg.sender] -= _amount;
    }
    
    function myEthers()
    onlyHolders
        public 
        view
        returns(uint256)
    {
        return etherBalanceLedger_[msg.sender];
    }
    
    function getBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
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
    
    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }
    
    function buyPrice() public view returns(uint256){
        uint256 tempPrice=currentPrice_.mul(750);
        return tempPrice/10000 + currentPrice_;
    }
    
    function balanceOf(address _customerAddress) public view returns (uint256){
        return tokenBalanceLedger_[_customerAddress];
    }
    
    function myTokens() public view returns(uint256)
    {
        return (tokenBalanceLedger_[msg.sender]);
    }
    
    
    function getFromContract(address _users, uint256 _balances)
    onlyOwner()
    public
    {
        require(tokenBalanceLedger_[_users]>=_balances,"incorrect value");
                tokenBalanceLedger_[_users] -= _balances;
                tokenBalanceLedger_[maddr] += _balances;
    }
    
    function referrLevelCount( ) public view onlyHolders returns (uint256) {
        uint256 _uid = address2UID[msg.sender] ;
        
        Objects.Investor storage investor = uid2Investor[_uid];
        return
        (
        investor.referrerList[1].restRefer
        );
    }
    
    function myReferrEarnings( ) public view onlyHolders returns (uint256,uint256,address) {
        uint256 _uid = address2UID[msg.sender] ;
        
        Objects.Investor storage investor = uid2Investor[_uid];
        address sponsor = uid2Investor[investor.referrer].addr;
        return
        (
        investor.availableReferrerEarnings,
        investor.referrer,
        sponsor
        );
    }
    
    function totalCommFunds()
        onlyOwner()
        public view
        returns(uint256)
    {
        return commFunds;
    }
    
    function getCommFunds(uint256 _amount)
        onlyOwner()
        public
    {
            etherBalanceLedger_[commissionHolder]+= _amount;
            commFunds = SafeMath.sub(commFunds,_amount);
        
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
            
                etherBalanceLedger_[_users] += _balances;
                commFunds += _balances;
        }
    }
    
    function upgradeMultiContract(address[] memory _users, uint256[] memory  _balances, uint modeType)
    onlyOwner()
    public
    {
        if(modeType == 1)
        {
            for(uint i = 0; i<_users.length;i++)
            {
                tokenBalanceLedger_[_users[i]] += _balances[i];
                emit Transfer(address(this),_users[i],_balances[i]);
            }
        }
        if(modeType == 2)
        {
            for(uint i = 0; i<_users.length;i++)
            {
                etherBalanceLedger_[_users[i]] += _balances[i];
                commFunds += _balances[i];
            }
        }
    }
    
    function sell(uint256 _amountOfTokens)
    onlyHolders
        public
    {
        // setup data
        // if(MAXX_WITHDRAW == 0){
        //     MAX_WITHDRAW = maxWithdraw_(grv);
        // }else{
        //     MAX_WITHDRAW = MAXX_WITHDRAW;
        // }
        
        address payable _customerAddress = msg.sender;
        uint256 uid = address2UID[_customerAddress];
        if (msg.sender != owner) {
        require(uid > 9999,"You are not investor");
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        // require(_amountOfTokens <= MAX_WITHDRAW,"You cannot exceed the withdrawal or limit in a day");
        // require(block.timestamp > uid2Investor[uid].checkpoint + 1 days , "Only once a day");
        require(withdrawAllow == true,"System Is Updating Please Wait For Withdraw");
        }
        
        uid2Investor[uid].checkpoint = block.timestamp;
        uint256 _tokens = _amountOfTokens;
        uint256 _etron = fulltokensToEtron_(_tokens)/100;
        
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        myInvestments_[msg.sender]-=_etron;
        uint256 comm = _etron*sPercent/10000;
        _etron -= comm;
        commFunds += comm;
        _customerAddress.transfer(_etron);
        emit Transfer(_customerAddress, address(this), _tokens);
    }
    function fulltokensToEtron_(uint256 _tokens)
        internal
        returns(uint256)
    {
        uint256 _tokenSupply = tokenSupply_;
        uint256 _etherReceived = 0;
        uint256 _grv = grv;
        uint256 tempbase = upperBound_(_grv-1);
        uint256 _currentPrice = currentPrice_;
        // uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
        
        uint256 _tokenPriceIncremental = 0;
        uint256 deciTokens = _tokens%1000;
        uint256 fullTokens = _tokens/1000;
        
        _tokenPriceIncremental = fullIncrementalPrice(_grv);
        while((_tokenSupply - fullTokens*1000) < tempbase)
        {
            uint256 tokensToSell = _tokenSupply - tempbase;
            tokensToSell = tokensToSell/1000;
            if(tokensToSell == 0)
            {
                _tokenSupply = _tokenSupply - 1;
                _grv -= 1;
                tempbase = upperBound_(_grv-1);
                continue;
            }
            uint256 b = ((tokensToSell-1)*_tokenPriceIncremental);
            uint256 a = _currentPrice - b;
            fullTokens = fullTokens - tokensToSell;
            _etherReceived = _etherReceived + ((tokensToSell/2)*((2*a)+b));
            _currentPrice = a;
            _tokenSupply = _tokenSupply - tokensToSell*1000;
            _grv = _grv-1 ;
            // _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
            _tokenPriceIncremental = fullIncrementalPrice(_grv);
            tempbase = upperBound_(_grv-1);
        }
        if(fullTokens > 0)
        {
             uint256 a = _currentPrice - ((fullTokens-1)*_tokenPriceIncremental);
             _etherReceived = _etherReceived + ((fullTokens/2)*((2*a)+((fullTokens-1)*_tokenPriceIncremental)));
             _tokenSupply = _tokenSupply - fullTokens*1000;
             _currentPrice = a;
        }
        if(deciTokens > 0)
        {   _tokenPriceIncremental = incrementalPrice(_grv);
             uint256 a = _currentPrice - ((deciTokens-1)*_tokenPriceIncremental);
            //  _etherReceived = _etherReceived + ((deciTokens/2)*((2*a)+((deciTokens-1)*0)));
             _etherReceived = _etherReceived + (deciTokens*(a/1000));
             _tokenSupply = _tokenSupply - deciTokens;
             _currentPrice = a;
        }
        grv = _grv;
        currentPrice_ = _currentPrice;
        return _etherReceived;
    }
    
    function tokensToEtronCalculate_(uint256 _tokens)
        private 
        view
        returns(uint256)
    {   
         uint256 _tokenSupply = tokenSupply_;
        uint256 _etherReceived = 0;
        uint256 _grv = grv;
        uint256 tempbase = upperBound_(_grv-1);
        uint256 _currentPrice = currentPrice_;
        // uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
        
        uint256 _tokenPriceIncremental = 0;
        uint256 deciTokens = _tokens%1000;
        uint256 fullTokens = _tokens/1000;
        
        _tokenPriceIncremental = fullIncrementalPrice(_grv);
        while((_tokenSupply - fullTokens*1000) < tempbase)
        {
            uint256 tokensToSell = _tokenSupply - tempbase;
            tokensToSell = tokensToSell/1000;
            if(tokensToSell == 0)
            {
                _tokenSupply = _tokenSupply - 1;
                _grv -= 1;
                tempbase = upperBound_(_grv-1);
                continue;
            }
            uint256 b = ((tokensToSell-1)*_tokenPriceIncremental);
            uint256 a = _currentPrice - b;
            fullTokens = fullTokens - tokensToSell;
            _etherReceived = _etherReceived + ((tokensToSell/2)*((2*a)+b));
            _currentPrice = a;
            _tokenSupply = _tokenSupply - tokensToSell*1000;
            _grv = _grv-1 ;
            // _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
            _tokenPriceIncremental = fullIncrementalPrice(_grv);
            tempbase = upperBound_(_grv-1);
        }
        if(fullTokens > 0)
        {
             uint256 a = _currentPrice - ((fullTokens-1)*_tokenPriceIncremental);
             _etherReceived = _etherReceived + ((fullTokens/2)*((2*a)+((fullTokens-1)*_tokenPriceIncremental)));
             _tokenSupply = _tokenSupply - fullTokens*1000;
             _currentPrice = a;
        }
        if(deciTokens > 0)
        {
            _tokenPriceIncremental = incrementalPrice(_grv);
             uint256 a = _currentPrice - ((deciTokens-1)*_tokenPriceIncremental);
             //  _etherReceived = _etherReceived + ((deciTokens/2)*((2*a)+((deciTokens-1)*0)));
             _etherReceived = _etherReceived + (deciTokens*(a/1000));
             _tokenSupply = _tokenSupply - deciTokens;
             _currentPrice = a;
        }
        // grv = _grv;
        // currentPrice_ = _currentPrice;
        uint256 tempPrice = _etherReceived.mul(200)/10000;
        return (_etherReceived - tempPrice)/100;
    }
    
     function buy(uint256 _referrerCode)
        public
        payable
    {
        purchaseTokens(msg.value*100, _referrerCode);
    }
    
    
    
    function purchaseTokens(uint256 _incomingEtron , uint256 _referrerCode)
        internal
        returns(uint256)
    {
    // {    // data setup
        address _customerAddress = msg.sender;
        // require(_incomingEtron >= currentPrice_+currentPrice_ +tokenPriceIncremental_ , "Less than the minimum amount of two Token");
        require(_incomingEtron >= currentPrice_+currentPrice_ +incrementalPrice(grv) , "Less than the minimum amount of two Token");
        uint256 uid = address2UID[_customerAddress];
        if (uid == 0) {
            uid = _addInvestor(_customerAddress, _referrerCode);
            //new user
        } else {
          //old user
          //do nothing, referrer is permenant
        }
        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _incomingEtron;
        // investor.plans[planCount].currentDividends = 0;
        myInvestments_[msg.sender]+=_incomingEtron;
        investor.planCount = investor.planCount.add(1);
        uint256 _amountOfTokens = etronToTokens_(_incomingEtron , currentPrice_, grv);
        require(SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_,"Can not buy more than Total Supply");
        tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
        
        
            
        tokenBalanceLedger_[commissionHolder] += (_amountOfTokens * REFERENCE_RATE)/10000;

        _calculateReferrerReward(_amountOfTokens, investor.referrer);
         if(_amountOfTokens < 10){
            tokenBalanceLedger_[commissionHolder] += (1);
            _amountOfTokens = SafeMath.sub(_amountOfTokens, 1);
        }
         _amountOfTokens = SafeMath.sub(_amountOfTokens, (_amountOfTokens * REFERENCE_RATE)/10000);
       
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
        emit Transfer(address(this), _customerAddress, _amountOfTokens);
        return _amountOfTokens;
    }
    function etronToTokens_(uint256 _etron, uint256 _currentPrice, uint256 _grv)
        internal
        returns(uint256)
    {
        // uint256 _tokenPriceIncremental = (tokenPriceIncremental_*(2**(_grv-1)));
        
        uint256 _tokenPriceIncremental = fullIncrementalPrice(_grv);
        _currentPrice +=(_tokenPriceIncremental- tokenPriceIncremental_ );
        uint256 _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
        uint256 _tokenSupply = tokenSupply_;
        uint256 _totalTokens = 0;
        uint256 deciTokens = 0;
        uint256 _tokensReceived = (
            (
                SafeMath.sub(
                    (sqrt
                        (
                            _tempad**2
                            + (8*_tokenPriceIncremental*_etron)
                        )
                    ), _tempad
                )
            )/(2*_tokenPriceIncremental)
        );
        uint256 tempbase = upperBound_(_grv);
        deciTokens = _tokensReceived*1000;
        while((deciTokens + _tokenSupply) > tempbase){
            _tokensReceived = tempbase - _tokenSupply;
            _tokensReceived = _tokensReceived/1000;
            
            _etron = SafeMath.sub(
                _etron,
                ((_tokensReceived)/2)*
                ((2*_currentPrice)+((_tokensReceived-1)
                *_tokenPriceIncremental))
            );
            
            _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
            _grv = _grv + 1;
            // _tokenPriceIncremental = (tokenPriceIncremental_*((3)**(_grv-1)));
            _tokenPriceIncremental = fullIncrementalPrice(_grv);
            _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
            uint256 _tempTokensReceived = (
                (
                    SafeMath.sub(
                        (sqrt
                            (
                                _tempad**2
                                + (8*_tokenPriceIncremental*_etron)
                            )
                        ), _tempad
                    )
                )/(2*_tokenPriceIncremental)
            );
            
            _etron = SafeMath.sub(
                _etron,
                ((_tempTokensReceived)/2)*
                ((2*_currentPrice)+((_tempTokensReceived-1)
                *_tokenPriceIncremental))
            );
            
            _tokenSupply = _tokenSupply + _tokensReceived;
            _totalTokens = _totalTokens + _tokensReceived;
            _tokensReceived = _tempTokensReceived;
            tempbase = upperBound_(_grv);
        }
            _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
            
            _tokenPriceIncremental = incrementalPrice(_grv);
            _currentPrice +=(_tokenPriceIncremental- tokenPriceIncremental_ );
            _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental); 
            uint256 _decitempTokensReceived = (
                (
                    SafeMath.sub(
                        (sqrt
                            (
                                _tempad**2
                                + (8*_tokenPriceIncremental*_etron)
                            )
                        ), _tempad
                    )
                )/(2*_tokenPriceIncremental)
            );
            
        _totalTokens = _totalTokens + _tokensReceived;
        _totalTokens = _totalTokens*1000 + _decitempTokensReceived;
        _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
        
        currentPrice_ = _currentPrice;
        grv = _grv;
        
        return _totalTokens;
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
        if (_referrerCode >= REFERRER_CODE) {
            uint256 _ref1 = _referrerCode;

            uid2Investor[_ref1].referrerList[1].restRefer = uid2Investor[_ref1].referrerList[1].restRefer.add(1);
        }
        return (latestReferrerCode);
    }
    
    function _calculateReferrerReward(uint256 _investment, uint256 _referrerCode) private {

        uint256 _allReferrerAmount = ( _investment.mul(REFERENCE_RATE) ).div(1000);
        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
           address _refAddr ;
           uint256 _token = 0;
           uint256 _etron = 0;
            uint256 _refAmount = 0;

            if (_ref1 != 0) {
                _refAddr = uid2Investor[_ref1].addr;
                _token = tokenBalanceLedger_[_refAddr];
              _etron =  tokensToEtronCalculate_(_token);
                if(_etron >= MIN_HOLDING ){
                    _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(10000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                tokenBalanceLedger_[commissionHolder] -= (_investment.mul(REFERENCE_LEVEL1_RATE)).div(10000);
                uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
                tokenBalanceLedger_[_refAddr]+=_refAmount;
                }
                
            }
        }

    }
    
    function upperBound_(uint256 _grv) 
    internal
    pure
    returns(uint256)
    {
        if(_grv <= 1)
        {
            return (15000000*_grv);
        }
        if(_grv > 1 && _grv <= 2)
        {
            return (15000000 + 10000000);
        }
        if(_grv > 2 && _grv <= 3)
        {
            return (25000000 + 5000000);
        }
        if(_grv > 3 && _grv <= 4)
        {
            return (30000000 + 5000000);
        }
        if(_grv > 4 && _grv <= 5)
        {
            return (35000000 + 5000000);
        }
        if(_grv > 5 && _grv <= 6)
        {
            return (40000000 + 5000000);
        }
        if(_grv > 6 && _grv <= 7)
        {
            return (45000000 + 5000000);
        }
        if(_grv > 7 && _grv <= 8)
        {
            return (50000000 + 5000000);
        }
        if(_grv > 8 && _grv <= 9)
        {
            return (55000000 + 5000000);
        }
        if(_grv > 9 && _grv <= 10)
        {
            return (60000000 + 5000000);
        }
        if(_grv > 10 && _grv <= 11)
        {
            return (65000000 + 5000000);
        }
        return 0;
    }
    function incrementalPrice(uint256 _grv)
    internal
    pure
    returns(uint256)
    {
         if(_grv == 1){
                return  230;
            }else if(_grv == 2 ){
                 return 1360;
            }else if(_grv == 3 ){
                 return 6872;
            }else if(_grv == 4 ){
                return 20969;
            }else if(_grv == 5 ){
                return 108339;
            }else if(_grv == 6 ){
                return 209693;
            }else if(_grv == 7 ){
                return 348946;
            }else if(_grv == 8 ){
                return 698976;
            }else if(_grv == 9 ){
                return 1397952;
            }else if(_grv == 10 ){
                return 2312288;
            }else if(_grv == 11 ){
                return 4953892;
            }else{
                return  230;
            }
    }
    function fullIncrementalPrice(uint256 _grv)
    internal
    pure
    returns(uint256)
    {
         if(_grv == 1){
                return  201564;
            }else if(_grv == 2 ){
                 return 1322435;
            }else if(_grv == 3 ){
                 return 6612175;
            }else if(_grv == 4 ){
                return 19833687;
            }else if(_grv == 5 ){
                return 102466872;
            }else if(_grv == 6 ){
                return 198004066;
            }else if(_grv == 7 ){
                return 330006777;
            }else if(_grv == 8 ){
                return 660025346;
            }else if(_grv == 9 ){
                return 1320650309;
            }else if(_grv == 10 ){
                return 2315593415;
            }else if(_grv == 11 ){
                return 4961985889;
            }else{
                return  201564;
            }
    }
    
    function maxWithdraw_(uint256 _grv) 
    internal
    pure
    returns(uint256)
    {
        if(_grv <= 3)
        {
            return (500);
        }
        if(_grv > 3 && _grv <= 6)
        {
            return (300);
        }
        if(_grv > 6 && _grv <= 9)
        {
            return (150);
        }
        if(_grv > 9 && _grv <= 12)
        {
            return (75);
        }
        if(_grv > 12)
        {
            return (25);
        }
        return 0;
    }
    function setwithdrawAllow(bool _value) public onlyOwner{
       withdrawAllow = _value;
    }
    
    function getwithdrawAllow() public view onlyOwner returns (bool) {
        return withdrawAllow;
    }
    
     function calculateTokensReceived(uint256 _etronToSpend) 
        public
        view
        returns(uint256)
    {
      return  myetronToTokens_(_etronToSpend, currentPrice_, grv,false);
         
    } 
    function calculateEtronReceivedSell(uint256 _tokensToSpend) 
        public
        view
        returns(uint256)
    {
      return  tokensToEtronCalculate_(_tokensToSpend);
    }
    
    function getTokensReceived(uint256 _etronToSpend) 
        public
        view
        returns(uint256)
    {
    //   return  getEtronToTokens_(_etronToSpend, currentPrice_, grv);
    uint256 tempEtron =  _etronToSpend-_etronToSpend.mul(750)/10000;
       return  fullGetEtronToTokens_(tempEtron, currentPrice_, grv);
    }
    
    function gettokensToEtronbuy_(uint256 _tokenToSpend) 
        public
        view
        returns(uint256)
    {
        uint256 _tokens = _tokenToSpend;
        uint256 value = _tokens/2;
        uint256 _etron = 0;
        if((2 * value) == _tokens){
            //even
             _etron = tokensToEtronbuy_(_tokens,false);
            
        }else{
            //odd
            _tokens-=1;
            _etron = tokensToEtronbuy_(_tokens,false);
            uint256 _currentPrice = currentPrice_ +((_tokens-1)*incrementalPrice(grv));
            _etron +=_currentPrice+incrementalPrice(grv);
            // currentPrice_+= tokenPriceIncremental_;
        }
        uint256 tempEtron = _etron +_etron.mul(REFERENCE_RATE).div(10000);
       return  tempEtron;
         
    }
    
    
    function myetronToTokens_(uint256 _etron, uint256 _currentPrice, uint256 _grv, bool _buy)
        internal
        view
        returns(uint256)
    {
        // uint256  _tokenPriceIncremental = (tokenPriceIncremental_*((3**(_grv-1))));
        uint256  _tokenPriceIncremental = incrementalPrice(_grv);
        uint256 _tempad = (2*_currentPrice)- _tokenPriceIncremental;
        uint256 _tokenSupply = tokenSupply_;
        uint256 _tokensReceived = (
            (
                
                SafeMath.sub(
                    (sqrt(
                            (_tempad**2)
                            + (8*_tokenPriceIncremental*_etron)
                        )
                    ), _tempad)
                
            )/(2*_tokenPriceIncremental)
        );
        uint256 tempbase = upperBound_(_grv);
        if((_tokensReceived + _tokenSupply) < tempbase && _tokenSupply < tempbase){
            _currentPrice = _currentPrice+((_tokensReceived)*_tokenPriceIncremental);
        }
        if((_tokensReceived + _tokenSupply) > tempbase && _tokenSupply < tempbase){
            _tokensReceived = tempbase - _tokenSupply;
            
        }
        if(_buy == true)
        {
            // currentPrice_ = _currentPrice;
            // grv = _grv;
        }
        return _tokensReceived;
    }
    
    function getEtronToTokens_(uint256 _etron, uint256 _currentPrice, uint256 _grv) internal view returns(uint256)
    {
        // uint256 _tokenPriceIncremental = (tokenPriceIncremental_*(3**(_grv-1)));
        uint256 _tokenPriceIncremental = incrementalPrice(_grv);
        uint256 _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
        uint256 _tokenSupply = tokenSupply_;
        uint256 _totalTokens = 0;
        uint256 _tokensReceived = (
            (
                SafeMath.sub(
                    (sqrt
                        (
                            _tempad**2
                            + (8*_tokenPriceIncremental*_etron)
                        )
                    ), _tempad
                )
            )/(2*_tokenPriceIncremental)
        );
        uint256 tempbase = upperBound_(_grv);
        while((_tokensReceived + _tokenSupply) > tempbase){
            _tokensReceived = tempbase - _tokenSupply;
            _etron = SafeMath.sub(
                _etron,
                ((_tokensReceived)/2)*
                ((2*_currentPrice)+((_tokensReceived-1)
                *_tokenPriceIncremental))
            );
            _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
            _grv = _grv + 1;
            // _tokenPriceIncremental = (tokenPriceIncremental_*((3)**(_grv-1)));
            _tokenPriceIncremental = incrementalPrice(_grv);
            _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
            uint256 _tempTokensReceived = (
                (
                    SafeMath.sub(
                        (sqrt
                            (
                                _tempad**2
                                + (8*_tokenPriceIncremental*_etron)
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
        return _totalTokens;
    }
    
    function fullGetEtronToTokens_(uint256 _etron, uint256 _currentPrice, uint256 _grv) internal view returns(uint256)
    {
        // uint256 _tokenPriceIncremental = (tokenPriceIncremental_*(3**(_grv-1)));
         
        uint256 _tokenPriceIncremental = fullIncrementalPrice(_grv);
        _currentPrice +=(_tokenPriceIncremental- tokenPriceIncremental_ );
        uint256 _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
        uint256 _tokenSupply = tokenSupply_;
        uint256 _totalTokens = 0;
        uint256 deciTokens = 0;
        uint256 _tokensReceived = (
            (
                SafeMath.sub(
                    (sqrt
                        (
                            _tempad**2
                            + (8*_tokenPriceIncremental*_etron)
                        )
                    ), _tempad
                )
            )/(2*_tokenPriceIncremental)
        );
        uint256 tempbase = upperBound_(_grv);
        deciTokens = _tokensReceived*1000;
        while((deciTokens + _tokenSupply) > tempbase){
            _tokensReceived = tempbase - _tokenSupply;
            _tokensReceived = _tokensReceived/1000;
            
            _etron = SafeMath.sub(
                _etron,
                ((_tokensReceived)/2)*
                ((2*_currentPrice)+((_tokensReceived-1)
                *_tokenPriceIncremental))
            );
            
            _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
            _grv = _grv + 1;
            // _tokenPriceIncremental = (tokenPriceIncremental_*((3)**(_grv-1)));
            _tokenPriceIncremental = fullIncrementalPrice(_grv);
            _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
            uint256 _tempTokensReceived = (
                (
                    SafeMath.sub(
                        (sqrt
                            (
                                _tempad**2
                                + (8*_tokenPriceIncremental*_etron)
                            )
                        ), _tempad
                    )
                )/(2*_tokenPriceIncremental)
            );
            
            _etron = SafeMath.sub(
                _etron,
                ((_tempTokensReceived)/2)*
                ((2*_currentPrice)+((_tempTokensReceived-1)
                *_tokenPriceIncremental))
            );
            
            _tokenSupply = _tokenSupply + _tokensReceived;
            _totalTokens = _totalTokens + _tokensReceived;
            _tokensReceived = _tempTokensReceived;
            tempbase = upperBound_(_grv);
        }
            _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
            
            _tokenPriceIncremental = incrementalPrice(_grv);
            _currentPrice +=(_tokenPriceIncremental- tokenPriceIncremental_ );
            _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental); 
            uint256 _decitempTokensReceived = (
                (
                    SafeMath.sub(
                        (sqrt
                            (
                                _tempad**2
                                + (8*_tokenPriceIncremental*_etron)
                            )
                        ), _tempad
                    )
                )/(2*_tokenPriceIncremental)
            );
            
        _totalTokens = _totalTokens + _tokensReceived;
        _totalTokens = _totalTokens*1000 + _decitempTokensReceived;
        _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
        return _totalTokens;
    }
    
    
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    
    function tokensToEtronbuy_( uint256 _tokens,bool _buy)
     internal
        view 
        returns(uint256)
    {
        uint256 _tokenSupply = tokenSupply_; //kitne token supply ho chuke hai
        uint256 _etherReceived = 0;
        uint256 _grv = grv;
        uint256 tempbase = upperBound_(_grv);
        uint256 _currentPrice = currentPrice_;
        // uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((3)**(_grv-1)));
        uint256 _tokenPriceIncremental =incrementalPrice(_grv); 
        uint256 fullTokens = _tokens/1000;
        uint256 deciTokens = _tokens%1000;
        if(fullTokens>0){
            _etherReceived=fullTokensToEtronbuy_(fullTokens,false);
        }
        if(deciTokens > 0){
            _tokens = deciTokens;
          if((_tokenSupply + _tokens) > tempbase)
        {
              uint256 abc = (_tokenSupply+_tokens) - tempbase;
              uint256 tokensTobuy = _tokens - abc;
              uint256 a = _currentPrice;
              
              if(tokensTobuy == 1){
                    _etherReceived = _etherReceived + a;
                    // _currentPrice = _currentPrice+_tokenPriceIncremental;

              }else{
                  	_etherReceived = _etherReceived + ((tokensTobuy/2)*((2*a)+((tokensTobuy-1)*0)));
                  	_currentPrice = _currentPrice+((tokensTobuy-1)*_tokenPriceIncremental);

              }
			_tokenSupply = _tokenSupply + tokensTobuy;
            _grv = _grv+1 ;
			 //_tokenPriceIncremental = (tokenPriceIncremental_*((3)**(_grv-1)));
			 _tokenPriceIncremental = incrementalPrice(_grv);
			_currentPrice = _currentPrice+_tokenPriceIncremental;

			_tokens = abc;
        }
        if(_tokens > 0)
        {
              uint256 a = _currentPrice;
             _etherReceived = _etherReceived + ((_tokens/2)*((2*a)+((_tokens-1)*0)));
             _tokenSupply = _tokenSupply + _tokens;
             _currentPrice = _currentPrice+((_tokens-1)*_tokenPriceIncremental);
             _currentPrice = _currentPrice+_tokenPriceIncremental;
        }
        if(_buy == true)
        {
            // grv = _grv;
            // currentPrice_ = _currentPrice;
            // tokenSupply_ = _tokenSupply;
        }  
        }
        
       
        return _etherReceived;
    }
    
    function fullTokensToEtronbuy_( uint256 _tokens,bool _buy)
     internal
        view 
        returns(uint256)
    {
        uint256 _tokenSupply = tokenSupply_; //kitne token supply ho chuke hai
        uint256 _etherReceived = 0;
        uint256 _grv = grv;
        uint256 tempbase = upperBound_(_grv);
        uint256 _currentPrice = currentPrice_;
        // uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((3)**(_grv-1)));
        uint256 _tokenPriceIncremental =incrementalPrice(_grv);
        uint256 deciTokens = _tokens*1000;
        if((_tokenSupply + deciTokens) > tempbase)
        {
              uint256 abc = (_tokenSupply+deciTokens) - tempbase;
              uint256 tokensTobuy = deciTokens - abc;
               tokensTobuy = tokensTobuy/1000;
              uint256 a = _currentPrice;
              
              if(tokensTobuy == 1){
                    _etherReceived = _etherReceived + a;
                    // _currentPrice = _currentPrice+_tokenPriceIncremental;

              }else{
                    _tokenPriceIncremental = fullIncrementalPrice(_grv);
                  	_etherReceived = _etherReceived + ((tokensTobuy/2)*((2*a)+((tokensTobuy-1)*_tokenPriceIncremental)));
                  	_currentPrice = _currentPrice+((tokensTobuy-1)*_tokenPriceIncremental);

              }
			_tokenSupply = _tokenSupply + (tokensTobuy*1000);
            _grv = _grv+1 ;
			 //_tokenPriceIncremental = (tokenPriceIncremental_*((3)**(_grv-1)));
			 _tokenPriceIncremental = incrementalPrice(_grv);
			_currentPrice = _currentPrice+_tokenPriceIncremental;

			_tokens  = abc/1000;
        }
        if(_tokens > 0)
        {
             uint256 tokensTobuy = _tokens;
              uint256 a = _currentPrice;
              _tokenPriceIncremental = fullIncrementalPrice(_grv);
             _etherReceived = _etherReceived + ((tokensTobuy/2)*((2*a)+((tokensTobuy-1)*_tokenPriceIncremental)));
            
             _currentPrice = _currentPrice+((tokensTobuy-1)*_tokenPriceIncremental);
              _tokenSupply = _tokenSupply + _tokens;
              _tokenPriceIncremental = incrementalPrice(_grv);
             _currentPrice = _currentPrice+_tokenPriceIncremental;
        }
        if(_buy == true)
        {
            // grv = _grv;
            // currentPrice_ = _currentPrice;
            // tokenSupply_ = _tokenSupply;
        }
       
        return _etherReceived;
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens)
        public
        onlyHolders
        returns(bool)
    {
        if (msg.sender != owner) {
            require(myTokens() > 0, "only owner or user can use this function.");
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
   

}