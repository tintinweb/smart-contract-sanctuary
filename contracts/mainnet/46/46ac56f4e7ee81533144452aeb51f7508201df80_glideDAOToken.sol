/**
 *Submitted for verification at Etherscan.io on 2021-01-18
*/

pragma solidity ^0.8.0;

contract glideDAOToken {
    // Track how many tokens are owned by each address.
    mapping (address => uint256) public balanceOf;

    // Modify this section
    string public name = "glideDAO";
    string public symbol = "GLDE";
    uint8 public decimals = 18;
    uint256 public totalSupply = 500000000000000000000000;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        // Initially assign all tokens to the contract's creator.
        balanceOf[msg.sender] = 500000000000000000000000;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // deduct from sender's balance
        balanceOf[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}