pragma solidity ^0.4.24;


contract LaunchingPad
{
     
    using SafeMath for uint256;


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

     event onJackpotwon(
        address winner,
        uint256 tokens
    );
    
    
    
    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }


    string public name = "SKY token";
    string public symbol = "SKY";
    uint256 constant public decimals = 18;
    uint256 constant internal buyInFee = 10;        
    uint256 constant internal sellOutFee = 10; 
    mapping(address => uint256) private tokenBalanceLedger;
    uint256 public tokenSupply = 0;  
    uint256 public coinMC = 0;
    uint256 public tokenPrice = 0.001 ether;
    uint256 public ethJackpot = 0;
    address public leader;
    uint256 public jpTimer = now + 1 weeks;


    function()
        public
        payable
    {
        buy();
    }
    
  
    function buy() public payable
    {
        address _customerAddress = msg.sender;
        uint256 _eth = msg.value;
        require( msg.value >= buyingPrice());
        
        if(now>=jpTimer){
            uint256 jpwinnings = ((ethJackpot/2)/buyingPrice());
            ethJackpot = 0;
            tokenBalanceLedger[leader] = tokenBalanceLedger[leader].add(jpwinnings);    

        }
        
        uint256 _tokens = _eth/buyingPrice();
        uint256 _fee = _tokens.mul(buyingPrice().sub(tokenPrice));
        uint256 _jackpotFee = _fee/2;        

        tokenBalanceLedger[_customerAddress] =  tokenBalanceLedger[_customerAddress].add( _tokens);
        tokenSupply = tokenSupply.add(_tokens);
        emit onBuyEvent(_customerAddress, _tokens);
        ethJackpot = ethJackpot.add(_jackpotFee);
        coinMC = address(this).balance.sub(ethJackpot);
        if(tokenSupply > 0){
            tokenPrice = (coinMC / tokenSupply);
            }else{(tokenPrice = buyingPrice().add(coinMC));}
        jpTimer = now + 1 days;
        leader = _customerAddress;
}


  function sell( uint256 _amount ) public
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
            }else{(tokenPrice = buyingPrice().add(coinMC));}
        _customerAddress.transfer( _eth );
    }
    
    function sellAll() public
    onlyTokenHolders
    {sell(tokenBalanceLedger[msg.sender]);}

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
    
}


library SafeMath {
    

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

    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a);
        return a - b;
    }

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