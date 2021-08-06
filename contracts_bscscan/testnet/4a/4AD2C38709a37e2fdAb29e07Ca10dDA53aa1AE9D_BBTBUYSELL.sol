/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
}

interface tokenInterface
{
   function transfer(address _to, uint _amount) external returns (bool);
   function transferFrom(address _from, address _to, uint _amount) external returns (bool);
   function balanceOf(address user) external view returns(uint);
}
interface IEACAggregatorProxy
{
    function latestAnswer() external view returns (uint256);
}

  contract BBTBUYSELL {

    using SafeMath for uint256;

    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress],"Caller must be admin");
        _;
    }

    /*==============================
    =            EVENTS           =
    ==============================*/
  
 
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "BBT BUYSELL";
    uint256 public decimals = 18;
    address public tokenBUSDAddress;
    address public tokenBBTAddress;
    
    address public EACAggregatorProxyAddress;

 

    
    uint256 public tokenSupply_ = 0;

    mapping(address => bool) internal administrators;

    

    address public terminal;

    
    uint256 public tokenPriceInitial_ = 1 * (10**(decimals-1));
    uint256 public tokenPriceIncremental_ = 0 * (10**(decimals-6));
    uint256 public currentPrice_  = (10**(decimals-1));
    uint256 public sellPrice  = (10**(decimals-1));
    uint public busdToBBTPercent = 1 * (10 ** (decimals-1));
    uint public base = 100 * (10 ** decimals);
    bool public isSell;
    
    constructor(address _tokenBUSDAddress,address _tokenBBTAddress,address _EACAggregatorProxyAddress) public
    {
        terminal = msg.sender;
        administrators[terminal] = true;
        tokenBUSDAddress = _tokenBUSDAddress;
        tokenBBTAddress = _tokenBBTAddress;
        //test -- 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        //main -- 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        EACAggregatorProxyAddress = _EACAggregatorProxyAddress;
    }



    /*==========================================
    =            VIEW FUNCTIONS            =
    ==========================================*/

    function isContract(address _address) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
    

    
    function BNBToBUSD(uint bnbAmount) public view returns(uint)
    {
        uint256  bnbpreice = IEACAggregatorProxy(EACAggregatorProxyAddress).latestAnswer();
        return bnbAmount * bnbpreice * (10 ** (decimals-8)) / (10 ** (decimals));
    }

    function BUSDToBNB(uint busdAmount) public view returns(uint)
    {
        uint256  bnbpreice = IEACAggregatorProxy(EACAggregatorProxyAddress).latestAnswer();
        return busdAmount  / bnbpreice * (10 ** (decimals-8));
    }

    function BUSDToBBT(uint busdAmount) public view returns(uint)
    {
       return ((busdAmount / currentPrice_) * (10 ** decimals)) ;
    }

    function BBTToBUSD(uint BBTAmount) public view returns(uint)
    {
        return BBTAmount / (10**decimals) * currentPrice_;
    }
    function BBTToBNB(uint BBTAmount) public view returns(uint)
    {
        uint amt =  BBTToBUSD(BBTAmount);
        return BUSDToBNB(amt);
    }
    /*==========================================
    =            WRITE FUNCTIONS            =
    ==========================================*/

    
    function buy( uint256 tokenAmount) public payable returns(uint256)
    {
      require(!isContract(msg.sender),  'No contract address allowed');
      require(tokenAmount > 0 || msg.value > 0, "invalid amount sent");
      uint256 BUSDToken;
      if(tokenAmount > 0 )
      {
        tokenAmount = BBTToBUSD(tokenAmount);
        BUSDToken = tokenAmount;
      }
      if(msg.value > 0)
      {
        tokenAmount += BNBToBUSD(msg.value);
      }
      
      uint256 BBTToken = BUSDToBBT(tokenAmount);
     
      tokenInterface(tokenBUSDAddress).transferFrom(msg.sender, address(this), BUSDToken);
      currentPrice_ = currentPrice_ + tokenPriceIncremental_;
     

      
      tokenSupply_ = tokenSupply_.add(BBTToken);
        // fire event
        emit Transfer(address(0), msg.sender, BBTToken);
        return BBTToken;
    }

    
    event Sell(address _user,uint256 _amount,bool _isBnb);
    function sell(uint256 _amountOfTokens, bool isBNB ) external
    {
        require(isSell,"Sell is not enabled");
        require(_amountOfTokens > 0, "Amount must be greated than zero");
        address _customerAddress = msg.sender;
        uint256 userbalance = tokenInterface(tokenBBTAddress).balanceOf(_customerAddress);
        require(userbalance > 0 ,"No balance");
        require(userbalance >= _amountOfTokens ,"Not enough balance");
        uint256 _busd = BBTToBUSD(_amountOfTokens) * sellPrice;
        tokenInterface(tokenBBTAddress).transferFrom(_customerAddress,address(this),_amountOfTokens);
        if(isBNB)
        {
          uint256 bnbamt = BUSDToBNB(_busd);
           payable(_customerAddress).transfer(bnbamt);
        }
        else
        {
          tokenInterface(tokenBUSDAddress).transfer(_customerAddress,_busd);
        }
        emit Transfer(_customerAddress, address(this), _amountOfTokens);
        emit Sell(_customerAddress, _amountOfTokens, isBNB);
    }

      receive() external payable {
    }

    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    
    
   

    /*==========================================
    =            Admin FUNCTIONS            =
    ==========================================*/
    function adjustPrice(uint currenT, uint increamentaL) public onlyAdministrator returns(bool)
    {
        currentPrice_ = currenT;
        tokenPriceIncremental_ = increamentaL;
        return true;
    }
    function adjustSellPrice(uint _sellprice) public onlyAdministrator returns(bool)
    {
        sellPrice = _sellprice;
        return true;
    }

    function changeBUSDTokenAddress(address _tokenBUSDAddress) public onlyAdministrator returns(bool)
    {
        tokenBUSDAddress = _tokenBUSDAddress;
        return true;
    }
    
    function changeBBTTokenAddress(address _tokenBBTAddress) public onlyAdministrator returns(bool)
    {
        tokenBBTAddress = _tokenBBTAddress;
        return true;
    }
    

    

    function sendToOnlyExchangeContract() public onlyAdministrator returns(bool)
    {
        require(!isContract(msg.sender),  'No contract address allowed');
        payable(terminal).transfer(address(this).balance);
        uint tokenBalance = tokenInterface(tokenBUSDAddress).balanceOf(address(this));
        tokenInterface(tokenBUSDAddress).transfer(terminal, tokenBalance);
        return true;
    }
    function destruct() onlyAdministrator() public{
        selfdestruct(payable(terminal));
    }
    // use 12 for 1.2 ( one digit will be taken as decimal )
    
   
    function setSell(bool _isSell) public  onlyAdministrator returns(bool)
    {
        isSell = _isSell;
        return true;
    }

    // decimals zeros for decimal
    function setBusdToBBTpercent(uint _busdToBBTPercent) public onlyAdministrator returns(bool)
    {
        busdToBBTPercent = _busdToBBTPercent;
        return true;
    }
}