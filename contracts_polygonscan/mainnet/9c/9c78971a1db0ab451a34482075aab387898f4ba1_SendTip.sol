/**
 *Submitted for verification at polygonscan.com on 2021-07-08
*/

pragma solidity ^0.6.0;

contract Ownable {
    address public _owner;

    constructor () internal {
        _owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
    * @dev Returns true if the caller is the current owner.
    */
    function isOwner() public view returns (bool) {
        return (msg.sender == _owner);
    }
}

contract SendTip is Ownable{
    
    struct transactionData {
        uint amount;
    }
    
    mapping (string => transactionData) transaction;
    
    
    function  initiate(string memory username) public payable {
            
            uint currentamount = transaction[username].amount;
            transaction[username].amount = currentamount + msg.value;
            
    }
    
    function read( string memory username) public view returns (uint) {
        
            uint amount =  transaction[username].amount;
            
            return (amount); 
    }
    
    
    function release(string memory username, address payable recipient )  public onlyOwner {
            
            uint transferamount = transaction[username].amount;
            transaction[username].amount = 0;
            payable(recipient).transfer(transferamount);
          
    }
    
}