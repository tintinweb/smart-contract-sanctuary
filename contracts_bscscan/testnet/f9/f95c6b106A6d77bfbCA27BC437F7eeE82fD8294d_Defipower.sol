/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

pragma solidity ^0.8.1;




contract Defipower {
      modifier onlyDefiPowerAdmin(){
        address defiPowerHolderAddress = msg.sender;
        require(administrators[defiPowerHolderAddress]);
        _;
    }
    modifier onlyDefiPowerHolders() {
        require(myTokens() > 0);
        _;
    }
    modifier onlyPrelaunchContract(){
        require(msg.sender==address(preLaunchSwapAddress));
        _;
    }
    
  

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
        uint256 BnbWithdrawn
    );
    event RewardWithdraw(
        address indexed customerAddress,
        uint256 tokens
    );
    event Buy(
        address indexed buyer,
        uint256 tokensBought
    );
    event Sell(
        address indexed seller,
        uint256 tokensSold
    );
    event Stake(
        address indexed staker,
        uint256 tokenStaked
    );
    event Unstake(
        address indexed staker,
        uint256 tokenRestored
    );
   event LevelIncome (
       address indexed initialSender, 
       address to,
       uint256 forlevel,
       uint256 amount
       );
       
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public  name = "Defipower";
    string public symbol = "DFPW";
    uint8 public decimals = 5;
    uint256 public totalSupply_ = 310000000000;
    uint256 constant internal startDefiPowerPrice_ = 2500000000;
    uint256  internal tokenPriceIncremental_ = 100;
    uint256 internal buyPercent = 500; //comes multiplied by 1000 from outside
    uint256 internal sellPercent = 20000;
    uint256 internal referralPercent = 500;
    uint256 internal _defiPowerTransferFees = 25;
    uint256 public currentPrice_ = startDefiPowerPrice_;
    uint256 public growthFactor = 1;
    // Please verify the website https://Defipower.com before purchasing tokens
    address public preLaunchSwapAddress;
    address commissionHolder; // holds commissions fees 
    address stakeHolder; // holds stake
    address payable devAddress; // Growth funds
    mapping(address => uint256) internal defiPowerAccountLedger_;
    mapping(address => uint256) internal defiPowerStakingLedger_;
    bool stakingPeriodOver;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => address) referrerBy;
    uint256[] levelIncomes = [8,7,6,5,4,3,2,1];

    uint256[8] internal slabPercentage = [1,1,1,1,1,1,1,1];
    uint256 [8] public requiredStaking = [100,200,400,600,800,1600,3200,6400];
    address payable sonk;
    uint public withDrawApprovals = 0; 
    uint256 public tokenSupply_ = 0;
    // uint256 internal profitPerShare_;
    mapping(address => bool) internal administrators;
    mapping(address => bool) internal moderators;
    uint256 commFunds=0;
  //  uint256 i =0;
    bool mutex = false;
    constructor()
    {
        sonk = payable(msg.sender);
        administrators[sonk] = true; 
        commissionHolder = sonk;
        stakeHolder = sonk;
        commFunds = 0;
        
    }
    
    /**********************************************************************/
    /**************************UPGRADABLES*********************************/
    /**********************************************************************/
    
    
    function preLaunchSwap (address receipient, uint _amount) onlyPrelaunchContract() public returns (uint256) {
        if (stakingPeriodOver){
       //  defiPowerStakingLedger_[receipient] = _SafeMath.sub(defiPowerStakingLedger_[receipient], _amount);
         defiPowerAccountLedger_[receipient] = _SafeMath.add(defiPowerAccountLedger_[receipient], _amount);
         return _amount;
        }
        return 0;
    }
    
   function updateStakingPeriodOver(bool _over) onlyDefiPowerAdmin() public returns (bool){
      stakingPeriodOver = _over;
      return stakingPeriodOver;
   }
 
    function upgradeContract(address[] memory _users, uint256[] memory _balances)
    onlyDefiPowerAdmin()
    public
    {
        for(uint256 i = 0; i<_users.length;i++)
        {
               defiPowerAccountLedger_[_users[i]] += _balances[i];
            tokenSupply_ += _balances[i];
            emit Transfer(address(this),_users[i], _balances[i]);
           
            
        }
    }
    
    receive() external payable
    {
    purchaseTokens(address(0), msg.value );
    }
    
    function upgradeDetails(uint256 _currentPrice, uint256 _growthFactor, uint256 _commFunds, address _preLaunchSwapAddress)
    onlyDefiPowerAdmin()
    public
    {
        currentPrice_ = _currentPrice;
        growthFactor = _growthFactor;
        commFunds = _commFunds;
        preLaunchSwapAddress = _preLaunchSwapAddress;
    }
    
    function setupHolders(address _commissionHolder, address _stakeHolder, uint mode_)
    onlyDefiPowerAdmin()
    public
    {
        if(mode_ == 1)
        {
            commissionHolder = _commissionHolder;
        }
        if(mode_ == 2)
        {
            stakeHolder = _stakeHolder;
        }
    }
    
    
    function withdrawStake(uint256[] memory _amount, address[] memory defiPowerHolderAddress)
        onlyDefiPowerAdmin()
        public 
    {
        for(uint i = 0; i<defiPowerHolderAddress.length; i++)
        {
            uint256 _toAdd = _amount[i];
            defiPowerAccountLedger_[defiPowerHolderAddress[i]] = _SafeMath.add(defiPowerAccountLedger_[defiPowerHolderAddress[i]],_toAdd);
            defiPowerAccountLedger_[stakeHolder] = _SafeMath.sub(defiPowerAccountLedger_[stakeHolder], _toAdd);
            emit Unstake(defiPowerHolderAddress[i], _toAdd);
            emit Transfer(address(this),defiPowerHolderAddress[i],_toAdd);
        }
    }
    
    /**********************************************************************/
    /*************************BUY/SELL/STAKE*******************************/
    /**********************************************************************/
    
    function buy(address _referrer)
        public
        payable
    {
        purchaseTokens(_referrer, msg.value);
    }       
    
    fallback() payable external
    {
        purchaseTokens(address(0), msg.value);
    }
    
    function holdStake(uint256 _amount) 
    onlyDefiPowerHolders()
    public
    {
        require(!isContract(msg.sender),"Stake from contract is not allowed");
        require(_amount>5000000,"Low Staking Amount!");
        defiPowerAccountLedger_[msg.sender] = _SafeMath.sub(defiPowerAccountLedger_[msg.sender], _amount);
        defiPowerStakingLedger_[msg.sender] = _SafeMath.add(defiPowerStakingLedger_[msg.sender], _amount);
        defiPowerAccountLedger_[stakeHolder] = _SafeMath.add(defiPowerAccountLedger_[stakeHolder], _amount);
    //  Add Staking and Transfer event values for finding out total values, No need to emit double events. 
    //    emit Transfer(msg.sender,address(this),_amount);
        emit Stake(msg.sender, _amount);
    }
    
    function getStake(address _staker) public  view
        returns(uint256) {
            uint256 rewards =  defiPowerStakingLedger_[_staker] ;
            return rewards;
        }
        
    function unstake(uint256 _amount, address defiPowerHolderAddress)
    onlyDefiPowerAdmin()
    public
    {
        // check if the holder holds DFPW equal ot _amount . If yes, check if block.Number 
        defiPowerAccountLedger_[defiPowerHolderAddress] = _SafeMath.add(defiPowerAccountLedger_[defiPowerHolderAddress],_amount);
        defiPowerAccountLedger_[stakeHolder] = _SafeMath.sub(defiPowerAccountLedger_[stakeHolder], _amount);
        defiPowerStakingLedger_[msg.sender] = _SafeMath.sub(defiPowerStakingLedger_[msg.sender], _amount);

        emit Transfer(address(this),defiPowerHolderAddress,_amount);
        emit Unstake(defiPowerHolderAddress, _amount);
    }
    
    function withdrawRewards(uint256 _amount, address defiPowerHolderAddress)
        onlyDefiPowerAdmin()
        public 
    {
        defiPowerAccountLedger_[defiPowerHolderAddress] = _SafeMath.add(defiPowerAccountLedger_[defiPowerHolderAddress],_amount);
        tokenSupply_ = _SafeMath.add (tokenSupply_,_amount);
    }
    function updateI(uint256 _io) public onlyDefiPowerAdmin {
        tokenPriceIncremental_ = _io;
    }
    function withdrawComm(uint256[] memory _amount, address[] memory defiPowerHolderAddress)
        onlyDefiPowerAdmin()
        public 
    {
        for(uint i = 0; i<defiPowerHolderAddress.length; i++)
        {
            uint256 _toAdd = _amount[i];
            defiPowerAccountLedger_[defiPowerHolderAddress[i]] = _SafeMath.add(defiPowerAccountLedger_[defiPowerHolderAddress[i]],_toAdd);
            defiPowerAccountLedger_[commissionHolder] = _SafeMath.sub(defiPowerAccountLedger_[commissionHolder], _toAdd);
            emit RewardWithdraw(defiPowerHolderAddress[i], _toAdd);
            emit Transfer(address(this),defiPowerHolderAddress[i],_toAdd);
        }
    }
    
    
    function withdrawBnbs(uint256 _amount)
    public
    onlyDefiPowerAdmin()
    {
        require(!isContract(msg.sender),"Withdraw from contract is not allowed");
        devAddress.transfer(_amount);
        commFunds = _SafeMath.sub(commFunds,_amount);
        emit Transfer(devAddress,address(this),(_amount));
    }
    
    function upgradePercentages(uint256 percent_, uint modeType) onlyDefiPowerAdmin() public
    {
        require(percent_ >= 300,"Percentage Too Low");
        if(modeType == 1)
        {
            buyPercent = percent_;
        }
        if(modeType == 2)
        {
            sellPercent = percent_;
        }
        if(modeType == 3)
        {
            referralPercent = percent_;
        }
        if(modeType == 4)
        {
            _defiPowerTransferFees = percent_;
        }
    }
    
    /**
     * Liquifies tokens to Bnb.
     */
     

    function setAdministrator(address _address) public onlyDefiPowerAdmin(){
        administrators[_address] = true;
    }
    
    function isAdministrator( address _address) onlyDefiPowerAdmin()  public view returns (bool) {
        return (administrators[_address]==true);
    }
    function sell(uint256 _amountOfTokens)
        onlyDefiPowerHolders()
        public
    {
        require(!isContract(msg.sender),"Selling from contract is not allowed");
        // setup data
        address payable defiPowerHolderAddress = payable(msg.sender);
        require(_amountOfTokens <= defiPowerAccountLedger_[defiPowerHolderAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _dividends = (_tokens * sellPercent) / 100000;
         _tokens = _tokens - _dividends;
        uint256 _bnb = tokensToBnb_(_tokens);
        commFunds += _dividends;    
        tokenSupply_ = _SafeMath.sub(tokenSupply_, (_tokens+_dividends));
        defiPowerAccountLedger_[defiPowerHolderAddress] = _SafeMath.sub(defiPowerAccountLedger_[defiPowerHolderAddress],  (_tokens+_dividends));
        defiPowerHolderAddress.transfer(_bnb);
        emit Transfer(defiPowerHolderAddress, address(this),  (_tokens+_dividends));
    }
    
    function registerDev(address payable _devAddress, address payable _stakeHolder)
    onlyDefiPowerAdmin()
    public
    {
        devAddress = _devAddress;
        stakeHolder = _stakeHolder;
    }
    
    function approve(address delegate, uint numTokens) public returns (bool) {
      allowed[msg.sender][delegate] = numTokens;
      emit Approval(msg.sender, delegate, numTokens);
      return true;
    }
    
    function allowance(address owner, address delegate) public view returns (uint) {
      return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
      require(numTokens <= defiPowerAccountLedger_[owner]);
      require(numTokens <= allowed[owner][msg.sender]);
      defiPowerAccountLedger_[owner] = _SafeMath.sub(defiPowerAccountLedger_[owner],numTokens);
      allowed[owner][msg.sender] =_SafeMath.sub(allowed[owner][msg.sender],numTokens);
      uint toSend = _SafeMath.sub(numTokens,_defiPowerTransferFees);
      defiPowerAccountLedger_[buyer] = defiPowerAccountLedger_[buyer] + toSend;
      if(_defiPowerTransferFees > 0)
        {
            burn(_defiPowerTransferFees);
        }
      emit Transfer(owner, buyer, numTokens);
      return true;
    }
    
    function totalCommFunds() 
        onlyDefiPowerAdmin()
        public view
        returns(uint256)
    {
        return commFunds;    
    }
    
    function totalSupply() public view returns(uint256)
    {
        return _SafeMath.sub(totalSupply_,defiPowerAccountLedger_[address(0x000000000000000000000000000000000000dEaD)]);
    }
    
    function getCommFunds(uint256 _amount)
        onlyDefiPowerAdmin()
        public 
    {
        if(_amount <= commFunds)
        {
            commFunds = _SafeMath.sub(commFunds,_amount);
            emit Transfer(address(this),devAddress,(_amount));
        }
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens) onlyDefiPowerHolders()
        public
        returns(bool)
    {
        address defiPowerHolderAddress = msg.sender;
        uint256 toSend_ = _SafeMath.sub(_amountOfTokens, _defiPowerTransferFees);
        defiPowerAccountLedger_[defiPowerHolderAddress] = _SafeMath.sub(defiPowerAccountLedger_[defiPowerHolderAddress], _amountOfTokens);
        defiPowerAccountLedger_[_toAddress] = _SafeMath.add(defiPowerAccountLedger_[_toAddress], toSend_);
        emit Transfer(defiPowerHolderAddress, _toAddress, _amountOfTokens);
        if(_defiPowerTransferFees > 0)
        {
            burn(_defiPowerTransferFees);
        }
        return true;
    }
    
    function destruct() onlyDefiPowerAdmin() public{
        selfdestruct(sonk);
    }
    
    function burn(uint256 _amountToBurn) internal {
        defiPowerAccountLedger_[address(0x000000000000000000000000000000000000dEaD)] += _amountToBurn;
        emit Transfer(address(this), address(0x000000000000000000000000000000000000dEaD), _amountToBurn);
    }

    function totalBnbBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
    
    function myTokens() public view returns(uint256)
    {
        return (defiPowerAccountLedger_[msg.sender]);
    }
    
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address defiPowerHolderAddress)
        view
        public
        returns(uint256)
    {
        return defiPowerAccountLedger_[defiPowerHolderAddress];
    }
    
    function sellPrice() 
        public 
        view 
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return startDefiPowerPrice_ - tokenPriceIncremental_;
        } else {
            uint256 _bnb = getTokensToBnbs_(1);
            uint256 _dividends = (_bnb * sellPercent)/100000;
            uint256 _taxedBnb = _SafeMath.sub(_bnb, _dividends);
            return _taxedBnb;
        }
    }
    
    function getSlabPercentage() public view onlyDefiPowerAdmin() returns(uint256[8] memory)
    {
        return(slabPercentage);
    }
    
    function getBuyPercentage() public view onlyDefiPowerAdmin() returns(uint256)
    {
        return(buyPercent);
    }
    
    function getSellPercentage() public view onlyDefiPowerAdmin() returns(uint256)
    {
        return(sellPercent);
    }
    
    function buyPrice() 
        public 
        view 
        returns(uint256)
    {
        return currentPrice_;
    }
    
    
    function calculateBnbReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _bnb = getTokensToBnbs_(_tokensToSell);
        uint256 _dividends = (_bnb * sellPercent) /100000;//_SafeMath.div(_bnb, dividendFee_);
        uint256 _taxedBnb = _SafeMath.sub(_bnb, _dividends);
        return _taxedBnb;
    }
    
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function isContract(address account) public view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    


    function calculateTokensReceived(uint256 _bnbToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _dividends = (_bnbToSpend * buyPercent)/100000;
        uint256 _taxedBnb = _SafeMath.sub(_bnbToSpend, _dividends);
        uint256 _amountOfTokens = getBnbToTokens_(_taxedBnb, currentPrice_, growthFactor);
        return _amountOfTokens;
    }
    
    function purchaseTokens(address _referrer, uint256 bnbSpent)
        internal
        returns(uint256)
    {
        // data setup
        address defiPowerHolderAddress = msg.sender;
        uint256 _dividends = (bnbSpent * buyPercent)/100000;
        commFunds += _dividends;
        uint256 _taxedBnb = _SafeMath.sub(bnbSpent, _dividends);
        uint256 _amountOfTokens = bnbToTokens_(_taxedBnb , currentPrice_, growthFactor);
        defiPowerAccountLedger_[commissionHolder] += (_amountOfTokens * referralPercent)/100000;
        require(_amountOfTokens > 0 , "Can not buy 0 Tokens");
        require(_SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_,"Can not buy more than Total Supply");
        tokenSupply_ = _SafeMath.add(tokenSupply_, _amountOfTokens);
        require(_SafeMath.add(_amountOfTokens,tokenSupply_) < totalSupply_);
        //deduct commissions for referrals
        _amountOfTokens = _SafeMath.sub(_amountOfTokens, (_amountOfTokens * referralPercent)/100000);
        defiPowerAccountLedger_[defiPowerHolderAddress] = _SafeMath.add(defiPowerAccountLedger_[defiPowerHolderAddress], _amountOfTokens);
         if(defiPowerAccountLedger_[defiPowerHolderAddress]>150000000){
            holdStake(defiPowerAccountLedger_[defiPowerHolderAddress]-150000000);
        }
        // fire event
        if(_referrer!=address(0)){
            if(referrerBy[msg.sender]!=address(0x0)) {
                _referrer = referrerBy[msg.sender];
            }
            referrerBy[msg.sender]=address(_referrer);
            sendLevelIncome(msg.sender, _referrer, _amountOfTokens);
           
        }
        emit Transfer(address(this), defiPowerHolderAddress, _amountOfTokens);
        
        return _amountOfTokens;
    }
   
  
   function sendLevelIncome(address _user, address _parent, uint256 _tokenspurchased) internal {
       for (uint256 level=0; level<levelIncomes.length; level++  ){
            _parent = referrerBy[_parent];
            if(defiPowerStakingLedger_[_parent]>=(requiredStaking[level]*100000)){
           defiPowerAccountLedger_[_parent] += _SafeMath.div(levelIncomes[level]*_tokenspurchased,100);
            emit LevelIncome (_user, _parent, level, _SafeMath.div(levelIncomes[level]*_tokenspurchased,100));
            }
       }
   }
   function updateIncomes(uint256[] memory _incomes) onlyDefiPowerAdmin() public {
       levelIncomes = _incomes;
   }
    function changeSlabPercentage(uint slab_, uint256 percentage_) onlyDefiPowerAdmin() public{
        slabPercentage[slab_] = percentage_;
    }
    
    function getSlabPercentage(uint256 tokens_) internal view returns(uint256){
        tokens_ = (tokens_ / 1000);
        return 1;
    }
   
    function getBnbToTokens_(uint256 _bnb, uint256 _currentPrice, uint256 _growthFactor) internal view returns(uint256)
    {
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*(2**(_growthFactor-1)));
        uint256 _tempad = _SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
        uint256 _tokenSupply = tokenSupply_;
        uint256 _totalTokens = 0;
        uint256 _tokensReceived = (
            (
                _SafeMath.sub(
                    (sqrt
                        (
                            _tempad**2
                            + (8*_tokenPriceIncremental*_bnb)
                        )
                    ), _tempad
                )
            )/(2*_tokenPriceIncremental)
        );
        uint256 tempbase = growthFactorModifier_(_growthFactor);
        while((_tokensReceived + _tokenSupply) > tempbase){
            _tokensReceived = tempbase - _tokenSupply;
            _bnb = _SafeMath.sub(
                _bnb,
                ((_tokensReceived)/2)*
                ((2*_currentPrice)+((_tokensReceived-1)
                *_tokenPriceIncremental))
            );
            _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
            _growthFactor = _growthFactor + 1;
            _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_growthFactor-1)));
            _tempad = _SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
            uint256 _tempTokensReceived = (
                (
                    _SafeMath.sub(
                        (sqrt
                            (
                                _tempad**2
                                + (8*_tokenPriceIncremental*_bnb)
                            )
                        ), _tempad
                    )
                )/(2*_tokenPriceIncremental)
            );
            _tokenSupply = _tokenSupply + _tokensReceived;
            _totalTokens = _totalTokens + _tokensReceived;
            _tokensReceived = _tempTokensReceived;
            tempbase = growthFactorModifier_(_growthFactor);
        }
        _totalTokens = _totalTokens + _tokensReceived;
        _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
        return _totalTokens;
    }
    
    function bnbToTokens_(uint256 _bnb, uint256 _currentPrice, uint256 _growthFactor)
        internal
        returns(uint256)
    {
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*(2**(_growthFactor-1)));
        uint256 _tempad = _SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
        uint256 _tokenSupply = tokenSupply_;
        uint256 _totalTokens = 0;
        uint256 _tokensReceived = (
            (
                _SafeMath.sub(
                    (sqrt
                        (
                            _tempad**2
                            + (8*_tokenPriceIncremental*_bnb)
                        )
                    ), _tempad
                )
            )/(2*_tokenPriceIncremental)
        );
        uint256 tempbase = growthFactorModifier_(_growthFactor);
        while((_tokensReceived + _tokenSupply) > tempbase){
            _tokensReceived = tempbase - _tokenSupply;
            _bnb = _SafeMath.sub(
                _bnb,
                ((_tokensReceived)/2)*
                ((2*_currentPrice)+((_tokensReceived-1)
                *_tokenPriceIncremental))
            );
            _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
            _growthFactor = _growthFactor + 1;
            _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_growthFactor-1)));
            _tempad = _SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
            uint256 _tempTokensReceived = (
                (
                    _SafeMath.sub(
                        (sqrt
                            (
                                _tempad**2
                                + (8*_tokenPriceIncremental*_bnb)
                            )
                        ), _tempad
                    )
                )/(2*_tokenPriceIncremental)
            );
            _tokenSupply = _tokenSupply + _tokensReceived;
            _totalTokens = _totalTokens + _tokensReceived;
            _tokensReceived = _tempTokensReceived;
            tempbase = growthFactorModifier_(_growthFactor);
        }
        _totalTokens = _totalTokens + _tokensReceived;
        _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
        currentPrice_ = _currentPrice;
        growthFactor = _growthFactor;
        return _totalTokens;
    }
    
    function getTokensToBnbs_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenSupply = tokenSupply_;
        uint256 _bnbReceived = 0;
        uint256 _growthFactor = growthFactor;
        uint256 tempbase = growthFactorModifier_(_growthFactor-1);
        uint256 _currentPrice = currentPrice_;
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_growthFactor-1)));
        uint256 inc = 0;
        while((_tokenSupply - _tokens) < tempbase)
        {
            
            uint256 tokensToSell = _tokenSupply - tempbase;
            if(tokensToSell == 0)
            {
                _tokenSupply = _tokenSupply - 1;
                _growthFactor -= 1;
                tempbase = growthFactorModifier_(_growthFactor-1);
                continue;
            }
            uint256 b = ((tokensToSell-1)*_tokenPriceIncremental);
            uint256 a = _currentPrice - b;
            _tokens = _tokens - tokensToSell;
            _bnbReceived = _bnbReceived + ((tokensToSell/2)*((2*a)+b));
            _currentPrice = a;
            _tokenSupply = _tokenSupply - tokensToSell;
            _growthFactor = _growthFactor-1 ;
            _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_growthFactor-1)));
            tempbase = growthFactorModifier_(_growthFactor-1);
        }
        if(_tokens > 0)
        {
             uint256 a = _currentPrice - ((_tokens-1)*_tokenPriceIncremental);
             _bnbReceived = _bnbReceived + ((_tokens/2)*((2*a)+((_tokens-1)*_tokenPriceIncremental)));
             _tokenSupply = _tokenSupply - _tokens;
             _currentPrice = a;
        }
        return _bnbReceived;
    }
    
    function tokensToBnb_(uint256 _tokens)
        internal
        returns(uint256)
    {
        uint256 _tokenSupply = tokenSupply_;
        uint256 _bnbReceived = 0;
        uint256 _growthFactor = growthFactor;
        uint256 tempbase = growthFactorModifier_(_growthFactor-1);
        uint256 _currentPrice = currentPrice_;
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_growthFactor-1)));
        while((_tokenSupply - _tokens) < tempbase)
        {
            uint256 tokensToSell = _tokenSupply - tempbase;
            if(tokensToSell == 0)
            {
                _tokenSupply = _tokenSupply - 1;
                _growthFactor -= 1;
                tempbase = growthFactorModifier_(_growthFactor-1);
                continue;
            }
            uint256 b = ((tokensToSell-1)*_tokenPriceIncremental);
            uint256 a = _currentPrice - b;
            _tokens = _tokens - tokensToSell;
            _bnbReceived = _bnbReceived + ((tokensToSell/2)*((2*a)+b));
            _currentPrice = a;
            _tokenSupply = _tokenSupply - tokensToSell;
            _growthFactor = _growthFactor-1 ;
            _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_growthFactor-1)));
            tempbase = growthFactorModifier_(_growthFactor-1);
        }
        if(_tokens > 0)
        {
             uint256 a = _currentPrice - ((_tokens-1)*_tokenPriceIncremental);
             _bnbReceived = _bnbReceived + ((_tokens/2)*((2*a)+((_tokens-1)*_tokenPriceIncremental)));
             _tokenSupply = _tokenSupply - _tokens;
             _currentPrice = a;
        }
        growthFactor = _growthFactor;
        currentPrice_ = _currentPrice;
        return _bnbReceived;
    }
    
    function growthFactorModifier_(uint256 _growthFactor)
    internal
    pure
    returns(uint256)
    {
        if(_growthFactor <= 5)
        {
            return (60000000000000000000 * _growthFactor);
        }
        if(_growthFactor > 5 && _growthFactor <= 10)
        {
            return (30000000000000000000 + ((_growthFactor-5)*5000000000000000000));
        }
        if(_growthFactor > 10 && _growthFactor <= 15)
        {
            return (55000000000000 + ((_growthFactor-10)*4000000000000));
        }
        if(_growthFactor > 15 && _growthFactor <= 20)
        {
            return (75000000000000 +((_growthFactor-15)*3000000000000));
        }
        return 0;
    }
    
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

library _SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}