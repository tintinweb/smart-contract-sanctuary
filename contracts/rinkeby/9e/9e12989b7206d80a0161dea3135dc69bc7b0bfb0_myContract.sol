/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

pragma solidity >=0.5.1;

contract myContract {
    mapping(address => uint256) public balances;
    address payable wallet;
    
    function buyToken(address payable _wallet) public payable{
        // buy a buyToken
        balances[msg.sender] += 1;
        //send ether to wallet
        _wallet.transfer(msg.value);
        
        
    }

}