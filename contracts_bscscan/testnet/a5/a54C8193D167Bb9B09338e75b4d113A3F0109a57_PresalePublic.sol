/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-27
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
    //  0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941
    //  0x5ea7D6A33D3655F661C298ac8086708148883c34
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



  contract PresalePublic is PriceConsumerV3 {
	using SafeMath for uint256;
	IBEP20 public token;
    address payable public owner;
    
    struct User{
        uint256 amountPublicSaleTokens;
        uint256 amountInvestedInPublicPreSale;
        bool isInvestedInPublicPreSale;
        uint256 amountPublicSaleTokensVesting;
        uint256 totalTokensTakenPublic;
    }
    

    bool public publicSaleClaimable;
    bool public publicSaleStop=true;
    bool public isCanceled;
    uint256 public publicparticipants;    
    uint256 public hardcap;
    uint256 public hardcapLimit=80000e18;
    uint256 public presalePublicTime=5 minutes;
    uint256 public prePublicSaleStart;
    uint256 public prePublicSaleEnd;
    uint256 public tokenPricePublicSale=16000000000000000;
    uint256 public totalTokensSalePublic;
    
    mapping(address=>User)public users;

	constructor(address payable _owner,address _token)  {
	    owner=_owner;
	    token=IBEP20(_token);
	}
	
		modifier isPublicSaleStop(){
	    require(!publicSaleStop,"public sale is not started yet");
	    _;
	}
	
	
	
		modifier isClaimAblePublicSale(){
	    require(publicSaleClaimable,"Public sale is not claimable yet");
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
    

    
    function bnbToTokensForPublicSale(uint256 _value)view public returns(uint256){
        
        return(usdtToTokensForPublicSale(getUSDT(_value)));
    }
    function tokenToBnbForPublicSale(uint256 _value)view public returns(uint256){
        uint256 amount=tokenToUsdtForPublicSale(_value);
        return(getBNB(amount));
    }
    
    function tokenToUsdtForPublicSale(uint256 _value)view public returns(uint256){
        return(_value.mul(tokenPricePublicSale).div(1e18));
    }
    
    
    function usdtToTokensForPublicSale(uint256 _value)view public returns(uint256){
        return(_value.mul(1e18).div(tokenPricePublicSale));
    }
    
    function publicPresale(address Addr,uint256 amount)public payable isPublicSaleStop returns(bool){
        require(!isCanceled,"presale is canceled");

        
        hardcap=hardcap.add(getUSDT(msg.value));
        
        require(hardcapLimit>=hardcap,"Hard cap limit is reached");
        
        uint256 tokens=bnbToTokensForPublicSale(msg.value);
        require(tokens>=amount,"you are sending low amount");
        
        if(users[Addr].amountInvestedInPublicPreSale==0){
            publicparticipants++;
        }
        users[Addr].isInvestedInPublicPreSale=true;
        users[Addr].amountInvestedInPublicPreSale=users[Addr].amountInvestedInPublicPreSale.add(msg.value);
        
        users[Addr].amountPublicSaleTokens=users[Addr].amountPublicSaleTokens.add(tokens.mul(75).div(100));
        users[Addr].amountPublicSaleTokensVesting=users[Addr].amountPublicSaleTokensVesting.add(tokens.mul(25).div(100));
        users[Addr].totalTokensTakenPublic=users[Addr].totalTokensTakenPublic.add(tokens);
        totalTokensSalePublic=totalTokensSalePublic.add(tokens);
        
        return true;
    }
    
    
    // function publicPresaleWithoutAllocations()public payable isPublicSaleStop IsExtraBuyEnable returns(bool){
    //     require(!isCanceled,"presale is canceled");
    //     // require(users[msg.sender].isInvestedInPublicPreSale,"you are not investor in private presale");
         
    //     hardcap=hardcap.add(getUSDT(msg.value));
        
    //     require(hardcapLimit>=hardcap,"Hard cap limit is reached");
        
    //     uint256 tokens=bnbToTokensForPublicSale(msg.value);
    //     // require(tokens>=amount,"you are sending low amount");
        
    //     if(users[msg.sender].amountInvestedInPublicPreSale==0){
    //         publicparticipants++;
    //     }
    //     users[msg.sender].isInvestedInPublicPreSale=true;
    //     users[msg.sender].totalInvestedExtra=users[msg.sender].totalInvestedExtra.add(msg.value);
    //     require(users[msg.sender].totalInvestedExtra<firstComeLimit,"you cannot invest more that size limit");
    //     users[msg.sender].amountPublicSaleTokens=users[msg.sender].amountPublicSaleTokens.add(tokens.mul(75).div(100));
    //     users[msg.sender].amountPublicSaleTokensVesting=users[msg.sender].amountPublicSaleTokensVesting.add(tokens.mul(25).div(100));
    //     users[msg.sender].totalTokensTakenPublic=users[msg.sender].totalTokensTakenPublic.add(tokens);
    //     totalTokensSalePublic=totalTokensSalePublic.add(tokens);
        
    //     return true;
    // }
    
    function publicSaleClaim()public isClaimAblePublicSale    returns(bool){
        require(!isCanceled,"presale is canceled");
        require(users[msg.sender].amountPublicSaleTokens>0);
        require(users[msg.sender].isInvestedInPublicPreSale,"you are not investor in public");
        token.transferFrom(owner,msg.sender,users[msg.sender].amountPublicSaleTokens);
        users[msg.sender].amountPublicSaleTokens=0;
        return true;
    }
    
        function publicSaleClaimvesting()public   returns(bool){
        require(!isCanceled,"presale is canceled");
        require(users[msg.sender].amountPublicSaleTokens>0);
        require(block.timestamp>prePublicSaleEnd.add(presalePublicTime),"You cannot claim amount before the time");
        token.transferFrom(owner,msg.sender,users[msg.sender].amountPublicSaleTokensVesting);
        users[msg.sender].amountPublicSaleTokensVesting=0;
        return true;
        
    }
    

    function cancelSale()public onlyOwner returns(bool){
        
            isCanceled=true;
        
        return true;
        
    }
    
    function claimAfterSaleCancel()public returns(bool){
        require(isCanceled,"presale is not canceled");
        payable(msg.sender).transfer(users[msg.sender].amountInvestedInPublicPreSale);
        users[msg.sender].amountInvestedInPublicPreSale=0;
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
    
    
    
    function setHardcap(uint256 value)onlyOwner public returns(bool){
        hardcap=value;
        return true;
    }
    
    
    
    function setPublicePreSaleTime(uint256 value)onlyOwner public returns(bool){
        presalePublicTime=value;
        return true;
    }
    
   
    function setTokenPriceToPublicSale(uint256 value)onlyOwner public returns(bool){
        tokenPricePublicSale=value;
        return true;
    }
    
    
    function setPublicPresaleSaleClaimable(bool value)onlyOwner public returns(bool){
        publicSaleClaimable=value;
        return true;
    }
    
    
    function startPublicPresaleSale()onlyOwner public returns(bool){
        publicSaleStop=false;
        prePublicSaleStart=block.timestamp;
        return true;
    }
    
    
    function stopPublicPresaleSale()onlyOwner public returns(bool){
        publicSaleStop=true;
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