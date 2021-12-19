/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Company{
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

}