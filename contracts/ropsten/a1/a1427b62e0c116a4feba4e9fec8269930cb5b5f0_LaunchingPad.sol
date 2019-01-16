pragma solidity ^0.4.24;


contract LaunchingPad
{
     
    using SafeMath for uint256;

    /*==============================
    =            EVENTS            =
    ==============================*/
    event OwnershipTransferred(
         address indexed previousOwner,
         address indexed nextOwner
         );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    event onBuyEvent(
        address from,
        uint256 tokens
    );
   
     event onSellEvent(
        address from,
        uint256 tokens
    );


    /*==============================
    =            MODIFIERS         =
    ==============================*/
    modifier onlyOwner
    {
        require (msg.sender == owner);
        _;
    }
        
    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }
    
    address public owner;
    
    constructor () public
    {
        owner = msg.sender;
       
        if ( address(this).balance > 0)
        {
            owner.transfer( address(this).balance );
        }
    }

  
 /*==============================
    =       TOKEN VARIABLES        =
    ==============================*/

    string public name = "SKY Jackpot token";
    string public symbol = "SKY";
    uint8 constant public decimals = 18;
    uint8 constant internal buyInFee = 10;        
    uint8 constant internal sellOutFee = 10; 
    mapping(address => uint256) private tokenBalanceLedger;
    uint256 public tokenSupply = 0;  
    uint256 public coinMC = 0;
    uint256 public tokenPrice = 0.001 ether;
    uint256 public ethJackpot = 0;
   // uint public jpCount = 0;
   // uint jpWin = 3;
    address public leader;
    uint256 public jpTimer;

  
  
    /*================================
    =       PUBLIC FUNCTIONS         =
    ================================*/

    function changeOwner(address _nextOwner) public
    onlyOwner
    {
        require (_nextOwner != owner);
        require(_nextOwner != address(0));
        emit OwnershipTransferred(owner, _nextOwner);
        owner = _nextOwner;
    }

    function changeName(string _name) public
    onlyOwner
    {
        name = _name;
    }

    function changeSymbol(string _symbol) public
    onlyOwner
    {
        symbol = _symbol;
    }


    function()
        payable
        public
    {
        buyToken();
    }
    
  
    function buyToken() public payable
    {
        address _customerAddress = msg.sender;
        uint256 _eth = msg.value;
        require( msg.value > buyingPrice());
        
        if(
        now >= jpTimer
        ){
            //_eth = _eth.add(ethJackpot/2);
            coinMC = coinMC.add(ethJackpot);
            ethJackpot = 0;
            jpTimer = now + 1 days;
            uint256 jpwinnings = buyingPrice().mul(ethJackpot/2);
            tokenBalanceLedger[leader] =  tokenBalanceLedger[leader].add(jpwinnings);
            
        }
        
        uint256 _fee = _eth.mul(buyInFee) / 100;
        uint256 jackpotFee = _fee/2;
        uint256 _tokens = (_eth - _fee) / tokenPrice;
        tokenBalanceLedger[_customerAddress] =  tokenBalanceLedger[_customerAddress].add( _tokens);
        tokenSupply = tokenSupply.add(_tokens);
        emit onBuyEvent(_customerAddress, _tokens);
        ethJackpot = ethJackpot.add(jackpotFee);
        coinMC = address(this).balance.sub(ethJackpot);
        if(tokenSupply > 0){
            tokenPrice = (coinMC / tokenSupply);
            }else{(tokenPrice = coinMC);}
        leader = _customerAddress;
}


  function sellTokens( uint256 _amount ) public
    onlyTokenHolders
    {
        address _customerAddress = msg.sender;
        require( _amount <= tokenBalanceLedger[ _customerAddress]);
        uint256 _eth = (_amount.mul( tokenPrice ));
        uint256 _fee = _eth / sellOutFee;
        tokenSupply = tokenSupply.sub( _amount );
        tokenBalanceLedger[ _customerAddress] = tokenBalanceLedger[ _customerAddress].sub( _amount );
        _eth = _eth - _fee; 
        uint256 jackpotFee = _fee/2;
        ethJackpot = ethJackpot.add(jackpotFee);
        emit onSellEvent( _customerAddress , _amount);
        coinMC = coinMC.sub(_eth + jackpotFee);
        if(tokenSupply > 0){
            tokenPrice = (coinMC / tokenSupply);
            }else{(tokenPrice = coinMC);}
        _customerAddress.transfer( _eth );
    }
    
    function sellAll() public
    onlyTokenHolders
    {sellTokens(tokenBalanceLedger[msg.sender]);}

    function transfer(address _toAddress, uint256 _amountOfTokens)
    public
    returns(bool)
    {
        address _customerAddress = msg.sender;
        require( _amountOfTokens <= tokenBalanceLedger[_customerAddress] );
        if (_amountOfTokens>0)
        {
            {
                tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub( _amountOfTokens );
                tokenBalanceLedger[ _toAddress] = tokenBalanceLedger[ _toAddress].add( _amountOfTokens );
            }
        }
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        return true;
    }

    /*================================
    =  VIEW AND HELPERS FUNCTIONS    =
    ================================*/

    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
 
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
    
   
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger[_customerAddress];
    }
    
    function sellingPrice()
        view
        public
        returns(uint256)
    {
        
        uint256 _fee = (tokenPrice.mul(sellOutFee)/100);
        return ( tokenPrice.sub(_fee)) ;

    }
    
    function buyingPrice()
        view
        public
        returns(uint256)
    {
        uint256  _fee = (tokenPrice.mul( buyInFee ) ) / 100;
        return( tokenPrice + _fee );
    }
    
   /* function ethBalanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _price = sellingPrice( true );
        uint256 _balance = tokenBalanceLedger[ _customerAddress];
        uint256 _value = (_balance.mul( _price ));
        return( _value );
    }
    
  
   
    function myEthBalanceOf()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return ethBalanceOf(_customerAddress);
    }
   
   
    function tradeValue(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _price = sellingPrice( false );
        uint256 _balance = tokenBalanceLedger[ _customerAddress];
        uint256 _value = (_balance.mul( _price ));
        return( _value );
    }
    
  
   
    function myTradeValue()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return tradeValue(_customerAddress);
    }    */
}


library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a);
        return c;
    }
   
}