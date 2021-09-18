/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Company{
    event event_performance(address Sales,uint256 Profit);
    event event_add_sales(string Salesman,address SalesAddress);
    event event_withdraw(address Sales,uint256 Balance);
    event event_receive(address Donor,uint256 Value);
    
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
    
    modifier IsBoss(){
        require(msg.sender==boss_address,"You are not the boss!");
        _;
    }
    
    function AddPerformance(string memory Salesman, uint256 Profit) public IsBoss{
        name_sales[Salesman].performance += Profit;
        name_sales[Salesman].salary += Profit/10;
        emit event_performance(name_sales[Salesman].sales_address,Profit);
    }
    
    function AddSales(string memory Salesman, address payable SalesAddress) public IsBoss{
        all_address.push(SalesAddress);
        address_name[SalesAddress] = Salesman;
        name_sales[Salesman].name = Salesman;
        name_sales[Salesman].sales_address = SalesAddress;
        name_sales[Salesman].performance = 0;
        name_sales[Salesman].salary = 0;
        name_sales[Salesman].withdrawn = 0;
        emit event_add_sales(Salesman,SalesAddress);
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
        require(balance > 0,"Balance not enought!");
        user.transfer(balance);
        string memory name = address_name[msg.sender];
        name_sales[name].withdrawn += balance;
        emit event_withdraw(msg.sender,balance);
        return balance;
    }
    
    fallback() external payable {
    }
    
    receive() external payable {
        emit event_receive(msg.sender,msg.value);
    }

    function Destroy() external IsBoss{
        selfdestruct(boss_address);
    }

}