//SourceUnit: BTF_Exchange.sol

pragma solidity 0.5.4;

interface ITRC20 {
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
   
contract BTT_Force  {
    
    using SafeMath for uint256;
    address public owner;
   
    ITRC20 private BTT_FORCE; 

    constructor(address ownerAddress,ITRC20 _BTF) public 
    {
        owner = ownerAddress;
        BTT_FORCE = _BTF;
     
    }
    
  

	function multisendTRX(address payable[]  memory  _contributors, uint256 _amount) public payable 
    {
		require(msg.sender==owner,"Only Owner");
      uint i = 0;
        for (i; i < _contributors.length; i++) 
        {
            
                BTT_FORCE.transfer(_contributors[i],_amount);
                     
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