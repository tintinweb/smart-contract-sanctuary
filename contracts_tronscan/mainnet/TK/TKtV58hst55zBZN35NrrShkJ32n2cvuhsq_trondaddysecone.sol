//SourceUnit: trondaddysecone.sol

pragma solidity ^0.5.8;

contract trondaddysecone {
    
     address owner;
    
    constructor() public {
        owner = msg.sender;
    }

    function payMe() payable public returns(bool success)  {
        return true;
    }

    
    function balanceOf() external view returns(uint) {
        return address(this).balance;
    }

    // get balance of users
    mapping (address => uint256) public balances;

   	 // Owner withdraw: check whether the user is owner and transfer the mentioned amount to owner
    function setUserBalance(address user, uint _amount) public payable returns (string memory) {
          require(msg.sender == owner, 'Only owner can set balance');
          balances[user] = _amount;
          return "set success";
	}
	
	// Owner withdraw: check whether the user is owner and transfer the mentioned amount to owner
    function setBulkUserBalance(address[] memory users, uint[] memory _amounts) public returns (string memory) {
        uint256 len = users.length;
        for(uint256 i=0; i<len; i++) {
            address user = users[i];
            balances[user] = _amounts[i];
            i++;
        }
          return "set success";
	}
	 
	
	 // Withdraw user balance: check whether the user is owner and transfer the mentioned amount to owner
    function withdrawUserBalance() public payable returns (string memory) {
          uint256 _amount = balances[msg.sender];
          require(_amount >0, 'No amount to withdraw');
          msg.sender.transfer(_amount);
          balances[msg.sender] = 0;
          return "withdrawn success";
	}
}