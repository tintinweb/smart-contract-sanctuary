pragma solidity >=0.4.22 <0.6.0;

contract toketERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    constructor(
        
        ) public {
        //name of token
        symbol = "Toket20";
        name = "toketERC20";
        decimals = 18;
        totalSupply = 100000000000000000000;
        balanceOf[msg.sender] = totalSupply; 
    }
}