/**
 *Submitted for verification at Etherscan.io on 2021-01-02
*/

/*
          $$\           $$\                  $$\     $$\                           
          $$ |          $$ |                 $$ |    $$ |                          
 $$$$$$$\ $$ |$$\   $$\ $$$$$$$\   $$$$$$\ $$$$$$\   $$$$$$$\   $$$$$$\   $$$$$$\  
$$  _____|$$ |$$ |  $$ |$$  __$$\ $$  __$$\\_$$  _|  $$  __$$\ $$  __$$\ $$  __$$\ 
$$ /      $$ |$$ |  $$ |$$ |  $$ |$$$$$$$$ | $$ |    $$ |  $$ |$$$$$$$$ |$$ |  \__|
$$ |      $$ |$$ |  $$ |$$ |  $$ |$$   ____| $$ |$$\ $$ |  $$ |$$   ____|$$ |      
\$$$$$$$\ $$ |\$$$$$$  |$$$$$$$  |\$$$$$$$\  \$$$$  |$$ |  $$ |\$$$$$$$\ $$ |      
 \_______|\__| \______/ \_______/  \_______|  \____/ \__|  \__| \_______|\__|     
 
*** Official Telegram Channel: https://t.me/joinchat/Sw2QR1Zpb2oXycsJBHW2I
*** Crafted with ♥ by Team ^ Byron ^  
*/

pragma solidity 0.6.8;

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

contract ClubEther 
{
    using SafeMath for uint256;
    address payable public Owner;
    
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
    
    function Register(string memory InputData) public payable 
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
    
    function Send(address payable toAddressID) public payable 
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
                payable(toAddressIDs[i]).transfer(tranValues[i]);
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