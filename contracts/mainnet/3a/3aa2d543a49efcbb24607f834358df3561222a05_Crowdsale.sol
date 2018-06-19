pragma solidity ^0.4.20;




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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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




contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}





contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    mapping(address => uint256) balances;
}
contract AthTokenInterface is ERC20{

  function delivery( address _to, uint256 _amount ) public returns( bool );
  function afterIco( uint256 _redemptionPrice ) public  returns( bool );
  function currentBalance() public returns( uint256 );
  
}






contract Crowdsale is Ownable{
    
    using SafeMath for uint256;
    
    bool _initialize = false;
    
    AthTokenInterface token;

    enum CrowdsaleStates { Disabled, Presale, ICO1, ICO2, ICO3, ICO4, Finished }
    
    uint256 public presale                  = 750000  ether;
    uint256 public bounty                   = 500000  ether;
    uint256 public constant price           = 0.00024 ether;
    uint256 public constant threshold       = 50000 ether;
    uint256 public constant min             = price * 500;
    uint256 public constant hardcap         = 1000 ether; 
    uint256 public          totalEth        = 0;
    
    uint256 public constant affiliatThreshold1 = 1 * min;
    uint256 public constant affiliatThreshold2 = 10 * min;
    uint256 public constant affiliatThreshold3 = 50 * min;
    uint256 public constant affiliatThreshold4 = 100 * min;
    
    uint256 public icoTimeStart          = 0;
    uint256 public ICO1Period            = 1 days;
    uint256 public ICO2Period            = 7 days + ICO1Period;
    uint256 public ICO3Period            = 10 days + ICO2Period;
    uint256 public ICO4Period            = 12 days + ICO3Period;
    
    
    address[] owners;
    
    
    CrowdsaleStates public CrowdsaleState = CrowdsaleStates.Disabled;
    
    modifier icoActive {
        require( 
               getCrowdsaleState() == CrowdsaleStates.Presale 
            || getCrowdsaleState() == CrowdsaleStates.ICO1 
            || getCrowdsaleState() == CrowdsaleStates.ICO2 
            || getCrowdsaleState() == CrowdsaleStates.ICO3
            || getCrowdsaleState() == CrowdsaleStates.ICO4
            );
        _;
    }
    
    modifier Finished {
        require( getCrowdsaleState() == CrowdsaleStates.Finished );
        _;
    }
    modifier notFinished {
        require( getCrowdsaleState() != CrowdsaleStates.Finished );
        _;
    }
    
    modifier Initialized {
        require( _initialize );
        _;
    }
    
    
    
    event NewInvestor( address );
    event NewReferrer( address );
    event Referral( address, address, uint256, uint256 );
    event Bounty( address, uint256 );
    event Swap( address, address, uint256 );
    event NewSwapToken( address );
    event Delivery( address, uint256 );
    
    
    
    mapping( address => uint256 ) investorsTotalBalances;
    mapping( address => uint256 ) investorsStock;
    mapping( address => bool ) investorsCheck;
    address[] public investors;
    
    
    
    mapping( address => bool ) referrers;
    address[] public referrersList;
    
    
    
    
    
    function initialize( address _a, address[] _owners ) public onlyOwner returns( bool )
    {
        require( _a != address(0) && _owners.length == 2 && _owners[0] != address(0) && _owners[1] != address(0) && !_initialize );
        
        
        token = AthTokenInterface( _a );
        owners = _owners;
        _initialize = true;
    }

    
    function getOwners(uint8 _i) public constant returns( address )
    {
        return owners[_i];
    }
    
   
    
    function referrersCount() public constant returns( uint256 )
    {
        return referrersList.length;
    }
    
    
    
    function regReferrer( address _a ) public onlyOwner Initialized returns( bool )
    {
        if( referrers[_a] != true ) {
            
            referrers[_a] = true;
            referrersList.push( _a );
            
            NewReferrer( _a );
            
        }
    }
    function regReferrers( address[] _a ) public onlyOwner Initialized returns( bool )
    {
        for( uint256 i = 0; i <= _a.length - 1; i++ ){
            
            if( referrers[_a[i]] != true ) {
            
                referrers[_a[i]] = true;
                referrersList.push( _a[i] );
                
                NewReferrer( _a[i] );
                
            }
        }
    }
    
    
    
    function referralBonusCalculate( uint256 _amount, uint256 _amountTokens ) public pure returns( uint256 )
    {
        uint256 amount = 0;
        
        if( _amount < affiliatThreshold2  )  amount =  _amountTokens.mul( 7 ).div( 100 );
        if( _amount < affiliatThreshold3  )  amount =  _amountTokens.mul( 10 ).div( 100 );
        if( _amount < affiliatThreshold4  )  amount =  _amountTokens.mul( 15 ).div( 100 );
        if( _amount >= affiliatThreshold4  ) amount =  _amountTokens.mul( 20 ).div( 100 );
        
        return amount;
    }
    
    function referrerBonusCalculate( uint256 _amount ) public pure returns( uint256 )
    {
        uint256 amount = 0;
        
        if( _amount < affiliatThreshold2  )  amount =  _amount.mul( 3 ).div( 100 );
        if( _amount < affiliatThreshold3  )  amount =  _amount.mul( 7 ).div( 100 );
        if( _amount < affiliatThreshold4  )  amount =  _amount.mul( 10 ).div( 100 );
        if( _amount >= affiliatThreshold4  ) amount =  _amount.mul( 15 ).div( 100 );
        
        return amount;
    }
    
    
    function redemptionPriceCalculate( uint256 _ath ) public pure returns( uint256 )
    {
        if( _ath >= 3333333 ether ) return price.mul( 150 ).div( 100 );
        if( _ath >= 2917777 ether ) return price.mul( 145 ).div( 100 );
        if( _ath >= 2500000 ether ) return price.mul( 140 ).div( 100 );
        if( _ath >= 2083333 ether ) return price.mul( 135 ).div( 100 );
        if( _ath >= 1700000 ether ) return price.mul( 130 ).div( 100 );
        if( _ath >= 1250000 ether ) return price.mul( 125 ).div( 100 );  
        
        return price;
    }
    
   
    function() public payable
    {
        buy( address(0) );
    }
    

    
    function buy( address _referrer ) public payable icoActive Initialized
    {
        
        
        
      require( msg.value >= min );
      

      uint256 _amount = crowdsaleBonus( msg.value.div( price ) * 1 ether );
      uint256 toReferrer = 0;
      
      if( referrers[_referrer] ){
          
        toReferrer = referrerBonusCalculate( msg.value );
        _referrer.transfer( toReferrer );
        _amount = _amount.add( referralBonusCalculate( msg.value, _amount ) );
        
        Referral( _referrer, msg.sender, msg.value, _amount );
        
      }
      
      
      
       
       
      token.delivery( msg.sender, _amount );
      totalEth = totalEth.add( msg.value );
      
      Delivery( msg.sender, _amount );
      
       
        
      if( getCrowdsaleState() == CrowdsaleStates.Presale ) {
          
          presale = presale.sub( _amount );
          
          for( uint256 i = 0; i <= owners.length - 1; i++ ){
              
            owners[i].transfer( ( msg.value.sub( toReferrer ) ).div( owners.length ) );
            
          }
      
      }
      
      
      investorsTotalBalances[msg.sender]  = investorsTotalBalances[msg.sender].add( _amount );
       
      if( investorsTotalBalances[msg.sender] >= threshold && investorsCheck[msg.sender] == false ){
          investors.push( msg.sender );
          investorsCheck[msg.sender] = true;
          
          NewInvestor( msg.sender );
      }
       
       
      
       
    }
    

    

    
    function getCrowdsaleState() public constant returns( CrowdsaleStates )
    {
        if( CrowdsaleState == CrowdsaleStates.Disabled ) return CrowdsaleStates.Disabled;
        if( CrowdsaleState == CrowdsaleStates.Finished ) return CrowdsaleStates.Finished;
        
        if( CrowdsaleState == CrowdsaleStates.Presale ){
            if( presale > 0 ) 
                return CrowdsaleStates.Presale;
            else
                return CrowdsaleStates.Disabled;
        }
        
        if( CrowdsaleState == CrowdsaleStates.ICO1 ){
            
            if( token.currentBalance() <= 0 || totalEth >= hardcap ) return CrowdsaleStates.Finished; 
            
            if( now.sub( icoTimeStart ) <= ICO1Period)  return CrowdsaleStates.ICO1;
            if( now.sub( icoTimeStart ) <= ICO2Period ) return CrowdsaleStates.ICO2;
            if( now.sub( icoTimeStart ) <= ICO3Period ) return CrowdsaleStates.ICO3;
            if( now.sub( icoTimeStart ) <= ICO4Period ) return CrowdsaleStates.ICO4;
            if( now.sub( icoTimeStart ) >  ICO4Period ) return CrowdsaleStates.Finished;
            
        }
    }
    
    
    
    function crowdsaleBonus( uint256 _amount ) internal constant  returns ( uint256 )
    {
        uint256 bonus = 0;
        
        if( getCrowdsaleState() == CrowdsaleStates.Presale ){
            bonus = _amount.mul( 50 ).div( 100 );
        }
        
        if( getCrowdsaleState() == CrowdsaleStates.ICO1 ){
            bonus = _amount.mul( 35 ).div( 100 );
        }
        if( getCrowdsaleState() == CrowdsaleStates.ICO2 ){
            bonus = _amount.mul( 25 ).div( 100 );
        }
        if( getCrowdsaleState() == CrowdsaleStates.ICO3 ){
            bonus = _amount.mul( 15 ).div( 100 );
        }
        
        return _amount.add( bonus );
        
    }
    
    
    function startPresale() public onlyOwner notFinished Initialized returns ( bool )
    {
        CrowdsaleState = CrowdsaleStates.Presale;
        return true;
    }
    
    function startIco() public onlyOwner notFinished Initialized returns ( bool )
    {
        CrowdsaleState = CrowdsaleStates.ICO1;
        icoTimeStart = now;
        return true;
    }
    
    
    function completeIcoPart1() public onlyOwner Finished Initialized returns( bool )
    {
        //stop ico
        CrowdsaleState = CrowdsaleStates.Finished;
        
        uint256 sales = token.totalSupply() - token.currentBalance();
        
        
        uint256 i;
        
        //burn
        if( totalEth >= hardcap ) {
            
            for( i = 0; i <= owners.length - 1; i++ ){
                token.delivery( owners[i], bounty.div( owners.length ) );
            }
            
        } else {
            
            uint256 tmp = sales.mul( 20 ).div( 100 ).add( bounty );
            for( i = 0; i <= owners.length - 1; i++ ){
                token.delivery( owners[i], tmp.div( owners.length ) );
            }  
            
        }
        
        uint b = address(this).balance;
         for( i = 0; i <= owners.length - 1; i++ ){
            owners[i].transfer(  b.div( owners.length ) );
        }
        
        token.afterIco(  redemptionPriceCalculate( sales )  );
    }
    
    function completeIcoPart2() public onlyOwner Finished Initialized returns( bool )
    {
        uint256 sum = 0;
        uint256 i = 0;
        for( i = 0; i <= investors.length - 1; i++ ) {
            sum = sum.add( investorsTotalBalances[ investors[i] ] );
        }
        for( i = 0; i <= investors.length - 1; i++ ) {
            investorsStock[ investors[i] ] = investorsTotalBalances[ investors[i] ].mul( 100 ).div( sum );
        }
    }
    
    
    function investorsCount() public constant returns( uint256 )
    {
        return investors.length ;
    }
    
    function investorsAddress( uint256 _i ) public constant returns( address )
    {
        return investors[_i] ;
    }
    
    function investorsInfo( address _a ) public constant returns( uint256, uint256 )
    {
        return ( investorsTotalBalances[_a], investorsStock[_a] );
    }
    
    function investorsStockInfo( address _a)  public constant returns(uint256)
    {
        return  investorsStock[_a];
    }
    
    

    
    function bountyTransfer( address _to, uint256 amount) public onlyOwner Initialized returns( bool )
    {
        
        
        require( bounty >= amount && token.currentBalance() >= amount );
        
        
        token.delivery( _to, amount );
        bounty = bounty.sub( amount );
        
        Delivery( _to, amount );
        Bounty( _to, amount );
        
    }
    
    
    
    
    bool public swapActivity = true;
    address[] tokenList;
    mapping( address => uint256 ) tokenRateAth;
    mapping( address => uint256 ) tokenRateToken;
    mapping( address => uint256 ) tokenLimit;
    mapping( address => uint256 ) tokenMinAmount;
    mapping( address => bool ) tokenActivity;
    mapping( address => bool ) tokenFirst;
    mapping ( address => uint256 ) tokenSwapped;
    
    
    function swapActivityHandler() public onlyOwner
    {
        swapActivity = !swapActivity;
    }
    
    
    function setSwapToken( address _a, uint256 _rateAth, uint256 _rateToken, uint256 _limit, uint256 _minAmount,  bool _activity ) public onlyOwner returns( bool )
    {
       if( tokenFirst[_a] == false ) {
           tokenFirst[_a] = true;
           
           NewSwapToken( _a );
       }
       
       tokenRateAth[_a]     = _rateAth;
       tokenRateToken[_a]   = _rateToken;
       tokenLimit[_a]       = _limit;
       tokenMinAmount[_a]   = _minAmount;
       tokenActivity[_a]    = _activity;
    }
    

    function swapTokenInfo( address _a) public constant returns( uint256, uint256, uint256, uint256,  bool )
    {
        return ( tokenRateAth[_a], tokenRateToken[_a], tokenLimit[_a], tokenMinAmount[_a], tokenActivity[_a] );
    }
    
    function swap( address _a, uint256 _amount ) public returns( bool )
    {
        require( swapActivity && tokenActivity[_a] && ( _amount >= tokenMinAmount[_a] ) );
        
        uint256 ath = tokenRateAth[_a].mul( _amount ).div( tokenRateToken[_a] );
        tokenSwapped[_a] = tokenSwapped[_a].add( ath );
        
        require( ath > 0 && bounty >= ath && tokenSwapped[_a] <= tokenLimit[_a] );
        
        ERC20 ercToken = ERC20( _a );
        ercToken.transferFrom( msg.sender, address(this), _amount );
        
        for( uint256 i = 0; i <= owners.length - 1; i++ )
          ercToken.transfer( owners[i], _amount.div( owners.length ) );
          
        token.delivery( msg.sender, ath );
        bounty = bounty.sub( ath );
        
        Delivery( msg.sender, ath );
        Swap( msg.sender, _a, ath );
        
    }
    
}