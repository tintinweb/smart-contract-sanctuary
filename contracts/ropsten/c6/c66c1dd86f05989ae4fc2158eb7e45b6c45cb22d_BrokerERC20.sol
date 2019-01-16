pragma solidity >=0.4.22 <0.6.0;

contract BrokerERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint public totalSupply;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    constructor() public {
        //name of token
        symbol = "Broker";
        name = "BrokerERC20";
        decimals = 18;
        totalSupply = 1000000;
        balanceOf[0x7B3004c9E18dc0bDB75E62b7E3c3549f39565b8F] = totalSupply; 
    }
}