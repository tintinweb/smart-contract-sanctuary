/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Stupid_bank {
    mapping(address => Customer) _account;
    
    uint256 retentionPrice = ethToWei(1);
    uint256 retentionPeriod = 30;
    address owner = 0x6032692257DAb7a4DCbD153ece2a540F069208Fa;
    
    struct Customer {
        address addr;
        bool retention;
        uint256 retentionTime;
    }
     struct testData {
        uint256 rperiod;
        uint256 rprice;
        address addr;
    }
    
    
    function retentionPay() public payable{
        require(_account[msg.sender].retention == false && msg.value >= retentionPrice , "Not possible");
        _account[msg.sender].retention = true;
        _account[msg.sender].retentionTime = block.timestamp + retentionPeriod;
    }
    
    function getRetention() public payable{
        require(_account[msg.sender].retention == true && block.timestamp >= _account[msg.sender].retentionTime, "You have to paid first!");
        payable(msg.sender).transfer(retentionPrice);
        _account[msg.sender].retention == false;
    }
    
    function takeRetention(address cus_addr) public payable{
        require(_account[cus_addr].retention == true && msg.sender == owner , "Customer didnt paid retention");
        payable(owner).transfer(retentionPrice);
        _account[cus_addr].retention == false;
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
    function gettimestamp(uint256 useless) public view returns(uint256 time){
        return block.timestamp;
    }
    function testuser(address cusaddr) public view returns(Customer memory tempcustomer){
        return _account[cusaddr];
    }
    function getData(uint256 useless) public view returns(testData memory tempdata){
        return testData(retentionPeriod, retentionPrice, owner);
    }
    function setData(uint256 reprice, uint256 locktime, address newowner) public onlyOwner {
        retentionPrice = reprice;
        retentionPeriod = locktime;
        owner = newowner;
    }
}