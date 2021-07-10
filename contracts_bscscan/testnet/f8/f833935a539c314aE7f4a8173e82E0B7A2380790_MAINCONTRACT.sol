/**
 *Submitted for verification at BscScan.com on 2021-07-10
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


   
contract MAINCONTRACT{
 
	
    address public owner;

   IBEP20 private busdToken; 

    constructor(address ownerAddress, IBEP20 _busdToken) public 
    {
        owner = ownerAddress;
        busdToken = _busdToken;
    }
    event PaymentDone(address _user,uint256 _amount, uint256 _block_timestamp);
   
	 
	function pyament(uint256 tokenQty) public payable 
	{
	    address userAddress=msg.sender;
	   
	    
	    require(busdToken.balanceOf(userAddress)>=(tokenQty),"Low Balance");
	    require(busdToken.allowance(userAddress,address(this))>=(tokenQty),"Approve your token First");
	    require(!isContract(userAddress),"Can not be contract");
       
	     
	
		 busdToken.transferFrom(userAddress,owner,tokenQty);
		 
		
		emit PaymentDone(userAddress, tokenQty, block.timestamp);
		}
	 

	
    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }    
  
}