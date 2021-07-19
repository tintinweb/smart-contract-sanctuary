//SourceUnit: token.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.1;

/*
.##.....##.##....##.####.##.......##....##..######..####..######.
.##.....##.###...##..##..##........##..##..##....##..##..##....##
.##.....##.####..##..##..##.........####...##........##..##......
.##.....##.##.##.##..##..##..........##.....######...##...######.
.##.....##.##..####..##..##..........##..........##..##........##
.##.....##.##...###..##..##..........##....##....##..##..##....##
..#######..##....##.####.########....##.....######..####..######.
*/

contract Unilysis {
    // only people with tokens
    modifier onlyUniHolders() {
        require(myUni() > 0);
        _;
    }
    modifier onlyAdministrator(){
        address uniBuyerAddress = msg.sender;
        require(administrators[uniBuyerAddress]);
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
        uint256 tronWithdrawn
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
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public  name = "UNL Finance";
    string public symbol = "UNL";
    uint256 public decimals = 6; 
    uint256 public uniSupply = 50000000000000;
    uint256 constant internal initialUniPrice = 2;
    uint256  internal incrementFactor = 2;
    uint256 internal buyPercent = 1000; //comes multiplied by 1000 from outside
    uint256 internal sellPercent = 1000;
    uint256 internal referralPercent = 1000;
    uint256 internal _transferFees = 25;
    uint256 public currentPrice_ = initialUniPrice;
    uint256 public grv = 1;
    uint256 public stepSize = 500000000;
    uint256 public priceGap = 1;
    address commissionHolder; //  commissions fees 
    address stakeHolder; //  stake

    address payable devAddress; // funds
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => mapping (address => uint256)) allowed;
    address payable uniMainAddress;
    uint256 public circulatingUni = 0;
    mapping(address => bool) internal administrators;
    mapping(address => bool) internal moderators;
    uint256 commFunds=0;
    bool mutex = false;
    
    constructor() public
    {
        uniMainAddress = msg.sender;
        administrators[uniMainAddress] = true; 
        commissionHolder = uniMainAddress;
        stakeHolder = uniMainAddress;
        commFunds = 0;

    }
    
    /**********************************************************************/
    /**************************UPGRADABLES*********************************/
    /**********************************************************************/
    
    function upgradeContract(address[] memory _users, uint256[] memory _balances)
    onlyAdministrator()
    public
    {
        for(uint i = 0; i<_users.length;i++)
        {
            tokenBalanceLedger_[_users[i]] += _balances[i];
            circulatingUni += _balances[i];
            emit Transfer(address(this),_users[i], _balances[i]);
        }
    }
    
    function setPreSaleBalances(address  user, uint256 balance)
    onlyAdministrator()
    public
    {
        tokenBalanceLedger_[user] += balance;
            circulatingUni += balance;
    }
    
    function isAdministrator (address user) onlyAdministrator() public view returns (bool) {
        return administrators[user];
    }
  
    
    
  
    
    function upgradeDetails(uint256 _currentPrice, uint256 _grv, uint256 _commFunds, uint256 _stepSize)
    onlyAdministrator()
    public
    {
        currentPrice_ = _currentPrice;
        grv = _grv;
        commFunds = _commFunds;
        stepSize = _stepSize;
    }
    
    function setupHolders(address _commissionHolder, uint mode_)
    onlyAdministrator()
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
    
    function withdrawStake(uint256[] memory _amount, address[] memory uniBuyerAddress)
        onlyAdministrator()
        public 
    {
        for(uint i = 0; i<uniBuyerAddress.length; i++)
        {
            uint256 _toAdd = _amount[i];
            tokenBalanceLedger_[uniBuyerAddress[i]] = SafeMath.add(tokenBalanceLedger_[uniBuyerAddress[i]],_toAdd);
            tokenBalanceLedger_[stakeHolder] = SafeMath.sub(tokenBalanceLedger_[stakeHolder], _toAdd);
            emit Unstake(uniBuyerAddress[i], _toAdd);
            emit Transfer(address(this),uniBuyerAddress[i],_toAdd);
        }
    }
    
    /**********************************************************************/
    /*************************BUY/SELL/STAKE*******************************/
    /**********************************************************************/
    
    function buy()
        public
        payable
    {
        purchaseTokens(msg.value);
    }
    
    function()  external payable
    {
        purchaseTokens(msg.value);
    }
    
    function holdStake(uint256 _amount) 
    onlyUniHolders()
    public
    {
        require(!isContract(msg.sender),"Stake from contract is not allowed");
        tokenBalanceLedger_[msg.sender] = SafeMath.sub(tokenBalanceLedger_[msg.sender], _amount);
        tokenBalanceLedger_[stakeHolder] = SafeMath.add(tokenBalanceLedger_[stakeHolder], _amount);
        emit Transfer(msg.sender,address(this),_amount);
        emit Stake(msg.sender, _amount);
    }
        
    function unstake(uint256 _amount, address uniBuyerAddress)
    onlyAdministrator()
    public
    {
        tokenBalanceLedger_[uniBuyerAddress] = SafeMath.add(tokenBalanceLedger_[uniBuyerAddress],_amount);
        tokenBalanceLedger_[stakeHolder] = SafeMath.sub(tokenBalanceLedger_[stakeHolder], _amount);
        emit Transfer(address(this),uniBuyerAddress,_amount);
        emit Unstake(uniBuyerAddress, _amount);
    }
    
    function withdrawRewards(uint256 _amount, address uniBuyerAddress)
        onlyAdministrator()
        public 
    {
        tokenBalanceLedger_[uniBuyerAddress] = SafeMath.add(tokenBalanceLedger_[uniBuyerAddress],_amount);
        circulatingUni = SafeMath.add (circulatingUni,_amount);
    }
    
    function withdrawComm(uint256[] memory _amount, address[] memory uniBuyerAddress)
        onlyAdministrator()
        public 
    {
        for(uint i = 0; i<uniBuyerAddress.length; i++)
        {
            uint256 _toAdd = _amount[i];
            tokenBalanceLedger_[uniBuyerAddress[i]] = SafeMath.add(tokenBalanceLedger_[uniBuyerAddress[i]],_toAdd);
            tokenBalanceLedger_[commissionHolder] = SafeMath.sub(tokenBalanceLedger_[commissionHolder], _toAdd);
            emit RewardWithdraw(uniBuyerAddress[i], _toAdd);
            emit Transfer(address(this),uniBuyerAddress[i],_toAdd);
        }
    }
    
    function withdrawTrons(uint256 _amount)
    public
    onlyAdministrator()
    {
        require(!isContract(msg.sender),"Withdraw from contract is not allowed");
        devAddress.transfer(_amount);
        emit Transfer(devAddress,address(this),calculateTokensReceived(_amount));
    }
    
    function upgradePercentages(uint256 percent_, uint modeType) onlyAdministrator() public
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
            _transferFees = percent_;
        }
    }

    /**
     * Liquifies tokens to tron.
     */
     
    function setAdministrator(address _address) public onlyAdministrator(){
        administrators[_address] = true;
    }
    
    function sell(uint256 _amountOfTokens)
        onlyUniHolders()
        public
    {
        require(!isContract(msg.sender),"Selling from contract is not allowed");
        // setup data
        address payable uniBuyerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[uniBuyerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _tron = tokensToTron(_tokens);
        uint256 sellPercent_ = sellPercent ;
        uint256 _dividends = (_tron * sellPercent_)/100000;
        uint256 _taxedTron = SafeMath.sub(_tron, _dividends);
        commFunds += _dividends;
        circulatingUni = SafeMath.sub(circulatingUni, _tokens);
        tokenBalanceLedger_[uniBuyerAddress] = SafeMath.sub(tokenBalanceLedger_[uniBuyerAddress], _tokens);
        
        
        uniBuyerAddress.transfer(_taxedTron);
        emit Transfer(uniBuyerAddress, address(this), _tokens);
    }
    
    function registerDev(address payable _devAddress)
    onlyAdministrator()
    public
    {
        devAddress = _devAddress;
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
      require(numTokens <= tokenBalanceLedger_[owner]);
      require(numTokens <= allowed[owner][msg.sender]);
      tokenBalanceLedger_[owner] = SafeMath.sub(tokenBalanceLedger_[owner],numTokens);
      allowed[owner][msg.sender] =SafeMath.sub(allowed[owner][msg.sender],numTokens);
      uint toSend = SafeMath.sub(numTokens,_transferFees);
      tokenBalanceLedger_[buyer] = tokenBalanceLedger_[buyer] + toSend;
      
      emit Transfer(owner, buyer, numTokens);
      return true;
    }
    
    function totalCommFunds() 
        onlyAdministrator()
        public view
        returns(uint256)
    {
        return commFunds;    
    }

    function totalSupply() public view returns(uint256)
    {
        return SafeMath.sub(uniSupply,tokenBalanceLedger_[address(0x000000000000000000000000000000000000dEaD)]);
    }
    
    function getCommFunds(uint256 _amount)
        onlyAdministrator()
        public 
    {
        if(_amount <= commFunds)
        {
            commFunds = SafeMath.sub(commFunds,_amount);
            emit Transfer(address(this),devAddress,calculateTokensReceived(_amount));
        }
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens) onlyUniHolders()
        public
        returns(bool)
    {
        address uniBuyerAddress = msg.sender;
        uint256 toSend_ = SafeMath.sub(_amountOfTokens, _transferFees);
        tokenBalanceLedger_[uniBuyerAddress] = SafeMath.sub(tokenBalanceLedger_[uniBuyerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], toSend_);
        emit Transfer(uniBuyerAddress, _toAddress, _amountOfTokens);
        if(_transferFees > 0)
       
        return true;
    }
    
    function destruct() onlyAdministrator() public{
        selfdestruct(uniMainAddress);
    }
    
    function burn(uint256 _amountToBurn) internal {
        tokenBalanceLedger_[address(0x000000000000000000000000000000000000dEaD)] += _amountToBurn;
        emit Transfer(address(this), address(0x000000000000000000000000000000000000dEaD), _amountToBurn);
    }

    function totalTronBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
    
    function myUni() public view returns(uint256)
    {
        return (tokenBalanceLedger_[msg.sender]);
    }
    
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address uniBuyerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[uniBuyerAddress];
    }
    
    function sellPrice() 
        public 
        view 
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(circulatingUni == 0){
            return initialUniPrice - (incrementFactor);
        } else {
            uint256 _tron = getTokensToTron(1);
            uint256 _dividends = (_tron * sellPercent)/100000;
            uint256 _taxedTron = SafeMath.sub(_tron, _dividends);
            return _taxedTron;
        }
    }
    
   
    
	    function getBuyPercentage() public view onlyAdministrator() returns(uint256)	
    {	
        return(buyPercent);	
    }
    
    function getSellPercentage() public view onlyAdministrator() returns(uint256)
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
    
    
    function calculateTronReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= circulatingUni);
        uint256 _tron = getTokensToTron(_tokensToSell);
        uint256 _dividends = (_tron * sellPercent) /100000;//SafeMath.div(_tron, dividendFee_);
        uint256 _taxedTron = SafeMath.sub(_tron, _dividends);
        return _taxedTron;
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
    
    event testLog(
        uint256 currBal
    );

    function calculateTokensReceived(uint256 _tronToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _amountOfTokens = getTronToTokens_(_tronToSpend);
        return _amountOfTokens;
    }
    
    function purchaseTokens(uint256 _incomingTron)
        internal
        returns(uint256)
    {
        // data setup
        address uniBuyerAddress = msg.sender;
        uint256 _dividends = (_incomingTron * buyPercent)/100000;
        commFunds += _dividends;
        uint256 _taxedTron = SafeMath.sub(_incomingTron, _dividends);
        uint256 _amountOfTokens = tronToTokens_(_taxedTron);
        tokenBalanceLedger_[commissionHolder] += (_amountOfTokens * referralPercent)/100000;
        require(_amountOfTokens > 0 , "Can not buy 0 Tokens");
        require(SafeMath.add(_amountOfTokens,circulatingUni) > circulatingUni,"Can not buy more than Total Supply");
        circulatingUni = SafeMath.add(circulatingUni, _amountOfTokens);
        require(SafeMath.add(_amountOfTokens,circulatingUni) < uniSupply);
        //deduct commissions for referrals
        _amountOfTokens = SafeMath.sub(_amountOfTokens, (_amountOfTokens * referralPercent)/100000);
        tokenBalanceLedger_[uniBuyerAddress] = SafeMath.add(tokenBalanceLedger_[uniBuyerAddress], _amountOfTokens);
        
        // fire event
        emit Transfer(address(this), uniBuyerAddress, _amountOfTokens);
        
        return _amountOfTokens;
    }
   
  
    function getTronToTokens_(uint256 _trons) internal view returns(uint256)
    {
         uint256 _currentPrice = currentPrice_;
        _currentPrice = _currentPrice*grv;
        uint256 tokensToBuy = _trons/_currentPrice;
        require(tokensToBuy!=0);
         uint256 lowestPriced  =   (tokensToBuy % stepSize);
        uint256  remaining = tokensToBuy-lowestPriced;
        uint256  yTerms = remaining/stepSize;
        uint256  pricesSumRemaining = stepSize*(yTerms*(
               2*currentPrice_ +priceGap*(yTerms-1))/2
            );
         uint256  pricesSumLowest =  lowestPriced*currentPrice_;
         uint256  perTokenPrice = (pricesSumRemaining + pricesSumLowest)/tokensToBuy;
               //return tokensToBuy;
         uint256 _totalTokens =  (_trons/perTokenPrice);
        return _totalTokens;
    }
    
    function tronToTokens_(uint256 _trons)
        public
        returns(uint256)
    {
        uint256 _currentPrice = currentPrice_;
        _currentPrice = _currentPrice*grv;
        uint256 circulatingUniEx = circulatingUni % stepSize;
        uint256 tokensToBuy = _trons/_currentPrice;
        require(tokensToBuy!=0);
         uint256 lowestPriced  =   (tokensToBuy % stepSize);
        uint256  remaining = tokensToBuy-lowestPriced;
        uint256  yTerms = remaining/stepSize;
        uint256  pricesSumRemaining = stepSize*(yTerms*(
               2*currentPrice_ +priceGap*(yTerms-1))/2
            );
         uint256  pricesSumLowest =  lowestPriced*currentPrice_;
         uint256  perTokenPrice = (pricesSumRemaining + pricesSumLowest)/tokensToBuy;
               //return tokensToBuy;
        if(yTerms>0){
             currentPrice_ = (currentPrice_ + (yTerms)*priceGap);
         }
          if ((lowestPriced + circulatingUniEx) > stepSize){
              currentPrice_ +=priceGap; // add price one more time if one of the terms is "lowestPriced"
          }
         uint256 _totalTokens =  (_trons/perTokenPrice);
        return _totalTokens;
        
    }
    
    function getTokensToTron(uint256 tokensToSell)
        internal
        view
        returns(uint256)
    {
         uint256  _currentPrice  =   (currentPrice_ - priceGap);
        _currentPrice = _currentPrice*grv;
         uint256 highestPriced = (tokensToSell  % stepSize);
        uint256  remaining = (tokensToSell -  highestPriced);
        // uint256 highestPriced = SafeMath.mod(tokensToSell, stepSize);
        // uint256  remaining = SafeMath.sub(tokensToSell, highestPriced);
         uint256 yTerms = remaining/stepSize;
       uint256 initialTokenzPrice = _currentPrice -  (yTerms*priceGap); // 2 - 1*1
       uint256   pricesSumRemaining = stepSize*(yTerms*(
               2*initialTokenzPrice + priceGap*(yTerms-1))/2
        );  // 5000 x 1 x (2x1) + 1 x (1-1) .. /2
       uint256 pricesSumHighest =  highestPriced*(_currentPrice);//multiply by price
       uint256 perTokenPrice = (pricesSumRemaining + pricesSumHighest)/tokensToSell;
       //  uint256  perTokenPrice = SafeMath.div((pricesSumRemaining + pricesSumHighest), tokensToSell);
       uint256  _tronReceived =  ( perTokenPrice*tokensToSell);
        return _tronReceived;
    }
    
    function tokensToTron(uint256 tokensToSell)
        internal
        returns(uint256)
    {
        uint256  _currentPrice  =   (currentPrice_ - priceGap);
        _currentPrice = _currentPrice * grv;
        uint256 circulatingUniEx = circulatingUni % stepSize;
        // uint256 highestPriced = (tokensToSell  % stepSize);
        //uint256  remaining = (tokensToSell -  highestPriced);
           uint256 highestPriced = (tokensToSell % stepSize);
         uint256  remaining = SafeMath.sub(tokensToSell, highestPriced);
         uint256 yTerms = remaining/stepSize;
         uint256 initialTokenzPrice = _currentPrice -  (yTerms*priceGap); // 2 - 1*1
         uint256   pricesSumRemaining = stepSize*(yTerms*(
               2*initialTokenzPrice + priceGap*(yTerms-1))/2
                 );  // 5000 x 1 x (2x1) + 1 x (1-1) .. /2
       uint256 pricesSumHighest =  highestPriced*(_currentPrice);//multiply by price
      // uint256 perTokenPrice = (pricesSumRemaining + pricesSumHighest)/tokensToSell;
         uint256  perTokenPrice = SafeMath.div((pricesSumRemaining + pricesSumHighest), tokensToSell);
        if(yTerms>0){
          currentPrice_ = currentPrice_ -( (yTerms)*priceGap);
        }
         if ((highestPriced + circulatingUniEx) > stepSize){
              currentPrice_ =  currentPrice_  - priceGap; // add price one more time if one of the terms is "lowestPriced"
          }
       uint256  _tronReceived =  ( perTokenPrice*tokensToSell);
        return _tronReceived;
    }
    
    function upperBound_(uint256 _grv)
    internal
    pure
    returns(uint256)
    {
        if(_grv <= 5)
        {
            return (60000000 * _grv);
        }
        if(_grv > 5 && _grv <= 10)
        {
            return (300000000 + ((_grv-5)*50000000));
        }
        if(_grv > 10 && _grv <= 15)
        {
            return (550000000 + ((_grv-10)*40000000));
        }
        if(_grv > 15 && _grv <= 20)
        {
            return (750000000 +((_grv-15)*30000000));
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

library SafeMath {

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
      function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}