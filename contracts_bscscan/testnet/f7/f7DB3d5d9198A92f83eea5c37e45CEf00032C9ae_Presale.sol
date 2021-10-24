/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

pragma solidity 0.8.9;


// SPDX-License-Identifier:MIT



interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}





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

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            , 
            int price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        return price;
    }
  }



  contract Presale is PriceConsumerV3 {
	using SafeMath for uint256;
	IBEP20 public token;
    address payable public owner;
    
    struct User{
        uint256 amountPrivateSaleTokens;
        uint256 timeForNextPrivateSaleClaimAble;
        uint256 amountPublicSaleTokens;
        uint256 timeForNextPublicSaleClaimAble;
    }
    
    bool public privateSaleClaimable;
    bool public publicSaleClaimable;
    bool public investmentclaimable;
    bool public salestop;
    uint256 public hardcap;
    uint256 public presaleTime=30 days;
    uint256 public pareSaleStart=block.timestamp;
    uint256 public tokenPrice=1000000000000000000;
    
    mapping(address=>User)public users;

	constructor(address payable _owner,address _token)  {
	    
	    owner=_owner;
	    
	    token=IBEP20(_token);
	}
	
	
	modifier isClaimAblePrivateSale(){
	    require(privateSaleClaimable,"Private sale is not claimable yet");
	    _;
	}
	
		modifier isSaleStop(){
	    require(!salestop,"Private sale is not claimable yet");
	    _;
	}
	
	
	
		modifier isClaimAblePublicSale(){
	    require(publicSaleClaimable,"Private sale is not claimable yet");
	    _;
	}
	
	modifier onlyOwner(){
	    require(msg.sender==owner,"access denied");
	    _;
	}
	
	
	function getBNB(uint256 _value)view public returns(uint256){
     return(uint256(getLatestPrice()).mul(_value)).div(1e18);   
    }
    
    function getUSDT(uint256 _value)view public returns(uint256){
        
        return(_value.mul(1e18).div(uint256(getLatestPrice())));
        
    }
    
    function bnbToTokens(uint256 _value)view public returns(uint256){
        
        return(getUSDT(_value).mul(tokenPrice).div(1e18));
    }
    function tokenToBnb(uint256 _value)view public returns(uint256){
        uint256 amount=_value.mul(tokenPrice);
        return(getBNB(amount));
    }
    
    function usdtToTokens(uint256 _value)view public returns(uint256){
        
        return(_value.mul(1e18).div(tokenPrice));
    }
    
    function tokenToUsdt(uint256 _value)view public returns(uint256){
        
        return(_value.mul(tokenPrice).div(1e18));
    }
    
    function privatePresale()public payable isSaleStop returns(bool){
        
        uint256 tokens=getUSDT(msg.value);
        
        users[msg.sender].amountPrivateSaleTokens=users[msg.sender].amountPrivateSaleTokens.add(tokens);
        
        return true;
    }
    
    function privateSaleClaim()public isClaimAblePrivateSale isSaleStop returns(bool){
        require(users[msg.sender].amountPrivateSaleTokens>0);
        require(block.timestamp>users[msg.sender].timeForNextPrivateSaleClaimAble.add(1 days),"You cannot claim amount before the time");
        token.transferFrom(owner,msg.sender,users[msg.sender].amountPrivateSaleTokens.div(2));
        users[msg.sender].timeForNextPrivateSaleClaimAble=block.timestamp;
        return true;
        
    }
    
    function publicPresale()public payable isSaleStop returns(bool){
        uint256 tokens=getUSDT(msg.value);
        users[msg.sender].amountPublicSaleTokens=users[msg.sender].amountPublicSaleTokens.add(tokens);
        return true;
    }
    
    function publicSaleClaim()public isClaimAblePublicSale isSaleStop returns(bool){
        require(users[msg.sender].amountPublicSaleTokens>0);
        require(block.timestamp>users[msg.sender].timeForNextPublicSaleClaimAble.add(1 days),"You cannot claim amount before the time");
        token.transferFrom(owner,msg.sender,users[msg.sender].amountPublicSaleTokens.div(2));
        users[msg.sender].timeForNextPublicSaleClaimAble=block.timestamp;
        return true;
        
    }
    
    function checksOnPresale()private {
        if(address(this).balance>hardcap && block.timestamp<pareSaleStart.add(presaleTime)){
            salestop=true;
        }
        else if(address(this).balance<hardcap && block.timestamp>pareSaleStart.add(presaleTime)){
            salestop=true;
        }
    }
    
    function cancelSale()public onlyOwner returns(bool){
        if(address(this).balance==0){
        selfdestruct(owner);
        }
        else{
            investmentclaimable=true;
        }
        return true;
        
    }
    
    function setInvestmentClaimAble(bool value)public onlyOwner returns(bool){
        investmentclaimable=value;
        return true;
    }
    
    function claimAfterSaleCancel()public returns(bool){
        require(salestop,"sale is not stop yet");
        payable(msg.sender).transfer(tokenToBnb(users[msg.sender].amountPublicSaleTokens));
        delete users[msg.sender];
        return true;
    }
    function getTokenByOwner()public onlyOwner returns(bool){
        require(salestop,"sale is not stop yet");
        token.transfer(owner,token.balanceOf(address(this)));
        return true;
        
    }
    
    function getFundByOwner()public onlyOwner returns(bool){
        
        owner.transfer(address(this).balance);
        return true;
        
    }
    
    
}



library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}