/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ERC20 {
    function transfer(address _to, uint256 _value)external returns(bool);
    function balanceOf(address tokenOwner)external view returns(uint balance);
    function transferFrom(address from, address to, uint tokens)external returns(bool success);
}

contract AirDroper {

    ERC20 public token;
    uint256 public dropAmount;

    mapping(address => bool) public hasClaimed;
    uint public droppedAddressCount;
    address[] public addresses;

    constructor(address _tokenAddr, uint256 _dropAmount, uint _tokenDecimal){
        token = ERC20(_tokenAddr);
        dropAmount = _dropAmount * 10 ** _tokenDecimal;
        droppedAddressCount = 0;
    }

    function getAirdrop() public {
        require(hasClaimed[msg.sender] == false, "Only one airdrop is authorized.") ;
        hasClaimed[msg.sender] = true;
        droppedAddressCount += 1;
        addresses.push(msg.sender);
        token.transfer(msg.sender, dropAmount);
    }

    function getAddresses() public view returns (address[] memory){
        return addresses;
    }

    function tokenAmountLeft() public view returns (uint256){
        return token.balanceOf(address(this));
    }
}