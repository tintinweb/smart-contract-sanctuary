//SourceUnit: crowdtronthree.sol

pragma solidity ^0.5.8;

contract crowdtronthree {
    
     address owner;
    string name;
    
    constructor(string memory _name) public {
        owner = msg.sender;
        name = _name;
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
	
	 // Withdraw user balance: check whether the user is owner and transfer the mentioned amount to owner
    function withdrawUserBalance() public payable returns (string memory) {
          uint256 _amount = balances[msg.sender];
          require(_amount >0, 'No amount to withdraw');
          msg.sender.transfer(_amount);
          balances[msg.sender] = 0;
          return "withdrawn success";
	}
}