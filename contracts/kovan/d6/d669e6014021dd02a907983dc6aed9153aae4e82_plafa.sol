/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// File: contracts/AggregatorV3Interface.sol


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
// File: contracts/PriceFeed.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    
    constructor() {
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
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
// File: contracts/pLafa.sol

pragma solidity ^0.8.0;



interface IPriceFeed{
    function getLatestPrice() external  returns(int);
}

contract plafa {
    
    IPriceFeed pfaddress;
    constructor(address _price) public {
        pfaddress = IPriceFeed(_price);
        contractDeployemnt = block.timestamp;
    }
     struct Transaction{
         uint256 initialDeposit;
         uint256 mint;
         uint256 currentPrice;
         uint256 timestamp;
         bool hasRedeemed;
         uint256 noOfTokensReceived;
     }
    
     /** Mapping **/
      
       mapping(address => uint256)public userBalance;
       mapping(address => bool)public user1000Qualifier;
       mapping(address => bool)public user250Qualifier;
       mapping(address => Transaction[])public transactions; 
       mapping(address => uint256)public payOuts;
     /**  Events  **/
     
        event TransactionMint100(address indexed _userAddress, uint256 _amount,uint256 _noOfToken);
        event TransactionMint50(address indexed _userAddress, uint256 _amount,uint256 _noOfToken);
        event Burn(address indexed _userAddress, uint256 _noOfTokens);
       
     /** Variables **/ 
     
        uint256 constant public tokenPriceInitial_ = 0.0000001 ether;
        uint256 constant public tokenPriceIncremental_ = 0.00000001 ether;
        uint256 constant internal magnitude = 2e64;
        string public name = "La Familia";
        string public symbol = "pLAFA";
        uint8 constant public decimals = 18;
        uint256 internal tokenSupply_ = 0;
        uint256 public TransactionCount = 0;
        uint256 public profitPerShareGeneral;
        uint256 public profitPerShare100Rewards;
        uint256 public profitPerShare250Rewards;
        uint256 public contractDeployemnt;
        
    
   function mint$100() external payable returns(uint256){
       
       uint256 userDeposit = msg.value;
       uint excess = 0;
       uint value = getEquivalentAmount(100);
       require(userDeposit >= value, "Insufficeint funds");
       if(userDeposit > value)excess = SafeMath.sub(userDeposit, value); 
       if(excess > 0)payable(msg.sender).transfer(excess);
       userDeposit = value;
       uint256 amountOfTokens = ethereumToTokens_(userDeposit);
       Transaction memory transaction =  Transaction(value,100,tokenPriceInitial_,block.timestamp,false,amountOfTokens);
       transactions[msg.sender].push(transaction);
       userBalance[msg.sender] += amountOfTokens;
       tokenSupply_ = SafeMath.add(tokenSupply_, amountOfTokens);
       
        if(contractDeployemnt + 24 hours > block.timestamp ) hasDeposited(1000,msg.sender);
        if(contractDeployemnt + 30 days > block.timestamp) hasDeposited (250,msg.sender);
        
       emit TransactionMint100(msg.sender,userDeposit,amountOfTokens);
       return amountOfTokens;
   }

   function mint$50() external payable returns(uint256){
       
       uint256 userDeposit = msg.value;
       uint excess = 0;
       uint value = getEquivalentAmount(50);
       require(userDeposit >= value, "Insufficeint funds");
       if(userDeposit > value)excess = SafeMath.sub(userDeposit, value); 
       if(excess > 0)payable(msg.sender).transfer(excess);
       userDeposit = value;
       uint256 amountOfTokens = ethereumToTokens_(userDeposit);
       Transaction memory transaction =  Transaction(value,50,tokenPriceInitial_,block.timestamp,false,amountOfTokens);
       transactions[msg.sender].push(transaction);
       userBalance[msg.sender] += amountOfTokens;
       tokenSupply_ = SafeMath.add(tokenSupply_, amountOfTokens);
       
        if(contractDeployemnt + 24 hours > block.timestamp ) hasDeposited(1000,msg.sender);
        if(contractDeployemnt + 30 days > block.timestamp) hasDeposited (250,msg.sender);
        
       emit TransactionMint50(msg.sender,userDeposit,amountOfTokens);
       return amountOfTokens;
   }
   
   function burn(uint _index) external payable{
       uint mintDeposit = transactions[msg.sender][_index].initialDeposit;
       uint mintValue = transactions[msg.sender][_index].mint;
       uint rewardLimit;
       rewardLimit = mintValue == 50? 125: 250;
       require(mintDeposit >= getEquivalentAmount(rewardLimit),"ERR_CANNOT_BURN");
       if(rewardLimit == 125) _burn(100,20,4,1);  
       else  _burn(200,40,8,2); 
       
      
   }
    function _burn( uint _reward,uint _tax1,uint _tax2,uint _tax3)internal{
      
           uint256 val1 = _tax1;
           uint256 val2 = _tax2;
           uint256 val3 = _tax3;

           uint256 p1 = getEquivalentAmount(val1);
           uint256 p2 = getEquivalentAmount(val2);
           uint256 p3 = getEquivalentAmount(val3);
           uint256 total = SafeMath.add(p1,SafeMath.add(p2,p3));
           uint totalTokens = ethereumToTokens_(total);
          
            profitPerShareGeneral += SafeMath.mul(p1,magnitude)/ tokenSupply_;
            profitPerShare100Rewards += SafeMath.mul(p2,magnitude)/ tokenSupply_;
            profitPerShare250Rewards += SafeMath.mul(p3,magnitude)/ tokenSupply_;
            
            userBalance[msg.sender]= SafeMath.sub(userBalance[msg.sender],totalTokens);
            payable(msg.sender).transfer(getEquivalentAmount(_reward));
            emit Burn(msg.sender, totalTokens);
    }
    
    function emergencyBurn(uint _index) external {
       uint mintValue = transactions[msg.sender][_index].mint;
       uint rewardLimit;
       rewardLimit = mintValue == 50? 125: 250;
       uint amount = tokensToEthereum_(transactions[msg.sender][_index].noOfTokensReceived);
       uint dollarEquivalency = getEquivalentPrice(amount);
       if(rewardLimit == 125) _burn(SafeMath.sub(dollarEquivalency,35),30,4,1);  
       else  _burn(SafeMath.sub(dollarEquivalency,70),60,8,2);
   }
    function getEquivalentAmount(uint256 _dollarAmount)public returns(uint256){
        int currentPrice = pfaddress.getLatestPrice();//41743000000;
        uint value = SafeMath.div(SafeMath.mul(_dollarAmount,1e26),uint256(currentPrice));
        return value;
    } 
   
     function getEquivalentPrice(uint256 _ethers)internal  returns(uint256){
        int currentPrice = pfaddress.getLatestPrice();//41743000000;
        uint value = SafeMath.div(SafeMath.mul(_ethers,uint256(currentPrice)),1e18);
        return value;
    } 
    
    
    function withdrawdividends(address _user) external{
        uint totalProfit = 0;
        if(user1000Qualifier[_user]== true){
            totalProfit = profitPerShareGeneral + profitPerShare100Rewards + profitPerShare250Rewards;
        }
        else if(user250Qualifier[_user]== true){
            totalProfit = profitPerShareGeneral + profitPerShare250Rewards;
        }
        else{
            totalProfit = profitPerShareGeneral;
        }
        
        uint updated = (totalProfit)*(userBalance[_user])-payOuts[_user];
        payOuts[_user] += updated;
        payable(_user).transfer(updated);
    }
    
    function hasDeposited(uint _amt, address _userAddress)public{
         uint sum =0;
         for(uint i = 0 ; i<transactions[_userAddress].length ; i++)
         {
              sum += transactions[_userAddress][i].initialDeposit;
         }
        uint value = getEquivalentAmount(_amt);
        if(_amt == 1000)
        {
            if(sum >= value){
            user1000Qualifier[_userAddress] = true; 
            user250Qualifier[_userAddress]= true;
         }
            
        }
        else if(_amt == 250){
            
        }
        if(sum >= value){
            user250Qualifier[_userAddress]= true;
         }
       
     }
    /**
     * Return the sell price of 1 individual token.
     */
    function price() 
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