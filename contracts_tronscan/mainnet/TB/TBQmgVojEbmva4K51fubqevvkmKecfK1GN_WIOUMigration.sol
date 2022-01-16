//SourceUnit: WOUI.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



/**
 * @title TRC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract  WIOUMigration {


      using SafeMath for uint256;
      
      address payable public  _owner;
      ITRC20 public _Token;
      
      
   
   constructor(ITRC20 _tokenaddress,address payable _address)
   {
       _Token = _tokenaddress;
       _owner = _address;
   }

    
           modifier onlyOwner()
    {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    

    function register()public view returns(address)
    {
        return msg.sender;
    }
    
    
    
    function multisendToken( address[] calldata _contributors, uint256[] calldata _balances) external onlyOwner  
    {
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
            _Token.transfer(_contributors[i], _balances[i]);
            
            }
    }
        
        
        
    function sendMultiEth(address payable[]  memory  _contributors, uint256[] memory _balances) public payable  onlyOwner 
    {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
    }



    function sell(uint256 _token)external
    {
        require(_token>0,"Select amount first");
        _Token.transferFrom(msg.sender,address(this),_token);
    }
    
    
    
    
    function withDraw(uint256 _amount) onlyOwner external
    {
        _owner.transfer(_amount);
    }
    
    
    function getTokens(uint256 _amount) onlyOwner external 
    {
        _Token.transfer(msg.sender,_amount);
    }
    
        
}



/**     
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a); 
    return c;
  }
}