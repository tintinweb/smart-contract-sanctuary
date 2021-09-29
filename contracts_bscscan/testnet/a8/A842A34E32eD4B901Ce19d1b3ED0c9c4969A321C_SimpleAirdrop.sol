/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ERC20 {
    function transfer(address _to, uint256 _value)external returns(bool);
    function balanceOf(address tokenOwner)external view returns(uint balance);
    function transferFrom(address from, address to, uint tokens)external returns(bool success);

}

contract SimpleAirdrop {

    ERC20 public token;
    uint256 public amount;
    mapping(address => bool) public hasClaimed;
    
    constructor(address _tokenAddr, uint256 _amount, uint _tokenDecimal) public {
        token = ERC20(_tokenAddr);
        amount = _amount * 10 ** _tokenDecimal;
    }
    
    function getAirdrop() public {
        require(hasClaimed[msg.sender] == false, "Only one airdrop is authorized.") ;
        token.transfer(msg.sender, amount);
        hasClaimed[msg.sender] = true;
    }
}