pragma solidity ^0.4.25;


contract HDX20
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
    
     /// Contract governance.

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

    string public name = "HDX20 token";
    string public symbol = "HDX20";
    uint8 constant public decimals = 18;
    uint256 constant internal magnitude = 1e18;
    uint8 constant internal buyInFee = 3;        
    uint8 constant internal sellOutFee = 3;      
    mapping(address => uint256) private tokenBalanceLedger;
    uint256 private tokenSupply = 0;  
    uint256 private contractValue = 0;
    uint256 private tokenPrice = 0.001 ether;   //starting price
  
  
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

    function buyTokenSub( uint256 _eth , address _customerAddress ) private
    returns(uint256)
    {
        uint256 _nb_token = (_eth.mul( magnitude)) / tokenPrice;
        tokenBalanceLedger[ _customerAddress ] =  tokenBalanceLedger[ _customerAddress ].add( _nb_token);
        tokenSupply = tokenSupply.add(_nb_token);
        emit onBuyEvent( _customerAddress , _nb_token);
        return( _nb_token );
    }
  
    function buyToken(  ) public payable
    returns(uint256)
    {
        uint256 _eth = msg.value;
        address _customerAddress = msg.sender;
        require( _eth>0);
        uint256 _fee = (_eth.mul( buyInFee )) / 100;
        uint256 _nb_token = buyTokenSub( _eth - _fee, _customerAddress);
        //add the value to the contract
        contractValue = contractValue.add( _eth );

        if (tokenSupply>magnitude)
        {
            tokenPrice = (contractValue.mul( magnitude)) / tokenSupply;
        }
        return( _nb_token );
    }
    
   





 function sellToken( uint256 _amount ) public
    onlyTokenHolders
    {
        address _customerAddress = msg.sender;
        uint256 balance = tokenBalanceLedger[ _customerAddress ];
        require( _amount <= balance);
        uint256 _eth = (_amount.mul( tokenPrice )) / magnitude;
        
        uint256 _fee = (_eth.mul( sellOutFee)) / 100;
        tokenSupply = tokenSupply.sub( _amount );

        balance = balance.sub( _amount );
        
        tokenBalanceLedger[ _customerAddress] = balance;

        //calculate what is really leaving the contract, basically _eth - _fee -devfee
        _eth = _eth - _fee; 
  
        contractValue = contractValue.sub( _eth );
        if (tokenSupply>magnitude)
        {
            tokenPrice = (contractValue.mul( magnitude)) / tokenSupply;
        }
         emit onSellEvent( _customerAddress , _amount);
        _customerAddress.transfer( _eth );
        
    }
  
    










function transferSub(address _customerAddress, address _toAddress, uint256 _amountOfTokens)
    private
    returns(bool)
    {
        require( _amountOfTokens <= tokenBalanceLedger[_customerAddress] );
        //actually a transfer of 0 token is valid in ERC20
        if (_amountOfTokens>0)
        {
            {
                //now proceed the transfer
                tokenBalanceLedger[ _customerAddress] = tokenBalanceLedger[ _customerAddress].sub( _amountOfTokens );
                tokenBalanceLedger[ _toAddress] = tokenBalanceLedger[ _toAddress].add( _amountOfTokens );


                if (tokenSupply>magnitude)
                {
                    tokenPrice = (contractValue.mul( magnitude)) / tokenSupply;
                }
            }
        }
        // fire event
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        // ERC20
        return true;
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens)
    public
    returns(bool)
    {
        return( transferSub( msg.sender ,  _toAddress, _amountOfTokens));
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
    
    function totalContractBalance()
        public
        view
        returns(uint)
    {
        return contractValue;
    }
    
  
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply;
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
    
    function sellingPrice( bool includeFees)
        view
        public
        returns(uint256)
    {
        uint256 _fee = 0;
        
        if (includeFees)
        {
            _fee = (tokenPrice.mul( sellOutFee ) ) / 100;
        }
        
        return( tokenPrice - _fee);
        
    }
    
    function buyingPrice( bool includeFees)
        view
        public
        returns(uint256)
    {
        uint256 _fee = 0;
        
        if (includeFees)
        {
            _fee = (tokenPrice.mul( buyInFee ) ) / 100;
        }
        
        return( tokenPrice + _fee );
        
    }
    
    function ethBalanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _price = sellingPrice( true );
        uint256 _balance = tokenBalanceLedger[ _customerAddress];
        uint256 _value = (_balance.mul( _price )) / magnitude;
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
   
   
    function ethBalanceOfNoFee(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _price = sellingPrice( false );
        uint256 _balance = tokenBalanceLedger[ _customerAddress];
        uint256 _value = (_balance.mul( _price )) / magnitude;
        return( _value );
    }
    
  
   
    function myEthBalanceOfNoFee()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return ethBalanceOfNoFee(_customerAddress);
    }    
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