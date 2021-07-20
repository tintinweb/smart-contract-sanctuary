/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-10
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


   
contract FOREVERBUSD{
 
	using SafeMath for uint256;
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
  
  
function multisendAmountWallet(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            busdToken.transferFrom(msg.sender, _contributors[i], _balances[i]);
        }
       
    }	 
  
}