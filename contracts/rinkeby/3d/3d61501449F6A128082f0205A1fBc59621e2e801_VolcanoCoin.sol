/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract VolcanoCoin {
    struct Payment {
      address receipient;
      uint256 amount;
    }
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
     
    address owner;

    event increaseSuppply(uint256);
    event Transfer(address, uint256);
    
    modifier onlyOwner {
        if (msg.sender == owner) {
            _; 
        }
    }
   
   constructor() {
      totalSupply = 100*10**18;
      owner = msg.sender;
      balances[msg.sender] = totalSupply;
   }
   
   function getTotalSupply() public view returns (uint256) {
      return totalSupply;    
   }
   
   function updateTotalSupply() public onlyOwner {
      totalSupply += 100000000;
      emit increaseSuppply(totalSupply);
   }
   
   function transfer(address _recipient, uint256 _amount) public {
      require(balances[msg.sender] >= _amount);

          balances[msg.sender] -=  _amount;
          balances[_recipient] +=  _amount;
          

          emit Transfer(_recipient, _amount);
}
   
   function getBalance(address user) public view returns (uint256) {
       return balances[user];
   }
   

}