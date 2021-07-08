/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

pragma solidity 0.5.4;

interface IERC20 {
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
   
contract FOREVER_BUSD  {
    
	event Registration(string  member_name, string  sponcer_id,string  position,uint256 package,address indexed sender);
	event Reinvestment(string  member_name,uint256 matrix);
	
    using SafeMath for uint256;
    address public owner;
   
    IERC20 private FOREVERBUSD; 

    constructor(address ownerAddress,IERC20 _BUSD) public 
    {
        owner = ownerAddress;
        FOREVERBUSD = _BUSD;
    }
    
	
	function NewRegistration(address userAddress,uint investment,string memory member_name, string memory sponcer_id,string memory position) public payable
	{
		FOREVERBUSD.transferFrom(userAddress ,address(this),investment);
		emit Registration(member_name, sponcer_id,position,investment,msg.sender);
	}
	
	function Investment(address userAddress,uint investment,string memory member_name) public payable
	{
		FOREVERBUSD.transferFrom(userAddress ,address(this),investment);
		emit Reinvestment(member_name,investment);
	}

	function multisendBUSD(address payable[]  memory  _contributors, uint256 _amount) public payable 
    {
		require(msg.sender==owner,"Only Owner");
		uint i = 0;
        for (i; i < _contributors.length; i++) 
        {
            
             FOREVERBUSD.transfer(_contributors[i],_amount);
                     
        }     
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