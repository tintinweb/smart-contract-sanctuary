/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

pragma solidity 0.5.10;

contract ERC20Interface {

   function totalSupply() public view returns (uint256);
   function balanceOf(address tokenOwner) public view returns (uint256 balanceRemain);
   function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
   function transfer(address to, uint256 tokens) public returns (bool success);
   function approve(address spender, uint256 tokens) public returns (bool success);
   function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
      
   event Transfer(address indexed from, address indexed to, uint256 value);
   event Approval(address indexed owner, address indexed spender, uint256 value);  

}

contract testpayment
{
    address uaddr;
	address owner;   
	uint256 public usdtTopupCnt = 1;
	uint256 public trxTopupCnt = 1;
		
  	struct Deposit {
		uint256 amount;
		uint256 reqNumber;
		uint256 userId;
		uint40 depositTime;
	}
	
	event topup(uint256 slno, string paytype, address indexed from, uint256 reqnum, uint256 amount, uint256 user, uint40 stsdate);
	
	
	mapping(uint256 => Deposit) public usdtDeposit;
	mapping(uint256 => Deposit) public trxDeposit;
    
    constructor() public 
	{
        owner = msg.sender;
    }
	
	function changeTokAddr(address _uaddr) public returns (string memory)
	 {
	  	require(msg.sender == owner,"Only Owner Can Transfer");
        uaddr = _uaddr;
        return("USDT Contract address updated successfully");
    }
    
	
	function checkUsdtBalance() public view returns (uint256 balance)
    {
        return ERC20Interface(uaddr).balanceOf(msg.sender);
	}
	
	function payEth(uint256 _reqNumber, uint256 _userId)  payable external  returns (string memory)
	{		
		require(msg.value>0);
			
		trxDeposit[trxTopupCnt].amount = msg.value;
		trxDeposit[trxTopupCnt].reqNumber = _reqNumber;
		trxDeposit[trxTopupCnt].userId = _userId;
		trxDeposit[trxTopupCnt].depositTime = uint40(block.timestamp);
		
		emit topup(trxTopupCnt, "TRX", msg.sender, _reqNumber, msg.value, _userId, uint40(block.timestamp));
		
		trxTopupCnt++;
		
		return "Success, Payment Received For Package Purchase";

	}
	
    function payUsdt(uint256 _reqNumber,uint256 _value,uint256 _userId) payable external returns (string memory)
    {
		require(_value>0);
        if(ERC20Interface(uaddr).balanceOf(msg.sender) >= _value)
		{
			if(ERC20Interface(uaddr).transferFrom(msg.sender, address(this), _value))
			{
				usdtDeposit[usdtTopupCnt].amount = _value;
				usdtDeposit[usdtTopupCnt].reqNumber = _reqNumber;
				usdtDeposit[usdtTopupCnt].userId = _userId;
				usdtDeposit[usdtTopupCnt].depositTime = uint40(block.timestamp);
				
				emit topup(usdtTopupCnt, "USDT", msg.sender, _reqNumber, _value, _userId, uint40(block.timestamp));
				
				usdtTopupCnt++;
								
				return "Success, Payment Received For Package Purchase";
			}
			else
			{
				return "Failed!!! Token transfer failed";
			}		
		}
		else
		{
			return "Failed!!! In-Sufficient USDT Balance";
		} 
	}
	
	function transferTRC20Token(address _foraddress, address _tokenAddress, uint256 _value) public returns (bool success) 
	{
	   require(msg.sender == owner,"Only Owner Can Transfer");
       return ERC20Interface(_tokenAddress).transfer(_foraddress, _value);
    }
	
	
	
    function withdrawEthBalance(address payable _foraddress, uint256 _value) public
	{
	   require(msg.sender == owner,"Only Owner Can Transfer");
	   _foraddress.transfer(_value);
	}
}