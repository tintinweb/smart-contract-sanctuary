/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// version of solidity complier this program was witten for
pragma solidity >=0.4.22 <0.8.0;

// our first contract implementing a faucet
contract restore {
    
    uint256 private number;
    
    function store(uint256 num) public{
        number=num;
    }
    
    function retrive() public view returns(uint256){
        return number;
    }
}