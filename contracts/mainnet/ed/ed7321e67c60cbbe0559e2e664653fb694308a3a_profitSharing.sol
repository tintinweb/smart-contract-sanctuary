/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.0;

contract profitSharing{
    
    address public owner;
    uint public allPercent;
    uint decimals = (10 ** 6);
    
    struct Addresses {
        address userAddress;
        uint percent;
    }
    
    Addresses[] public addresses;
    Addresses[] newAddr;
    uint public payBalance = 0;
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    event Deposit(address indexed from, uint value);
    
    constructor () public {
        owner = msg.sender;
    }
    
    function() external payable {
        if(address(this).balance >= payBalance * decimals){
            payAll();
        }
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    } 
    
    function setPayBalance(uint _payBalance) public isOwner{
        payBalance = _payBalance;
    }
    
    function payAll() public isOwner payable{
        uint j = 0;
        uint allBalance = address(this).balance;
        for (j = 0; j < addresses.length; j++) {
            addresses[j].userAddress.transfer((allBalance * addresses[j].percent) / 100);
        }
        //if(address(this).balance > 0){
        //    owner.transfer(address(this).balance);
        //}
    }
    
    function getCount() public view returns(uint) {
        return addresses.length;
    }
    
    function getAdresses(uint j) public view returns(uint num, address addr, uint per){
        num = j;
        addr = addresses[j].userAddress;
        per = addresses[j].percent;
    }
    
    function setAddresses(address _userAddr, uint percent) public isOwner{ 
        addresses.push(Addresses(_userAddr, percent));
        allPercent += percent;
    }
    
    function updateAddresses(address _userAddr, uint percent, uint num) public isOwner{
        uint old = allPercent - addresses[num].percent;
        addresses[num] = Addresses(_userAddr, percent);
        allPercent = old + percent;
    }
    
    function deleteAddresses(uint num) public isOwner{
        uint i = 0;
        for(i = 0; i < addresses.length; i++){
            if(i != num){
                newAddr.push(addresses[i]);
            }
        }
        addresses.length = 0;
        addresses = newAddr;
    }
}