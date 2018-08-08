pragma solidity 0.4.24;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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
    require(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}
contract owned {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner , "Unauthorized Access");
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface ERC20BackedERC223{
    
    function balanceOf(address who) constant external returns (uint);
    function transfer(address to, uint value) external returns (bool success);
    function transfer(address to, uint value, bytes data) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    function name() external view returns (string _name);

    /* Get the contract constant _symbol */
    function symbol() external view returns (string _symbol);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
/**
 * @title Contract that will work with ERC223 tokens.
 */
 
contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
 struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    function tokenFallback(address _from, uint _value, bytes _data) external;
}

library SafeERC20BackedERC223 {

  function safeTransfer(ERC20BackedERC223 token, address to, uint256 value, bytes data) internal {
    assert(token.transfer(to, value, data));
  }    
    
  function safeTransfer(ERC20BackedERC223 token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

}

contract CybitICOTokenVault is ERC223ReceivingContract, owned{
    
     using SafeERC20BackedERC223 for ERC20BackedERC223;
     ERC20BackedERC223 CybitToken;
      struct Investor {
        string fName;
        string lName;
    }
    
    mapping (address => Investor) investors;
    address[] public investorAccts;
    
     event TokenReceived(address indexed from, uint value, string token_name);

     constructor() public
     {
         
         CybitToken = ERC20BackedERC223(0x2a08c4B5CB8eC0b84beEC790741Ae92Bd1f921E3);
     }
          function tokenFallback(address _from, uint _value, bytes _data) external{
           /* tkn variable is analogue of msg variable of Ether transaction
      *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
      *  tkn.value the number of tokens that were sent   (analogue of msg.value)
      *  tkn.data is data of token transaction   (analogue of msg.data)
      *  tkn.sig is 4 bytes signature of function
      *  if data of token transaction is a function execution
      */
      require(msg.sender == owner);
      TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      //uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      //tkn.sig = bytes4(u);
      //require( tkn.sender == owner , "Only Owner can send" );
      emit TokenReceived(tkn.sender,tkn.value,CybitToken.name());
     
     }
     function() public {
         //not payable fallback function
          revert();
    }
    function sendApprovedTokensToInvestor(address _benificiary,uint256 _approvedamount,string _fName, string _lName) public onlyOwner
    {
        require(CybitToken.balanceOf(address(this)) > _approvedamount);
        investors[_benificiary] = Investor({
                                            fName: _fName,
                                            lName: _lName
            
        });
        
        investorAccts.push(_benificiary) -1;
        CybitToken.safeTransfer(_benificiary , _approvedamount);
    }
     function onlyPayForFuel() public payable onlyOwner{
        // Owner will pay in contract to bear the gas price if transactions made from contract
        
    }
    function withdrawEtherFromcontract(uint _amountInwei) public onlyOwner{
        require(address(this).balance > _amountInwei);
      require(msg.sender == owner);
      owner.transfer(_amountInwei);
     
    }
    function withdrawTokenFromcontract(ERC20BackedERC223 _token, uint256 _tamount) public onlyOwner{
        require(_token.balanceOf(address(this)) > _tamount);
         _token.safeTransfer(owner, _tamount);
     
    }
}