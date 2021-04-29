/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Company{
    uint internal startDate = 1619654400;//20210429
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;
    string public boss_name;
    address payable public boss_address;
    struct Sales{
        string name;
        address payable sales_address;
        uint256 performance;
        uint256 salary;
        uint256 withdrawn;
    }
    address[] all_address;
    mapping(address=>string) address_name;
    mapping(string=>Sales) name_sales;
    function AddPerformance(string memory Salesman, uint256 Profit) public {
        name_sales[Salesman].performance += Profit;
        name_sales[Salesman].salary += Profit/10;
    }
    
    function AddSales(string memory Salesman, address payable SalesAddress) public {
        all_address.push(SalesAddress);
        address_name[SalesAddress] = Salesman;
        name_sales[Salesman].name = Salesman;
        name_sales[Salesman].sales_address = SalesAddress;
        name_sales[Salesman].performance = 0;
        name_sales[Salesman].salary = 0;
        name_sales[Salesman].withdrawn = 0;
    }
    
    function CheckBalance (address payable SalesAddress) public view returns(uint256){
        Sales memory s = name_sales[address_name[SalesAddress]];
        return s.salary-s.withdrawn;
    }
    
    function MyBalance() external view returns(uint256) {
        Sales memory s = name_sales[address_name[msg.sender]];
        return s.salary-s.withdrawn;
    }
    
    constructor(string memory name){
        boss_name = name;
        boss_address = payable(msg.sender);
    }

    function GetAllPerformance() public view returns(uint256){
        uint256 sum = 0;
        for(uint i=0;i<all_address.length;i++){
            address tmp = all_address[i];
            string memory name = address_name[tmp];
            sum += name_sales[name].performance;
        }
        return sum;
    }
    
    function Withdraw() external returns(uint256){
        address payable user = payable(msg.sender);
        uint balance = CheckBalance(user);
        user.transfer(balance);
        string memory name = address_name[msg.sender];
        name_sales[name].withdrawn += balance;
        return balance;
    }
    
    
    
    fallback() external payable {
    }
    
    receive() external payable {
    }

    function Destroy() external {
        uint nowTimestamp = block.timestamp;
        bool isOverYear = diffDays(startDate,nowTimestamp)>=365;
      if(isOverYear){
            selfdestruct(boss_address);
        }
    }
    
    function test() public view returns (bool isOverYear,uint nowTimestamp){
         nowTimestamp = block.timestamp;
         isOverYear = diffDays(startDate,nowTimestamp)>=365;
        
    }
    
    function nowInSeconds() public returns (uint256){
        return block.timestamp;
    }
    
    function timestampFromDate(uint year, uint month, uint day) public pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    
    function _daysFromDate(uint year, uint month, uint day) public pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);
 
        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;
 
        _days = uint(__days);
    }
    
    function diffDays(uint fromTimestamp, uint toTimestamp) public pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }


}