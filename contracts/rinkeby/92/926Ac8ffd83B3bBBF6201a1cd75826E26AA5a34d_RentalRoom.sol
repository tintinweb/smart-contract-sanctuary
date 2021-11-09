/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract RentalRoom {
    mapping(address => Customer) _account;
    
    uint256 public timeNow;
    uint256 rentalPrice = ethToWei(1);
    uint256 rentalPeriod = 90;
    address owner = 0xCB14334ED23cb644390906A1F31C50eA75333B3C;
    
    struct Customer {
        address addr;
        bool rental;
        uint256 rentalTime;
        uint256 balance;
    }
    
    struct testData {
        uint256 rperiod;
        uint256 rprice;
        uint256 addr;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function ethToWei(uint256 eth_value) internal returns(uint256 ethwei){
        return uint256(eth_value * 1000000000000000000);
    }
     
    function weiToEth(uint256 wei_value) internal returns(uint256 weieth){
        return uint256(wei_value / 1000000000000000000);
    }
    
    function setDataprice(uint256 reprice) public onlyOwner {
        rentalPrice = reprice;
    }
    
    function setDatalocktime(uint256 locktime) public onlyOwner {
        rentalPeriod = locktime;
    }

    function deposit() public payable {
        _account[msg.sender].balance += msg.value;
        _account[msg.sender].addr = msg.sender;
    }
    
    function payForRent() public {
        require(_account[msg.sender].balance >= rentalPrice &&
                _account[msg.sender].rental == false , 'Can not pay for reantal');
        
        _account[msg.sender].rental = true;
        _account[msg.sender].balance -= rentalPrice;
        _account[msg.sender].rentalTime = block.timestamp + rentalPeriod;
    }
    
    function takeRentalPrice(address owner_addr) public onlyOwner{
        require(_account[owner_addr].rental == true && msg.sender == owner,'Not enough money');
        _account[owner_addr].rental = false;
        _account[owner].balance += rentalPrice;
    }
}