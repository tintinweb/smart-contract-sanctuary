/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-28
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
   
contract AIRDROP_TOKEN  
{
     using SafeMath for uint256;

 
  
	
    address public owner;
    
  
    
   //For Token Transfer
   
   IBEP20 private MyToken; 

    constructor(address ownerAddress, IBEP20 _MyToken) public 
    {
        owner = ownerAddress;
        
        MyToken = _MyToken;
 
    }
    
  
	 function multisendTOKEN(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
			require(msg.sender == owner, "onlyOwner");
			uint256 i = 0;
			for (i; i < _contributors.length; i++) {
				MyToken.transfer(_contributors[i],_balances[i]);
			}
		}

        
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}