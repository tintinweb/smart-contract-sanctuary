pragma solidity ^0.4.25;


contract LaunchingPad
{
     
    using SafeMath for uint256;

    event onTransfer(
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
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public divs;
    uint256 public totalSupply = 0;  
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
            balanceOf[leader] = balanceOf[leader].add(jpwinnings);    
        }
        uint256 _tokens = _eth/buyingPrice();
        uint256 splitFee = (_tokens.mul(buyingPrice().sub(tokenPrice))/2);
        balanceOf[_customerAddress] =  balanceOf[_customerAddress].add( _tokens);
        totalSupply = totalSupply.add(_tokens);
        emit onBuyEvent(_customerAddress, _tokens);
        ethJackpot = ethJackpot.add(splitFee);
        coinMC = address(this).balance.sub(ethJackpot);
        if(totalSupply > 0){
            tokenPrice = (coinMC / totalSupply);
            }else{(tokenPrice = buyingPrice().add(coinMC));}
        jpTimer = now + 1 days;
        leader = _customerAddress;
    }


  function sell(uint256 _amount) public
    onlyTokenHolders
    {
        address _customerAddress = msg.sender;
        require(_amount <= balanceOf[_customerAddress]);
        uint256 _eth = _amount.mul(sellingPrice());
        uint256 _fee = _amount.mul(tokenPrice.sub(sellingPrice()));
        totalSupply = totalSupply.sub(_amount);
        balanceOf[ _customerAddress] = balanceOf[ _customerAddress].sub(_amount);
        uint256 splitFee = _fee/2;
        ethJackpot = ethJackpot.add(splitFee);
        divs[leader] = divs[leader].add(splitFee);
        emit onSellEvent(_customerAddress, _amount);
        coinMC = coinMC.sub(_eth.add(splitFee));
        if(totalSupply > 0){
            totalSupply = (coinMC/totalSupply);
            }else{(tokenPrice = buyingPrice().add(coinMC));}
        divs[_customerAddress] = divs[_customerAddress].add(_eth);
    }
    
    function sellAll() public
    onlyTokenHolders
    {
        sell(balanceOf[msg.sender]);
    }
    
    function withDraw() public payable
    {
        address _customerAddress = msg.sender;
        _customerAddress.transfer(divs[_customerAddress]);
        divs[_customerAddress] = 0;
    }

    function transfer(address _toAddress, uint256 _amountOfTokens)
    public
    returns(bool)
    {
        address _customerAddress = msg.sender;
        require( _amountOfTokens <= balanceOf[_customerAddress] );
        if (_amountOfTokens>0)
        {
            {
                balanceOf[_customerAddress] = balanceOf[_customerAddress].sub( _amountOfTokens );
                balanceOf[ _toAddress] = balanceOf[ _toAddress].add( _amountOfTokens );
            }
        }
        emit onTransfer(_customerAddress, _toAddress, _amountOfTokens);
        return true;
    }

    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
 
    function myDivs()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return divs[_customerAddress];    
    }
    
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf[_customerAddress];
    }
    
   
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return balanceOf[_customerAddress];
    }
    
    function sellingPrice()
        view
        public
        returns(uint256)
    {
        uint256 _fee = tokenPrice/sellOutFee;
        return tokenPrice.sub(_fee) ;
    }
    
    function buyingPrice()
        view
        public
        returns(uint256)
    {
        uint256 _fee = tokenPrice/buyInFee;
        return tokenPrice + _fee ;
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