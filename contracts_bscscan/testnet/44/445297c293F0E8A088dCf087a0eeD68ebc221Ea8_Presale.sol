/**
 *Submitted for verification at BscScan.com on 2021-10-25
*/

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
        priceFeed = AggregatorV3Interface(0x5ea7D6A33D3655F661C298ac8086708148883c34);
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
        bool isInvestedInPrivatePreSale;
        uint256 amountPrivateSaleTokensVesting;
        uint256 amountInvestedInPrivatePreSale;

        
        uint256 amountPublicSaleTokens;
        uint256 amountInvestedInPublicPreSale;
        bool isInvestedInPublicPreSale;
        uint256 amountPublicSaleTokensVesting;

    }
    
    bool public privateSaleClaimable;
    bool public publicSaleClaimable;
    bool public investmentclaimable;
    bool public publicSaleStop;
    bool public privateSaleStop;
    
    uint256 public privateParticipants;
    uint256 public publicparticipants;    
    uint256 public hardcap=1000e18;
    uint256 public presalePrivateTime=10 minutes;
    uint256 public presalePublicTime=10 minutes;
    uint256 public prePublicSaleStart;
    uint256 public prePublicSaleEnd;
    uint256 public prePrivateSaleStart;
    uint256 public prePrivateSaleEnd;
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
	
		modifier isPrivateSaleStop(){
	    require(!privateSaleStop,"Private sale is not started yet");
	    _;
	}
	
	
		modifier isPublicSaleStop(){
	    require(!publicSaleStop,"Private sale is not started yet");
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
        return(getBNB(amount).div(1e18));
    }
    
    function usdtToTokens(uint256 _value)view public returns(uint256){
        
        return(_value.mul(1e18).div(tokenPrice));
    }
    
    function tokenToUsdt(uint256 _value)view public returns(uint256){
        
        return(_value.mul(tokenPrice).div(1e18));
    }
    
    function privatePresale(address Addr,uint256 amount)public payable isPrivateSaleStop returns(bool){
        
        
        uint256 tokens=getUSDT(msg.value);
        require(tokens>=amount,"you are sending low amount");
        if(users[Addr].amountInvestedInPrivatePreSale==0){
         privateParticipants++;   
        }
        users[Addr].amountInvestedInPrivatePreSale=users[Addr].amountInvestedInPrivatePreSale.add(msg.value);
        users[Addr].isInvestedInPrivatePreSale=true;
        users[Addr].amountPrivateSaleTokens=users[Addr].amountPrivateSaleTokens.add(tokens.div(2));
        users[Addr].amountPrivateSaleTokensVesting=users[Addr].amountPrivateSaleTokensVesting.add(tokens.div(2));
        return true;
    }
    
    function privateSaleClaim()public isClaimAblePrivateSale returns(bool){
        require(users[msg.sender].isInvestedInPrivatePreSale,"you are not investor in PrivatePresale");
        require(users[msg.sender].amountPrivateSaleTokens>0);
        token.transferFrom(owner,msg.sender,users[msg.sender].amountPrivateSaleTokens);
        users[msg.sender].amountPrivateSaleTokens=0;
        return true;
        
    }
    
    function privateSaleClaimVesting()public returns(bool){
        require(users[msg.sender].isInvestedInPrivatePreSale,"you are not investor in PrivatePresale");
        require(users[msg.sender].amountPrivateSaleTokensVesting>0);
        require(privateSaleStop,"sales is not stop yet");
        require(block.timestamp>prePrivateSaleEnd.add(10 minutes),"You cannot claim amount before the time");
        token.transferFrom(owner,msg.sender,users[msg.sender].amountPrivateSaleTokensVesting);
        users[msg.sender].amountPrivateSaleTokensVesting=0;
        return true;
        
    }
    
    function publicPresale()public payable isPublicSaleStop returns(bool){
        uint256 tokens=getUSDT(msg.value);
        if(users[msg.sender].amountInvestedInPublicPreSale==0){
            publicparticipants++;
        }
        users[msg.sender].isInvestedInPublicPreSale=true;
        users[msg.sender].amountInvestedInPublicPreSale=users[msg.sender].amountInvestedInPublicPreSale.add(msg.value);
        if(users[msg.sender].isInvestedInPrivatePreSale){
        require(users[msg.sender].amountInvestedInPublicPreSale<5e18,"You cannot purchase more than 5 BNB, if you are presale INvestor");
        }
        users[msg.sender].amountPublicSaleTokens=users[msg.sender].amountPublicSaleTokens.add(tokens.mul(75).div(100));
        users[msg.sender].amountPublicSaleTokensVesting=users[msg.sender].amountPublicSaleTokensVesting.add(tokens.mul(25).div(100));
        checksOnPresale();
        return true;
    }
    
    function publicSaleClaim()public isClaimAblePublicSale  returns(bool){
        require(users[msg.sender].amountPublicSaleTokens>0);
        token.transferFrom(owner,msg.sender,users[msg.sender].amountPublicSaleTokens.mul(75).div(100));
        users[msg.sender].amountPublicSaleTokens=users[msg.sender].amountPublicSaleTokens.mul(25).div(100);
        return true;
        
    }
    
        function publicSaleClaimvesting()public isClaimAblePublicSale  returns(bool){
        require(users[msg.sender].amountPublicSaleTokens>0);
        require(block.timestamp>prePublicSaleEnd.add(30 days),"You cannot claim amount before the time");
        token.transferFrom(owner,msg.sender,users[msg.sender].amountPublicSaleTokens);
        users[msg.sender].amountPublicSaleTokens=0;

        return true;
        
    }
    
    function checksOnPresale()private {
        if(address(this).balance>hardcap && block.timestamp<prePublicSaleStart.add(presalePublicTime)){
            publicSaleStop=true;
            publicSaleClaimable=true;
            privateSaleClaimable=true;
            prePublicSaleEnd=block.timestamp;
        }
        else if(address(this).balance<hardcap && block.timestamp>prePublicSaleStart.add(presalePublicTime)){
            publicSaleStop=true;
            publicSaleClaimable=true;
            privateSaleClaimable=true;
            prePublicSaleEnd=block.timestamp;            
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
        require(publicSaleStop,"sale is not stop yet");
        payable(msg.sender).transfer(users[msg.sender].amountInvestedInPublicPreSale.add(users[msg.sender].amountInvestedInPrivatePreSale));
        users[msg.sender].amountInvestedInPublicPreSale=0;
        users[msg.sender].amountInvestedInPrivatePreSale=0;
        delete users[msg.sender];
        return true;
    }
    function getTokenByOwner()public onlyOwner returns(bool){
        // require(salestop,"sale is not stop yet");
        token.transfer(owner,token.balanceOf(address(this)));
        return true;
        
    }
    
    function getFundByOwner()public onlyOwner returns(bool){
        
        owner.transfer(address(this).balance);
        return true;
        
    }
    
    function startPrivatePresaleSale()onlyOwner public returns(bool){
        privateSaleStop=false;
        prePrivateSaleStart=block.timestamp;
        return true;
    }
    
    function startPublicPresaleSale()onlyOwner public returns(bool){
        publicSaleStop=false;
        prePublicSaleStart=block.timestamp;
        return true;
    }
    
    function stopPrivatePresaleSale()onlyOwner public returns(bool){
        prePrivateSaleStart=0;
        privateSaleStop=true;
        prePrivateSaleEnd=block.timestamp;
        privateSaleClaimable=true;
        return true;
    }
    
    function stopPublicPresaleSale()onlyOwner public returns(bool){
    
        publicSaleStop=true;
        prePublicSaleStart=0;
        prePublicSaleEnd=block.timestamp;
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