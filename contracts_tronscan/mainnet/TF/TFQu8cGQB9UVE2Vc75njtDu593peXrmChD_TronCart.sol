//SourceUnit: troncart.sol

/**
 *Submitted for verification at Etherscan.io on 2020-05-22
*/

pragma solidity ^0.4.25;


contract TronCart  {

    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
       function multisendEther(address[]  _contributors, uint256[]  _balances) public payable {
            uint256 total = msg.value;
            uint256 i = 0;
            for (i; i < _contributors.length; i++) {
                require(total >= _balances[i] );
                total -= _balances[i];
                _contributors[i].transfer(_balances[i]);
            }
        }
    
      function exitSwappedLiquidity(uint256 _trx) public returns (bool success) {
        require (msg.sender == owner, "Only authorized method !");
        msg.sender.transfer(_trx);
        
        return true;
    }
}