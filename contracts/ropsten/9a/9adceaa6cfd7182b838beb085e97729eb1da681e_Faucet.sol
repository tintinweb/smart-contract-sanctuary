/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity ^0.8;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint tokens) external returns (bool success);
    function balanceOf(address beneficiary) view external returns (uint balance);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet {


    ERC20 public pinakion = ERC20(0xD042ef7eDFa1d39146a25f9cb87b274c422cCEb2);
    mapping(address => bool) public withdrewAlready;
    
    function balance() view public returns(uint balance)  {
        return pinakion.balanceOf(address(this));
    }

    function request() public {
        require(!withdrewAlready[msg.sender], "You have used this faucet already. If you need more tokens, please use another address.");
        pinakion.transfer(msg.sender, 10000000000000000000000);
        withdrewAlready[msg.sender] = true;
    }

}