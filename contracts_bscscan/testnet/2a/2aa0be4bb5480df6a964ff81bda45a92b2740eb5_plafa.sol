/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    
    constructor() {
        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}


interface IPriceFeed{
    function getLatestPrice() external  returns(int);
}

contract plafa {
    
    using SafeMath for uint256;
    IPriceFeed pfaddress;
    constructor(address _price) public {
        pfaddress = IPriceFeed(_price);
    }
     struct User{
         address userAddress;
         uint256 initialDeposit;
         uint256 currentPrice;
         uint256 timeStamp;
     }
     /** Modifiers **/
     
         modifier _require100or50 (uint256 _amount){
              require(_amount == 50e18 || _amount == 100e18);
             _;
         }
         
     /** Mapping **/
      
       mapping(address => uint256)public userBalance;
       mapping(uint256 => User)public users;  
     /**  Events  **/
     
        event userMint100(address indexed _useraddress, uint256 _amount,uint256 _noOfToken);
        event userMint50(address indexed _useraddress, uint256 _amount,uint256 _noOfToken);
       
     /** Variables **/ 
     
        uint256 constant public tokenPriceInitial_ = 0.0000001 ether;
        uint256 constant public tokenPriceIncremental_ = 0.00000001 ether;
        uint256 constant internal magnitude = 2**64;
        string public name = "La Familia";
        string public symbol = "pLAFA";
        uint8 constant public decimals = 18;
        uint256 internal tokenSupply_ = 0;
        uint256 public userCount = 0;
          
   
   function mint$100() external payable returns(uint256){
       
       uint256 userDeposit = msg.value;
       uint excess = 0;
       uint value = getEquivalentPrice(100);
       require(userDeposit >= value, "Insufficeint funds");
       if(userDeposit > value)excess = SafeMath.sub(userDeposit, value); 
       if(excess > 0)payable(msg.sender).transfer(excess);
       userDeposit = value;
       User memory user =  User(msg.sender,value,tokenPriceInitial_,block.timestamp);
       users[userCount] = user;
       uint256 amountOfTokens = ethereumToTokens_(userDeposit);
       userBalance[msg.sender] += amountOfTokens;
       tokenSupply_ = SafeMath.add(tokenSupply_, amountOfTokens);
       emit userMint100(msg.sender,userDeposit,amountOfTokens);
       return amountOfTokens;
   }

   function mint$50() external payable returns(uint256){
       
       uint256 userDeposit = msg.value;
       uint excess = 0;
       uint value = getEquivalentPrice(50);
       require(userDeposit >= value, "Insufficeint funds");
       if(userDeposit > value)excess = SafeMath.sub(userDeposit, value); 
       if(excess > 0)payable(msg.sender).transfer(excess);
       userDeposit = value;
       User memory user =  User(msg.sender,value,tokenPriceInitial_,block.timestamp);
       users[userCount] = user;
       uint256 amountOfTokens = ethereumToTokens_(userDeposit);
       userBalance[msg.sender] += amountOfTokens;
       tokenSupply_ = SafeMath.add(tokenSupply_, amountOfTokens);
       emit userMint50(msg.sender,userDeposit,amountOfTokens);
       return amountOfTokens;
   }
   
    function getEquivalentPrice(uint256 _dollarAmount)public  returns(uint256){
        int currentPrice = pfaddress.getLatestPrice();
        uint value = SafeMath.div(SafeMath.mul(_dollarAmount,1e26),uint256(currentPrice));
        return value;
    } 
    
    /**
     * Return the buy price of 1 individual token.
     */
    // function sellPrice() 
    //     public 
    //     view 
    //     returns(uint256)
    // {
       
    //     if(tokenSupply_ == 0){
    //         return tokenPriceInitial_ - tokenPriceIncremental_;
    //     } else {
    //         uint256 _ethereum = tokensToEthereum_(1e18);
    //         uint256 _dividends = SafeMath.div(_ethereum, dividendFee_  );
    //         uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
    //         return _taxedEthereum;
    //     }
    // }
    
    /**
     * Return the sell price of 1 individual token.
     */
    function buyPrice() 
        public 
        view 
        returns(uint256)
    {
        
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
           
           return _ethereum;
        }
    }
    
     function ethereumToTokens_(uint256 _ethereum)
        public
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived = 
         (
            (
                // underflow attempts BTFO
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
                            +
                            (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                            +
                            (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
                        )
                    ), _tokenPriceInitial
                )
            )/(tokenPriceIncremental_)
        )-(tokenSupply_)
        ;
  
        return _tokensReceived;
    }
    
    /**
     * Calculate token sell value.
          */
     function tokensToEthereum_(uint256 _tokens)
        public
        view
        returns(uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
        (
            // underflow attempts BTFO
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
                        )-tokenPriceIncremental_
                    )*(tokens_ - 1e18)
                ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
            )
        /1e18);
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

}   /**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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