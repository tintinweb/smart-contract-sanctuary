//SourceUnit: Kiaan11Tron.sol

pragma solidity 0.4.25;

contract Kiaan11
{
    using SafeMath for uint256;
    address public Owner;
    
    // This is the constructor whose code is
    // run only when the contract is created.
    constructor() public payable {
        Owner = msg.sender;
    }
    
    function GetOwner() public view returns(address)
    {
        return Owner;
    }
    
    // GetAddressCurrentBalance
    function GetBalance(address strAddress) external view returns(uint)
    {
        return address(strAddress).balance;
    }
    
    function JoinKiaan11(string memory InputData) public payable 
    {
        if(keccak256(abi.encodePacked(InputData))==keccak256(abi.encodePacked('')))
        {
            // do nothing!
            revert();
        }
        
        if(msg.sender!=Owner)
        {
            Owner.transfer(msg.value);
        }
        else
        {
            // else do nothing!
            revert();
        }
    }
    
    function Send(address toAddressID) public payable 
    {
        if(msg.sender==Owner)
        {
            toAddressID.transfer(msg.value);
        }
        else
        {
            // else do nothing!
            revert();
        }
    }
    
    function SendWithdrawals(address[] memory toAddressIDs, uint256[] memory tranValues) public payable 
    {
        if(msg.sender==Owner)
        {
            uint256 total = msg.value;
            uint256 i = 0;
            for (i; i < toAddressIDs.length; i++) 
            {
                require(total >= tranValues[i] );
                total = total.sub(tranValues[i]);
                toAddressIDs[i].transfer(tranValues[i]);
            }
        }
        else
        {
            // else do nothing!
            revert();
        }
    }
    
    function Transfer() public
    {
      Owner.transfer(address(this).balance);  
    }
}

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