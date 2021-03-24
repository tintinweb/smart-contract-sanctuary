/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity 0.4.24;



interface Token {
    
    function balanceOf(address account) external  returns (uint256);
}
contract testIt {
    
    
    address public owner;
    uint public tokenSendFee; // in wei
    uint public ethSendFee; // in wei

    address public constant tokenAddress = 0x38676A1d8C2Be34a80BF030C8D5b559a662893C3;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function checkBalance(address addr) external returns (uint256) {
        return Token(tokenAddress).balanceOf(addr);
    }
    
}