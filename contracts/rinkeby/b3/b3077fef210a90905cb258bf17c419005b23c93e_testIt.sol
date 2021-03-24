/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity 0.4.24;



interface Token {
    
    function balanceOf(address) external  returns (uint256);
}
contract testIt {
    
    
  address public owner;

    constructor() public {
        owner = msg.sender;
    }
    
    function checkBalance(address addr,address tokenAddr) public view returns (uint256) {
        return Token(tokenAddr).balanceOf(addr);
    }
    
}