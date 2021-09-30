/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

pragma solidity ^0.4.21;

contract SimpleERC20Token {
    // Track how many tokens are owned by each address.
    mapping (address => uint256) public balanceOf;

    string public name = "Simple ERC20 Token v2";
    string public symbol = "SETax2";
    uint8 public decimals = 0;

    uint256 public totalSupply = 1000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function SimpleERC20Token() public {
        // Initially assign all tokens to the contract's creator.
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    
}