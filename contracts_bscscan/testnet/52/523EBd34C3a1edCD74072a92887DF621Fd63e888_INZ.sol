/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

pragma solidity 0.5.4;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
  external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
  external returns (bool);
  
  function transferFrom(address from, address to, uint256 value)
  external returns (bool);
  function burn(uint256 value)
  external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}

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
   
contract INZ{
     using SafeMath for uint256;

    uint public  total_token_buy = 0;
	uint public  total_token_sale = 0;

	
	uint256 public  MINIMUM_BUY = 1e17;
	uint256 public  MINIMUM_SALE = 1e17;
	uint256 public  tokenPrice = 1e15;
	

    address public owner;
 
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate,uint256 bnb_amount);
  
     //For Token Transfer
   
   IBEP20 private inzToken; 
 

    constructor(IBEP20 _inzToken) public 
    {
        owner = msg.sender;
        
        inzToken = _inzToken;
        
    }
    

    function withdrawBalance(uint256 amt,uint8 _type) public 
    {
        require(msg.sender == owner, "onlyOwner");
        if(_type==1)
        msg.sender.transfer(amt);
        else
        inzToken.transfer(msg.sender,amt);
    }


    

    function buyToken(uint tokenQty) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	     require(msg.value>=MINIMUM_BUY,"Minimum 0.1 BNB");
	  
	     
	     uint256 buy_amt=calcBuyAmt(tokenQty);
	     require(msg.value>=buy_amt,"Invalid buy amount");
	   
	     
	     inzToken.transfer(msg.sender , tokenQty);
	     
	     
         total_token_buy=total_token_buy+tokenQty;
		 emit TokenDistribution(address(this), msg.sender, tokenQty, tokenPrice,msg.value);					
	 }
	 
	function sellToken(uint tokenQty) public payable 
	{
	    address userAddress=msg.sender;
	    
	    require(inzToken.balanceOf(userAddress)>=(tokenQty),"Low Balance");
	    require(inzToken.allowance(userAddress,address(this))>=(tokenQty),"Approve your token First");
	    require(!isContract(userAddress),"Can not be contract");
	    
	    uint256 bnb_amt=calcBuyAmt(tokenQty);
	     
		 inzToken.transferFrom(userAddress ,address(this), (tokenQty));
		 address(uint160(msg.sender)).transfer(bnb_amt);
		
		emit TokenDistribution(userAddress,address(this), tokenQty, tokenPrice,bnb_amt);
		total_token_sale=total_token_sale+tokenQty;
	 }
	 

	function calcBuyAmt(uint256 tokenQty) public view returns(uint256)
	{
	    uint256 amt;
	    amt=(tokenQty.div(1e18)).mul(tokenPrice);
	    return (amt);
	}
	


	
    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }    
  
    function token_setting(uint256 min_buy,  uint256 min_sale,  uint256 _tokenPrice) public payable
    {
           require(msg.sender==owner,"Only Owner");
              MINIMUM_BUY = min_buy;
    	      MINIMUM_SALE = min_sale;
    	      tokenPrice = _tokenPrice;
    }
    

    
        
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}